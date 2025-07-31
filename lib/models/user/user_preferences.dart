// lib/models/user/user_preferences.dart - Integrated with audio system
import 'package:flutter/material.dart';
import '../fretboard/fretboard_config.dart';
import '../../controllers/audio_controller.dart'; // NEW: Import for AudioBackend

/// Comprehensive user preferences for app settings, theme, and fretboard defaults
/// Enhanced with new audio system integration while preserving all existing functionality
class UserPreferences {
  // Theme and UI preferences
  final ThemeMode themeMode;
  final bool showAnimations;
  final bool showHints;
  final bool showTooltips;
  final bool playSounds; // EXISTING: General sound preference
  final double soundVolume; // EXISTING: General sound volume
  final bool showNotifications;
  final bool autoSaveProgress;

  // NEW: Enhanced audio system preferences (in addition to existing playSounds/soundVolume)
  final AudioBackend audioBackend;
  final Duration melodyNoteDuration;
  final Duration melodyGapDuration; 
  final Duration harmonyDuration;
  final int defaultVelocity;
  final bool audioEnabled; // NEW: Specific to the new audio system

  // Fretboard display preferences
  final FretboardLayout defaultLayout;
  final int defaultStringCount;
  final int defaultFretCount;
  final List<String> defaultTuning;
  final bool showFretNumbers;
  final bool showStringLabels;
  final bool showNoteNames;
  final bool showIntervals;
  final bool showScaleDegrees;
  final bool highlightRootNotes;
  final bool highlightSelectedNotes;
  final double fretboardScale;
  final bool showEmptyStrings;

  // Music theory preferences
  final String defaultRoot;
  final ViewMode defaultViewMode;
  final String defaultScale;
  final Set<int> defaultSelectedOctaves;
  final bool useFlatsForSharps;
  final bool showEnharmonicEquivalents;
  final bool showModeNames;
  final bool showChordSymbols;
  final bool showIntervalNames;

  // Quiz preferences
  final bool showQuizHints;
  final bool showQuizExplanations;
  final bool allowQuizSkipping;
  final int defaultQuizTimeLimit; // in minutes, 0 for no limit
  final bool showQuizTimer;
  final bool showQuizProgress;
  final bool playQuizSounds;
  final bool showQuizFeedback;
  final bool randomizeQuizOrder;
  final bool showQuizResults;

  // Learning preferences
  final bool showLearningProgress;
  final bool showTopicOverview;
  final bool showSectionSummary;
  final bool autoAdvanceTopics;
  final bool showDifficultyLevel;
  final bool showEstimatedTime;
  final bool showPrerequisites;
  final bool showRelatedTopics;

  // Accessibility preferences
  final bool useHighContrast;
  final bool useLargeText;
  final bool showColorBlindFriendly;
  final bool useReducedMotion;
  final bool showScreenReaderLabels;
  final bool useHapticFeedback;

  // Performance preferences
  final bool enableCaching;
  final bool preloadContent;
  final bool optimizeForSlowConnections;
  final bool enableOfflineMode;

