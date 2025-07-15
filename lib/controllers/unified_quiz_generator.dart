// lib/controllers/unified_quiz_generator.dart

import 'dart:math';
import '../models/quiz/quiz_question.dart';
import '../models/quiz/quiz_session.dart';
import '../models/quiz/sections/introduction/whattheory_quiz_questions.dart';
import '../models/quiz/sections/introduction/whytheory_quiz_questions.dart';
import '../models/quiz/sections/introduction/practicetips_quiz_questions.dart';

/// Configuration for generating quizzes
class QuizGenerationConfig {
  const QuizGenerationConfig({
    this.questionCount = 10,
    this.timeLimit,
    this.allowSkip = true,
    this.allowReview = true,
    this.passingScore = 0.7,
    this.randomSeed,
  });

  /// Number of questions to generate
  final int questionCount;

  /// Time limit in minutes (null = no limit)
  final int? timeLimit;

  /// Whether users can skip questions
  final bool allowSkip;

  /// Whether users can review answers before submitting
  final bool allowReview;

  /// Minimum score required to pass (0.0 to 1.0)
  final double passingScore;

  /// Optional seed for consistent randomization
  final int? randomSeed;
}

/// Unified quiz generator for all sections and topics
///
/// This generator dynamically loads questions based on section and topic IDs,
/// providing both topic-specific and section-wide quiz generation.
class UnifiedQuizGenerator {
  final Random _random;

  UnifiedQuizGenerator({int? seed}) : _random = Random(seed);

  /// Generate a quiz for a specific topic
  List<QuizQuestion> generateTopicQuiz({
    required String sectionId,
    required String topicId,
    int questionCount = 5,
  }) {
    final questions = _getTopicQuestions(sectionId, topicId);

    if (questions.isEmpty) {
      throw ArgumentError(
          'No questions available for section: $sectionId, topic: $topicId');
    }

    // Use all available questions if requesting more than available
    final actualCount = questionCount.clamp(1, questions.length);

    // Shuffle and select
    questions.shuffle(_random);
    return questions.take(actualCount).toList();
  }

  /// Generate a quiz for an entire section (all topics)
  List<QuizQuestion> generateSectionQuiz({
    required String sectionId,
    int questionCount = 12,
  }) {
    final allTopicIds = _getSectionTopicIds(sectionId);

    if (allTopicIds.isEmpty) {
      throw ArgumentError('No topics available for section: $sectionId');
    }

    // Get all questions from all topics in the section
    List<QuizQuestion> allQuestions = [];
    for (final topicId in allTopicIds) {
      allQuestions.addAll(_getTopicQuestions(sectionId, topicId));
    }

    if (allQuestions.isEmpty) {
      throw ArgumentError('No questions available for section: $sectionId');
    }

    // Calculate balanced distribution
    final questionsPerTopic = questionCount ~/ allTopicIds.length;
    final remainingQuestions = questionCount % allTopicIds.length;

    List<QuizQuestion> selectedQuestions = [];

    // Select questions from each topic
    for (int i = 0; i < allTopicIds.length; i++) {
      final topicId = allTopicIds[i];
      final topicQuestions = _getTopicQuestions(sectionId, topicId);

      final questionsToTake =
          questionsPerTopic + (i < remainingQuestions ? 1 : 0);

      topicQuestions.shuffle(_random);
      selectedQuestions.addAll(topicQuestions.take(questionsToTake));
    }

    // If we still need more questions, fill from remaining pool
    if (selectedQuestions.length < questionCount) {
      final remainingPool =
          allQuestions.where((q) => !selectedQuestions.contains(q)).toList();
      remainingPool.shuffle(_random);

      final needed = questionCount - selectedQuestions.length;
      selectedQuestions.addAll(remainingPool.take(needed));
    }

    // Final shuffle
    selectedQuestions.shuffle(_random);
    return selectedQuestions.take(questionCount).toList();
  }

  /// Create a quiz session for a topic
  QuizSession createTopicQuizSession({
    required String sectionId,
    required String topicId,
    QuizGenerationConfig config = const QuizGenerationConfig(),
    String? sessionId,
  }) {
    final questions = generateTopicQuiz(
      sectionId: sectionId,
      topicId: topicId,
      questionCount: config.questionCount,
    );

    final topicTitle = _getTopicTitle(sectionId, topicId);

    return QuizSession(
      id: sessionId ??
          '${sectionId}_${topicId}_${DateTime.now().millisecondsSinceEpoch}',
      quizType: QuizType.topic,
      questions: questions,
      title: '$topicTitle Quiz',
      description: 'Test your understanding of "$topicTitle" concepts',
      allowSkip: config.allowSkip,
      allowReview: config.allowReview,
      timeLimit: config.timeLimit,
      passingScore: config.passingScore,
    );
  }

