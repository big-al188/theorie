// lib/models/quiz/sections/fundamentals/introduction_to_intervals_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Introduction to Intervals" topic
class IntroductionToIntervalsQuizQuestions {
  static const String topicId = 'introduction-to-intervals';
  static const String topicTitle = 'Introduction to Intervals';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'intervals_001',
        questionText: 'What is an interval in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'The distance between two notes', isCorrect: true),
          AnswerOption(id: 'b', text: 'A type of rhythm', isCorrect: false),
          AnswerOption(id: 'c', text: 'How loud a note is', isCorrect: false),
          AnswerOption(id: 'd', text: 'A musical instrument', isCorrect: false),
        ],
        explanation:
            'An interval is simply the distance between two notes. It\'s like measuring how many steps there are between where you are and where you want to go!',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_002',
        questionText: 'What is a half step?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'The smallest distance in music', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Two notes played together', isCorrect: false),
          AnswerOption(id: 'c', text: 'A very loud note', isCorrect: false),
          AnswerOption(id: 'd', text: 'Half the volume', isCorrect: false),
        ],
        explanation:
            'A half step is the smallest distance in music, like from C to C#. It\'s also called a minor second.',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_003',
        questionText: 'What is a whole step?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'Two half steps', isCorrect: true),
          AnswerOption(id: 'b', text: 'One half step', isCorrect: false),
          AnswerOption(id: 'c', text: 'Three half steps', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Playing all notes at once', isCorrect: false),
        ],
        explanation:
            'A whole step equals two half steps, like from C to D. It\'s also called a major second.',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_004',
        questionText: 'What is unison?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'When two notes are exactly the same',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'When notes are very far apart', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'When notes sound bad together', isCorrect: false),
          AnswerOption(id: 'd', text: 'A type of instrument', isCorrect: false),
        ],
        explanation:
            'Unison is when two notes are exactly the same - like two people singing the exact same note. No distance at all!',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_005',
        questionText: 'What basic intervals are formed by skipping letters?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Third (skip one letter, like C to E)',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Fourth (skip two letters, like C to F)',
              isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Fifth (skip three letters, like C to G)',
              isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Playing the same note twice', isCorrect: false),
        ],
        explanation:
            'These simple intervals are created by skipping letters: Third (C to E), Fourth (C to F), and Fifth (C to G). They\'re the building blocks of harmony!',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_006',
        questionText: 'How do small intervals typically sound?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: 'Tense or mysterious', isCorrect: true),
          AnswerOption(id: 'b', text: 'Always happy', isCorrect: false),
          AnswerOption(id: 'c', text: 'Very dramatic', isCorrect: false),
          AnswerOption(id: 'd', text: 'Completely silent', isCorrect: false),
        ],
        explanation:
            'Small intervals (like half steps) can sound tense or mysterious. They create a sense of closeness that can feel uncomfortable or suspenseful.',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_007',
        questionText: 'How do large intervals typically sound?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: 'Dramatic or exciting', isCorrect: true),
          AnswerOption(id: 'b', text: 'Always sad', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Tense and uncomfortable', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Exactly like small intervals', isCorrect: false),
        ],
        explanation:
            'Large intervals can sound dramatic or exciting. They create a sense of space and openness that can feel powerful or soaring.',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_008',
        questionText: 'Which song starts with a big octave jump?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: '"Somewhere Over the Rainbow"', isCorrect: true),
          AnswerOption(
              id: 'b',
              text: '"Twinkle, Twinkle, Little Star"',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: '"Mary Had a Little Lamb"', isCorrect: false),
          AnswerOption(id: 'd', text: '"Happy Birthday"', isCorrect: false),
        ],
        explanation:
            '"Somewhere Over the Rainbow" famously starts with a big octave jump on the word "Some-where," creating a dramatic, soaring effect.',
      ),
      MultipleChoiceQuestion(
        id: 'intervals_009',
        questionText: 'What are intervals the building blocks of?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Melodies', isCorrect: true),
          AnswerOption(id: 'b', text: 'Chords', isCorrect: true),
          AnswerOption(id: 'c', text: 'Harmonies', isCorrect: true),
          AnswerOption(id: 'd', text: 'Only rhythm', isCorrect: false),
        ],
        explanation:
            'Intervals are the building blocks of melodies (notes jumping different distances), chords (different intervals stacked together), and harmonies (intervals sounding together). Every melody is just a series of intervals!',
      ),
    ];
  }
}
