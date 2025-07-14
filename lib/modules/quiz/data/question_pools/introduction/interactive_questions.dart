import '../../models/question_models.dart';
import '../../models/quiz_enums.dart';

/// Interactive questions for the Introduction section
class IntroductionInteractiveQuestions {
  static List<Question> get questions => [
    ...scaleQuestions,
    ...chordQuestions,
  ];

  static List<ScaleInteractiveQuestion> get scaleQuestions => [
    ScaleInteractiveQuestion(
      id: 'intro_scale_001',
      text: 'Fill in the missing notes of the C major scale',
      topicId: 'basic_scales',
      difficulty: DifficultyLevel.beginner,
      pointValue: 2.0,
      scaleKey: 'C',
      scaleType: 'major',
      displayMode: ScaleDisplayMode.mixed,
      interactionMode: ScaleInteractionMode.fillNotes,
      initialState: {
        'visibleNotes': ['C', 'E', 'G', 'C'],
        'hiddenNotes': ['D', 'F', 'A', 'B'],
        'scalePositions': [0, 1, 2, 3, 4, 5, 6, 7],
      },
      expectedAnswer: {
        'notes': {
          '0': 'C',
          '1': 'D',
          '2': 'E',
          '3': 'F',
          '4': 'G',
          '5': 'A',
          '6': 'B',
          '7': 'C',
        },
      },
      explanation: 'The C major scale contains all natural notes: C, D, E, F, G, A, B, C',
      relatedConceptIds: ['major_scale', 'scale_construction', 'natural_notes'],
    ),

    ScaleInteractiveQuestion(
      id: 'intro_scale_002',
      text: 'Identify the intervals in the G major scale',
      topicId: 'basic_scales',
      difficulty: DifficultyLevel.intermediate,
      pointValue: 3.0,
      scaleKey: 'G',
      scaleType: 'major',
      displayMode: ScaleDisplayMode.showAll,
      interactionMode: ScaleInteractionMode.fillIntervals,
      initialState: {
        'notes': ['G', 'A', 'B', 'C', 'D', 'E', 'F#', 'G'],
        'visibleIntervals': ['W', 'W'],
        'hiddenIntervals': [2, 3, 4, 5, 6],
      },
      expectedAnswer: {
        'intervals': {
          '0-1': 'W',  // G to A
          '1-2': 'W',  // A to B
          '2-3': 'H',  // B to C
          '3-4': 'W',  // C to D
          '4-5': 'W',  // D to E
          '5-6': 'W',  // E to F#
          '6-7': 'H',  // F# to G
        },
      },
      allowPartialCredit: true,
      explanation: 'The major scale pattern is: Whole, Whole, Half, Whole, Whole, Whole, Half (W-W-H-W-W-W-H)',
      relatedConceptIds: ['major_scale_pattern', 'whole_steps', 'half_steps'],
    ),

    ScaleInteractiveQuestion(
      id: 'intro_scale_003',
      text: 'Build the F major scale from scratch',
      topicId: 'basic_scales',
      difficulty: DifficultyLevel.intermediate,
      pointValue: 3.0,
      scaleKey: 'F',
      scaleType: 'major',
      displayMode: ScaleDisplayMode.hideNotes,
      interactionMode: ScaleInteractionMode.construct,
      initialState: {
        'startingNote': 'F',
        'emptyPositions': [1, 2, 3, 4, 5, 6, 7],
        'availableNotes': ['G', 'A', 'Bb', 'B', 'C', 'D', 'E', 'F'],
      },
      expectedAnswer: {
        'notes': {
          '0': 'F',
          '1': 'G',
          '2': 'A',
          '3': 'Bb',
          '4': 'C',
          '5': 'D',
          '6': 'E',
          '7': 'F',
        },
      },
      explanation: 'F major has one flat (Bb). The scale is: F, G, A, Bb, C, D, E, F',
      relatedConceptIds: ['f_major', 'flat_keys', 'scale_construction'],
    ),

    ScaleInteractiveQuestion(
      id: 'intro_scale_004',
      text: 'Highlight all the whole steps in this D major scale',
      topicId: 'basic_scales',
      difficulty: DifficultyLevel.intermediate,
      pointValue: 2.0,
      scaleKey: 'D',
      scaleType: 'major',
      displayMode: ScaleDisplayMode.showAll,
      interactionMode: ScaleInteractionMode.highlight,
      initialState: {
        'notes': ['D', 'E', 'F#', 'G', 'A', 'B', 'C#', 'D'],
        'highlightType': 'intervals',
      },
      expectedAnswer: {
        'highlightedIntervals': ['0-1', '1-2', '3-4', '4-5', '5-6'],
      },
      explanation: 'In D major, the whole steps are: D-E, E-F#, G-A, A-B, and B-C#',
      relatedConceptIds: ['whole_steps', 'major_scale_pattern', 'd_major'],
    ),

    ScaleInteractiveQuestion(
      id: 'intro_scale_005',
      text: 'Complete the chromatic scale starting from E',
      topicId: 'basic_scales',
      difficulty: DifficultyLevel.advanced,
      pointValue: 4.0,
      scaleKey: 'E',
      scaleType: 'chromatic',
      displayMode: ScaleDisplayMode.mixed,
      interactionMode: ScaleInteractionMode.fillNotes,
      initialState: {
        'visibleNotes': ['E', 'F#', 'G#', 'A#', 'C', 'D'],
        'hiddenNotes': ['F', 'G', 'A', 'B', 'C#', 'D#', 'E'],
        'scaleLength': 13,
      },
      expectedAnswer: {
        'notes': {
          '0': 'E',
          '1': 'F',
          '2': 'F#',
          '3': 'G',
          '4': 'G#',
          '5': 'A',
          '6': 'A#',
          '7': 'B',
          '8': 'C',
          '9': 'C#',
          '10': 'D',
          '11': 'D#',
          '12': 'E',
        },
      },
      allowPartialCredit: true,
      explanation: 'A chromatic scale includes all 12 pitches, each a half step apart',
      relatedConceptIds: ['chromatic_scale', 'half_steps', 'all_twelve_notes'],
    ),
  ];

