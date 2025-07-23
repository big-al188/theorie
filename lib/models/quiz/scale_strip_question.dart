// lib/models/quiz/scale_strip_question.dart

import 'package:flutter/foundation.dart';
import 'quiz_question.dart';

/// Enumeration for different interval label formats
enum IntervalLabelFormat {
  /// Numeric labels: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
  numeric,
  /// Scale degree labels with accidentals: 1, ♭2, 2, ♭3, 3, 4, ♭5, 5, ♭6, 6, ♭7, 7, 8
  scaleDegreesWithAccidentals,
  /// Roman numerals: I, ii, iii, IV, V, vi, vii°
  romanNumerals,
}

/// Configuration for scale strip display and interaction
class ScaleStripConfiguration {
  const ScaleStripConfiguration({
    this.showIntervalLabels = true,
    this.showNoteLabels = true,
    this.allowMultipleSelection = true,
    this.displayMode = ScaleStripMode.intervals,
    this.preHighlightedPositions = const {},
    this.rootNote = 'C',
    this.octaveCount = 1,
    this.validationMode = ValidationMode.exactPositions,
    this.showEmptyPositions = false,
    this.highlightRoot = true,
    this.lockPreHighlighted = false,
    this.useDropdownSelection = false,
    this.enableOctaveDistinction = false,
    this.allowPartialCreditForOctaves = false,
    this.showFirstNoteAsReference = false,
    this.firstNotePosition,
    this.useScaleDegreeLabels = false,
    this.intervalLabelFormat = IntervalLabelFormat.numeric,
    this.showPreHighlightedLabels = false,
  });

  /// Whether to show interval numbers on the scale strip
  final bool showIntervalLabels;

  /// Whether to show note names on the scale strip
  final bool showNoteLabels;

  /// Whether multiple positions can be selected
  final bool allowMultipleSelection;

  /// The display mode for the scale strip
  final ScaleStripMode displayMode;

  /// Positions that are pre-highlighted (0-based from C)
  final Set<int> preHighlightedPositions;

  /// Root note for the scale (e.g., 'C', 'D', 'F#')
  final String rootNote;

  /// Number of octaves to display
  final int octaveCount;

  /// How to validate the user's answer
  final ValidationMode validationMode;

  /// Whether to show empty positions as blanks to fill
  final bool showEmptyPositions;

  /// Whether to highlight the root note with special styling
  final bool highlightRoot;

  /// Whether pre-highlighted positions should be locked (non-interactive)
  final bool lockPreHighlighted;

  /// Whether to use dropdown selection for note names instead of direct selection
  final bool useDropdownSelection;

  /// Whether to distinguish between different octaves in validation
  final bool enableOctaveDistinction;

  /// Whether to award partial credit for correct notes in wrong octaves
  final bool allowPartialCreditForOctaves;

  /// Whether to show the first note as a reference without special highlighting
  final bool showFirstNoteAsReference;

  /// Position of the first note to show as reference (if showFirstNoteAsReference is true)
  final int? firstNotePosition;

  /// Whether to use scale degree labels instead of numeric labels
  final bool useScaleDegreeLabels;

  /// Format for interval labels
  final IntervalLabelFormat intervalLabelFormat;

  /// Whether to show correct labels for pre-highlighted positions
  final bool showPreHighlightedLabels;

