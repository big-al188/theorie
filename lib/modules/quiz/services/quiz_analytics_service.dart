import 'package:flutter/foundation.dart';
import '../models/quiz_models.dart';
import '../models/question_models.dart';

/// Service for tracking quiz analytics and performance metrics
class QuizAnalyticsService {
  final Map<String, List<AnalyticsEvent>> _events = {};
  final Map<String, QuestionMetrics> _questionMetrics = {};
  final Map<String, TopicPerformance> _topicPerformance = {};

  /// Track quiz started event
  void trackQuizStarted(Quiz quiz) {
    _logEvent(AnalyticsEvent(
      type: EventType.quizStarted,
      timestamp: DateTime.now(),
      data: {
        'quizId': quiz.id,
        'quizType': quiz.type.toString(),
        'sectionId': quiz.sectionId,
        'topicId': quiz.topicId,
        'questionCount': quiz.questions.length,
        'estimatedMinutes': quiz.metadata.estimatedMinutes,
      },
    ));
  }

  /// Track question answered event
  void trackQuestionAnswered({
    required Quiz quiz,
    required Question question,
    required Answer answer,
  }) {
    // Log event
    _logEvent(AnalyticsEvent(
      type: EventType.questionAnswered,
      timestamp: answer.timestamp,
      data: {
        'quizId': quiz.id,
        'questionId': question.id,
        'questionType': question.type.toString(),
        'isCorrect': answer.isCorrect,
        'earnedPoints': answer.earnedPoints,
        'timeToAnswer': _calculateTimeToAnswer(quiz, question, answer),
      },
    ));

    // Update question metrics
    _updateQuestionMetrics(question, answer);
    
    // Update topic performance
    _updateTopicPerformance(question.topicId, answer.isCorrect);
  }

  /// Track quiz completed event
  void trackQuizCompleted(Quiz quiz, QuizResult result) {
    _logEvent(AnalyticsEvent(
      type: EventType.quizCompleted,
      timestamp: DateTime.now(),
      data: {
        'quizId': quiz.id,
        'score': result.score,
        'timeSpent': result.timeSpent.inSeconds,
        'questionsAnswered': result.answers.length,
        'correctAnswers': result.answers.values.where((a) => a.isCorrect).length,
        'strengths': result.strengths,
        'areasForImprovement': result.areasForImprovement,
      },
    ));
  }

  /// Track quiz paused event
  void trackQuizPaused(Quiz quiz) {
    _logEvent(AnalyticsEvent(
      type: EventType.quizPaused,
      timestamp: DateTime.now(),
      data: {
        'quizId': quiz.id,
        'progress': quiz.progress,
        'questionsAnswered': quiz.answers.length,
        'currentScore': quiz.score,
      },
    ));
  }

  /// Track quiz abandoned event
  void trackQuizAbandoned(Quiz quiz) {
    _logEvent(AnalyticsEvent(
      type: EventType.quizAbandoned,
      timestamp: DateTime.now(),
      data: {
        'quizId': quiz.id,
        'progress': quiz.progress,
        'questionsAnswered': quiz.answers.length,
        'timeSpent': quiz.timeSpent.inSeconds,
      },
    ));
  }

  /// Get performance analytics for a specific topic
  TopicPerformance? getTopicPerformance(String topicId) {
    return _topicPerformance[topicId];
  }

  /// Get metrics for a specific question
  QuestionMetrics? getQuestionMetrics(String questionId) {
    return _questionMetrics[questionId];
  }

