# Persistence Integration Guide

## Overview
This guide covers the complete persistence architecture for the Theorie app, including local storage, cloud synchronization, and best practices for data management. The app uses a hybrid approach combining SharedPreferences for local storage and Firebase Firestore for cloud synchronization.

## Architecture Overview

### Storage Layers
1. **Local Storage** (SharedPreferences) - Primary storage for offline functionality
2. **Cloud Storage** (Firebase Firestore) - Secondary storage for authenticated users
3. **Memory Cache** - Runtime cache for frequently accessed data

### Data Flow
```
User Action → Controller → Model Update → Local Storage → Cloud Sync (if authenticated)
```

## Local Storage with SharedPreferences

### Core Service: UserService
Location: `lib/services/user_service.dart`

#### Key Methods
```dart
// Initialize service
await UserService.instance.initialize();

// Save current user
await UserService.instance.saveCurrentUser(user);

// Get current user
final user = await UserService.instance.getCurrentUser();

// Update user progress
await UserService.instance.updateUserProgress(progress);

// Export/Import data
final data = await UserService.instance.exportUserData();
await UserService.instance.importUserData(data);
```

#### Storage Keys
```dart
static const String _currentUserKey = 'current_user';
static const String _usersKey = 'all_users';
static const String _lastLoginKey = 'last_login_user_id';
static const String _defaultUserKey = 'default_user_persistent';
```

### Data Serialization
All data is stored as JSON strings using `jsonEncode()` and `jsonDecode()`:

```dart
// Save user data
await _prefs.setString(_currentUserKey, jsonEncode(user.toJson()));

// Load user data
final userJson = _prefs.getString(_currentUserKey);
final user = User.fromJson(jsonDecode(userJson));
```

## Cloud Storage with Firebase

### Core Service: FirebaseUserService
Location: `lib/services/firebase_user_service.dart`

#### Authentication Integration
```dart
// Sign in with email/password
await FirebaseUserService.instance.signInWithEmailPassword(email, password);

// Sign out
await FirebaseUserService.instance.signOut();

// Check authentication status
final isLoggedIn = FirebaseUserService.instance.isLoggedIn;
```

#### Data Synchronization
```dart
// Save user progress to cloud
await FirebaseUserService.instance.saveUserProgress(progress);

// Get user progress from cloud
final progress = await FirebaseUserService.instance.getUserProgress();

// Save user preferences to cloud
await FirebaseUserService.instance.saveUserPreferences(preferences);
```

### Firebase Database Service
Location: `lib/services/firebase_database_service.dart`

#### Collection Structure
```
users/
  {userId}/
    profile: UserProfile
    preferences: UserPreferences
    progress: UserProgress
    quizResults/
      {sessionId}: QuizResult
```

#### Core Operations
```dart
// Save user data
await FirebaseDatabaseService.instance.saveUserProfile(userId, profile);
await FirebaseDatabaseService.instance.saveUserPreferences(userId, preferences);
await FirebaseDatabaseService.instance.saveUserProgress(userId, progress);

// Retrieve user data
final profile = await FirebaseDatabaseService.instance.getUserProfile(userId);
final preferences = await FirebaseDatabaseService.instance.getUserPreferences(userId);
final progress = await FirebaseDatabaseService.instance.getUserProgress(userId);
```

## Progress Tracking Integration

### Core Service: ProgressTrackingService
Location: `lib/services/progress_tracking_service.dart`

#### Key Features
- **Offline-First**: Always saves locally first, then syncs to cloud
- **Periodic Sync**: Automatic synchronization every 2 minutes
- **Conflict Resolution**: Smart handling of data conflicts
- **Error Recovery**: Retry mechanisms for failed sync operations

#### Core Methods
```dart
// Initialize service
await ProgressTrackingService.instance.initialize();

// Update topic progress
await ProgressTrackingService.instance.updateTopicProgress(
  topicId: 'scales_major',
  passed: true,
  sectionId: 'fundamentals'
);

// Update section progress
await ProgressTrackingService.instance.updateSectionProgress(
  sectionId: 'fundamentals',
  passed: true
);

// Get current progress
final progress = await ProgressTrackingService.instance.getCurrentProgress();
```

