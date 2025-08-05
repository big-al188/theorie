// lib/services/firebase_config.dart - Environment-aware Firebase configuration
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for web platform with environment variable support
class FirebaseConfig {
  /// Get Firebase options from environment variables with fallbacks
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY', 
      defaultValue: 'AIzaSyBMSV6xCg43QFpOlMuCRRu0bBRyqOmV2rM'), // Your current key as fallback
    authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', 
      defaultValue: 'theorie-3ef8a.firebaseapp.com'),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', 
      defaultValue: 'theorie-3ef8a'),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', 
      defaultValue: 'theorie-3ef8a.firebasestorage.app'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', 
      defaultValue: '338181134596'),
    appId: const String.fromEnvironment('FIREBASE_APP_ID', 
      defaultValue: '1:338181134596:web:33d6319ea70205f6631851'),
    measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID', 
      defaultValue: 'G-FXHPYNH9Q4'),
  );

  /// Initialize Firebase with error handling
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: web,
      );
      
      if (kDebugMode) {
        print('🔥 Firebase initialized successfully');
        print('📍 Project ID: ${web.projectId}');
        print('🌍 Environment: ${AppConfig.environment}');
      }
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
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

/// Application configuration with environment variables
class AppConfig {
  static const String apiUrl = String.fromEnvironment('API_BASE_URL', 
    defaultValue: 'https://us-central1-theorie-3ef8a.cloudfunctions.net'); // Your Firebase Functions URL
  static const String environment = String.fromEnvironment('ENVIRONMENT', 
    defaultValue: 'development');
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', 
    defaultValue: kDebugMode ? 'pk_test_51Rs7HVILJ0OoLUiBc8PBRibh5acqX5EI2cI7D7Au1us6UcSZzF01hDXn9jo7F0Tv0x8B0V4ydH9pzcSGDqpQGYwg00tQapSRq4' : '');
  
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isTest => environment == 'test';
  
  /// Debug method to log configuration (never log secrets in production)
  static void logConfiguration() {
    if (kDebugMode) {
      print('🔧 App Configuration:');
      print('  • Environment: $environment');
      print('  • API URL: $apiUrl');
      print('  • Stripe Key: ${stripePublishableKey.isNotEmpty ? "✅ Configured (${stripePublishableKey.substring(0, 12)}...)" : "❌ Missing"}');
      print('  • Debug Mode: ${kDebugMode ? "ON" : "OFF"}');
      print('  • Firebase Project: ${FirebaseConfig.web.projectId}');
    }
  }
}

/// Environment-specific configuration (kept for backward compatibility)
class FirebaseEnvironment {
  static bool get isDevelopment => AppConfig.isDevelopment;
  static String get currentProjectId => FirebaseConfig.web.projectId;
  
  // Legacy constants
  static const String developmentProjectId = "theorie-3ef8a";
  static const String productionProjectId = "theorie-prod";
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