// lib/models/fretboard/fretboard_config.dart - Fixed octave calculation
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../music/chord.dart';
import '../music/note.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/fretboard_controller.dart';

/// Configuration for a fretboard display
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
  final Set<int> selectedOctaves;
  final Set<int> selectedIntervals;
  final double? width;
  final double? height;
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
    this.showScaleStrip = false,
    this.showFretboard = true,
    this.showChordName = false,
    this.showNoteNames = false,
    this.selectedOctaves = const {3},
    this.selectedIntervals = const {0},
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.visibleFretStart = 0,
    int? visibleFretEnd,
  }) : visibleFretEnd = visibleFretEnd ?? fretCount;

  /// Create default configuration
  factory FretboardConfig.defaults() {
    return FretboardConfig(
      stringCount: AppConstants.defaultStringCount,
      fretCount: AppConstants.defaultFretCount,
      tuning: const ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      layout: FretboardLayout.rightHandedBassTop,
      root: AppConstants.defaultRoot,
      viewMode: ViewMode.intervals,
      scale: AppConstants.defaultScale,
      modeIndex: 0,
      chordType: 'major',
      chordInversion: ChordInversion.root,
    );
  }

  // Derived properties
  bool get isLeftHanded => layout.isLeftHanded;
  bool get isBassTop => layout.isBassTop;
  bool get isScaleMode => viewMode == ViewMode.scales;
  bool get isIntervalMode => viewMode == ViewMode.intervals;
  bool get isChordMode => viewMode == ViewMode.chords;

  // FIXED: Octave count calculation now respects user's selection
  int get octaveCount {
    // Always return the actual count of selected octaves
    // Don't override based on chord voicing calculations
    return selectedOctaves.isEmpty ? 1 : selectedOctaves.length;
  }

  int get maxSelectedOctave => selectedOctaves.isEmpty
      ? 3
      : selectedOctaves.reduce((a, b) => a > b ? a : b);
  int get minSelectedOctave => selectedOctaves.isEmpty
      ? 3
      : selectedOctaves.reduce((a, b) => a < b ? a : b);

  int get selectedChordOctave {
    if (!isChordMode || selectedOctaves.isEmpty) return 3;
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
  chords('Chords');

  const ViewMode(this.displayName);
  final String displayName;
}
