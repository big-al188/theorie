import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/question_models.dart';
import '../models/quiz_enums.dart';

/// Controller for managing question pools
class QuestionPoolController {
  final Map<String, List<Question>> _questionsBySection = {};
  final Map<String, List<Question>> _questionsByTopic = {};
  final Map<QuestionType, List<Question>> _questionsByType = {};
  bool _isInitialized = false;

  /// Check if pool is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize question pools
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // In a real app, this would load from a database or API
      // For now, we'll load from static data files
      await _loadQuestions();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing question pool: $e');
      rethrow;
    }
  }

  /// Load questions for a specific section
  Future<void> loadQuestionsForSection(String sectionId) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if already loaded
    if (_questionsBySection.containsKey(sectionId)) {
      return;
    }

    // Load section-specific questions
    await _loadSectionQuestions(sectionId);
  }

  /// Get questions based on criteria
  List<Question> getQuestions({
    QuestionType? type,
    String? sectionId,
    String? topicId,
    DifficultyLevel? difficulty,
    int? limit,
  }) {
    List<Question> questions = [];

    // Start with all questions
    if (type != null) {
      questions = List.from(_questionsByType[type] ?? []);
    } else if (sectionId != null) {
      questions = List.from(_questionsBySection[sectionId] ?? []);
    } else if (topicId != null) {
      questions = List.from(_questionsByTopic[topicId] ?? []);
    } else {
      // Get all questions
      questions = _getAllQuestions();
    }

    // Apply filters
    if (sectionId != null && type != null) {
      questions = questions.where((q) {
        return _getQuestionSection(q) == sectionId;
      }).toList();
    }

    if (topicId != null && (type != null || sectionId != null)) {
      questions = questions.where((q) => q.topicId == topicId).toList();
    }

    if (difficulty != null) {
      questions = questions.where((q) => q.difficulty == difficulty).toList();
    }

    // Apply limit if specified
    if (limit != null && questions.length > limit) {
      questions = questions.take(limit).toList();
    }

    return questions;
  }

  /// Get a specific question by ID
  Question? getQuestionById(String id) {
    for (final questions in _questionsBySection.values) {
      final question = questions.firstWhere(
        (q) => q.id == id,
        orElse: () => null as dynamic,
      );
      if (question != null) return question;
    }
    return null;
  }

  /// Get random questions
  List<Question> getRandomQuestions({
    required int count,
    QuestionType? type,
    String? sectionId,
    String? topicId,
    DifficultyLevel? difficulty,
  }) {
    final availableQuestions = getQuestions(
      type: type,
      sectionId: sectionId,
      topicId: topicId,
      difficulty: difficulty,
    );

    if (availableQuestions.length <= count) {
      return availableQuestions;
    }

    // Shuffle and take required count
    final shuffled = List.from(availableQuestions)..shuffle();
    return shuffled.take(count).toList().cast<Question>();
  }

  /// Get question statistics
  Map<String, dynamic> getStatistics({
    String? sectionId,
    String? topicId,
  }) {
    final questions = getQuestions(
      sectionId: sectionId,
      topicId: topicId,
    );

    final stats = <String, dynamic>{
      'totalQuestions': questions.length,
      'byType': <String, int>{},
      'byDifficulty': <String, int>{},
      'byTopic': <String, int>{},
    };

    for (final question in questions) {
      // Count by type
      final typeKey = question.type.toString();
      stats['byType'][typeKey] = (stats['byType'][typeKey] ?? 0) + 1;

      // Count by difficulty
      final diffKey = question.difficulty.toString();
      stats['byDifficulty'][diffKey] = (stats['byDifficulty'][diffKey] ?? 0) + 1;

      // Count by topic
      stats['byTopic'][question.topicId] = 
          (stats['byTopic'][question.topicId] ?? 0) + 1;
    }

    return stats;
  }

  /// Add a new question to the pool
  void addQuestion(Question question) {
    // Add to section map
    final sectionId = _getQuestionSection(question);
    _questionsBySection.putIfAbsent(sectionId, () => []);
    _questionsBySection[sectionId]!.add(question);

    // Add to topic map
    _questionsByTopic.putIfAbsent(question.topicId, () => []);
    _questionsByTopic[question.topicId]!.add(question);

    // Add to type map
    _questionsByType.putIfAbsent(question.type, () => []);
    _questionsByType[question.type]!.add(question);
  }

  /// Remove a question from the pool
  void removeQuestion(String questionId) {
    // Remove from all maps
    _questionsBySection.forEach((key, questions) {
      questions.removeWhere((q) => q.id == questionId);
    });

    _questionsByTopic.forEach((key, questions) {
      questions.removeWhere((q) => q.id == questionId);
    });

    _questionsByType.forEach((key, questions) {
      questions.removeWhere((q) => q.id == questionId);
    });
  }

  /// Clear all questions
  void clear() {
    _questionsBySection.clear();
    _questionsByTopic.clear();
    _questionsByType.clear();
    _isInitialized = false;
  }

  /// Load all questions (called during initialization)
  Future<void> _loadQuestions() async {
    // In a real app, this would load from a database
    // For now, we'll simulate with a delay and load from static data
    await Future.delayed(const Duration(milliseconds: 500));

    // Load introduction section questions
    await _loadIntroductionQuestions();

    // Additional sections would be loaded here
  }

  /// Load section-specific questions
  Future<void> _loadSectionQuestions(String sectionId) async {
    switch (sectionId) {
      case 'introduction':
        await _loadIntroductionQuestions();
        break;
      // Add other sections as needed
      default:
        debugPrint('Unknown section: $sectionId');
    }
  }

  /// Load introduction section questions
  Future<void> _loadIntroductionQuestions() async {
    // This would normally load from a data source
    // For now, we'll import from static files
    try {
      // Dynamic import would happen here
      // For the example, we'll create some sample questions
      
      // Sample multiple choice questions
      final mcQuestions = [
        MultipleChoiceQuestion(
          id: 'intro_mc_001',
          text: 'What is the musical alphabet?',
          topicId: 'music_basics',
          difficulty: DifficultyLevel.beginner,
          pointValue: 1.0,
          correctAnswer: 'A, B, C, D, E, F, G',
          correctAnswerVariations: ['A B C D E F G', 'ABCDEFG'],
          incorrectAnswerPool: [
            'A, B, C, D, E, F, G, H',
            'A, B, C, D, E',
            'Do, Re, Mi, Fa, Sol, La, Ti',
            'C, D, E, F, G, A, B',
          ],
          explanation: 'The musical alphabet consists of seven letters: A, B, C, D, E, F, and G. These letters repeat in order.',
          relatedConceptIds: ['musical_alphabet', 'note_names'],
        ),
        MultipleChoiceQuestion(
          id: 'intro_mc_002',
          text: 'How many lines does a musical staff have?',
          topicId: 'notes_and_staff',
          difficulty: DifficultyLevel.beginner,
          pointValue: 1.0,
          correctAnswer: '5',
          correctAnswerVariations: ['Five', '5 lines'],
          incorrectAnswerPool: ['4', '6', '7', '8'],
          explanation: 'A musical staff consists of 5 horizontal lines and 4 spaces.',
          relatedConceptIds: ['staff_lines', 'staff_basics'],
        ),
      ];

      // Sample scale interactive questions
      final scaleQuestions = [
        ScaleInteractiveQuestion(
          id: 'intro_scale_001',
          text: 'Fill in the missing notes of the C major scale',
          topicId: 'basic_scales',
          difficulty: DifficultyLevel.beginner,
          pointValue: 2.0,
          scaleKey: 'C',
          scaleType: 'major',
          displayMode: ScaleDisplayMode.mixed,
          interactionMode: ScaleInteractionMode.fillNotes,
          initialState: {
            'visibleNotes': ['C', 'E', 'G'],
            'hiddenNotes': ['D', 'F', 'A', 'B'],
          },
          expectedAnswer: {
            'notes': ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'],
          },
          explanation: 'The C major scale contains all natural notes: C, D, E, F, G, A, B, C',
          relatedConceptIds: ['major_scale', 'scale_construction'],
        ),
      ];

      // Add questions to pool
      for (final question in [...mcQuestions, ...scaleQuestions]) {
        addQuestion(question);
      }

    } catch (e) {
      debugPrint('Error loading introduction questions: $e');
      rethrow;
    }
  }

  /// Get all questions
  List<Question> _getAllQuestions() {
    final allQuestions = <Question>[];
    for (final questions in _questionsBySection.values) {
      allQuestions.addAll(questions);
    }
    return allQuestions;
  }

  /// Get section ID from question
  String _getQuestionSection(Question question) {
    // Extract section from topic ID (assuming format: section_topic)
    final parts = question.topicId.split('_');
    if (parts.length >= 2) {
      // For now, we'll use a mapping
      if (question.topicId.startsWith('music_basics') ||
          question.topicId.startsWith('notes_and_staff') ||
          question.topicId.startsWith('basic_rhythm') ||
          question.topicId.startsWith('key_signatures') ||
          question.topicId.startsWith('basic_scales')) {
        return 'introduction';
      }
    }
    return 'unknown';
  }
}