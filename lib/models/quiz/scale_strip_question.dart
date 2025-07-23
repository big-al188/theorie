// lib/models/quiz/scale_strip_question.dart

import 'package:flutter/foundation.dart';
import 'quiz_question.dart';

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

  /// Whether to highlight the root note
  final bool highlightRoot;

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showIntervalLabels': showIntervalLabels,
      'showNoteLabels': showNoteLabels,
      'allowMultipleSelection': allowMultipleSelection,
      'displayMode': displayMode.toString(),
      'preHighlightedPositions': preHighlightedPositions.toList(),
      'rootNote': rootNote,
      'octaveCount': octaveCount,
      'validationMode': validationMode.toString(),
      'showEmptyPositions': showEmptyPositions,
      'highlightRoot': highlightRoot,
    };
  }

  factory ScaleStripConfiguration.fromJson(Map<String, dynamic> json) {
    return ScaleStripConfiguration(
      showIntervalLabels: json['showIntervalLabels'] ?? true,
      showNoteLabels: json['showNoteLabels'] ?? true,
      allowMultipleSelection: json['allowMultipleSelection'] ?? true,
      displayMode: ScaleStripMode.values.firstWhere(
        (mode) => mode.toString() == json['displayMode'],
        orElse: () => ScaleStripMode.intervals,
      ),
      preHighlightedPositions: Set<int>.from(json['preHighlightedPositions'] ?? []),
      rootNote: json['rootNote'] ?? 'C',
      octaveCount: json['octaveCount'] ?? 1,
      validationMode: ValidationMode.values.firstWhere(
        (mode) => mode.toString() == json['validationMode'],
        orElse: () => ValidationMode.exactPositions,
      ),
      showEmptyPositions: json['showEmptyPositions'] ?? false,
      highlightRoot: json['highlightRoot'] ?? true,
    );
  }
}

/// Display modes for the scale strip
enum ScaleStripMode {
  intervals,      // Show interval numbers (1, 2, 3, etc.)
  noteNames,      // Show note names (C, D, E, etc.)
  fillInBlanks,   // Show blanks to fill in
  construction,   // Construction mode for chords/scales
}

/// Validation modes for answers
enum ValidationMode {
  exactPositions,  // Must select exact chromatic positions
  noteNames,       // Correct notes in any octave
  intervals,       // Correct interval relationships
  pattern,         // Pattern recognition (e.g., W-W-H-W-W-W-H)
}

/// Represents a user's answer selection on the scale strip
class ScaleStripAnswer {
  const ScaleStripAnswer({
    required this.selectedPositions,
    required this.selectedNotes,
    this.timeTaken,
  });

  /// Chromatic positions selected (0-11, where 0 = C)
  final Set<int> selectedPositions;

  /// Note names selected (for note-based validation)
  final Set<String> selectedNotes;

  /// Time taken to answer (optional)
  final Duration? timeTaken;

  bool get isEmpty => selectedPositions.isEmpty && selectedNotes.isEmpty;

  ScaleStripAnswer copyWith({
    Set<int>? selectedPositions,
    Set<String>? selectedNotes,
    Duration? timeTaken,
  }) {
    return ScaleStripAnswer(
      selectedPositions: selectedPositions ?? this.selectedPositions,
      selectedNotes: selectedNotes ?? this.selectedNotes,
      timeTaken: timeTaken ?? this.timeTaken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedPositions': selectedPositions.toList(),
      'selectedNotes': selectedNotes.toList(),
      'timeTaken': timeTaken?.inMilliseconds,
    };
  }

