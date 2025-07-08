// lib/models/music/scale.dart
import 'note.dart';

/// Represents a musical scale
class Scale {
  final String name;
  final List<int> intervals; // Semitone intervals from root
  final List<String>? modeNames;

  const Scale({
    required this.name,
    required this.intervals,
    this.modeNames,
  });

  /// Get all scale definitions
  static Map<String, Scale> get all => _scales;

  /// Get a scale by name
  static Scale? get(String name) => _scales[name];

  /// Common scale accessors
  static Scale get major => _scales['Major']!;
  static Scale get naturalMinor => _scales['Natural Minor']!;
  static Scale get harmonicMinor => _scales['Harmonic Minor']!;
  static Scale get melodicMinor => _scales['Melodic Minor']!;
  static Scale get majorPentatonic => _scales['Major Pentatonic']!;
  static Scale get minorPentatonic => _scales['Minor Pentatonic']!;
  static Scale get blues => _scales['Blues']!;
  static Scale get chromatic => _scales['Chromatic']!;

  /// Get the number of notes in the scale
  int get length => intervals.length;

  /// Check if a pitch class is in the scale (relative to root)
  bool containsPitchClass(int rootPc, int pitchClass) {
    final interval = (pitchClass - rootPc + 12) % 12;
    return intervals.contains(interval);
  }

  /// Get all notes in the scale for a given root
  List<Note> getNotesForRoot(Note root) {
    return intervals.map((interval) {
      final pc = (root.pitchClass + interval) % 12;
      final octaveAdjust = (root.pitchClass + interval) ~/ 12;
      return Note(
        pitchClass: pc,
        octave: root.octave + octaveAdjust,
        preferFlats: root.preferFlats,
      );
    }).toList();
  }

  /// Get pitch classes for a mode of this scale
  List<int> getModeIntervals(int modeIndex) {
    if (modeIndex == 0) return intervals;

    final mode = modeIndex % length;
    final offset = intervals[mode];

    return List.generate(length, (i) {
      final interval = (intervals[(i + mode) % length] - offset + 12) % 12;
      return interval;
    })
      ..sort();
  }

  /// Get the mode name
  String getModeName(int modeIndex) {
    if (modeNames != null && modeIndex < modeNames!.length) {
      return modeNames![modeIndex];
    }
    return 'Mode ${modeIndex + 1}';
  }

  /// Get root note for a specific mode
  Note getModeRoot(Note baseRoot, int modeIndex) {
    final offset = intervals[modeIndex % length];
    return baseRoot.transpose(offset);
  }

  /// Get scale degrees as interval names
  List<String> get degrees {
    const degreeNames = [
      '1',
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
    return intervals.map((interval) => degreeNames[interval]).toList();
  }

  @override
  String toString() => name;
}

/// Scale definitions
final Map<String, Scale> _scales = {
  // Common scales
  'Chromatic': const Scale(
    name: 'Chromatic',
    intervals: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  ),
  'Major': const Scale(
    name: 'Major',
    intervals: [0, 2, 4, 5, 7, 9, 11],
    modeNames: [
      'Ionian',
      'Dorian',
      'Phrygian',
      'Lydian',
      'Mixolydian',
      'Aeolian',
      'Locrian'
    ],
  ),
  'Natural Minor': const Scale(
    name: 'Natural Minor',
    intervals: [0, 2, 3, 5, 7, 8, 10],
    modeNames: [
      'Natural Minor',
      'Locrian',
      'Ionian',
      'Dorian',
      'Phrygian',
      'Lydian',
      'Mixolydian'
    ],
  ),
  'Harmonic Minor': const Scale(
    name: 'Harmonic Minor',
    intervals: [0, 2, 3, 5, 7, 8, 11],
    modeNames: [
      'Harmonic Minor',
      'Locrian ♯6',
      'Ionian ♯5',
      'Dorian ♯4',
      'Phrygian Dominant',
      'Lydian ♯9',
      'Altered Dominant'
    ],
  ),
  'Melodic Minor': const Scale(
    name: 'Melodic Minor',
    intervals: [0, 2, 3, 5, 7, 9, 11],
    modeNames: [
      'Melodic Minor',
      'Dorian ♭2',
      'Lydian Augmented',
      'Lydian Dominant',
      'Mixolydian ♭6',
      'Locrian ♯2',
      'Altered'
    ],
  ),

  // Pentatonic scales
  'Major Pentatonic': const Scale(
    name: 'Major Pentatonic',
    intervals: [0, 2, 4, 7, 9],
  ),
  'Minor Pentatonic': const Scale(
    name: 'Minor Pentatonic',
    intervals: [0, 3, 5, 7, 10],
  ),
  'Blues': const Scale(
    name: 'Blues',
    intervals: [0, 3, 5, 6, 7, 10],
  ),

  // Church modes (individual)
  'Dorian': const Scale(name: 'Dorian', intervals: [0, 2, 3, 5, 7, 9, 10]),
  'Phrygian': const Scale(name: 'Phrygian', intervals: [0, 1, 3, 5, 7, 8, 10]),
  'Lydian': const Scale(name: 'Lydian', intervals: [0, 2, 4, 6, 7, 9, 11]),
  'Mixolydian':
      const Scale(name: 'Mixolydian', intervals: [0, 2, 4, 5, 7, 9, 10]),
  'Aeolian': const Scale(name: 'Aeolian', intervals: [0, 2, 3, 5, 7, 8, 10]),
  'Locrian': const Scale(name: 'Locrian', intervals: [0, 1, 3, 5, 6, 8, 10]),

  // Jazz scales
  'Bebop Dominant': const Scale(
    name: 'Bebop Dominant',
    intervals: [0, 2, 4, 5, 7, 9, 10, 11],
  ),
  'Bebop Major': const Scale(
    name: 'Bebop Major',
    intervals: [0, 2, 4, 5, 7, 8, 9, 11],
  ),
  'Altered': const Scale(
    name: 'Altered',
    intervals: [0, 1, 3, 4, 6, 8, 10],
  ),
  'Whole Tone': const Scale(
    name: 'Whole Tone',
    intervals: [0, 2, 4, 6, 8, 10],
  ),
  'Diminished': const Scale(
    name: 'Diminished',
    intervals: [0, 2, 3, 5, 6, 8, 9, 11],
  ),

  // Ethnic scales
  'Hungarian Minor': const Scale(
    name: 'Hungarian Minor',
    intervals: [0, 2, 3, 6, 7, 8, 11],
  ),
  'Japanese': const Scale(
    name: 'Japanese',
    intervals: [0, 1, 5, 7, 8],
  ),
  'Arabic': const Scale(
    name: 'Arabic',
    intervals: [0, 1, 4, 5, 7, 8, 11],
  ),
  'Gypsy': const Scale(
    name: 'Gypsy',
    intervals: [0, 1, 4, 5, 7, 8, 10],
  ),

  // Exotic scales
  'Enigmatic': const Scale(
    name: 'Enigmatic',
    intervals: [0, 1, 4, 6, 8, 10, 11],
  ),
  'Double Harmonic': const Scale(
    name: 'Double Harmonic',
    intervals: [0, 1, 4, 5, 7, 8, 11],
  ),
  'Neapolitan Major': const Scale(
    name: 'Neapolitan Major',
    intervals: [0, 1, 3, 5, 7, 9, 11],
  ),
  'Neapolitan Minor': const Scale(
    name: 'Neapolitan Minor',
    intervals: [0, 1, 3, 5, 7, 8, 11],
  ),
};
