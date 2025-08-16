// test/keyboard_range_validation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/keyboard/keyboard_config.dart';
import 'package:Theorie/models/fretboard/fretboard_config.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/controllers/keyboard_controller.dart';
import 'package:flutter/material.dart';

void main() {
  group('Keyboard Range Validation Tests', () {
    test('Interval highlighting respects keyboard bounds', () {
      // Create a small keyboard (C2 to C4, 25 keys)
      final config = KeyboardConfig(
        keyCount: 25,
        startNote: 'C2',
        keyboardType: 'Small Piano',
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
        selectedOctaves: {1, 2, 3, 4, 5}, // Wide octave range
        selectedIntervals: {0, 12, 24, 36}, // Root and multiple octaves
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final highlightMap = KeyboardController.getIntervalHighlightMap(config);
      
      // Calculate expected keyboard range (C2 = MIDI 36, C4 = MIDI 60)
      final keyboardStartMidi = 36; // C2
      final keyboardEndMidi = 36 + 25 - 1; // C2 + 24 keys = 60 (C4)
      
      // Verify all highlighted notes are within keyboard range
      for (final midi in highlightMap.keys) {
        expect(midi, greaterThanOrEqualTo(keyboardStartMidi),
            reason: 'MIDI $midi should be >= keyboard start $keyboardStartMidi');
        expect(midi, lessThanOrEqualTo(keyboardEndMidi),
            reason: 'MIDI $midi should be <= keyboard end $keyboardEndMidi');
      }
      
      // Verify that out-of-range intervals are not highlighted
      // C1 (24) and C5 (72) should not be in the highlight map
      expect(highlightMap.containsKey(24), isFalse, 
          reason: 'C1 (MIDI 24) should not be highlighted as it\'s below keyboard range');
      expect(highlightMap.containsKey(72), isFalse,
          reason: 'C5 (MIDI 72) should not be highlighted as it\'s above keyboard range');
    });

    test('Scale highlighting respects keyboard bounds', () {
      // Create a keyboard with limited range
      final config = KeyboardConfig(
        keyCount: 37, // 3 octaves + 1 key (C2 to C5)
        startNote: 'C2',
        keyboardType: 'Small Piano',
        root: 'C',
        viewMode: ViewMode.scales,
        scale: 'major',
        modeIndex: 0,
        chordType: 'major',
        chordInversion: ChordInversion.root,
        showScaleStrip: true,
        showKeyboard: true,
        showChordName: false,
        showNoteNames: false,
        showAdditionalOctaves: false,
        showOctave: true,
        selectedOctaves: {1, 2, 3, 4, 5, 6}, // Wide octave range
        selectedIntervals: {0},
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final highlightMap = KeyboardController.getScaleHighlightMap(config);
      
      // Calculate expected keyboard range
      final keyboardStartMidi = 36; // C2
      final keyboardEndMidi = 36 + 37 - 1; // C2 + 36 keys = 72 (C5)
      
      // Verify all highlighted notes are within keyboard range
      for (final midi in highlightMap.keys) {
        expect(midi, greaterThanOrEqualTo(keyboardStartMidi),
            reason: 'MIDI $midi should be >= keyboard start $keyboardStartMidi');
        expect(midi, lessThanOrEqualTo(keyboardEndMidi),
            reason: 'MIDI $midi should be <= keyboard end $keyboardEndMidi');
      }
    });

    test('Chord highlighting respects keyboard bounds', () {
      // Create a very small keyboard
      final config = KeyboardConfig(
        keyCount: 13, // 1 octave (C2 to C3)
        startNote: 'C2',
        keyboardType: 'Tiny Piano',
        root: 'C',
        viewMode: ViewMode.chordInversions,
        scale: 'major',
        modeIndex: 0,
        chordType: 'major',
        chordInversion: ChordInversion.root,
        showScaleStrip: true,
        showKeyboard: true,
        showChordName: false,
        showNoteNames: false,
        showAdditionalOctaves: true, // This would normally add extra octaves
        showOctave: false,
        selectedOctaves: {2}, // C2 octave
        selectedIntervals: {0},
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final highlightMap = KeyboardController.getChordInversionHighlightMap(config);
      
      // Calculate expected keyboard range (C2 to C3)
      final keyboardStartMidi = 36; // C2
      final keyboardEndMidi = 36 + 13 - 1; // C2 + 12 keys = 48 (C3)
      
      // Verify all highlighted notes are within keyboard range
      for (final midi in highlightMap.keys) {
        expect(midi, greaterThanOrEqualTo(keyboardStartMidi),
            reason: 'MIDI $midi should be >= keyboard start $keyboardStartMidi');
        expect(midi, lessThanOrEqualTo(keyboardEndMidi),
            reason: 'MIDI $midi should be <= keyboard end $keyboardEndMidi');
      }
      
      // Even with showAdditionalOctaves=true, notes outside keyboard range should not be highlighted
      expect(highlightMap.containsKey(24), isFalse, 
          reason: 'C1 (MIDI 24) should not be highlighted even with additional octaves');
      expect(highlightMap.containsKey(60), isFalse,
          reason: 'C4 (MIDI 60) should not be highlighted even with additional octaves');
    });

    test('Edge case: Single key keyboard', () {
      // Create a single-key keyboard
      final config = KeyboardConfig(
        keyCount: 1,
        startNote: 'C4',
        keyboardType: 'Single Key',
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
        selectedIntervals: {0, 4, 7}, // C major triad
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final highlightMap = KeyboardController.getIntervalHighlightMap(config);
      
      // Only C4 (MIDI 60) should be highlighted, not E4 or G4
      expect(highlightMap.length, lessThanOrEqualTo(1),
          reason: 'Single-key keyboard should highlight at most 1 key');
      
      if (highlightMap.isNotEmpty) {
        expect(highlightMap.keys.first, equals(60),
            reason: 'Only C4 (MIDI 60) should be highlighted');
      }
    });
  });
}