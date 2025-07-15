// lib/views/pages/quiz_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../models/quiz/quiz_question.dart';
import '../../models/quiz/quiz_session.dart';
import '../../models/quiz/multiple_choice_question.dart';
import '../widgets/quiz/quiz_progress_bar.dart';
import '../widgets/quiz/multiple_choice_widget.dart';
import '../widgets/quiz/quiz_results_widget.dart';

/// Main page for taking quizzes
///
/// This page serves as the primary interface for quiz-taking, handling
/// the display of questions, progress tracking, navigation, and results.
/// It integrates with the QuizController to manage quiz state and flow.
class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    this.title,
    this.showAppBar = true,
  });

  /// Optional title override for the page
  final String? title;

  /// Whether to show the app bar
  final bool showAppBar;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showingResults = false;
  String? _lastFeedback;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizController>(
      builder: (context, quizController, child) {
        return Scaffold(
          appBar:
              widget.showAppBar ? _buildAppBar(context, quizController) : null,
          body: SafeArea(
            child: _buildBody(context, quizController),
          ),
        );
      },
    );
  }

  // FIXED: Updated to show proper title when showing results
  PreferredSizeWidget _buildAppBar(
      BuildContext context, QuizController controller) {
    String title = widget.title ?? 'Quiz';

    // Show results title when displaying results - THIS FIXES THE TITLE
    if (controller.isShowingResults) {
      title = 'Quiz Results';
    } else if (controller.hasActiveSession) {
      final session = controller.currentSession!;
      title = session.title ?? 'Quiz';
    }

    return AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _handleBackAction(context, controller),
      ),
    );
  }

  // FIXED: Now checks for results display - THIS IS THE KEY FIX
  Widget _buildBody(BuildContext context, QuizController controller) {
    // Show results if quiz is completed - THIS IS THE KEY FIX
    if (controller.isShowingResults) {
      return QuizResultsWidget(
        onRetakeQuiz: () => _handleRetakeQuiz(context, controller),
        onBackToMenu: () => _handleBackToMenu(context, controller),
      );
    }

    // Existing logic for active session
    if (!controller.hasActiveSession) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Setting up quiz...'),
          ],
        ),
      );
    }

    final session = controller.currentSession!;
    if (_showingResults) {
      return QuizResultsWidget(
        onRetakeQuiz: () => _handleRetakeQuiz(context, controller),
        onBackToMenu: () => _handleBackToMenu(context, controller),
      );
    }

    return _buildActiveQuizInterface(context, controller, session);
  }

  Widget _buildActiveQuizInterface(
      BuildContext context, QuizController controller, QuizSession session) {
    return Column(
      children: [
        // Progress bar
        if (session.totalQuestions > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: QuizProgressBar(
              current: session.currentQuestionIndex + 1,
              total: session.totalQuestions,
              timeRemaining: session.timeRemaining,
            ),
          ),

        // Feedback message
        if (_lastFeedback != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildFeedbackCard(context, _lastFeedback!),
          ),

        // Main question area
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildQuestionSection(context, controller),
            ),
          ),
        ),

        // Navigation controls
        _buildNavigationControls(context, controller, session),
      ],
    );
  }

  Widget _buildNavigationControls(
      BuildContext context, QuizController controller, QuizSession session) {
    final isAnswered =
        controller.isQuestionAnswered(session.currentQuestion.id);
    final hasNext = session.hasNextQuestion;
    final hasPrevious = session.hasPreviousQuestion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main action buttons
          Row(
            children: [
              // Skip button (if allowed)
              if (session.allowSkip) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleSkip(controller),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Next/Complete button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isAnswered
                      ? () => _handleNext(context, controller)
                      : null,
                  child: Text(
                    hasNext ? 'Next Question' : 'Complete Quiz',
                  ),
                ),
              ),
            ],
          ),

          // Previous button (if available)
          if (hasPrevious) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _handlePrevious(controller),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous Question'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, String feedback) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feedback,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _lastFeedback = null),
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(
      BuildContext context, QuizController controller) {
    final question = controller.currentQuestion!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildQuestionWidget(context, question, controller),
    );
  }

  Widget _buildQuestionWidget(
      BuildContext context, QuizQuestion question, QuizController controller) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question as MultipleChoiceQuestion,
          selectedAnswer: controller.getUserAnswerForQuestion(question.id),
          onAnswerSelected: (answer) =>
              _handleAnswerSubmission(controller, answer),
          enabled: !controller.isProcessingAnswer,
        );
      default:
        return _buildUnsupportedQuestionType(context, question);
    }
  }

  Widget _buildUnsupportedQuestionType(
      BuildContext context, QuizQuestion question) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'Unsupported Question Type',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Question type "${question.type.name}" is not yet implemented.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _handleAnswerSubmission(
      QuizController controller, dynamic answer) async {
    try {
      await controller.submitAnswer(answer, autoAdvance: false);
      _restartTransitionAnimations();

      setState(() {
        _lastFeedback = 'Answer submitted successfully!';
      });

      // Clear feedback after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _lastFeedback = null;
          });
        }
      });
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to submit answer: $e');
    }
  }

  // FIXED: Now properly handles quiz completion
  void _handleNext(BuildContext context, QuizController controller) async {
    try {
      if (controller.hasNextQuestion) {
        await controller.nextQuestion();
        _restartTransitionAnimations();
      } else {
        // Complete the quiz - the UI will automatically switch to results
        await controller.completeQuiz();
        // No need to manually set _showingResults since controller.isShowingResults handles this
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to proceed: $e');
    }
  }

  void _handlePrevious(QuizController controller) async {
    try {
      await controller.previousQuestion();
      _restartTransitionAnimations();
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to go to previous question: $e');
    }
  }

  void _handleSkip(QuizController controller) async {
    try {
      await controller.skipQuestion(autoAdvance: false);
      setState(() {
        _lastFeedback = 'Question skipped';
      });

      // Clear feedback after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _lastFeedback = null;
          });
        }
      });
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to skip question: $e');
    }
  }

  // ADDED: Helper methods for result navigation
  void _handleRetakeQuiz(BuildContext context, QuizController controller) {
    // Clear results and navigate back to allow starting a new quiz
    controller.clearResults();
    Navigator.of(context).pop();
  }

  void _handleBackToMenu(BuildContext context, QuizController controller) {
    controller.clearResults();
    Navigator.of(context).pop();
  }

  void _handleBackAction(BuildContext context, QuizController controller) {
    if (controller.isShowingResults) {
      _handleBackToMenu(context, controller);
    } else if (controller.hasActiveSession) {
      _showAbandonQuizDialog(context, controller);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showAbandonQuizDialog(BuildContext context, QuizController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Quiz?'),
        content: const Text(
          'Are you sure you want to abandon this quiz? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                await controller.abandonQuiz();
                if (mounted) {
                  Navigator.of(context).pop(); // Close quiz page
                }
              } catch (e) {
                _showErrorSnackbar(context, 'Failed to abandon quiz: $e');
              }
            },
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  void _restartTransitionAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
