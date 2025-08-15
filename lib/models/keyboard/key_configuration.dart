// lib/models/keyboard/key_configuration.dart
import 'package:flutter/material.dart';
import '../music/note.dart';

/// Configuration for individual piano keys
/// This model represents the properties of each key on the keyboard
class KeyConfiguration {
  final int keyIndex; // 0-based index from start of keyboard
  final int midiNote; // MIDI note number
  final String noteName; // Note name (e.g., "C", "F#", "Bb")
  final int octave; // Octave number
  final bool isWhiteKey; // true for white keys, false for black keys
  final bool isHighlighted; // Whether this key should be highlighted
  final Color? highlightColor; // Color for highlighting
  final bool isPressed; // Whether this key is currently pressed (for interaction)
  final String? intervalLabel; // Interval label (e.g., "R", "3", "5")

  const KeyConfiguration({
    required this.keyIndex,
    required this.midiNote,
    required this.noteName,
    required this.octave,
    required this.isWhiteKey,
    this.isHighlighted = false,
    this.highlightColor,
    this.isPressed = false,
    this.intervalLabel,
  });

  /// Create a KeyConfiguration from a MIDI note number and keyboard start
  factory KeyConfiguration.fromMidiNote({
    required int keyIndex,
    required int midiNote,
    bool isHighlighted = false,
    Color? highlightColor,
    bool isPressed = false,
    String? intervalLabel,
  }) {
    final note = Note.fromMidi(midiNote);
    final isWhiteKey = _isWhiteKey(midiNote);

    return KeyConfiguration(
      keyIndex: keyIndex,
      midiNote: midiNote,
      noteName: note.name,
      octave: note.octave,
      isWhiteKey: isWhiteKey,
      isHighlighted: isHighlighted,
      highlightColor: highlightColor,
      isPressed: isPressed,
      intervalLabel: intervalLabel,
    );
  }

  /// Create a highlighted version of this key
  KeyConfiguration withHighlight({
    required bool isHighlighted,
    Color? highlightColor,
    String? intervalLabel,
  }) {
    return KeyConfiguration(
      keyIndex: keyIndex,
      midiNote: midiNote,
      noteName: noteName,
      octave: octave,
      isWhiteKey: isWhiteKey,
      isHighlighted: isHighlighted,
      highlightColor: highlightColor,
      isPressed: isPressed,
      intervalLabel: intervalLabel,
    );
  }

  /// Create a pressed version of this key
  KeyConfiguration withPressed(bool isPressed) {
    return KeyConfiguration(
      keyIndex: keyIndex,
      midiNote: midiNote,
      noteName: noteName,
      octave: octave,
      isWhiteKey: isWhiteKey,
      isHighlighted: isHighlighted,
      highlightColor: highlightColor,
      isPressed: isPressed,
      intervalLabel: intervalLabel,
    );
  }

  /// Get the full note name with octave
  String get fullNoteName => '$noteName$octave';

  /// Get display name for the key (may include accidentals)
  String get displayName {
    if (intervalLabel != null) {
      return intervalLabel!;
    }
    return noteName;
  }

  /// Helper method to determine if a MIDI note is a white key
  static bool _isWhiteKey(int midiNote) {
    final semitone = midiNote % 12;
    // White keys: C, D, E, F, G, A, B (semitones 0, 2, 4, 5, 7, 9, 11)
    return [0, 2, 4, 5, 7, 9, 11].contains(semitone);
  }

  /// Get the visual position of this key within an octave for black keys
  /// Returns a value between 0.0 and 7.0 representing position relative to white keys
  /// Uses improved positioning for proper visual grouping
  double? getBlackKeyVisualPosition() {
    if (isWhiteKey) return null;
    
    final semitone = midiNote % 12;
    switch (semitone) {
      case 1:  // C# - first group
        return 0.65;
      case 3:  // D# - first group
        return 1.35;
      case 6:  // F# - second group
        return 3.65;
      case 8:  // G# - second group, closer to G
        return 4.25;
      case 10: // A# - second group, closer to A
        return 4.9;
      default:
        return null;
    }
  }

  /// Get the white key index within an octave (0-6 for C,D,E,F,G,A,B)
  int? getWhiteKeyIndexInOctave() {
    if (!isWhiteKey) return null;
    
    final semitone = midiNote % 12;
    switch (semitone) {
      case 0:  // C
        return 0;
      case 2:  // D
        return 1;
      case 4:  // E
        return 2;
      case 5:  // F
        return 3;
      case 7:  // G
        return 4;
      case 9:  // A
        return 5;
      case 11: // B
        return 6;
      default:
        return null;
    }
  }

  /// Check if this black key is in the first group (C#, D#)
  bool get isFirstBlackKeyGroup {
    if (isWhiteKey) return false;
    final semitone = midiNote % 12;
    return semitone == 1 || semitone == 3;
  }

  /// Check if this black key is in the second group (F#, G#, A#)
  bool get isSecondBlackKeyGroup {
    if (isWhiteKey) return false;
    final semitone = midiNote % 12;
    return semitone == 6 || semitone == 8 || semitone == 10;
  }

  @override
  String toString() {
    return 'KeyConfiguration(keyIndex: $keyIndex, midiNote: $midiNote, '
           'noteName: $noteName, octave: $octave, isWhiteKey: $isWhiteKey, '
           'isHighlighted: $isHighlighted, intervalLabel: $intervalLabel)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyConfiguration &&
          runtimeType == other.runtimeType &&
          keyIndex == other.keyIndex &&
          midiNote == other.midiNote;

  @override
  int get hashCode => keyIndex.hashCode ^ midiNote.hashCode;
}