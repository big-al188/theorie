// lib/views/pages/quiz_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../models/quiz/quiz_question.dart';
import '../../models/quiz/quiz_session.dart';
import '../../models/quiz/multiple_choice_question.dart'; // Add this import
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

  PreferredSizeWidget _buildAppBar(
      BuildContext context, QuizController controller) {
    String title = widget.title ?? 'Quiz';

    if (controller.hasActiveSession) {
      final session = controller.currentSession!;
      title = session.title ?? 'Quiz';
    }

    return AppBar(
      title: Text(title),
      elevation: 0,
      leading: _showingResults
          ? null
          : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _handleQuizExit(context, controller),
            ),
      actions: _buildAppBarActions(context, controller),
    );
  }

  List<Widget> _buildAppBarActions(
      BuildContext context, QuizController controller) {
    if (_showingResults || !controller.hasActiveSession) return [];

    return [
      if (controller.currentSession?.allowReview == true)
        IconButton(
          icon: const Icon(Icons.list_alt),
          onPressed: () => _showQuestionOverview(context, controller),
          tooltip: 'Question Overview',
        ),
      IconButton(
        icon: Icon(controller.currentSession?.status == QuizSessionStatus.paused
            ? Icons.play_arrow
            : Icons.pause),
        onPressed: () => _togglePause(context, controller),
        tooltip: controller.currentSession?.status == QuizSessionStatus.paused
            ? 'Resume Quiz'
            : 'Pause Quiz',
      ),
    ];
  }

  Widget _buildBody(BuildContext context, QuizController controller) {
    if (_showingResults) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: const QuizResultsWidget(),
      );
    }

    if (!controller.hasActiveSession) {
      return _buildNoActiveQuiz(context);
    }

    final session = controller.currentSession!;

    if (session.status == QuizSessionStatus.paused) {
      return _buildPausedState(context, controller);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildProgressSection(context, controller),
            Expanded(
              child: _buildQuestionSection(context, controller),
            ),
            _buildNavigationSection(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveQuiz(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Quiz',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a quiz to begin learning!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedState(BuildContext context, QuizController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pause_circle_outline,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Quiz Paused',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap resume to continue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _resumeQuiz(controller),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
      BuildContext context, QuizController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          QuizProgressBar(
            current: controller.currentQuestionIndex + 1,
            total: controller.totalQuestions,
            timeRemaining: controller.timeRemaining,
          ),
          if (_lastFeedback != null) ...[
            const SizedBox(height: 12),
            _buildFeedbackCard(context, _lastFeedback!),
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

  Widget _buildNavigationSection(
      BuildContext context, QuizController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.hasPreviousQuestion
                  ? () => _previousQuestion(controller)
                  : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 16),

          // Skip button (if allowed)
          if (controller.currentSession?.allowSkip == true)
            OutlinedButton(
              onPressed: () => _skipQuestion(controller),
              child: const Text('Skip'),
            ),
          if (controller.currentSession?.allowSkip == true)
            const SizedBox(width: 16),

          // Next/Finish button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleNextAction(controller),
              icon: Icon(controller.hasNextQuestion
                  ? Icons.arrow_forward
                  : Icons.check),
              label: Text(controller.hasNextQuestion ? 'Next' : 'Finish'),
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _handleAnswerSubmission(
      QuizController controller, dynamic answer) async {
    try {
      final result = await controller.submitAnswer(answer, autoAdvance: false);
      setState(() {
        _lastFeedback = result.feedback;
      });

      // Clear feedback after a delay
      if (_lastFeedback != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _lastFeedback = null);
          }
        });
      }
    } catch (e) {
      _showErrorMessage(context, 'Failed to submit answer: $e');
    }
  }

  Future<void> _handleNextAction(QuizController controller) async {
    if (controller.hasNextQuestion) {
      await _nextQuestion(controller);
    } else {
      await _finishQuiz(controller);
    }
  }

  Future<void> _nextQuestion(QuizController controller) async {
    try {
      await controller.nextQuestion();
      _resetAnimations();
    } catch (e) {
      _showErrorMessage(context, 'Failed to go to next question: $e');
    }
  }

  Future<void> _previousQuestion(QuizController controller) async {
    try {
      await controller.previousQuestion();
      _resetAnimations();
    } catch (e) {
      _showErrorMessage(context, 'Failed to go to previous question: $e');
    }
  }

  Future<void> _skipQuestion(QuizController controller) async {
    try {
      await controller.skipQuestion(autoAdvance: false);
      setState(() {
        _lastFeedback = 'Question skipped';
      });
    } catch (e) {
      _showErrorMessage(context, 'Failed to skip question: $e');
    }
  }

  Future<void> _finishQuiz(QuizController controller) async {
    try {
      final result = await controller.completeQuiz();
      setState(() {
        _showingResults = true;
        _lastFeedback = null;
      });
      _resetAnimations();
    } catch (e) {
      _showErrorMessage(context, 'Failed to finish quiz: $e');
    }
  }

  Future<void> _togglePause(
      BuildContext context, QuizController controller) async {
    try {
      if (controller.currentSession?.status == QuizSessionStatus.paused) {
        await controller.resumeQuiz();
      } else {
        await controller.pauseQuiz();
      }
    } catch (e) {
      _showErrorMessage(context, 'Failed to toggle pause: $e');
    }
  }

  Future<void> _resumeQuiz(QuizController controller) async {
    try {
      await controller.resumeQuiz();
    } catch (e) {
      _showErrorMessage(context, 'Failed to resume quiz: $e');
    }
  }

  void _handleQuizExit(BuildContext context, QuizController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.abandonQuiz();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showQuestionOverview(BuildContext context, QuizController controller) {
    // TODO: Implement question overview dialog
    _showErrorMessage(context, 'Question overview not yet implemented');
  }

  void _resetAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
