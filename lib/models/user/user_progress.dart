// lib/models/user/user_progress.dart
import 'package:uuid/uuid.dart';

/// Represents comprehensive user learning progress and quiz completion status
/// This is the single source of truth for all user progress tracking
class UserProgress {
  final Set<String> completedTopics;
  final Set<String> completedSections;
  final Map<String, SectionProgress> sectionProgress;
  final List<QuizAttempt> quizAttempts;
  final Map<String, double> bestScores;
  final Map<String, int> topicAttemptCounts;
  final Map<String, Duration> topicTimeSpent;
  final DateTime? lastActivityDate;
  final int totalQuizzesTaken; // ADDED: For backward compatibility
  final int totalQuizzesPassed; // ADDED: For backward compatibility
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStreakDate;

  const UserProgress({
    this.completedTopics = const <String>{},
    this.completedSections = const <String>{},
    this.sectionProgress = const <String, SectionProgress>{},
    this.quizAttempts = const <QuizAttempt>[],
    this.bestScores = const <String, double>{},
    this.topicAttemptCounts = const <String, int>{},
    this.topicTimeSpent = const <String, Duration>{},
    this.lastActivityDate,
    this.totalQuizzesTaken = 0, // ADDED: For backward compatibility
    this.totalQuizzesPassed = 0, // ADDED: For backward compatibility
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakDate,
  });

  /// Create empty progress for new users
  factory UserProgress.empty() {
    return const UserProgress();
  }

  /// Creates a copy with updated values
  UserProgress copyWith({
    Set<String>? completedTopics,
    Set<String>? completedSections,
    Map<String, SectionProgress>? sectionProgress,
    List<QuizAttempt>? quizAttempts,
    Map<String, double>? bestScores,
    Map<String, int>? topicAttemptCounts,
    Map<String, Duration>? topicTimeSpent,
    DateTime? lastActivityDate,
    int? totalQuizzesTaken, // ADDED: For backward compatibility
    int? totalQuizzesPassed, // ADDED: For backward compatibility
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStreakDate,
  }) {
    return UserProgress(
      completedTopics: completedTopics ?? this.completedTopics,
      completedSections: completedSections ?? this.completedSections,
      sectionProgress: sectionProgress ?? this.sectionProgress,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      bestScores: bestScores ?? this.bestScores,
      topicAttemptCounts: topicAttemptCounts ?? this.topicAttemptCounts,
      topicTimeSpent: topicTimeSpent ?? this.topicTimeSpent,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken, // ADDED
      totalQuizzesPassed: totalQuizzesPassed ?? this.totalQuizzesPassed, // ADDED
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
    );
  }

  /// Record a quiz attempt and update progress
  UserProgress recordQuizAttempt({
    required String topicId,
    required String sectionId,
    required double score,
    required bool passed,
    required Duration timeSpent,
    required int totalQuestions,
    required int correctAnswers,
    bool isTopicQuiz = true,
  }) {
    final now = DateTime.now();
    final attempt = QuizAttempt(
      id: const Uuid().v4(),
      topicId: topicId,
      sectionId: sectionId,
      timestamp: now,
      score: score,
      passed: passed,
      timeSpent: timeSpent,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      isTopicQuiz: isTopicQuiz,
    );

    // Update attempts list
    final updatedAttempts = List<QuizAttempt>.from(quizAttempts)..add(attempt);

    // Update best scores
    final updatedBestScores = Map<String, double>.from(bestScores);
    final currentBest = updatedBestScores[topicId] ?? 0.0;
    if (score > currentBest) {
      updatedBestScores[topicId] = score;
    }

    // Update attempt counts
    final updatedAttemptCounts = Map<String, int>.from(topicAttemptCounts);
    updatedAttemptCounts[topicId] = (updatedAttemptCounts[topicId] ?? 0) + 1;

    // Update time spent
    final updatedTimeSpent = Map<String, Duration>.from(topicTimeSpent);
    final currentTime = updatedTimeSpent[topicId] ?? Duration.zero;
    updatedTimeSpent[topicId] = currentTime + timeSpent;

    // Update completion status
    final updatedCompletedTopics = Set<String>.from(completedTopics);
    final updatedCompletedSections = Set<String>.from(completedSections);

    if (passed) {
      if (isTopicQuiz) {
        updatedCompletedTopics.add(topicId);
      } else {
        updatedCompletedSections.add(sectionId);
      }
    }

    // Update streak
    final updatedStreak = _updateStreak(passed, now);

    return copyWith(
      quizAttempts: updatedAttempts,
      bestScores: updatedBestScores,
      topicAttemptCounts: updatedAttemptCounts,
      topicTimeSpent: updatedTimeSpent,
      completedTopics: updatedCompletedTopics,
      completedSections: updatedCompletedSections,
      lastActivityDate: now,
      totalQuizzesTaken: totalQuizzesTaken + 1,
      totalQuizzesPassed: passed ? totalQuizzesPassed + 1 : totalQuizzesPassed,
      currentStreak: updatedStreak.currentStreak,
      longestStreak: updatedStreak.longestStreak,
      lastStreakDate: updatedStreak.lastStreakDate,
    );
  }

