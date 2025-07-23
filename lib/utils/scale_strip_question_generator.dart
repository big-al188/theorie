// lib/utils/scale_strip_question_generator.dart

import '../models/quiz/scale_strip_question.dart';
import '../models/quiz/quiz_question.dart';
import '../models/music/scale.dart';
import '../models/music/interval.dart';
import '../models/music/note.dart';
import 'music_utils.dart';
import 'scale_strip_utils.dart';

/// Enhanced generator for scale strip questions with proper octave and enharmonic handling
class ScaleStripQuestionGenerator {
  /// Generate octave questions with proper 13th position handling
  /// FIXED: Each question uses its own root note as the strip root
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
          rootNote: rootNote,  // FIX: Strip root matches question root
          octaveCount: 1,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          preHighlightedPositions: const {},
          highlightRoot: true,
          showEmptyPositions: true,
          keyContext: rootNote,
          fillScreenWidth: true,
        ),
        correctAnswer: _generateOctaveAnswer(rootNote),
        scaleType: 'octave',
        questionMode: ScaleStripQuestionMode.intervals,
        explanation: _generateOctaveExplanation(rootNote),
      );
      questions.add(question);
      questionId++;
    }

    return questions;
  }

  /// Generate enhanced chromatic scale questions with proper enharmonic handling
  /// FIXED: Each question uses its own root note as the strip root
  static List<ScaleStripQuestion> generateChromaticQuestions({
    List<String> rootNotes = const ['C', 'F#', 'Gb', 'Bb', 'G'],
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
          rootNote: rootNote,  // Strip root matches question root
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
      );
      questions.add(question);
      questionId++;
    }

    return questions;
  }

  /// Generate interval questions with proper octave handling
  /// FIXED: Each question uses its own root note as the strip root
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
  /// FIXED: Each question uses its own root note as the strip root
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

  /// Generate octave answer for a given root note
  static ScaleStripAnswer _generateOctaveAnswer(String rootNote) {
    // For octave questions on a strip rooted at the same note,
    // positions 0 and 12 both represent the root note
    return ScaleStripAnswer(
      selectedPositions: {0, 12},
      selectedNotes: {rootNote},
    );
  }

  /// Generate chromatic answer for a given root note
  static ScaleStripAnswer _generateChromaticAnswer(String rootNote) {
    return ScaleStripUtils.generateChromaticAnswer(rootNote, includeOctave: true);
  }

  /// Get natural note positions relative to the given root
  static Set<int> _getNaturalNotePositions(String rootNote) {
    return ScaleStripUtils.getNaturalNotePositions(rootNote);
  }

  /// Generate an interval question
  static ScaleStripQuestion _generateIntervalQuestion(
    String rootNote,
    Interval interval,
    String questionId,
  ) {
    final intervalSemitones = interval.semitones;
    
    // FIX: Use the interval utility to calculate correct position
    final answer = ScaleStripUtils.generateIntervalAnswer(
      questionRoot: rootNote,
      stripRoot: rootNote,  // Strip root matches question root
      intervalSemitones: intervalSemitones,
      includeOctave: intervalSemitones == 12,
    );
    
    return ScaleStripQuestion(
      id: questionId,
      questionText: 'Select the ${interval.name} from $rootNote',
      topic: QuestionTopic.intervals,
      difficulty: _getIntervalDifficulty(interval),
      pointValue: 5,
      configuration: ScaleStripConfiguration(
        showIntervalLabels: true,
        showNoteLabels: true,
        allowMultipleSelection: false,
        displayMode: ScaleStripMode.intervals,
        rootNote: rootNote,  // Strip root matches question root
        octaveCount: 1,
        includeOctaveNote: intervalSemitones == 12,
        validationMode: ValidationMode.exactPositions,
        highlightRoot: true,
        keyContext: rootNote,
        fillScreenWidth: true,
      ),
      correctAnswer: answer,
      questionMode: ScaleStripQuestionMode.intervals,
      explanation: _generateIntervalExplanation(rootNote, interval, answer),
    );
  }

  /// Generate a scale question
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
      );
    } catch (e) {
      // Scale type not found or other error
      return null;
    }
  }

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

  static String _generateOctaveExplanation(String rootNote) {
    return '''
An octave is the interval between a note and the next occurrence of the same note name, either higher or lower in pitch. 

From $rootNote to the next $rootNote is exactly 12 semitones (half-steps), which creates the octave interval. This is why we have position 1 ($rootNote) and position 13 (the next $rootNote) selected.

The octave is one of the most fundamental intervals in music - it sounds so similar that we give both notes the same name!
    ''';
  }

  static String _generateChromaticExplanation(String rootNote) {
    final keySignature = MusicUtils.getKeySignature(rootNote);
    final preferFlats = keySignature['flats'] > 0;
    final accidentalType = preferFlats ? 'flats' : 'sharps';
    
    return '''
The chromatic scale contains all 12 different pitches within an octave, starting from $rootNote.

Since $rootNote is a ${preferFlats ? 'flat' : 'sharp'} key context, we typically use $accidentalType for the missing notes. However, both sharp and flat spellings are acceptable - for example, C# and Db are the same pitch, just spelled differently.

The natural notes are already provided. You need to fill in the missing chromatic notes between them, plus the octave $rootNote at the end.

Remember: There are no sharps or flats between E-F and B-C because these pairs are already a half-step apart!
    ''';
  }

  static String _generateIntervalExplanation(String rootNote, Interval interval, ScaleStripAnswer answer) {
    final targetNotes = answer.selectedNotes.toList();
    final targetNote = targetNotes.isNotEmpty ? targetNotes.first : '';
    
    // Generate description based on interval properties
    String description;
    if (interval.isPerfect) {
      description = 'This is a perfect interval, which means it has a very stable and consonant sound.';
    } else if (interval.isConsonant) {
      description = 'This is a consonant interval that sounds pleasant and stable.';
    } else {
      description = 'This interval creates tension and is often used to add color to music.';
    }
    
    return '''
A ${interval.name} from $rootNote is $targetNote, which is ${interval.semitones} semitones away.

$description The ${interval.quality.symbol} quality gives this interval its characteristic sound.

On this scale strip rooted at $rootNote, the ${interval.name} appears at position ${answer.selectedPositions.first + 1}.
    ''';
  }

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

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}