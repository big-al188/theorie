// lib/models/quiz/sections/fundamentals/natural_minor_scale_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "The Natural Minor Scale" topic
class NaturalMinorScaleQuizQuestions {
  static const String topicId = 'natural-minor-scale';
  static const String topicTitle = 'The Natural Minor Scale';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'minor_scale_001',
        questionText:
            'How does the natural minor scale compare to the major scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text:
                  'If major is like a sunny day, minor is like a cloudy evening',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'They sound exactly the same', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Minor is always louder than major',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Minor has more notes than major',
              isCorrect: false),
        ],
        explanation:
            'If the major scale is like a sunny day, the natural minor scale is like a cloudy evening - not necessarily sad, but more serious and mysterious!',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_002',
        questionText: 'What is the interval pattern for a natural minor scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: 'W-H-W-W-H-W-W', isCorrect: true),
          AnswerOption(id: 'b', text: 'W-W-H-W-W-W-H', isCorrect: false),
          AnswerOption(id: 'c', text: 'H-W-W-W-H-W-W', isCorrect: false),
          AnswerOption(id: 'd', text: 'W-W-W-H-W-W-H', isCorrect: false),
        ],
        explanation:
            'The natural minor scale follows the pattern W-H-W-W-H-W-W. This is the same as the major scale pattern but starting from the 6th note instead!',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_003',
        questionText: 'In A minor, what are all the notes?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'A-B-C-D-E-F-G', isCorrect: true),
          AnswerOption(id: 'b', text: 'A-B♭-C-D-E♭-F-G', isCorrect: false),
          AnswerOption(id: 'c', text: 'A-B-C#-D-E-F#-G#', isCorrect: false),
          AnswerOption(id: 'd', text: 'A-C-E-G', isCorrect: false),
        ],
        explanation:
            'A minor uses only the white keys on a piano: A-B-C-D-E-F-G. This makes it the easiest minor scale to understand, just like C major is the easiest major scale.',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_004',
        questionText: 'What emotions can the minor scale express?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Thoughtful or mysterious', isCorrect: true),
          AnswerOption(id: 'b', text: 'Cool and powerful', isCorrect: true),
          AnswerOption(id: 'c', text: 'Emotional depth', isCorrect: true),
          AnswerOption(id: 'd', text: 'Only sadness', isCorrect: false),
        ],
        explanation:
            'Minor doesn\'t always mean sad! It can mean thoughtful, mysterious, cool, powerful, or have emotional depth. It\'s just another color in your musical paint box!',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_005',
        questionText:
            'What is the relative relationship between major and minor scales?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'They use the same notes but start in different places',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'They use completely different notes',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Minor scales have more notes', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'They cannot be related at all', isCorrect: false),
        ],
        explanation:
            'Every major scale has a "relative" minor scale that uses the exact same notes but starts in a different place! C major and A minor are relatives - same notes, different starting point, different feeling.',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_006',
        questionText: 'Where do we commonly hear minor scales?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Rock and metal songs', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Traditional folk songs', isCorrect: true),
          AnswerOption(
              id: 'c', text: 'Emotional moments in movies', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Only in classical music', isCorrect: false),
        ],
        explanation:
            'Minor scales are used in many types of music: rock and metal songs, traditional folk songs from around the world, emotional moments in movies, and spooky music.',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_007',
        questionText: 'Which song examples use minor scales?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: '"Greensleeves"', isCorrect: true),
          AnswerOption(
              id: 'b', text: '"House of the Rising Sun"', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'The "Imperial March" from Star Wars',
              isCorrect: true),
          AnswerOption(id: 'd', text: '"Happy Birthday"', isCorrect: false),
        ],
        explanation:
            'Famous minor scale songs include "Greensleeves," "House of the Rising Sun," and the "Imperial March" from Star Wars. Many lullabies and detective show themes also use minor scales.',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_008',
        questionText:
            'What is the key difference between major and minor scale patterns?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'The start of the pattern is different',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Minor scales have more whole steps',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Minor scales are played faster',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Minor scales use different instruments',
              isCorrect: false),
        ],
        explanation:
            'The start of the pattern is different! Major starts W-W-H, while minor starts W-H-W. This small change makes a big difference in how the scale sounds and feels.',
      ),
      MultipleChoiceQuestion(
        id: 'minor_scale_009',
        questionText: 'How many different notes are in a natural minor scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: '7', isCorrect: true),
          AnswerOption(id: 'b', text: '5', isCorrect: false),
          AnswerOption(id: 'c', text: '12', isCorrect: false),
          AnswerOption(id: 'd', text: '8', isCorrect: false),
        ],
        explanation:
            'Like the major scale, the natural minor scale contains 7 different notes. The pattern and feeling are different, but the number of notes is the same.',
      ),
    ];
  }
}
