// lib/services/firebase_user_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user/user.dart';
import '../models/user/user_preferences.dart';
import '../models/user/user_progress.dart';
import './firebase_auth_service.dart';
import './firebase_database_service.dart';
import './user_service.dart';

/// Enhanced User Service with Firebase integration for separated models
/// Provides a unified interface for user management with Firebase backend
/// and fallback to local storage for offline functionality
class FirebaseUserService {
  static FirebaseUserService? _instance;
  static FirebaseUserService get instance =>
      _instance ??= FirebaseUserService._();
  FirebaseUserService._();

  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService.instance;
  final UserService _localService = UserService.instance;

  bool _isInitialized = false;
  CompleteUserData? _cachedUserData;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local service for fallback
      await _localService.initialize();
      _isInitialized = true;
      print('Firebase User Service initialized successfully');
    } catch (e) {
      print('Error initializing Firebase User Service: $e');
      _isInitialized = true;
    }
  }

  /// Auth state stream - delegate to Firebase Auth Service
  Stream<firebase_auth.User?> get authStateChanges =>
      _authService.authStateChanges;

  /// Get current user account (prioritize Firebase, fallback to local)
  Future<User?> getCurrentUser() async {
    await initialize();

    try {
      print('Getting current user account...');

      if (_authService.isLoggedIn) {
        print('Firebase user detected, loading user data...');

        final firebaseUser = _authService.currentFirebaseUser!;
        final user = await _dbService.getUser(firebaseUser.uid);

        if (user != null) {
          print('User account loaded successfully: ${user.username}');
          return user;
        } else {
          print('No user data found, attempting repair...');
          return await _repairUserData(firebaseUser);
        }
      }

      print('No Firebase user, checking local storage...');
      return await _localService.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');
      try {
        return await _localService.getCurrentUser();
      } catch (localError) {
        print('Local service also failed: $localError');
        return null;
      }
    }
  }

  /// Get complete user data (account + preferences + progress)
  Future<CompleteUserData?> getCompleteUserData() async {
    await initialize();

    try {
      if (_cachedUserData != null) {
        return _cachedUserData;
      }

      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        final completeData = await _dbService.getCompleteUserData(firebaseUser.uid);

        if (completeData != null) {
          _cachedUserData = completeData;
          return completeData;
        } else {
          // Auto-repair missing data
          final repairedUser = await _repairUserData(firebaseUser);
          if (repairedUser != null) {
            _cachedUserData = CompleteUserData(
              user: repairedUser,
              preferences: UserPreferences.defaults(),
              progress: UserProgress.empty(),
            );
            return _cachedUserData;
          }
        }
      }

      // Fallback to local storage
      final localUser = await _localService.getCurrentUser();
      if (localUser != null) {
        // For local users, we need to extract preferences and progress
        // This is a temporary solution until we fully migrate the local service
        return CompleteUserData(
          user: localUser,
          preferences: UserPreferences.defaults(), // TODO: Extract from local storage
          progress: UserProgress.empty(), // TODO: Extract from local storage
        );
      }

      return null;
    } catch (e) {
      print('Error getting complete user data: $e');
      return null;
    }
  }

  /// Get user preferences
  Future<UserPreferences?> getUserPreferences() async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        return await _dbService.getUserPreferences(firebaseUser.uid);
      } else {
        // For guest users, get preferences from complete user data
        final completeData = await getCompleteUserData();
        return completeData?.preferences;
      }
    } catch (e) {
      print('Error getting user preferences: $e');
      return UserPreferences.defaults();
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.saveUserPreferences(firebaseUser.uid, preferences);

        // Update cached data
        if (_cachedUserData != null) {
          _cachedUserData = _cachedUserData!.copyWith(preferences: preferences);
        }
      } else {
        // For guest users, update local storage
        // TODO: Implement proper local preference storage
        print('Saving preferences for guest user (local storage)');
      }
    } catch (e) {
      print('Error saving user preferences: $e');
      rethrow;
    }
  }

  /// Get user progress
  Future<UserProgress?> getUserProgress() async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        return await _dbService.getUserProgress(firebaseUser.uid);
      } else {
        // For guest users, get progress from complete user data
        final completeData = await getCompleteUserData();
        return completeData?.progress;
      }
    } catch (e) {
      print('Error getting user progress: $e');
      return UserProgress.empty();
    }
  }

  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.saveUserProgress(firebaseUser.uid, progress);

        // Update cached data
        if (_cachedUserData != null) {
          _cachedUserData = _cachedUserData!.copyWith(progress: progress);
        }
      } else {
        // For guest users, update local storage
        // TODO: Implement proper local progress storage
        print('Saving progress for guest user (local storage)');
      }
    } catch (e) {
      print('Error saving user progress: $e');
      rethrow;
    }
  }

  /// Record quiz attempt
  Future<void> recordQuizAttempt(QuizAttempt attempt) async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.recordQuizAttempt(firebaseUser.uid, attempt);

        // Update cached progress
        if (_cachedUserData != null) {
          final updatedProgress = _cachedUserData!.progress.recordQuizAttempt(
            topicId: attempt.topicId,
            sectionId: attempt.sectionId,
            score: attempt.score,
            passed: attempt.passed,
            timeSpent: attempt.timeSpent,
            totalQuestions: attempt.totalQuestions,
            correctAnswers: attempt.correctAnswers,
            isTopicQuiz: attempt.isTopicQuiz,
          );
          _cachedUserData = _cachedUserData!.copyWith(progress: updatedProgress);
        }
      } else {
        // For guest users, update local storage
        // TODO: Implement proper local quiz attempt storage
        print('Recording quiz attempt for guest user (local storage)');
      }
    } catch (e) {
      print('Error recording quiz attempt: $e');
      rethrow;
    }
  }

  /// Register new user with Firebase
  Future<User> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    await initialize();

    try {
      print('Starting user registration...');

      // Register with Firebase Auth
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        username: username,
        password: password,
      );

      print('User registered successfully: ${user.username}');
      
      // Cache the complete user data
      _cachedUserData = CompleteUserData(
        user: user,
        preferences: UserPreferences.defaults(),
        progress: UserProgress.empty(),
      );

      return user;
    } catch (e) {
      print('Registration failed: $e');
      rethrow;
    }
  }

  /// Login user with Firebase
  Future<User?> loginUser({
    String? email,
    String? password,
  }) async {
    await initialize();

    try {
      if (email != null && password != null) {
        print('Logging in with email/password...');

        final user = await _authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        print('Login successful: ${user.username}');
        
        // Load complete user data
        final completeData = await getCompleteUserData();
        if (completeData != null) {
          _cachedUserData = completeData;
        }

        return user;
      } else {
        print('Logging in as guest...');
        return await loginAsGuest();
      }
    } catch (e) {
      print('Login failed: $e');
      rethrow;
    }
  }

  /// Login as guest (local only)
  Future<User> loginAsGuest() async {
    await initialize();

    try {
      print('Logging in as guest...');
      final user = await _localService.loginUser();
      
      if (user != null) {
        _cachedUserData = CompleteUserData(
          user: user,
          preferences: UserPreferences.defaults(),
          progress: UserProgress.empty(),
        );
        return user;
      } else {
        final defaultUser = User.defaultUser();
        _cachedUserData = CompleteUserData(
          user: defaultUser,
          preferences: UserPreferences.defaults(),
          progress: UserProgress.empty(),
        );
        return defaultUser;
      }
    } catch (e) {
      print('Guest login failed, creating default user: $e');
      final defaultUser = User.defaultUser();
      _cachedUserData = CompleteUserData(
        user: defaultUser,
        preferences: UserPreferences.defaults(),
        progress: UserProgress.empty(),
      );
      return defaultUser;
    }
  }

  /// Update user account
  Future<void> updateUser(User user) async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.updateUser(firebaseUser.uid, user);

        // Update cached data
        if (_cachedUserData != null) {
          _cachedUserData = _cachedUserData!.copyWith(user: user);
        }
      } else {
        // Update locally for guest users
        await _localService.saveCurrentUser(user);
        if (_cachedUserData != null) {
          _cachedUserData = _cachedUserData!.copyWith(user: user);
        }
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Update specific preference
  Future<void> updatePreference(String key, dynamic value) async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.updateUserPreference(firebaseUser.uid, key, value);

        // Update cached data
        if (_cachedUserData != null) {
          // TODO: Update specific preference in cached data
          _cachedUserData = null; // Force reload
        }
      } else {
        // Update locally for guest users
        print('Updating preference for guest user: $key = $value');
      }
    } catch (e) {
      print('Error updating preference: $e');
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      print('Logging out...');

      if (_authService.isLoggedIn) {
        await _authService.signOut();
      }

      _cachedUserData = null;
      print('Logout successful');
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      print('Error sending email verification: $e');
      rethrow;
    }
  }

  /// Check if current user's email is verified
  bool get isEmailVerified => _authService.isEmailVerified;

  /// Check if user is logged in with Firebase
  bool get isLoggedIn => _authService.isLoggedIn;

  /// Get current Firebase user
  firebase_auth.User? get currentFirebaseUser =>
      _authService.currentFirebaseUser;

  /// Clear cached user data
  void clearCache() {
    _cachedUserData = null;
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      if (_authService.isLoggedIn) {
        await _authService.deleteAccount();
        _cachedUserData = null;
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  /// Diagnostic Operations

  /// Add diagnostic method to help troubleshoot database issues
  Future<void> diagnoseDatabaseIssues(String userId) async {
    try {
      print('=== Database Diagnosis for User: $userId ===');

      final health = await _dbService.checkDatabaseHealth(userId);

      print('Database Health Check Results:');
      health.forEach((document, exists) {
        print('  $document: ${exists ? "✓ EXISTS" : "✗ MISSING"}');
      });

      if (health['userDocument'] == false) {
        print('>>> ISSUE IDENTIFIED: User document is missing in Firestore');
        print('>>> SOLUTION: Auto-repair will create missing documents');
      }

      final missingDocs = health.entries
          .where((entry) => entry.value == false && entry.key != 'error')
          .map((entry) => entry.key)
          .toList();

      if (missingDocs.isNotEmpty) {
        print('>>> MISSING DOCUMENTS: ${missingDocs.join(", ")}');
      }

      print('=== End Database Diagnosis ===');
    } catch (e) {
      print('Error during database diagnosis: $e');
    }
  }

  /// Export user data for backup
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        return await _dbService.exportUserData(firebaseUser.uid);
      } else {
        // Export local user data
        final completeData = await getCompleteUserData();
        return {
          'user': completeData?.user.toJson(),
          'preferences': completeData?.preferences.toJson(),
          'progress': completeData?.progress.toJson(),
          'exportedAt': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print('Error exporting user data: $e');
      rethrow;
    }
  }

  /// Helper Methods

  /// Repair user data for existing Firebase users
  Future<User?> _repairUserData(firebase_auth.User firebaseUser) async {
    try {
      print('Attempting to repair user data for: ${firebaseUser.uid}');

      final repairedUser = await _dbService.repairUserData(
        firebaseUid: firebaseUser.uid,
        email: firebaseUser.email ?? 'unknown@email.com',
        displayName: firebaseUser.displayName,
      );

      print('User data repaired successfully: ${repairedUser.username}');
      return repairedUser;
    } catch (repairError) {
      print('Failed to repair user data: $repairError');
      print('Logging out due to unrecoverable data issue');
      await logout();
      return null;
    }
  }

  /// Check for migration from local storage to Firebase
  Future<void> _checkForMigration() async {
    try {
      if (_authService.isLoggedIn) {
        final localUser = await _localService.getCurrentUser();
        final firebaseUser = await getCurrentUser();

        if (localUser != null && firebaseUser == null) {
          print('Found local user data that might need migration');
          // TODO: Implement migration logic if needed
        }
      }
    } catch (e) {
      print('Error checking for migration: $e');
    }
  }
}

/// Extended CompleteUserData with additional helpers
extension CompleteUserDataExtensions on CompleteUserData {
  /// Get display name
  String get displayName => user.displayName;

  /// Check if user is guest
  bool get isGuest => user.isGuest;

  /// Check if user is Firebase user
  bool get isFirebaseUser => user.isFirebaseUser;

  /// Get learning stats
  LearningStats get learningStats => progress.learningStats;

  /// Get fretboard preferences
  FretboardPreferences get fretboardPreferences => preferences.fretboardPreferences;

  /// Get quiz preferences
  QuizPreferences get quizPreferences => preferences.quizPreferences;
}