  ScaleStripConfiguration copyWith({
    bool? showIntervalLabels,
    bool? showNoteLabels,
    bool? allowMultipleSelection,
    ScaleStripMode? displayMode,
    Set<int>? preHighlightedPositions,
    String? rootNote,
    int? octaveCount,
    ValidationMode? validationMode,
    bool? showEmptyPositions,
    bool? highlightRoot,
    bool? lockPreHighlighted,
    bool? useDropdownSelection,
    bool? enableOctaveDistinction,
    bool? allowPartialCreditForOctaves,
    bool? showFirstNoteAsReference,
    int? firstNotePosition,
    bool? useScaleDegreeLabels,
    IntervalLabelFormat? intervalLabelFormat,
    bool? showPreHighlightedLabels,
  }) {
    return ScaleStripConfiguration(
      showIntervalLabels: showIntervalLabels ?? this.showIntervalLabels,
      showNoteLabels: showNoteLabels ?? this.showNoteLabels,
      allowMultipleSelection: allowMultipleSelection ?? this.allowMultipleSelection,
      displayMode: displayMode ?? this.displayMode,
      preHighlightedPositions: preHighlightedPositions ?? this.preHighlightedPositions,
      rootNote: rootNote ?? this.rootNote,
      octaveCount: octaveCount ?? this.octaveCount,
      validationMode: validationMode ?? this.validationMode,
      showEmptyPositions: showEmptyPositions ?? this.showEmptyPositions,
      highlightRoot: highlightRoot ?? this.highlightRoot,
      lockPreHighlighted: lockPreHighlighted ?? this.lockPreHighlighted,
      useDropdownSelection: useDropdownSelection ?? this.useDropdownSelection,
      enableOctaveDistinction: enableOctaveDistinction ?? this.enableOctaveDistinction,
      allowPartialCreditForOctaves: allowPartialCreditForOctaves ?? this.allowPartialCreditForOctaves,
      showFirstNoteAsReference: showFirstNoteAsReference ?? this.showFirstNoteAsReference,
      firstNotePosition: firstNotePosition ?? this.firstNotePosition,
      useScaleDegreeLabels: useScaleDegreeLabels ?? this.useScaleDegreeLabels,
      intervalLabelFormat: intervalLabelFormat ?? this.intervalLabelFormat,
      showPreHighlightedLabels: showPreHighlightedLabels ?? this.showPreHighlightedLabels,
    );
  }
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

/// Enhanced answer class with octave awareness and partial credit support
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
  /// Map of note name to list of valid octaves: {'C': [3, 4], 'E': [3, 4]}
  final Map<String, List<int>> expectedOctavePatterns;

  /// Alternative answers that should receive partial credit
  final List<Set<String>> partialCreditAnswers;

  /// Time taken to provide this answer
  final Duration? timeTaken;

  bool get isEmpty => selectedPositions.isEmpty && selectedNotes.isEmpty;

  /// Get note names without octave info
  Set<String> get noteNamesOnly {
    return selectedNotes.map((note) {
      // Remove octave number if present (e.g., 'C4' -> 'C')
      return note.replaceAll(RegExp(r'\d+$'), '');
    }).toSet();
  }

  /// Check if this answer has octave information
  bool get hasOctaveInfo {
    return selectedNotes.any((note) => RegExp(r'\d+$').hasMatch(note));
  }

  ScaleStripAnswer copyWith({
    Set<int>? selectedPositions,
    Set<String>? selectedNotes,
    Map<String, List<int>>? expectedOctavePatterns,
    List<Set<String>>? partialCreditAnswers,
    Duration? timeTaken,
  }) {
    return ScaleStripAnswer(
      selectedPositions: selectedPositions ?? this.selectedPositions,
      selectedNotes: selectedNotes ?? this.selectedNotes,
      expectedOctavePatterns: expectedOctavePatterns ?? this.expectedOctavePatterns,
      partialCreditAnswers: partialCreditAnswers ?? this.partialCreditAnswers,
      timeTaken: timeTaken ?? this.timeTaken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedPositions': selectedPositions.toList(),
      'selectedNotes': selectedNotes.toList(),
      'expectedOctavePatterns': expectedOctavePatterns.map(
        (key, value) => MapEntry(key, value),
      ),
      'partialCreditAnswers': partialCreditAnswers
          .map((answer) => answer.toList())
          .toList(),
      'timeTaken': timeTaken?.inMilliseconds,
    };
  }

