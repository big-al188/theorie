// lib/models/learning/learning_content.dart

import 'package:flutter/material.dart';
import 'tiers/introduction_tier.dart';
import 'tiers/fundamentals_tier.dart';
import 'tiers/essentials_tier.dart';
import 'tiers/intermediate_tier.dart';
import 'tiers/advanced_tier.dart';
import 'tiers/professional_tier.dart';
import 'tiers/master_tier.dart';
import 'tiers/virtuoso_tier.dart';

/// Represents a learning section
class LearningSection {
  final String id;
  final String title;
  final String description;
  final List<LearningTopic> topics;
  final int order;
  final LearningLevel level;

  const LearningSection({
    required this.id,
    required this.title,
    required this.description,
    required this.topics,
    required this.order,
    required this.level,
  });

  /// Get total number of topics in this section
  int get totalTopics => topics.length;

  /// Check if section has topics
  bool get hasTopics => topics.isNotEmpty;
}

/// Represents an individual learning topic
class LearningTopic {
  final String id;
  final String title;
  final String description;
  final String content;
  final List<String> keyPoints;
  final List<String> examples;
  final int order;
  final Duration estimatedReadTime;
  final bool hasQuiz; // Add this field

  const LearningTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.keyPoints,
    required this.examples,
    required this.order,
    required this.estimatedReadTime,
    this.hasQuiz = false, // Add this parameter
  });
}

/// Learning difficulty levels - Updated to 8 tiers
enum LearningLevel {
  introduction('Introduction', 'Start your musical journey'),
  fundamentals('Fundamentals', 'Build essential knowledge'),
  essentials('Essentials', 'Core concepts for musicians'),
  intermediate('Intermediate', 'Develop deeper understanding'),
  advanced('Advanced', 'Master complex concepts'),
  professional('Professional', 'Industry-level expertise'),
  master('Master', 'Comprehensive mastery'),
  virtuoso('Virtuoso', 'Push the boundaries');

  const LearningLevel(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Available instruments
enum Instrument {
  guitar('Guitar', 'Six-string fretted instrument'),
  piano('Piano', 'Keyboard instrument (Coming Soon)'),
  bass('Bass', 'Four-string bass guitar (Coming Soon)'),
  ukulele('Ukulele', 'Four-string small guitar (Coming Soon)');

  const Instrument(this.displayName, this.description);
  final String displayName;
  final String description;

  bool get isAvailable => this == Instrument.guitar;
}

/// Data repository for learning content
class LearningContentRepository {
  static final Map<LearningLevel, LearningSection> _sections = {
    LearningLevel.introduction: IntroductionTier.getSection(),
    LearningLevel.fundamentals: FundamentalsTier.getSection(),
    LearningLevel.essentials: EssentialsTier.getSection(),
    LearningLevel.intermediate: IntermediateTier.getSection(),
    LearningLevel.advanced: AdvancedTier.getSection(),
    LearningLevel.professional: ProfessionalTier.getSection(),
    LearningLevel.master: MasterTier.getSection(),
    LearningLevel.virtuoso: VirtuosoTier.getSection(),
  };

  /// Get all learning sections
  static List<LearningSection> getAllSections() {
    return _sections.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Get a specific section by level
  static LearningSection? getSection(LearningLevel level) {
    return _sections[level];
  }

  /// Get available instruments
  static List<Instrument> getAvailableInstruments() {
    return Instrument.values.where((instrument) => instrument.isAvailable).toList();
  }

  /// Get all instruments (including coming soon)
  static List<Instrument> getAllInstruments() {
    return Instrument.values;
  }

  /// Find a topic by ID across all sections
  static LearningTopic? findTopicById(String topicId) {
    for (final section in _sections.values) {
      final topic = section.topics.firstWhere(
        (t) => t.id == topicId,
        orElse: () => LearningTopic(
          id: '',
          title: '',
          description: '',
          content: '',
          keyPoints: [],
          examples: [],
          order: 0,
          estimatedReadTime: Duration.zero,
        ),
      );
      if (topic.id.isNotEmpty) return topic;
    }
    return null;
  }

  /// Get total number of topics across all sections
  static int getTotalTopicsCount() {
    return _sections.values
        .map((section) => section.totalTopics)
        .fold(0, (sum, count) => sum + count);
  }
}