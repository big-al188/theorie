// lib/services/progress_tracking_service.dart

import 'package:flutter/foundation.dart';
import '../models/user/user.dart';
import '../models/quiz/quiz_result.dart';
import '../models/learning/learning_content.dart';
import 'user_service.dart';

/// Service responsible for tracking and updating user learning progress
///
/// This service handles:
/// - Topic completion tracking when quizzes are finished
/// - Section progress calculations and updates
/// - Section quiz auto-completion of all topics
/// - Progress persistence through UserService
/// - Real-time progress notifications
class ProgressTrackingService extends ChangeNotifier {
  static final ProgressTrackingService _instance =
      ProgressTrackingService._internal();
  static ProgressTrackingService get instance => _instance;

  ProgressTrackingService._internal();

  /// Records topic quiz completion and updates progress
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
        timeSpent: result.timeSpent,
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

  /// Records section quiz completion and auto-completes all topics
  ///
  /// When a user passes a section quiz, this method:
  /// 1. Marks the section quiz as completed
  /// 2. Automatically marks ALL topics in the section as completed
  /// 3. Updates section progress to reflect full completion
  /// 4. Notifies listeners for real-time UI updates
  Future<void> recordSectionQuizCompletion({
    required QuizResult result,
    required String sectionId,
    double passingScore = 0.7,
  }) async {
    try {
      // Determine if quiz was passed
      final passed = result.scorePercentage >= passingScore;

      // Get current user
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) {
        debugPrint('Warning: Cannot record section progress - no current user');
        return;
      }

      // Get the section to find all topics
      final section = _findSectionById(sectionId);
      if (section == null) {
        debugPrint('Warning: Could not find section $sectionId');
        return;
      }

      var currentProgress = currentUser.progress;

      // Mark section quiz as completed
      currentProgress = currentProgress.completeSectionQuiz(sectionId, passed);

      // If section quiz was passed, auto-complete all topics in the section
      if (passed) {
        for (final topic in section.topics) {
          currentProgress = currentProgress.completeTopicQuiz(topic.id, true);
        }

        // Update section progress to reflect all topics completed
        currentProgress = _updateSectionProgress(
          progress: currentProgress,
          sectionId: sectionId,
          allTopicsCompleted: true,
        );

        debugPrint(
            'Section quiz passed: Auto-completed ${section.topics.length} topics in $sectionId');
      }

      // Save updated progress
      await UserService.instance.updateUserProgress(currentProgress);

      // Notify all listeners immediately after saving
      notifyListeners();
      debugPrint('Section quiz progress saved and listeners notified');

      debugPrint(
          'Section quiz completed: $sectionId - ${passed ? "PASSED" : "FAILED"} (${(result.scorePercentage * 100).round()}%)');
    } catch (e) {
      debugPrint('Error recording section quiz completion: $e');
      rethrow;
    }
  }

  /// Initialize section progress data for current user
  ///
  /// This ensures all sections have proper progress tracking data
  /// and creates missing entries with default values.
  Future<void> initializeSectionProgress() async {
    try {
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) return;

      final sections = LearningContentRepository.getAllSections();
      var currentProgress = currentUser.progress;
      bool hasUpdates = false;

      // Ensure all sections have progress data
      for (final section in sections) {
        if (!currentProgress.sectionProgress.containsKey(section.id)) {
          final newSectionProgress = Map<String, SectionProgress>.from(
              currentProgress.sectionProgress);

          // Count already completed topics for this section
          int completedTopics = 0;
          for (final topic in section.topics) {
            if (currentProgress.completedTopics.contains(topic.id)) {
              completedTopics++;
            }
          }

          newSectionProgress[section.id] = SectionProgress(
            topicsCompleted: completedTopics,
            totalTopics: section.totalTopics,
            sectionQuizCompleted:
                currentProgress.completedSections.contains(section.id),
          );

          currentProgress = UserProgress(
            sectionProgress: newSectionProgress,
            completedTopics: currentProgress.completedTopics,
            completedSections: currentProgress.completedSections,
            totalQuizzesTaken: currentProgress.totalQuizzesTaken,
            totalQuizzesPassed: currentProgress.totalQuizzesPassed,
          );

          hasUpdates = true;
        }
      }

      // Save if there were any updates
      if (hasUpdates) {
        final newProgress = UserProgress(
          sectionProgress: currentProgress.sectionProgress,
          completedTopics: currentProgress.completedTopics,
          completedSections: currentProgress.completedSections,
          totalQuizzesTaken: currentProgress.totalQuizzesTaken,
          totalQuizzesPassed: currentProgress.totalQuizzesPassed,
        );
        await UserService.instance.updateUserProgress(newProgress);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing section progress: $e');
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

      // Update topic completion - using existing method from user.dart
      currentProgress = currentProgress.completeTopicQuiz(topicId, passed);

      // Update section progress for ALL sections that contain this topic
      // This ensures we don't miss updates when sectionId is not provided
      final sectionForTopic = _findSectionContainingTopic(topicId);
      if (sectionForTopic != null) {
        currentProgress = _updateSectionProgress(
          progress: currentProgress,
          sectionId: sectionForTopic.id,
          topicId: topicId,
          passed: passed,
        );
      } else if (sectionId != null) {
        // Fallback to provided sectionId if topic lookup fails
        currentProgress = _updateSectionProgress(
          progress: currentProgress,
          sectionId: sectionId,
          topicId: topicId,
          passed: passed,
        );
      }

      // Save updated progress
      await UserService.instance.updateUserProgress(currentProgress);

      // Notify all listeners immediately after saving
      notifyListeners();
      debugPrint('Progress saved and listeners notified');
    } catch (e) {
      debugPrint('Error updating topic completion: $e');
      rethrow;
    }
  }

  /// Forces a refresh of progress data from storage
  Future<void> refreshProgress() async {
    try {
      await initializeSectionProgress();
    } catch (e) {
      debugPrint('Error refreshing progress: $e');
    }
  }

  /// Find which section contains a specific topic
  LearningSection? _findSectionContainingTopic(String topicId) {
    final sections = LearningContentRepository.getAllSections();
    for (final section in sections) {
      for (final topic in section.topics) {
        if (topic.id == topicId) {
          return section;
        }
      }
    }
    return null;
  }

  /// Updates section-level progress calculations
  /// ENHANCED: Support for auto-completing all topics when section quiz passed
  UserProgress _updateSectionProgress({
    required UserProgress progress,
    required String sectionId,
    String? topicId,
    bool? passed,
    bool allTopicsCompleted = false,
  }) {
    try {
      // Get the section to find total topics
      final section = _findSectionById(sectionId);

      if (section == null) {
        debugPrint('Warning: Could not find section $sectionId');
        return progress;
      }

      // Count completed topics in this section
      int completedTopics = 0;
      if (allTopicsCompleted) {
        // All topics are completed (section quiz passed)
        completedTopics = section.totalTopics;
      } else {
        // Count individually
        for (final topic in section.topics) {
          if (progress.completedTopics.contains(topic.id)) {
            completedTopics++;
          }
        }
      }

      // Create updated section progress
      final newSectionProgress = SectionProgress(
        topicsCompleted: completedTopics,
        totalTopics: section.totalTopics,
        sectionQuizCompleted: progress.completedSections.contains(sectionId),
      );

      // Update the progress with new section data
      final updatedSectionProgress =
          Map<String, SectionProgress>.from(progress.sectionProgress);
      updatedSectionProgress[sectionId] = newSectionProgress;

      // Create new UserProgress with updated section data
      return UserProgress(
        sectionProgress: updatedSectionProgress,
        completedTopics: progress.completedTopics,
        completedSections: progress.completedSections,
        totalQuizzesTaken: progress.totalQuizzesTaken,
        totalQuizzesPassed: progress.totalQuizzesPassed,
      );
    } catch (e) {
      debugPrint('Error updating section progress: $e');
      return progress;
    }
  }

  /// Find a section by its ID
  LearningSection? _findSectionById(String sectionId) {
    final sections = LearningContentRepository.getAllSections();
    for (final section in sections) {
      if (section.id == sectionId) {
        return section;
      }
    }
    return null;
  }

  /// Gets current progress for a specific section
  Future<SectionProgress> getSectionProgressAsync(String sectionId) async {
    try {
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) {
        return _getDefaultSectionProgress(sectionId);
      }

      return currentUser.progress.getSectionProgress(sectionId);
    } catch (e) {
      debugPrint('Error getting section progress: $e');
      return _getDefaultSectionProgress(sectionId);
    }
  }

  /// Get default section progress (used for fallback)
  SectionProgress _getDefaultSectionProgress(String sectionId) {
    final section = _findSectionById(sectionId);
    return SectionProgress(
      topicsCompleted: 0,
      totalTopics: section?.totalTopics ?? 0,
      sectionQuizCompleted: false,
    );
  }
}
