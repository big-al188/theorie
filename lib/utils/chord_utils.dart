// lib/utils/chord_utils.dart
import '../models/music/note.dart';
import '../models/music/chord.dart';
import '../models/music/tuning.dart';
import '../models/fretboard/fret_position.dart';
import 'note_utils.dart';

/// Utility functions for chord operations
class ChordUtils {
  /// Get interval label for display
  static String getIntervalLabel(int interval) {
    const intervalLabels = [
      'R',
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
    return intervalLabels[interval % 12];
  }

  /// Get extended interval label
  static String getExtendedIntervalLabel(int degree) {
    const baseIntervals = [
      'R',
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
    final octave = degree ~/ 12;
    final step = degree % 12;

    if (octave == 0) return baseIntervals[step];
    if (step == 0) return 'O$octave';

    final raw = baseIntervals[step];
    final match = RegExp(r'([♭]?)(\d+)').firstMatch(raw);

    if (match != null) {
      final accidental = match.group(1) ?? '';
      final baseNumber = int.parse(match.group(2)!);
      final extendedNumber = baseNumber + (octave * 7);
      return '$accidental$extendedNumber';
    }

    return raw;
  }

  /// Build chord notes for a root
  static List<String> buildChord(String root, String chordType,
      {bool? preferFlats}) {
    final chord = Chord.get(chordType);
    if (chord == null) return [root];

    final rootPc = NoteUtils.pitchClassFromName(root);
    final useFlats = preferFlats ?? NoteUtils.shouldUseFlats(root);

    return chord.intervals.map((interval) {
      final notePc = (rootPc + interval) % 12;
      return NoteUtils.nameFromPitchClass(notePc, preferFlats: useFlats);
    }).toList();
  }

  /// Get chord voicing notes
  static List<String> getChordVoicingNotes({
    required String root,
    required int octave,
    required String chordType,
    required ChordInversion inversion,
  }) {
    final chord = Chord.get(chordType);
    if (chord == null) return [];

    final rootNote = Note.fromString('$root$octave');
    final midiNotes = chord.buildVoicing(
      root: rootNote,
      inversion: inversion,
    );

    return midiNotes
        .map((midi) =>
            Note.fromMidi(midi, preferFlats: rootNote.preferFlats).fullName)
        .toList();
  }

  /// Analyze chord from notes
  static String? analyzeChord(List<String> notes) {
    if (notes.isEmpty) return null;

    // Get unique pitch classes
    final pitchClasses =
        notes.map(NoteUtils.pitchClassFromName).toSet().toList()..sort();

    // Try each note as potential root
    for (final rootPc in pitchClasses) {
      final intervals =
          pitchClasses.map((pc) => (pc - rootPc + 12) % 12).toList()..sort();

      // Check against all chord types
      for (final entry in Chord.all.entries) {
        final chordIntervals = entry.value.intervals.map((i) => i % 12).toList()
          ..sort();
        if (_listsEqual(intervals, chordIntervals)) {
          final rootName = NoteUtils.nameFromPitchClass(rootPc);
          return entry.value.getSymbol(rootName);
        }
      }
    }

    return null;
  }

  /// Get consonance value of an interval
  static double getConsonanceValue(int semitones) {
    const consonanceMap = {
      0: 1.0, // Unison
      12: 1.0, // Octave
      7: 0.9, // Perfect 5th
      5: 0.8, // Perfect 4th
      4: 0.7, // Major 3rd
      3: 0.65, // Minor 3rd
      9: 0.6, // Major 6th
      8: 0.55, // Minor 6th
      2: 0.4, // Major 2nd
      10: 0.35, // Minor 7th
      11: 0.3, // Major 7th
      1: 0.2, // Minor 2nd
      6: 0.1, // Tritone
    };

    return consonanceMap[semitones % 12] ?? 0.0;
  }

  /// Check if interval is consonant
  static bool isConsonantInterval(int semitones, {double threshold = 0.5}) {
    return getConsonanceValue(semitones) >= threshold;
  }

  /// Get positions for chord tones by voicing position
  static List<ChordTone> getPositionsForVoicingNote(
    List<ChordTone> allTones,
    int voicingPosition,
  ) {
    return allTones
        .where((tone) => tone.voicingPosition == voicingPosition)
        .toList();
  }

  /// Generate all possible chord voicings within constraints
  static List<List<ChordTone>> generateAllVoicings({
    required List<ChordTone> allPositions,
    int maxStretch = 5,
  }) {
    if (allPositions.isEmpty) return [];

    // Group by voicing position
    final positionGroups = <int, List<ChordTone>>{};
    for (final tone in allPositions) {
      positionGroups.putIfAbsent(tone.voicingPosition, () => []).add(tone);
    }

    // Generate combinations
    final voicings = <List<ChordTone>>[];
    _generateVoicingCombinations(
      positionGroups: positionGroups,
      currentVoicing: [],
      allVoicings: voicings,
      maxStretch: maxStretch,
    );

    return voicings;
  }

  static void _generateVoicingCombinations({
    required Map<int, List<ChordTone>> positionGroups,
    required List<ChordTone> currentVoicing,
    required List<List<ChordTone>> allVoicings,
    required int maxStretch,
  }) {
    if (currentVoicing.length == positionGroups.length) {
      // Check stretch constraint
      final frets = currentVoicing
          .where((t) => t.fretNumber > 0)
          .map((t) => t.fretNumber)
          .toList();
      if (frets.isNotEmpty) {
        final span = frets.reduce((a, b) => a > b ? a : b) -
            frets.reduce((a, b) => a < b ? a : b);
        if (span <= maxStretch) {
          allVoicings.add(List.from(currentVoicing));
        }
      }
      return;
    }

    final nextPosition = currentVoicing.length;
    final options = positionGroups[nextPosition] ?? [];

    for (final option in options) {
      // Check if string already used
      if (currentVoicing.any((t) => t.stringIndex == option.stringIndex)) {
        continue;
      }

      currentVoicing.add(option);
      _generateVoicingCombinations(
        positionGroups: positionGroups,
        currentVoicing: currentVoicing,
        allVoicings: allVoicings,
        maxStretch: maxStretch,
      );
      currentVoicing.removeLast();
    }
  }

  /// Rank voicings by playability
  static List<List<ChordTone>> rankVoicings(List<List<ChordTone>> voicings) {
    final scored = voicings.map((voicing) {
      int score = 0;

      // Calculate fret span
      final frets = voicing
          .where((t) => t.fretNumber > 0)
          .map((t) => t.fretNumber)
          .toList();
      if (frets.isNotEmpty) {
        final span = frets.reduce((a, b) => a > b ? a : b) -
            frets.reduce((a, b) => a < b ? a : b);
        score += span * 2;
      }

      // Prefer lower positions
      final avgFret = voicing.map((t) => t.fretNumber).reduce((a, b) => a + b) /
          voicing.length;
      score += avgFret.round();

      // Prefer fewer muted strings
      final mutedCount = 6 - voicing.length;
      score += mutedCount * 3;

      return {'voicing': voicing, 'score': score};
    }).toList();

    scored.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));

    return scored.map((item) => item['voicing'] as List<ChordTone>).toList();
  }

  static bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Extension on String for chord utils
extension ChordStringExtension on String {
  bool get shouldUseFlats => NoteUtils.shouldUseFlats(this);
}
