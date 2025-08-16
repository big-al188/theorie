// test/note_normalization_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/constants/music_constants.dart';

void main() {
  group('Note Normalization Tests', () {
    test('Normalization function handles Unicode symbols correctly', () {
      // Test the normalization logic that would be used in RootSelector
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      expect(normalizeNoteName('G♭'), equals('Gb'));
      expect(normalizeNoteName('F♯'), equals('F#'));
      expect(normalizeNoteName('D♭'), equals('Db'));
      expect(normalizeNoteName('A♭'), equals('Ab'));
      expect(normalizeNoteName('E♭'), equals('Eb'));
      expect(normalizeNoteName('B♭'), equals('Bb'));
      expect(normalizeNoteName('C♯'), equals('C#'));
      expect(normalizeNoteName('Db'), equals('Db')); // Already normalized
      expect(normalizeNoteName('C'), equals('C')); // Natural note
    });

    test('Matching common root function works correctly', () {
      // Test the logic for finding matching common roots
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
        
        return null;
      }
      
      // Test that Unicode symbols get mapped to their commonRoots equivalents
      expect(findMatchingCommonRoot('G♭'), equals('Gb'));
      expect(findMatchingCommonRoot('D♭'), equals('Db'));
      expect(findMatchingCommonRoot('A♭'), equals('Ab'));
      expect(findMatchingCommonRoot('E♭'), equals('Eb'));
      expect(findMatchingCommonRoot('B♭'), equals('Bb'));
      
      // Test that exact matches work
      expect(findMatchingCommonRoot('Gb'), equals('Gb'));
      expect(findMatchingCommonRoot('C'), equals('C'));
      expect(findMatchingCommonRoot('F'), equals('F'));
      
      // Test that non-existent roots return null
      expect(findMatchingCommonRoot('F♯'), isNull); // F# not in commonRoots
      expect(findMatchingCommonRoot('C♯'), isNull); // C# not in commonRoots
    });

    test('All common roots are self-consistent', () {
      // Verify that all common roots work with the normalization
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      for (final root in MusicConstants.commonRoots) {
        final normalized = normalizeNoteName(root);
        expect(normalized, equals(root), 
            reason: 'Common root "$root" should already be normalized');
      }
    });

    test('Unicode to letter conversion coverage', () {
      // Test specific problematic cases that might break UI
      final testCases = [
        {'unicode': 'G♭', 'letter': 'Gb'},
        {'unicode': 'D♭', 'letter': 'Db'},
        {'unicode': 'A♭', 'letter': 'Ab'},
        {'unicode': 'E♭', 'letter': 'Eb'},
        {'unicode': 'B♭', 'letter': 'Bb'},
        {'unicode': 'F♯', 'letter': 'F#'},
        {'unicode': 'C♯', 'letter': 'C#'},
      ];
      
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      for (final testCase in testCases) {
        final unicode = testCase['unicode']!;
        final letter = testCase['letter']!;
        
        expect(normalizeNoteName(unicode), equals(letter),
            reason: 'Unicode "$unicode" should normalize to "$letter"');
      }
    });
  });
}