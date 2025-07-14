import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_models.dart';
import '../models/question_models.dart';
import '../models/quiz_enums.dart';
import '../controllers/quiz_controller.dart';
import 'components/question_views/multiple_choice_view.dart';
import 'components/question_views/interactive_question_view.dart';
import 'components/widgets/quiz_progress_bar.dart';
import 'quiz_review_view.dart';
import 'quiz_landing_view.dart';

/// View for active quiz taking
class QuizActiveView extends StatefulWidget {
  const QuizActiveView({Key? key}) : super(key: key);

  @override
  State<QuizActiveView> createState() => _QuizActiveViewState();
}

class _QuizActiveViewState extends State<QuizActiveView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizController>(
      builder: (context, controller, child) {
        final quiz = controller.currentQuiz;
        
        if (quiz == null) {
          // No active quiz, return to landing
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => QuizLandingView(
                  sectionId: 'introduction', // Default section
                ),
              ),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _pageController ??= PageController(
          initialPage: controller.currentQuestionIndex,
        );

        return WillPopScope(
          onWillPop: () => _handleBackPress(controller),
          child: Scaffold(
            appBar: _buildAppBar(context, controller, quiz),
            body: SafeArea(
              child: Column(
                children: [
                  QuizProgressBar(
                    current: controller.currentQuestionIndex + 1,
                    total: controller.totalQuestions,
                    progress: controller.progress,
                  ),
                  Expanded(
                    child: _buildQuestionView(controller, quiz),
                  ),
                  _buildNavigationControls(context, controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    QuizController controller,
    Quiz quiz,
  ) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(quiz.metadata.title),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _handleExit(context, controller),
      ),
      actions: [
        if (quiz.status == QuizStatus.inProgress)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => _handlePause(context, controller),
            tooltip: 'Pause Quiz',
          ),
        IconButton(
          icon: const Icon(Icons.timer_outlined),
          onPressed: () => _showTimeDialog(context, quiz),
          tooltip: 'Time Elapsed',
        ),
      ],
    );
  }

  Widget _buildQuestionView(QuizController controller, Quiz quiz) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quiz.questions.length,
      itemBuilder: (context, index) {
        final question = quiz.questions[index];
        final answer = controller.getAnswerForQuestion(question.id);
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildQuestionWidget(
              question: question,
              answer: answer,
              onAnswerSubmit: (value) => _handleAnswerSubmit(
                controller,
                value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionWidget({
    required Question question,
    Answer? answer,
    required Function(dynamic) onAnswerSubmit,
  }) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceView(
          question: question as MultipleChoiceQuestion,
          selectedAnswer: answer?.value,
          onAnswerSelected: onAnswerSubmit,
          showFeedback: answer != null,
          isCorrect: answer?.isCorrect,
        );
        
      case QuestionType.scaleInteractive:
      case QuestionType.chordInteractive:
        return InteractiveQuestionView(
          question: question,
          previousAnswer: answer?.value,
          onAnswerSubmit: onAnswerSubmit,
          showFeedback: answer != null,
          feedback: answer?.feedback,
        );
        
      default:
        return Center(
          child: Text(
            'Question type ${question.type} not implemented',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
    }
  }

  Widget _buildNavigationControls(
    BuildContext context,
    QuizController controller,
  ) {
    final theme = Theme.of(context);
    final isLastQuestion = !controller.canGoNext;
    final currentAnswer = controller.currentQuestion != null
        ? controller.getAnswerForQuestion(controller.currentQuestion!.id)
        : null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (controller.canGoPrevious)
            OutlinedButton.icon(
              onPressed: () => _navigateToPrevious(controller),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            )
          else
            const SizedBox(width: 120),
          
          const Spacer(),
          
          if (controller.isSubmitting)
            const CircularProgressIndicator()
          else if (isLastQuestion && currentAnswer != null)
            FilledButton.icon(
              onPressed: () => _completeQuiz(context, controller),
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Quiz'),
            )
          else if (currentAnswer != null && controller.canGoNext)
            FilledButton.icon(
              onPressed: () => _navigateToNext(controller),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            )
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }

  Future<void> _handleAnswerSubmit(
    QuizController controller,
    dynamic answer,
  ) async {
    await controller.submitAnswer(answer);
    
    // Animate the feedback
    _animationController.reset();
    _animationController.forward();
  }

  void _navigateToNext(QuizController controller) {
    controller.nextQuestion();
    _pageController?.animateToPage(
      controller.currentQuestionIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _animationController.reset();
    _animationController.forward();
  }

  void _navigateToPrevious(QuizController controller) {
    controller.previousQuestion();
    _pageController?.animateToPage(
      controller.currentQuestionIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _completeQuiz(
    BuildContext context,
    QuizController controller,
  ) async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Quiz?'),
        content: Text(
          'You have answered ${controller.currentQuiz!.answers.length} '
          'out of ${controller.totalQuestions} questions.\n\n'
          'Are you ready to submit your quiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Review Answers'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit Quiz'),
          ),
        ],
      ),
    );

    if (shouldComplete == true && mounted) {
      try {
        final result = await controller.completeQuiz();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => QuizReviewView(
                quiz: controller.currentQuiz!,
                result: result,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing quiz: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<bool> _handleBackPress(QuizController controller) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Your progress will be saved and you can resume later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit & Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await controller.pauseQuiz();
      return true;
    }
    return false;
  }

  Future<void> _handleExit(
    BuildContext context,
    QuizController controller,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop('pause'),
            child: const Text('Save & Exit'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('abandon'),
            child: Text(
              'Abandon Quiz',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (result == 'pause') {
      await controller.pauseQuiz();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizLandingView(
              sectionId: controller.currentQuiz!.sectionId,
            ),
          ),
        );
      }
    } else if (result == 'abandon') {
      await controller.abandonQuiz();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const QuizLandingView(sectionId: 'introduction'),
          ),
        );
      }
    }
  }

  Future<void> _handlePause(
    BuildContext context,
    QuizController controller,
  ) async {
    await controller.pauseQuiz();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz paused. You can resume from the quiz menu.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizLandingView(
            sectionId: controller.currentQuiz!.sectionId,
          ),
        ),
      );
    }
  }

  void _showTimeDialog(BuildContext context, Quiz quiz) {
    final timeSpent = quiz.timeSpent;
    final minutes = timeSpent.inMinutes;
    final seconds = timeSpent.inSeconds % 60;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Elapsed'),
        content: Text(
          '$minutes:${seconds.toString().padLeft(2, '0')}\n\n'
          'Estimated time: ${quiz.metadata.estimatedMinutes} minutes',
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
}