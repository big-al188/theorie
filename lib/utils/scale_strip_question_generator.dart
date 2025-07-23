// lib/utils/scale_strip_question_generator.dart

import 'dart:math';
import '../models/music/scale.dart';
import '../models/music/chord.dart';
import '../models/music/note.dart';
import '../models/music/interval.dart';
import '../models/quiz/scale_strip_question.dart';
import '../models/quiz/quiz_question.dart';

/// Generalized generator for scale strip questions using music theory models
class ScaleStripQuestionGenerator {
  static final Random _random = Random();

  /// Generate questions for a specific scale
  static List<ScaleStripQuestion> generateScaleQuestions(
    Scale scale, {
    List<String> rootNotes = const ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
    List<ScaleStripQuestionMode> modes = const [
      ScaleStripQuestionMode.construction,
      ScaleStripQuestionMode.intervals,
      ScaleStripQuestionMode.pattern,
    ],
  }) {
    final questions = <ScaleStripQuestion>[];
    var questionId = 1;

    for (final rootNote in rootNotes) {
      for (final mode in modes) {
        final question = _generateScaleQuestion(
          scale,
          rootNote,
          mode,
          'scale_${scale.name.toLowerCase().replaceAll(' ', '_')}_${rootNote.toLowerCase()}_${mode.name}_${questionId++}',
        );
        questions.add(question);
      }
    }

    return questions;
  }

  /// Generate questions for a specific chord type
  static List<ScaleStripQuestion> generateChordQuestions(
    Chord chord, {
    List<String> rootNotes = const ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
    List<ScaleStripQuestionMode> modes = const [
      ScaleStripQuestionMode.construction,
      ScaleStripQuestionMode.intervals,
    ],
  }) {
    final questions = <ScaleStripQuestion>[];
    var questionId = 1;

    for (final rootNote in rootNotes) {
      for (final mode in modes) {
        final question = _generateChordQuestion(
          chord,
          rootNote,
          mode,
          'chord_${chord.type}_${rootNote.toLowerCase()}_${mode.name}_${questionId++}',
        );
        questions.add(question);
      }
    }

    return questions;
  }

  /// Generate questions for all available scales
  static List<ScaleStripQuestion> generateAllScaleQuestions({
    List<String> scaleNames = const [
      'Major',
      'Natural Minor',
      'Major Pentatonic',
      'Minor Pentatonic',
      'Blues',
      'Dorian',
      'Mixolydian',
    ],
    List<String> rootNotes = const ['C', 'G', 'D', 'A', 'E', 'F'],
    int maxQuestions = 50,
  }) {
    final questions = <ScaleStripQuestion>[];

    for (final scaleName in scaleNames) {
      final scale = Scale.get(scaleName);
      if (scale != null) {
        final scaleQuestions = generateScaleQuestions(
          scale,
          rootNotes: rootNotes.take(3).toList(), // Limit to avoid too many
        );
        questions.addAll(scaleQuestions);
      }
    }

    // Shuffle and limit
    questions.shuffle(_random);
    return questions.take(maxQuestions).toList();
  }

  /// Generate questions for all basic chords
  static List<ScaleStripQuestion> generateAllChordQuestions({
    List<String> chordTypes = const [
      'major',
      'minor',
      'diminished',
      'augmented',
      'sus2',
      'sus4',
      'major7',
      'minor7',
      'dominant7',
      'add9',
    ],
    List<String> rootNotes = const ['C', 'G', 'D', 'A', 'E', 'F'],
    int maxQuestions = 30,
  }) {
    final questions = <ScaleStripQuestion>[];

    for (final chordType in chordTypes) {
      final chord = Chord.get(chordType);
      if (chord != null) {
        final chordQuestions = generateChordQuestions(
          chord,
          rootNotes: rootNotes.take(2).toList(), // Limit to avoid too many
        );
        questions.addAll(chordQuestions);
      }
    }

    // Shuffle and limit
    questions.shuffle(_random);
    return questions.take(maxQuestions).toList();
  }

