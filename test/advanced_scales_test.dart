// test/advanced_scales_test.dart
import 'package:test/test.dart';
import 'package:theorie/theory/note.dart';
import 'package:theorie/theory/scales.dart';

const _majorSteps = [2, 2, 1, 2, 2, 2, 1];

void _expectStepPattern(List<Note> notes, List<int> steps) {
  // Accept scales with 7 (no duplicate octave) or 8 notes (with octave)
  expect(notes.length, isIn([steps.length, steps.length + 1]));

  final tonicMidi = notes.first.midi;             // remember the root

  for (var i = 0; i < steps.length; i++) {
    final current = notes[i];

    // If we’re at the last supplied note (no explicit octave),
    // wrap to *tonic + 12* instead of current +12.
    final next = (i < notes.length - 1)
        ? notes[i + 1]
        : Note.fromMidi(tonicMidi + 12);

    expect(
      next.midi - current.midi,
      equals(steps[i]),
      reason: 'Degree ${i + 1}‑>${i + 2}',
    );
  }
}


void main() {
  // 1‑48 ── all 12 tonics × 4 scale types
  const tonics = [
    'C','C#','D','Eb','E','F','F#','G','Ab','A','Bb','B'
  ];
  final builders = {
    'Major': major,
    'Natural minor': naturalMinor,
    'Major pentatonic': majorPentatonic,
    'Minor pentatonic': minorPentatonic,
  };

  for (final tonic in tonics) {
    for (final entry in builders.entries) {
      final builder = entry.value;
      final name    = entry.key;
      test('$tonic $name scale uniqueness & TTSTTTS', () {
        final scale = builder(Note.parse('${tonic}4'));
        final pcs   = scale.notes.map((n) => n.pc).toSet();
        expect(pcs.length, equals(scale.notes.length),
            reason: 'Duplicate pcs in $tonic $name');

        if (name == 'Major') {
          _expectStepPattern(scale.notes, _majorSteps);
        }
      });
    }
  }

  // 49 ── mode rotation keeps pcs
  test('Mode rotation keeps pitch classes', () {
    final set1 = major(Note.parse('C3')).notes.map((n) => n.pc).toSet();
    final set2 = major(Note.parse('C3')).mode(1).notes.map((n) => n.pc).toSet();
    expect(set1, equals(set2));
  });

  // 50 ── degree bounds
  test('Degree bounds & value', () {
    final gPent = majorPentatonic(Note.parse('G2'));
    expect(gPent.degree(3).label, equals('B'));
    expect(() => gPent.degree(6), throwsRangeError);
  });
}
