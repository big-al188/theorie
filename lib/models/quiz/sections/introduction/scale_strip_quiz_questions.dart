// lib/models/quiz/sections/introduction/scale_strip_quiz_questions.dart

import '../../scale_strip_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Scale Strip Quiz" topic in Introduction section
/// Updated to fix bugs with octave handling, interval labeling, and interactions
class ScaleStripQuizQuestions {
  static const String sectionId = 'introduction';
  static const String topicId = 'scale-strip-quiz';
  static const String topicTitle = 'Scale Strip Quiz';

  static List<ScaleStripQuestion> getQuestions() {
    return [
      _createBDiminishedTriadQuestion(),        // Question 1: Fixed octave handling
      _createChromaticScaleNotesQuestion(),     // Question 2: Fixed interval dropdown
      _createMajorScalePatternQuestion(),       // Question 3: Fixed gold highlighting
      _createCMajorTriadConstructionQuestion(), // Question 4: Fixed octave + partial credit
      _createPentatonicScaleQuestion(),         // Question 5: Fixed highlighting
      _createNaturalMinorScaleQuestion(),       // Question 6: Fixed highlighting
      _createMajorScaleIntervalsQuestion(),     // Question 7: Fixed interval labels
      _createMinorScaleMissingIntervalsQuestion(), // Question 8: Fixed interval labels + locks
    ];
  }

