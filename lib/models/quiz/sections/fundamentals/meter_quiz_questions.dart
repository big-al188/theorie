// lib/models/quiz/sections/fundamentals/meter_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Meter" topic
class MeterQuizQuestions {
  static const String topicId = 'meter';
  static const String topicTitle = 'Meter';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'meter_001',
        questionText: 'What is meter in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'How we group beats in music to create patterns',
              isCorrect: true),
          AnswerOption(id: 'b', text: 'How loud music is', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'What instruments are used', isCorrect: false),
          AnswerOption(id: 'd', text: 'The speed of music', isCorrect: false),
        ],
        explanation:
            'Meter is how we group beats in music to create patterns. It\'s like organizing words into sentences - it helps music make sense and gives it structure!',
      ),
      MultipleChoiceQuestion(
        id: 'meter_002',
        questionText: 'What are measures (or bars) in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Small sections that divide music like paragraphs',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'The volume level of music', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Types of musical instruments', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Different keys on a piano', isCorrect: false),
        ],
        explanation:
            'Measures (or bars) are small sections that divide music, like dividing a long story into paragraphs. Each measure contains a specific number of beats.',
      ),
      MultipleChoiceQuestion(
        id: 'meter_003',
        questionText: 'What is the pattern for duple meter?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'STRONG-weak, STRONG-weak (groups of 2)',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'STRONG-weak-weak (groups of 3)',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'STRONG-weak-medium-weak (groups of 4)',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'All beats are equally strong', isCorrect: false),
        ],
        explanation:
            'Duple meter has a STRONG-weak, STRONG-weak pattern in groups of 2. It feels like marching: LEFT-right, LEFT-right, and is very common in pop and rock music.',
      ),
      MultipleChoiceQuestion(
        id: 'meter_004',
        questionText: 'What is the pattern for triple meter?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a', text: 'STRONG-weak-weak (groups of 3)', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'STRONG-weak (groups of 2)', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'STRONG-weak-medium-weak (groups of 4)',
              isCorrect: false),
          AnswerOption(id: 'd', text: 'No pattern at all', isCorrect: false),
        ],
        explanation:
            'Triple meter has a STRONG-weak-weak pattern in groups of 3. It feels like waltzing: ONE-two-three, ONE-two-three, and creates a spinning, circular feeling.',
      ),
      MultipleChoiceQuestion(
        id: 'meter_005',
        questionText: 'What is the pattern for quadruple meter?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'STRONG-weak-medium-weak (groups of 4)',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'STRONG-weak (groups of 2)', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'STRONG-weak-weak (groups of 3)',
              isCorrect: false),
          AnswerOption(id: 'd', text: 'All beats are weak', isCorrect: false),
        ],
        explanation:
            'Quadruple meter has a STRONG-weak-medium-weak pattern in groups of 4. This is the most common meter in popular music and feels balanced and even.',
      ),
      MultipleChoiceQuestion(
        id: 'meter_006',
        questionText: 'Which movements help you feel different meters?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Duple: March in place', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Triple: Sway side to side', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Quadruple: Nod your head to pop music',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'All meters feel exactly the same',
              isCorrect: false),
        ],
        explanation:
            'Different movements help you feel meter: Duple = marching in place, Triple = swaying side to side, Quadruple = nodding your head to pop music. Your body naturally feels the meter!',
      ),
      MultipleChoiceQuestion(
        id: 'meter_007',
        questionText: 'Where do we find meter in daily life?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Walking (duple meter)', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Waltz dancing (triple meter)', isCorrect: true),
          AnswerOption(
              id: 'c', text: 'Your heartbeat (duple meter)', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Meter only exists in music', isCorrect: false),
        ],
        explanation:
            'Meter is everywhere in daily life! Walking is duple meter (left-right), waltz dancing is triple meter, your heartbeat is duple meter, and skipping is compound meter.',
      ),
      MultipleChoiceQuestion(
        id: 'meter_008',
        questionText: 'Why is meter important in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Helps musicians play together', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Creates the groove and feel', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Makes music predictable and satisfying',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'Only makes music more complicated',
              isCorrect: false),
        ],
        explanation:
            'Meter is important because it helps musicians play together, creates the groove and feel, makes music predictable and satisfying, and creates different moods. Different meters create different feelings!',
      ),
      MultipleChoiceQuestion(
        id: 'meter_009',
        questionText: 'What is the relationship between meter and dancing?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Meter is why you can dance to music',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Dancing has nothing to do with meter',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Only classical music has meter',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'You need special training to feel meter',
              isCorrect: false),
        ],
        explanation:
            'Meter is the framework that holds music together. It\'s why you can dance to music - your body naturally feels the meter and wants to move with it! No special training needed.',
      ),
    ];
  }
}
