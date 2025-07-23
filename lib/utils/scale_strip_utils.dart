// lib/utils/scale_strip_utils.dart

import '../models/music/note.dart';
import '../models/music/scale.dart';
import '../models/music/chord.dart';
import '../models/quiz/scale_strip_question.dart';
import 'music_utils.dart';
import '../constants/music_constants.dart';

/// Enhanced utility functions for scale strip quiz integration with proper enharmonic handling
class ScaleStripUtils {
  
  /// Calculate positions on the strip from notes relative to a root
  /// FIXED: Properly handle when question root differs from strip root
  static Set<int> calculatePositions(List<Note> notes, String stripRoot) {
    final stripRootPc = Note.fromString(stripRoot).pitchClass;
    final positions = <int>{};
    
    for (final note in notes) {
      final position = (note.pitchClass - stripRootPc + 12) % 12;
      positions.add(position);
    }
    
    return positions;
  }

  /// Calculate positions for a specific interval from a question root relative to strip root
  /// NEW: Handle interval questions where question root != strip root
  static int calculateIntervalPosition(String questionRoot, String stripRoot, int intervalSemitones) {
    final questionRootPc = Note.fromString(questionRoot).pitchClass;
    final stripRootPc = Note.fromString(stripRoot).pitchClass;
    
    // Calculate the target note's pitch class
    final targetPc = (questionRootPc + intervalSemitones) % 12;
    
    // Calculate position on the strip
    final position = (targetPc - stripRootPc + 12) % 12;
    
    return position;
  }

  /// Generate answer for any scale using the Scale model with proper octave handling
  static ScaleStripAnswer generateScaleAnswer(String scaleName, String rootNote, String stripRoot, {bool includeOctave = true}) {
    final scale = Scale.get(scaleName);
    if (scale == null) {
      throw ArgumentError('Unknown scale: $scaleName');
    }

    final rootNoteObj = Note.fromString(rootNote);
    final scaleNotes = scale.getNotesForRoot(rootNoteObj);
    
    final positions = calculatePositions(scaleNotes, stripRoot);
    
    // Add octave position if requested and not already present
    if (includeOctave && !positions.contains(12)) {
      // Only add octave if the scale root matches the strip root
      if (rootNote == stripRoot) {
        positions.add(12);
      }
    }
    
    final noteNames = scaleNotes.map((n) => n.name).toSet();
    if (includeOctave && rootNote == stripRoot) {
      noteNames.add(rootNote); // Add octave note
    }
    
    return ScaleStripAnswer(
      selectedPositions: positions,
      selectedNotes: noteNames,
    );
  }

  /// Generate answer for any chord using the Chord model
  static ScaleStripAnswer generateChordAnswer(String chordType, String rootNote, String stripRoot, {bool includeOctave = false}) {
    final chord = Chord.get(chordType);
    if (chord == null) {
      throw ArgumentError('Unknown chord: $chordType');
    }

    final rootNoteObj = Note.fromString(rootNote);
    final chordNotes = chord.getNotesForRoot(rootNoteObj);
    
    final positions = calculatePositions(chordNotes, stripRoot);
    
    // Add octave if chord spans more than an octave or if explicitly requested
    if (includeOctave || needsMultipleOctaves(chordType)) {
      // Only add octave if the chord root matches the strip root
      if (rootNote == stripRoot) {
        positions.add(12);
      }
    }
    
    final noteNames = chordNotes.map((n) => n.name).toSet();
    if (includeOctave && rootNote == stripRoot) {
      noteNames.add(rootNote);
    }
    
    return ScaleStripAnswer(
      selectedPositions: positions,
      selectedNotes: noteNames,
    );
  }

  /// Enhanced chromatic scale answer generation with proper enharmonic handling
  static ScaleStripAnswer generateChromaticAnswer(String rootNote, {bool includeOctave = true}) {
    final positions = <int>{};
    final notes = <String>{};
    
    // Generate all 12 chromatic positions
    for (int i = 0; i < 12; i++) {
      positions.add(i);
      notes.add(getPreferredNoteNameForPosition(rootNote, i));
    }
    
    // Add octave position and note
    if (includeOctave) {
      positions.add(12);
      notes.add(rootNote);
    }
    
    return ScaleStripAnswer(
      selectedPositions: positions,
      selectedNotes: notes,
    );
  }

