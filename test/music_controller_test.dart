// test/music_controller_test.dart - Comprehensive music controller tests
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/controllers/music_controller.dart';

void main() {
  group('Music Controller Tests', () {
    group('Mode Operations', () {
      test('should get mode roots correctly', () {
        expect(MusicController.getModeRoot('C', 'Major', 0), 'C');
        expect(MusicController.getModeRoot('C', 'Major', 1), 'D');
        expect(MusicController.getModeRoot('C', 'Major', 4), 'G');
        
        // Test with invalid scale
        expect(MusicController.getModeRoot('C', 'InvalidScale', 0), 'C');
      });

      test('should get available modes', () {
        final majorModes = MusicController.getAvailableModes('Major');
        expect(majorModes, contains('Ionian'));
        expect(majorModes, contains('Dorian'));
        expect(majorModes, contains('Mixolydian'));
        expect(majorModes.length, 7);
        
        // Test with invalid scale
        final invalidModes = MusicController.getAvailableModes('InvalidScale');
        expect(invalidModes, ['Mode 1']);
      });

      test('should get current mode names', () {
        expect(MusicController.getCurrentModeName('Major', 0), 'Ionian');
        expect(MusicController.getCurrentModeName('Major', 1), 'Dorian');
        expect(MusicController.getCurrentModeName('Major', 4), 'Mixolydian');
        
        // Test with invalid scale
        expect(MusicController.getCurrentModeName('InvalidScale', 2), 'Mode 3');
      });
    });

    group('Chord Operations', () {
      test('should generate chord symbols', () {
        expect(MusicController.getChordSymbol('C', 'major'), 'C');
        expect(MusicController.getChordSymbol('C', 'minor'), 'Cm');
        expect(MusicController.getChordSymbol('F#', 'major'), 'F#');
        expect(MusicController.getChordSymbol('Bb', 'minor'), 'Bbm');
        
        // Test with invalid chord
        expect(MusicController.getChordSymbol('C', 'invalid'), 'C');
      });

      test('should generate chord display names with inversions', () {
        expect(MusicController.getChordDisplayName('C', 'major', ChordInversion.root), 'C');
        expect(MusicController.getChordDisplayName('C', 'major', ChordInversion.first), 'C/E');
        expect(MusicController.getChordDisplayName('C', 'major', ChordInversion.second), 'C/G');
        
        // Test with seventh chord
        expect(MusicController.getChordDisplayName('G', 'dominant7', ChordInversion.third), 'G7/F');
        
        // Test with invalid chord
        expect(MusicController.getChordDisplayName('C', 'invalid', ChordInversion.first), 'C');
        
        // Test with invalid inversion (beyond chord intervals)
        expect(MusicController.getChordDisplayName('C', 'major', ChordInversion.fourth), 'C');
      });

      test('should analyze chords from notes', () {
        // C Major chord
        final cMajorNotes = [
          Note.fromString('C4'),
          Note.fromString('E4'),
          Note.fromString('G4'),
        ];
        final cMajorAnalysis = MusicController.analyzeChord(cMajorNotes);
        expect(cMajorAnalysis, 'C');
        
        // F minor chord
        final fMinorNotes = [
          Note.fromString('F3'),
          Note.fromString('Ab3'),
          Note.fromString('C4'),
        ];
        final fMinorAnalysis = MusicController.analyzeChord(fMinorNotes);
        expect(fMinorAnalysis, 'Fm');
        
        // Dm7 chord
        final dm7Notes = [
          Note.fromString('D4'),
          Note.fromString('F4'),
          Note.fromString('A4'),
          Note.fromString('C5'),
        ];
        final dm7Analysis = MusicController.analyzeChord(dm7Notes);
        expect(dm7Analysis, 'Dm7');
        
        // Empty chord
        final emptyAnalysis = MusicController.analyzeChord([]);
        expect(emptyAnalysis, isNull);
        
        // Unrecognized chord (random notes)
        final randomNotes = [
          Note.fromString('C4'),
          Note.fromString('C#4'),
          Note.fromString('D4'),
          Note.fromString('D#4'),
        ];
        final randomAnalysis = MusicController.analyzeChord(randomNotes);
        expect(randomAnalysis, isNull);
      });
    });

    group('Scale and Note Operations', () {
      test('should check note membership in scales', () {
        final c4 = Note.fromString('C4');
        final d4 = Note.fromString('D4');
        final cs4 = Note.fromString('C#4');
        
        expect(MusicController.isNoteInScale(c4, 'C', 'Major'), isTrue);
        expect(MusicController.isNoteInScale(d4, 'C', 'Major'), isTrue);
        expect(MusicController.isNoteInScale(cs4, 'C', 'Major'), isFalse);
        
        // Test with different root - F# is in G Major, not C#
        final fs4 = Note.fromString('F#4');
        expect(MusicController.isNoteInScale(fs4, 'G', 'Major'), isTrue); // F# in G Major
        
        // Test with invalid scale
        expect(MusicController.isNoteInScale(c4, 'C', 'InvalidScale'), isFalse);
      });

      test('should get intervals between notes', () {
        final c4 = Note.fromString('C4');
        final g4 = Note.fromString('G4');
        final e4 = Note.fromString('E4');
        
        final fifth = MusicController.getInterval(c4, g4);
        expect(fifth.semitones, 7);
        
        final third = MusicController.getInterval(c4, e4);
        expect(third.semitones, 4);
        
        final unison = MusicController.getInterval(c4, c4);
        expect(unison.semitones, 0);
        
        // Descending interval
        final descendingFifth = MusicController.getInterval(g4, c4);
        expect(descendingFifth.semitones, 7); // intervalTo returns absolute value
      });

      test('should transpose notes', () {
        final c4 = Note.fromString('C4');
        final g4 = MusicController.transposeNote(c4, 7);
        
        expect(g4.name, 'G');
        expect(g4.octave, 4);
        
        final c5 = MusicController.transposeNote(c4, 12);
        expect(c5.octave, 5);
        
        // Negative transposition
        final f3 = MusicController.transposeNote(c4, -7);
        expect(f3.name, 'F');
        expect(f3.octave, 3);
      });

      test('should get enharmonic equivalents', () {
        final cs4 = Note.fromString('C#4');
        final enharmonic = MusicController.getEnharmonic(cs4);
        
        expect(enharmonic.name, 'D♭');
        expect(enharmonic.octave, 4);
        expect(enharmonic.pitchClass, cs4.pitchClass);
        
        final fs4 = Note.fromString('F#4');
        final fsEnharmonic = MusicController.getEnharmonic(fs4);
        expect(fsEnharmonic.name, 'G♭');
      });
    });

    group('Utility Functions', () {
      test('should determine flat preference for roots', () {
        expect(MusicController.shouldUseFlats('F'), isTrue);
        expect(MusicController.shouldUseFlats('Bb'), isTrue);
        expect(MusicController.shouldUseFlats('Eb'), isTrue);
        expect(MusicController.shouldUseFlats('Ab'), isTrue);
        expect(MusicController.shouldUseFlats('Db'), isTrue);
        
        expect(MusicController.shouldUseFlats('C'), isFalse);
        expect(MusicController.shouldUseFlats('G'), isFalse);
        expect(MusicController.shouldUseFlats('D'), isFalse);
        expect(MusicController.shouldUseFlats('A'), isFalse);
        expect(MusicController.shouldUseFlats('E'), isFalse);
        
        // Test sharps
        expect(MusicController.shouldUseFlats('F#'), isFalse);
        expect(MusicController.shouldUseFlats('C#'), isFalse);
      });

      test('should get default starting octave for tuning', () {
        // Standard guitar tuning
        final guitarTuning = ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'];
        
        final cOctave = MusicController.getDefaultStartingOctave('C', guitarTuning);
        expect(cOctave, greaterThanOrEqualTo(2));
        
        final gOctave = MusicController.getDefaultStartingOctave('G', guitarTuning);
        expect(gOctave, 2); // First G above lowest string E2 is G2
        
        final eOctave = MusicController.getDefaultStartingOctave('E', guitarTuning);
        expect(eOctave, 2); // E2 is the lowest E
        
        // Empty tuning
        final emptyOctave = MusicController.getDefaultStartingOctave('C', []);
        expect(emptyOctave, 3); // AppConstants.defaultOctave
        
        // Bass tuning (lower)
        final bassTuning = ['E1', 'A1', 'D2', 'G2'];
        final bassEOctave = MusicController.getDefaultStartingOctave('E', bassTuning);
        expect(bassEOctave, 1);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle invalid scale names gracefully', () {
        expect(MusicController.getModeRoot('C', '', 0), 'C');
        expect(MusicController.getAvailableModes(''), ['Mode 1']);
        expect(MusicController.getCurrentModeName('NonExistent', 5), 'Mode 6');
      });

      test('should handle invalid chord types gracefully', () {
        expect(MusicController.getChordSymbol('G', ''), 'G');
        expect(MusicController.getChordSymbol('A', 'FakeChord'), 'A');
        expect(MusicController.getChordDisplayName('F', '', ChordInversion.first), 'F');
      });

      test('should handle octave edge cases in tuning calculation', () {
        // Very high tuning
        final highTuning = ['C7', 'E7', 'G7'];
        final highOctave = MusicController.getDefaultStartingOctave('C', highTuning);
        expect(highOctave, 7);
        
        // Very low tuning
        final lowTuning = ['C0', 'E0', 'G0'];
        final lowOctave = MusicController.getDefaultStartingOctave('G', lowTuning);
        expect(lowOctave, 0);
      });

      test('should handle duplicate notes in chord analysis', () {
        // Chord with duplicate pitch classes in different octaves
        final duplicateNotes = [
          Note.fromString('C3'),
          Note.fromString('E4'),
          Note.fromString('G4'),
          Note.fromString('C5'), // Duplicate C
        ];
        final analysis = MusicController.analyzeChord(duplicateNotes);
        expect(analysis, 'C'); // Should still recognize as C major
      });

      test('should handle complex chord analysis', () {
        // Test with a more complex chord (Cmaj7)
        final cmaj7Notes = [
          Note.fromString('C4'),
          Note.fromString('E4'),
          Note.fromString('G4'),
          Note.fromString('B4'),
        ];
        final cmaj7Analysis = MusicController.analyzeChord(cmaj7Notes);
        expect(cmaj7Analysis, 'Cmaj7');
        
        // Test chord in different inversions (should still identify root)
        final firstInversionNotes = [
          Note.fromString('E3'),
          Note.fromString('G3'),
          Note.fromString('C4'),
        ];
        final inversionAnalysis = MusicController.analyzeChord(firstInversionNotes);
        expect(inversionAnalysis, 'C');
      });

      test('should handle large interval calculations', () {
        final c1 = Note.fromMidi(24); // Very low C
        final c8 = Note.fromMidi(96); // Very high C
        
        final largeInterval = MusicController.getInterval(c1, c8);
        expect(largeInterval.semitones, 72); // 6 octaves
        
        final transposed = MusicController.transposeNote(c1, 72);
        expect(transposed.midi, c8.midi);
      });
    });
  });
}