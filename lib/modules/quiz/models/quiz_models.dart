import 'package:flutter/foundation.dart';
import 'question_models.dart';
import 'quiz_enums.dart';

/// Base quiz model containing all quiz-related data
class Quiz {
  final String id;
  final QuizType type;
  final String sectionId;
  final String? topicId;
  final List<Question> questions;
  final Map<String, Answer> answers;
  final DateTime startTime;
  final DateTime? endTime;
  final QuizStatus status;
  final int currentQuestionIndex;
  final QuizMetadata metadata;

  Quiz({
    required this.id,
    required this.type,
    required this.sectionId,
    this.topicId,
    required this.questions,
    Map<String, Answer>? answers,
    DateTime? startTime,
    this.endTime,
    this.status = QuizStatus.notStarted,
    this.currentQuestionIndex = 0,
    required this.metadata,
  })  : answers = answers ?? {},
        startTime = startTime ?? DateTime.now();



    /// Get accuracy percentage
    double get accuracy {
    if (questions.isEmpty) return 0.0;
    final correctCount = answers.values.where((a) => a.isCorrect).length;
    return (correctCount / questions.length) * 100;
    }
  /// Calculate current score
  double get score {
    if (questions.isEmpty) return 0.0;
    
    double totalPoints = 0;
    double earnedPoints = 0;
    
    for (final question in questions) {
      totalPoints += question.pointValue;
      final answer = answers[question.id];
      if (answer != null) {
        earnedPoints += answer.earnedPoints;
      }
    }
    
    return totalPoints > 0 ? (earnedPoints / totalPoints) * 100 : 0.0;
  }

  /// Get progress percentage
  double get progress {
    if (questions.isEmpty) return 0.0;
    return (answers.length / questions.length) * 100;
  }

  /// Get time spent on quiz
  Duration get timeSpent {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Check if quiz is complete
  bool get isComplete => answers.length == questions.length;

  /// Get current question
  Question? get currentQuestion {
    if (currentQuestionIndex >= 0 && currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  /// Create a copy with updated values
  Quiz copyWith({
    String? id,
    QuizType? type,
    String? sectionId,
    String? topicId,
    List<Question>? questions,
    Map<String, Answer>? answers,
    DateTime? startTime,
    DateTime? endTime,
    QuizStatus? status,
    int? currentQuestionIndex,
    QuizMetadata? metadata,
  }) {
    return Quiz(
      id: id ?? this.id,
      type: type ?? this.type,
      sectionId: sectionId ?? this.sectionId,
      topicId: topicId ?? this.topicId,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'sectionId': sectionId,
      'topicId': topicId,
      'questions': questions.map((q) => q.toJson()).toList(),
      'answers': answers.map((key, value) => MapEntry(key, value.toJson())),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.toString(),
      'currentQuestionIndex': currentQuestionIndex,
      'metadata': metadata.toJson(),
    };
  }

  /// Create from JSON
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      type: QuizType.values.firstWhere(
        (t) => t.toString() == json['type'],
      ),
      sectionId: json['sectionId'],
      topicId: json['topicId'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      answers: (json['answers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Answer.fromJson(value)),
      ),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
      status: QuizStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
      ),
      currentQuestionIndex: json['currentQuestionIndex'],
      metadata: QuizMetadata.fromJson(json['metadata']),
    );
  }
}

/// Metadata for quiz configuration and tracking
class QuizMetadata {
  final String title;
  final String description;
  final int estimatedMinutes;
  final DifficultyLevel difficulty;
  final List<String> coveredTopics;
  final Map<String, dynamic> customData;

  const QuizMetadata({
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.coveredTopics,
    this.customData = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'difficulty': difficulty.toString(),
      'coveredTopics': coveredTopics,
      'customData': customData,
    };
  }

  factory QuizMetadata.fromJson(Map<String, dynamic> json) {
    return QuizMetadata(
      title: json['title'],
      description: json['description'],
      estimatedMinutes: json['estimatedMinutes'],
      difficulty: DifficultyLevel.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
      ),
      coveredTopics: List<String>.from(json['coveredTopics']),
      customData: json['customData'] ?? {},
    );
  }
}

/// Represents a user's answer to a question
class Answer {
  final String questionId;
  final dynamic value;
  final DateTime timestamp;
  final double earnedPoints;
  final bool isCorrect;
  final String? feedback;

  const Answer({
    required this.questionId,
    required this.value,
    required this.timestamp,
    required this.earnedPoints,
    required this.isCorrect,
    this.feedback,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'earnedPoints': earnedPoints,
      'isCorrect': isCorrect,
      'feedback': feedback,
    };
  }

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      questionId: json['questionId'],
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      earnedPoints: json['earnedPoints'].toDouble(),
      isCorrect: json['isCorrect'],
      feedback: json['feedback'],
    );
  }
}

/// Summary of quiz results
class QuizResult {
  final String quizId;
  final double score;
  final Duration timeSpent;
  final Map<String, Answer> answers;
  final DateTime completedAt;
  final List<String> strengths;
  final List<String> areasForImprovement;

