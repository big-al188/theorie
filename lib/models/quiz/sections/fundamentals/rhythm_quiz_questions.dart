// lib/models/quiz/sections/fundamentals/rhythm_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Rhythm" topic
class RhythmQuizQuestions {
  static const String topicId = 'rhythm';
  static const String topicTitle = 'Rhythm';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'rhythm_001',
        questionText: 'What is rhythm in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'The pattern of long and short sounds',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'How high or low notes are', isCorrect: false),
          AnswerOption(id: 'c', text: 'The volume of music', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'The type of instrument used', isCorrect: false),
        ],
        explanation:
            'Rhythm is the pattern of long and short sounds that makes music move and groove. It\'s what makes you want to tap your feet, clap your hands, or dance!',
      ),
      MultipleChoiceQuestion(
        id: 'rhythm_002',
        questionText: 'What is the beat in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'The steady pulse you feel', isCorrect: true),
          AnswerOption(id: 'b', text: 'The highest note', isCorrect: false),
          AnswerOption(id: 'c', text: 'The loudest sound', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'The first note of a song', isCorrect: false),
        ],
        explanation:
            'The beat is the steady pulse you feel in music - like a clock ticking. It\'s what you clap along to in a song and what keeps everything together.',
      ),
      MultipleChoiceQuestion(
        id: 'rhythm_003',
        questionText: 'How many beats does a whole note last?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: '4 beats', isCorrect: true),
          AnswerOption(id: 'b', text: '2 beats', isCorrect: false),
          AnswerOption(id: 'c', text: '1 beat', isCorrect: false),
          AnswerOption(id: 'd', text: 'Half a beat', isCorrect: false),
        ],
        explanation:
            'A whole note holds for 4 beats - like saying "goooooal" in soccer. It\'s the longest common note value.',
      ),
      MultipleChoiceQuestion(
        id: 'rhythm_004',
        questionText: 'How many beats does a quarter note last?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(id: 'a', text: '1 beat', isCorrect: true),
          AnswerOption(id: 'b', text: '2 beats', isCorrect: false),
          AnswerOption(id: 'c', text: '4 beats', isCorrect: false),
          AnswerOption(id: 'd', text: 'Half a beat', isCorrect: false),
        ],
        explanation:
            'A quarter note lasts for 1 beat each - like walking steps. They\'re the most common note value in many songs.',
      ),
      MultipleChoiceQuestion(
        id: 'rhythm_005',
        questionText: 'What are rests in music?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Silences that are part of the rhythm',
              isCorrect: true),
          AnswerOption(id: 'b', text: 'Very loud notes', isCorrect: false),
          AnswerOption(id: 'c', text: 'Very high notes', isCorrect: false),
          AnswerOption(id: 'd', text: 'Broken instruments', isCorrect: false),
        ],
        explanation:
            'Rests are silences that are an important part of music! They tell us when NOT to play and create space and breathing room in music.',
      ),
      MultipleChoiceQuestion(
        id: 'rhythm_006',
        questionText: 'Which rhythm pattern matches "We Will Rock You"?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'stomp-stomp-CLAP', isCorrect: true),
          AnswerOption(id: 'b', text: 'clap-clap-stomp', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'stomp-clap-stomp-clap', isCorrect: false),
          AnswerOption(id: 'd', text: 'clap-clap-clap-clap', isCorrect: false),
        ],
        explanation:
            '"We Will Rock You" has the famous stomp-stomp-CLAP rhythm pattern that everyone recognizes and wants to join in with!',
      ),
      MultipleChoiceQuestion(
        id: 'rhythm_007',
        questionText: 'Rhythm is found in which aspects of daily life?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Your heartbeat', isCorrect: true),
          AnswerOption(id: 'b', text: 'Walking', isCorrect: true),
          AnswerOption(id: 'c', text: 'Speaking', isCorrect: true),
          AnswerOption(id: 'd', text: 'Only in music', isCorrect: false),
        ],
        explanation:
            'Rhythm is everywhere in daily life! Your heartbeat has rhythm, walking has rhythm, speaking has rhythm, and even breathing has rhythm.',
      ),
      MultipleChoiceQuestion(
        id: 'rhythm_008',
        questionText: 'Try this rhythm game: how many claps for "Hamburger"?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: '3 medium claps', isCorrect: true),
          AnswerOption(id: 'b', text: '2 quick claps', isCorrect: false),
          AnswerOption(id: 'c', text: '4 quick claps', isCorrect: false),
          AnswerOption(id: 'd', text: '1 long clap', isCorrect: false),
        ],
        explanation:
            '"Hamburger" has three syllables (Ham-bur-ger), so it gets three medium claps. This is a fun way to practice feeling rhythm!',
      ),
    ];
  }
}
