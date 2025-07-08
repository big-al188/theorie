// lib/constants/ui_constants.dart
import 'package:flutter/material.dart';

/// UI-related constants
class UIConstants {
  // Fretboard dimensions
  static const double stringHeight = 32.0;
  static const double noteRowHeight = 90.0;
  static const double headWidthRatio = 0.1;
  static const double nutWidth = 12.0;
  static const double fretWidth = 2.0;
  static const double edgeWidth = 5.0;

  // Note marker dimensions
  static const double noteMarkerRadius = 15.0;
  static const double noteMarkerStrokeWidth = 2.0;
  static const double intervalLabelFontSize = 16.0;
  static const double noteLabelFontSize = 11.0;

  // Scale strip dimensions
  static const double scaleStripLabelSpace = 24.0;
  static const double scaleStripPaddingPerOctave = 4.0;
  static const double scaleStripNoteRadius = 16.0;

  // Control widget dimensions
  static const double controlSpacing = 8.0;
  static const double controlLabelFontSize = 12.0;
  static const double controlButtonMinWidth = 50.0;
  static const double controlButtonHeight = 30.0;

  // Dialog dimensions
  static const double settingsDialogWidth = 700.0;
  static const double settingsDialogHeight = 650.0;
  static const double dialogPadding = 24.0;

  // String colors for visual distinction
  static const List<Color> stringColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
    Colors.lime,
    Colors.amber,
  ];

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle smallLabelStyle = TextStyle(
    fontSize: 10,
    color: Colors.grey,
  );

  // Color schemes
  static const Map<String, Map<String, Color>> colorSchemes = {
    'default': {
      'background': Colors.white,
      'fretboard': Color(0xFFF5F5DC), // Beige
      'strings': Colors.grey,
      'frets': Colors.black,
      'nut': Colors.black,
      'markers': Colors.grey,
    },
    'dark': {
      'background': Color(0xFF121212),
      'fretboard': Color(0xFF2D2D2D),
      'strings': Color(0xFF666666),
      'frets': Color(0xFF888888),
      'nut': Color(0xFFCCCCCC),
      'markers': Color(0xFF555555),
    },
    'vintage': {
      'background': Color(0xFFFDF7),
      'fretboard': Color(0xFFD2B48C), // Tan
      'strings': Color(0xFF8B4513), // Saddle brown
      'frets': Color(0xFF654321),
      'nut': Color(0xFF2F1B14),
      'markers': Color(0xFFCD853F),
    },
  };
}