  const UserPreferences({
    // Theme and UI
    this.themeMode = ThemeMode.system,
    this.showAnimations = true,
    this.showHints = true,
    this.showTooltips = true,
    this.playSounds = true,
    this.soundVolume = 0.5,
    this.showNotifications = true,
    this.autoSaveProgress = true,

    // NEW: Enhanced audio system preferences with sensible defaults
    this.audioBackend = AudioBackend.midi,
    this.melodyNoteDuration = const Duration(milliseconds: 500),
    this.melodyGapDuration = const Duration(milliseconds: 50),
    this.harmonyDuration = const Duration(milliseconds: 2000),
    this.defaultVelocity = 100,
    this.audioEnabled = true,

    // Fretboard display
    this.defaultLayout = FretboardLayout.rightHandedBassBottom,
    this.defaultStringCount = 6,
    this.defaultFretCount = 12,
    this.defaultTuning = const ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
    this.showFretNumbers = true,
    this.showStringLabels = true,
    this.showNoteNames = true,
    this.showIntervals = true,
    this.showScaleDegrees = true,
    this.highlightRootNotes = true,
    this.highlightSelectedNotes = true,
    this.fretboardScale = 1.0,
    this.showEmptyStrings = true,

    // Music theory
    this.defaultRoot = 'C',
    this.defaultViewMode = ViewMode.intervals,
    this.defaultScale = 'Major',
    this.defaultSelectedOctaves = const {3},
    this.useFlatsForSharps = false,
    this.showEnharmonicEquivalents = true,
    this.showModeNames = true,
    this.showChordSymbols = true,
    this.showIntervalNames = true,

    // Quiz
    this.showQuizHints = true,
    this.showQuizExplanations = true,
    this.allowQuizSkipping = false,
    this.defaultQuizTimeLimit = 0,
    this.showQuizTimer = true,
    this.showQuizProgress = true,
    this.playQuizSounds = true,
    this.showQuizFeedback = true,
    this.randomizeQuizOrder = false,
    this.showQuizResults = true,

    // Learning
    this.showLearningProgress = true,
    this.showTopicOverview = true,
    this.showSectionSummary = true,
    this.autoAdvanceTopics = false,
    this.showDifficultyLevel = true,
    this.showEstimatedTime = true,
    this.showPrerequisites = true,
    this.showRelatedTopics = true,

    // Accessibility
    this.useHighContrast = false,
    this.useLargeText = false,
    this.showColorBlindFriendly = false,
    this.useReducedMotion = false,
    this.showScreenReaderLabels = false,
    this.useHapticFeedback = true,

    // Performance
    this.enableCaching = true,
    this.preloadContent = true,
    this.optimizeForSlowConnections = false,
    this.enableOfflineMode = true,
  });

  /// Create default preferences
  factory UserPreferences.defaults() {
    return const UserPreferences();
  }

  /// Convert to JSON for persistence - ENHANCED with new audio fields
  Map<String, dynamic> toJson() {
    return {
      // Theme and UI
      'themeMode': themeMode.index,
      'showAnimations': showAnimations,
      'showHints': showHints,
      'showTooltips': showTooltips,
      'playSounds': playSounds,
      'soundVolume': soundVolume,
      'showNotifications': showNotifications,
      'autoSaveProgress': autoSaveProgress,

      // NEW: Enhanced audio system preferences
      'audioBackend': audioBackend.index,
      'melodyNoteDurationMs': melodyNoteDuration.inMilliseconds,
      'melodyGapDurationMs': melodyGapDuration.inMilliseconds,
      'harmonyDurationMs': harmonyDuration.inMilliseconds,
      'defaultVelocity': defaultVelocity,
      'audioEnabled': audioEnabled,

      // Fretboard display
      'defaultLayout': defaultLayout.index,
      'defaultStringCount': defaultStringCount,
      'defaultFretCount': defaultFretCount,
      'defaultTuning': defaultTuning,
      'showFretNumbers': showFretNumbers,
      'showStringLabels': showStringLabels,
      'showNoteNames': showNoteNames,
      'showIntervals': showIntervals,
      'showScaleDegrees': showScaleDegrees,
      'highlightRootNotes': highlightRootNotes,
      'highlightSelectedNotes': highlightSelectedNotes,
      'fretboardScale': fretboardScale,
      'showEmptyStrings': showEmptyStrings,

      // Music theory
      'defaultRoot': defaultRoot,
      'defaultViewMode': defaultViewMode.index,
      'defaultScale': defaultScale,
      'defaultSelectedOctaves': defaultSelectedOctaves.toList(),
      'useFlatsForSharps': useFlatsForSharps,
      'showEnharmonicEquivalents': showEnharmonicEquivalents,
      'showModeNames': showModeNames,
      'showChordSymbols': showChordSymbols,
      'showIntervalNames': showIntervalNames,

      // Quiz
      'showQuizHints': showQuizHints,
      'showQuizExplanations': showQuizExplanations,
      'allowQuizSkipping': allowQuizSkipping,
      'defaultQuizTimeLimit': defaultQuizTimeLimit,
      'showQuizTimer': showQuizTimer,
      'showQuizProgress': showQuizProgress,
      'playQuizSounds': playQuizSounds,
      'showQuizFeedback': showQuizFeedback,
      'randomizeQuizOrder': randomizeQuizOrder,
      'showQuizResults': showQuizResults,

      // Learning
      'showLearningProgress': showLearningProgress,
      'showTopicOverview': showTopicOverview,
      'showSectionSummary': showSectionSummary,
      'autoAdvanceTopics': autoAdvanceTopics,
      'showDifficultyLevel': showDifficultyLevel,
      'showEstimatedTime': showEstimatedTime,
      'showPrerequisites': showPrerequisites,
      'showRelatedTopics': showRelatedTopics,

      // Accessibility
      'useHighContrast': useHighContrast,
      'useLargeText': useLargeText,
      'showColorBlindFriendly': showColorBlindFriendly,
      'useReducedMotion': useReducedMotion,
      'showScreenReaderLabels': showScreenReaderLabels,
      'useHapticFeedback': useHapticFeedback,

      // Performance
      'enableCaching': enableCaching,
      'preloadContent': preloadContent,
      'optimizeForSlowConnections': optimizeForSlowConnections,
      'enableOfflineMode': enableOfflineMode,
    };
  }