  factory ScaleStripAnswer.fromJson(Map<String, dynamic> json) {
    return ScaleStripAnswer(
      selectedPositions: Set<int>.from(json['selectedPositions'] ?? []),
      selectedNotes: Set<String>.from(json['selectedNotes'] ?? []),
      expectedOctavePatterns: (json['expectedOctavePatterns'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, List<int>.from(value))) ?? {},
      partialCreditAnswers: (json['partialCreditAnswers'] as List?)
          ?.map((answer) => Set<String>.from(answer))
          .toList() ?? [],
      timeTaken: json['timeTaken'] != null 
        ? Duration(milliseconds: json['timeTaken']) 
        : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScaleStripAnswer &&
        setEquals(other.selectedPositions, selectedPositions) &&
        setEquals(other.selectedNotes, selectedNotes) &&
        mapEquals(other.expectedOctavePatterns, expectedOctavePatterns);
  }

  @override
  int get hashCode => Object.hash(
    selectedPositions, 
    selectedNotes, 
    expectedOctavePatterns,
  );

  @override
  String toString() => 'ScaleStripAnswer(positions: $selectedPositions, notes: $selectedNotes)';
}

/// Scale strip question implementation for interactive scale exercises
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

    final result = _validateScaleStripAnswer(userAnswer);
    
