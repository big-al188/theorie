// test/scales_test.dart
//
// Unit‑tests for lib/models/music/scale.dart.
// Requires note.dart to be present.
//
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/models/music/scale.dart';

void main() {
  group('Major scale construction', () {
    test('C major contains the expected notes', () {
      final rootNote = Note.fromString('C4');
      final cMaj = Scale.major.getNotesForRoot(rootNote);
      final labels = cMaj.take(7).map((n) => n.name).toList();
      expect(labels, equals(['C', 'D', 'E', 'F', 'G', 'A', 'B']));
    });

    test('F Lydian (mode‑4 of C major) has correct intervals', () {
      final lydianIntervals = Scale.major.getModeIntervals(3); // Lydian is mode 4 (index 3)
      // Lydian should have raised 4th degree
      expect(lydianIntervals, contains(6)); // #4 is 6 semitones
    });

    test('Round‑trip mode(0) returns original scale intervals', () {
      final originalIntervals = Scale.major.intervals;
      final mode0Intervals = Scale.major.getModeIntervals(0);
      expect(mode0Intervals.take(originalIntervals.length), equals(originalIntervals));
    });
  });

  group('Minor relationships & pentatonics', () {
    test('A natural minor shares pitch collection with C major', () {
      final cMajSet = Scale.major.getNotesForRoot(Note.fromString('C3'))
          .map((n) => n.pitchClass)
          .toSet();
      final aMinSet = Scale.naturalMinor.getNotesForRoot(Note.fromString('A2'))
          .map((n) => n.pitchClass)
          .toSet();
      expect(aMinSet, equals(cMajSet));
    });

    test('E major pentatonic notes are correct', () {
      final ePent = Scale.majorPentatonic.getNotesForRoot(Note.fromString('E3'));
      final labels = ePent.take(5).map((n) => n.name).toList();
      expect(labels, equals(['E', 'F♯', 'G♯', 'B', 'C♯']));
    });
  });
}