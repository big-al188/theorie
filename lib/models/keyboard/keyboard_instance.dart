// lib/models/keyboard/keyboard_instance.dart
import 'package:flutter/material.dart';
import 'keyboard_config.dart';
import '../music/chord.dart';
import '../fretboard/fretboard_config.dart'; // Import for ViewMode

/// Individual keyboard instance for multi-keyboard views
/// Following the same pattern as FretboardInstance for consistency
class KeyboardInstance {
  final String id;
  final String root;
  final ViewMode viewMode;
  final String scale;
  final int modeIndex;
  final String chordType;
  final ChordInversion chordInversion;
  final Set<int> selectedOctaves;
  final Set<int> selectedIntervals;
  final int keyCount;
  final String startNote;
  final String keyboardType;
  bool isCompact;
  bool showScaleStrip;
  bool showNoteNames;
  bool showAdditionalOctaves; // Show chord notes in additional octaves
  bool showOctave; // Show octave note in scale modes

  KeyboardInstance({
    required this.id,
    required this.root,
    required this.viewMode,
    required this.scale,
    required this.modeIndex,
    required this.chordType,
    required this.chordInversion,
    required this.selectedOctaves,
    required this.selectedIntervals,
    required this.keyCount,
    required this.startNote,
    required this.keyboardType,
    this.isCompact = false,
    this.showScaleStrip = true,
    this.showNoteNames = false,
    this.showAdditionalOctaves = false,
    this.showOctave = false,
  });

  /// Create a default instance
  factory KeyboardInstance.defaults(String id) {
    return KeyboardInstance(
      id: id,
      root: 'C',
      viewMode: ViewMode.intervals,
      scale: 'Major',
      modeIndex: 0,
      chordType: 'major',
      chordInversion: ChordInversion.root,
      selectedOctaves: {3},
      selectedIntervals: {0},
      keyCount: 61, // Default to standard keyboard
      startNote: 'C2', // Default start note for 61-key keyboard
      keyboardType: 'Keyboard',
      showScaleStrip: true,
      showNoteNames: false,
      showAdditionalOctaves: false,
      showOctave: false,
    );
  }

  /// Convert to KeyboardConfig
  KeyboardConfig toConfig() {
    // Always respect the user's selected octaves for the config
    Set<int> octavesToUse = Set.from(selectedOctaves);

    if (octavesToUse.isEmpty) {
      debugPrint(
          'WARNING: KeyboardInstance.toConfig: empty selectedOctaves, defaulting to {3}');
      octavesToUse = {3};
    }

    debugPrint(
        'KeyboardInstance.toConfig: using user-selected octaves for config: $octavesToUse');

    return KeyboardConfig(
      root: root,
      viewMode: viewMode,
      scale: scale,
      modeIndex: modeIndex,
      chordType: chordType,
      chordInversion: chordInversion,
      selectedOctaves: octavesToUse,
      selectedIntervals: selectedIntervals,
      keyCount: keyCount,
      startNote: startNote,
      keyboardType: keyboardType,
      showScaleStrip: showScaleStrip,
      showKeyboard: true,
      showChordName: false,
      showNoteNames: showNoteNames,
      showAdditionalOctaves: showAdditionalOctaves,
      showOctave: showOctave,
      width: 800.0, // Default keyboard width
      height: 200.0, // Default keyboard height
      padding: EdgeInsets.zero,
    );
  }

  KeyboardInstance copyWith({
    String? root,
    ViewMode? viewMode,
    String? scale,
    int? modeIndex,
    String? chordType,
    ChordInversion? chordInversion,
    Set<int>? selectedOctaves,
    Set<int>? selectedIntervals,
    int? keyCount,
    String? startNote,
    String? keyboardType,
    bool? isCompact,
    bool? showScaleStrip,
    bool? showNoteNames,
    bool? showAdditionalOctaves,
    bool? showOctave,
  }) {
    return KeyboardInstance(
      id: id,
      root: root ?? this.root,
      viewMode: viewMode ?? this.viewMode,
      scale: scale ?? this.scale,
      modeIndex: modeIndex ?? this.modeIndex,
      chordType: chordType ?? this.chordType,
      chordInversion: chordInversion ?? this.chordInversion,
      selectedOctaves: selectedOctaves ?? this.selectedOctaves,
      selectedIntervals: selectedIntervals ?? this.selectedIntervals,
      keyCount: keyCount ?? this.keyCount,
      startNote: startNote ?? this.startNote,
      keyboardType: keyboardType ?? this.keyboardType,
      isCompact: isCompact ?? this.isCompact,
      showScaleStrip: showScaleStrip ?? this.showScaleStrip,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      showAdditionalOctaves:
          showAdditionalOctaves ?? this.showAdditionalOctaves,
      showOctave: showOctave ?? this.showOctave,
    );
  }
}