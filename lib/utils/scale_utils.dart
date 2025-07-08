// lib/utils/scale_utils.dart
import '../models/music/note.dart';
import '../models/music/scale.dart';
import 'note_utils.dart';

/// Utility functions for scale operations
class ScaleUtils {
  /// Get pitch classes for a scale mode
  static List<int> getPitchClasses(String scaleName, {int mode = 0}) {
    final scale = Scale.get(scaleName);
    if (scale == null) return Scale.chromatic.intervals;

    return scale.getModeIntervals(mode);
  }

  /// Get effective root for a mode
  static String getModeRoot(String baseRoot, String scaleName, int modeIndex) {
    final scale = Scale.get(scaleName);
    if (scale == null) return baseRoot;

    final rootNote = Note.fromString('${baseRoot}3');
    final modeRoot = scale.getModeRoot(rootNote, modeIndex);

    return modeRoot.name;
  }

  /// Get scale degrees
  static List<String> getScaleDegrees(String scaleName) {
    const degreeNames = [
      '1',
      '♭2',
      '2',
      '♭3',
      '3',
      '4',
      '♭5',
      '5',
      '♭6',
      '6',
      '♭7',
      '7'
    ];

    final scale = Scale.get(scaleName);
    if (scale == null) return [];

    return scale.intervals.map((interval) => degreeNames[interval]).toList();
  }

  /// Check if a scale contains an interval
  static bool scaleContainsInterval(String scaleName, int interval) {
    final scale = Scale.get(scaleName);
    return scale?.intervals.contains(interval % 12) ?? false;
  }

  /// Check if a note is in a scale
  static bool isNoteInScale(String note, String scaleRoot, String scaleName) {
    final notePc = NoteUtils.pitchClassFromName(note);
    final rootPc = NoteUtils.pitchClassFromName(scaleRoot);
    final interval = (notePc - rootPc + 12) % 12;

    return scaleContainsInterval(scaleName, interval);
  }

  /// Get relative minor/major key
  static String getRelativeKey(String key, String scaleType) {
    final keyPc = NoteUtils.pitchClassFromName(key);

    if (scaleType == 'Major') {
      // Relative minor is a minor 6th up (9 semitones)
      final relativeMinorPc = (keyPc + 9) % 12;
      return NoteUtils.nameFromPitchClass(relativeMinorPc,
          preferFlats: NoteUtils.shouldUseFlats(key));
    } else if (scaleType == 'Natural Minor') {
      // Relative major is a major 3rd up (3 semitones)
      final relativeMajorPc = (keyPc + 3) % 12;
      return NoteUtils.nameFromPitchClass(relativeMajorPc,
          preferFlats: NoteUtils.shouldUseFlats(key));
    }

    return key;
  }

  /// Get parallel minor/major key
  static String getParallelKey(String key) {
    // Parallel keys have the same root
    return key;
  }

  /// Get closest note in scale
  static String getClosestScaleNote(
      String note, String scaleRoot, String scaleName) {
    final scale = Scale.get(scaleName);
    if (scale == null) return note;

    final notePc = NoteUtils.pitchClassFromName(note);
    final rootPc = NoteUtils.pitchClassFromName(scaleRoot);
    final interval = (notePc - rootPc + 12) % 12;

    // Find closest interval in scale
    int closestInterval = scale.intervals[0];
    int minDistance = 12;

    for (final scaleInterval in scale.intervals) {
      final distance = (interval - scaleInterval).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestInterval = scaleInterval;
      }
    }

    final closestPc = (rootPc + closestInterval) % 12;
    return NoteUtils.nameFromPitchClass(closestPc,
        preferFlats: NoteUtils.shouldUseFlats(scaleRoot));
  }

  /// Generate scale notes for multiple octaves
  static List<Note> generateScaleNotes({
    required String root,
    required String scaleName,
    required Set<int> octaves,
    int modeIndex = 0,
  }) {
    final scale = Scale.get(scaleName);
    if (scale == null) return [];

    final notes = <Note>[];
    final effectiveRoot = getModeRoot(root, scaleName, modeIndex);
    final intervals = scale.getModeIntervals(modeIndex);
    
    // Add the octave to the intervals if not already present
    final extendedIntervals = [...intervals];
    if (!extendedIntervals.contains(12)) {
      extendedIntervals.add(12);
    }

    for (final octave in octaves) {
      final rootNote = Note.fromString('$effectiveRoot$octave');
      
      // Build the scale from root to octave
      for (final interval in extendedIntervals) {
        final note = rootNote.transpose(interval);
        notes.add(note);
      }
    }

    return notes..sort((a, b) => a.midi.compareTo(b.midi));
  }

  /// Validate if a note collection forms a scale
  static bool isValidScale(List<String> notes, String scaleType) {
    if (notes.isEmpty) return false;

    final scale = Scale.get(scaleType);
    if (scale == null) return false;

    final pitchClasses =
        notes.map(NoteUtils.pitchClassFromName).toSet().toList()..sort();
    final rootPc = pitchClasses[0];

    final intervals =
        pitchClasses.map((pc) => (pc - rootPc + 12) % 12).toList();

    return _listsEqual(intervals, scale.intervals);
  }

  static bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Extension on String for convenience
extension NoteStringExtension on String {
  bool get shouldUseFlats => NoteUtils.shouldUseFlats(this);
}