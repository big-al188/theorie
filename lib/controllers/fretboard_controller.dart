// lib/controllers/fretboard_controller.dart - Updated with additional octaves support (FIXED)
import 'package:flutter/material.dart';
import '../models/fretboard/fretboard_config.dart';
import '../models/fretboard/highlight_info.dart'; // NEW: Import highlight types
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

    // Get the mode intervals instead of the original scale intervals
    final modeIntervals = scale.getModeIntervals(config.modeIndex);

    for (final octave in config.selectedOctaves) {
      final rootNote = Note.fromString('$effectiveRoot$octave');

      for (int i = 0; i < modeIntervals.length; i++) {
        final interval = modeIntervals[i];
        final note = rootNote.transpose(interval);
        final color = ColorUtils.colorForDegree(interval); // Use actual interval, not position
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

  /// NEW: Generate additional octaves highlight map for chord modes
  static Map<int, HighlightInfo> getAdditionalOctavesMap(FretboardConfig config) {
    final map = <int, HighlightInfo>{};
    
    // Only apply in chord modes when toggle is enabled
    if (!config.showAdditionalOctaves || 
        (config.viewMode != ViewMode.chordInversions && config.viewMode != ViewMode.openChords)) {
      return map;
    }

    final chord = Chord.get(config.chordType);
    if (chord == null) return map;

    // Get the chord's letter names (note classes, not specific octaves)
    final rootNote = Note.fromString('${config.root}0'); // Use octave 0 for note class calculations
    
    // Get chord note classes by building chord from intervals
    final chordNoteClasses = <String>{};
    for (final interval in chord.intervals) {
      final chordNote = rootNote.transpose(interval);
      chordNoteClasses.add(chordNote.name); // FIXED: Use .name instead of .noteClass
    }

    debugPrint('Additional octaves: Looking for note classes: $chordNoteClasses');

    // Get primary highlights to avoid overlap (handle both chord modes)
    final primaryMap = config.viewMode == ViewMode.chordInversions 
        ? getChordInversionHighlightMap(config)
        : getOpenChordHighlightMap(config);

    // Calculate MIDI range for visible fretboard area
    final minMidi = _calculateMinMidiBounds(config);
    final maxMidi = _calculateMaxMidiBounds(config);

    debugPrint('Additional octaves: Searching MIDI range $minMidi to $maxMidi');

    // Find all instances of chord note classes across the fretboard
    for (int midi = minMidi; midi <= maxMidi; midi++) {
      final note = Note.fromMidi(midi, preferFlats: rootNote.preferFlats);
      
      // If this note class is in the chord and not already highlighted in primary
      if (chordNoteClasses.contains(note.name) && !primaryMap.containsKey(midi)) { // FIXED: Use .name instead of .noteClass
        map[midi] = HighlightInfo(
          midi: midi,
          type: HighlightType.additionalOctave,
          noteClass: note.name, // FIXED: Use .name instead of .noteClass
        );
      }
    }

    debugPrint('Additional octaves map: ${map.length} notes found');
    return map;
  }

  /// NEW: Helper - Calculate minimum MIDI note that could appear on fretboard
  static int _calculateMinMidiBounds(FretboardConfig config) {
    // Find lowest open string
    int minMidi = 127; // Start high
    for (final tuningNote in config.tuning) {
      final note = Note.fromString(tuningNote);
      if (note.midi < minMidi) {
        minMidi = note.midi;
      }
    }
    return minMidi; // Open strings are the minimum
  }

  /// NEW: Helper - Calculate maximum MIDI note that could appear on fretboard
  static int _calculateMaxMidiBounds(FretboardConfig config) {
    // Find highest string at highest visible fret
    int maxMidi = 0;
    for (final tuningNote in config.tuning) {
      final openNote = Note.fromString(tuningNote);
      final highestFrettedNote = openNote.transpose(config.visibleFretEnd);
      if (highestFrettedNote.midi > maxMidi) {
        maxMidi = highestFrettedNote.midi;
      }
    }
    return maxMidi;
  }

  /// NEW: Combined highlight data structure
  static CombinedHighlightMap getCombinedHighlightMap(FretboardConfig config) {
    return CombinedHighlightMap(
      primary: getHighlightMap(config),
      additional: getAdditionalOctavesMap(config),
    );
  }

  /// Generate highlight map for open chord mode
  static Map<int, Color> getOpenChordHighlightMap(FretboardConfig config) {
    final chord = Chord.get(config.chordType);
    if (chord == null) return {};

    debugPrint('=== Building Open Chord Highlight Map ===');
    debugPrint('Root: ${config.root}, Chord: ${config.chordType}, Inversion: ${config.chordInversion.displayName}');
    debugPrint('Show all positions: ${config.showAllPositions}');
    debugPrint('Visible fret start: ${config.visibleFretStart}, range: ${config.visibleFretStart} to ${config.visibleFretStart + 4}');

    if (config.showAllPositions) {
      // Show all positions: use the existing MIDI-based approach
      return _getOpenChordAllPositionsMap(config, chord);
    } else {
      // Default: only highlight the specific fret positions that form the open chord
      return _getOpenChordBasicPositionsMap(config, chord);
    }
  }

  /// Generate highlight map for open chord mode - all positions (MIDI-based)
  static Map<int, Color> _getOpenChordAllPositionsMap(FretboardConfig config, Chord chord) {
    final map = <int, Color>{};
    final rootNote = Note.fromString('${config.root}0');

    // First find the basic chord shape to get the MIDI notes
    final basicChordMidiNotes = <int>{};
    final chordTones = <int>{};
    for (final interval in chord.intervals) {
      final chordNote = rootNote.transpose(interval);
      chordTones.add(chordNote.pitchClass);
    }

    final bassNotePitchClass = chord.intervals.length > config.chordInversion.index
        ? rootNote.transpose(chord.intervals[config.chordInversion.index]).pitchClass
        : rootNote.pitchClass;

    // Find basic chord shape first (same logic as before)
    final stringIndicesWithTuning = <Map<String, dynamic>>[];
    for (int i = 0; i < config.tuning.length; i++) {
      final openNote = Note.fromString(config.tuning[i]);
      stringIndicesWithTuning.add({
        'index': i,
        'openMidi': openNote.midi,
        'openNote': openNote,
      });
    }
    stringIndicesWithTuning.sort((a, b) => a['openMidi'].compareTo(b['openMidi']));

    int? bassStringIndex;
    for (final stringData in stringIndicesWithTuning) {
      final stringIndex = stringData['index'] as int;
      final openNote = stringData['openNote'] as Note;
      
      for (int fret = config.visibleFretStart; fret <= config.visibleFretStart + 4; fret++) {
        final frettedNote = openNote.transpose(fret);
        if (frettedNote.pitchClass == bassNotePitchClass) {
          bassStringIndex = stringIndex;
          basicChordMidiNotes.add(frettedNote.midi);
          break;
        }
      }
      if (bassStringIndex != null) break;
    }

    if (bassStringIndex == null) return {};

    final bassStringMidi = Note.fromString(config.tuning[bassStringIndex]).midi;
    for (final stringData in stringIndicesWithTuning) {
      final openNote = stringData['openNote'] as Note;
      
      if (openNote.midi <= bassStringMidi) continue;
      
      for (int fret = config.visibleFretStart; fret <= config.visibleFretStart + 4; fret++) {
        final frettedNote = openNote.transpose(fret);
        if (chordTones.contains(frettedNote.pitchClass)) {
          basicChordMidiNotes.add(frettedNote.midi);
          break;
        }
      }
    }

    // Now find all occurrences of those MIDI notes
    debugPrint('Show all positions enabled - highlighting all occurrences of: $basicChordMidiNotes');
    
    for (int stringIndex = 0; stringIndex < config.tuning.length; stringIndex++) {
      final openNote = Note.fromString(config.tuning[stringIndex]);
      
      for (int fret = 0; fret <= config.visibleFretEnd; fret++) {
        final frettedNote = openNote.transpose(fret);
        
        if (basicChordMidiNotes.contains(frettedNote.midi)) {
          // Calculate the actual interval from the root note (same approach as chord inversion mode)
          final referenceRoot = Note.fromString('${config.root}3'); // Use consistent reference octave
          final extendedInterval = frettedNote.midi - referenceRoot.midi;
          
          final color = ColorUtils.colorForDegree(extendedInterval);
          map[frettedNote.midi] = color;
        }
      }
    }

    debugPrint('All positions map complete: ${map.length} notes');
    return map;
  }

  /// Generate highlight map for open chord mode - basic positions only (position-based)
  static Map<int, Color> _getOpenChordBasicPositionsMap(FretboardConfig config, Chord chord) {
    final map = <int, Color>{};
    final rootNote = Note.fromString('${config.root}0');

    // Get chord tones as note classes (pitch classes)
    final chordTones = <int>{};
    for (final interval in chord.intervals) {
      final chordNote = rootNote.transpose(interval);
      chordTones.add(chordNote.pitchClass);
    }

    // Determine bass note pitch class for the inversion
    final bassNotePitchClass = chord.intervals.length > config.chordInversion.index
        ? rootNote.transpose(chord.intervals[config.chordInversion.index]).pitchClass
        : rootNote.pitchClass;

    debugPrint('Basic positions only - looking for chord tones: $chordTones, bass: $bassNotePitchClass');

    // Track exactly which positions we're highlighting to avoid duplicates
    final highlightedPositions = <String, Map<String, dynamic>>{};  // "stringIndex:fret" -> note info
    
    // Sort strings by pitch (lowest to highest)
    final stringIndicesWithTuning = <Map<String, dynamic>>[];
    for (int i = 0; i < config.tuning.length; i++) {
      final openNote = Note.fromString(config.tuning[i]);
      stringIndicesWithTuning.add({
        'index': i,
        'openMidi': openNote.midi,
        'openNote': openNote,
      });
    }
    stringIndicesWithTuning.sort((a, b) => a['openMidi'].compareTo(b['openMidi']));

    // Find bass string (lowest string that can play the bass note)
    int? bassStringIndex;
    for (final stringData in stringIndicesWithTuning) {
      final stringIndex = stringData['index'] as int;
      final openNote = stringData['openNote'] as Note;
      
      // Check frets within range for bass note
      for (int fret = config.visibleFretStart; fret <= config.visibleFretStart + 4; fret++) {
        final frettedNote = openNote.transpose(fret);
        if (frettedNote.pitchClass == bassNotePitchClass) {
          bassStringIndex = stringIndex;
          
          // Record this exact position
          final positionKey = '$stringIndex:$fret';
          final chordToneIndex = chord.intervals.indexWhere((interval) {
            final chordToneNote = rootNote.transpose(interval);
            return chordToneNote.pitchClass == bassNotePitchClass;
          });
          
          // Store actual interval value for bass note
          final actualInterval = chordToneIndex >= 0 ? chord.intervals[chordToneIndex] : 0;
          
          highlightedPositions[positionKey] = {
            'stringIndex': stringIndex,
            'fret': fret,
            'midi': frettedNote.midi,
            'chordToneIndex': chordToneIndex,
            'actualInterval': actualInterval, // Store the actual interval
            'note': frettedNote,
          };
          
          debugPrint('Added bass position: string $stringIndex, fret $fret (${frettedNote.name})');
          break;
        }
      }
      if (bassStringIndex != null) break;
    }

    if (bassStringIndex == null) {
      debugPrint('No bass note found within range');
      return {};
    }

    // Now find one chord tone per string on higher strings
    final bassStringMidi = Note.fromString(config.tuning[bassStringIndex]).midi;
    
    for (final stringData in stringIndicesWithTuning) {
      final stringIndex = stringData['index'] as int;
      final openNote = stringData['openNote'] as Note;
      
      // Skip strings lower than or equal to bass string
      if (openNote.midi <= bassStringMidi) continue;
      
      // Find the first chord tone on this string within range
      for (int fret = config.visibleFretStart; fret <= config.visibleFretStart + 4; fret++) {
        final frettedNote = openNote.transpose(fret);
        if (chordTones.contains(frettedNote.pitchClass)) {
          // Record this exact position
          final positionKey = '$stringIndex:$fret';
          final chordToneIndex = chord.intervals.indexWhere((interval) {
            final chordToneNote = rootNote.transpose(interval);
            return chordToneNote.pitchClass == frettedNote.pitchClass;
          });
          
          // Store actual interval value, not just the index
          final actualInterval = chordToneIndex >= 0 ? chord.intervals[chordToneIndex] : 0;
          
          highlightedPositions[positionKey] = {
            'stringIndex': stringIndex,
            'fret': fret,
            'midi': frettedNote.midi,
            'chordToneIndex': chordToneIndex,
            'actualInterval': actualInterval, // Store the actual interval
            'note': frettedNote,
          };
          
          debugPrint('Added chord position: string $stringIndex, fret $fret (${frettedNote.name})');
          break; // Only one note per string for basic shape
        }
      }
    }

    // Now convert the position-based highlights to MIDI-based map
    // BUT only include the exact positions we identified
    for (final positionInfo in highlightedPositions.values) {
      final midi = positionInfo['midi'] as int;
      // Calculate the actual interval directly from MIDI (same approach as chord inversion mode)
      final referenceRoot = Note.fromString('${config.root}3'); // Use consistent reference octave
      final extendedInterval = midi - referenceRoot.midi;
      final color = ColorUtils.colorForDegree(extendedInterval);
      
      // CRITICAL: Only add this MIDI if it hasn't been added yet, or if it's the exact position we want
      if (!map.containsKey(midi)) {
        map[midi] = color;
      } else {
        // If MIDI already exists, we have a duplicate note - this shouldn't happen with proper logic
        // but if it does, we keep the first one (bass note priority)
        debugPrint('WARNING: Duplicate MIDI $midi found, keeping first occurrence');
      }
    }

    debugPrint('Basic positions map complete: ${map.length} notes from ${highlightedPositions.length} positions');
    debugPrint('Highlighted positions: ${highlightedPositions.keys.toList()}');
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
        return getOpenChordHighlightMap(config);
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
    final referenceRoot = Note.fromString('${config.root}$referenceOctave');

    // Calculate extended interval
    final extendedInterval = tappedMidi - referenceRoot.midi;
    final newIntervals = Set<int>.from(config.selectedIntervals);

    if (config.selectedIntervals.contains(extendedInterval)) {
      // Remove if already selected
      newIntervals.remove(extendedInterval);
    } else {
      // Add if not selected
      newIntervals.add(extendedInterval);
    }

    // Special case: if only one interval and it becomes root, change root
    if (newIntervals.length == 1 && 
        newIntervals.first != 0 && 
        onRootAndOctavesChanged != null) {
      final newRoot = tappedNote.name; // FIXED: Use .name instead of .noteClass
      final newOctaves = {tappedNote.octave};
      onRootAndOctavesChanged(newRoot, newOctaves);
    } else {
      onIntervalsChanged(newIntervals);
    }
  }

  /// Get interval label for display
  static String getIntervalLabel(int interval) {
    // Extended intervals beyond octave
    if (interval >= 12) {
      final octave = interval ~/ 12;
      final baseInterval = interval % 12;
      final base = _getBaseIntervalLabel(baseInterval);
      
      // For simple display, just add octave number
      final match = RegExp(r'([♭♯]?)(\d+)').firstMatch(base);
      if (match != null) {
        final accidental = match.group(1) ?? '';
        final number = int.parse(match.group(2)!);
        final extendedNumber = number + (octave * 7);
        return '$accidental$extendedNumber';
      }
    }
    
    return _getBaseIntervalLabel(interval);
  }

  /// Get base interval label (within one octave)
  static String _getBaseIntervalLabel(int interval) {
    const labels = [
      '1',   // Root
      '♭2',  // Minor 2nd
      '2',   // Major 2nd
      '♭3',  // Minor 3rd
      '3',   // Major 3rd
      '4',   // Perfect 4th
      '♭5',  // Tritone
      '5',   // Perfect 5th
      '♭6',  // Minor 6th
      '6',   // Major 6th
      '♭7',  // Minor 7th
      '7',   // Major 7th
    ];
    
    final normalizedInterval = interval % 12;
    if (normalizedInterval >= 0 && normalizedInterval < labels.length) {
      return labels[normalizedInterval];
    }
    
    return interval.toString(); // Fallback
  }

  /// Convert extended interval label to display format
  static String getExtendedIntervalLabel(int interval, int octave) {
    final baseLabel = _getBaseIntervalLabel(interval);
    if (octave <= 0) return baseLabel;

    // Parse the base label to add octave extension
    final raw = baseLabel;
    final match = RegExp(r'([♭♯]?)(\d+)').firstMatch(raw);

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

// In fretboard_controller.dart, change getCorrectedFretCount to:
static int getCorrectedFretCount(FretboardConfig config) {
  if (config.visibleFretStart == 0) {
    // FIXED: Need to process frets 0 through visibleFretEnd (includes fret 12)
    // Return visibleFretEnd + 1 so loop processes all frets
    return config.visibleFretEnd + 1;  // 13 for range 0-12
  } else {
    // Zoomed case: showing frets from visibleFretStart to visibleFretEnd (inclusive)
    return config.visibleFretEnd - config.visibleFretStart + 1;
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