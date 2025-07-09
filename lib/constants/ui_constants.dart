// lib/constants/ui_constants.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// UI-related constants with responsive design support
class UIConstants {
  // Base fretboard dimensions (used for desktop/default)
  static const double baseStringHeight = 32.0;
  static const double baseNoteRowHeight = 90.0;
  static const double headWidthRatio = 0.1;
  static const double baseNutWidth = 12.0;
  static const double baseFretWidth = 2.0;
  static const double baseEdgeWidth = 5.0;

  // Base note marker dimensions
  static const double baseNoteMarkerRadius = 15.0;
  static const double noteMarkerStrokeWidth = 2.0;
  static const double intervalLabelFontSize = 16.0;
  static const double noteLabelFontSize = 11.0;

  // Base scale strip dimensions
  static const double scaleStripLabelSpace = 24.0;
  static const double baseScaleStripPaddingPerOctave = 4.0;
  static const double baseScaleStripNoteRadius = 16.0;

  // Control widget dimensions
  static const double controlSpacing = 8.0;
  static const double controlLabelFontSize = 12.0;
  static const double controlButtonMinWidth = 50.0;
  static const double controlButtonHeight = 30.0;

  // Dialog dimensions
  static const double settingsDialogWidth = 700.0;
  static const double settingsDialogHeight = 650.0;
  static const double dialogPadding = 24.0;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  // Touch target minimum (accessibility)
  static const double minTouchTargetSize = 44.0;

  // Legacy properties that delegate to responsive methods
  static double get stringHeight =>
      ResponsiveConstants.getStringHeight(800.0); // Default desktop
  static double get noteRowHeight =>
      ResponsiveConstants.getNoteRowHeight(800.0);
  static double get nutWidth => baseNutWidth;
  static double get fretWidth => baseFretWidth;
  static double get edgeWidth => baseEdgeWidth;
  static double get noteMarkerRadius =>
      ResponsiveConstants.getNoteMarkerRadius(800.0);
  static double get scaleStripPaddingPerOctave =>
      ResponsiveConstants.getScaleStripPaddingPerOctave(800.0);
  static double get scaleStripNoteRadius =>
      ResponsiveConstants.getScaleStripNoteRadius(800.0);

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

/// Responsive constants that adapt to screen size
class ResponsiveConstants {
  // Get device type for responsive behavior
  static DeviceType getDeviceType(double screenWidth) {
    if (screenWidth < UIConstants.mobileBreakpoint) return DeviceType.mobile;
    if (screenWidth < UIConstants.tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // String heights - reduced for mobile to save vertical space
  static double getStringHeight(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 24.0; // Reduced from 32 for mobile
      case DeviceType.tablet:
        return 28.0; // Moderate reduction for tablet
      case DeviceType.desktop:
        return UIConstants.baseStringHeight; // Full size for desktop
    }
  }

  // Note row heights for scale strip - reduced for mobile
  static double getNoteRowHeight(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 65.0; // Reduced from 90 for mobile
      case DeviceType.tablet:
        return 75.0; // Moderate reduction for tablet
      case DeviceType.desktop:
        return UIConstants.baseNoteRowHeight; // Full size for desktop
    }
  }

  // Spacing between fretboard and scale strip - reduced for mobile
  static double getFretboardScaleStripSpacing(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 12.0; // Reduced from 24 for mobile
      case DeviceType.tablet:
        return 18.0; // Moderate reduction for tablet
      case DeviceType.desktop:
        return 24.0; // Full spacing for desktop
    }
  }

  // Top padding for fret labels - reduced for mobile
  static double getFretLabelPadding(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 12.0; // Reduced from 20 for mobile
      case DeviceType.tablet:
        return 16.0; // Moderate reduction for tablet
      case DeviceType.desktop:
        return 20.0; // Full padding for desktop
    }
  }

  // Scale strip padding per octave - reduced for mobile
  static double getScaleStripPaddingPerOctave(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 2.0; // Reduced from 4 for mobile
      case DeviceType.tablet:
        return 3.0; // Moderate reduction for tablet
      case DeviceType.desktop:
        return UIConstants
            .baseScaleStripPaddingPerOctave; // Full padding for desktop
    }
  }

  // Note marker radius - slightly reduced for mobile
  static double getNoteMarkerRadius(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 12.0; // Reduced from 15 for mobile
      case DeviceType.tablet:
        return 13.5; // Slight reduction for tablet
      case DeviceType.desktop:
        return UIConstants.baseNoteMarkerRadius; // Full size for desktop
    }
  }

  // Scale strip note radius - slightly reduced for mobile
  static double getScaleStripNoteRadius(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 13.0; // Reduced from 16 for mobile
      case DeviceType.tablet:
        return 14.5; // Slight reduction for tablet
      case DeviceType.desktop:
        return UIConstants.baseScaleStripNoteRadius; // Full size for desktop
    }
  }

  // Ensure touch targets meet accessibility guidelines
  static double getEffectiveTouchArea(double visualSize) {
    return math.max(visualSize, UIConstants.minTouchTargetSize);
  }

  // Font size scaling for mobile
  static double getScaledFontSize(double baseFontSize, double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return (baseFontSize * 0.85)
            .clamp(9.0, baseFontSize); // Scale down for mobile
      case DeviceType.tablet:
        return (baseFontSize * 0.92)
            .clamp(10.0, baseFontSize); // Slight scale down for tablet
      case DeviceType.desktop:
        return baseFontSize; // Full size for desktop
    }
  }

  // Clean view padding - more aggressive reduction for mobile
  static double getCleanViewPadding(double screenWidth) {
    switch (getDeviceType(screenWidth)) {
      case DeviceType.mobile:
        return 2.0; // Very tight for mobile clean view
      case DeviceType.tablet:
        return 3.0; // Tight for tablet clean view
      case DeviceType.desktop:
        return 4.0; // Normal for desktop clean view
    }
  }

  // Card padding - reduced for mobile
  static double getCardPadding(double screenWidth, bool isCompact) {
    if (isCompact) {
      switch (getDeviceType(screenWidth)) {
        case DeviceType.mobile:
          return 6.0; // Reduced for mobile compact
        case DeviceType.tablet:
          return 8.0; // Standard compact
        case DeviceType.desktop:
          return 8.0; // Standard compact
      }
    } else {
      switch (getDeviceType(screenWidth)) {
        case DeviceType.mobile:
          return 12.0; // Reduced for mobile
        case DeviceType.tablet:
          return 14.0; // Slightly reduced for tablet
        case DeviceType.desktop:
          return 16.0; // Full padding for desktop
      }
    }
  }
}

/// Device type enumeration for responsive design
enum DeviceType {
  mobile,
  tablet,
  desktop,
}
