// lib/models/quiz/sections/introduction/whattheory_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "What is Music Theory?" topic
class WhatTheoryQuizQuestions {
  static const String topicId = 'what-is-music-theory';
  static const String topicTitle = 'What is Music Theory?';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'what_theory_001',
        questionText: 'According to the lesson, music theory is most like:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'Learning the ABCs of music', isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Memorizing every song ever written',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Only useful for classical musicians',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Making music more complicated', isCorrect: false),
        ],
        explanation:
            'Music theory is like learning the ABCs of music - it provides the fundamental building blocks that help us understand how music works.',
      ),
      MultipleChoiceQuestion(
        id: 'what_theory_002',
        questionText: 'What does understanding music theory help you do?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Understand why certain notes sound good together',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Learn new songs faster', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Create your own music with confidence',
              isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Only play classical music', isCorrect: false),
        ],
        explanation:
            'Music theory helps with understanding note relationships, learning songs faster, and creating music confidently. It applies to all genres, not just classical.',
      ),
      MultipleChoiceQuestion(
        id: 'what_theory_003',
        questionText: 'Music theory reveals that all music shares:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'The same simple patterns', isCorrect: true),
          AnswerOption(id: 'b', text: 'The same instruments', isCorrect: false),
          AnswerOption(id: 'c', text: 'The same lyrics', isCorrect: false),
          AnswerOption(id: 'd', text: 'The same tempo', isCorrect: false),
        ],
        explanation:
            'Music theory shows that all music, regardless of genre, follows the same basic patterns and principles.',
      ),
      MultipleChoiceQuestion(
        id: 'what_theory_004',
        questionText: 'The lesson compares music to:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'The universe', isCorrect: true),
          AnswerOption(id: 'b', text: 'A math problem', isCorrect: false),
          AnswerOption(id: 'c', text: 'A foreign language', isCorrect: false),
          AnswerOption(id: 'd', text: 'A painting', isCorrect: false),
        ],
        explanation:
            'The lesson describes music as the universe, with music theory helping us understand where we can go and the paths between sounds.',
      ),
      MultipleChoiceQuestion(
        id: 'what_theory_005',
        questionText:
            'According to the lesson, when you understand music theory you can:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Communicate ideas with other musicians',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Take any song and understand its structure',
              isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Only play songs you\'ve memorized',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Avoid learning new instruments',
              isCorrect: false),
        ],
        explanation:
            'Music theory enables communication with other musicians and helps you understand the structure of any song.',
      ),
      MultipleChoiceQuestion(
        id: 'what_theory_006',
        questionText:
            'The lesson states that music theory helps us understand:',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'The paths between sounds and connections',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Only how to read sheet music', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Which instruments are the best',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'How to tune instruments', isCorrect: false),
        ],
        explanation:
            'Music theory shows us the paths between sounds and the connections that make melodies soar and harmonies resonate.',
      ),
    ];
  }
}
