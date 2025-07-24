// lib/models/quiz/sections/introduction/scale_strip_quiz_questions.dart

import '../../scale_strip_question.dart';
import '../../quiz_question.dart';
import '../../../../utils/scale_strip_question_generator.dart';
import '../../../../utils/scale_strip_utils.dart';

/// Enhanced scale strip quiz questions with proper octave and enharmonic handling
/// UPDATED: Now uses automatic root selection for interval questions
class ScaleStripQuizQuestions {
  
  /// Topic ID for scale strip quiz
  static const String topicId = 'scale-strip-quiz';
  
  /// Topic title for scale strip quiz
  static const String topicTitle = 'Scale Strip Quiz';
  
  /// Get all questions for the unified quiz generator
  static List<ScaleStripQuestion> getQuestions() {
    return getAllQuestions();
  }
  
  /// Get all scale strip questions for the introduction section
  static List<ScaleStripQuestion> getAllQuestions() {
    return [
      ...getOctaveQuestions(),
      ...getChromaticQuestions(),
      ...getBasicIntervalQuestions(),
      ...getBasicScaleQuestions(),
    ];
  }

  /// UPDATED: Octave recognition questions with automatic root selection
  static List<ScaleStripQuestion> getOctaveQuestions() {
    return [
      // FIXED: Octave question for C with auto-selection
      ScaleStripQuestion(
        id: 'scale_strip_octave_c_001',
        questionText: 'Select the Octave from C',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.intervals,
          rootNote: 'C',
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          // NEW: Automatically select and lock the root note
          preHighlightedPositions: {0},
          lockPreHighlighted: true,
          showPreHighlightedLabels: true,
          highlightRoot: true,
          showEmptyPositions: true,
          keyContext: 'C',
          fillScreenWidth: true,
        ),
        // NEW: Only position 12 needs to be selected by user (root is pre-selected)
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {12},  // Only octave position
          selectedNotes: {'C'},
        ),
        scaleType: 'octave',
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: '''
An octave is the interval between a note and the next occurrence of the same note name, either higher or lower in pitch.

From C to the next C is exactly 12 semitones (half-steps), which creates the octave interval.

The root note C is automatically selected to show you the starting point. You need to select the octave position to complete the interval.

The octave is one of the most fundamental intervals in music - it sounds so similar that we give both notes the same name!
        ''',
        hints: const [
          'The root note C is already selected for you',
          'An octave is 12 semitones from the starting note',
          'Select the octave position (the second C)',
        ],
        tags: const ['octave', 'intervals', 'recognition'],
      ),