  /// Generate interval recognition questions
  static List<ScaleStripQuestion> generateIntervalQuestions({
    List<String> rootNotes = const ['C', 'F', 'G'],
    List<Interval> intervals = const [
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

  /// Generate chromatic scale questions
  static List<ScaleStripQuestion> generateChromaticQuestions({
    List<String> rootNotes = const ['C', 'F#', 'Bb'],
  }) {
    final questions = <ScaleStripQuestion>[];
    final chromaticScale = Scale.chromatic;
    var questionId = 1;

    for (final rootNote in rootNotes) {
      // Fill-in-the-blanks chromatic question
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
          validationMode: ValidationMode.noteNames,
          preHighlightedPositions: _getNaturalNotePositions(rootNote),
          showEmptyPositions: true,
          lockPreHighlighted: true,
          useDropdownSelection: true,
          showPreHighlightedLabels: true,
        ),
        correctAnswer: _generateChromaticAnswer(rootNote),
        scaleType: 'chromatic',
        questionMode: ScaleStripQuestionMode.notes,
        explanation: _generateChromaticExplanation(rootNote),
        hints: [
          'The chromatic scale includes every semitone',
          'Remember: no sharps between E-F and B-C',
          'Click on empty positions to select notes',
        ],
        tags: ['chromatic', 'note-names', 'sharps-flats'],
      );
      questions.add(question);
      questionId++;
    }

    return questions;
  }

  /// Generate a scale question
  static ScaleStripQuestion _generateScaleQuestion(
    Scale scale,
    String rootNote,
    ScaleStripQuestionMode mode,
    String id,
  ) {
    final root = Note.fromString(rootNote);
    final scaleNotes = scale.getNotesForRoot(root);
    final correctPositions = _calculatePositionsFromRoot(scaleNotes, rootNote);
    final correctNoteNames = scaleNotes.map((n) => n.name).toSet();

    final difficulty = _getScaleDifficulty(scale);
    final pointValue = _getPointValue(difficulty, mode);

    return ScaleStripQuestion(
      id: id,
      questionText: _generateScaleQuestionText(scale, rootNote, mode),
      topic: QuestionTopic.scales,
      difficulty: difficulty,
      pointValue: pointValue,
      configuration: _generateScaleConfiguration(scale, rootNote, mode),
      correctAnswer: ScaleStripAnswer(
        selectedPositions: correctPositions,
        selectedNotes: correctNoteNames,
      ),
      scaleType: scale.name.toLowerCase().replaceAll(' ', '_'),
      questionMode: mode,
      explanation: _generateScaleExplanation(scale, rootNote, scaleNotes),
      hints: _generateScaleHints(scale, mode),
      tags: _generateScaleTags(scale),
    );
  }

  /// Generate a chord question
  static ScaleStripQuestion _generateChordQuestion(
    Chord chord,
    String rootNote,
    ScaleStripQuestionMode mode,
    String id,
  ) {
    final root = Note.fromString(rootNote);
    final chordNotes = chord.getNotesForRoot(root);
    final correctPositions = _calculatePositionsFromRoot(chordNotes, rootNote);
    final correctNoteNames = chordNotes.map((n) => n.name).toSet();

    final difficulty = _getChordDifficulty(chord);
    final pointValue = _getPointValue(difficulty, mode);
    final octaveCount = _getRecommendedOctaveCount(chord);

    return ScaleStripQuestion(
      id: id,
      questionText: _generateChordQuestionText(chord, rootNote, mode),
      topic: QuestionTopic.chords,
      difficulty: difficulty,
      pointValue: pointValue,
      configuration: _generateChordConfiguration(chord, rootNote, mode, octaveCount),
      correctAnswer: ScaleStripAnswer(
        selectedPositions: correctPositions,
        selectedNotes: correctNoteNames,
      ),
      scaleType: chord.type,
      questionMode: mode,
      explanation: _generateChordExplanation(chord, rootNote, chordNotes),
      hints: _generateChordHints(chord, mode),
      tags: _generateChordTags(chord),
    );
  }

  /// Generate an interval question
  static ScaleStripQuestion _generateIntervalQuestion(
    String rootNote,
    Interval interval,
    String id,
  ) {
    final root = Note.fromString(rootNote);
    final targetNote = root.transpose(interval.semitones);
    final correctPositions = _calculatePositionsFromRoot([root, targetNote], rootNote);

    return ScaleStripQuestion(
      id: id,
      questionText: 'Select the ${interval.name} from $rootNote',
      topic: QuestionTopic.intervals,
      difficulty: QuestionDifficulty.intermediate,
      pointValue: 8,
      configuration: ScaleStripConfiguration(
        showIntervalLabels: true,
        showNoteLabels: true,
        allowMultipleSelection: false,
        displayMode: ScaleStripMode.intervals,
        rootNote: rootNote,
        octaveCount: 1,
        validationMode: ValidationMode.exactPositions,
        preHighlightedPositions: {0}, // Highlight root
        lockPreHighlighted: true,
      ),
      correctAnswer: ScaleStripAnswer(
        selectedPositions: {interval.semitones},
        selectedNotes: {targetNote.name},
      ),
      scaleType: 'interval',
      questionMode: ScaleStripQuestionMode.intervals,
      explanation: 'A ${interval.name} is ${interval.semitones} semitones from the root note.',
      hints: [
        'Count ${interval.semitones} semitones from the root',
        'The root note is already highlighted',
      ],
      tags: ['intervals', 'recognition'],
    );
  }

  /// Calculate chromatic positions from a root note
  static Set<int> _calculatePositionsFromRoot(List<Note> notes, String rootNote) {
    final rootPc = Note.fromString(rootNote).pitchClass;
    final positions = <int>{};
    
    for (final note in notes) {
      final position = (note.pitchClass - rootPc + 12) % 12;
      positions.add(position);
    }
    
    return positions;
  }

  /// Get natural note positions for chromatic fill-in
  static Set<int> _getNaturalNotePositions(String rootNote) {
    final naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final rootPc = Note.fromString(rootNote).pitchClass;
    final positions = <int>{};
    
    for (final noteName in naturalNotes) {
      final notePc = Note.fromString(noteName).pitchClass;
      final position = (notePc - rootPc + 12) % 12;
      positions.add(position);
    }
    
    return positions;
  }

  /// Generate chromatic answer with missing sharps/flats
  static ScaleStripAnswer _generateChromaticAnswer(String rootNote) {
    final chromaticScale = Scale.chromatic;
    final root = Note.fromString(rootNote);
    final allNotes = chromaticScale.getNotesForRoot(root);
    final naturalPositions = _getNaturalNotePositions(rootNote);
    
    final missingPositions = <int>{};
    final missingNotes = <String>{};
    
    for (int i = 0; i < 12; i++) {
      if (!naturalPositions.contains(i)) {
        missingPositions.add(i);
        final noteAtPosition = allNotes[i];
        missingNotes.add(noteAtPosition.name);
      }
    }
    
    return ScaleStripAnswer(
      selectedPositions: missingPositions,
      selectedNotes: missingNotes,
    );
  }

  /// Generate configuration based on scale properties
  static ScaleStripConfiguration _generateScaleConfiguration(
    Scale scale,
    String rootNote,
    ScaleStripQuestionMode mode,
  ) {
    switch (mode) {
      case ScaleStripQuestionMode.construction:
        return ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.construction,
          rootNote: rootNote,
          octaveCount: 1,
          validationMode: ValidationMode.exactPositions,
        );
      
      case ScaleStripQuestionMode.intervals:
        return ScaleStripConfiguration(
          showIntervalLabels: true,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.intervals,
          rootNote: rootNote,
          octaveCount: 1,
          validationMode: ValidationMode.exactPositions,
          useScaleDegreeLabels: true,
          intervalLabelFormat: IntervalLabelFormat.scaleDegreesWithAccidentals,
        );
      
      case ScaleStripQuestionMode.pattern:
        return ScaleStripConfiguration(
          showIntervalLabels: false,
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.pattern,
          rootNote: 'C', // Start from C to test pattern understanding
          octaveCount: 1,
          validationMode: ValidationMode.pattern,
        );
      
      default:
        return const ScaleStripConfiguration();
    }
  }

