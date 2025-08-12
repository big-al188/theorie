// test/intervals_test.dart – unit tests for Interval logic
// -----------------------------------------------------------------------------
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/models/music/interval.dart';

void main() {
  group('Simple interval creation', () {
    test('Interval constructor works', () {
      final interval = Interval(7);
      expect(interval.semitones, 7);
    });

    test('Common interval constants exist', () {
      expect(Interval.unison.semitones, 0);
      expect(Interval.majorThird.semitones, 4);
      expect(Interval.perfectFifth.semitones, 7);
      expect(Interval.octave.semitones, 12);
    });
  });

  group('Note transposition', () {
    test('C4 up perfect fifth yields G4', () {
      final c4 = Note.fromString('C4');
      final g4 = c4.transpose(7); // Perfect fifth
      expect(g4.name, 'G');
      expect(g4.octave, 4);
    });

    test('A4 up minor third yields C5', () {
      final a4 = Note.fromString('A4');
      final c5 = a4.transpose(3); // Minor third
      expect(c5.name, 'C');
      expect(c5.octave, 5);
    });
  });

  group('Interval calculations', () {
    test('Distance between C4 and G4 is 7 semitones', () {
      final c4 = Note.fromString('C4');
      final g4 = Note.fromString('G4');
      final distance = g4.midi - c4.midi;
      expect(distance, 7);
    });

    test('Distance between E4 and C4 is -4 semitones', () {
      final e4 = Note.fromString('E4');
      final c4 = Note.fromString('C4');
      final distance = c4.midi - e4.midi;
      expect(distance, -4);
    });
  });

  group('Interval Names and Labels', () {
    test('Basic interval names', () {
      expect(Interval.unison.name, contains('Unison'));
      expect(Interval.perfectFifth.name, contains('Perfect 5th'));
      expect(Interval.majorThird.name, contains('Major 3rd'));
      expect(Interval.minorSeventh.name, contains('Minor 7th'));
    });

    test('Extended interval names beyond octave', () {
      final ninth = Interval(14); // Major ninth (14 semitones)
      final eleventh = Interval(17); // Perfect eleventh
      expect(ninth.name, contains('+ 1oct'));
      expect(eleventh.name, contains('+ 1oct'));
    });

    test('Octave interval name', () {
      expect(Interval.octave.name, 'Octave');
      final twoOctaves = Interval(24);
      expect(twoOctaves.name, contains('+ 2oct'));
    });

    test('Interval labels for display', () {
      expect(Interval.unison.label, 'R');
      expect(Interval.majorThird.label, '3');
      expect(Interval.perfectFifth.label, '5');
      expect(Interval.minorSeventh.label, '♭7');
    });

    test('Extended interval labels', () {
      final ninth = Interval(14); // Major ninth
      expect(ninth.label, '9'); // Should show as 9th
      
      final compound = Interval(26); // Major second + 2 octaves  
      expect(compound.label, '16'); // Should show as 16th
    });

    test('Octave labels', () {
      expect(Interval.octave.label, 'O1');
      final twoOctaves = Interval(24);
      expect(twoOctaves.label, 'O2');
    });
  });

  group('Interval Quality', () {
    test('Perfect intervals', () {
      expect(Interval.unison.quality, IntervalQuality.perfect);
      expect(Interval.perfectFourth.quality, IntervalQuality.perfect);
      expect(Interval.perfectFifth.quality, IntervalQuality.perfect);
    });

    test('Major intervals', () {
      expect(Interval.majorSecond.quality, IntervalQuality.major);
      expect(Interval.majorThird.quality, IntervalQuality.major);
      expect(Interval.majorSixth.quality, IntervalQuality.major);
      expect(Interval.majorSeventh.quality, IntervalQuality.major);
    });

    test('Minor intervals', () {
      expect(Interval.minorSecond.quality, IntervalQuality.minor);
      expect(Interval.minorThird.quality, IntervalQuality.minor);
      expect(Interval.minorSixth.quality, IntervalQuality.minor);
      expect(Interval.minorSeventh.quality, IntervalQuality.minor);
    });

    test('Tritone quality', () {
      expect(Interval.tritone.quality, IntervalQuality.diminished);
    });
  });

  group('Interval Properties', () {
    test('Consonant intervals', () {
      expect(Interval.unison.isConsonant, isTrue);
      expect(Interval.majorThird.isConsonant, isTrue);
      expect(Interval.minorThird.isConsonant, isTrue);
      expect(Interval.perfectFifth.isConsonant, isTrue);
      expect(Interval.octave.isConsonant, isTrue);
      
      // Dissonant intervals
      expect(Interval.majorSecond.isConsonant, isFalse);
      expect(Interval.tritone.isConsonant, isFalse);
      expect(Interval.majorSeventh.isConsonant, isFalse);
    });

    test('Perfect intervals identification', () {
      expect(Interval.unison.isPerfect, isTrue);
      expect(Interval.perfectFourth.isPerfect, isTrue);
      expect(Interval.perfectFifth.isPerfect, isTrue);
      expect(Interval.octave.isPerfect, isTrue);
      
      // Non-perfect intervals
      expect(Interval.majorThird.isPerfect, isFalse);
      expect(Interval.minorSeventh.isPerfect, isFalse);
    });

    test('Interval inversion', () {
      expect(Interval.majorThird.inverted.semitones, 8); // Major third inverts to minor sixth
      expect(Interval.perfectFifth.inverted.semitones, 5); // Perfect fifth inverts to perfect fourth
      expect(Interval.minorSecond.inverted.semitones, 11); // Minor second inverts to major seventh
      expect(Interval.unison.inverted.semitones, 12); // Unison inverts to octave
    });
  });

  group('Interval Arithmetic', () {
    test('Adding intervals', () {
      final majorThird = Interval.majorThird;
      final minorThird = Interval.minorThird;
      final sum = majorThird + minorThird;
      
      expect(sum.semitones, 7); // 4 + 3 = 7 (perfect fifth)
      expect(sum, equals(Interval.perfectFifth));
    });

    test('Subtracting intervals', () {
      final perfectFifth = Interval.perfectFifth;
      final majorThird = Interval.majorThird;
      final difference = perfectFifth - majorThird;
      
      expect(difference.semitones, 3); // |7 - 4| = 3 (minor third)
      expect(difference, equals(Interval.minorThird));
    });

    test('Subtraction produces absolute value', () {
      final small = Interval.majorSecond;
      final large = Interval.perfectFifth;
      final diff1 = large - small;
      final diff2 = small - large;
      
      expect(diff1.semitones, diff2.semitones); // Both should be positive
    });
  });

  group('Object Equality and String Representation', () {
    test('Interval equality', () {
      final fifth1 = Interval(7);
      final fifth2 = Interval.perfectFifth;
      final third = Interval.majorThird;
      
      expect(fifth1 == fifth2, isTrue);
      expect(fifth1 == third, isFalse);
      expect(fifth1.hashCode, equals(fifth2.hashCode));
    });

    test('String representation', () {
      expect(Interval.perfectFifth.toString(), contains('Perfect 5th'));
      expect(Interval.majorThird.toString(), contains('Major 3rd'));
      expect(Interval.unison.toString(), contains('Unison'));
      expect(Interval.perfectFifth.toString(), contains('7 semitones'));
    });
  });

  group('IntervalQuality Enum', () {
    test('Quality symbols', () {
      expect(IntervalQuality.perfect.symbol, 'P');
      expect(IntervalQuality.major.symbol, 'M');
      expect(IntervalQuality.minor.symbol, 'm');
      expect(IntervalQuality.augmented.symbol, '+');
      expect(IntervalQuality.diminished.symbol, '°');
    });
  });
}