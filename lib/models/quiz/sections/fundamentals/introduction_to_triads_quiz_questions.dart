// lib/models/quiz/sections/fundamentals/introduction_to_triads_quiz_questions.dart

import '../../multiple_choice_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Introduction to Triads" topic
class IntroductionToTriadsQuizQuestions {
  static const String topicId = 'introduction-to-triads';
  static const String topicTitle = 'Introduction to Triads';

  static List<MultipleChoiceQuestion> getQuestions() {
    return [
      MultipleChoiceQuestion(
        id: 'triads_001',
        questionText: 'What is a triad?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'The simplest type of chord with three notes',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'A rhythm with three beats', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Three instruments playing together',
              isCorrect: false),
          AnswerOption(id: 'd', text: 'A very loud note', isCorrect: false),
        ],
        explanation:
            'A triad is the simplest type of chord - just three notes that sound great together! They\'re called "triads" because "tri" means three.',
      ),
      MultipleChoiceQuestion(
        id: 'triads_002',
        questionText: 'What are the three parts of a triad?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a', text: 'Root, Third, and Fifth', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Low, Medium, and High', isCorrect: false),
          AnswerOption(
              id: 'c', text: 'First, Second, and Third', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Bass, Middle, and Treble', isCorrect: false),
        ],
        explanation:
            'A triad is like a three-layer cake: Bottom layer = Root (names the chord), Middle layer = Third (makes it major or minor), Top layer = Fifth (adds fullness).',
      ),
      MultipleChoiceQuestion(
        id: 'triads_003',
        questionText: 'How do you build a simple triad?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 15,
        options: [
          AnswerOption(
              id: 'a',
              text:
                  'Pick a root, skip a letter for the third, skip another for the fifth',
              isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Play three random notes', isCorrect: false),
          AnswerOption(id: 'c', text: 'Use only black keys', isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'Play the same note three times',
              isCorrect: false),
        ],
        explanation:
            'To build a triad: 1) Pick your root note (like C), 2) Skip a letter, add the third (E), 3) Skip another letter, add the fifth (G). C-E-G = C major triad!',
      ),
      MultipleChoiceQuestion(
        id: 'triads_004',
        questionText: 'How do major triads sound?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(id: 'a', text: 'Happy, bright, strong', isCorrect: true),
          AnswerOption(id: 'b', text: 'Sad, dark, weak', isCorrect: false),
          AnswerOption(id: 'c', text: 'Tense and scary', isCorrect: false),
          AnswerOption(id: 'd', text: 'Strange and dreamy', isCorrect: false),
        ],
        explanation:
            'Major triads sound happy, bright, and strong - like a sunny day! They use a root + major third + perfect fifth.',
      ),
      MultipleChoiceQuestion(
        id: 'triads_005',
        questionText: 'How do minor triads sound?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a', text: 'Sad, mysterious, thoughtful', isCorrect: true),
          AnswerOption(id: 'b', text: 'Happy and bright', isCorrect: false),
          AnswerOption(id: 'c', text: 'Very tense and scary', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'Exactly like major triads', isCorrect: false),
        ],
        explanation:
            'Minor triads sound sad, mysterious, or thoughtful - like a cloudy day. They use a root + minor third + perfect fifth.',
      ),
      MultipleChoiceQuestion(
        id: 'triads_006',
        questionText: 'What makes diminished triads special?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.advanced,
        pointValue: 20,
        options: [
          AnswerOption(
              id: 'a',
              text: 'They sound tense, scary, and unstable',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'They sound exactly like major triads',
              isCorrect: false),
          AnswerOption(
              id: 'c', text: 'They are always played loudly', isCorrect: false),
          AnswerOption(
              id: 'd', text: 'They use only black keys', isCorrect: false),
        ],
        explanation:
            'Diminished triads sound tense, scary, and unstable - like suspense in a movie! They use a root + minor third + diminished fifth.',
      ),
      MultipleChoiceQuestion(
        id: 'triads_007',
        questionText: 'What makes augmented triads unique?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.advanced,
        pointValue: 20,
        options: [
          AnswerOption(
              id: 'a',
              text: 'They sound strange, dreamy, and mysterious',
              isCorrect: true),
          AnswerOption(
              id: 'b',
              text: 'They sound happy like major triads',
              isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'They sound sad like minor triads',
              isCorrect: false),
          AnswerOption(
              id: 'd',
              text: 'They cannot be played on piano',
              isCorrect: false),
        ],
        explanation:
            'Augmented triads sound strange, dreamy, and mysterious - like a magic spell! They use a root + major third + augmented fifth.',
      ),
      MultipleChoiceQuestion(
        id: 'triads_008',
        questionText: 'Where are triads commonly found?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        multiSelect: true,
        options: [
          AnswerOption(id: 'a', text: 'Every song you know', isCorrect: true),
          AnswerOption(
              id: 'b', text: 'Piano and guitar music', isCorrect: true),
          AnswerOption(id: 'c', text: 'Orchestra music', isCorrect: true),
          AnswerOption(
              id: 'd', text: 'Only in classical music', isCorrect: false),
        ],
        explanation:
            'Triads are everywhere! They\'re in every song you know, piano music, guitar music, orchestras, and even doorbells often play triads! They\'re the foundation of all harmony.',
      ),
      MultipleChoiceQuestion(
        id: 'triads_009',
        questionText: 'What is an easy way to play triads on piano?',
        topic: QuestionTopic.theory,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        options: [
          AnswerOption(
              id: 'a',
              text: 'Play every other white key starting from any note',
              isCorrect: true),
          AnswerOption(id: 'b', text: 'Play only black keys', isCorrect: false),
          AnswerOption(
              id: 'c',
              text: 'Play three keys right next to each other',
              isCorrect: false),
          AnswerOption(id: 'd', text: 'Play random keys', isCorrect: false),
        ],
        explanation:
            'On piano, you can easily play triads by playing every other white key starting from any note. For example: C-E-G, or D-F-A, or E-G-B!',
      ),
    ];
  }
}
