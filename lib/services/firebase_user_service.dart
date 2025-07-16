// lib/services/firebase_user_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user/user.dart' as app_user;
import './firebase_auth_service.dart';
import './firebase_database_service.dart';
import './user_service.dart';

/// Enhanced User Service with Firebase integration
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
  app_user.User? _cachedUser;

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
      // Still mark as initialized to prevent infinite loops
      _isInitialized = true;
    }
  }

  /// Auth state stream - delegate to Firebase Auth Service
  Stream<firebase_auth.User?> get authStateChanges =>
      _authService.authStateChanges;

  /// Get current user (prioritize Firebase, fallback to local, auto-repair if needed)
  Future<app_user.User?> getCurrentUser() async {
    await initialize();

    try {
      print('Getting current user...');

      // Check if we have a Firebase user
      if (_authService.isLoggedIn) {
        print('Firebase user detected, loading app user data...');

        final firebaseUser = _authService.currentFirebaseUser!;
        print('Loading Firebase user data for: ${firebaseUser.uid}');

        // Try to get existing app user data
        final appUser = await _dbService.getUser(firebaseUser.uid);

        if (appUser != null) {
          print('App user loaded successfully: ${appUser.username}');
          _cachedUser = appUser;
          return appUser;
        } else {
          print(
              'No app user data found for Firebase user: ${firebaseUser.uid}');

          // Auto-repair: Create missing user data
          try {
            print('Attempting to repair missing user data...');

            final repairedUser = await _dbService.repairUserData(
              firebaseUid: firebaseUser.uid,
              email: firebaseUser.email ?? 'unknown@email.com',
              displayName: firebaseUser.displayName,
            );

            print('User data repaired successfully: ${repairedUser.username}');
            _cachedUser = repairedUser;

            // Update last login time
            final updatedUser =
                repairedUser.copyWith(lastLoginAt: DateTime.now());
            await _dbService.updateUser(firebaseUser.uid, updatedUser);
            _cachedUser = updatedUser;

            return updatedUser;
          } catch (repairError) {
            print('Failed to repair user data: $repairError');

            // If repair fails, we need to sign out the user
            print('Logging out...');
            await logout();
            print('Logout successful');
            print('Signed out user due to unrecoverable data issue');
            return null;
          }
        }
      }

      print('No Firebase user, checking local storage...');
      // Fallback to local service for guest users
      return await _localService.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');

      // If Firebase fails, try local service as fallback
      try {
        print('Attempting local service fallback...');
        return await _localService.getCurrentUser();
      } catch (localError) {
        print('Local service also failed: $localError');
        return null;
      }
    }
  }

  /// Add diagnostic method to help troubleshoot database issues
  Future<void> diagnoseDatabaseIssues(String userId) async {
    try {
      print('=== Database Diagnosis for User: $userId ===');

      final health = await _dbService.checkDatabaseHealth(userId);

      print('Database Health Check Results:');
      health.forEach((document, exists) {
        print('  $document: ${exists ? "✓ EXISTS" : "✗ MISSING"}');
      });

      // If main user document is missing, this confirms the repair is needed
      if (health['userDocument'] == false) {
        print('>>> ISSUE IDENTIFIED: User document is missing in Firestore');
        print('>>> SOLUTION: Auto-repair will create missing documents');
      }

      // Check for partial data
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

  /// Register new user with Firebase
  Future<app_user.User> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    await initialize();

    try {
      print('Starting user registration...');

      // Register with Firebase using the new anonymous auth flow
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        username: username,
        password: password,
      );

      print('User registered successfully: ${user.username}');
      _cachedUser = user;
      return user;
    } catch (e) {
      print('Registration failed: $e');
      rethrow;
    }
  }

  /// Login user with Firebase
  Future<app_user.User?> loginUser({
    String? email,
    String? password,
  }) async {
    await initialize();

    try {
      if (email != null && password != null) {
        print('Logging in with email/password...');

        // Sign in with Firebase
        final user = await _authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        print('Login successful: ${user.username}');
        _cachedUser = user;
        return user;
      } else {
        print('Logging in as guest...');
        // Guest login - use local service
        return await _localService.loginUser();
      }
    } catch (e) {
      print('Login failed: $e');
      rethrow;
    }
  }

  /// Login as guest (local only)
  Future<app_user.User> loginAsGuest() async {
    await initialize();

    try {
      print('Logging in as guest...');
      final user = await _localService.loginUser();
      return user ?? app_user.User.defaultUser();
    } catch (e) {
      print('Guest login failed, creating default user: $e');
      return app_user.User.defaultUser();
    }
  }

  /// Update user data
  Future<void> updateUser(app_user.User user) async {
    await initialize();

    try {
      if (_authService.isLoggedIn) {
        // Update in Firebase
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.updateUser(firebaseUser.uid, user);
        _cachedUser = user;
      } else {
        // Update locally for guest users
        await _localService.saveCurrentUser(user);
      }
    } catch (e) {
      print('Error updating user: $e');
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

      _cachedUser = null;
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
    _cachedUser = null;
  }

  /// Get user preferences
  Future<app_user.UserPreferences?> getUserPreferences() async {
    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        return await _dbService.getUserPreferences(firebaseUser.uid);
      } else {
        // For guest users, return preferences from current user
        final user = await getCurrentUser();
        return user?.preferences;
      }
    } catch (e) {
      print('Error getting user preferences: $e');
      return null;
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences(app_user.UserPreferences preferences) async {
    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.saveUserPreferences(firebaseUser.uid, preferences);

        // Update cached user
        if (_cachedUser != null) {
          _cachedUser = _cachedUser!.copyWith(preferences: preferences);
        }
      } else {
        // For guest users, update the current user and save locally
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(preferences: preferences);
          await _localService.saveCurrentUser(updatedUser);
          _cachedUser = updatedUser;
        }
      }
    } catch (e) {
      print('Error saving user preferences: $e');
      rethrow;
    }
  }

  /// Get user progress
  Future<app_user.UserProgress?> getUserProgress() async {
    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        return await _dbService.getUserProgress(firebaseUser.uid);
      } else {
        // For guest users, return progress from current user
        final user = await getCurrentUser();
        return user?.progress;
      }
    } catch (e) {
      print('Error getting user progress: $e');
      return null;
    }
  }

  /// Save user progress
  Future<void> saveUserProgress(app_user.UserProgress progress) async {
    try {
      if (_authService.isLoggedIn) {
        final firebaseUser = _authService.currentFirebaseUser!;
        await _dbService.saveUserProgress(firebaseUser.uid, progress);

        // Update cached user
        if (_cachedUser != null) {
          _cachedUser = _cachedUser!.copyWith(progress: progress);
        }
      } else {
        // For guest users, update the current user and save locally
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(progress: progress);
          await _localService.saveCurrentUser(updatedUser);
          _cachedUser = updatedUser;
        }
      }
    } catch (e) {
      print('Error saving user progress: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      if (_authService.isLoggedIn) {
        await _authService.deleteAccount();
        _cachedUser = null;
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  /// Check for migration from local storage to Firebase
  Future<void> _checkForMigration() async {
    try {
      // If user is logged in to Firebase but we have local data, we might need to migrate
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
      // Don't throw here - migration is optional
    }
  }
}
