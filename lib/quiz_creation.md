# Quiz Creation Guide

## Overview
This guide covers the complete process of creating new quizzes and questions for the Theorie app. The quiz system supports topic-based and section-based quizzes with multiple question types, detailed explanations, and performance tracking.

## Quiz System Architecture

### Core Components
1. **Question Models** - Data structures for different question types
2. **Quiz Generator** - Central system for creating quizzes
3. **Quiz Controller** - State management and session handling
4. **Quiz Widgets** - UI components for quiz display

### File Organization
```
lib/models/quiz/
├── quiz_question.dart              # Base question model
├── multiple_choice_question.dart   # Multiple choice implementation
├── quiz_session.dart               # Quiz session management
├── quiz_result.dart                # Quiz result tracking
└── sections/                       # Section-specific questions
    ├── introduction/
    │   ├── whattheory_quiz_questions.dart
    │   ├── whytheory_quiz_questions.dart
    │   └── practicetips_quiz_questions.dart
    └── fundamentals/
        ├── scales_quiz_questions.dart
        ├── chords_quiz_questions.dart
        └── intervals_quiz_questions.dart
```

## Question Models

### Base QuizQuestion Model
```dart
abstract class QuizQuestion {
  final String id;
  final String topicId;
  final String sectionId;
  final String questionText;
  final QuestionType type;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final String explanation;
  final Map<String, dynamic> metadata;

  const QuizQuestion({
    required this.id,
    required this.topicId,
    required this.sectionId,
    required this.questionText,
    required this.type,
    required this.difficulty,
    required this.tags,
    required this.explanation,
    this.metadata = const {},
  });

  // Abstract methods to be implemented by subclasses
  bool isCorrect(dynamic answer);
  String getDetailedExplanation(dynamic selectedAnswer);
  Map<String, dynamic> toJson();
}
```

### Multiple Choice Question Model
```dart
class MultipleChoiceQuestion extends QuizQuestion {
  final List<AnswerOption> options;
  final bool multiSelect;
  final List<String> correctAnswers;

  const MultipleChoiceQuestion({
    required super.id,
    required super.topicId,
    required super.sectionId,
    required super.questionText,
    required super.difficulty,
    required super.tags,
    required super.explanation,
    required this.options,
    required this.correctAnswers,
    this.multiSelect = false,
    super.metadata = const {},
  }) : super(type: QuestionType.multipleChoice);

  @override
  bool isCorrect(dynamic answer) {
    if (multiSelect) {
      // Handle multi-select answers
      final Set<String> selectedIds = _extractSelectedIds(answer);
      return selectedIds.length == correctAnswers.length &&
          selectedIds.every((id) => correctAnswers.contains(id));
    } else {
      // Handle single-select answers
      final String selectedId = _extractSingleId(answer);
      return correctAnswers.contains(selectedId);
    }
  }

  @override
  String getDetailedExplanation(dynamic selectedAnswer) {
    final buffer = StringBuffer();
    
    // Add base explanation
    buffer.writeln(explanation);
    
    // Add specific feedback based on selected answer
    if (selectedAnswer != null) {
      buffer.writeln('\n**Your Answer:**');
      buffer.writeln(_getAnswerFeedback(selectedAnswer));
    }
    
    // Add correct answer information
    buffer.writeln('\n**Correct Answer:**');
    buffer.writeln(_getCorrectAnswerExplanation());
    
    return buffer.toString();
  }
}
```

### Answer Option Model
```dart
class AnswerOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String? explanation;
  final Map<String, dynamic> metadata;

  const AnswerOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCorrect': isCorrect,
    'explanation': explanation,
    'metadata': metadata,
  };

  factory AnswerOption.fromJson(Map<String, dynamic> json) => AnswerOption(
    id: json['id'],
    text: json['text'],
    isCorrect: json['isCorrect'],
    explanation: json['explanation'],
    metadata: json['metadata'] ?? {},
  );
}
```

## Creating Quiz Questions

### Step 1: Create Section Question File
Create a new file in `lib/models/quiz/sections/{section}/`:

