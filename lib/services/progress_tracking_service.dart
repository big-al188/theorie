// lib/services/progress_tracking_service.dart
// UPDATED: Now properly imports and uses separated user models

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user.dart';
import '../models/user/user_progress.dart';    // ADDED: Import separated models
import '../models/quiz/quiz_result.dart';
import '../models/quiz/quiz_session.dart';
import '../models/learning/learning_content.dart';
import 'user_service.dart';
import 'firebase_user_service.dart';

/// Service responsible for tracking and updating user learning progress
/// UPDATED: Now works with separated user models
class ProgressTrackingService extends ChangeNotifier {
  static final ProgressTrackingService _instance =
      ProgressTrackingService._internal();
  static ProgressTrackingService get instance => _instance;

  ProgressTrackingService._internal();

  // Offline storage components
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _syncTimer;
  final Duration _syncInterval = const Duration(minutes: 2);

  // Local storage keys
  static const String _progressKey = 'offline_progress';
  static const String _pendingSyncKey = 'pending_sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Cache and sync queue
  UserProgress? _cachedProgress;
  final List<Map<String, dynamic>> _pendingSyncQueue = [];

  /// Initialize offline storage
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

  /// UPDATED: Enhanced progress loading with proper Firebase integration
  Future<UserProgress> getCurrentProgress() async {
    await initialize();

    try {
      debugPrint('🔍 [ProgressTracker] Loading current progress...');

      // STEP 1: Check local storage first (for active sessions)
      final localProgress = await _loadLocalProgress();
      if (localProgress != null &&
          (localProgress.completedTopics.isNotEmpty ||
              localProgress.sectionProgress.isNotEmpty)) {
        debugPrint('📱 [ProgressTracker] Found valid local progress');
        _cachedProgress = localProgress;

        // Sync to UserService for UI consistency
        try {
          await UserService.instance.updateUserProgress(localProgress);
          debugPrint('✅ [ProgressTracker] Synced local progress to UserService');
        } catch (e) {
          debugPrint('⚠️ [ProgressTracker] Could not sync to UserService: $e');
        }

        return localProgress;
      }

      debugPrint('📱 [ProgressTracker] No valid local progress, checking Firebase...');

      // STEP 2: Try to load from Firebase (for app restart scenarios)
      final firebaseProgress = await _loadProgressFromFirebase();
      if (firebaseProgress != null) {
        debugPrint('☁️ [ProgressTracker] Loaded progress from Firebase');

        // Cache locally for future use
        await _saveLocalProgress(firebaseProgress);

        // Sync to UserService for UI consistency
        try {
          await UserService.instance.updateUserProgress(firebaseProgress);
          debugPrint('✅ [ProgressTracker] Synced Firebase progress to UserService');
        } catch (e) {
          debugPrint('⚠️ [ProgressTracker] Could not sync Firebase progress to UserService: $e');
        }

        _cachedProgress = firebaseProgress;
        return firebaseProgress;
      }

      debugPrint('☁️ [ProgressTracker] No Firebase progress found, trying UserService...');

      // STEP 3: Fallback to UserService (for compatibility)
      final user = await _getCurrentUserSafely();
      if (user != null && !user.isDefaultUser) {
        // UPDATED: Get progress separately from UserService
        final userServiceProgress = await UserService.instance.getUserProgress(user.id);
        if (userServiceProgress.completedTopics.isNotEmpty ||
            userServiceProgress.sectionProgress.isNotEmpty) {
          debugPrint('👤 [ProgressTracker] Found progress in UserService');

          // Cache locally
          await _saveLocalProgress(userServiceProgress);
          _cachedProgress = userServiceProgress;
          return userServiceProgress;
        }
      }

      // STEP 4: Final fallback - empty progress
      debugPrint('🆕 [ProgressTracker] Creating new empty progress');
      final emptyProgress = UserProgress.empty();
      _cachedProgress = emptyProgress;
      return emptyProgress;
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error loading progress: $e');

      // Return cached progress if available
      if (_cachedProgress != null) {
        debugPrint('🔄 [ProgressTracker] Returning cached progress due to error');
        return _cachedProgress!;
      }

      return UserProgress.empty();
    }
  }

