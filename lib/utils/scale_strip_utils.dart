// lib/utils/scale_strip_utils.dart

/// Utility functions for scale strip question handling
/// Provides note name resolution, octave calculations, and interval labeling
class ScaleStripUtils {
  
  /// Standard chromatic scale starting from C
  static const List<String> chromaticNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  /// Mapping from flat notes to sharp equivalents
  static const Map<String, String> flatToSharp = {
    'Db': 'C#',
    'Eb': 'D#', 
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  /// Scale degree labels with accidentals for interval display
  static const List<String> scaleDegreeLabels = [
    '1', '♭2', '2', '♭3', '3', '4', '♭5', '5', '♭6', '6', '♭7', '7'
  ];

  /// Roman numeral labels for advanced theory
  static const List<String> romanNumeralLabels = [
    'I', '♭II', 'II', '♭III', 'III', 'IV', '♭V', 'V', '♭VI', 'VI', '♭VII', 'VII'
  ];

  /// Get note name for a chromatic position relative to a root note
  /// 
  /// [chromaticPosition] - Position 0-11 in chromatic scale
  /// [rootNote] - Root note (e.g., 'C', 'D', 'F#', 'Bb')
  /// Returns the note name at that position
  static String getNoteNameForPosition(int chromaticPosition, String rootNote) {
    // Normalize root note to sharp if it's a flat
    final normalizedRoot = flatToSharp[rootNote] ?? rootNote;
    
    // Find root position in chromatic scale
    int rootIndex = chromaticNotes.indexOf(normalizedRoot);
    if (rootIndex == -1) {
      throw ArgumentError('Invalid root note: $rootNote');
    }
    
    // Calculate note index
    final noteIndex = (chromaticPosition + rootIndex) % 12;
    return chromaticNotes[noteIndex];
  }

  /// Get note name with octave for a position in multi-octave scale strip
  /// 
  /// [position] - Absolute position in scale strip (0-based)
  /// [rootNote] - Root note of the scale
  /// [startingOctave] - Starting octave number (default: 3)
  /// Returns note name with octave (e.g., 'C4', 'F#5')
  static String getNoteNameWithOctave(int position, String rootNote, {int startingOctave = 3}) {
    final octave = startingOctave + (position ~/ 12);
    final chromaticPosition = position % 12;
    final noteName = getNoteNameForPosition(chromaticPosition, rootNote);
    return '$noteName$octave';
  }

  /// Extract note name without octave from a note string
  /// 
  /// [noteWithOctave] - Note string like 'C4' or 'F#5'
  /// Returns just the note name like 'C' or 'F#'
  static String extractNoteName(String noteWithOctave) {
    return noteWithOctave.replaceAll(RegExp(r'\d+$'), '');
  }

  /// Extract octave number from a note string
  /// 
  /// [noteWithOctave] - Note string like 'C4' or 'F#5'
  /// Returns the octave number, or null if not present
  static int? extractOctave(String noteWithOctave) {
    final match = RegExp(r'\d+$').firstMatch(noteWithOctave);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  /// Check if a note string contains octave information
  /// 
  /// [note] - Note string to check
  /// Returns true if octave is present
  static bool hasOctaveInfo(String note) {
    return RegExp(r'\d+$').hasMatch(note);
  }

  /// Convert a set of notes with octaves to notes without octaves
  /// 
  /// [notesWithOctaves] - Set of notes like {'C4', 'E4', 'G4'}
  /// Returns set of notes without octaves like {'C', 'E', 'G'}
  static Set<String> removeOctaveInfo(Set<String> notesWithOctaves) {
    return notesWithOctaves.map(extractNoteName).toSet();
  }

  /// Get interval label for a chromatic position
  /// 
  /// [position] - Chromatic position (0-11)
  /// [format] - Label format to use
  /// Returns formatted interval label
  static String getIntervalLabel(int position, IntervalLabelFormat format) {
    final chromaticPos = position % 12;
    
    switch (format) {
      case IntervalLabelFormat.numeric:
        return (chromaticPos + 1).toString();
      
      case IntervalLabelFormat.scaleDegreesWithAccidentals:
        return scaleDegreeLabels[chromaticPos];
      
      case IntervalLabelFormat.romanNumerals:
        return romanNumeralLabels[chromaticPos];
    }
  }

  /// Calculate positions for a major scale starting from a root note
  /// 
  /// [rootNote] - Root note of the scale
  /// [octaveCount] - Number of octaves to include
  /// Returns set of positions for the major scale
  static Set<int> getMajorScalePositions(String rootNote, {int octaveCount = 1}) {
    const majorScaleIntervals = [0, 2, 4, 5, 7, 9, 11]; // W-W-H-W-W-W-H
    final positions = <int>{};
    
    for (int octave = 0; octave < octaveCount; octave++) {
      for (final interval in majorScaleIntervals) {
        positions.add(octave * 12 + interval);
      }
    }
    
    // Add octave note
    positions.add(octaveCount * 12);
    
    return positions;
  }

  /// Calculate positions for a natural minor scale starting from a root note
  /// 
  /// [rootNote] - Root note of the scale
  /// [octaveCount] - Number of octaves to include  
  /// Returns set of positions for the natural minor scale
  static Set<int> getNaturalMinorScalePositions(String rootNote, {int octaveCount = 1}) {
    const minorScaleIntervals = [0, 2, 3, 5, 7, 8, 10]; // W-H-W-W-H-W-W
    final positions = <int>{};
    
    for (int octave = 0; octave < octaveCount; octave++) {
      for (final interval in minorScaleIntervals) {
        positions.add(octave * 12 + interval);
      }
    }
    
    // Add octave note
    positions.add(octaveCount * 12);
    
    return positions;
  }

  /// Calculate positions for a major triad
  /// 
  /// [rootNote] - Root note of the triad
  /// [octave] - Starting octave
  /// Returns set of positions for the major triad
  static Set<int> getMajorTriadPositions(String rootNote, {int octave = 0}) {
    const triadIntervals = [0, 4, 7]; // Root, major third, perfect fifth
    return triadIntervals.map((interval) => octave * 12 + interval).toSet();
  }

  /// Calculate positions for a diminished triad
  /// 
  /// [rootNote] - Root note of the triad
  /// [octave] - Starting octave
  /// Returns set of positions for the diminished triad
  static Set<int> getDiminishedTriadPositions(String rootNote, {int octave = 0}) {
    const triadIntervals = [0, 3, 6]; // Root, minor third, diminished fifth
    return triadIntervals.map((interval) => octave * 12 + interval).toSet();
  }

  /// Calculate positions for a pentatonic scale
  /// 
  /// [rootNote] - Root note of the scale
  /// [isMinor] - Whether to use minor pentatonic (default: false for major)
  /// [octaveCount] - Number of octaves to include
  /// Returns set of positions for the pentatonic scale
  static Set<int> getPentatonicScalePositions(
    String rootNote, {
    bool isMinor = false,
    int octaveCount = 1,
  }) {
    final intervals = isMinor 
        ? [0, 3, 5, 7, 10] // Minor pentatonic: 1, ♭3, 4, 5, ♭7
        : [0, 2, 4, 7, 9];  // Major pentatonic: 1, 2, 3, 5, 6
    
    final positions = <int>{};
    
    for (int octave = 0; octave < octaveCount; octave++) {
      for (final interval in intervals) {
        positions.add(octave * 12 + interval);
      }
    }
    
    return positions;
  }

  /// Calculate chromatic scale positions
  /// 
  /// [octaveCount] - Number of octaves to include
  /// Returns set of all chromatic positions
  static Set<int> getChromaticScalePositions({int octaveCount = 1}) {
    final positions = <int>{};
    
    for (int octave = 0; octave < octaveCount; octave++) {
      for (int i = 0; i < 12; i++) {
        positions.add(octave * 12 + i);
      }
    }
    
    // Add octave note
    positions.add(octaveCount * 12);
    
    return positions;
  }

  /// Validate if user selections match expected positions with partial credit
  /// 
  /// [userPositions] - Positions selected by user
  /// [correctPositions] - Expected correct positions
  /// [allowOctaveVariation] - Whether to allow same notes in different octaves
  /// Returns validation result with score and feedback
  static ValidationResult validatePositions(
    Set<int> userPositions,
    Set<int> correctPositions, {
    bool allowOctaveVariation = false,
  }) {
    if (allowOctaveVariation) {
      // Reduce to chromatic positions only (ignore octaves)
      final userChromatic = userPositions.map((pos) => pos % 12).toSet();
      final correctChromatic = correctPositions.map((pos) => pos % 12).toSet();
      
      final intersection = userChromatic.intersection(correctChromatic);
      final score = intersection.length / correctChromatic.length;
      
      return ValidationResult(
        score: score,
        isCorrect: score >= 0.7,
        feedback: _generatePositionFeedback(score, allowOctaveVariation),
      );
    } else {
      // Exact position matching
      final intersection = userPositions.intersection(correctPositions);
      final score = intersection.length / correctPositions.length;
      
      return ValidationResult(
        score: score,
        isCorrect: score >= 0.7,
        feedback: _generatePositionFeedback(score, false),
      );
    }
  }

  /// Generate feedback message based on validation score
  static String _generatePositionFeedback(double score, bool allowedOctaveVariation) {
    if (score == 1.0) {
      return 'Perfect! All positions are correct.';
    } else if (score >= 0.8) {
      return 'Excellent! Most positions are correct.';
    } else if (score >= 0.6) {
      return allowedOctaveVariation 
          ? 'Good! Correct notes, consider the octave placement.'
          : 'Good progress! Check a few more positions.';
    } else if (score >= 0.3) {
      return 'Some positions are correct. Review the pattern.';
    } else {
      return 'Review the scale pattern and try again.';
    }
  }
}

/// Result of position validation
class ValidationResult {
  const ValidationResult({
    required this.score,
    required this.isCorrect,
    required this.feedback,
    this.detailedErrors = const [],
  });

  /// Score from 0.0 to 1.0
  final double score;
  
  /// Whether the answer is considered correct
  final bool isCorrect;
  
  /// Feedback message
  final String feedback;
  
  /// Detailed error information
  final List<String> detailedErrors;
}

/// Import the required enum if not already imported
/// This should be imported from the scale_strip_question.dart file
enum IntervalLabelFormat {
  numeric,
  scaleDegreesWithAccidentals,
  romanNumerals,
}