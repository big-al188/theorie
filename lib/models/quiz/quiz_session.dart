// lib/models/quiz/quiz_session.dart

import 'package:flutter/foundation.dart';
import 'quiz_question.dart';
import 'quiz_result.dart';

/// Enum representing the current state of a quiz session
enum QuizSessionStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  abandoned,
}

/// Enum representing different quiz types
enum QuizType {
  section,
  topic,
  refresher,
  custom,
  practice,
}

/// Represents a user's answer to a question during a quiz session
class QuestionAnswer {
  const QuestionAnswer({
    required this.questionId,
    required this.answer,
    required this.answeredAt,
    this.timeSpent,
    this.hintsUsed = 0,
    this.isSkipped = false,
  });

  /// ID of the question being answered
  final String questionId;

  /// The user's answer
  final dynamic answer;

  /// When the answer was submitted
  final DateTime answeredAt;

  /// Time spent on this question
  final Duration? timeSpent;

  /// Number of hints used for this question
  final int hintsUsed;

  /// Whether the question was skipped
  final bool isSkipped;

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': _serializeAnswer(answer),
      'answeredAt': answeredAt.toIso8601String(),
      'timeSpent': timeSpent?.inMilliseconds,
      'hintsUsed': hintsUsed,
      'isSkipped': isSkipped,
    };
  }

  /// Serializes different answer types to JSON-compatible format
  dynamic _serializeAnswer(dynamic answer) {
    if (answer == null) return null;
    if (answer is String || answer is num || answer is bool) return answer;
    if (answer is List) return answer.map(_serializeAnswer).toList();
    if (answer is Map)
      return answer.map((k, v) => MapEntry(k.toString(), _serializeAnswer(v)));
    // For complex objects, convert to string representation
    return answer.toString();
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      questionId: json['questionId'] as String,
      answer: json['answer'],
      answeredAt: DateTime.parse(json['answeredAt'] as String),
      timeSpent: json['timeSpent'] != null
          ? Duration(milliseconds: json['timeSpent'] as int)
          : null,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      isSkipped: json['isSkipped'] as bool? ?? false,
    );
  }
}

/// Manages the state of an active quiz session
///
/// This class tracks all aspects of a quiz being taken including:
/// - Question progression and navigation
/// - User answers and timing
/// - Score calculation and progress tracking
/// - Session persistence and recovery
class QuizSession extends ChangeNotifier {
  QuizSession({
    required this.id,
    required this.quizType,
    required this.questions,
    this.title,
    this.description,
    this.allowReview = true,
    this.allowSkip = true,
    this.timeLimit,
    this.passingScore = 0.7,
  })  : assert(questions.isNotEmpty, 'Quiz must have at least one question'),
        _currentQuestionIndex = 0,
        _status = QuizSessionStatus.notStarted,
        _answers = {},
        _startTime = null,
        _endTime = null,
        _lastActivityTime = DateTime.now();

  /// Unique identifier for this quiz session
  final String id;

  /// Type of quiz being taken
  final QuizType quizType;

  /// List of questions in this quiz
  final List<QuizQuestion> questions;

  /// Optional title for the quiz
  final String? title;

  /// Optional description of the quiz
  final String? description;

  /// Whether users can review answers before submitting
  final bool allowReview;

  /// Whether users can skip questions
  final bool allowSkip;

  /// Optional time limit for the entire quiz (in minutes)
  final int? timeLimit;

  /// Minimum score required to pass (0.0 to 1.0)
  final double passingScore;

  // Private state variables
  int _currentQuestionIndex;
  QuizSessionStatus _status;
  Map<String, QuestionAnswer> _answers;
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime _lastActivityTime;

  // Getters for accessing state
  int get currentQuestionIndex => _currentQuestionIndex;
  QuizSessionStatus get status => _status;
  Map<String, QuestionAnswer> get answers => Map.unmodifiable(_answers);
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  DateTime get lastActivityTime => _lastActivityTime;

  /// Current question being displayed
  QuizQuestion get currentQuestion => questions[_currentQuestionIndex];

  /// Total number of questions
  int get totalQuestions => questions.length;

  /// Number of questions answered (including skipped)
  int get questionsAnswered => _answers.length;

  /// Number of questions skipped
  int get questionsSkipped => _answers.values.where((a) => a.isSkipped).length;

  /// Whether there are more questions to answer
  bool get hasNextQuestion => _currentQuestionIndex < questions.length - 1;

  /// Whether there are previous questions to review
  bool get hasPreviousQuestion => _currentQuestionIndex > 0;

  /// Whether the quiz is completed
  bool get isCompleted => _status == QuizSessionStatus.completed;

  /// Whether the quiz is in progress
  bool get isInProgress => _status == QuizSessionStatus.inProgress;

  /// Total time elapsed (if started)
  Duration? get timeElapsed {
    if (_startTime == null) return null;
    final endTime = _endTime ?? DateTime.now();
    return endTime.difference(_startTime!);
  }

