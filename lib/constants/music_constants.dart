// lib/constants/music_constants.dart

/// Music theory constants and data
class MusicConstants {
  // Note names
  static const List<String> sharpNoteNames = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B'
  ];

  static const List<String> flatNoteNames = [
    'C',
    'D♭',
    'D',
    'E♭',
    'E',
    'F',
    'G♭',
    'G',
    'A♭',
    'A',
    'B♭',
    'B'
  ];

  // Common root notes for UI display
  static const List<String> commonRoots = [
    'C',
    'G',
    'D',
    'A',
    'E',
    'B',
    'Gb',
    'Db',
    'Ab',
    'Eb',
    'Bb',
    'F'
  ];

  // Roots that typically use flat notation
  static const Set<String> flatRoots = {
    'F',
    'Bb',
    'Eb',
    'Ab',
    'Db',
    'Gb',
    'Cb'
  };

  // Circle of fifths
  static const List<String> circleOfFifths = [
    'C',
    'G',
    'D',
    'A',
    'E',
    'B',
    'F#',
    'C#',
    'F',
    'Bb',
    'Eb',
    'Ab',
    'Db',
    'Gb',
    'Cb'
  ];

  // Interval labels
  static const List<String> intervalLabels = [
    'R',
    '♭2',
    '2',
    '♭3',
    '3',
    '4',
    '♭5',
    '5',
    '♭6',
    '6',
    '♭7',
    '7'
  ];

  // Interval names
  static const List<String> intervalNames = [
    'Unison',
    'Minor 2nd',
    'Major 2nd',
    'Minor 3rd',
    'Major 3rd',
    'Perfect 4th',
    'Tritone',
    'Perfect 5th',
    'Minor 6th',
    'Major 6th',
    'Minor 7th',
    'Major 7th'
  ];

  // Standard tunings
  static const Map<String, List<String>> standardTunings = {
    'Guitar (6-string)': ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
    'Guitar (7-string)': ['B1', 'E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
    'Guitar (8-string)': ['F#1', 'B1', 'E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
    'Bass (4-string)': ['E1', 'A1', 'D2', 'G2'],
    'Bass (5-string)': ['B0', 'E1', 'A1', 'D2', 'G2'],
    'Bass (6-string)': ['B0', 'E1', 'A1', 'D2', 'G2', 'C3'],
    'Ukulele': ['G4', 'C4', 'E4', 'A4'],
    'Mandolin': ['G3', 'D4', 'A4', 'E5'],
    'Banjo (5-string)': ['G4', 'D3', 'G3', 'B3', 'D4'],
    'Drop D': ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
    'Drop C': ['C2', 'G2', 'C3', 'F3', 'A3', 'D4'],
    'Drop B': ['B1', 'F#2', 'B2', 'E3', 'G#3', 'C#4'],
    'Open G': ['D2', 'G2', 'D3', 'G3', 'B3', 'D4'],
    'Open D': ['D2', 'A2', 'D3', 'F#3', 'A3', 'D4'],
    'Open E': ['E2', 'B2', 'E3', 'G#3', 'B3', 'E4'],
    'DADGAD': ['D2', 'A2', 'D3', 'G3', 'A3', 'D4'],
    'Nashville': ['E3', 'A3', 'D4', 'G3', 'B3', 'E4'],
  };

  // Fret marker positions
  static const Set<int> fretMarkers = {3, 5, 7, 9, 12, 15, 17, 19, 21, 24};
  static const Set<int> doubleFretMarkers = {12, 24};

  // MIDI constants
  static const int middleC = 60; // C4 in MIDI
  static const double a440Hz = 440.0;
  static const int a440Midi = 69;

  // Music math constants
  static const double semitoneFactor = 1.059463094359; // 12th root of 2
}
