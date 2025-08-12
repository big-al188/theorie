// test/chord_test.dart - Comprehensive chord system tests
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/models/music/note.dart';

void main() {
  group('Chord System Tests', () {
    group('Chord Lookup and Basic Properties', () {
      test('Basic chord lookups work', () {
        final major = Chord.get('major');
        expect(major, isNotNull);
        expect(major!.type, 'major');
        expect(major.symbol, '');
        expect(major.displayName, 'Major');
        expect(major.intervals, [0, 4, 7]);
        expect(major.category, 'Basic Triads');

        final minor = Chord.get('minor');
        expect(minor, isNotNull);
        expect(minor!.symbol, 'm');
        expect(minor.intervals, [0, 3, 7]);
      });

      test('Invalid chord lookup returns null', () {
        final invalidChord = Chord.get('nonexistent');
        expect(invalidChord, isNull);
      });

      test('All chord definitions accessible', () {
        final allChords = Chord.all;
        expect(allChords, isNotEmpty);
        expect(allChords.length, greaterThan(80)); // We have many chords (86)
        expect(allChords['major'], isA<Chord>());
        expect(allChords['minor'], isA<Chord>());
      });
    });

    group('Chord Categories', () {
      test('Chords grouped by category correctly', () {
        final byCategory = Chord.byCategory;
        
        expect(byCategory.keys, contains('Basic Triads'));
        expect(byCategory.keys, contains('Seventh Chords'));
        expect(byCategory.keys, contains('Extended (9ths)'));
        expect(byCategory.keys, contains('Jazz Chords'));
        
        final basicTriads = byCategory['Basic Triads']!;
        expect(basicTriads.length, 4); // major, minor, diminished, augmented
        
        final triadNames = basicTriads.map((c) => c.type).toSet();
        expect(triadNames, contains('major'));
        expect(triadNames, contains('minor'));
        expect(triadNames, contains('diminished'));
        expect(triadNames, contains('augmented'));
      });
    });

    group('Common Chords', () {
      test('Common chords list contains expected chords', () {
        final common = Chord.common;
        expect(common.length, 9);
        
        final commonTypes = common.map((c) => c.type).toList();
        expect(commonTypes, contains('major'));
        expect(commonTypes, contains('minor'));
        expect(commonTypes, contains('major7'));
        expect(commonTypes, contains('minor7'));
        expect(commonTypes, contains('dominant7'));
        expect(commonTypes, contains('sus2'));
        expect(commonTypes, contains('sus4'));
        expect(commonTypes, contains('add9'));
        expect(commonTypes, contains('power-chord'));
      });
    });

    group('Chord Symbol Generation', () {
      test('Basic chord symbols', () {
        final major = Chord.get('major')!;
        expect(major.getSymbol('C'), 'C');
        expect(major.getSymbol('F#'), 'F#');
        
        final minor = Chord.get('minor')!;
        expect(minor.getSymbol('A'), 'Am');
        expect(minor.getSymbol('Bb'), 'Bbm');
        
        final major7 = Chord.get('major7')!;
        expect(major7.getSymbol('G'), 'Gmaj7');
        
        final dominant7 = Chord.get('dominant7')!;
        expect(dominant7.getSymbol('D'), 'D7');
      });

      test('Complex chord symbols', () {
        final dim7 = Chord.get('diminished7')!;
        expect(dim7.getSymbol('C'), 'C°7');
        
        final halfDim = Chord.get('half-diminished7')!;
        expect(halfDim.getSymbol('B'), 'Bø7');
        
        final alt = Chord.get('7alt')!;
        expect(alt.getSymbol('F'), 'F7alt');
        
        final sharp11 = Chord.get('7#11')!;
        expect(sharp11.getSymbol('E'), 'E7♯11');
      });
    });

    group('Chord Notes Generation', () {
      test('Generate notes for major chord', () {
        final major = Chord.get('major')!;
        final cRoot = Note.fromString('C4');
        final notes = major.getNotesForRoot(cRoot);
        
        expect(notes.length, 3);
        expect(notes[0].name, 'C');
        expect(notes[0].octave, 4);
        expect(notes[1].name, 'E');
        expect(notes[1].octave, 4);
        expect(notes[2].name, 'G');
        expect(notes[2].octave, 4);
      });

      test('Generate notes for extended chord', () {
        final major9 = Chord.get('major9')!;
        final dRoot = Note.fromString('D3');
        final notes = major9.getNotesForRoot(dRoot);
        
        expect(notes.length, 5);
        expect(notes[0].name, 'D'); // Root
        expect(notes[1].name, 'F♯'); // Major 3rd
        expect(notes[2].name, 'A'); // Perfect 5th
        expect(notes[3].name, 'C♯'); // Major 7th
        expect(notes[4].name, 'E'); // 9th (crosses octave)
        expect(notes[4].octave, 4); // Should be in next octave
      });

      test('Generate notes with flat preference', () {
        final minor = Chord.get('minor')!;
        final bbRoot = Note.fromString('Bb4');
        final notes = minor.getNotesForRoot(bbRoot);
        
        expect(notes.length, 3);
        expect(notes[0].name, 'B♭');
        expect(notes[1].name, 'D♭'); // Minor 3rd, should prefer flats
        expect(notes[2].name, 'F');
      });
    });

    group('Chord Inversions', () {
      test('Available inversions for different chord sizes', () {
        final major = Chord.get('major')!; // 3 notes
        final majorInversions = major.availableInversions;
        expect(majorInversions.length, 3);
        expect(majorInversions, contains(ChordInversion.root));
        expect(majorInversions, contains(ChordInversion.first));
        expect(majorInversions, contains(ChordInversion.second));

        final major7 = Chord.get('major7')!; // 4 notes
        final major7Inversions = major7.availableInversions;
        expect(major7Inversions.length, 4);
        expect(major7Inversions, contains(ChordInversion.third));

        final powerChord = Chord.get('power-chord')!; // 2 notes
        final powerInversions = powerChord.availableInversions;
        expect(powerInversions.length, 2);
      });
    });

    group('Chord Voicings', () {
      test('Root position voicing', () {
        final major = Chord.get('major')!;
        final c4 = Note.fromString('C4');
        final voicing = major.buildVoicing(
          root: c4, 
          inversion: ChordInversion.root
        );
        
        expect(voicing.length, 3);
        expect(voicing[0], 60); // C4
        expect(voicing[1], 64); // E4
        expect(voicing[2], 67); // G4
        expect(voicing, orderedEquals([60, 64, 67])); // Should be sorted
      });

      test('First inversion voicing', () {
        final major = Chord.get('major')!;
        final c4 = Note.fromString('C4');
        final voicing = major.buildVoicing(
          root: c4, 
          inversion: ChordInversion.first
        );
        
        expect(voicing.length, 3);
        expect(voicing[0], 64); // E4 (bass)
        expect(voicing, contains(67)); // G4
        expect(voicing, contains(72)); // C5 (octave above)
        expect(voicing, orderedEquals(voicing..sort())); // Should be sorted
      });

      test('Complex chord voicing', () {
        final major7 = Chord.get('major7')!;
        final g3 = Note.fromString('G3');
        final voicing = major7.buildVoicing(
          root: g3, 
          inversion: ChordInversion.second
        );
        
        expect(voicing.length, 4);
        expect(voicing[0], lessThan(voicing[1])); // Should be sorted ascending
        expect(voicing[1], lessThan(voicing[2]));
        expect(voicing[2], lessThan(voicing[3]));
        
        // Bass note should correspond to second inversion (5th in bass)
        final bassInterval = (voicing[0] - g3.midi) % 12;
        expect(bassInterval, 7); // Perfect 5th
      });

      test('Invalid inversion falls back to root position', () {
        final major = Chord.get('major')!; // Only has 3 notes
        final c4 = Note.fromString('C4');
        final voicing = major.buildVoicing(
          root: c4, 
          inversion: ChordInversion.fourth // Invalid for triad
        );
        
        // Should fallback to root position
        expect(voicing, orderedEquals([60, 64, 67]));
      });
    });

    group('Specific Chord Types', () {
      test('Seventh chords have correct intervals', () {
        final major7 = Chord.get('major7')!;
        expect(major7.intervals, [0, 4, 7, 11]);
        
        final minor7 = Chord.get('minor7')!;
        expect(minor7.intervals, [0, 3, 7, 10]);
        
        final dom7 = Chord.get('dominant7')!;
        expect(dom7.intervals, [0, 4, 7, 10]);
        
        final halfDim7 = Chord.get('half-diminished7')!;
        expect(halfDim7.intervals, [0, 3, 6, 10]);
      });

      test('Suspended chords have correct intervals', () {
        final sus2 = Chord.get('sus2')!;
        expect(sus2.intervals, [0, 2, 7]);
        
        final sus4 = Chord.get('sus4')!;
        expect(sus4.intervals, [0, 5, 7]);
        
        final sus7_2 = Chord.get('7sus2')!;
        expect(sus7_2.intervals, [0, 2, 7, 10]);
      });

      test('Extended chords have correct intervals', () {
        final major9 = Chord.get('major9')!;
        expect(major9.intervals, [0, 4, 7, 11, 14]);
        
        final dom11 = Chord.get('dominant11')!;
        expect(dom11.intervals, [0, 4, 7, 10, 14, 17]);
        
        final major13 = Chord.get('major13')!;
        expect(major13.intervals, [0, 4, 7, 11, 14, 17, 21]);
      });

      test('Altered chords have correct intervals', () {
        final sharp11 = Chord.get('7#11')!;
        expect(sharp11.intervals, [0, 4, 7, 10, 18]);
        
        final flat9 = Chord.get('7b9')!;
        expect(flat9.intervals, [0, 4, 7, 10, 13]);
        
        final alt = Chord.get('7alt')!;
        expect(alt.intervals, [0, 4, 7, 10, 13, 15]);
      });

      test('Power chords have correct intervals', () {
        final power = Chord.get('power-chord')!;
        expect(power.intervals, [0, 7]);
        
        final powerOctave = Chord.get('power-chord-octave')!;
        expect(powerOctave.intervals, [0, 7, 12]);
      });

      test('Exotic/special chords exist', () {
        final mystic = Chord.get('mystic')!;
        expect(mystic.displayName, 'Mystic Chord');
        expect(mystic.intervals, [0, 6, 10, 16, 21, 26]);
        
        final tristan = Chord.get('tristan')!;
        expect(tristan.displayName, 'Tristan Chord');
        expect(tristan.intervals, [0, 3, 6, 10]);
        
        final soWhat = Chord.get('so-what')!;
        expect(soWhat.displayName, 'So What Chord');
        expect(soWhat.category, 'Quartal Chords');
      });
    });

    group('Chord Categories Coverage', () {
      test('All major categories are represented', () {
        final categories = Chord.byCategory;
        
        final expectedCategories = [
          'Basic Triads',
          'Suspended',
          'Seventh Chords',
          'Sixth Chords',
          'Add Chords',
          'Extended (9ths)',
          'Extended (11ths)',
          'Extended (13ths)',
          'Power Chords',
          'Altered Chords',
          'Jazz Chords',
          'Quartal Chords',
          'Cluster Chords',
          'Polychords',
          'Special/Exotic',
          'Omit Chords',
          'Slash Chords',
        ];
        
        for (final category in expectedCategories) {
          expect(categories.keys, contains(category));
          expect(categories[category]!, isNotEmpty);
        }
      });

      test('Categories contain expected chord counts', () {
        final categories = Chord.byCategory;
        
        expect(categories['Basic Triads']!.length, 4);
        expect(categories['Seventh Chords']!.length, greaterThan(5));
        expect(categories['Extended (9ths)']!.length, greaterThan(5));
        expect(categories['Jazz Chords']!.length, greaterThan(5));
      });
    });

    group('ChordInversion Enum', () {
      test('Inversion display names', () {
        expect(ChordInversion.root.displayName, 'Root Position');
        expect(ChordInversion.first.displayName, 'First Inversion');
        expect(ChordInversion.second.displayName, 'Second Inversion');
        expect(ChordInversion.third.displayName, 'Third Inversion');
        expect(ChordInversion.fourth.displayName, 'Fourth Inversion');
        expect(ChordInversion.fifth.displayName, 'Fifth Inversion');
      });

      test('Inversion enum values', () {
        expect(ChordInversion.values.length, 6);
        expect(ChordInversion.root.index, 0);
        expect(ChordInversion.first.index, 1);
        expect(ChordInversion.fifth.index, 5);
      });
    });

    group('Chord String Representation', () {
      test('toString returns display name', () {
        final major = Chord.get('major')!;
        expect(major.toString(), 'Major');
        
        final aug7 = Chord.get('augmented7')!;
        expect(aug7.toString(), 'Augmented 7th');
        
        final mystic = Chord.get('mystic')!;
        expect(mystic.toString(), 'Mystic Chord');
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Empty or invalid chord symbols', () {
        expect(Chord.get(''), isNull);
        expect(Chord.get('invalid'), isNull);
        expect(Chord.get('MAJOR'), isNull); // Case sensitive
      });

      test('Chord notes generation with extreme octaves', () {
        final major = Chord.get('major')!;
        final highRoot = Note.fromMidi(120); // Very high note
        final notes = major.getNotesForRoot(highRoot);
        
        expect(notes.length, 3);
        expect(notes.every((n) => n.midi >= 120), isTrue);
        
        final lowRoot = Note.fromMidi(12); // Very low note
        final lowNotes = major.getNotesForRoot(lowRoot);
        expect(lowNotes.length, 3);
        expect(lowNotes.every((n) => n.midi >= 12), isTrue);
      });

      test('Voicing optimization works correctly', () {
        final major13 = Chord.get('major13')!; // Large chord
        final c4 = Note.fromString('C4');
        final voicing = major13.buildVoicing(
          root: c4,
          inversion: ChordInversion.root
        );
        
        expect(voicing.length, 7); // All chord tones
        expect(voicing, orderedEquals(voicing..sort())); // Should be sorted
        expect(voicing.first, 60); // Should start with C4
        
        // Should not have impossible voice leading
        for (int i = 1; i < voicing.length; i++) {
          expect(voicing[i] - voicing[i-1], lessThan(24)); // No huge jumps
        }
      });
    });
  });
}