// lib/controllers/music_controller.dart
import '../models/music/note.dart';
import '../models/music/scale.dart';
import '../models/music/chord.dart';
import '../models/music/interval.dart';
import '../constants/app_constants.dart';
import '../constants/music_constants.dart';

/// Controller for music theory operations
class MusicController {
  /// Get the effective root for a scale mode
  static String getModeRoot(String baseRoot, String scaleName, int modeIndex) {
    final scale = Scale.get(scaleName);
    if (scale == null) return baseRoot;

    final rootNote = Note.fromString('$baseRoot${AppConstants.defaultOctave}');
    final modeRoot = scale.getModeRoot(rootNote, modeIndex);

    return modeRoot.name;
  }

  /// Get available modes for a scale
  static List<String> getAvailableModes(String scaleName) {
    final scale = Scale.get(scaleName);
    if (scale == null) return ['Mode 1'];

    if (scale.modeNames != null) {
      return scale.modeNames!;
    }

    return List.generate(scale.length, (i) => 'Mode ${i + 1}');
  }

  /// Get the current mode name
  static String getCurrentModeName(String scaleName, int modeIndex) {
    final scale = Scale.get(scaleName);
    if (scale == null) return 'Mode ${modeIndex + 1}';

    return scale.getModeName(modeIndex);
  }

  /// Build a chord symbol
  static String getChordSymbol(String root, String chordType) {
    final chord = Chord.get(chordType);
    if (chord == null) return root;

    return chord.getSymbol(root);
  }

  /// Get chord display name with inversion
  static String getChordDisplayName(
      String root, String chordType, ChordInversion inversion) {
    final baseSymbol = getChordSymbol(root, chordType);

    if (inversion == ChordInversion.root) {
      return baseSymbol;
    }

    // Get the bass note for the inversion
    final chord = Chord.get(chordType);
    if (chord == null || inversion.index >= chord.intervals.length) {
      return baseSymbol;
    }

    final rootNote = Note.fromString('$root${AppConstants.defaultOctave}');
    final bassInterval = chord.intervals[inversion.index];
    final bassNote = rootNote.transpose(bassInterval);

    return '$baseSymbol/${bassNote.name}';
  }

  /// Check if note is in scale
  static bool isNoteInScale(Note note, String root, String scaleName) {
    final scale = Scale.get(scaleName);
    if (scale == null) return false;

    final rootNote = Note.fromString('$root${note.octave}');
    return note.inScale(rootNote.pitchClass, scale.intervals);
  }

  /// Get interval between two notes
  static Interval getInterval(Note note1, Note note2) {
    final semitones = note1.intervalTo(note2);
    return Interval(semitones);
  }

  /// Transpose a note
  static Note transposeNote(Note note, int semitones) {
    return note.transpose(semitones);
  }

  /// Get enharmonic equivalent
  static Note getEnharmonic(Note note) {
    return note.enharmonic;
  }

  /// Determine if root should use flats
  static bool shouldUseFlats(String root) {
    return MusicConstants.flatRoots.contains(root);
  }

  /// Get default starting octave for tuning
  static int getDefaultStartingOctave(String root, List<String> tuning) {
    if (tuning.isEmpty) return AppConstants.defaultOctave;

    final rootPc = Note.fromString('${root}0').pitchClass;
    final lowestString = tuning
        .map((s) => Note.fromString(s))
        .reduce((a, b) => a.midi < b.midi ? a : b);

    // Find the first occurrence of root above lowest string
    var testNote = lowestString;
    while (testNote.pitchClass != rootPc) {
      testNote = testNote.transpose(1);
    }

    return testNote.octave;
  }

  /// Analyze a chord from notes
  static String? analyzeChord(List<Note> notes) {
    if (notes.isEmpty) return null;

    // Get unique pitch classes
    final pitchClasses = notes.map((n) => n.pitchClass).toSet().toList()
      ..sort();

    // Try each note as potential root
    for (final rootPc in pitchClasses) {
      final intervals =
          pitchClasses.map((pc) => (pc - rootPc + 12) % 12).toList()..sort();

      // Check against all chord types
      for (final entry in Chord.all.entries) {
        final chordIntervals = entry.value.intervals.map((i) => i % 12).toList()
          ..sort();
        if (_listsEqual(intervals, chordIntervals)) {
          final rootNote = Note(pitchClass: rootPc, octave: 0);
          return entry.value.getSymbol(rootNote.name);
        }
      }
    }

    return null;
  }

  static bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
