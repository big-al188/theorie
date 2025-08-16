// test/keyboard_octave_bug_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/models/keyboard/keyboard_config.dart';
import 'package:Theorie/models/keyboard/key_configuration.dart';
import 'package:Theorie/models/fretboard/fretboard_config.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/controllers/keyboard_controller.dart';
import 'package:flutter/material.dart';

void main() {
  group('Keyboard Octave Bug Tests', () {
    test('Root in lower octave should highlight correctly', () {
      // Start with C3 as root
      var config = KeyboardConfig(
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
        selectedOctaves: {3}, // C3
        selectedIntervals: {0}, // Just root
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      // Get initial highlight map
      var highlightMap = KeyboardController.getIntervalHighlightMap(config);
      final c3Midi = Note.fromString('C3').midi; // Should be 48
      expect(highlightMap.containsKey(c3Midi), isTrue, 
          reason: 'C3 should be highlighted initially');

      // Now simulate tapping C2 (lower octave)
      final c2Midi = Note.fromString('C2').midi; // Should be 36
      final c2Key = KeyConfiguration.fromMidiNote(
        keyIndex: 0,
        midiNote: c2Midi,
        isHighlighted: false,
        highlightColor: null,
        intervalLabel: null,
      );

      // Simulate the handleKeyTap logic
      config = simulateKeyTap(c2Key, config);

      // After tapping C2, it should become the new root and be highlighted
      expect(config.root, equals('C'), reason: 'Root note should remain C');
      expect(config.selectedOctaves.contains(2), isTrue, 
          reason: 'Octave 2 should be added to selected octaves');

      // Get new highlight map
      highlightMap = KeyboardController.getIntervalHighlightMap(config);
      expect(highlightMap.containsKey(c2Midi), isTrue, 
          reason: 'C2 should be highlighted after being tapped');
      
      // IMPORTANT: Each interval should highlight exactly one specific note
      // C3 should NOT be highlighted just because C2 was tapped - they are different intervals
      // Only the specific intervals in selectedIntervals should be highlighted

      // Debug output
      print('Config after C2 tap:');
      print('  Root: ${config.root}');
      print('  Selected octaves: ${config.selectedOctaves}');
      print('  Selected intervals: ${config.selectedIntervals}');
      print('  Min selected octave: ${config.minSelectedOctave}');
      print('  Highlight map keys: ${highlightMap.keys.toList()}');
      print('  C2 MIDI ($c2Midi) highlighted: ${highlightMap.containsKey(c2Midi)}');
      print('  C3 MIDI ($c3Midi) highlighted: ${highlightMap.containsKey(c3Midi)}');
    });

    test('Reference octave calculation issue', () {
      // Test the core issue with reference octave calculation
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
        selectedOctaves: {2, 3}, // Both C2 and C3 octaves
        selectedIntervals: {0, 12}, // Root and octave
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final referenceOctave = config.minSelectedOctave; // Should be 2
      final rootNote = Note.fromString('${config.root}$referenceOctave'); // C2
      
      print('Reference octave: $referenceOctave');
      print('Root note: ${rootNote.fullName} (MIDI: ${rootNote.midi})');

      // Test interval calculations
      final c2Midi = Note.fromString('C2').midi; // 36
      final c3Midi = Note.fromString('C3').midi; // 48
      
      final c2Interval = c2Midi - rootNote.midi; // Should be 0
      final c3Interval = c3Midi - rootNote.midi; // Should be 12

      print('C2 interval from root: $c2Interval');
      print('C3 interval from root: $c3Interval');

      expect(c2Interval, equals(0), reason: 'C2 should be interval 0 from C2 root');
      expect(c3Interval, equals(12), reason: 'C3 should be interval 12 from C2 root');

      // Check if highlights work correctly
      final highlightMap = KeyboardController.getIntervalHighlightMap(config);
      print('Highlight map: $highlightMap');
      
      expect(highlightMap.containsKey(c2Midi), isTrue, 
          reason: 'C2 should be highlighted when interval 0 is selected');
      expect(highlightMap.containsKey(c3Midi), isTrue, 
          reason: 'C3 should be highlighted when interval 12 is selected');
    });

    test('Intervals should highlight specific notes only', () {
      // Test that each interval highlights exactly one specific MIDI note
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
        selectedOctaves: {2, 3, 4}, // Multiple octaves
        selectedIntervals: {0, 4, 12}, // Root, Major 3rd, and Octave
        width: 800.0,
        height: 200.0,
        padding: EdgeInsets.zero,
      );

      final highlightMap = KeyboardController.getIntervalHighlightMap(config);
      
      // With reference octave 2 (minSelectedOctave), we should get:
      // - Interval 0: C2 (MIDI 36)
      // - Interval 4: E2 (MIDI 40) 
      // - Interval 12: C3 (MIDI 48)
      
      final c2 = Note.fromString('C2').midi; // 36
      final e2 = Note.fromString('E2').midi; // 40
      final c3 = Note.fromString('C3').midi; // 48
      
      expect(highlightMap.containsKey(c2), isTrue, reason: 'C2 should be highlighted (interval 0)');
      expect(highlightMap.containsKey(e2), isTrue, reason: 'E2 should be highlighted (interval 4)');
      expect(highlightMap.containsKey(c3), isTrue, reason: 'C3 should be highlighted (interval 12)');
      
      // Other notes of the same pitch class should NOT be highlighted
      final c4 = Note.fromString('C4').midi; // 60
      final e3 = Note.fromString('E3').midi; // 52
      final e4 = Note.fromString('E4').midi; // 64
      
      expect(highlightMap.containsKey(c4), isFalse, reason: 'C4 should NOT be highlighted (no interval 24)');
      expect(highlightMap.containsKey(e3), isFalse, reason: 'E3 should NOT be highlighted (no interval 16)');
      expect(highlightMap.containsKey(e4), isFalse, reason: 'E4 should NOT be highlighted (no interval 28)');

      // Color consistency: same interval types should have same colors
      final rootColor = highlightMap[c2]!; // Interval 0
      final octaveColor = highlightMap[c3]!; // Interval 12 (should be same as interval 0)
      expect(octaveColor, equals(rootColor), reason: 'Octave should have same color as root');

      print('Highlight map: $highlightMap');
      print('Expected highlights: C2($c2), E2($e2), C3($c3)');
    });
  });
}

