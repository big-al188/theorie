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
  /// FIXED: Updated to match the calling signature
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
  /// FIXED: Updated to match the calling signature
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
      );
    }
  }

  /// Navigate to an implemented section quiz
  static Future<void> _navigateToImplementedSectionQuiz(
    BuildContext context,
    LearningSection section,
    QuizController quizController,
  ) async {
    try {
      // Show loading indicator
      _showLoadingDialog(context);

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

      // UPDATED: Start the quiz with section context for future progress tracking
      await quizController.startQuiz(
        questions: session.questions,
        quizType: session.quizType,
        sectionId:
            section.id, // ADDED: Pass section ID for future progress tracking
        title: session.title,
        description: session.description,
        allowSkip: session.allowSkip,
        allowReview: session.allowReview,
        timeLimit: session.timeLimit,
        passingScore: session.passingScore,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to quiz page
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
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to start quiz: $e');
      }
    }
  }

  /// Navigate to an implemented topic quiz
  static Future<void> _navigateToImplementedTopicQuiz(
    BuildContext context,
    LearningTopic topic,
    LearningSection section,
    QuizController quizController,
  ) async {
    try {
      // Show loading indicator
      _showLoadingDialog(context);

      // Generate quiz session with appropriate configuration
      final questionCount =
          _generator.getTopicQuestionCount(section.id, topic.id);
      final config = QuizGenerationConfig(
        questionCount: questionCount, // Use all available questions
        timeLimit: _getTopicTimeLimit(questionCount),
        allowSkip: true,
        allowReview: true,
        passingScore: 0.75, // Higher passing score for topic quizzes
      );

      final session = _generator.createTopicQuizSession(
        sectionId: section.id,
        topicId: topic.id,
        config: config,
      );

      // UPDATED: Start the quiz with topic and section context for future progress tracking
      await quizController.startQuiz(
        questions: session.questions,
        quizType: session.quizType,
        topicId: topic.id, // ADDED: Pass topic ID for future progress tracking
        sectionId:
            section.id, // ADDED: Pass section ID for future progress tracking
        title: session.title,
        description: session.description,
        allowSkip: session.allowSkip,
        allowReview: session.allowReview,
        timeLimit: session.timeLimit,
        passingScore: session.passingScore,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to quiz page
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
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to start quiz: $e');
      }
    }
  }

  /// Navigate to placeholder quiz page (for non-implemented sections)
  static Future<void> _navigateToPlaceholderQuiz({
    required BuildContext context,
    required String title,
    required String description,
    String? topicId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizPlaceholderPage(
          title: title,
          description: description,
          topicId: topicId,
        ),
      ),
    );
  }

  /// Show loading dialog
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Preparing your quiz...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Error'),
        content: Text(message),
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
class QuizPlaceholderPage extends StatelessWidget {
  final String title;
  final String description;
  final String? topicId;

  const QuizPlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    this.topicId,
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'The quiz system will include:\n'
                '• Interactive questions\n'
                '• Progress tracking\n'
                '• Detailed feedback\n'
                '• Adaptive difficulty',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange.shade800,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Learning'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
