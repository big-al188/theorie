import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_models.dart';
import '../models/quiz_enums.dart';

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
      if (json == null) return QuizStatistics.empty();
      
      final data = jsonDecode(json) as Map<String, dynamic>;
      var stats = QuizStatistics.fromJson(data);
      
      // Filter statistics if needed
      if (sectionId != null || topicId != null) {
        final history = await getQuizHistory(
          sectionId: sectionId,
          topicId: topicId,
        );
        
        // Recalculate statistics based on filtered history
        stats = _calculateStatistics(history);
      }
      
      return stats;
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return QuizStatistics.empty();
    }
  }

  /// Delete quiz from history
  Future<void> deleteFromHistory(String quizId) async {
    await _ensureInitialized();
    
    try {
      final history = await getQuizHistory();
      final updatedHistory = history.where((entry) => entry.quizId != quizId).toList();
      
      final json = jsonEncode(updatedHistory.map((e) => e.toJson()).toList());
      await _prefs.setString(_historyKey, json);
      
      // Recalculate statistics
      final stats = _calculateStatistics(updatedHistory);
      await _prefs.setString(_statsKey, jsonEncode(stats.toJson()));
    } catch (e) {
      debugPrint('Error deleting from history: $e');
      rethrow;
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
      sectionId: quiz.sectionId,
      topicId: quiz.topicId,
      type: quiz.type,
      title: quiz.metadata.title,
      completedAt: quiz.endTime ?? DateTime.now(),
      score: quiz.score,
      questionsAnswered: quiz.answers.length,
      totalQuestions: quiz.questions.length,
      timeSpent: quiz.timeSpent,
      accuracy: quiz.accuracy,
    );
    
    history.insert(0, entry);
    
    // Keep only last 100 entries
    final trimmedHistory = history.take(100).toList();
    
    final json = jsonEncode(trimmedHistory.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, json);
  }

  /// Update statistics
  Future<void> _updateStatistics(Quiz quiz) async {
    final stats = await getStatistics();
    
    // Update statistics based on the completed quiz
    final updatedStats = QuizStatistics(
      totalQuizzes: stats.totalQuizzes + 1,
      totalScore: stats.totalScore + quiz.score,
      totalTimeSpent: stats.totalTimeSpent + quiz.timeSpent,
      averageScore: (stats.totalScore + quiz.score) / (stats.totalQuizzes + 1),
      averageTimePerQuiz: Duration(
        seconds: ((stats.totalTimeSpent.inSeconds + quiz.timeSpent.inSeconds) / 
                  (stats.totalQuizzes + 1)).round(),
      ),
      bestScore: quiz.score > stats.bestScore ? quiz.score : stats.bestScore,
      worstScore: stats.worstScore == 0 || quiz.score < stats.worstScore 
          ? quiz.score 
          : stats.worstScore,
      totalQuestionsAnswered: stats.totalQuestionsAnswered + quiz.answers.length,
      correctAnswers: stats.correctAnswers + 
          quiz.answers.values.where((a) => a.isCorrect).length,
      lastQuizDate: DateTime.now(),
    );
    
    final json = jsonEncode(updatedStats.toJson());
    await _prefs.setString(_statsKey, json);
  }

  /// Update last saved timestamp
  Future<void> _updateLastSaved(String quizId) async {
    final key = 'last_saved_$quizId';
    await _prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// Calculate statistics from history
  QuizStatistics _calculateStatistics(List<QuizHistoryEntry> history) {
    if (history.isEmpty) return QuizStatistics.empty();
    
    double totalScore = 0;
    Duration totalTime = Duration.zero;
    double bestScore = 0;
    double worstScore = 100;
    int totalQuestionsAnswered = 0;
    int correctAnswers = 0;
    
    for (final entry in history) {
      totalScore += entry.score;
      totalTime += entry.timeSpent;
      if (entry.score > bestScore) bestScore = entry.score;
      if (entry.score < worstScore) worstScore = entry.score;
      totalQuestionsAnswered += entry.questionsAnswered;
      correctAnswers += (entry.questionsAnswered * entry.accuracy / 100).round();
    }
    
    return QuizStatistics(
      totalQuizzes: history.length,
      totalScore: totalScore,
      totalTimeSpent: totalTime,
      averageScore: totalScore / history.length,
      averageTimePerQuiz: Duration(
        seconds: (totalTime.inSeconds / history.length).round(),
      ),
      bestScore: bestScore,
      worstScore: worstScore,
      totalQuestionsAnswered: totalQuestionsAnswered,
      correctAnswers: correctAnswers,
      lastQuizDate: history.first.completedAt,
    );
  }
}