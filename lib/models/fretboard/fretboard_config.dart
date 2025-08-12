// lib/models/fretboard/fretboard_config.dart - Updated with showAdditionalOctaves
import 'package:flutter/material.dart';
import '../music/chord.dart';
import '../../controllers/fretboard_controller.dart';
import '../../controllers/music_controller.dart';

/// Configuration for fretboard display and behavior
class FretboardConfig {
  final int stringCount;
  final int fretCount;
  final List<String> tuning;
  final FretboardLayout layout;
  final String root;
  final ViewMode viewMode;
  final String scale;
  final int modeIndex;
  final String chordType;
  final ChordInversion chordInversion;
  final bool showScaleStrip;
  final bool showFretboard;
  final bool showChordName;
  final bool showNoteNames;
  final bool showAdditionalOctaves; // NEW: Show chord notes in additional octaves
  final bool showAllPositions; // NEW: Show all positions for open chords
  final Set<int> selectedOctaves;
  final Set<int> selectedIntervals;
  final double width;
  final double height;
  final EdgeInsets padding;
  final int visibleFretStart;
  final int visibleFretEnd;

  const FretboardConfig({
    required this.stringCount,
    required this.fretCount,
    required this.tuning,
    required this.layout,
    required this.root,
    required this.viewMode,
    required this.scale,
    required this.modeIndex,
    required this.chordType,
    required this.chordInversion,
    required this.showScaleStrip,
    required this.showFretboard,
    required this.showChordName,
    required this.showNoteNames,
    required this.showAdditionalOctaves, // NEW: Required parameter
    required this.showAllPositions, // NEW: Required parameter
    required this.selectedOctaves,
    required this.selectedIntervals,
    required this.width,
    required this.height,
    required this.padding,
    required this.visibleFretStart,
    required this.visibleFretEnd,
  });

  // Derived properties
  bool get isLeftHanded => layout.isLeftHanded;
  bool get isBassTop => layout.isBassTop;
  bool get isScaleMode => viewMode == ViewMode.scales;
  bool get isIntervalMode => viewMode == ViewMode.intervals;
  bool get isChordInversionMode => viewMode == ViewMode.chordInversions;
  bool get isOpenChordMode => viewMode == ViewMode.openChords;
  bool get isBarreChordMode => viewMode == ViewMode.barreChords;
  bool get isAdvancedChordMode => viewMode == ViewMode.advancedChords;
  
  // Legacy support - maps to chord inversion mode
  bool get isChordMode => isChordInversionMode;
  
  // General chord mode check for any chord-related mode
  bool get isAnyChordMode => isChordInversionMode || isOpenChordMode || isBarreChordMode || isAdvancedChordMode;

  int get octaveSpan => selectedOctaves.isEmpty
      ? 1 
      : selectedOctaves.length;

  int get maxSelectedOctave => selectedOctaves.isEmpty
      ? 3
      : selectedOctaves.reduce((a, b) => a > b ? a : b);
  int get minSelectedOctave => selectedOctaves.isEmpty
      ? 3
      : selectedOctaves.reduce((a, b) => a < b ? a : b);

  int get selectedChordOctave {
    if (!isAnyChordMode || selectedOctaves.isEmpty) return 3;
    return selectedOctaves.first;
  }

  int get visibleFretCount => visibleFretEnd - visibleFretStart;

  // Get effective root considering mode
  String get effectiveRoot =>
      isScaleMode ? MusicController.getModeRoot(root, scale, modeIndex) : root;

  // Get display root (always the base root for chords)
  String get displayRoot => root;

  // Get available modes for current scale
  List<String> get availableModes => MusicController.getAvailableModes(scale);

  // Get current mode name
  String get currentModeName => availableModes.isNotEmpty
      ? availableModes[modeIndex % availableModes.length]
      : 'Mode ${modeIndex + 1}';

  // Get current chord name with inversion notation
  String get currentChordName => MusicController.getChordDisplayName(
        root,
        chordType,
        chordInversion,
      );

  // Get highlight map for current configuration
  Map<int, Color> get highlightMap => FretboardController.getHighlightMap(this);

  FretboardConfig copyWith({
    int? stringCount,
    int? fretCount,
    List<String>? tuning,
    FretboardLayout? layout,
    String? root,
    ViewMode? viewMode,
    String? scale,
    int? modeIndex,
    String? chordType,
    ChordInversion? chordInversion,
    bool? showScaleStrip,
    bool? showFretboard,
    bool? showChordName,
    bool? showNoteNames,
    bool? showAdditionalOctaves, // NEW: Add to copyWith method
    bool? showAllPositions, // NEW: Add to copyWith method
    Set<int>? selectedOctaves,
    Set<int>? selectedIntervals,
    double? width,
    double? height,
    EdgeInsets? padding,
    int? visibleFretStart,
    int? visibleFretEnd,
  }) {
    return FretboardConfig(
      stringCount: stringCount ?? this.stringCount,
      fretCount: fretCount ?? this.fretCount,
      tuning: tuning ?? this.tuning,
      layout: layout ?? this.layout,
      root: root ?? this.root,
      viewMode: viewMode ?? this.viewMode,
      scale: scale ?? this.scale,
      modeIndex: modeIndex ?? this.modeIndex,
      chordType: chordType ?? this.chordType,
      chordInversion: chordInversion ?? this.chordInversion,
      showScaleStrip: showScaleStrip ?? this.showScaleStrip,
      showFretboard: showFretboard ?? this.showFretboard,
      showChordName: showChordName ?? this.showChordName,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      showAdditionalOctaves: showAdditionalOctaves ?? this.showAdditionalOctaves, // NEW
      showAllPositions: showAllPositions ?? this.showAllPositions, // NEW
      selectedOctaves: selectedOctaves ?? this.selectedOctaves,
      selectedIntervals: selectedIntervals ?? this.selectedIntervals,
      width: width ?? this.width,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      visibleFretStart: visibleFretStart ?? this.visibleFretStart,
      visibleFretEnd: visibleFretEnd ?? this.visibleFretEnd,
    );
  }
}

/// Layout options for fretboard display
enum FretboardLayout {
  rightHandedBassTop('RH · Bass Top'),
  rightHandedBassBottom('RH · Bass Bottom'),
  leftHandedBassTop('LH · Bass Top'),
  leftHandedBassBottom('LH · Bass Bottom');

  const FretboardLayout(this.displayName);
  final String displayName;

  bool get isLeftHanded =>
      this == leftHandedBassTop || this == leftHandedBassBottom;
  bool get isBassTop => this == rightHandedBassTop || this == leftHandedBassTop;
}

/// View modes for the fretboard
enum ViewMode {
  intervals('Intervals'),
  scales('Scales'), 
  chordInversions('Chord Inversions'),
  openChords('Open Chords'),
  barreChords('Barre Chords'),
  advancedChords('Advanced Chords');

  const ViewMode(this.displayName);
  final String displayName;
  
  // Helper methods for mode categories
  bool get isChordMode => this == chordInversions || this == openChords || this == barreChords || this == advancedChords;
  bool get isImplemented => this == intervals || this == scales || this == chordInversions || this == openChords;
}