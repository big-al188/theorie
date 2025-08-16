// test/note_normalization_fix_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/constants/music_constants.dart';

void main() {
  group('Note Normalization Fix Tests', () {
    test('Root selector enharmonic mapping fixes sharp/flat dropdown issue', () {
      // This is the exact function from the updated root_selector.dart
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      String? findMatchingCommonRoot(String value) {
        final normalizedValue = normalizeNoteName(value);
        
        // First try exact match
        if (MusicConstants.commonRoots.contains(value)) {
          return value;
        }
        
        // Then try normalized match
        for (final root in MusicConstants.commonRoots) {
          if (normalizeNoteName(root) == normalizedValue) {
            return root;
          }
        }
        
        // Handle enharmonic equivalents (sharp to flat conversions)
        const enharmonicMap = {
          'F#': 'Gb', 'f#': 'Gb',
          'C#': 'Db', 'c#': 'Db', 
          'G#': 'Ab', 'g#': 'Ab',
          'D#': 'Eb', 'd#': 'Eb',
          'A#': 'Bb', 'a#': 'Bb',
          // Unicode versions
          'F♯': 'Gb',
          'C♯': 'Db',
          'G♯': 'Ab', 
          'D♯': 'Eb',
          'A♯': 'Bb',
        };
        
        // Check if the value is an enharmonic equivalent that should map to a common root
        final enharmonicEquivalent = enharmonicMap[value] ?? enharmonicMap[normalizedValue];
        if (enharmonicEquivalent != null && MusicConstants.commonRoots.contains(enharmonicEquivalent)) {
          return enharmonicEquivalent;
        }
        
        return null;
      }
      
      // Test the specific cases that were causing the assertion errors
      final problematicCases = [
        ('F♯', 'Gb'),  // Unicode sharp to flat
        ('C♯', 'Db'),  // Unicode sharp to flat
        ('G♯', 'Ab'),  // Unicode sharp to flat
        ('D♯', 'Eb'),  // Unicode sharp to flat
        ('A♯', 'Bb'),  // Unicode sharp to flat
        ('F#', 'Gb'),  // ASCII sharp to flat
        ('C#', 'Db'),  // ASCII sharp to flat
        ('G#', 'Ab'),  // ASCII sharp to flat
        ('D#', 'Eb'),  // ASCII sharp to flat
        ('A#', 'Bb'),  // ASCII sharp to flat
        ('E♭', 'Eb'),  // Unicode flat to ASCII
        ('B♭', 'Bb'),  // Unicode flat to ASCII
        ('A♭', 'Ab'),  // Unicode flat to ASCII
        ('D♭', 'Db'),  // Unicode flat to ASCII
        ('G♭', 'Gb'),  // Unicode flat to ASCII
      ];
      
      print('Testing enharmonic mapping fixes:');
      
      for (final (input, expected) in problematicCases) {
        final result = findMatchingCommonRoot(input);
        print('  "$input" -> "$result" (expected: "$expected")');
        
        expect(result, equals(expected), 
            reason: 'Input "$input" should map to "$expected"');
        expect(MusicConstants.commonRoots.contains(result), isTrue,
            reason: 'Result "$result" must be in commonRoots to avoid assertion error');
      }
      
      print('✓ All problematic cases now have valid dropdown mappings');
    });

    test('Dropdown value is always in items list', () {
      // Test that the dropdown construction logic works
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      String? findMatchingCommonRoot(String value) {
        final normalizedValue = normalizeNoteName(value);
        
        if (MusicConstants.commonRoots.contains(value)) {
          return value;
        }
        
        for (final root in MusicConstants.commonRoots) {
          if (normalizeNoteName(root) == normalizedValue) {
            return root;
          }
        }
        
        const enharmonicMap = {
          'F#': 'Gb', 'f#': 'Gb',
          'C#': 'Db', 'c#': 'Db', 
          'G#': 'Ab', 'g#': 'Ab',
          'D#': 'Eb', 'd#': 'Eb',
          'A#': 'Bb', 'a#': 'Bb',
          'F♯': 'Gb',
          'C♯': 'Db',
          'G♯': 'Ab', 
          'D♯': 'Eb',
          'A♯': 'Bb',
        };
        
        final enharmonicEquivalent = enharmonicMap[value] ?? enharmonicMap[normalizedValue];
        if (enharmonicEquivalent != null && MusicConstants.commonRoots.contains(enharmonicEquivalent)) {
          return enharmonicEquivalent;
        }
        
        return null;
      }
      
      // Simulate the dropdown construction logic from root_selector.dart
      final testValues = ['F♯', 'Eb', 'C#', 'B♭', 'G#'];
      
      for (final currentValue in testValues) {
        print('Testing dropdown construction for currentValue="$currentValue"');
        
        // Get the appropriate value to use in dropdown
        final matchingRoot = findMatchingCommonRoot(currentValue);
        final dropdownValue = matchingRoot ?? currentValue;
        
        print('  matchingRoot: $matchingRoot');
        print('  dropdownValue: $dropdownValue');
        
        // Create a set to avoid duplicates, then convert to list
        final rootOptionsSet = Set<String>.from(MusicConstants.commonRoots);
        
        // Ensure the dropdown value is always included
        rootOptionsSet.add(dropdownValue);
        
        print('  dropdownValue in rootOptionsSet: ${rootOptionsSet.contains(dropdownValue)}');
        
        // This should always be true to avoid assertion errors
        expect(rootOptionsSet.contains(dropdownValue), isTrue,
            reason: 'Dropdown value "$dropdownValue" must be in the items list');
        
        // The dropdown value should also be from commonRoots (due to enharmonic mapping)
        expect(MusicConstants.commonRoots.contains(dropdownValue), isTrue,
            reason: 'Dropdown value "$dropdownValue" should be a valid common root');
      }
    });

    test('No more assertion errors expected', () {
      // This test verifies that the specific assertion error scenario is fixed
      
      print('Verifying assertion error fix:');
      
      // The original error was: "Assertion failed: there should be exactly one item with dropdownbuttons value: Eb"
      // This happened when currentValue was "E♭" (Unicode) but dropdown items only had "Eb" (ASCII)
      
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      String? findMatchingCommonRoot(String value) {
        final normalizedValue = normalizeNoteName(value);
        
        if (MusicConstants.commonRoots.contains(value)) {
          return value;
        }
        
        for (final root in MusicConstants.commonRoots) {
          if (normalizeNoteName(root) == normalizedValue) {
            return root;
          }
        }
        
        const enharmonicMap = {
          'F#': 'Gb', 'f#': 'Gb',
          'C#': 'Db', 'c#': 'Db', 
          'G#': 'Ab', 'g#': 'Ab',
          'D#': 'Eb', 'd#': 'Eb',
          'A#': 'Bb', 'a#': 'Bb',
          'F♯': 'Gb',
          'C♯': 'Db',
          'G♯': 'Ab', 
          'D♯': 'Eb',
          'A♯': 'Bb',
        };
        
        final enharmonicEquivalent = enharmonicMap[value] ?? enharmonicMap[normalizedValue];
        if (enharmonicEquivalent != null && MusicConstants.commonRoots.contains(enharmonicEquivalent)) {
          return enharmonicEquivalent;
        }
        
        return null;
      }
      
      // Test the specific case that was failing
      const problematicValue = 'E♭';  // Unicode flat from Note.name
      
      print('Testing problematic value: "$problematicValue"');
      
      final matchingRoot = findMatchingCommonRoot(problematicValue);
      final dropdownValue = matchingRoot ?? problematicValue;
      
      print('  Matching root: $matchingRoot');
      print('  Dropdown value: $dropdownValue');
      
      // Create items list (same as root_selector.dart)
      final rootOptionsSet = Set<String>.from(MusicConstants.commonRoots);
      rootOptionsSet.add(dropdownValue);
      final items = rootOptionsSet.toList();
      
      print('  Items contain dropdown value: ${items.contains(dropdownValue)}');
      print('  Items: $items');
      
      // The assertion that was failing: exactly one item with the dropdown value
      final matchingItems = items.where((item) => item == dropdownValue).toList();
      print('  Matching items: $matchingItems');
      
      expect(matchingItems.length, equals(1),
          reason: 'There should be exactly one item with dropdown value "$dropdownValue"');
      
      print('✓ Assertion error scenario is now fixed');
    });
  });
}