  /// Get the preferred note name for a position based on key context and circle of fifths
  static String getPreferredNoteNameForPosition(String keyContext, int position) {
    final keySignature = MusicUtils.getKeySignature(keyContext);
    final preferFlats = keySignature['flats'] > 0;
    
    final rootPc = _getNotePitchClass(keyContext);
    final targetPc = (rootPc + position) % 12;
    
    return _getNoteNameFromPitchClass(targetPc, preferFlats: preferFlats);
  }

  /// FIXED: Get all available note names for a position (including enharmonic equivalents)
  /// For educational purposes, return only valid enharmonic equivalents for the position
  static List<String> getAllNotesForPosition(String keyContext, int position) {
    final rootPc = _getNotePitchClass(keyContext);
    final targetPc = (rootPc + position) % 12;
    
    // Get all possible note names for this pitch class
    const allNoteNames = [
      ['C'], ['C#', 'Db'], ['D'], ['D#', 'Eb'], ['E'], ['F'],
      ['F#', 'Gb'], ['G'], ['G#', 'Ab'], ['A'], ['A#', 'Bb'], ['B']
    ];
    
    return List<String>.from(allNoteNames[targetPc]);
  }

  /// NEW: Get ALL possible note names for dropdown selection (educational mode)
  /// This returns all note names regardless of position for educational purposes
  static List<String> getAllPossibleNoteNames() {
    return const [
      'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 
      'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B'
    ];
  }

  /// Get missing positions from a complete set (useful for fill-in questions)
  static Set<int> getMissingPositions(Set<int> allPositions, Set<int> givenPositions) {
    return allPositions.difference(givenPositions);
  }

  /// Get natural note positions for chromatic exercises
  /// FIXED: Handle different strip roots properly
  static Set<int> getNaturalNotePositions(String stripRoot) {
    const naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final positions = <int>{};
    final stripRootPc = _getNotePitchClass(stripRoot);
    
    for (final noteName in naturalNotes) {
      final notePc = _getNotePitchClass(noteName);
      final position = (notePc - stripRootPc + 12) % 12;
      positions.add(position);
    }
    
    return positions;
  }

  /// Check if a chord needs multiple octaves
  static bool needsMultipleOctaves(String chordType) {
    final chord = Chord.get(chordType);
    return chord?.intervals.any((interval) => interval > 12) ?? false;
  }

  /// Get enharmonic equivalent of a note
  static String getEnharmonicEquivalent(String noteName) {
    final pitchClass = _getNotePitchClass(noteName);
    final isSharp = noteName.contains('#');
    final isFlat = noteName.contains('b');
    
    if (isSharp) {
      return _getNoteNameFromPitchClass(pitchClass, preferFlats: true);
    } else if (isFlat) {
      return _getNoteNameFromPitchClass(pitchClass, preferFlats: false);
    } else {
      // Natural note, no enharmonic for most cases
      return noteName;
    }
  }

  /// Check if two notes are enharmonically equivalent
  static bool areEnharmonicallyEquivalent(String note1, String note2) {
    return _getNotePitchClass(note1) == _getNotePitchClass(note2);
  }

  /// Get key signature information for context
  static KeySignatureInfo getKeySignatureInfo(String key) {
    final keySignature = MusicUtils.getKeySignature(key);
    final position = MusicUtils.getCircleOfFifthsPosition(key);
    
    return KeySignatureInfo(
      key: key,
      sharps: keySignature['sharps'] as int,
      flats: keySignature['flats'] as int,
      accidentals: List<String>.from(keySignature['accidentals'] as List),
      preferFlats: keySignature['flats'] > 0,
      circlePosition: position,
    );
  }

