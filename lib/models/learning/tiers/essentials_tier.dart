
// lib/models/learning/tiers/essentials_tier.dart

import '../learning_content.dart';

class EssentialsTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'essentials',
      title: 'Essentials',
      description: 'Core concepts for musicians',
      level: LearningLevel.essentials,
      order: 3,
      topics: [], // To be filled later
    );
  }
}