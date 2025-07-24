// lib/utils/scale_strip_question_generator.dart

import '../models/quiz/scale_strip_question.dart';
import '../models/quiz/quiz_question.dart';
import '../models/music/scale.dart';
import '../models/music/interval.dart';
import '../models/music/note.dart';
import 'music_utils.dart';
import 'scale_strip_utils.dart';

/// Enhanced generator for scale strip questions with proper octave and enharmonic handling
/// UPDATED: Added automatic root note selection for interval questions
class ScaleStripQuestionGenerator {
  /// Generate octave questions with automatic root note selection
  /// NEW: Root note (position 0) is automatically selected and locked
  static List<ScaleStripQuestion> generateOctaveQuestions({
    List<String> rootNotes = const ['C', 'F', 'G', 'D', 'A', 'E', 'B'],
  }) {
    final questions = <ScaleStripQuestion>[];
    var questionId = 1;

    for (final rootNote in rootNotes) {
      final question = ScaleStripQuestion(
        id: 'octave_from_${rootNote.toLowerCase()}_$questionId',
        questionText: 'Select the Octave from $rootNote',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.intervals,
          rootNote: rootNote,
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          // NEW: Automatically select and lock the root note
          preHighlightedPositions: {0},
          lockPreHighlighted: true,
          showPreHighlightedLabels: true,
          highlightRoot: true,
          showEmptyPositions: true,
          keyContext: rootNote,
          fillScreenWidth: true,
        ),
        // NEW: Only position 12 needs to be selected by user (root is pre-selected)
        correctAnswer: ScaleStripAnswer(
          selectedPositions: {12},
          selectedNotes: {rootNote},
        ),
        scaleType: 'octave',
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: _generateOctaveExplanation(rootNote),
        hints: [
          'The root note $rootNote is already selected for you',
          'An octave is 12 semitones from the starting note',
          'Select the octave position (the second $rootNote)',
        ],
        tags: ['octave', 'intervals', 'recognition'],
      );
      questions.add(question);
      questionId++;
    }

