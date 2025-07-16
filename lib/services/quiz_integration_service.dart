// lib/services/quiz_integration_service.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/unified_quiz_generator.dart';
import '../models/learning/learning_content.dart';
import '../models/quiz/quiz_question.dart';
import '../models/quiz/quiz_session.dart';
import '../views/pages/quiz_page.dart';

/// Service for integrating quiz functionality with learning content
///
/// This service provides a bridge between the learning system and quiz system,
/// handling navigation, session management, and quiz configuration.
class QuizIntegrationService {
  static final UnifiedQuizGenerator _generator = UnifiedQuizGenerator();

  /// Navigate to section quiz
  /// ENHANCED: Added proper error handling and cleanup
  static Future<void> navigateToSectionQuiz({
    required BuildContext context,
    required LearningSection section,
    required QuizController quizController,
  }) async {
    if (isSectionQuizImplemented(section.id)) {
      await _navigateToImplementedSectionQuiz(context, section, quizController);
    } else {
      await _navigateToPlaceholderQuiz(
        context: context,
        title: '${section.title} Section Quiz',
        description:
            'A comprehensive quiz covering all topics in ${section.title}',
      );
    }
  }

  /// Navigate to topic quiz
  /// ENHANCED: Added proper error handling and cleanup
  static Future<void> navigateToTopicQuiz({
    required BuildContext context,
    required LearningTopic topic,
    required LearningSection section,
    required QuizController quizController,
  }) async {
    if (isTopicQuizImplemented(section.id, topic.id)) {
      await _navigateToImplementedTopicQuiz(
          context, topic, section, quizController);
    } else {
      await _navigateToPlaceholderQuiz(
        context: context,
        title: '${topic.title} Quiz',
        description: topic.description,
        topicId: topic.id,
        sectionId: section.id,
      );
    }
  }