  /// Generate configuration based on chord properties
  static ScaleStripConfiguration _generateChordConfiguration(
    Chord chord,
    String rootNote,
    ScaleStripQuestionMode mode,
    int octaveCount,
  ) {
    return ScaleStripConfiguration(
      showIntervalLabels: mode == ScaleStripQuestionMode.intervals,
      showNoteLabels: true,
      allowMultipleSelection: true,
      displayMode: mode == ScaleStripQuestionMode.intervals 
          ? ScaleStripMode.intervals 
          : ScaleStripMode.construction,
      rootNote: rootNote,
      octaveCount: octaveCount,
      validationMode: ValidationMode.exactPositions,
      enableOctaveDistinction: octaveCount > 1,
    );
  }

  /// Determine difficulty based on scale complexity
  static QuestionDifficulty _getScaleDifficulty(Scale scale) {
    if (scale.name == 'Major' || scale.name == 'Major Pentatonic') {
      return QuestionDifficulty.beginner;
    } else if (scale.name == 'Natural Minor' || scale.name == 'Minor Pentatonic' || scale.name == 'Blues') {
      return QuestionDifficulty.beginner;
    } else if (scale.name.contains('Dorian') || scale.name.contains('Mixolydian')) {
      return QuestionDifficulty.intermediate;
    } else {
      return QuestionDifficulty.advanced;
    }
  }

  /// Determine difficulty based on chord complexity
  static QuestionDifficulty _getChordDifficulty(Chord chord) {
    if (chord.category == 'Basic Triads') {
      return QuestionDifficulty.beginner;
    } else if (chord.category == 'Suspended' || chord.category == 'Seventh Chords') {
      return QuestionDifficulty.intermediate;
    } else {
      return QuestionDifficulty.advanced;
    }
  }

