import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/quiz_models.dart';
import '../models/question_models.dart';
import '../models/quiz_template.dart';
import '../models/quiz_enums.dart';
import 'question_pool_controller.dart';

/// Factory class for generating quizzes
class QuizGenerator {
  final QuestionPoolController _questionPool;
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  QuizGenerator({
    required QuestionPoolController questionPool,
  }) : _questionPool = questionPool;

  /// Generate a quiz from a template
  Future<Quiz> generateFromTemplate(QuizTemplate template) async {
    if (!template.isValid) {
      throw ArgumentError('Invalid quiz template');
    }

    // Load questions from pool
    await _questionPool.loadQuestionsForSection(template.sectionId);

    // Select questions based on template
    final selectedQuestions = _selectQuestions(template);

    // Shuffle questions if needed
    if (template.constraints['shuffleQuestions'] ?? true) {
      selectedQuestions.shuffle(_random);
    }

    // Create quiz metadata
    final metadata = _createMetadata(template, selectedQuestions);

    // Create and return quiz
    return Quiz(
      id: _uuid.v4(),
      type: template.quizType,
      sectionId: template.sectionId,
      topicId: template.topicId,
      questions: selectedQuestions,
      metadata: metadata,
    );
  }

  /// Generate a custom quiz based on user preferences
  Future<Quiz> generateCustomQuiz({
    required String sectionId,
    required Set<String> topicIds,
    required int questionCount,
    required DifficultyRange difficultyRange,
    Map<QuestionType, double>? typePreferences,
  }) async {
    // Create a dynamic template
    final template = QuizTemplate(
      id: 'custom_${_uuid.v4()}',
      name: 'Custom Quiz',
      quizType: QuizType.custom,
      sectionId: sectionId,
      questionDistribution: _calculateDistribution(
        questionCount,
        typePreferences ?? _defaultTypePreferences,
      ),
      topicWeights: _calculateTopicWeights(topicIds),
      difficultyRange: difficultyRange,
      requiredConcepts: {},
      generationStrategy: QuizGenerationStrategy.balanced,
      estimatedMinutes: (questionCount * 1.5).ceil(),
    );

    return generateFromTemplate(template);
  }

  /// Generate a refresher quiz based on past performance
  Future<Quiz> generateRefresherQuiz({
    required String sectionId,
    required List<String> weakTopics,
    int questionCount = 5,
  }) async {
    final template = QuizTemplate(
      id: 'refresher_${_uuid.v4()}',
      name: 'Refresher Quiz',
      quizType: QuizType.refresher,
      sectionId: sectionId,
      questionDistribution: {
        QuestionType.multipleChoice: (questionCount * 0.8).ceil(),
        QuestionType.scaleInteractive: (questionCount * 0.2).floor(),
      },
      topicWeights: _calculateTopicWeights(weakTopics.toSet()),
      difficultyRange: const DifficultyRange(
        minimum: DifficultyLevel.beginner,
        maximum: DifficultyLevel.intermediate,
      ),
      requiredConcepts: {},
      generationStrategy: QuizGenerationStrategy.review,
      estimatedMinutes: questionCount,
    );

    return generateFromTemplate(template);
  }

  /// Select questions based on template requirements
  List<Question> _selectQuestions(QuizTemplate template) {
    final selectedQuestions = <Question>[];

    // Process each question type
    template.questionDistribution.forEach((type, count) {
      final questionsOfType = _selectQuestionsOfType(
        type: type,
        count: count,
        template: template,
        alreadySelected: selectedQuestions,
      );
      selectedQuestions.addAll(questionsOfType);
    });

    // Ensure required concepts are covered
    _ensureRequiredConcepts(selectedQuestions, template);

    return selectedQuestions;
  }