```dart
// lib/models/quiz/sections/fundamentals/scales_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

class ScalesQuizQuestions {
  static const String sectionId = 'fundamentals';
  static const String topicId = 'scales';
  static const String topicTitle = 'Scales';

  static List<QuizQuestion> getQuestions() {
    return [
      _createMajorScalePatternQuestion(),
      _createScaleDegreesQuestion(),
      _createKeySignatureQuestion(),
      _createModeQuestion(),
      _createPracticalApplicationQuestion(),
    ];
  }

  static MultipleChoiceQuestion _createMajorScalePatternQuestion() {
    return MultipleChoiceQuestion(
      id: 'scales_major_pattern_001',
      topicId: topicId,
      sectionId: sectionId,
      questionText: 'What is the interval pattern for a major scale?',
      difficulty: DifficultyLevel.beginner,
      tags: ['scales', 'major', 'intervals', 'pattern'],
      explanation: '''
The major scale follows a specific pattern of whole steps (W) and half steps (H).
This pattern creates the characteristic "happy" sound of major scales and is
the foundation for understanding all other scales and modes.
      ''',
      options: [
        AnswerOption(
          id: 'a',
          text: 'W-W-H-W-W-W-H',
          isCorrect: true,
          explanation: 'Correct! This is the major scale pattern.',
        ),
        AnswerOption(
          id: 'b',
          text: 'W-H-W-W-H-W-W',
          isCorrect: false,
          explanation: 'This is the natural minor scale pattern.',
        ),
        AnswerOption(
          id: 'c',
          text: 'H-W-W-W-H-W-W',
          isCorrect: false,
          explanation: 'This pattern doesn\'t correspond to any common scale.',
        ),
        AnswerOption(
          id: 'd',
          text: 'W-W-W-H-W-W-H',
          isCorrect: false,
          explanation: 'This pattern has too many consecutive whole steps.',
        ),
      ],
      correctAnswers: ['a'],
      metadata: {
        'category': 'theory',
        'instrument': 'guitar',
        'estimatedTime': 30,
      },
    );
  }

  static MultipleChoiceQuestion _createScaleDegreesQuestion() {
    return MultipleChoiceQuestion(
      id: 'scales_degrees_001',
      topicId: topicId,
      sectionId: sectionId,
      questionText: 'In the key of C major, what note is the 5th degree?',
      difficulty: DifficultyLevel.beginner,
      tags: ['scales', 'major', 'degrees', 'C major'],
      explanation: '''
Scale degrees are numbered positions within a scale. In C major, the notes are:
1st (Tonic) = C, 2nd (Supertonic) = D, 3rd (Mediant) = E, 4th (Subdominant) = F,
5th (Dominant) = G, 6th (Submediant) = A, 7th (Leading Tone) = B, 8th (Octave) = C
      ''',
      options: [
        AnswerOption(
          id: 'a',
          text: 'E',
          isCorrect: false,
          explanation: 'E is the 3rd degree (mediant) of C major.',
        ),
        AnswerOption(
          id: 'b',
          text: 'F',
          isCorrect: false,
          explanation: 'F is the 4th degree (subdominant) of C major.',
        ),
        AnswerOption(
          id: 'c',
          text: 'G',
          isCorrect: true,
          explanation: 'Correct! G is the 5th degree (dominant) of C major.',
        ),
        AnswerOption(
          id: 'd',
          text: 'A',
          isCorrect: false,
          explanation: 'A is the 6th degree (submediant) of C major.',
        ),
      ],
      correctAnswers: ['c'],
    );
  }

  // Continue with other question creation methods...
}
```

### Step 2: Register Questions in UnifiedQuizGenerator
Update `lib/controllers/unified_quiz_generator.dart`:

```dart
// Add import
import '../models/quiz/sections/fundamentals/scales_quiz_questions.dart';

// Update _getFundamentalsTopicQuestions method
List<QuizQuestion> _getFundamentalsTopicQuestions(String topicId) {
  switch (topicId) {
    case ScalesQuizQuestions.topicId:
      return ScalesQuizQuestions.getQuestions();
    // Add other topics...
    default:
      return [];
  }
}

// Update _getSectionTopicIds method
List<String> _getSectionTopicIds(String sectionId) {
  switch (sectionId) {
    case 'fundamentals':
      return [
        ScalesQuizQuestions.topicId,
        // Add other topic IDs...
      ];
    // Other sections...
  }
}

// Update _getFundamentalsTopicTitle method
String _getFundamentalsTopicTitle(String topicId) {
  switch (topicId) {
    case ScalesQuizQuestions.topicId:
      return ScalesQuizQuestions.topicTitle;
    // Add other topics...
    default:
      return 'Unknown Topic';
  }
}
```

## Question Types and Patterns

### 1. Theory Questions
Focus on understanding concepts:

