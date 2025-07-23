// lib/utils/scale_strip_utils.dart

import '../models/music/note.dart';
import '../models/music/scale.dart';
import '../models/music/chord.dart';
import '../models/quiz/scale_strip_question.dart';

/// Simplified utility functions for scale strip quiz integration with music theory models
class ScaleStripUtils {
  
  /// Calculate positions on the strip from notes relative to a root
  static Set<int> calculatePositions(List<Note> notes, String stripRoot) {
    final stripRootPc = Note.fromString(stripRoot).pitchClass;
    final positions = <int>{};
    
    for (final note in notes) {
      final position = (note.pitchClass - stripRootPc + 12) % 12;
      positions.add(position);
    }
    
    return positions;
  }

  /// Generate answer for any scale using the Scale model
  static ScaleStripAnswer generateScaleAnswer(String scaleName, String rootNote, String stripRoot) {
    final scale = Scale.get(scaleName);
    if (scale == null) {
      throw ArgumentError('Unknown scale: $scaleName');
    }

    final rootNoteObj = Note.fromString(rootNote);
    final scaleNotes = scale.getNotesForRoot(rootNoteObj);
    
    return ScaleStripAnswer(
      selectedPositions: calculatePositions(scaleNotes, stripRoot),
      selectedNotes: scaleNotes.map((n) => n.name).toSet(),
    );
  }

  /// Generate answer for any chord using the Chord model
  static ScaleStripAnswer generateChordAnswer(String chordType, String rootNote, String stripRoot) {
    final chord = Chord.get(chordType);
    if (chord == null) {
      throw ArgumentError('Unknown chord: $chordType');
    }

    final rootNoteObj = Note.fromString(rootNote);
    final chordNotes = chord.getNotesForRoot(rootNoteObj);
    
    return ScaleStripAnswer(
      selectedPositions: calculatePositions(chordNotes, stripRoot),
      selectedNotes: chordNotes.map((n) => n.name).toSet(),
    );
  }

  /// Get missing positions from a complete set (useful for fill-in questions)
  static Set<int> getMissingPositions(Set<int> allPositions, Set<int> givenPositions) {
    return allPositions.difference(givenPositions);
  }