  /// Navigate to an implemented section quiz
  /// ENHANCED: Added comprehensive error handling and safe dialog operations
  static Future<void> _navigateToImplementedSectionQuiz(
    BuildContext context,
    LearningSection section,
    QuizController quizController,
  ) async {
    bool dialogShown = false;

    try {
      // Check if context is still valid before showing dialog
      if (!context.mounted) return;

      // Show loading indicator
      _showLoadingDialog(context);
      dialogShown = true;

      // Generate quiz session with appropriate configuration
      final config = QuizGenerationConfig(
        questionCount: _getSectionQuestionCount(section.id),
        timeLimit: _getSectionTimeLimit(section.id),
        allowSkip: true,
        allowReview: true,
        passingScore: 0.7,
      );

      final session = _generator.createSectionQuizSession(
        sectionId: section.id,
        config: config,
      );

      // Check if context is still valid before starting quiz
      if (!context.mounted) {
        _safeCloseDialog(context, dialogShown);
        return;
      }

      // Start the quiz with section context for progress tracking
      await quizController.startQuiz(
        questions: session.questions,
        quizType: session.quizType,
        sectionId: section.id,
        title: session.title,
        description: session.description,
        allowSkip: session.allowSkip,
        allowReview: session.allowReview,
        timeLimit: session.timeLimit,
        passingScore: session.passingScore,
      );

      // Close loading dialog before navigation
      _safeCloseDialog(context, dialogShown);
      dialogShown = false;

      // Navigate to quiz page only if context is still valid
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizPage(
              title: session.title,
              showAppBar: true,
            ),
          ),
        );
      }
    } catch (e) {
      // Always close loading dialog on error
      _safeCloseDialog(context, dialogShown);

      // Show error only if context is still valid
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to start quiz: $e');
      }

      // Clean up quiz controller state if needed
      try {
        if (quizController.hasActiveSession) {
          await quizController.abandonQuiz();
        }
      } catch (cleanupError) {
        // Log cleanup error but don't rethrow
        print('Error during quiz cleanup: $cleanupError');
      }
    }
  }

  /// Navigate to an implemented topic quiz
  /// ENHANCED: Added comprehensive error handling and safe dialog operations
  static Future<void> _navigateToImplementedTopicQuiz(
    BuildContext context,
    LearningTopic topic,
    LearningSection section,
    QuizController quizController,
  ) async {
    bool dialogShown = false;

    try {
      // Check if context is still valid before showing dialog
      if (!context.mounted) return;

      // Show loading indicator
      _showLoadingDialog(context);
      dialogShown = true;

      // Generate quiz session with appropriate configuration
      final questionCount =
          _generator.getTopicQuestionCount(section.id, topic.id);
      final config = QuizGenerationConfig(
        questionCount: questionCount,
        timeLimit: _getTopicTimeLimit(questionCount),
        allowSkip: true,
        allowReview: true,
        passingScore: 0.75, // Slightly higher for individual topics
      );

      final session = _generator.createTopicQuizSession(
        sectionId: section.id,
        topicId: topic.id,
        config: config,
      );

      // Check if context is still valid before starting quiz
      if (!context.mounted) {
        _safeCloseDialog(context, dialogShown);
        return;
      }

      // Start the quiz with both topic and section context
      await quizController.startQuiz(
        questions: session.questions,
        quizType: session.quizType,
        topicId: topic.id,
        sectionId: section.id,
        title: session.title,
        description: session.description,
        allowSkip: session.allowSkip,
        allowReview: session.allowReview,
        timeLimit: session.timeLimit,
        passingScore: session.passingScore,
      );

      // Close loading dialog before navigation
      _safeCloseDialog(context, dialogShown);
      dialogShown = false;

      // Navigate to quiz page only if context is still valid
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizPage(
              title: session.title,
              showAppBar: true,
            ),
          ),
        );
      }
    } catch (e) {
      // Always close loading dialog on error
      _safeCloseDialog(context, dialogShown);

      // Show error only if context is still valid
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to start quiz: $e');
      }

      // Clean up quiz controller state if needed
      try {
        if (quizController.hasActiveSession) {
          await quizController.abandonQuiz();
        }
      } catch (cleanupError) {
        // Log cleanup error but don't rethrow
        print('Error during quiz cleanup: $cleanupError');
      }
    }
  }

  /// Navigate to placeholder quiz for non-implemented content
  static Future<void> _navigateToPlaceholderQuiz({
    required BuildContext context,
    required String title,
    required String description,
    String? topicId,
    String? sectionId,
  }) async {
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizPlaceholderPage(
          title: title,
          description: description,
          topicId: topicId,
          sectionId: sectionId,
        ),
      ),
    );
  }

  /// ENHANCED: Safe loading dialog that prevents infinite loading
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false, // Prevent back button dismissal
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading Quiz...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your questions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ENHANCED: Safe dialog closure that prevents errors
  static void _safeCloseDialog(BuildContext context, bool dialogShown) {
    if (!dialogShown || !context.mounted) return;

    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      // Log error but don't rethrow - dialog might already be closed
      print('Error closing dialog: $e');
    }
  }

  /// ENHANCED: Enhanced error dialog with better UX
  static void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Quiz Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unable to start the quiz:'),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Text(
                'Please try again or contact support if the problem persists.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Get appropriate question count for a section quiz
  static int _getSectionQuestionCount(String sectionId) {
    switch (sectionId) {
      case 'introduction':
        return 12; // 4 questions per topic * 3 topics
      case 'fundamentals':
        return 15; // More questions for larger sections
      default:
        return 10; // Default fallback
    }
  }

  /// Get appropriate time limit for a section quiz
  static int _getSectionTimeLimit(String sectionId) {
    switch (sectionId) {
      case 'introduction':
        return 15; // 15 minutes for introduction
      case 'fundamentals':
        return 20; // More time for fundamentals
      default:
        return 12; // Default fallback
    }
  }

  /// Get appropriate time limit for a topic quiz based on question count
  static int _getTopicTimeLimit(int questionCount) {
    // Approximately 1.5 minutes per question
    return (questionCount * 1.5).ceil().clamp(5, 15);
  }

  /// Check if a section has quiz implementation
  static bool isSectionQuizImplemented(String sectionId) {
    return _generator.isSectionImplemented(sectionId);
  }

  /// Check if a topic has quiz implementation
  static bool isTopicQuizImplemented(String sectionId, String topicId) {
    return _generator.isTopicImplemented(sectionId, topicId);
  }

  /// Get quiz statistics for a section
  static Map<String, dynamic> getSectionQuizStats(String sectionId) {
    return _generator.getSectionStats(sectionId);
  }

  /// Get the number of questions available for a topic
  static int getTopicQuestionCount(String sectionId, String topicId) {
    return _generator.getTopicQuestionCount(sectionId, topicId);
  }
}

/// Placeholder quiz page for non-implemented sections
/// ENHANCED: Improved styling to match current app theme
class QuizPlaceholderPage extends StatelessWidget {
  final String title;
  final String description;
  final String? topicId;
  final String? sectionId;

  const QuizPlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    this.topicId,
    this.sectionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Coming Soon!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'This quiz is currently under development. '
                'Check back soon for interactive music theory questions!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