```dart
static MultipleChoiceQuestion _createTheoryQuestion() {
  return MultipleChoiceQuestion(
    id: 'theory_001',
    questionText: 'What is the function of the dominant chord in a key?',
    difficulty: DifficultyLevel.intermediate,
    tags: ['theory', 'harmony', 'function'],
    explanation: '''
The dominant chord (V) creates tension that wants to resolve to the tonic (I).
This is the most important harmonic relationship in Western music and forms
the basis of functional harmony.
    ''',
    options: [
      AnswerOption(
        id: 'a',
        text: 'Creates tension that resolves to tonic',
        isCorrect: true,
      ),
      AnswerOption(
        id: 'b',
        text: 'Provides stability and rest',
        isCorrect: false,
        explanation: 'This describes the tonic function, not dominant.',
      ),
      // More options...
    ],
    correctAnswers: ['a'],
  );
}
```

### 2. Practical Application Questions
Focus on real-world use:

```dart
static MultipleChoiceQuestion _createPracticalQuestion() {
  return MultipleChoiceQuestion(
    id: 'practical_001',
    questionText: 'Which scale would you use to solo over a minor ii-V-i progression?',
    difficulty: DifficultyLevel.advanced,
    tags: ['scales', 'improvisation', 'jazz'],
    explanation: '''
For minor ii-V-i progressions, the harmonic minor scale and its modes work well.
The natural minor scale can also be used, but the harmonic minor provides better
voice leading and stronger resolution to the tonic.
    ''',
    options: [
      AnswerOption(
        id: 'a',
        text: 'Harmonic minor scale',
        isCorrect: true,
      ),
      AnswerOption(
        id: 'b',
        text: 'Major pentatonic scale',
        isCorrect: false,
        explanation: 'Major pentatonic doesn\'t fit well over minor progressions.',
      ),
      // More options...
    ],
    correctAnswers: ['a'],
  );
}
```

### 3. Multi-Select Questions
For complex topics with multiple correct answers:

```dart
static MultipleChoiceQuestion _createMultiSelectQuestion() {
  return MultipleChoiceQuestion(
    id: 'multi_001',
    questionText: 'Which of the following are characteristics of the Dorian mode?',
    difficulty: DifficultyLevel.intermediate,
    tags: ['modes', 'dorian', 'characteristics'],
    multiSelect: true,
    explanation: '''
The Dorian mode is the second mode of the major scale. It has a minor quality
but with a natural 6th degree, which gives it a distinctive sound that's
neither fully major nor minor.
    ''',
    options: [
      AnswerOption(
        id: 'a',
        text: 'Has a natural 6th degree',
        isCorrect: true,
      ),
      AnswerOption(
        id: 'b',
        text: 'Sounds minor but brighter than natural minor',
        isCorrect: true,
      ),
      AnswerOption(
        id: 'c',
        text: 'Has a flattened 7th degree',
        isCorrect: true,
      ),
      AnswerOption(
        id: 'd',
        text: 'Is the same as the natural minor scale',
        isCorrect: false,
        explanation: 'Dorian differs from natural minor by having a natural 6th.',
      ),
    ],
    correctAnswers: ['a', 'b', 'c'],
  );
}
```

## Question Writing Guidelines

### 1. Clear and Unambiguous Questions
- Use simple, direct language
- Avoid double negatives
- Make questions specific and focused
- Test questions with others to ensure clarity

### 2. Educational Value
- Each question should teach something
- Include comprehensive explanations
- Connect to practical applications
- Build on previous knowledge

### 3. Appropriate Difficulty Progression
```dart
enum DifficultyLevel {
  beginner,    // Basic concepts, simple recognition
  intermediate, // Application, analysis
  advanced,    // Synthesis, complex relationships
  expert,      // Advanced applications, nuanced understanding
}
```

### 4. Effective Distractors
- Make incorrect answers plausible
- Include common misconceptions
- Provide explanations for why they're wrong
- Avoid obviously incorrect options

### 5. Comprehensive Explanations
```dart
explanation: '''
[Brief statement of the correct answer]

[Detailed explanation of why it's correct]

[Additional context or related information]

[Practical applications or examples]
''',
```

## Quiz Session Configuration

### QuizGenerationConfig
```dart
class QuizGenerationConfig {
  const QuizGenerationConfig({
    this.questionCount = 10,
    this.timeLimit,
    this.allowSkip = true,
    this.allowReview = true,
    this.passingScore = 0.7,
    this.randomSeed,
  });

  final int questionCount;
  final int? timeLimit;
  final bool allowSkip;
  final bool allowReview;
  final double passingScore;
  final int? randomSeed;
}
```

