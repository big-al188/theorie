// test/scale_comprehensive_test.dart - Comprehensive scale tests for 100% coverage
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/models/music/scale.dart';

void main() {
  group('Scale Comprehensive Tests', () {
    group('Static Scale Access', () {
      test('Common scale static getters work correctly', () {
        expect(Scale.major.name, 'Major');
        expect(Scale.naturalMinor.name, 'Natural Minor');
        expect(Scale.harmonicMinor.name, 'Harmonic Minor');
        expect(Scale.melodicMinor.name, 'Melodic Minor');
        expect(Scale.majorPentatonic.name, 'Major Pentatonic');
        expect(Scale.minorPentatonic.name, 'Minor Pentatonic');
        expect(Scale.blues.name, 'Blues');
        expect(Scale.chromatic.name, 'Chromatic');
      });

      test('Scale.get() method works correctly', () {
        expect(Scale.get('Major'), isNotNull);
        expect(Scale.get('Major')!.name, 'Major');
        expect(Scale.get('Nonexistent'), isNull);
        expect(Scale.get(''), isNull);
      });

      test('Scale.all contains all scales', () {
        final allScales = Scale.all;
        expect(allScales.isNotEmpty, true);
        expect(allScales, contains('Major'));
        expect(allScales, contains('Natural Minor'));
        expect(allScales, contains('Blues'));
        expect(allScales, contains('Chromatic'));
      });
    });

    group('Scale Properties', () {
      test('Scale length matches intervals count', () {
        expect(Scale.major.length, 7);
        expect(Scale.majorPentatonic.length, 5);
        expect(Scale.chromatic.length, 12);
        expect(Scale.blues.length, 6);
      });

      test('Pitch class containment works correctly', () {
        // C Major should contain C, D, E, F, G, A, B (0, 2, 4, 5, 7, 9, 11)
        expect(Scale.major.containsPitchClass(0, 0), true); // C in C Major
        expect(Scale.major.containsPitchClass(0, 2), true); // D in C Major
        expect(Scale.major.containsPitchClass(0, 4), true); // E in C Major
        expect(Scale.major.containsPitchClass(0, 1), false); // C# not in C Major
        
        // Test with different root - F Major (root pc = 5)
        expect(Scale.major.containsPitchClass(5, 5), true); // F in F Major
        expect(Scale.major.containsPitchClass(5, 7), true); // G in F Major
        expect(Scale.major.containsPitchClass(5, 10), true); // Bb in F Major
        expect(Scale.major.containsPitchClass(5, 11), false); // B not in F Major
      });

      test('Scale degrees generate correctly', () {
        final majorDegrees = Scale.major.degrees;
        expect(majorDegrees, ['1', '2', '3', '4', '5', '6', '7']);
        
        final naturalMinorDegrees = Scale.naturalMinor.degrees;
        expect(naturalMinorDegrees, ['1', '2', '♭3', '4', '5', '♭6', '♭7']);
        
        final harmonicMinorDegrees = Scale.harmonicMinor.degrees;
        expect(harmonicMinorDegrees, ['1', '2', '♭3', '4', '5', '♭6', '7']);
        
        final chromaticDegrees = Scale.chromatic.degrees;
        expect(chromaticDegrees.length, 12);
        expect(chromaticDegrees[1], '♭2');
        expect(chromaticDegrees[6], '♭5');
      });

      test('toString returns scale name', () {
        expect(Scale.major.toString(), 'Major');
        expect(Scale.blues.toString(), 'Blues');
        expect(Scale.chromatic.toString(), 'Chromatic');
      });
    });

    group('Note Generation', () {
      test('Generate notes for various scales and roots', () {
        final dMajor = Scale.major.getNotesForRoot(Note.fromString('D4'));
        final noteNames = dMajor.take(7).map((n) => n.name).toList();
        expect(noteNames, ['D', 'E', 'F♯', 'G', 'A', 'B', 'C♯']);

        final fMinor = Scale.naturalMinor.getNotesForRoot(Note.fromString('F4'));
        final fMinorNames = fMinor.take(7).map((n) => n.name).toList();
        expect(fMinorNames, ['F', 'G', 'A♭', 'B♭', 'C', 'D♭', 'E♭']);
      });

      test('Notes include octave adjustments correctly', () {
        final c4 = Note.fromString('C4');
        final cMajorNotes = Scale.major.getNotesForRoot(c4);
        
        // Should have 8 notes (7 + octave)
        expect(cMajorNotes.length, 8);
        expect(cMajorNotes.last.name, 'C');
        expect(cMajorNotes.last.octave, 5); // Octave above
      });

      test('Flat preference is respected', () {
        final bbRoot = Note.fromString('Bb4'); // Bb naturally prefers flats
        final bbMajor = Scale.major.getNotesForRoot(bbRoot);
        
        // Should prefer flats in Bb major since Bb root naturally prefers flats
        final noteNames = bbMajor.take(7).map((n) => n.name).toList();
        expect(noteNames, ['B♭', 'C', 'D', 'E♭', 'F', 'G', 'A']);
        expect(bbRoot.preferFlats, true); // Bb should naturally prefer flats
      });
    });

    group('Mode Operations', () {
      test('Mode intervals calculated correctly', () {
        // Dorian (mode 1 of major)
        final dorianIntervals = Scale.major.getModeIntervals(1);
        expect(dorianIntervals, contains(0)); // Root
        expect(dorianIntervals, contains(10)); // b7
        expect(dorianIntervals, contains(3)); // b3
        expect(dorianIntervals.length, 8); // Should include octave

        // Lydian (mode 3 of major)  
        final lydianIntervals = Scale.major.getModeIntervals(3);
        expect(lydianIntervals, contains(6)); // #4
        
        // Mixolydian (mode 4 of major)
        final mixolydianIntervals = Scale.major.getModeIntervals(4);
        expect(mixolydianIntervals, contains(10)); // b7
      });

      test('Mode root calculation works', () {
        final c4 = Note.fromString('C4');
        
        // Dorian mode (index 1) of C major starts on D
        final dorianRoot = Scale.major.getModeRoot(c4, 1);
        expect(dorianRoot.name, 'D');
        expect(dorianRoot.octave, 4);
        
        // Mixolydian mode (index 4) of C major starts on G
        final mixolydianRoot = Scale.major.getModeRoot(c4, 4);
        expect(mixolydianRoot.name, 'G');
        expect(mixolydianRoot.octave, 4);
        
        // Test with mode index greater than scale length
        final wrapAroundRoot = Scale.major.getModeRoot(c4, 8); // wraps to index 1
        expect(wrapAroundRoot.name, 'D');
      });

      test('Mode names work correctly', () {
        // Major scale has mode names
        expect(Scale.major.getModeName(0), 'Ionian');
        expect(Scale.major.getModeName(1), 'Dorian');
        expect(Scale.major.getModeName(6), 'Locrian');
        
        // Harmonic minor has mode names
        expect(Scale.harmonicMinor.getModeName(4), 'Phrygian Dominant');
        
        // Scale without mode names uses generic names
        expect(Scale.blues.getModeName(0), 'Mode 1');
        expect(Scale.blues.getModeName(2), 'Mode 3');
        
        // Out of bounds mode name
        expect(Scale.major.getModeName(10), 'Mode 11');
      });
    });

    group('Exotic and Special Scales', () {
      test('Pentatonic scales have correct intervals', () {
        expect(Scale.majorPentatonic.intervals, [0, 2, 4, 7, 9]);
        expect(Scale.minorPentatonic.intervals, [0, 3, 5, 7, 10]);
        expect(Scale.blues.intervals, [0, 3, 5, 6, 7, 10]);
      });

      test('Jazz scales exist and have correct properties', () {
        final bebopDom = Scale.get('Bebop Dominant');
        expect(bebopDom, isNotNull);
        expect(bebopDom!.intervals.length, 8);
        
        final altered = Scale.get('Altered');
        expect(altered, isNotNull);
        expect(altered!.intervals, [0, 1, 3, 4, 6, 8, 10]);
        
        final wholeTone = Scale.get('Whole Tone');
        expect(wholeTone, isNotNull);
        expect(wholeTone!.intervals, [0, 2, 4, 6, 8, 10]);
      });

      test('Ethnic scales exist and work correctly', () {
        final hungarianMinor = Scale.get('Hungarian Minor');
        expect(hungarianMinor, isNotNull);
        expect(hungarianMinor!.name, 'Hungarian Minor');
        
        final japanese = Scale.get('Japanese');
        expect(japanese, isNotNull);
        expect(japanese!.intervals, [0, 1, 5, 7, 8]);
        
        final arabic = Scale.get('Arabic');
        expect(arabic, isNotNull);
        expect(arabic!.intervals.length, 7);
        
        final gypsy = Scale.get('Gypsy');
        expect(gypsy, isNotNull);
      });

      test('Exotic scales exist and work correctly', () {
        final enigmatic = Scale.get('Enigmatic');
        expect(enigmatic, isNotNull);
        expect(enigmatic!.name, 'Enigmatic');
        
        final doubleHarmonic = Scale.get('Double Harmonic');
        expect(doubleHarmonic, isNotNull);
        
        final neapolitanMajor = Scale.get('Neapolitan Major');
        expect(neapolitanMajor, isNotNull);
        
        final neapolitanMinor = Scale.get('Neapolitan Minor');
        expect(neapolitanMinor, isNotNull);
      });
    });

    group('Church Modes as Individual Scales', () {
      test('Individual church modes exist', () {
        final dorian = Scale.get('Dorian');
        expect(dorian, isNotNull);
        expect(dorian!.intervals, [0, 2, 3, 5, 7, 9, 10]);
        
        final phrygian = Scale.get('Phrygian');
        expect(phrygian, isNotNull);
        expect(phrygian!.intervals, [0, 1, 3, 5, 7, 8, 10]);
        
        final lydian = Scale.get('Lydian');
        expect(lydian, isNotNull);
        expect(lydian!.intervals, [0, 2, 4, 6, 7, 9, 11]);
        
        final mixolydian = Scale.get('Mixolydian');
        expect(mixolydian, isNotNull);
        expect(mixolydian!.intervals, [0, 2, 4, 5, 7, 9, 10]);
        
        final aeolian = Scale.get('Aeolian');
        expect(aeolian, isNotNull);
        expect(aeolian!.intervals, [0, 2, 3, 5, 7, 8, 10]);
        
        final locrian = Scale.get('Locrian');
        expect(locrian, isNotNull);
        expect(locrian!.intervals, [0, 1, 3, 5, 6, 8, 10]);
      });
    });

    group('Scale Edge Cases and Error Handling', () {
      test('Mode operations with extreme values', () {
        final c4 = Note.fromString('C4');
        
        // Very high mode index should wrap
        final highModeRoot = Scale.major.getModeRoot(c4, 100);
        expect(highModeRoot, isA<Note>());
        
        // Negative mode index behavior
        final negativeModeIntervals = Scale.major.getModeIntervals(-1);
        expect(negativeModeIntervals, isA<List<int>>());
        expect(negativeModeIntervals, isNotEmpty);
      });

      test('Pitch class operations with edge values', () {
        // Test with pitch classes at boundaries
        expect(Scale.major.containsPitchClass(11, 1), true); // B major contains C# (pitch class 1)
        expect(Scale.major.containsPitchClass(0, 11), true); // C major contains B
        
        // Test with large pitch class values (should wrap) - the function should handle modulo internally
        expect(Scale.major.containsPitchClass(0, 12), true); // Should wrap to 0 (same as root)
        // For root wrapping, use 0 instead of 12 since pitch classes are 0-11
        expect(Scale.major.containsPitchClass(0, 0), true); // C major contains C
      });

      test('Notes generation with extreme octaves', () {
        final highRoot = Note.fromMidi(120); // Very high note
        final highScale = Scale.major.getNotesForRoot(highRoot);
        expect(highScale.isNotEmpty, true);
        expect(highScale.every((n) => n.midi >= 120), true);
        
        final lowRoot = Note.fromMidi(12); // Very low note
        final lowScale = Scale.major.getNotesForRoot(lowRoot);
        expect(lowScale.isNotEmpty, true);
        expect(lowScale.every((n) => n.midi >= 12), true);
      });

      test('Mode intervals always include octave', () {
        for (int i = 0; i < Scale.major.length; i++) {
          final modeIntervals = Scale.major.getModeIntervals(i);
          expect(modeIntervals, contains(12)); // Should always contain octave
        }
        
        // Test with pentatonic scale modes too
        for (int i = 0; i < Scale.majorPentatonic.length; i++) {
          final pentModeIntervals = Scale.majorPentatonic.getModeIntervals(i);
          expect(pentModeIntervals, contains(12));
        }
      });
    });

    group('Scale Comparison and Analysis', () {
      test('Compare scale intervals across different scales', () {
        // Natural minor should be major with b3, b6, b7
        final majorIntervals = Scale.major.intervals;
        final minorIntervals = Scale.naturalMinor.intervals;
        
        expect(majorIntervals[0], minorIntervals[0]); // Same root
        expect(majorIntervals[1], minorIntervals[1]); // Same 2nd
        expect(majorIntervals[2], isNot(minorIntervals[2])); // Different 3rd
        expect(majorIntervals[3], minorIntervals[3]); // Same 4th
        expect(majorIntervals[4], minorIntervals[4]); // Same 5th
        expect(majorIntervals[5], isNot(minorIntervals[5])); // Different 6th
        expect(majorIntervals[6], isNot(minorIntervals[6])); // Different 7th
      });

      test('Scale analysis across multiple octaves', () {
        final c3 = Note.fromString('C3');
        final c5 = Note.fromString('C5');
        
        final c3Major = Scale.major.getNotesForRoot(c3);
        final c5Major = Scale.major.getNotesForRoot(c5);
        
        // Same pitch classes, different octaves
        for (int i = 0; i < 7; i++) {
          expect(c3Major[i].pitchClass, c5Major[i].pitchClass);
          expect(c3Major[i].octave + 2, c5Major[i].octave);
        }
      });
    });

    group('Performance and Memory', () {
      test('Scale operations are consistent and efficient', () {
        final c4 = Note.fromString('C4');
        
        // Multiple calls should return consistent results
        final scale1 = Scale.major.getNotesForRoot(c4);
        final scale2 = Scale.major.getNotesForRoot(c4);
        
        expect(scale1.length, scale2.length);
        for (int i = 0; i < scale1.length; i++) {
          expect(scale1[i].midi, scale2[i].midi);
          expect(scale1[i].name, scale2[i].name);
        }
        
        // Mode calculations should be consistent
        final mode1a = Scale.major.getModeIntervals(3);
        final mode1b = Scale.major.getModeIntervals(3);
        expect(mode1a, equals(mode1b));
      });
    });
  });
}