  /// Update section progress based on completed topics
  UserProgress updateSectionProgress(String sectionId, int totalTopics) {
    final completedInSection = completedTopics
        .where((topicId) => topicId.startsWith(sectionId))
        .length;

    final isSectionCompleted = completedSections.contains(sectionId);

    final updatedSectionProgress = Map<String, SectionProgress>.from(sectionProgress);
    updatedSectionProgress[sectionId] = SectionProgress(
      sectionId: sectionId,
      topicsCompleted: completedInSection,
      totalTopics: totalTopics,
      sectionQuizCompleted: isSectionCompleted,
      lastAccessed: DateTime.now(),
    );

    return copyWith(sectionProgress: updatedSectionProgress);
  }

  /// Helper method to update streak
  ({int currentStreak, int longestStreak, DateTime? lastStreakDate}) _updateStreak(
    bool passed,
    DateTime now,
  ) {
    if (!passed) {
      return (
        currentStreak: 0,
        longestStreak: longestStreak,
        lastStreakDate: lastStreakDate,
      );
    }

    final newCurrentStreak = currentStreak + 1;
    final newLongestStreak = newCurrentStreak > longestStreak ? newCurrentStreak : longestStreak;

    return (
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastStreakDate: now,
    );
  }

  /// Gets progress for a specific section
  SectionProgress getSectionProgress(String sectionId) {
    return sectionProgress[sectionId] ??
        SectionProgress(
          sectionId: sectionId,
          topicsCompleted: 0,
          totalTopics: 0,
          sectionQuizCompleted: false,
        );
  }

  /// Checks if a topic is completed
  bool isTopicCompleted(String topicId) {
    return completedTopics.contains(topicId);
  }

  /// Checks if a section quiz is completed
  bool isSectionCompleted(String sectionId) {
    return completedSections.contains(sectionId);
  }

  /// Gets the best score for a topic
  double getBestScore(String topicId) {
    return bestScores[topicId] ?? 0.0;
  }

  /// Gets quiz attempts for a specific topic
  List<QuizAttempt> getTopicAttempts(String topicId) {
    return quizAttempts.where((attempt) => attempt.topicId == topicId).toList();
  }

  /// Gets the number of attempts for a topic
  int getTopicAttemptCount(String topicId) {
    return topicAttemptCounts[topicId] ?? 0;
  }

  /// Gets total time spent on a topic
  Duration getTopicTimeSpent(String topicId) {
    return topicTimeSpent[topicId] ?? Duration.zero;
  }

