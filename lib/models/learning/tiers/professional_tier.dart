// lib/models/learning/tiers/professional_tier.dart

import '../learning_content.dart';

class ProfessionalTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'professional',
      title: 'Professional',
      description: 'Industry-level expertise',
      level: LearningLevel.professional,
      order: 6,
      topics: [], // To be filled later
    );
  }
}