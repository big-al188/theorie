// lib/models/quiz/sections/fundamentals/chromatic_scale_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "The Chromatic Scale" topic
class ChromaticScaleQuizQuestions {
  static const String topicId = 'chromatic-scale';
  static const String topicTitle = 'The Chromatic Scale';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'chromatic_001',
        questionText:
            'How many different notes are there in the chromatic scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: '12', isCorrect: true),
          AnswerOption(id: 'b', text: '7', isCorrect: false),
          AnswerOption(id: 'c', text: '8', isCorrect: false),
          AnswerOption(id: 'd', text: '24', isCorrect: false),
        ],
        explanation:
            'The chromatic scale includes all 12 different sounds we use in music. This includes the 7 letter notes plus the 5 sharps and flats between them.',
      ),
      MultipleChoiceQuestion(
        id: 'chromatic_002',
        questionText: 'What does the sharp symbol (#) mean?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'A tiny bit higher', isCorrect: true),
          AnswerOption(id: 'b', text: 'A tiny bit lower', isCorrect: false),
          AnswerOption(id: 'c', text: 'Much higher', isCorrect: false),
          AnswerOption(id: 'd', text: 'The same pitch', isCorrect: false),
        ],
        explanation:
            'Sharp (#) means "a tiny bit higher" - like taking a small step up. It raises the note by a half step.',
      ),
      MultipleChoiceQuestion(
        id: 'chromatic_003',
        questionText: 'What does the flat symbol (♭) mean?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'A tiny bit lower', isCorrect: true),
          AnswerOption(id: 'b', text: 'A tiny bit higher', isCorrect: false),
          AnswerOption(id: 'c', text: 'Much lower', isCorrect: false),
          AnswerOption(id: 'd', text: 'The same pitch', isCorrect: false),
        ],
        explanation:
            'Flat (♭) means "a tiny bit lower" - like taking a small step down. It lowers the note by a half step.',
      ),
      MultipleChoiceQuestion(
        id: 'chromatic_004',
        questionText:
            'Between which pairs of letters are there NO sharps or flats?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'B and C', isCorrect: true),
          AnswerOption(id: 'b', text: 'E and F', isCorrect: true),
          AnswerOption(id: 'c', text: 'C and D', isCorrect: false),
          AnswerOption(id: 'd', text: 'F and G', isCorrect: false),
        ],
        explanation:
            'There are no sharps or flats between B-C and E-F. These pairs are already as close as notes can be - they\'re like best friends standing right next to each other!',
      ),
      MultipleChoiceQuestion(
        id: 'chromatic_005',
        questionText: 'A# and B♭ are:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'The same sound with different names',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Two completely different notes',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'One higher than the other', isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Only used on different instruments',
              isCorrect: false),
        ],
        explanation:
            'A# and B♭ are the same sound, just with different names! This is called enharmonic equivalence. It\'s like how you might be called by your first name or a nickname - same person, different names.',
      ),
      MultipleChoiceQuestion(
        id: 'chromatic_006',
        questionText: 'On a piano keyboard, the sharps and flats are found on:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'The black keys', isCorrect: true),
          AnswerOption(id: 'b', text: 'The white keys', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Only the highest keys', isCorrect: false),
          AnswerOption(id: 'd', text: 'Only the lowest keys', isCorrect: false),
        ],
        explanation:
            'On a piano, the black keys represent the sharps and flats, while the white keys represent the natural notes (A, B, C, D, E, F, G).',
      ),
      MultipleChoiceQuestion(
        id: 'chromatic_007',
        questionText: 'The chromatic scale is like having:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: '12 different colored crayons instead of just 7',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'The same 7 colors repeated', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Only black and white colors', isCorrect: false),
          AnswerOption(id: 'd', text: 'Invisible colors', isCorrect: false),
        ],
        explanation:
            'The chromatic scale gives you all 12 different musical "colors" to work with, just like having a full box of crayons gives you more colors to create art with.',
      ),
    ];
  }
}
