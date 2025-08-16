// test/keyboard_sharps_flats_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/keyboard/keyboard_config.dart';
import 'package:Theorie/models/fretboard/fretboard_config.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/controllers/keyboard_controller.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/constants/music_constants.dart';
import 'package:flutter/material.dart';

void main() {
  group('Keyboard Sharps/Flats UI Tests', () {
    test('All common roots should be parseable by Note.fromString', () {
      // Test that all common roots can be parsed without error
      for (final root in MusicConstants.commonRoots) {
        expect(() => Note.fromString(root), returnsNormally,
            reason: 'Root "$root" should be parseable by Note.fromString');
        
        final note = Note.fromString(root);
        expect(note.name, isNotEmpty, 
            reason: 'Root "$root" should produce a valid note name');
        
        print('Root: $root -> Note name: ${note.name}, Pitch class: ${note.pitchClass}');
      }
    });

    test('Keyboard configuration should work with all common roots', () {
      // Test that keyboard configuration works with each common root
      for (final root in MusicConstants.commonRoots) {
        final config = KeyboardConfig(
          keyCount: 25,
          startNote: 'C2',
          keyboardType: 'Small Piano',
          root: root,
          viewMode: ViewMode.intervals,
          scale: 'major',
          modeIndex: 0,
          chordType: 'major',
          chordInversion: ChordInversion.root,
          showScaleStrip: true,
          showKeyboard: true,
          showChordName: false,
          showNoteNames: false,
          showAdditionalOctaves: false,
          showOctave: false,
          selectedOctaves: {3},
          selectedIntervals: {0},
          width: 800.0,
          height: 200.0,
          padding: EdgeInsets.zero,
        );

        expect(() => KeyboardController.getIntervalHighlightMap(config), 
            returnsNormally,
            reason: 'Keyboard highlighting should work with root "$root"');
        
        final highlightMap = KeyboardController.getIntervalHighlightMap(config);
        expect(highlightMap, isNotEmpty,
            reason: 'Root "$root" should produce highlights');
      }
    });

    test('Note formatting consistency between different notations', () {
      // Test that different sharp/flat notations are handled consistently
      final testCases = [
        {'input': 'Gb', 'expected_pitch_class': 6},  // F# / Gb
        {'input': 'F#', 'expected_pitch_class': 6},  
        {'input': 'Db', 'expected_pitch_class': 1},  // C# / Db
        {'input': 'C#', 'expected_pitch_class': 1},
        {'input': 'Ab', 'expected_pitch_class': 8},  // G# / Ab
        {'input': 'G#', 'expected_pitch_class': 8},
        {'input': 'Eb', 'expected_pitch_class': 3},  // D# / Eb
        {'input': 'D#', 'expected_pitch_class': 3},
        {'input': 'Bb', 'expected_pitch_class': 10}, // A# / Bb
        {'input': 'A#', 'expected_pitch_class': 10},
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as String;
        final expectedPitchClass = testCase['expected_pitch_class'] as int;
        
        final note = Note.fromString(input);
        expect(note.pitchClass, equals(expectedPitchClass),
            reason: 'Note "$input" should have pitch class $expectedPitchClass, got ${note.pitchClass}');
      }
    });

    test('Circle of fifths notes should all be parseable', () {
      // Test that all circle of fifths notes work
      for (final root in MusicConstants.circleOfFifths) {
        expect(() => Note.fromString(root), returnsNormally,
            reason: 'Circle of fifths root "$root" should be parseable');
        
        final note = Note.fromString(root);
        print('Circle of fifths: $root -> ${note.name} (pitch class ${note.pitchClass})');
      }
    });

    test('Flat roots preference detection', () {
      // Test that flat roots are detected correctly
      final flatRoots = ['F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb'];
      
      for (final root in flatRoots) {
        final note = Note.fromString(root);
        if (root != 'F') { // F is natural, not a flat
          // For actual flat notes, they should prefer flats
          expect(note.preferFlats, isTrue,
              reason: 'Note "$root" should prefer flats');
        }
      }
    });

    test('Note naming consistency in keyboard context', () {
      // Test specific edge case: when a sharp/flat root is selected,
      // the note names should be consistent
      final testRoots = ['F#', 'Gb', 'C#', 'Db'];
      
      for (final root in testRoots) {
        final note = Note.fromString(root);
        final retrievedName = note.name;
        
        print('Root: $root -> Retrieved name: $retrievedName, PreferFlats: ${note.preferFlats}');
        
        // The retrieved name should be a valid note name
        expect(retrievedName, isNotEmpty);
        expect(() => Note.fromString(retrievedName), returnsNormally,
            reason: 'Retrieved name "$retrievedName" should be parseable back to a note');
      }
    });
  });
}