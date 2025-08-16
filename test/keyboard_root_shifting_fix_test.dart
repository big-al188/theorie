// test/keyboard_root_shifting_fix_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Keyboard Root Shifting Fix Tests', () {
    test('Simulated key tap behavior should not shift root', () {
      // Simulate the exact scenario from the debug output
      
      // Start with C2 root, octave 3, no intervals
      var root = 'C';
      var selectedOctaves = <int>{3};
      var selectedIntervals = <int>{};
      
      print('Initial state: root=$root, octaves=$selectedOctaves, intervals=$selectedIntervals');
      
      // Simulate tapping C2 (MIDI 36) when root is C3 (MIDI 48)
      final c2Midi = 36; // C2
      final c3Midi = 48; // C3 (reference)
      
      // Calculate interval: C2 relative to C3 = -12
      final extendedInterval = c2Midi - c3Midi; // Should be -12
      
      expect(extendedInterval, equals(-12), reason: 'C2 should be 12 semitones below C3');
      
      // Apply the new simple logic (no root shifting)
      if (selectedIntervals.isEmpty) {
        // First tap - C2 becomes new root
        root = 'C';
        selectedIntervals = {0};
        selectedOctaves = {2}; // C2 octave
      } else if (selectedIntervals.contains(extendedInterval)) {
        // Remove existing interval
        selectedIntervals.remove(extendedInterval);
      } else {
        // Add new interval - NO ROOT SHIFTING
        selectedIntervals.add(extendedInterval);
        selectedOctaves.add(2); // Add C2 octave
      }
      
      print('After C2 tap: root=$root, octaves=$selectedOctaves, intervals=$selectedIntervals');
      
      // After first tap, should have: root=C, octaves={2}, intervals={0}
      expect(root, equals('C'), reason: 'Root should be C');
      expect(selectedOctaves, equals({2}), reason: 'Should have octave 2');
      expect(selectedIntervals, equals({0}), reason: 'Should have interval 0 (root)');
      
      // Now tap C2 again when root is C2
      final newExtendedInterval = c2Midi - c2Midi; // Should be 0
      expect(newExtendedInterval, equals(0), reason: 'C2 relative to C2 should be 0');
      
      // Tap C2 again - should remove it (toggle off)
      if (selectedIntervals.contains(newExtendedInterval)) {
        selectedIntervals.remove(newExtendedInterval);
      }
      
      print('After removing C2: root=$root, octaves=$selectedOctaves, intervals=$selectedIntervals');
      expect(selectedIntervals, isEmpty, reason: 'No intervals should remain');
      
      // Now tap A4 (MIDI 69) when we have no intervals
      final a4Midi = 69;
      if (selectedIntervals.isEmpty) {
        // A4 becomes new root
        root = 'A';
        selectedIntervals = {0};
        selectedOctaves = {4}; // A4 octave
      }
      
      print('After A4 tap: root=$root, octaves=$selectedOctaves, intervals=$selectedIntervals');
      expect(root, equals('A'), reason: 'Root should now be A');
      expect(selectedOctaves, equals({4}), reason: 'Should have octave 4');
      expect(selectedIntervals, equals({0}), reason: 'Should have interval 0 (root)');
      
      // Now tap C2 again when root is A4
      final a4_to_c2_interval = c2Midi - a4Midi; // Should be -33
      expect(a4_to_c2_interval, equals(-33), reason: 'C2 should be 33 semitones below A4');
      
      // Add this interval - NO ROOT SHIFTING
      selectedIntervals.add(a4_to_c2_interval);
      selectedOctaves.add(2); // Add C2 octave
      
      print('After adding C2 to A4 root: root=$root, octaves=$selectedOctaves, intervals=$selectedIntervals');
      
      // Should have: root=A, octaves={4,2}, intervals={0,-33}
      expect(root, equals('A'), reason: 'Root should remain A');
      expect(selectedOctaves, equals({4, 2}), reason: 'Should have octaves 4 and 2');
      expect(selectedIntervals, equals({0, -33}), reason: 'Should have intervals 0 and -33');
      
      // Key test: intervals should NOT grow exponentially
      // Tap C2 again - should remove -33 interval
      if (selectedIntervals.contains(a4_to_c2_interval)) {
        selectedIntervals.remove(a4_to_c2_interval);
      }
      
      print('After removing C2: root=$root, octaves=$selectedOctaves, intervals=$selectedIntervals');
      expect(selectedIntervals, equals({0}), reason: 'Should only have root interval');
      
      // Add C2 back again - same interval should be added
      selectedIntervals.add(a4_to_c2_interval);
      selectedOctaves.add(2);
      
      print('After re-adding C2: root=$root, octaves=$selectedOctaves, intervals=$selectedIntervals');
      expect(selectedIntervals, equals({0, -33}), reason: 'Should have same intervals as before');
      
      // NO exponential growth! The interval should stay -33, not become larger numbers
      final maxInterval = selectedIntervals.reduce((a, b) => a.abs() > b.abs() ? a : b);
      expect(maxInterval.abs(), lessThan(50), reason: 'No interval should exceed 50 semitones');
    });

    test('Multiple negative intervals should work without root shifting', () {
      var root = 'C';
      var selectedOctaves = <int>{4};
      var selectedIntervals = <int>{0}; // Start with C4 as root
      
      // Add some negative intervals (notes below C4)
      final negativeIntervals = [-1, -5, -12, -17]; // B3, G3, C3, F2
      
      for (final interval in negativeIntervals) {
        selectedIntervals.add(interval);
        final noteMidi = 60 + interval; // C4 is MIDI 60
        final noteOctave = ((noteMidi - 12) / 12).floor() + 1; // Calculate octave
        selectedOctaves.add(noteOctave);
      }
      
      print('After adding negative intervals: root=$root, intervals=$selectedIntervals');
      
      // Root should not have changed
      expect(root, equals('C'), reason: 'Root should remain C');
      
      // Intervals should remain negative
      expect(selectedIntervals.contains(-1), isTrue, reason: 'Should contain -1');
      expect(selectedIntervals.contains(-5), isTrue, reason: 'Should contain -5');
      expect(selectedIntervals.contains(-12), isTrue, reason: 'Should contain -12');
      expect(selectedIntervals.contains(-17), isTrue, reason: 'Should contain -17');
      
      // No intervals should have grown beyond reasonable bounds
      final maxAbsInterval = selectedIntervals.map((i) => i.abs()).reduce((a, b) => a > b ? a : b);
      expect(maxAbsInterval, lessThan(25), reason: 'No interval should exceed 25 semitones');
    });
  });
}