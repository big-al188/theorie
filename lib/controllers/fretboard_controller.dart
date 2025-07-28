// lib/controllers/fretboard_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/fretboard/fretboard_config.dart';
import '../models/music/note.dart';
import '../models/music/scale.dart';
import '../models/music/chord.dart';
import '../utils/color_utils.dart';
import 'music_controller.dart';

/// Controller for fretboard display logic and interactions
class FretboardController {
  /// Generate highlight map for scale mode
  static Map<int, Color> getScaleHighlightMap(FretboardConfig config) {
    final map = <int, Color>{};
    final scale = Scale.get(config.scale);
    if (scale == null) return {};

    // Get the effective root for the mode
    final effectiveRoot = MusicController.getModeRoot(
        config.root, config.scale, config.modeIndex);

    for (final octave in config.selectedOctaves) {
      final rootNote = Note.fromString('$effectiveRoot$octave');

      for (int i = 0; i < scale.intervals.length; i++) {
        final interval = scale.intervals[i];
        final note = rootNote.transpose(interval);
        final color = ColorUtils.colorForDegree(i);
        map[note.midi] = color;
      }
    }

    return map;
  }

  /// Generate highlight map for interval mode
  static Map<int, Color> getIntervalHighlightMap(FretboardConfig config) {
    final map = <int, Color>{};

    // Handle empty intervals
    if (config.selectedIntervals.isEmpty) return {};

    // Use the configured octaves, or default to octave 3
    final octaves = config.selectedOctaves.isNotEmpty
        ? config.selectedOctaves
        : {3};
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

  /// Generate highlight map for chord inversion mode with FIXED close voicing support
  static Map<int, Color> getChordInversionHighlightMap(FretboardConfig config) {
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

  /// Generate highlight map for unimplemented chord modes (placeholder)
  static Map<int, Color> getUnimplementedChordHighlightMap(FretboardConfig config) {
    // For now, return empty map for unimplemented modes
    // This can be expanded when these modes are implemented
    debugPrint('${config.viewMode.displayName} mode is not yet implemented');
    return <int, Color>{};
  }

  /// Get complete highlight map based on view mode
  static Map<int, Color> getHighlightMap(FretboardConfig config) {
    switch (config.viewMode) {
      case ViewMode.scales:
        return getScaleHighlightMap(config);
      case ViewMode.intervals:
        return getIntervalHighlightMap(config);
      case ViewMode.chordInversions:
        return getChordInversionHighlightMap(config);
      case ViewMode.openChords:
      case ViewMode.barreChords:
      case ViewMode.advancedChords:
        return getUnimplementedChordHighlightMap(config);
    }
  }

  /// Handle fretboard tap in interval mode
  static void handleIntervalModeTap(FretboardConfig config, int stringIndex,
      int fretIndex, Function(Set<int>) onIntervalsChanged,
      {Function(String, Set<int>)? onRootAndOctavesChanged}) {
    
    // Calculate tapped note
    final openString = Note.fromString(config.tuning[stringIndex]);
    final tappedNote = openString.transpose(fretIndex);
    final tappedMidi = tappedNote.midi;

    // Get reference octave
    final referenceOctave = config.selectedOctaves.isNotEmpty
        ? config.selectedOctaves.reduce((a, b) => a < b ? a : b)
        : 3;
    final rootNote = Note.fromString('${config.root}$referenceOctave');

    // Calculate extended interval
    final extendedInterval = tappedMidi - rootNote.midi;

    var newIntervals = Set<int>.from(config.selectedIntervals);
    var newOctaves = Set<int>.from(config.selectedOctaves);
    var newRoot = config.root;

    // Handle based on current state
    if (newIntervals.isEmpty) {
      // No notes selected - this becomes the new root
      newRoot = tappedNote.name;
      newIntervals = {0};
      newOctaves = {tappedNote.octave};
    } else if (newIntervals.contains(extendedInterval)) {
      // Removing existing interval
      newIntervals.remove(extendedInterval);
      
      if (newIntervals.isEmpty) {
        // Empty state
      } else if (extendedInterval == 0) {
        // Root removal - find new root
        final lowestInterval = newIntervals.reduce((a, b) => a < b ? a : b);
        final newRootMidi = rootNote.midi + lowestInterval;
        final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
        newRoot = newRootNote.name;
        newOctaves = {newRootNote.octave};

        // Adjust all intervals relative to new root
        final adjustedIntervals = <int>{};
        for (final interval in newIntervals) {
          final adjustedInterval = interval - lowestInterval;
          adjustedIntervals.add(adjustedInterval);
          
          final noteMidi = newRootMidi + adjustedInterval;
          final noteOctave = Note.fromMidi(noteMidi).octave;
          newOctaves.add(noteOctave);
        }
        newIntervals = adjustedIntervals;
      } else if (newIntervals.length == 1 && !newIntervals.contains(0)) {
        // Single interval becomes root
        final singleInterval = newIntervals.first;
        final newRootMidi = rootNote.midi + singleInterval;
        final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
        newRoot = newRootNote.name;
        newOctaves = {newRootNote.octave};
        newIntervals = {0};
      }
    } else {
      // Adding new interval
      if (extendedInterval < 0) {
        // Note below current root - extend octaves downward
        final octavesDown = ((-extendedInterval - 1) ~/ 12) + 1;
        final newReferenceOctave = referenceOctave - octavesDown;

        // Add lower octaves
        for (int i = 0; i < octavesDown; i++) {
          newOctaves.add(referenceOctave - i - 1);
        }

        // Recalculate intervals from new reference
        final newRootNote = Note.fromString('${config.root}$newReferenceOctave');
        
        final adjustedIntervals = <int>{};
        for (final interval in newIntervals) {
          adjustedIntervals.add(interval + (octavesDown * 12));
        }

        final adjustedNewInterval = tappedMidi - newRootNote.midi;
        adjustedIntervals.add(adjustedNewInterval);
        
        newIntervals = adjustedIntervals;
      } else {
        // Normal case - just add interval
        newIntervals.add(extendedInterval);
        
        if (!newOctaves.contains(tappedNote.octave)) {
          newOctaves.add(tappedNote.octave);
        }
      }
    }

    // Apply changes
    if (onRootAndOctavesChanged != null && newRoot != config.root) {
      onRootAndOctavesChanged(newRoot, newOctaves);
    }
    onIntervalsChanged(newIntervals);
  }

  /// Handle scale note tap (from scale strip)
  static void handleScaleNoteTap(FretboardConfig config, int midiNote,
      Function(Set<int>) onIntervalsChanged,
      {Function(String, Set<int>)? onRootAndOctavesChanged}) {
    
    if (config.viewMode != ViewMode.intervals) return;

    final clickedNote = Note.fromMidi(midiNote);
    
    // Calculate extended interval
    final referenceOctave = config.selectedOctaves.isEmpty
        ? 3
        : config.selectedOctaves.reduce((a, b) => a < b ? a : b);
    final rootNote = Note.fromString('${config.root}$referenceOctave');
    final extendedInterval = midiNote - rootNote.midi;

    var newIntervals = Set<int>.from(config.selectedIntervals);
    var newOctaves = Set<int>.from(config.selectedOctaves);
    var newRoot = config.root;

    // Handle similar to fret tap logic
    if (newIntervals.isEmpty) {
      newRoot = clickedNote.name;
      newIntervals = {0};
      newOctaves = {clickedNote.octave};
    } else if (newIntervals.contains(extendedInterval)) {
      // Remove interval
      newIntervals.remove(extendedInterval);
      
      if (newIntervals.isEmpty) {
        // Empty state
      } else if (extendedInterval == 0) {
        // Root removal
        final lowestInterval = newIntervals.reduce((a, b) => a < b ? a : b);
        final newRootMidi = rootNote.midi + lowestInterval;
        final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
        newRoot = newRootNote.name;
        newOctaves = {newRootNote.octave};

        final adjustedIntervals = <int>{};
        for (final interval in newIntervals) {
          final adjustedInterval = interval - lowestInterval;
          adjustedIntervals.add(adjustedInterval);
          
          final noteMidi = newRootMidi + adjustedInterval;
          final noteOctave = Note.fromMidi(noteMidi).octave;
          newOctaves.add(noteOctave);
        }
        newIntervals = adjustedIntervals;
      } else if (newIntervals.length == 1 && !newIntervals.contains(0)) {
        final singleInterval = newIntervals.first;
        final newRootMidi = rootNote.midi + singleInterval;
        final newRootNote = Note.fromMidi(newRootMidi, preferFlats: rootNote.preferFlats);
        newRoot = newRootNote.name;
        newOctaves = {newRootNote.octave};
        newIntervals = {0};
      }
    } else {
      // Add new interval
      if (extendedInterval < 0) {
        final octavesDown = ((-extendedInterval - 1) ~/ 12) + 1;
        final newReferenceOctave = referenceOctave - octavesDown;

        for (int i = 0; i < octavesDown; i++) {
          newOctaves.add(referenceOctave - i - 1);
        }

        final newRootNote = Note.fromString('${config.root}$newReferenceOctave');
        
        final adjustedIntervals = <int>{};
        for (final interval in newIntervals) {
          adjustedIntervals.add(interval + (octavesDown * 12));
        }

        final adjustedNewInterval = midiNote - newRootNote.midi;
        adjustedIntervals.add(adjustedNewInterval);
        
        newIntervals = adjustedIntervals;
      } else {
        newIntervals.add(extendedInterval);
        
        if (!newOctaves.contains(clickedNote.octave)) {
          newOctaves.add(clickedNote.octave);
        }
      }
    }

    // Apply changes
    if (onRootAndOctavesChanged != null && newRoot != config.root) {
      onRootAndOctavesChanged(newRoot, newOctaves);
    }
    onIntervalsChanged(newIntervals);
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

  /// Helper method to check if mode is any chord mode
  static bool isAnyChordMode(ViewMode viewMode) {
    return viewMode == ViewMode.chordInversions ||
           viewMode == ViewMode.openChords ||
           viewMode == ViewMode.barreChords ||
           viewMode == ViewMode.advancedChords;
  }

  /// Helper method to check if mode is implemented
  static bool isModeImplemented(ViewMode viewMode) {
    return viewMode.isImplemented;
  }

  /// Legacy support for old isChordMode checks
  static bool isChordMode(ViewMode viewMode) {
    return viewMode == ViewMode.chordInversions;
  }
}