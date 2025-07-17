// lib/models/quiz/sections/fundamentals/harmony_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Harmony" topic
class HarmonyQuizQuestions {
  static const String topicId = 'harmony';
  static const String topicTitle = 'Harmony';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'harmony_001',
        questionText: 'What is harmony in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Different notes sounding at the same time',
              isCorrect: true),
          AnswerOption(id: 'b', text: 'A single melody line', isCorrect: false),
          AnswerOption(id: 'c', text: 'The rhythm of a song', isCorrect: false),
          AnswerOption(id: 'd', text: 'How fast music plays', isCorrect: false),
        ],
        explanation:
            'Harmony is what happens when different notes sound at the same time and create something beautiful together. It\'s like musical teamwork!',
      ),
      MultipleChoiceQuestion(
        id: 'harmony_002',
        questionText: 'How does harmony add to music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'Adds depth and emotion', isCorrect: true),
          AnswerOption(id: 'b', text: 'Makes music louder', isCorrect: false),
          AnswerOption(id: 'c', text: 'Makes music faster', isCorrect: false),
          AnswerOption(id: 'd', text: 'Changes the rhythm', isCorrect: false),
        ],
        explanation:
            'Harmony adds depth and emotion to music. One note alone is like a single color, but when you combine notes (harmony), it\'s like mixing colors to create new, beautiful shades.',
      ),
      MultipleChoiceQuestion(
        id: 'harmony_003',
        questionText: 'What is consonance in harmony?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'When notes sound smooth and pleasant together',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'When notes clash and create tension',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'When notes are played very loudly',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'When notes are played one at a time',
              isCorrect: false),
        ],
        explanation:
            'Consonance is when notes sound smooth and pleasant together, like best friends holding hands or colors that match perfectly.',
      ),
      MultipleChoiceQuestion(
        id: 'harmony_004',
        questionText: 'What is dissonance in harmony?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text: 'When notes create tension or clash a bit',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'When notes sound perfectly smooth',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'When notes are played softly', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'When no notes are played', isCorrect: false),
        ],
        explanation:
            'Dissonance is when notes create tension or clash a bit. It\'s not bad, just different! Like spicy food - it adds excitement and is often used to create drama before resolving to consonance.',
      ),
      MultipleChoiceQuestion(
        id: 'harmony_005',
        questionText: 'Which are examples of simple, pleasant harmony?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Thirds (like C and E together)', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Fifths (like C and G together)', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'Octaves (same note, different heights)',
              isCorrect: true),
          AnswerOption(
              id: 'd',
              text: 'Only playing one note at a time',
              isCorrect: false),
        ],
        explanation:
            'Thirds (like C and E) are very sweet, fifths (like C and G) are strong and stable, and octaves (same note at different heights) blend perfectly. These are all examples of consonant harmony.',
      ),
      MultipleChoiceQuestion(
        id: 'harmony_006',
        questionText: 'Where do we commonly hear harmony in real life?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Church choirs singing in parts', isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Backup singers supporting the main singer',
              isCorrect: true),
          AnswerOption(
              id: 'c', text: 'Guitar chords under a melody', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Only in classical music', isCorrect: false),
        ],
        explanation:
            'Harmony is everywhere! We hear it in church choirs, backup singers, guitar chords, when people sing "Happy Birthday" in different parts, and in orchestra sections playing different notes together.',
      ),
      MultipleChoiceQuestion(
        id: 'harmony_007',
        questionText: 'How do major and minor harmony typically make us feel?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Major = happy, Minor = thoughtful',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Major = sad, Minor = happy', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'Both sound exactly the same', isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Only volume matters for feeling',
              isCorrect: false),
        ],
        explanation:
            'Major harmony typically sounds happy, bright, and positive, while minor harmony sounds more thoughtful, mysterious, or emotional. Different harmonies create different moods!',
      ),
      MultipleChoiceQuestion(
        id: 'harmony_008',
        questionText: 'What is harmony like in terms of friendship?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text:
                  'Different notes coming together to create something more beautiful',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Notes competing to be the loudest',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Notes that never work together',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Only one note can exist at a time',
              isCorrect: false),
        ],
        explanation:
            'Harmony is like friendship in music - different notes coming together to create something more beautiful than any could make alone. It\'s about cooperation and creating beauty together.',
      ),
    ];
  }
}