  factory ScaleStripAnswer.fromJson(Map<String, dynamic> json) {
    return ScaleStripAnswer(
      selectedPositions: Set<int>.from(json['selectedPositions'] ?? []),
      selectedNotes: Set<String>.from(json['selectedNotes'] ?? []),
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
        setEquals(other.selectedNotes, selectedNotes);
  }

  @override
  int get hashCode => Object.hash(selectedPositions, selectedNotes);

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
      feedback: result.feedback,
      explanation: explanation,
    );
  }

  @override
  double calculateScore(dynamic userAnswer, {Duration? timeTaken}) {
    if (userAnswer is! ScaleStripAnswer) return 0.0;
    
    final result = _validateScaleStripAnswer(userAnswer);
    return result.score;
  }

  /// Validates a scale strip answer based on the configuration
  ValidationResult _validateScaleStripAnswer(ScaleStripAnswer userAnswer) {
    switch (configuration.validationMode) {
      case ValidationMode.exactPositions:
        return _validateExactPositions(userAnswer);
      case ValidationMode.noteNames:
        return _validateNoteNames(userAnswer);
      case ValidationMode.intervals:
        return _validateIntervals(userAnswer);
      case ValidationMode.pattern:
        return _validatePattern(userAnswer);
    }
  }

  /// Validates exact chromatic positions
  ValidationResult _validateExactPositions(ScaleStripAnswer userAnswer) {
    final correctPositions = correctAnswer.selectedPositions;
    final userPositions = userAnswer.selectedPositions;

    final correctCount = userPositions.intersection(correctPositions).length;
    final totalCorrect = correctPositions.length;
    final extraSelections = userPositions.difference(correctPositions).length;

    double score = correctCount / totalCorrect;
    
    // Penalize extra selections
    if (extraSelections > 0) {
      score = (score - (extraSelections * 0.1)).clamp(0.0, 1.0);
    }

    String feedback = _generatePositionFeedback(
      correctCount, totalCorrect, extraSelections, userPositions, correctPositions
    );

    return ValidationResult(score: score, feedback: feedback);
  }

  /// Validates note names regardless of octave
  ValidationResult _validateNoteNames(ScaleStripAnswer userAnswer) {
    final correctNotes = correctAnswer.selectedNotes;
    final userNotes = userAnswer.selectedNotes;

    final correctCount = userNotes.intersection(correctNotes).length;
    final totalCorrect = correctNotes.length;
    final extraSelections = userNotes.difference(correctNotes).length;

    double score = correctCount / totalCorrect;
    
    if (extraSelections > 0) {
      score = (score - (extraSelections * 0.1)).clamp(0.0, 1.0);
    }

    String feedback = _generateNoteFeedback(
      correctCount, totalCorrect, extraSelections, userNotes, correctNotes
    );

    return ValidationResult(score: score, feedback: feedback);
  }

  /// Validates interval relationships
  ValidationResult _validateIntervals(ScaleStripAnswer userAnswer) {
    // Convert positions to intervals from root
    final userIntervals = _positionsToIntervals(userAnswer.selectedPositions);
    final correctIntervals = _positionsToIntervals(correctAnswer.selectedPositions);

    final correctCount = userIntervals.intersection(correctIntervals).length;
    final totalCorrect = correctIntervals.length;

    final score = correctCount / totalCorrect;
    final feedback = 'You identified $correctCount of $totalCorrect intervals correctly.';

    return ValidationResult(score: score, feedback: feedback);
  }

  /// Validates scale patterns
  ValidationResult _validatePattern(ScaleStripAnswer userAnswer) {
    final userPattern = _generatePattern(userAnswer.selectedPositions);
    final correctPattern = _generatePattern(correctAnswer.selectedPositions);

    final score = userPattern == correctPattern ? 1.0 : 0.0;
    final feedback = score == 1.0 
      ? 'Correct pattern!' 
      : 'Pattern doesn\'t match. Expected: $correctPattern, Got: $userPattern';

    return ValidationResult(score: score, feedback: feedback);
  }

  /// Convert chromatic positions to intervals from root
  Set<int> _positionsToIntervals(Set<int> positions) {
    if (positions.isEmpty) return {};
    
    final root = positions.first; // Assume first position is root
    return positions.map((pos) => (pos - root) % 12).toSet();
  }

  /// Generate pattern string from positions (W = whole step, H = half step)
  String _generatePattern(Set<int> positions) {
    if (positions.length < 2) return '';
    
    final sortedPositions = positions.toList()..sort();
    final intervals = <String>[];
    
    for (int i = 1; i < sortedPositions.length; i++) {
      final diff = sortedPositions[i] - sortedPositions[i - 1];
      intervals.add(diff == 2 ? 'W' : 'H');
    }
    
    return intervals.join('-');
  }

  /// Generate feedback for position validation
  String _generatePositionFeedback(
    int correctCount, 
    int totalCorrect, 
    int extraSelections,
    Set<int> userPositions,
    Set<int> correctPositions,
  ) {
    final buffer = StringBuffer();
    
    if (correctCount == totalCorrect && extraSelections == 0) {
      buffer.writeln('Perfect! You selected all the correct positions.');
    } else {
      buffer.writeln('You selected $correctCount of $totalCorrect correct positions.');
      
      if (extraSelections > 0) {
        buffer.writeln('You also selected $extraSelections incorrect position(s).');
      }
      
      final missed = correctPositions.difference(userPositions);
      if (missed.isNotEmpty) {
        buffer.writeln('You missed positions: ${missed.join(', ')}');
      }
    }
    
    return buffer.toString();
  }

  /// Generate feedback for note validation
  String _generateNoteFeedback(
    int correctCount, 
    int totalCorrect, 
    int extraSelections,
    Set<String> userNotes,
    Set<String> correctNotes,
  ) {
    final buffer = StringBuffer();
    
    if (correctCount == totalCorrect && extraSelections == 0) {
      buffer.writeln('Excellent! You identified all the correct notes.');
    } else {
      buffer.writeln('You identified $correctCount of $totalCorrect correct notes.');
      
      if (extraSelections > 0) {
        buffer.writeln('You also selected $extraSelections incorrect note(s).');
      }
      
      final missed = correctNotes.difference(userNotes);
      if (missed.isNotEmpty) {
        buffer.writeln('You missed notes: ${missed.join(', ')}');
      }
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'topic': topic.toString(),
      'difficulty': difficulty.toString(),
      'pointValue': pointValue,
      'explanation': explanation,
      'hints': hints,
      'tags': tags,
      'timeLimit': timeLimit,
      'allowPartialCredit': allowPartialCredit,
      'type': type.toString(),
      'configuration': configuration.toJson(),
      'correctAnswer': correctAnswer.toJson(),
      'scaleType': scaleType,
      'questionMode': questionMode.toString(),
    };
  }

  factory ScaleStripQuestion.fromJson(Map<String, dynamic> json) {
    return ScaleStripQuestion(
      id: json['id'],
      questionText: json['questionText'],
      topic: QuestionTopic.values.firstWhere(
        (t) => t.toString() == json['topic'],
        orElse: () => QuestionTopic.scales,
      ),
      difficulty: QuestionDifficulty.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
        orElse: () => QuestionDifficulty.beginner,
      ),
      pointValue: json['pointValue'],
      explanation: json['explanation'],
      hints: List<String>.from(json['hints'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      timeLimit: json['timeLimit'],
      allowPartialCredit: json['allowPartialCredit'] ?? true,
      configuration: ScaleStripConfiguration.fromJson(json['configuration']),
      correctAnswer: ScaleStripAnswer.fromJson(json['correctAnswer']),
      scaleType: json['scaleType'] ?? 'major',
      questionMode: ScaleStripQuestionMode.values.firstWhere(
        (m) => m.toString() == json['questionMode'],
        orElse: () => ScaleStripQuestionMode.intervals,
      ),
    );
  }
}

/// Different modes for scale strip questions
enum ScaleStripQuestionMode {
  intervals,      // Fill in scale intervals
  notes,          // Identify note names
  construction,   // Construct scales/chords
  pattern,        // Pattern recognition
}

/// Result of answer validation (internal helper class)
class ValidationResult {
  const ValidationResult({
    required this.score,
    required this.feedback,  
  });

  final double score;
  final String feedback;
}