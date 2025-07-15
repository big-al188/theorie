// lib/controllers/quiz_question_generator.dart

import 'dart:math';
import '../models/quiz/quiz_question.dart';
import '../models/quiz/multiple_choice_question.dart';

/// Configuration for generating quizzes
class QuizGenerationConfig {
  const QuizGenerationConfig({
    this.questionCount = 10,
    this.topics = const [],
    this.difficulties = const [],
    this.allowedTypes = const [QuestionType.multipleChoice],
    this.randomSeed,
  });

  /// Number of questions to generate
  final int questionCount;

  /// Topics to include (empty = all topics)
  final List<QuestionTopic> topics;

  /// Difficulty levels to include (empty = all difficulties)
  final List<QuestionDifficulty> difficulties;

  /// Question types to include
  final List<QuestionType> allowedTypes;

  /// Optional seed for consistent randomization
  final int? randomSeed;
}

/// Exception thrown when question generation fails
class QuestionGenerationException implements Exception {
  const QuestionGenerationException(this.message);
  final String message;

  @override
  String toString() => 'QuestionGenerationException: $message';
}

/// Controller responsible for generating quiz questions
///
/// This class manages the question pool and provides methods for
/// creating customized quizzes based on various criteria like
/// topic, difficulty, and question count.
class QuizQuestionGenerator {
  QuizQuestionGenerator({int? seed}) : _random = Random(seed);

  final Random _random;

