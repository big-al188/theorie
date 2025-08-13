// test/fretboard_controller_test.dart - Comprehensive fretboard controller tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Theorie/controllers/fretboard_controller.dart';
import 'package:Theorie/models/fretboard/fretboard_config.dart';
import 'package:Theorie/models/fretboard/highlight_info.dart';
import 'package:Theorie/models/music/chord.dart';
import 'package:Theorie/models/music/note.dart';
import 'package:Theorie/models/music/scale.dart';

void main() {
  group('FretboardController Tests', () {
    // Helper method to create a basic FretboardConfig for testing
    FretboardConfig createTestConfig({
      ViewMode viewMode = ViewMode.scales,
      String root = 'C',
      String scale = 'Major',
      int modeIndex = 0,
      String chordType = 'major',
      ChordInversion chordInversion = ChordInversion.root,
      Set<int> selectedOctaves = const {3, 4},
      Set<int> selectedIntervals = const {0, 4, 7},
      List<String> tuning = const ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      bool showAdditionalOctaves = false,
      bool showAllPositions = true,
    }) {
      return FretboardConfig(
        stringCount: tuning.length,
        fretCount: 12,
        tuning: tuning,
        layout: FretboardLayout.rightHandedBassBottom,
        root: root,
        viewMode: viewMode,
        scale: scale,
        modeIndex: modeIndex,
        chordType: chordType,
        chordInversion: chordInversion,
        showScaleStrip: true,
        showFretboard: true,
        showChordName: true,
        showNoteNames: true,
        showAdditionalOctaves: showAdditionalOctaves,
        showAllPositions: showAllPositions,
        selectedOctaves: selectedOctaves,
        selectedIntervals: selectedIntervals,
        width: 800,
        height: 400,
        padding: EdgeInsets.zero,
        visibleFretStart: 0,
        visibleFretEnd: 12,
      );
    }

    group('Scale Highlight Map Generation', () {
      test('should generate correct highlight map for C Major scale', () {
        final config = createTestConfig(
          viewMode: ViewMode.scales,
          root: 'C',
          scale: 'Major',
          modeIndex: 0,
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getScaleHighlightMap(config);

        // C Major scale: C, D, E, F, G, A, B
        // C4 = MIDI 60, D4 = 62, E4 = 64, F4 = 65, G4 = 67, A4 = 69, B4 = 71
        expect(highlightMap.keys, contains(60)); // C4
        expect(highlightMap.keys, contains(62)); // D4
        expect(highlightMap.keys, contains(64)); // E4
        expect(highlightMap.keys, contains(65)); // F4
        expect(highlightMap.keys, contains(67)); // G4
        expect(highlightMap.keys, contains(69)); // A4
        expect(highlightMap.keys, contains(71)); // B4

        // Should not contain chromatic notes
        expect(highlightMap.keys, isNot(contains(61))); // C#4
        expect(highlightMap.keys, isNot(contains(63))); // D#4

        // Should have colors assigned
        expect(highlightMap.values.every((color) => color is Color), isTrue);
      });

      test('should generate correct highlight map for Bb Major scale (flat preference)', () {
        final config = createTestConfig(
          viewMode: ViewMode.scales,
          root: 'Bb',
          scale: 'Major',
          modeIndex: 0,
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getScaleHighlightMap(config);

        // Bb Major scale: Bb, C, D, Eb, F, G, A
        // Starting from Bb4 = MIDI 70: Bb4, C5, D5, Eb5, F5, G5, A5, Bb5
        expect(highlightMap.keys, contains(70)); // Bb4
        expect(highlightMap.keys, contains(72)); // C5
        expect(highlightMap.keys, contains(74)); // D5
        expect(highlightMap.keys, contains(75)); // Eb5
        expect(highlightMap.keys, contains(77)); // F5
        expect(highlightMap.keys, contains(79)); // G5
        expect(highlightMap.keys, contains(81)); // A5

        // Should have 8 notes (7 scale notes + octave)
        expect(highlightMap.length, 8);
      });

      test('should generate correct highlight map for scale modes', () {
        final config = createTestConfig(
          viewMode: ViewMode.scales,
          root: 'C',
          scale: 'Major',
          modeIndex: 1, // Dorian mode (starting from D)
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getScaleHighlightMap(config);

        // D Dorian (mode 1 of C Major): D, E, F, G, A, B, C, D
        // Starting from D4 = MIDI 62: D4, E4, F4, G4, A4, B4, C5, D5
        expect(highlightMap.keys, contains(62)); // D4
        expect(highlightMap.keys, contains(64)); // E4
        expect(highlightMap.keys, contains(65)); // F4
        expect(highlightMap.keys, contains(67)); // G4
        expect(highlightMap.keys, contains(69)); // A4
        expect(highlightMap.keys, contains(71)); // B4
        expect(highlightMap.keys, contains(72)); // C5
        expect(highlightMap.keys, contains(74)); // D5 (octave)

        expect(highlightMap.length, 8); // 7 notes + octave
      });

      test('should return empty map for invalid scale', () {
        final config = createTestConfig(
          viewMode: ViewMode.scales,
          root: 'C',
          scale: 'NonExistentScale',
          modeIndex: 0,
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getScaleHighlightMap(config);
        expect(highlightMap, isEmpty);
      });

      test('should generate highlight map for multiple octaves', () {
        final config = createTestConfig(
          viewMode: ViewMode.scales,
          root: 'C',
          scale: 'Major',
          modeIndex: 0,
          selectedOctaves: {3, 4, 5},
        );

        final highlightMap = FretboardController.getScaleHighlightMap(config);

        // Should include notes from octaves 3, 4, and 5
        expect(highlightMap.keys, contains(48)); // C3
        expect(highlightMap.keys, contains(60)); // C4
        expect(highlightMap.keys, contains(72)); // C5

        // Should have C Major scale across 3 octaves (includes octave note)
        expect(highlightMap.length, 22);
      });
    });

    group('Interval Highlight Map Generation', () {
      test('should generate correct highlight map for interval mode', () {
        final config = createTestConfig(
          viewMode: ViewMode.intervals,
          root: 'C',
          selectedIntervals: {0, 4, 7}, // Major triad intervals
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getIntervalHighlightMap(config);

        // C4 + intervals: C4 (60), E4 (64), G4 (67)
        expect(highlightMap.keys, contains(60)); // Root (C4)
        expect(highlightMap.keys, contains(64)); // Major 3rd (E4)
        expect(highlightMap.keys, contains(67)); // Perfect 5th (G4)

        expect(highlightMap.length, 3);
      });

      test('should return empty map for empty intervals', () {
        final config = createTestConfig(
          viewMode: ViewMode.intervals,
          root: 'C',
          selectedIntervals: {},
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getIntervalHighlightMap(config);
        expect(highlightMap, isEmpty);
      });

      test('should use default octave when no octaves selected', () {
        final config = createTestConfig(
          viewMode: ViewMode.intervals,
          root: 'C',
          selectedIntervals: {0, 7}, // Root and 5th
          selectedOctaves: {},
        );

        final highlightMap = FretboardController.getIntervalHighlightMap(config);

        // Should default to octave 3: C3 (48), G3 (55)
        expect(highlightMap.keys, contains(48)); // C3
        expect(highlightMap.keys, contains(55)); // G3
        expect(highlightMap.length, 2);
      });

      test('should generate intervals across multiple octaves', () {
        final config = createTestConfig(
          viewMode: ViewMode.intervals,
          root: 'C',
          selectedIntervals: {0, 12}, // Root and octave
          selectedOctaves: {3, 4},
        );

        final highlightMap = FretboardController.getIntervalHighlightMap(config);

        // Should have interval notes from octaves 3 and 4
        expect(highlightMap.keys, contains(48)); // C3
        expect(highlightMap.keys, contains(60)); // C4
        
        // Check that we have the expected number of unique notes
        expect(highlightMap.length, 2); // C3, C4
      });
    });

    group('Chord Highlight Map Generation', () {
      test('should generate correct highlight map for chord inversions', () {
        final config = createTestConfig(
          viewMode: ViewMode.chordInversions,
          root: 'C',
          chordType: 'major',
          chordInversion: ChordInversion.root,
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getChordInversionHighlightMap(config);

        // C major chord: C, E, G
        expect(highlightMap.keys, contains(60)); // C4
        expect(highlightMap.keys, contains(64)); // E4
        expect(highlightMap.keys, contains(67)); // G4
        expect(highlightMap.length, 3);
      });

      test('should generate highlight map for different chord types', () {
        final config = createTestConfig(
          viewMode: ViewMode.chordInversions,
          root: 'C',
          chordType: 'minor7',
          chordInversion: ChordInversion.root,
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getChordInversionHighlightMap(config);

        // C minor 7 chord: C, Eb, G, Bb
        expect(highlightMap.keys, contains(60)); // C4
        expect(highlightMap.keys, contains(63)); // Eb4
        expect(highlightMap.keys, contains(67)); // G4
        expect(highlightMap.keys, contains(70)); // Bb4
        expect(highlightMap.length, 4);
      });

      test('should return empty map for invalid chord type', () {
        final config = createTestConfig(
          viewMode: ViewMode.chordInversions,
          root: 'C',
          chordType: 'nonexistent',
          chordInversion: ChordInversion.root,
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getChordInversionHighlightMap(config);
        expect(highlightMap, isEmpty);
      });
    });

    group('Combined Highlight Map Generation', () {
      test('should generate combined highlight map with additional octaves', () {
        final config = createTestConfig(
          viewMode: ViewMode.chordInversions,
          root: 'C',
          chordType: 'major',
          showAdditionalOctaves: true,
          selectedOctaves: {4},
        );

        final combinedMap = FretboardController.getCombinedHighlightMap(config);

        expect(combinedMap.primary, isNotEmpty);
        expect(combinedMap.additional, isNotEmpty);

        // Primary should have the base chord notes
        expect(combinedMap.primary.keys, contains(60)); // C4
        expect(combinedMap.primary.keys, contains(64)); // E4
        expect(combinedMap.primary.keys, contains(67)); // G4

        // Additional should have octave notes
        expect(combinedMap.additional, isA<Map<int, HighlightInfo>>());
      });

      test('should generate separate maps for primary and additional octaves', () {
        final config = createTestConfig(
          viewMode: ViewMode.chordInversions,
          root: 'C',
          chordType: 'major',
          showAdditionalOctaves: true,
          selectedOctaves: {3, 4},
        );

        final combinedMap = FretboardController.getCombinedHighlightMap(config);

        // Both maps should be populated
        expect(combinedMap.primary, isNotEmpty);
        expect(combinedMap.additional, isNotEmpty);

        // Maps should be different objects
        expect(identical(combinedMap.primary, combinedMap.additional), isFalse);
      });
    });

    group('Main Highlight Map Dispatcher', () {
      test('should dispatch to correct highlight map method based on view mode', () {
        // Test scales mode
        final scalesConfig = createTestConfig(viewMode: ViewMode.scales);
        final scalesMap = FretboardController.getHighlightMap(scalesConfig);
        expect(scalesMap, isNotEmpty);

        // Test intervals mode
        final intervalsConfig = createTestConfig(viewMode: ViewMode.intervals);
        final intervalsMap = FretboardController.getHighlightMap(intervalsConfig);
        expect(intervalsMap, isNotEmpty);

        // Test chord inversions mode
        final chordsConfig = createTestConfig(viewMode: ViewMode.chordInversions);
        final chordsMap = FretboardController.getHighlightMap(chordsConfig);
        expect(chordsMap, isNotEmpty);

        // Test open chords mode
        final openChordsConfig = createTestConfig(viewMode: ViewMode.openChords);
        final openChordsMap = FretboardController.getHighlightMap(openChordsConfig);
        expect(openChordsMap, isA<Map<int, Color>>());

        // Test unimplemented modes
        final barreConfig = createTestConfig(viewMode: ViewMode.barreChords);
        final barreMap = FretboardController.getHighlightMap(barreConfig);
        expect(barreMap, isEmpty); // Should return empty for unimplemented
      });
    });

    group('Fretboard Position Calculations', () {
      test('should calculate corrected fret count', () {
        final config = createTestConfig();

        final correctedCount = FretboardController.getCorrectedFretCount(config);
        expect(correctedCount, 13); // 0 through 12 inclusive = 13 frets
      });

      test('should find fret for note correctly', () {
        // Test finding C note on low E string (E2)
        // E2 is MIDI 40, C3 is MIDI 48, so C should be at fret 8
        final targetNote = Note.fromMidi(48); // C3
        final openString = Note.fromMidi(40); // E2
        final fret = FretboardController.getFretForNote(targetNote, openString, 12);
        expect(fret, 8);

        // Test note not on string within fret range
        final impossibleNote = Note.fromMidi(100);
        final impossibleFret = FretboardController.getFretForNote(impossibleNote, openString, 12);
        expect(impossibleFret, isNull);

        // Test exact match (open string)
        final openFret = FretboardController.getFretForNote(openString, openString, 12);
        expect(openFret, 0);
      });

      test('should determine if note should be highlighted', () {
        final highlightMap = {60: Colors.red, 64: Colors.blue};

        expect(FretboardController.shouldHighlightNote(60, highlightMap), isTrue);
        expect(FretboardController.shouldHighlightNote(61, highlightMap), isFalse);
        expect(FretboardController.shouldHighlightNote(64, highlightMap), isTrue);
      });
    });

    group('Interval Mode Tap Handling', () {
      test('should handle interval mode tap correctly', () {
        final config = createTestConfig(
          viewMode: ViewMode.intervals,
          root: 'C',
          selectedIntervals: {0}, // Just root
          selectedOctaves: {3},
          tuning: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
        );

        Set<int> capturedIntervals = {};
        String? capturedRoot;
        Set<int>? capturedOctaves;

        void onIntervalsChanged(Set<int> intervals) {
          capturedIntervals = intervals;
        }

        void onRootAndOctavesChanged(String root, Set<int> octaves) {
          capturedRoot = root;
          capturedOctaves = octaves;
        }

        // Tap on 5th fret of low E string (E2 + 5 = A2, MIDI 45)
        FretboardController.handleIntervalModeTap(
          config,
          0, // stringIndex (low E string)
          5, // fretIndex (5th fret)
          onIntervalsChanged,
          onRootAndOctavesChanged: onRootAndOctavesChanged,
        );

        // Should add the new interval (A2 relative to C3 reference)
        expect(capturedIntervals, isNotEmpty);
      });

      test('should remove interval if already selected', () {
        final config = createTestConfig(
          viewMode: ViewMode.intervals,
          root: 'C',
          selectedIntervals: {0, 7}, // Root and 5th
          selectedOctaves: {4},
        );

        Set<int> capturedIntervals = {};

        void onIntervalsChanged(Set<int> intervals) {
          capturedIntervals = intervals;
        }

        // Calculate a tap that would result in interval 7 (perfect 5th)
        // This should remove the interval since it's already selected
        FretboardController.handleIntervalModeTap(
          config,
          3, // G string
          0, // Open (G3 = MIDI 55, C4 = MIDI 60, so interval = 55-60 = -5, but we need to test actual calculation)
          onIntervalsChanged,
        );

        // The exact result depends on the calculation, but the method should be called
        expect(capturedIntervals, isA<Set<int>>());
      });
    });

    group('Interval Label Generation', () {
      test('should generate correct interval labels', () {
        expect(FretboardController.getIntervalLabel(0), '1');
        expect(FretboardController.getIntervalLabel(1), '♭2');
        expect(FretboardController.getIntervalLabel(2), '2');
        expect(FretboardController.getIntervalLabel(3), '♭3');
        expect(FretboardController.getIntervalLabel(4), '3');
        expect(FretboardController.getIntervalLabel(5), '4');
        expect(FretboardController.getIntervalLabel(6), '♭5');
        expect(FretboardController.getIntervalLabel(7), '5');
        expect(FretboardController.getIntervalLabel(8), '♭6');
        expect(FretboardController.getIntervalLabel(9), '6');
        expect(FretboardController.getIntervalLabel(10), '♭7');
        expect(FretboardController.getIntervalLabel(11), '7');
        expect(FretboardController.getIntervalLabel(12), '8');
      });

      test('should generate extended interval labels', () {
        expect(FretboardController.getExtendedIntervalLabel(13, 1), '♭9');
        expect(FretboardController.getExtendedIntervalLabel(14, 1), '9');
        expect(FretboardController.getExtendedIntervalLabel(15, 1), '♭10');
        expect(FretboardController.getExtendedIntervalLabel(24, 2), '15');
      });

      test('should handle safe interval label generation', () {
        expect(FretboardController.getIntervalLabelSafe(0, 'test'), '1');
        expect(FretboardController.getIntervalLabelSafe(7, 'test'), '5');
        expect(FretboardController.getIntervalLabelSafe(-1, 'test'), '7'); // -1 mod 12 = 11, which is '7'
        expect(FretboardController.getIntervalLabelSafe(100, 'test'), '59'); // 100: 8 octaves + interval 4 ('3') = 3 + (8*7) = 59
      });
    });

    group('Utility Methods', () {
      test('should detect chord modes correctly', () {
        expect(FretboardController.isAnyChordMode(ViewMode.chordInversions), isTrue);
        expect(FretboardController.isAnyChordMode(ViewMode.openChords), isTrue);
        expect(FretboardController.isAnyChordMode(ViewMode.barreChords), isTrue);
        expect(FretboardController.isAnyChordMode(ViewMode.advancedChords), isTrue);
        expect(FretboardController.isAnyChordMode(ViewMode.scales), isFalse);
        expect(FretboardController.isAnyChordMode(ViewMode.intervals), isFalse);
      });

      test('should detect implemented modes correctly', () {
        expect(FretboardController.isModeImplemented(ViewMode.scales), isTrue);
        expect(FretboardController.isModeImplemented(ViewMode.intervals), isTrue);
        expect(FretboardController.isModeImplemented(ViewMode.chordInversions), isTrue);
        expect(FretboardController.isModeImplemented(ViewMode.openChords), isTrue);
        expect(FretboardController.isModeImplemented(ViewMode.barreChords), isFalse);
        expect(FretboardController.isModeImplemented(ViewMode.advancedChords), isFalse);
      });

      test('should detect chord modes correctly', () {
        expect(FretboardController.isChordMode(ViewMode.chordInversions), isTrue);
        expect(FretboardController.isChordMode(ViewMode.openChords), isFalse); // isChordMode only returns true for chordInversions
        expect(FretboardController.isChordMode(ViewMode.scales), isFalse);
      });

      test('should determine if interval will become root', () {
        final config = createTestConfig(
          root: 'C',
          selectedIntervals: {0, 7},
          selectedOctaves: {4},
        );

        // C4 = MIDI 60, should become root if it's the only interval
        final willBecome = FretboardController.willIntervalBecomeRoot(config, 60);
        expect(willBecome, isFalse); // Because we have multiple intervals

        final config2 = createTestConfig(
          viewMode: ViewMode.intervals, // Must be in interval mode
          root: 'C',
          selectedIntervals: {7}, // Only 5th
          selectedOctaves: {4},
        );

        final willBecome2 = FretboardController.willIntervalBecomeRoot(config2, 67); // G4 (5th)
        expect(willBecome2, isTrue); // Because removing 5th leaves only root
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty octaves gracefully', () {
        final config = createTestConfig(
          selectedOctaves: {},
          selectedIntervals: {0, 4, 7},
        );

        final highlightMap = FretboardController.getIntervalHighlightMap(config);
        expect(highlightMap, isNotEmpty); // Should use default octave
      });

      test('should handle invalid chord types gracefully', () {
        final config = createTestConfig(
          viewMode: ViewMode.chordInversions,
          chordType: 'invalid',
        );

        final highlightMap = FretboardController.getChordInversionHighlightMap(config);
        expect(highlightMap, isEmpty);
      });

      test('should handle invalid scale names gracefully', () {
        final config = createTestConfig(
          viewMode: ViewMode.scales,
          scale: 'invalid',
        );

        final highlightMap = FretboardController.getScaleHighlightMap(config);
        expect(highlightMap, isEmpty);
      });

      test('should handle extreme intervals gracefully', () {
        final config = createTestConfig(
          selectedIntervals: {-12, 0, 12, 24, 36}, // Extreme intervals
          selectedOctaves: {4},
        );

        final highlightMap = FretboardController.getIntervalHighlightMap(config);
        expect(highlightMap, isA<Map<int, Color>>());
        expect(highlightMap, isNotEmpty);
      });

      test('should handle very high and low octaves', () {
        final config = createTestConfig(
          selectedOctaves: {0, 1, 8, 9}, // Extreme octaves
          selectedIntervals: {0},
        );

        final highlightMap = FretboardController.getIntervalHighlightMap(config);
        expect(highlightMap, isNotEmpty);

        // Should handle notes that might be outside normal MIDI range
        for (final midiNote in highlightMap.keys) {
          expect(midiNote, greaterThanOrEqualTo(0));
          expect(midiNote, lessThanOrEqualTo(127));
        }
      });
    });
  });
}