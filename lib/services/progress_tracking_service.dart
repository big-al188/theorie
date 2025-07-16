// lib/services/progress_tracking_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user.dart';
import '../models/quiz/quiz_result.dart';
import '../models/quiz/quiz_session.dart'; // Added: Import for QuizType
import '../models/learning/learning_content.dart';
import 'user_service.dart';

/// Service responsible for tracking and updating user learning progress
///
/// This service handles:
/// - Topic completion tracking when quizzes are finished
/// - Section progress calculations and updates
/// - Section quiz auto-completion of all topics
/// - Progress persistence through UserService
/// - Real-time progress notifications
/// - ENHANCED: Offline-first storage with background Firebase sync
/// - ENHANCED: PWA support with persistent local storage
/// - ENHANCED: Comprehensive debug logging
/// - FIXED: Proper existing progress checking to prevent data loss
class ProgressTrackingService extends ChangeNotifier {
  static final ProgressTrackingService _instance =
      ProgressTrackingService._internal();
  static ProgressTrackingService get instance => _instance;

  ProgressTrackingService._internal();

  // ADDED: Offline storage components
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _syncTimer;
  final Duration _syncInterval = const Duration(minutes: 2);

  // ADDED: Local storage keys
  static const String _progressKey = 'offline_progress';
  static const String _pendingSyncKey = 'pending_sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // ADDED: Cache and sync queue
  UserProgress? _cachedProgress;
  final List<Map<String, dynamic>> _pendingSyncQueue = [];

  /// ADDED: Initialize offline storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadLocalProgress();
      await _loadPendingSyncQueue();
      _startPeriodicSync();
      _isInitialized = true;