  const QuizResult({
    required this.quizId,
    required this.score,
    required this.timeSpent,
    required this.answers,
    required this.completedAt,
    required this.strengths,
    required this.areasForImprovement,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'score': score,
      'timeSpent': timeSpent.inSeconds,
      'answers': answers.map((key, value) => MapEntry(key, value.toJson())),
      'completedAt': completedAt.toIso8601String(),
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'],
      score: json['score'].toDouble(),
      timeSpent: Duration(seconds: json['timeSpent']),
      answers: (json['answers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Answer.fromJson(value)),
      ),
      completedAt: DateTime.parse(json['completedAt']),
      strengths: List<String>.from(json['strengths']),
      areasForImprovement: List<String>.from(json['areasForImprovement']),
    );
  }
}

/// Entry in quiz history
class QuizHistoryEntry {
  final String quizId;
  final String sectionId;
  final String? topicId;
  final QuizType type;
  final String title;
  final DateTime completedAt;
  final double score;
  final int questionsAnswered;
  final int totalQuestions;
  final Duration timeSpent;
  final double accuracy;

  const QuizHistoryEntry({
    required this.quizId,
    required this.sectionId,
    this.topicId,
    required this.type,
    required this.title,
    required this.completedAt,
    required this.score,
    required this.questionsAnswered,
    required this.totalQuestions,
    required this.timeSpent,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'sectionId': sectionId,
      'topicId': topicId,
      'type': type.toString(),
      'title': title,
      'completedAt': completedAt.toIso8601String(),
      'score': score,
      'questionsAnswered': questionsAnswered,
      'totalQuestions': totalQuestions,
      'timeSpent': timeSpent.inSeconds,
      'accuracy': accuracy,
    };
  }

  factory QuizHistoryEntry.fromJson(Map<String, dynamic> json) {
    return QuizHistoryEntry(
      quizId: json['quizId'],
      sectionId: json['sectionId'],
      topicId: json['topicId'],
      type: QuizType.values.firstWhere(
        (t) => t.toString() == json['type'],
      ),
      title: json['title'],
      completedAt: DateTime.parse(json['completedAt']),
      score: json['score'].toDouble(),
      questionsAnswered: json['questionsAnswered'],
      totalQuestions: json['totalQuestions'],
      timeSpent: Duration(seconds: json['timeSpent']),
      accuracy: json['accuracy'].toDouble(),
    );
  }
}

/// Quiz statistics
class QuizStatistics {
  final int totalQuizzes;
  final double totalScore;
  final Duration totalTimeSpent;
  final double averageScore;
  final Duration averageTimePerQuiz;
  final double bestScore;
  final double worstScore;
  final int totalQuestionsAnswered;
  final int correctAnswers;
  final DateTime? lastQuizDate;

  const QuizStatistics({
    required this.totalQuizzes,
    required this.totalScore,
    required this.totalTimeSpent,
    required this.averageScore,
    required this.averageTimePerQuiz,
    required this.bestScore,
    required this.worstScore,
    required this.totalQuestionsAnswered,
    required this.correctAnswers,
    this.lastQuizDate,
  });

  factory QuizStatistics.empty() {
    return QuizStatistics(
      totalQuizzes: 0,
      totalScore: 0.0,
      totalTimeSpent: Duration.zero,
      averageScore: 0.0,
      averageTimePerQuiz: Duration.zero,
      bestScore: 0.0,
      worstScore: 0.0,
      totalQuestionsAnswered: 0,
      correctAnswers: 0,
      lastQuizDate: null,
    );
  }

  double get accuracy {
    if (totalQuestionsAnswered == 0) return 0.0;
    return (correctAnswers / totalQuestionsAnswered) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuizzes': totalQuizzes,
      'totalScore': totalScore,
      'totalTimeSpent': totalTimeSpent.inSeconds,
      'averageScore': averageScore,
      'averageTimePerQuiz': averageTimePerQuiz.inSeconds,
      'bestScore': bestScore,
      'worstScore': worstScore,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'correctAnswers': correctAnswers,
      'lastQuizDate': lastQuizDate?.toIso8601String(),
    };
  }

  factory QuizStatistics.fromJson(Map<String, dynamic> json) {
    return QuizStatistics(
      totalQuizzes: json['totalQuizzes'] ?? 0,
      totalScore: (json['totalScore'] ?? 0).toDouble(),
      totalTimeSpent: Duration(seconds: json['totalTimeSpent'] ?? 0),
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      averageTimePerQuiz: Duration(seconds: json['averageTimePerQuiz'] ?? 0),
      bestScore: (json['bestScore'] ?? 0).toDouble(),
      worstScore: (json['worstScore'] ?? 0).toDouble(),
      totalQuestionsAnswered: json['totalQuestionsAnswered'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      lastQuizDate: json['lastQuizDate'] != null 
          ? DateTime.parse(json['lastQuizDate']) 
          : null,
    );
  }
}

/// Validation result for question answers
class AnswerValidation {
  final bool isCorrect;
  final double earnedPoints;
  final String? feedback;
  final Map<String, dynamic> details;

  const AnswerValidation({
    required this.isCorrect,
    required this.earnedPoints,
    this.feedback,
    this.details = const {},
  });
}