      // FIXED: Octave question for G with auto-selection  
      ScaleStripQuestion(
        id: 'scale_strip_octave_g_002',
        questionText: 'Select the Octave from G',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.intervals,
          rootNote: 'G',
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          // NEW: Automatically select and lock the root note
          preHighlightedPositions: {0},
          lockPreHighlighted: true,
          showPreHighlightedLabels: true,
          highlightRoot: true,
          showEmptyPositions: true,
          keyContext: 'G',
          fillScreenWidth: true,
        ),
        // NEW: Only position 12 needs to be selected by user (root is pre-selected)
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {12},  // Only octave position
          selectedNotes: {'G'},
        ),
        scaleType: 'octave',
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: '''
An octave from G to the next G spans exactly 12 semitones (half-steps).

The root note G is automatically selected to show you the starting point. You need to select the octave position to complete the interval.

This interval is so fundamental that both notes share the same letter name, even though the higher G vibrates at exactly twice the frequency of the lower G.
        ''',
        hints: const [
          'The root note G is already selected for you',
          'An octave is 12 semitones from the starting note',
          'Select the octave position (the second G)',
        ],
        tags: const ['octave', 'intervals', 'recognition'],
      ),

      // FIXED: Octave question for F with auto-selection
      ScaleStripQuestion(
        id: 'scale_strip_octave_f_003',
        questionText: 'Select the Octave from F',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 10,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.intervals,
          rootNote: 'F',
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          // NEW: Automatically select and lock the root note
          preHighlightedPositions: {0},
          lockPreHighlighted: true,
          showPreHighlightedLabels: true,
          highlightRoot: true,
          showEmptyPositions: true,
          keyContext: 'F',
          fillScreenWidth: true,
        ),
        // NEW: Only position 12 needs to be selected by user (root is pre-selected)
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {12},  // Only octave position
          selectedNotes: {'F'},
        ),
        scaleType: 'octave',
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: '''
An octave from F to the next F spans exactly 12 semitones (half-steps).

The root note F is automatically selected to show you the starting point. You need to select the octave position to complete the interval.

The octave is the most consonant interval after unison - it sounds so similar to the original note that we consider them the same pitch class.
        ''',
        hints: const [
          'The root note F is already selected for you',
          'An octave is 12 semitones from the starting note',
          'Select the octave position (the second F)',
        ],
        tags: const ['octave', 'intervals', 'recognition'],
      ),
    ];
  }

  /// UPDATED: Basic interval questions with automatic root selection
  static List<ScaleStripQuestion> getBasicIntervalQuestions() {
    return [
      // Perfect 5th from C with auto-selection
      ScaleStripQuestion(
        id: 'scale_strip_perfect_5th_c_001',
        questionText: 'Select the Perfect 5th from C',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 5,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: true,
          showNoteLabels: true,
          allowMultipleSelection: false,
          displayMode: ScaleStripMode.intervals,
          rootNote: 'C',
          octaveCount: 1,
          includeOctaveNote: false,
          validationMode: ValidationMode.exactPositions,
          // NEW: Automatically select and lock the root note
          preHighlightedPositions: {0},
          lockPreHighlighted: true,
          showPreHighlightedLabels: true,
          highlightRoot: true,
          keyContext: 'C',
          fillScreenWidth: true,
        ),
        // NEW: Only position 7 needs to be selected by user (root is pre-selected)
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {7},  // Only the G position
          selectedNotes: {'G'},
        ),
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: '''
A Perfect 5th from C is G, which is 7 semitones away.

The root note C is automatically selected to show you the starting point. You need to select position 8 (G) to complete the Perfect 5th interval.

Perfect 5ths are extremely stable and consonant intervals, forming the basis of power chords in rock music and being present in the harmonic series.
        ''',
        hints: const [
          'The root note C is already selected for you',
          'Count 7 semitones from the root',
          'This is a perfect interval',
        ],
        tags: const ['intervals', 'perfect-5th', 'recognition'],
      ),

      // Major 3rd from F with auto-selection
      ScaleStripQuestion(
        id: 'scale_strip_major_3rd_f_001',
        questionText: 'Select the Major 3rd from F',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 5,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: true,
          showNoteLabels: true,
          allowMultipleSelection: false,
          displayMode: ScaleStripMode.intervals,
          rootNote: 'F',
          octaveCount: 1,
          includeOctaveNote: false,
          validationMode: ValidationMode.exactPositions,
          // NEW: Automatically select and lock the root note
          preHighlightedPositions: {0},
          lockPreHighlighted: true,
          showPreHighlightedLabels: true,
          highlightRoot: true,
          keyContext: 'F',
          fillScreenWidth: true,
        ),
        // NEW: Only position 4 needs to be selected by user (root is pre-selected)
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {4},  // Only the A position
          selectedNotes: {'A'},
        ),
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: '''
A Major 3rd from F is A, which is 4 semitones away.

The root note F is automatically selected to show you the starting point. You need to select position 5 (A) to complete the Major 3rd interval.

Major 3rds give chords their "happy" or "bright" sound and are essential building blocks of major triads.
        ''',
        hints: const [
          'The root note F is already selected for you',
          'Count 4 semitones from the root',
          'This is a major interval',
        ],
        tags: const ['intervals', 'major-3rd', 'recognition'],
      ),
    ];
  }

  /// PRESERVED: Chromatic scale questions (these use different mechanics)
  static List<ScaleStripQuestion> getChromaticQuestions() {
    return [
      ScaleStripQuestion(
        id: 'scale_strip_chromatic_c_001',
        questionText: 'Fill in the missing notes in the chromatic scale starting from C',
        topic: QuestionTopic.scales,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 12,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: false,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.fillInBlanks,
          rootNote: 'C',
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          preHighlightedPositions: {0, 2, 4, 5, 7, 9, 11, 12}, // Natural notes
          showEmptyPositions: true,
          lockPreHighlighted: true,
          useDropdownSelection: true,
          showPreHighlightedLabels: true,
          keyContext: 'C',
          allowEnharmonicPartialCredit: true,
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {1, 3, 6, 8, 10}, // Sharp/flat positions
          selectedNotes: {'C#', 'D#', 'F#', 'G#', 'A#'}, // Prefer sharps in C
        ),
        scaleType: 'chromatic',
        questionMode: ScaleStripQuestionMode.notes,
        explanation: '''
The chromatic scale contains all 12 different pitches within an octave. Starting from C, the complete chromatic scale is:

C - C# - D - D# - E - F - F# - G - G# - A - A# - B - C

The natural notes (C, D, E, F, G, A, B) are already provided. You need to fill in the missing chromatic notes between them.

Remember: There are no sharps or flats between E-F and B-C because these pairs are already a half-step apart!
        ''',
        hints: const [
          'The chromatic scale includes every semitone',
          'Remember: no sharps between E-F and B-C',
          'Click on empty positions to select notes',
          'In the key of C, sharp spellings are preferred',
        ],
        tags: const ['chromatic', 'note-names', 'sharps', 'fill-in-blanks'],
      ),
    ];
  }

  /// PRESERVED: Basic scale construction questions
  static List<ScaleStripQuestion> getBasicScaleQuestions() {
    return [
      ScaleStripQuestion(
        id: 'scale_strip_c_major_001',
        questionText: 'Select all notes in the C Major scale',
        topic: QuestionTopic.scales,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 14,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.construction,
          rootNote: 'C',
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          highlightRoot: true,
          allowEnharmonicPartialCredit: true,
          keyContext: 'C',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {0, 2, 4, 5, 7, 9, 11, 12}, // C major scale positions
          selectedNotes: {'C', 'D', 'E', 'F', 'G', 'A', 'B'}, // C major scale notes
        ),
        scaleType: 'major',
        questionMode: ScaleStripQuestionMode.construction,
        explanation: '''
The C Major scale contains the following notes: C - D - E - F - G - A - B - C

This scale follows the major scale pattern (W-W-H-W-W-W-H) and includes 8 total positions on the scale strip, including the octave.

Each note has its specific function within the scale and contributes to the characteristic "happy" sound of the major mode.
        ''',
        hints: const [
          'Major scales follow the W-W-H-W-W-W-H pattern',
          'Count whole and half steps from the root',
          'Include the octave note at the end',
        ],
        tags: const ['scales', 'major', 'construction'],
      ),
    ];
  }
}