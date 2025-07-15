// lib/controllers/quiz_controller.dart

import 'package:flutter/foundation.dart';
import '../models/quiz/quiz_question.dart';
import '../models/quiz/quiz_session.dart';
import '../models/quiz/quiz_result.dart';
import '../models/quiz/multiple_choice_question.dart';

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
  QuizResult? _lastResult; // ADDED: Store completed quiz results
  final Map<String, int> _questionStartTimes = {};
  bool _isProcessingAnswer = false;

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
  ///
  /// [questions] - List of questions for the quiz
  /// [quizType] - Type of quiz being created
  /// [title] - Optional title for the quiz
  /// [options] - Additional configuration options
  Future<void> startQuiz({
    required List<QuizQuestion> questions,
    required QuizType quizType,
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
      // ADDED: Clear any previous results when starting new quiz
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
      throw QuizControllerException('Failed to start quiz: $e');
    }
  }

  /// Submits an answer for the current question
  ///
  /// [answer] - The user's answer
  /// [autoAdvance] - Whether to automatically advance to next question
  Future<QuestionResult> submitAnswer(
    dynamic answer, {
    bool autoAdvance = true,
  }) async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (_isProcessingAnswer) {
      throw QuizControllerException('Already processing an answer');
    }

    _isProcessingAnswer = true;
    notifyListeners();

    try {
      final question = _currentSession!.currentQuestion;
      final timeSpent = _calculateQuestionTime();

      // Validate the answer
      final result = question.validateAnswer(answer);

      // Submit to session
      _currentSession!.submitAnswer(
        answer,
        timeSpent: timeSpent,
        hintsUsed: 0, // TODO: Implement hint tracking
      );

      // Auto-advance if enabled and not on last question
      if (autoAdvance && _currentSession!.hasNextQuestion) {
        await nextQuestion();
      }

      return result;
    } catch (e) {
      throw QuizControllerException('Failed to submit answer: $e');
    } finally {
      _isProcessingAnswer = false;
      notifyListeners();
    }
  }

  /// Skips the current question
  Future<void> skipQuestion({bool autoAdvance = true}) async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (!_currentSession!.allowSkip) {
      throw QuizControllerException('Skipping is not allowed for this quiz');
    }

    try {
      _currentSession!.skipQuestion();

      // Auto-advance if enabled and not on last question
      if (autoAdvance && _currentSession!.hasNextQuestion) {
        await nextQuestion();
      }
    } catch (e) {
      throw QuizControllerException('Failed to skip question: $e');
    }
  }

  /// Navigates to the next question
  Future<void> nextQuestion() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (!_currentSession!.hasNextQuestion) {
      throw QuizControllerException('No next question available');
    }

    try {
      final success = _currentSession!.nextQuestion();
      if (success) {
        _recordQuestionStartTime();
      }
    } catch (e) {
      throw QuizControllerException('Failed to navigate to next question: $e');
    }
  }

  /// Navigates to the previous question
  Future<void> previousQuestion() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (!_currentSession!.hasPreviousQuestion) {
      throw QuizControllerException('No previous question available');
    }

    try {
      final success = _currentSession!.previousQuestion();
      if (success) {
        _recordQuestionStartTime();
      }
    } catch (e) {
      throw QuizControllerException(
          'Failed to navigate to previous question: $e');
    }
  }

  /// Navigates directly to a specific question
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
  Future<QuizResult> completeQuiz() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    try {
      final result = _currentSession!.complete();

      // ADDED: Store the result for display - THIS IS THE KEY FIX
      _lastResult = QuizResult.fromSession(_currentSession!);

      // Clean up
      _currentSession!.removeListener(_onSessionChanged);
      _currentSession = null;
      _questionStartTimes.clear();

      notifyListeners();
      return _lastResult!; // Return the stored result
    } catch (e) {
      throw QuizControllerException('Failed to complete quiz: $e');
    }
  }

  /// Abandons the current quiz session
  Future<void> abandonQuiz() async {
    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    try {
      _currentSession!.abandon();

      // Clean up
      _currentSession!.removeListener(_onSessionChanged);
      _currentSession = null;
      _questionStartTimes.clear();
      _lastResult = null; // ADDED: Clear results when abandoning

      notifyListeners();
    } catch (e) {
      throw QuizControllerException('Failed to abandon quiz: $e');
    }
  }

  // ADDED: Method to clear results when starting new quiz
  /// Clears the last quiz result (when user wants to start a new quiz)
  void clearResults() {
    _lastResult = null;
    notifyListeners();
  }

  /// Returns the user's answer for a specific question
  dynamic getUserAnswerForQuestion(String questionId) {
    if (_currentSession == null) return null;

    final answer = _currentSession!.getAnswerForQuestion(questionId);
    return answer?.answer;
  }

  /// Checks if a specific question has been answered
  bool isQuestionAnswered(String questionId) {
    if (_currentSession == null) return false;
    return _currentSession!.isQuestionAnswered(questionId);
  }

  /// Returns a list of unanswered questions
  List<QuizQuestion> getUnansweredQuestions() {
    if (_currentSession == null) return [];
    return _currentSession!.getUnansweredQuestions();
  }

  /// Gets performance statistics for the current session
  Map<String, dynamic> getCurrentPerformanceStats() {
    if (_currentSession == null) return {};

    final answered = _currentSession!.questionsAnswered;
    final correct =
        _currentSession!.answers.values.where((a) => !a.isSkipped).where((a) {
      final question =
          _currentSession!.questions.firstWhere((q) => q.id == a.questionId);
      return question.validateAnswer(a.answer).isCorrect;
    }).length;

    return {
      'questionsAnswered': answered,
      'questionsCorrect': correct,
      'accuracy': answered > 0 ? correct / answered : 0.0,
      'progress': _currentSession!.progress,
      'timeElapsed': _currentSession!.timeElapsed?.inSeconds ?? 0,
    };
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
