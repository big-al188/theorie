// lib/models/quiz/sections/introduction/scale_strip_quiz_questions.dart

import '../../scale_strip_question.dart';
import '../../quiz_question.dart';
import '../../../../utils/scale_strip_question_generator.dart';
import '../../../../utils/scale_strip_utils.dart';

/// Enhanced scale strip quiz questions with proper octave and enharmonic handling
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

  /// Octave recognition questions - FIXED to use correct root note
  static List<ScaleStripQuestion> getOctaveQuestions() {
    return [
      // Fixed octave question for C
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
          rootNote: 'C',  // Scale strip root matches question root
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          preHighlightedPositions: const {},
          highlightRoot: true,
          showEmptyPositions: true,
          keyContext: 'C',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {0, 12},  // C positions on C-rooted strip
          selectedNotes: {'C'},
        ),
        scaleType: 'octave',
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: '''
An octave from C includes both the starting C (position 1) and the C that is 12 semitones higher (position 13).

These two notes have the same name because they sound so similar - the higher C vibrates at exactly twice the frequency of the lower C. This 12-semitone distance is what we call an octave.

In this scale strip, you should select both the first position (C) and the 13th position (the next C).
        ''',
      ),

      // FIXED: G octave question with G as the root
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
          rootNote: 'G',  // FIX: Use G as the strip root, not C
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          highlightRoot: true,
          keyContext: 'G',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {0, 12},  // G positions on G-rooted strip
          selectedNotes: {'G'},
        ),
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: 'An octave from G includes the starting G and the G that is 12 semitones higher.',
      ),
    ];
  }

  /// Enhanced chromatic scale questions with proper dropdown functionality
  static List<ScaleStripQuestion> getChromaticQuestions() {
    return [
      // Chromatic scale starting from C with enhanced dropdown options
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
          rootNote: 'C',  // Strip root matches question root
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          preHighlightedPositions: {0, 2, 4, 5, 7, 9, 11, 12}, // Natural notes + octave
          showEmptyPositions: true,
          lockPreHighlighted: true,
          useDropdownSelection: true,
          showPreHighlightedLabels: true,
          allowEnharmonicPartialCredit: true,
          keyContext: 'C',
          fillScreenWidth: true,
        ),
        correctAnswer: ScaleStripAnswer(
          selectedPositions: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
          selectedNotes: {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'},
        ),
        scaleType: 'chromatic',
        questionMode: ScaleStripQuestionMode.notes,
        explanation: '''
The chromatic scale contains all 12 different pitches within an octave. Starting from C, the complete chromatic scale is:

C - C# - D - D# - E - F - F# - G - G# - A - A# - B - C

Since we're in the key of C (which has no sharps or flats), we typically use sharp notation for the black keys. However, both sharp and flat spellings are musically correct:
- C# = Db
- D# = Eb  
- F# = Gb
- G# = Ab
- A# = Bb

You'll get full credit for sharp spellings and partial credit for flat spellings in this context.
        ''',
      ),

      // Chromatic scale from Gb (flat key example)
      ScaleStripQuestion(
        id: 'scale_strip_chromatic_gb_002',
        questionText: 'Fill in the missing notes in the chromatic scale starting from Gb',
        topic: QuestionTopic.scales,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 12,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: false,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.fillInBlanks,
          rootNote: 'Gb',  // Strip root matches question root
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          preHighlightedPositions: {0, 1, 3, 5, 6, 8, 10, 12}, // Natural notes relative to Gb
          showEmptyPositions: true,
          lockPreHighlighted: true,
          useDropdownSelection: true,
          showPreHighlightedLabels: true,
          allowEnharmonicPartialCredit: true,
          keyContext: 'Gb',
          fillScreenWidth: true,
        ),
        correctAnswer: ScaleStripAnswer(
          selectedPositions: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
          selectedNotes: {'Gb', 'G', 'Ab', 'A', 'Bb', 'B', 'C', 'Db', 'D', 'Eb', 'E', 'F'},
        ),
        scaleType: 'chromatic',
        questionMode: ScaleStripQuestionMode.notes,
        explanation: '''
Starting from Gb, the chromatic scale includes all 12 pitches. Since Gb is a flat key (6 flats in the key signature), we typically prefer flat notation:

Gb - G - Ab - A - Bb - B - C - Db - D - Eb - E - F - Gb

In flat keys, we use flats for most accidentals. You'll get full credit for flat spellings and partial credit for sharp equivalents like F# instead of Gb.
        ''',
      ),
    ];
  }

  /// Basic interval recognition questions - FIXED to handle interval calculations properly
  static List<ScaleStripQuestion> getBasicIntervalQuestions() {
    return [
      // Perfect 5th from C - using C-rooted strip
      ScaleStripQuestion(
        id: 'scale_strip_interval_p5_c_001',
        questionText: 'Select the Perfect 5th from C',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 5,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: true,
          showNoteLabels: true,
          allowMultipleSelection: false,
          displayMode: ScaleStripMode.intervals,
          rootNote: 'C',  // Strip root matches question root
          octaveCount: 1,
          includeOctaveNote: false,
          validationMode: ValidationMode.exactPositions,
          highlightRoot: true,
          keyContext: 'C',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {7}, // G is 7 semitones from C on C-rooted strip
          selectedNotes: {'G'},
        ),
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: 'A Perfect 5th from C is G, which is 7 semitones (half-steps) higher than C.',
      ),

      // FIXED: Major 3rd from F - now uses F-rooted strip
      ScaleStripQuestion(
        id: 'scale_strip_interval_m3_f_002',
        questionText: 'Select the Major 3rd from F',
        topic: QuestionTopic.intervals,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 5,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: true,
          showNoteLabels: true,
          allowMultipleSelection: false,
          displayMode: ScaleStripMode.intervals,
          rootNote: 'F',  // FIX: Use F as strip root instead of C
          octaveCount: 1,
          includeOctaveNote: false,
          validationMode: ValidationMode.exactPositions,
          highlightRoot: true,
          keyContext: 'F',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {4}, // A is 4 semitones from F on F-rooted strip
          selectedNotes: {'A'},
        ),
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: 'A Major 3rd from F is A, which is 4 semitones higher than F.',
      ),
    ];
  }

  /// Basic scale construction questions - FIXED to use proper root notes
  static List<ScaleStripQuestion> getBasicScaleQuestions() {
    return [
      // C Major scale - strip root matches question root
      ScaleStripQuestion(
        id: 'scale_strip_scale_cmaj_001',
        questionText: 'Select all notes in the C Major scale',
        topic: QuestionTopic.scales,
        difficulty: QuestionDifficulty.beginner,
        pointValue: 14,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.construction,
          rootNote: 'C',  // Strip root matches question root
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          highlightRoot: true,
          allowEnharmonicPartialCredit: true,
          keyContext: 'C',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {0, 2, 4, 5, 7, 9, 11, 12}, // C D E F G A B C on C-rooted strip
          selectedNotes: {'C', 'D', 'E', 'F', 'G', 'A', 'B'},
        ),
        scaleType: 'major',
        questionMode: ScaleStripQuestionMode.construction,
        explanation: '''
The C Major scale contains no sharps or flats - just the natural notes:

C - D - E - F - G - A - B - C

This follows the major scale pattern: W-W-H-W-W-W-H (where W = whole step, H = half step).

Notice that you should select both the starting C and the octave C to complete the full scale!
        ''',
      ),

      // FIXED: G Major scale with G as the strip root
      ScaleStripQuestion(
        id: 'scale_strip_scale_gmaj_002',
        questionText: 'Select all notes in the G Major scale',
        topic: QuestionTopic.scales,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 14,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.construction,
          rootNote: 'G',  // FIX: Use G as strip root instead of C
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          highlightRoot: true,
          allowEnharmonicPartialCredit: true,
          keyContext: 'G',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {0, 2, 4, 5, 7, 9, 11, 12}, // G A B C D E F# G on G-rooted strip
          selectedNotes: {'G', 'A', 'B', 'C', 'D', 'E', 'F#'},
        ),
        scaleType: 'major',
        questionMode: ScaleStripQuestionMode.construction,
        explanation: '''
The G Major scale has one sharp (F#):

G - A - B - C - D - E - F# - G

This follows the same major scale pattern as C Major, but starting from G. The F# comes from the key signature of G Major.

If you selected Gb instead of F#, you'd get partial credit since they're the same pitch, but F# is the correct spelling in this key.
        ''',
      ),

      // FIXED: F Major scale with F as the strip root
      ScaleStripQuestion(
        id: 'scale_strip_scale_fmaj_003',
        questionText: 'Select all notes in the F Major scale',
        topic: QuestionTopic.scales,
        difficulty: QuestionDifficulty.intermediate,
        pointValue: 14,
        configuration: ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.construction,
          rootNote: 'F',  // FIX: Use F as strip root instead of C
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          highlightRoot: true,
          allowEnharmonicPartialCredit: true,
          keyContext: 'F',
          fillScreenWidth: true,
        ),
        correctAnswer: const ScaleStripAnswer(
          selectedPositions: {0, 2, 4, 5, 7, 9, 11, 12}, // F G A Bb C D E F on F-rooted strip
          selectedNotes: {'F', 'G', 'A', 'Bb', 'C', 'D', 'E'},
        ),
        scaleType: 'major',
        questionMode: ScaleStripQuestionMode.construction,
        explanation: '''
The F Major scale has one flat (Bb):

F - G - A - Bb - C - D - E - F

This follows the major scale pattern starting from F. The Bb comes from the key signature of F Major.

If you selected A# instead of Bb, you'd get partial credit since they're the same pitch, but Bb is the correct spelling in this key.
        ''',
      ),
    ];
  }

  /// Get questions filtered by difficulty
  static List<ScaleStripQuestion> getQuestionsByDifficulty(QuestionDifficulty difficulty) {
    return getAllQuestions().where((q) => q.difficulty == difficulty).toList();
  }

  /// Get questions filtered by topic
  static List<ScaleStripQuestion> getQuestionsByTopic(QuestionTopic topic) {
    return getAllQuestions().where((q) => q.topic == topic).toList();
  }

  /// Get a specific number of random questions
  static List<ScaleStripQuestion> getRandomQuestions(int count) {
    final allQuestions = getAllQuestions();
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  /// Get progressive questions (ordered by difficulty)
  static List<ScaleStripQuestion> getProgressiveQuestions() {
    final questions = getAllQuestions();
    questions.sort((a, b) {
      // Sort by difficulty first, then by topic
      final difficultyComparison = a.difficulty.index.compareTo(b.difficulty.index);
      if (difficultyComparison != 0) return difficultyComparison;
      return a.topic.index.compareTo(b.topic.index);
    });
    return questions;
  }
}