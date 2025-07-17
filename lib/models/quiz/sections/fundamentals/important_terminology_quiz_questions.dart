// lib/models/quiz/sections/fundamentals/important_terminology_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Important Terminology" topic
class ImportantTerminologyQuizQuestions {
  static const String topicId = 'important-terminology';
  static const String topicTitle = 'Important Terminology';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'terminology_001',
        questionText: 'What is a note in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'A single musical sound', isCorrect: true),
          AnswerOption(id: 'b', text: 'A group of sounds', isCorrect: false),
          AnswerOption(id: 'c', text: 'A rhythm pattern', isCorrect: false),
          AnswerOption(id: 'd', text: 'A musical instrument', isCorrect: false),
        ],
        explanation:
            'A note is a single musical sound - like a single letter in a word. When you press one piano key or pluck one guitar string, you make a note!',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_002',
        questionText: 'What is pitch?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'How high or low a sound is', isCorrect: true),
          AnswerOption(id: 'b', text: 'How loud a sound is', isCorrect: false),
          AnswerOption(id: 'c', text: 'How fast a sound is', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'How long a sound lasts', isCorrect: false),
        ],
        explanation:
            'Pitch is how high or low a sound is. A mouse has a high pitch (squeaky voice) while a lion has a low pitch (deep roar).',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_003',
        questionText: 'What is a melody?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'A series of notes that make a tune you can sing',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'Multiple notes played at the same time',
              isCorrect: false),
          AnswerOption(id: 'c', text: 'The rhythm of a song', isCorrect: false),
          AnswerOption(id: 'd', text: 'The volume of music', isCorrect: false),
        ],
        explanation:
            'A melody is a series of notes that make a tune you can sing. It\'s the part of a song you hum or whistle - like "Happy Birthday" or your favorite song\'s main tune.',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_004',
        questionText: 'What is harmony?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Different notes that sound good together at the same time',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'A single note played loudly', isCorrect: false),
          AnswerOption(id: 'c', text: 'The speed of music', isCorrect: false),
          AnswerOption(id: 'd', text: 'A type of instrument', isCorrect: false),
        ],
        explanation:
            'Harmony happens when different notes sound good together at the same time. It\'s like when friends sing different parts but they sound beautiful together!',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_005',
        questionText: 'What is tempo?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'How fast or slow music goes', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'How high or low music is', isCorrect: false),
          AnswerOption(id: 'c', text: 'How loud music is', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'What instruments are used', isCorrect: false),
        ],
        explanation:
            'Tempo is how fast or slow music goes. Like walking slowly in a park (slow tempo) or running in a race (fast tempo)!',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_006',
        questionText: 'What is a beat?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'The steady pulse in music', isCorrect: true),
          AnswerOption(id: 'b', text: 'A very loud note', isCorrect: false),
          AnswerOption(id: 'c', text: 'A high-pitched sound', isCorrect: false),
          AnswerOption(id: 'd', text: 'A broken instrument', isCorrect: false),
        ],
        explanation:
            'The beat is the steady pulse in music - like a clock ticking. It\'s what you clap along to in a song.',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_007',
        questionText: 'What is a scale?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'A group of notes arranged from low to high',
              isCorrect: true),
          AnswerOption(id: 'b', text: 'A rhythm pattern', isCorrect: false),
          AnswerOption(id: 'c', text: 'A type of guitar', isCorrect: false),
          AnswerOption(id: 'd', text: 'A loud sound', isCorrect: false),
        ],
        explanation:
            'A scale is a group of notes that sound good together, arranged from low to high (or high to low). It\'s like a musical ladder!',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_008',
        questionText: 'What is a chord?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Three or more notes played at the same time',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'One note played very loudly', isCorrect: false),
          AnswerOption(id: 'c', text: 'A fast rhythm', isCorrect: false),
          AnswerOption(id: 'd', text: 'A type of drum', isCorrect: false),
        ],
        explanation:
            'A chord is when you play three or more notes at the same time, and they sound nice together. It\'s like a musical sandwich - multiple layers that taste great together!',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_009',
        questionText: 'What is an octave?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text:
                  'The distance from one letter to the same letter higher or lower',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Eight different instruments', isCorrect: false),
          AnswerOption(id: 'c', text: 'A very fast rhythm', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'The loudest note possible', isCorrect: false),
        ],
        explanation:
            'An octave is the distance from one letter to the same letter higher or lower. Like from one C to the next C - they sound similar but one is higher!',
      ),
      MultipleChoiceQuestion(
        id: 'terminology_010',
        questionText: 'Which examples demonstrate different pitches?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(
              id: 'a', text: 'Bird chirps = high pitch', isCorrect: true),
          AnswerOption(id: 'b', text: 'Thunder = low pitch', isCorrect: true),
          AnswerOption(
              id: 'c',
              text: 'All sounds have the same pitch',
              isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Pitch only exists in music', isCorrect: false),
        ],
        explanation:
            'Bird chirps demonstrate high pitch while thunder demonstrates low pitch. Pitch exists in all sounds, not just music!',
      ),
    ];
  }
}