  /// Question 1: B Diminished Triad - Fixed octave handling
  static ScaleStripQuestion _createBDiminishedTriadQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_001',
      questionText: 'Construct a B Diminished Triad',
      topic: QuestionTopic.chords,
      difficulty: QuestionDifficulty.advanced,
      pointValue: 20,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: false,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.construction,
        rootNote: 'C',
        octaveCount: 2,
        validationMode: ValidationMode.noteNamesWithOctaves,
        highlightRoot: false,
        enableOctaveDistinction: true, // NEW: Enable octave-aware validation
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {11, 14, 17}, // B3, D4, F4 (specific octave positions)
        selectedNotes: {'B3', 'D4', 'F4'}, // Include octave info
        expectedOctavePatterns: {'B': [3], 'D': [4], 'F': [4]}, // Valid octaves for each note
      ),
      scaleType: 'diminished_triad',
      questionMode: ScaleStripQuestionMode.construction,
      explanation: '''
A diminished triad consists of a root, minor third, and diminished fifth.
B diminished triad: B-D-F.
The intervals are: minor third (3 semitones) and diminished fifth (6 semitones) from root.
With extended harmony, the octave placement matters for voice leading.
      ''',
      hints: [
        'Diminished triads have a minor third and diminished fifth',
        'Count 3 semitones for minor third, 6 semitones for diminished fifth',
        'Consider voice leading - D and F should be in the octave above B',
      ],
      tags: ['diminished-chords', 'advanced-harmony', 'chord-construction', 'octave-awareness'],
    );
  }

  /// Question 2: Chromatic Scale Notes - Fixed interval dropdown interaction
  static ScaleStripQuestion _createChromaticScaleNotesQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_002',
      questionText: 'Label the missing notes in the chromatic scale',
      topic: QuestionTopic.notes,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 12,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: false,
        showNoteLabels: false, // Don't show all note labels by default
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.fillInBlanks,
        rootNote: 'C',
        octaveCount: 1,
        validationMode: ValidationMode.noteNames,
        preHighlightedPositions: {0, 2, 4, 5, 7, 9, 11}, // C, D, E, F, G, A, B
        showEmptyPositions: true,
        lockPreHighlighted: true, // NEW: Lock pre-highlighted positions
        useDropdownSelection: true, // NEW: Enable dropdown for note selection
        showPreHighlightedLabels: true, // Always show labels for pre-highlighted notes
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {1, 3, 6, 8, 10}, // C#, D#, F#, G#, A#
        selectedNotes: {'C#', 'D#', 'F#', 'G#', 'A#'},
      ),
      scaleType: 'chromatic',
      questionMode: ScaleStripQuestionMode.notes,
      explanation: '''
The chromatic scale contains all 12 notes: C-C#-D-D#-E-F-F#-G-G#-A-A#-B.
You needed to identify the missing sharps: C#, D#, F#, G#, A#.
Remember that there are no sharps between E-F and B-C (natural half steps).
      ''',
      hints: [
        'The chromatic scale includes every semitone',
        'Click on empty positions to select from note options',
        'Remember: no sharps between E-F and B-C',
      ],
      tags: ['chromatic-scale', 'note-names', 'sharps-flats', 'dropdown-selection'],
    );
  }

  /// Question 3: G Major Scale Pattern - Fixed gold highlighting
  static ScaleStripQuestion _createMajorScalePatternQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_003',
      questionText: 'Select the notes that follow the major scale pattern starting from G',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 18,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: false,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.construction,
        rootNote: 'C', // Start from C but test G major understanding
        octaveCount: 1,
        validationMode: ValidationMode.pattern,
        highlightRoot: false, // FIXED: No special highlighting for root
        showFirstNoteAsReference: true, // NEW: Show G as reference without special highlighting
        firstNotePosition: 7, // G position for reference
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {7, 9, 11, 0, 2, 4, 6}, // G A B C D E F#
        selectedNotes: {'G', 'A', 'B', 'C', 'D', 'E', 'F#'},
      ),
      scaleType: 'major',
      questionMode: ScaleStripQuestionMode.pattern,
      explanation: '''
The G major scale follows the major scale pattern: W-W-H-W-W-W-H.
Starting from G: G-A-B-C-D-E-F#-G.
Notice that F# is required to maintain the correct interval pattern.
Starting the strip from C forces you to think about the G major scale pattern more deeply.
      ''',
      hints: [
        'Follow the W-W-H-W-W-W-H pattern from G',
        'You may need to use sharps or flats to maintain the pattern',
        'Think about scale degrees, not just alphabetical order',
      ],
      tags: ['major-scale', 'pattern-recognition', 'key-signatures', 'critical-thinking'],
    );
  }

  /// Question 4: C Major Triad - Fixed octave handling and partial credit
  static ScaleStripQuestion _createCMajorTriadConstructionQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_004',
      questionText: 'Construct a C Major Triad',
      topic: QuestionTopic.chords,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: false,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.construction,
        rootNote: 'C',
        octaveCount: 2,
        validationMode: ValidationMode.noteNamesWithPartialCredit,
        highlightRoot: false,
        enableOctaveDistinction: true, // NEW: Enable octave-aware validation
        allowPartialCreditForOctaves: true, // NEW: Award partial credit for correct notes in wrong octaves
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {0, 4, 7}, // C3, E3, G3 (primary voicing)
        selectedNotes: {'C3', 'E3', 'G3'},
        expectedOctavePatterns: {
          'C': [2, 3, 4], // C can be in multiple octaves
          'E': [3, 4, 5], // E can be in multiple octaves  
          'G': [3, 4, 5], // G can be in multiple octaves
        },
        partialCreditAnswers: [
          {'C4', 'E4', 'G4'}, // Higher octave version
          {'C2', 'E3', 'G3'}, // Lower root
          {'C3', 'E4', 'G4'}, // Mixed octaves
        ],
      ),
      scaleType: 'major_triad',
      questionMode: ScaleStripQuestionMode.construction,
      explanation: '''
A C Major triad consists of the notes C, E, and G.
This represents the 1st, 3rd, and 5th degrees of the C major scale.
Major triads have a major third (4 semitones) and perfect fifth (7 semitones) from the root.
With multiple octaves available, voice leading and octave placement become important considerations.
      ''',
      hints: [
        'A major triad uses the 1st, 3rd, and 5th notes of the major scale',
        'Look for C, E, and G in any octave combination',
        'Consider how the octave placement affects the sound',
      ],
      tags: ['triads', 'chord-construction', 'major-chords', 'octave-awareness', 'partial-credit'],
    );
  }

  /// Question 5: C Major Pentatonic - Fixed highlighting
  static ScaleStripQuestion _createPentatonicScaleQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_005',
      questionText: 'Select the notes of the C major pentatonic scale',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: true,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.construction,
        rootNote: 'C',
        octaveCount: 1,
        validationMode: ValidationMode.exactPositions,
        highlightRoot: false, // FIXED: No special gold highlighting
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {0, 2, 4, 7, 9}, // C D E G A
        selectedNotes: {'C', 'D', 'E', 'G', 'A'},
      ),
      scaleType: 'pentatonic_major',
      questionMode: ScaleStripQuestionMode.construction,
      explanation: '''
The major pentatonic scale uses 5 notes: 1, 2, 3, 5, 6 of the major scale.
In C major pentatonic: C-D-E-G-A.
This scale omits the 4th (F) and 7th (B) degrees to avoid half-step dissonances.
      ''',
      hints: [
        'Pentatonic means "five notes"',
        'Use scale degrees 1, 2, 3, 5, 6 of the major scale',
        'Avoid the 4th and 7th degrees',
      ],
      tags: ['pentatonic', 'five-note-scales', 'world-music'],
    );
  }

  /// Question 6: E Natural Minor Scale - Fixed highlighting  
  static ScaleStripQuestion _createNaturalMinorScaleQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_006',
      questionText: 'Select all notes in the E natural minor scale',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 16,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: true,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.construction,
        rootNote: 'E',
        octaveCount: 1,
        validationMode: ValidationMode.exactPositions,
        highlightRoot: false, // FIXED: No special gold highlighting
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {4, 6, 7, 9, 11, 0, 2}, // E F# G A B C D
        selectedNotes: {'E', 'F#', 'G', 'A', 'B', 'C', 'D'},
      ),
      scaleType: 'natural_minor',
      questionMode: ScaleStripQuestionMode.construction,
      explanation: '''
The E natural minor scale: E-F#-G-A-B-C-D-E.
This follows the natural minor pattern: W-H-W-W-H-W-W.
Natural minor has flattened 3rd, 6th, and 7th degrees compared to major.
      ''',
      hints: [
        'Follow the natural minor pattern: W-H-W-W-H-W-W',
        'Natural minor has ♭3, ♭6, ♭7 compared to major',
        'E natural minor is the relative minor of G major',
      ],
      tags: ['minor-scale', 'natural-minor', 'scale-construction'],
    );
  }

  /// Question 7: Major Scale Intervals - Fixed interval labeling
  static ScaleStripQuestion _createMajorScaleIntervalsQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_007',
      questionText: 'Fill out the intervals for a major scale',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 10,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: true,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.intervals,
        rootNote: 'C',
        octaveCount: 1,
        validationMode: ValidationMode.exactPositions,
        highlightRoot: true,
        useScaleDegreeLabels: true, // NEW: Use scale degree labels instead of numbers
        intervalLabelFormat: IntervalLabelFormat.scaleDegreesWithAccidentals, // NEW: 1 ♭2 2 ♭3 3 4 ♭5 5 ♭6 6 ♭7 7 8
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {0, 2, 4, 5, 7, 9, 11, 12}, // C D E F G A B C
        selectedNotes: {'C', 'D', 'E', 'F', 'G', 'A', 'B'},
      ),
      scaleType: 'major',
      questionMode: ScaleStripQuestionMode.intervals,
      explanation: '''
The major scale follows the interval pattern: 1-2-3-4-5-6-7-8 (octave).
In the key of C major, this corresponds to the notes C-D-E-F-G-A-B-C.
The major scale has the interval pattern of whole-whole-half-whole-whole-whole-half steps.
Scale degrees are labeled: 1 2 3 4 5 6 7 8, avoiding chromatic steps like ♭2, ♭5, etc.
      ''',
      hints: [
        'Start with the root note (C) and follow the major scale pattern',
        'Remember: W-W-H-W-W-W-H (W=whole step, H=half step)',
        'Major scales use natural intervals: 1, 2, 3, 4, 5, 6, 7, 8',
      ],
      tags: ['major-scale', 'intervals', 'basic-theory', 'scale-degrees'],
    );
  }

  /// Question 8: Natural Minor Scale Missing Intervals - Fixed labels and locks
  static ScaleStripQuestion _createMinorScaleMissingIntervalsQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_008',
      questionText: 'Fill in the missing intervals for the natural minor scale',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 15,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: true,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.intervals,
        rootNote: 'A',
        octaveCount: 1,
        validationMode: ValidationMode.exactPositions,
        preHighlightedPositions: {9, 12, 16, 21}, // A, C, E, A (1st, ♭3rd, 5th, 8th)
        highlightRoot: false,
        lockPreHighlighted: true, // NEW: Lock pre-highlighted positions
        useScaleDegreeLabels: true, // NEW: Use scale degree labels
        intervalLabelFormat: IntervalLabelFormat.scaleDegreesWithAccidentals, // NEW: 1 ♭2 2 ♭3 3 4 ♭5 5 ♭6 6 ♭7 7 8
        showPreHighlightedLabels: true, // NEW: Show correct labels for locked positions
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {11, 14, 19, 23}, // B, D, F, G (2nd, 4th, ♭6th, ♭7th)
        selectedNotes: {'B', 'D', 'F', 'G'},
      ),
      scaleType: 'natural_minor',
      questionMode: ScaleStripQuestionMode.intervals,
      explanation: '''
The natural minor scale pattern is: 1-2-♭3-4-5-♭6-♭7-8.
In A natural minor: A-B-C-D-E-F-G-A.
The missing intervals you needed to identify were the 2nd (B), 4th (D), ♭6th (F), and ♭7th (G).
Pre-highlighted positions show the 1st (A), ♭3rd (C), 5th (E), and 8th (A).
      ''',
      hints: [
        'The natural minor scale has flattened 3rd, 6th, and 7th intervals',
        'Follow the pattern: W-H-W-W-H-W-W',
        'The locked positions show 1, ♭3, 5, 8 - you need to find 2, 4, ♭6, ♭7',
      ],
      tags: ['minor-scale', 'intervals', 'fill-in-blanks', 'scale-degrees'],
    );
  }
}