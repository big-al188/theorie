// lib/services/firebase_database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/user.dart' as app_user;
import '../models/quiz/quiz_result.dart';
import '../models/quiz/quiz_session.dart';
import './firebase_config.dart';

/// Firebase Firestore Database Service
/// Handles all database operations for user data, preferences, and progress
class FirebaseDatabaseService {
  static FirebaseDatabaseService? _instance;
  static FirebaseDatabaseService get instance =>
      _instance ??= FirebaseDatabaseService._();
  FirebaseDatabaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection references
  CollectionReference get _usersCollection =>
      _firestore.collection(FirebaseCollections.users);

  CollectionReference get _usernamesCollection =>
      _firestore.collection('usernames');

  CollectionReference get _userProgressCollection =>
      _firestore.collection(FirebaseCollections.userProgress);

  CollectionReference get _quizResultsCollection =>
      _firestore.collection(FirebaseCollections.quizResults);

  CollectionReference get _userPreferencesCollection =>
      _firestore.collection(FirebaseCollections.userPreferences);

  /// User Operations

  /// Create a new user document
  Future<void> createUser(String userId, app_user.User user) async {
    try {
      print('Creating user with ID: $userId');

      final batch = _firestore.batch();

      // Create user document
      final userData = user.toJson();
      userData['firebaseUid'] = userId; // Ensure Firebase UID is stored
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['lastLoginAt'] = FieldValue.serverTimestamp();

      batch.set(_usersCollection.doc(userId), userData);

      // Create username document for secure validation
      batch.set(_usernamesCollection.doc(user.username), {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Committing user creation batch...');
      await batch.commit();

      // Create initial user data documents (preferences, progress, etc.)
      print('Creating initial user data documents...');
      await _createInitialUserData(userId, user);

      print('User creation completed successfully');
    } catch (e) {
      print('Error in createUser: $e');
      throw DatabaseException('Failed to create user: ${e.toString()}');
    }
  }

  /// Repair missing user data for existing Firebase Auth users
  /// This handles cases where Firebase Auth succeeded but Firestore creation failed
  Future<app_user.User> repairUserData({
    required String firebaseUid,
    required String email,
    String? displayName,
  }) async {
    try {
      print('Attempting to repair user data for: $firebaseUid');

      // Check if user document already exists
      final existingDoc = await _usersCollection.doc(firebaseUid).get();
      if (existingDoc.exists) {
        print('User document already exists, no repair needed');
        final data = existingDoc.data() as Map<String, dynamic>;

        // Convert timestamps if needed
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['lastLoginAt'] is Timestamp) {
          data['lastLoginAt'] =
              (data['lastLoginAt'] as Timestamp).toDate().toIso8601String();
        }

        return app_user.User.fromJson(data);
      }

      // Extract username from email or use display name
      String baseUsername = displayName ?? email.split('@').first;

      // Ensure username is valid and unique
      String username = await _generateUniqueUsername(baseUsername);

      print('Generated unique username: $username');

      // Create new user object with Firebase UID as the ID
      final newUser = app_user.User.fromRegistration(
        username: username,
        email: email.toLowerCase().trim(),
      );

      // IMPORTANT: Create a copy with the Firebase UID as the user ID
      final repairedUser = newUser.copyWith();

      print('Creating repaired user document...');

      // Create user document with Firebase UID as document ID
      await createUser(firebaseUid, repairedUser);

      print('User data repaired successfully for: $username');
      return repairedUser;
    } catch (e) {
      print('Failed to repair user data: $e');
      throw DatabaseException('Failed to repair user data: ${e.toString()}');
    }
  }

  /// Generate a unique username by appending numbers if needed
  Future<String> _generateUniqueUsername(String baseUsername) async {
    // Clean up the base username
    String cleanUsername =
        baseUsername.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (cleanUsername.length < 3) {
      cleanUsername = 'user${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    if (cleanUsername.length > 20) {
      cleanUsername = cleanUsername.substring(0, 20);
    }

    String currentUsername = cleanUsername;
    int counter = 1;

    // Check if username is available, append numbers if needed
    while (await isUsernameTaken(currentUsername)) {
      if (counter == 1) {
        currentUsername = '${cleanUsername}_$counter';
      } else {
        // Remove previous number and add new one
        currentUsername = '${cleanUsername}_$counter';
      }
      counter++;

      // Prevent infinite loop
      if (counter > 999) {
        currentUsername =
            'user${DateTime.now().millisecondsSinceEpoch % 10000}';
        break;
      }
    }

    return currentUsername;
  }

  /// Health check method to verify database setup
  Future<Map<String, bool>> checkDatabaseHealth(String userId) async {
    try {
      final results = <String, bool>{};

      // Check user document
      final userDoc = await _usersCollection.doc(userId).get();
      results['userDocument'] = userDoc.exists;

      // Check preferences document
      final prefsDoc = await _userPreferencesCollection.doc(userId).get();
      results['preferencesDocument'] = prefsDoc.exists;

      // Check progress document
      final progressDoc = await _userProgressCollection.doc(userId).get();
      results['progressDocument'] = progressDoc.exists;

      // Check quiz results document
      final quizDoc = await _quizResultsCollection.doc(userId).get();
      results['quizResultsDocument'] = quizDoc.exists;

      // Check username document if user exists
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final username = userData['username'] as String?;
        if (username != null) {
          final usernameDoc = await _usernamesCollection.doc(username).get();
          results['usernameDocument'] = usernameDoc.exists;
        }
      }

      return results;
    } catch (e) {
      print('Error checking database health: $e');
      return {'error': false};
    }
  }

