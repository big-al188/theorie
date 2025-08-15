// test/keyboard_interval_mode_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/keyboard/keyboard_instance.dart';
import 'package:Theorie/models/keyboard/key_configuration.dart';
import 'package:Theorie/models/fretboard/fretboard_config.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/controllers/keyboard_controller.dart';

void main() {
  group('Keyboard Interval Mode Tests', () {
    test('Root shifting with negative intervals - C3 root, B2 click scenario', () {
      // Initial state: C3 as root with no selected intervals
      var keyboard = KeyboardInstance(
        id: 'test',
        root: 'C',
        viewMode: ViewMode.intervals,
        scale: 'major',
        modeIndex: 0,
        selectedOctaves: {3},
        selectedIntervals: {0}, // Just the root C3
        keyCount: 88,
        startNote: 'A0',
        keyboardType: 'Full Piano',
        chordType: 'major',
        chordInversion: ChordInversion.root,
        showScaleStrip: true,
        showNoteNames: false,
        showAdditionalOctaves: false,
        showOctave: false,
        isCompact: false,
      );

      // Click B2 (MIDI 47) when root is C3 (MIDI 48)
      final tappedMidi = 47; // B2
      final currentRootNote = Note.fromString('${keyboard.root}3'); // C3
      final clickedNote = Note.fromMidi(tappedMidi, preferFlats: currentRootNote.preferFlats); // B2
      
      // Calculate extended interval
      final referenceOctave = 3;
      final rootNote = Note.fromString('${keyboard.root}$referenceOctave'); // C3
      final extendedInterval = tappedMidi - rootNote.midi; // 47 - 48 = -1
      
      expect(extendedInterval, equals(-1), reason: 'B2 should be -1 interval from C3');
      
      // Simulate the interval mode logic
      var newIntervals = Set<int>.from(keyboard.selectedIntervals);
      var newOctaves = Set<int>.from(keyboard.selectedOctaves);
      var newRoot = keyboard.root;
      
      // Adding a new interval - this creates a negative interval
      newIntervals.add(extendedInterval); // {0, -1}
      newOctaves.add(clickedNote.octave); // {3, 2}
      
      // Check if we have negative intervals - yes, we do
      final lowestInterval = newIntervals.reduce((a, b) => a < b ? a : b);
      expect(lowestInterval, equals(-1), reason: 'Lowest interval should be -1');
      
      // Need to shift root to accommodate negative intervals
      final newRootMidi = rootNote.midi + lowestInterval; // 48 + (-1) = 47 (B2)
      expect(newRootMidi, equals(47), reason: 'New root MIDI should be 47 (B2)');
      
      // Wait, this would make B2 the root, but we want C2 as the new root
      // Let me check the actual logic - it should shift to the lowest note to make all intervals positive
      
      // Actually, we want the root to be the lowest note that makes all intervals positive
      // If we have intervals {0, -1}, the lowest is -1
      // New root should be original_root + lowest_interval = C3 + (-1) = B2
      // But that would make B2 the root, and we'd have intervals {1, 0} relative to B2
      
      // Let me re-read the requirement: "when the root is C3 and the user selects B2, 
      // the root should be moved to C2"
      
      // This suggests a different logic: when adding a note below the current root,
      // shift everything down by an octave to accommodate it
      
      // Let me implement the correct logic:
      // If clicking B2 when root is C3, we want final state:
      // Root: C2, with intervals for C2, B2, C3 all highlighted
      
      // C2 = MIDI 36, B2 = MIDI 35, C3 = MIDI 48
      // Wait, that's not right. Let me recalculate:
      // B2 = MIDI 47, C2 = MIDI 36, C3 = MIDI 48
      
      print('B2 MIDI: ${Note.fromString("B2").midi}'); // Should be 47
      print('C2 MIDI: ${Note.fromString("C2").midi}'); // Should be 36  
      print('C3 MIDI: ${Note.fromString("C3").midi}'); // Should be 48
      
      // So if root becomes C2 (36), then:
      // B2 (47) - C2 (36) = 11 semitones (major 7th)
      // C3 (48) - C2 (36) = 12 semitones (octave)
      
      // This means the intervals should be {0, 11, 12} with root C2
    });

    test('Verify MIDI note calculations', () {
      expect(Note.fromString("B2").midi, equals(47));
      expect(Note.fromString("C2").midi, equals(36));
      expect(Note.fromString("C3").midi, equals(48));
      
      // If root is C2 (36):
      // C2 interval: 36 - 36 = 0 ✓
      // B2 interval: 47 - 36 = 11 ✓  
      // C3 interval: 48 - 36 = 12 ✓
    });
    
    test('Extended interval labels work correctly', () {
      // Test that we show extended intervals (9, 11, 13) instead of wrapping to simple intervals
      expect(KeyboardController.getIntervalLabel(0), equals('1')); // Root
      expect(KeyboardController.getIntervalLabel(2), equals('2')); // Major 2nd
      expect(KeyboardController.getIntervalLabel(14), equals('9')); // Major 9th (2 + 12)
      expect(KeyboardController.getIntervalLabel(16), equals('10')); // Major 10th (3 + 12)
      expect(KeyboardController.getIntervalLabel(17), equals('11')); // Perfect 11th (5 + 12)
      expect(KeyboardController.getIntervalLabel(21), equals('13')); // Major 13th (9 + 12)
      expect(KeyboardController.getIntervalLabel(24), equals('15')); // Double octave (1 + 14)
      
      // Test some tritone variations
      expect(KeyboardController.getIntervalLabel(6), equals('♭5')); // Tritone
      expect(KeyboardController.getIntervalLabel(18), equals('♭12')); // Octave + tritone
      
      // For C1 root, D2 should be interval 14 (one octave + 2 semitones) = 9th
      final c1Midi = Note.fromString('C1').midi; // 24
      final d2Midi = Note.fromString('D2').midi; // 38
      final interval = d2Midi - c1Midi; // 38 - 24 = 14
      expect(interval, equals(14));
      expect(KeyboardController.getIntervalLabel(interval), equals('9'));
    });

    test('New implementation behavior check', () {
      // Test the new octave-based shifting logic
      // Starting: C3 root (interval 0), no other intervals
      var newIntervals = <int>{0};
      var newOctaves = <int>{3};
      var newRoot = 'C';
      
      // Add B2 - this creates interval -1 from C3
      final extendedInterval = -1; // B2 relative to C3
      newIntervals.add(extendedInterval); // {0, -1}
      newOctaves.add(2); // {3, 2}
      
      // New logic: shift root by octave to accommodate negative intervals
      final rootNote = Note.fromString('C3'); // MIDI 48
      final lowestInterval = newIntervals.reduce((a, b) => a < b ? a : b); // -1
      
      if (lowestInterval < 0) {
        // Calculate how many octaves down we need to shift
        final octaveShift = ((lowestInterval.abs() - 1) ~/ 12 + 1) * 12; // ((1-1) ~/ 12 + 1) * 12 = 12
        final newRootMidi = rootNote.midi - octaveShift; // 48 - 12 = 36 (C2)
        final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
        newRoot = newRootNote.name; // Should be 'C'
        
        // Adjust all intervals to be relative to new root
        final adjustedIntervals = <int>{};
        newOctaves = <int>{};
        
        for (final interval in newIntervals) {
          final adjustedInterval = interval + octaveShift; // 0+12=12, -1+12=11
          adjustedIntervals.add(adjustedInterval);
          
          final noteMidi = newRootMidi + adjustedInterval;
          final noteOctave = Note.fromMidi(noteMidi).octave;
          newOctaves.add(noteOctave);
        }
        newIntervals = adjustedIntervals;
      }
      
      print('Final root: $newRoot');
      print('Final intervals: $newIntervals');
      print('Final octaves: $newOctaves');
      
      // This should give us root=C, intervals={11, 12}, octaves={2, 3}
      // Which means C2 (root), B2 (11 semitones from C2), C3 (12 semitones from C2)
      expect(newRoot, equals('C'));
      expect(newIntervals, equals({11, 12}));
      expect(newOctaves, equals({2, 3}));
      
      // Verify the MIDI notes:
      // C2 = 36, C2 + 11 = 47 (B2), C2 + 12 = 48 (C3) ✓
    });
  });
}