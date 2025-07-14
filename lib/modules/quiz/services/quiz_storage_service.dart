import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_models.dart';

/// Service for storing and retrieving quiz data
class QuizStorageService {
  static const String _progressPrefix = 'quiz_progress_';
  static const String _completedPrefix = 'quiz_completed_';
  static const String _historyKey = 'quiz_history';
  static const String _statsKey = 'quiz_stats';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing quiz storage: $e');
      rethrow;
    }
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Save quiz progress
  Future<void> saveQuizProgress(Quiz quiz) async {
    await _ensureInitialized();
    
    try {
      final key = '$_progressPrefix${quiz.id}';
      final json = jsonEncode(quiz.toJson());
      await _prefs.setString(key, json);
      
      // Update last saved timestamp
      await _updateLastSaved(quiz.id);
    } catch (e) {
      debugPrint('Error saving quiz progress: $e');
      rethrow;
    }
  }

  /// Get quiz progress
  Future<Quiz?> getQuizProgress(String quizId) async {
    await _ensureInitialized();
    
    try {
      final key = '$_progressPrefix$quizId';
      final json = _prefs.getString(key);
      
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return Quiz.fromJson(data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting quiz progress: $e');
      return null;
    }
  }

  /// Delete quiz progress
  Future<void> deleteQuizProgress(String quizId) async {
    await _ensureInitialized();
    
    try {
      final key = '$_progressPrefix$quizId';
      await _prefs.remove(key);
    } catch (e) {
      debugPrint('Error deleting quiz progress: $e');
    }
  }

  /// Save completed quiz
  Future<void> saveCompletedQuiz(Quiz quiz) async {
    await _ensureInitialized();
    
    try {
      // Save to history
      await _addToHistory(quiz);
      
      // Update statistics
      await _updateStatistics(quiz);
      
      // Clean up progress if exists
      await deleteQuizProgress(quiz.id);
    } catch (e) {
      debugPrint('Error saving completed quiz: $e');
      rethrow;
    }
  }

  /// Get all paused quizzes
  Future<List<Quiz>> getPausedQuizzes() async {
    await _ensureInitialized();
    
    try {
      final quizzes = <Quiz>[];
      final keys = _prefs.getKeys().where((key) => key.startsWith(_progressPrefix));
      
      for (final key in keys) {
        final json = _prefs.getString(key);
        if (json != null) {
          try {
            final data = jsonDecode(json) as Map<String, dynamic>;
            final quiz = Quiz.fromJson(data);
            if (quiz.status == QuizStatus.paused) {
              quizzes.add(quiz);
            }
          } catch (e) {
            // Skip corrupted data
            debugPrint('Error parsing quiz data for $key: $e');
          }
        }
      }
      
      // Sort by start time (most recent first)
      quizzes.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      return quizzes;
    } catch (e) {
      debugPrint('Error getting paused quizzes: $e');
      return [];
    }
  }

  /// Get quiz history
  Future<List<QuizHistoryEntry>> getQuizHistory({
    String? sectionId,
    String? topicId,
    int? limit,
  }) async {
    await _ensureInitialized();
    
    try {
      final json = _prefs.getString(_historyKey);
      if (json == null) return [];
      
      final data = jsonDecode(json) as List<dynamic>;
      var entries = data
          .map((item) => QuizHistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
      
      // Apply filters
      if (sectionId != null) {
        entries = entries.where((e) => e.sectionId == sectionId).toList();
      }
      if (topicId != null) {
        entries = entries.where((e) => e.topicId == topicId).toList();
      }
      
      // Sort by completion date (most recent first)
      entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      
      // Apply limit
      if (limit != null && entries.length > limit) {
        entries = entries.take(limit).toList();
      }
      
      return entries;
    } catch (e) {
      debugPrint('Error getting quiz history: $e');
      return [];
    }
  }

  /// Get quiz statistics
  Future<QuizStatistics> getStatistics({
    String? sectionId,
    String? topicId,
  }) async {
    await _ensureInitialized();
    
    try {
      final json = _prefs.getString(_statsKey);
      if (json == null) {
        return QuizStatistics.empty();
      }
      
      final data = jsonDecode(json) as Map<String, dynamic>;
      final stats = QuizStatistics.fromJson(data);
      
      // Filter stats if needed
      if (sectionId != null || topicId != null) {
        return await _calculateFilteredStats(sectionId, topicId);
      }
      
      return stats;
    } catch (e) {
      debugPrint('Error getting quiz statistics: $e');
      return QuizStatistics.empty();
    }
  }

  /// Clear all quiz data
  Future<void> clearAllData() async {
    await _ensureInitialized();
    
    try {
      // Get all quiz-related keys
      final keys = _prefs.getKeys().where((key) =>
          key.startsWith(_progressPrefix) ||
          key.startsWith(_completedPrefix) ||
          key == _historyKey ||
          key == _statsKey);
      
      // Remove all keys
      for (final key in keys) {
        await _prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing quiz data: $e');
      rethrow;
    }
  }

  /// Add quiz to history
  Future<void> _addToHistory(Quiz quiz) async {
    final history = await getQuizHistory();
    
    final entry = QuizHistoryEntry(
      quizId: quiz.id,
      quizType: quiz.type,
      sectionId: quiz.sectionId,
      topicId: quiz.topicId,
      score: quiz.score,
      timeSpent: quiz.timeSpent,
      completedAt: quiz.endTime ?? DateTime.now(),
      metadata: quiz.metadata,
    );
    
    history.insert(0, entry);
    
    // Keep only last 100 entries
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    final json = jsonEncode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, json);
  }

  /// Update statistics
  Future<void> _updateStatistics(Quiz quiz) async {
    final stats = await getStatistics();
    final updatedStats = stats.updateWithQuiz(quiz);
    
    final json = jsonEncode(updatedStats.toJson());
    await _prefs.setString(_statsKey, json);
  }

  /// Update last saved timestamp
  Future<void> _updateLastSaved(String quizId) async {
    final key = 'last_saved_$quizId';
    await _prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// Calculate filtered statistics
  Future<QuizStatistics> _calculateFilteredStats(
    String? sectionId,
    String? topicId,
  ) async {
    final history = await getQuizHistory(
      sectionId: sectionId,
      topicId: topicId,
    );
    
    if (history.isEmpty) {
      return QuizStatistics.empty();
    }
    
    // Calculate stats from filtered history
    final totalQuizzes = history.length;
    final totalScore = history.fold(0.0, (sum, entry) => sum + entry.score);
    final totalTime = history.fold(
      Duration.zero,
      (sum, entry) => sum + entry.timeSpent,
    );
    
    return QuizStatistics(
      totalQuizzesTaken: totalQuizzes,
      averageScore: totalScore / totalQuizzes,
      totalTimeSpent: totalTime,
      lastQuizDate: history.first.completedAt,
      topicScores: _calculateTopicScores(history),
    );
  }

  /// Calculate topic scores from history
  Map<String, double> _calculateTopicScores(List<QuizHistoryEntry> history) {
    final topicScores = <String, List<double>>{};
    
    for (final entry in history) {
      if (entry.topicId != null) {
        topicScores.putIfAbsent(entry.topicId!, () => []);
        topicScores[entry.topicId!]!.add(entry.score);
      }
    }
    
    // Calculate averages
    return topicScores.map((topic, scores) {
      final average = scores.fold(0.0, (sum, score) => sum + score) / scores.length;
      return MapEntry(topic, average);
    });
  }
}

/// Entry in quiz history
class QuizHistoryEntry {
  final String quizId;
  final QuizType quizType;
  final String sectionId;
  final String? topicId;
  final double score;
  final Duration timeSpent;
  final DateTime completedAt;
  final QuizMetadata metadata;

  const QuizHistoryEntry({
    required this.quizId,
    required this.quizType,
    required this.sectionId,
    this.topicId,
    required this.score,
    required this.timeSpent,
    required this.completedAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizType': quizType.toString(),
      'sectionId': sectionId,
      'topicId': topicId,
      'score': score,
      'timeSpent': timeSpent.inSeconds,
      'completedAt': completedAt.toIso8601String(),
      'metadata': metadata.toJson(),
    };
  }

  factory QuizHistoryEntry.fromJson(Map<String, dynamic> json) {
    return QuizHistoryEntry(
      quizId: json['quizId'],
      quizType: QuizType.values.firstWhere(
        (t) => t.toString() == json['quizType'],
      ),
      sectionId: json['sectionId'],
      topicId: json['topicId'],
      score: json['score'].toDouble(),
      timeSpent: Duration(seconds: json['timeSpent']),
      completedAt: DateTime.parse(json['completedAt']),
      metadata: QuizMetadata.fromJson(json['metadata']),
    );
  }
}

/// Quiz statistics
class QuizStatistics {
  final int totalQuizzesTaken;
  final double averageScore;
  final Duration totalTimeSpent;
  final DateTime? lastQuizDate;
  final Map<String, double> topicScores;

  const QuizStatistics({
    required this.totalQuizzesTaken,
    required this.averageScore,
    required this.totalTimeSpent,
    this.lastQuizDate,
    required this.topicScores,
  });

  factory QuizStatistics.empty() {
    return const QuizStatistics(
      totalQuizzesTaken: 0,
      averageScore: 0.0,
      totalTimeSpent: Duration.zero,
      topicScores: {},
    );
  }

  QuizStatistics updateWithQuiz(Quiz quiz) {
    final newTotal = totalQuizzesTaken + 1;
    final newAverageScore = ((averageScore * totalQuizzesTaken) + quiz.score) / newTotal;
    final newTotalTime = totalTimeSpent + quiz.timeSpent;
    
    // Update topic scores
    final newTopicScores = Map<String, double>.from(topicScores);
    if (quiz.topicId != null) {
      final currentScore = topicScores[quiz.topicId!] ?? 0.0;
      final currentCount = _getTopicQuizCount(quiz.topicId!);
      newTopicScores[quiz.topicId!] = 
          ((currentScore * currentCount) + quiz.score) / (currentCount + 1);
    }
    
    return QuizStatistics(
      totalQuizzesTaken: newTotal,
      averageScore: newAverageScore,
      totalTimeSpent: newTotalTime,
      lastQuizDate: DateTime.now(),
      topicScores: newTopicScores,
    );
  }

  int _getTopicQuizCount(String topicId) {
    // This is a simplified calculation
    // In a real app, you'd track count per topic
    return totalQuizzesTaken ~/ topicScores.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuizzesTaken': totalQuizzesTaken,
      'averageScore': averageScore,
      'totalTimeSpent': totalTimeSpent.inSeconds,
      'lastQuizDate': lastQuizDate?.toIso8601String(),
      'topicScores': topicScores,
    };
  }

  factory QuizStatistics.fromJson(Map<String, dynamic> json) {
    return QuizStatistics(
      totalQuizzesTaken: json['totalQuizzesTaken'],
      averageScore: json['averageScore'].toDouble(),
      totalTimeSpent: Duration(seconds: json['totalTimeSpent']),
      lastQuizDate: json['lastQuizDate'] != null 
          ? DateTime.parse(json['lastQuizDate'])
          : null,
      topicScores: Map<String, double>.from(json['topicScores']),
    );
  }
}