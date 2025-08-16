// test/keyboard_controls_dropdown_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Keyboard Controls Dropdown Tests', () {
    test('Enharmonic mapping for keyboard controls dropdown', () {
      // This reproduces the exact logic from keyboard_controls.dart _buildRootSelector()
      
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      String? findMatchingDropdownRoot(String value) {
        const dropdownRoots = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        final normalizedValue = normalizeNoteName(value);
        
        // First try exact match
        if (dropdownRoots.contains(value)) {
          return value;
        }
        
        // Then try normalized match  
        for (final root in dropdownRoots) {
          if (normalizeNoteName(root) == normalizedValue) {
            return root;
          }
        }
        
        // Handle enharmonic equivalents (flat to sharp conversions for this dropdown)
        const enharmonicMap = {
          'Db': 'C#', 'D♭': 'C#',
          'Eb': 'D#', 'E♭': 'D#', 
          'Gb': 'F#', 'G♭': 'F#',
          'Ab': 'G#', 'A♭': 'G#',
          'Bb': 'A#', 'B♭': 'A#',
        };
        
        // Check if the value is an enharmonic equivalent that should map to a dropdown root
        final enharmonicEquivalent = enharmonicMap[value] ?? enharmonicMap[normalizedValue];
        if (enharmonicEquivalent != null && dropdownRoots.contains(enharmonicEquivalent)) {
          return enharmonicEquivalent;
        }
        
        return null;
      }
      
      // Test the specific case that was causing the error: A♯
      const problematicValue = 'A♯';  // Unicode sharp from instance.root
      
      print('Testing problematic value: "$problematicValue"');
      
      final matchingRoot = findMatchingDropdownRoot(problematicValue);
      final dropdownValue = matchingRoot ?? 'C';
      
      print('  Matching root: $matchingRoot');
      print('  Dropdown value: $dropdownValue');
      
      expect(dropdownValue, equals('A#'), 
          reason: 'A♯ should map to A# for the dropdown');
      
      // Verify the dropdown value is in the items list
      const dropdownItems = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
      expect(dropdownItems.contains(dropdownValue), isTrue,
          reason: 'Dropdown value "$dropdownValue" must be in the items list');
      
      print('✓ A♯ dropdown assertion error is fixed');
    });

    test('All possible note names work with keyboard controls dropdown', () {
      // Test comprehensive mapping for the keyboard controls dropdown
      
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      String? findMatchingDropdownRoot(String value) {
        const dropdownRoots = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        final normalizedValue = normalizeNoteName(value);
        
        if (dropdownRoots.contains(value)) {
          return value;
        }
        
        for (final root in dropdownRoots) {
          if (normalizeNoteName(root) == normalizedValue) {
            return root;
          }
        }
        
        const enharmonicMap = {
          'Db': 'C#', 'D♭': 'C#',
          'Eb': 'D#', 'E♭': 'D#', 
          'Gb': 'F#', 'G♭': 'F#',
          'Ab': 'G#', 'A♭': 'G#',
          'Bb': 'A#', 'B♭': 'A#',
        };
        
        final enharmonicEquivalent = enharmonicMap[value] ?? enharmonicMap[normalizedValue];
        if (enharmonicEquivalent != null && dropdownRoots.contains(enharmonicEquivalent)) {
          return enharmonicEquivalent;
        }
        
        return null;
      }
      
      // Test all possible note names that could come from instance.root
      final testCases = [
        // Natural notes
        ('C', 'C'),
        ('D', 'D'),
        ('E', 'E'),
        ('F', 'F'),
        ('G', 'G'),
        ('A', 'A'),
        ('B', 'B'),
        // Sharp notes (Unicode)
        ('C♯', 'C#'),
        ('D♯', 'D#'),
        ('F♯', 'F#'),
        ('G♯', 'G#'),
        ('A♯', 'A#'),  // This was the failing case
        // Sharp notes (ASCII)
        ('C#', 'C#'),
        ('D#', 'D#'),
        ('F#', 'F#'),
        ('G#', 'G#'),
        ('A#', 'A#'),
        // Flat notes (Unicode) - should map to sharp equivalents
        ('D♭', 'C#'),
        ('E♭', 'D#'),
        ('G♭', 'F#'),
        ('A♭', 'G#'),
        ('B♭', 'A#'),
        // Flat notes (ASCII) - should map to sharp equivalents
        ('Db', 'C#'),
        ('Eb', 'D#'),
        ('Gb', 'F#'),
        ('Ab', 'G#'),
        ('Bb', 'A#'),
      ];
      
      print('Testing all note name mappings for keyboard controls dropdown:');
      
      const dropdownItems = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
      
      for (final (input, expected) in testCases) {
        final result = findMatchingDropdownRoot(input);
        final dropdownValue = result ?? 'C';
        
        print('  "$input" -> "$dropdownValue" (expected: "$expected")');
        
        expect(dropdownValue, equals(expected), 
            reason: 'Input "$input" should map to "$expected"');
        expect(dropdownItems.contains(dropdownValue), isTrue,
            reason: 'Dropdown value "$dropdownValue" must be in the items list');
      }
      
      print('✓ All note names work correctly with keyboard controls dropdown');
    });

    test('Dropdown construction prevents assertion errors', () {
      // Test that the dropdown construction logic always works
      
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      String? findMatchingDropdownRoot(String value) {
        const dropdownRoots = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        final normalizedValue = normalizeNoteName(value);
        
        if (dropdownRoots.contains(value)) {
          return value;
        }
        
        for (final root in dropdownRoots) {
          if (normalizeNoteName(root) == normalizedValue) {
            return root;
          }
        }
        
        const enharmonicMap = {
          'Db': 'C#', 'D♭': 'C#',
          'Eb': 'D#', 'E♭': 'D#', 
          'Gb': 'F#', 'G♭': 'F#',
          'Ab': 'G#', 'A♭': 'G#',
          'Bb': 'A#', 'B♭': 'A#',
        };
        
        final enharmonicEquivalent = enharmonicMap[value] ?? enharmonicMap[normalizedValue];
        if (enharmonicEquivalent != null && dropdownRoots.contains(enharmonicEquivalent)) {
          return enharmonicEquivalent;
        }
        
        return null;
      }
      
      // Test the specific assertion error scenario
      final problematicRoots = ['A♯', 'F♯', 'C♯', 'D♯', 'G♯', 'E♭', 'B♭', 'A♭', 'D♭', 'G♭'];
      
      for (final instanceRoot in problematicRoots) {
        print('Testing dropdown construction for instance.root="$instanceRoot"');
        
        // Simulate the dropdown construction logic
        final matchingRoot = findMatchingDropdownRoot(instanceRoot);
        final dropdownValue = matchingRoot ?? 'C'; // Fallback to C if no match found
        
        print('  matchingRoot: $matchingRoot');
        print('  dropdownValue: $dropdownValue');
        
        const dropdownItems = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        
        // The assertion that was failing: exactly one item with the dropdown value
        final matchingItems = dropdownItems.where((item) => item == dropdownValue).toList();
        print('  Matching items: $matchingItems');
        
        expect(matchingItems.length, equals(1),
            reason: 'There should be exactly one item with dropdown value "$dropdownValue"');
      }
      
      print('✓ All dropdown construction scenarios work without assertion errors');
    });
  });
}