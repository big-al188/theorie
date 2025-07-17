// lib/models/quiz/sections/fundamentals/major_scale_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "The Major Scale" topic
class MajorScaleQuizQuestions {
  static const String topicId = 'major-scale';
  static const String topicTitle = 'The Major Scale';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'major_scale_001',
        questionText: 'What is the interval pattern for a major scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: 'W-W-H-W-W-W-H', isCorrect: true),
          AnswerOption(id: 'b', text: 'W-H-W-W-H-W-W', isCorrect: false),
          AnswerOption(id: 'c', text: 'H-W-W-W-H-W-W', isCorrect: false),
          AnswerOption(id: 'd', text: 'W-W-W-H-W-W-H', isCorrect: false),
        ],
        explanation:
            'The major scale follows the pattern W-W-H-W-W-W-H (where W = whole step and H = half step). This pattern creates the characteristic "happy" sound of major scales.',
      ),
      MultipleChoiceQuestion(
        id: 'major_scale_002',
        questionText: 'How many different notes are in a major scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: '7', isCorrect: true),
          AnswerOption(id: 'b', text: '8', isCorrect: false),
          AnswerOption(id: 'c', text: '12', isCorrect: false),
          AnswerOption(id: 'd', text: '6', isCorrect: false),
        ],
        explanation:
            'A major scale contains 7 different notes. Even though we often include the octave (8th note), it\'s the same as the first note, just higher.',
      ),
      MultipleChoiceQuestion(
        id: 'major_scale_003',
        questionText: 'What are the solfège syllables for the major scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'Do-Re-Mi-Fa-Sol-La-Ti-Do', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'La-Ti-Do-Re-Mi-Fa-Sol-La', isCorrect: false),
          AnswerOption(id: 'c', text: 'A-B-C-D-E-F-G-A', isCorrect: false),
          AnswerOption(id: 'd', text: 'C-D-E-F-G-A-B-C', isCorrect: false),
        ],
        explanation:
            'The solfège syllables Do-Re-Mi-Fa-Sol-La-Ti-Do represent the major scale pattern. You know this from "The Sound of Music"!',
      ),
      MultipleChoiceQuestion(
        id: 'major_scale_004',
        questionText: 'What feeling does the major scale typically create?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Happy', isCorrect: true),
          AnswerOption(id: 'b', text: 'Bright', isCorrect: true),
          AnswerOption(id: 'c', text: 'Positive', isCorrect: true),
          AnswerOption(id: 'd', text: 'Sad', isCorrect: false),
        ],
        explanation:
            'The major scale sounds happy, bright, and positive. It\'s often described as "sunny" or "cheerful" and is used in celebration songs and upbeat music.',
      ),
      MultipleChoiceQuestion(
        id: 'major_scale_005',
        questionText: 'What is the first note of a major scale called?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: 'Tonic or home note', isCorrect: true),
          AnswerOption(id: 'b', text: 'Leading tone', isCorrect: false),
          AnswerOption(id: 'c', text: 'Dominant', isCorrect: false),
          AnswerOption(id: 'd', text: 'Subdominant', isCorrect: false),
        ],
        explanation:
            'The first note of a major scale is called the "tonic" or "home" note. It\'s where the scale starts and ends, and it feels like coming home when you hear it.',
      ),
      MultipleChoiceQuestion(
        id: 'major_scale_006',
        questionText: 'In C major, what are all the notes?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'C-D-E-F-G-A-B', isCorrect: true),
          AnswerOption(id: 'b', text: 'C-D-E-F#-G-A-B', isCorrect: false),
          AnswerOption(id: 'c', text: 'C-D-E♭-F-G-A-B♭', isCorrect: false),
          AnswerOption(id: 'd', text: 'C-D♭-E-F-G♭-A-B', isCorrect: false),
        ],
        explanation:
            'C major uses only the white keys on a piano: C-D-E-F-G-A-B. This is why it\'s often the first major scale students learn - no sharps or flats!',
      ),
      MultipleChoiceQuestion(
        id: 'major_scale_007',
        questionText: 'Which song famously teaches the major scale pattern?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: '"Do-Re-Mi" from The Sound of Music',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: '"Twinkle, Twinkle, Little Star"',
              isCorrect: false),
          AnswerOption(id: 'c', text: '"Happy Birthday"', isCorrect: false),
          AnswerOption(
              id: 'd', text: '"Mary Had a Little Lamb"', isCorrect: false),
        ],
        explanation:
            '"Do-Re-Mi" from The Sound of Music specifically teaches the major scale using the solfège syllables. It\'s a great way to learn how the major scale sounds!',
      ),
      MultipleChoiceQuestion(
        id: 'major_scale_008',
        questionText: 'If you know the major scale pattern, you can:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Build a major scale starting from any note',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Understand chord construction', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Create melodies that sound good',
              isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Only play in the key of C', isCorrect: false),
        ],
        explanation:
            'Once you know the major scale pattern (W-W-H-W-W-W-H), you can apply it starting from any note to create major scales, understand chords, and create melodies. It\'s like having a recipe that always works!',
      ),
    ];
  }
}