    return questions;
  }

  /// Generate enhanced chromatic scale questions with proper enharmonic handling
  /// PRESERVED: All existing functionality maintained
  static List<ScaleStripQuestion> generateChromaticQuestions({
    List<String> rootNotes = const ['C', 'F#', 'Gb', 'Bb', 'G', 'Db', 'A', 'Eb'],
  }) {
    final questions = <ScaleStripQuestion>[];
    var questionId = 1;

    for (final rootNote in rootNotes) {
      final question = ScaleStripQuestion(
        id: 'chromatic_fill_${rootNote.toLowerCase()}_$questionId',
        questionText: 'Fill in the missing notes in the chromatic scale starting from $rootNote',
        topic: QuestionTopic.scales,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 12,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: false,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.fillInBlanks,
          rootNote: rootNote,
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          preHighlightedPositions: _getNaturalNotePositions(rootNote),
          showEmptyPositions: true,
          lockPreHighlighted: true,
          useDropdownSelection: true,
          showPreHighlightedLabels: true,
          keyContext: rootNote,
          allowEnharmonicPartialCredit: true,
          fillScreenWidth: true,
        ),
        correctAnswer: _generateChromaticAnswer(rootNote),
        scaleType: 'chromatic',
        questionMode: ScaleStripQuestionMode.notes,
        explanation: _generateChromaticExplanation(rootNote),
        hints: _generateChromaticHints(rootNote),
        tags: ['chromatic', 'note-names', 'sharps-flats', 'fill-in-blanks'],
      );
      questions.add(question);
      questionId++;
    }

    return questions;
  }

  /// Generate interval questions with automatic root note selection
  /// NEW: Root note (position 0) is automatically selected and locked
  static List<ScaleStripQuestion> generateIntervalQuestions({
    List<String> rootNotes = const ['C', 'G', 'F', 'D'],
    List<Interval> intervals = const [
      Interval.unison,
      Interval.majorSecond,
      Interval.majorThird,
      Interval.perfectFourth,
      Interval.perfectFifth,
      Interval.majorSixth,
      Interval.majorSeventh,
      Interval.octave,
    ],
  }) {
    final questions = <ScaleStripQuestion>[];
    var questionId = 1;

    for (final rootNote in rootNotes) {
      for (final interval in intervals) {
        final question = _generateIntervalQuestion(
          rootNote,
          interval,
          'interval_${interval.name.toLowerCase().replaceAll(' ', '_')}_${rootNote.toLowerCase()}_${questionId++}',
        );
        questions.add(question);
      }
    }

    return questions;
  }

  /// Generate scale questions with proper root handling
  /// PRESERVED: All existing functionality maintained
  static List<ScaleStripQuestion> generateScaleQuestions({
    List<String> rootNotes = const ['C', 'G', 'F', 'D', 'A', 'E', 'B'],
    List<String> scaleTypes = const ['major', 'minor', 'dorian', 'mixolydian'],
  }) {
    final questions = <ScaleStripQuestion>[];
    var questionId = 1;

    for (final rootNote in rootNotes) {
      for (final scaleType in scaleTypes) {
        final question = _generateScaleQuestion(
          rootNote,
          scaleType,
          'scale_${scaleType}_${rootNote.toLowerCase()}_${questionId++}',
        );
        if (question != null) {
          questions.add(question);
        }
      }
    }

    return questions;
  }

  // Helper methods

  /// DEPRECATED: Generate octave answer for old approach
  /// Kept for backward compatibility but no longer used
  static ScaleStripAnswer _generateOctaveAnswer(String rootNote) {
    // For octave questions on a strip rooted at the same note,
    // positions 0 and 12 both represent the root note
    return ScaleStripAnswer(
      selectedPositions: {0, 12},
      selectedNotes: {rootNote},
    );
  }

  /// PRESERVED: Generate chromatic answer for fill-in-the-blank questions
  static ScaleStripAnswer _generateChromaticAnswer(String rootNote) {
    // Use the specialized method for fill-in-the-blank questions
    // This returns only the missing notes (sharps/flats) that need to be filled in
    return ScaleStripUtils.generateChromaticFillAnswer(rootNote, includeOctave: true);
  }

  /// Get natural note positions relative to the given root
  static Set<int> _getNaturalNotePositions(String rootNote) {
    return ScaleStripUtils.getNaturalNotePositions(rootNote);
  }

  /// Generate an interval question with automatic root note selection
  /// NEW: Root note (position 0) is automatically selected and locked
  static ScaleStripQuestion _generateIntervalQuestion(
    String rootNote,
    Interval interval,
    String questionId,
  ) {
    final intervalSemitones = interval.semitones;
    
    // Calculate the target position for the interval
    final targetPosition = intervalSemitones;
    
    // For unison, both root and target are position 0
    // For octave, target is position 12
    // For other intervals, target is the semitone count from root
    final targetPositions = <int>{};
    if (intervalSemitones == 0) {
      // Unison: only position 0 (already pre-highlighted)
      // No additional positions needed
    } else if (intervalSemitones == 12) {
      // Octave: position 12 (position 0 is pre-highlighted)
      targetPositions.add(12);
    } else {
      // Other intervals: the calculated position
      targetPositions.add(targetPosition);
    }
    
    // Calculate the target note name
    final targetNote = _calculateTargetNoteName(rootNote, intervalSemitones);
    
    return ScaleStripQuestion(
      id: questionId,
      questionText: 'Select the ${interval.name} from $rootNote',
      topic: QuestionTopic.intervals,
      difficulty: _getIntervalDifficulty(interval),
      pointValue: 5,
      configuration: ScaleStripConfiguration(
        showIntervalLabels: true,
        showNoteLabels: true,
        // Single selection for non-octave intervals, multiple for octave
        allowMultipleSelection: intervalSemitones == 12,
        displayMode: ScaleStripMode.intervals,
        rootNote: rootNote,
        octaveCount: 1,
        includeOctaveNote: intervalSemitones == 12,
        validationMode: ValidationMode.exactPositions,
        // NEW: Automatically select and lock the root note
        preHighlightedPositions: {0},
        lockPreHighlighted: true,
        showPreHighlightedLabels: true,
        highlightRoot: true,
        keyContext: rootNote,
        fillScreenWidth: true,
      ),
      // NEW: Only the target position(s) need to be selected by user
      correctAnswer: ScaleStripAnswer(
        selectedPositions: targetPositions,
        selectedNotes: intervalSemitones == 0 ? {} : {targetNote},
      ),
      questionMode: ScaleStripQuestionMode.intervals,
      explanation: _generateIntervalExplanation(rootNote, interval, targetNote),
      hints: [
        'The root note $rootNote is already selected for you',
        'Count ${interval.semitones} semitones from the root',
        interval.isPerfect ? 'This is a perfect interval' : 'This is a major/minor interval',
      ],
      tags: ['intervals', 'recognition', interval.name.toLowerCase().replaceAll(' ', '-')],
    );
  }

  /// PRESERVED: Generate a scale question
  static ScaleStripQuestion? _generateScaleQuestion(
    String rootNote,
    String scaleType,
    String questionId,
  ) {
    try {
      final answer = ScaleStripUtils.generateScaleAnswer(
        scaleType,
        rootNote,
        rootNote,  // Strip root matches question root
        includeOctave: true,
      );

      return ScaleStripQuestion(
        id: questionId,
        questionText: 'Select all notes in the $rootNote ${_capitalizeFirst(scaleType)} scale',
        topic: QuestionTopic.scales,
        difficulty: _getScaleDifficulty(scaleType),
        pointValue: 14,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.construction,
          rootNote: rootNote,  // Strip root matches question root
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          highlightRoot: true,
          allowEnharmonicPartialCredit: true,
          keyContext: rootNote,
          fillScreenWidth: true,
        ),
        correctAnswer: answer,
        scaleType: scaleType,
        questionMode: ScaleStripQuestionMode.construction,
        explanation: _generateScaleExplanation(rootNote, scaleType, answer),
        hints: _generateScaleHints(scaleType),
        tags: ['scales', scaleType, 'construction'],
      );
    } catch (e) {
      // Scale type not found or other error
      return null;
    }
  }

  // PRESERVED: Difficulty assessment methods
  static QuestionDifficulty _getIntervalDifficulty(Interval interval) {
    switch (interval.semitones) {
      case 0: // Unison
      case 12: // Octave
        return QuestionDifficulty.beginner;
      case 7: // Perfect 5th
      case 5: // Perfect 4th
        return QuestionDifficulty.beginner;
      case 4: // Major 3rd
      case 3: // Minor 3rd
        return QuestionDifficulty.intermediate;
      default:
        return QuestionDifficulty.intermediate;
    }
  }

  static QuestionDifficulty _getScaleDifficulty(String scaleType) {
    switch (scaleType.toLowerCase()) {
      case 'major':
      case 'minor':
        return QuestionDifficulty.beginner;
      case 'dorian':
      case 'mixolydian':
      case 'aeolian':
        return QuestionDifficulty.intermediate;
      default:
        return QuestionDifficulty.advanced;
    }
  }

  // ENHANCED: Explanation generation methods with auto-selection context
  static String _generateOctaveExplanation(String rootNote) {
    return '''
An octave is the interval between a note and the next occurrence of the same note name, either higher or lower in pitch. 

From $rootNote to the next $rootNote is exactly 12 semitones (half-steps), which creates the octave interval.

The root note $rootNote is automatically selected to show you the starting point. You need to select the octave position to complete the interval.

The octave is one of the most fundamental intervals in music - it sounds so similar that we give both notes the same name!
    ''';
  }

  /// PRESERVED: Enhanced chromatic explanation with proper key context
  static String _generateChromaticExplanation(String rootNote) {
    final keySignature = MusicUtils.getKeySignature(rootNote);
    final preferFlats = keySignature['flats'] > 0;
    
    // Generate the complete chromatic scale with proper spellings
    final chromaticNotes = <String>[];
    for (int i = 0; i < 12; i++) {
      chromaticNotes.add(ScaleStripUtils.getPreferredNoteNameForPosition(rootNote, i));
    }
    chromaticNotes.add(rootNote); // Add octave
    
    String explanation = '''
The chromatic scale contains all 12 different pitches within an octave. Starting from $rootNote, the complete chromatic scale is:

${chromaticNotes.join(' - ')}

''';
    
    if (preferFlats) {
      explanation += '''
Since $rootNote is a flat key (${keySignature['flats']} flats in the key signature), we typically prefer flat notation for the accidentals. You'll get:
• **Full credit** for using flats: ${_getExpectedFlats(rootNote)}
• **75% partial credit** for using sharp equivalents

''';
    } else if (keySignature['sharps'] > 0) {
      explanation += '''
Since $rootNote is a sharp key (${keySignature['sharps']} sharps in the key signature), we typically prefer sharp notation for the accidentals. You'll get:
• **Full credit** for using sharps: ${_getExpectedSharps(rootNote)}
• **75% partial credit** for using flat equivalents

''';
    } else {
      explanation += '''
Since $rootNote has no sharps or flats in its key signature, we typically use sharp notation for the chromatic notes. You'll get:
• **Full credit** for using sharps: ${_getExpectedSharps(rootNote)}
• **75% partial credit** for using flat equivalents

''';
    }
    
    explanation += '''
The natural notes (${_getNaturalNotesForRoot(rootNote)}) are already provided. You need to fill in the missing chromatic notes between them.

**Remember**: There are no sharps or flats between E-F and B-C because these pairs are already a half-step apart!
    ''';
    
    return explanation;
  }

  /// PRESERVED: Generate key-specific hints for chromatic questions
  static List<String> _generateChromaticHints(String rootNote) {
    final keySignature = MusicUtils.getKeySignature(rootNote);
    final preferFlats = keySignature['flats'] > 0;
    
    final hints = <String>[
      'The chromatic scale includes every semitone',
      'Remember: no sharps between E-F and B-C',
      'Click on empty positions to select notes',
    ];
    
    if (preferFlats) {
      hints.add('In the key of $rootNote, flat spellings are preferred');
      hints.add('You get full credit for flats, partial credit for sharps');
    } else {
      hints.add('In the key of $rootNote, sharp spellings are preferred');
      hints.add('You get full credit for sharps, partial credit for flats');
    }
    
    return hints;
  }

  /// PRESERVED: Generate scale-specific hints
  static List<String> _generateScaleHints(String scaleType) {
    switch (scaleType.toLowerCase()) {
      case 'major':
        return [
          'Major scales follow the W-W-H-W-W-W-H pattern',
          'Count whole and half steps from the root',
          'Include the octave note at the end',
        ];
      case 'minor':
        return [
          'Minor scales have a ♭3, ♭6, and ♭7 compared to major',
          'The pattern is W-H-W-W-H-W-W',
          'Listen for the characteristic minor sound',
        ];
      case 'dorian':
        return [
          'Dorian is like natural minor with a raised 6th',
          'It\'s the 2nd mode of the major scale',
          'Has a distinctive modal character',
        ];
      case 'mixolydian':
        return [
          'Mixolydian is like major with a ♭7',
          'It\'s the 5th mode of the major scale',
          'Common in blues and rock music',
        ];
      default:
        return [
          'Follow the specific interval pattern for this scale',
          'Count carefully from the root note',
          'Include the octave note',
        ];
    }
  }

  /// NEW: Enhanced interval explanation with auto-selection context
  static String _generateIntervalExplanation(String rootNote, Interval interval, String targetNote) {
    return '''
The ${interval.name} from $rootNote to $targetNote spans ${interval.semitones} semitones.

The root note $rootNote is automatically selected to show you the starting point. 

${interval.isPerfect ? 
  'This is a perfect interval, which maintains its quality regardless of the starting note.' :
  'This is a major interval. In minor keys, this interval would be smaller by one semitone.'}
    ''';
  }

  /// PRESERVED: Scale explanation generation
  static String _generateScaleExplanation(String rootNote, String scaleType, ScaleStripAnswer answer) {
    final noteList = answer.selectedNotes.toList()..sort();
    final noteString = noteList.join(' - ');
    
    return '''
The $rootNote ${_capitalizeFirst(scaleType)} scale contains the following notes:

$noteString

This scale follows the ${scaleType} scale pattern and includes ${answer.selectedPositions.length} total positions on the scale strip, including the octave.

Each note has its specific function within the scale and contributes to the characteristic sound of the ${scaleType} mode.
    ''';
  }

  // PRESERVED: Helper methods for explanation generation
  static String _getExpectedFlats(String rootNote) {
    final expectedNotes = <String>[];
    final naturalPositions = ScaleStripUtils.getNaturalNotePositions(rootNote);
    
    for (int i = 0; i < 12; i++) {
      if (!naturalPositions.contains(i)) {
        final note = ScaleStripUtils.getPreferredNoteNameForPosition(rootNote, i);
        if (note.contains('b')) {
          expectedNotes.add(note);
        }
      }
    }
    
    return expectedNotes.join(', ');
  }

  static String _getExpectedSharps(String rootNote) {
    final expectedNotes = <String>[];
    final naturalPositions = ScaleStripUtils.getNaturalNotePositions(rootNote);
    
    for (int i = 0; i < 12; i++) {
      if (!naturalPositions.contains(i)) {
        final note = ScaleStripUtils.getPreferredNoteNameForPosition(rootNote, i);
        if (note.contains('#')) {
          expectedNotes.add(note);
        }
      }
    }
    
    return expectedNotes.join(', ');
  }

  static String _getNaturalNotesForRoot(String rootNote) {
    const naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final naturalPositions = ScaleStripUtils.getNaturalNotePositions(rootNote);
    final presentNaturals = <String>[];
    
    for (int i = 0; i < 12; i++) {
      if (naturalPositions.contains(i)) {
        final note = ScaleStripUtils.getPreferredNoteNameForPosition(rootNote, i);
        if (naturalNotes.contains(note)) {
          presentNaturals.add(note);
        }
      }
    }
    
    return presentNaturals.join(', ');
  }

  /// NEW: Calculate the target note name for an interval
  static String _calculateTargetNoteName(String rootNote, int semitones) {
    if (semitones == 0) return rootNote;
    
    // Get the root note's pitch class
    final rootPitchClass = _getNotePitchClass(rootNote);
    final targetPitchClass = (rootPitchClass + semitones) % 12;
    
    // Convert back to note name using key context
    return _getNoteNameFromPitchClass(targetPitchClass, keyContext: rootNote);
  }

  static int _getNotePitchClass(String noteName) {
    var cleanNote = noteName.replaceAll(RegExp(r'\d+'), '');
    cleanNote = cleanNote.replaceAll('♭', 'b').replaceAll('♯', '#');
    
    const noteMap = {
      'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
      'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
      'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11,
      'Cb': 11, 'B#': 0, 'E#': 5, 'Fb': 4,
    };
    
    return noteMap[cleanNote] ?? 0;
  }

  static String _getNoteNameFromPitchClass(int pitchClass, {String? keyContext}) {
    if (keyContext != null) {
      // Use key context to determine sharp/flat preference
      final keyInfo = _getKeySignatureInfo(keyContext);
      return keyInfo.preferFlats ? 
        _getFlatNoteName(pitchClass) : 
        _getSharpNoteName(pitchClass);
    }
    
    // Default to sharp names
    return _getSharpNoteName(pitchClass);
  }

  static String _getSharpNoteName(int pitchClass) {
    const sharpNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return sharpNames[pitchClass % 12];
  }

  static String _getFlatNoteName(int pitchClass) {
    const flatNames = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
    return flatNames[pitchClass % 12];
  }

  static ({bool preferFlats}) _getKeySignatureInfo(String key) {
    // Simple heuristic: flat keys prefer flats, sharp keys prefer sharps
    final hasFlat = key.contains('b') || key.contains('♭');
    final hasSharp = key.contains('#') || key.contains('♯');
    
    if (hasFlat) return (preferFlats: true);
    if (hasSharp) return (preferFlats: false);
    
    // For natural keys, use circle of fifths logic
    const flatKeys = ['F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb'];
    return (preferFlats: flatKeys.contains(key));
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}