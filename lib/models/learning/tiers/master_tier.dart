// lib/models/learning/tiers/master_tier.dart

import '../learning_content.dart';

class MasterTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'master',
      title: 'Master',
      description: 'Comprehensive mastery',
      level: LearningLevel.master,
      order: 7,
      topics: [], // To be filled later
    );
  }
}