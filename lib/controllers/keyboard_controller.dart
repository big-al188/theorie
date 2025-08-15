// lib/controllers/keyboard_controller.dart
import 'package:flutter/material.dart';
import '../models/keyboard/keyboard_config.dart';
import '../models/keyboard/key_configuration.dart';
import '../models/music/note.dart';
import '../models/music/scale.dart';
import '../models/music/chord.dart';
import '../models/fretboard/fretboard_config.dart'; // For ViewMode
import '../utils/color_utils.dart';
import 'music_controller.dart';
import 'fretboard_controller.dart';

/// Controller for keyboard display logic and interactions
/// Following the same pattern as FretboardController for consistency
class KeyboardController {
  /// Generate highlight map for the keyboard based on current mode
  static Map<int, Color> getHighlightMap(KeyboardConfig config) {
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
        // For now, use chord inversion logic for all chord modes
        return getChordInversionHighlightMap(config);
    }
  }

  /// Generate highlight map for scale mode
  static Map<int, Color> getScaleHighlightMap(KeyboardConfig config) {
    final map = <int, Color>{};
    final scale = Scale.get(config.scale);
    if (scale == null) return {};

    // Get the effective root for the mode
    final effectiveRoot = MusicController.getModeRoot(
        config.root, config.scale, config.modeIndex);

    // Get the mode intervals instead of the original scale intervals
    final modeIntervals = scale.getModeIntervals(config.modeIndex);

    for (final octave in config.selectedOctaves) {
      final rootNote = Note.fromString('$effectiveRoot$octave');

      for (int i = 0; i < modeIntervals.length; i++) {
        final interval = modeIntervals[i];
        
        // Skip octave note if showOctave is disabled and this is the octave interval
        if (!config.showOctave && interval == 12) {
          continue;
        }
        
        final note = rootNote.transpose(interval);
        final color = ColorUtils.colorForDegree(interval);
        map[note.midi] = color;
      }
    }

    return map;
  }

  /// Generate highlight map for interval mode
  static Map<int, Color> getIntervalHighlightMap(KeyboardConfig config) {
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

  /// Generate highlight map for chord inversion mode
  static Map<int, Color> getChordInversionHighlightMap(KeyboardConfig config) {
    final map = <int, Color>{};
    final chord = Chord.get(config.chordType);
    if (chord == null) return {};

    // Use the user's selected octave
    final octave = config.selectedChordOctave;
    final rootNote = Note.fromString('${config.root}$octave');

    debugPrint('=== Building Keyboard Chord Highlight Map ===');
    debugPrint(
        'Root: ${config.root}, User Selected Octave: $octave, Chord: ${config.chordType}, Inversion: ${config.chordInversion.displayName}');

    // Build chord voicing
    final voicingMidiNotes = chord.buildVoicing(
      root: rootNote,
      inversion: config.chordInversion,
    );

    debugPrint('Chord Voicing MIDI notes: $voicingMidiNotes');

    // Color each note based on its interval from the user's selected root
    for (final midi in voicingMidiNotes) {
      final extendedInterval = midi - rootNote.midi;
      map[midi] = ColorUtils.colorForDegree(extendedInterval);

      debugPrint(
          'MIDI $midi -> interval $extendedInterval -> color ${ColorUtils.colorForDegree(extendedInterval)}');
    }

    // Add additional octaves if requested
    if (config.showAdditionalOctaves) {
      final additionalMaps = _getAdditionalOctaveHighlights(map, config);
      map.addAll(additionalMaps);
    }

    debugPrint('Final keyboard highlight map: $map');
    return map;
  }

  /// Get additional octave highlights for chord modes
  static Map<int, Color> _getAdditionalOctaveHighlights(
      Map<int, Color> baseMap, KeyboardConfig config) {
    final additionalMap = <int, Color>{};
    
    // Add highlights one octave up and down
    for (final entry in baseMap.entries) {
      final baseMidi = entry.key;
      final color = entry.value;
      
      // Add octave above
      final upperOctave = baseMidi + 12;
      if (upperOctave <= 127) { // MIDI range check
        additionalMap[upperOctave] = color;
      }
      
      // Add octave below
      final lowerOctave = baseMidi - 12;
      if (lowerOctave >= 0) { // MIDI range check
        additionalMap[lowerOctave] = color;
      }
    }
    
    return additionalMap;
  }

  /// Generate key configurations for the entire keyboard
  static List<KeyConfiguration> generateKeyConfigurations(KeyboardConfig config) {
    final keys = <KeyConfiguration>[];
    final startNote = Note.fromString(config.startNote);
    final highlightMap = getHighlightMap(config);

    for (int i = 0; i < config.keyCount; i++) {
      final midiNote = startNote.midi + i;
      final isHighlighted = highlightMap.containsKey(midiNote);
      final highlightColor = highlightMap[midiNote];

      String? intervalLabel;
      if (isHighlighted && config.showNoteNames) {
        // Show note names instead of intervals
        final note = Note.fromMidi(midiNote);
        intervalLabel = note.name;
      } else if (isHighlighted) {
        // Show interval labels
        intervalLabel = _getIntervalLabel(midiNote, config);
      }

      final keyConfig = KeyConfiguration.fromMidiNote(
        keyIndex: i,
        midiNote: midiNote,
        isHighlighted: isHighlighted,
        highlightColor: highlightColor,
        intervalLabel: intervalLabel,
      );

      keys.add(keyConfig);
    }

    return keys;
  }

  /// Get interval label for a MIDI note
  /// Get interval label for a given MIDI note and interval
  static String getIntervalLabel(int interval) {
    // Use the same interval labels as FretboardController
    return FretboardController.getIntervalLabel(interval);
  }

  static String? _getIntervalLabel(int midiNote, KeyboardConfig config) {
    if (config.selectedIntervals.isEmpty && !config.isScaleMode) return null;

    final referenceOctave = config.minSelectedOctave;
    final rootNote = Note.fromString('${config.root}$referenceOctave');
    final extendedInterval = midiNote - rootNote.midi;

    // For scale mode, use effective root
    if (config.isScaleMode) {
      final effectiveRoot = MusicController.getModeRoot(
          config.root, config.scale, config.modeIndex);
      final effectiveRootNote = Note.fromString('$effectiveRoot$referenceOctave');
      final effectiveInterval = midiNote - effectiveRootNote.midi;
      return _intervalToLabel(effectiveInterval);
    }

    return _intervalToLabel(extendedInterval);
  }

  /// Convert interval to display label
  static String _intervalToLabel(int extendedInterval) {
    final simpleInterval = extendedInterval % 12;
    switch (simpleInterval) {
      case 0: return 'R';
      case 1: return '♭2';
      case 2: return '2';
      case 3: return '♭3';
      case 4: return '3';
      case 5: return '4';
      case 6: return '♭5';
      case 7: return '5';
      case 8: return '♭6';
      case 9: return '6';
      case 10: return '♭7';
      case 11: return '7';
      default: return '';
    }
  }

  /// Calculate the total width needed for white keys
  static double calculateWhiteKeyTotalWidth(KeyboardConfig config, double whiteKeyWidth) {
    final keys = generateKeyConfigurations(config);
    final whiteKeyCount = keys.where((key) => key.isWhiteKey).length;
    return whiteKeyCount * whiteKeyWidth;
  }

  /// Calculate the position of a white key
  static double calculateWhiteKeyPosition(int whiteKeyIndex, double whiteKeyWidth) {
    return whiteKeyIndex * whiteKeyWidth;
  }

  /// Calculate the position of a black key relative to white keys
  static double calculateBlackKeyPosition(KeyConfiguration blackKey, double whiteKeyWidth) {
    final visualPosition = blackKey.getBlackKeyVisualPosition();
    if (visualPosition == null) return 0.0;

    // Calculate which octave this key is in
    final octave = blackKey.midiNote ~/ 12;
    final whiteKeysPerOctave = 7;
    final octaveOffset = octave * whiteKeysPerOctave * whiteKeyWidth;

    return octaveOffset + (visualPosition * whiteKeyWidth);
  }

  /// Handle key tap interaction
  static void handleKeyTap(KeyConfiguration key, KeyboardConfig config, 
      Function(KeyboardConfig) onConfigUpdate) {
    debugPrint('Key tapped: ${key.fullNoteName} (MIDI: ${key.midiNote})');

    if (config.isIntervalMode) {
      _handleIntervalModeKeyTap(key, config, onConfigUpdate);
    } else if (config.isScaleMode) {
      _handleScaleModeKeyTap(key, config, onConfigUpdate);
    } else if (config.isAnyChordMode) {
      _handleChordModeKeyTap(key, config, onConfigUpdate);
    }
  }

  /// Handle key tap in interval mode
  static void _handleIntervalModeKeyTap(KeyConfiguration key, KeyboardConfig config, 
      Function(KeyboardConfig) onConfigUpdate) {
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
    final updatedConfig = config.copyWith(
      root: newRoot,
      selectedIntervals: newIntervals,
      selectedOctaves: newOctaves,
    );
    onConfigUpdate(updatedConfig);
  }

  /// Handle key tap in scale mode (simplified for now)
  static void _handleScaleModeKeyTap(KeyConfiguration key, KeyboardConfig config, 
      Function(KeyboardConfig) onConfigUpdate) {
    // For scale mode, key taps could change the root
    final tappedNote = Note.fromMidi(key.midiNote);
    final updatedConfig = config.copyWith(root: tappedNote.name);
    onConfigUpdate(updatedConfig);
  }

  /// Handle key tap in chord mode (simplified for now)
  static void _handleChordModeKeyTap(KeyConfiguration key, KeyboardConfig config, 
      Function(KeyboardConfig) onConfigUpdate) {
    // For chord mode, key taps could change the root
    final tappedNote = Note.fromMidi(key.midiNote);
    final updatedConfig = config.copyWith(root: tappedNote.name);
    onConfigUpdate(updatedConfig);
  }
}