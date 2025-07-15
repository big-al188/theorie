// lib/models/quiz/quiz_result.dart

import 'package:flutter/foundation.dart';
import 'quiz_question.dart';
import 'quiz_session.dart';

/// Represents the result for an individual question
class QuestionResultDetail {
  const QuestionResultDetail({
    required this.question,
    required this.userAnswer,
    required this.questionResult,
    required this.pointsEarned,
    required this.timeSpent,
    this.hintsUsed = 0,
    this.wasSkipped = false,
  });

  /// The question that was answered
  final QuizQuestion question;

  /// The user's submitted answer
  final dynamic userAnswer;

  /// The validation result for this answer
  final QuestionResult questionResult;

  /// Points earned for this question
  final double pointsEarned;

  /// Time spent answering this question
  final Duration timeSpent;

  /// Number of hints used
  final int hintsUsed;

  /// Whether the question was skipped
  final bool wasSkipped;

  /// Whether this question was answered correctly
  bool get isCorrect => questionResult.isCorrect;

  /// Score as a percentage for this question
  double get scorePercentage => pointsEarned / question.pointValue;

  Map<String, dynamic> toJson() {
    return {
      'question': question.toJson(),
      'userAnswer': userAnswer?.toString(),
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
      'timeSpent': timeSpent.inMilliseconds,
      'hintsUsed': hintsUsed,
      'wasSkipped': wasSkipped,
      'scorePercentage': scorePercentage,
    };
  }
}

/// Represents performance statistics for a quiz topic
class TopicPerformance {
  const TopicPerformance({
    required this.topic,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.totalPoints,
    required this.pointsEarned,
    required this.averageTime,
  });

  /// The topic these statistics refer to
  final QuestionTopic topic;

  /// Number of questions attempted for this topic
  final int questionsAttempted;

  /// Number of questions answered correctly
  final int questionsCorrect;

  /// Total possible points for this topic
  final double totalPoints;

  /// Points earned for this topic
  final double pointsEarned;

  /// Average time spent per question on this topic
  final Duration averageTime;

  /// Accuracy percentage for this topic
  double get accuracy =>
      questionsAttempted > 0 ? questionsCorrect / questionsAttempted : 0.0;

  /// Score percentage for this topic
  double get scorePercentage =>
      totalPoints > 0 ? pointsEarned / totalPoints : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'topic': topic.name,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
      'totalPoints': totalPoints,
      'pointsEarned': pointsEarned,
      'accuracy': accuracy,
      'scorePercentage': scorePercentage,
      'averageTime': averageTime.inMilliseconds,
    };
  }
}

/// Comprehensive result data for a completed quiz
///
/// This class calculates and stores all relevant metrics about a quiz
/// performance including scoring, timing, topic breakdown, and improvement
/// suggestions.
class QuizResult {
  const QuizResult({
    required this.sessionId,
    required this.quizType,
    required this.completedAt,
    required this.totalQuestions,
    required this.questionsAnswered,
    required this.questionsCorrect,
    required this.questionsSkipped,
    required this.totalPossiblePoints,
    required this.pointsEarned,
    required this.timeSpent,
    required this.questionResults,
    required this.topicPerformance,
    this.passingScore = 0.7,
    this.timeLimitMinutes,
    this.hintsUsed = 0,
  });

  /// ID of the quiz session this result belongs to
  final String sessionId;

  /// Type of quiz that was completed
  final QuizType quizType;

  /// When the quiz was completed
  final DateTime completedAt;

  /// Total number of questions in the quiz
  final int totalQuestions;

  /// Number of questions that were answered (including incorrect)
  final int questionsAnswered;

  /// Number of questions answered correctly
  final int questionsCorrect;

  /// Number of questions that were skipped
  final int questionsSkipped;

  /// Maximum points possible for this quiz
  final double totalPossiblePoints;

  /// Points earned by the user
  final double pointsEarned;

  /// Total time spent on the quiz
  final Duration timeSpent;

  /// Detailed results for each question
  final List<QuestionResultDetail> questionResults;

  /// Performance breakdown by topic
  final List<TopicPerformance> topicPerformance;