  /// Gets recent quiz attempts (last N attempts)
  List<QuizAttempt> getRecentAttempts({int limit = 10}) {
    final sortedAttempts = List<QuizAttempt>.from(quizAttempts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedAttempts.take(limit).toList();
  }

  /// Gets pass rate for a specific topic
  double getTopicPassRate(String topicId) {
    final topicAttempts = getTopicAttempts(topicId);
    if (topicAttempts.isEmpty) return 0.0;

    final passedAttempts = topicAttempts.where((attempt) => attempt.passed).length;
    return passedAttempts / topicAttempts.length;
  }

  /// Gets overall pass rate
  double get overallPassRate {
    if (totalQuizzesTaken == 0) return 0.0;
    return totalQuizzesPassed / totalQuizzesTaken;
  }

  /// Calculates overall progress percentage
  double get overallProgress {
    if (sectionProgress.isEmpty) return 0.0;

    double totalProgress = 0.0;
    int sectionCount = 0;

    for (final progress in sectionProgress.values) {
      totalProgress += progress.progressPercentage;
      sectionCount++;
    }

    return sectionCount > 0 ? totalProgress / sectionCount : 0.0;
  }

  /// Gets total topics completed across all sections
  int get totalTopicsCompleted => completedTopics.length;

  /// Gets total sections completed
  int get totalSectionsCompleted => completedSections.length;

  /// Gets total time spent across all topics
  Duration get totalTimeSpent {
    return topicTimeSpent.values.fold(Duration.zero, (a, b) => a + b);
  }

  /// Gets average quiz score
  double get averageQuizScore {
    if (quizAttempts.isEmpty) return 0.0;
    final totalScore = quizAttempts.fold(0.0, (sum, attempt) => sum + attempt.score);
    return totalScore / quizAttempts.length;
  }

  /// Gets learning statistics
  LearningStats get learningStats => LearningStats(
    totalTopicsCompleted: totalTopicsCompleted,
    totalSectionsCompleted: totalSectionsCompleted,
    totalQuizzesTaken: totalQuizzesTaken,
    totalQuizzesPassed: totalQuizzesPassed,
    overallPassRate: overallPassRate,
    averageScore: averageQuizScore,
    totalTimeSpent: totalTimeSpent,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActivityDate: lastActivityDate,
  );

  /// ADDED: Convenience method for backward compatibility with UserService
  /// Complete a topic quiz with simplified parameters
  UserProgress completeTopicQuiz(String topicId, bool passed) {
    // Use recordQuizAttempt with minimal required data
    return recordQuizAttempt(
      topicId: topicId,
      sectionId: '', // Empty section ID for compatibility
      score: passed ? 1.0 : 0.0, // Simple pass/fail score
      passed: passed,
      timeSpent: Duration.zero, // No time tracking for simple completion
      totalQuestions: 1, // Assume single question for compatibility
      correctAnswers: passed ? 1 : 0,
      isTopicQuiz: true,
    );
  }

  /// ADDED: Convenience method for backward compatibility with UserService
  /// Complete a section quiz with simplified parameters
  UserProgress completeSectionQuiz(String sectionId, bool passed) {
    // Use recordQuizAttempt with minimal required data
    return recordQuizAttempt(
      topicId: '', // Empty topic ID for section quiz
      sectionId: sectionId,
      score: passed ? 1.0 : 0.0, // Simple pass/fail score
      passed: passed,
      timeSpent: Duration.zero, // No time tracking for simple completion
      totalQuestions: 1, // Assume single question for compatibility
      correctAnswers: passed ? 1 : 0,
      isTopicQuiz: false, // This is a section quiz
    );
  }

  /// Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'completedTopics': completedTopics.toList(),
      'completedSections': completedSections.toList(),
      'sectionProgress': sectionProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'quizAttempts': quizAttempts.map((attempt) => attempt.toJson()).toList(),
      'bestScores': bestScores,
      'topicAttemptCounts': topicAttemptCounts,
      'topicTimeSpent': topicTimeSpent.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'totalQuizzesTaken': totalQuizzesTaken, // ADDED: For backward compatibility
      'totalQuizzesPassed': totalQuizzesPassed, // ADDED: For backward compatibility
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStreakDate': lastStreakDate?.toIso8601String(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      completedTopics: Set<String>.from(json['completedTopics'] ?? []),
      completedSections: Set<String>.from(json['completedSections'] ?? []),
      sectionProgress: (json['sectionProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, SectionProgress.fromJson(value)),
          ) ??
          {},
      quizAttempts: (json['quizAttempts'] as List?)
              ?.map((attempt) => QuizAttempt.fromJson(attempt))
              .toList() ??
          [],
      bestScores: json['bestScores'] != null
          ? Map<String, double>.from(json['bestScores'])
          : {},
      topicAttemptCounts: json['topicAttemptCounts'] != null
          ? Map<String, int>.from(json['topicAttemptCounts'])
          : {},
      topicTimeSpent: (json['topicTimeSpent'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Duration(milliseconds: value as int)),
          ) ??
          {},
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'] as String)
          : null,
      totalQuizzesTaken: json['totalQuizzesTaken'] as int? ?? 0, // ADDED
      totalQuizzesPassed: json['totalQuizzesPassed'] as int? ?? 0, // ADDED
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastStreakDate: json['lastStreakDate'] != null
          ? DateTime.parse(json['lastStreakDate'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'UserProgress(topics: $totalTopicsCompleted, sections: $totalSectionsCompleted, quizzes: $totalQuizzesTaken, streak: $currentStreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.completedTopics == completedTopics &&
        other.completedSections == completedSections &&
        other.totalQuizzesTaken == totalQuizzesTaken &&
        other.currentStreak == currentStreak;
  }

  @override
  int get hashCode => Object.hash(
        completedTopics,
        completedSections,
        totalQuizzesTaken,
        currentStreak,
      );
}

/// Represents progress within a specific learning section
class SectionProgress {
  final String sectionId;
  final int topicsCompleted;
  final int totalTopics;
  final bool sectionQuizCompleted;
  final DateTime? lastAccessed;
  final double? averageScore;
  final Duration? totalTimeSpent;

  const SectionProgress({
    this.sectionId = '', // FIXED: Made optional with default
    required this.topicsCompleted,
    required this.totalTopics,
    required this.sectionQuizCompleted,
    this.lastAccessed,
    this.averageScore,
    this.totalTimeSpent,
  });

  /// Creates a copy with updated values
  SectionProgress copyWith({
    String? sectionId,
    int? topicsCompleted,
    int? totalTopics,
    bool? sectionQuizCompleted,
    DateTime? lastAccessed,
    double? averageScore,
    Duration? totalTimeSpent,
  }) {
    return SectionProgress(
      sectionId: sectionId ?? this.sectionId,
      topicsCompleted: topicsCompleted ?? this.topicsCompleted,
      totalTopics: totalTopics ?? this.totalTopics,
      sectionQuizCompleted: sectionQuizCompleted ?? this.sectionQuizCompleted,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      averageScore: averageScore ?? this.averageScore,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
    );
  }

  /// Calculates progress as a percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalTopics == 0) return 0.0;
    return topicsCompleted / totalTopics;
  }

  /// Checks if all topics in the section are completed
  bool get isComplete {
    return topicsCompleted >= totalTopics && totalTopics > 0;
  }

  /// Checks if the section is fully completed (topics + section quiz)
  bool get isFullyComplete {
    return isComplete && sectionQuizCompleted;
  }

  /// Gets a human-readable progress string
  String get progressText => '$topicsCompleted / $totalTopics';

  /// Gets progress percentage as a string
  String get progressPercentageText => '${(progressPercentage * 100).toStringAsFixed(0)}%';

  /// Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'sectionId': sectionId,
      'topicsCompleted': topicsCompleted,
      'totalTopics': totalTopics,
      'sectionQuizCompleted': sectionQuizCompleted,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'averageScore': averageScore,
      'totalTimeSpent': totalTimeSpent?.inMilliseconds,
    };
  }

