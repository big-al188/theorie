// test/intervals_test.dart – unit tests for Interval logic
// -----------------------------------------------------------------------------
import 'package:flutter_test/flutter_test.dart';
import 'package:theorie/theory/note.dart';
import 'package:theorie/theory/interval.dart';

void main() {
  group('Simple interval naming 0–11', () {
    final cases = <int, String>{
      0: 'P1',
      1: 'm2',
      2: 'M2',
      3: 'm3',
      4: 'M3',
      5: 'P4',
      6: 'A4',   // tritone labelled augmented 4th in our impl
      7: 'P5',
      8: 'm6',
      9: 'M6',
      10: 'm7',
      11: 'M7',
    };

    cases.forEach((semi, label) {
      test('$semi → $label', () {
        expect(Interval(semi).toString(), label);
      });
    });
  });

  group('Compound interval naming up to 15th', () {
    final cases = <int, String>{
      12: 'P8',
      13: 'm9',
      14: 'M9',
      15: 'm10',
      16: 'M10',
      17: 'P11',
      18: 'A11',
      19: 'P12',
      20: 'm13',
      21: 'M13',
      22: 'm14',
      23: 'M14',
      24: 'P15',
    };

    cases.forEach((semi, label) {
      test('$semi → $label', () {
        expect(Interval(semi).toString(), label);
      });
    });
  });

  group('Fallback naming beyond 15th', () {
    test('28 semitones → M3+2oct', () {
      expect(Interval(28).toString(), 'M3+2oct');
    });
  });

  group('between() and transpose() round‑trip', () {
    test('C4 up M9 yields D5, and between matches', () {
      final c4 = Note.parse('C4');
      final m9 = Interval(14);
      final d5 = transpose(c4, m9);

      expect(d5.toString(), 'D5');
      expect(between(c4, d5).semitones, 14);
    });

    test('Descending interval negative', () {
      final e4 = Note.parse('E4');
      final c4 = Note.parse('C4');
      final down = between(e4, c4);
      expect(down.semitones, -4);
      expect(down.toString(), '-M3');
    });
  });
}
