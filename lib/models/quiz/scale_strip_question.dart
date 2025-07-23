// lib/models/quiz/scale_strip_question.dart

import 'package:flutter/foundation.dart';
import 'quiz_question.dart';
import '../music/scale.dart';
import '../music/chord.dart';
import '../../utils/scale_strip_utils.dart';

/// Enumeration for different interval label formats
enum IntervalLabelFormat {
  /// Numeric labels: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
  numeric,
  /// Scale degree labels with accidentals: 1, ♭2, 2, ♭3, 3, 4, ♭5, 5, ♭6, 6, ♭7, 7, 8
  scaleDegreesWithAccidentals,
  /// Roman numerals: I, ii, iii, IV, V, vi, vii°
  romanNumerals,
}

/// Enumeration for scale strip display modes
enum ScaleStripMode {
  /// Display and select intervals
  intervals,
  /// Display and select note names
  notes,
  /// Construct scales or chords
  construction,
  /// Fill in missing notes/intervals
  fillInBlanks,
  /// Recognize patterns
  pattern,
}

/// Enumeration for answer validation modes
enum ValidationMode {
  /// Exact position matching
  exactPositions,
  /// Note name matching (ignoring octaves)
  noteNames,
  /// Note names with octave awareness
  noteNamesWithOctaves,
  /// Pattern matching (allowing transposition)
  pattern,
  /// Note names with partial credit for octave differences
  noteNamesWithPartialCredit,
}

/// Enumeration for scale strip question modes
enum ScaleStripQuestionMode {
  /// Select interval positions
  intervals,
  /// Select/identify note names
  notes,
  /// Construct scales or chords
  construction,
  /// Recognize scale/chord patterns
  pattern,
}

/// Enhanced configuration for scale strip display and behavior
class ScaleStripConfiguration {
  const ScaleStripConfiguration({
    this.showIntervalLabels = false,
    this.showNoteLabels = true,
    this.allowMultipleSelection = true,
    this.displayMode = ScaleStripMode.construction,
    this.rootNote = 'C',
    this.octaveCount = 1,
    this.validationMode = ValidationMode.exactPositions,
    this.preHighlightedPositions = const {},
    this.highlightRoot = false,
    this.showEmptyPositions = false,
    this.lockPreHighlighted = false,
    this.useDropdownSelection = false,
    this.showPreHighlightedLabels = false,
    this.useScaleDegreeLabels = false,
    this.intervalLabelFormat = IntervalLabelFormat.numeric,
    this.enableOctaveDistinction = false,
    this.allowPartialCreditForOctaves = false,
    this.clearSelectionOnStart = false,
    this.validateSelectionOnChange = false,
    this.showFirstNoteAsReference = false,
    this.firstNotePosition,
    this.lockReferenceNote = false,
    this.referenceNoteLabel,
  });

  /// Whether to show interval labels (1, 2, ♭3, etc.)
  final bool showIntervalLabels;

  /// Whether to show note names (C, D, E, etc.)
  final bool showNoteLabels;

  /// Whether multiple positions can be selected
  final bool allowMultipleSelection;

  /// Display mode for the scale strip
  final ScaleStripMode displayMode;

  /// Root note for the scale strip
  final String rootNote;

  /// Number of octaves to display
  final int octaveCount;

  /// How to validate answers
  final ValidationMode validationMode;

  /// Positions that are pre-highlighted
  final Set<int> preHighlightedPositions;

  /// Whether to highlight the root note specially
  final bool highlightRoot;

  /// Whether to show empty positions as selectable
  final bool showEmptyPositions;

  /// Whether pre-highlighted positions are locked from interaction
  final bool lockPreHighlighted;

  /// Whether to use dropdown selection for note names
  final bool useDropdownSelection;

  /// Whether to show labels for pre-highlighted positions
  final bool showPreHighlightedLabels;

  /// Whether to use scale degree labels instead of interval numbers
  final bool useScaleDegreeLabels;

  /// Format for interval labels
  final IntervalLabelFormat intervalLabelFormat;

