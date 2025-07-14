// lib/models/learning/learning_tier.dart

import 'package:flutter/material.dart';
import 'learning_content.dart';

/// Learning tier levels for the 8-tier system
enum LearningTier {
  introduction('Introduction', 'Start your musical journey', 1),
  fundamentals('Fundamentals', 'Build essential knowledge', 2),
  essentials('Essentials', 'Core concepts for musicians', 3),
  intermediate('Intermediate', 'Develop deeper understanding', 4),
  advanced('Advanced', 'Master complex concepts', 5),
  professional('Professional', 'Industry-level expertise', 6),
  master('Master', 'Comprehensive mastery', 7),
  virtuoso('Virtuoso', 'Push the boundaries', 8);

  const LearningTier(this.displayName, this.description, this.order);
  final String displayName;
  final String description;
  final int order;
  
  /// Get the filename for this tier's content
  String get filename => 'tier_${name}_content.dart';
  
  /// Get the color associated with this tier
  Color get color {
    switch (this) {
      case LearningTier.introduction:
        return const Color(0xFF4CAF50); // Green
      case LearningTier.fundamentals:
        return const Color(0xFF2196F3); // Blue
      case LearningTier.essentials:
        return const Color(0xFF00BCD4); // Cyan
      case LearningTier.intermediate:
        return const Color(0xFFFF9800); // Orange
      case LearningTier.advanced:
        return const Color(0xFFFF5722); // Deep Orange
      case LearningTier.professional:
        return const Color(0xFF9C27B0); // Purple
      case LearningTier.master:
        return const Color(0xFF673AB7); // Deep Purple
      case LearningTier.virtuoso:
        return const Color(0xFF795548); // Brown
    }
  }
}

/// Updated learning section to work with the new tier system
class TieredLearningSection {
  final String id;
  final String title;
  final String description;
  final List<LearningTopic> topics;
  final LearningTier tier;

  const TieredLearningSection({
    required this.id,
    required this.title,
    required this.description,
    required this.topics,
    required this.tier,
  });

  /// Get total number of topics in this section
  int get totalTopics => topics.length;

  /// Check if section has topics
  bool get hasTopics => topics.isNotEmpty;
  
  /// Convert to the legacy LearningSection format for UI compatibility
  LearningSection toLegacySection() {
    // Map new tiers to closest old levels for UI compatibility
    final legacyLevel = _mapToLegacyLevel(tier);
    
    return LearningSection(
      id: id,
      title: title,
      description: description,
      topics: topics,
      order: tier.order,
      level: legacyLevel,
    );
  }
  
  static LearningLevel _mapToLegacyLevel(LearningTier tier) {
    switch (tier) {
      case LearningTier.introduction:
      case LearningTier.fundamentals:
        return LearningLevel.beginner;
      case LearningTier.essentials:
        return LearningLevel.novice;
      case LearningTier.intermediate:
        return LearningLevel.intermediate;
      case LearningTier.advanced:
      case LearningTier.professional:
        return LearningLevel.advanced;
      case LearningTier.master:
      case LearningTier.virtuoso:
        return LearningLevel.expert;
    }
  }
}

/// Base class for tier content
abstract class TierContent {
  TieredLearningSection getContent();
}