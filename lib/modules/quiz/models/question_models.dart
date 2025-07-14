import 'package:flutter/foundation.dart';
import 'quiz_enums.dart';

/// Abstract base class for all question types
abstract class Question {
  final String id;
  final String text;
  final String topicId;
  final DifficultyLevel difficulty;
  final double pointValue;
  final String? explanation;
  final List<String> relatedConceptIds;
  final Map<String, dynamic> metadata;

  const Question({
    required this.id,
    required this.text,
    required this.topicId,
    required this.difficulty,
    required this.pointValue,
    this.explanation,
    this.relatedConceptIds = const [],
    this.metadata = const {},
  });

  /// Get question type
  QuestionType get type;

  /// Validate an answer and return result
  AnswerValidation validateAnswer(dynamic answer);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'text': text,
      'topicId': topicId,
      'difficulty': difficulty.toString(),
      'pointValue': pointValue,
      'explanation': explanation,
      'relatedConceptIds': relatedConceptIds,
      'metadata': metadata,
    };
  }

  /// Factory method to create appropriate question type from JSON
  static Question fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = QuestionType.values.firstWhere(
      (t) => t.toString() == typeStr,
    );

    switch (type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestion.fromJson(json);
      case QuestionType.scaleInteractive:
        return ScaleInteractiveQuestion.fromJson(json);
      case QuestionType.chordInteractive:
        return ChordInteractiveQuestion.fromJson(json);
      default:
        throw UnimplementedError('Question type $type not implemented');
    }
  }
}

/// Multiple choice question with answer pool system
class MultipleChoiceQuestion extends Question {
  final String correctAnswer;
  final List<String> correctAnswerVariations;
  final List<String> incorrectAnswerPool;
  final int numberOfChoices;
  final bool shuffleAnswers;

  const MultipleChoiceQuestion({
    required String id,
    required String text,
    required String topicId,
    required DifficultyLevel difficulty,
    required double pointValue,
    required this.correctAnswer,
    this.correctAnswerVariations = const [],
    required this.incorrectAnswerPool,
    this.numberOfChoices = 4,
    this.shuffleAnswers = true,
    String? explanation,
    List<String> relatedConceptIds = const [],
    Map<String, dynamic> metadata = const {},
  }) : super(
          id: id,
          text: text,
          topicId: topicId,
          difficulty: difficulty,
          pointValue: pointValue,
          explanation: explanation,
          relatedConceptIds: relatedConceptIds,
          metadata: metadata,
        );

  @override
  QuestionType get type => QuestionType.multipleChoice;

  /// Get all valid correct answers
  List<String> get allCorrectAnswers => [correctAnswer, ...correctAnswerVariations];

