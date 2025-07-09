// lib/controllers/fretboard_controller.dart - Fixed chord highlighting
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

    for (final octave in octaves) {
      // Create the root note for this octave
      final octaveRootNote = Note.fromString('$effectiveRoot$octave');
      final octaveRootMidi = octaveRootNote.midi;

      // For scale mode, we want to show notes from root to root+octave
      // This means we include all scale notes from the root up to (but not including) the next root
      for (int i = 0; i < pitchClasses.length; i++) {
        final interval = pitchClasses[i];
        final noteMidi = octaveRootMidi + interval;

        // Only include notes within the musical octave (root to root+12)
        if (interval >= 0 && interval <= 12) {
          map[noteMidi] = ColorUtils.colorForDegree(interval);
        }
      }

      // Always include the octave (root + 12)
      map[octaveRootMidi + 12] = ColorUtils.colorForDegree(12);
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

  /// Generate highlight map for chord mode with FIXED close voicing support
  static Map<int, Color> getChordHighlightMap(FretboardConfig config) {
    final map = <int, Color>{};
    final chord = Chord.get(config.chordType);
    if (chord == null) return {};

    // FIXED: Use the user's selected octave, not calculated octave
    final octave = config.selectedChordOctave;
    final rootNote = Note.fromString('${config.root}$octave');

    debugPrint('=== Building FIXED Chord Voicing Highlight Map ===');
    debugPrint(
        'Root: ${config.root}, User Selected Octave: $octave, Chord: ${config.chordType}, Inversion: ${config.chordInversion.displayName}');

    // Build chord voicing using the FIXED algorithm
    final voicingMidiNotes = chord.buildVoicing(
      root: rootNote,
      inversion: config.chordInversion,
    );

    debugPrint('FIXED Voicing MIDI notes: $voicingMidiNotes');

    // Color each note based on its interval from the USER'S selected root
    for (final midi in voicingMidiNotes) {
      // FIXED: Calculate interval from user's selected root, not chord's calculated root
      final extendedInterval = midi - rootNote.midi;

      // Use the extended interval for coloring to distinguish octave positions
      map[midi] = ColorUtils.colorForDegree(extendedInterval);

      final note = Note.fromMidi(midi, preferFlats: rootNote.preferFlats);
      debugPrint(
          '  FIXED: Added to map: MIDI $midi (${note.fullName}) - extended interval $extendedInterval from user root ${rootNote.fullName}');
    }

    debugPrint('=== FIXED Highlight Map Complete: ${map.length} notes ===');
    debugPrint('User selected octaves: ${config.selectedOctaves}');
    debugPrint(
        'Chord spans octaves: ${voicingMidiNotes.map((m) => Note.fromMidi(m).octave).toSet()}');

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
  static void handleIntervalModeTap(FretboardConfig config, int stringIndex,
      int fretIndex, Function(Set<int>) onIntervalsChanged,
      {Function(String, Set<int>)? onRootChanged}) {
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

      // Check if we should change root
      if (newIntervals.length == 1 &&
          !newIntervals.contains(0) &&
          onRootChanged != null) {
        final selectedInterval = newIntervals.first;
        final newRootNote = rootNote.transpose(selectedInterval);
        onRootChanged(newRootNote.name, {newRootNote.octave});
        // Return {0} as the new intervals since we're changing the root
        onIntervalsChanged({0});
      } else {
        onIntervalsChanged(newIntervals);
      }
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

  /// Check if single interval will become root
  static bool willIntervalBecomeRoot(FretboardConfig config, int midiNote) {
    if (!config.isIntervalMode ||
        config.selectedIntervals.length != 1 ||
        config.selectedIntervals.contains(0)) {
      return false;
    }

    final sortedOctaves = config.selectedOctaves.toList()..sort();
    final referenceOctave = sortedOctaves.isNotEmpty ? sortedOctaves.first : 3;
    final rootNote = Note.fromString('${config.root}$referenceOctave');
    final noteInterval = midiNote - rootNote.midi;

    return config.selectedIntervals.contains(noteInterval);
  }
}
