// lib/utils/color_utils.dart
import 'package:flutter/material.dart';

/// Utility functions for color generation in music visualization
class ColorUtils {
  // Base color palette for pitch classes (0-11)
  static const List<HSLColor> _basePalette = [
    HSLColor.fromAHSL(1, 114, .50, 1), // 0  (R) - Green
    HSLColor.fromAHSL(1, 55, .50, 1), // ♭2 - Yellow-Green
    HSLColor.fromAHSL(1, 150, .50, 1), // 2 - Cyan
    HSLColor.fromAHSL(1, 34, .50, 1), // ♭3 - Orange
    HSLColor.fromAHSL(1, 174, .50, 1), // 3 - Teal
    HSLColor.fromAHSL(1, 185, .50, 1), // 4 - Light Blue
    HSLColor.fromAHSL(1, 18, .50, 1), // ♭5 - Red-Orange
    HSLColor.fromAHSL(1, 210, .50, 1), // 5 - Blue
    HSLColor.fromAHSL(1, 6, .50, 1), // ♭6 - Red
    HSLColor.fromAHSL(1, 224, .50, 1), // 6 - Blue-Purple
    HSLColor.fromAHSL(1, 318, .50, 1), // ♭7 - Magenta
    HSLColor.fromAHSL(1, 241, .50, 1), // 7 - Purple
  ];

  // Scale degree colors for major context
  static const List<HSLColor> _majorScalePalette = [
    HSLColor.fromAHSL(1, 120, 0.8, 0.5), // I - Green (tonic)
    HSLColor.fromAHSL(1, 60, 0.6, 0.6), // ii - Light yellow
    HSLColor.fromAHSL(1, 30, 0.6, 0.6), // iii - Light orange
    HSLColor.fromAHSL(1, 240, 0.8, 0.5), // IV - Blue (subdominant)
    HSLColor.fromAHSL(1, 0, 0.8, 0.5), // V - Red (dominant)
    HSLColor.fromAHSL(1, 300, 0.6, 0.6), // vi - Light purple
    HSLColor.fromAHSL(1, 180, 0.4, 0.7), // vii° - Very light cyan
  ];

  // Scale degree colors for minor context
  static const List<HSLColor> _minorScalePalette = [
    HSLColor.fromAHSL(1, 120, 0.8, 0.4), // i - Dark green (tonic)
    HSLColor.fromAHSL(1, 180, 0.4, 0.7), // ii° - Light cyan
    HSLColor.fromAHSL(1, 30, 0.8, 0.5), // III - Orange
    HSLColor.fromAHSL(1, 240, 0.8, 0.4), // iv - Dark blue (subdominant)
    HSLColor.fromAHSL(1, 0, 0.8, 0.4), // v - Dark red (dominant)
    HSLColor.fromAHSL(1, 60, 0.8, 0.5), // VI - Yellow
    HSLColor.fromAHSL(1, 300, 0.8, 0.5), // VII - Purple
  ];

  /// Get color for musical degree with octave awareness
  static Color colorForDegree(int degree) {
    // Extended saturation, lightness, and alpha arrays for octaves 0-8
    const sats = [0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55];
    const lights = [0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80];
    const alphas = [1.00, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60];

    final oct = (degree ~/ 12).clamp(0, sats.length - 1);
    final base = _basePalette[degree % 12];

    return HSLColor.fromAHSL(
      alphas[oct],
      base.hue,
      base.saturation * sats[oct],
      lights[oct],
    ).toColor();
  }

  /// Get monochromatic color for chord based on octave
  static Color colorForChordInOctave(int octave,
      {bool isRoot = false, bool isBass = false}) {
    // Define base colors for each octave (0-8)
    const baseColors = [
      HSLColor.fromAHSL(1, 0, 0.8, 0.5), // Octave 0 - Red
      HSLColor.fromAHSL(1, 30, 0.8, 0.5), // Octave 1 - Orange
      HSLColor.fromAHSL(1, 60, 0.8, 0.5), // Octave 2 - Yellow
      HSLColor.fromAHSL(1, 120, 0.8, 0.5), // Octave 3 - Green
      HSLColor.fromAHSL(1, 240, 0.8, 0.5), // Octave 4 - Blue
      HSLColor.fromAHSL(1, 280, 0.8, 0.5), // Octave 5 - Purple
      HSLColor.fromAHSL(1, 320, 0.8, 0.5), // Octave 6 - Pink
      HSLColor.fromAHSL(1, 180, 0.9, 0.4), // Octave 7 - Teal
      HSLColor.fromAHSL(1, 45, 0.9, 0.3), // Octave 8 - Bronze
    ];

    final octaveIndex = octave.clamp(0, baseColors.length - 1);
    var baseColor = baseColors[octaveIndex];

    // Adjust for special chord tones
    if (isRoot) {
      baseColor = baseColor.withSaturation(1.0).withLightness(0.4);
    } else if (isBass) {
      baseColor = baseColor.withLightness(0.3);
    }

    return baseColor.toColor();
  }

  /// Get color for scale degree with Roman numeral analysis
  static Color colorForScaleDegree(int degree, {bool isMajor = true}) {
    final basePalette = isMajor ? _majorScalePalette : _minorScalePalette;
    final index = degree % basePalette.length;
    return basePalette[index].toColor();
  }

  /// Lighten/darken color for octave
  static Color adjustColorForOctave(Color baseColor, int octave) {
    final hsl = HSLColor.fromColor(baseColor);
    final lightnessFactor = 1.0 - (octave * 0.1);
    final alphaFactor = 1.0 - (octave * 0.05);

    return hsl
        .withLightness((hsl.lightness * lightnessFactor).clamp(0.0, 1.0))
        .withAlpha((hsl.alpha * alphaFactor).clamp(0.0, 1.0))
        .toColor();
  }

  /// Get contrasting text color
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Get theme-aware color
  static Color getThemeAwareColor(
      Color lightColor, Color darkColor, bool isDarkMode) {
    return isDarkMode ? darkColor : lightColor;
  }

  /// Generate gradient for scale visualization
  static LinearGradient scaleGradient(int scaleLength, {bool isMajor = true}) {
    final colors = List.generate(
        scaleLength, (i) => colorForScaleDegree(i, isMajor: isMajor));

    return LinearGradient(
      colors: colors,
      stops: List.generate(scaleLength, (i) => i / (scaleLength - 1)),
    );
  }

  /// Get fretboard position heat color
  static Color heatmapColor(double intensity) {
    // Intensity should be 0.0 to 1.0
    final clampedIntensity = intensity.clamp(0.0, 1.0);

    if (clampedIntensity < 0.5) {
      // Blue to green
      return Color.lerp(
        Colors.blue.shade300,
        Colors.green.shade300,
        clampedIntensity * 2,
      )!;
    } else {
      // Green to red
      return Color.lerp(
        Colors.green.shade300,
        Colors.red.shade300,
        (clampedIntensity - 0.5) * 2,
      )!;
    }
  }

  /// Get interval quality color
  static Color intervalQualityColor(IntervalQuality quality) {
    switch (quality) {
      case IntervalQuality.perfect:
        return Colors.blue.shade600;
      case IntervalQuality.major:
        return Colors.green.shade600;
      case IntervalQuality.minor:
        return Colors.orange.shade600;
      case IntervalQuality.augmented:
        return Colors.purple.shade600;
      case IntervalQuality.diminished:
        return Colors.red.shade600;
    }
  }
}

/// Interval quality enum for color mapping
enum IntervalQuality {
  perfect,
  major,
  minor,
  augmented,
  diminished,
}