  /// Hardcoded question pool for MVP implementation
  /// In a real application, this would be loaded from a database or API
  static final List<MultipleChoiceQuestion> _questionPool = [
    // Notes Questions
    MultipleChoiceQuestion(
      id: 'notes_001',
      questionText:
          'Which note is located on the 3rd fret of the low E string?',
      topic: QuestionTopic.notes,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 10,
      options: [
        AnswerOption(id: 'a', text: 'G', isCorrect: true),
        AnswerOption(id: 'b', text: 'F', isCorrect: false),
        AnswerOption(id: 'c', text: 'A', isCorrect: false),
        AnswerOption(id: 'd', text: 'B', isCorrect: false),
      ],
      explanation:
          'The low E string (6th string) at the 3rd fret produces a G note.',
    ),

    MultipleChoiceQuestion(
      id: 'notes_002',
      questionText: 'What note is on the 5th fret of the A string?',
      topic: QuestionTopic.notes,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 10,
      options: [
        AnswerOption(id: 'a', text: 'C', isCorrect: false),
        AnswerOption(id: 'b', text: 'D', isCorrect: true),
        AnswerOption(id: 'c', text: 'E', isCorrect: false),
        AnswerOption(id: 'd', text: 'F', isCorrect: false),
      ],
      explanation:
          'The A string (5th string) at the 5th fret produces a D note.',
    ),

    MultipleChoiceQuestion(
      id: 'notes_003',
      questionText: 'Which fret on the D string produces an F# note?',
      topic: QuestionTopic.notes,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      options: [
        AnswerOption(id: 'a', text: '2nd fret', isCorrect: false),
        AnswerOption(id: 'b', text: '3rd fret', isCorrect: false),
        AnswerOption(id: 'c', text: '4th fret', isCorrect: true),
        AnswerOption(id: 'd', text: '5th fret', isCorrect: false),
      ],
      explanation:
          'The D string (4th string) at the 4th fret produces an F# note.',
    ),

    // Intervals Questions
    MultipleChoiceQuestion(
      id: 'intervals_001',
      questionText: 'What is the interval between C and E?',
      topic: QuestionTopic.intervals,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 10,
      options: [
        AnswerOption(id: 'a', text: 'Major 2nd', isCorrect: false),
        AnswerOption(id: 'b', text: 'Major 3rd', isCorrect: true),
        AnswerOption(id: 'c', text: 'Perfect 4th', isCorrect: false),
        AnswerOption(id: 'd', text: 'Perfect 5th', isCorrect: false),
      ],
      explanation: 'C to E is a Major 3rd interval (4 semitones).',
    ),

    MultipleChoiceQuestion(
      id: 'intervals_002',
      questionText: 'How many semitones are in a Perfect 5th?',
      topic: QuestionTopic.intervals,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      options: [
        AnswerOption(id: 'a', text: '5 semitones', isCorrect: false),
        AnswerOption(id: 'b', text: '6 semitones', isCorrect: false),
        AnswerOption(id: 'c', text: '7 semitones', isCorrect: true),
        AnswerOption(id: 'd', text: '8 semitones', isCorrect: false),
      ],
      explanation: 'A Perfect 5th interval contains 7 semitones.',
    ),

    // Scales Questions
    MultipleChoiceQuestion(
      id: 'scales_001',
      questionText: 'Which notes make up the C Major scale?',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 10,
      options: [
        AnswerOption(id: 'a', text: 'C D E F G A B', isCorrect: true),
        AnswerOption(id: 'b', text: 'C D E F# G A B', isCorrect: false),
        AnswerOption(id: 'c', text: 'C D Eb F G A Bb', isCorrect: false),
        AnswerOption(id: 'd', text: 'C Db E F G Ab B', isCorrect: false),
      ],
      explanation:
          'The C Major scale contains no sharps or flats: C D E F G A B.',
    ),

    MultipleChoiceQuestion(
      id: 'scales_002',
      questionText:
          'What is the pattern of whole and half steps in a major scale?',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      options: [
        AnswerOption(id: 'a', text: 'W W H W W W H', isCorrect: true),
        AnswerOption(id: 'b', text: 'W H W W H W W', isCorrect: false),
        AnswerOption(id: 'c', text: 'H W W H W W W', isCorrect: false),
        AnswerOption(id: 'd', text: 'W W W H W W H', isCorrect: false),
      ],
      explanation:
          'Major scales follow the pattern: Whole, Whole, Half, Whole, Whole, Whole, Half.',
    ),

    // Chords Questions
    MultipleChoiceQuestion(
      id: 'chords_001',
      questionText: 'Which notes make up a C Major chord?',
      topic: QuestionTopic.chords,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 10,
      options: [
        AnswerOption(id: 'a', text: 'C E G', isCorrect: true),
        AnswerOption(id: 'b', text: 'C F G', isCorrect: false),
        AnswerOption(id: 'c', text: 'C D G', isCorrect: false),
        AnswerOption(id: 'd', text: 'C E A', isCorrect: false),
      ],
      explanation:
          'A C Major chord is built with the root (C), major third (E), and perfect fifth (G).',
    ),

    MultipleChoiceQuestion(
      id: 'chords_002',
      questionText: 'What makes a chord "minor"?',
      topic: QuestionTopic.chords,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      options: [
        AnswerOption(id: 'a', text: 'Lowered 5th', isCorrect: false),
        AnswerOption(id: 'b', text: 'Lowered 3rd', isCorrect: true),
        AnswerOption(id: 'c', text: 'Added 7th', isCorrect: false),
        AnswerOption(id: 'd', text: 'Raised root', isCorrect: false),
      ],
      explanation:
          'A minor chord has a minor (lowered) third interval from the root.',
    ),

    // Key Signatures Questions
    MultipleChoiceQuestion(
      id: 'keys_001',
      questionText: 'How many sharps does the key of D Major have?',
      topic: QuestionTopic.keySignatures,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      options: [
        AnswerOption(id: 'a', text: '1 sharp', isCorrect: false),
        AnswerOption(id: 'b', text: '2 sharps', isCorrect: true),
        AnswerOption(id: 'c', text: '3 sharps', isCorrect: false),
        AnswerOption(id: 'd', text: '4 sharps', isCorrect: false),
      ],
      explanation: 'D Major has 2 sharps: F# and C#.',
    ),

    MultipleChoiceQuestion(
      id: 'keys_002',
      questionText: 'Which key signature has 3 flats?',
      topic: QuestionTopic.keySignatures,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      options: [
        AnswerOption(id: 'a', text: 'F Major', isCorrect: false),
        AnswerOption(id: 'b', text: 'Bb Major', isCorrect: false),
        AnswerOption(id: 'c', text: 'Eb Major', isCorrect: true),
        AnswerOption(id: 'd', text: 'Ab Major', isCorrect: false),
      ],
      explanation: 'Eb Major has 3 flats: Bb, Eb, and Ab.',
    ),

    // Theory Questions
    MultipleChoiceQuestion(
      id: 'theory_001',
      questionText: 'What is the relative minor of C Major?',
      topic: QuestionTopic.theory,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      options: [
        AnswerOption(id: 'a', text: 'A minor', isCorrect: true),
        AnswerOption(id: 'b', text: 'D minor', isCorrect: false),
        AnswerOption(id: 'c', text: 'E minor', isCorrect: false),
        AnswerOption(id: 'd', text: 'F minor', isCorrect: false),
      ],
      explanation:
          'The relative minor is found on the 6th degree of the major scale. A is the 6th degree of C Major.',
    ),

    MultipleChoiceQuestion(
      id: 'theory_002',
      questionText: 'What does "forte" mean in musical dynamics?',
      topic: QuestionTopic.theory,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 10,
      options: [
        AnswerOption(id: 'a', text: 'Soft', isCorrect: false),
        AnswerOption(id: 'b', text: 'Loud', isCorrect: true),
        AnswerOption(id: 'c', text: 'Fast', isCorrect: false),
        AnswerOption(id: 'd', text: 'Slow', isCorrect: false),
      ],
      explanation: 'Forte (f) indicates loud dynamic level in music.',
    ),

    // Advanced Questions
    MultipleChoiceQuestion(
      id: 'advanced_001',
      questionText:
          'What chord progression is known as the "Circle of Fifths progression"?',
      topic: QuestionTopic.progressions,
      difficulty: QuestionDifficulty.advanced,
      pointValue: 20,
      options: [
        AnswerOption(id: 'a', text: 'I-V-vi-IV', isCorrect: false),
        AnswerOption(id: 'b', text: 'vi-IV-I-V', isCorrect: true),
        AnswerOption(id: 'c', text: 'I-vi-ii-V', isCorrect: false),
        AnswerOption(id: 'd', text: 'ii-V-I', isCorrect: false),
      ],
      explanation:
          'The vi-IV-I-V progression follows the circle of fifths pattern and is very common in popular music.',
    ),

    MultipleChoiceQuestion(
      id: 'modes_001',
      questionText: 'Which mode is built on the 5th degree of the major scale?',
      topic: QuestionTopic.modes,
      difficulty: QuestionDifficulty.advanced,
      pointValue: 20,
      options: [
        AnswerOption(id: 'a', text: 'Dorian', isCorrect: false),
        AnswerOption(id: 'b', text: 'Phrygian', isCorrect: false),
        AnswerOption(id: 'c', text: 'Lydian', isCorrect: false),
        AnswerOption(id: 'd', text: 'Mixolydian', isCorrect: true),
      ],
      explanation:
          'Mixolydian mode is built on the 5th degree of the major scale.',
    ),
  ];