  /// Get recommended octave count for chords
  static int _getRecommendedOctaveCount(Chord chord) {
    // Check if chord has intervals beyond an octave
    final hasExtendedIntervals = chord.intervals.any((interval) => interval > 12);
    return hasExtendedIntervals ? 2 : 1;
  }

  /// Generate question text based on context
  static String _generateScaleQuestionText(Scale scale, String rootNote, ScaleStripQuestionMode mode) {
    switch (mode) {
      case ScaleStripQuestionMode.construction:
        return 'Select all notes in the $rootNote ${scale.name.toLowerCase()} scale';
      case ScaleStripQuestionMode.intervals:
        return 'Fill out the intervals for a ${scale.name.toLowerCase()} scale in $rootNote';
      case ScaleStripQuestionMode.pattern:
        return 'Select the notes that follow the ${scale.name.toLowerCase()} pattern starting from $rootNote';
      default:
        return 'Complete the ${scale.name.toLowerCase()} scale starting from $rootNote';
    }
  }

  static String _generateChordQuestionText(Chord chord, String rootNote, ScaleStripQuestionMode mode) {
    final chordSymbol = chord.getSymbol(rootNote);
    switch (mode) {
      case ScaleStripQuestionMode.construction:
        return 'Construct a $chordSymbol chord';
      case ScaleStripQuestionMode.intervals:
        return 'Select the intervals for a ${chord.displayName.toLowerCase()} chord';
      default:
        return 'Build a $chordSymbol chord';
    }
  }

  /// Generate explanations
  static String _generateScaleExplanation(Scale scale, String rootNote, List<Note> notes) {
    final noteNames = notes.map((n) => n.name).join('-');
    return 'The $rootNote ${scale.name.toLowerCase()} scale: $noteNames.\n'
           'This scale contains ${scale.length} notes with the interval pattern: ${scale.degrees.join('-')}.';
  }

  static String _generateChordExplanation(Chord chord, String rootNote, List<Note> notes) {
    final noteNames = notes.map((n) => n.name).join('-');
    final intervals = chord.intervals.map((i) => '${i} semitones').join(', ');
    return 'The $rootNote ${chord.displayName.toLowerCase()}: $noteNames.\n'
           'This chord has intervals of $intervals from the root.';
  }

  static String _generateChromaticExplanation(String rootNote) {
    return 'The chromatic scale contains all 12 notes. From $rootNote, this includes every semitone up to the octave. '
           'Remember that there are no sharps between E-F and B-C (natural half steps).';
  }

  /// Generate hints
  static List<String> _generateScaleHints(Scale scale, ScaleStripQuestionMode mode) {
    final hints = <String>[];
    
    if (scale.name == 'Major') {
      hints.add('Major scales follow the W-W-H-W-W-W-H pattern');
    } else if (scale.name == 'Natural Minor') {
      hints.add('Natural minor follows the W-H-W-W-H-W-W pattern');
    }
    
    if (mode == ScaleStripQuestionMode.intervals) {
      hints.add('Focus on the interval pattern: ${scale.degrees.join('-')}');
    }
    
    return hints;
  }

  static List<String> _generateChordHints(Chord chord, ScaleStripQuestionMode mode) {
    final hints = <String>[];
    
    if (chord.category == 'Basic Triads') {
      if (chord.type == 'major') {
        hints.add('Major triads: Root + Major 3rd + Perfect 5th');
      } else if (chord.type == 'minor') {
        hints.add('Minor triads: Root + Minor 3rd + Perfect 5th');
      }
    }
    
    hints.add('Count semitones: ${chord.intervals.join(', ')}');
    
    return hints;
  }

  /// Generate tags
  static List<String> _generateScaleTags(Scale scale) {
    final tags = ['scales', scale.name.toLowerCase().replaceAll(' ', '-')];
    
    if (scale.name.contains('Major')) tags.add('major');
    if (scale.name.contains('Minor')) tags.add('minor');
    if (scale.name.contains('Pentatonic')) tags.add('pentatonic');
    
    return tags;
  }

  static List<String> _generateChordTags(Chord chord) {
    final tags = ['chords', chord.type, chord.category.toLowerCase().replaceAll(' ', '-')];
    return tags;
  }

  /// Get point value based on difficulty and mode
  static int _getPointValue(QuestionDifficulty difficulty, ScaleStripQuestionMode mode) {
    var base = switch (difficulty) {
      QuestionDifficulty.beginner => 10,
      QuestionDifficulty.intermediate => 15,
      QuestionDifficulty.advanced => 20,
      QuestionDifficulty.expert => 25,
    };
    
    // Adjust for question mode complexity
    if (mode == ScaleStripQuestionMode.pattern) base += 5;
    if (mode == ScaleStripQuestionMode.intervals) base += 3;
    
    return base;
  }
}