  /// Select questions of a specific type
  List<Question> _selectQuestionsOfType({
    required QuestionType type,
    required int count,
    required QuizTemplate template,
    required List<Question> alreadySelected,
  }) {
    // Get available questions
    final availableQuestions = _questionPool.getQuestions(
      type: type,
      sectionId: template.sectionId,
      topicId: template.topicId,
    );

    // Filter by difficulty
    final filteredQuestions = availableQuestions.where((q) {
      return template.difficultyRange.difficultiesInRange.contains(q.difficulty);
    }).toList();

    // Remove already selected questions
    final alreadySelectedIds = alreadySelected.map((q) => q.id).toSet();
    filteredQuestions.removeWhere((q) => alreadySelectedIds.contains(q.id));

    // Score and sort questions
    final scoredQuestions = _scoreQuestions(
      questions: filteredQuestions,
      template: template,
      alreadySelected: alreadySelected,
    );

    // Select top questions
    return _selectTopQuestions(scoredQuestions, count);
  }

  /// Score questions based on template criteria
  List<_ScoredQuestion> _scoreQuestions({
    required List<Question> questions,
    required QuizTemplate template,
    required List<Question> alreadySelected,
  }) {
    final scoredQuestions = <_ScoredQuestion>[];

    for (final question in questions) {
      double score = 0.0;

      // Topic weight score
      final topicWeight = template.topicWeights[question.topicId] ?? 0.0;
      score += topicWeight * 100;

      // Difficulty distribution score
      final difficultyWeight = template.difficultyRange.getWeight(question.difficulty);
      score += difficultyWeight * 50;

      // Coverage score (prefer questions that cover new concepts)
      final coveredConcepts = alreadySelected
          .expand((q) => q.relatedConceptIds)
          .toSet();
      final newConcepts = question.relatedConceptIds
          .where((c) => !coveredConcepts.contains(c))
          .length;
      score += newConcepts * 20;

      // Required concepts bonus
      final coversRequired = question.relatedConceptIds
          .any((c) => template.requiredConcepts.contains(c));
      if (coversRequired) score += 100;

      // Add randomness for variety
      score += _random.nextDouble() * 10;

      scoredQuestions.add(_ScoredQuestion(question, score));
    }

    // Sort by score (descending)
    scoredQuestions.sort((a, b) => b.score.compareTo(a.score));

    return scoredQuestions;
  }

  /// Select top questions from scored list
  List<Question> _selectTopQuestions(List<_ScoredQuestion> scoredQuestions, int count) {
    final selected = <Question>[];
    
    for (int i = 0; i < count && i < scoredQuestions.length; i++) {
      selected.add(scoredQuestions[i].question);
    }

    // If we don't have enough questions, fill with any available
    if (selected.length < count) {
      for (final scored in scoredQuestions.skip(selected.length)) {
        if (selected.length >= count) break;
        if (!selected.contains(scored.question)) {
          selected.add(scored.question);
        }
      }
    }

    return selected;
  }

  /// Ensure required concepts are covered
  void _ensureRequiredConcepts(List<Question> questions, QuizTemplate template) {
    final coveredConcepts = questions
        .expand((q) => q.relatedConceptIds)
        .toSet();

    final missingConcepts = template.requiredConcepts
        .where((c) => !coveredConcepts.contains(c))
        .toSet();

    if (missingConcepts.isNotEmpty) {
      // Try to swap questions to cover missing concepts
      _swapForRequiredConcepts(questions, missingConcepts, template);
    }
  }

  /// Swap questions to ensure concept coverage
  void _swapForRequiredConcepts(
    List<Question> questions,
    Set<String> missingConcepts,
    QuizTemplate template,
  ) {
    // Find questions that could be swapped
    for (int i = 0; i < questions.length && missingConcepts.isNotEmpty; i++) {
      final currentQuestion = questions[i];
      
      // Find a replacement that covers missing concepts
      final replacement = _findReplacementQuestion(
        currentQuestion: currentQuestion,
        missingConcepts: missingConcepts,
        template: template,
        excludeIds: questions.map((q) => q.id).toSet(),
      );

      if (replacement != null) {
        questions[i] = replacement;
        missingConcepts.removeAll(replacement.relatedConceptIds);
      }
    }
  }