  /// Generates a quiz with the specified configuration
  List<QuizQuestion> generateQuiz(QuizGenerationConfig config) {
    if (config.questionCount <= 0) {
      throw QuestionGenerationException('Question count must be positive');
    }

    if (config.allowedTypes.isEmpty) {
      throw QuestionGenerationException(
          'At least one question type must be allowed');
    }

    try {
      // Filter questions based on criteria
      var availableQuestions = _filterQuestions(config);

      if (availableQuestions.isEmpty) {
        throw QuestionGenerationException(
            'No questions match the specified criteria');
      }

      // If we need more questions than available, use all available
      final questionCount =
          config.questionCount.clamp(1, availableQuestions.length);

      // Shuffle and select questions
      availableQuestions.shuffle(_random);
      final selectedQuestions = availableQuestions.take(questionCount).toList();

      // Ensure topic distribution if multiple topics requested
      if (config.topics.length > 1) {
        selectedQuestions
            .sort((a, b) => a.topic.index.compareTo(b.topic.index));
      }

      return selectedQuestions;
    } catch (e) {
      throw QuestionGenerationException('Failed to generate quiz: $e');
    }
  }

  /// Generates a topic-specific quiz
  List<QuizQuestion> generateTopicQuiz({
    required QuestionTopic topic,
    int questionCount = 10,
    List<QuestionDifficulty> difficulties = const [],
  }) {
    return generateQuiz(QuizGenerationConfig(
      questionCount: questionCount,
      topics: [topic],
      difficulties: difficulties,
    ));
  }

