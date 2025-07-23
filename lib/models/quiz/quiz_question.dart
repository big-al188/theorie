// lib/models/quiz/quiz_question.dart

import 'package:flutter/foundation.dart';

/// Enum representing different question types in the quiz system
enum QuestionType {
  multipleChoice,
  interactive,
  trueFalse,
  fillInBlank,
  scaleStrip, // Add this new type
}

/// Extension to provide display names for question types
extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.interactive:
        return 'Interactive';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.fillInBlank:
        return 'Fill in Blank';
      case QuestionType.scaleStrip:
        return 'Scale Strip';
    }
  }
}



/// Enum representing difficulty levels for questions
enum QuestionDifficulty {
  beginner(1),
  intermediate(2),
  advanced(3),
  expert(4);

  const QuestionDifficulty(this.value);
  final int value;
}

/// Enum representing different music theory topics
enum QuestionTopic {
  notes,
  intervals,
  scales,
  chords,
  keySignatures,
  modes,
  progressions,
  theory,
}

/// Abstract base class for all quiz questions
///
/// This class defines the common interface and properties that all
/// question types must implement. It follows the Template Method pattern
/// to provide consistent behavior across different question types.
abstract class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.topic,
    required this.difficulty,
    required this.pointValue,
    this.explanation,
    this.hints = const [],
    this.tags = const [],
    this.timeLimit,
    this.allowPartialCredit = false,
  });

  /// Unique identifier for the question
  final String id;

  /// The main question text displayed to the user
  final String questionText;

  /// The topic/category this question belongs to
  final QuestionTopic topic;

  /// The difficulty level of this question
  final QuestionDifficulty difficulty;

  /// Points awarded for correct answer
  final int pointValue;

  /// Optional explanation shown after answering
  final String? explanation;

  /// List of hints that can be revealed to help the user
  final List<String> hints;

  /// Tags for additional categorization and filtering
  final List<String> tags;

  /// Optional time limit for answering (in seconds)
  final int? timeLimit;

  /// Whether partial credit can be awarded for this question
  final bool allowPartialCredit;

  /// Returns the type of this question
  QuestionType get type;

  /// Validates if the provided answer is correct
  ///
  /// [userAnswer] - The answer provided by the user
  /// Returns a [QuestionResult] containing validation details
  QuestionResult validateAnswer(dynamic userAnswer);

  /// Returns the correct answer(s) for this question
  /// This is used for showing solutions and generating explanations
  dynamic get correctAnswer;

  /// Returns a list of all possible answers for this question
  /// Used for answer validation and generating incorrect options
  List<dynamic> get possibleAnswers => [correctAnswer];

  /// Calculates the score for a given answer
  ///
  /// [userAnswer] - The answer provided by the user
  /// [timeTaken] - Time taken to answer (optional for time-based scoring)
  /// Returns the score as a percentage (0.0 to 1.0)
  double calculateScore(dynamic userAnswer, {Duration? timeTaken}) {
    final result = validateAnswer(userAnswer);
    if (result.isCorrect) {
      double score = 1.0;

      // Apply time-based scoring if time limit is set
      if (timeLimit != null && timeTaken != null) {
        final timeRatio = timeTaken.inSeconds / timeLimit!;
        if (timeRatio > 1.0) {
          // Overtime penalty
          score *= 0.8;
        } else if (timeRatio < 0.5) {
          // Bonus for quick answers
          score *= 1.1;
        }
      }

      return score.clamp(0.0, 1.0);
    }

    // Check for partial credit
    if (allowPartialCredit && result.partialCreditScore != null) {
      return result.partialCreditScore!.clamp(0.0, 1.0);
    }

    return 0.0;
  }

  /// Returns a JSON representation of this question
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'topic': topic.name,
      'difficulty': difficulty.name,
      'pointValue': pointValue,
      'explanation': explanation,
      'hints': hints,
      'tags': tags,
      'timeLimit': timeLimit,
      'allowPartialCredit': allowPartialCredit,
      'type': type.name,
    };
  }

  /// Creates a QuizQuestion from JSON data
  /// This is a factory method that should be overridden by subclasses
  static QuizQuestion fromJson(Map<String, dynamic> json) {
    throw UnimplementedError(
        'fromJson must be implemented by concrete question classes');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizQuestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuizQuestion(id: $id, type: $type, topic: $topic, difficulty: $difficulty)';
  }
}

/// Represents the result of validating a question answer
class QuestionResult {
  const QuestionResult({
    required this.isCorrect,
    required this.userAnswer,
    required this.correctAnswer,
    this.partialCreditScore,
    this.feedback,
    this.explanation,
  });

  /// Whether the answer is completely correct
  final bool isCorrect;

  /// The answer provided by the user
  final dynamic userAnswer;

  /// The correct answer for the question
  final dynamic correctAnswer;

  /// Score for partial credit (0.0 to 1.0), null if not applicable
  final double? partialCreditScore;

  /// Immediate feedback message for the user
  final String? feedback;

  /// Detailed explanation of the answer
  final String? explanation;

  /// Whether any credit should be awarded
  bool get hasCredit =>
      isCorrect || (partialCreditScore != null && partialCreditScore! > 0);

  /// The final score considering partial credit
  double get finalScore {
    if (isCorrect) return 1.0;
    return partialCreditScore ?? 0.0;
  }

  @override
  String toString() {
    return 'QuestionResult(isCorrect: $isCorrect, score: $finalScore)';
  }
}