  /// Load progress directly from Firebase
  Future<UserProgress?> _loadProgressFromFirebase() async {
    try {
      debugPrint('🔍 [ProgressTracker] Attempting to load from Firebase...');

      // Try to get Firebase user service directly
      final firebaseUser = await FirebaseUserService.instance.getCurrentUser();
      if (firebaseUser != null && !firebaseUser.isDefaultUser) {
        debugPrint('☁️ [ProgressTracker] Found Firebase user: ${firebaseUser.username}');

        // UPDATED: Load progress from Firebase database
        final firebaseProgress = await FirebaseUserService.instance.getUserProgress();
        if (firebaseProgress != null &&
            (firebaseProgress.completedTopics.isNotEmpty ||
                firebaseProgress.sectionProgress.isNotEmpty)) {
          debugPrint('✅ [ProgressTracker] Found progress in Firebase database');
          return firebaseProgress;
        } else {
          debugPrint('📭 [ProgressTracker] Firebase database has empty progress');
        }
      } else {
        debugPrint('👤 [ProgressTracker] No authenticated Firebase user found');
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error loading from Firebase: $e');
      return null;
    }
  }

  /// Initialize section progress with better Firebase integration
  Future<void> initializeSectionProgress() async {
    await initialize();

    try {
      // Get current user safely
      final currentUser = await _getCurrentUserSafely();
      if (currentUser == null) {
        debugPrint('⏳ [ProgressTracker] Initialize skipped - no current user');
        return;
      }

      debugPrint('👤 [ProgressTracker] Initializing progress for user: ${currentUser.username}');

      // Load existing progress using enhanced method
      var currentProgress = await getCurrentProgress();

      // If we have existing section progress, skip initialization
      if (currentProgress.sectionProgress.isNotEmpty) {
        debugPrint('✅ [ProgressTracker] Section progress already initialized');
        return;
      }

      debugPrint('🔧 [ProgressTracker] No existing progress found, initializing sections...');

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
            sectionQuizCompleted: currentProgress.completedSections.contains(section.id),
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
        // Save to local storage first, then update UserService, then Firebase
        await _saveLocalProgress(currentProgress);
        await UserService.instance.updateUserProgress(currentProgress);

        // UPDATED: Also save to Firebase
        if (!currentUser.isDefaultUser) {
          try {
            await FirebaseUserService.instance.saveUserProgress(currentProgress);
            debugPrint('✅ [ProgressTracker] Section progress synced to Firebase');
          } catch (e) {
            debugPrint('⚠️ [ProgressTracker] Could not sync section progress to Firebase: $e');
          }
        }

        notifyListeners();
        debugPrint('💾 [ProgressTracker] Section progress initialized and saved');
      } else {
        debugPrint('✅ [ProgressTracker] Section progress already initialized');
      }
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error initializing section progress: $e');
    }
  }

  /// Records topic quiz completion with offline-first storage
  Future<void> recordQuizCompletion({
    required QuizResult result,
    required String topicId,
    String? sectionId,
    double passingScore = 0.7,
  }) async {
    await initialize();

    try {
      final passed = result.scorePercentage >= passingScore;
      final timestamp = DateTime.now();

      debugPrint('📝 [ProgressTracker] Recording topic quiz: $topicId (${passed ? "PASSED" : "FAILED"})');

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

      debugPrint('✅ [ProgressTracker] Topic quiz recorded locally and queued for sync');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error recording quiz completion: $e');
      rethrow;
    }
  }

