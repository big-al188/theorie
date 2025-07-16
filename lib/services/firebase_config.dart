// lib/services/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for web platform
class FirebaseConfig {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "your-api-key-here",
    authDomain: "your-project-id.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project-id.appspot.com",
    messagingSenderId: "your-sender-id",
    appId: "your-app-id",
    measurementId: "your-measurement-id", // Optional for analytics
  );

  /// Initialize Firebase with error handling
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: web,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Check if Firebase is already initialized
  static bool get isInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Environment-specific configuration
class FirebaseEnvironment {
  static const bool isDevelopment = true; // Set to false for production

  static const String developmentProjectId = "theorie-dev";
  static const String productionProjectId = "theorie-prod";

  static String get currentProjectId =>
      isDevelopment ? developmentProjectId : productionProjectId;
}

/// Firebase collection and document naming conventions
class FirebaseCollections {
  static const String users = 'users';
  static const String userProgress = 'user_progress';
  static const String quizResults = 'quiz_results';
  static const String userPreferences = 'user_preferences';

  /// Subcollections
  static const String quizSessions = 'quiz_sessions';
  static const String learningProgress = 'learning_progress';
}

/// Firebase security rules helper
class FirebaseRules {
  /// Generate security rules for Firestore
  static String get firestoreRules => '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to user's subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // User progress data
    match /user_progress/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Quiz results
    match /quiz_results/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /quiz_sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // User preferences
    match /user_preferences/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
''';

  /// Generate authentication rules
  static String get authRules => '''
// Authentication rules
- Email/password authentication enabled
- Email verification required
- Password reset enabled
- Anonymous authentication disabled for security
''';
}
