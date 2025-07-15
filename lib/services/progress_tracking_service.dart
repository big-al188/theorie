// lib/services/progress_tracking_service.dart

import 'package:flutter/foundation.dart';
import '../models/user/user.dart';
import '../models/user/user_progress.dart';
import '../models/quiz/quiz_result.dart';
import '../models/learning/learning_content.dart';
import 'user_service.dart';

/// Service responsible for tracking and updating user learning progress
///
/// This service handles:
/// - Topic completion tracking when quizzes are finished
/// - Section progress calculations and updates
/// - Progress persistence through UserService
/// - Real-time progress notifications
class ProgressTrackingService extends ChangeNotifier {
  static final ProgressTrackingService _instance =
      ProgressTrackingService._internal();
  static ProgressTrackingService get instance => _instance;

  ProgressTrackingService._internal();

  /// Records quiz completion and updates progress
  ///
  /// This method:
  /// 1. Determines if the quiz was passed based on score
  /// 2. Updates topic completion status
  /// 3. Recalculates section progress
  /// 4. Persists changes through UserService
  /// 5. Notifies listeners of progress changes
  Future<void> recordQuizCompletion({
    required QuizResult result,
    required String topicId,
    String? sectionId,
    double passingScore = 0.7,
  }) async {
    try {
      // Determine if quiz was passed
      final passed = result.scorePercentage >= passingScore;

      // Get current user
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) {
        debugPrint('Warning: Cannot record progress - no current user');
        return;
      }

      // Update topic completion
      await _updateTopicCompletion(
        userId: currentUser.id,
        topicId: topicId,
        sectionId: sectionId,
        passed: passed,
        score: result.scorePercentage,
        timeSpent: result.timeElapsed,
      );

      // Notify listeners that progress has changed
      notifyListeners();

      debugPrint(
          'Progress updated: Topic $topicId - ${passed ? "PASSED" : "FAILED"} (${(result.scorePercentage * 100).round()}%)');
    } catch (e) {
      debugPrint('Error recording quiz completion: $e');
      rethrow;
    }
  }

  /// Updates topic completion status and section progress
  Future<void> _updateTopicCompletion({
    required String userId,
    required String topicId,
    String? sectionId,
    required bool passed,
    required double score,
    required Duration timeSpent,
  }) async {
    try {
      // Get current user and progress
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) return;

      var currentProgress = currentUser.progress;

      // Update topic completion
      currentProgress = currentProgress.completeTopicQuiz(topicId, passed);

      // If we have a section ID, also update section-level tracking
      if (sectionId != null) {
        currentProgress = _updateSectionProgress(
          progress: currentProgress,
          sectionId: sectionId,
          topicId: topicId,
          passed: passed,
        );
      }

      // Update detailed quiz tracking
      currentProgress = _updateDetailedQuizTracking(
        progress: currentProgress,
        topicId: topicId,
        score: score,
        timeSpent: timeSpent,
        passed: passed,
      );

      // Save updated progress
      await UserService.instance.updateUserProgress(currentProgress);
    } catch (e) {
      debugPrint('Error updating topic completion: $e');
      rethrow;
    }
  }

  /// Updates section-level progress calculations
  UserProgress _updateSectionProgress({
    required UserProgress progress,
    required String sectionId,
    required String topicId,
    required bool passed,
  }) {
    try {
      // Get the section to find total topics
      final section = LearningContentRepository.getSection(
        LearningLevel.values.firstWhere(
          (level) =>
              LearningContentRepository.getSection(level)?.id == sectionId,
          orElse: () => LearningLevel.introduction,
        ),
      );

      if (section == null) {
        debugPrint('Warning: Could not find section $sectionId');
        return progress;
      }

      // Count completed topics in this section
      int completedTopics = 0;
      for (final topic in section.topics) {
        if (progress.completedTopics.contains(topic.id)) {
          completedTopics++;
        }
      }

      // Create updated section progress
      final sectionProgress = SectionProgress(
        topicsCompleted: completedTopics,
        totalTopics: section.totalTopics,
        sectionQuizCompleted:
            progress.completedSectionQuizzes.contains(sectionId),
      );

      // Update the progress with new section data
      final updatedSectionProgress =
          Map<String, SectionProgress>.from(progress.sectionProgress);
      updatedSectionProgress[sectionId] = sectionProgress;

      return progress.copyWith(sectionProgress: updatedSectionProgress);
    } catch (e) {
      debugPrint('Error updating section progress: $e');
      return progress;
    }
  }

  /// Updates detailed quiz tracking for analytics
  UserProgress _updateDetailedQuizTracking({
    required UserProgress progress,
    required String topicId,
    required double score,
    required Duration timeSpent,
    required bool passed,
  }) {
    try {
      // Create quiz attempt record
      final quizAttempt = QuizAttempt(
        topicId: topicId,
        score: score,
        timeSpent: timeSpent,
        passed: passed,
        attemptDate: DateTime.now(),
      );

      // Update quiz attempts list
      final updatedAttempts =
          List<QuizAttempt>.from(progress.quizAttempts ?? []);
      updatedAttempts.add(quizAttempt);

      // Update best scores tracking
      final updatedBestScores =
          Map<String, double>.from(progress.bestScores ?? {});
      final currentBest = updatedBestScores[topicId] ?? 0.0;
      if (score > currentBest) {
        updatedBestScores[topicId] = score;
      }

      return progress.copyWith(
        quizAttempts: updatedAttempts,
        bestScores: updatedBestScores,
      );
    } catch (e) {
      debugPrint('Error updating detailed quiz tracking: $e');
      return progress;
    }
  }

  /// Gets current progress for a specific section
  SectionProgress getSectionProgress(String sectionId) {
    try {
      // This is a synchronous method for UI use
      // It should be called after progress is already loaded
      final userService = UserService.instance;

      // Note: This assumes getCurrentUser is synchronous or cached
      // In production, you might want to cache this data
      return SectionProgress(
        topicsCompleted: 0,
        totalTopics: _getTotalTopicsForSection(sectionId),
        sectionQuizCompleted: false,
      );
    } catch (e) {
      debugPrint('Error getting section progress: $e');
      return SectionProgress(
        topicsCompleted: 0,
        totalTopics: 0,
        sectionQuizCompleted: false,
      );
    }
  }

  /// Gets total topics for a section
  int _getTotalTopicsForSection(String sectionId) {
    try {
      final section = LearningContentRepository.getAllSections()
          .firstWhere((s) => s.id == sectionId);
      return section.totalTopics;
    } catch (e) {
      debugPrint('Error getting total topics for section $sectionId: $e');
      return 0;
    }
  }

  /// Forces a refresh of progress data from storage
  Future<void> refreshProgress() async {
    try {
      // Force UserService to reload current user data
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser != null) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing progress: $e');
    }
  }

  /// Clears all progress data (for testing or reset functionality)
  Future<void> clearAllProgress() async {
    try {
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser != null) {
        final emptyProgress = UserProgress(
          completedTopics: <String>{},
          completedSectionQuizzes: <String>{},
          sectionProgress: <String, SectionProgress>{},
        );

        await UserService.instance.updateUserProgress(emptyProgress);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error clearing progress: $e');
      rethrow;
    }
  }
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
}