  /// Force sync when user becomes available
  Future<void> onUserAuthenticated() async {
    await initialize();

    debugPrint('🔄 [ProgressTracker] User authenticated - attempting immediate sync...');

    // When user becomes authenticated, reload progress from Firebase first
    try {
      final firebaseProgress = await _loadProgressFromFirebase();
      if (firebaseProgress != null) {
        debugPrint('🔄 [ProgressTracker] Reloading progress from Firebase after authentication');
        await _saveLocalProgress(firebaseProgress);
        _cachedProgress = firebaseProgress;

        // Update UserService
        try {
          await UserService.instance.updateUserProgress(firebaseProgress);
          debugPrint('✅ [ProgressTracker] Updated UserService with Firebase progress');
        } catch (e) {
          debugPrint('⚠️ [ProgressTracker] Could not update UserService: $e');
        }

        // Notify listeners of the updated progress
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ [ProgressTracker] Error reloading Firebase progress: $e');
    }

    // Then handle pending sync
    if (_pendingSyncQueue.isNotEmpty) {
      debugPrint('📤 [ProgressTracker] Found ${_pendingSyncQueue.length} pending items to sync');

      final success = await _syncToFirebase();
      if (success) {
        debugPrint('🚀 [ProgressTracker] User authentication sync successful');
      } else {
        debugPrint('⚠️ [ProgressTracker] User authentication sync failed - will retry later');
      }
    } else {
      debugPrint('✅ [ProgressTracker] No pending items to sync');
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

  /// Get current user with better Firebase integration
  Future<User?> _getCurrentUserSafely() async {
    try {
      debugPrint('🔍 [ProgressTracker] Attempting to get current user...');

      // Try UserService first (faster)
      var user = await UserService.instance.getCurrentUser();
      if (user != null) {
        debugPrint('✅ [ProgressTracker] Found user via UserService: ${user.username}');
        return user;
      }

      // If UserService doesn't have user, try Firebase directly
      debugPrint('🔍 [ProgressTracker] UserService empty, trying Firebase...');
      user = await FirebaseUserService.instance.getCurrentUser();
      if (user != null) {
        debugPrint('✅ [ProgressTracker] Found user via Firebase: ${user.username}');

        // Sync to UserService for consistency
        try {
          await UserService.instance.saveCurrentUser(user);
          debugPrint('✅ [ProgressTracker] Synced Firebase user to UserService');
        } catch (e) {
          debugPrint('⚠️ [ProgressTracker] Could not sync user to UserService: $e');
        }

        return user;
      }

      debugPrint('❌ [ProgressTracker] No user found in either service');
      return null;
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error getting current user: $e');
      return null;
    }
  }

  /// Records section quiz completion and auto-completes all topics
  Future<void> recordSectionQuizCompletion({
    required QuizResult result,
    required String sectionId,
    double passingScore = 0.7,
  }) async {
    await initialize();

    try {
      final passed = result.scorePercentage >= passingScore;
      final timestamp = DateTime.now();

      debugPrint('📝 [ProgressTracker] Recording section quiz: $sectionId (${passed ? "PASSED" : "FAILED"})');

      // Get section to auto-complete topics if passed
      final section = _findSectionById(sectionId);
      if (section == null) {
        debugPrint('⚠️ [ProgressTracker] Section not found: $sectionId');
        return;
      }

      // Store locally immediately
      await _storeLocalProgress(
        type: 'section_quiz',
        data: {
          'sectionId': sectionId,
          'passed': passed,
          'score': result.scorePercentage,
          'timestamp': timestamp.toIso8601String(),
          'result': result.toJson(),
          'autoCompleteTopics': passed ? section.topics.map((t) => t.id).toList() : [],
        },
      );

      // Add to sync queue
      await _addToSyncQueue({
        'type': 'section_quiz',
        'sectionId': sectionId,
        'passed': passed,
        'score': result.scorePercentage,
        'timestamp': timestamp.toIso8601String(),
        'result': result.toJson(),
        'autoCompleteTopics': passed ? section.topics.map((t) => t.id).toList() : [],
      });

      // If section passed, auto-complete all topics locally
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
        debugPrint('✨ [ProgressTracker] Auto-completed ${section.topics.length} topics for section: $sectionId');
      }

      // Notify UI and attempt sync
      notifyListeners();
      _attemptImmediateSync();

      debugPrint('✅ [ProgressTracker] Section quiz recorded locally and queued for sync');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error recording section quiz completion: $e');
      rethrow;
    }
  }

  /// Store progress locally with immediate effect
  Future<void> _storeLocalProgress({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Load current local progress
      UserProgress currentProgress = await _loadLocalProgress() ?? UserProgress.empty();

      // Apply the progress update based on type
      switch (type) {
        case 'topic_quiz':
        case 'topic_completion':
          final topicId = data['topicId'] as String;
          final passed = data['passed'] as bool;
          final sectionId = data['sectionId'] as String?;

          currentProgress = _updateTopicInProgress(currentProgress, topicId, passed, sectionId);
          break;

        case 'section_quiz':
          final sectionId = data['sectionId'] as String;
          final passed = data['passed'] as bool;
          final autoCompleteTopics = data['autoCompleteTopics'] as List<dynamic>?;

          currentProgress = _updateSectionInProgress(currentProgress, sectionId, passed);

          // Auto-complete topics if section passed
          if (passed && autoCompleteTopics != null) {
            for (final topicId in autoCompleteTopics) {
              currentProgress = _updateTopicInProgress(currentProgress, topicId as String, true, sectionId);
            }
          }
          break;
      }

      // Save to local storage
      await _prefs!.setString(_progressKey, jsonEncode(currentProgress.toJson()));
      _cachedProgress = currentProgress;

      debugPrint('💾 [ProgressTracker] Stored $type locally');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error storing local progress: $e');
      rethrow;
    }
  }

  /// Update topic in local progress object
  UserProgress _updateTopicInProgress(UserProgress progress, String topicId, bool passed, String? sectionId) {
    final updatedTopics = Set<String>.from(progress.completedTopics);

    if (passed) {
      updatedTopics.add(topicId);
    } else {
      updatedTopics.remove(topicId);
    }

    // Update section progress if we can find the section
    final section = sectionId != null ? _findSectionById(sectionId) : _findSectionContainingTopic(topicId);
    if (section != null) {
      final updatedSectionProgress = Map<String, SectionProgress>.from(progress.sectionProgress);

      final completedInSection = section.topics.where((t) => updatedTopics.contains(t.id)).length;

      updatedSectionProgress[section.id] = SectionProgress(
        topicsCompleted: completedInSection,
        totalTopics: section.topics.length,
        sectionQuizCompleted: progress.completedSections.contains(section.id),
      );

      return UserProgress(
        sectionProgress: updatedSectionProgress,
        completedTopics: updatedTopics,
        completedSections: progress.completedSections,
        totalQuizzesTaken: progress.totalQuizzesTaken + 1,
        totalQuizzesPassed: passed ? progress.totalQuizzesPassed + 1 : progress.totalQuizzesPassed,
      );
    }

    return UserProgress(
      sectionProgress: progress.sectionProgress,
      completedTopics: updatedTopics,
      completedSections: progress.completedSections,
      totalQuizzesTaken: progress.totalQuizzesTaken + 1,
      totalQuizzesPassed: passed ? progress.totalQuizzesPassed + 1 : progress.totalQuizzesPassed,
    );
  }

  /// Update section in local progress object
  UserProgress _updateSectionInProgress(UserProgress progress, String sectionId, bool passed) {
    final updatedSections = Set<String>.from(progress.completedSections);

    if (passed) {
      updatedSections.add(sectionId);
    } else {
      updatedSections.remove(sectionId);
    }

    return UserProgress(
      sectionProgress: progress.sectionProgress,
      completedTopics: progress.completedTopics,
      completedSections: updatedSections,
      totalQuizzesTaken: progress.totalQuizzesTaken + 1,
      totalQuizzesPassed: passed ? progress.totalQuizzesPassed + 1 : progress.totalQuizzesPassed,
    );
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

  // ===== FIREBASE SYNC METHODS =====

  /// Sync topic progress to Firebase
  Future<void> _syncTopicProgress(User user, Map<String, dynamic> item) async {
    try {
      final topicId = item['topicId'] as String;
      final passed = item['passed'] as bool;
      final sectionId = item['sectionId'] as String?;

      debugPrint('🔄 [ProgressTracker] Syncing topic $topicId to Firebase...');

      // Get current progress from local storage (most up-to-date)
      var currentProgress = await _loadLocalProgress() ?? UserProgress.empty();

      // Update the progress with this topic
      currentProgress = _updateTopicInProgress(currentProgress, topicId, passed, sectionId);

      // Save to Firebase using FirebaseUserService
      await FirebaseUserService.instance.saveUserProgress(currentProgress);

      // Also update UserService for consistency
      await UserService.instance.updateUserProgress(currentProgress);

      debugPrint('✅ [ProgressTracker] Topic $topicId synced to Firebase successfully');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Failed to sync topic to Firebase: $e');
      rethrow;
    }
  }

  /// Sync section progress to Firebase
  Future<void> _syncSectionProgress(User user, Map<String, dynamic> item) async {
    try {
      final sectionId = item['sectionId'] as String;
      final passed = item['passed'] as bool;
      final autoCompleteTopics = item['autoCompleteTopics'] as List<dynamic>?;

      debugPrint('🔄 [ProgressTracker] Syncing section $sectionId to Firebase...');

      // Get current progress from local storage (most up-to-date)
      var currentProgress = await _loadLocalProgress() ?? UserProgress.empty();

      // Update section completion
      currentProgress = _updateSectionInProgress(currentProgress, sectionId, passed);

      // Auto-complete topics if section passed
      if (passed && autoCompleteTopics != null) {
        for (final topicId in autoCompleteTopics) {
          currentProgress = _updateTopicInProgress(currentProgress, topicId as String, true, sectionId);
        }
      }

      // Save to Firebase using FirebaseUserService
      await FirebaseUserService.instance.saveUserProgress(currentProgress);

      // Also update UserService for consistency
      await UserService.instance.updateUserProgress(currentProgress);

      debugPrint('✅ [ProgressTracker] Section $sectionId synced to Firebase successfully');
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Failed to sync section to Firebase: $e');
      rethrow;
    }
  }

  // ===== REMAINING METHODS =====

  /// Check if topic is completed (offline-first)
  Future<bool> isTopicCompleted(String topicId) async {
    final progress = await getCurrentProgress();
    return progress.completedTopics.contains(topicId);
  }

  /// Check if section is completed (offline-first)
  Future<bool> isSectionCompleted(String sectionId) async {
    final progress = await getCurrentProgress();
    return progress.completedSections.contains(sectionId);
  }

  /// Get section progress (offline-first)
  Future<SectionProgress?> getSectionProgress(String sectionId) async {
    final progress = await getCurrentProgress();
    return progress.sectionProgress[sectionId];
  }

  /// Force sync to Firebase
  Future<bool> forceSyncToFirebase() async {
    await initialize();
    debugPrint('🔄 [ProgressTracker] Force sync to Firebase started...');

    try {
      final success = await _syncToFirebase();
      if (success) {
        debugPrint('✅ [ProgressTracker] Force sync completed successfully');
      } else {
        debugPrint('⚠️ [ProgressTracker] Force sync failed (user not available)');
      }
      return success;
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Force sync error: $e');
      return false;
    }
  }

  /// Manual sync trigger for debugging/testing
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
        }
      }
    } catch (e) {
      result['errors'].add('Exception: $e');
      debugPrint('❌ [ProgressTracker] Manual sync debug error: $e');
    }

