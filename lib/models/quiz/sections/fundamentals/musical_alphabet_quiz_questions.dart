// lib/models/quiz/sections/fundamentals/musical_alphabet_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "The Musical Alphabet" topic
class MusicalAlphabetQuizQuestions {
  static const String topicId = 'musical-alphabet';
  static const String topicTitle = 'The Musical Alphabet';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'musical_alphabet_001',
        questionText: 'How many letters are in the musical alphabet?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: '7', isCorrect: true),
          AnswerOption(id: 'b', text: '12', isCorrect: false),
          AnswerOption(id: 'c', text: '26', isCorrect: false),
          AnswerOption(id: 'd', text: '8', isCorrect: false),
        ],
        explanation:
            'The musical alphabet contains only 7 letters: A, B, C, D, E, F, and G. These letters repeat over and over to name all the notes in music.',
      ),
      MultipleChoiceQuestion(
        id: 'musical_alphabet_002',
        questionText: 'What are the seven letters of the musical alphabet?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'A, B, C, D, E, F, G', isCorrect: true),
          AnswerOption(id: 'b', text: 'A, B, C, D, E, F, H', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Do, Re, Mi, Fa, Sol, La, Ti', isCorrect: false),
          AnswerOption(id: 'd', text: 'C, D, E, F, G, A, H', isCorrect: false),
        ],
        explanation:
            'The musical alphabet uses the letters A, B, C, D, E, F, and G. After G, the pattern starts over again at A.',
      ),
      MultipleChoiceQuestion(
        id: 'musical_alphabet_003',
        questionText:
            'What happens after we reach the letter G in the musical alphabet?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'We start over again at A', isCorrect: true),
          AnswerOption(id: 'b', text: 'We continue to H', isCorrect: false),
          AnswerOption(id: 'c', text: 'We stop', isCorrect: false),
          AnswerOption(id: 'd', text: 'We go backwards to F', isCorrect: false),
        ],
        explanation:
            'The musical alphabet repeats in a cycle. After G, we start over again at A, creating the pattern: A → B → C → D → E → F → G → A → B → C... and so on.',
      ),
      MultipleChoiceQuestion(
        id: 'musical_alphabet_004',
        questionText: 'Which memory trick helps remember the musical alphabet?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'All Big Cats Dance Every Friday Gently',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Always Be Cool During Every Fun Game',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Apples Bring Color During Each Fresh Growth',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'All Basic Chords Develop Every Fundamental Good',
              isCorrect: false),
        ],
        explanation:
            'The memory trick "All Big Cats Dance Every Friday Gently" helps remember the musical alphabet because the first letter of each word gives you A, B, C, D, E, F, G.',
      ),
      MultipleChoiceQuestion(
        id: 'musical_alphabet_005',
        questionText:
            'On a piano, which keys are named with the musical alphabet letters?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'The white keys', isCorrect: true),
          AnswerOption(id: 'b', text: 'The black keys', isCorrect: false),
          AnswerOption(id: 'c', text: 'Only the middle keys', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'All keys have the same name', isCorrect: false),
        ],
        explanation:
            'On a piano, the white keys are named with the musical alphabet letters (A, B, C, D, E, F, G). The black keys have different names using sharps and flats.',
      ),
      MultipleChoiceQuestion(
        id: 'musical_alphabet_006',
        questionText:
            'What makes the musical alphabet special compared to the regular alphabet?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'It only has 7 letters', isCorrect: true),
          AnswerOption(id: 'b', text: 'It repeats in a cycle', isCorrect: true),
          AnswerOption(id: 'c', text: 'It can make any song', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'It uses different symbols', isCorrect: false),
        ],
        explanation:
            'The musical alphabet is special because it only has 7 letters (not 26), it repeats in a cycle, and these 7 letters can be used to make any song in Western music.',
      ),
    ];
  }
}
