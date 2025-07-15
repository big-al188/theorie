// lib/constants/quiz_constants.dart

import '../models/quiz/quiz_question.dart';

/// Quiz-related constants and extensions

/// Extension to provide display names for QuestionTopic enum
extension QuestionTopicExtension on QuestionTopic {
  /// Returns a human-readable display name for the topic
  String get displayName {
    switch (this) {
      case QuestionTopic.notes:
        return 'Notes';
      case QuestionTopic.intervals:
        return 'Intervals';
      case QuestionTopic.scales:
        return 'Scales';
      case QuestionTopic.chords:
        return 'Chords';
      case QuestionTopic.keySignatures:
        return 'Key Signatures';
      case QuestionTopic.modes:
        return 'Modes';
      case QuestionTopic.progressions:
        return 'Progressions';
      case QuestionTopic.theory:
        return 'Theory';
    }
  }
}

/// Quiz scoring constants
class QuizScoringConstants {
  static const double defaultPassingScore = 0.7;
  static const int defaultQuestionPointValue = 1;
  static const int defaultTimePerQuestionSeconds = 120;
}

/// Quiz display constants
class QuizDisplayConstants {
  static const String defaultCompleteTitle = 'Quiz Complete!';
  static const String defaultCompleteMessage = 'Great job completing the quiz';
  static const String defaultPassedStatus = 'PASSED';
  static const String defaultNeedsImprovementStatus = 'NEEDS IMPROVEMENT';
}
