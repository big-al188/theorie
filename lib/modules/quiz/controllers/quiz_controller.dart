import 'package:flutter/foundation.dart';
import '../models/quiz_models.dart';
import '../models/question_models.dart';
import '../models/quiz_enums.dart';
import '../services/quiz_storage_service.dart';
import '../services/quiz_analytics_service.dart';

/// Main controller for managing quiz state and flow
class QuizController extends ChangeNotifier {
  final QuizStorageService _storageService;
  final QuizAnalyticsService _analyticsService;

  Quiz? _currentQuiz;
  bool _isSubmitting = false;
  ValidationMode _validationMode = ValidationMode.onSubmit;

  QuizController({
    required QuizStorageService storageService,
    required QuizAnalyticsService analyticsService,
  })  : _storageService = storageService,
        _analyticsService = analyticsService;

  // Getters
  Quiz? get currentQuiz => _currentQuiz;
  bool get hasActiveQuiz => _currentQuiz != null;
  bool get isSubmitting => _isSubmitting;
  ValidationMode get validationMode => _validationMode;

  Question? get currentQuestion => _currentQuiz?.currentQuestion;
  int get currentQuestionIndex => _currentQuiz?.currentQuestionIndex ?? 0;
  int get totalQuestions => _currentQuiz?.questions.length ?? 0;
  double get progress => _currentQuiz?.progress ?? 0.0;
  double get score => _currentQuiz?.score ?? 0.0;
  bool get canGoNext => currentQuestionIndex < totalQuestions - 1;
  bool get canGoPrevious => currentQuestionIndex > 0;
  bool get isComplete => _currentQuiz?.isComplete ?? false;

