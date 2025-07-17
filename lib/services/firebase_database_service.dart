// lib/services/firebase_database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/user.dart';
import '../models/user/user_preferences.dart';
import '../models/user/user_progress.dart';
import '../models/quiz/quiz_result.dart';
import '../models/quiz/quiz_session.dart';
import './firebase_config.dart';

/// Firebase Firestore Database Service for Separated User Models
/// Handles all database operations for user account data, preferences, and progress
/// Updated to work with the new separated model architecture
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

  /// User Account Operations

  /// Create a new user account with initial data
  Future<void> createUser(String userId, User user) async {
    try {
      print('Creating user account with ID: $userId');

      final batch = _firestore.batch();

      // Create user account document
      final userData = user.toJson();
      userData['firebaseUid'] = userId;
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['lastLoginAt'] = FieldValue.serverTimestamp();

      batch.set(_usersCollection.doc(userId), userData);

      // Create username document for secure validation
      batch.set(_usernamesCollection.doc(user.username), {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Committing user account creation batch...');
      await batch.commit();

      // Create initial user data documents (preferences and progress)
      print('Creating initial user data documents...');
      await _createInitialUserData(userId);

      print('User account creation completed successfully');
    } catch (e) {
      print('Error in createUser: $e');
      throw DatabaseException('Failed to create user account: ${e.toString()}');
    }
  }

  /// Repair missing user data for existing Firebase Auth users
  Future<User> repairUserData({
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
        return _convertFirestoreUserData(data);
      }

      // Extract username from email or use display name
      String baseUsername = displayName ?? email.split('@').first;
      String username = await _generateUniqueUsername(baseUsername);

      print('Generated unique username: $username');

      // Create new user object with Firebase UID as the ID
      final newUser = User.fromRegistration(
        username: username,
        email: email.toLowerCase().trim(),
        firebaseUid: firebaseUid,
      );

      print('Creating repaired user document...');
      await createUser(firebaseUid, newUser);

      print('User data repaired successfully for: $username');
      return newUser;
    } catch (e) {
      print('Failed to repair user data: $e');
      throw DatabaseException('Failed to repair user data: ${e.toString()}');
    }
  }

  /// Get user account by Firebase UID
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return _convertFirestoreUserData(data);
    } catch (e) {
      throw DatabaseException('Failed to get user account: ${e.toString()}');
    }
  }

  /// Update user account data
  Future<void> updateUser(String userId, User user) async {
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
      throw DatabaseException('Failed to update user account: ${e.toString()}');
    }
  }

  /// Delete user account and all associated data
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
      throw DatabaseException('Failed to delete user account: ${e.toString()}');
    }
  }

  /// User Preferences Operations

  /// Save user preferences
  Future<void> saveUserPreferences(
      String userId, UserPreferences preferences) async {
    try {
      await _userPreferencesCollection.doc(userId).set(
            {
              ...preferences.toJson(),
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      throw DatabaseException('Failed to save user preferences: ${e.toString()}');
    }
  }

  /// Get user preferences
  Future<UserPreferences?> getUserPreferences(String userId) async {
    try {
      final doc = await _userPreferencesCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserPreferences.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to get user preferences: ${e.toString()}');
    }
  }

  /// Update specific preference
  Future<void> updateUserPreference(
      String userId, String key, dynamic value) async {
    try {
      await _userPreferencesCollection.doc(userId).update({
        key: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DatabaseException('Failed to update user preference: ${e.toString()}');
    }
  }

  /// User Progress Operations

  /// Save user progress
  Future<void> saveUserProgress(String userId, UserProgress progress) async {
    try {
      await _userProgressCollection.doc(userId).set(
            {
              ...progress.toJson(),
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      throw DatabaseException('Failed to save user progress: ${e.toString()}');
    }
  }

  /// Get user progress
  Future<UserProgress?> getUserProgress(String userId) async {
    try {
      final doc = await _userProgressCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserProgress.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to get user progress: ${e.toString()}');
    }
  }

  /// Update specific progress data
  Future<void> updateProgressData(
      String userId, String key, dynamic value) async {
    try {
      await _userProgressCollection.doc(userId).update({
        key: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DatabaseException('Failed to update progress data: ${e.toString()}');
    }
  }

  /// Record quiz attempt and update progress
  Future<void> recordQuizAttempt(
    String userId,
    QuizAttempt attempt,
  ) async {
    try {
      final batch = _firestore.batch();

      // Get current progress
      final currentProgress = await getUserProgress(userId);
      if (currentProgress == null) {
        throw DatabaseException('User progress not found');
      }

      // Update progress with new attempt
      final updatedProgress = currentProgress.recordQuizAttempt(
        topicId: attempt.topicId,
        sectionId: attempt.sectionId,
        score: attempt.score,
        passed: attempt.passed,
        timeSpent: attempt.timeSpent,
        totalQuestions: attempt.totalQuestions,
        correctAnswers: attempt.correctAnswers,
        isTopicQuiz: attempt.isTopicQuiz,
      );

      // Save updated progress
      batch.set(
        _userProgressCollection.doc(userId),
        {
          ...updatedProgress.toJson(),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      throw DatabaseException('Failed to record quiz attempt: ${e.toString()}');
    }
  }

  /// Complete User Data Operations

  /// Get complete user data (account, preferences, progress)
  Future<CompleteUserData?> getCompleteUserData(String userId) async {
    try {
      final futures = await Future.wait([
        getUser(userId),
        getUserPreferences(userId),
        getUserProgress(userId),
      ]);

      final user = futures[0] as User?;
      final preferences = futures[1] as UserPreferences?;
      final progress = futures[2] as UserProgress?;

      if (user == null) return null;

      return CompleteUserData(
        user: user,
        preferences: preferences ?? UserPreferences.defaults(),
        progress: progress ?? UserProgress.empty(),
      );
    } catch (e) {
      throw DatabaseException('Failed to get complete user data: ${e.toString()}');
    }
  }

  /// Save complete user data
  Future<void> saveCompleteUserData(
      String userId, CompleteUserData userData) async {
    try {
      final batch = _firestore.batch();

      // Update user account
      batch.update(_usersCollection.doc(userId), {
        ...userData.user.toJson(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Update preferences
      batch.set(
        _userPreferencesCollection.doc(userId),
        {
          ...userData.preferences.toJson(),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Update progress
      batch.set(
        _userProgressCollection.doc(userId),
        {
          ...userData.progress.toJson(),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      throw DatabaseException('Failed to save complete user data: ${e.toString()}');
    }
  }

  /// Quiz Results Operations (updated for new models)

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

        return _createQuizResultFromData(data);
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to get quiz results: ${e.toString()}');
    }
  }

  /// Health Check and Diagnostic Operations

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

  /// Data Migration and Backup Operations

  /// Export user data for backup
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final completeData = await getCompleteUserData(userId);
      final quizResults = await getQuizResults(userId);

      return {
        'user': completeData?.user.toJson(),
        'preferences': completeData?.preferences.toJson(),
        'progress': completeData?.progress.toJson(),
        'quizResults': quizResults.map((r) => r.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw DatabaseException('Failed to export user data: ${e.toString()}');
    }
  }

  /// Username Management Operations

  /// Check if username is already taken
  Future<bool> isUsernameTaken(String username) async {
    try {
      final doc = await _usernamesCollection.doc(username).get();
      return doc.exists;
    } catch (e) {
      throw DatabaseException('Failed to check username: ${e.toString()}');
    }
  }

  /// Generate a unique username by appending numbers if needed
  Future<String> _generateUniqueUsername(String baseUsername) async {
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

    while (await isUsernameTaken(currentUsername)) {
      currentUsername = '${cleanUsername}_$counter';
      counter++;

      if (counter > 999) {
        currentUsername =
            'user${DateTime.now().millisecondsSinceEpoch % 10000}';
        break;
      }
    }

    return currentUsername;
  }

  /// Helper Methods

  /// Create initial user data documents
  Future<void> _createInitialUserData(String userId) async {
    try {
      print('Creating initial data for user: $userId');

      final batch = _firestore.batch();

      // Create preferences document
      batch.set(
        _userPreferencesCollection.doc(userId),
        {
          ...UserPreferences.defaults().toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Create progress document
      batch.set(
        _userProgressCollection.doc(userId),
        {
          ...UserProgress.empty().toJson(),
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

  /// Convert Firestore data to User model
  User _convertFirestoreUserData(Map<String, dynamic> data) {
    // Convert Firestore timestamps to DateTime strings
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] =
          (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['lastLoginAt'] is Timestamp) {
      data['lastLoginAt'] =
          (data['lastLoginAt'] as Timestamp).toDate().toIso8601String();
    }

    return User.fromJson(data);
  }

  /// Temporary method to create QuizResult from data
  QuizResult _createQuizResultFromData(Map<String, dynamic> data) {
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
      questionResults: [],
      topicPerformance: [],
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
      await _firestore.settings.toString();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Container for complete user data
class CompleteUserData {
  final User user;
  final UserPreferences preferences;
  final UserProgress progress;

  const CompleteUserData({
    required this.user,
    required this.preferences,
    required this.progress,
  });

  /// Create copy with updated user data
  CompleteUserData copyWith({
    User? user,
    UserPreferences? preferences,
    UserProgress? progress,
  }) {
    return CompleteUserData(
      user: user ?? this.user,
      preferences: preferences ?? this.preferences,
      progress: progress ?? this.progress,
    );
  }
}

/// Custom database exception
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => message;
}