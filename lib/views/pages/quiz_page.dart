// lib/views/pages/quiz_page.dart

import 'dart:async'; // ADDED: For Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../models/quiz/quiz_question.dart';
import '../../models/quiz/quiz_session.dart';
import '../../models/quiz/multiple_choice_question.dart';
import '../../constants/ui_constants.dart'; // ADDED: For responsive design
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

  // ADDED: Timer for real-time updates and scroll controller for mobile
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();

  bool _showingResults = false;
  String? _lastFeedback;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPeriodicTimer(); // ADDED: Start timer for real-time updates
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

  // ADDED: Real-time timer for quiz updates
  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final controller = context.read<QuizController>();

        // Only update if we have an active session with time limit
        if (controller.hasActiveSession &&
            controller.currentSession?.timeLimit != null) {
          // Force a rebuild to update timer display
          setState(() {});

          // Check if time expired
          if (controller.isTimeExpired) {
            _handleTimeExpired();
          }
        }
      }
    });
  }

  // ADDED: Handle time expiration
  void _handleTimeExpired() async {
    _timer?.cancel();

    final controller = context.read<QuizController>();
    if (controller.hasActiveSession) {
      await controller.completeQuiz();
    }

    if (mounted) {
      _showTimeExpiredDialog();
    }
  }

  // ADDED: Show time expired dialog
  void _showTimeExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Time\'s Up!'),
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
    _timer?.cancel(); // ADDED: Clean up timer
    _scrollController.dispose(); // ADDED: Clean up scroll controller
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

  // UPDATED: Made responsive for mobile with scrolling
  Widget _buildActiveQuizInterface(
      BuildContext context, QuizController controller, QuizSession session) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isMobile = deviceType == DeviceType.mobile;

    return Column(
      children: [
        // Progress bar
        if (session.totalQuestions > 1)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16, // ADDED: Mobile-specific padding
              vertical: 8,
            ),
            child: QuizProgressBar(
              current: session.currentQuestionIndex + 1,
              total: session.totalQuestions,
              timeRemaining:
                  session.timeRemaining, // FIXED: Real-time timer updates
              showPercentage: !isMobile, // ADDED: Hide percentage on mobile
            ),
          ),

        // Feedback message
        if (_lastFeedback != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16, // ADDED: Mobile-specific padding
              vertical: 8,
            ),
            child: _buildFeedbackCard(context, _lastFeedback!),
          ),

        // UPDATED: Main question area with scrolling for mobile
        Expanded(
          child: SingleChildScrollView(
            // ADDED: Scrollable for mobile
            controller: _scrollController,
            padding:
                EdgeInsets.all(isMobile ? 12 : 16), // ADDED: Responsive padding
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildQuestionSection(context, controller),
              ),
            ),
          ),
        ),

        // Navigation controls
        Container(
          padding: EdgeInsets.all(
              isMobile ? 12 : 16), // ADDED: Mobile-specific padding
          child: _buildNavigationControls(context, controller, session),
        ),
      ],
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

        // Question text - FIXED: Use correct property name
        Text(
          question.questionText, // FIXED: Use existing property name
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),

        // Question description/explanation - FIXED: Use correct property
        if (question.explanation?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            question.explanation!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],

        const SizedBox(height: 24),

        // Question widget
        _buildQuestionWidget(context, question, controller),
      ],
    );
  }

  Widget _buildQuestionWidget(
      BuildContext context, QuizQuestion question, QuizController controller) {
    if (question is MultipleChoiceQuestion) {
      return MultipleChoiceWidget(
        question: question,
        selectedAnswer: controller.currentSession
            ?.getAnswerForQuestion(question.id)
            ?.answer,
        onAnswerSelected: (answer) =>
            _handleAnswerSubmission(controller, answer),
        enabled: !controller.isProcessingAnswer,
      );
    }

    // Handle other question types
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

  // UPDATED: Make navigation responsive
  Widget _buildNavigationControls(
      BuildContext context, QuizController controller, QuizSession session) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isMobile = deviceType == DeviceType.mobile;

    final isAnswered = controller.currentSession
            ?.isQuestionAnswered(session.currentQuestion.id) ??
        false;
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
                    height: isMobile ? 44 : 48, // ADDED: Mobile-specific height
                    child: OutlinedButton(
                      onPressed: () => _handleSkip(controller),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                            fontSize: isMobile
                                ? 14
                                : 16), // ADDED: Mobile-specific font
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
                  height: isMobile ? 44 : 48, // ADDED: Mobile-specific height
                  child: ElevatedButton(
                    onPressed: isAnswered
                        ? () => _handleNext(context, controller)
                        : null,
                    child: Text(
                      hasNext ? 'Next Question' : 'Complete Quiz',
                      style: TextStyle(
                          fontSize: isMobile
                              ? 14
                              : 16), // ADDED: Mobile-specific font
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
              height: isMobile ? 40 : 44, // ADDED: Mobile-specific height
              child: OutlinedButton(
                onPressed: () => _handlePrevious(controller),
                child: Text(
                  'Previous Question',
                  style: TextStyle(
                      fontSize:
                          isMobile ? 13 : 15), // ADDED: Mobile-specific font
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, String feedback) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feedback,
                style: TextStyle(color: Colors.blue[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restartTransitionAnimations() {
    _slideController.reset();
    _slideController.forward();
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            Theme.of(context).colorScheme.error, // FIXED: Use colorScheme.error
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
            'Are you sure you want to exit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