  /// Whether octave information matters for validation
  final bool enableOctaveDistinction;

  /// Whether to award partial credit for correct notes in wrong octaves
  final bool allowPartialCreditForOctaves;

  /// Whether to clear any existing selections when starting
  final bool clearSelectionOnStart;

  /// Whether to validate selection immediately when it changes
  final bool validateSelectionOnChange;

  /// Whether to show the first note as a non-selectable reference
  final bool showFirstNoteAsReference;

  /// Position of the first note to show as reference
  final int? firstNotePosition;

  /// Whether the reference note is locked from interaction
  final bool lockReferenceNote;

  /// Optional label to show for the reference note
  final String? referenceNoteLabel;

  /// Create configuration optimized for scales
  factory ScaleStripConfiguration.forScale(
    String scaleName,
    String rootNote,
    ScaleStripQuestionMode mode,
  ) {
    switch (mode) {
      case ScaleStripQuestionMode.construction:
        return ScaleStripConfiguration(
          displayMode: ScaleStripMode.construction,
          rootNote: rootNote,
          showNoteLabels: true,
          allowMultipleSelection: true,
        );
      
      case ScaleStripQuestionMode.intervals:
        return ScaleStripConfiguration(
          displayMode: ScaleStripMode.intervals,
          rootNote: rootNote,
          showIntervalLabels: true,
          showNoteLabels: true,
          allowMultipleSelection: true,
          useScaleDegreeLabels: true,
          intervalLabelFormat: IntervalLabelFormat.scaleDegreesWithAccidentals,
        );
      
      case ScaleStripQuestionMode.pattern:
        return ScaleStripConfiguration(
          displayMode: ScaleStripMode.pattern,
          rootNote: 'C', // Use C to test pattern understanding
          showNoteLabels: true,
          allowMultipleSelection: true,
          validationMode: ValidationMode.pattern,
        );
      
      default:
        return const ScaleStripConfiguration();
    }
  }

  /// Create configuration optimized for chords
  factory ScaleStripConfiguration.forChord(
    String chordType,
    String rootNote,
    ScaleStripQuestionMode mode,
  ) {
    final needsMultipleOctaves = ScaleStripUtils.needsMultipleOctaves(chordType);
    
    return ScaleStripConfiguration(
      displayMode: mode == ScaleStripQuestionMode.intervals 
          ? ScaleStripMode.intervals 
          : ScaleStripMode.construction,
      rootNote: rootNote,
      octaveCount: needsMultipleOctaves ? 2 : 1,
      showIntervalLabels: mode == ScaleStripQuestionMode.intervals,
      showNoteLabels: true,
      allowMultipleSelection: true,
      enableOctaveDistinction: needsMultipleOctaves,
    );
  }

  /// Create configuration for chromatic exercises
  factory ScaleStripConfiguration.forChromatic(String rootNote) {
    final naturalPositions = ScaleStripUtils.getNaturalNotePositions(rootNote);
    
    return ScaleStripConfiguration(
      displayMode: ScaleStripMode.fillInBlanks,
      rootNote: rootNote,
      showNoteLabels: false,
      showEmptyPositions: true,
      preHighlightedPositions: naturalPositions,
      lockPreHighlighted: true,
      useDropdownSelection: true,
      showPreHighlightedLabels: true,
      validationMode: ValidationMode.noteNames,
    );
  }