  /// Minimum score required to pass
  final double passingScore;

  /// Time limit for the quiz (if any)
  final int? timeLimitMinutes;

  /// Total number of hints used
  final int hintsUsed;

  // Calculated properties

  /// Overall score as a percentage (0.0 to 1.0)
  double get scorePercentage =>
      totalPossiblePoints > 0 ? pointsEarned / totalPossiblePoints : 0.0;

  /// Accuracy percentage (correct answers / total answered)
  double get accuracy =>
      questionsAnswered > 0 ? questionsCorrect / questionsAnswered : 0.0;

  /// Completion percentage (questions answered / total questions)
  double get completionPercentage =>
      totalQuestions > 0 ? questionsAnswered / totalQuestions : 0.0;

  /// Whether the user passed the quiz
  bool get passed => scorePercentage >= passingScore;

  /// Grade letter based on score percentage
  String get letterGrade {
    final score = scorePercentage;
    if (score >= 0.97) return 'A+';
    if (score >= 0.93) return 'A';
    if (score >= 0.90) return 'A-';
    if (score >= 0.87) return 'B+';
    if (score >= 0.83) return 'B';
    if (score >= 0.80) return 'B-';
    if (score >= 0.77) return 'C+';
    if (score >= 0.73) return 'C';
    if (score >= 0.70) return 'C-';
    if (score >= 0.67) return 'D+';
    if (score >= 0.63) return 'D';
    if (score >= 0.60) return 'D-';
    return 'F';
  }

  /// Average time per question
  Duration get averageTimePerQuestion {
    if (questionsAnswered == 0) return Duration.zero;
    return Duration(
        milliseconds: timeSpent.inMilliseconds ~/ questionsAnswered);
  }

  /// Whether the quiz was completed within time limit
  bool get completedWithinTimeLimit {
    if (timeLimitMinutes == null) return true;
    return timeSpent.inMinutes <= timeLimitMinutes!;
  }

  /// Topics where performance was below average
  List<TopicPerformance> get weakTopics {
    if (topicPerformance.isEmpty) return [];
    final averageScore = topicPerformance
            .map((tp) => tp.scorePercentage)
            .reduce((a, b) => a + b) /
        topicPerformance.length;

    return topicPerformance
        .where((tp) =>
            tp.scorePercentage < averageScore && tp.scorePercentage < 0.8)
        .toList()
      ..sort((a, b) => a.scorePercentage.compareTo(b.scorePercentage));
  }

  /// Topics where performance was above average
  List<TopicPerformance> get strongTopics {
    if (topicPerformance.isEmpty) return [];
    final averageScore = topicPerformance
            .map((tp) => tp.scorePercentage)
            .reduce((a, b) => a + b) /
        topicPerformance.length;

    return topicPerformance
        .where((tp) =>
            tp.scorePercentage >= averageScore && tp.scorePercentage >= 0.8)
        .toList()
      ..sort((a, b) => b.scorePercentage.compareTo(a.scorePercentage));
  }

  /// Questions that were answered incorrectly
  List<QuestionResultDetail> get incorrectQuestions =>
      questionResults.where((qr) => !qr.isCorrect && !qr.wasSkipped).toList();

  /// Questions that were skipped
  List<QuestionResultDetail> get skippedQuestions =>
      questionResults.where((qr) => qr.wasSkipped).toList();

