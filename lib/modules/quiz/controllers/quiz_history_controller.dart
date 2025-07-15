import 'package:flutter/foundation.dart';
import '../models/quiz_models.dart';
import '../models/quiz_enums.dart';
import '../services/quiz_storage_service.dart';
import '../services/quiz_analytics_service.dart';
import 'dart:math' as math;

/// Controller for managing quiz history and statistics
class QuizHistoryController extends ChangeNotifier {
  final QuizStorageService _storageService;
  final QuizAnalyticsService _analyticsService;

  List<QuizHistoryEntry> _history = [];
  QuizStatistics _statistics = QuizStatistics.empty();
  bool _isLoading = false;
  String? _error;

  QuizHistoryController({
    required QuizStorageService storageService,
    required QuizAnalyticsService analyticsService,
  })  : _storageService = storageService,
        _analyticsService = analyticsService;

  // Getters
  List<QuizHistoryEntry> get history => _history;
  QuizStatistics get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _history.isNotEmpty;

  /// Initialize and load history
  Future<void> initialize() async {
    await loadHistory();
  }

  /// Load quiz history
  Future<void> loadHistory({
    String? sectionId,
    String? topicId,
    int? limit,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load history from storage
      _history = await _storageService.getQuizHistory(
        sectionId: sectionId,
        topicId: topicId,
        limit: limit,
      );

      // Load statistics
      _statistics = await _storageService.getStatistics(
        sectionId: sectionId,
        topicId: topicId,
      );

    } catch (e) {
      _error = 'Failed to load quiz history: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get paused quizzes
  List<Quiz> getPausedQuizzes() {
    // This would be loaded from storage
    // For now, returning empty list
    return [];
  }

  /// Get quiz history for a specific topic
  List<QuizHistoryEntry> getTopicHistory(String topicId) {
    return _history.where((entry) => entry.topicId == topicId).toList();
  }

  /// Get quiz history for a specific section
  List<QuizHistoryEntry> getSectionHistory(String sectionId) {
    return _history.where((entry) => entry.sectionId == sectionId).toList();
  }

  /// Get recent quizzes
  List<QuizHistoryEntry> getRecentQuizzes(int count) {
    return _history.take(count).toList();
  }

  /// Get performance trend for a topic
  List<PerformancePoint> getTopicPerformanceTrend(String topicId, {int limit = 10}) {
    final topicHistory = getTopicHistory(topicId);
    
    // Get last N quizzes for the topic
    final recentQuizzes = topicHistory.take(limit).toList();
    
    // Reverse to get chronological order
    return recentQuizzes.reversed.map((entry) {
      return PerformancePoint(
        date: entry.completedAt,
        score: entry.score,
        timeSpent: entry.timeSpent,
      );
    }).toList();
  }

  /// Get overall performance trend
  List<PerformancePoint> getOverallPerformanceTrend({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final recentHistory = _history.where((entry) {
      return entry.completedAt.isAfter(cutoffDate);
    }).toList();

    // Group by date
    final performanceByDate = <DateTime, List<double>>{};
    
    for (final entry in recentHistory) {
      final date = DateTime(
        entry.completedAt.year,
        entry.completedAt.month,
        entry.completedAt.day,
      );
      performanceByDate.putIfAbsent(date, () => []).add(entry.score);
    }

    // Calculate daily averages
    return performanceByDate.entries.map((entry) {
      final avgScore = entry.value.fold(0.0, (sum, score) => sum + score) / entry.value.length;
      return PerformancePoint(
        date: entry.key,
        score: avgScore,
        timeSpent: Duration.zero, // Not calculated for daily averages
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get quiz statistics by type
  Map<QuizType, QuizTypeStats> getStatsByType() {
    final statsByType = <QuizType, QuizTypeStats>{};

    for (final type in QuizType.values) {
      final typeHistory = _history.where((entry) => entry.type == type).toList();
      
      if (typeHistory.isNotEmpty) {
        final totalScore = typeHistory.fold(0.0, (sum, entry) => sum + entry.score);
        final totalTime = typeHistory.fold(
          Duration.zero,
          (sum, entry) => sum + entry.timeSpent,
        );

        statsByType[type] = QuizTypeStats(
          type: type,
          count: typeHistory.length,
          averageScore: totalScore / typeHistory.length,
          totalTime: totalTime,
          lastTaken: typeHistory.first.completedAt,
        );
      }
    }

    return statsByType;
  }

  /// Get weak topics based on performance
  List<WeakTopic> getWeakTopics({double threshold = 70.0}) {
    final topicScores = <String, List<double>>{};
    
    // Group scores by topic
    for (final entry in _history) {
      if (entry.topicId != null) {
        topicScores.putIfAbsent(entry.topicId!, () => []).add(entry.score);
      }
    }

    // Calculate averages and filter weak topics
    final weakTopics = <WeakTopic>[];
    
    topicScores.forEach((topicId, scores) {
      final average = scores.fold(0.0, (sum, score) => sum + score) / scores.length;
      
      if (average < threshold) {
        weakTopics.add(WeakTopic(
          topicId: topicId,
          averageScore: average,
          attemptCount: scores.length,
          lastAttempt: _history
              .firstWhere((e) => e.topicId == topicId)
              .completedAt,
        ));
      }
    });

    // Sort by average score (lowest first)
    weakTopics.sort((a, b) => a.averageScore.compareTo(b.averageScore));
    
    return weakTopics;
  }

  /// Get strong topics based on performance
  List<StrongTopic> getStrongTopics({double threshold = 85.0, int minAttempts = 3}) {
    final topicScores = <String, List<double>>{};
    
    // Group scores by topic
    for (final entry in _history) {
      if (entry.topicId != null) {
        topicScores.putIfAbsent(entry.topicId!, () => []).add(entry.score);
      }
    }

    // Calculate averages and filter strong topics
    final strongTopics = <StrongTopic>[];
    
    topicScores.forEach((topicId, scores) {
      if (scores.length >= minAttempts) {
        final average = scores.fold(0.0, (sum, score) => sum + score) / scores.length;
        
        if (average >= threshold) {
          strongTopics.add(StrongTopic(
            topicId: topicId,
            averageScore: average,
            attemptCount: scores.length,
            consistency: _calculateConsistency(scores),
          ));
        }
      }
    });

    // Sort by average score (highest first)
    strongTopics.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    
    return strongTopics;
  }

  /// Calculate consistency score (lower is better)
  double _calculateConsistency(List<double> scores) {
    if (scores.length < 2) return 0.0;
    
    final mean = scores.fold(0.0, (sum, score) => sum + score) / scores.length;
    final variance = scores.fold(0.0, (sum, score) {
      return sum + (score - mean) * (score - mean);
    }) / scores.length;
    
    return math.sqrt(variance);
  }

  /// Get learning insights
  List<LearningInsight> getLearningInsights() {
    return _analyticsService.getLearningInsights(
      userId: 'current_user', // In a real app, get actual user ID
      limit: 5,
    );
  }

  /// Get streak information
  StreakInfo getStreakInfo() {
    return _analyticsService.getStreakInfo();
  }

  /// Delete a specific quiz from history
  Future<void> deleteQuizFromHistory(String quizId) async {
    try {
      // Remove from local list
      _history.removeWhere((entry) => entry.quizId == quizId);
      
      // Update storage (would need to implement this method)
      // await _storageService.deleteFromHistory(quizId);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete quiz: $e';
      notifyListeners();
    }
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _storageService.clearAllData();
      _analyticsService.clearData();
      
      _history = [];
      _statistics = QuizStatistics.empty();
      _error = null;
    } catch (e) {
      _error = 'Failed to clear history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadHistory();
  }
}

// Supporting classes

class PerformancePoint {
  final DateTime date;
  final double score;
  final Duration timeSpent;

  PerformancePoint({
    required this.date,
    required this.score,
    required this.timeSpent,
  });
}

class QuizTypeStats {
  final QuizType type;
  final int count;
  final double averageScore;
  final Duration totalTime;
  final DateTime lastTaken;

  QuizTypeStats({
    required this.type,
    required this.count,
    required this.averageScore,
    required this.totalTime,
    required this.lastTaken,
  });

  Duration get averageTime => Duration(
    seconds: count > 0 ? totalTime.inSeconds ~/ count : 0,
  );
}

class WeakTopic {
  final String topicId;
  final double averageScore;
  final int attemptCount;
  final DateTime lastAttempt;

  WeakTopic({
    required this.topicId,
    required this.averageScore,
    required this.attemptCount,
    required this.lastAttempt,
  });
}

class StrongTopic {
  final String topicId;
  final double averageScore;
  final int attemptCount;
  final double consistency;

  StrongTopic({
    required this.topicId,
    required this.averageScore,
    required this.attemptCount,
    required this.consistency,
  });
}