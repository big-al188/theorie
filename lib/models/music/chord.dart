// lib/models/music/chord.dart
import 'note.dart';
import '../../constants/app_constants.dart';

/// Represents a chord type and structure
class Chord {
  final String type;
  final String symbol;
  final String displayName;
  final List<int> intervals;
  final String category;

  const Chord({
    required this.type,
    required this.symbol,
    required this.displayName,
    required this.intervals,
    required this.category,
  });

  /// Get all chord definitions
  static Map<String, Chord> get all => _chords;

  /// Get chords by category
  static Map<String, List<Chord>> get byCategory {
    final Map<String, List<Chord>> result = {};
    for (final chord in _chords.values) {
      result.putIfAbsent(chord.category, () => []).add(chord);
    }
    return result;
  }

  /// Get common chords for quick access
  static List<Chord> get common => [
        _chords['major']!,
        _chords['minor']!,
        _chords['major7']!,
        _chords['minor7']!,
        _chords['dominant7']!,
        _chords['sus2']!,
        _chords['sus4']!,
        _chords['add9']!,
        _chords['power-chord']!,
      ];

  /// Get a chord by type
  static Chord? get(String type) => _chords[type];

  /// Get chord notes for a given root
  List<Note> getNotesForRoot(Note root) {
    return intervals.map((interval) {
      final pc = (root.pitchClass + interval) % 12;
      final octaveAdjust = interval ~/ 12;
      return Note(
        pitchClass: pc,
        octave: root.octave + octaveAdjust,
        preferFlats: root.preferFlats,
      );
    }).toList();
  }

  /// Get full chord symbol with root
  String getSymbol(String rootName) => '$rootName$symbol';

  /// Get available inversions for this chord
  List<ChordInversion> get availableInversions {
    final count = intervals.length.clamp(1, AppConstants.maxChordInversions);
    return ChordInversion.values.take(count).toList();
  }

  /// Build chord voicing with proper inversion
  /// FIXED: Inversions now build correctly from the specified octave
  List<int> buildVoicing({
    required Note root,
    required ChordInversion inversion,
  }) {
    final rootMidi = root.midi;
    final voicing = <int>[];

    if (inversion == ChordInversion.root) {
      // Root position - build normally from the root
      for (final interval in intervals) {
        voicing.add(rootMidi + interval);
      }
    } else {
      // For inversions, we need to move lower notes up an octave
      final inversionIndex = inversion.index;
      
      if (inversionIndex >= intervals.length) {
        // Fallback to root position if invalid inversion
        for (final interval in intervals) {
          voicing.add(rootMidi + interval);
        }
      } else {
        // Build the inversion by moving the bottom notes up an octave
        // For first inversion: 3rd, 5th, Root+12
        // For second inversion: 5th, Root+12, 3rd+12
        // etc.
        
        // Add the notes that stay in the original octave
        for (int i = inversionIndex; i < intervals.length; i++) {
          voicing.add(rootMidi + intervals[i]);
        }
        
        // Add the notes that move up an octave
        for (int i = 0; i < inversionIndex; i++) {
          voicing.add(rootMidi + intervals[i] + 12);
        }
      }
    }

    return voicing;
  }

  @override
  String toString() => displayName;
}

/// Chord inversion types
enum ChordInversion {
  root('Root Position'),
  first('First Inversion'),
  second('Second Inversion'),
  third('Third Inversion'),
  fourth('Fourth Inversion'),
  fifth('Fifth Inversion');

  const ChordInversion(this.displayName);
  final String displayName;
}