  /// Get natural note positions for chromatic exercises
  static Set<int> getNaturalNotePositions(String stripRoot) {
    const naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final positions = <int>{};
    final stripRootPc = Note.fromString(stripRoot).pitchClass;
    
    for (final noteName in naturalNotes) {
      final notePc = Note.fromString(noteName).pitchClass;
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

  /// Get all scales organized by difficulty
  static Map<String, List<String>> getScalesByDifficulty() {
    final allScales = Scale.all;
    
    return {
      'Beginner': [
        'Major',
        'Natural Minor',
        'Major Pentatonic',
        'Minor Pentatonic',
      ].where((name) => allScales.containsKey(name)).toList(),
      
      'Intermediate': [
        'Blues',
        'Dorian',
        'Mixolydian',
        'Harmonic Minor',
      ].where((name) => allScales.containsKey(name)).toList(),
      
      'Advanced': [
        'Melodic Minor',
        'Lydian',
        'Phrygian',
        'Locrian',
        'Altered',
        'Whole Tone',
        'Diminished',
      ].where((name) => allScales.containsKey(name)).toList(),
    };
  }

  /// Get all chords organized by difficulty
  static Map<String, List<String>> getChordsByDifficulty() {
    final allChords = Chord.all;
    
    return {
      'Beginner': [
        'major',
        'minor',
        'diminished',
        'augmented',
      ].where((type) => allChords.containsKey(type)).toList(),
      
      'Intermediate': [
        'sus2',
        'sus4',
        'major7',
        'minor7',
        'dominant7',
        'major6',
        'minor6',
        'add9',
      ].where((type) => allChords.containsKey(type)).toList(),
      
      'Advanced': [
        'major9',
        'minor9',
        'dominant9',
        'major11',
        'minor11',
        'dominant11',
        'major13',
        'minor13',
        'dominant13',
        '7alt',
        'diminished7',
        'half-diminished7',
      ].where((type) => allChords.containsKey(type)).toList(),
    };
  }

  /// Generate pre-highlighted positions for partial scales
  static Set<int> generatePreHighlightedPositions(
    String scaleName, 
    String rootNote, 
    List<int> degrees  // 1-based scale degrees to highlight
  ) {
    final scale = Scale.get(scaleName);
    if (scale == null) return {};
    
    final positions = <int>{};
    final rootPc = Note.fromString(rootNote).pitchClass;
    
    for (final degree in degrees) {
      if (degree > 0 && degree <= scale.intervals.length) {
        final interval = scale.intervals[degree - 1]; // Convert to 0-based
        final position = (rootPc + interval) % 12;
        positions.add(position);
      }
    }
    
    return positions;
  }

  /// Generate note names for specific scale degrees
  static Set<String> generateNoteNamesForDegrees(
    String scaleName,
    String rootNote,
    List<int> degrees,
  ) {
    final scale = Scale.get(scaleName);
    if (scale == null) return {};

    final rootNoteObj = Note.fromString(rootNote);
    final noteNames = <String>{};
    
    for (final degree in degrees) {
      if (degree > 0 && degree <= scale.intervals.length) {
        final interval = scale.intervals[degree - 1];
        final note = rootNoteObj.transpose(interval);
        noteNames.add(note.name);
      }
    }
    
    return noteNames;
  }

  /// Get common root notes for exercises
  static List<String> getCommonRoots() {
    return ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  }

  /// Get sharp/flat roots
  static List<String> getAccidentalRoots() {
    return ['C#', 'D#', 'F#', 'G#', 'A#', 'Db', 'Eb', 'Gb', 'Ab', 'Bb'];
  }

  /// Validate that notes form a valid scale
  static bool validateScale(Set<String> noteNames, String scaleName, String rootNote) {
    final expectedAnswer = generateScaleAnswer(scaleName, rootNote, rootNote);
    return expectedAnswer.selectedNotes.difference(noteNames).isEmpty &&
           noteNames.difference(expectedAnswer.selectedNotes).isEmpty;
  }

  /// Validate that notes form a valid chord
  static bool validateChord(Set<String> noteNames, String chordType, String rootNote) {
    final expectedAnswer = generateChordAnswer(chordType, rootNote, rootNote);
    return expectedAnswer.selectedNotes.difference(noteNames).isEmpty &&
           noteNames.difference(expectedAnswer.selectedNotes).isEmpty;
  }

  /// Get interval patterns for scales
  static List<String> getScalePattern(String scaleName) {
    final scale = Scale.get(scaleName);
    if (scale == null) return [];
    
    final pattern = <String>[];
    for (int i = 1; i < scale.intervals.length; i++) {
      final diff = scale.intervals[i] - scale.intervals[i - 1];
      pattern.add(diff == 1 ? 'H' : 'W'); // Half or Whole step
    }
    return pattern;
  }

  /// Get chord quality description
  static String getChordQuality(String chordType) {
    final chord = Chord.get(chordType);
    if (chord == null) return 'Unknown';
    
    if (chord.intervals.length == 2) {
      return 'Power chord';
    } else if (chord.intervals.length == 3) {
      return 'Triad';
    } else if (chord.intervals.contains(10) || chord.intervals.contains(11)) {
      return 'Seventh chord';
    } else if (chord.intervals.any((i) => i >= 14)) {
      return 'Extended chord';
    }
    
    return chord.category;
  }

  /// Get available modes for a scale
  static List<String> getAvailableModes(String scaleName) {
    final scale = Scale.get(scaleName);
    if (scale == null) return [];
    
    if (scale.modeNames != null) {
      return scale.modeNames!;
    }
    
    return List.generate(scale.length, (i) => 'Mode ${i + 1}');
  }

  /// Generate explanation text for scales
  static String generateScaleExplanation(String scaleName, String rootNote) {
    final scale = Scale.get(scaleName);
    if (scale == null) return 'Unknown scale';
    
    final pattern = getScalePattern(scaleName);
    final patternText = pattern.isNotEmpty ? ' (${pattern.join('-')})' : '';
    
    return 'The $rootNote ${scale.name.toLowerCase()} scale follows the pattern$patternText. '
           'This scale contains ${scale.length} notes with the degrees: ${scale.degrees.join('-')}.';
  }

  /// Generate explanation text for chords
  static String generateChordExplanation(String chordType, String rootNote) {
    final chord = Chord.get(chordType);
    if (chord == null) return 'Unknown chord';
    
    final quality = getChordQuality(chordType);
    final intervals = chord.intervals.map((i) => '$i semitones').join(', ');
    
    return 'The $rootNote ${chord.displayName.toLowerCase()} is a $quality. '
           'It uses intervals of $intervals from the root note.';
  }

  /// Get random selection of items from a list
  static List<T> getRandomSelection<T>(List<T> items, int count) {
    if (items.length <= count) return List.from(items);
    
    final shuffled = List<T>.from(items)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Debug helper to verify music theory calculations
  static void debugMusicTheory(String scaleName, String chordType, String rootNote) {
    print('=== Music Theory Debug ===');
    
    if (scaleName.isNotEmpty) {
      final scale = Scale.get(scaleName);
      if (scale != null) {
        final scaleAnswer = generateScaleAnswer(scaleName, rootNote, rootNote);
        print('$rootNote $scaleName:');
        print('  Intervals: ${scale.intervals}');
        print('  Notes: ${scaleAnswer.selectedNotes.join('-')}');
        print('  Positions: ${scaleAnswer.selectedPositions}');
      }
    }
    
    if (chordType.isNotEmpty) {
      final chord = Chord.get(chordType);
      if (chord != null) {
        final chordAnswer = generateChordAnswer(chordType, rootNote, rootNote);
        print('$rootNote $chordType:');
        print('  Intervals: ${chord.intervals}');
        print('  Notes: ${chordAnswer.selectedNotes.join('-')}');
        print('  Positions: ${chordAnswer.selectedPositions}');
        print('  Octaves needed: ${needsMultipleOctaves(chordType) ? 2 : 1}');
      }
    }
  }
}