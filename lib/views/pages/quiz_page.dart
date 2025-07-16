// lib/views/pages/quiz_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../models/quiz/quiz_question.dart';
import '../../models/quiz/quiz_session.dart';
import '../../models/quiz/multiple_choice_question.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import '../widgets/quiz/quiz_progress_bar.dart';
import '../widgets/quiz/multiple_choice_widget.dart';
import '../widgets/quiz/quiz_results_widget.dart';
import 'learning_topics_page.dart';

/// Main page for taking quizzes
class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    this.title,
    this.showAppBar = true,
    this.section,
    this.topic,
  });

  final String? title;
  final bool showAppBar;
  final LearningSection? section;
  final LearningTopic? topic;

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

  bool _disposed = false;
  bool _isExiting = false;

  // Stable UI state management
  String? _lastFeedback;
  bool _isTransitioning = false;
  String? _currentQuestionId;
  Map<String, dynamic>? _stableAnswerState;
  bool _timeoutDialogShown = false;

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
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _startPeriodicUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || !mounted || _isTransitioning || _isExiting) return;

      try {
        final controller = Provider.of<QuizController>(context, listen: false);
        if (controller.hasActiveSession && controller.timeRemaining != null) {
          if (mounted && !_disposed) {
            setState(() {});
          }
        }
      } catch (e) {
        print('Error in periodic update: $e');
      }
    });
  }

  void _restartTransitionAnimations() {
    if (_disposed || !mounted || _isExiting) return;

    setState(() {
      _isTransitioning = true;
    });

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
      if (mounted && !_disposed) {
        setState(() {
          _isTransitioning = false;
        });
      }
    });
  }

  void _handleAnswerSubmission(
      QuizController controller, dynamic answer) async {
    if (_disposed || controller.isProcessingAnswer || _isExiting) return;

    try {
      final questionId = controller.currentQuestion?.id;

      _stableAnswerState = {
        'questionId': questionId,
        'answer': answer,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await controller.submitAnswer(answer, autoAdvance: false);

      if (mounted && !_disposed) {
        setState(() {
          _lastFeedback = 'Answer submitted';
        });
        await _showFeedbackWithAnimation();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        _showErrorSnackbar(context, 'Failed to submit answer: $e');
      }
    }
  }

  Future<void> _showFeedbackWithAnimation() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted && !_disposed) {
      setState(() {
        _lastFeedback = null;
      });
    }
  }

  void _handleNext(BuildContext context, QuizController controller) async {
    if (_disposed || _isTransitioning || _isExiting) return;

    try {
      if (controller.hasNextQuestion) {
        await controller.nextQuestion();
        _restartTransitionAnimations();
      } else {
        await controller.completeQuiz();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        _showErrorSnackbar(context, 'Failed to proceed: $e');
      }
    }
  }

  void _handlePrevious(QuizController controller) async {
    if (_disposed || _isTransitioning || _isExiting) return;

    try {
      await controller.previousQuestion();
      _restartTransitionAnimations();
    } catch (e) {
      if (mounted && !_disposed) {
        _showErrorSnackbar(context, 'Failed to go to previous question: $e');
      }
    }
  }

  void _handleSkip(QuizController controller) async {
    if (_disposed || _isTransitioning || _isExiting) return;

    try {
      await controller.skipQuestion(autoAdvance: true);
      if (mounted && !_disposed) {
        setState(() {
          _lastFeedback = 'Question skipped';
        });
        await _showFeedbackWithAnimation();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        _showErrorSnackbar(context, 'Failed to skip question: $e');
      }
    }
  }

  void _handleRetakeQuiz(BuildContext context, QuizController controller) {
    if (_disposed || _isExiting) return;
    _exitQuiz(context, controller);
  }

  void _handleBackToMenu(BuildContext context, QuizController controller) {
    if (_disposed || _isExiting) return;
    _exitQuiz(context, controller);
  }

  // FIXED: Better navigation handling
  void _exitQuiz(BuildContext context, QuizController controller) {
    if (_disposed || _isExiting) return;

    debugPrint('Starting quiz exit process...');
    _isExiting = true;

    // Clean up quiz state first
    Future.microtask(() {
      try {
        if (controller.hasActiveSession) {
          controller.abandonQuiz();
        }
        controller.clearResults();
        debugPrint('Quiz controller cleaned up');
      } catch (e) {
        debugPrint('Cleanup error: $e');
      }
    });

    // Use proper navigation based on how we got here
    try {
      if (widget.section != null) {
        // We came from learning topics, navigate back properly
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LearningTopicsPage(section: widget.section!),
          ),
          (route) => route.isFirst,
        );
        debugPrint('Navigated back to learning topics');
      } else {
        // Fallback: pop until we reach a valid route
        Navigator.of(context).popUntil((route) {
          debugPrint('Checking route: ${route.settings.name}');
          return route.isFirst ||
              route.settings.name?.contains('learning') == true ||
              route.settings.name == '/home';
        });
        debugPrint('Popped to valid route');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Last resort: go to home
      try {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } catch (homeError) {
        debugPrint('Home navigation error: $homeError');
      }
    }
  }

  void _handleBackAction(BuildContext context, QuizController controller) {
    if (_disposed || _isExiting) return;

    if (controller.isShowingResults) {
      _exitQuiz(context, controller);
    } else if (controller.hasActiveSession) {
      _showAbandonQuizDialog(context, controller);
    } else {
      _exitQuiz(context, controller);
    }
  }

  void _showAbandonQuizDialog(BuildContext context, QuizController controller) {
    if (_disposed || !mounted || _isExiting) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandon Quiz?'),
        content: const Text(
            'Are you sure you want to exit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog first
              _exitQuiz(context, controller); // Then exit quiz
            },
            child: const Text('Exit Quiz'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (_disposed || !mounted || _isExiting) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTimeExpiredDialog(QuizController controller) {
    if (_disposed || !mounted || _timeoutDialogShown || _isExiting) return;

    _timeoutDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              _timeoutDialogShown = false;

              if (!_disposed && mounted) {
                try {
                  if (controller.hasActiveSession &&
                      !controller.isShowingResults) {
                    await controller.completeQuiz();
                  }
                } catch (e) {
                  debugPrint('Error completing quiz after timeout: $e');
                  controller.clearResults();
                }

                if (mounted && !_disposed) {
                  setState(() {});
                }
              }
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _fadeController.dispose();
    _slideController.dispose();
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we're exiting, show minimal UI to prevent rebuilds
    if (_isExiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_disposed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<QuizController>(
      builder: (context, quizController, child) {
        // Handle controller errors
        if (quizController.hasError) {
          return _buildErrorScreen(context, quizController);
        }

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

  Widget _buildErrorScreen(BuildContext context, QuizController controller) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Quiz Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'An error occurred while loading the quiz. Please try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _exitQuiz(context, controller),
                    child: const Text('Go Back'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.clearResults();
                      _exitQuiz(context, controller);
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        onPressed: () {
          try {
            _handleBackAction(context, controller);
          } catch (e) {
            debugPrint('AppBar close error: $e');
            _exitQuiz(context, controller);
          }
        },
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

    // Track question changes for stable UI
    final currentQuestionId = session.currentQuestion.id;
    if (_currentQuestionId != currentQuestionId) {
      _currentQuestionId = currentQuestionId;
      _stableAnswerState = null;
    }

    // Check for time expiration
    if (session.timeLimit != null &&
        controller.isTimeExpired &&
        !_timeoutDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_disposed) {
          _showTimeExpiredDialog(controller);
        }
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

  Widget _buildQuizContent(
    BuildContext context,
    QuizController controller,
    QuizSession session,
    DeviceType deviceType,
  ) {
    return Column(
      children: [
        _buildStableHeader(context, session, deviceType),
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
        _buildStableFooter(context, controller, session, deviceType),
      ],
    );
  }

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
          QuizProgressBar(
            current: session.currentQuestionIndex + 1,
            total: session.totalQuestions,
            timeRemaining: session.timeRemaining,
          ),
          SizedBox(
            height: 40,
            child: _lastFeedback != null
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _lastFeedback!,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
        Text(
          'Question ${session.currentQuestionIndex + 1} of ${session.totalQuestions}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        Text(
          question.questionText,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 24),
        _buildStableQuestionWidget(context, question, controller),
      ],
    );
  }

  Widget _buildStableQuestionWidget(
    BuildContext context,
    QuizQuestion question,
    QuizController controller,
  ) {
    if (question is MultipleChoiceQuestion) {
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

  Widget _buildStableFooter(
    BuildContext context,
    QuizController controller,
    QuizSession session,
    DeviceType deviceType,
  ) {
    final isMobile = deviceType == DeviceType.mobile;

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
            Row(
              children: [
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
