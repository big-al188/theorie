// lib/utils/music_utils.dart
import 'dart:math' as math;
import '../models/music/note.dart';
import '../models/music/scale.dart';
import '../constants/music_constants.dart';
import 'note_utils.dart';
import 'scale_utils.dart';
import 'chord_utils.dart';

/// General music theory utilities
class MusicUtils {
  /// Calculate semitones from frequency ratio
  static double semitonesFromFrequencyRatio(double ratio) {
    return 12 * math.log(ratio) / math.ln2;
  }

  /// Get frequency ratio from semitones
  static double frequencyRatioFromSemitones(double semitones) {
    return math.pow(2, semitones / 12).toDouble();
  }

  /// Calculate cents from frequency ratio
  static double centsFromFrequencyRatio(double ratio) {
    return 1200 * math.log(ratio) / math.ln2;
  }

  /// Get beat frequency between two frequencies
  static double getBeatFrequency(double freq1, double freq2) {
    return (freq1 - freq2).abs();
  }

  /// Calculate harmonic series
  static List<double> getHarmonicSeries(
      double fundamental, int numberOfHarmonics) {
    return List.generate(numberOfHarmonics, (i) => fundamental * (i + 1));
  }

  /// Get circle of fifths position
  static int getCircleOfFifthsPosition(String key) {
    final normalized = NoteUtils.nameFromPitchClass(
      NoteUtils.pitchClassFromName(key),
      preferFlats: NoteUtils.shouldUseFlats(key),
    );
    return MusicConstants.circleOfFifths.indexOf(normalized);
  }

  /// Calculate key signature
  static Map<String, dynamic> getKeySignature(String key) {
    final position = getCircleOfFifthsPosition(key);
    if (position == -1)
      return {'sharps': 0, 'flats': 0, 'accidentals': <String>[]};

    if (position <= 7) {
      // Sharp keys
      final sharps = position;
      final sharpOrder = ['F#', 'C#', 'G#', 'D#', 'A#', 'E#', 'B#'];
      return {
        'sharps': sharps,
        'flats': 0,
        'accidentals': sharps > 0 ? sharpOrder.sublist(0, sharps) : <String>[],
      };
    } else {
      // Flat keys
      final flats = 15 - position;
      final flatOrder = ['Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb', 'Fb'];
      return {
        'sharps': 0,
        'flats': flats,
        'accidentals': flats > 0 ? flatOrder.sublist(0, flats) : <String>[],
      };
    }
  }

  /// Generate chord progressions
  static List<List<String>> generateChordProgressions(
      String key, String scaleType, int length) {
    final scale = Scale.get(scaleType);
    if (scale == null) return [];

    final rootNote = Note.fromString('${key}3');
    final chordRoots = scale.intervals.map((interval) {
      final chordRootNote = rootNote.transpose(interval);
      return chordRootNote.name;
    }).toList();

    final progressions = <List<String>>[];
    _generateCombinations(chordRoots, length, [], progressions);

    return progressions;
  }

  static void _generateCombinations(
    List<String> options,
    int length,
    List<String> current,
    List<List<String>> results,
  ) {
    if (current.length == length) {
      results.add(List.from(current));
      return;
    }

    for (final option in options) {
      current.add(option);
      _generateCombinations(options, length, current, results);
      current.removeLast();
    }
  }

  /// Calculate string tension ratio
  static double getStringTensionRatio(String originalNote, String newNote) {
    final originalFreq = Note.fromString(originalNote).frequency;
    final newFreq = Note.fromString(newNote).frequency;

    // Tension is proportional to frequency squared
    return math.pow(newFreq / originalFreq, 2).toDouble();
  }

  /// Convert between tuning systems
  static double convertToEqualTemperament(
      double frequency, String tuningSystem) {
    switch (tuningSystem) {
      case 'just_intonation':
        // Simplified - would need full ratio tables
        return frequency;
      case 'pythagorean':
        // Simplified - would need full ratio tables
        return frequency;
      case 'well_tempered':
        // Simplified - would need full ratio tables
        return frequency;
      default:
        return frequency; // Already equal temperament
    }
  }

  /// Check if two notes form a consonant interval
  static bool isConsonantInterval(String note1, String note2,
      {double threshold = 0.5}) {
    final interval = NoteUtils.intervalInSemitones(note1, note2);
    return ChordUtils.isConsonantInterval(interval, threshold: threshold);
  }

  /// Get theoretical fret position
  static double calculateFretPosition(
      String openStringNote, String targetNote) {
    final openNote = Note.fromString(openStringNote);
    final target = Note.fromString(targetNote);
    final semitoneDifference = target.midi - openNote.midi;

    if (semitoneDifference < 0) return -1; // Target is lower than open string

    return semitoneDifference.toDouble();
  }

  /// Common chord progressions by genre
  static Map<String, List<List<String>>> commonProgressions = {
    'Pop': [
      ['I', 'V', 'vi', 'IV'], // 1-5-6-4
      ['I', 'vi', 'IV', 'V'], // 1-6-4-5
      ['vi', 'IV', 'I', 'V'], // 6-4-1-5
    ],
    'Jazz': [
      ['IIM7', 'V7', 'IM7'], // 2-5-1
      ['IM7', 'VIM7', 'IIM7', 'V7'], // 1-6-2-5
      ['IIIM7', 'VIM7', 'IIM7', 'V7'], // 3-6-2-5
    ],
    'Blues': [
      ['I7', 'I7', 'I7', 'I7'],
      ['IV7', 'IV7', 'I7', 'I7'],
      ['V7', 'IV7', 'I7', 'V7'],
    ],
    'Rock': [
      ['I', 'IV', 'V'], // 1-4-5
      ['I', 'bVII', 'IV', 'I'], // 1-b7-4-1
      ['I', 'V', 'bVII', 'IV'], // 1-5-b7-4
    ],
  };

  /// Get Roman numeral for scale degree
  static String getRomanNumeral(int degree, bool isMajor) {
    const majorNumerals = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'];
    const minorNumerals = ['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII'];

    final numerals = isMajor ? majorNumerals : minorNumerals;
    return numerals[degree % numerals.length];
  }

  /// Transpose a chord progression
  static List<String> transposeProgression(
    List<String> progression,
    String fromKey,
    String toKey,
  ) {
    final interval = NoteUtils.intervalInSemitones(fromKey, toKey);

    return progression.map((chord) {
      // Extract root from chord symbol
      final match = RegExp(r'^([A-G][#b]?)(.*)$').firstMatch(chord);
      if (match == null) return chord;

      final root = match.group(1)!;
      final suffix = match.group(2)!;

      final transposedRoot = NoteUtils.transposeNoteName(
        root,
        interval,
        preferFlats: NoteUtils.shouldUseFlats(toKey),
      );

      return '$transposedRoot$suffix';
    }).toList();
  }
}
