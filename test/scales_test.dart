// test/scales_test.dart
//
// Unit‑tests for lib/theory/scales.dart.
// Requires note.dart and interval.dart to be present.
//
import 'package:test/test.dart';
import 'package:theorie/theory/note.dart';
import 'package:theorie/theory/scales.dart';

void main() {
  group('Major scale construction', () {
    test('C major contains the expected notes', () {
      final cMaj = major(Note.parse('C4'));
      final labels = cMaj.notes.map((n) => n.label).toList();
      expect(labels, equals(['C', 'D', 'E', 'F', 'G', 'A', 'B']));
    });

    test('F Lydian (mode‑4 of C major) has a sharp 4th (B)', () {
      final fLyd = major(Note.parse('C4')).mode(3); // rotation 3 ⇒ Lydian
      final firstFour = fLyd.notes.take(4).map((n) => n.label).toList();
      expect(firstFour, equals(['F', 'G', 'A', 'B'])); // B natural (♮) is #4
    });

    test('Round‑trip mode(0) returns original scale', () {
      final cMaj = major(Note.parse('C3'));
      expect(cMaj.mode(0).notes, equals(cMaj.notes));
    });
  });

  group('Minor relationships & pentatonics', () {
    test('A natural minor shares pitch collection with C major', () {
      final cMajSet = major(Note.parse('C3'))
          .notes
          .map((n) => n.pc)
          .toSet();
      final aMinSet = naturalMinor(Note.parse('A2'))
          .notes
          .map((n) => n.pc)
          .toSet();
      expect(aMinSet, equals(cMajSet));
    });

    test('E major pentatonic notes are correct', () {
      final ePent = majorPentatonic(Note.parse('E3'));
      final labels = ePent.notes.map((n) => n.label).toList();
      expect(labels, equals(['E', 'F♯', 'G♯', 'B', 'C♯']));
    });
  });
}