#### Sync Strategy
```dart
// Periodic sync timer
Timer.periodic(Duration(minutes: 2), (timer) {
  _syncPendingChanges();
});

// Sync queue management
final List<Map<String, dynamic>> _pendingSyncQueue = [];

// Add to sync queue
_pendingSyncQueue.add({
  'type': 'topic_progress',
  'topicId': topicId,
  'passed': passed,
  'timestamp': DateTime.now().toIso8601String(),
});
```

## Data Models and Serialization

### User Model
Location: `lib/models/user/user.dart`

```dart
class User {
  final String id;
  final String email;
  final String displayName;
  final UserPreferences preferences;
  final UserProgress progress;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  // Serialization methods
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'preferences': preferences.toJson(),
    'progress': progress.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    displayName: json['displayName'],
    preferences: UserPreferences.fromJson(json['preferences']),
    progress: UserProgress.fromJson(json['progress']),
    createdAt: DateTime.parse(json['createdAt']),
    lastLoginAt: DateTime.parse(json['lastLoginAt']),
  );
}
```

### UserProgress Model
Location: `lib/models/user/user_progress.dart`

```dart
class UserProgress {
  final Set<String> completedTopics;
  final Map<String, SectionProgress> sectionProgress;
  final List<QuizResult> quizHistory;
  final DateTime lastUpdated;

  // Serialization methods
  Map<String, dynamic> toJson() => {
    'completedTopics': completedTopics.toList(),
    'sectionProgress': sectionProgress.map((k, v) => MapEntry(k, v.toJson())),
    'quizHistory': quizHistory.map((q) => q.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
    completedTopics: Set<String>.from(json['completedTopics'] ?? []),
    sectionProgress: (json['sectionProgress'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, SectionProgress.fromJson(v))),
    quizHistory: (json['quizHistory'] as List<dynamic>? ?? [])
        .map((q) => QuizResult.fromJson(q))
        .toList(),
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}
```

## Best Practices

### 1. Error Handling
Always wrap persistence operations in try-catch blocks:

```dart
Future<void> saveUserData(User user) async {
  try {
    await _prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  } catch (e) {
    debugPrint('Error saving user data: $e');
    // Handle error appropriately
    rethrow;
  }
}
```

### 2. Data Validation
Validate data before saving:

```dart
Future<void> saveUserProgress(UserProgress progress) async {
  if (progress.completedTopics.isEmpty && progress.sectionProgress.isEmpty) {
    throw ArgumentError('Progress cannot be empty');
  }
  
  // Validate topic IDs
  for (final topicId in progress.completedTopics) {
    if (topicId.isEmpty) {
      throw ArgumentError('Topic ID cannot be empty');
    }
  }
  
  // Proceed with saving
  await _saveProgressToStorage(progress);
}
```

### 3. Batch Operations
For multiple updates, use batch operations:

```dart
Future<void> updateMultipleTopics(List<String> topicIds, bool passed) async {
  final batch = <String, dynamic>{};
  
  for (final topicId in topicIds) {
    batch[topicId] = {
      'passed': passed,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  await _saveBatchUpdate(batch);
}
```

### 4. Offline Support
Always implement offline-first approach:

```dart
Future<void> updateProgress(String topicId, bool passed) async {
  // 1. Save locally first
  await _saveProgressLocally(topicId, passed);
  
  // 2. Update UI immediately
  notifyListeners();
  
  // 3. Sync to cloud if possible
  if (await _hasInternetConnection()) {
    try {
      await _syncToCloud(topicId, passed);
    } catch (e) {
      // Add to sync queue for later retry
      _addToSyncQueue(topicId, passed);
    }
  }
}
```

### 5. Memory Management
Dispose of resources properly:

```dart
class ProgressTrackingService extends ChangeNotifier {
  Timer? _syncTimer;
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
```

## Integration Patterns

### 1. Controller Integration
```dart
class QuizController extends ChangeNotifier {
  Future<void> completeQuiz() async {
    // Calculate results
    final result = _calculateQuizResult();
    
    // Save to progress service
    await ProgressTrackingService.instance.saveQuizResult(result);
    
    // Update topic progress if quiz passed
    if (result.passed) {
      await ProgressTrackingService.instance.updateTopicProgress(
        topicId: _currentQuiz.topicId,
        passed: true,
        sectionId: _currentQuiz.sectionId,
      );
    }
    
    // Update UI
    notifyListeners();
  }
}
```