  /// Create from JSON - ENHANCED with new audio fields and backwards compatibility
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      // Theme and UI
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      showAnimations: json['showAnimations'] as bool? ?? true,
      showHints: json['showHints'] as bool? ?? true,
      showTooltips: json['showTooltips'] as bool? ?? true,
      playSounds: json['playSounds'] as bool? ?? true,
      soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 0.5,
      showNotifications: json['showNotifications'] as bool? ?? true,
      autoSaveProgress: json['autoSaveProgress'] as bool? ?? true,

      // NEW: Enhanced audio system preferences with backwards compatibility
      audioBackend: json['audioBackend'] != null 
          ? AudioBackend.values[json['audioBackend'] as int] 
          : AudioBackend.midi,
      melodyNoteDuration: json['melodyNoteDurationMs'] != null 
          ? Duration(milliseconds: json['melodyNoteDurationMs'] as int) 
          : const Duration(milliseconds: 500),
      melodyGapDuration: json['melodyGapDurationMs'] != null 
          ? Duration(milliseconds: json['melodyGapDurationMs'] as int) 
          : const Duration(milliseconds: 50),
      harmonyDuration: json['harmonyDurationMs'] != null 
          ? Duration(milliseconds: json['harmonyDurationMs'] as int) 
          : const Duration(milliseconds: 2000),
      defaultVelocity: json['defaultVelocity'] as int? ?? 100,
      audioEnabled: json['audioEnabled'] as bool? ?? true,

      // Fretboard display
      defaultLayout: FretboardLayout.values[json['defaultLayout'] as int? ?? 0],
      defaultStringCount: json['defaultStringCount'] as int? ?? 6,
      defaultFretCount: json['defaultFretCount'] as int? ?? 12,
      defaultTuning: List<String>.from(json['defaultTuning'] as List? ?? ['E2', 'A2', 'D3', 'G3', 'B3', 'E4']),
      showFretNumbers: json['showFretNumbers'] as bool? ?? true,
      showStringLabels: json['showStringLabels'] as bool? ?? true,
      showNoteNames: json['showNoteNames'] as bool? ?? true,
      showIntervals: json['showIntervals'] as bool? ?? true,
      showScaleDegrees: json['showScaleDegrees'] as bool? ?? true,
      highlightRootNotes: json['highlightRootNotes'] as bool? ?? true,
      highlightSelectedNotes: json['highlightSelectedNotes'] as bool? ?? true,
      fretboardScale: (json['fretboardScale'] as num?)?.toDouble() ?? 1.0,
      showEmptyStrings: json['showEmptyStrings'] as bool? ?? true,

      // Music theory
      defaultRoot: json['defaultRoot'] as String? ?? 'C',
      defaultViewMode: ViewMode.values[json['defaultViewMode'] as int? ?? 0],
      defaultScale: json['defaultScale'] as String? ?? 'Major',
      defaultSelectedOctaves: Set<int>.from(json['defaultSelectedOctaves'] as List? ?? [3]),
      useFlatsForSharps: json['useFlatsForSharps'] as bool? ?? false,
      showEnharmonicEquivalents: json['showEnharmonicEquivalents'] as bool? ?? true,
      showModeNames: json['showModeNames'] as bool? ?? true,
      showChordSymbols: json['showChordSymbols'] as bool? ?? true,
      showIntervalNames: json['showIntervalNames'] as bool? ?? true,

