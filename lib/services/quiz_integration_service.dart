// lib/services/quiz_integration_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/unified_quiz_generator.dart';
import '../models/learning/learning_content.dart';
import '../models/quiz/quiz_question.dart';
import '../models/quiz/quiz_session.dart';
import '../views/pages/quiz_page.dart';
import '../views/pages/learning_topics_page.dart';

/// Service for integrating quiz functionality with learning content
///
/// This service provides a bridge between the learning system and quiz system,
/// handling navigation, session management, and quiz configuration.
class QuizIntegrationService {
  static final UnifiedQuizGenerator _generator = UnifiedQuizGenerator();

  /// Navigate to section quiz
  static Future<void> navigateToSectionQuiz({
    required BuildContext context,
    required LearningSection section,
    required QuizController quizController,
  }) async {
    if (kDebugMode) {
      debugPrint('🚀 [QuizIntegration] Navigating to section quiz: ${section.id}');
    }
    
    if (isSectionQuizImplemented(section.id)) {
      await _navigateToImplementedSectionQuiz(context, section, quizController);
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ [QuizIntegration] Section ${section.id} not implemented, showing placeholder');
      }
      await _navigateToPlaceholderQuiz(
        context: context,
        title: '${section.title} Section Quiz',
        description:
            'A comprehensive quiz covering all topics in ${section.title}',
        section: section,
      );
    }
  }

  /// Navigate to topic quiz
  static Future<void> navigateToTopicQuiz({
    required BuildContext context,
    required LearningTopic topic,
    required LearningSection section,
    required QuizController quizController,
  }) async {
    if (kDebugMode) {
      debugPrint('🚀 [QuizIntegration] Navigating to topic quiz: ${section.id}/${topic.id}');
    }
    
    final isImplemented = isTopicQuizImplemented(section.id, topic.id);
    final questionCount = getTopicQuestionCount(section.id, topic.id);
    
    if (kDebugMode) {
      debugPrint('📊 [QuizIntegration] Topic implementation check:');
      debugPrint('   - Section: ${section.id}');
      debugPrint('   - Topic: ${topic.id}');
      debugPrint('   - Implemented: $isImplemented');
      debugPrint('   - Question Count: $questionCount');
    }
    
    if (isImplemented && questionCount > 0) {
      if (kDebugMode) {
        debugPrint('✅ [QuizIntegration] Starting implemented topic quiz');
      }
      await _navigateToImplementedTopicQuiz(
          context, topic, section, quizController);
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ [QuizIntegration] Topic ${section.id}/${topic.id} not implemented, showing placeholder');
        debugPrint('   - Reason: implemented=$isImplemented, questions=$questionCount');
      }
      await _navigateToPlaceholderQuiz(
        context: context,
        title: '${topic.title} Quiz',
        description: topic.description,
        topicId: topic.id,
        sectionId: section.id,
        section: section,
        topic: topic,
      );
    }
  }

  /// Navigate to an implemented section quiz with proper error handling
  static Future<void> _navigateToImplementedSectionQuiz(
    BuildContext context,
    LearningSection section,
    QuizController quizController,
  ) async {
    try {
      // Check if context is still valid before starting
      if (!context.mounted) {
        debugPrint('❌ [QuizIntegration] Context not mounted for section quiz');
        return;
      }

      // Generate quiz session with appropriate configuration
      final config = QuizGenerationConfig(
        questionCount: _getSectionQuestionCount(section.id),
        timeLimit: _getSectionTimeLimit(section.id),
        allowSkip: true,
        allowReview: true,
        passingScore: 0.7,
      );

      if (kDebugMode) {
        debugPrint('⚙️ [QuizIntegration] Creating section quiz session with config:');
        debugPrint('   - Question Count: ${config.questionCount}');
        debugPrint('   - Time Limit: ${config.timeLimit}');
      }

      final session = _generator.createSectionQuizSession(
        sectionId: section.id,
        config: config,
      );

      // Check if context is still valid before starting quiz
      if (!context.mounted) {
        debugPrint('❌ [QuizIntegration] Context not mounted after session creation');
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

      // Navigate to quiz page with proper route setup
      if (context.mounted) {
        // Store the current route for proper return navigation
        final currentRoute = ModalRoute.of(context);
        debugPrint(
            'Starting section quiz from: ${currentRoute?.settings.name}');

        await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => QuizPage(
              title: session.title,
              showAppBar: true,
              section: section, // Pass section context for proper navigation
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            settings: RouteSettings(
              name: '/quiz/section/${section.id}',
              arguments: {
                'section': section,
                'returnRoute':
                    currentRoute?.settings.name ?? '/learning_topics',
                'canPop': true,
              },
            ),
          ),
        );

        // Ensure we're back on the correct page after quiz
        if (context.mounted) {
          debugPrint(
              'Section quiz completed, ensuring proper return navigation');

          // If we don't have a proper route, force navigation to learning topics
          if (currentRoute?.settings.name == null ||
              !Navigator.of(context).canPop()) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LearningTopicsPage(section: section),
                settings: const RouteSettings(name: '/learning_topics'),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [QuizIntegration] Error starting section quiz: $e');
      debugPrint('Stack trace: $stackTrace');

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
        debugPrint('Error during quiz cleanup: $cleanupError');
      }
    }
  }

  /// Navigate to an implemented topic quiz with proper error handling
  static Future<void> _navigateToImplementedTopicQuiz(
    BuildContext context,
    LearningTopic topic,
    LearningSection section,
    QuizController quizController,
  ) async {
    try {
      // Check if context is still valid before starting
      if (!context.mounted) {
        debugPrint('❌ [QuizIntegration] Context not mounted for topic quiz');
        return;
      }

      // Generate quiz session with appropriate configuration
      final questionCount =
          _generator.getTopicQuestionCount(section.id, topic.id);
      
      if (kDebugMode) {
        debugPrint('📊 [QuizIntegration] Topic quiz details:');
        debugPrint('   - Section: ${section.id}');
        debugPrint('   - Topic: ${topic.id}');
        debugPrint('   - Available Questions: $questionCount');
      }
      
      final config = QuizGenerationConfig(
        questionCount: questionCount,
        timeLimit: _getTopicTimeLimit(questionCount),
        allowSkip: true,
        allowReview: true,
        passingScore: 0.75, // Slightly higher for individual topics
      );

      if (kDebugMode) {
        debugPrint('⚙️ [QuizIntegration] Creating topic quiz session with config:');
        debugPrint('   - Question Count: ${config.questionCount}');
        debugPrint('   - Time Limit: ${config.timeLimit}');
      }

      final session = _generator.createTopicQuizSession(
        sectionId: section.id,
        topicId: topic.id,
        config: config,
      );

      if (kDebugMode) {
        debugPrint('✅ [QuizIntegration] Session created successfully:');
        debugPrint('   - Session ID: ${session.id}');
        debugPrint('   - Title: ${session.title}');
        debugPrint('   - Questions: ${session.questions.length}');
        debugPrint('   - Quiz Type: ${session.quizType}');
      }

      // Check if context is still valid before starting quiz
      if (!context.mounted) {
        debugPrint('❌ [QuizIntegration] Context not mounted after session creation');
        return;
      }

      // Start the quiz with both topic and section context
      if (kDebugMode) {
        debugPrint('🎯 [QuizIntegration] Starting quiz controller...');
      }
      
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

      if (kDebugMode) {
        debugPrint('✅ [QuizIntegration] Quiz controller started successfully');
      }

      // Navigate to quiz page with proper route setup
      if (context.mounted) {
        // Store the current route for proper return navigation
        final currentRoute = ModalRoute.of(context);
        debugPrint('Starting topic quiz from: ${currentRoute?.settings.name}');

        if (kDebugMode) {
          debugPrint('🧭 [QuizIntegration] Navigating to QuizPage...');
        }

        await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => QuizPage(
              title: session.title,
              showAppBar: true,
              section: section, // Pass section context for proper navigation
              topic: topic, // Pass topic context for additional info
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            settings: RouteSettings(
              name: '/quiz/topic/${section.id}/${topic.id}',
              arguments: {
                'section': section,
                'topic': topic,
                'returnRoute':
                    currentRoute?.settings.name ?? '/learning_topics',
                'canPop': true,
              },
            ),
          ),
        );

        // Ensure we're back on the correct page after quiz
        if (context.mounted) {
          debugPrint('Topic quiz completed, ensuring proper return navigation');

          // If we don't have a proper route, force navigation to learning topics
          if (currentRoute?.settings.name == null ||
              !Navigator.of(context).canPop()) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LearningTopicsPage(section: section),
                settings: const RouteSettings(name: '/learning_topics'),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [QuizIntegration] Error starting topic quiz: $e');
      debugPrint('Stack trace: $stackTrace');

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
        debugPrint('Error during quiz cleanup: $cleanupError');
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
    LearningSection? section,
    LearningTopic? topic,
  }) async {
    if (!context.mounted) return;

    if (kDebugMode) {
      debugPrint('🚧 [QuizIntegration] Showing placeholder for: $title');
    }

    // Store current route for proper return
    final currentRoute = ModalRoute.of(context);
    debugPrint('Starting placeholder quiz from: ${currentRoute?.settings.name}');

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuizPlaceholderPage(
          title: title,
          description: description,
          topicId: topicId,
          sectionId: sectionId,
          section: section,
          topic: topic,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        settings: RouteSettings(
          name: '/quiz/placeholder/${sectionId ?? 'unknown'}',
          arguments: {
            'section': section,
            'topic': topic,
            'returnRoute': currentRoute?.settings.name ?? '/learning_topics',
            'canPop': true,
          },
        ),
      ),
    );
  }

  /// Show error dialog with improved styling
  static void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Quiz Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
    try {
      final isImplemented = _generator.isSectionImplemented(sectionId);
      final questionCount = _generator.getSectionQuestionCount(sectionId);
      
      if (kDebugMode) {
        debugPrint('🔍 [QuizIntegration] Section implementation check for $sectionId:');
        debugPrint('   - Generator says implemented: $isImplemented');
        debugPrint('   - Question count: $questionCount');
        debugPrint('   - Final result: ${isImplemented && questionCount > 0}');
      }
      
      return isImplemented && questionCount > 0;
    } catch (e) {
      debugPrint('❌ [QuizIntegration] Error checking section implementation: $e');
      return false;
    }
  }

  /// Check if a topic has quiz implementation
  static bool isTopicQuizImplemented(String sectionId, String topicId) {
    try {
      final isImplemented = _generator.isTopicImplemented(sectionId, topicId);
      final questionCount = _generator.getTopicQuestionCount(sectionId, topicId);
      
      if (kDebugMode) {
        debugPrint('🔍 [QuizIntegration] Topic implementation check for $sectionId/$topicId:');
        debugPrint('   - Generator says implemented: $isImplemented');
        debugPrint('   - Question count: $questionCount');
        debugPrint('   - Final result: ${isImplemented && questionCount > 0}');
      }
      
      return isImplemented && questionCount > 0;
    } catch (e) {
      debugPrint('❌ [QuizIntegration] Error checking topic implementation: $e');
      return false;
    }
  }

  /// Get quiz statistics for a section
  static Map<String, dynamic> getSectionQuizStats(String sectionId) {
    try {
      return _generator.getSectionStats(sectionId);
    } catch (e) {
      debugPrint('❌ [QuizIntegration] Error getting section stats: $e');
      return {};
    }
  }

  /// Get the number of questions available for a topic
  static int getTopicQuestionCount(String sectionId, String topicId) {
    try {
      final count = _generator.getTopicQuestionCount(sectionId, topicId);
      if (kDebugMode) {
        debugPrint('📊 [QuizIntegration] Question count for $sectionId/$topicId: $count');
      }
      return count;
    } catch (e) {
      debugPrint('❌ [QuizIntegration] Error getting topic question count: $e');
      return 0;
    }
  }

  /// Get the number of questions available for a section
  static int getSectionQuestionCount(String sectionId) {
    try {
      final count = _generator.getSectionQuestionCount(sectionId);
      if (kDebugMode) {
        debugPrint('📊 [QuizIntegration] Section question count for $sectionId: $count');
      }
      return count;
    } catch (e) {
      debugPrint('❌ [QuizIntegration] Error getting section question count: $e');
      return 0;
    }
  }

  /// Get detailed topic statistics
  static Map<String, dynamic> getTopicStats(String sectionId, String topicId) {
    try {
      return _generator.getTopicStats(sectionId, topicId);
    } catch (e) {
      debugPrint('❌ [QuizIntegration] Error getting topic stats: $e');
      return {};
    }
  }

  /// Test method for debugging quiz integration
  static void debugQuizIntegration() {
    if (!kDebugMode) return;
    
    debugPrint('🔍 [QuizIntegration] DEBUGGING QUIZ INTEGRATION');
    debugPrint('===============================================');
    
    try {
      // Test scale strip specifically
      const sectionId = 'introduction';
      const topicId = 'scale-strip-quiz';
      
      debugPrint('\n📊 Testing Scale Strip Integration:');
      
      final isImplemented = isTopicQuizImplemented(sectionId, topicId);
      final questionCount = getTopicQuestionCount(sectionId, topicId);
      final sectionStats = getSectionQuizStats(sectionId);
      
      debugPrint('   - Topic implemented: $isImplemented');
      debugPrint('   - Question count: $questionCount');
      debugPrint('   - Section has scale strip: ${sectionStats['hasScaleStripQuestions']}');
      debugPrint('   - Section total questions: ${sectionStats['totalQuestions']}');
      
      if (isImplemented && questionCount > 0) {
        debugPrint('✅ Scale strip quiz should work!');
      } else {
        debugPrint('❌ Scale strip quiz will show placeholder');
        debugPrint('   - Reason: implemented=$isImplemented, questions=$questionCount');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Debug integration failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}

/// Placeholder quiz page for non-implemented sections
class QuizPlaceholderPage extends StatelessWidget {
  final String title;
  final String description;
  final String? topicId;
  final String? sectionId;
  final LearningSection? section;
  final LearningTopic? topic;

  const QuizPlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    this.topicId,
    this.sectionId,
    this.section,
    this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _navigateBack(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This quiz is currently under development. Check back soon for engaging questions on: $title',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _navigateBack(context),
                child: const Text('Back to Learning'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => QuizIntegrationService.debugQuizIntegration(),
                  child: const Text('Debug Integration'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate back with proper handling
  void _navigateBack(BuildContext context) {
    try {
      debugPrint('Placeholder navigating back');

      // If we have a section reference, navigate to the learning topics page
      if (section != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LearningTopicsPage(section: section!),
            settings: const RouteSettings(name: '/learning_topics'),
          ),
          (route) => route.isFirst,
        );
      } else {
        // Otherwise, try to pop normally
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // Last resort: go to home
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Placeholder navigation error: $e');
      // Final fallback
      try {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } catch (homeError) {
        debugPrint('Placeholder home navigation also failed: $homeError');
      }
    }
  }
}