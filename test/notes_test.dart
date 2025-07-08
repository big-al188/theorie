// test/notes_test.dart – extended unit tests for lib/theory/note.dart
// -----------------------------------------------------------------------------
// Run with:   flutter test  (or dart test)
// -----------------------------------------------------------------------------
import 'package:flutter_test/flutter_test.dart';
import 'package:theorie/theory/note.dart';

void main() {
  group('Note basics', () {
    test('C4 fundamentals', () {
      final c4 = Note.parse('C4');
      expect(c4.label, 'C');
      expect(c4.octave, 4);
      expect(c4.pc, 0);
      expect(c4.midi, 60);
      expect(c4.freq, closeTo(261.6256, 1e-3));
    });

    test('A4 has frequency of exactly 440 Hz', () {
      final a4 = Note.fromMidi(69);
      expect(a4.freq, closeTo(440, 1e-9));
      expect(a4.label, 'A');
      expect(a4.octave, 4);
    });

    test('Enharmonic equivalence F#3 ≡ Gb3', () {
      final fs = Note.parse('F#3');
      final gb = Note.parse('Gb3');
      expect(fs.midi, equals(gb.midi));
      expect(fs, equals(gb));
    });

    test('Accidental preference influences spelling', () {
      final cSharp = Note.fromMidi(61, pref: AccidentalPreference.sharp);
      final dFlat  = Note.fromMidi(61, pref: AccidentalPreference.flat);
      expect(cSharp.label, 'C♯');
      expect(dFlat.label,  'D♭');
    });
  });

  group('Boundary values', () {
    test('Lowest supported note C-1 (MIDI 0)', () {
      final cNeg1 = Note.fromMidi(0);
      expect(cNeg1.octave, -1);
      expect(cNeg1.label, 'C');
      expect(cNeg1.freq, closeTo(8.1758, 1e-4));
    });

    test('Highest supported note G9 (MIDI 127)', () {
      final g9 = Note.fromMidi(127);
      expect(g9.octave, 9);
      expect(g9.label, 'G');
      expect(g9.freq, closeTo(12543.854, 1e-3));
    });
  });

  group('Parsing validation', () {
    test('Rejects invalid note letter', () {
      expect(() => Note.parse('H4'), throwsFormatException);
    });

    test('Rejects out-of-range octave', () {
      expect(() => Note.parse('C10'), throwsRangeError);
    });

    test('Rejects malformed accidental', () {
      expect(() => Note.parse('C##4'), throwsFormatException);
    });
  });
}
