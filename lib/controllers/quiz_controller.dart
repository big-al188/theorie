// lib/controllers/quiz_controller.dart

import 'package:flutter/foundation.dart';
import '../models/quiz/quiz_question.dart';
import '../models/quiz/quiz_session.dart';
import '../models/quiz/quiz_result.dart';
import '../models/quiz/multiple_choice_question.dart';
import '../services/progress_tracking_service.dart';

/// Exception thrown when quiz controller operations fail
class QuizControllerException implements Exception {
  const QuizControllerException(this.message);
  final String message;

  @override
  String toString() => 'QuizControllerException: $message';
}

/// Main controller for managing quiz flow and state
///
/// This controller handles the lifecycle of quiz sessions including:
/// - Session creation and initialization
/// - Navigation between questions
/// - Answer submission and validation
/// - Progress tracking and timing
/// - Quiz completion and result generation
class QuizController extends ChangeNotifier {
  QuizController() : _currentSession = null;

  // Private state
  QuizSession? _currentSession;
  QuizResult? _lastResult;
  final Map<String, int> _questionStartTimes = {};
  bool _isProcessingAnswer = false;

  // FIXED: Quiz context for progress tracking
  String? _currentTopicId;
  String? _currentSectionId;

  // Getters for accessing current state
  QuizSession? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession != null;
  bool get isProcessingAnswer => _isProcessingAnswer;

  // ADDED: Getters for results display
  bool get isShowingResults => _lastResult != null;
  QuizResult? get lastResult => _lastResult;

  /// Convenience getters that delegate to current session
  QuizQuestion? get currentQuestion => _currentSession?.currentQuestion;
  int get currentQuestionIndex => _currentSession?.currentQuestionIndex ?? 0;
  int get totalQuestions => _currentSession?.totalQuestions ?? 0;
  double get progress => _currentSession?.progress ?? 0.0;
  bool get hasNextQuestion => _currentSession?.hasNextQuestion ?? false;
  bool get hasPreviousQuestion => _currentSession?.hasPreviousQuestion ?? false;
  Duration? get timeElapsed => _currentSession?.timeElapsed;
  Duration? get timeRemaining => _currentSession?.timeRemaining;
  bool get isTimeExpired => _currentSession?.isTimeExpired ?? false;

  /// Creates and starts a new quiz session
  /// FIXED: Added topicId and sectionId for progress tracking
  Future<void> startQuiz({
    required List<QuizQuestion> questions,
    required QuizType quizType,
    String? topicId, // FIXED: For progress tracking
    String? sectionId, // FIXED: For progress tracking
    String? title,
    String? description,
    bool allowReview = true,
    bool allowSkip = true,
    int? timeLimit,
    double passingScore = 0.7,
  }) async {
    if (_currentSession != null) {
      throw QuizControllerException('Another quiz session is already active');
    }

    if (questions.isEmpty) {
      throw QuizControllerException('Cannot start quiz with no questions');
    }

    try {
      // FIXED: Store context for progress tracking
      _currentTopicId = topicId;
      _currentSectionId = sectionId;

      // Clear any previous results when starting new quiz
      _lastResult = null;

      // Generate unique session ID
      final sessionId = 'quiz_${DateTime.now().millisecondsSinceEpoch}';

      // Create new session
      _currentSession = QuizSession(
        id: sessionId,
        quizType: quizType,
        questions: questions,
        title: title,
        description: description,
        allowReview: allowReview,
        allowSkip: allowSkip,
        timeLimit: timeLimit,
        passingScore: passingScore,
      );

      // Listen to session changes
      _currentSession!.addListener(_onSessionChanged);

      // Start the session
      _currentSession!.start();

      // Record start time for first question
      _recordQuestionStartTime();

      notifyListeners();
    } catch (e) {
      _currentSession = null;
      _currentTopicId = null;
      _currentSectionId = null;
      throw QuizControllerException('Failed to start quiz: $e');
    }
  }

  /// Submits an answer for the current question
  /// FIXED: Updated to use existing QuizSession methods
  Future<bool> submitAnswer(dynamic answer, {bool autoAdvance = true}) async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (_isProcessingAnswer) {
      return false; // Prevent double submission
    }

