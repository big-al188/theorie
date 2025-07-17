// lib/models/quiz/sections/fundamentals/time_signatures_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Time Signatures" topic
class TimeSignaturesQuizQuestions {
  static const String topicId = 'time-signatures';
  static const String topicTitle = 'Time Signatures';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'time_sig_001',
        questionText: 'What is a time signature?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Numbers that tell us how to count music',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'How loud music should be', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'What instruments to use', isCorrect: false),
          AnswerOption(id: 'd', text: 'The key of the song', isCorrect: false),
        ],
        explanation:
            'Time signatures are like a map for reading music. Those two numbers you see at the beginning of sheet music tell musicians how to count and feel the beat!',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_002',
        questionText: 'What do the two numbers in a time signature represent?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Top = beats per measure, Bottom = what note gets one beat',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Top = volume, Bottom = speed', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Top = key signature, Bottom = tempo',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Both numbers mean the same thing',
              isCorrect: false),
        ],
        explanation:
            'The top number tells you how many beats are in each measure, and the bottom number tells you what type of note gets one beat. It\'s like a fraction but for music!',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_003',
        questionText: 'What does 4/4 time mean?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: '4 beats per measure, quarter note gets the beat',
              isCorrect: true),
          AnswerOption(id: 'b', text: '4 notes per song', isCorrect: false),
          AnswerOption(
              id: 'c', text: '4 instruments playing', isCorrect: false),
          AnswerOption(id: 'd', text: '4 minutes long', isCorrect: false),
        ],
        explanation:
            '4/4 time means 4 beats per measure with the quarter note getting one beat. It sounds like: 1-2-3-4, 1-2-3-4, and is used in most pop, rock, and hip-hop!',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_004',
        questionText: 'Why is 4/4 time called "Common Time"?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'It\'s the most common time signature in popular music',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'It\'s the easiest to play', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'It was invented first', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'It uses common instruments', isCorrect: false),
        ],
        explanation:
            '4/4 time is called "Common Time" because it\'s so widely used in popular music. It\'s so common it\'s sometimes shown as "C" instead of 4/4.',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_005',
        questionText: 'What does 3/4 time mean and how does it feel?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: '3 beats per measure, feels like waltzing',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: '3 instruments playing together',
              isCorrect: false),
          AnswerOption(id: 'c', text: '3 notes per chord', isCorrect: false),
          AnswerOption(id: 'd', text: '3 minutes of music', isCorrect: false),
        ],
        explanation:
            '3/4 time has 3 beats per measure with the quarter note getting one beat. It sounds like: 1-2-3, 1-2-3, and is perfect for dancing in circles (waltzing)!',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_006',
        questionText: 'What does 2/4 time feel like?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a', text: 'Like marching: 1-2, 1-2', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Like waltzing in circles', isCorrect: false),
          AnswerOption(id: 'c', text: 'Like sitting still', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Like running very fast', isCorrect: false),
        ],
        explanation:
            '2/4 time has 2 beats per measure and feels like marching: 1-2, 1-2. It\'s great for marches and some children\'s songs.',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_007',
        questionText: 'What makes 6/8 time special?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.advanced,
        pointValue: 20,
        options: [
          AnswerOption(
              id: 'a',
              text:
                  '6 beats per measure but felt in 2 big beats with a lilting feel',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Exactly the same as 6/4 time', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Only used in classical music', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Has 6 different instruments', isCorrect: false),
        ],
        explanation:
            '6/8 time has 6 eighth-note beats per measure, but it feels like 2 big beats (1-2-3, 4-5-6) with a lilting, rolling feeling. It\'s used in ballads and Irish jigs.',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_008',
        questionText: 'Which songs match their time signatures?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: '"Twinkle Twinkle" = 4/4 time', isCorrect: true),
          AnswerOption(
              id: 'b', text: '"Happy Birthday" = 3/4 time', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: '"Stars and Stripes Forever" = 2/4 time',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'All songs use the same time signature',
              isCorrect: false),
        ],
        explanation:
            'Different songs use different time signatures: "Twinkle Twinkle" in 4/4, "Happy Birthday" in 3/4, "Stars and Stripes Forever" in 2/4, and "Nothing Else Matters" in 6/8.',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_009',
        questionText:
            'How do different time signatures create different feelings?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: '4/4 = steady, balanced, "normal"',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: '3/4 = graceful, spinning, dance-like',
              isCorrect: true),
          AnswerOption(
              id: 'c',
              text: '2/4 = march-like, direct, simple',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'All time signatures feel exactly the same',
              isCorrect: false),
        ],
        explanation:
            'Different time signatures create different feelings: 4/4 feels steady and balanced, 3/4 feels graceful and spinning, 2/4 feels march-like and direct, 6/8 feels rolling and gentle.',
      ),
      MultipleChoiceQuestion(
        id: 'time_sig_010',
        questionText:
            'Once you feel the pattern of a time signature, what happens to counting?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'Counting becomes natural', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Counting becomes impossible', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'You have to count faster', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'You need a calculator', isCorrect: false),
        ],
        explanation:
            'Time signatures are just a way to organize music. Once you feel the pattern, counting becomes natural - like knowing when to clap along to your favorite song!',
      ),
    ];
  }
}
