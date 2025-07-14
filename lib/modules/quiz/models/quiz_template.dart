import 'quiz_enums.dart';

/// Template for generating quizzes
class QuizTemplate {
  final String id;
  final String name;
  final QuizType quizType;
  final String sectionId;
  final String? topicId;
  final Map<QuestionType, int> questionDistribution;
  final Map<String, double> topicWeights;
  final DifficultyRange difficultyRange;
  final Set<String> requiredConcepts;
  final QuizGenerationStrategy generationStrategy;
  final int estimatedMinutes;
  final Map<String, dynamic> constraints;

  const QuizTemplate({
    required this.id,
    required this.name,
    required this.quizType,
    required this.sectionId,
    this.topicId,
    required this.questionDistribution,
    required this.topicWeights,
    required this.difficultyRange,
    required this.requiredConcepts,
    this.generationStrategy = QuizGenerationStrategy.balanced,
    required this.estimatedMinutes,
    this.constraints = const {},
  });

  /// Total number of questions
  int get totalQuestions {
    return questionDistribution.values.fold(0, (sum, count) => sum + count);
  }

  /// Check if template is valid
  bool get isValid {
    // Ensure we have at least one question
    if (totalQuestions == 0) return false;
    
    // Ensure topic weights sum to approximately 1.0
    final weightSum = topicWeights.values.fold(0.0, (sum, weight) => sum + weight);
    if (weightSum < 0.95 || weightSum > 1.05) return false;
    
    // Ensure difficulty range is valid
    if (!difficultyRange.isValid) return false;
    
    return true;
  }

  /// Create a copy with updated values
  QuizTemplate copyWith({
    String? id,
    String? name,
    QuizType? quizType,
    String? sectionId,
    String? topicId,
    Map<QuestionType, int>? questionDistribution,
    Map<String, double>? topicWeights,
    DifficultyRange? difficultyRange,
    Set<String>? requiredConcepts,
    QuizGenerationStrategy? generationStrategy,
    int? estimatedMinutes,
    Map<String, dynamic>? constraints,
  }) {
    return QuizTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      quizType: quizType ?? this.quizType,
      sectionId: sectionId ?? this.sectionId,
      topicId: topicId ?? this.topicId,
      questionDistribution: questionDistribution ?? this.questionDistribution,
      topicWeights: topicWeights ?? this.topicWeights,
      difficultyRange: difficultyRange ?? this.difficultyRange,
      requiredConcepts: requiredConcepts ?? this.requiredConcepts,
      generationStrategy: generationStrategy ?? this.generationStrategy,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      constraints: constraints ?? this.constraints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quizType': quizType.toString(),
      'sectionId': sectionId,
      'topicId': topicId,
      'questionDistribution': questionDistribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'topicWeights': topicWeights,
      'difficultyRange': difficultyRange.toJson(),
      'requiredConcepts': requiredConcepts.toList(),
      'generationStrategy': generationStrategy.toString(),
      'estimatedMinutes': estimatedMinutes,
      'constraints': constraints,
    };
  }

  factory QuizTemplate.fromJson(Map<String, dynamic> json) {
    return QuizTemplate(
      id: json['id'],
      name: json['name'],
      quizType: QuizType.values.firstWhere(
        (t) => t.toString() == json['quizType'],
      ),
      sectionId: json['sectionId'],
      topicId: json['topicId'],
      questionDistribution: (json['questionDistribution'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          QuestionType.values.firstWhere((t) => t.toString() == key),
          value as int,
        ),
      ),
      topicWeights: Map<String, double>.from(json['topicWeights']),
      difficultyRange: DifficultyRange.fromJson(json['difficultyRange']),
      requiredConcepts: Set<String>.from(json['requiredConcepts']),
      generationStrategy: QuizGenerationStrategy.values.firstWhere(
        (s) => s.toString() == json['generationStrategy'],
        orElse: () => QuizGenerationStrategy.balanced,
      ),
      estimatedMinutes: json['estimatedMinutes'],
      constraints: json['constraints'] ?? {},
    );
  }
}

/// Represents a range of difficulties
class DifficultyRange {
  final DifficultyLevel minimum;
  final DifficultyLevel maximum;
  final Map<DifficultyLevel, double> distribution;

  const DifficultyRange({
    required this.minimum,
    required this.maximum,
    this.distribution = const {},
  });

  /// Check if range is valid
  bool get isValid {
    return minimum.index <= maximum.index;
  }

  /// Get all difficulties in range
  List<DifficultyLevel> get difficultiesInRange {
    return DifficultyLevel.values
        .where((d) => d.index >= minimum.index && d.index <= maximum.index)
        .toList();
  }

  /// Get weight for a difficulty level
  double getWeight(DifficultyLevel difficulty) {
    if (!difficultiesInRange.contains(difficulty)) return 0.0;
    
    // If no distribution specified, use equal weights
    if (distribution.isEmpty) {
      return 1.0 / difficultiesInRange.length;
    }
    
    return distribution[difficulty] ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'minimum': minimum.toString(),
      'maximum': maximum.toString(),
      'distribution': distribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  factory DifficultyRange.fromJson(Map<String, dynamic> json) {
    return DifficultyRange(
      minimum: DifficultyLevel.values.firstWhere(
        (d) => d.toString() == json['minimum'],
      ),
      maximum: DifficultyLevel.values.firstWhere(
        (d) => d.toString() == json['maximum'],
      ),
      distribution: (json['distribution'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          DifficultyLevel.values.firstWhere((d) => d.toString() == key),
          value.toDouble(),
        ),
      ) ?? {},
    );
  }
}

/// Predefined templates for common quiz types
class QuizTemplates {
  /// Introduction section comprehensive quiz
  static const introductionSectionQuiz = QuizTemplate(
    id: 'intro_section_comprehensive',
    name: 'Introduction Section Quiz',
    quizType: QuizType.section,
    sectionId: 'introduction',
    questionDistribution: {
      QuestionType.multipleChoice: 10,
      QuestionType.scaleInteractive: 3,
      QuestionType.chordInteractive: 2,
    },
    topicWeights: {
      'music_basics': 0.3,
      'notes_and_staff': 0.3,
      'basic_rhythm': 0.2,
      'key_signatures': 0.2,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
      distribution: {
        DifficultyLevel.beginner: 0.6,
        DifficultyLevel.intermediate: 0.4,
      },
    ),
    requiredConcepts: {
      'note_names',
      'staff_lines',
      'basic_intervals',
      'simple_rhythms',
    },
    estimatedMinutes: 15,
  );

  /// Quick topic refresher template
  static const topicRefresherQuiz = QuizTemplate(
    id: 'topic_refresher',
    name: 'Quick Topic Review',
    quizType: QuizType.refresher,
    sectionId: '',  // Will be filled dynamically
    questionDistribution: {
      QuestionType.multipleChoice: 5,
      QuestionType.scaleInteractive: 1,
    },
    topicWeights: {},  // Will be filled dynamically
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
    ),
    requiredConcepts: {},  // Will be filled dynamically
    generationStrategy: QuizGenerationStrategy.review,
    estimatedMinutes: 5,
  );
}