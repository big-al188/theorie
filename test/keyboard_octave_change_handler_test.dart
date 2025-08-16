// test/keyboard_octave_change_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/keyboard/keyboard_config.dart';
import 'package:Theorie/models/fretboard/fretboard_config.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/controllers/keyboard_controller.dart';
import 'package:flutter/material.dart';

void main() {
  group('Keyboard Octave Change Handler Tests', () {
    test('Octave change should preserve actual MIDI notes in interval mode', () {
      // Create initial config with some intervals selected
      final initialConfig = KeyboardConfig(
        keyCount: 61,
        startNote: 'C2',
        keyboardType: 'Standard Piano',
        root: 'C',
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
        selectedOctaves: {4}, // C4 as reference
        selectedIntervals: {0, 4, 7}, // C major triad in octave 4
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      // Calculate initial MIDI notes
      final c4Midi = 60; // C4
      final initialMidiNotes = {60, 64, 67}; // C4, E4, G4
      
      print('Initial state:');
      print('  Root: C4, Selected octaves: {4}');
      print('  Intervals: {0, 4, 7}');
      print('  MIDI notes: {60, 64, 67}');

      // Change selected octaves to include a lower octave
      final newSelectedOctaves = {3, 4}; // This changes minSelectedOctave from 4 to 3
      
      final updatedConfig = KeyboardController.handleOctaveChange(initialConfig, newSelectedOctaves);
      
      print('After octave change:');
      print('  New selected octaves: ${updatedConfig.selectedOctaves}');
      print('  New reference octave: ${updatedConfig.minSelectedOctave}');
      print('  New intervals: ${updatedConfig.selectedIntervals}');
      
      // Calculate what MIDI notes the new intervals represent
      final newRootMidi = 48; // C3 (new reference)
      final newMidiNotes = updatedConfig.selectedIntervals.map((i) => newRootMidi + i).toSet();
      
      print('  New MIDI notes: $newMidiNotes');
      
      // The same MIDI notes should be preserved
      expect(newMidiNotes, equals(initialMidiNotes), 
          reason: 'Same MIDI notes should be highlighted after octave change');
      
      // Expected: intervals should be {12, 16, 19} (one octave higher relative to C3)
      expect(updatedConfig.selectedIntervals, equals({12, 16, 19}));
      expect(updatedConfig.selectedOctaves, equals({3, 4}));
    });

    test('No interval change when reference octave stays the same', () {
      final config = KeyboardConfig(
        keyCount: 61,
        startNote: 'C2',
        keyboardType: 'Standard Piano',
        root: 'A',
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
        selectedOctaves: {3, 4},
        selectedIntervals: {0, -12, 7},
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      // minSelectedOctave is 3, add octave 5 (doesn't change minSelectedOctave)
      final newSelectedOctaves = {3, 4, 5};
      
      final updatedConfig = KeyboardController.handleOctaveChange(config, newSelectedOctaves);
      
      // Intervals should remain the same since reference octave didn't change
      expect(updatedConfig.selectedIntervals, equals(config.selectedIntervals));
      expect(updatedConfig.selectedOctaves, equals({3, 4, 5}));
    });

    test('Non-interval modes should update octaves normally', () {
      final config = KeyboardConfig(
        keyCount: 61,
        startNote: 'C2',
        keyboardType: 'Standard Piano',
        root: 'C',
        viewMode: ViewMode.scales, // Not interval mode
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
        selectedOctaves: {4},
        selectedIntervals: {0, 4, 7},
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final newSelectedOctaves = {2, 3};
      
      final updatedConfig = KeyboardController.handleOctaveChange(config, newSelectedOctaves);
      
      // For non-interval modes, intervals should remain unchanged
      expect(updatedConfig.selectedIntervals, equals(config.selectedIntervals));
      expect(updatedConfig.selectedOctaves, equals({2, 3}));
    });

    test('Empty intervals should update octaves normally', () {
      final config = KeyboardConfig(
        keyCount: 61,
        startNote: 'C2',
        keyboardType: 'Standard Piano',
        root: 'C',
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
        selectedOctaves: {4},
        selectedIntervals: {}, // No intervals selected
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final newSelectedOctaves = {2, 3};
      
      final updatedConfig = KeyboardController.handleOctaveChange(config, newSelectedOctaves);
      
      // With no intervals, should just update octaves
      expect(updatedConfig.selectedIntervals, isEmpty);
      expect(updatedConfig.selectedOctaves, equals({2, 3}));
    });

    test('Negative intervals should be handled correctly', () {
      final config = KeyboardConfig(
        keyCount: 61,
        startNote: 'C2',
        keyboardType: 'Standard Piano',
        root: 'A',
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
        selectedOctaves: {2, 3}, // Reference is A2
        selectedIntervals: {0, 12, -9}, // A2, A3, C2
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      // Change to higher octaves (reference becomes A4)
      final newSelectedOctaves = {4, 5};
      
      final updatedConfig = KeyboardController.handleOctaveChange(config, newSelectedOctaves);
      
      // Calculate expected MIDI notes
      final oldRootMidi = 45; // A2
      final originalMidiNotes = {45, 57, 36}; // A2, A3, C2
      
      final newRootMidi = 69; // A4
      final newMidiNotes = updatedConfig.selectedIntervals.map((i) => newRootMidi + i).toSet();
      
      expect(newMidiNotes, equals(originalMidiNotes), 
          reason: 'Same MIDI notes should be preserved with negative intervals');
      
      // Intervals should now be negative since root moved higher than some notes
      expect(updatedConfig.selectedIntervals.any((i) => i < 0), isTrue,
          reason: 'Should have negative intervals when root is above some notes');
    });
  });
}