/// Chord definitions - organized by category
final Map<String, Chord> _chords = {
  // Basic Triads
  'major': const Chord(
    type: 'major',
    symbol: '',
    displayName: 'Major',
    intervals: [0, 4, 7],
    category: 'Basic Triads',
  ),
  'minor': const Chord(
    type: 'minor',
    symbol: 'm',
    displayName: 'Minor',
    intervals: [0, 3, 7],
    category: 'Basic Triads',
  ),
  'diminished': const Chord(
    type: 'diminished',
    symbol: '°',
    displayName: 'Diminished',
    intervals: [0, 3, 6],
    category: 'Basic Triads',
  ),
  'augmented': const Chord(
    type: 'augmented',
    symbol: '+',
    displayName: 'Augmented',
    intervals: [0, 4, 8],
    category: 'Basic Triads',
  ),

  // Suspended Chords
  'sus2': const Chord(
    type: 'sus2',
    symbol: 'sus2',
    displayName: 'Suspended 2nd',
    intervals: [0, 2, 7],
    category: 'Suspended',
  ),
  'sus4': const Chord(
    type: 'sus4',
    symbol: 'sus4',
    displayName: 'Suspended 4th',
    intervals: [0, 5, 7],
    category: 'Suspended',
  ),
  '7sus2': const Chord(
    type: '7sus2',
    symbol: '7sus2',
    displayName: '7 Suspended 2nd',
    intervals: [0, 2, 7, 10],
    category: 'Suspended',
  ),
  '7sus4': const Chord(
    type: '7sus4',
    symbol: '7sus4',
    displayName: '7 Suspended 4th',
    intervals: [0, 5, 7, 10],
    category: 'Suspended',
  ),

  // Seventh Chords
  'major7': const Chord(
    type: 'major7',
    symbol: 'maj7',
    displayName: 'Major 7th',
    intervals: [0, 4, 7, 11],
    category: 'Seventh Chords',
  ),
  'minor7': const Chord(
    type: 'minor7',
    symbol: 'm7',
    displayName: 'Minor 7th',
    intervals: [0, 3, 7, 10],
    category: 'Seventh Chords',
  ),
  'dominant7': const Chord(
    type: 'dominant7',
    symbol: '7',
    displayName: 'Dominant 7th',
    intervals: [0, 4, 7, 10],
    category: 'Seventh Chords',
  ),
  'diminished7': const Chord(
    type: 'diminished7',
    symbol: '°7',
    displayName: 'Diminished 7th',
    intervals: [0, 3, 6, 9],
    category: 'Seventh Chords',
  ),
  'half-diminished7': const Chord(
    type: 'half-diminished7',
    symbol: 'ø7',
    displayName: 'Half Diminished 7th',
    intervals: [0, 3, 6, 10],
    category: 'Seventh Chords',
  ),
  'augmented7': const Chord(
    type: 'augmented7',
    symbol: '+7',
    displayName: 'Augmented 7th',
    intervals: [0, 4, 8, 10],
    category: 'Seventh Chords',
  ),
  'augmented-major7': const Chord(
    type: 'augmented-major7',
    symbol: '+maj7',
    displayName: 'Augmented Major 7th',
    intervals: [0, 4, 8, 11],
    category: 'Seventh Chords',
  ),
  'minor-major7': const Chord(
    type: 'minor-major7',
    symbol: 'm(maj7)',
    displayName: 'Minor Major 7th',
    intervals: [0, 3, 7, 11],
    category: 'Seventh Chords',
  ),

  // Sixth Chords
  'major6': const Chord(
    type: 'major6',
    symbol: '6',
    displayName: 'Major 6th',
    intervals: [0, 4, 7, 9],
    category: 'Sixth Chords',
  ),
  'minor6': const Chord(
    type: 'minor6',
    symbol: 'm6',
    displayName: 'Minor 6th',
    intervals: [0, 3, 7, 9],
    category: 'Sixth Chords',
  ),
  '6/9': const Chord(
    type: '6/9',
    symbol: '6/9',
    displayName: '6/9',
    intervals: [0, 4, 7, 9, 14],
    category: 'Sixth Chords',
  ),
  'm6/9': const Chord(
    type: 'm6/9',
    symbol: 'm6/9',
    displayName: 'Minor 6/9',
    intervals: [0, 3, 7, 9, 14],
    category: 'Sixth Chords',
  ),

  // Add Chords
  'add9': const Chord(
    type: 'add9',
    symbol: 'add9',
    displayName: 'Add 9th',
    intervals: [0, 4, 7, 14],
    category: 'Add Chords',
  ),
  'add11': const Chord(
    type: 'add11',
    symbol: 'add11',
    displayName: 'Add 11th',
    intervals: [0, 4, 7, 17],
    category: 'Add Chords',
  ),
  'add13': const Chord(
    type: 'add13',
    symbol: 'add13',
    displayName: 'Add 13th',
    intervals: [0, 4, 7, 21],
    category: 'Add Chords',
  ),
  'madd9': const Chord(
    type: 'madd9',
    symbol: 'm(add9)',
    displayName: 'Minor Add 9th',
    intervals: [0, 3, 7, 14],
    category: 'Add Chords',
  ),
  'madd11': const Chord(
    type: 'madd11',
    symbol: 'm(add11)',
    displayName: 'Minor Add 11th',
    intervals: [0, 3, 7, 17],
    category: 'Add Chords',
  ),
  'add4': const Chord(
    type: 'add4',
    symbol: 'add4',
    displayName: 'Add 4th',
    intervals: [0, 4, 5, 7],
    category: 'Add Chords',
  ),

  // Extended Chords (9ths)
  'major9': const Chord(
    type: 'major9',
    symbol: 'maj9',
    displayName: 'Major 9th',
    intervals: [0, 4, 7, 11, 14],
    category: 'Extended (9ths)',
  ),
  'minor9': const Chord(
    type: 'minor9',
    symbol: 'm9',
    displayName: 'Minor 9th',
    intervals: [0, 3, 7, 10, 14],
    category: 'Extended (9ths)',
  ),
  'dominant9': const Chord(
    type: 'dominant9',
    symbol: '9',
    displayName: 'Dominant 9th',
    intervals: [0, 4, 7, 10, 14],
    category: 'Extended (9ths)',
  ),
  '9sus4': const Chord(
    type: '9sus4',
    symbol: '9sus4',
    displayName: '9 Suspended 4th',
    intervals: [0, 5, 7, 10, 14],
    category: 'Extended (9ths)',
  ),
  '7b9': const Chord(
    type: '7b9',
    symbol: '7♭9',
    displayName: '7 Flat 9',
    intervals: [0, 4, 7, 10, 13],
    category: 'Extended (9ths)',
  ),
  '7#9': const Chord(
    type: '7#9',
    symbol: '7♯9',
    displayName: '7 Sharp 9',
    intervals: [0, 4, 7, 10, 15],
    category: 'Extended (9ths)',
  ),
  'maj7#9': const Chord(
    type: 'maj7#9',
    symbol: 'maj7♯9',
    displayName: 'Major 7 Sharp 9',
    intervals: [0, 4, 7, 11, 15],
    category: 'Extended (9ths)',
  ),

  // Extended Chords (11ths)
  'major11': const Chord(
    type: 'major11',
    symbol: 'maj11',
    displayName: 'Major 11th',
    intervals: [0, 4, 7, 11, 14, 17],
    category: 'Extended (11ths)',
  ),
  'minor11': const Chord(
    type: 'minor11',
    symbol: 'm11',
    displayName: 'Minor 11th',
    intervals: [0, 3, 7, 10, 14, 17],
    category: 'Extended (11ths)',
  ),
  'dominant11': const Chord(
    type: 'dominant11',
    symbol: '11',
    displayName: 'Dominant 11th',
    intervals: [0, 4, 7, 10, 14, 17],
    category: 'Extended (11ths)',
  ),
  '7#11': const Chord(
    type: '7#11',
    symbol: '7♯11',
    displayName: '7 Sharp 11',
    intervals: [0, 4, 7, 10, 18],
    category: 'Extended (11ths)',
  ),
  'maj7#11': const Chord(
    type: 'maj7#11',
    symbol: 'maj7♯11',
    displayName: 'Major 7 Sharp 11',
    intervals: [0, 4, 7, 11, 18],
    category: 'Extended (11ths)',
  ),
  'm7b5add11': const Chord(
    type: 'm7b5add11',
    symbol: 'm7♭5(add11)',
    displayName: 'Minor 7 Flat 5 Add 11',
    intervals: [0, 3, 6, 10, 17],
    category: 'Extended (11ths)',
  ),

  // Extended Chords (13ths)
  'major13': const Chord(
    type: 'major13',
    symbol: 'maj13',
    displayName: 'Major 13th',
    intervals: [0, 4, 7, 11, 14, 17, 21],
    category: 'Extended (13ths)',
  ),
  'minor13': const Chord(
    type: 'minor13',
    symbol: 'm13',
    displayName: 'Minor 13th',
    intervals: [0, 3, 7, 10, 14, 17, 21],
    category: 'Extended (13ths)',
  ),
  'dominant13': const Chord(
    type: 'dominant13',
    symbol: '13',
    displayName: 'Dominant 13th',
    intervals: [0, 4, 7, 10, 14, 17, 21],
    category: 'Extended (13ths)',
  ),
  '7b13': const Chord(
    type: '7b13',
    symbol: '7♭13',
    displayName: '7 Flat 13',
    intervals: [0, 4, 7, 10, 20],
    category: 'Extended (13ths)',
  ),
  '7#13': const Chord(
    type: '7#13',
    symbol: '7♯13',
    displayName: '7 Sharp 13',
    intervals: [0, 4, 7, 10, 22],
    category: 'Extended (13ths)',
  ),

  // Power Chords
  'power-chord': const Chord(
    type: 'power-chord',
    symbol: '5',
    displayName: 'Power Chord (5th)',
    intervals: [0, 7],
    category: 'Power Chords',
  ),
  'power-chord-octave': const Chord(
    type: 'power-chord-octave',
    symbol: '5(8)',
    displayName: 'Power Chord + Octave',
    intervals: [0, 7, 12],
    category: 'Power Chords',
  ),
  'power-sus2': const Chord(
    type: 'power-sus2',
    symbol: 'sus2(no5)',
    displayName: 'Power Sus2',
    intervals: [0, 2],
    category: 'Power Chords',
  ),
  'power-sus4': const Chord(
    type: 'power-sus4',
    symbol: '5sus4',
    displayName: 'Power Sus4',
    intervals: [0, 5, 7],
    category: 'Power Chords',
  ),

  // Altered Chords
  '7alt': const Chord(
    type: '7alt',
    symbol: '7alt',
    displayName: '7 Altered',
    intervals: [0, 4, 7, 10, 13, 15],
    category: 'Altered Chords',
  ),
  '7b5': const Chord(
    type: '7b5',
    symbol: '7♭5',
    displayName: '7 Flat 5',
    intervals: [0, 4, 6, 10],
    category: 'Altered Chords',
  ),
  '7#5': const Chord(
    type: '7#5',
    symbol: '7♯5',
    displayName: '7 Sharp 5',
    intervals: [0, 4, 8, 10],
    category: 'Altered Chords',
  ),
  'maj7b5': const Chord(
    type: 'maj7b5',
    symbol: 'maj7♭5',
    displayName: 'Major 7 Flat 5',
    intervals: [0, 4, 6, 11],
    category: 'Altered Chords',
  ),
  'maj7#5': const Chord(
    type: 'maj7#5',
    symbol: 'maj7♯5',
    displayName: 'Major 7 Sharp 5',
    intervals: [0, 4, 8, 11],
    category: 'Altered Chords',
  ),
  '7b9b13': const Chord(
    type: '7b9b13',
    symbol: '7♭9♭13',
    displayName: '7 Flat 9 Flat 13',
    intervals: [0, 4, 7, 10, 13, 20],
    category: 'Altered Chords',
  ),
  '7#9b13': const Chord(
    type: '7#9b13',
    symbol: '7♯9♭13',
    displayName: '7 Sharp 9 Flat 13',
    intervals: [0, 4, 7, 10, 15, 20],
    category: 'Altered Chords',
  ),

  // Jazz Chords
  'maj7#5#11': const Chord(
    type: 'maj7#5#11',
    symbol: 'maj7♯5♯11',
    displayName: 'Major 7 Sharp 5 Sharp 11',
    intervals: [0, 4, 8, 11, 18],
    category: 'Jazz Chords',
  ),
  'm7b9': const Chord(
    type: 'm7b9',
    symbol: 'm7♭9',
    displayName: 'Minor 7 Flat 9',
    intervals: [0, 3, 7, 10, 13],
    category: 'Jazz Chords',
  ),
  'dim7add9': const Chord(
    type: 'dim7add9',
    symbol: '°7(add9)',
    displayName: 'Diminished 7 Add 9',
    intervals: [0, 3, 6, 9, 14],
    category: 'Jazz Chords',
  ),
  'maj9#11': const Chord(
    type: 'maj9#11',
    symbol: 'maj9♯11',
    displayName: 'Major 9 Sharp 11',
    intervals: [0, 4, 7, 11, 14, 18],
    category: 'Jazz Chords',
  ),
  'm11b5': const Chord(
    type: 'm11b5',
    symbol: 'm11♭5',
    displayName: 'Minor 11 Flat 5',
    intervals: [0, 3, 6, 10, 14, 17],
    category: 'Jazz Chords',
  ),
  '13sus4': const Chord(
    type: '13sus4',
    symbol: '13sus4',
    displayName: '13 Suspended 4th',
    intervals: [0, 5, 7, 10, 14, 17, 21],
    category: 'Jazz Chords',
  ),

  // Quartal Chords
  'quartal3': const Chord(
    type: 'quartal3',
    symbol: 'Q3',
    displayName: 'Quartal Triad',
    intervals: [0, 5, 10],
    category: 'Quartal Chords',
  ),
  'quartal4': const Chord(
    type: 'quartal4',
    symbol: 'Q4',
    displayName: 'Quartal 4-note',
    intervals: [0, 5, 10, 15],
    category: 'Quartal Chords',
  ),
  'quartal5': const Chord(
    type: 'quartal5',
    symbol: 'Q5',
    displayName: 'Quartal 5-note',
    intervals: [0, 5, 10, 15, 20],
    category: 'Quartal Chords',
  ),
  'so-what': const Chord(
    type: 'so-what',
    symbol: 'SW',
    displayName: 'So What Chord',
    intervals: [0, 5, 10, 15, 19],
    category: 'Quartal Chords',
  ),

  // Cluster Chords
  'cluster-maj': const Chord(
    type: 'cluster-maj',
    symbol: 'CMaj',
    displayName: 'Major Cluster',
    intervals: [0, 2, 4],
    category: 'Cluster Chords',
  ),
  'cluster-min': const Chord(
    type: 'cluster-min',
    symbol: 'Cmin',
    displayName: 'Minor Cluster',
    intervals: [0, 1, 3],
    category: 'Cluster Chords',
  ),
  'cluster-chromatic': const Chord(
    type: 'cluster-chromatic',
    symbol: 'CChr',
    displayName: 'Chromatic Cluster',
    intervals: [0, 1, 2],
    category: 'Cluster Chords',
  ),

  // Polychords
  'major-over-major': const Chord(
    type: 'major-over-major',
    symbol: '|Maj',
    displayName: 'Major over Major',
    intervals: [0, 4, 7, 14, 18, 21],
    category: 'Polychords',
  ),
  'minor-over-major': const Chord(
    type: 'minor-over-major',
    symbol: 'm|Maj',
    displayName: 'Minor over Major',
    intervals: [0, 4, 7, 15, 18, 22],
    category: 'Polychords',
  ),

  // Special/Exotic
  'mystic': const Chord(
    type: 'mystic',
    symbol: 'Mys',
    displayName: 'Mystic Chord',
    intervals: [0, 6, 10, 16, 21, 26],
    category: 'Special/Exotic',
  ),
  'elektra': const Chord(
    type: 'elektra',
    symbol: 'Elek',
    displayName: 'Elektra Chord',
    intervals: [0, 7, 9, 13, 16],
    category: 'Special/Exotic',
  ),
  'dream': const Chord(
    type: 'dream',
    symbol: 'Dream',
    displayName: 'Dream Chord',
    intervals: [0, 5, 6, 7],
    category: 'Special/Exotic',
  ),
  'farben': const Chord(
    type: 'farben',
    symbol: 'Farb',
    displayName: 'Farben Chord',
    intervals: [0, 8, 11, 16, 21],
    category: 'Special/Exotic',
  ),
  'tristan': const Chord(
    type: 'tristan',
    symbol: 'Trist',
    displayName: 'Tristan Chord',
    intervals: [0, 3, 6, 10],
    category: 'Special/Exotic',
  ),
  'petrushka': const Chord(
    type: 'petrushka',
    symbol: 'Petr',
    displayName: 'Petrushka Chord',
    intervals: [0, 1, 4, 6, 7, 10],
    category: 'Special/Exotic',
  ),
  'viennese-trichord': const Chord(
    type: 'viennese-trichord',
    symbol: 'VT',
    displayName: 'Viennese Trichord',
    intervals: [0, 1, 6],
    category: 'Special/Exotic',
  ),

  // Omit Chords
  'major-no3': const Chord(
    type: 'major-no3',
    symbol: '(no3)',
    displayName: 'Major (no 3rd)',
    intervals: [0, 7],
    category: 'Omit Chords',
  ),
  'major7-no3': const Chord(
    type: 'major7-no3',
    symbol: 'maj7(no3)',
    displayName: 'Major 7 (no 3rd)',
    intervals: [0, 7, 11],
    category: 'Omit Chords',
  ),
  'major7-no5': const Chord(
    type: 'major7-no5',
    symbol: 'maj7(no5)',
    displayName: 'Major 7 (no 5th)',
    intervals: [0, 4, 11],
    category: 'Omit Chords',
  ),
  '7-no3': const Chord(
    type: '7-no3',
    symbol: '7(no3)',
    displayName: '7 (no 3rd)',
    intervals: [0, 7, 10],
    category: 'Omit Chords',
  ),
  '9-no3': const Chord(
    type: '9-no3',
    symbol: '9(no3)',
    displayName: '9 (no 3rd)',
    intervals: [0, 7, 10, 14],
    category: 'Omit Chords',
  ),
  '11-no5': const Chord(
    type: '11-no5',
    symbol: '11(no5)',
    displayName: '11 (no 5th)',
    intervals: [0, 4, 10, 14, 17],
    category: 'Omit Chords',
  ),

  // Slash Chords (common bass note variations)
  'major-b3-bass': const Chord(
    type: 'major-b3-bass',
    symbol: '/♭3',
    displayName: 'Major/♭3 Bass',
    intervals: [0, 3, 4, 7],
    category: 'Slash Chords',
  ),
  'major-5-bass': const Chord(
    type: 'major-5-bass',
    symbol: '/5',
    displayName: 'Major/5 Bass',
    intervals: [0, 4, 7, 7],
    category: 'Slash Chords',
  ),
  'minor-b7-bass': const Chord(
    type: 'minor-b7-bass',
    symbol: 'm/♭7',
    displayName: 'Minor/♭7 Bass',
    intervals: [0, 3, 7, 10],
    category: 'Slash Chords',
  ),
};