    return QuestionResult(
      isCorrect: result.score >= 0.7, // 70% threshold for correct
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      partialCreditScore: result.score < 1.0 ? result.score : null,
      feedback: result.feedback,
      explanation: explanation,
    );
  }

  @override
  double calculateScore(dynamic userAnswer, {Duration? timeTaken}) {
    if (userAnswer is! ScaleStripAnswer) {
      return 0.0;
    }

    final result = _validateScaleStripAnswer(userAnswer);
    return result.score;
  }

  /// Internal validation logic with enhanced octave and partial credit support
  _ValidationResult _validateScaleStripAnswer(ScaleStripAnswer userAnswer) {
    switch (configuration.validationMode) {
      case ValidationMode.exactPositions:
        return _validateExactPositions(userAnswer);
      
      case ValidationMode.noteNames:
        return _validateNoteNames(userAnswer);
      
      case ValidationMode.noteNamesWithOctaves:
        return _validateNoteNamesWithOctaves(userAnswer);
      
      case ValidationMode.noteNamesWithPartialCredit:
        return _validateNoteNamesWithPartialCredit(userAnswer);
      
      case ValidationMode.pattern:
        return _validatePattern(userAnswer);
    }
  }

  _ValidationResult _validateExactPositions(ScaleStripAnswer userAnswer) {
    final correctPositions = correctAnswer.selectedPositions;
    final userPositions = userAnswer.selectedPositions;
    
    final intersection = correctPositions.intersection(userPositions);
    final score = intersection.length / correctPositions.length;
    
    String feedback;
    if (score == 1.0) {
      feedback = 'Perfect! All positions are correct.';
    } else if (score >= 0.7) {
      feedback = 'Good job! Most positions are correct.';
    } else if (score >= 0.3) {
      feedback = 'Some positions are correct, but review the pattern.';
    } else {
      feedback = 'Review the scale pattern and try again.';
    }
    
    return _ValidationResult(score: score, feedback: feedback);
  }

  _ValidationResult _validateNoteNames(ScaleStripAnswer userAnswer) {
    final correctNotes = correctAnswer.noteNamesOnly;
    final userNotes = userAnswer.noteNamesOnly;
    
    final intersection = correctNotes.intersection(userNotes);
    final score = intersection.length / correctNotes.length;
    
    String feedback;
    if (score == 1.0) {
      feedback = 'Excellent! All note names are correct.';
    } else if (score >= 0.7) {
      feedback = 'Well done! Most note names are correct.';
    } else {
      feedback = 'Review the note names and try again.';
    }
    
    return _ValidationResult(score: score, feedback: feedback);
  }

  _ValidationResult _validateNoteNamesWithOctaves(ScaleStripAnswer userAnswer) {
    final correctNotes = correctAnswer.selectedNotes;
    final userNotes = userAnswer.selectedNotes;
    
    final intersection = correctNotes.intersection(userNotes);
    final score = intersection.length / correctNotes.length;
    
    String feedback;
    if (score == 1.0) {
      feedback = 'Perfect! All notes and octaves are correct.';
    } else if (score >= 0.7) {
      feedback = 'Good! Most notes and octaves are correct.';
    } else {
      feedback = 'Consider the octave placement carefully.';
    }
    
    return _ValidationResult(score: score, feedback: feedback);
  }

  _ValidationResult _validateNoteNamesWithPartialCredit(ScaleStripAnswer userAnswer) {
    final correctNotes = correctAnswer.selectedNotes;
    final userNotes = userAnswer.selectedNotes;
    
    // First check for exact match
    final exactMatch = correctNotes.intersection(userNotes);
    if (exactMatch.length == correctNotes.length) {
      return _ValidationResult(score: 1.0, feedback: 'Perfect! All notes and octaves are correct.');
    }
    
    // Check for partial credit answers
    for (final partialAnswer in correctAnswer.partialCreditAnswers) {
      final partialMatch = partialAnswer.intersection(userNotes);
      if (partialMatch.length == partialAnswer.length) {
        return _ValidationResult(
          score: 0.8,
          feedback: 'Good! Correct notes, consider the optimal octave placement.',
        );
      }
    }
    
    // Check for correct note names regardless of octave
    final correctNoteNames = correctAnswer.noteNamesOnly;
    final userNoteNames = userAnswer.noteNamesOnly;
    final noteNameMatch = correctNoteNames.intersection(userNoteNames);
    
    if (noteNameMatch.length == correctNoteNames.length) {
      return _ValidationResult(
        score: 0.6,
        feedback: 'Correct note names! Pay attention to octave placement.',
      );
    }
    
    // Partial note name match
    final score = noteNameMatch.length / correctNoteNames.length;
    return _ValidationResult(
      score: score * 0.5, // Reduced score for incomplete answer
      feedback: 'Some notes are correct. Review the complete pattern.',
    );
  }

  _ValidationResult _validatePattern(ScaleStripAnswer userAnswer) {
    // For pattern validation, we check if the user's selection follows
    // the expected pattern regardless of starting position
    final userPositions = userAnswer.selectedPositions.toList()..sort();
    final correctPositions = correctAnswer.selectedPositions.toList()..sort();
    
    if (userPositions.length != correctPositions.length) {
      return _ValidationResult(
        score: 0.0,
        feedback: 'Incorrect number of notes. Check the pattern.',
      );
    }
    
    // Calculate intervals between selected positions
    final userIntervals = <int>[];
    for (int i = 1; i < userPositions.length; i++) {
      userIntervals.add(userPositions[i] - userPositions[i - 1]);
    }
    
    final correctIntervals = <int>[];
    for (int i = 1; i < correctPositions.length; i++) {
      correctIntervals.add(correctPositions[i] - correctPositions[i - 1]);
    }
    
    // Check if interval patterns match
    bool patternsMatch = listEquals(userIntervals, correctIntervals);
    
    if (patternsMatch) {
      return _ValidationResult(score: 1.0, feedback: 'Excellent! Pattern is correct.');
    } else {
      return _ValidationResult(
        score: 0.0,
        feedback: 'Pattern doesn\'t match. Review the interval structure.',
      );
    }
  }

  /// Get interval label for a given position based on configuration
  String getIntervalLabel(int position) {
    switch (configuration.intervalLabelFormat) {
      case IntervalLabelFormat.numeric:
        return (position + 1).toString();
      
      case IntervalLabelFormat.scaleDegreesWithAccidentals:
        return _getScaleDegreeLabel(position);
      
      case IntervalLabelFormat.romanNumerals:
        return _getRomanNumeralLabel(position);
    }
  }

  String _getScaleDegreeLabel(int position) {
    const labels = [
      '1', '♭2', '2', '♭3', '3', '4', '♭5', '5', '♭6', '6', '♭7', '7'
    ];
    return labels[position % 12];
  }

  String _getRomanNumeralLabel(int position) {
    const labels = [
      'I', '♭II', 'II', '♭III', 'III', 'IV', '♭V', 'V', '♭VI', 'VI', '♭VII', 'VII'
    ];
    return labels[position % 12];
  }
}

/// Internal result class for validation
class _ValidationResult {
  const _ValidationResult({
    required this.score,
    required this.feedback,
  });

  final double score;
  final String feedback;
}