  static List<ChordInteractiveQuestion> get chordQuestions => [
    ChordInteractiveQuestion(
      id: 'intro_chord_001',
      text: 'Place your fingers to form a C major chord',
      topicId: 'basic_chords',
      difficulty: DifficultyLevel.beginner,
      pointValue: 2.0,
      chordName: 'C major',
      fretboardMode: FretboardMode.chord,
      initialState: {
        'strings': 6,
        'frets': 5,
        'showFingerNumbers': true,
        'highlightStrings': [2, 3, 4, 5],
      },
      acceptablePositions: [
        {
          'positions': {
            '1': 'x',  // 1st string (high E) - muted
            '2': 3,    // 2nd string - 3rd fret (C)
            '3': 2,    // 3rd string - 2nd fret (E)
            '4': 0,    // 4th string - open (G)
            '5': 1,    // 5th string - 1st fret (C)
            '6': 'x',  // 6th string (low E) - muted
          },
        },
      ],
      explanation: 'The open C major chord uses fingers on the 5th, 3rd, and 2nd strings',
      relatedConceptIds: ['c_major_chord', 'open_chords', 'chord_fingering'],
    ),

    ChordInteractiveQuestion(
      id: 'intro_chord_002',
      text: 'Form a G major chord on the fretboard',
      topicId: 'basic_chords',
      difficulty: DifficultyLevel.beginner,
      pointValue: 2.0,
      chordName: 'G major',
      fretboardMode: FretboardMode.chord,
      initialState: {
        'strings': 6,
        'frets': 5,
        'showFingerNumbers': true,
      },
      acceptablePositions: [
        {
          'positions': {
            '1': 3,    // 1st string - 3rd fret (G)
            '2': 0,    // 2nd string - open (B)
            '3': 0,    // 3rd string - open (G)
            '4': 0,    // 4th string - open (D)
            '5': 2,    // 5th string - 2nd fret (B)
            '6': 3,    // 6th string - 3rd fret (G)
          },
        },
        {
          // Alternative fingering
          'positions': {
            '1': 3,    // 1st string - 3rd fret (G)
            '2': 3,    // 2nd string - 3rd fret (D)
            '3': 0,    // 3rd string - open (G)
            '4': 0,    // 4th string - open (D)
            '5': 2,    // 5th string - 2nd fret (B)
            '6': 3,    // 6th string - 3rd fret (G)
          },
        },
      ],
      explanation: 'The G major chord can be played with all strings ringing',
      relatedConceptIds: ['g_major_chord', 'open_chords', 'chord_variations'],
    ),

    ChordInteractiveQuestion(
      id: 'intro_chord_003',
      text: 'Create an A minor chord',
      topicId: 'basic_chords',
      difficulty: DifficultyLevel.beginner,
      pointValue: 2.0,
      chordName: 'A minor',
      fretboardMode: FretboardMode.chord,
      initialState: {
        'strings': 6,
        'frets': 5,
        'showFingerNumbers': true,
        'showChordDiagram': false,
      },
      acceptablePositions: [
        {
          'positions': {
            '1': 0,    // 1st string - open (E)
            '2': 1,    // 2nd string - 1st fret (C)
            '3': 2,    // 3rd string - 2nd fret (A)
            '4': 2,    // 4th string - 2nd fret (E)
            '5': 0,    // 5th string - open (A)
            '6': 'x',  // 6th string - muted
          },
        },
      ],
      explanation: 'A minor is one of the easiest chords, requiring only 3 fingers',
      relatedConceptIds: ['a_minor_chord', 'minor_chords', 'open_chords'],
    ),

    ChordInteractiveQuestion(
      id: 'intro_chord_004',
      text: 'Identify the notes in this D major chord shape',
      topicId: 'basic_chords',
      difficulty: DifficultyLevel.intermediate,
      pointValue: 3.0,
      chordName: 'D major',
      fretboardMode: FretboardMode.singleNote,
      initialState: {
        'strings': 6,
        'frets': 5,
        'chordPositions': {
          '1': 2,    // 1st string - 2nd fret
          '2': 3,    // 2nd string - 3rd fret
          '3': 2,    // 3rd string - 2nd fret
          '4': 0,    // 4th string - open
          '5': 'x',  // 5th string - muted
          '6': 'x',  // 6th string - muted
        },
        'identifyNotes': true,
      },
      acceptablePositions: [
        {
          'noteNames': {
            '1': 'F#',  // 1st string 2nd fret
            '2': 'D',   // 2nd string 3rd fret
            '3': 'A',   // 3rd string 2nd fret
            '4': 'D',   // 4th string open
          },
        },
      ],
      requireExactPosition: false,
      explanation: 'D major chord contains the notes D, F#, and A',
      relatedConceptIds: ['d_major_chord', 'chord_tones', 'note_identification'],
    ),

    ChordInteractiveQuestion(
      id: 'intro_chord_005',
      text: 'Build an E minor chord from scratch',
      topicId: 'basic_chords',
      difficulty: DifficultyLevel.intermediate,
      pointValue: 3.0,
      chordName: 'E minor',
      fretboardMode: FretboardMode.chord,
      initialState: {
        'strings': 6,
        'frets': 5,
        'emptyFretboard': true,
        'availableFingers': 2,
      },
      acceptablePositions: [
        {
          'positions': {
            '1': 0,    // 1st string - open (E)
            '2': 0,    // 2nd string - open (B)
            '3': 0,    // 3rd string - open (G)
            '4': 2,    // 4th string - 2nd fret (E)
            '5': 2,    // 5th string - 2nd fret (B)
            '6': 0,    // 6th string - open (E)
          },
        },
      ],
      explanation: 'E minor uses only 2 fingers and all strings can ring',
      relatedConceptIds: ['e_minor_chord', 'easy_chords', 'chord_construction'],
    ),
  ];
}