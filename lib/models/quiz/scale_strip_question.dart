// lib/models/quiz/scale_strip_question.dart

import 'package:flutter/foundation.dart';
import 'quiz_question.dart';
import '../music/scale.dart';
import '../music/chord.dart';
import '../../utils/scale_strip_utils.dart';
import '../../utils/music_utils.dart';
import '../music/note.dart';

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
  /// Enhanced validation with enharmonic partial credit
  noteNamesWithEnharmonicCredit,
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
    this.includeOctaveNote = true,
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
    this.allowEnharmonicPartialCredit = true,
    this.clearSelectionOnStart = false,
    this.validateSelectionOnChange = false,
    this.showFirstNoteAsReference = false,
    this.firstNotePosition,
    this.lockReferenceNote = false,
    this.referenceNoteLabel,
    this.keyContext,
    this.fillScreenWidth = true,
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

  /// Whether to include the octave note (position 12 for C to C)
  final bool includeOctaveNote;

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

  /// Whether to award partial credit for enharmonic equivalents
  final bool allowEnharmonicPartialCredit;

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

  /// Key context for determining sharp/flat preference (e.g., 'G', 'Gb', 'F#')
  final String? keyContext;

  /// Whether to fill the available screen width
  final bool fillScreenWidth;

  /// Get the total number of positions including octave if enabled
  int get totalPositions {
    final basePositions = 12 * octaveCount;
    return includeOctaveNote ? basePositions + 1 : basePositions;
  }

  /// FIXED: Get all available note names for a position based on context
  /// For dropdown mode, this returns valid enharmonic equivalents
  List<String> getAvailableNotesForPosition(int position) {
    if (useDropdownSelection) {
      // For dropdown selection, return valid enharmonic equivalents for this position
      return ScaleStripUtils.getAllNotesForPosition(keyContext ?? rootNote, position);
    } else {
      // For non-dropdown mode, return all possible notes for educational purposes
      return ScaleStripUtils.getAllPossibleNoteNames();
    }
  }

  /// NEW: Get ALL possible note names for dropdown selection (educational mode)
  List<String> getAllPossibleNoteNames() {
    return ScaleStripUtils.getAllPossibleNoteNames();
  }

  /// Get the preferred note name for a position based on key context
  String getPreferredNoteForPosition(int position) {
    return ScaleStripUtils.getPreferredNoteNameForPosition(keyContext ?? rootNote, position);
  }

  ScaleStripConfiguration copyWith({
    bool? showIntervalLabels,
    bool? showNoteLabels,
    bool? allowMultipleSelection,
    ScaleStripMode? displayMode,
    String? rootNote,
    int? octaveCount,
    bool? includeOctaveNote,
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
    bool? allowEnharmonicPartialCredit,
    bool? clearSelectionOnStart,
    bool? validateSelectionOnChange,
    bool? showFirstNoteAsReference,
    int? firstNotePosition,
    bool? lockReferenceNote,
    String? referenceNoteLabel,
    String? keyContext,
    bool? fillScreenWidth,
  }) {
    return ScaleStripConfiguration(
      showIntervalLabels: showIntervalLabels ?? this.showIntervalLabels,
      showNoteLabels: showNoteLabels ?? this.showNoteLabels,
      allowMultipleSelection: allowMultipleSelection ?? this.allowMultipleSelection,
      displayMode: displayMode ?? this.displayMode,
      rootNote: rootNote ?? this.rootNote,
      octaveCount: octaveCount ?? this.octaveCount,
      includeOctaveNote: includeOctaveNote ?? this.includeOctaveNote,
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
      allowEnharmonicPartialCredit: allowEnharmonicPartialCredit ?? this.allowEnharmonicPartialCredit,
      clearSelectionOnStart: clearSelectionOnStart ?? this.clearSelectionOnStart,
      validateSelectionOnChange: validateSelectionOnChange ?? this.validateSelectionOnChange,
      showFirstNoteAsReference: showFirstNoteAsReference ?? this.showFirstNoteAsReference,
      firstNotePosition: firstNotePosition ?? this.firstNotePosition,
      lockReferenceNote: lockReferenceNote ?? this.lockReferenceNote,
      referenceNoteLabel: referenceNoteLabel ?? this.referenceNoteLabel,
      keyContext: keyContext ?? this.keyContext,
      fillScreenWidth: fillScreenWidth ?? this.fillScreenWidth,
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
      includeOctaveNote == other.includeOctaveNote &&
      validationMode == other.validationMode &&
      setEquals(preHighlightedPositions, other.preHighlightedPositions) &&
      keyContext == other.keyContext &&
      fillScreenWidth == other.fillScreenWidth;

  @override
  int get hashCode => Object.hashAll([
    showIntervalLabels, showNoteLabels, allowMultipleSelection,
    displayMode, rootNote, octaveCount, includeOctaveNote, validationMode, 
    preHighlightedPositions, keyContext, fillScreenWidth,
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

  bool get isEmpty => selectedPositions.isEmpty && selectedNotes.isEmpty;

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

/// Enhanced scale strip question with improved validation
class ScaleStripQuestion extends QuizQuestion {
  const ScaleStripQuestion({
    required String id,
    required String questionText,
    required QuestionTopic topic,
    required QuestionDifficulty difficulty,
    required int pointValue,
    required this.configuration,
    required ScaleStripAnswer correctAnswer,
    this.scaleType,
    this.questionMode = ScaleStripQuestionMode.notes,
    String? explanation,
    List<String>? hints,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) : _correctAnswer = correctAnswer,
       super(
          id: id,
          questionText: questionText,
          topic: topic,
          difficulty: difficulty,
          pointValue: pointValue,
          explanation: explanation,
          hints: hints ?? const [],
          tags: tags ?? const [],
        );

  final ScaleStripConfiguration configuration;
  final ScaleStripAnswer _correctAnswer;
  final String? scaleType;
  final ScaleStripQuestionMode questionMode;

  @override
  QuestionType get type => QuestionType.scaleStrip;

  @override
  ScaleStripAnswer get correctAnswer => _correctAnswer;

  @override
  QuestionResult validateAnswer(dynamic answer) {
    if (answer is! ScaleStripAnswer) {
      return QuestionResult(
        isCorrect: false,
        userAnswer: answer,
        correctAnswer: _correctAnswer,
        feedback: 'Invalid answer type. Expected ScaleStripAnswer.',
      );
    }

    return _validateScaleStripAnswer(answer);
  }

  QuestionResult _validateScaleStripAnswer(ScaleStripAnswer answer) {
    // Debug logging for troubleshooting
    if (kDebugMode) {
      print('=== VALIDATION DEBUG ===');
      print('Validation mode: ${configuration.validationMode}');
      print('Display mode: ${configuration.displayMode}');
      print('Key context: ${configuration.keyContext}');
      print('======================');
    }
    
    switch (configuration.validationMode) {
      case ValidationMode.exactPositions:
        return _validateExactPositions(answer);
      case ValidationMode.noteNames:
        return _validateNoteNamesWithEnharmonicCredit(answer);
      case ValidationMode.noteNamesWithEnharmonicCredit:
        return _validateNoteNamesWithEnharmonicCredit(answer);
      case ValidationMode.noteNamesWithOctaves:
        return _validateNoteNamesWithEnharmonicCredit(answer);
      case ValidationMode.pattern:
        return _validateExactPositions(answer);
      case ValidationMode.noteNamesWithPartialCredit:
        return _validateNoteNamesWithEnharmonicCredit(answer);
    }
  }

  QuestionResult _validateExactPositions(ScaleStripAnswer answer) {
    final correctPositions = _correctAnswer.selectedPositions;
    final userPositions = answer.selectedPositions;
    
    final isCorrect = setEquals(correctPositions, userPositions);
    
    return QuestionResult(
      isCorrect: isCorrect,
      userAnswer: answer,
      correctAnswer: _correctAnswer,
      feedback: isCorrect 
          ? 'Correct! You selected all the right positions.'
          : 'Not quite right. Check which positions should be selected.',
    );
  }

  /// FIXED: Enhanced validation with better enharmonic handling for dropdown questions
  QuestionResult _validateNoteNamesWithEnharmonicCredit(ScaleStripAnswer answer) {
    final correctNotes = _correctAnswer.selectedNotes;
    final userNotes = answer.selectedNotes;
    
    // Debug logging for development
    if (kDebugMode) {
      print('Validating answer:');
      print('Correct notes: $correctNotes');
      print('User notes: $userNotes');
      print('User positions: ${answer.selectedPositions}');
      print('Correct positions: ${_correctAnswer.selectedPositions}');
      print('Key context: ${configuration.keyContext}');
    }
    
    // FIXED: For fill-in-the-blank questions, validate based on positions first
    if (configuration.displayMode == ScaleStripMode.fillInBlanks) {
      return _validateFillInBlanksQuestion(answer);
    }
    
    if (correctNotes.isEmpty || userNotes.isEmpty) {
      return QuestionResult(
        isCorrect: false,
        userAnswer: answer,
        correctAnswer: _correctAnswer,
        feedback: 'Please select some notes to answer the question.',
      );
    }
    
    // FIXED: Instead of comparing against stored correct notes,
    // generate the contextually correct spellings for the selected positions
    final expectedNotesForPositions = <String>{};
    final keyContext = configuration.keyContext ?? configuration.rootNote;
    
    for (final position in _correctAnswer.selectedPositions) {
      final contextuallyCorrectNote = configuration.getPreferredNoteForPosition(position);
      expectedNotesForPositions.add(contextuallyCorrectNote);
    }
    
    if (kDebugMode) {
      print('Expected notes for positions: $expectedNotesForPositions');
    }
    
    int contextuallyCorrectMatches = 0;
    int enharmonicMatches = 0;
    final totalExpected = expectedNotesForPositions.length;
    
    // Check for contextually correct matches first (these get full credit)
    for (final note in userNotes) {
      if (expectedNotesForPositions.contains(note)) {
        contextuallyCorrectMatches++;
      }
    }
    
    // Check for enharmonic matches (notes not already counted as contextually correct)
    final unmatchedUserNotes = userNotes.where((note) => !expectedNotesForPositions.contains(note)).toList();
    final unmatchedExpectedNotes = expectedNotesForPositions.where((note) => !userNotes.contains(note)).toList();
    
    for (final userNote in unmatchedUserNotes) {
      final userPc = _getNotePitchClass(userNote);
      for (final expectedNote in unmatchedExpectedNotes) {
        final expectedPc = _getNotePitchClass(expectedNote);
        if (userPc == expectedPc) {
          enharmonicMatches++;
          break; // Each user note can only match one expected note
        }
      }
    }
    
    final totalMatches = contextuallyCorrectMatches + enharmonicMatches;
    final isCorrect = contextuallyCorrectMatches == totalExpected && userNotes.length == totalExpected;
    final hasPartialCredit = !isCorrect && totalMatches > 0;
    
    if (kDebugMode) {
      print('Contextually correct: $contextuallyCorrectMatches');
      print('Enharmonic matches: $enharmonicMatches');
      print('Total matches: $totalMatches');
      print('Is correct: $isCorrect');
    }
    
    // Calculate partial credit score
    double? partialCreditScore;
    if (hasPartialCredit) {
      final correctScore = contextuallyCorrectMatches / totalExpected;
      final enharmonicScore = (enharmonicMatches / totalExpected) * 0.75; // 75% credit for enharmonics
      final excessPenalty = userNotes.length > totalExpected ? 
          (userNotes.length - totalExpected) / totalExpected * 0.25 : 0.0;
      partialCreditScore = (correctScore + enharmonicScore - excessPenalty).clamp(0.0, 1.0);
    }
    
    String feedback;
    if (isCorrect) {
      feedback = 'Excellent! All notes are correct with proper spelling for the key of $keyContext.';
    } else if (totalMatches == totalExpected && userNotes.length > totalExpected) {
      feedback = 'Good work! You have the right notes but selected too many. Remove the extras.';
    } else if (enharmonicMatches > 0 && contextuallyCorrectMatches < totalExpected) {
      feedback = 'Good work! Some notes are enharmonically correct but the key of $keyContext prefers different spellings.';
    } else if (contextuallyCorrectMatches > 0) {
      feedback = 'You\'re on the right track! ${contextuallyCorrectMatches} out of ${totalExpected} notes have the correct spelling for $keyContext.';
    } else if (totalMatches > 0) {
      feedback = 'You have some correct notes but they need proper spelling for the key of $keyContext.';
    } else {
      feedback = 'Focus on the correct notes and their proper spelling for the key of $keyContext.';
    }
    
    return QuestionResult(
      isCorrect: isCorrect,
      userAnswer: answer,
      correctAnswer: _correctAnswer,
      partialCreditScore: partialCreditScore,
      feedback: feedback,
    );
  }

  /// NEW: Specialized validation for fill-in-the-blank questions
  QuestionResult _validateFillInBlanksQuestion(ScaleStripAnswer answer) {
    final correctPositions = _correctAnswer.selectedPositions;
    final userPositions = answer.selectedPositions;
    final preHighlighted = configuration.preHighlightedPositions;
    
    // For fill-in-the-blank, we need to check only the positions that should be filled in
    final missingPositions = correctPositions.difference(preHighlighted);
    final userFilledPositions = userPositions.difference(preHighlighted);
    
    if (kDebugMode) {
      print('Fill-in validation:');
      print('Missing positions to fill: $missingPositions');
      print('User filled positions: $userFilledPositions');
      print('Pre-highlighted: $preHighlighted');
    }
    
    // Check if user filled the correct positions
    final correctFills = missingPositions.intersection(userFilledPositions);
    final incorrectFills = userFilledPositions.difference(missingPositions);
    
    final totalMissing = missingPositions.length;
    final correctFillCount = correctFills.length;
    final incorrectFillCount = incorrectFills.length;
    
    final isCorrect = correctFillCount == totalMissing && incorrectFillCount == 0;
    
    // Calculate partial credit
    double? partialCreditScore;
    if (!isCorrect && correctFillCount > 0) {
      final correctRatio = correctFillCount / totalMissing;
      final incorrectPenalty = incorrectFillCount / totalMissing * 0.5; // 50% penalty for wrong fills
      partialCreditScore = (correctRatio - incorrectPenalty).clamp(0.0, 1.0);
    }
    
    // Now validate the note names for the filled positions
    if (configuration.useDropdownSelection && answer.selectedNotes.isNotEmpty) {
      return _validateDropdownNoteNames(answer, correctFills, incorrectFills, partialCreditScore);
    }
    
    String feedback;
    if (isCorrect) {
      feedback = 'Perfect! You filled in all the missing notes correctly.';
    } else if (correctFillCount > 0) {
      feedback = 'Good work! You got ${correctFillCount} out of ${totalMissing} missing notes correct.';
      if (incorrectFillCount > 0) {
        feedback += ' Watch out for ${incorrectFillCount} incorrect selections.';
      }
    } else {
      feedback = 'Keep trying! Focus on which positions need to be filled in.';
    }
    
    return QuestionResult(
      isCorrect: isCorrect,
      userAnswer: answer,
      correctAnswer: _correctAnswer,
      partialCreditScore: partialCreditScore,
      feedback: feedback,
    );
  }

  /// NEW: Validate note names for dropdown selections
  QuestionResult _validateDropdownNoteNames(
    ScaleStripAnswer answer, 
    Set<int> correctFills, 
    Set<int> incorrectFills,
    double? basePartialScore,
  ) {
    final userNotes = answer.selectedNotes;
    final keyContext = configuration.keyContext ?? configuration.rootNote;
    
    // FIXED: Build expected notes based on key context, not stored correct notes
    final expectedNotesForFills = <String>{};
    for (final position in correctFills) {
      final expectedNote = configuration.getPreferredNoteForPosition(position);
      expectedNotesForFills.add(expectedNote);
    }
    
    if (kDebugMode) {
      print('Dropdown validation:');
      print('Correct fill positions: $correctFills');
      print('Expected notes for fills: $expectedNotesForFills');
      print('User notes: $userNotes');
    }
    
    int contextuallyCorrectMatches = 0;
    int enharmonicMatches = 0;
    
    // Check note name accuracy with key context priority
    for (final userNote in userNotes) {
      if (expectedNotesForFills.contains(userNote)) {
        contextuallyCorrectMatches++;
      } else {
        // Check for enharmonic equivalents
        final userPc = _getNotePitchClass(userNote);
        for (final expectedNote in expectedNotesForFills) {
          final expectedPc = _getNotePitchClass(expectedNote);
          if (userPc == expectedPc) {
            enharmonicMatches++;
            break;
          }
        }
      }
    }
    
    final totalCorrectFills = correctFills.length;
    final contextualAccuracy = totalCorrectFills > 0 ? contextuallyCorrectMatches / totalCorrectFills : 0.0;
    final enharmonicAccuracy = totalCorrectFills > 0 ? enharmonicMatches / totalCorrectFills : 0.0;
    
    // Combine position accuracy with note name accuracy
    double? finalPartialScore;
    if (basePartialScore != null) {
      // Weight: 60% position accuracy, 40% note spelling accuracy
      final noteAccuracy = contextualAccuracy + (enharmonicAccuracy * 0.75);
      finalPartialScore = (basePartialScore * 0.6 + noteAccuracy * 0.4).clamp(0.0, 1.0);
    } else if (contextuallyCorrectMatches > 0 || enharmonicMatches > 0) {
      finalPartialScore = (contextualAccuracy + enharmonicAccuracy * 0.75).clamp(0.0, 1.0);
    }
    
    final isCorrect = correctFills.length == totalCorrectFills && 
                     incorrectFills.isEmpty && 
                     contextuallyCorrectMatches == totalCorrectFills;
    
    String feedback;
    if (isCorrect) {
      feedback = 'Excellent! All positions and note spellings are correct for the key of $keyContext.';
    } else if ((contextuallyCorrectMatches + enharmonicMatches) >= totalCorrectFills && incorrectFills.isEmpty) {
      if (enharmonicMatches > 0) {
        feedback = 'Good work! All notes are correct, but some spellings could be improved for the key of $keyContext.';
      } else {
        feedback = 'Nice job on the note names! Check your position selections.';
      }
    } else {
      feedback = 'Focus on both the correct positions and their proper spellings for the key of $keyContext.';
    }
    
    return QuestionResult(
      isCorrect: isCorrect,
      userAnswer: answer,
      correctAnswer: _correctAnswer,
      partialCreditScore: finalPartialScore,
      feedback: feedback,
    );
  }

  int _getNotePitchClass(String noteName) {
    // Clean the note name and extract pitch class
    var cleanNote = noteName.replaceAll(RegExp(r'\d+'), ''); // Remove octave numbers
    cleanNote = cleanNote.replaceAll('♭', 'b').replaceAll('♯', '#');
    
    try {
      return Note.fromString(cleanNote).pitchClass;
    } catch (e) {
      // Fallback for edge cases
      const noteMap = {
        'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
        'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
        'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11,
        'Cb': 11, 'B#': 0, 'E#': 5, 'Fb': 4,
      };
      return noteMap[cleanNote] ?? 0;
    }
  }

  @override
  bool operator ==(Object other) => identical(this, other) ||
      other is ScaleStripQuestion &&
      super == other &&
      configuration == other.configuration &&
      _correctAnswer == other._correctAnswer &&
      scaleType == other.scaleType &&
      questionMode == other.questionMode;

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        configuration,
        _correctAnswer,
        scaleType,
        questionMode,
      );
}