  ScaleStripConfiguration copyWith({
    bool? showIntervalLabels,
    bool? showNoteLabels,
    bool? allowMultipleSelection,
    ScaleStripMode? displayMode,
    String? rootNote,
    int? octaveCount,
    ValidationMode? validationMode,
    Set<int>? preHighlightedPositions,
    bool? highlightRoot,
    bool? showEmptyPositions,
    bool? lockPreHighlighted,
    bool? useDropdownSelection,
    bool? showPreHighlightedLabels,
    bool? useScaleDegreeLabels,
    IntervalLabelFormat? intervalLabelFormat,
    bool? enableOctaveDistinction,
    bool? allowPartialCreditForOctaves,
    bool? clearSelectionOnStart,
    bool? validateSelectionOnChange,
    bool? showFirstNoteAsReference,
    int? firstNotePosition,
    bool? lockReferenceNote,
    String? referenceNoteLabel,
  }) {
    return ScaleStripConfiguration(
      showIntervalLabels: showIntervalLabels ?? this.showIntervalLabels,
      showNoteLabels: showNoteLabels ?? this.showNoteLabels,
      allowMultipleSelection: allowMultipleSelection ?? this.allowMultipleSelection,
      displayMode: displayMode ?? this.displayMode,
      rootNote: rootNote ?? this.rootNote,
      octaveCount: octaveCount ?? this.octaveCount,
      validationMode: validationMode ?? this.validationMode,
      preHighlightedPositions: preHighlightedPositions ?? this.preHighlightedPositions,
      highlightRoot: highlightRoot ?? this.highlightRoot,
      showEmptyPositions: showEmptyPositions ?? this.showEmptyPositions,
      lockPreHighlighted: lockPreHighlighted ?? this.lockPreHighlighted,
      useDropdownSelection: useDropdownSelection ?? this.useDropdownSelection,
      showPreHighlightedLabels: showPreHighlightedLabels ?? this.showPreHighlightedLabels,
      useScaleDegreeLabels: useScaleDegreeLabels ?? this.useScaleDegreeLabels,
      intervalLabelFormat: intervalLabelFormat ?? this.intervalLabelFormat,
      enableOctaveDistinction: enableOctaveDistinction ?? this.enableOctaveDistinction,
      allowPartialCreditForOctaves: allowPartialCreditForOctaves ?? this.allowPartialCreditForOctaves,
      clearSelectionOnStart: clearSelectionOnStart ?? this.clearSelectionOnStart,
      validateSelectionOnChange: validateSelectionOnChange ?? this.validateSelectionOnChange,
      showFirstNoteAsReference: showFirstNoteAsReference ?? this.showFirstNoteAsReference,
      firstNotePosition: firstNotePosition ?? this.firstNotePosition,
      lockReferenceNote: lockReferenceNote ?? this.lockReferenceNote,
      referenceNoteLabel: referenceNoteLabel ?? this.referenceNoteLabel,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || 
      other is ScaleStripConfiguration &&
      showIntervalLabels == other.showIntervalLabels &&
      showNoteLabels == other.showNoteLabels &&
      allowMultipleSelection == other.allowMultipleSelection &&
      displayMode == other.displayMode &&
      rootNote == other.rootNote &&
      octaveCount == other.octaveCount &&
      validationMode == other.validationMode &&
      setEquals(preHighlightedPositions, other.preHighlightedPositions);

  @override
  int get hashCode => Object.hashAll([
    showIntervalLabels, showNoteLabels, allowMultipleSelection,
    displayMode, rootNote, octaveCount, validationMode, preHighlightedPositions,
  ]);
}

/// Enhanced answer class with better validation support
class ScaleStripAnswer {
  const ScaleStripAnswer({
    this.selectedPositions = const {},
    this.selectedNotes = const {},
    this.expectedOctavePatterns = const {},
    this.partialCreditAnswers = const [],
    this.timeTaken,
  });

  /// Positions selected on the scale strip (0-based from root)
  final Set<int> selectedPositions;

  /// Note names selected (may include octave info like 'C4')
  final Set<String> selectedNotes;

  /// Expected octave patterns for each note (for octave-aware validation)
  final Map<String, List<int>> expectedOctavePatterns;

  /// Alternative answers that should receive partial credit
  final List<Set<String>> partialCreditAnswers;

  /// Time taken to provide this answer
  final Duration? timeTaken;

  /// Check if the answer is empty
  bool get isEmpty => selectedPositions.isEmpty && selectedNotes.isEmpty;

  /// Create answer from scale using music theory model
  factory ScaleStripAnswer.fromScale(String scaleName, String rootNote, String stripRoot) {
    return ScaleStripUtils.generateScaleAnswer(scaleName, rootNote, stripRoot);
  }

  /// Create answer from chord using music theory model
  factory ScaleStripAnswer.fromChord(String chordType, String rootNote, String stripRoot) {
    return ScaleStripUtils.generateChordAnswer(chordType, rootNote, stripRoot);
  }

  @override
  bool operator ==(Object other) => identical(this, other) ||
      other is ScaleStripAnswer &&
      setEquals(selectedPositions, other.selectedPositions) &&
      setEquals(selectedNotes, other.selectedNotes);

  @override
  int get hashCode => Object.hash(selectedPositions, selectedNotes);

  @override
  String toString() => 'ScaleStripAnswer(positions: $selectedPositions, notes: $selectedNotes)';
}

/// Enhanced scale strip question with automatic generation capabilities
class ScaleStripQuestion extends QuizQuestion {
  const ScaleStripQuestion({
    required super.id,
    required super.questionText,
    required super.topic,
    required super.difficulty,
    required super.pointValue,
    required this.configuration,
    required this.correctAnswer,
    super.explanation,
    super.hints,
    super.tags,
    super.timeLimit,
    super.allowPartialCredit = true,
    this.scaleType = 'major',
    this.questionMode = ScaleStripQuestionMode.intervals,
  });

  /// Configuration for the scale strip display
  final ScaleStripConfiguration configuration;

  /// The correct answer for this question
  final ScaleStripAnswer correctAnswer;

  /// Type of scale being tested (major, minor, chromatic, etc.)
  final String scaleType;

  /// The mode of this question (intervals, notes, construction)
  final ScaleStripQuestionMode questionMode;

  @override
  QuestionType get type => QuestionType.scaleStrip;

  @override
  List<dynamic> get possibleAnswers => [correctAnswer];

  /// Create a scale question using music theory models
  factory ScaleStripQuestion.forScale({
    required String id,
    required String scaleName,
    required String rootNote,
    required ScaleStripQuestionMode mode,
    String? customQuestionText,
    String? customExplanation,
    List<String>? customHints,
  }) {
    final scale = Scale.get(scaleName);
    if (scale == null) {
      throw ArgumentError('Unknown scale: $scaleName');
    }

    final difficulty = _getDifficultyForScale(scaleName);
    final pointValue = _getPointValueForDifficulty(difficulty, mode);
    final config = ScaleStripConfiguration.forScale(scaleName, rootNote, mode);
    final answer = ScaleStripAnswer.fromScale(scaleName, rootNote, config.rootNote);

    return ScaleStripQuestion(
      id: id,
      questionText: customQuestionText ?? _generateScaleQuestionText(scaleName, rootNote, mode),
      topic: QuestionTopic.scales,
      difficulty: difficulty,
      pointValue: pointValue,
      configuration: config,
      correctAnswer: answer,
      scaleType: scaleName.toLowerCase().replaceAll(' ', '_'),
      questionMode: mode,
      explanation: customExplanation ?? ScaleStripUtils.generateScaleExplanation(scaleName, rootNote),
      hints: customHints ?? _generateScaleHints(scaleName, mode),
      tags: _generateScaleTags(scaleName),
    );
  }

  /// Create a chord question using music theory models
  factory ScaleStripQuestion.forChord({
    required String id,
    required String chordType,
    required String rootNote,
    required ScaleStripQuestionMode mode,
    String? customQuestionText,
    String? customExplanation,
    List<String>? customHints,
  }) {
    final chord = Chord.get(chordType);
    if (chord == null) {
      throw ArgumentError('Unknown chord: $chordType');
    }

    final difficulty = _getDifficultyForChord(chordType);
    final pointValue = _getPointValueForDifficulty(difficulty, mode);
    final config = ScaleStripConfiguration.forChord(chordType, rootNote, mode);
    final answer = ScaleStripAnswer.fromChord(chordType, rootNote, config.rootNote);

    return ScaleStripQuestion(
      id: id,
      questionText: customQuestionText ?? _generateChordQuestionText(chordType, rootNote, mode),
      topic: QuestionTopic.chords,
      difficulty: difficulty,
      pointValue: pointValue,
      configuration: config,
      correctAnswer: answer,
      scaleType: chordType,
      questionMode: mode,
      explanation: customExplanation ?? ScaleStripUtils.generateChordExplanation(chordType, rootNote),
      hints: customHints ?? _generateChordHints(chordType, mode),
      tags: _generateChordTags(chordType),
    );
  }

  @override
  QuestionResult validateAnswer(dynamic userAnswer) {
    if (userAnswer is! ScaleStripAnswer) {
      return QuestionResult(
        isCorrect: false,
        userAnswer: userAnswer,
        correctAnswer: correctAnswer,
        feedback: 'Invalid answer format',
      );
    }

    final result = _validateAnswer(userAnswer);
    
    return QuestionResult(
      isCorrect: result.score >= 0.7, // 70% threshold
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      partialCreditScore: result.score < 1.0 ? result.score : null,
      feedback: result.feedback,
      explanation: explanation,
    );
  }

  @override
  double calculateScore(dynamic userAnswer, {Duration? timeTaken}) {
    if (userAnswer is! ScaleStripAnswer) return 0.0;
    return _validateAnswer(userAnswer).score;
  }

  /// Internal validation with support for different modes
  _ValidationResult _validateAnswer(ScaleStripAnswer userAnswer) {
    switch (configuration.validationMode) {
      case ValidationMode.exactPositions:
        return _validateExactPositions(userAnswer);
      case ValidationMode.noteNames:
        return _validateNoteNames(userAnswer);
      case ValidationMode.pattern:
        return _validatePattern(userAnswer);
      default:
        return _validateExactPositions(userAnswer);
    }
  }

  _ValidationResult _validateExactPositions(ScaleStripAnswer userAnswer) {
    final expected = correctAnswer.selectedPositions;
    final actual = userAnswer.selectedPositions;
    
    if (actual.isEmpty) {
      return _ValidationResult(score: 0.0, feedback: 'No positions selected.');
    }
    
    final correct = actual.intersection(expected).length;
    final total = expected.length;
    final score = total > 0 ? correct / total : 0.0;
    
    return _ValidationResult(
      score: score,
      feedback: score == 1.0 ? 'Perfect!' : 'Check ${total - correct} more positions.',
    );
  }

  _ValidationResult _validateNoteNames(ScaleStripAnswer userAnswer) {
    final expected = correctAnswer.selectedNotes;
    final actual = userAnswer.selectedNotes;
    
    if (actual.isEmpty) {
      return _ValidationResult(score: 0.0, feedback: 'No notes selected.');
    }
    
    final correct = actual.intersection(expected).length;
    final total = expected.length;
    final score = total > 0 ? correct / total : 0.0;
    
    return _ValidationResult(
      score: score,
      feedback: score == 1.0 ? 'Excellent!' : 'Review the note names.',
    );
  }

  _ValidationResult _validatePattern(ScaleStripAnswer userAnswer) {
    // Pattern validation checks interval relationships
    final userPositions = userAnswer.selectedPositions.toList()..sort();
    final expectedPositions = correctAnswer.selectedPositions.toList()..sort();
    
    if (userPositions.length != expectedPositions.length) {
      return _ValidationResult(score: 0.0, feedback: 'Incorrect number of notes.');
    }
    
    // Check interval pattern
    final userIntervals = _getIntervals(userPositions);
    final expectedIntervals = _getIntervals(expectedPositions);
    
    final matches = userIntervals.where((i) => expectedIntervals.contains(i)).length;
    final score = expectedIntervals.isNotEmpty ? matches / expectedIntervals.length : 0.0;
    
    return _ValidationResult(
      score: score,
      feedback: score == 1.0 ? 'Perfect pattern!' : 'Check the interval pattern.',
    );
  }

  List<int> _getIntervals(List<int> positions) {
    final intervals = <int>[];
    for (int i = 1; i < positions.length; i++) {
      intervals.add(positions[i] - positions[i - 1]);
    }
    return intervals;
  }

  /// Static helper methods for question generation
  static QuestionDifficulty _getDifficultyForScale(String scaleName) {
    final beginner = ['Major', 'Natural Minor', 'Major Pentatonic', 'Minor Pentatonic'];
    final intermediate = ['Blues', 'Dorian', 'Mixolydian', 'Harmonic Minor'];
    
    if (beginner.contains(scaleName)) return QuestionDifficulty.beginner;
    if (intermediate.contains(scaleName)) return QuestionDifficulty.intermediate;
    return QuestionDifficulty.advanced;
  }

  static QuestionDifficulty _getDifficultyForChord(String chordType) {
    final chord = Chord.get(chordType);
    if (chord == null) return QuestionDifficulty.beginner;
    
    if (chord.category == 'Basic Triads') return QuestionDifficulty.beginner;
    if (['Suspended', 'Seventh Chords', 'Sixth Chords'].contains(chord.category)) {
      return QuestionDifficulty.intermediate;
    }
    return QuestionDifficulty.advanced;
  }

  static int _getPointValueForDifficulty(QuestionDifficulty difficulty, ScaleStripQuestionMode mode) {
    var base = switch (difficulty) {
      QuestionDifficulty.beginner => 10,
      QuestionDifficulty.intermediate => 15,
      QuestionDifficulty.advanced => 20,
      QuestionDifficulty.expert => 25,
    };
    
    if (mode == ScaleStripQuestionMode.pattern) base += 5;
    if (mode == ScaleStripQuestionMode.intervals) base += 3;
    
    return base;
  }

  static String _generateScaleQuestionText(String scaleName, String rootNote, ScaleStripQuestionMode mode) {
    switch (mode) {
      case ScaleStripQuestionMode.construction:
        return 'Select all notes in the $rootNote ${scaleName.toLowerCase()} scale';
      case ScaleStripQuestionMode.intervals:
        return 'Fill out the intervals for a ${scaleName.toLowerCase()} scale';
      case ScaleStripQuestionMode.pattern:
        return 'Select the notes that follow the ${scaleName.toLowerCase()} pattern starting from $rootNote';
      default:
        return 'Complete the ${scaleName.toLowerCase()} scale';
    }
  }

  static String _generateChordQuestionText(String chordType, String rootNote, ScaleStripQuestionMode mode) {
    final chord = Chord.get(chordType);
    final symbol = chord?.getSymbol(rootNote) ?? '$rootNote$chordType';
    
    switch (mode) {
      case ScaleStripQuestionMode.construction:
        return 'Construct a $symbol chord';
      case ScaleStripQuestionMode.intervals:
        return 'Select the intervals for a ${chord?.displayName ?? chordType} chord';
      default:
        return 'Build a $symbol chord';
    }
  }

  static List<String> _generateScaleHints(String scaleName, ScaleStripQuestionMode mode) {
    final hints = <String>[];
    final pattern = ScaleStripUtils.getScalePattern(scaleName);
    
    if (pattern.isNotEmpty) {
      hints.add('Pattern: ${pattern.join('-')} (W=whole, H=half step)');
    }
    
    if (mode == ScaleStripQuestionMode.pattern) {
      hints.add('Focus on the interval relationships between notes');
    }
    
    return hints;
  }

  static List<String> _generateChordHints(String chordType, ScaleStripQuestionMode mode) {
    final chord = Chord.get(chordType);
    final hints = <String>[];
    
    if (chord != null) {
      hints.add('Intervals from root: ${chord.intervals.join(', ')} semitones');
      hints.add('Chord quality: ${ScaleStripUtils.getChordQuality(chordType)}');
    }
    
    return hints;
  }

  static List<String> _generateScaleTags(String scaleName) {
    return ['scales', scaleName.toLowerCase().replaceAll(' ', '-')];
  }

  static List<String> _generateChordTags(String chordType) {
    final chord = Chord.get(chordType);
    final tags = ['chords', chordType];
    if (chord != null) {
      tags.add(chord.category.toLowerCase().replaceAll(' ', '-'));
    }
    return tags;
  }
}

/// Internal validation result
class _ValidationResult {
  const _ValidationResult({required this.score, required this.feedback});
  final double score;
  final String feedback;
}