  /// Generates a difficulty-specific quiz
  List<QuizQuestion> generateDifficultyQuiz({
    required QuestionDifficulty difficulty,
    int questionCount = 10,
    List<QuestionTopic> topics = const [],
  }) {
    return generateQuiz(QuizGenerationConfig(
      questionCount: questionCount,
      topics: topics,
      difficulties: [difficulty],
    ));
  }

  /// Generates a mixed review quiz with balanced topic distribution
  List<QuizQuestion> generateReviewQuiz({
    int questionCount = 15,
    bool includeAllTopics = true,
  }) {
    final topics = includeAllTopics ? QuestionTopic.values : <QuestionTopic>[];

    return generateQuiz(QuizGenerationConfig(
      questionCount: questionCount,
      topics: topics,
      difficulties: [
        QuestionDifficulty.beginner,
        QuestionDifficulty.intermediate,
      ],
    ));
  }

  /// Gets available questions count for given criteria
  int getAvailableQuestionCount({
    List<QuestionTopic> topics = const [],
    List<QuestionDifficulty> difficulties = const [],
    List<QuestionType> allowedTypes = const [QuestionType.multipleChoice],
  }) {
    final config = QuizGenerationConfig(
      questionCount: _questionPool.length,
      topics: topics,
      difficulties: difficulties,
      allowedTypes: allowedTypes,
    );

    return _filterQuestions(config).length;
  }

  /// Gets statistics about the question pool
  Map<String, dynamic> getQuestionPoolStats() {
    final topicCounts = <QuestionTopic, int>{};
    final difficultyCounts = <QuestionDifficulty, int>{};
    final typeCounts = <QuestionType, int>{};

    for (final question in _questionPool) {
      topicCounts[question.topic] = (topicCounts[question.topic] ?? 0) + 1;
      difficultyCounts[question.difficulty] =
          (difficultyCounts[question.difficulty] ?? 0) + 1;
      typeCounts[question.type] = (typeCounts[question.type] ?? 0) + 1;
    }

    return {
      'totalQuestions': _questionPool.length,
      'topicBreakdown': topicCounts.map((k, v) => MapEntry(k.name, v)),
      'difficultyBreakdown':
          difficultyCounts.map((k, v) => MapEntry(k.name, v)),
      'typeBreakdown': typeCounts.map((k, v) => MapEntry(k.name, v)),
    };
  }

  /// Filters questions based on the provided configuration
  List<QuizQuestion> _filterQuestions(QuizGenerationConfig config) {
    return _questionPool.where((question) {
      // Filter by type
      if (!config.allowedTypes.contains(question.type)) return false;

      // Filter by topic
      if (config.topics.isNotEmpty && !config.topics.contains(question.topic))
        return false;

      // Filter by difficulty
      if (config.difficulties.isNotEmpty &&
          !config.difficulties.contains(question.difficulty)) return false;

      return true;
    }).toList();
  }

  /// Gets a random question from the pool
  QuizQuestion getRandomQuestion({
    QuestionTopic? topic,
    QuestionDifficulty? difficulty,
    QuestionType? type,
  }) {
    final config = QuizGenerationConfig(
      questionCount: 1,
      topics: topic != null ? [topic] : [],
      difficulties: difficulty != null ? [difficulty] : [],
      allowedTypes: type != null ? [type] : [QuestionType.multipleChoice],
    );

    final questions = generateQuiz(config);
    if (questions.isEmpty) {
      throw QuestionGenerationException(
          'No questions available with specified criteria');
    }

    return questions.first;
  }
}