      // Quiz
      showQuizHints: json['showQuizHints'] as bool? ?? true,
      showQuizExplanations: json['showQuizExplanations'] as bool? ?? true,
      allowQuizSkipping: json['allowQuizSkipping'] as bool? ?? false,
      defaultQuizTimeLimit: json['defaultQuizTimeLimit'] as int? ?? 0,
      showQuizTimer: json['showQuizTimer'] as bool? ?? true,
      showQuizProgress: json['showQuizProgress'] as bool? ?? true,
      playQuizSounds: json['playQuizSounds'] as bool? ?? true,
      showQuizFeedback: json['showQuizFeedback'] as bool? ?? true,
      randomizeQuizOrder: json['randomizeQuizOrder'] as bool? ?? false,
      showQuizResults: json['showQuizResults'] as bool? ?? true,

      // Learning
      showLearningProgress: json['showLearningProgress'] as bool? ?? true,
      showTopicOverview: json['showTopicOverview'] as bool? ?? true,
      showSectionSummary: json['showSectionSummary'] as bool? ?? true,
      autoAdvanceTopics: json['autoAdvanceTopics'] as bool? ?? false,
      showDifficultyLevel: json['showDifficultyLevel'] as bool? ?? true,
      showEstimatedTime: json['showEstimatedTime'] as bool? ?? true,
      showPrerequisites: json['showPrerequisites'] as bool? ?? true,
      showRelatedTopics: json['showRelatedTopics'] as bool? ?? true,

      // Accessibility
      useHighContrast: json['useHighContrast'] as bool? ?? false,
      useLargeText: json['useLargeText'] as bool? ?? false,
      showColorBlindFriendly: json['showColorBlindFriendly'] as bool? ?? false,
      useReducedMotion: json['useReducedMotion'] as bool? ?? false,
      showScreenReaderLabels: json['showScreenReaderLabels'] as bool? ?? false,
      useHapticFeedback: json['useHapticFeedback'] as bool? ?? true,

