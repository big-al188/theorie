// lib/models/quiz/sections/introduction/scale_strip_quiz_questions.dart

import '../../scale_strip_question.dart';
import '../../quiz_question.dart';

/// Quiz questions for "Scale Strip Quiz" topic in Introduction section
class ScaleStripQuizQuestions {
  static const String sectionId = 'introduction';
  static const String topicId = 'scale-strip-quiz';
  static const String topicTitle = 'Scale Strip Quiz';

  static List<ScaleStripQuestion> getQuestions() {
    return [
      _createMajorScaleIntervalsQuestion(),
      _createMinorScaleMissingIntervalsQuestion(),
      _createChromaticScaleNotesQuestion(),
      _createCMajorTriadConstructionQuestion(),
      _createMajorScalePatternQuestion(),
      _createPentatonicScaleQuestion(),
      _createDiminishedTriadQuestion(),
      _createNaturalMinorScaleQuestion(),
    ];
  }

  /// Question 1: Fill out the intervals for a major scale
  static ScaleStripQuestion _createMajorScaleIntervalsQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_001',
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
      ''',
      hints: [
        'Start with the root note (C) and follow the major scale pattern',
        'Remember: W-W-H-W-W-W-H (W=whole step, H=half step)',
      ],
      tags: ['major-scale', 'intervals', 'basic-theory'],
    );
  }

  /// Question 2: Fill in missing intervals for minor scale
  static ScaleStripQuestion _createMinorScaleMissingIntervalsQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_002',
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
        preHighlightedPositions: {9, 12, 16, 21}, // A, C, E, A (1st, 3rd, 5th, 8th)
        highlightRoot: false,
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {11, 14, 19}, // B, D, G (2nd, 4th, 6th, 7th)
        selectedNotes: {'B', 'D', 'G'},
      ),
      scaleType: 'natural_minor',
      questionMode: ScaleStripQuestionMode.intervals,
      explanation: '''
The natural minor scale pattern is: 1-2-♭3-4-5-♭6-♭7-8.
In A natural minor: A-B-C-D-E-F-G-A.
The missing intervals you needed to identify were the 2nd (B), 4th (D), 6th (F), and 7th (G).
      ''',
      hints: [
        'The natural minor scale has flattened 3rd, 6th, and 7th intervals',
        'Follow the pattern: W-H-W-W-H-W-W',
      ],
      tags: ['minor-scale', 'intervals', 'fill-in-blanks'],
    );
  }

  /// Question 3: Label missing notes in chromatic scale
  static ScaleStripQuestion _createChromaticScaleNotesQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_003',
      questionText: 'Label the missing notes in the chromatic scale',
      topic: QuestionTopic.notes,
      difficulty: QuestionDifficulty.beginner,
      pointValue: 12,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: false,
        showNoteLabels: false,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.fillInBlanks,
        rootNote: 'C',
        octaveCount: 1,
        validationMode: ValidationMode.noteNames,
        preHighlightedPositions: {0, 2, 4, 5, 7, 9, 11}, // C, D, E, F, G, A, B
        showEmptyPositions: true,
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
        'Remember: no sharps between E-F and B-C',
      ],
      tags: ['chromatic-scale', 'note-names', 'sharps-flats'],
    );
  }

  /// Question 4: Construct C Major Triad
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
        rootNote: 'F', // Start from different root to test understanding
        octaveCount: 2,
        validationMode: ValidationMode.noteNames,
        highlightRoot: false,
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {5, 9, 12}, // C, E, G positions (will vary by octave)
        selectedNotes: {'C', 'E', 'G'},
      ),
      scaleType: 'major_triad',
      questionMode: ScaleStripQuestionMode.construction,
      explanation: '''
A C Major triad consists of the notes C, E, and G.
This represents the 1st, 3rd, and 5th degrees of the C major scale.
Major triads have a major third (4 semitones) and perfect fifth (7 semitones) from the root.
      ''',
      hints: [
        'A major triad uses the 1st, 3rd, and 5th notes of the major scale',
        'Look for C, E, and G anywhere on the scale strip',
      ],
      tags: ['triads', 'chord-construction', 'major-chords'],
    );
  }

  /// Question 5: Major Scale Pattern Recognition
  static ScaleStripQuestion _createMajorScalePatternQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_005',
      questionText: 'Select the notes that follow the major scale pattern starting from G',
      topic: QuestionTopic.scales,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 18,
      configuration: const ScaleStripConfiguration(
        showIntervalLabels: false,
        showNoteLabels: true,
        allowMultipleSelection: true,
        displayMode: ScaleStripMode.construction,
        rootNote: 'G',
        octaveCount: 1,
        validationMode: ValidationMode.pattern,
        highlightRoot: true,
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {7, 9, 11, 0, 2, 4, 6}, // G A B C D E F# (removed duplicate 7)
        selectedNotes: {'G', 'A', 'B', 'C', 'D', 'E', 'F#'},
      ),
      scaleType: 'major',
      questionMode: ScaleStripQuestionMode.pattern,
      explanation: '''
The G major scale follows the major scale pattern: W-W-H-W-W-W-H.
Starting from G: G-A-B-C-D-E-F#-G.
Notice that F# is required to maintain the correct interval pattern.
      ''',
      hints: [
        'Follow the W-W-H-W-W-W-H pattern from the root',
        'You may need to use sharps or flats to maintain the pattern',
      ],
      tags: ['major-scale', 'pattern-recognition', 'key-signatures'],
    );
  }

  /// Question 6: Pentatonic Scale
  static ScaleStripQuestion _createPentatonicScaleQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_006',
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
        highlightRoot: true,
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {0, 2, 4, 7, 9, 12}, // C D E G A C
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
      ],
      tags: ['pentatonic', 'five-note-scales', 'world-music'],
    );
  }

  /// Question 7: Diminished Triad
  static ScaleStripQuestion _createDiminishedTriadQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_007',
      questionText: 'Construct a B diminished triad',
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
        validationMode: ValidationMode.noteNames,
        highlightRoot: false,
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {11, 14, 17}, // B D F
        selectedNotes: {'B', 'D', 'F'},
      ),
      scaleType: 'diminished_triad',
      questionMode: ScaleStripQuestionMode.construction,
      explanation: '''
A diminished triad consists of a root, minor third, and diminished fifth.
B diminished triad: B-D-F.
The intervals are: minor third (3 semitones) and diminished fifth (6 semitones) from root.
      ''',
      hints: [
        'Diminished triads have a minor third and diminished fifth',
        'Count 3 semitones for minor third, 6 semitones for diminished fifth',
      ],
      tags: ['diminished-chords', 'advanced-harmony', 'chord-construction'],
    );
  }

  /// Question 8: Natural Minor Scale
  static ScaleStripQuestion _createNaturalMinorScaleQuestion() {
    return ScaleStripQuestion(
      id: 'scale_strip_008',
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
        highlightRoot: true,
      ),
      correctAnswer: const ScaleStripAnswer(
        selectedPositions: {4, 6, 7, 9, 11, 0, 2}, // E F# G A B C D (removed duplicate 4)
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
        'Natural minor pattern: W-H-W-W-H-W-W',
        'Think of it as the relative minor of G major',
      ],
      tags: ['minor-scales', 'natural-minor', 'relative-keys'],
    );
  }
}