// lib/models/quiz/sections/introduction/scale_strip_quiz_questions.dart

import '../../../quiz/quiz_question.dart';
import '../../../quiz/scale_strip_question.dart';
import '../../../music/scale.dart';
import '../../../music/chord.dart';
import '../../../../utils/scale_strip_question_generator.dart';

/// Generalized scale strip quiz questions using music theory models
class ScaleStripQuizQuestions {
  static const String topicId = 'scale-strip-quiz';
  static const String topicTitle = 'Scale Strip Quiz';

  /// Get all scale strip quiz questions using the generalized generator
  static List<ScaleStripQuestion> getQuestions() {
    final questions = <ScaleStripQuestion>[];

    // Add basic scale questions
    questions.addAll(_getBasicScaleQuestions());
    
    // Add basic chord questions
    questions.addAll(_getBasicChordQuestions());
    
    // Add interval questions
    questions.addAll(_getIntervalQuestions());
    
    // Add chromatic questions
    questions.addAll(_getChromaticQuestions());
    
    // Add pattern recognition questions
    questions.addAll(_getPatternQuestions());

    return questions;
  }

  /// Get questions for specific difficulty level
  static List<ScaleStripQuestion> getQuestionsByDifficulty(QuestionDifficulty difficulty) {
    return getQuestions().where((q) => q.difficulty == difficulty).toList();
  }

  /// Get questions for specific topic
  static List<ScaleStripQuestion> getQuestionsByTopic(QuestionTopic topic) {
    return getQuestions().where((q) => q.topic == topic).toList();
  }

  /// Get questions for specific scale
  static List<ScaleStripQuestion> getQuestionsForScale(String scaleName) {
    final scale = Scale.get(scaleName);
    if (scale == null) return [];
    
    return ScaleStripQuestionGenerator.generateScaleQuestions(
      scale,
      rootNotes: ['C', 'G', 'F'],
      modes: [
        ScaleStripQuestionMode.construction,
        ScaleStripQuestionMode.intervals,
      ],
    );
  }

  /// Get questions for specific chord
  static List<ScaleStripQuestion> getQuestionsForChord(String chordType) {
    final chord = Chord.get(chordType);
    if (chord == null) return [];
    
    return ScaleStripQuestionGenerator.generateChordQuestions(
      chord,
      rootNotes: ['C', 'G'],
      modes: [
        ScaleStripQuestionMode.construction,
        ScaleStripQuestionMode.intervals,
      ],
    );
  }

  /// Basic scale questions for introduction level
  static List<ScaleStripQuestion> _getBasicScaleQuestions() {
    final questions = <ScaleStripQuestion>[];

    // Major scale questions
    final majorScale = Scale.major;
    questions.addAll(ScaleStripQuestionGenerator.generateScaleQuestions(
      majorScale,
      rootNotes: ['C', 'G'],
      modes: [
        ScaleStripQuestionMode.construction,
        ScaleStripQuestionMode.intervals,
      ],
    ));

    // Natural minor scale questions
    final naturalMinorScale = Scale.naturalMinor;
    questions.addAll(ScaleStripQuestionGenerator.generateScaleQuestions(
      naturalMinorScale,
      rootNotes: ['A', 'E'],
      modes: [
        ScaleStripQuestionMode.construction,
        ScaleStripQuestionMode.intervals,
      ],
    ));

    // Pentatonic scale questions
    final majorPentatonic = Scale.majorPentatonic;
    questions.addAll(ScaleStripQuestionGenerator.generateScaleQuestions(
      majorPentatonic,
      rootNotes: ['C'],
      modes: [ScaleStripQuestionMode.construction],
    ));

    return questions;
  }

  /// Basic chord questions for introduction level
  static List<ScaleStripQuestion> _getBasicChordQuestions() {
    final questions = <ScaleStripQuestion>[];

    // Basic triads
    final basicChords = ['major', 'minor', 'diminished'];
    for (final chordType in basicChords) {
      final chord = Chord.get(chordType);
      if (chord != null) {
        questions.addAll(ScaleStripQuestionGenerator.generateChordQuestions(
          chord,
          rootNotes: ['C'],
          modes: [ScaleStripQuestionMode.construction],
        ));
      }
    }

    // Extended chords with 2 octaves
    final extendedChords = ['add9', 'major7'];
    for (final chordType in extendedChords) {
      final chord = Chord.get(chordType);
      if (chord != null) {
        questions.addAll(ScaleStripQuestionGenerator.generateChordQuestions(
          chord,
          rootNotes: ['C'],
          modes: [ScaleStripQuestionMode.construction],
        ));
      }
    }

    return questions;
  }

  /// Interval recognition questions
  static List<ScaleStripQuestion> _getIntervalQuestions() {
    return ScaleStripQuestionGenerator.generateIntervalQuestions(
      rootNotes: ['C'],
    );
  }

  /// Chromatic scale questions
  static List<ScaleStripQuestion> _getChromaticQuestions() {
    return ScaleStripQuestionGenerator.generateChromaticQuestions(
      rootNotes: ['C'],
    );
  }

  /// Pattern recognition questions
  static List<ScaleStripQuestion> _getPatternQuestions() {
    final questions = <ScaleStripQuestion>[];

    // Major scale pattern starting from different notes
    final majorScale = Scale.major;
    questions.addAll(ScaleStripQuestionGenerator.generateScaleQuestions(
      majorScale,
      rootNotes: ['G', 'D'],
      modes: [ScaleStripQuestionMode.pattern],
    ));

    return questions;
  }

