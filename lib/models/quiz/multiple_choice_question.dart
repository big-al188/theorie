// lib/models/quiz/multiple_choice_question.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'quiz_question.dart';

/// Represents a single answer option in a multiple choice question
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
  });

  /// Unique identifier for this option
  final String id;

  /// The text displayed for this option
  final String text;

  /// Whether this option is correct
  final bool isCorrect;

  /// Optional explanation for why this option is correct/incorrect
  final String? explanation;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
      'explanation': explanation,
    };
  }

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool,
      explanation: json['explanation'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnswerOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AnswerOption(id: $id, text: $text, isCorrect: $isCorrect)';
}

/// Multiple choice question implementation
///
/// This class represents a question with multiple answer options where
/// one or more options can be correct. It supports single-select and
/// multi-select modes, randomized option order, and detailed feedback.
class MultipleChoiceQuestion extends QuizQuestion {
  MultipleChoiceQuestion({
    required super.id,
    required super.questionText,
    required super.topic,
    required super.difficulty,
    required super.pointValue,
    required this.options,
    super.explanation,
    super.hints,
    super.tags,
    super.timeLimit,
    super.allowPartialCredit = false,
    this.multiSelect = false,
    this.randomizeOptions = true,
    this.minimumCorrectForCredit = 1,
  })  : assert(options.length >= 2,
            'Multiple choice questions must have at least 2 options'),
        assert(options.where((o) => o.isCorrect).isNotEmpty,
            'At least one option must be correct');

  /// List of answer options
  final List<AnswerOption> options;

  /// Whether multiple options can be selected
  final bool multiSelect;

  /// Whether to randomize the order of options when displaying
  final bool randomizeOptions;

  /// Minimum number of correct answers needed for partial credit (multi-select only)
  final int minimumCorrectForCredit;

  @override
  QuestionType get type => QuestionType.multipleChoice;

  /// Returns all correct options
  List<AnswerOption> get correctOptions =>
      options.where((o) => o.isCorrect).toList();

  /// Returns all incorrect options
  List<AnswerOption> get incorrectOptions =>
      options.where((o) => !o.isCorrect).toList();

  @override
  List<AnswerOption> get correctAnswer => correctOptions;

  @override
  List<AnswerOption> get possibleAnswers => options;

  /// Returns options in display order (randomized if enabled)
  List<AnswerOption> getDisplayOptions({int? seed}) {
    if (!randomizeOptions) return options;

    final displayOptions = List<AnswerOption>.from(options);
    if (seed != null) {
      displayOptions.shuffle(Random(seed));
    } else {
      displayOptions.shuffle();
    }
    return displayOptions;
  }

  @override
  QuestionResult validateAnswer(dynamic userAnswer) {
    if (userAnswer == null) {
      return QuestionResult(
        isCorrect: false,
        userAnswer: userAnswer,
        correctAnswer: correctAnswer,
        feedback: 'Please select an answer',
      );
    }

    // Handle single selection
    if (!multiSelect) {
      return _validateSingleAnswer(userAnswer);
    }

    // Handle multiple selection
    return _validateMultipleAnswers(userAnswer);
  }

  /// Validates a single answer selection
  QuestionResult _validateSingleAnswer(dynamic userAnswer) {
    late AnswerOption selectedOption;

    // Handle different input types
    if (userAnswer is AnswerOption) {
      selectedOption = userAnswer;
    } else if (userAnswer is String) {
      final option = options.firstWhere(
        (o) => o.id == userAnswer,
        orElse: () => throw ArgumentError('Invalid option ID: $userAnswer'),
      );
      selectedOption = option;
    } else {
      throw ArgumentError(
          'Invalid answer type for single select: ${userAnswer.runtimeType}');
    }

    final isCorrect = selectedOption.isCorrect;
    final feedback = _generateFeedback([selectedOption], isCorrect);

    return QuestionResult(
      isCorrect: isCorrect,
      userAnswer: selectedOption,
      correctAnswer: correctOptions.first,
      feedback: feedback,
      explanation: explanation ?? selectedOption.explanation,
    );
  }

