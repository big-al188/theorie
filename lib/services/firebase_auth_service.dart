// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/user.dart' as app_user;
import './firebase_config.dart';
import './firebase_database_service.dart';

/// Firebase Authentication Service
/// Handles user registration, login, logout, and auth state management
class FirebaseAuthService {
  static FirebaseAuthService? _instance;
  static FirebaseAuthService get instance =>
      _instance ??= FirebaseAuthService._();
  FirebaseAuthService._();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService.instance;

  /// Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  /// Get current app user
  Future<app_user.User?> get currentUser async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;

    try {
      return await _dbService.getUser(firebaseUser.uid);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => currentFirebaseUser != null;

  /// Auth state stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user with email and password
  Future<app_user.User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        throw AuthException('All fields are required');
      }

      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters');
      }

      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }

      if (!_isValidUsername(username)) {
        throw AuthException(
            'Username must be 3-20 characters and contain only letters, numbers, and underscores');
      }

      // Check if username is already taken
      final isUsernameTaken = await _dbService.isUsernameTaken(username);
      if (isUsernameTaken) {
        throw AuthException('Username is already taken');
      }

      // Create Firebase user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Failed to create user account');
      }

      // Update Firebase user profile
      await credential.user!.updateDisplayName(username);

      // Create app user
      final appUser = app_user.User.fromRegistration(
        username: username,
        email: email.trim().toLowerCase(),
      );

      // Save user to Firestore with Firebase UID as document ID
      await _dbService.createUser(credential.user!.uid, appUser);

      // Send email verification
      await credential.user!.sendEmailVerification();

      return appUser.copyWith();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<app_user.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      // Sign in with Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Sign in failed');
      }

      // Get user from Firestore
      final appUser = await _dbService.getUser(credential.user!.uid);
      if (appUser == null) {
        throw AuthException('User data not found');
      }

      // Update last login time
      final updatedUser = appUser.copyWith(lastLoginAt: DateTime.now());
      await _dbService.updateUser(credential.user!.uid, updatedUser);

      return updatedUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) {
        throw AuthException('Email is required');
      }

      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to send reset email: ${e.toString()}');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) {
        throw AuthException('No user logged in');
      }

      if (user.emailVerified) {
        throw AuthException('Email is already verified');
      }

      await user.sendEmailVerification();
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to send verification email: ${e.toString()}');
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => currentFirebaseUser?.emailVerified ?? false;

  /// Reload user to check verification status
  Future<void> reloadUser() async {
    try {
      await currentFirebaseUser?.reload();
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) {
        throw AuthException('No user logged in');
      }

      // Delete user data from Firestore
      await _dbService.deleteUser(user.uid);

      // Delete Firebase user
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentFirebaseUser;
      if (user == null) {
        throw AuthException('No user logged in');
      }

      if (newPassword.length < 6) {
        throw AuthException('Password must be at least 6 characters');
      }

      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      throw AuthException('Failed to update password: ${e.toString()}');
    }
  }

  /// Helper methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to complete this action';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}

/// Custom authentication exception
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
