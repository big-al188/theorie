// lib/models/fretboard/fretboard_instance.dart - Updated with showAdditionalOctaves
import 'package:flutter/material.dart';
import 'fretboard_config.dart';
import '../music/chord.dart';

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
  bool showAdditionalOctaves; // NEW: Show chord notes in additional octaves
  bool showAllPositions; // NEW: Show all positions for open chords
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
    this.showAdditionalOctaves = false, // NEW: Default to false
    this.showAllPositions = false, // NEW: Default to false
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
      showScaleStrip: true,
      showNoteNames: false,
      showAdditionalOctaves: false, // NEW: Default to false
      visibleFretEnd: 12,
    );
  }

  /// Convert to FretboardConfig
  FretboardConfig toConfig({
    required FretboardLayout layout,
    required int globalFretCount,
  }) {
    // Always respect the user's selected octaves for the config
    // The scale strip will do its own smart octave detection based on highlighted notes
    Set<int> octavesToUse = Set.from(selectedOctaves);

    if (octavesToUse.isEmpty) {
      debugPrint(
          'WARNING: FretboardInstance.toConfig: empty selectedOctaves, defaulting to {3}');
      octavesToUse = {3};
    }

    // Note: We don't do octave expansion here anymore.
    // The scale strip will determine its own octaves based on highlighted notes.
    debugPrint(
        'FretboardInstance.toConfig: using user-selected octaves for config: $octavesToUse');

    return FretboardConfig(
      root: root,
      viewMode: viewMode,
      scale: scale,
      modeIndex: modeIndex,
      chordType: chordType,
      chordInversion: chordInversion,
      selectedOctaves: octavesToUse, // User selection for generating highlights
      selectedIntervals: selectedIntervals,
      tuning: tuning,
      stringCount: stringCount,
      fretCount: globalFretCount,
      layout: layout,
      showScaleStrip: showScaleStrip,
      showFretboard: true,
      showChordName: false,
      showNoteNames: showNoteNames,
      showAdditionalOctaves: showAdditionalOctaves,
      showAllPositions: showAllPositions,
      width: 400.0,
      height: 300.0,
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
    bool? showAdditionalOctaves, // NEW: Add to copyWith method
    bool? showAllPositions, // NEW: Add to copyWith method
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
      showAdditionalOctaves:
          showAdditionalOctaves ?? this.showAdditionalOctaves, // NEW
      showAllPositions: showAllPositions ?? this.showAllPositions, // NEW
      visibleFretStart: visibleFretStart ?? this.visibleFretStart,
      visibleFretEnd: visibleFretEnd ?? this.visibleFretEnd,
    );
  }
}
