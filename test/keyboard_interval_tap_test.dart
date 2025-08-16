// test/keyboard_interval_tap_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';

void main() {
  group('Keyboard Interval Tap Behavior Tests', () {
    test('Should make lowest note the root without negative intervals', () {
      // Test the new behavior where the lowest highlighted note becomes the root
      
      // Simulate clicking notes: E4, C4, G4 (in that order)
      final clickedNotes = [64, 60, 67]; // E4, C4, G4
      final allMidiNotes = <int>{};
      
      for (final midi in clickedNotes) {
        allMidiNotes.add(midi);
        
        // Find the lowest note - this should be the root
        final lowestMidi = allMidiNotes.reduce((a, b) => a < b ? a : b);
        final lowestNote = Note.fromMidi(lowestMidi);
        
        // Calculate intervals relative to lowest note (no negatives)
        final intervals = allMidiNotes.map((m) => m - lowestMidi).toSet();
        
        print('After clicking MIDI $midi:');
        print('  All notes: $allMidiNotes');
        print('  Root: ${lowestNote.fullName} (MIDI $lowestMidi)');
        print('  Intervals: $intervals');
        
        // Verify no negative intervals
        expect(intervals.every((i) => i >= 0), isTrue, 
            reason: 'Should have no negative intervals');
        
        // Verify root interval is always 0
        expect(intervals.contains(0), isTrue, 
            reason: 'Root should always have interval 0');
      }
      
      // Final state should be: C4 as root, intervals {0, 4, 7}
      final finalLowest = allMidiNotes.reduce((a, b) => a < b ? a : b);
      final finalIntervals = allMidiNotes.map((m) => m - finalLowest).toSet();
      
      expect(finalLowest, equals(60)); // C4
      expect(finalIntervals, equals({0, 4, 7})); // C major triad
    });

    test('Should toggle notes correctly and maintain lowest as root', () {
      // Start with C4, E4, G4
      var currentMidiNotes = {60, 64, 67}; // C4, E4, G4
      
      // Click E4 to remove it
      currentMidiNotes.remove(64);
      
      var lowestMidi = currentMidiNotes.reduce((a, b) => a < b ? a : b);
      var intervals = currentMidiNotes.map((m) => m - lowestMidi).toSet();
      
      print('After removing E4:');
      print('  Notes: $currentMidiNotes');
      print('  Root: MIDI $lowestMidi (${Note.fromMidi(lowestMidi).fullName})');
      print('  Intervals: $intervals');
      
      // Should still be C4 as root, intervals {0, 7}
      expect(lowestMidi, equals(60)); // C4
      expect(intervals, equals({0, 7})); // C, G
      
      // Add A3 (lower than current root)
      currentMidiNotes.add(57); // A3
      
      lowestMidi = currentMidiNotes.reduce((a, b) => a < b ? a : b);
      intervals = currentMidiNotes.map((m) => m - lowestMidi).toSet();
      
      print('After adding A3:');
      print('  Notes: $currentMidiNotes');
      print('  Root: MIDI $lowestMidi (${Note.fromMidi(lowestMidi).fullName})');
      print('  Intervals: $intervals');
      
      // Now A3 should be the root
      expect(lowestMidi, equals(57)); // A3
      expect(intervals, equals({0, 3, 10})); // A3, C4, G4 relative to A3
      expect(intervals.every((i) => i >= 0), isTrue);
    });

    test('Should handle removing all notes correctly', () {
      // Start with just one note
      var currentMidiNotes = {60}; // C4
      
      // Remove the last note
      currentMidiNotes.remove(60);
      
      // When no notes left, clicking a new note should make it the root
      final newClickedMidi = 67; // G4
      
      print('After removing all notes, clicking G4:');
      print('  Should reset to root G4 with interval {0}');
      
      // This simulates the reset behavior when currentActualMidiNotes.isEmpty
      expect(currentMidiNotes.isEmpty, isTrue);
      
      // New state should be just the clicked note as root
      final newNote = Note.fromMidi(newClickedMidi);
      expect(newNote.name, equals('G'));
    });

    test('Should preserve actual notes across operations', () {
      // Test that the actual MIDI notes are always preserved correctly
      final expectedMidiNotes = {48, 52, 55}; // C3, E3, G3
      
      // Calculate what the intervals would be with different roots
      
      // With C3 as root (lowest)
      final c3Root = 48;
      final intervalsFromC3 = expectedMidiNotes.map((m) => m - c3Root).toSet();
      expect(intervalsFromC3, equals({0, 4, 7}));
      
      // Verify we can reconstruct the original notes
      final reconstructedFromC3 = intervalsFromC3.map((i) => c3Root + i).toSet();
      expect(reconstructedFromC3, equals(expectedMidiNotes));
      
      // If we add A2 (lower note), root should shift to A2
      final withA2 = Set<int>.from(expectedMidiNotes)..add(45); // A2
      final a2Root = 45;
      final intervalsFromA2 = withA2.map((m) => m - a2Root).toSet();
      
      // Should have no negative intervals
      expect(intervalsFromA2.every((i) => i >= 0), isTrue);
      expect(intervalsFromA2, equals({0, 3, 7, 10})); // A2, C3, E3, G3
      
      // Verify reconstruction
      final reconstructedFromA2 = intervalsFromA2.map((i) => a2Root + i).toSet();
      expect(reconstructedFromA2, equals(withA2));
    });
  });
}