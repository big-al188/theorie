// lib/models/learning/tiers/advanced_tier.dart

import '../learning_content.dart';

class AdvancedTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'advanced',
      title: 'Advanced',
      description: 'Master complex concepts',
      level: LearningLevel.advanced,
      order: 5,
      topics: [], // To be filled later
    );
  }
}