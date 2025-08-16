// test/keyboard_root_octave_change_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';

void main() {
  group('Keyboard Root Octave Change Tests', () {
    test('Intervals should represent same notes when root octave changes', () {
      // Scenario: User has selected some notes, then the root octave changes
      // The same actual notes should remain highlighted
      
      // Initial state: Root C4, with some intervals selected
      var rootNote = 'C';
      var rootOctave = 4;
      var selectedIntervals = <int>{0, 4, 7}; // C4, E4, G4 (C major triad)
      
      // Calculate the actual MIDI notes these intervals represent
      final rootMidi = Note.fromString('$rootNote$rootOctave').midi; // C4 = 60
      final actualMidiNotes = selectedIntervals.map((interval) => rootMidi + interval).toSet();
      
      print('Initial state:');
      print('  Root: $rootNote$rootOctave (MIDI $rootMidi)');
      print('  Intervals: $selectedIntervals');
      print('  Actual MIDI notes: $actualMidiNotes');
      
      // The actual notes should be C4(60), E4(64), G4(67)
      expect(actualMidiNotes, equals({60, 64, 67}));
      
      // Now root octave changes to C3
      rootOctave = 3;
      final newRootMidi = Note.fromString('$rootNote$rootOctave').midi; // C3 = 48
      
      // CORRECT behavior: Recalculate intervals to point to the same actual notes
      final correctNewIntervals = actualMidiNotes.map((midi) => midi - newRootMidi).toSet();
      
      print('After root octave change (CORRECT):');
      print('  New root: $rootNote$rootOctave (MIDI $newRootMidi)');
      print('  New intervals (correct): $correctNewIntervals');
      print('  Actual MIDI notes: ${correctNewIntervals.map((i) => newRootMidi + i).toSet()}');
      
      // The correct new intervals should be {12, 16, 19} (one octave higher)
      expect(correctNewIntervals, equals({12, 16, 19}));
      
      // Verify the same actual notes are still represented
      final newActualMidiNotes = correctNewIntervals.map((interval) => newRootMidi + interval).toSet();
      expect(newActualMidiNotes, equals({60, 64, 67}), 
          reason: 'Same actual MIDI notes should be highlighted after root octave change');
      
      // INCORRECT behavior (what might be happening currently):
      // Simply keeping the same intervals without recalculation
      final incorrectNewIntervals = selectedIntervals; // {0, 4, 7}
      final incorrectMidiNotes = incorrectNewIntervals.map((interval) => newRootMidi + interval).toSet();
      
      print('Incorrect behavior (shifting):');
      print('  Same intervals: $incorrectNewIntervals');
      print('  Wrong MIDI notes: $incorrectMidiNotes');
      
      // This would give C3(48), E3(52), G3(55) instead of C4(60), E4(64), G4(67)
      expect(incorrectMidiNotes, equals({48, 52, 55}));
      expect(incorrectMidiNotes, isNot(equals(actualMidiNotes)), 
          reason: 'Keeping same intervals would highlight different notes');
    });

    test('Root octave change should preserve actual note positions', () {
      // Test multiple octave changes
      var rootNote = 'A';
      var rootOctave = 4;
      var selectedIntervals = <int>{0, -12, 3, 6}; // A4, A3, C5, D#5
      
      // Calculate initial MIDI notes
      var rootMidi = Note.fromString('$rootNote$rootOctave').midi; // A4 = 69
      var actualMidiNotes = selectedIntervals.map((interval) => rootMidi + interval).toSet();
      
      print('Initial state:');
      print('  Root: $rootNote$rootOctave (MIDI $rootMidi)');
      print('  Intervals: $selectedIntervals');
      print('  Actual MIDI notes: $actualMidiNotes');
      
      // Should be A4(69), A3(57), C5(72), D#5(75)
      expect(actualMidiNotes, equals({69, 57, 72, 75}));
      
      // Change root to A2
      rootOctave = 2;
      rootMidi = Note.fromString('$rootNote$rootOctave').midi; // A2 = 45
      
      // Recalculate intervals to maintain same notes
      selectedIntervals = actualMidiNotes.map((midi) => midi - rootMidi).toSet();
      
      print('After changing to A2:');
      print('  New root: $rootNote$rootOctave (MIDI $rootMidi)');
      print('  New intervals: $selectedIntervals');
      print('  Actual MIDI notes: ${selectedIntervals.map((i) => rootMidi + i).toSet()}');
      
      // Verify same notes are still represented
      final newMidiNotes = selectedIntervals.map((interval) => rootMidi + interval).toSet();
      expect(newMidiNotes, equals({69, 57, 72, 75}), 
          reason: 'Same MIDI notes should be preserved');
      
      // Change root to A6
      rootOctave = 6;
      rootMidi = Note.fromString('$rootNote$rootOctave').midi; // A6 = 93
      
      // Recalculate intervals again
      selectedIntervals = actualMidiNotes.map((midi) => midi - rootMidi).toSet();
      
      print('After changing to A6:');
      print('  New root: $rootNote$rootOctave (MIDI $rootMidi)');
      print('  New intervals: $selectedIntervals');
      print('  Actual MIDI notes: ${selectedIntervals.map((i) => rootMidi + i).toSet()}');
      
      // Should have negative intervals now since root is higher than some notes
      expect(selectedIntervals.any((i) => i < 0), isTrue, 
          reason: 'Should have negative intervals when root is above some selected notes');
      
      // But same notes should still be represented
      final finalMidiNotes = selectedIntervals.map((interval) => rootMidi + interval).toSet();
      expect(finalMidiNotes, equals({69, 57, 72, 75}), 
          reason: 'Same MIDI notes should be preserved after multiple octave changes');
    });
  });
}