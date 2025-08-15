// lib/constants/keyboard_constants.dart

/// Keyboard/Piano constants and data
class KeyboardConstants {
  // Standard keyboard types and their key counts
  static const Map<String, int> keyboardTypes = {
    'Micro Keyboard': 25,
    'Keyboard': 61,
    'Piano': 88,
  };

  // Default keyboard configurations
  static const Map<String, Map<String, dynamic>> defaultConfigurations = {
    'Micro Keyboard': {
      'keyCount': 25,
      'startNote': 'C3', // Two octaves starting from C3
      'description': 'Compact 25-key keyboard perfect for basic exercises',
    },
    'Keyboard': {
      'keyCount': 61,
      'startNote': 'C2', // Five octaves starting from C2
      'description': 'Standard 61-key keyboard with full range',
    },
    'Piano': {
      'keyCount': 88,
      'startNote': 'A0', // Full piano range from A0 to C8
      'description': 'Full 88-key piano with complete range',
    },
  };

  // Piano key pattern (C major scale pattern in one octave)
  // true = white key, false = black key
  static const List<bool> keyPattern = [
    true,  // C
    false, // C#
    true,  // D
    false, // D#
    true,  // E
    true,  // F
    false, // F#
    true,  // G
    false, // G#
    true,  // A
    false, // A#
    true,  // B
  ];

  // White key positions in an octave (0-6 for C, D, E, F, G, A, B)
  static const List<int> whiteKeyIndices = [0, 2, 4, 5, 7, 9, 11];
  
  // Black key positions in an octave
  static const List<int> blackKeyIndices = [1, 3, 6, 8, 10];

  // Black key visual positioning relative to white keys
  // Maps black key semitone to its visual position between white keys
  // Proper piano layout with correct black key grouping
  static const Map<int, double> blackKeyPositions = {
    1: 0.65,  // C# - 65% between C and D (first group)
    3: 1.35,  // D# - 35% between D and E (first group)
    6: 3.65,  // F# - 65% between F and G (second group)
    8: 4.25,  // G# - 25% between G and A (second group, closer to G)
    10: 4.9,  // A# - 90% between A and B (second group, closer to A)
  };

  // Key dimensions ratios (for responsive design)
  static const double whiteKeyWidthRatio = 1.0;
  static const double whiteKeyHeightRatio = 6.0;
  static const double blackKeyWidthRatio = 0.6;
  static const double blackKeyHeightRatio = 4.0;

  // Default keyboard settings
  static const int defaultKeyCount = 61;
  static const String defaultStartNote = 'C2';
  static const String defaultKeyboardType = 'Keyboard';

  // Minimum and maximum key counts
  static const int minKeys = 12; // One octave minimum
  static const int maxKeys = 88; // Full piano maximum

  // Common start notes for different ranges
  static const List<String> commonStartNotes = [
    'A0', 'C1', 'C2', 'C3', 'C4', 'C5',
  ];

  /// Get the keyboard type name for a given key count
  static String getKeyboardTypeName(int keyCount) {
    for (final entry in keyboardTypes.entries) {
      if (entry.value == keyCount) {
        return entry.key;
      }
    }
    return 'Custom ($keyCount keys)';
  }

  /// Get the default start note for a keyboard type
  static String getDefaultStartNote(String keyboardType) {
    final config = defaultConfigurations[keyboardType];
    return config?['startNote'] ?? defaultStartNote;
  }

  /// Get the description for a keyboard type
  static String getKeyboardDescription(String keyboardType) {
    final config = defaultConfigurations[keyboardType];
    return config?['description'] ?? 'Custom keyboard configuration';
  }

  /// Calculate the number of octaves for a given key count
  static double getOctaveCount(int keyCount) {
    return keyCount / 12.0;
  }

  /// Get the white key count for a given total key count
  static int getWhiteKeyCount(int totalKeyCount, String startNote) {
    // This is a simplified calculation - in reality it depends on the start note
    // For now, we'll use the standard ratio of approximately 7 white keys per 12 total keys
    return (totalKeyCount * 7 / 12).round();
  }

  /// Check if a semitone position represents a white key
  static bool isWhiteKey(int semitone) {
    final position = semitone % 12;
    return keyPattern[position];
  }

  /// Check if a semitone position represents a black key
  static bool isBlackKey(int semitone) {
    return !isWhiteKey(semitone);
  }

  /// Get the visual position of a black key relative to white keys
  /// Returns position relative to white keys (0.0 to 7.0 range)
  static double getBlackKeyVisualPosition(int semitone) {
    final position = semitone % 12;
    return blackKeyPositions[position] ?? 0.0;
  }

  /// Check if a black key is in the first group (C#, D#)
  static bool isFirstBlackKeyGroup(int semitone) {
    final position = semitone % 12;
    return position == 1 || position == 3; // C# or D#
  }

  /// Check if a black key is in the second group (F#, G#, A#)
  static bool isSecondBlackKeyGroup(int semitone) {
    final position = semitone % 12;
    return position == 6 || position == 8 || position == 10; // F#, G#, or A#
  }
}