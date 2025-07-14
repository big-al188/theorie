// lib/models/learning/tiers/intermediate_tier.dart

import '../learning_content.dart';

class IntermediateTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'intermediate',
      title: 'Intermediate',
      description: 'Develop deeper understanding',
      level: LearningLevel.intermediate,
      order: 4,
      topics: [], // To be filled later
    );
  }
}