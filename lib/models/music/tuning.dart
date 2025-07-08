// lib/models/music/tuning.dart
import 'note.dart';
import '../../constants/music_constants.dart';

/// Represents an instrument tuning
class Tuning {
  final String name;
  final List<String> strings;
  final InstrumentType instrumentType;

  const Tuning({
    required this.name,
    required this.strings,
    required this.instrumentType,
  });

  /// Get all standard tunings
  static Map<String, Tuning> get all {
    final Map<String, Tuning> tunings = {};

    MusicConstants.standardTunings.forEach((name, strings) {
      tunings[name] = Tuning(
        name: name,
        strings: strings,
        instrumentType: _getInstrumentType(name),
      );
    });

    return tunings;
  }

  /// Get tunings for a specific instrument type
  static Map<String, Tuning> forInstrument(InstrumentType type) {
    return Map.fromEntries(
      all.entries.where((entry) => entry.value.instrumentType == type),
    );
  }

  /// Number of strings
  int get stringCount => strings.length;

  /// Get notes for all strings
  List<Note> get stringNotes {
    return strings.map((s) => Note.fromString(s)).toList();
  }

  /// Get MIDI values for all strings
  List<int> get stringMidis {
    return stringNotes.map((n) => n.midi).toList();
  }

  /// Get the lowest note in the tuning
  Note get lowestNote {
    final notes = stringNotes;
    notes.sort((a, b) => a.midi.compareTo(b.midi));
    return notes.first;
  }

  /// Get the highest note in the tuning
  Note get highestNote {
    final notes = stringNotes;
    notes.sort((a, b) => a.midi.compareTo(b.midi));
    return notes.last;
  }

  /// Get the range in semitones
  int get range => highestNote.midi - lowestNote.midi;

  /// Check if a note is playable on a string within fret range
  bool canPlayNote(Note note, int maxFrets) {
    for (final stringNote in stringNotes) {
      final fretNumber = note.midi - stringNote.midi;
      if (fretNumber >= 0 && fretNumber <= maxFrets) {
        return true;
      }
    }
    return false;
  }

  /// Find all positions where a note can be played
  List<FretPosition> findNotePositions(Note note, int maxFrets) {
    final positions = <FretPosition>[];

    for (int stringIndex = 0; stringIndex < strings.length; stringIndex++) {
      final stringMidi = stringNotes[stringIndex].midi;
      final fretNumber = note.midi - stringMidi;

      if (fretNumber >= 0 && fretNumber <= maxFrets) {
        positions.add(FretPosition(
          stringIndex: stringIndex,
          fretNumber: fretNumber,
          note: note,
        ));
      }
    }

    return positions;
  }

  /// Create a custom tuning from the current one
  Tuning transpose(int semitones) {
    final transposedStrings =
        stringNotes.map((note) => note.transpose(semitones).fullName).toList();

    return Tuning(
      name: '$name (${semitones > 0 ? '+' : ''}$semitones)',
      strings: transposedStrings,
      instrumentType: instrumentType,
    );
  }

  /// Compare tunings
  bool equals(List<String> otherStrings) {
    if (strings.length != otherStrings.length) return false;

    for (int i = 0; i < strings.length; i++) {
      if (strings[i] != otherStrings[i]) return false;
    }

    return true;
  }

  @override
  String toString() => name;

  /// Determine instrument type from tuning name
  static InstrumentType _getInstrumentType(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('bass')) {
      return InstrumentType.bass;
    } else if (lowerName.contains('ukulele')) {
      return InstrumentType.ukulele;
    } else if (lowerName.contains('mandolin')) {
      return InstrumentType.mandolin;
    } else if (lowerName.contains('banjo')) {
      return InstrumentType.banjo;
    } else {
      return InstrumentType.guitar;
    }
  }
}

/// Instrument types
enum InstrumentType {
  guitar('Guitar'),
  bass('Bass'),
  ukulele('Ukulele'),
  mandolin('Mandolin'),
  banjo('Banjo');

  const InstrumentType(this.displayName);
  final String displayName;
}

/// Represents a position on the fretboard
class FretPosition {
  final int stringIndex;
  final int fretNumber;
  final Note note;

  const FretPosition({
    required this.stringIndex,
    required this.fretNumber,
    required this.note,
  });

  /// Get MIDI value
  int get midi => note.midi;

  /// Get note name
  String get noteName => note.fullName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FretPosition &&
          runtimeType == other.runtimeType &&
          stringIndex == other.stringIndex &&
          fretNumber == other.fretNumber;

  @override
  int get hashCode => stringIndex.hashCode ^ fretNumber.hashCode;

  @override
  String toString() => 'String $stringIndex, Fret $fretNumber ($noteName)';
}