### Creating Quiz Sessions
```dart
// Topic-specific quiz
final session = generator.createTopicQuizSession(
  sectionId: 'fundamentals',
  topicId: 'scales',
  config: QuizGenerationConfig(
    questionCount: 8,
    timeLimit: 10, // minutes
    allowSkip: false,
    passingScore: 0.8,
  ),
);

// Section-wide quiz
final session = generator.createSectionQuizSession(
  sectionId: 'fundamentals',
  config: QuizGenerationConfig(
    questionCount: 15,
    timeLimit: 20,
    allowReview: true,
  ),
);
```

## Best Practices

### 1. Question Quality
- **Accuracy**: Ensure all musical information is correct
- **Relevance**: Questions should relate to learning objectives
- **Clarity**: Test questions with others before implementation
- **Balance**: Mix different difficulty levels and question types

### 2. Performance Considerations
- **Efficient Loading**: Keep question files reasonably sized
- **Memory Management**: Avoid loading all questions at once
- **Caching**: Cache frequently accessed questions
- **Lazy Loading**: Load questions only when needed

### 3. Maintainability
- **Consistent Structure**: Follow established patterns
- **Clear Organization**: Group related questions together
- **Documentation**: Comment complex question logic
- **Version Control**: Track changes to questions

### 4. Testing
```dart
void main() {
  group('Scales Quiz Questions', () {
    test('should have valid question structure', () {
      final questions = ScalesQuizQuestions.getQuestions();
      
      expect(questions.length, greaterThan(0));
      
      for (final question in questions) {
        expect(question.id, isNotEmpty);
        expect(question.questionText, isNotEmpty);
        expect(question.explanation, isNotEmpty);
        
        if (question is MultipleChoiceQuestion) {
          expect(question.options.length, greaterThan(1));
          expect(question.correctAnswers, isNotEmpty);
        }
      }
    });
    
    test('should have correct answer validation', () {
      final questions = ScalesQuizQuestions.getQuestions();
      
      for (final question in questions) {
        if (question is MultipleChoiceQuestion) {
          // Test correct answers
          final correctAnswer = question.options
              .where((opt) => question.correctAnswers.contains(opt.id))
              .first;
          expect(question.isCorrect(correctAnswer), isTrue);
          
          // Test incorrect answers
          final incorrectAnswer = question.options
              .where((opt) => !question.correctAnswers.contains(opt.id))
              .first;
          expect(question.isCorrect(incorrectAnswer), isFalse);
        }
      }
    });
  });
}
```

## Integration with Learning Content

### Aligning with Topics
Ensure quiz questions align with learning content:

```dart
// Learning topic ID should match quiz topic ID
const topicId = 'fundamentals_scales'; // Used in both places

// Questions should test concepts from the learning content
static MultipleChoiceQuestion _createQuestion() {
  return MultipleChoiceQuestion(
    topicId: topicId, // Same ID as learning topic
    questionText: 'Question based on learning content...',
    // ...
  );
}
```

### Progressive Difficulty
Match question difficulty to learning progression:

1. **Beginner**: Basic recognition and definitions
2. **Intermediate**: Application and analysis
3. **Advanced**: Synthesis and complex relationships
4. **Expert**: Advanced applications and nuanced understanding

## Common Pitfalls to Avoid

1. **Ambiguous Questions**: Always test questions for clarity
2. **Incorrect Music Theory**: Verify all musical information
3. **Poor Explanations**: Provide comprehensive explanations
4. **Unbalanced Difficulty**: Include appropriate difficulty progression
5. **Missing Integration**: Ensure questions align with learning content

## Maintenance and Updates

### Adding New Questions
1. Create the question using established patterns
2. Test for accuracy and clarity
3. Ensure proper difficulty classification
4. Update the question count in tests

### Updating Existing Questions
1. Maintain question IDs for consistency
2. Update explanations as needed
3. Test changes thoroughly
4. Consider impact on existing user progress

### Performance Monitoring
- Monitor question load times
- Track user performance on questions
- Identify questions that need improvement
- Update based on user feedback

This guide provides a comprehensive approach to creating high-quality quiz questions that enhance the learning experience in the Theorie app. Follow these patterns and guidelines to ensure educational value, technical accuracy, and seamless integration with the rest of the application.