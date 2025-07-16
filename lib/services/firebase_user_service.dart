// lib/services/firebase_user_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user/user.dart' as app_user;
import '../models/user/user_progress.dart'; // Import the correct UserProgress class
import './firebase_auth_service.dart';
import './firebase_database_service.dart';
import './user_service.dart'; // Import existing service for migration

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
  final UserService _localService =
      UserService.instance; // For migration and fallback

  bool _isInitialized = false;
  app_user.User? _cachedUser;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local service for migration purposes
      await _localService.initialize();

      // Check for existing user and migration
      await _checkForMigration();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing Firebase User Service: $e');
      // Fallback to local service if Firebase fails
      await _localService.initialize();
      _isInitialized = true;
    }
  }

  /// Get current user (prioritize Firebase, fallback to local)
  Future<app_user.User?> getCurrentUser() async {
    await initialize();

    try {
      // Try Firebase first
      if (_authService.isLoggedIn) {
        _cachedUser = await _authService.currentUser;
        return _cachedUser;
      }

      // Fallback to local service for guest users
      return await _localService.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');
      // Fallback to local service
      return await _localService.getCurrentUser();
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
      // Register with Firebase
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        username: username,
        password: password,
      );

      _cachedUser = user;
      return user;
    } catch (e) {
      // Don't fallback to local service for registration
      // Registration should always use Firebase
      rethrow;
    }
  }

  /// Login user with Firebase
  Future<app_user.User?> loginUser({
    String? username,
    String? email,
    String? password,
  }) async {
    await initialize();

    try {
      // Handle guest login (local storage)
      if ((username?.isEmpty ?? true) &&
          (email?.isEmpty ?? true) &&
          (password?.isEmpty ?? true)) {
        return await loginAsGuest();
      }

      // Firebase login requires email and password
      if (email == null || password == null) {
        throw ArgumentError(
            'Email and password are required for Firebase login');
      }

      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _cachedUser = user;
      return user;
    } catch (e) {
      print('Error logging in user: $e');
      // For login failures, don't fallback automatically
      // Let the UI handle the error
      rethrow;
    }
  }

  /// Login as guest (uses local storage)
  Future<app_user.User> loginAsGuest() async {
    await initialize();

    try {
      final user = await _localService.loginAsGuest();
      _cachedUser = user;
      return user;
    } catch (e) {
      throw Exception('Failed to login as guest: ${e.toString()}');
    }
  }

  /// Save current user
  Future<void> saveCurrentUser(app_user.User user) async {
    await initialize();

    try {
      if (_authService.isLoggedIn && _authService.currentFirebaseUser != null) {
        // Save to Firebase
        await _dbService.updateUser(
            _authService.currentFirebaseUser!.uid, user);
      } else {
        // Save to local storage for guest users
        await _localService.saveCurrentUser(user);
      }

      _cachedUser = user;
    } catch (e) {
      print('Error saving current user: $e');
      // Always try to save locally as fallback
      await _localService.saveCurrentUser(user);
      _cachedUser = user;
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences(app_user.UserPreferences preferences) async {
    await initialize();

    try {
      if (_authService.isLoggedIn && _authService.currentFirebaseUser != null) {
        // Save to Firebase
        await _dbService.saveUserPreferences(
            _authService.currentFirebaseUser!.uid, preferences);
      }

      // Always save locally for caching/fallback
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(preferences: preferences);
        await _localService.saveCurrentUser(updatedUser);
        _cachedUser = updatedUser;
      }
    } catch (e) {
      print('Error saving user preferences: $e');
      // Fallback to local only
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(preferences: preferences);
        await _localService.saveCurrentUser(updatedUser);
        _cachedUser = updatedUser;
      }
    }
  }

  /// Save user progress
  Future<void> saveUserProgress(app_user.UserProgress progress) async {
    await initialize();

    try {
      if (_authService.isLoggedIn && _authService.currentFirebaseUser != null) {
        // Save to Firebase
        await _dbService.saveUserProgress(
            _authService.currentFirebaseUser!.uid, progress);
      }

      // Always save locally for caching/fallback
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(progress: progress);
        await _localService.saveCurrentUser(updatedUser);
        _cachedUser = updatedUser;
      }
    } catch (e) {
      print('Error saving user progress: $e');
      // Fallback to local only
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(progress: progress);
        await _localService.saveCurrentUser(updatedUser);
        _cachedUser = updatedUser;
      }
    }
  }

  /// Logout user
  Future<void> logout() async {
    await initialize();

    try {
      // Sign out from Firebase if logged in
      if (_authService.isLoggedIn) {
        await _authService.signOut();
      }

      // Clear local cache
      _cachedUser = null;

      // Note: We don't clear local storage entirely
      // This allows guest users to maintain their data
    } catch (e) {
      print('Error during logout: $e');
      // Still clear cache even if Firebase signout fails
      _cachedUser = null;
    }
  }

  /// Delete account (Firebase users only)
  Future<void> deleteAccount() async {
    await initialize();

    if (!_authService.isLoggedIn) {
      throw Exception('No authenticated user to delete');
    }

    try {
      await _authService.deleteAccount();
      _cachedUser = null;
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await initialize();
    await _authService.sendPasswordResetEmail(email);
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    await initialize();
    await _authService.sendEmailVerification();
  }

  /// Check if email is verified
  bool get isEmailVerified => _authService.isEmailVerified;

  /// Check if user is logged in with Firebase
  bool get isFirebaseUser => _authService.isLoggedIn;

  /// Check if user is guest (local only)
  Future<bool> get isGuestUser async {
    final user = await getCurrentUser();
    return user?.isDefaultUser ?? false;
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData() async {
    await initialize();

    try {
      if (_authService.isLoggedIn && _authService.currentFirebaseUser != null) {
        // Export from Firebase
        return await _dbService
            .exportUserData(_authService.currentFirebaseUser!.uid);
      } else {
        // Export from local storage
        return await _localService.exportUserData();
      }
    } catch (e) {
      // Fallback to local export
      return await _localService.exportUserData();
    }
  }

  /// Import user data
  Future<void> importUserData(Map<String, dynamic> data) async {
    await initialize();

    try {
      if (_authService.isLoggedIn && _authService.currentFirebaseUser != null) {
        // For Firebase users, we would need to implement import to Firebase
        // For now, just import to local storage
        await _localService.importUserData(data);
      } else {
        await _localService.importUserData(data);
      }
    } catch (e) {
      throw Exception('Failed to import user data: ${e.toString()}');
    }
  }

  /// Check for local data migration to Firebase
  Future<void> _checkForMigration() async {
    try {
      // If user is logged in with Firebase but has local data,
      // we could implement migration logic here

      if (_authService.isLoggedIn) {
        final localUser = await _localService.getCurrentUser();

        // If local user has significant data and is not just default user,
        // we could offer to migrate it to Firebase
        if (localUser != null &&
            !localUser.isDefaultUser &&
            localUser.progress.totalTopicsCompleted > 0) {
          print('Local user data found for potential migration');
          // TODO: Implement migration UI and logic
        }
      }
    } catch (e) {
      print('Error checking for migration: $e');
    }
  }

  /// Get auth state stream
  Stream<firebase_auth.User?> get authStateChanges =>
      _authService.authStateChanges;

  /// Clear cache (useful for testing)
  void clearCache() {
    _cachedUser = null;
  }
}
