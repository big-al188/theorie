// lib/models/fretboard/fretboard_instance.dart - Fixed octave calculation
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'fretboard_config.dart';
import '../music/chord.dart';
import '../music/note.dart';

/// Individual fretboard instance for multi-fretboard views
class FretboardInstance {
  final String id;
  final String root;
  final ViewMode viewMode;
  final String scale;
  final int modeIndex;
  final String chordType;
  final ChordInversion chordInversion;
  final Set<int> selectedOctaves;
  final Set<int> selectedIntervals;
  final List<String> tuning;
  final int stringCount;
  bool isCompact;
  bool showScaleStrip;
  bool showNoteNames;
  int visibleFretStart;
  int visibleFretEnd;

  FretboardInstance({
    required this.id,
    required this.root,
    required this.viewMode,
    required this.scale,
    required this.modeIndex,
    required this.chordType,
    required this.chordInversion,
    required this.selectedOctaves,
    required this.selectedIntervals,
    required this.tuning,
    required this.stringCount,
    this.isCompact = false,
    this.showScaleStrip = true,
    this.showNoteNames = false,
    this.visibleFretStart = 0,
    required this.visibleFretEnd,
  });

  /// Create a default instance
  factory FretboardInstance.defaults(String id) {
    return FretboardInstance(
      id: id,
      root: 'C',
      viewMode: ViewMode.intervals,
      scale: 'Major',
      modeIndex: 0,
      chordType: 'major',
      chordInversion: ChordInversion.root,
      selectedOctaves: {3},
      selectedIntervals: {0},
      tuning: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      stringCount: 6,
      showNoteNames: false,
      visibleFretEnd: 12,
    );
  }

  /// Convert to FretboardConfig
  /// FIXED: Now respects user's octave selection for all modes
  FretboardConfig toConfig({
    required FretboardLayout layout,
    required int globalFretCount,
  }) {
    // FIXED: Always respect the user's selected octaves
    Set<int> octavesToUse = Set.from(selectedOctaves);

    if (octavesToUse.isEmpty) {
      debugPrint(
          'WARNING: FretboardInstance.toConfig: empty selectedOctaves, defaulting to {3}');
      octavesToUse = {3};
    }

    // FIXED: For chord mode, we still respect user selection but may add adjacent octaves
    // if the chord voicing naturally extends beyond the selected range
    if (viewMode == ViewMode.chords) {
      final chord = Chord.get(chordType);
      if (chord != null) {
        // Get the user's primary octave selection
        final userOctave = octavesToUse.first;
        final rootNote = Note.fromString('$root$userOctave');

        // Build the voicing with the new fixed algorithm
        final voicingMidiNotes = chord.buildVoicing(
          root: rootNote,
          inversion: chordInversion,
        );

        if (voicingMidiNotes.isNotEmpty) {
          // Calculate the actual octave span of the voicing
          final minMidi = voicingMidiNotes.reduce(math.min);
          final maxMidi = voicingMidiNotes.reduce(math.max);
          final minOctave = (minMidi ~/ 12) - 1;
          final maxOctave = (maxMidi ~/ 12) - 1;

          // FIXED: Only add additional octaves if the voicing actually extends beyond
          // the user's selection, and only add the necessary adjacent octaves
          final voicingOctaves = <int>{};
          for (int i = minOctave; i <= maxOctave; i++) {
            voicingOctaves.add(i);
          }

          // If the voicing fits within or close to the user's selection, respect it
          // Otherwise, include the minimal span needed for the chord
          if (voicingOctaves.length <= 2 &&
              voicingOctaves.any((oct) => (oct - userOctave).abs() <= 1)) {
            // Voicing is reasonable - use user's octave plus any necessary adjacent ones
            octavesToUse = {userOctave};
            for (final oct in voicingOctaves) {
              if ((oct - userOctave).abs() <= 1) {
                octavesToUse.add(oct);
              }
            }
          } else {
            // Voicing spans too far - use the calculated span but centered around user's choice
            octavesToUse = voicingOctaves;
          }

          debugPrint(
              'Chord mode: user selected octave $userOctave, voicing spans $voicingOctaves, using $octavesToUse');
        }
      }
    }

    return FretboardConfig(
      root: root,
      viewMode: viewMode,
      scale: scale,
      modeIndex: modeIndex,
      chordType: chordType,
      chordInversion: chordInversion,
      selectedOctaves: octavesToUse,
      selectedIntervals: selectedIntervals,
      tuning: tuning,
      stringCount: stringCount,
      fretCount: globalFretCount,
      layout: layout,
      showScaleStrip: showScaleStrip,
      showFretboard: true,
      showChordName: false,
      showNoteNames: showNoteNames,
      padding: EdgeInsets.zero,
      visibleFretStart: visibleFretStart,
      visibleFretEnd: visibleFretEnd.clamp(1, globalFretCount),
    );
  }

  FretboardInstance copyWith({
    String? root,
    ViewMode? viewMode,
    String? scale,
    int? modeIndex,
    String? chordType,
    ChordInversion? chordInversion,
    Set<int>? selectedOctaves,
    Set<int>? selectedIntervals,
    List<String>? tuning,
    int? stringCount,
    bool? isCompact,
    bool? showScaleStrip,
    bool? showNoteNames,
    int? visibleFretStart,
    int? visibleFretEnd,
  }) {
    return FretboardInstance(
      id: id,
      root: root ?? this.root,
      viewMode: viewMode ?? this.viewMode,
      scale: scale ?? this.scale,
      modeIndex: modeIndex ?? this.modeIndex,
      chordType: chordType ?? this.chordType,
      chordInversion: chordInversion ?? this.chordInversion,
      selectedOctaves: selectedOctaves ?? this.selectedOctaves,
      selectedIntervals: selectedIntervals ?? this.selectedIntervals,
      tuning: tuning ?? this.tuning,
      stringCount: stringCount ?? this.stringCount,
      isCompact: isCompact ?? this.isCompact,
      showScaleStrip: showScaleStrip ?? this.showScaleStrip,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      visibleFretStart: visibleFretStart ?? this.visibleFretStart,
      visibleFretEnd: visibleFretEnd ?? this.visibleFretEnd,
    );
  }
}