  /// Create custom questions with specific configurations
  static List<ScaleStripQuestion> createCustomQuestions({
    required List<String> scaleNames,
    required List<String> chordTypes,
    required List<String> rootNotes,
    int maxQuestions = 20,
  }) {
    final questions = <ScaleStripQuestion>[];

    // Add scale questions
    for (final scaleName in scaleNames) {
      final scale = Scale.get(scaleName);
      if (scale != null) {
        questions.addAll(ScaleStripQuestionGenerator.generateScaleQuestions(
          scale,
          rootNotes: rootNotes,
        ));
      }
    }

    // Add chord questions
    for (final chordType in chordTypes) {
      final chord = Chord.get(chordType);
      if (chord != null) {
        questions.addAll(ScaleStripQuestionGenerator.generateChordQuestions(
          chord,
          rootNotes: rootNotes,
        ));
      }
    }

    // Shuffle and limit
    questions.shuffle();
    return questions.take(maxQuestions).toList();
  }

  /// Generate questions based on available music theory models
  static List<ScaleStripQuestion> generateFromAvailableModels({
    bool includeAllScales = false,
    bool includeAllChords = false,
    List<String>? specificScales,
    List<String>? specificChords,
    int maxQuestions = 30,
  }) {
    final questions = <ScaleStripQuestion>[];

    if (includeAllScales) {
      // Use all available scales
      final allScales = Scale.all.keys.toList();
      questions.addAll(ScaleStripQuestionGenerator.generateAllScaleQuestions(
        scaleNames: allScales.take(10).toList(), // Limit to avoid too many
        maxQuestions: maxQuestions ~/ 2,
      ));
    } else if (specificScales != null) {
      // Use specific scales
      for (final scaleName in specificScales) {
        final scale = Scale.get(scaleName);
        if (scale != null) {
          questions.addAll(ScaleStripQuestionGenerator.generateScaleQuestions(
            scale,
            rootNotes: ['C', 'G'],
          ));
        }
      }
    }

    if (includeAllChords) {
      // Use all basic chords
      final basicChords = Chord.all.values
          .where((chord) => ['Basic Triads', 'Seventh Chords', 'Suspended'].contains(chord.category))
          .map((chord) => chord.type)
          .toList();
      questions.addAll(ScaleStripQuestionGenerator.generateAllChordQuestions(
        chordTypes: basicChords.take(10).toList(), // Limit to avoid too many
        maxQuestions: maxQuestions ~/ 2,
      ));
    } else if (specificChords != null) {
      // Use specific chords
      for (final chordType in specificChords) {
        final chord = Chord.get(chordType);
        if (chord != null) {
          questions.addAll(ScaleStripQuestionGenerator.generateChordQuestions(
            chord,
            rootNotes: ['C', 'G'],
          ));
        }
      }
    }

    // Shuffle and limit
    questions.shuffle();
    return questions.take(maxQuestions).toList();
  }

  /// Generate a balanced quiz with different question types
  static List<ScaleStripQuestion> generateBalancedQuiz({
    int scaleQuestions = 8,
    int chordQuestions = 6,
    int intervalQuestions = 4,
    int chromaticQuestions = 2,
  }) {
    final questions = <ScaleStripQuestion>[];

    // Add scale questions
    final scaleQuestionList = ScaleStripQuestionGenerator.generateAllScaleQuestions(
      maxQuestions: scaleQuestions,
    );
    questions.addAll(scaleQuestionList);

    // Add chord questions
    final chordQuestionList = ScaleStripQuestionGenerator.generateAllChordQuestions(
      maxQuestions: chordQuestions,
    );
    questions.addAll(chordQuestionList);

    // Add interval questions
    final intervalQuestionList = ScaleStripQuestionGenerator.generateIntervalQuestions();
    questions.addAll(intervalQuestionList.take(intervalQuestions));

    // Add chromatic questions
    final chromaticQuestionList = ScaleStripQuestionGenerator.generateChromaticQuestions();
    questions.addAll(chromaticQuestionList.take(chromaticQuestions));

    // Shuffle for variety
    questions.shuffle();
    return questions;
  }

  /// Get questions by category for organized learning
  static Map<String, List<ScaleStripQuestion>> getQuestionsByCategory() {
    return {
      'Basic Scales': _getBasicScaleQuestions(),
      'Basic Chords': _getBasicChordQuestions(),
      'Intervals': _getIntervalQuestions(),
      'Chromatic': _getChromaticQuestions(),
      'Patterns': _getPatternQuestions(),
    };
  }

  /// Get progressive questions (easier to harder)
  static List<ScaleStripQuestion> getProgressiveQuestions() {
    final questions = <ScaleStripQuestion>[];
    
    // Start with basic major scale
    questions.addAll(getQuestionsForScale('Major').where((q) => 
        q.questionMode == ScaleStripQuestionMode.construction).take(2));
    
    // Add basic chords
    questions.addAll(getQuestionsForChord('major').take(1));
    questions.addAll(getQuestionsForChord('minor').take(1));
    
    // Add chromatic
    questions.addAll(_getChromaticQuestions().take(1));
    
    // Add minor scales
    questions.addAll(getQuestionsForScale('Natural Minor').take(2));
    
    // Add more complex chords
    questions.addAll(getQuestionsForChord('add9').take(1));
    
    // Add intervals
    questions.addAll(_getIntervalQuestions().take(3));
    
    // Add pattern recognition
    questions.addAll(_getPatternQuestions().take(2));
    
    return questions;
  }
}