// lib/models/user/user_progress.dart

/// Represents user's learning progress and quiz completion status
///
/// This model tracks:
/// - Individual topic completion status
/// - Section-level progress aggregation
/// - Detailed quiz attempt history
/// - Best scores for each topic
/// - Section quiz completion status
class UserProgress {
  final Set<String> completedTopics;
  final Set<String> completedSectionQuizzes;
  final Map<String, SectionProgress> sectionProgress;
  final List<QuizAttempt>? quizAttempts;
  final Map<String, double>? bestScores;

  const UserProgress({
    this.completedTopics = const <String>{},
    this.completedSectionQuizzes = const <String>{},
    this.sectionProgress = const <String, SectionProgress>{},
    this.quizAttempts,
    this.bestScores,
  });

  /// Creates a copy with updated values
  UserProgress copyWith({
    Set<String>? completedTopics,
    Set<String>? completedSectionQuizzes,
    Map<String, SectionProgress>? sectionProgress,
    List<QuizAttempt>? quizAttempts,
    Map<String, double>? bestScores,
  }) {
    return UserProgress(
      completedTopics: completedTopics ?? this.completedTopics,
      completedSectionQuizzes:
          completedSectionQuizzes ?? this.completedSectionQuizzes,
      sectionProgress: sectionProgress ?? this.sectionProgress,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      bestScores: bestScores ?? this.bestScores,
    );
  }

  /// Marks a topic quiz as completed and updates section progress
  UserProgress completeTopicQuiz(String topicId, bool passed) {
    final updatedCompleted = Set<String>.from(completedTopics);

    if (passed) {
      updatedCompleted.add(topicId);
    } else {
      // Remove if previously completed but now failed
      updatedCompleted.remove(topicId);
    }

    // Update section progress will be handled by ProgressTrackingService
    return copyWith(completedTopics: updatedCompleted);
  }

  /// Marks a section quiz as completed
  UserProgress completeSectionQuiz(String sectionId, bool passed) {
    final updatedCompleted = Set<String>.from(completedSectionQuizzes);

    if (passed) {
      updatedCompleted.add(sectionId);
    } else {
      updatedCompleted.remove(sectionId);
    }

    // Update the specific section progress
    final updatedSectionProgress =
        Map<String, SectionProgress>.from(sectionProgress);
    final currentSection = updatedSectionProgress[sectionId] ??
        const SectionProgress(
            topicsCompleted: 0, totalTopics: 0, sectionQuizCompleted: false);

    updatedSectionProgress[sectionId] = currentSection.copyWith(
      sectionQuizCompleted: passed,
    );

    return copyWith(
      completedSectionQuizzes: updatedCompleted,
      sectionProgress: updatedSectionProgress,
    );
  }

  /// Gets progress for a specific section
  SectionProgress getSectionProgress(String sectionId) {
    return sectionProgress[sectionId] ??
        const SectionProgress(
            topicsCompleted: 0, totalTopics: 0, sectionQuizCompleted: false);
  }

  /// Checks if a topic is completed
  bool isTopicCompleted(String topicId) {
    return completedTopics.contains(topicId);
  }

  /// Checks if a section quiz is completed
  bool isSectionQuizCompleted(String sectionId) {
    return completedSectionQuizzes.contains(sectionId);
  }

  /// Gets the best score for a topic
  double getBestScore(String topicId) {
    return bestScores?[topicId] ?? 0.0;
  }

  /// Gets quiz attempts for a specific topic
  List<QuizAttempt> getTopicAttempts(String topicId) {
    return quizAttempts
            ?.where((attempt) => attempt.topicId == topicId)
            .toList() ??
        [];
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
  int get totalTopicsCompleted {
    return completedTopics.length;
  }

  /// Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'completedTopics': completedTopics.toList(),
      'completedSectionQuizzes': completedSectionQuizzes.toList(),
      'sectionProgress': sectionProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'quizAttempts': quizAttempts?.map((attempt) => attempt.toJson()).toList(),
      'bestScores': bestScores,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      completedTopics: Set<String>.from(json['completedTopics'] ?? []),
      completedSectionQuizzes:
          Set<String>.from(json['completedSectionQuizzes'] ?? []),
      sectionProgress: (json['sectionProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, SectionProgress.fromJson(value)),
          ) ??
          {},
      quizAttempts: (json['quizAttempts'] as List?)
          ?.map((attempt) => QuizAttempt.fromJson(attempt))
          .toList(),
      bestScores: json['bestScores'] != null
          ? Map<String, double>.from(json['bestScores'])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserProgress(completed: ${completedTopics.length}, sections: ${sectionProgress.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.completedTopics == completedTopics &&
        other.completedSectionQuizzes == completedSectionQuizzes;
  }

  @override
  int get hashCode => Object.hash(completedTopics, completedSectionQuizzes);
}

/// Represents progress within a specific learning section
class SectionProgress {
  final int topicsCompleted;
  final int totalTopics;
  final bool sectionQuizCompleted;

  const SectionProgress({
    required this.topicsCompleted,
    required this.totalTopics,
    required this.sectionQuizCompleted,
  });

  /// Creates a copy with updated values
  SectionProgress copyWith({
    int? topicsCompleted,
    int? totalTopics,
    bool? sectionQuizCompleted,
  }) {
    return SectionProgress(
      topicsCompleted: topicsCompleted ?? this.topicsCompleted,
      totalTopics: totalTopics ?? this.totalTopics,
      sectionQuizCompleted: sectionQuizCompleted ?? this.sectionQuizCompleted,
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

  /// Gets a human-readable progress string
  String get progressText => '$topicsCompleted / $totalTopics';

  /// Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'topicsCompleted': topicsCompleted,
      'totalTopics': totalTopics,
      'sectionQuizCompleted': sectionQuizCompleted,
    };
  }

  factory SectionProgress.fromJson(Map<String, dynamic> json) {
    return SectionProgress(
      topicsCompleted: json['topicsCompleted'] as int? ?? 0,
      totalTopics: json['totalTopics'] as int? ?? 0,
      sectionQuizCompleted: json['sectionQuizCompleted'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SectionProgress($progressText, quiz: $sectionQuizCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionProgress &&
        other.topicsCompleted == topicsCompleted &&
        other.totalTopics == totalTopics &&
        other.sectionQuizCompleted == sectionQuizCompleted;
  }

  @override
  int get hashCode =>
      Object.hash(topicsCompleted, totalTopics, sectionQuizCompleted);
}

/// Represents a single quiz attempt for detailed tracking
class QuizAttempt {
  final String topicId;
  final double score;
  final Duration timeSpent;
  final bool passed;
  final DateTime attemptDate;

  const QuizAttempt({
    required this.topicId,
    required this.score,
    required this.timeSpent,
    required this.passed,
    required this.attemptDate,
  });

  /// Serialization methods
  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'score': score,
        'timeSpent': timeSpent.inSeconds,
        'passed': passed,
        'attemptDate': attemptDate.toIso8601String(),
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
        topicId: json['topicId'] as String,
        score: (json['score'] as num).toDouble(),
        timeSpent: Duration(seconds: json['timeSpent'] as int),
        passed: json['passed'] as bool,
        attemptDate: DateTime.parse(json['attemptDate'] as String),
      );

  @override
  String toString() {
    return 'QuizAttempt($topicId: ${(score * 100).round()}%, ${passed ? "PASSED" : "FAILED"})';
  }
}
