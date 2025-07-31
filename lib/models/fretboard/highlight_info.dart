// lib/models/fretboard/highlight_info.dart
import 'package:flutter/material.dart';

/// Types of note highlighting on the fretboard
enum HighlightType {
  /// Primary highlights - the main chord/scale notes in selected octaves
  primary,
  /// Additional octave highlights - chord notes in other octaves (white circles)
  additionalOctave,
}

/// Information about a highlighted note on the fretboard
class HighlightInfo {
  /// MIDI note number
  final int midi;
  
  /// Type of highlight
  final HighlightType type;
  
  /// Color for the highlight (null for additionalOctave type which uses white)
  final Color? color;
  
  /// Note class (C, D, E, F, G, A, B) - used for matching across octaves
  final String noteClass;

  const HighlightInfo({
    required this.midi,
    required this.type,
    this.color,
    required this.noteClass,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightInfo &&
          runtimeType == other.runtimeType &&
          midi == other.midi &&
          type == other.type &&
          color == other.color &&
          noteClass == other.noteClass;

  @override
  int get hashCode =>
      midi.hashCode ^
      type.hashCode ^
      color.hashCode ^
      noteClass.hashCode;

  @override
  String toString() {
    return 'HighlightInfo{midi: $midi, type: $type, color: $color, noteClass: $noteClass}';
  }
}

/// Combined highlight maps for rendering both primary and additional highlights
class CombinedHighlightMap {
  /// Primary highlights (colored circles for main chord/scale notes)
  final Map<int, Color> primary;
  
  /// Additional octave highlights (white circles for chord notes in other octaves)
  final Map<int, HighlightInfo> additional;

  const CombinedHighlightMap({
    required this.primary,
    required this.additional,
  });

  /// Check if a MIDI note has any type of highlighting
  bool hasHighlight(int midi) {
    return primary.containsKey(midi) || additional.containsKey(midi);
  }

  /// Get the total number of highlighted notes
  int get totalHighlights => primary.length + additional.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombinedHighlightMap &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          additional == other.additional;

  @override
  int get hashCode => primary.hashCode ^ additional.hashCode;

  @override
  String toString() {
    return 'CombinedHighlightMap{primary: ${primary.length} notes, additional: ${additional.length} notes}';
  }
}