      // Performance
      enableCaching: json['enableCaching'] as bool? ?? true,
      preloadContent: json['preloadContent'] as bool? ?? true,
      optimizeForSlowConnections: json['optimizeForSlowConnections'] as bool? ?? false,
      enableOfflineMode: json['enableOfflineMode'] as bool? ?? true,
    );
  }

  /// Create copy with updated fields - ENHANCED with new audio fields
  UserPreferences copyWith({
    // Theme and UI
    ThemeMode? themeMode,
    bool? showAnimations,
    bool? showHints,
    bool? showTooltips,
    bool? playSounds,
    double? soundVolume,
    bool? showNotifications,
    bool? autoSaveProgress,

    // NEW: Enhanced audio system parameters
    AudioBackend? audioBackend,
    Duration? melodyNoteDuration,
    Duration? melodyGapDuration,
    Duration? harmonyDuration,
    int? defaultVelocity,
    bool? audioEnabled,

    // Fretboard display
    FretboardLayout? defaultLayout,
    int? defaultStringCount,
    int? defaultFretCount,
    List<String>? defaultTuning,
    bool? showFretNumbers,
    bool? showStringLabels,
    bool? showNoteNames,
    bool? showIntervals,
    bool? showScaleDegrees,
    bool? highlightRootNotes,
    bool? highlightSelectedNotes,
    double? fretboardScale,
    bool? showEmptyStrings,

    // Music theory
    String? defaultRoot,
    ViewMode? defaultViewMode,
    String? defaultScale,
    Set<int>? defaultSelectedOctaves,
    bool? useFlatsForSharps,
    bool? showEnharmonicEquivalents,
    bool? showModeNames,
    bool? showChordSymbols,
    bool? showIntervalNames,

    // Quiz
    bool? showQuizHints,
    bool? showQuizExplanations,
    bool? allowQuizSkipping,
    int? defaultQuizTimeLimit,
    bool? showQuizTimer,
    bool? showQuizProgress,
    bool? playQuizSounds,
    bool? showQuizFeedback,
    bool? randomizeQuizOrder,
    bool? showQuizResults,

    // Learning
    bool? showLearningProgress,
    bool? showTopicOverview,
    bool? showSectionSummary,
    bool? autoAdvanceTopics,
    bool? showDifficultyLevel,
    bool? showEstimatedTime,
    bool? showPrerequisites,
    bool? showRelatedTopics,

    // Accessibility
    bool? useHighContrast,
    bool? useLargeText,
    bool? showColorBlindFriendly,
    bool? useReducedMotion,
    bool? showScreenReaderLabels,
    bool? useHapticFeedback,

    // Performance
    bool? enableCaching,
    bool? preloadContent,
    bool? optimizeForSlowConnections,
    bool? enableOfflineMode,
  }) {
    return UserPreferences(
      // Theme and UI
      themeMode: themeMode ?? this.themeMode,
      showAnimations: showAnimations ?? this.showAnimations,
      showHints: showHints ?? this.showHints,
      showTooltips: showTooltips ?? this.showTooltips,
      playSounds: playSounds ?? this.playSounds,
      soundVolume: soundVolume ?? this.soundVolume,
      showNotifications: showNotifications ?? this.showNotifications,
      autoSaveProgress: autoSaveProgress ?? this.autoSaveProgress,

      // NEW: Enhanced audio system
      audioBackend: audioBackend ?? this.audioBackend,
      melodyNoteDuration: melodyNoteDuration ?? this.melodyNoteDuration,
      melodyGapDuration: melodyGapDuration ?? this.melodyGapDuration,
      harmonyDuration: harmonyDuration ?? this.harmonyDuration,
      defaultVelocity: defaultVelocity ?? this.defaultVelocity,
      audioEnabled: audioEnabled ?? this.audioEnabled,

      // Fretboard display
      defaultLayout: defaultLayout ?? this.defaultLayout,
      defaultStringCount: defaultStringCount ?? this.defaultStringCount,
      defaultFretCount: defaultFretCount ?? this.defaultFretCount,
      defaultTuning: defaultTuning ?? this.defaultTuning,
      showFretNumbers: showFretNumbers ?? this.showFretNumbers,
      showStringLabels: showStringLabels ?? this.showStringLabels,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      showIntervals: showIntervals ?? this.showIntervals,
      showScaleDegrees: showScaleDegrees ?? this.showScaleDegrees,
      highlightRootNotes: highlightRootNotes ?? this.highlightRootNotes,
      highlightSelectedNotes: highlightSelectedNotes ?? this.highlightSelectedNotes,
      fretboardScale: fretboardScale ?? this.fretboardScale,
      showEmptyStrings: showEmptyStrings ?? this.showEmptyStrings,

      // Music theory
      defaultRoot: defaultRoot ?? this.defaultRoot,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      defaultScale: defaultScale ?? this.defaultScale,
      defaultSelectedOctaves: defaultSelectedOctaves ?? this.defaultSelectedOctaves,
      useFlatsForSharps: useFlatsForSharps ?? this.useFlatsForSharps,
      showEnharmonicEquivalents: showEnharmonicEquivalents ?? this.showEnharmonicEquivalents,
      showModeNames: showModeNames ?? this.showModeNames,
      showChordSymbols: showChordSymbols ?? this.showChordSymbols,
      showIntervalNames: showIntervalNames ?? this.showIntervalNames,

      // Quiz
      showQuizHints: showQuizHints ?? this.showQuizHints,
      showQuizExplanations: showQuizExplanations ?? this.showQuizExplanations,
      allowQuizSkipping: allowQuizSkipping ?? this.allowQuizSkipping,
      defaultQuizTimeLimit: defaultQuizTimeLimit ?? this.defaultQuizTimeLimit,
      showQuizTimer: showQuizTimer ?? this.showQuizTimer,
      showQuizProgress: showQuizProgress ?? this.showQuizProgress,
      playQuizSounds: playQuizSounds ?? this.playQuizSounds,
      showQuizFeedback: showQuizFeedback ?? this.showQuizFeedback,
      randomizeQuizOrder: randomizeQuizOrder ?? this.randomizeQuizOrder,
      showQuizResults: showQuizResults ?? this.showQuizResults,

      // Learning
      showLearningProgress: showLearningProgress ?? this.showLearningProgress,
      showTopicOverview: showTopicOverview ?? this.showTopicOverview,
      showSectionSummary: showSectionSummary ?? this.showSectionSummary,
      autoAdvanceTopics: autoAdvanceTopics ?? this.autoAdvanceTopics,
      showDifficultyLevel: showDifficultyLevel ?? this.showDifficultyLevel,
      showEstimatedTime: showEstimatedTime ?? this.showEstimatedTime,
      showPrerequisites: showPrerequisites ?? this.showPrerequisites,
      showRelatedTopics: showRelatedTopics ?? this.showRelatedTopics,

      // Accessibility
      useHighContrast: useHighContrast ?? this.useHighContrast,
      useLargeText: useLargeText ?? this.useLargeText,
      showColorBlindFriendly: showColorBlindFriendly ?? this.showColorBlindFriendly,
      useReducedMotion: useReducedMotion ?? this.useReducedMotion,
      showScreenReaderLabels: showScreenReaderLabels ?? this.showScreenReaderLabels,
      useHapticFeedback: useHapticFeedback ?? this.useHapticFeedback,

      // Performance
      enableCaching: enableCaching ?? this.enableCaching,
      preloadContent: preloadContent ?? this.preloadContent,
      optimizeForSlowConnections: optimizeForSlowConnections ?? this.optimizeForSlowConnections,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
    );
  }

  /// Get fretboard-specific preferences as a separate object
  FretboardPreferences get fretboardPreferences => FretboardPreferences(
    layout: defaultLayout,
    stringCount: defaultStringCount,
    fretCount: defaultFretCount,
    tuning: defaultTuning,
    showFretNumbers: showFretNumbers,
    showStringLabels: showStringLabels,
    scale: fretboardScale,
    showEmptyStrings: showEmptyStrings,
  );

  /// Get quiz-specific preferences as a separate object
  QuizPreferences get quizPreferences => QuizPreferences(
    showHints: showQuizHints,
    showExplanations: showQuizExplanations,
    allowSkipping: allowQuizSkipping,
    timeLimit: defaultQuizTimeLimit,
    showTimer: showQuizTimer,
    showProgress: showQuizProgress,
    playSounds: playQuizSounds,
    showFeedback: showQuizFeedback,
    randomizeOrder: randomizeQuizOrder,
    showResults: showQuizResults,
  );

  /// NEW: Get audio-specific preferences as a separate object for the audio system
  AudioPreferences get audioPreferences => AudioPreferences(
    backend: audioBackend,
    volume: soundVolume, // Use existing soundVolume for master volume
    melodyNoteDuration: melodyNoteDuration,
    melodyGapDuration: melodyGapDuration,
    harmonyDuration: harmonyDuration,
    defaultVelocity: defaultVelocity,
    enabled: audioEnabled && playSounds, // Combine both audio flags
  );

  @override
  String toString() {
    return 'UserPreferences(theme: $themeMode, layout: $defaultLayout, root: $defaultRoot, scale: $defaultScale)';
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
        other.defaultScale == defaultScale &&
        // NEW: Include audio preferences in equality check
        other.audioBackend == audioBackend &&
        other.audioEnabled == audioEnabled;
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
        // NEW: Include audio preferences in hash
        audioBackend,
        audioEnabled,
      );
}

