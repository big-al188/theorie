// lib/controllers/quiz_controller.dart

import 'package:flutter/foundation.dart';
import '../models/quiz/quiz_question.dart';
import '../models/quiz/quiz_session.dart';
import '../models/quiz/quiz_result.dart';
import '../models/quiz/multiple_choice_question.dart';
import '../models/quiz/scale_strip_question.dart';
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
/// - Progress tracking and timing (now with enhanced offline support)
/// - Quiz completion and result generation
class QuizController extends ChangeNotifier {
  QuizController() : _currentSession = null;

  // Private state
  QuizSession? _currentSession;
  QuizResult? _lastResult;
  final Map<String, int> _questionStartTimes = {};
  bool _isProcessingAnswer = false;

  // Quiz context for progress tracking
  String? _currentTopicId;
  String? _currentSectionId;

  // Disposal state tracking for safety
  bool _disposed = false;
  String? _lastError;

  // Getters for accessing current state
  QuizSession? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession != null && !_disposed;
  bool get isProcessingAnswer => _isProcessingAnswer;

  // Error state getters
  bool get hasError => _lastError != null;
  String? get error => _lastError;

  // Getters for results display
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

  /// Safe notification method that checks disposal state
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Creates and starts a new quiz session
  Future<void> startQuiz({
    required List<QuizQuestion> questions,
    required QuizType quizType,
    String? topicId,
    String? sectionId,
    String? title,
    String? description,
    bool allowReview = true,
    bool allowSkip = true,
    int? timeLimit,
    double passingScore = 0.7,
  }) async {
    // Check if controller is disposed
    if (_disposed) {
      throw QuizControllerException('Controller has been disposed');
    }

    // Clear any previous errors
    _lastError = null;

    // Clean up any existing session first
    if (_currentSession != null) {
      try {
        await _cleanupCurrentSession();
      } catch (e) {
        // Force cleanup if normal cleanup fails
        _forceCleanup();
      }
    }

    if (questions.isEmpty) {
      throw QuizControllerException('Cannot start quiz with no questions');
    }

    try {
      // Store context for progress tracking
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

      _safeNotifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _forceCleanup();
      _safeNotifyListeners();
      throw QuizControllerException('Failed to start quiz: $e');
    }
  }

