// lib/models/user/user_preferences.dart
import 'package:flutter/material.dart';
import '../fretboard/fretboard_config.dart';

/// User preferences for app settings
class UserPreferences {
  final ThemeMode themeMode;
  final FretboardLayout defaultLayout;
  final int defaultStringCount;
  final int defaultFretCount;
  final List<String> defaultTuning;
  final String defaultRoot;
  final ViewMode defaultViewMode;
  final String defaultScale;
  final Set<int> defaultSelectedOctaves;

  const UserPreferences({
    required this.themeMode,
    required this.defaultLayout,
    required this.defaultStringCount,
    required this.defaultFretCount,
    required this.defaultTuning,
    required this.defaultRoot,
    required this.defaultViewMode,
    required this.defaultScale,
    required this.defaultSelectedOctaves,
  });

  /// Create default preferences
  factory UserPreferences.defaults() {
    return const UserPreferences(
      themeMode: ThemeMode.light,
      defaultLayout: FretboardLayout.rightHandedBassBottom,
      defaultStringCount: 6,
      defaultFretCount: 12,
      defaultTuning: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      defaultRoot: 'C',
      defaultViewMode: ViewMode.intervals,
      defaultScale: 'Major',
      defaultSelectedOctaves: {3},
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'defaultLayout': defaultLayout.index,
      'defaultStringCount': defaultStringCount,
      'defaultFretCount': defaultFretCount,
      'defaultTuning': defaultTuning,
      'defaultRoot': defaultRoot,
      'defaultViewMode': defaultViewMode.index,
      'defaultScale': defaultScale,
      'defaultSelectedOctaves': defaultSelectedOctaves.toList(),
    };
  }

  /// Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      themeMode: ThemeMode.values[json['themeMode'] as int],
      defaultLayout: FretboardLayout.values[json['defaultLayout'] as int],
      defaultStringCount: json['defaultStringCount'] as int,
      defaultFretCount: json['defaultFretCount'] as int,
      defaultTuning: List<String>.from(json['defaultTuning'] as List),
      defaultRoot: json['defaultRoot'] as String,
      defaultViewMode: ViewMode.values[json['defaultViewMode'] as int],
      defaultScale: json['defaultScale'] as String,
      defaultSelectedOctaves:
          Set<int>.from(json['defaultSelectedOctaves'] as List),
    );
  }

  UserPreferences copyWith({
    ThemeMode? themeMode,
    FretboardLayout? defaultLayout,
    int? defaultStringCount,
    int? defaultFretCount,
    List<String>? defaultTuning,
    String? defaultRoot,
    ViewMode? defaultViewMode,
    String? defaultScale,
    Set<int>? defaultSelectedOctaves,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      defaultLayout: defaultLayout ?? this.defaultLayout,
      defaultStringCount: defaultStringCount ?? this.defaultStringCount,
      defaultFretCount: defaultFretCount ?? this.defaultFretCount,
      defaultTuning: defaultTuning ?? this.defaultTuning,
      defaultRoot: defaultRoot ?? this.defaultRoot,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      defaultScale: defaultScale ?? this.defaultScale,
      defaultSelectedOctaves:
          defaultSelectedOctaves ?? this.defaultSelectedOctaves,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(theme: $themeMode, layout: $defaultLayout)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences &&
        other.themeMode == themeMode &&
        other.defaultLayout == defaultLayout &&
        other.defaultStringCount == defaultStringCount &&
        other.defaultFretCount == defaultFretCount &&
        other.defaultRoot == defaultRoot &&
        other.defaultViewMode == defaultViewMode &&
        other.defaultScale == defaultScale;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        defaultLayout,
        defaultStringCount,
        defaultFretCount,
        defaultRoot,
        defaultViewMode,
        defaultScale,
      );
}
