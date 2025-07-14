/// Type of quiz
enum QuizType {
  section,    // Full section quiz
  topic,      // Single topic quiz
  refresher,  // Quick refresher quiz
  custom,     // Custom quiz
}

/// Status of quiz
enum QuizStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  abandoned,
}

/// Question types
enum QuestionType {
  multipleChoice,
  scaleInteractive,
  chordInteractive,
  intervalInteractive,
  rhythmInteractive,
}

/// Difficulty levels
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// Scale display modes for interactive questions
enum ScaleDisplayMode {
  showAll,         // Show all notes and intervals
  hideNotes,       // Hide note names
  hideIntervals,   // Hide interval labels
  mixed,           // Mix of hidden elements
}

/// Scale interaction modes
enum ScaleInteractionMode {
  readOnly,        // Just display, no interaction
  fillNotes,       // User fills in note names
  fillIntervals,   // User fills in intervals
  highlight,       // User highlights specific notes
  construct,       // User constructs scale from scratch
}

/// Fretboard modes for chord questions
enum FretboardMode {
  chord,           // Display/interact with chords
  scale,           // Display/interact with scales
  singleNote,      // Single note identification
  pattern,         // Pattern recognition
}

/// Validation modes
enum ValidationMode {
  immediate,       // Validate on each interaction
  onSubmit,        // Validate when submitted
  delayed,         // Validate after delay
}

/// Answer selection strategies
enum AnswerSelectionStrategy {
  random,          // Randomly select from pool
  weighted,        // Weight by difficulty/relevance
  adaptive,        // Adapt based on performance
  sequential,      // Use in sequence
}

/// Quiz generation strategies
enum QuizGenerationStrategy {
  balanced,        // Balance across topics
  focused,         // Focus on specific areas
  review,          // Focus on previously missed
  comprehensive,   // Cover everything
}

/// Extensions for enum utilities
extension QuizTypeExtension on QuizType {
  String get displayName {
    switch (this) {
      case QuizType.section:
        return 'Section Quiz';
      case QuizType.topic:
        return 'Topic Quiz';
      case QuizType.refresher:
        return 'Quick Refresher';
      case QuizType.custom:
        return 'Custom Quiz';
    }
  }

  String get description {
    switch (this) {
      case QuizType.section:
        return 'Comprehensive quiz covering the entire section';
      case QuizType.topic:
        return 'Focused quiz on a specific topic';
      case QuizType.refresher:
        return 'Quick 5-minute review of key concepts';
      case QuizType.custom:
        return 'Personalized quiz based on your preferences';
    }
  }
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  int get pointMultiplier {
    switch (this) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.intermediate:
        return 2;
      case DifficultyLevel.advanced:
        return 3;
      case DifficultyLevel.expert:
        return 4;
    }
  }

  double get timeMultiplier {
    switch (this) {
      case DifficultyLevel.beginner:
        return 1.0;
      case DifficultyLevel.intermediate:
        return 1.5;
      case DifficultyLevel.advanced:
        return 2.0;
      case DifficultyLevel.expert:
        return 2.5;
    }
  }
}

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.scaleInteractive:
        return 'Scale Exercise';
      case QuestionType.chordInteractive:
        return 'Chord Exercise';
      case QuestionType.intervalInteractive:
        return 'Interval Exercise';
      case QuestionType.rhythmInteractive:
        return 'Rhythm Exercise';
    }
  }

  String get icon {
    switch (this) {
      case QuestionType.multipleChoice:
        return '📝';
      case QuestionType.scaleInteractive:
        return '🎹';
      case QuestionType.chordInteractive:
        return '🎸';
      case QuestionType.intervalInteractive:
        return '🎵';
      case QuestionType.rhythmInteractive:
        return '🥁';
    }
  }
}