  /// Create a quiz session for a section
  QuizSession createSectionQuizSession({
    required String sectionId,
    QuizGenerationConfig config = const QuizGenerationConfig(),
    String? sessionId,
  }) {
    final questions = generateSectionQuiz(
      sectionId: sectionId,
      questionCount: config.questionCount,
    );

    final sectionTitle = _getSectionTitle(sectionId);

    return QuizSession(
      id: sessionId ??
          '${sectionId}_section_${DateTime.now().millisecondsSinceEpoch}',
      quizType: QuizType.section,
      questions: questions,
      title: '$sectionTitle Section Quiz',
      description:
          'Test your knowledge of all topics in the $sectionTitle section',
      allowSkip: config.allowSkip,
      allowReview: config.allowReview,
      timeLimit: config.timeLimit,
      passingScore: config.passingScore,
    );
  }

  /// Check if a section has quiz implementation
  bool isSectionImplemented(String sectionId) {
    return _getSectionTopicIds(sectionId).isNotEmpty;
  }

  /// Check if a topic has quiz implementation
  bool isTopicImplemented(String sectionId, String topicId) {
    return _getTopicQuestions(sectionId, topicId).isNotEmpty;
  }

  /// Get available question count for a topic
  int getTopicQuestionCount(String sectionId, String topicId) {
    return _getTopicQuestions(sectionId, topicId).length;
  }

  /// Get available question count for a section
  int getSectionQuestionCount(String sectionId) {
    final allTopicIds = _getSectionTopicIds(sectionId);
    int totalCount = 0;
    for (final topicId in allTopicIds) {
      totalCount += _getTopicQuestions(sectionId, topicId).length;
    }
    return totalCount;
  }

  /// Get quiz statistics for a section
  Map<String, dynamic> getSectionStats(String sectionId) {
    final topicIds = _getSectionTopicIds(sectionId);
    final topicCounts = <String, int>{};

    for (final topicId in topicIds) {
      topicCounts[topicId] = getTopicQuestionCount(sectionId, topicId);
    }

    final totalQuestions =
        topicCounts.values.fold(0, (sum, count) => sum + count);

    return {
      'sectionId': sectionId,
      'totalQuestions': totalQuestions,
      'topicCounts': topicCounts,
      'availableTopics': topicIds,
      'averageQuestionsPerTopic':
          topicIds.isNotEmpty ? totalQuestions / topicIds.length : 0.0,
      'implemented': totalQuestions > 0,
    };
  }

  /// Get questions for a specific topic
  List<QuizQuestion> _getTopicQuestions(String sectionId, String topicId) {
    switch (sectionId) {
      case 'introduction':
        return _getIntroductionTopicQuestions(topicId);
      // Add more sections here as they are implemented
      default:
        return [];
    }
  }

  /// Get questions for Introduction section topics
  List<QuizQuestion> _getIntroductionTopicQuestions(String topicId) {
    switch (topicId) {
      case WhatTheoryQuizQuestions.topicId:
        return WhatTheoryQuizQuestions.getQuestions();
      case WhyTheoryQuizQuestions.topicId:
        return WhyTheoryQuizQuestions.getQuestions();
      case PracticeTipsQuizQuestions.topicId:
        return PracticeTipsQuizQuestions.getQuestions();
      default:
        return [];
    }
  }

  /// Get all topic IDs for a section
  List<String> _getSectionTopicIds(String sectionId) {
    switch (sectionId) {
      case 'introduction':
        return [
          WhatTheoryQuizQuestions.topicId,
          WhyTheoryQuizQuestions.topicId,
          PracticeTipsQuizQuestions.topicId,
        ];
      // Add more sections here as they are implemented
      default:
        return [];
    }
  }

  /// Get display title for a section
  String _getSectionTitle(String sectionId) {
    switch (sectionId) {
      case 'introduction':
        return 'Introduction';
      case 'fundamentals':
        return 'Fundamentals';
      case 'essentials':
        return 'Essentials';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      case 'professional':
        return 'Professional';
      case 'master':
        return 'Master';
      case 'virtuoso':
        return 'Virtuoso';
      default:
        return 'Unknown Section';
    }
  }

  /// Get display title for a topic
  String _getTopicTitle(String sectionId, String topicId) {
    switch (sectionId) {
      case 'introduction':
        return _getIntroductionTopicTitle(topicId);
      // Add more sections here as they are implemented
      default:
        return 'Unknown Topic';
    }
  }

  /// Get topic titles for Introduction section
  String _getIntroductionTopicTitle(String topicId) {
    switch (topicId) {
      case WhatTheoryQuizQuestions.topicId:
        return WhatTheoryQuizQuestions.topicTitle;
      case WhyTheoryQuizQuestions.topicId:
        return WhyTheoryQuizQuestions.topicTitle;
      case PracticeTipsQuizQuestions.topicId:
        return PracticeTipsQuizQuestions.topicTitle;
      default:
        return 'Unknown Topic';
    }
  }
}
