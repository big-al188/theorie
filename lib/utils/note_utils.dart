// lib/utils/note_utils.dart
import 'dart:math' as math;
import '../models/music/note.dart';
import '../constants/music_constants.dart';

/// Utility functions for note operations
class NoteUtils {
  /// Parse note name to pitch class
  static int pitchClassFromName(String noteName) {
    var normalized = noteName.trim().replaceAll('♭', 'b').replaceAll('♯', '#');

    const noteMap = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
      'C#': 1,
      'D#': 3,
      'F#': 6,
      'G#': 8,
      'A#': 10,
      'Db': 1,
      'Eb': 3,
      'Gb': 6,
      'Ab': 8,
      'Bb': 10,
      'Cb': 11,
      'Fb': 4,
      'E#': 5,
      'B#': 0,
    };

    final pc = noteMap[normalized];
    if (pc != null) return pc;

    // Try case-insensitive
    for (final entry in noteMap.entries) {
      if (entry.key.toLowerCase() == normalized.toLowerCase()) {
        return entry.value;
      }
    }

    throw FormatException('Invalid note name: $noteName');
  }

  /// Get note name from pitch class
  static String nameFromPitchClass(int pitchClass, {bool preferFlats = false}) {
    final pc = pitchClass % 12;
    final names = preferFlats
        ? MusicConstants.flatNoteNames
        : MusicConstants.sharpNoteNames;
    return names[pc];
  }

  /// Convert MIDI to frequency
  static double frequencyFromMidi(int midi) {
    final semitonesFromA4 = midi - MusicConstants.a440Midi;
    return MusicConstants.a440Hz * math.pow(2, semitonesFromA4 / 12.0);
  }

  /// Convert frequency to MIDI
  static int midiFromFrequency(double frequency) {
    return (MusicConstants.a440Midi +
            12 * math.log(frequency / MusicConstants.a440Hz) / math.ln2)
        .round();
  }

  /// Get chromatic sequence from root
  static List<String> chromaticSequence(String root) {
    final rootNote = Note.fromString('${root}0');
    final useFlats = rootNote.preferFlats;
    final noteArray =
        useFlats ? MusicConstants.flatNoteNames : MusicConstants.sharpNoteNames;
    final rootPc = rootNote.pitchClass;

    return List.generate(12, (i) => noteArray[(rootPc + i) % 12]);
  }

  /// Calculate interval in semitones
  static int intervalInSemitones(String note1, String note2) {
    final pc1 = pitchClassFromName(note1);
    final pc2 = pitchClassFromName(note2);
    return (pc2 - pc1 + 12) % 12;
  }

  /// Get interval name
  static String intervalName(int semitones) {
    return MusicConstants.intervalNames[semitones % 12];
  }

  /// Transpose note name by semitones
  static String transposeNoteName(String noteName, int semitones,
      {bool? preferFlats}) {
    final pc = pitchClassFromName(noteName);
    final newPc = (pc + semitones) % 12;
    final useFlats = preferFlats ?? MusicConstants.flatRoots.contains(noteName);
    return nameFromPitchClass(newPc, preferFlats: useFlats);
  }

  /// Get enharmonic spellings
  static List<String> getEnharmonicSpellings(int pitchClass) {
    return [
      nameFromPitchClass(pitchClass, preferFlats: false),
      nameFromPitchClass(pitchClass, preferFlats: true),
    ].toSet().toList();
  }

  /// Calculate cents deviation between frequencies
  static double centsFromFrequencyRatio(double ratio) {
    return 1200 * math.log(ratio) / math.ln2;
  }

  /// Get frequency ratio from cents
  static double frequencyRatioFromCents(double cents) {
    return math.pow(2, cents / 1200).toDouble();
  }

  /// Round frequency to nearest cent
  static double roundToCents(double frequency, int cents) {
    final semitones =
        12 * math.log(frequency / MusicConstants.a440Hz) / math.ln2;
    final roundedSemitones =
        (semitones * (1200 / cents)).round() * (cents / 1200);
    return MusicConstants.a440Hz * math.pow(2, roundedSemitones);
  }

  /// Determine if a root should use flat accidentals
  static bool shouldUseFlats(String root) {
    final normalized = _normalizeNoteName(root);
    return MusicConstants.flatRoots.contains(normalized);
  }

  /// Normalize note name for consistent spelling
  static String _normalizeNoteName(String noteName) {
    var result = noteName.trim();

    // Remove octave numbers - FIX: Add missing closing quote
    result = result.replaceAll(RegExp(r'\d+'), '');

    // Normalize flat and sharp symbols
    result = result.replaceAll('♯', '#').replaceAll('♭', 'b');

    // Ensure proper capitalization
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    return result;
  }
}