  /// Time remaining (if time limit is set)
  Duration? get timeRemaining {
    if (timeLimit == null || _startTime == null) return null;
    final totalTime = Duration(minutes: timeLimit!);
    final elapsed = timeElapsed!;
    final remaining = totalTime - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether the time limit has been exceeded
  bool get isTimeExpired {
    final remaining = timeRemaining;
    return remaining != null && remaining <= Duration.zero;
  }

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => questionsAnswered / totalQuestions;

  /// Starts the quiz session
  void start() {
    if (_status != QuizSessionStatus.notStarted) {
      throw StateError('Quiz can only be started from notStarted state');
    }

    _status = QuizSessionStatus.inProgress;
    _startTime = DateTime.now();
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Pauses the quiz session
  void pause() {
    if (_status != QuizSessionStatus.inProgress) {
      throw StateError('Quiz can only be paused when in progress');
    }

    _status = QuizSessionStatus.paused;
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Resumes the quiz session
  void resume() {
    if (_status != QuizSessionStatus.paused) {
      throw StateError('Quiz can only be resumed when paused');
    }

    _status = QuizSessionStatus.inProgress;
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Submits an answer for the current question
  void submitAnswer(dynamic answer, {Duration? timeSpent, int hintsUsed = 0}) {
    if (_status != QuizSessionStatus.inProgress) {
      throw StateError('Cannot submit answer when quiz is not in progress');
    }

    final questionAnswer = QuestionAnswer(
      questionId: currentQuestion.id,
      answer: answer,
      answeredAt: DateTime.now(),
      timeSpent: timeSpent,
      hintsUsed: hintsUsed,
      isSkipped: false,
    );

    _answers[currentQuestion.id] = questionAnswer;
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Skips the current question
  void skipQuestion() {
    if (!allowSkip) {
      throw StateError('Skipping is not allowed for this quiz');
    }

    if (_status != QuizSessionStatus.inProgress) {
      throw StateError('Cannot skip question when quiz is not in progress');
    }

    final questionAnswer = QuestionAnswer(
      questionId: currentQuestion.id,
      answer: null,
      answeredAt: DateTime.now(),
      isSkipped: true,
    );

    _answers[currentQuestion.id] = questionAnswer;
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Navigates to the next question
  bool nextQuestion() {
    if (!hasNextQuestion) return false;

    _currentQuestionIndex++;
    _lastActivityTime = DateTime.now();
    notifyListeners();
    return true;
  }

  /// Navigates to the previous question
  bool previousQuestion() {
    if (!hasPreviousQuestion) return false;

    _currentQuestionIndex--;
    _lastActivityTime = DateTime.now();
    notifyListeners();
    return true;
  }

  /// Navigates to a specific question by index
  void goToQuestion(int index) {
    if (index < 0 || index >= questions.length) {
      throw ArgumentError('Question index out of range: $index');
    }

    _currentQuestionIndex = index;
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Completes the quiz and returns the result
  QuizResult complete() {
    if (_status == QuizSessionStatus.completed) {
      throw StateError('Quiz is already completed');
    }

    _status = QuizSessionStatus.completed;
    _endTime = DateTime.now();
    _lastActivityTime = DateTime.now();

    final result = QuizResult.fromSession(this);
    notifyListeners();
    return result;
  }

  /// Abandons the quiz session
  void abandon() {
    _status = QuizSessionStatus.abandoned;
    _endTime = DateTime.now();
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Gets the answer for a specific question
  QuestionAnswer? getAnswerForQuestion(String questionId) {
    return _answers[questionId];
  }

  /// Checks if a specific question has been answered
  bool isQuestionAnswered(String questionId) {
    return _answers.containsKey(questionId);
  }

  /// Returns all unanswered questions
  List<QuizQuestion> getUnansweredQuestions() {
    return questions.where((q) => !isQuestionAnswered(q.id)).toList();
  }

  /// Serializes the session to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizType': quizType.name,
      'questions': questions.map((q) => q.toJson()).toList(),
      'title': title,
      'description': description,
      'allowReview': allowReview,
      'allowSkip': allowSkip,
      'timeLimit': timeLimit,
      'passingScore': passingScore,
      'currentQuestionIndex': _currentQuestionIndex,
      'status': _status.name,
      'answers': _answers.map((k, v) => MapEntry(k, v.toJson())),
      'startTime': _startTime?.toIso8601String(),
      'endTime': _endTime?.toIso8601String(),
      'lastActivityTime': _lastActivityTime.toIso8601String(),
    };
  }

  /// Creates a QuizSession from JSON data
  static QuizSession fromJson(Map<String, dynamic> json) {
    // Note: This would need to be implemented with proper question deserialization
    // based on the actual question types in the application
    throw UnimplementedError(
        'fromJson implementation depends on question type factories');
  }
}