  /// Get overall analytics summary
  AnalyticsSummary getAnalyticsSummary({
    String? sectionId,
    String? topicId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredEvents = _filterEvents(
      sectionId: sectionId,
      topicId: topicId,
      startDate: startDate,
      endDate: endDate,
    );

    return _calculateSummary(filteredEvents);
  }

  /// Get learning insights based on performance
  List<LearningInsight> getLearningInsights({
    required String userId,
    int limit = 5,
  }) {
    final insights = <LearningInsight>[];

    // Analyze topic performance
    _topicPerformance.forEach((topicId, performance) {
      if (performance.accuracy < 0.6) {
        insights.add(LearningInsight(
          type: InsightType.needsImprovement,
          topicId: topicId,
          message: 'You might want to review $topicId. Your accuracy is ${(performance.accuracy * 100).toInt()}%.',
          priority: InsightPriority.high,
          suggestedAction: 'Review topic materials and take a practice quiz',
        ));
      } else if (performance.accuracy > 0.9 && performance.totalAttempts > 10) {
        insights.add(LearningInsight(
          type: InsightType.mastery,
          topicId: topicId,
          message: 'Great job! You\'ve mastered $topicId with ${(performance.accuracy * 100).toInt()}% accuracy.',
          priority: InsightPriority.low,
          suggestedAction: 'Move on to more advanced topics',
        ));
      }
    });

    // Analyze question patterns
    _questionMetrics.forEach((questionId, metrics) {
      if (metrics.averageTimeToAnswer > 120 && metrics.correctRate < 0.5) {
        insights.add(LearningInsight(
          type: InsightType.difficulty,
          message: 'Question $questionId seems challenging. Consider breaking it down into smaller concepts.',
          priority: InsightPriority.medium,
          suggestedAction: 'Practice related concepts separately',
        ));
      }
    });

    // Sort by priority and limit
    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return insights.take(limit).toList();
  }

  /// Get streak information
  StreakInfo getStreakInfo() {
    final completedQuizzes = _events.values
        .expand((events) => events)
        .where((e) => e.type == EventType.quizCompleted)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (completedQuizzes.isEmpty) {
      return StreakInfo(currentStreak: 0, longestStreak: 0);
    }

    // Calculate current streak
    int currentStreak = 0;
    DateTime? lastDate;
    
    for (final event in completedQuizzes) {
      final eventDate = DateTime(
        event.timestamp.year,
        event.timestamp.month,
        event.timestamp.day,
      );

      if (lastDate == null) {
        currentStreak = 1;
        lastDate = eventDate;
      } else {
        final dayDifference = lastDate.difference(eventDate).inDays;
        if (dayDifference == 1) {
          currentStreak++;
          lastDate = eventDate;
        } else if (dayDifference > 1) {
          break;
        }
      }
    }

    // Check if streak is still active (last quiz was today or yesterday)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (lastDate != null) {
      final daysSinceLastQuiz = todayDate.difference(lastDate).inDays;
      if (daysSinceLastQuiz > 1) {
        currentStreak = 0;
      }
    }

    // TODO: Calculate longest streak
    return StreakInfo(
      currentStreak: currentStreak,
      longestStreak: currentStreak, // Simplified for now
    );
  }

  /// Clear all analytics data
  void clearData() {
    _events.clear();
    _questionMetrics.clear();
    _topicPerformance.clear();
  }

  // Private helper methods

  void _logEvent(AnalyticsEvent event) {
    final key = '${event.type}_${DateTime.now().millisecondsSinceEpoch}';
    _events.putIfAbsent(key, () => []).add(event);
    
    // Keep only last 1000 events per type
    if (_events[key]!.length > 1000) {
      _events[key]!.removeRange(0, _events[key]!.length - 1000);
    }
  }

  void _updateQuestionMetrics(Question question, Answer answer) {
    final metrics = _questionMetrics[question.id] ?? QuestionMetrics(
      questionId: question.id,
      totalAttempts: 0,
      correctAttempts: 0,
      totalTimeSpent: 0,
    );

    _questionMetrics[question.id] = QuestionMetrics(
      questionId: question.id,
      totalAttempts: metrics.totalAttempts + 1,
      correctAttempts: metrics.correctAttempts + (answer.isCorrect ? 1 : 0),
      totalTimeSpent: metrics.totalTimeSpent + 30, // Simplified time calculation
    );
  }