      debugPrint('🏠 [ProgressTracker] Service initialized successfully');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Failed to initialize: $e');
      _isInitialized = true; // Prevent infinite retry
    }
  }

  /// Records topic quiz completion and updates progress
  ///
  /// ENHANCED: Now with offline-first storage for instant UI feedback
  /// This method:
  /// 1. Stores progress locally immediately for instant UI updates
  /// 2. Determines if the quiz was passed based on score
  /// 3. Updates topic completion status locally and remotely
  /// 4. Recalculates section progress
  /// 5. Queues for Firebase sync when user is available
  /// 6. Notifies listeners of progress changes
  Future<void> recordQuizCompletion({
    required QuizResult result,
    required String topicId,
    String? sectionId,
    double passingScore = 0.7,
  }) async {
    await initialize(); // Ensure initialized

    try {
      final passed = result.scorePercentage >= passingScore;
      final timestamp = DateTime.now();

      debugPrint(
          '📝 [ProgressTracker] Recording topic quiz: $topicId (${passed ? "PASSED" : "FAILED"})');

      // STEP 1: Store locally immediately for instant UI feedback
      await _storeLocalProgress(
        type: 'topic_quiz',
        data: {
          'topicId': topicId,
          'sectionId': sectionId,
          'passed': passed,
          'score': result.scorePercentage,
          'timestamp': timestamp.toIso8601String(),
          'result': result.toJson(),
        },
      );

      // STEP 2: Add to sync queue for Firebase sync
      await _addToSyncQueue({
        'type': 'topic_quiz',
        'topicId': topicId,
        'sectionId': sectionId,
        'passed': passed,
        'score': result.scorePercentage,
        'timestamp': timestamp.toIso8601String(),
        'result': result.toJson(),
      });

      // STEP 3: Notify UI immediately
      notifyListeners();

      // STEP 4: Try immediate sync (non-blocking)
      _attemptImmediateSync();

      debugPrint(
          '✅ [ProgressTracker] Topic quiz recorded locally and queued for sync');
      debugPrint(
          'Progress updated: Topic $topicId - ${passed ? "PASSED" : "FAILED"} (${(result.scorePercentage * 100).round()}%)');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error recording quiz completion: $e');

      // FALLBACK: Try original method if offline approach fails
      try {
        await _recordQuizCompletionFallback(
          result: result,
          topicId: topicId,
          sectionId: sectionId,
          passingScore: passingScore,
        );
      } catch (fallbackError) {
        debugPrint('❌ [ProgressTracker] Fallback also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// Records section quiz completion and auto-completes all topics
  ///
  /// ENHANCED: Now with offline-first storage
  /// When a user passes a section quiz, this method:
  /// 1. Stores progress locally immediately
  /// 2. Marks the section quiz as completed
  /// 3. Automatically marks ALL topics in the section as completed
  /// 4. Updates section progress to reflect full completion
  /// 5. Queues for Firebase sync
  /// 6. Notifies listeners for real-time UI updates
  Future<void> recordSectionQuizCompletion({
    required QuizResult result,
    required String sectionId,
    double passingScore = 0.7,
  }) async {
    await initialize(); // Ensure initialized

    try {
      final passed = result.scorePercentage >= passingScore;
      final timestamp = DateTime.now();

      debugPrint(
          '📝 [ProgressTracker] Recording section quiz: $sectionId (${passed ? "PASSED" : "FAILED"})');

      // Get section to auto-complete topics if passed
      final section = _findSectionById(sectionId);
      if (section == null) {
        debugPrint('⚠️ [ProgressTracker] Section not found: $sectionId');
        return;
      }

      // STEP 1: Store locally immediately
      await _storeLocalProgress(
        type: 'section_quiz',
        data: {
          'sectionId': sectionId,
          'passed': passed,
          'score': result.scorePercentage,
          'timestamp': timestamp.toIso8601String(),
          'result': result.toJson(),
          'autoCompleteTopics':
              passed ? section.topics.map((t) => t.id).toList() : [],
        },
      );

      // STEP 2: Add to sync queue
      await _addToSyncQueue({
        'type': 'section_quiz',
        'sectionId': sectionId,
        'passed': passed,
        'score': result.scorePercentage,
        'timestamp': timestamp.toIso8601String(),
        'result': result.toJson(),
        'autoCompleteTopics':
            passed ? section.topics.map((t) => t.id).toList() : [],
      });

      // STEP 3: If section passed, auto-complete all topics locally
      if (passed) {
        for (final topic in section.topics) {
          await _storeLocalProgress(
            type: 'topic_completion',
            data: {
              'topicId': topic.id,
              'sectionId': sectionId,
              'passed': true,
              'autoCompleted': true,
              'timestamp': timestamp.toIso8601String(),
            },
          );
        }
        debugPrint(
            '✨ [ProgressTracker] Auto-completed ${section.topics.length} topics for section: $sectionId');
      }

      // STEP 4: Notify UI and attempt sync
      notifyListeners();
      _attemptImmediateSync();

      debugPrint(
          '✅ [ProgressTracker] Section quiz recorded locally and queued for sync');
      debugPrint(
          'Section quiz completed: $sectionId - ${passed ? "PASSED" : "FAILED"} (${(result.scorePercentage * 100).round()}%)');
    } catch (e) {
      debugPrint(
          '❌ [ProgressTracker] Error recording section quiz completion: $e');

      // FALLBACK: Try original method
      try {
        await _recordSectionQuizCompletionFallback(
          result: result,
          sectionId: sectionId,
          passingScore: passingScore,
        );
      } catch (fallbackError) {
        debugPrint('❌ [ProgressTracker] Fallback also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// CRITICAL FIX: Initialize section progress data for current user
  /// Now properly checks for existing progress before initialization
  Future<void> initializeSectionProgress() async {
    await initialize(); // Ensure initialized

    try {
      // Try to get current user safely
      final currentUser = await _getCurrentUserSafely();
      if (currentUser == null) {
        debugPrint('⏳ [ProgressTracker] Initialize skipped - no current user');
        return;
      }

      debugPrint(
          '👤 [ProgressTracker] Initializing progress for user: ${currentUser.username}');

      // CRITICAL FIX: Check for existing progress first (offline-first approach)
      var currentProgress = await getCurrentProgress();

      // If we have existing section progress, skip initialization
      if (currentProgress.sectionProgress.isNotEmpty) {
        debugPrint('✅ [ProgressTracker] Section progress already initialized');
        return;
      }

      debugPrint(
          '🔧 [ProgressTracker] No existing progress found, initializing sections...');

      final sections = LearningContentRepository.getAllSections();
      bool hasUpdates = false;

      // Only initialize sections that don't have progress data
      for (final section in sections) {
        if (!currentProgress.sectionProgress.containsKey(section.id)) {
          final newSectionProgress = Map<String, SectionProgress>.from(
              currentProgress.sectionProgress);

          // Count already completed topics for this section
          int completedTopics = 0;
          for (final topic in section.topics) {
            if (currentProgress.completedTopics.contains(topic.id)) {
              completedTopics++;
            }
          }

          newSectionProgress[section.id] = SectionProgress(
            topicsCompleted: completedTopics,
            totalTopics: section.totalTopics,
            sectionQuizCompleted:
                currentProgress.completedSections.contains(section.id),
          );

          currentProgress = UserProgress(
            sectionProgress: newSectionProgress,
            completedTopics: currentProgress.completedTopics,
            completedSections: currentProgress.completedSections,
            totalQuizzesTaken: currentProgress.totalQuizzesTaken,
            totalQuizzesPassed: currentProgress.totalQuizzesPassed,
          );

          hasUpdates = true;
        }
      }

      // Save if there were any updates
      if (hasUpdates) {
        // Save to local storage first, then update UserService
        await _saveLocalProgress(currentProgress);
        await UserService.instance.updateUserProgress(currentProgress);
        notifyListeners();
        debugPrint(
            '💾 [ProgressTracker] Section progress initialized and saved');
      } else {
        debugPrint('✅ [ProgressTracker] Section progress already initialized');
      }
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error initializing section progress: $e');
    }
  }

  /// ADDED: Get current progress (offline-first)
  /// ENHANCED: Always prioritize local storage over remote to prevent progress loss
  Future<UserProgress> getCurrentProgress() async {
    await initialize();

    try {
      // ALWAYS check local storage first for the most recent progress
      final localProgress = await _loadLocalProgress();
      if (localProgress != null) {
        debugPrint('📱 [ProgressTracker] Loaded progress from local storage');
        _cachedProgress = localProgress;

        // ENHANCED: Sync local progress to UserService for UI consistency
        try {
          await UserService.instance.updateUserProgress(localProgress);
          debugPrint(
              '✅ [ProgressTracker] Synced local progress to UserService');
        } catch (e) {
          debugPrint(
              '⚠️ [ProgressTracker] Could not sync local progress to UserService: $e');
        }

        return localProgress;
      }

      debugPrint(
          '📱 [ProgressTracker] No local progress found, checking remote...');

      // Only fallback to remote if local is completely empty
      final user = await _getCurrentUserSafely();
      if (user != null) {
        debugPrint(
            '☁️ [ProgressTracker] Loading progress from remote user data');
        final remoteProgress = user.progress;

        // Cache the remote progress locally for next time
        if (remoteProgress.completedTopics.isNotEmpty ||
            remoteProgress.sectionProgress.isNotEmpty) {
          await _prefs!
              .setString(_progressKey, jsonEncode(remoteProgress.toJson()));
          _cachedProgress = remoteProgress;
          debugPrint('💾 [ProgressTracker] Cached remote progress locally');
        }

        // ENHANCED: Also update UserService with the latest progress for UI consistency
        try {
          await UserService.instance.updateUserProgress(remoteProgress);
          debugPrint('✅ [ProgressTracker] Synced progress to UserService');
        } catch (e) {
          debugPrint(
              '⚠️ [ProgressTracker] Could not sync progress to UserService: $e');
        }

        return remoteProgress;
      }

      // Final fallback - empty progress
      debugPrint('🆕 [ProgressTracker] Creating new empty progress');
      return UserProgress.empty();
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error loading progress: $e');

      // If there's an error, try to return cached progress
      if (_cachedProgress != null) {
        debugPrint(
            '🔄 [ProgressTracker] Returning cached progress due to error');
        return _cachedProgress!;
      }

      return UserProgress.empty();
    }
  }

  /// Save progress to local storage
  Future<void> _saveLocalProgress(UserProgress progress) async {
    try {
      await _prefs?.setString(_progressKey, jsonEncode(progress.toJson()));
      _cachedProgress = progress;
      debugPrint('💾 [ProgressTracker] Progress saved to local storage');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error saving local progress: $e');
    }
  }

  /// ADDED: Check if topic is completed (offline-first)
  Future<bool> isTopicCompleted(String topicId) async {
    final progress = await getCurrentProgress();
    return progress.completedTopics.contains(topicId);
  }

  /// ADDED: Check if section is completed (offline-first)
  Future<bool> isSectionCompleted(String sectionId) async {
    final progress = await getCurrentProgress();
    return progress.completedSections.contains(sectionId);
  }

  /// ADDED: Get section progress (offline-first)
  Future<SectionProgress?> getSectionProgress(String sectionId) async {
    final progress = await getCurrentProgress();
    return progress.sectionProgress[sectionId];
  }

  /// ADDED: Force sync to Firebase
  Future<bool> forceSyncToFirebase() async {
    await initialize();

    debugPrint('🔄 [ProgressTracker] Force sync to Firebase started...');

    try {
      final success = await _syncToFirebase();
      if (success) {
        debugPrint('✅ [ProgressTracker] Force sync completed successfully');
      } else {
        debugPrint(
            '⚠️ [ProgressTracker] Force sync failed (user not available)');
      }
      return success;
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Force sync error: $e');
      return false;
    }
  }

  /// ADDED: Force sync when user becomes available (called from AppState)
  Future<void> onUserAuthenticated() async {
    await initialize();

    debugPrint(
        '🔄 [ProgressTracker] User authenticated - attempting immediate sync...');

    if (_pendingSyncQueue.isNotEmpty) {
      debugPrint(
          '📤 [ProgressTracker] Found ${_pendingSyncQueue.length} pending items to sync');

      // Try immediate sync
      final success = await _syncToFirebase();
      if (success) {
        debugPrint('🚀 [ProgressTracker] User authentication sync successful');
      } else {
        debugPrint(
            '⚠️ [ProgressTracker] User authentication sync failed - will retry later');
      }
    } else {
      debugPrint('✅ [ProgressTracker] No pending items to sync');
    }
  }

  /// ADDED: Manual sync trigger for debugging/testing
  Future<Map<String, dynamic>> manualSyncDebug() async {
    await initialize();

    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'pendingItems': _pendingSyncQueue.length,
      'userFound': false,
      'userDetails': null,
      'syncAttempted': false,
      'syncSuccess': false,
      'errors': <String>[],
    };

    try {
      // Try to get user with full debugging
      debugPrint('🔧 [ProgressTracker] Manual sync debug started...');

      final user = await _getCurrentUserSafely();
      result['userFound'] = user != null;

      if (user != null) {
        result['userDetails'] = {
          'username': user.username,
          'isDefaultUser': user.isDefaultUser,
          'id': user.id,
        };

        if (!user.isDefaultUser && _pendingSyncQueue.isNotEmpty) {
          debugPrint('🔧 [ProgressTracker] Attempting manual sync...');
          result['syncAttempted'] = true;

          final success = await _syncToFirebase();
          result['syncSuccess'] = success;

          debugPrint('🔧 [ProgressTracker] Manual sync result: $success');
        } else {
          if (user.isDefaultUser) {
            result['errors'].add('User is guest - no sync needed');
          }
          if (_pendingSyncQueue.isEmpty) {
            result['errors'].add('No pending items to sync');
          }
        }
      } else {
        result['errors'].add('No authenticated user found');
      }
    } catch (e) {
      result['errors'].add('Exception: $e');
      debugPrint('❌ [ProgressTracker] Manual sync debug error: $e');
    }

    debugPrint('🔧 [ProgressTracker] Manual sync debug result: $result');
    return result;
  }

  /// ADDED: Get detailed sync status for debugging
  Map<String, dynamic> getDetailedSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'pendingSync': _pendingSyncQueue.length,
      'pendingItems': _pendingSyncQueue
          .map((item) => {
                'type': item['type'],
                'timestamp': item['timestamp'],
                'topicId': item['topicId'],
                'sectionId': item['sectionId'],
              })
          .toList(),
      'lastSync': _prefs?.getString(_lastSyncKey),
      'cachedProgress': _cachedProgress != null,
      'syncInterval': _syncInterval.inMinutes,
    };
  }

  /// ADDED: Get sync status for debugging (legacy compatibility)
  Map<String, dynamic> getSyncStatus() {
    return getDetailedSyncStatus();
  }

  /// Forces a refresh of progress data from storage
  Future<void> refreshProgress() async {
    try {
      await initializeSectionProgress();
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error refreshing progress: $e');
    }
  }

  // ===== EXISTING METHODS (maintained for compatibility) =====

  /// Gets current progress for a specific section
  Future<SectionProgress> getSectionProgressAsync(String sectionId) async {
    try {
      final currentUser = await _getCurrentUserSafely();
      if (currentUser == null) {
        return _getDefaultSectionProgress(sectionId);
      }

      return currentUser.progress.getSectionProgress(sectionId);
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error getting section progress: $e');
      return _getDefaultSectionProgress(sectionId);
    }
  }

  /// Get default section progress (used for fallback)
  SectionProgress _getDefaultSectionProgress(String sectionId) {
    final section = _findSectionById(sectionId);
    return SectionProgress(
      topicsCompleted: 0,
      totalTopics: section?.totalTopics ?? 0,
      sectionQuizCompleted: false,
    );
  }

  // ===== PRIVATE OFFLINE STORAGE METHODS =====

  /// Store progress locally with immediate effect
  Future<void> _storeLocalProgress({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Load current local progress
      UserProgress currentProgress =
          await _loadLocalProgress() ?? UserProgress.empty();

      // Apply the progress update based on type
      switch (type) {
        case 'topic_quiz':
        case 'topic_completion':
          final topicId = data['topicId'] as String;
          final passed = data['passed'] as bool;
          final sectionId = data['sectionId'] as String?;

          currentProgress = _updateTopicInProgress(
              currentProgress, topicId, passed, sectionId);
          break;

        case 'section_quiz':
          final sectionId = data['sectionId'] as String;
          final passed = data['passed'] as bool;
          final autoCompleteTopics =
              data['autoCompleteTopics'] as List<dynamic>?;

          currentProgress =
              _updateSectionInProgress(currentProgress, sectionId, passed);

          // Auto-complete topics if section passed
          if (passed && autoCompleteTopics != null) {
            for (final topicId in autoCompleteTopics) {
              currentProgress = _updateTopicInProgress(
                  currentProgress, topicId as String, true, sectionId);
            }
          }
          break;
      }

      // Save to local storage
      await _prefs!
          .setString(_progressKey, jsonEncode(currentProgress.toJson()));
      _cachedProgress = currentProgress;

      debugPrint('💾 [ProgressTracker] Stored $type locally');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error storing local progress: $e');
      rethrow;
    }
  }

  /// Load progress from local storage
  Future<UserProgress?> _loadLocalProgress() async {
    try {
      final progressJson = _prefs?.getString(_progressKey);
      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        final progress = UserProgress.fromJson(progressData);
        _cachedProgress = progress;
        return progress;
      }
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error loading local progress: $e');
    }
    return null;
  }

  /// Add item to sync queue
  Future<void> _addToSyncQueue(Map<String, dynamic> item) async {
    try {
      _pendingSyncQueue.add(item);
      await _prefs!.setString(_pendingSyncKey, jsonEncode(_pendingSyncQueue));
      debugPrint(
          '📤 [ProgressTracker] Added to sync queue (${_pendingSyncQueue.length} pending)');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error adding to sync queue: $e');
    }
  }

  /// Load pending sync queue from storage
  Future<void> _loadPendingSyncQueue() async {
    try {
      final queueJson = _prefs?.getString(_pendingSyncKey);
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List<dynamic>;
        _pendingSyncQueue.clear();
        _pendingSyncQueue.addAll(queueData.cast<Map<String, dynamic>>());
        debugPrint(
            '📥 [ProgressTracker] Loaded ${_pendingSyncQueue.length} items from sync queue');
      } else {
        debugPrint('📥 [ProgressTracker] Loaded 0 items from sync queue');
      }
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error loading sync queue: $e');
    }
  }

  /// Start periodic sync timer
  /// ENHANCED: More frequent sync when there are pending items
  void _startPeriodicSync() {
    _syncTimer?.cancel();

    // Use shorter interval if there are pending items
    final interval = _pendingSyncQueue.isNotEmpty
        ? const Duration(seconds: 30) // More frequent when items are pending
        : _syncInterval; // Normal 2-minute interval when queue is empty

    _syncTimer = Timer.periodic(interval, (_) {
      _attemptImmediateSync();

      // Adjust timer if queue state changed
      final shouldBeFrequent = _pendingSyncQueue.isNotEmpty;
      final isFrequent = interval.inSeconds < 60;

      if (shouldBeFrequent != isFrequent) {
        debugPrint('🔄 [ProgressTracker] Adjusting sync frequency...');
        _startPeriodicSync(); // Restart with appropriate interval
      }
    });

    debugPrint(
        '⏱️ [ProgressTracker] Periodic sync started (every ${interval.inSeconds} seconds)');
  }

  /// Attempt immediate sync (non-blocking)
  void _attemptImmediateSync() {
    if (_pendingSyncQueue.isEmpty) return;

    // Run sync in background without blocking UI
    _syncToFirebase().then((success) {
      if (success) {
        debugPrint('🚀 [ProgressTracker] Background sync successful');
      }
    }).catchError((e) {
      debugPrint('⚠️ [ProgressTracker] Background sync failed: $e');
    });
  }

  /// Sync pending items to Firebase
  Future<bool> _syncToFirebase() async {
    if (_pendingSyncQueue.isEmpty) return true;

    try {
      // Get current user safely with enhanced debugging
      final user = await _getCurrentUserSafely();
      if (user == null) {
        debugPrint('⏳ [ProgressTracker] Sync skipped - no authenticated user');
        debugPrint(
            '🔍 [ProgressTracker] Debug - checking user availability...');

        // Enhanced debugging - try multiple ways to get user
        try {
          final userServiceUser = await UserService.instance.getCurrentUser();
          debugPrint(
              '🔍 [ProgressTracker] UserService user: ${userServiceUser?.username ?? "null"}');
          debugPrint(
              '🔍 [ProgressTracker] UserService user isDefault: ${userServiceUser?.isDefaultUser ?? "null"}');
        } catch (e) {
          debugPrint('❌ [ProgressTracker] UserService error: $e');
        }

        return false;
      }

      // Additional validation - check if user is authenticated
      if (user.isDefaultUser) {
        debugPrint(
            '⏳ [ProgressTracker] Sync skipped - user is guest (${user.username})');
        return false;
      }

      debugPrint(
          '☁️ [ProgressTracker] Syncing ${_pendingSyncQueue.length} items to Firebase for user: ${user.username}');

      // Process each item in sync queue
      int successCount = 0;
      int failCount = 0;

      for (final item in List.from(_pendingSyncQueue)) {
        try {
          await _syncSingleItem(user, item);
          _pendingSyncQueue.remove(item);
          successCount++;
          debugPrint('✅ [ProgressTracker] Synced item: ${item['type']}');
        } catch (e) {
          failCount++;
          debugPrint(
              '❌ [ProgressTracker] Failed to sync item ${item['type']}: $e');
          // Keep item in queue for retry
        }
      }

      debugPrint(
          '📊 [ProgressTracker] Sync complete - Success: $successCount, Failed: $failCount');

      // Save updated queue and timestamp
      await _prefs!.setString(_pendingSyncKey, jsonEncode(_pendingSyncQueue));
      await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());

      final remaining = _pendingSyncQueue.length;
      if (remaining == 0) {
        debugPrint(
            '✅ [ProgressTracker] All items synced to Firebase successfully');
      } else {
        debugPrint(
            '⚠️ [ProgressTracker] Sync completed with $remaining items remaining');
      }

      return remaining == 0;
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Firebase sync error: $e');
      return false;
    }
  }

  /// Sync a single item to Firebase using existing methods
  Future<void> _syncSingleItem(User user, Map<String, dynamic> item) async {
    final type = item['type'] as String;

    switch (type) {
      case 'topic_quiz':
      case 'topic_completion':
        await _syncTopicProgress(user, item);
        break;
      case 'section_quiz':
        await _syncSectionProgress(user, item);
        break;
    }
  }

  /// Sync topic progress to Firebase using existing UserService
  Future<void> _syncTopicProgress(User user, Map<String, dynamic> item) async {
    try {
      final topicId = item['topicId'] as String;
      final passed = item['passed'] as bool;
      final sectionId = item['sectionId'] as String?;

      // Use existing _updateTopicCompletion method
      await _updateTopicCompletion(
        userId: user.id,
        topicId: topicId,
        sectionId: sectionId,
        passed: passed,
        score: item['score'] as double? ?? (passed ? 1.0 : 0.0),
        timeSpent: Duration.zero, // Would need to store this in item
      );

      debugPrint('☁️ [ProgressTracker] Topic $topicId synced to Firebase');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Failed to sync topic to Firebase: $e');
      rethrow;
    }
  }

  /// Sync section progress to Firebase using existing methods
  Future<void> _syncSectionProgress(
      User user, Map<String, dynamic> item) async {
    try {
      final sectionId = item['sectionId'] as String;
      final passed = item['passed'] as bool;

      // FIXED: Create QuizResult from data instead of using fromJson
      final resultData = item['result'] as Map<String, dynamic>;
      final result = _createQuizResultFromData(resultData);

      // Use existing fallback method for section quiz completion
      await _recordSectionQuizCompletionFallback(
        result: result,
        sectionId: sectionId,
        passingScore: 0.7,
      );

      debugPrint('☁️ [ProgressTracker] Section $sectionId synced to Firebase');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Failed to sync section to Firebase: $e');
      rethrow;
    }
  }

  /// ADDED: Create QuizResult from data (since fromJson doesn't exist)
  QuizResult _createQuizResultFromData(Map<String, dynamic> data) {
    try {
      return QuizResult(
        sessionId: data['sessionId'] as String? ?? 'unknown',
        quizType: _parseQuizType(data['quizType'] as String?),
        completedAt: data['completedAt'] != null
            ? DateTime.parse(data['completedAt'] as String)
            : DateTime.now(),
        totalQuestions: data['totalQuestions'] as int? ?? 0,
        questionsAnswered: data['questionsAnswered'] as int? ?? 0,
        questionsCorrect: data['questionsCorrect'] as int? ?? 0,
        questionsSkipped: data['questionsSkipped'] as int? ?? 0,
        totalPossiblePoints:
            (data['totalPossiblePoints'] as num?)?.toDouble() ?? 0.0,
        pointsEarned: (data['pointsEarned'] as num?)?.toDouble() ?? 0.0,
        timeSpent: Duration(milliseconds: data['timeSpent'] as int? ?? 0),
        questionResults: [], // Would need proper deserialization
        topicPerformance: [], // Would need proper deserialization
        passingScore: (data['passingScore'] as num?)?.toDouble() ?? 0.7,
        timeLimitMinutes: data['timeLimitMinutes'] as int?,
        hintsUsed: data['hintsUsed'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint(
          '⚠️ [ProgressTracker] Error creating QuizResult from data: $e');
      // Return a minimal valid QuizResult
      return QuizResult(
        sessionId: 'fallback',
        quizType: QuizType.topic,
        completedAt: DateTime.now(),
        totalQuestions: 1,
        questionsAnswered: 1,
        questionsCorrect: 1,
        questionsSkipped: 0,
        totalPossiblePoints: 1.0,
        pointsEarned: 1.0,
        timeSpent: Duration.zero,
        questionResults: [],
        topicPerformance: [],
      );
    }
  }

  /// Parse quiz type from string
  QuizType _parseQuizType(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'topic':
        return QuizType.topic;
      case 'section':
        return QuizType.section;
      default:
        return QuizType.topic;
    }
  }

  // ===== FALLBACK METHODS (original implementations) =====

  /// Fallback topic quiz completion (original method)
  Future<void> _recordQuizCompletionFallback({
    required QuizResult result,
    required String topicId,
    String? sectionId,
    double passingScore = 0.7,
  }) async {
    try {
      final passed = result.scorePercentage >= passingScore;
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) {
        debugPrint(
            '⚠️ [ProgressTracker] Fallback: Cannot record progress - no current user');
        return;
      }

      await _updateTopicCompletion(
        userId: currentUser.id,
        topicId: topicId,
        sectionId: sectionId,
        passed: passed,
        score: result.scorePercentage,
        timeSpent: result.timeSpent,
      );

      notifyListeners();
      debugPrint(
          '🔄 [ProgressTracker] Fallback: Progress updated via original method');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Fallback method failed: $e');
      rethrow;
    }
  }

  /// Fallback section quiz completion (original method)
  Future<void> _recordSectionQuizCompletionFallback({
    required QuizResult result,
    required String sectionId,
    double passingScore = 0.7,
  }) async {
    try {
      final passed = result.scorePercentage >= passingScore;
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) {
        debugPrint(
            '⚠️ [ProgressTracker] Fallback: Cannot record section progress - no current user');
        return;
      }

      final section = _findSectionById(sectionId);
      if (section == null) {
        debugPrint(
            '⚠️ [ProgressTracker] Fallback: Could not find section $sectionId');
        return;
      }

      var currentProgress = currentUser.progress;
      currentProgress = currentProgress.completeSectionQuiz(sectionId, passed);

      if (passed) {
        for (final topic in section.topics) {
          currentProgress = currentProgress.completeTopicQuiz(topic.id, true);
        }
        currentProgress = _updateSectionProgress(
          progress: currentProgress,
          sectionId: sectionId,
          allTopicsCompleted: true,
        );
      }

      await UserService.instance.updateUserProgress(currentProgress);
      notifyListeners();
      debugPrint(
          '🔄 [ProgressTracker] Fallback: Section quiz progress saved via original method');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Fallback section method failed: $e');
      rethrow;
    }
  }

  // ===== EXISTING HELPER METHODS =====

  /// Updates topic completion status and section progress
  Future<void> _updateTopicCompletion({
    required String userId,
    required String topicId,
    String? sectionId,
    required bool passed,
    required double score,
    required Duration timeSpent,
  }) async {
    try {
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) return;

      var currentProgress = currentUser.progress;
      currentProgress = currentProgress.completeTopicQuiz(topicId, passed);

      final sectionForTopic = _findSectionContainingTopic(topicId);
      if (sectionForTopic != null) {
        currentProgress = _updateSectionProgress(
          progress: currentProgress,
          sectionId: sectionForTopic.id,
          topicId: topicId,
          passed: passed,
        );
      } else if (sectionId != null) {
        currentProgress = _updateSectionProgress(
          progress: currentProgress,
          sectionId: sectionId,
          topicId: topicId,
          passed: passed,
        );
      }

      await UserService.instance.updateUserProgress(currentProgress);
      notifyListeners();
      debugPrint('💾 [ProgressTracker] Progress saved and listeners notified');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error updating topic completion: $e');
      rethrow;
    }
  }

  /// Find which section contains a specific topic
  LearningSection? _findSectionContainingTopic(String topicId) {
    final sections = LearningContentRepository.getAllSections();
    for (final section in sections) {
      for (final topic in section.topics) {
        if (topic.id == topicId) {
          return section;
        }
      }
    }
    return null;
  }

  /// Updates section-level progress calculations
  UserProgress _updateSectionProgress({
    required UserProgress progress,
    required String sectionId,
    String? topicId,
    bool? passed,
    bool allTopicsCompleted = false,
  }) {
    try {
      final section = _findSectionById(sectionId);
      if (section == null) {
        debugPrint('⚠️ [ProgressTracker] Could not find section $sectionId');
        return progress;
      }

      int completedTopics = 0;
      if (allTopicsCompleted) {
        completedTopics = section.totalTopics;
      } else {
        for (final topic in section.topics) {
          if (progress.completedTopics.contains(topic.id)) {
            completedTopics++;
          }
        }
      }

      final newSectionProgress = SectionProgress(
        topicsCompleted: completedTopics,
        totalTopics: section.totalTopics,
        sectionQuizCompleted: progress.completedSections.contains(sectionId),
      );

      final updatedSectionProgress =
          Map<String, SectionProgress>.from(progress.sectionProgress);
      updatedSectionProgress[sectionId] = newSectionProgress;

      return UserProgress(
        sectionProgress: updatedSectionProgress,
        completedTopics: progress.completedTopics,
        completedSections: progress.completedSections,
        totalQuizzesTaken: progress.totalQuizzesTaken,
        totalQuizzesPassed: progress.totalQuizzesPassed,
      );
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error updating section progress: $e');
      return progress;
    }
  }

  /// Find a section by its ID
  LearningSection? _findSectionById(String sectionId) {
    final sections = LearningContentRepository.getAllSections();
    for (final section in sections) {
      if (section.id == sectionId) {
        return section;
      }
    }
    return null;
  }

  /// Safely get current user with error handling
  /// ENHANCED: Added comprehensive debugging and multiple fallback attempts
  Future<User?> _getCurrentUserSafely() async {
    try {
      debugPrint('🔍 [ProgressTracker] Attempting to get current user...');

      final user = await UserService.instance.getCurrentUser();

      if (user != null) {
        debugPrint(
            '✅ [ProgressTracker] Found user: ${user.username} (isDefault: ${user.isDefaultUser})');
        return user;
      } else {
        debugPrint(
            '⚠️ [ProgressTracker] UserService.getCurrentUser returned null');

        // Try a small delay and retry once (for timing issues)
        await Future.delayed(const Duration(milliseconds: 100));
        final retryUser = await UserService.instance.getCurrentUser();

        if (retryUser != null) {
          debugPrint(
              '✅ [ProgressTracker] Found user on retry: ${retryUser.username}');
          return retryUser;
        } else {
          debugPrint('❌ [ProgressTracker] Still no user found after retry');
        }

        return null;
      }
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error getting current user: $e');

      // Try once more after the error
      try {
        await Future.delayed(const Duration(milliseconds: 200));
        final fallbackUser = await UserService.instance.getCurrentUser();
        if (fallbackUser != null) {
          debugPrint(
              '✅ [ProgressTracker] Found user on fallback attempt: ${fallbackUser.username}');
          return fallbackUser;
        }
      } catch (fallbackError) {
        debugPrint(
            '❌ [ProgressTracker] Fallback attempt also failed: $fallbackError');
      }

      return null;
    }
  }

  /// Update topic in local progress object
  UserProgress _updateTopicInProgress(
      UserProgress progress, String topicId, bool passed, String? sectionId) {
    final updatedTopics = Set<String>.from(progress.completedTopics);

    if (passed) {
      updatedTopics.add(topicId);
    } else {
      updatedTopics.remove(topicId);
    }

    // Update section progress if we can find the section
    final section = sectionId != null
        ? _findSectionById(sectionId)
        : _findSectionContainingTopic(topicId);
    if (section != null) {
      final updatedSectionProgress =
          Map<String, SectionProgress>.from(progress.sectionProgress);

      final completedInSection =
          section.topics.where((t) => updatedTopics.contains(t.id)).length;

      updatedSectionProgress[section.id] = SectionProgress(
        topicsCompleted: completedInSection,
        totalTopics: section.topics.length,
        sectionQuizCompleted: progress.completedSections.contains(section.id),
      );

      // FIXED: Use proper constructor instead of copyWith
      return UserProgress(
        sectionProgress: updatedSectionProgress,
        completedTopics: updatedTopics,
        completedSections: progress.completedSections,
        totalQuizzesTaken: progress.totalQuizzesTaken,
        totalQuizzesPassed: progress.totalQuizzesPassed,
      );
    }

    // FIXED: Use proper constructor instead of copyWith
    return UserProgress(
      sectionProgress: progress.sectionProgress,
      completedTopics: updatedTopics,
      completedSections: progress.completedSections,
      totalQuizzesTaken: progress.totalQuizzesTaken,
      totalQuizzesPassed: progress.totalQuizzesPassed,
    );
  }

  /// Update section in local progress object
  UserProgress _updateSectionInProgress(
      UserProgress progress, String sectionId, bool passed) {
    final updatedSections = Set<String>.from(progress.completedSections);

    if (passed) {
      updatedSections.add(sectionId);
    } else {
      updatedSections.remove(sectionId);
    }

    // FIXED: Use proper constructor instead of copyWith
    return UserProgress(
      sectionProgress: progress.sectionProgress,
      completedTopics: progress.completedTopics,
      completedSections: updatedSections,
      totalQuizzesTaken: progress.totalQuizzesTaken,
      totalQuizzesPassed: progress.totalQuizzesPassed,
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
