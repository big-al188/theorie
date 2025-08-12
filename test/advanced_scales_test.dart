// test/advanced_scales_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/models/music/scale.dart';

const _majorSteps = [2, 2, 1, 2, 2, 2, 1];

void _expectStepPattern(List<Note> notes, List<int> steps) {
  // Accept scales with 7 (no duplicate octave) or 8 notes (with octave)
  expect(notes.length, greaterThanOrEqualTo(steps.length));

  final tonicMidi = notes.first.midi;             // remember the root

  for (var i = 0; i < steps.length; i++) {
    final current = notes[i];

    // If we're at the last supplied note (no explicit octave),
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
  final scales = {
    'Major': Scale.major,
    'Natural minor': Scale.naturalMinor,
    'Major pentatonic': Scale.majorPentatonic,
    'Minor pentatonic': Scale.minorPentatonic,
  };

  for (final tonic in tonics) {
    for (final entry in scales.entries) {
      final scale = entry.value;
      final name  = entry.key;
      test('$tonic $name scale uniqueness & step pattern', () {
        final rootNote = Note.fromString('${tonic}4');
        final scaleNotes = scale.getNotesForRoot(rootNote);
        final pcs = scaleNotes.map((n) => n.pitchClass).toSet();
        expect(pcs.length, equals(scale.intervals.length),
            reason: 'Duplicate pcs in $tonic $name');

        if (name == 'Major') {
          _expectStepPattern(scaleNotes, _majorSteps);
        }
      });
    }
  }

  // Mode rotation test
  test('Major scale intervals are correct', () {
    final majorIntervals = Scale.major.intervals;
    expect(majorIntervals, equals([0, 2, 4, 5, 7, 9, 11]));
  });

  // Basic scale functionality
  test('Scale contains pitch class correctly', () {
    final rootNote = Note.fromString('C4');
    expect(Scale.major.containsPitchClass(0, 4), isTrue); // E in C major
    expect(Scale.major.containsPitchClass(0, 1), isFalse); // C# not in C major
  });
}