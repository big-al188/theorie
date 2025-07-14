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