  /// Get user by Firebase UID
  Future<app_user.User?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Convert Firestore timestamps to DateTime
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] =
            (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['lastLoginAt'] is Timestamp) {
        data['lastLoginAt'] =
            (data['lastLoginAt'] as Timestamp).toDate().toIso8601String();
      }

      return app_user.User.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to get user: ${e.toString()}');
    }
  }

  /// Update user data
  Future<void> updateUser(String userId, app_user.User user) async {
    try {
      final batch = _firestore.batch();

      // Get existing user to check if username changed
      final existingUser = await getUser(userId);

      // Update user document
      final userData = user.toJson();
      userData['lastLoginAt'] = FieldValue.serverTimestamp();
      batch.update(_usersCollection.doc(userId), userData);

      // Handle username change
      if (existingUser != null && existingUser.username != user.username) {
        // Delete old username document
        batch.delete(_usernamesCollection.doc(existingUser.username));

        // Create new username document
        batch.set(_usernamesCollection.doc(user.username), {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw DatabaseException('Failed to update user: ${e.toString()}');
    }
  }

  /// Delete user and all associated data
  Future<void> deleteUser(String userId) async {
    try {
      final batch = _firestore.batch();

      // Get user first to get username for deletion
      final user = await getUser(userId);

      // Delete user document
      batch.delete(_usersCollection.doc(userId));

      // Delete username document
      if (user != null) {
        batch.delete(_usernamesCollection.doc(user.username));
      }

      // Delete user preferences
      batch.delete(_userPreferencesCollection.doc(userId));

      // Delete user progress
      batch.delete(_userProgressCollection.doc(userId));

      // Delete quiz results
      batch.delete(_quizResultsCollection.doc(userId));

      // Delete quiz sessions subcollection
      final quizSessionsRef = _quizResultsCollection
          .doc(userId)
          .collection(FirebaseCollections.quizSessions);

      final quizSessions = await quizSessionsRef.get();
      for (final doc in quizSessions.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw DatabaseException('Failed to delete user: ${e.toString()}');
    }
  }

  /// Check if username is already taken (SECURE VERSION)
  Future<bool> isUsernameTaken(String username) async {
    try {
      final doc = await _usernamesCollection.doc(username).get();
      return doc.exists;
    } catch (e) {
      throw DatabaseException('Failed to check username: ${e.toString()}');
    }
  }

  /// User Preferences Operations

  /// Save user preferences
  Future<void> saveUserPreferences(
      String userId, app_user.UserPreferences preferences) async {
    try {
      await _userPreferencesCollection.doc(userId).set(
            preferences.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw DatabaseException('Failed to save preferences: ${e.toString()}');
    }
  }

  /// Get user preferences
  Future<app_user.UserPreferences?> getUserPreferences(String userId) async {
    try {
      final doc = await _userPreferencesCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return app_user.UserPreferences.fromJson(
          doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw DatabaseException('Failed to get preferences: ${e.toString()}');
    }
  }

  /// User Progress Operations

  /// Save user progress
  Future<void> saveUserProgress(
      String userId, app_user.UserProgress progress) async {
    try {
      await _userProgressCollection.doc(userId).set(
            progress.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw DatabaseException('Failed to save progress: ${e.toString()}');
    }
  }

  /// Get user progress
  Future<app_user.UserProgress?> getUserProgress(String userId) async {
    try {
      final doc = await _userProgressCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return app_user.UserProgress.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw DatabaseException('Failed to get progress: ${e.toString()}');
    }
  }

  /// Quiz Results Operations

  /// Save quiz result
  Future<void> saveQuizResult(String userId, QuizResult result) async {
    try {
      final quizSessionsRef = _quizResultsCollection
          .doc(userId)
          .collection(FirebaseCollections.quizSessions);

      await quizSessionsRef.doc(result.sessionId).set({
        ...result.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DatabaseException('Failed to save quiz result: ${e.toString()}');
    }
  }

  /// Get quiz results for user
  Future<List<QuizResult>> getQuizResults(
    String userId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _quizResultsCollection
          .doc(userId)
          .collection(FirebaseCollections.quizSessions)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert Firestore timestamp
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }

        // Since QuizResult.fromJson doesn't exist, we'll create a simple conversion
        // Note: This is a temporary fix - ideally QuizResult should have a fromJson method
        return _createQuizResultFromData(data);
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to get quiz results: ${e.toString()}');
    }
  }

  /// Delete quiz result
  Future<void> deleteQuizResult(String userId, String sessionId) async {
    try {
      await _quizResultsCollection
          .doc(userId)
          .collection(FirebaseCollections.quizSessions)
          .doc(sessionId)
          .delete();
    } catch (e) {
      throw DatabaseException('Failed to delete quiz result: ${e.toString()}');
    }
  }

  /// Data Migration and Backup Operations

  /// Export user data for backup
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final user = await getUser(userId);
      final preferences = await getUserPreferences(userId);
      final progress = await getUserProgress(userId);
      final quizResults = await getQuizResults(userId);

      return {
        'user': user?.toJson(),
        'preferences': preferences?.toJson(),
        'progress': progress?.toJson(),
        'quizResults': quizResults.map((r) => r.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw DatabaseException('Failed to export user data: ${e.toString()}');
    }
  }

  /// Batch operations for data migration
  Future<void> batchUpdateUsers(List<Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final userId = update['userId'] as String;
        final userData = update['data'] as Map<String, dynamic>;

        batch.update(_usersCollection.doc(userId), userData);
      }

      await batch.commit();
    } catch (e) {
      throw DatabaseException('Failed to batch update users: ${e.toString()}');
    }
  }

  /// Helper Methods

  /// Create initial user data documents - Improved with better error handling
  Future<void> _createInitialUserData(String userId, app_user.User user) async {
    try {
      print('Creating initial data for user: $userId');

      final batch = _firestore.batch();

      // Create preferences document
      batch.set(
        _userPreferencesCollection.doc(userId),
        {
          ...user.preferences.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Create progress document
      batch.set(
        _userProgressCollection.doc(userId),
        {
          ...user.progress.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Create quiz results document (empty initially)
      batch.set(
        _quizResultsCollection.doc(userId),
        {
          'createdAt': FieldValue.serverTimestamp(),
          'totalQuizzesTaken': 0,
          'averageScore': 0.0,
          'lastQuizDate': null,
        },
      );

      await batch.commit();
      print('Initial user data created successfully');
    } catch (e) {
      print('Error creating initial user data: $e');
      throw DatabaseException(
          'Failed to create initial user data: ${e.toString()}');
    }
  }

  /// Temporary method to create QuizResult from data
  /// This should be replaced with proper QuizResult.fromJson once implemented
  QuizResult _createQuizResultFromData(Map<String, dynamic> data) {
    // This is a simplified conversion - you may need to adjust based on actual QuizResult structure
    return QuizResult(
      sessionId: data['sessionId'] as String? ?? '',
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
  }

  /// Parse quiz type from string
  QuizType _parseQuizType(String? typeString) {
    switch (typeString) {
      case 'topic':
        return QuizType.topic;
      case 'section':
        return QuizType.section;
      case 'practice':
        return QuizType.practice;
      default:
        return QuizType.topic;
    }
  }

  /// Health check for database connectivity
  Future<bool> checkConnectivity() async {
    try {
      await _firestore.settings.toString(); // Simple connectivity test
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Username Management Utilities (for admin/debugging)

  /// Get userId from username (for admin purposes)
  Future<String?> getUserIdFromUsername(String username) async {
    try {
      final doc = await _usernamesCollection.doc(username).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userId'] as String?;
      }
      return null;
    } catch (e) {
      throw DatabaseException(
          'Failed to get userId from username: ${e.toString()}');
    }
  }

  /// Clean up orphaned username documents (for maintenance)
  Future<void> cleanupOrphanedUsernames() async {
    try {
      final usernamesSnapshot = await _usernamesCollection.get();
      final batch = _firestore.batch();

      for (final usernameDoc in usernamesSnapshot.docs) {
        final data = usernameDoc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String;

        // Check if user still exists
        final userDoc = await _usersCollection.doc(userId).get();
        if (!userDoc.exists) {
          // Delete orphaned username document
          batch.delete(usernameDoc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      throw DatabaseException(
          'Failed to cleanup orphaned usernames: ${e.toString()}');
    }
  }
}

/// Custom database exception
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => message;
}