  @override
  AnswerValidation validateAnswer(dynamic answer) {
    if (answer is! String) {
      return AnswerValidation(
        isCorrect: false,
        earnedPoints: 0,
        feedback: 'Invalid answer format',
      );
    }

    final isCorrect = allCorrectAnswers.contains(answer);
    return AnswerValidation(
      isCorrect: isCorrect,
      earnedPoints: isCorrect ? pointValue : 0,
      feedback: isCorrect 
          ? 'Correct!' 
          : 'Incorrect. The correct answer is: $correctAnswer',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'correctAnswer': correctAnswer,
      'correctAnswerVariations': correctAnswerVariations,
      'incorrectAnswerPool': incorrectAnswerPool,
      'numberOfChoices': numberOfChoices,
      'shuffleAnswers': shuffleAnswers,
    });
    return json;
  }

  factory MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceQuestion(
      id: json['id'],
      text: json['text'],
      topicId: json['topicId'],
      difficulty: DifficultyLevel.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
      ),
      pointValue: json['pointValue'].toDouble(),
      correctAnswer: json['correctAnswer'],
      correctAnswerVariations: List<String>.from(json['correctAnswerVariations'] ?? []),
      incorrectAnswerPool: List<String>.from(json['incorrectAnswerPool']),
      numberOfChoices: json['numberOfChoices'] ?? 4,
      shuffleAnswers: json['shuffleAnswers'] ?? true,
      explanation: json['explanation'],
      relatedConceptIds: List<String>.from(json['relatedConceptIds'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Interactive question for scale exercises
class ScaleInteractiveQuestion extends Question {
  final String scaleKey;
  final String scaleType;
  final ScaleDisplayMode displayMode;
  final ScaleInteractionMode interactionMode;
  final Map<String, dynamic> initialState;
  final Map<String, dynamic> expectedAnswer;
  final bool allowPartialCredit;

  const ScaleInteractiveQuestion({
    required String id,
    required String text,
    required String topicId,
    required DifficultyLevel difficulty,
    required double pointValue,
    required this.scaleKey,
    required this.scaleType,
    required this.displayMode,
    required this.interactionMode,
    required this.initialState,
    required this.expectedAnswer,
    this.allowPartialCredit = true,
    String? explanation,
    List<String> relatedConceptIds = const [],
    Map<String, dynamic> metadata = const {},
  }) : super(
          id: id,
          text: text,
          topicId: topicId,
          difficulty: difficulty,
          pointValue: pointValue,
          explanation: explanation,
          relatedConceptIds: relatedConceptIds,
          metadata: metadata,
        );

  @override
  QuestionType get type => QuestionType.scaleInteractive;

  @override
  AnswerValidation validateAnswer(dynamic answer) {
    if (answer is! Map<String, dynamic>) {
      return AnswerValidation(
        isCorrect: false,
        earnedPoints: 0,
        feedback: 'Invalid answer format',
      );
    }

    // Compare answer with expected
    double correctPercentage = _calculateCorrectPercentage(answer);
    bool isCorrect = correctPercentage >= 1.0;
    double earnedPoints = allowPartialCredit 
        ? pointValue * correctPercentage
        : (isCorrect ? pointValue : 0);

    return AnswerValidation(
      isCorrect: isCorrect,
      earnedPoints: earnedPoints,
      feedback: _generateFeedback(correctPercentage),
      details: {
        'correctPercentage': correctPercentage,
        'expectedAnswer': expectedAnswer,
      },
    );
  }

  double _calculateCorrectPercentage(Map<String, dynamic> answer) {
    // Implementation depends on interaction mode
    // This is a simplified version
    int totalExpected = expectedAnswer.length;
    int correctCount = 0;

    expectedAnswer.forEach((key, expectedValue) {
      if (answer[key] == expectedValue) {
        correctCount++;
      }
    });

    return totalExpected > 0 ? correctCount / totalExpected : 0.0;
  }

  String _generateFeedback(double correctPercentage) {
    if (correctPercentage >= 1.0) {
      return 'Perfect! You got all the notes/intervals correct.';
    } else if (correctPercentage >= 0.8) {
      return 'Almost there! You got ${(correctPercentage * 100).toInt()}% correct.';
    } else if (correctPercentage >= 0.5) {
      return 'Good effort! You got ${(correctPercentage * 100).toInt()}% correct.';
    } else {
      return 'Keep practicing! Review the scale pattern and try again.';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'scaleKey': scaleKey,
      'scaleType': scaleType,
      'displayMode': displayMode.toString(),
      'interactionMode': interactionMode.toString(),
      'initialState': initialState,
      'expectedAnswer': expectedAnswer,
      'allowPartialCredit': allowPartialCredit,
    });
    return json;
  }

  factory ScaleInteractiveQuestion.fromJson(Map<String, dynamic> json) {
    return ScaleInteractiveQuestion(
      id: json['id'],
      text: json['text'],
      topicId: json['topicId'],
      difficulty: DifficultyLevel.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
      ),
      pointValue: json['pointValue'].toDouble(),
      scaleKey: json['scaleKey'],
      scaleType: json['scaleType'],
      displayMode: ScaleDisplayMode.values.firstWhere(
        (m) => m.toString() == json['displayMode'],
      ),
      interactionMode: ScaleInteractionMode.values.firstWhere(
        (m) => m.toString() == json['interactionMode'],
      ),
      initialState: json['initialState'],
      expectedAnswer: json['expectedAnswer'],
      allowPartialCredit: json['allowPartialCredit'] ?? true,
      explanation: json['explanation'],
      relatedConceptIds: List<String>.from(json['relatedConceptIds'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Interactive question for chord exercises
class ChordInteractiveQuestion extends Question {
  final String chordName;
  final FretboardMode fretboardMode;
  final Map<String, dynamic> initialState;
  final List<Map<String, dynamic>> acceptablePositions;
  final bool requireExactPosition;

  const ChordInteractiveQuestion({
    required String id,
    required String text,
    required String topicId,
    required DifficultyLevel difficulty,
    required double pointValue,
    required this.chordName,
    required this.fretboardMode,
    required this.initialState,
    required this.acceptablePositions,
    this.requireExactPosition = false,
    String? explanation,
    List<String> relatedConceptIds = const [],
    Map<String, dynamic> metadata = const {},
  }) : super(
          id: id,
          text: text,
          topicId: topicId,
          difficulty: difficulty,
          pointValue: pointValue,
          explanation: explanation,
          relatedConceptIds: relatedConceptIds,
          metadata: metadata,
        );

  @override
  QuestionType get type => QuestionType.chordInteractive;

  @override
  AnswerValidation validateAnswer(dynamic answer) {
    if (answer is! Map<String, dynamic>) {
      return AnswerValidation(
        isCorrect: false,
        earnedPoints: 0,
        feedback: 'Invalid answer format',
      );
    }

    // Check if answer matches any acceptable position
    bool isCorrect = false;
    for (final acceptablePosition in acceptablePositions) {
      if (_positionsMatch(answer, acceptablePosition)) {
        isCorrect = true;
        break;
      }
    }

    return AnswerValidation(
      isCorrect: isCorrect,
      earnedPoints: isCorrect ? pointValue : 0,
      feedback: isCorrect 
          ? 'Correct! That\'s a valid $chordName chord.'
          : 'Not quite. Try reviewing the $chordName chord shape.',
      details: {
        'submittedPosition': answer,
        'acceptablePositions': acceptablePositions,
      },
    );
  }

  bool _positionsMatch(Map<String, dynamic> pos1, Map<String, dynamic> pos2) {
    // Simplified matching logic
    // In reality, this would compare fret positions, strings, etc.
    return pos1.toString() == pos2.toString();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'chordName': chordName,
      'fretboardMode': fretboardMode.toString(),
      'initialState': initialState,
      'acceptablePositions': acceptablePositions,
      'requireExactPosition': requireExactPosition,
    });
    return json;
  }

  factory ChordInteractiveQuestion.fromJson(Map<String, dynamic> json) {
    return ChordInteractiveQuestion(
      id: json['id'],
      text: json['text'],
      topicId: json['topicId'],
      difficulty: DifficultyLevel.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
      ),
      pointValue: json['pointValue'].toDouble(),
      chordName: json['chordName'],
      fretboardMode: FretboardMode.values.firstWhere(
        (m) => m.toString() == json['fretboardMode'],
      ),
      initialState: json['initialState'],
      acceptablePositions: List<Map<String, dynamic>>.from(
        json['acceptablePositions'],
      ),
      requireExactPosition: json['requireExactPosition'] ?? false,
      explanation: json['explanation'],
      relatedConceptIds: List<String>.from(json['relatedConceptIds'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Result of answer validation
class AnswerValidation {
  final bool isCorrect;
  final double earnedPoints;
  final String feedback;
  final Map<String, dynamic>? details;

  const AnswerValidation({
    required this.isCorrect,
    required this.earnedPoints,
    required this.feedback,
    this.details,
  });
}