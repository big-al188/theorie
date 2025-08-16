// test/root_selector_dropdown_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/constants/music_constants.dart';

void main() {
  group('Root Selector Dropdown Tests', () {
    test('All possible note names should find valid dropdown values', () {
      // Test both sharp and flat note names from the Note class
      final testNotes = [
        // All natural notes
        'C', 'D', 'E', 'F', 'G', 'A', 'B',
        // All flat notes (Unicode)
        'D♭', 'E♭', 'G♭', 'A♭', 'B♭',
        // All sharp notes (Unicode) 
        'C♯', 'D♯', 'F♯', 'G♯', 'A♯',
        // ASCII versions
        'Db', 'Eb', 'Gb', 'Ab', 'Bb',
        'C#', 'D#', 'F#', 'G#', 'A#',
      ];
      
      // Reproduce the exact logic from root_selector.dart
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
      
      print('Testing all note names for dropdown compatibility:');
      
      for (final noteName in testNotes) {
        final result = findMatchingCommonRoot(noteName);
        print('  "$noteName" -> "$result"');
        
        expect(result, isNotNull, 
            reason: 'Note name "$noteName" should find a matching common root');
        expect(MusicConstants.commonRoots.contains(result), isTrue,
            reason: 'Result "$result" should be in commonRoots');
      }
    });

    test('App state root assignment scenario', () {
      // Test the specific scenario where app_state.dart calls _root = newRootNote.name
      
      print('Testing app state root assignment scenarios:');
      
      // Simulate different starting roots that could cause the issue
      final problematicScenarios = [
        'F#',   // Sharp note that needs enharmonic mapping
        'C#',   // Sharp note that needs enharmonic mapping  
        'G#',   // Sharp note that needs enharmonic mapping
        'D#',   // Sharp note that needs enharmonic mapping
        'A#',   // Sharp note that needs enharmonic mapping
        'Eb',   // Flat note with Unicode conversion
        'Bb',   // Flat note with Unicode conversion
        'Ab',   // Flat note with Unicode conversion
        'Db',   // Flat note with Unicode conversion
        'Gb',   // Flat note with Unicode conversion
      ];
      
      // Reproduce the exact root selector logic
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
      
      for (final startingRoot in problematicScenarios) {
        print('\\nScenario: Starting with root "$startingRoot"');
        
        // 1. Create a Note from starting root
        final note = Note.fromString(startingRoot);
        print('  Created Note: ${note.fullName}');
        
        // 2. Get the note name (this is what gets assigned to _root)
        final noteName = note.name;
        print('  Note.name: "$noteName"');
        
        // 3. Test if this note name would work in the dropdown
        final dropdownValue = findMatchingCommonRoot(noteName);
        print('  Dropdown value: "$dropdownValue"');
        
        // 4. Verify it's valid
        expect(dropdownValue, isNotNull,
            reason: 'Note name "$noteName" from starting root "$startingRoot" should find a dropdown value');
        expect(MusicConstants.commonRoots.contains(dropdownValue), isTrue,
            reason: 'Dropdown value "$dropdownValue" should be in commonRoots');
            
        print('  ✓ Success: "$startingRoot" -> Note.name="$noteName" -> dropdown="$dropdownValue"');
      }
    });

    test('Dropdown should not throw assertion errors', () {
      // Test that every possible note name that could come from Note.name 
      // will have a valid dropdown value
      
      print('Testing all possible Note.name outputs:');
      
      // Generate all possible note names that Note.name could return
      final allPossibleNoteNames = <String>{};
      
      // Test every pitch class in both sharp and flat preference
      for (int pc = 0; pc < 12; pc++) {
        final sharpNote = Note(pitchClass: pc, octave: 4, preferFlats: false);
        final flatNote = Note(pitchClass: pc, octave: 4, preferFlats: true);
        
        allPossibleNoteNames.add(sharpNote.name);
        allPossibleNoteNames.add(flatNote.name);
      }
      
      // Test the root selector logic on each possible note name
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
      
      for (final noteName in allPossibleNoteNames) {
        final dropdownValue = findMatchingCommonRoot(noteName);
        print('  Note.name "$noteName" -> dropdown "$dropdownValue"');
        
        expect(dropdownValue, isNotNull,
            reason: 'Every possible Note.name "$noteName" should find a dropdown value');
      }
      
      print('✓ All ${allPossibleNoteNames.length} possible Note.name values have valid dropdown mappings');
    });
  });
}