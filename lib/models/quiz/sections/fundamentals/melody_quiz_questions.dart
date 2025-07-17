// lib/models/quiz/sections/fundamentals/melody_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Melody" topic
class MelodyQuizQuestions {
  static const String topicId = 'melody';
  static const String topicTitle = 'Melody';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'melody_001',
        questionText: 'What is a melody?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text:
                  'A series of notes played one after another that creates a tune',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Multiple notes played at the same time',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'The rhythm pattern of a song', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'How loud or soft music is', isCorrect: false),
        ],
        explanation:
            'A melody is a series of notes played one after another that creates a tune. It\'s the part of a song you sing in the shower, whistle while you work, or can\'t get out of your head!',
      ),
      MultipleChoiceQuestion(
        id: 'melody_002',
        questionText: 'In most music, what role does melody play?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'The main character or star of the show',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Background support only', isCorrect: false),
          AnswerOption(id: 'c', text: 'The rhythm section', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'The least important part', isCorrect: false),
        ],
        explanation:
            'In most music, melody is like the main character in a movie - it\'s what we follow and remember, while other parts (harmony, rhythm) support it. It\'s usually the part we sing.',
      ),
      MultipleChoiceQuestion(
        id: 'melody_003',
        questionText: 'Which describes different ways melodies can move?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Ascending (going up like climbing stairs)',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Descending (going down like sliding)',
              isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Arc (up then down like throwing a ball)',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'Always staying on the same note',
              isCorrect: false),
        ],
        explanation:
            'Melodies have shape and direction! They can move ascending (up), descending (down), in arcs (up then down), or in waves (up and down repeatedly like ocean waves).',
      ),
      MultipleChoiceQuestion(
        id: 'melody_004',
        questionText: 'What is stepwise motion in melody?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Notes right next to each other (smooth and easy)',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Jumping to faraway notes', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Playing the same note repeatedly',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Playing notes randomly', isCorrect: false),
        ],
        explanation:
            'Stepwise motion means notes are right next to each other, creating smooth and easy melodic movement. It sounds natural and flowing.',
      ),
      MultipleChoiceQuestion(
        id: 'melody_005',
        questionText: 'What are leaps in melody?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Jumping to faraway notes (dramatic and exciting)',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Notes right next to each other',
              isCorrect: false),
          AnswerOption(id: 'c', text: 'Very quiet notes', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Notes played very fast', isCorrect: false),
        ],
        explanation:
            'Leaps are when melody jumps to faraway notes, creating dramatic and exciting movement. They add surprise and energy to melodies.',
      ),
      MultipleChoiceQuestion(
        id: 'melody_006',
        questionText: 'What makes a melody memorable?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Repetition of ideas so we remember them',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Slight changes to keep things interesting',
              isCorrect: true),
          AnswerOption(id: 'c', text: 'A catchy "hook"', isCorrect: true),
          AnswerOption(id: 'd', text: 'Using only one note', isCorrect: false),
        ],
        explanation:
            'Great melodies often repeat ideas so we remember them, make slight changes to keep things interesting, and have a "hook" - the super catchy part that sticks in your head.',
      ),
      MultipleChoiceQuestion(
        id: 'melody_007',
        questionText: 'How do high and low melodies typically affect mood?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'High = bright or excited, Low = serious or calm',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'High = sad, Low = happy', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Both sound exactly the same', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Only volume matters for mood', isCorrect: false),
        ],
        explanation:
            'High melodies can sound bright or excited, while low melodies can sound serious or calm. The pitch range helps create different emotional feelings.',
      ),
      MultipleChoiceQuestion(
        id: 'melody_008',
        questionText: 'What makes each song unique?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Its melody is like a musical fingerprint',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'All songs have the same melody',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Only the rhythm matters', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Only the instruments used', isCorrect: false),
        ],
        explanation:
            'Melody is what makes each song unique - it\'s the musical fingerprint that makes "Twinkle Twinkle" different from "Mary Had a Little Lamb" even though they might use similar notes!',
      ),
      MultipleChoiceQuestion(
        id: 'melody_009',
        questionText: 'How can you start creating simple melodies?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Humming random notes', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Making up tunes to words', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Changing familiar melodies slightly',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'Never experimenting with sounds',
              isCorrect: false),
        ],
        explanation:
            'You can start creating melodies by humming random notes, making up tunes to words, changing familiar melodies slightly, or following the rhythm of spoken words. Start simple and have fun!',
      ),
    ];
  }
}