// Helper function to simulate key tap logic
KeyboardConfig simulateKeyTap(KeyConfiguration key, KeyboardConfig config) {
  final referenceOctave = config.minSelectedOctave;
  final rootNote = Note.fromString('${config.root}$referenceOctave');
  final extendedInterval = key.midiNote - rootNote.midi;

  var newIntervals = Set<int>.from(config.selectedIntervals);
  var newOctaves = Set<int>.from(config.selectedOctaves);
  var newRoot = config.root;

  // Handle based on current state
  if (newIntervals.isEmpty) {
    // No notes selected - this becomes the new root
    final tappedNote = Note.fromMidi(key.midiNote);
    newRoot = tappedNote.name;
    newIntervals = {0};
    newOctaves = {tappedNote.octave};
  } else if (newIntervals.contains(extendedInterval)) {
    // Removing an existing interval
    newIntervals.remove(extendedInterval);
    if (newIntervals.isEmpty) {
      newIntervals = {0}; // Keep at least the root
    }
  } else {
    // Adding a new interval
    newIntervals.add(extendedInterval);
    final tappedNote = Note.fromMidi(key.midiNote);
    if (!newOctaves.contains(tappedNote.octave)) {
      newOctaves.add(tappedNote.octave);
    }
  }

  // Update configuration
  return config.copyWith(
    root: newRoot,
    selectedIntervals: newIntervals,
    selectedOctaves: newOctaves,
  );
}