  /// Generate scale strip configuration for different question types
  /// ENHANCED: Better handling of root note configurations
  static ScaleStripConfiguration createConfiguration({
    required String questionType,
    required String rootNote,
    String? stripRoot, // NEW: Allow different strip root
    bool includeOctave = true,
    bool useDropdowns = false,
    String? keyContext,
  }) {
    // Use stripRoot if provided, otherwise match question root
    final actualStripRoot = stripRoot ?? rootNote;
    
    switch (questionType) {
      case 'octave':
        return ScaleStripConfiguration(
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.intervals,
          rootNote: actualStripRoot,
          includeOctaveNote: true,
          validationMode: ValidationMode.exactPositions,
          highlightRoot: true,
          keyContext: keyContext ?? rootNote,
          fillScreenWidth: true,
        );
        
      case 'chromatic':
        return ScaleStripConfiguration(
          showNoteLabels: false,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.fillInBlanks,
          rootNote: actualStripRoot,
          includeOctaveNote: includeOctave,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          preHighlightedPositions: getNaturalNotePositions(actualStripRoot),
          lockPreHighlighted: true,
          useDropdownSelection: useDropdowns,
          showPreHighlightedLabels: true,
          allowEnharmonicPartialCredit: true,
          keyContext: keyContext ?? rootNote,
          fillScreenWidth: true,
        );
        
      case 'scale':
        return ScaleStripConfiguration(
          showNoteLabels: true,
          allowMultipleSelection: true,
          displayMode: ScaleStripMode.construction,
          rootNote: actualStripRoot,
          includeOctaveNote: includeOctave,
          validationMode: ValidationMode.noteNamesWithEnharmonicCredit,
          highlightRoot: true,
          allowEnharmonicPartialCredit: true,
          keyContext: keyContext ?? rootNote,
          fillScreenWidth: true,
        );
        
      case 'interval':
        return ScaleStripConfiguration(
          showIntervalLabels: true,
          showNoteLabels: true,
          allowMultipleSelection: false,
          displayMode: ScaleStripMode.intervals,
          rootNote: actualStripRoot,
          includeOctaveNote: includeOctave,
          validationMode: ValidationMode.exactPositions,
          highlightRoot: true,
          keyContext: keyContext ?? rootNote,
          fillScreenWidth: true,
        );
        
      default:
        return ScaleStripConfiguration(
          rootNote: actualStripRoot,
          keyContext: keyContext ?? rootNote,
          fillScreenWidth: true,
        );
    }
  }

  /// NEW: Generate interval answer accounting for different question and strip roots
  static ScaleStripAnswer generateIntervalAnswer({
    required String questionRoot,
    required String stripRoot, 
    required int intervalSemitones,
    bool includeOctave = false,
  }) {
    final position = calculateIntervalPosition(questionRoot, stripRoot, intervalSemitones);
    final positions = <int>{position};
    
    // Calculate the target note name
    final questionRootPc = _getNotePitchClass(questionRoot);
    final targetPc = (questionRootPc + intervalSemitones) % 12;
    final targetNote = _getNoteNameFromPitchClass(targetPc);
    
    // Handle octave position for interval = 12
    if (intervalSemitones == 12 && includeOctave) {
      positions.add(12);
    }
    
    return ScaleStripAnswer(
      selectedPositions: positions,
      selectedNotes: {targetNote},
    );
  }

  /// FIXED: Validate user answer against correct answer with enhanced enharmonic support
  static bool validateAnswer(ScaleStripAnswer userAnswer, ScaleStripAnswer correctAnswer, {bool allowEnharmonics = true}) {
    // Check position matching first
    if (userAnswer.selectedPositions == correctAnswer.selectedPositions) {
      return true;
    }
    
    // If allowing enharmonics, check note equivalency
    if (allowEnharmonics) {
      // Convert notes to pitch classes for comparison
      final userPitchClasses = <int>{};
      final correctPitchClasses = <int>{};
      
      for (final note in userAnswer.selectedNotes) {
        try {
          userPitchClasses.add(_getNotePitchClass(note));
        } catch (e) {
          // Skip invalid notes
        }
      }
      
      for (final note in correctAnswer.selectedNotes) {
        try {
          correctPitchClasses.add(_getNotePitchClass(note));
        } catch (e) {
          // Skip invalid notes
        }
      }
      
      return userPitchClasses == correctPitchClasses;
    }
    
    return false;
  }

  // Private helper methods

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

  static String _getNoteNameFromPitchClass(int pitchClass, {bool preferFlats = false}) {
    const sharpNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const flatNames = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
    
    final names = preferFlats ? flatNames : sharpNames;
    return names[pitchClass % 12];
  }
}

/// Key signature information for context
class KeySignatureInfo {
  const KeySignatureInfo({
    required this.key,
    required this.sharps,
    required this.flats,
    required this.accidentals,
    required this.preferFlats,
    required this.circlePosition,
  });

  final String key;
  final int sharps;
  final int flats;
  final List<String> accidentals;
  final bool preferFlats;
  final int circlePosition;

  bool get isSharpKey => sharps > 0;
  bool get isFlatKey => flats > 0;
  bool get isNaturalKey => sharps == 0 && flats == 0;

  @override
  String toString() => 'KeySignatureInfo($key: ${sharps}♯ ${flats}♭)';
}