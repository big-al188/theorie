// test/root_selector_unicode_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/constants/music_constants.dart';

void main() {
  group('Root Selector Unicode/ASCII Mismatch Tests', () {
    test('Note names should match commonRoots format', () {
      // Test the exact scenario that causes the dropdown issue
      
      print('Testing Note.name vs commonRoots compatibility:');
      
      // Test each common root
      for (final commonRoot in MusicConstants.commonRoots) {
        try {
          final note = Note.fromString(commonRoot);
          final noteName = note.name;
          
          print('  CommonRoot: "$commonRoot" -> Note.name: "$noteName"');
          
          // Check if they match exactly
          if (commonRoot == noteName) {
            print('    ✓ Exact match');
          } else {
            print('    ⚠ Mismatch! This could cause dropdown issues');
          }
          
          // Test normalization
          final normalizedCommon = commonRoot.replaceAll('♯', '#').replaceAll('♭', 'b');
          final normalizedNote = noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
          
          if (normalizedCommon == normalizedNote) {
            print('    ✓ Matches after normalization');
          } else {
            print('    ✗ Even normalization doesn\'t match!');
          }
          
        } catch (e) {
          print('  ERROR parsing "$commonRoot": $e');
        }
      }
    });

    test('Specific problematic cases', () {
      // Test the specific cases that are likely causing issues
      final problematicRoots = ['Eb', 'Bb', 'Ab', 'Db', 'Gb'];
      
      for (final root in problematicRoots) {
        print('Testing problematic root: $root');
        
        final note = Note.fromString(root);
        final noteName = note.name;
        
        print('  Input: "$root" -> Note.name: "$noteName"');
        
        // Check if the note name would be found in commonRoots
        final found = MusicConstants.commonRoots.contains(noteName);
        print('  Found in commonRoots: $found');
        
        if (!found) {
          // This is the problem case - need normalization
          final normalizedNoteName = noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
          final foundAfterNormalization = MusicConstants.commonRoots.contains(normalizedNoteName);
          print('  Found after normalization: $foundAfterNormalization');
          
          expect(foundAfterNormalization, isTrue, 
              reason: 'Root "$root" produces Note.name "$noteName" which should normalize to match commonRoots');
        }
      }
    });

    test('Root selector normalization function', () {
      // Test the exact normalization logic from root_selector.dart
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
      
      // Test with Unicode note names from Note class
      final testCases = [
        'E♭',  // Unicode flat
        'B♭',  // Unicode flat
        'A♭',  // Unicode flat
        'D♭',  // Unicode flat
        'G♭',  // Unicode flat
        'F♯',  // Unicode sharp
        'C♯',  // Unicode sharp
      ];
      
      for (final testCase in testCases) {
        final result = findMatchingCommonRoot(testCase);
        print('findMatchingCommonRoot("$testCase") = "$result"');
        
        expect(result, isNotNull, 
            reason: 'Should find a match for Unicode note name "$testCase"');
      }
    });

    test('App state scenario that causes the issue', () {
      // Simulate the app_state.dart scenario where _root = newRootNote.name
      
      // Start with an ASCII root
      const initialRoot = 'Eb';  // ASCII format
      print('Initial root: "$initialRoot"');
      
      // Create a Note from it
      final note = Note.fromString(initialRoot);
      print('Note created, note.name = "${note.name}"');
      
      // This simulates: _root = newRootNote.name;
      final newRoot = note.name;  // This will be Unicode format
      print('New root (from note.name): "$newRoot"');
      
      // Check if this new root would work in the dropdown
      final foundInCommonRoots = MusicConstants.commonRoots.contains(newRoot);
      print('Found in commonRoots: $foundInCommonRoots');
      
      if (!foundInCommonRoots) {
        print('This would cause the dropdown assertion error!');
        
        // Test if normalization would fix it
        final normalized = newRoot.replaceAll('♯', '#').replaceAll('♭', 'b');
        final foundAfterNormalization = MusicConstants.commonRoots.contains(normalized);
        print('Would normalization fix it: $foundAfterNormalization');
      }
    });
  });
}