/// Subset of preferences specific to fretboard display
class FretboardPreferences {
  final FretboardLayout layout;
  final int stringCount;
  final int fretCount;
  final List<String> tuning;
  final bool showFretNumbers;
  final bool showStringLabels;
  final double scale;
  final bool showEmptyStrings;

  const FretboardPreferences({
    required this.layout,
    required this.stringCount,
    required this.fretCount,
    required this.tuning,
    required this.showFretNumbers,
    required this.showStringLabels,
    required this.scale,
    required this.showEmptyStrings,
  });
}

/// Subset of preferences specific to quiz behavior
class QuizPreferences {
  final bool showHints;
  final bool showExplanations;
  final bool allowSkipping;
  final int timeLimit;
  final bool showTimer;
  final bool showProgress;
  final bool playSounds;
  final bool showFeedback;
  final bool randomizeOrder;
  final bool showResults;

  const QuizPreferences({
    required this.showHints,
    required this.showExplanations,
    required this.allowSkipping,
    required this.timeLimit,
    required this.showTimer,
    required this.showProgress,
    required this.playSounds,
    required this.showFeedback,
    required this.randomizeOrder,
    required this.showResults,
  });
}

/// NEW: Subset of preferences specific to audio system behavior
class AudioPreferences {
  final AudioBackend backend;
  final double volume;
  final Duration melodyNoteDuration;
  final Duration melodyGapDuration;
  final Duration harmonyDuration;
  final int defaultVelocity;
  final bool enabled;

  const AudioPreferences({
    required this.backend,
    required this.volume,
    required this.melodyNoteDuration,
    required this.melodyGapDuration,
    required this.harmonyDuration,
    required this.defaultVelocity,
    required this.enabled,
  });
}