// lib/models/quiz/sections/fundamentals/open_chords_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Open Chords" topic
class OpenChordsQuizQuestions {
  static const String topicId = 'open-chords';
  static const String topicTitle = 'Open Chords';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'open_chords_001',
        questionText: 'What are open chords?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Chords that use open strings on the guitar',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Chords played very loudly', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Chords with only one note', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Chords that sound bad', isCorrect: false),
        ],
        explanation:
            'Open chords are chords that use open strings on the guitar. They\'re called "open" because some strings ring out without being pressed down - they\'re open and free!',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_002',
        questionText:
            'Why are open chords typically learned first by guitarists?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Easier on your fingers', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Sound great right away', isCorrect: true),
          AnswerOption(
              id: 'c', text: 'Used in thousands of songs', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'They are the hardest to learn', isCorrect: false),
        ],
        explanation:
            'Open chords are learned first because they\'re easier on your fingers, sound great right away, are used in thousands of songs, and help build finger strength gradually.',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_003',
        questionText: 'Which are common major open chords?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'C Major', isCorrect: true),
          AnswerOption(id: 'b', text: 'G Major', isCorrect: true),
          AnswerOption(id: 'c', text: 'D Major', isCorrect: true),
          AnswerOption(id: 'd', text: 'F# Major', isCorrect: false),
        ],
        explanation:
            'Common major open chords include C Major (bright and happy), G Major (full and strong), D Major (clear and cheerful), A Major (warm and friendly), and E Major (big and bold).',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_004',
        questionText: 'Which are common minor open chords?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'A Minor', isCorrect: true),
          AnswerOption(id: 'b', text: 'E Minor', isCorrect: true),
          AnswerOption(id: 'c', text: 'D Minor', isCorrect: true),
          AnswerOption(id: 'd', text: 'B Minor', isCorrect: false),
        ],
        explanation:
            'Common minor open chords include A Minor (thoughtful and mellow), E Minor (deep and emotional), and D Minor (gentle and sad).',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_005',
        questionText: 'What do open strings create in open chords?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Natural resonance', isCorrect: true),
          AnswerOption(id: 'b', text: 'Fuller sound', isCorrect: true),
          AnswerOption(
              id: 'c', text: 'Beautiful ringing tones', isCorrect: true),
          AnswerOption(id: 'd', text: 'Muted, dull sounds', isCorrect: false),
        ],
        explanation:
            'Open strings vibrate freely, creating natural resonance, fuller sound, easier transitions, less finger fatigue, and beautiful ringing tones.',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_006',
        questionText:
            'Which chord progression uses all open chords and appears in "Wonderwall"?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: 'G, D, C, Em', isCorrect: true),
          AnswerOption(id: 'b', text: 'F#, Bb, Eb, Gm', isCorrect: false),
          AnswerOption(id: 'c', text: 'B, F#, E, A', isCorrect: false),
          AnswerOption(id: 'd', text: 'C#, G#, D#, A#', isCorrect: false),
        ],
        explanation:
            '"Wonderwall" uses the open chord progression G, D, C, Em. This is a very popular progression that works great with open chords!',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_007',
        questionText: 'Which open chord families sound great together?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'G, C, and D', isCorrect: true),
          AnswerOption(id: 'b', text: 'A, D, and E', isCorrect: true),
          AnswerOption(id: 'c', text: 'Am, F, and C', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'All chords sound bad together', isCorrect: false),
        ],
        explanation:
            'Some open chords are "friends" that sound great together: G, C, and D; A, D, and E; Am, F, and C; Em, G, and D. These families work well in many songs!',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_008',
        questionText:
            'What types of songs can you play with just 3-4 open chords?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Most folk songs', isCorrect: true),
          AnswerOption(id: 'b', text: 'Many pop songs', isCorrect: true),
          AnswerOption(id: 'c', text: 'Campfire favorites', isCorrect: true),
          AnswerOption(id: 'd', text: 'Only classical music', isCorrect: false),
        ],
        explanation:
            'With just 3-4 open chords, you can play most folk songs, many pop songs, campfire favorites, and simple rock songs. It\'s amazing how much music you can make!',
      ),
      MultipleChoiceQuestion(
        id: 'open_chords_009',
        questionText: 'What tips help when learning open chords?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Press firmly but don\'t squeeze too hard',
              isCorrect: true),
          AnswerOption(id: 'b', text: 'Keep fingers curved', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Practice changing between chords slowly',
              isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Press as hard as possible', isCorrect: false),
        ],
        explanation:
            'Good tips for open chords: press firmly but don\'t squeeze too hard, keep fingers curved, strum only the strings you need, practice changing between chords slowly, and let open strings ring clearly.',
      ),
    ];
  }
}
