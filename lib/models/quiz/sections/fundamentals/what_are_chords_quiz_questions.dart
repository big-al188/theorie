// lib/models/quiz/sections/fundamentals/what_are_chords_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "What are Chords?" topic
class WhatAreChordsQuizQuestions {
  static const String topicId = 'what-are-chords';
  static const String topicTitle = 'What are Chords?';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'chords_001',
        questionText: 'What is a chord?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Three or more notes played together',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'One note played loudly', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Two notes played in sequence', isCorrect: false),
          AnswerOption(id: 'd', text: 'A rhythm pattern', isCorrect: false),
        ],
        explanation:
            'A chord is three or more different notes played at the same time. It\'s like a musical sandwich with multiple ingredients layered together!',
      ),
      MultipleChoiceQuestion(
        id: 'chords_002',
        questionText: 'What are the three basic ingredients of a simple chord?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a', text: 'Root, Third, and Fifth', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Root, Second, and Fourth', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'First, Middle, and Last', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Low, Medium, and High', isCorrect: false),
        ],
        explanation:
            'Every basic chord has a Root (the main note that names the chord), a Third (determines if it\'s major or minor), and a Fifth (adds stability and fullness).',
      ),
      MultipleChoiceQuestion(
        id: 'chords_003',
        questionText: 'What\'s the difference between major and minor chords?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Major sounds happy, minor sounds thoughtful',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Major is louder than minor', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Major has more notes than minor',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'They are exactly the same', isCorrect: false),
        ],
        explanation:
            'Major chords sound bright, happy, and positive, while minor chords sound darker, thoughtful, and emotional. The difference is just one note, but what a difference it makes!',
      ),
      MultipleChoiceQuestion(
        id: 'chords_004',
        questionText: 'What do chords provide in most music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Support for the melody', isCorrect: true),
          AnswerOption(id: 'b', text: 'Mood and emotion', isCorrect: true),
          AnswerOption(id: 'c', text: 'Fullness and richness', isCorrect: true),
          AnswerOption(id: 'd', text: 'The main melody line', isCorrect: false),
        ],
        explanation:
            'Chords support the melody (like a foundation supports a house), create the mood and emotion, and make music sound full and complete.',
      ),
      MultipleChoiceQuestion(
        id: 'chords_005',
        questionText: 'What are chord progressions?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Chords moving from one to another',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Playing chords faster and faster',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Adding more notes to chords', isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Playing the same chord repeatedly',
              isCorrect: false),
        ],
        explanation:
            'Chord progressions are like words forming sentences - different chords move from one to another, creating different feelings and telling musical stories.',
      ),
      MultipleChoiceQuestion(
        id: 'chords_006',
        questionText: 'Where do we commonly hear chords being played?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Guitar strumming at campfires', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Piano players using both hands', isCorrect: true),
          AnswerOption(
              id: 'c', text: 'Groups singing in harmony', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Only in classical music', isCorrect: false),
        ],
        explanation:
            'Chords are everywhere! We hear them when someone plays guitar around a campfire, piano players using both hands, groups singing in harmony, and in the background of almost every song.',
      ),
      MultipleChoiceQuestion(
        id: 'chords_007',
        questionText: 'How many chords do you need to play many popular songs?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'Just 3 or 4', isCorrect: true),
          AnswerOption(id: 'b', text: 'At least 20', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'All 12 possible chords', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Hundreds of different chords', isCorrect: false),
        ],
        explanation:
            'With just 3 or 4 chords, you can play most folk songs, many pop songs, campfire favorites, and simple rock songs. It\'s amazing how much music you can make with so few chords!',
      ),
      MultipleChoiceQuestion(
        id: 'chords_008',
        questionText:
            'In the pizza analogy, what does each chord ingredient represent?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Root = dough, Third = sauce, Fifth = cheese',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Root = cheese, Third = dough, Fifth = sauce',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Root = sauce, Third = cheese, Fifth = dough',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'All ingredients are the same', isCorrect: false),
        ],
        explanation:
            'In the pizza analogy: Root = the dough (foundation), Third = the sauce (gives it character), Fifth = the cheese (completes it). Each ingredient has its own important role!',
      ),
    ];
  }
}