### 2. Widget Integration
```dart
class QuizPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressTrackingService>(
      builder: (context, progressService, child) {
        final progress = progressService.getCurrentProgress();
        
        return Scaffold(
          body: Column(
            children: [
              // Show progress
              ProgressIndicator(progress: progress),
              
              // Quiz content
              QuizContent(),
            ],
          ),
        );
      },
    );
  }
}
```

## Testing Persistence

### Unit Tests
```dart
void main() {
  group('UserService Tests', () {
    late UserService userService;
    
    setUp(() {
      userService = UserService.instance;
    });
    
    test('should save and retrieve user data', () async {
      final user = User.defaultUser();
      await userService.saveCurrentUser(user);
      
      final retrievedUser = await userService.getCurrentUser();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals(user.id));
    });
    
    test('should handle corrupted data gracefully', () async {
      // Test error handling
      await userService.handleCorruptedData();
      final user = await userService.getCurrentUser();
      expect(user, isNotNull);
    });
  });
}
```

### Integration Tests
```dart
void main() {
  group('Persistence Integration Tests', () {
    testWidgets('should sync progress between local and cloud', (tester) async {
      // Test full sync workflow
      await tester.pumpWidget(MyApp());
      
      // Simulate user action
      await tester.tap(find.text('Complete Topic'));
      await tester.pumpAndSettle();
      
      // Verify local storage
      final localProgress = await UserService.instance.getCurrentUser();
      expect(localProgress!.progress.completedTopics.length, equals(1));
      
      // Verify cloud sync
      final cloudProgress = await FirebaseUserService.instance.getUserProgress();
      expect(cloudProgress!.completedTopics.length, equals(1));
    });
  });
}
```

## Performance Considerations

### 1. Lazy Loading
Load data only when needed:

```dart
class UserService {
  User? _cachedUser;
  
  Future<User?> getCurrentUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }
    
    _cachedUser = await _loadUserFromStorage();
    return _cachedUser;
  }
}
```

### 2. Background Sync
Use background sync for non-critical updates:

```dart
void _scheduleBackgroundSync() {
  Timer.periodic(Duration(minutes: 5), (timer) {
    _syncNonCriticalData();
  });
}
```

### 3. Data Compression
For large datasets, consider compression:

```dart
Future<void> saveCompressedData(Map<String, dynamic> data) async {
  final compressed = gzip.encode(utf8.encode(jsonEncode(data)));
  await _prefs.setString(_dataKey, base64.encode(compressed));
}
```

## Security Considerations

### 1. Data Encryption
Encrypt sensitive data before storing:

```dart
Future<void> saveSecureData(String key, String data) async {
  final encrypted = await _encryptData(data);
  await _prefs.setString(key, encrypted);
}
```

### 2. Input Validation
Validate all input data:

```dart
bool _isValidUserId(String userId) {
  return userId.isNotEmpty && userId.length >= 3 && userId.length <= 50;
}
```

### 3. Access Control
Implement proper access control:

```dart
Future<bool> _hasPermission(String operation) async {
  final user = await getCurrentUser();
  return user != null && user.permissions.contains(operation);
}
```

## Troubleshooting

### Common Issues
1. **Data Corruption**: Implement data validation and recovery mechanisms
2. **Sync Conflicts**: Use timestamp-based conflict resolution
3. **Network Failures**: Implement retry logic with exponential backoff
4. **Storage Limits**: Monitor storage usage and implement cleanup

### Debug Tools
```dart
void debugPrintStorageState() {
  debugPrint('=== Storage State ===');
  debugPrint('Local user: ${_prefs.getString(_currentUserKey)}');
  debugPrint('Pending sync: ${_pendingSyncQueue.length} items');
  debugPrint('Last sync: ${_prefs.getString(_lastSyncKey)}');
}
```

## Migration Strategies

### Data Migration
When updating data structures, implement migration logic:

```dart
Future<void> migrateUserData(int fromVersion, int toVersion) async {
  if (fromVersion == 1 && toVersion == 2) {
    // Migrate from v1 to v2
    final oldData = await _loadOldUserData();
    final newData = _convertToNewFormat(oldData);
    await _saveNewUserData(newData);
  }
}
```

This guide provides a comprehensive overview of persistence integration in the Theorie app. Follow these patterns and best practices to ensure robust, reliable data management throughout the application.