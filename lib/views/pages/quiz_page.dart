// lib/views/pages/quiz_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../models/quiz/quiz_question.dart';
import '../../models/quiz/quiz_session.dart';
import '../../models/quiz/multiple_choice_question.dart';
import '../../constants/ui_constants.dart';
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

  Timer? _timer;
  final ScrollController _scrollController = ScrollController();

  // FIXED: Stable UI state management - prevent unnecessary rebuilds
  String? _lastFeedback;
  bool _isTransitioning = false;

  // FIXED: Store stable question data to prevent UI jumps
  String? _currentQuestionId;
  Map<String, dynamic>? _stableAnswerState;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startPeriodicUpdates();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      // FIXED: Start with no offset for first question
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // FIXED: Start both animations immediately for first question
    _fadeController.forward();
    _slideController.forward();
  }

  void _startPeriodicUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Only update if mounted and not transitioning
      if (mounted && !_isTransitioning) {
        final controller = Provider.of<QuizController>(context, listen: false);
        // Only notify listeners if there are actual timing updates to show
        if (controller.hasActiveSession && controller.timeRemaining != null) {
          setState(() {});
        }
      }
    });
  }

  // FIXED: Only restart animations during navigation, not answer selection
  void _restartTransitionAnimations() {
    if (!mounted) return;

    setState(() {
      _isTransitioning = true;
    });

    // FIXED: Set up slide animation for navigation transitions
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.reset();
    _slideController.reset();

    _fadeController.forward();
    _slideController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    });
  }

  // FIXED: Stable answer submission that doesn't trigger page rebuilds
  void _handleAnswerSubmission(
      QuizController controller, dynamic answer) async {
    if (controller.isProcessingAnswer) return;

    try {
      // FIXED: Don't trigger state changes during answer submission
      final questionId = controller.currentQuestion?.id;

      // Store answer state locally for stable UI
      _stableAnswerState = {
        'questionId': questionId,
        'answer': answer,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Submit answer without auto-advance to prevent UI jumping
      await controller.submitAnswer(answer, autoAdvance: false);

      // FIXED: Provide immediate feedback with fade in/out animation
      if (mounted) {
        setState(() {
          _lastFeedback = 'Answer submitted';
        });

        // FIXED: Use animation for smoother feedback display
        await _showFeedbackWithAnimation();
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to submit answer: $e');
    }
  }

  // FIXED: Add smooth feedback animation
  Future<void> _showFeedbackWithAnimation() async {
    // Keep feedback visible for 2 seconds, then fade out
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      setState(() {
        _lastFeedback = null;
      });
    }
  }

  // FIXED: Proper navigation handling that triggers animations only when needed
  void _handleNext(BuildContext context, QuizController controller) async {
    if (_isTransitioning) return;

    try {
      if (controller.hasNextQuestion) {
        await controller.nextQuestion();
        _restartTransitionAnimations(); // Only animate on navigation
      } else {
        await controller.completeQuiz();
        // Results will show automatically via controller state
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to proceed: $e');
    }
  }

  void _handlePrevious(QuizController controller) async {
    if (_isTransitioning) return;

    try {
      await controller.previousQuestion();
      _restartTransitionAnimations(); // Only animate on navigation
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to go to previous question: $e');
    }
  }

  void _handleSkip(QuizController controller) async {
    if (_isTransitioning) return;

    try {
      await controller.skipQuestion(autoAdvance: true);
      if (mounted) {
        setState(() {
          _lastFeedback = 'Question skipped';
        });

        // FIXED: Use same smooth feedback animation
        await _showFeedbackWithAnimation();
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to skip question: $e');
    }
  }

  void _handleRetakeQuiz(BuildContext context, QuizController controller) {
    controller.clearResults();
    Navigator.of(context).pop();
  }

  void _handleBackToMenu(BuildContext context, QuizController controller) {
    controller.clearResults();
    Navigator.of(context).pop();
  }

  // FIXED: Proper cleanup when exiting quiz early
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
            'Are you sure you want to exit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // FIXED: Properly clean up session before exiting
              _cleanupAndExit(context, controller);
            },
            child: const Text('Exit Quiz'),
          ),
        ],
      ),
    );
  }

  // FIXED: Proper cleanup method to prevent session conflicts
  void _cleanupAndExit(BuildContext context, QuizController controller) async {
    try {
      // Clear any active session to prevent conflicts
      if (controller.hasActiveSession) {
        await controller.abandonQuiz();
      }
      controller.clearResults();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // If cleanup fails, force clear and exit
      controller.clearResults();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTimeExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Time Expired'),
          ],
        ),
        content: const Text(
          'The quiz time limit has been reached. Your answers have been submitted automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {}); // Trigger rebuild to show results
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _timer?.cancel();
    _scrollController.dispose();
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

  Widget _buildBody(BuildContext context, QuizController controller) {
    if (controller.isShowingResults) {
      return QuizResultsWidget(
        onRetakeQuiz: () => _handleRetakeQuiz(context, controller),
        onBackToMenu: () => _handleBackToMenu(context, controller),
      );
    }

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

    // FIXED: Track question changes for stable UI
    final currentQuestionId = session.currentQuestion.id;
    if (_currentQuestionId != currentQuestionId) {
      _currentQuestionId = currentQuestionId;
      _stableAnswerState = null; // Reset answer state for new question
    }

    // Check for time expiration
    if (session.timeLimit != null && controller.isTimeExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTimeExpiredDialog();
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final deviceType = ResponsiveConstants.getDeviceType(screenWidth);

        return _buildQuizContent(context, controller, session, deviceType);
      },
    );
  }

  // FIXED: Stable quiz content that doesn't rebuild unnecessarily
  Widget _buildQuizContent(
    BuildContext context,
    QuizController controller,
    QuizSession session,
    DeviceType deviceType,
  ) {
    return Column(
      children: [
        // Fixed header that doesn't change during answer selection
        _buildStableHeader(context, session, deviceType),

        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16 : 24),
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildQuestionSection(context, controller),
                  ),
                );
              },
            ),
          ),
        ),

        // Fixed footer that only updates when navigation state changes
        _buildStableFooter(context, controller, session, deviceType),
      ],
    );
  }

  // FIXED: Stable header that shows progress without rebuilding content
  Widget _buildStableHeader(
      BuildContext context, QuizSession session, DeviceType deviceType) {
    return Container(
      padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // FIXED: Use correct QuizProgressBar parameters
          QuizProgressBar(
            current: session.currentQuestionIndex + 1,
            total: session.totalQuestions,
            timeRemaining: session.timeRemaining,
          ),

          // FIXED: Always reserve space for feedback to prevent layout shifts
          SizedBox(
            height: 40, // FIXED: Increased height to prevent text cutoff
            child: _lastFeedback != null
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8), // FIXED: Increased padding
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _lastFeedback!,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13, // FIXED: Slightly increased font size
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center, // FIXED: Center align text
                      ),
                    ),
                  )
                : const SizedBox.shrink(), // Empty space when no feedback
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(
      BuildContext context, QuizController controller) {
    final session = controller.currentSession!;
    final question = session.currentQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question counter
        Text(
          'Question ${session.currentQuestionIndex + 1} of ${session.totalQuestions}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),

        // Question text
        Text(
          question.questionText,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),

        // REMOVED: Question explanation (this was revealing the answer!)
        // We only show explanations after the user answers in results

        const SizedBox(height: 24),

        // FIXED: Question widget with stable answer state
        _buildStableQuestionWidget(context, question, controller),
      ],
    );
  }

  // FIXED: Stable question widget that uses local state for selections
  Widget _buildStableQuestionWidget(
    BuildContext context,
    QuizQuestion question,
    QuizController controller,
  ) {
    if (question is MultipleChoiceQuestion) {
      // Use stable answer state or controller state
      dynamic selectedAnswer;

      if (_stableAnswerState != null &&
          _stableAnswerState!['questionId'] == question.id) {
        selectedAnswer = _stableAnswerState!['answer'];
      } else {
        selectedAnswer = controller.currentSession
            ?.getAnswerForQuestion(question.id)
            ?.answer;
      }

      return MultipleChoiceWidget(
        question: question,
        selectedAnswer: selectedAnswer,
        onAnswerSelected: (answer) =>
            _handleAnswerSubmission(controller, answer),
        enabled: !controller.isProcessingAnswer && !_isTransitioning,
        // Don't show question text again - it's already displayed above
        showQuestionText: false,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Question type ${question.runtimeType} not yet supported',
        style: TextStyle(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // FIXED: Stable footer that only updates for navigation state changes
  Widget _buildStableFooter(
    BuildContext context,
    QuizController controller,
    QuizSession session,
    DeviceType deviceType,
  ) {
    final isMobile = deviceType == DeviceType.mobile;

    // Check if current question is answered (use stable state or controller state)
    bool isAnswered = false;
    if (_stableAnswerState != null &&
        _stableAnswerState!['questionId'] == session.currentQuestion.id) {
      isAnswered = true;
    } else {
      isAnswered = controller.currentSession
              ?.isQuestionAnswered(session.currentQuestion.id) ??
          false;
    }

    final hasNext = session.hasNextQuestion;
    final hasPrevious = session.hasPreviousQuestion;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main action buttons
            Row(
              children: [
                // Skip button (if allowed)
                if (session.allowSkip) ...[
                  Expanded(
                    child: SizedBox(
                      height: isMobile ? 44 : 48,
                      child: OutlinedButton(
                        onPressed: _isTransitioning
                            ? null
                            : () => _handleSkip(controller),
                        child: Text(
                          'Skip',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Next/Complete button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: isMobile ? 44 : 48,
                    child: ElevatedButton(
                      onPressed: (isAnswered && !_isTransitioning)
                          ? () => _handleNext(context, controller)
                          : null,
                      child: Text(
                        hasNext ? 'Next Question' : 'Complete Quiz',
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Previous button row (if has previous)
            if (hasPrevious) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: isMobile ? 40 : 44,
                child: OutlinedButton(
                  onPressed: _isTransitioning
                      ? null
                      : () => _handlePrevious(controller),
                  child: Text(
                    'Previous Question',
                    style: TextStyle(fontSize: isMobile ? 12 : 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
