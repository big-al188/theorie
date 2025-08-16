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

    // Calculate keyboard MIDI range
    final startNote = Note.fromString(config.startNote);
    final keyboardStartMidi = startNote.midi;
    final keyboardEndMidi = keyboardStartMidi + config.keyCount - 1;

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
        
        // Only add to highlight map if within keyboard range
        if (note.midi >= keyboardStartMidi && note.midi <= keyboardEndMidi) {
          final color = ColorUtils.colorForDegree(interval);
          map[note.midi] = color;
        }
      }
    }

    return map;
  }

  /// Generate highlight map for interval mode
  static Map<int, Color> getIntervalHighlightMap(KeyboardConfig config) {
    final map = <int, Color>{};

    // Handle empty intervals
    if (config.selectedIntervals.isEmpty) return {};

    // Calculate keyboard MIDI range
    final startNote = Note.fromString(config.startNote);
    final keyboardStartMidi = startNote.midi;
    final keyboardEndMidi = keyboardStartMidi + config.keyCount - 1;

    // Use the configured octaves, or default to octave 3
    final octaves = config.selectedOctaves.isNotEmpty
        ? config.selectedOctaves
        : {3};
    final referenceOctave = config.minSelectedOctave;
    final rootNote = Note.fromString('${config.root}$referenceOctave');

    for (final extendedInterval in config.selectedIntervals) {
      final specificMidi = rootNote.midi + extendedInterval;
      
      // Only add to highlight map if within keyboard range
      if (specificMidi >= keyboardStartMidi && specificMidi <= keyboardEndMidi) {
        final noteOctave = Note.fromMidi(specificMidi).octave;
        
        // Only highlight if in selected octaves
        if (octaves.contains(noteOctave)) {
          // Use the actual extended interval for color (but mod 12 for color consistency)
          final colorInterval = extendedInterval % 12;
          map[specificMidi] = ColorUtils.colorForDegree(colorInterval);
        }
      }
    }

    return map;
  }

  /// Generate highlight map for chord inversion mode
  static Map<int, Color> getChordInversionHighlightMap(KeyboardConfig config) {
    final map = <int, Color>{};
    final chord = Chord.get(config.chordType);
    if (chord == null) return {};

    // Calculate keyboard MIDI range
    final startNote = Note.fromString(config.startNote);
    final keyboardStartMidi = startNote.midi;
    final keyboardEndMidi = keyboardStartMidi + config.keyCount - 1;

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
      // Only add to highlight map if within keyboard range
      if (midi >= keyboardStartMidi && midi <= keyboardEndMidi) {
        final extendedInterval = midi - rootNote.midi;
        map[midi] = ColorUtils.colorForDegree(extendedInterval);

        debugPrint(
            'MIDI $midi -> interval $extendedInterval -> color ${ColorUtils.colorForDegree(extendedInterval)}');
      }
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
    
    // Calculate keyboard MIDI range
    final startNote = Note.fromString(config.startNote);
    final keyboardStartMidi = startNote.midi;
    final keyboardEndMidi = keyboardStartMidi + config.keyCount - 1;
    
    // Add highlights one octave up and down
    for (final entry in baseMap.entries) {
      final baseMidi = entry.key;
      final color = entry.value;
      
      // Add octave above
      final upperOctave = baseMidi + 12;
      if (upperOctave >= keyboardStartMidi && upperOctave <= keyboardEndMidi) {
        additionalMap[upperOctave] = color;
      }
      
      // Add octave below
      final lowerOctave = baseMidi - 12;
      if (lowerOctave >= keyboardStartMidi && lowerOctave <= keyboardEndMidi) {
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

  /// Convert interval to display label with extended intervals
  static String _intervalToLabel(int extendedInterval) {
    // For negative intervals, show them as negative
    if (extendedInterval < 0) {
      return '-${_intervalToLabel(-extendedInterval)}';
    }
    
    // Use the same logic as FretboardController for extended intervals
    if (extendedInterval >= 12) {
      final octave = extendedInterval ~/ 12;
      final baseInterval = extendedInterval % 12;
      final base = _getBaseIntervalLabel(baseInterval);
      
      // Convert to extended interval notation (2nd -> 9th, 3rd -> 10th, etc.)
      final match = RegExp(r'([♭♯]?)(\d+)').firstMatch(base);
      if (match != null) {
        final accidental = match.group(1) ?? '';
        final number = int.parse(match.group(2)!);
        final extendedNumber = number + (octave * 7);
        return '$accidental$extendedNumber';
      }
    }
    
    return _getBaseIntervalLabel(extendedInterval);
  }

  /// Get base interval label (within one octave)
  static String _getBaseIntervalLabel(int interval) {
    switch (interval % 12) {
      case 0: return '1';   // Root (consistent with FretboardController)
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

  /// Handle octave changes while preserving actual note positions
  static KeyboardConfig handleOctaveChange(KeyboardConfig config, Set<int> newSelectedOctaves) {
    // If not in interval mode, just update octaves normally
    if (!config.isIntervalMode || config.selectedIntervals.isEmpty) {
      return config.copyWith(selectedOctaves: newSelectedOctaves);
    }

    // For interval mode, preserve the actual MIDI notes when reference octave changes
    final oldReferenceOctave = config.minSelectedOctave;
    final newReferenceOctave = newSelectedOctaves.isEmpty 
        ? 3 
        : newSelectedOctaves.reduce((a, b) => a < b ? a : b);

    // If reference octave didn't change, just update octaves
    if (oldReferenceOctave == newReferenceOctave) {
      return config.copyWith(selectedOctaves: newSelectedOctaves);
    }

    // Calculate current actual MIDI notes
    final oldRootMidi = Note.fromString('${config.root}$oldReferenceOctave').midi;
    final actualMidiNotes = config.selectedIntervals.map((interval) => oldRootMidi + interval).toSet();

    // Recalculate intervals relative to new reference octave
    final newRootMidi = Note.fromString('${config.root}$newReferenceOctave').midi;
    final newIntervals = actualMidiNotes.map((midi) => midi - newRootMidi).toSet();

    debugPrint('Keyboard octave change:');
    debugPrint('  Old reference: ${config.root}$oldReferenceOctave (MIDI $oldRootMidi)');
    debugPrint('  New reference: ${config.root}$newReferenceOctave (MIDI $newRootMidi)');
    debugPrint('  Old intervals: ${config.selectedIntervals}');
    debugPrint('  New intervals: $newIntervals');
    debugPrint('  Preserved MIDI notes: $actualMidiNotes');

    return config.copyWith(
      selectedOctaves: newSelectedOctaves,
      selectedIntervals: newIntervals,
    );
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