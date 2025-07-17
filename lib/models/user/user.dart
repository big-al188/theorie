// lib/models/user/user.dart
import 'package:uuid/uuid.dart';

/// Represents a user account with ONLY account information
/// All preferences and progress tracking have been moved to separate models
class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isDefaultUser;
  final String? firebaseUid; // For Firebase users
  final bool isEmailVerified;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.lastLoginAt,
    this.isDefaultUser = false,
    this.firebaseUid,
    this.isEmailVerified = false,
  });

  /// Create default guest user
  factory User.defaultUser() {
    return User(
      id: 'default-user',
      username: 'Guest User',
      email: 'guest@theorie.app',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isDefaultUser: true,
      isEmailVerified: false,
    );
  }

  /// Create user from registration data
  factory User.fromRegistration({
    required String username,
    required String email,
    String? firebaseUid,
  }) {
    return User(
      id: firebaseUid ?? const Uuid().v4(),
      username: username,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      firebaseUid: firebaseUid,
      isEmailVerified: false,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isDefaultUser': isDefaultUser,
      'firebaseUid': firebaseUid,
      'isEmailVerified': isEmailVerified,
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      isDefaultUser: json['isDefaultUser'] as bool? ?? false,
      firebaseUid: json['firebaseUid'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  /// Create copy with updated fields
  User copyWith({
    String? username,
    String? email,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    String? firebaseUid,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isDefaultUser: isDefaultUser,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  /// Check if this is a guest user
  bool get isGuest => isDefaultUser;

  /// Check if this is a Firebase authenticated user
  bool get isFirebaseUser => firebaseUid != null;

  /// Get display name for UI
  String get displayName => isDefaultUser ? 'Guest' : username;

  /// Get user type for debugging/logging
  String get userType {
    if (isDefaultUser) return 'Guest';
    if (isFirebaseUser) return 'Firebase';
    return 'Local';
  }

  @override
  String toString() => 'User(id: $id, username: $username, email: $email, type: $userType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, username, email);
}