    try {
      _isProcessingAnswer = true;
      notifyListeners();

      final questionTime = _calculateQuestionTime();

      // FIXED: Use existing session method signature
      _currentSession!.submitAnswer(
        answer,
        timeSpent: questionTime,
        hintsUsed: 0, // TODO: Implement hint tracking if needed
      );

      // Validate answer for return value
      final question = _currentSession!.currentQuestion;
      final result = question.validateAnswer(answer);

      if (autoAdvance && _currentSession!.hasNextQuestion) {
        _currentSession!.nextQuestion();
        _recordQuestionStartTime();
      }

      return result.isCorrect;
    } catch (e) {
      throw QuizControllerException('Failed to submit answer: $e');
    } finally {
      _isProcessingAnswer = false;
      notifyListeners();
    }
  }

  /// Moves to the next question
  /// FIXED: Updated to use existing QuizSession methods
  Future<void> nextQuestion() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (!_currentSession!.hasNextQuestion) {
      throw QuizControllerException('No next question available');
    }

    try {
      _currentSession!.nextQuestion();
      _recordQuestionStartTime();
    } catch (e) {
      throw QuizControllerException('Failed to go to next question: $e');
    }
  }

  /// Moves to the previous question
  /// FIXED: Updated to use existing QuizSession methods
  Future<void> previousQuestion() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (!_currentSession!.hasPreviousQuestion) {
      throw QuizControllerException('No previous question available');
    }

    try {
      _currentSession!.previousQuestion();
      _recordQuestionStartTime();
    } catch (e) {
      throw QuizControllerException('Failed to go to previous question: $e');
    }
  }

  /// Skips the current question
  /// FIXED: Updated to use existing QuizSession methods
  Future<void> skipQuestion({bool autoAdvance = true}) async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (!_currentSession!.allowSkip) {
      throw QuizControllerException('Skipping is not allowed for this quiz');
    }

    try {
      _currentSession!.skipQuestion();

      if (autoAdvance && _currentSession!.hasNextQuestion) {
        _currentSession!.nextQuestion();
        _recordQuestionStartTime();
      }
    } catch (e) {
      throw QuizControllerException('Failed to skip question: $e');
    }
  }

  /// Jumps to a specific question by index
  Future<void> goToQuestion(int index) async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (index < 0 || index >= _currentSession!.totalQuestions) {
      throw QuizControllerException('Question index out of range: $index');
    }

    try {
      _currentSession!.goToQuestion(index);
      _recordQuestionStartTime();
    } catch (e) {
      throw QuizControllerException(
          'Failed to navigate to question $index: $e');
    }
  }

  /// Pauses the current quiz session
  Future<void> pauseQuiz() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    try {
      _currentSession!.pause();
    } catch (e) {
      throw QuizControllerException('Failed to pause quiz: $e');
    }
  }

  /// Resumes a paused quiz session
  Future<void> resumeQuiz() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    try {
      _currentSession!.resume();
      _recordQuestionStartTime(); // Reset question timer
    } catch (e) {
      throw QuizControllerException('Failed to resume quiz: $e');
    }
  }

  /// Completes the quiz and returns the result
  /// FIXED: Now properly handles progress tracking for both topic and section quizzes
  Future<QuizResult> completeQuiz() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    try {
      final result = _currentSession!.complete();

      // FIXED: Store the result for display
      _lastResult = QuizResult.fromSession(_currentSession!);

      // FIXED: Record progress based on quiz type
      if (_currentTopicId != null) {
        // Topic quiz - track topic completion
        try {
          debugPrint(
              'Recording topic quiz completion for topic: $_currentTopicId, section: $_currentSectionId');
          await ProgressTrackingService.instance.recordQuizCompletion(
            result: _lastResult!,
            topicId: _currentTopicId!,
            sectionId: _currentSectionId, // Optional section context
            passingScore: _currentSession!.passingScore,
          );
          debugPrint('Topic progress tracking completed successfully');
        } catch (e) {
          debugPrint('Error in topic progress tracking: $e');
          // Don't throw here - quiz completion should still work even if progress tracking fails
        }
      } else if (_currentSectionId != null) {
        // Section quiz - track section completion
        try {
          debugPrint(
              'Recording section quiz completion for section: $_currentSectionId');
          await ProgressTrackingService.instance.recordSectionQuizCompletion(
            result: _lastResult!,
            sectionId: _currentSectionId!,
            passingScore: _currentSession!.passingScore,
          );
          debugPrint('Section progress tracking completed successfully');
        } catch (e) {
          debugPrint('Error in section progress tracking: $e');
          // Don't throw here - quiz completion should still work even if progress tracking fails
        }
      } else {
        debugPrint(
            'Warning: No topicId or sectionId provided, progress will not be tracked');
      }

      // Clean up session
      _currentSession!.removeListener(_onSessionChanged);
      _currentSession = null;
      _questionStartTimes.clear();

      notifyListeners();
      return _lastResult!;
    } catch (e) {
      throw QuizControllerException('Failed to complete quiz: $e');
    }
  }

  /// ADDED: Clears results and allows starting a new quiz
  void clearResults() {
    _lastResult = null;
    _currentTopicId = null;
    _currentSectionId = null;
    notifyListeners();
  }

  /// Gets quiz statistics for display
  Map<String, dynamic> getQuizStatistics() {
    if (_currentSession == null && _lastResult == null) {
      return <String, dynamic>{};
    }

    // If we have completed results, use those
    if (_lastResult != null) {
      return <String, dynamic>{
        'answered': _lastResult!.questionsAnswered,
        'total': _lastResult!.totalQuestions,
        'correct': _lastResult!.questionsCorrect,
        'accuracy': _lastResult!.accuracy,
        'progress': 1.0, // Completed
        'timeElapsed': _lastResult!.timeSpent.inSeconds,
        'scorePercentage': _lastResult!.scorePercentage,
        'passed': _lastResult!.passed,
      };
    }

    // For active session, use basic counts
    final answeredCount = _currentSession!.answers.length;
    final total = _currentSession!.totalQuestions;

    return <String, dynamic>{
      'answered': answeredCount,
      'total': total,
      'correct': 0, // Can't determine without validating each answer
      'accuracy': 0.0,
      'progress': _currentSession!.progress,
      'timeElapsed': _currentSession!.timeElapsed?.inSeconds ?? 0,
      'scorePercentage': 0.0,
      'passed': false,
    };
  }

  /// ADDED: Method for quiz results widget compatibility
  Map<String, dynamic> getCurrentPerformanceStats() {
    return getQuizStatistics();
  }

  /// Records the start time for the current question
  void _recordQuestionStartTime() {
    if (_currentSession != null) {
      _questionStartTimes[_currentSession!.currentQuestion.id] =
          DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// Calculates the time spent on the current question
  Duration _calculateQuestionTime() {
    if (_currentSession == null) return Duration.zero;

    final questionId = _currentSession!.currentQuestion.id;
    final startTime = _questionStartTimes[questionId];

    if (startTime == null) return Duration.zero;

    final now = DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: now - startTime);
  }

  /// Handles changes to the current session
  void _onSessionChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _currentSession?.removeListener(_onSessionChanged);
    super.dispose();
  }
}
