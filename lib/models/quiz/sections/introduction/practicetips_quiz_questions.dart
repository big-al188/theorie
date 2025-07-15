// lib/models/quiz/sections/introduction/practicetips_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Practice Tips" topic
class PracticeTipsQuizQuestions {
  static const String topicId = 'practice-tips';
  static const String topicTitle = 'Practice Tips';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'practice_tips_001',
        questionText: 'The lesson describes learning music theory as:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'A journey, not a destination', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'A race to finish quickly', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Only for serious students', isCorrect: false),
          AnswerOption(id: 'd', text: 'A test you must pass', isCorrect: false),
        ],
        explanation:
            'Learning music theory is presented as a journey - an ongoing process of discovery and growth rather than a destination to reach.',
      ),
      MultipleChoiceQuestion(
        id: 'practice_tips_002',
        questionText: 'Which practice approach does the lesson recommend?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Short, regular practice sessions',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Long sessions once per week', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Only practice when you feel like it',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Practice only with a teacher present',
              isCorrect: false),
        ],
        explanation:
            'The lesson recommends consistent, short practice sessions rather than infrequent long sessions for better retention and progress.',
      ),
      MultipleChoiceQuestion(
        id: 'practice_tips_003',
        questionText:
            'What should you do when music theory concepts seem confusing?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Take breaks and come back to it later',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Force yourself to understand it immediately',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Skip it and never return', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Give up learning music theory', isCorrect: false),
        ],
        explanation:
            'The lesson suggests that taking breaks when concepts are confusing allows your mind to process the information, often leading to better understanding when you return.',
      ),
      MultipleChoiceQuestion(
        id: 'practice_tips_004',
        questionText: 'The lesson suggests connecting music theory to:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Songs you already know and love',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Only classical music examples', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Complex mathematical formulas', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Abstract concepts only', isCorrect: false),
        ],
        explanation:
            'Connecting theory to familiar songs helps make abstract concepts concrete and personally meaningful.',
      ),
      MultipleChoiceQuestion(
        id: 'practice_tips_005',
        questionText:
            'According to the lesson, what should be your attitude when starting to learn music theory?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Be patient and enjoy the process',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Rush to learn everything immediately',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Focus only on the most difficult concepts',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Compare yourself constantly to others',
              isCorrect: false),
        ],
        explanation:
            'The lesson emphasizes patience and enjoying the learning process as a journey of discovery.',
      ),
      MultipleChoiceQuestion(
        id: 'practice_tips_006',
        questionText:
            'What does the lesson say about applying music theory to your playing?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Start with simple concepts and build up gradually',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Learn all theory before touching your instrument',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Only focus on advanced concepts',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Ignore practical application until later',
              isCorrect: false),
        ],
        explanation:
            'The lesson advocates for starting with simple concepts and gradually building understanding through practical application.',
      ),
    ];
  }
}
