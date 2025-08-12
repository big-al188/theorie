// test/notes_test.dart – extended unit tests for lib/theory/note.dart
// -----------------------------------------------------------------------------
// Run with:   flutter test  (or dart test)
// -----------------------------------------------------------------------------
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';

void main() {
  group('Note basics', () {
    test('C4 fundamentals', () {
      final c4 = Note.fromString('C4');
      expect(c4.name, 'C');
      expect(c4.octave, 4);
      expect(c4.pitchClass, 0);
      expect(c4.midi, 60);
    });

    test('A4 has MIDI note 69', () {
      final a4 = Note.fromMidi(69);
      expect(a4.name, 'A');
      expect(a4.octave, 4);
      expect(a4.midi, 69);
    });

    test('Enharmonic equivalence F#3 ≡ Gb3', () {
      final fs = Note.fromString('F#3');
      final gb = Note.fromString('Gb3');
      expect(fs.midi, equals(gb.midi));
      expect(fs.pitchClass, equals(gb.pitchClass));
    });

    test('Pitch class calculation works', () {
      final cSharp = Note.fromMidi(61); // C#4
      final dFlat = Note.fromMidi(61);  // Also C#4/Db4
      expect(cSharp.pitchClass, 1);
      expect(dFlat.pitchClass, 1);
    });
  });

  group('Boundary values', () {
    test('Lowest supported note C-1 (MIDI 0)', () {
      final cNeg1 = Note.fromMidi(0);
      expect(cNeg1.octave, -1);
      expect(cNeg1.name, 'C');
    });

    test('Highest supported note G9 (MIDI 127)', () {
      final g9 = Note.fromMidi(127);
      expect(g9.octave, 9);
      expect(g9.name, 'G');
    });
  });

  group('Parsing validation', () {
    test('Handles valid note strings', () {
      final note = Note.fromString('C4');
      expect(note.name, 'C');
      expect(note.octave, 4);
    });

    test('Handles sharps and flats', () {
      final sharp = Note.fromString('F#3');
      final flat = Note.fromString('Bb4');
      expect(sharp.name, 'F♯');
      expect(flat.name, 'B♭');
    });

    test('Handles notes without octave (defaults to octave 3)', () {
      final c = Note.fromString('C');
      expect(c.name, 'C');
      expect(c.octave, 3);
      expect(c.preferFlats, false);

      final bb = Note.fromString('Bb');
      expect(bb.name, 'B♭');
      expect(bb.octave, 3);
      expect(bb.preferFlats, true);
    });
  });

  group('Advanced Note Properties', () {
    test('Full name includes octave', () {
      final c4 = Note.fromString('C4');
      final fs3 = Note.fromString('F#3');
      expect(c4.fullName, 'C4');
      expect(fs3.fullName, 'F♯3');
    });

    test('Frequency calculation (A4 = 440Hz)', () {
      final a4 = Note.fromMidi(69);
      expect(a4.frequency, closeTo(440.0, 1e-9));
      
      final c4 = Note.fromMidi(60);
      expect(c4.frequency, closeTo(261.6256, 1e-3));
    });

    test('Chromatic octave calculation', () {
      final c4 = Note.fromMidi(60); // MIDI 60 = C4, chromaticOctave = (60-12)/12 = 4
      final c5 = Note.fromMidi(72); // MIDI 72 = C5, chromaticOctave = (72-12)/12 = 5
      expect(c4.chromaticOctave, 4);
      expect(c5.chromaticOctave, 5);
    });

    test('Enharmonic equivalents', () {
      final cs4 = Note.fromString('C#4');
      final enharmonic = cs4.enharmonic;
      expect(enharmonic.name, 'D♭');
      expect(enharmonic.octave, 4);
      expect(enharmonic.pitchClass, cs4.pitchClass);
      expect(enharmonic.preferFlats, !cs4.preferFlats);
    });

    test('Interval calculation to other notes', () {
      final c4 = Note.fromString('C4');
      final g4 = Note.fromString('G4');
      final c5 = Note.fromString('C5');
      
      expect(c4.intervalTo(g4), 7);
      expect(c4.intervalTo(c5), 12);
      expect(g4.intervalTo(c4), 7); // absolute value
    });

    test('Scale membership checking', () {
      final c4 = Note.fromString('C4');
      final d4 = Note.fromString('D4');
      final cs4 = Note.fromString('C#4');
      
      const majorScale = [0, 2, 4, 5, 7, 9, 11];
      
      expect(c4.inScale(0, majorScale), isTrue); // C in C major
      expect(d4.inScale(0, majorScale), isTrue); // D in C major
      expect(cs4.inScale(0, majorScale), isFalse); // C# not in C major
    });
  });

  group('Object Equality and String Representation', () {
    test('Equality based on pitch class and octave', () {
      final c4a = Note.fromString('C4');
      final c4b = Note.fromMidi(60);
      final c5 = Note.fromString('C5');
      
      expect(c4a == c4b, isTrue);
      expect(c4a == c5, isFalse);
      expect(c4a.hashCode, equals(c4b.hashCode));
    });

    test('String representation shows full name', () {
      final c4 = Note.fromString('C4');
      final bb3 = Note.fromString('Bb3');
      
      expect(c4.toString(), 'C4');
      expect(bb3.toString(), 'B♭3');
    });
  });
}