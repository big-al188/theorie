// lib/models/music/interval.dart
import '../../constants/music_constants.dart';

/// Represents a musical interval
class Interval {
  final int semitones;

  const Interval(this.semitones);

  /// Common interval constructors
  static const Interval unison = Interval(0);
  static const Interval minorSecond = Interval(1);
  static const Interval majorSecond = Interval(2);
  static const Interval minorThird = Interval(3);
  static const Interval majorThird = Interval(4);
  static const Interval perfectFourth = Interval(5);
  static const Interval tritone = Interval(6);
  static const Interval perfectFifth = Interval(7);
  static const Interval minorSixth = Interval(8);
  static const Interval majorSixth = Interval(9);
  static const Interval minorSeventh = Interval(10);
  static const Interval majorSeventh = Interval(11);
  static const Interval octave = Interval(12);

  /// Get the interval name
  String get name {
    final simple = semitones % 12;
    final octaves = semitones ~/ 12;

    if (octaves == 0) {
      return MusicConstants.intervalNames[simple];
    } else if (octaves == 1 && simple == 0) {
      return 'Octave';
    } else {
      // Extended intervals
      final baseName = MusicConstants.intervalNames[simple];
      return '$baseName + ${octaves}oct';
    }
  }

  /// Get the interval label (for display)
  String get label {
    final simple = semitones % 12;
    final octaves = semitones ~/ 12;

    if (octaves == 0) {
      return MusicConstants.intervalLabels[simple];
    } else if (simple == 0) {
      return 'O$octaves'; // Octave marker
    } else {
      // Extended interval notation
      return _getExtendedIntervalLabel(simple, octaves);
    }
  }

  /// Get quality (perfect, major, minor, etc.)
  IntervalQuality get quality {
    final simple = semitones % 12;
    switch (simple) {
      case 0:
      case 5:
      case 7:
        return IntervalQuality.perfect;
      case 2:
      case 4:
      case 9:
      case 11:
        return IntervalQuality.major;
      case 1:
      case 3:
      case 8:
      case 10:
        return IntervalQuality.minor;
      case 6:
        return IntervalQuality.diminished; // or augmented
      default:
        return IntervalQuality.major;
    }
  }

  /// Check if this is a consonant interval
  bool get isConsonant {
    final simple = semitones % 12;
    return const {0, 3, 4, 5, 7, 8, 9, 12}.contains(simple);
  }

  /// Check if this is a perfect interval
  bool get isPerfect {
    final simple = semitones % 12;
    return const {0, 5, 7, 12}.contains(simple);
  }

  /// Invert the interval within an octave
  Interval get inverted {
    final simple = semitones % 12;
    return Interval(12 - simple);
  }

  /// Add two intervals
  Interval operator +(Interval other) => Interval(semitones + other.semitones);

  /// Subtract intervals
  Interval operator -(Interval other) =>
      Interval((semitones - other.semitones).abs());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interval &&
          runtimeType == other.runtimeType &&
          semitones == other.semitones;

  @override
  int get hashCode => semitones.hashCode;

  @override
  String toString() => '$name ($semitones semitones)';

  /// Get extended interval label (9th, 11th, 13th, etc.)
  String _getExtendedIntervalLabel(int simple, int octaves) {
    const baseIntervals = [
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
    final raw = baseIntervals[simple];
    final match = RegExp(r'([♭]?)(\d+)').firstMatch(raw);

    if (match != null) {
      final accidental = match.group(1) ?? '';
      final baseNumber = int.parse(match.group(2)!);
      final extendedNumber = baseNumber + (octaves * 7);
      return '$accidental$extendedNumber';
    }

    return raw;
  }
}

/// Interval quality types
enum IntervalQuality {
  perfect('P'),
  major('M'),
  minor('m'),
  augmented('+'),
  diminished('°');

  const IntervalQuality(this.symbol);
  final String symbol;
}
