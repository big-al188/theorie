// lib/controllers/fretboard_controller.dart
import 'package:flutter/material.dart';
import '../models/music/note.dart';
import '../models/music/scale.dart';
import '../models/music/chord.dart';
import '../models/fretboard/fretboard_config.dart';
import '../utils/color_utils.dart';
import 'music_controller.dart';

/// Controller for fretboard logic and calculations
class FretboardController {
  /// Generate highlight map for scale mode
  static Map<int, Color> getScaleHighlightMap(FretboardConfig config) {
    final scale = Scale.get(config.scale);
    if (scale == null) return {};

    final effectiveRoot = config.isScaleMode
        ? MusicController.getModeRoot(
            config.root, config.scale, config.modeIndex)
        : config.root;

    final rootNote = Note.fromString('${effectiveRoot}0');
    final pitchClasses = scale.getModeIntervals(config.modeIndex);
    final map = <int, Color>{};
    final octaves =
        config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
    final minOctave = config.minSelectedOctave;

    for (final octave in octaves) {
      for (int i = 0; i < pitchClasses.length; i++) {
        final chromaticStep = pitchClasses[i];
        final note = Note(
          pitchClass: (rootNote.pitchClass + chromaticStep) % 12,
          octave: octave,
        );
        final octaveOffset = octave - minOctave;
        final intervalFromRoot = chromaticStep + (octaveOffset * 12);
        map[note.midi] = ColorUtils.colorForDegree(intervalFromRoot);
      }
    }

    return map;
  }

  /// Generate highlight map for interval mode
  static Map<int, Color> getIntervalHighlightMap(FretboardConfig config) {
    final map = <int, Color>{};
    final octaves =
        config.selectedOctaves.isEmpty ? {3} : config.selectedOctaves;
    final referenceOctave = config.minSelectedOctave;
    final rootNote = Note.fromString('${config.root}$referenceOctave');

    for (final extendedInterval in config.selectedIntervals) {
      final specificMidi = rootNote.midi + extendedInterval;
      final noteOctave = Note.fromMidi(specificMidi).octave;

      if (octaves.contains(noteOctave)) {
        map[specificMidi] = ColorUtils.colorForDegree(extendedInterval);
      }
    }

    return map;
  }

  /// Generate highlight map for chord mode with extended interval support
  static Map<int, Color> getChordHighlightMap(FretboardConfig config) {
    final map = <int, Color>{};
    final chord = Chord.get(config.chordType);
    if (chord == null) return {};

    final octave = config.selectedChordOctave;
    final rootNote = Note.fromString('${config.root}$octave');

    debugPrint('=== Building Chord Voicing Highlight Map ===');
    debugPrint(
        'Root: ${config.root}, Octave: $octave, Chord: ${config.chordType}, Inversion: ${config.chordInversion.displayName}');

    // Build chord voicing
    final voicingMidiNotes = chord.buildVoicing(
      root: rootNote,
      inversion: config.chordInversion,
    );

    debugPrint('Voicing MIDI notes: $voicingMidiNotes');

    // Color each note based on its interval from root
    for (final midi in voicingMidiNotes) {
      final notePc = midi % 12;
      final intervalFromRoot = (notePc - rootNote.pitchClass + 12) % 12;

      // FIX: Calculate extended interval for proper labeling
      final octaveDiff = (midi - rootNote.midi) ~/ 12;
      final extendedInterval = intervalFromRoot + (octaveDiff * 12);

      map[midi] = ColorUtils.colorForDegree(extendedInterval);

      final note = Note.fromMidi(midi, preferFlats: rootNote.preferFlats);
      debugPrint(
          '  Added to map: MIDI $midi (${note.fullName}) - extended interval $extendedInterval');
    }

    debugPrint('=== Highlight Map Complete: ${map.length} notes ===');
    return map;
  }

