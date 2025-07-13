// lib/services/user_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user.dart';

/// Service for managing user data and persistence
class UserService {
  static const String _currentUserKey = 'current_user';
  static const String _usersKey = 'all_users';
  static const String _lastLoginKey = 'last_login_user_id';
  static const String _defaultUserKey = 'default_user_persistent';

  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  UserService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _ensureDefaultUserExists();
  }

  /// Ensure a persistent default user exists
  Future<void> _ensureDefaultUserExists() async {
    // Don't call initialize() here to avoid recursion
    // _prefs should already be initialized when this is called
    
    final existingDefaultUser = _prefs!.getString(_defaultUserKey);
    if (existingDefaultUser == null) {
      // Create and save a persistent default user
      final defaultUser = User.defaultUser();
      await _prefs!.setString(_defaultUserKey, jsonEncode(defaultUser.toJson()));
    }
  }

  /// Get the persistent default user
  Future<User> _getDefaultUser() async {
    // Don't call initialize() here to avoid recursion
    // _prefs should already be initialized when this is called
    
    final defaultUserJson = _prefs!.getString(_defaultUserKey);
    if (defaultUserJson != null) {
      try {
        final userData = jsonDecode(defaultUserJson) as Map<String, dynamic>;
        return User.fromJson(userData);
      } catch (e) {
        // If corrupted, create a new default user
        final defaultUser = User.defaultUser();
        await _prefs!.setString(_defaultUserKey, jsonEncode(defaultUser.toJson()));
        return defaultUser;
      }
    }
    
    // Fallback - create new default user
    final defaultUser = User.defaultUser();
    await _prefs!.setString(_defaultUserKey, jsonEncode(defaultUser.toJson()));
    return defaultUser;
  }

  /// Get current logged-in user
  Future<User?> getCurrentUser() async {
    await initialize();
    
    final userJson = _prefs!.getString(_currentUserKey);
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (e) {
        // Clear corrupted data
        await _prefs!.remove(_currentUserKey);
        return null;
      }
    }
    return null;
  }

  /// Save current user
  Future<void> saveCurrentUser(User user) async {
    await initialize();
    
    // Update last login time
    final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
    
    // Save current user
    await _prefs!.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
    
    // Save to users list (but only if not default user)
    if (!updatedUser.isDefaultUser) {
      await _saveUserToList(updatedUser);
    }
    
    // Update default user if this is a default user with changes
    if (updatedUser.isDefaultUser) {
      await _prefs!.setString(_defaultUserKey, jsonEncode(updatedUser.toJson()));
    }
    
    // Update last login user ID
    await _prefs!.setString(_lastLoginKey, updatedUser.id);
  }

  /// Register a new user
  Future<User> registerUser({
    required String username,
    required String email,
  }) async {
    await initialize();
    
    // Check if user already exists
    final existingUsers = await _getAllUsers();
    final existingUser = existingUsers.values
        .where((user) => user.email.toLowerCase() == email.toLowerCase())
        .firstOrNull;
    
    if (existingUser != null) {
      throw UserServiceException('User with this email already exists');
    }
    
    // Create new user
    final newUser = User.fromRegistration(
      username: username,
      email: email,
    );
    
    // Save as current user
    await saveCurrentUser(newUser);
    
    return newUser;
  }

  /// Login with username or email, or get default user for guest login
  Future<User?> loginUser({
    String? username,
    String? email,
  }) async {
    await initialize();
    
    // Handle guest login (empty or null credentials)
    if ((username?.isEmpty ?? true) && (email?.isEmpty ?? true)) {
      final defaultUser = await _getDefaultUser();
      await saveCurrentUser(defaultUser);
      return defaultUser;
    }
    
    final existingUsers = await _getAllUsers();
    
    User? foundUser;
    for (final user in existingUsers.values) {
      if (username != null && user.username.toLowerCase() == username.toLowerCase()) {
        foundUser = user;
        break;
      }
      if (email != null && user.email.toLowerCase() == email.toLowerCase()) {
        foundUser = user;
        break;
      }
    }
    
    if (foundUser != null) {
      await saveCurrentUser(foundUser);
      return foundUser;
    }
    
    return null;
  }

  /// Login as guest - explicit method for guest login
  Future<User> loginAsGuest() async {
    final defaultUser = await _getDefaultUser();
    await saveCurrentUser(defaultUser);
    return defaultUser;
  }

  /// Logout current user
  Future<void> logout() async {
    await initialize();
    await _prefs!.remove(_currentUserKey);
  }

  /// Update user preferences
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(preferences: preferences);
      await saveCurrentUser(updatedUser);
    }
  }

  /// Update user progress
  Future<void> updateUserProgress(UserProgress progress) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(progress: progress);
      await saveCurrentUser(updatedUser);
    }
  }

  /// Complete a topic quiz
  Future<void> completeTopicQuiz(String topicId, bool passed) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedProgress = currentUser.progress.completeTopicQuiz(topicId, passed);
      await updateUserProgress(updatedProgress);
    }
  }

  /// Complete a section quiz
  Future<void> completeSectionQuiz(String sectionId, bool passed) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedProgress = currentUser.progress.completeSectionQuiz(sectionId, passed);
      await updateUserProgress(updatedProgress);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Get last login user ID
  Future<String?> getLastLoginUserId() async {
    await initialize();
    return _prefs!.getString(_lastLoginKey);
  }

  /// Delete user account
  Future<void> deleteUser(String userId) async {
    await initialize();
    
    final users = await _getAllUsers();
    users.remove(userId);
    
    await _prefs!.setString(_usersKey, jsonEncode(
      users.map((key, value) => MapEntry(key, value.toJson()))
    ));
    
    // If deleting current user, logout
    final currentUser = await getCurrentUser();
    if (currentUser?.id == userId) {
      await logout();
    }
  }

  /// Get all registered users (for admin purposes)
  Future<List<User>> getAllRegisteredUsers() async {
    final users = await _getAllUsers();
    return users.values.where((user) => !user.isDefaultUser).toList();
  }

  /// Clear all user data (for testing/reset)
  Future<void> clearAllUserData() async {
    await initialize();
    await _prefs!.remove(_currentUserKey);
    await _prefs!.remove(_usersKey);
    await _prefs!.remove(_lastLoginKey);
    await _prefs!.remove(_defaultUserKey);
    await _ensureDefaultUserExists(); // Recreate default user
  }

  /// Private method to get all users
  Future<Map<String, User>> _getAllUsers() async {
    // Don't call initialize() here since this is called from other methods
    // that already call initialize()
    
    final usersJson = _prefs!.getString(_usersKey);
    if (usersJson != null) {
      try {
        final usersMap = jsonDecode(usersJson) as Map<String, dynamic>;
        return usersMap.map((key, value) => 
            MapEntry(key, User.fromJson(value as Map<String, dynamic>)));
      } catch (e) {
        // Clear corrupted data
        await _prefs!.remove(_usersKey);
        return {};
      }
    }
    return {};
  }

  /// Private method to save user to list
  Future<void> _saveUserToList(User user) async {
    final users = await _getAllUsers();
    users[user.id] = user;
    
    await _prefs!.setString(_usersKey, jsonEncode(
      users.map((key, value) => MapEntry(key, value.toJson()))
    ));
  }

  /// Export user data (for backup)
  Future<Map<String, dynamic>> exportUserData() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw UserServiceException('No user logged in');
    }
    
    return {
      'user': currentUser.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Import user data (for restore)
  Future<void> importUserData(Map<String, dynamic> data) async {
    try {
      final userData = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);
      await saveCurrentUser(user);
    } catch (e) {
      throw UserServiceException('Invalid user data format');
    }
  }
}

/// Exception class for user service errors
class UserServiceException implements Exception {
  final String message;
  const UserServiceException(this.message);
  
  @override
  String toString() => 'UserServiceException: $message';
}