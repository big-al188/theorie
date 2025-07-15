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
  /// FIXED: Creates new UserProgress instead of using copyWith
  UserProgress _updateSectionProgress({
    required UserProgress progress,
    required String sectionId,
    required String topicId,
    required bool passed,
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
      for (final topic in section.topics) {
        if (progress.completedTopics.contains(topic.id)) {
          completedTopics++;
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

      // FIXED: Create new UserProgress instead of using copyWith
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
    try {
      return sections.firstWhere((section) => section.id == sectionId);
    } catch (e) {
      debugPrint('Section not found: $sectionId');
      return null;
    }
  }

  /// Initialize or refresh section progress for all sections
  Future<void> initializeSectionProgress() async {
    try {
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) return;

      var currentProgress = currentUser.progress;
      final sections = LearningContentRepository.getAllSections();

      // Initialize progress for all sections
      final updatedSectionProgress =
          Map<String, SectionProgress>.from(currentProgress.sectionProgress);

      bool hasChanges = false;

      for (final section in sections) {
        // Count completed topics in this section
        int completedTopics = 0;
        for (final topic in section.topics) {
          if (currentProgress.completedTopics.contains(topic.id)) {
            completedTopics++;
          }
        }

        // Create or update section progress
        final newSectionProgress = SectionProgress(
          topicsCompleted: completedTopics,
          totalTopics: section.totalTopics,
          sectionQuizCompleted:
              currentProgress.completedSections.contains(section.id),
        );

        final existingProgress = updatedSectionProgress[section.id];
        if (existingProgress == null ||
            existingProgress.topicsCompleted != completedTopics ||
            existingProgress.totalTopics != section.totalTopics) {
          updatedSectionProgress[section.id] = newSectionProgress;
          hasChanges = true;
        }
      }

      // Update progress if there were changes
      if (hasChanges) {
        // FIXED: Create new UserProgress instead of using copyWith
        final newProgress = UserProgress(
          sectionProgress: updatedSectionProgress,
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

  /// ADDED: Records section quiz completion
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

      // Update section quiz completion
      var currentProgress = currentUser.progress;
      currentProgress = currentProgress.completeSectionQuiz(sectionId, passed);

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

  /// Clears all progress data (for testing or reset functionality)
  Future<void> clearAllProgress() async {
    try {
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser != null) {
        // FIXED: Create new UserProgress instead of using copyWith
        final emptyProgress = UserProgress(
          sectionProgress: <String, SectionProgress>{},
          completedTopics: <String>{},
          completedSections: <String>{},
          totalQuizzesTaken: 0,
          totalQuizzesPassed: 0,
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