  /// Start a new quiz
  Future<void> startQuiz(Quiz quiz) async {
    try {
      _currentQuiz = quiz.copyWith(
        status: QuizStatus.inProgress,
        startTime: DateTime.now(),
      );
      
      // Save initial state
      await _storageService.saveQuizProgress(_currentQuiz!);
      
      // Track analytics
      _analyticsService.trackQuizStarted(_currentQuiz!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting quiz: $e');
      rethrow;
    }
  }

  /// Resume a paused quiz
  Future<void> resumeQuiz(String quizId) async {
    try {
      final savedQuiz = await _storageService.getQuizProgress(quizId);
      if (savedQuiz != null) {
        _currentQuiz = savedQuiz.copyWith(
          status: QuizStatus.inProgress,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resuming quiz: $e');
      rethrow;
    }
  }

  /// Submit answer for current question
  Future<void> submitAnswer(dynamic answer) async {
    if (_currentQuiz == null || _isSubmitting) return;

    try {
      _isSubmitting = true;
      notifyListeners();

      final question = currentQuestion;
      if (question == null) return;

      // Validate answer
      final validation = question.validateAnswer(answer);
      
      // Create answer object
      final answerObj = Answer(
        questionId: question.id,
        value: answer,
        timestamp: DateTime.now(),
        earnedPoints: validation.earnedPoints,
        isCorrect: validation.isCorrect,
        feedback: validation.feedback,
      );

      // Update quiz with answer
      final updatedAnswers = Map<String, Answer>.from(_currentQuiz!.answers);
      updatedAnswers[question.id] = answerObj;

      _currentQuiz = _currentQuiz!.copyWith(
        answers: updatedAnswers,
      );

      // Save progress
      await _storageService.saveQuizProgress(_currentQuiz!);

      // Track analytics
      _analyticsService.trackQuestionAnswered(
        quiz: _currentQuiz!,
        question: question,
        answer: answerObj,
      );

      // Auto-advance if validation mode is immediate
      if (_validationMode == ValidationMode.immediate && canGoNext) {
        await Future.delayed(const Duration(seconds: 2));
        await nextQuestion();
      }

    } catch (e) {
      debugPrint('Error submitting answer: $e');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Move to next question
  Future<void> nextQuestion() async {
    if (_currentQuiz == null || !canGoNext) return;

    _currentQuiz = _currentQuiz!.copyWith(
      currentQuestionIndex: currentQuestionIndex + 1,
    );

    await _storageService.saveQuizProgress(_currentQuiz!);
    notifyListeners();
  }

  /// Move to previous question
  Future<void> previousQuestion() async {
    if (_currentQuiz == null || !canGoPrevious) return;

    _currentQuiz = _currentQuiz!.copyWith(
      currentQuestionIndex: currentQuestionIndex - 1,
    );

    await _storageService.saveQuizProgress(_currentQuiz!);
    notifyListeners();
  }

  /// Jump to specific question
  Future<void> jumpToQuestion(int index) async {
    if (_currentQuiz == null || index < 0 || index >= totalQuestions) return;

    _currentQuiz = _currentQuiz!.copyWith(
      currentQuestionIndex: index,
    );

    await _storageService.saveQuizProgress(_currentQuiz!);
    notifyListeners();
  }

  /// Complete the quiz
  Future<QuizResult> completeQuiz() async {
    if (_currentQuiz == null) {
      throw StateError('No active quiz to complete');
    }

    try {
      _isSubmitting = true;
      notifyListeners();

      // Update quiz status
      _currentQuiz = _currentQuiz!.copyWith(
        status: QuizStatus.completed,
        endTime: DateTime.now(),
      );

      // Generate result
      final result = _generateQuizResult(_currentQuiz!);

      // Save completed quiz
      await _storageService.saveCompletedQuiz(_currentQuiz!);
      await _storageService.deleteQuizProgress(_currentQuiz!.id);

      // Track analytics
      _analyticsService.trackQuizCompleted(_currentQuiz!, result);

      // Clear current quiz
      _currentQuiz = null;

      return result;
    } catch (e) {
      debugPrint('Error completing quiz: $e');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Pause the current quiz
  Future<void> pauseQuiz() async {
    if (_currentQuiz == null) return;

    _currentQuiz = _currentQuiz!.copyWith(
      status: QuizStatus.paused,
    );

    await _storageService.saveQuizProgress(_currentQuiz!);
    _analyticsService.trackQuizPaused(_currentQuiz!);
    
    notifyListeners();
  }

  /// Abandon the current quiz
  Future<void> abandonQuiz() async {
    if (_currentQuiz == null) return;

    _currentQuiz = _currentQuiz!.copyWith(
      status: QuizStatus.abandoned,
      endTime: DateTime.now(),
    );

    await _storageService.saveCompletedQuiz(_currentQuiz!);
    await _storageService.deleteQuizProgress(_currentQuiz!.id);
    _analyticsService.trackQuizAbandoned(_currentQuiz!);

    _currentQuiz = null;
    notifyListeners();
  }

  /// Set validation mode
  void setValidationMode(ValidationMode mode) {
    _validationMode = mode;
    notifyListeners();
  }

  /// Get answer for a specific question
  Answer? getAnswerForQuestion(String questionId) {
    return _currentQuiz?.answers[questionId];
  }

  /// Check if a question has been answered
  bool isQuestionAnswered(String questionId) {
    return _currentQuiz?.answers.containsKey(questionId) ?? false;
  }

  /// Get review data for completed quiz
  Map<String, dynamic> getReviewData() {
    if (_currentQuiz == null) return {};

    final reviewData = <String, dynamic>{};
    
    for (final question in _currentQuiz!.questions) {
      final answer = _currentQuiz!.answers[question.id];
      reviewData[question.id] = {
        'question': question,
        'answer': answer,
        'isAnswered': answer != null,
        'isCorrect': answer?.isCorrect ?? false,
        'earnedPoints': answer?.earnedPoints ?? 0,
      };
    }

    return reviewData;
  }

  /// Generate quiz result
  QuizResult _generateQuizResult(Quiz quiz) {
    // Analyze answers to find strengths and weaknesses
    final topicPerformance = <String, List<bool>>{};
    
    for (final question in quiz.questions) {
      final answer = quiz.answers[question.id];
      if (answer != null) {
        topicPerformance.putIfAbsent(question.topicId, () => []);
        topicPerformance[question.topicId]!.add(answer.isCorrect);
      }
    }

    // Calculate strengths and areas for improvement
    final strengths = <String>[];
    final areasForImprovement = <String>[];

    topicPerformance.forEach((topicId, results) {
      final correctCount = results.where((r) => r).length;
      final accuracy = correctCount / results.length;

      if (accuracy >= 0.8) {
        strengths.add(topicId);
      } else if (accuracy < 0.5) {
        areasForImprovement.add(topicId);
      }
    });

    return QuizResult(
      quizId: quiz.id,
      score: quiz.score,
      timeSpent: quiz.timeSpent,
      answers: quiz.answers,
      completedAt: quiz.endTime ?? DateTime.now(),
      strengths: strengths,
      areasForImprovement: areasForImprovement,
    );
  }

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}