  /// Creates a QuizResult from a completed QuizSession
  static QuizResult fromSession(QuizSession session) {
    if (!session.isCompleted) {
      throw ArgumentError('Cannot create result from incomplete session');
    }

    final questionResults = <QuestionResultDetail>[];
    final topicStats = <QuestionTopic, _TopicStats>{};

    double totalPossiblePoints = 0;
    double pointsEarned = 0;
    int questionsCorrect = 0;
    int questionsSkipped = 0;
    int questionsAnswered = 0;
    int totalHintsUsed = 0;

    // Process each question and calculate detailed results
    for (final question in session.questions) {
      totalPossiblePoints += question.pointValue;

      final userAnswer = session.getAnswerForQuestion(question.id);
      if (userAnswer == null) {
        // Question was not attempted at all
        continue;
      }

      final timeSpent = userAnswer.timeSpent ?? Duration.zero;
      final wasSkipped = userAnswer.isSkipped;

      if (wasSkipped) {
        questionsSkipped++;
        questionResults.add(QuestionResultDetail(
          question: question,
          userAnswer: null,
          questionResult: QuestionResult(
            isCorrect: false,
            userAnswer: null,
            correctAnswer: question.correctAnswer,
          ),
          pointsEarned: 0,
          timeSpent: timeSpent,
          hintsUsed: userAnswer.hintsUsed,
          wasSkipped: true,
        ));
      } else {
        questionsAnswered++;
        final questionResult = question.validateAnswer(userAnswer.answer);
        final questionPoints =
            question.calculateScore(userAnswer.answer, timeTaken: timeSpent) *
                question.pointValue;

        pointsEarned += questionPoints;
        if (questionResult.isCorrect) questionsCorrect++;
        totalHintsUsed += userAnswer.hintsUsed;

        questionResults.add(QuestionResultDetail(
          question: question,
          userAnswer: userAnswer.answer,
          questionResult: questionResult,
          pointsEarned: questionPoints,
          timeSpent: timeSpent,
          hintsUsed: userAnswer.hintsUsed,
          wasSkipped: false,
        ));

        // Update topic statistics
        final topic = question.topic;
        final stats = topicStats[topic] ?? _TopicStats();
        stats.questionsAttempted++;
        if (questionResult.isCorrect) stats.questionsCorrect++;
        stats.totalPoints += question.pointValue;
        stats.pointsEarned += questionPoints;
        stats.totalTime += timeSpent;
        topicStats[topic] = stats;
      }
    }

    // Convert topic statistics to TopicPerformance objects
    final topicPerformance = topicStats.entries.map((entry) {
      final topic = entry.key;
      final stats = entry.value;
      return TopicPerformance(
        topic: topic,
        questionsAttempted: stats.questionsAttempted,
        questionsCorrect: stats.questionsCorrect,
        totalPoints: stats.totalPoints,
        pointsEarned: stats.pointsEarned,
        averageTime: stats.questionsAttempted > 0
            ? Duration(
                milliseconds:
                    stats.totalTime.inMilliseconds ~/ stats.questionsAttempted)
            : Duration.zero,
      );
    }).toList();

    return QuizResult(
      sessionId: session.id,
      quizType: session.quizType,
      completedAt: session.endTime!,
      totalQuestions: session.totalQuestions,
      questionsAnswered: questionsAnswered,
      questionsCorrect: questionsCorrect,
      questionsSkipped: questionsSkipped,
      totalPossiblePoints: totalPossiblePoints,
      pointsEarned: pointsEarned,
      timeSpent: session.timeElapsed!,
      questionResults: questionResults,
      topicPerformance: topicPerformance,
      passingScore: session.passingScore,
      timeLimitMinutes: session.timeLimit,
      hintsUsed: totalHintsUsed,
    );
  }

  /// Serializes the result to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'quizType': quizType.name,
      'completedAt': completedAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'questionsAnswered': questionsAnswered,
      'questionsCorrect': questionsCorrect,
      'questionsSkipped': questionsSkipped,
      'totalPossiblePoints': totalPossiblePoints,
      'pointsEarned': pointsEarned,
      'timeSpent': timeSpent.inMilliseconds,
      'questionResults': questionResults.map((qr) => qr.toJson()).toList(),
      'topicPerformance': topicPerformance.map((tp) => tp.toJson()).toList(),
      'passingScore': passingScore,
      'timeLimitMinutes': timeLimitMinutes,
      'hintsUsed': hintsUsed,
      'scorePercentage': scorePercentage,
      'accuracy': accuracy,
      'passed': passed,
      'letterGrade': letterGrade,
    };
  }
}

/// Helper class for accumulating topic statistics
class _TopicStats {
  int questionsAttempted = 0;
  int questionsCorrect = 0;
  double totalPoints = 0;
  double pointsEarned = 0;
  Duration totalTime = Duration.zero;
}
