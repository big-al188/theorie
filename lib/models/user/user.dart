// lib/models/user/user.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../fretboard/fretboard_config.dart';

/// Represents a user of the application
class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences preferences;
  final UserProgress progress;
  final bool isDefaultUser;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
    required this.progress,
    this.isDefaultUser = false,
  });

  /// Create default test user
  factory User.defaultUser() {
    return User(
      id: 'default-user',
      username: 'Guest User',
      email: 'guest@theorie.app',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: UserPreferences.defaults(),
      progress: UserProgress.empty(),
      isDefaultUser: true,
    );
  }

  /// Create user from registration data
  factory User.fromRegistration({
    required String username,
    required String email,
  }) {
    return User(
      id: const Uuid().v4(),
      username: username,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: UserPreferences.defaults(),
      progress: UserProgress.empty(),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences.toJson(),
      'progress': progress.toJson(),
      'isDefaultUser': isDefaultUser,
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      preferences:
          UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>),
      progress: UserProgress.fromJson(json['progress'] as Map<String, dynamic>),
      isDefaultUser: json['isDefaultUser'] as bool? ?? false,
    );
  }

  /// Create copy with updated fields
  User copyWith({
    String? username,
    String? email,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    UserProgress? progress,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      progress: progress ?? this.progress,
      isDefaultUser: isDefaultUser,
    );
  }

  @override
  String toString() => 'User(id: $id, username: $username, email: $email)';
}

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
}

/// User progress tracking
class UserProgress {
  final Map<String, SectionProgress> sectionProgress;
  final Set<String> completedTopics;
  final Set<String> completedSections;
  final int totalQuizzesTaken;
  final int totalQuizzesPassed;

  const UserProgress({
    required this.sectionProgress,
    required this.completedTopics,
    required this.completedSections,
    required this.totalQuizzesTaken,
    required this.totalQuizzesPassed,
  });

  /// Create empty progress
  factory UserProgress.empty() {
    return const UserProgress(
      sectionProgress: {},
      completedTopics: {},
      completedSections: {},
      totalQuizzesTaken: 0,
      totalQuizzesPassed: 0,
    );
  }

  /// Gets total topics completed across all sections
  int get totalTopicsCompleted {
    return completedTopics.length;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sectionProgress': sectionProgress.map((k, v) => MapEntry(k, v.toJson())),
      'completedTopics': completedTopics.toList(),
      'completedSections': completedSections.toList(),
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalQuizzesPassed': totalQuizzesPassed,
    };
  }

  /// Create from JSON
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final sectionProgressMap =
        json['sectionProgress'] as Map<String, dynamic>? ?? {};
    return UserProgress(
      sectionProgress: sectionProgressMap.map(
        (k, v) =>
            MapEntry(k, SectionProgress.fromJson(v as Map<String, dynamic>)),
      ),
      completedTopics: Set<String>.from(json['completedTopics'] as List? ?? []),
      completedSections:
          Set<String>.from(json['completedSections'] as List? ?? []),
      totalQuizzesTaken: json['totalQuizzesTaken'] as int? ?? 0,
      totalQuizzesPassed: json['totalQuizzesPassed'] as int? ?? 0,
    );
  }

  /// Get progress for a specific section
  SectionProgress getSectionProgress(String sectionId) {
    return sectionProgress[sectionId] ?? SectionProgress.empty();
  }

  /// Check if topic is completed
  bool isTopicCompleted(String topicId) {
    return completedTopics.contains(topicId);
  }

  /// Check if section is completed
  bool isSectionCompleted(String sectionId) {
    return completedSections.contains(sectionId);
  }

  /// Mark topic as completed
  UserProgress completeTopicQuiz(String topicId, bool passed) {
    final newCompletedTopics = Set<String>.from(completedTopics);
    if (passed) {
      newCompletedTopics.add(topicId);
    }

    return UserProgress(
      sectionProgress: sectionProgress,
      completedTopics: newCompletedTopics,
      completedSections: completedSections,
      totalQuizzesTaken: totalQuizzesTaken + 1,
      totalQuizzesPassed: passed ? totalQuizzesPassed + 1 : totalQuizzesPassed,
    );
  }

  /// Mark section as completed
  UserProgress completeSectionQuiz(String sectionId, bool passed) {
    final newCompletedSections = Set<String>.from(completedSections);
    if (passed) {
      newCompletedSections.add(sectionId);
    }

    return UserProgress(
      sectionProgress: sectionProgress,
      completedTopics: completedTopics,
      completedSections: newCompletedSections,
      totalQuizzesTaken: totalQuizzesTaken + 1,
      totalQuizzesPassed: passed ? totalQuizzesPassed + 1 : totalQuizzesPassed,
    );
  }
}

/// Progress for individual sections
class SectionProgress {
  final int topicsCompleted;
  final int totalTopics;
  final bool sectionQuizCompleted;
  final DateTime? lastAccessed;

  const SectionProgress({
    required this.topicsCompleted,
    required this.totalTopics,
    required this.sectionQuizCompleted,
    this.lastAccessed,
  });

  factory SectionProgress.empty() {
    return const SectionProgress(
      topicsCompleted: 0,
      totalTopics: 0,
      sectionQuizCompleted: false,
    );
  }

  double get progressPercentage =>
      totalTopics > 0 ? topicsCompleted / totalTopics : 0.0;

  bool get isCompleted =>
      topicsCompleted == totalTopics && sectionQuizCompleted;

  Map<String, dynamic> toJson() {
    return {
      'topicsCompleted': topicsCompleted,
      'totalTopics': totalTopics,
      'sectionQuizCompleted': sectionQuizCompleted,
      'lastAccessed': lastAccessed?.toIso8601String(),
    };
  }

  factory SectionProgress.fromJson(Map<String, dynamic> json) {
    return SectionProgress(
      topicsCompleted: json['topicsCompleted'] as int,
      totalTopics: json['totalTopics'] as int,
      sectionQuizCompleted: json['sectionQuizCompleted'] as bool,
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'] as String)
          : null,
    );
  }
}
