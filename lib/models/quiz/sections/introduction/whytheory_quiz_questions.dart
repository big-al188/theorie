// lib/models/quiz/sections/introduction/whytheory_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Why Learn Music Theory?" topic
class WhyTheoryQuizQuestions {
  static const String topicId = 'why-learn-music-theory';
  static const String topicTitle = 'Why Learn Music Theory?';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'why_theory_001',
        questionText:
            'According to the lesson, music theory gives you a common language to:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'Connect with other musicians', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Argue about music styles', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Criticize other players', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Show off your knowledge', isCorrect: false),
        ],
        explanation:
            'Music theory provides a common language that helps musicians communicate and connect with each other effectively.',
      ),
      MultipleChoiceQuestion(
        id: 'why_theory_002',
        questionText:
            'What does the lesson say about learning songs with music theory?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'You see patterns instead of memorizing every note',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'You must write everything down first',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'You can only learn classical pieces',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'It makes learning slower but more accurate',
              isCorrect: false),
        ],
        explanation:
            'Music theory helps you recognize patterns in music, making it faster to learn songs instead of memorizing every individual note.',
      ),
      MultipleChoiceQuestion(
        id: 'why_theory_003',
        questionText:
            'The lesson mentions that music theory helps you create music by:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Turning melodies in your head into real songs',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Knowing which chords support your ideas',
              isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Expressing emotions through music',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'Copying other musicians exactly',
              isCorrect: false),
        ],
        explanation:
            'Music theory provides tools for turning musical ideas into reality, supporting melodies with appropriate chords, and expressing emotions musically.',
      ),
      MultipleChoiceQuestion(
        id: 'why_theory_004',
        questionText: 'What does the lesson say about mastering music theory?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'You don\'t need to master everything at once',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'You must learn everything before playing music',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Only experts should attempt to learn it',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'It takes decades to be useful', isCorrect: false),
        ],
        explanation:
            'The lesson emphasizes that each concept you learn immediately makes music more fun and accessible - you don\'t need to master everything before benefiting.',
      ),
      MultipleChoiceQuestion(
        id: 'why_theory_005',
        questionText:
            'According to the lesson, what can you do at jam sessions with music theory knowledge?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Join in when someone says "let\'s play in the key of G"',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Suggest chord changes that could make a song better',
              isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Share musical ideas clearly and confidently',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'Only listen without participating',
              isCorrect: false),
        ],
        explanation:
            'Music theory enables active participation in jam sessions through understanding keys, suggesting improvements, and clear communication.',
      ),
      MultipleChoiceQuestion(
        id: 'why_theory_006',
        questionText:
            'The lesson states that with music theory, practicing becomes:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'More like play and less like work',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'More difficult and time-consuming',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Only possible with a teacher', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Less important than before', isCorrect: false),
        ],
        explanation:
            'When you understand what you\'re playing, practice becomes more enjoyable and feels less like work.',
      ),
      MultipleChoiceQuestion(
        id: 'why_theory_007',
        questionText:
            'According to the lesson, learning music theory is about:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Enhancing your musical journey every step of the way',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Becoming a theory expert quickly',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Replacing natural musical instinct',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Learning to play only one style of music',
              isCorrect: false),
        ],
        explanation:
            'The lesson emphasizes that music theory is about enhancing your musical journey, not about becoming an expert or replacing musical instinct.',
      ),
    ];
  }
}