  factory SectionProgress.fromJson(Map<String, dynamic> json) {
    return SectionProgress(
      sectionId: json['sectionId'] as String? ?? '',
      topicsCompleted: json['topicsCompleted'] as int? ?? 0,
      totalTopics: json['totalTopics'] as int? ?? 0,
      sectionQuizCompleted: json['sectionQuizCompleted'] as bool? ?? false,
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'] as String)
          : null,
      averageScore: json['averageScore'] as double?,
      totalTimeSpent: json['totalTimeSpent'] != null
          ? Duration(milliseconds: json['totalTimeSpent'] as int)
          : null,
    );
  }

  @override
  String toString() {
    return 'SectionProgress($sectionId: $progressText, quiz: $sectionQuizCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionProgress &&
        other.sectionId == sectionId &&
        other.topicsCompleted == topicsCompleted &&
        other.totalTopics == totalTopics &&
        other.sectionQuizCompleted == sectionQuizCompleted;
  }

  @override
  int get hashCode => Object.hash(
        sectionId,
        topicsCompleted,
        totalTopics,
        sectionQuizCompleted,
      );
}

/// Represents a quiz attempt for detailed tracking
class QuizAttempt {
  final String id;
  final String topicId;
  final String sectionId;
  final DateTime timestamp;
  final double score;
  final bool passed;
  final Duration timeSpent;
  final int totalQuestions;
  final int correctAnswers;
  final bool isTopicQuiz;
  final Map<String, dynamic>? metadata;

