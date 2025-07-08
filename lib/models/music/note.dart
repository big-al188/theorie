// lib/models/music/note.dart
import 'dart:math' as math;
import '../../constants/music_constants.dart';

/// Represents a musical note with pitch class and octave
class Note {
  final int pitchClass; // 0-11
  final int octave;
  final bool preferFlats;

  const Note({
    required this.pitchClass,
    required this.octave,
    this.preferFlats = false,
  });

  /// Create a Note from a string like "C4" or "Bb3" or just "C#"
  factory Note.fromString(String noteString) {
    // Clean the input
    final cleaned = noteString.trim();
    
    // Check if it has an octave number
    final hasOctave = RegExp(r'\d$').hasMatch(cleaned);
    
    if (!hasOctave) {
      // Just a note name without octave - parse it and assume octave 3
      final pitchClass = _pitchClassFromName(cleaned);
      final preferFlats = MusicConstants.flatRoots.contains(cleaned);
      return Note(
        pitchClass: pitchClass,
        octave: 3, // Default octave
        preferFlats: preferFlats,
      );
    }
    
    // Has octave - parse normally
    final match = RegExp(r'^([A-G](?:#|b|♯|♭)?)(\d+)$').firstMatch(cleaned);

    if (match == null) {
      throw FormatException('Invalid note format: $noteString');
    }

    final noteName = match.group(1)!;
    final octave = int.parse(match.group(2)!);
    final pitchClass = _pitchClassFromName(noteName);
    final preferFlats = MusicConstants.flatRoots.contains(noteName);

    return Note(
      pitchClass: pitchClass,
      octave: octave,
      preferFlats: preferFlats,
    );
  }

  /// Create a Note from MIDI number
  factory Note.fromMidi(int midi, {bool preferFlats = false}) {
    final pitchClass = midi % 12;
    final octave = (midi ~/ 12) - 1;

    return Note(
      pitchClass: pitchClass,
      octave: octave,
      preferFlats: preferFlats,
    );
  }

  /// Get the note name (without octave)
  String get name {
    final names = preferFlats
        ? MusicConstants.flatNoteNames
        : MusicConstants.sharpNoteNames;
    return names[pitchClass];
  }

  /// Get the full note name with octave
  String get fullName => '$name$octave';

  /// Convert to MIDI number
  int get midi => (octave + 1) * 12 + pitchClass;

  /// Get frequency in Hz (A4 = 440Hz)
  double get frequency {
    final semitonesFromA4 = midi - MusicConstants.a440Midi;
    return MusicConstants.a440Hz * math.pow(2, semitonesFromA4 / 12.0);
  }

  /// Get chromatic octave (octave changes at C)
  int get chromaticOctave => (midi - 12) ~/ 12;

  /// Transpose by semitones
  Note transpose(int semitones) {
    return Note.fromMidi(midi + semitones, preferFlats: preferFlats);
  }

  /// Get enharmonic equivalent
  Note get enharmonic => Note(
        pitchClass: pitchClass,
        octave: octave,
        preferFlats: !preferFlats,
      );

  /// Calculate interval to another note in semitones
  int intervalTo(Note other) => (other.midi - midi).abs();

  /// Check if this note is in a given scale
  bool inScale(int rootPitchClass, List<int> scaleIntervals) {
    final intervalFromRoot = (pitchClass - rootPitchClass + 12) % 12;
    return scaleIntervals.contains(intervalFromRoot);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          pitchClass == other.pitchClass &&
          octave == other.octave;

  @override
  int get hashCode => pitchClass.hashCode ^ octave.hashCode;

  @override
  String toString() => fullName;

  /// Convert note name to pitch class
  static int _pitchClassFromName(String noteName) {
    // Normalize the input
    var normalized = noteName.trim();
    
    // Replace unicode sharp/flat symbols with standard ones
    normalized = normalized.replaceAll('♭', 'b').replaceAll('♯', '#');
    
    // Ensure first letter is uppercase
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }

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
    if (pc == null) {
      throw FormatException('Invalid note name: $noteName (normalized: $normalized)');
    }

    return pc;
  }
}