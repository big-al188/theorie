import '../../models/quiz_template.dart';
import '../../models/quiz_enums.dart';

/// Quiz templates for the Introduction section
class IntroductionTemplates {
  /// Comprehensive section quiz covering all Introduction topics
  static const sectionQuiz = QuizTemplate(
    id: 'intro_section_comprehensive',
    name: 'Introduction Section Quiz',
    quizType: QuizType.section,
    sectionId: 'introduction',
    questionDistribution: {
      QuestionType.multipleChoice: 12,
      QuestionType.scaleInteractive: 3,
      QuestionType.chordInteractive: 3,
    },
    topicWeights: {
      'music_basics': 0.25,
      'notes_and_staff': 0.30,
      'basic_rhythm': 0.20,
      'key_signatures': 0.15,
      'basic_scales': 0.05,
      'basic_chords': 0.05,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
      distribution: {
        DifficultyLevel.beginner: 0.60,
        DifficultyLevel.intermediate: 0.40,
      },
    ),
    requiredConcepts: {
      'musical_alphabet',
      'note_names',
      'staff_lines',
      'staff_spaces',
      'clefs',
      'time_signatures',
      'note_values',
      'key_signatures',
    },
    generationStrategy: QuizGenerationStrategy.balanced,
    estimatedMinutes: 20,
    constraints: {
      'shuffleQuestions': true,
      'allowSkip': false,
      'showProgress': true,
      'immediateFeeback': false,
    },
  );

  /// Music Basics topic quiz
  static const musicBasicsQuiz = QuizTemplate(
    id: 'intro_topic_music_basics',
    name: 'Music Basics Quiz',
    quizType: QuizType.topic,
    sectionId: 'introduction',
    topicId: 'music_basics',
    questionDistribution: {
      QuestionType.multipleChoice: 8,
      QuestionType.scaleInteractive: 1,
    },
    topicWeights: {
      'music_basics': 1.0,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
      distribution: {
        DifficultyLevel.beginner: 0.75,
        DifficultyLevel.intermediate: 0.25,
      },
    ),
    requiredConcepts: {
      'musical_alphabet',
      'pitch',
      'rhythm',
      'intervals',
    },
    generationStrategy: QuizGenerationStrategy.focused,
    estimatedMinutes: 10,
  );

  /// Notes and Staff topic quiz
  static const notesAndStaffQuiz = QuizTemplate(
    id: 'intro_topic_notes_staff',
    name: 'Notes and Staff Quiz',
    quizType: QuizType.topic,
    sectionId: 'introduction',
    topicId: 'notes_and_staff',
    questionDistribution: {
      QuestionType.multipleChoice: 8,
      QuestionType.scaleInteractive: 2,
    },
    topicWeights: {
      'notes_and_staff': 1.0,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
      distribution: {
        DifficultyLevel.beginner: 0.60,
        DifficultyLevel.intermediate: 0.40,
      },
    ),
    requiredConcepts: {
      'staff_lines',
      'staff_spaces',
      'treble_clef',
      'bass_clef',
      'ledger_lines',
    },
    generationStrategy: QuizGenerationStrategy.focused,
    estimatedMinutes: 12,
  );

  /// Basic Rhythm topic quiz
  static const basicRhythmQuiz = QuizTemplate(
    id: 'intro_topic_basic_rhythm',
    name: 'Basic Rhythm Quiz',
    quizType: QuizType.topic,
    sectionId: 'introduction',
    topicId: 'basic_rhythm',
    questionDistribution: {
      QuestionType.multipleChoice: 10,
    },
    topicWeights: {
      'basic_rhythm': 1.0,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
    ),
    requiredConcepts: {
      'note_values',
      'time_signatures',
      'beats',
      'measures',
    },
    generationStrategy: QuizGenerationStrategy.focused,
    estimatedMinutes: 10,
  );

  /// Key Signatures topic quiz
  static const keySignaturesQuiz = QuizTemplate(
    id: 'intro_topic_key_signatures',
    name: 'Key Signatures Quiz',
    quizType: QuizType.topic,
    sectionId: 'introduction',
    topicId: 'key_signatures',
    questionDistribution: {
      QuestionType.multipleChoice: 7,
      QuestionType.scaleInteractive: 2,
    },
    topicWeights: {
      'key_signatures': 0.8,
      'basic_scales': 0.2,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.intermediate,
      maximum: DifficultyLevel.advanced,
      distribution: {
        DifficultyLevel.intermediate: 0.70,
        DifficultyLevel.advanced: 0.30,
      },
    ),
    requiredConcepts: {
      'sharps_and_flats',
      'major_keys',
      'key_signature_placement',
    },
    generationStrategy: QuizGenerationStrategy.focused,
    estimatedMinutes: 12,
  );

  /// Quick refresher quiz
  static const introductionRefresher = QuizTemplate(
    id: 'intro_refresher',
    name: 'Introduction Quick Review',
    quizType: QuizType.refresher,
    sectionId: 'introduction',
    questionDistribution: {
      QuestionType.multipleChoice: 5,
      QuestionType.scaleInteractive: 1,
    },
    topicWeights: {
      'music_basics': 0.20,
      'notes_and_staff': 0.30,
      'basic_rhythm': 0.25,
      'key_signatures': 0.25,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
    ),
    requiredConcepts: {},
    generationStrategy: QuizGenerationStrategy.review,
    estimatedMinutes: 5,
    constraints: {
      'shuffleQuestions': true,
      'allowSkip': true,
      'showProgress': true,
      'immediateFeeback': true,
    },
  );

  /// Scales and Chords combined quiz
  static const scalesAndChordsQuiz = QuizTemplate(
    id: 'intro_scales_chords',
    name: 'Scales and Chords Practice',
    quizType: QuizType.topic,
    sectionId: 'introduction',
    questionDistribution: {
      QuestionType.multipleChoice: 4,
      QuestionType.scaleInteractive: 3,
      QuestionType.chordInteractive: 3,
    },
    topicWeights: {
      'basic_scales': 0.5,
      'basic_chords': 0.5,
    },
    difficultyRange: DifficultyRange(
      minimum: DifficultyLevel.beginner,
      maximum: DifficultyLevel.intermediate,
      distribution: {
        DifficultyLevel.beginner: 0.50,
        DifficultyLevel.intermediate: 0.50,
      },
    ),
    requiredConcepts: {
      'major_scale',
      'scale_construction',
      'basic_chords',
      'chord_fingering',
    },
    generationStrategy: QuizGenerationStrategy.balanced,
    estimatedMinutes: 15,
    constraints: {
      'interactiveFirst': false,
      'alternateTypes': true,
    },
  );

  /// Get all templates for the Introduction section
  static List<QuizTemplate> get allTemplates => [
    sectionQuiz,
    musicBasicsQuiz,
    notesAndStaffQuiz,
    basicRhythmQuiz,
    keySignaturesQuiz,
    introductionRefresher,
    scalesAndChordsQuiz,
  ];

  /// Get template by ID
  static QuizTemplate? getTemplateById(String id) {
    try {
      return allTemplates.firstWhere((template) => template.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get templates by quiz type
  static List<QuizTemplate> getTemplatesByType(QuizType type) {
    return allTemplates.where((template) => template.quizType == type).toList();
  }

  /// Get topic-specific templates
  static List<QuizTemplate> getTopicTemplates(String topicId) {
    return allTemplates.where((template) => 
      template.topicId == topicId || 
      template.topicWeights.containsKey(topicId)
    ).toList();
  }
}