  /// Get complete highlight map based on view mode
  static Map<int, Color> getHighlightMap(FretboardConfig config) {
    switch (config.viewMode) {
      case ViewMode.scales:
        return getScaleHighlightMap(config);
      case ViewMode.intervals:
        return getIntervalHighlightMap(config);
      case ViewMode.chords:
        return getChordHighlightMap(config);
    }
  }

  /// Handle fretboard tap in interval mode
  static void handleIntervalModeTap(
    FretboardConfig config,
    int stringIndex,
    int fretIndex,
    Function(Set<int>) onIntervalsChanged,
  ) {
    final openStringNote = Note.fromString(config.tuning[stringIndex]);
    final tappedNote = openStringNote.transpose(fretIndex);

    final sortedOctaves = config.selectedOctaves.toList()..sort();
    final referenceOctave = sortedOctaves.isNotEmpty ? sortedOctaves.first : 3;
    final rootNote = Note.fromString('${config.root}$referenceOctave');
    final extendedInterval = tappedNote.midi - rootNote.midi;

    debugPrint(
        'Interval mode tap: tappedMidi=${tappedNote.midi}, rootMidi=${rootNote.midi}, extendedInterval=$extendedInterval');

    if (extendedInterval >= 0 && extendedInterval < 48) {
      final newIntervals = Set<int>.from(config.selectedIntervals);
      if (newIntervals.contains(extendedInterval)) {
        if (newIntervals.length > 1 || extendedInterval != 0) {
          newIntervals.remove(extendedInterval);
        }
      } else {
        newIntervals.add(extendedInterval);
      }

      onIntervalsChanged(newIntervals);
    }
  }

  /// Calculate visible fret range with corrections
  static int getCorrectedFretCount(FretboardConfig config) {
    if (config.visibleFretStart == 0) {
      return config.visibleFretCount;
    } else {
      // For non-zero start, add 1 to include both endpoints
      return config.visibleFretCount + 1;
    }
  }

  /// Get fret position for a note on a string
  static int? getFretForNote(
      Note targetNote, Note openStringNote, int maxFrets) {
    final fretNumber = targetNote.midi - openStringNote.midi;
    if (fretNumber >= 0 && fretNumber <= maxFrets) {
      return fretNumber;
    }
    return null;
  }

  /// Check if a note should be highlighted
  static bool shouldHighlightNote(int midi, Map<int, Color> highlightMap) {
    return highlightMap.containsKey(midi);
  }

  /// Get interval label for display with defensive programming
  static String getIntervalLabel(int interval) {
    const baseIntervals = [
      'R', // 0
      '♭2', // 1
      '2', // 2
      '♭3', // 3
      '3', // 4
      '4', // 5
      '♭5', // 6
      '5', // 7
      '♭6', // 8
      '6', // 9
      '♭7', // 10
      '7' // 11
    ];

    // Defensive check for negative intervals
    if (interval < 0) {
      debugPrint(
          'WARNING: getIntervalLabel called with negative interval: $interval');
      return 'R'; // Default to root
    }

    final octave = interval ~/ 12;
    final step = interval % 12;

    // Extra safety check (though modulo should always return 0-11)
    if (step < 0 || step >= baseIntervals.length) {
      debugPrint(
          'ERROR: Invalid step $step calculated from interval $interval');
      return 'R';
    }

    if (octave == 0) return baseIntervals[step];
    if (step == 0) return 'O$octave'; // Octave markers

    final raw = baseIntervals[step];
    final match = RegExp(r'([♭]?)(\d+)').firstMatch(raw);

    if (match != null) {
      final accidental = match.group(1) ?? '';
      final baseNumber = int.parse(match.group(2)!);
      final extendedNumber = baseNumber + (octave * 7);
      return '$accidental$extendedNumber';
    }

    return raw;
  }

  /// Get interval label with context for debugging
  static String getIntervalLabelSafe(int interval, String context) {
    if (interval < 0 || interval > 48) {
      debugPrint('WARNING: Invalid interval $interval in context: $context');
    }
    return getIntervalLabel(interval);
  }
}