  const QuizAttempt({
    required this.id,
    required this.topicId,
    required this.sectionId,
    required this.timestamp,
    required this.score,
    required this.passed,
    required this.timeSpent,
    required this.totalQuestions,
    required this.correctAnswers,
    this.isTopicQuiz = true,
    this.metadata,
  });

  /// Gets accuracy percentage
  double get accuracy => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

  /// Gets number of incorrect answers
  int get incorrectAnswers => totalQuestions - correctAnswers;

  /// Gets time per question
  Duration get averageTimePerQuestion {
    if (totalQuestions == 0) return Duration.zero;
    return Duration(milliseconds: timeSpent.inMilliseconds ~/ totalQuestions);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'sectionId': sectionId,
      'timestamp': timestamp.toIso8601String(),
      'score': score,
      'passed': passed,
      'timeSpent': timeSpent.inMilliseconds,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'isTopicQuiz': isTopicQuiz,
      'metadata': metadata,
    };
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      sectionId: json['sectionId'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      score: json['score'] as double,
      passed: json['passed'] as bool,
      timeSpent: Duration(milliseconds: json['timeSpent'] as int),
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      isTopicQuiz: json['isTopicQuiz'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'QuizAttempt($topicId: ${(score * 100).toStringAsFixed(1)}%, $passed)';
  }
}

/// Comprehensive learning statistics
class LearningStats {
  final int totalTopicsCompleted;
  final int totalSectionsCompleted;
  final int totalQuizzesTaken;
  final int totalQuizzesPassed;
  final double overallPassRate;
  final double averageScore;
  final Duration totalTimeSpent;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  const LearningStats({
    required this.totalTopicsCompleted,
    required this.totalSectionsCompleted,
    required this.totalQuizzesTaken,
    required this.totalQuizzesPassed,
    required this.overallPassRate,
    required this.averageScore,
    required this.totalTimeSpent,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
  });

  /// Gets days since last activity
  int? get daysSinceLastActivity {
    if (lastActivityDate == null) return null;
    return DateTime.now().difference(lastActivityDate!).inDays;
  }

  /// Gets total study time in hours
  double get totalStudyHours => totalTimeSpent.inMinutes / 60.0;

  /// Gets average score as percentage
  double get averageScorePercentage => averageScore * 100;

  /// Gets pass rate as percentage
  double get passRatePercentage => overallPassRate * 100;

  @override
  String toString() {
    return 'LearningStats(topics: $totalTopicsCompleted, quizzes: $totalQuizzesTaken, pass rate: ${passRatePercentage.toStringAsFixed(1)}%)';
  }
}