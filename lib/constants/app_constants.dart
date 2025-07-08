// lib/constants/app_constants.dart
import 'package:flutter/material.dart';

/// General application constants
class AppConstants {
  // Fretboard limits
  static const int minStrings = 1;
  static const int maxStrings = 10;
  static const int minFrets = 1;
  static const int maxFrets = 24;

  // Octave limits (0-8 range = 9 total octaves)
  static const int minOctaves = 1;
  static const int maxOctaves = 8;
  static const int defaultOctave = 3;

  // Zoom limits
  static const double minZoom = 0.3;
  static const double maxZoom = 3.0;
  static const double defaultZoom = 1.0;

  // Default values
  static const int defaultStringCount = 6;
  static const int defaultFretCount = 12;
  static const String defaultRoot = 'C';
  static const String defaultScale = 'Major';

  // Chord voicing settings
  static const int maxChordInversions = 6;
  static const bool enforceChordVoicings = true;
  static const int defaultChordOctave = 3;

  // Performance settings
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration debounceDelay = Duration(milliseconds: 300);

  // Layout settings
  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const double defaultSpacing = 16.0;
  static const BorderRadius defaultBorderRadius =
      BorderRadius.all(Radius.circular(8));
}