    debugPrint('🔧 [ProgressTracker] Manual sync debug result: $result');
    return result;
  }

  /// Get detailed sync status for debugging
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

  /// Add item to sync queue
  Future<void> _addToSyncQueue(Map<String, dynamic> item) async {
    try {
      _pendingSyncQueue.add(item);
      await _prefs!.setString(_pendingSyncKey, jsonEncode(_pendingSyncQueue));
      debugPrint('📤 [ProgressTracker] Added to sync queue (${_pendingSyncQueue.length} pending)');
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
        debugPrint('📥 [ProgressTracker] Loaded ${_pendingSyncQueue.length} items from sync queue');
      } else {
        debugPrint('📥 [ProgressTracker] Loaded 0 items from sync queue');
      }
    } catch (e) {
      debugPrint('❌ [ProgressTracker] Error loading sync queue: $e');
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();

    final interval = _pendingSyncQueue.isNotEmpty ? const Duration(seconds: 30) : _syncInterval;

    _syncTimer = Timer.periodic(interval, (_) {
      _attemptImmediateSync();
    });

    debugPrint('⏱️ [ProgressTracker] Periodic sync started (every ${interval.inSeconds} seconds)');
  }

  /// Attempt immediate sync (non-blocking)
  void _attemptImmediateSync() {
    if (_pendingSyncQueue.isEmpty) return;

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
      final user = await _getCurrentUserSafely();
      if (user == null || user.isDefaultUser) {
        debugPrint('⏳ [ProgressTracker] Sync skipped - no authenticated user');
        return false;
      }

      debugPrint('☁️ [ProgressTracker] Syncing ${_pendingSyncQueue.length} items to Firebase for user: ${user.username}');

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
          debugPrint('❌ [ProgressTracker] Failed to sync item ${item['type']}: $e');
        }
      }

      // Save updated queue and timestamp
      await _prefs!.setString(_pendingSyncKey, jsonEncode(_pendingSyncQueue));
      await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());

      debugPrint('📊 [ProgressTracker] Sync complete - Success: $successCount, Failed: $failCount');

      return _pendingSyncQueue.isEmpty;
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

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}