  /// Validates multiple answer selections
  QuestionResult _validateMultipleAnswers(dynamic userAnswer) {
    late List<AnswerOption> selectedOptions;

    // Handle different input types
    if (userAnswer is List<AnswerOption>) {
      selectedOptions = userAnswer;
    } else if (userAnswer is List<String>) {
      selectedOptions = userAnswer
          .map((id) => options.firstWhere((o) => o.id == id))
          .toList();
    } else if (userAnswer is Set<AnswerOption>) {
      selectedOptions = userAnswer.toList();
    } else if (userAnswer is Set<String>) {
      selectedOptions = userAnswer
          .map((id) => options.firstWhere((o) => o.id == id))
          .toList();
    } else {
      throw ArgumentError(
          'Invalid answer type for multi-select: ${userAnswer.runtimeType}');
    }

    final correctCount = selectedOptions.where((o) => o.isCorrect).length;
    final incorrectCount = selectedOptions.where((o) => !o.isCorrect).length;
    final totalCorrect = correctOptions.length;

    // Check if completely correct
    final isCompletelyCorrect =
        correctCount == totalCorrect && incorrectCount == 0;

    // Calculate partial credit if enabled
    double? partialScore;
    if (allowPartialCredit && !isCompletelyCorrect) {
      if (correctCount >= minimumCorrectForCredit) {
        // Award partial credit based on ratio of correct selections
        final accuracy = correctCount / totalCorrect;
        final penalty =
            incorrectCount * 0.1; // 10% penalty per incorrect selection
        partialScore =
            (accuracy - penalty).clamp(0.0, 0.9); // Max 90% for partial credit
      }
    }

    final feedback = _generateFeedback(selectedOptions, isCompletelyCorrect);

    return QuestionResult(
      isCorrect: isCompletelyCorrect,
      userAnswer: selectedOptions,
      correctAnswer: correctOptions,
      partialCreditScore: partialScore,
      feedback: feedback,
      explanation: explanation,
    );
  }

  /// Generates contextual feedback based on the selected options
  String _generateFeedback(List<AnswerOption> selectedOptions, bool isCorrect) {
    if (isCorrect) {
      return 'Correct! Well done.';
    }

    if (selectedOptions.isEmpty) {
      return 'Please select an answer.';
    }

    if (!multiSelect) {
      return 'Incorrect. The correct answer is: ${correctOptions.first.text}';
    }

    // Multi-select feedback
    final correctSelected = selectedOptions.where((o) => o.isCorrect).length;
    final incorrectSelected = selectedOptions.where((o) => !o.isCorrect).length;
    final totalCorrect = correctOptions.length;

    if (correctSelected == 0) {
      return 'Incorrect. None of your selections were correct.';
    } else if (incorrectSelected > 0) {
      return 'Partially correct. You got $correctSelected out of $totalCorrect correct, but also selected some incorrect options.';
    } else {
      return 'Good! You selected correct options, but missed ${totalCorrect - correctSelected} correct answers.';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'options': options.map((o) => o.toJson()).toList(),
      'multiSelect': multiSelect,
      'randomizeOptions': randomizeOptions,
      'minimumCorrectForCredit': minimumCorrectForCredit,
    };
  }

  /// Creates a MultipleChoiceQuestion from JSON data
  static MultipleChoiceQuestion fromJson(Map<String, dynamic> json) {
    return MultipleChoiceQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      topic: QuestionTopic.values.firstWhere(
        (t) => t.name == json['topic'],
      ),
      difficulty: QuestionDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
      ),
      pointValue: json['pointValue'] as int,
      options: (json['options'] as List)
          .map((o) => AnswerOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      explanation: json['explanation'] as String?,
      hints: List<String>.from(json['hints'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      timeLimit: json['timeLimit'] as int?,
      allowPartialCredit: json['allowPartialCredit'] as bool? ?? false,
      multiSelect: json['multiSelect'] as bool? ?? false,
      randomizeOptions: json['randomizeOptions'] as bool? ?? true,
      minimumCorrectForCredit: json['minimumCorrectForCredit'] as int? ?? 1,
    );
  }

  @override
  String toString() {
    return 'MultipleChoiceQuestion(id: $id, options: ${options.length}, multiSelect: $multiSelect)';
  }
}