  void _updateTopicPerformance(String topicId, bool isCorrect) {
    final performance = _topicPerformance[topicId] ?? TopicPerformance(
      topicId: topicId,
      totalAttempts: 0,
      correctAttempts: 0,
      lastAttemptDate: DateTime.now(),
    );

    _topicPerformance[topicId] = TopicPerformance(
      topicId: topicId,
      totalAttempts: performance.totalAttempts + 1,
      correctAttempts: performance.correctAttempts + (isCorrect ? 1 : 0),
      lastAttemptDate: DateTime.now(),
    );
  }

  int _calculateTimeToAnswer(Quiz quiz, Question question, Answer answer) {
    // Simplified calculation - in a real app, you'd track actual time per question
    final avgTimePerQuestion = quiz.timeSpent.inSeconds / quiz.questions.length;
    return avgTimePerQuestion.round();
  }

  List<AnalyticsEvent> _filterEvents({
    String? sectionId,
    String? topicId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _events.values
        .expand((events) => events)
        .where((event) {
          if (startDate != null && event.timestamp.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && event.timestamp.isAfter(endDate)) {
            return false;
          }
          if (sectionId != null && event.data['sectionId'] != sectionId) {
            return false;
          }
          if (topicId != null && event.data['topicId'] != topicId) {
            return false;
          }
          return true;
        })
        .toList();
  }

  AnalyticsSummary _calculateSummary(List<AnalyticsEvent> events) {
    final completedQuizzes = events.where((e) => e.type == EventType.quizCompleted).length;
    final totalQuestions = events.where((e) => e.type == EventType.questionAnswered).length;
    final correctAnswers = events
        .where((e) => e.type == EventType.questionAnswered && e.data['isCorrect'] == true)
        .length;

    return AnalyticsSummary(
      totalQuizzes: completedQuizzes,
      totalQuestions: totalQuestions,
      averageScore: totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0,
      totalTimeSpent: Duration(
        seconds: events
            .where((e) => e.type == EventType.quizCompleted)
            .fold(0, (sum, e) => sum + (e.data['timeSpent'] as int)),
      ),
    );
  }
}

// Supporting classes

enum EventType {
  quizStarted,
  questionAnswered,
  quizCompleted,
  quizPaused,
  quizAbandoned,
}

class AnalyticsEvent {
  final EventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  AnalyticsEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class QuestionMetrics {
  final String questionId;
  final int totalAttempts;
  final int correctAttempts;
  final int totalTimeSpent;

  QuestionMetrics({
    required this.questionId,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.totalTimeSpent,
  });

  double get correctRate => totalAttempts > 0 ? correctAttempts / totalAttempts : 0;
  double get averageTimeToAnswer => totalAttempts > 0 ? totalTimeSpent / totalAttempts : 0;
}

class TopicPerformance {
  final String topicId;
  final int totalAttempts;
  final int correctAttempts;
  final DateTime lastAttemptDate;

  TopicPerformance({
    required this.topicId,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.lastAttemptDate,
  });

  double get accuracy => totalAttempts > 0 ? correctAttempts / totalAttempts : 0;
}

class AnalyticsSummary {
  final int totalQuizzes;
  final int totalQuestions;
  final double averageScore;
  final Duration totalTimeSpent;

  AnalyticsSummary({
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.averageScore,
    required this.totalTimeSpent,
  });
}

enum InsightType {
  needsImprovement,
  mastery,
  difficulty,
  recommendation,
}

enum InsightPriority {
  low,
  medium,
  high,
}

class LearningInsight {
  final InsightType type;
  final String? topicId;
  final String message;
  final InsightPriority priority;
  final String suggestedAction;

  LearningInsight({
    required this.type,
    this.topicId,
    required this.message,
    required this.priority,
    required this.suggestedAction,
  });
}

class StreakInfo {
  final int currentStreak;
  final int longestStreak;

  StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
  });
}