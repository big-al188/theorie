// lib/models/keyboard/keyboard_config.dart
import 'package:flutter/material.dart';
import '../music/chord.dart';
import '../fretboard/fretboard_config.dart'; // For ViewMode
import '../../controllers/music_controller.dart';

/// Configuration for keyboard display and behavior
/// Following the same pattern as FretboardConfig for consistency
class KeyboardConfig {
  final int keyCount;
  final String startNote;
  final String keyboardType;
  final String root;
  final ViewMode viewMode;
  final String scale;
  final int modeIndex;
  final String chordType;
  final ChordInversion chordInversion;
  final bool showScaleStrip;
  final bool showKeyboard;
  final bool showChordName;
  final bool showNoteNames;
  final bool showAdditionalOctaves; // Show chord notes in additional octaves
  final bool showOctave; // Show octave note in scale modes
  final Set<int> selectedOctaves;
  final Set<int> selectedIntervals;
  final double width;
  final double height;
  final EdgeInsets padding;

  const KeyboardConfig({
    required this.keyCount,
    required this.startNote,
    required this.keyboardType,
    required this.root,
    required this.viewMode,
    required this.scale,
    required this.modeIndex,
    required this.chordType,
    required this.chordInversion,
    required this.showScaleStrip,
    required this.showKeyboard,
    required this.showChordName,
    required this.showNoteNames,
    required this.showAdditionalOctaves,
    required this.showOctave,
    required this.selectedOctaves,
    required this.selectedIntervals,
    required this.width,
    required this.height,
    required this.padding,
  });

  // Derived properties following FretboardConfig pattern
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
  // Note: This will be calculated by KeyboardController.getHighlightMap(this) when needed

  KeyboardConfig copyWith({
    int? keyCount,
    String? startNote,
    String? keyboardType,
    String? root,
    ViewMode? viewMode,
    String? scale,
    int? modeIndex,
    String? chordType,
    ChordInversion? chordInversion,
    bool? showScaleStrip,
    bool? showKeyboard,
    bool? showChordName,
    bool? showNoteNames,
    bool? showAdditionalOctaves,
    bool? showOctave,
    Set<int>? selectedOctaves,
    Set<int>? selectedIntervals,
    double? width,
    double? height,
    EdgeInsets? padding,
  }) {
    return KeyboardConfig(
      keyCount: keyCount ?? this.keyCount,
      startNote: startNote ?? this.startNote,
      keyboardType: keyboardType ?? this.keyboardType,
      root: root ?? this.root,
      viewMode: viewMode ?? this.viewMode,
      scale: scale ?? this.scale,
      modeIndex: modeIndex ?? this.modeIndex,
      chordType: chordType ?? this.chordType,
      chordInversion: chordInversion ?? this.chordInversion,
      showScaleStrip: showScaleStrip ?? this.showScaleStrip,
      showKeyboard: showKeyboard ?? this.showKeyboard,
      showChordName: showChordName ?? this.showChordName,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      showAdditionalOctaves: showAdditionalOctaves ?? this.showAdditionalOctaves,
      showOctave: showOctave ?? this.showOctave,
      selectedOctaves: selectedOctaves ?? this.selectedOctaves,
      selectedIntervals: selectedIntervals ?? this.selectedIntervals,
      width: width ?? this.width,
      height: height ?? this.height,
      padding: padding ?? this.padding,
    );
  }
}

/// Enum for view modes - reusing the same ViewMode from FretboardConfig
/// This ensures consistency across fretboard and keyboard systems