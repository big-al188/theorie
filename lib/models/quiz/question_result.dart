// lib/models/quiz/question_result.dart

import 'package:flutter/foundation.dart';

/// Represents the result of validating a quiz question answer
/// Enhanced to support partial credit and detailed scoring for scale strip questions
class QuestionResult {
  const QuestionResult({
    required this.isCorrect,
    required this.userAnswer,
    required this.correctAnswer,
    this.feedback,
    this.explanation,
    this.hints = const [],
    this.timeTaken,
    this.pointsEarned,
    this.maxPoints,
    this.partialCredit = false,
    this.score = 0.0,
    this.detailedFeedback = const {},
    this.improvementSuggestions = const [],
  });

  /// Whether the answer is considered correct (typically score >= 0.7)
  final bool isCorrect;

  /// The answer provided by the user
  final dynamic userAnswer;

  /// The correct answer for comparison
  final dynamic correctAnswer;

  /// Short feedback message about the answer
  final String? feedback;

  /// Detailed explanation of the concept
  final String? explanation;

  /// Additional hints that might help the user
  final List<String> hints;

  /// Time taken to answer the question
  final Duration? timeTaken;

  /// Points earned for this answer
  final double? pointsEarned;

  /// Maximum possible points for this question
  final double? maxPoints;

  /// Whether partial credit was awarded
  final bool partialCredit;

  /// Numerical score from 0.0 to 1.0
  final double score;

  /// Detailed feedback broken down by category
  final Map<String, String> detailedFeedback;

  /// Specific suggestions for improvement
  final List<String> improvementSuggestions;

  /// Get the percentage score as an integer
  int get percentageScore => (score * 100).round();

  /// Get a letter grade based on the score
  String get letterGrade {
    if (score >= 0.97) return 'A+';
    if (score >= 0.93) return 'A';
    if (score >= 0.90) return 'A-';
    if (score >= 0.87) return 'B+';
    if (score >= 0.83) return 'B';
    if (score >= 0.80) return 'B-';
    if (score >= 0.77) return 'C+';
    if (score >= 0.73) return 'C';
    if (score >= 0.70) return 'C-';
    if (score >= 0.67) return 'D+';
    if (score >= 0.63) return 'D';
    if (score >= 0.60) return 'D-';
    return 'F';
  }

  /// Get a descriptive performance level
  String get performanceLevel {
    if (score >= 0.90) return 'Excellent';
    if (score >= 0.80) return 'Good';
    if (score >= 0.70) return 'Satisfactory';
    if (score >= 0.60) return 'Needs Improvement';
    return 'Requires Review';
  }

  /// Whether this result shows mastery of the concept
  bool get showsMastery => score >= 0.85;

  /// Whether this result indicates the user needs more practice
  bool get needsMorePractice => score < 0.70;

  /// Create a copy with updated values
  QuestionResult copyWith({
    bool? isCorrect,
    dynamic userAnswer,
    dynamic correctAnswer,
    String? feedback,
    String? explanation,
    List<String>? hints,
    Duration? timeTaken,
    double? pointsEarned,
    double? maxPoints,
    bool? partialCredit,
    double? score,
    Map<String, String>? detailedFeedback,
    List<String>? improvementSuggestions,
  }) {
    return QuestionResult(
      isCorrect: isCorrect ?? this.isCorrect,
      userAnswer: userAnswer ?? this.userAnswer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      feedback: feedback ?? this.feedback,
      explanation: explanation ?? this.explanation,
      hints: hints ?? this.hints,
      timeTaken: timeTaken ?? this.timeTaken,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      maxPoints: maxPoints ?? this.maxPoints,
      partialCredit: partialCredit ?? this.partialCredit,
      score: score ?? this.score,
      detailedFeedback: detailedFeedback ?? this.detailedFeedback,
      improvementSuggestions: improvementSuggestions ?? this.improvementSuggestions,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'isCorrect': isCorrect,
      'userAnswer': _serializeAnswer(userAnswer),
      'correctAnswer': _serializeAnswer(correctAnswer),
      'feedback': feedback,
      'explanation': explanation,
      'hints': hints,
      'timeTaken': timeTaken?.inMilliseconds,
      'pointsEarned': pointsEarned,
      'maxPoints': maxPoints,
      'partialCredit': partialCredit,
      'score': score,
      'detailedFeedback': detailedFeedback,
      'improvementSuggestions': improvementSuggestions,
    };
  }

  /// Create from JSON
  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      isCorrect: json['isCorrect'] ?? false,
      userAnswer: json['userAnswer'],
      correctAnswer: json['correctAnswer'],
      feedback: json['feedback'],
      explanation: json['explanation'],
      hints: List<String>.from(json['hints'] ?? []),
      timeTaken: json['timeTaken'] != null 
        ? Duration(milliseconds: json['timeTaken']) 
        : null,
      pointsEarned: json['pointsEarned']?.toDouble(),
      maxPoints: json['maxPoints']?.toDouble(),
      partialCredit: json['partialCredit'] ?? false,
      score: json['score']?.toDouble() ?? 0.0,
      detailedFeedback: Map<String, String>.from(json['detailedFeedback'] ?? {}),
      improvementSuggestions: List<String>.from(json['improvementSuggestions'] ?? []),
    );
  }

  /// Helper method to serialize answers for JSON storage
  dynamic _serializeAnswer(dynamic answer) {
    if (answer == null) return null;
    
    // Handle ScaleStripAnswer
    if (answer.runtimeType.toString().contains('ScaleStripAnswer')) {
      try {
        return (answer as dynamic).toJson();
      } catch (e) {
        return answer.toString();
      }
    }
    
    // Handle lists and sets
    if (answer is List || answer is Set) {
      return answer.toList();
    }
    
    // Handle maps
    if (answer is Map) {
      return Map<String, dynamic>.from(answer);
    }
    
    // Default to string representation
    return answer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionResult &&
        other.isCorrect == isCorrect &&
        other.userAnswer == userAnswer &&
        other.correctAnswer == correctAnswer &&
        other.feedback == feedback &&
        other.explanation == explanation &&
        listEquals(other.hints, hints) &&
        other.timeTaken == timeTaken &&
        other.pointsEarned == pointsEarned &&
        other.maxPoints == maxPoints &&
        other.partialCredit == partialCredit &&
        other.score == score &&
        mapEquals(other.detailedFeedback, detailedFeedback) &&
        listEquals(other.improvementSuggestions, improvementSuggestions);
  }

  @override
  int get hashCode => Object.hash(
    isCorrect,
    userAnswer,
    correctAnswer,
    feedback,
    explanation,
    hints,
    timeTaken,
    pointsEarned,
    maxPoints,
    partialCredit,
    score,
    detailedFeedback,
    improvementSuggestions,
  );

  @override
  String toString() {
    return 'QuestionResult('
        'isCorrect: $isCorrect, '
        'score: $score, '
        'partialCredit: $partialCredit, '
        'feedback: $feedback'
        ')';
  }