  /// Find a replacement question that covers missing concepts
  Question? _findReplacementQuestion({
    required Question currentQuestion,
    required Set<String> missingConcepts,
    required QuizTemplate template,
    required Set<String> excludeIds,
  }) {
    final candidates = _questionPool.getQuestions(
      type: currentQuestion.type,
      sectionId: template.sectionId,
      topicId: template.topicId,
    );

    // Filter and score candidates
    final validCandidates = candidates.where((q) {
      return !excludeIds.contains(q.id) &&
          template.difficultyRange.difficultiesInRange.contains(q.difficulty) &&
          q.relatedConceptIds.any((c) => missingConcepts.contains(c));
    }).toList();

    if (validCandidates.isEmpty) return null;

    // Return the best candidate
    validCandidates.sort((a, b) {
      final aCovers = a.relatedConceptIds.where((c) => missingConcepts.contains(c)).length;
      final bCovers = b.relatedConceptIds.where((c) => missingConcepts.contains(c)).length;
      return bCovers.compareTo(aCovers);
    });

    return validCandidates.first;
  }

  /// Create quiz metadata
  QuizMetadata _createMetadata(QuizTemplate template, List<Question> questions) {
    // Calculate covered topics
    final coveredTopics = questions
        .map((q) => q.topicId)
        .toSet()
        .toList();

    // Calculate average difficulty
    final avgDifficulty = _calculateAverageDifficulty(questions);

    return QuizMetadata(
      title: template.name,
      description: _generateDescription(template, questions),
      estimatedMinutes: template.estimatedMinutes,
      difficulty: avgDifficulty,
      coveredTopics: coveredTopics,
      customData: {
        'templateId': template.id,
        'questionCount': questions.length,
        'questionTypes': _getQuestionTypeBreakdown(questions),
      },
    );
  }

  /// Generate quiz description
  String _generateDescription(QuizTemplate template, List<Question> questions) {
    switch (template.quizType) {
      case QuizType.section:
        return 'Comprehensive quiz covering all topics in this section with ${questions.length} questions.';
      case QuizType.topic:
        return 'Focused quiz on specific topics with ${questions.length} questions.';
      case QuizType.refresher:
        return 'Quick ${questions.length}-question review of key concepts.';
      case QuizType.custom:
        return 'Custom quiz with ${questions.length} questions tailored to your preferences.';
    }
  }

  /// Calculate average difficulty
  DifficultyLevel _calculateAverageDifficulty(List<Question> questions) {
    if (questions.isEmpty) return DifficultyLevel.beginner;

    final avgIndex = questions
        .map((q) => q.difficulty.index)
        .reduce((a, b) => a + b) / questions.length;

    return DifficultyLevel.values[avgIndex.round()];
  }

  /// Get question type breakdown
  Map<String, int> _getQuestionTypeBreakdown(List<Question> questions) {
    final breakdown = <String, int>{};
    
    for (final question in questions) {
      final typeStr = question.type.toString();
      breakdown[typeStr] = (breakdown[typeStr] ?? 0) + 1;
    }

    return breakdown;
  }

  /// Calculate distribution from preferences
  Map<QuestionType, int> _calculateDistribution(
    int totalQuestions,
    Map<QuestionType, double> preferences,
  ) {
    final distribution = <QuestionType, int>{};
    int allocated = 0;

    // Allocate based on preferences
    preferences.forEach((type, preference) {
      final count = (totalQuestions * preference).floor();
      distribution[type] = count;
      allocated += count;
    });

    // Distribute remaining questions
    while (allocated < totalQuestions) {
      // Add to the type with highest preference that hasn't been fully allocated
      final sortedTypes = preferences.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedTypes) {
        if (allocated < totalQuestions) {
          distribution[entry.key] = (distribution[entry.key] ?? 0) + 1;
          allocated++;
          break;
        }
      }
    }

    return distribution;
  }

  /// Calculate topic weights
  Map<String, double> _calculateTopicWeights(Set<String> topicIds) {
    final weight = 1.0 / topicIds.length;
    return Map.fromEntries(
      topicIds.map((id) => MapEntry(id, weight)),
    );
  }

  /// Default type preferences
  static const _defaultTypePreferences = {
    QuestionType.multipleChoice: 0.6,
    QuestionType.scaleInteractive: 0.2,
    QuestionType.chordInteractive: 0.2,
  };
}

/// Helper class for scored questions
class _ScoredQuestion {
  final Question question;
  final double score;

  _ScoredQuestion(this.question, this.score);
}