  /// Submits an answer for the current question with enhanced support for scale strip questions
  Future<QuestionResult> submitAnswer(
    dynamic answer, {
    bool autoAdvance = true,
  }) async {
    if (_disposed) {
      throw QuizControllerException('Controller has been disposed');
    }

    if (_currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    if (_isProcessingAnswer) {
      throw QuizControllerException('Already processing an answer');
    }

    _isProcessingAnswer = true;
    _lastError = null;
    _safeNotifyListeners();

    try {
      final question = _currentSession!.currentQuestion;
      final timeSpent = _calculateQuestionTime();

      // Enhanced answer validation for different question types
      QuestionResult result;
      
      switch (question.type) {
        case QuestionType.multipleChoice:
          if (question is MultipleChoiceQuestion) {
            result = question.validateAnswer(answer);
          } else {
            throw QuizControllerException('Question type mismatch: expected MultipleChoiceQuestion');
          }
          break;
          
        case QuestionType.scaleStrip:
          if (question is ScaleStripQuestion) {
            // Ensure we have a valid ScaleStripAnswer
            ScaleStripAnswer scaleStripAnswer;
            if (answer is ScaleStripAnswer) {
              scaleStripAnswer = answer;
            } else if (answer == null) {
              // Create empty answer for null input
              scaleStripAnswer = const ScaleStripAnswer(
                selectedPositions: {},
                selectedNotes: {},
              );
            } else {
              throw QuizControllerException('Invalid answer type for scale strip question: expected ScaleStripAnswer, got ${answer.runtimeType}');
            }
            
            result = question.validateAnswer(scaleStripAnswer);
            
            // Track scale strip specific metrics for analytics
            await _trackScaleStripMetrics(question, scaleStripAnswer, result, timeSpent);
          } else {
            throw QuizControllerException('Question type mismatch: expected ScaleStripQuestion');
          }
          break;
          
        default:
          // Handle other question types
          result = question.validateAnswer(answer);
          break;
      }

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
      _lastError = 'Failed to submit answer: $e';
      throw QuizControllerException('Failed to submit answer: $e');
    } finally {
      _isProcessingAnswer = false;
      _safeNotifyListeners();
    }
  }

  /// Track scale strip specific metrics for detailed analytics
  Future<void> _trackScaleStripMetrics(
    ScaleStripQuestion question,
    ScaleStripAnswer answer,
    QuestionResult result,
    Duration timeSpent,
  ) async {
    try {
      // Use calculateScore method to get the score since QuestionResult doesn't have a score property
      final score = question.calculateScore(answer);
      debugPrint('📊 Scale strip metrics: ${question.questionMode} - ${(score * 100).round()}%');
      
      // TODO: Implement detailed scale strip metrics tracking
      // This could be expanded when ProgressTrackingService supports custom metrics
    } catch (e) {
      debugPrint('⚠️ Failed to track scale strip metrics: $e');
      // Don't throw - metrics failure shouldn't break quiz flow
    }
  }

  /// Get the current answer based on question type
  dynamic getCurrentAnswer() {
    if (currentQuestion == null) return null;
    
    final questionId = currentQuestion!.id;
    final currentAnswers = _currentSession?.answers.values ?? [];
    final existingAnswer = currentAnswers
        .where((a) => a.questionId == questionId)
        .lastOrNull;
    
    if (existingAnswer != null) {
      return existingAnswer.answer; // Use 'answer' property, not 'selectedAnswer'
    }

    // Return appropriate empty answer based on question type
    switch (currentQuestion!.type) {
      case QuestionType.multipleChoice:
        return null; // MultipleChoice uses null for no selection
      case QuestionType.scaleStrip:
        return const ScaleStripAnswer(
          selectedPositions: {},
          selectedNotes: {},
        );
      default:
        return null;
    }
  }

  /// Validate answer format for current question type
  bool isValidAnswerFormat(dynamic answer) {
    if (currentQuestion == null) return false;

    switch (currentQuestion!.type) {
      case QuestionType.multipleChoice:
        return answer == null || answer is String || answer is List<String>;
      case QuestionType.scaleStrip:
        return answer is ScaleStripAnswer;
      case QuestionType.interactive:
      case QuestionType.trueFalse:
      case QuestionType.fillInBlank:
        return true; // Accept any format for unimplemented types
    }
  }

  /// Get a human-readable summary of an answer for results display
  String getAnswerSummary(dynamic answer) {
    if (answer == null) return 'No answer selected';

    if (answer is ScaleStripAnswer) {
      final scaleAnswer = answer;
      if (scaleAnswer.isEmpty) {
        return 'No selection made';
      }
      
      final positionCount = scaleAnswer.selectedPositions.length;
      final notesList = scaleAnswer.selectedNotes.toList()..sort();
      
      if (notesList.isNotEmpty) {
        return 'Selected $positionCount position${positionCount != 1 ? 's' : ''}: ${notesList.join(', ')}';
      } else {
        return 'Selected $positionCount position${positionCount != 1 ? 's' : ''}';
      }
    } else if (answer is String) {
      return 'Selected: $answer';
    } else if (answer is List) {
      final selections = answer.cast<String>();
      if (selections.isEmpty) return 'No selections made';
      return 'Selected: ${selections.join(', ')}';
    } else {
      return answer.toString();
    }
  }

  /// Skips the current question
  Future<void> skipQuestion({bool autoAdvance = true}) async {
    if (_disposed || _currentSession == null) return;

    if (!_currentSession!.allowSkip) {
      throw QuizControllerException('Skipping is not allowed for this quiz');
    }

    _lastError = null;

    try {
      _currentSession!.skipQuestion();

      // Auto-advance if enabled and not on last question
      if (autoAdvance && _currentSession!.hasNextQuestion) {
        await nextQuestion();
      }
    } catch (e) {
      _lastError = 'Failed to skip question: $e';
      throw QuizControllerException('Failed to skip question: $e');
    }
  }

  /// Advances to the next question
  Future<void> nextQuestion() async {
    if (_disposed || _currentSession == null) return;

    if (!_currentSession!.hasNextQuestion) {
      throw QuizControllerException('No next question available');
    }

    _lastError = null;

    try {
      _currentSession!.nextQuestion();
      _recordQuestionStartTime();
      _safeNotifyListeners();
    } catch (e) {
      _lastError = 'Failed to advance to next question: $e';
      throw QuizControllerException('Failed to advance to next question: $e');
    }
  }

  /// Goes to the previous question
  Future<void> previousQuestion() async {
    if (_disposed || _currentSession == null) return;

    if (!_currentSession!.hasPreviousQuestion) {
      throw QuizControllerException('No previous question available');
    }

    _lastError = null;

    try {
      _currentSession!.previousQuestion();
      _recordQuestionStartTime();
      _safeNotifyListeners();
    } catch (e) {
      _lastError = 'Failed to go to previous question: $e';
      throw QuizControllerException('Failed to go to previous question: $e');
    }
  }

  /// Navigates to a specific question by index
  Future<void> goToQuestion(int index) async {
    if (_disposed || _currentSession == null) return;

    if (index < 0 || index >= _currentSession!.totalQuestions) {
      throw QuizControllerException('Question index out of range: $index');
    }

    _lastError = null;

    try {
      _currentSession!.goToQuestion(index);
      _recordQuestionStartTime();
      _safeNotifyListeners();
    } catch (e) {
      _lastError = 'Failed to navigate to question $index: $e';
      throw QuizControllerException('Failed to navigate to question $index: $e');
    }
  }

  /// Pauses the current quiz session
  Future<void> pauseQuiz() async {
    if (_disposed || _currentSession == null) return;

    _lastError = null;

    try {
      _currentSession!.pause();
      _safeNotifyListeners();
    } catch (e) {
      _lastError = 'Failed to pause quiz: $e';
      throw QuizControllerException('Failed to pause quiz: $e');
    }
  }

  /// Resumes a paused quiz session
  Future<void> resumeQuiz() async {
    if (_disposed || _currentSession == null) return;

    _lastError = null;

    try {
      _currentSession!.resume();
      _recordQuestionStartTime(); // Reset question timer
      _safeNotifyListeners();
    } catch (e) {
      _lastError = 'Failed to resume quiz: $e';
      throw QuizControllerException('Failed to resume quiz: $e');
    }
  }

  /// Completes the quiz and returns the result
  Future<QuizResult> completeQuiz() async {
    if (_disposed || _currentSession == null) {
      throw QuizControllerException('No active quiz session');
    }

    _lastError = null;

    try {
      _currentSession!.complete();

      // Store the result for display
      _lastResult = QuizResult.fromSession(_currentSession!);

      // Record progress using enhanced service with offline support
      await _recordQuizProgress(_lastResult!);

      // Clean up session
      await _cleanupCurrentSession();

      _safeNotifyListeners();
      return _lastResult!;
    } catch (e) {
      _lastError = 'Failed to complete quiz: $e';
      throw QuizControllerException('Failed to complete quiz: $e');
    }
  }

  /// Records quiz progress using enhanced service with offline-first approach
  Future<void> _recordQuizProgress(QuizResult result) async {
    try {
      debugPrint('🎯 [QuizController] Recording quiz progress for ${_currentSession?.quizType}');

      if (_currentSession?.quizType == QuizType.section && _currentSectionId != null) {
        // This is a section quiz - use section completion method
        await ProgressTrackingService.instance.recordSectionQuizCompletion(
          result: result,
          sectionId: _currentSectionId!,
        );
        debugPrint('✅ [QuizController] Section quiz progress recorded for section: $_currentSectionId');
      } else if (_currentSession?.quizType == QuizType.topic && _currentTopicId != null) {
        // This is a topic quiz - use topic completion method
        await ProgressTrackingService.instance.recordQuizCompletion(
          result: result,
          topicId: _currentTopicId!,
          sectionId: _currentSectionId, // Pass section ID if available
        );
        debugPrint('✅ [QuizController] Topic quiz progress recorded for topic: $_currentTopicId');
      } else {
        debugPrint('⚠️ [QuizController] No progress tracking context available or unknown quiz type');
      }
    } catch (e) {
      debugPrint('❌ [QuizController] Error recording quiz progress: $e');
      // Don't rethrow - progress tracking failures shouldn't prevent quiz completion
    }
  }

  /// Abandons the current quiz session
  Future<void> abandonQuiz() async {
    if (_disposed) return;

    _lastError = null;

    try {
      // Clear any active session to prevent conflicts
      if (_currentSession != null) {
        if (_currentSession!.status == QuizSessionStatus.inProgress ||
            _currentSession!.status == QuizSessionStatus.paused) {
          // Session was active, so we need to clean it up
          await _cleanupCurrentSession();
        }
      }
    } catch (e) {
      // If cleanup fails, force cleanup
      _forceCleanup();
    }

    _safeNotifyListeners();
  }

  /// Clears results and session state for new quiz
  void clearResults() {
    if (_disposed) return;

    _lastResult = null;
    _lastError = null;
    _currentTopicId = null;
    _currentSectionId = null;

    // Ensure no active session when clearing results
    if (_currentSession != null) {
      try {
        _forceCleanup();
      } catch (e) {
        // Ignore cleanup errors when force clearing
      }
    }

    _safeNotifyListeners();
  }

  /// Gets quiz statistics for display
  Map<String, dynamic> getQuizStatistics() {
    if (_currentSession == null) {
      return <String, dynamic>{};
    }

    // For completed quiz, use result stats
    if (_lastResult != null) {
      return <String, dynamic>{
        'answered': _lastResult!.questionsAnswered,
        'total': _lastResult!.totalQuestions,
        'correct': _lastResult!.questionsCorrect,
        'accuracy': _lastResult!.accuracy,
        'progress': 1.0, // Completed
        'timeElapsed': _lastResult!.timeSpent.inSeconds,
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
    };
  }

  /// Method for quiz results widget compatibility
  Map<String, dynamic> getCurrentPerformanceStats() {
    return getQuizStatistics();
  }

  /// Private method to properly clean up current session
  Future<void> _cleanupCurrentSession() async {
    if (_currentSession == null) return;

    try {
      // Remove listener to prevent notifications during cleanup
      _currentSession!.removeListener(_onSessionChanged);

      // Clear session reference
      _currentSession = null;

      // Clear timing data
      _questionStartTimes.clear();
    } catch (e) {
      // If cleanup fails, force cleanup
      _forceCleanup();
      rethrow;
    }
  }

  /// Force cleanup method for when normal cleanup fails
  void _forceCleanup() {
    // Remove listener if session exists
    if (_currentSession != null) {
      try {
        _currentSession!.removeListener(_onSessionChanged);
      } catch (e) {
        // Ignore errors during force cleanup
      }
    }

    // Clear all state
    _currentSession = null;
    _questionStartTimes.clear();
    _isProcessingAnswer = false;
    _currentTopicId = null;
    _currentSectionId = null;
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
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    // Set disposed flag first to prevent any further operations
    _disposed = true;

    // Proper cleanup on disposal
    try {
      if (_currentSession != null) {
        _cleanupCurrentSession();
      }
    } catch (e) {
      _forceCleanup();
    }
    super.dispose();
  }
}