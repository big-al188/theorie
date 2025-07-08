// lib/models/fretboard/fret_position.dart
import '../music/note.dart';

/// Extended fret position with additional metadata
class FretPositionEx {
  final int stringIndex;
  final int fretNumber;
  final int midiNote;
  final String noteName;

  const FretPositionEx({
    required this.stringIndex,
    required this.fretNumber,
    required this.midiNote,
    required this.noteName,
  });

  /// Create from note
  factory FretPositionEx.fromNote({
    required int stringIndex,
    required int fretNumber,
    required Note note,
  }) {
    return FretPositionEx(
      stringIndex: stringIndex,
      fretNumber: fretNumber,
      midiNote: note.midi,
      noteName: note.fullName,
    );
  }

  @override
  String toString() =>
      'FretPosition(string: $stringIndex, fret: $fretNumber, midi: $midiNote, note: $noteName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FretPositionEx &&
          runtimeType == other.runtimeType &&
          stringIndex == other.stringIndex &&
          fretNumber == other.fretNumber;

  @override
  int get hashCode => stringIndex.hashCode ^ fretNumber.hashCode;
}

/// Represents a chord tone on the fretboard
class ChordTone {
  final FretPositionEx position;
  final int intervalFromRoot;
  final String intervalName;
  final bool isRoot;
  final int chordToneIndex;
  final int voicingPosition;

  const ChordTone({
    required this.position,
    required this.intervalFromRoot,
    required this.intervalName,
    required this.isRoot,
    required this.chordToneIndex,
    required this.voicingPosition,
  });

  /// Convenience getters
  int get midiNote => position.midiNote;
  int get stringIndex => position.stringIndex;
  int get fretNumber => position.fretNumber;
  String get noteName => position.noteName;

  @override
  String toString() =>
      'ChordTone(${position.toString()}, interval: $intervalName ($intervalFromRoot), voicing pos: $voicingPosition)';
}
