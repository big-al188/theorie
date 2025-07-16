# Question Type Integration Guide

## Overview
This guide covers how to integrate new question types into the Theorie app's quiz system. The app currently supports multiple choice questions but is designed to be extensible for additional question types like interactive fretboard questions, audio-based questions, and visual exercises.

## Current Architecture

### Question Type System
The quiz system uses a polymorphic approach with a base `QuizQuestion` class and specific implementations for each question type:

```
QuizQuestion (Abstract Base)
├── MultipleChoiceQuestion (Implemented)
├── InteractiveFretboardQuestion (Planned)
├── AudioQuestion (Planned)
├── ScaleStripQuestion (Planned)
└── PianoKeyboardQuestion (Planned)
```

### Core Components
1. **Question Models** - Data structures for question types
2. **Question Widgets** - UI components for display and interaction
3. **Answer Validation** - Logic for checking correctness
4. **Quiz Integration** - Integration with the quiz controller

## Base Question Architecture

### Abstract QuizQuestion Class
```dart
abstract class QuizQuestion {
  final String id;
  final String topicId;
  final String sectionId;
  final String questionText;
  final QuestionType type;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final String explanation;
  final Map<String, dynamic> metadata;

  const QuizQuestion({
    required this.id,
    required this.topicId,
    required this.sectionId,
    required this.questionText,
    required this.type,
    required this.difficulty,
    required this.tags,
    required this.explanation,
    this.metadata = const {},
  });

  // Abstract methods that must be implemented
  bool isCorrect(dynamic answer);
  String getDetailedExplanation(dynamic selectedAnswer);
  Map<String, dynamic> toJson();
  factory QuizQuestion.fromJson(Map<String, dynamic> json);
}
```

### Question Type Enum
```dart
enum QuestionType {
  multipleChoice('Multiple Choice'),
  interactiveFretboard('Interactive Fretboard'),
  audioRecognition('Audio Recognition'),
  scaleStrip('Scale Strip'),
  pianoKeyboard('Piano Keyboard'),
  intervalIdentification('Interval Identification'),
  chordProgression('Chord Progression'),
  rhythmPattern('Rhythm Pattern');

  const QuestionType(this.displayName);
  final String displayName;
}
```

## Creating a New Question Type

### Step 1: Define the Question Model
Create a new question class that extends `QuizQuestion`:

```dart
// lib/models/quiz/interactive_fretboard_question.dart

import 'quiz_question.dart';

class InteractiveFretboardQuestion extends QuizQuestion {
  final String fretboardConfig;
  final List<FretboardPosition> targetPositions;
  final int timeLimit;
  final bool allowMultipleSelections;
  final FretboardValidationMode validationMode;

  const InteractiveFretboardQuestion({
    required super.id,
    required super.topicId,
    required super.sectionId,
    required super.questionText,
    required super.difficulty,
    required super.tags,
    required super.explanation,
    required this.fretboardConfig,
    required this.targetPositions,
    this.timeLimit = 60,
    this.allowMultipleSelections = false,
    this.validationMode = FretboardValidationMode.exact,
    super.metadata = const {},
  }) : super(type: QuestionType.interactiveFretboard);

  @override
  bool isCorrect(dynamic answer) {
    if (answer is! List<FretboardPosition>) {
      return false;
    }

    final List<FretboardPosition> selectedPositions = answer;

    switch (validationMode) {
      case FretboardValidationMode.exact:
        return _validateExactPositions(selectedPositions);
      case FretboardValidationMode.anyOctave:
        return _validateAnyOctave(selectedPositions);
      case FretboardValidationMode.pattern:
        return _validatePattern(selectedPositions);
    }
  }

  @override
  String getDetailedExplanation(dynamic selectedAnswer) {
    final buffer = StringBuffer();
    
    // Add base explanation
    buffer.writeln(explanation);
    
    // Add fretboard-specific feedback
    if (selectedAnswer is List<FretboardPosition>) {
      buffer.writeln('\n**Your Selection:**');
      buffer.writeln(_formatFretboardPositions(selectedAnswer));
      
      buffer.writeln('\n**Correct Positions:**');
      buffer.writeln(_formatFretboardPositions(targetPositions));
      
      // Add learning tips
      buffer.writeln('\n**Learning Tips:**');
      buffer.writeln(_generateLearningTips(selectedAnswer));
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'topicId': topicId,
    'sectionId': sectionId,
    'questionText': questionText,
    'type': type.name,
    'difficulty': difficulty.name,
    'tags': tags,
    'explanation': explanation,
    'fretboardConfig': fretboardConfig,
    'targetPositions': targetPositions.map((p) => p.toJson()).toList(),
    'timeLimit': timeLimit,
    'allowMultipleSelections': allowMultipleSelections,
    'validationMode': validationMode.name,
    'metadata': metadata,
  };

  factory InteractiveFretboardQuestion.fromJson(Map<String, dynamic> json) {
    return InteractiveFretboardQuestion(
      id: json['id'],
      topicId: json['topicId'],
      sectionId: json['sectionId'],
      questionText: json['questionText'],
      difficulty: DifficultyLevel.values.byName(json['difficulty']),
      tags: List<String>.from(json['tags']),
      explanation: json['explanation'],
      fretboardConfig: json['fretboardConfig'],
      targetPositions: (json['targetPositions'] as List)
          .map((p) => FretboardPosition.fromJson(p))
          .toList(),
      timeLimit: json['timeLimit'] ?? 60,
      allowMultipleSelections: json['allowMultipleSelections'] ?? false,
      validationMode: FretboardValidationMode.values
          .byName(json['validationMode'] ?? 'exact'),
      metadata: json['metadata'] ?? {},
    );
  }

  // Private validation methods
  bool _validateExactPositions(List<FretboardPosition> selected) {
    if (selected.length != targetPositions.length) return false;
    
    for (final position in targetPositions) {
      if (!selected.contains(position)) return false;
    }
    return true;
  }

  bool _validateAnyOctave(List<FretboardPosition> selected) {
    // Allow correct notes in any octave
    final targetNotes = targetPositions.map((p) => p.note % 12).toSet();
    final selectedNotes = selected.map((p) => p.note % 12).toSet();
    return targetNotes.difference(selectedNotes).isEmpty;
  }

  bool _validatePattern(List<FretboardPosition> selected) {
    // Validate pattern recognition rather than exact positions
    return _calculatePattern(selected) == _calculatePattern(targetPositions);
  }

  String _formatFretboardPositions(List<FretboardPosition> positions) {
    return positions.map((p) => 'String ${p.string}, Fret ${p.fret}').join(', ');
  }

  String _generateLearningTips(List<FretboardPosition> selectedPositions) {
    // Generate contextual learning tips based on the mistake
    final buffer = StringBuffer();
    
    if (selectedPositions.length != targetPositions.length) {
      buffer.writeln('• Remember to select all required positions');
    }
    
    // Add more specific tips based on the question type
    if (tags.contains('scales')) {
      buffer.writeln('• Focus on the scale pattern and interval relationships');
    }
    
    return buffer.toString();
  }
}

// Supporting classes
class FretboardPosition {
  final int string;
  final int fret;
  final int note;

  const FretboardPosition({
    required this.string,
    required this.fret,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
    'string': string,
    'fret': fret,
    'note': note,
  };

  factory FretboardPosition.fromJson(Map<String, dynamic> json) {
    return FretboardPosition(
      string: json['string'],
      fret: json['fret'],
      note: json['note'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FretboardPosition &&
        other.string == string &&
        other.fret == fret &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(string, fret, note);
}

enum FretboardValidationMode {
  exact,      // Must select exact positions
  anyOctave,  // Correct notes in any octave
  pattern,    // Pattern recognition
}
```

### Step 2: Create the Question Widget
Create a widget for displaying and interacting with the new question type:

```dart
// lib/views/widgets/quiz/interactive_fretboard_widget.dart

import 'package:flutter/material.dart';
import '../../../models/quiz/interactive_fretboard_question.dart';
import '../fretboard/fretboard_widget.dart';

class InteractiveFretboardWidget extends StatefulWidget {
  const InteractiveFretboardWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.onAnswerSelected,
    this.showCorrectAnswer = false,
    this.enabled = true,
  });

  final InteractiveFretboardQuestion question;
  final List<FretboardPosition>? selectedAnswer;
  final ValueChanged<List<FretboardPosition>>? onAnswerSelected;
  final bool showCorrectAnswer;
  final bool enabled;

  @override
  State<InteractiveFretboardWidget> createState() => 
      _InteractiveFretboardWidgetState();
}

class _InteractiveFretboardWidgetState 
    extends State<InteractiveFretboardWidget> {
  List<FretboardPosition> _selectedPositions = [];
  int _remainingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _startTimer();
  }

  void _initializeState() {
    _selectedPositions = widget.selectedAnswer ?? [];
    _remainingTime = widget.question.timeLimit;
  }

  void _startTimer() {
    if (widget.question.timeLimit > 0 && widget.enabled) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 0) {
            _timer?.cancel();
            _submitAnswer();
          }
        });
      });
    }
  }

  void _submitAnswer() {
    widget.onAnswerSelected?.call(_selectedPositions);
  }

  void _onFretboardTap(FretboardPosition position) {
    if (!widget.enabled) return;

    setState(() {
      if (_selectedPositions.contains(position)) {
        _selectedPositions.remove(position);
      } else {
        if (widget.question.allowMultipleSelections) {
          _selectedPositions.add(position);
        } else {
          _selectedPositions = [position];
        }
      }
    });

    // Auto-submit if single selection
    if (!widget.question.allowMultipleSelections) {
      _submitAnswer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question text
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.question.questionText,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),

        // Timer display
        if (widget.question.timeLimit > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LinearProgressIndicator(
              value: _remainingTime / widget.question.timeLimit,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingTime > 10 ? Colors.blue : Colors.red,
              ),
            ),
          ),

        // Fretboard widget
        Expanded(
          child: InteractiveFretboardDisplay(
            config: widget.question.fretboardConfig,
            selectedPositions: _selectedPositions,
            correctPositions: widget.showCorrectAnswer 
                ? widget.question.targetPositions 
                : null,
            onPositionTap: _onFretboardTap,
            enabled: widget.enabled,
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.question.allowMultipleSelections
                ? 'Tap multiple positions on the fretboard. Press submit when ready.'
                : 'Tap the correct position on the fretboard.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),

        // Submit button for multiple selections
        if (widget.question.allowMultipleSelections && widget.enabled)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedPositions.isNotEmpty ? _submitAnswer : null,
              child: Text('Submit Answer'),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Custom fretboard display widget
class InteractiveFretboardDisplay extends StatelessWidget {
  const InteractiveFretboardDisplay({
    super.key,
    required this.config,
    required this.selectedPositions,
    this.correctPositions,
    this.onPositionTap,
    this.enabled = true,
  });

  final String config;
  final List<FretboardPosition> selectedPositions;
  final List<FretboardPosition>? correctPositions;
  final ValueChanged<FretboardPosition>? onPositionTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: enabled ? _handleTap : null,
      child: CustomPaint(
        painter: InteractiveFretboardPainter(
          selectedPositions: selectedPositions,
          correctPositions: correctPositions,
          config: config,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    // Calculate which fret and string was tapped
    final position = _calculateFretboardPosition(details.localPosition);
    if (position != null) {
      onPositionTap?.call(position);
    }
  }

  FretboardPosition? _calculateFretboardPosition(Offset offset) {
    // Implementation depends on fretboard layout
    // This is a simplified example
    final fret = (offset.dx / 60).round(); // Approximate fret width
    final string = (offset.dy / 40).round(); // Approximate string spacing
    
    if (fret >= 0 && fret <= 12 && string >= 0 && string <= 5) {
      // Calculate MIDI note based on string and fret
      final note = _calculateMidiNote(string, fret);
      return FretboardPosition(string: string, fret: fret, note: note);
    }
    return null;
  }

  int _calculateMidiNote(int string, int fret) {
    // Standard tuning MIDI notes for open strings
    const openStrings = [64, 59, 55, 50, 45, 40]; // E A D G B E
    return openStrings[string] + fret;
  }
}

// Custom painter for the interactive fretboard
class InteractiveFretboardPainter extends CustomPainter {
  final List<FretboardPosition> selectedPositions;
  final List<FretboardPosition>? correctPositions;
  final String config;

  InteractiveFretboardPainter({
    required this.selectedPositions,
    this.correctPositions,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw fretboard background
    _drawFretboard(canvas, size);
    
    // Draw selected positions
    _drawPositions(canvas, size, selectedPositions, Colors.blue);
    
    // Draw correct positions if showing answers
    if (correctPositions != null) {
      _drawPositions(canvas, size, correctPositions!, Colors.green);
    }
  }

  void _drawFretboard(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 2.0;

    // Draw frets
    for (int i = 0; i <= 12; i++) {
      final x = i * (size.width / 12);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw strings
    for (int i = 0; i < 6; i++) {
      final y = i * (size.height / 5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawPositions(
    Canvas canvas,
    Size size,
    List<FretboardPosition> positions,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final position in positions) {
      final x = position.fret * (size.width / 12);
      final y = position.string * (size.height / 5);
      
      canvas.drawCircle(Offset(x, y), 15, paint);
    }
  }

  @override
  bool shouldRepaint(InteractiveFretboardPainter oldDelegate) {
    return selectedPositions != oldDelegate.selectedPositions ||
           correctPositions != oldDelegate.correctPositions;
  }
}
```

### Step 3: Update Quiz Integration
Update the quiz system to handle the new question type:

```dart
// lib/views/widgets/quiz/quiz_question_widget.dart

import 'package:flutter/material.dart';
import '../../../models/quiz/quiz_question.dart';
import '../../../models/quiz/multiple_choice_question.dart';
import '../../../models/quiz/interactive_fretboard_question.dart';
import 'multiple_choice_widget.dart';
import 'interactive_fretboard_widget.dart';

class QuizQuestionWidget extends StatelessWidget {
  const QuizQuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.onAnswerSelected,
    this.showCorrectAnswer = false,
    this.enabled = true,
  });

  final QuizQuestion question;
  final dynamic selectedAnswer;
  final ValueChanged<dynamic>? onAnswerSelected;
  final bool showCorrectAnswer;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question as MultipleChoiceQuestion,
          selectedAnswer: selectedAnswer,
          onAnswerSelected: onAnswerSelected,
          showCorrectAnswer: showCorrectAnswer,
          enabled: enabled,
        );

      case QuestionType.interactiveFretboard:
        return InteractiveFretboardWidget(
          question: question as InteractiveFretboardQuestion,
          selectedAnswer: selectedAnswer as List<FretboardPosition>?,
          onAnswerSelected: onAnswerSelected,
          showCorrectAnswer: showCorrectAnswer,
          enabled: enabled,
        );

      // Add other question types as they are implemented
      default:
        return Center(
          child: Text(
            'Question type ${question.type.displayName} not implemented',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
    }
  }
}
```

### Step 4: Update Quiz Controller
Update the quiz controller to handle the new question type:

```dart
// lib/controllers/quiz_controller.dart

class QuizController extends ChangeNotifier {
  // ... existing code ...

  Future<void> submitAnswer(dynamic answer) async {
    if (_currentQuestion == null) return;

    final question = _currentQuestion!;
    final isCorrect = question.isCorrect(answer);

    // Store answer with appropriate type
    _answers[_currentQuestionIndex] = _createAnswerRecord(question, answer, isCorrect);

    // Update score
    if (isCorrect) {
      _correctAnswers++;
    }

    // Provide feedback
    _lastFeedback = question.getDetailedExplanation(answer);

    notifyListeners();
  }

  Map<String, dynamic> _createAnswerRecord(
    QuizQuestion question,
    dynamic answer,
    bool isCorrect,
  ) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return {
          'questionId': question.id,
          'answer': answer,
          'isCorrect': isCorrect,
          'timeSpent': _calculateTimeSpent(),
          'type': 'multiple_choice',
        };

      case QuestionType.interactiveFretboard:
        return {
          'questionId': question.id,
          'answer': (answer as List<FretboardPosition>)
              .map((p) => p.toJson())
              .toList(),
          'isCorrect': isCorrect,
          'timeSpent': _calculateTimeSpent(),
          'type': 'interactive_fretboard',
        };

      default:
        return {
          'questionId': question.id,
          'answer': answer,
          'isCorrect': isCorrect,
          'timeSpent': _calculateTimeSpent(),
          'type': 'unknown',
        };
    }
  }

  // ... rest of the controller code ...
}
```

## Additional Question Type Examples

### Audio Recognition Question
```dart
class AudioQuestion extends QuizQuestion {
  final String audioUrl;
  final List<String> correctAnswers;
  final AudioQuestionType audioType;

  const AudioQuestion({
    required super.id,
    required super.topicId,
    required super.sectionId,
    required super.questionText,
    required super.difficulty,
    required super.tags,
    required super.explanation,
    required this.audioUrl,
    required this.correctAnswers,
    required this.audioType,
    super.metadata = const {},
  }) : super(type: QuestionType.audioRecognition);

  @override
  bool isCorrect(dynamic answer) {
    if (answer is String) {
      return correctAnswers.contains(answer.toLowerCase());
    }
    return false;
  }

  // ... implementation details ...
}

enum AudioQuestionType {
  intervalRecognition,
  chordRecognition,
  scaleRecognition,
  rhythmRecognition,
}
```

### Scale Strip Question
```dart
class ScaleStripQuestion extends QuizQuestion {
  final String scaleType;
  final String rootNote;
  final List<int> correctPositions;
  final bool showNoteNames;

  const ScaleStripQuestion({
    required super.id,
    required super.topicId,
    required super.sectionId,
    required super.questionText,
    required super.difficulty,
    required super.tags,
    required super.explanation,
    required this.scaleType,
    required this.rootNote,
    required this.correctPositions,
    this.showNoteNames = false,
    super.metadata = const {},
  }) : super(type: QuestionType.scaleStrip);

  @override
  bool isCorrect(dynamic answer) {
    if (answer is List<int>) {
      return _comparePositions(answer, correctPositions);
    }
    return false;
  }

  // ... implementation details ...
}
```

## Testing New Question Types

### Unit Tests
```dart
void main() {
  group('InteractiveFretboardQuestion Tests', () {
    late InteractiveFretboardQuestion question;

    setUp(() {
      question = InteractiveFretboardQuestion(
        id: 'test_fretboard_001',
        topicId: 'scales',
        sectionId: 'fundamentals',
        questionText: 'Find the C major scale positions',
        difficulty: DifficultyLevel.beginner,
        tags: ['scales', 'major', 'C'],
        explanation: 'Test explanation',
        fretboardConfig: 'standard',
        targetPositions: [
          FretboardPosition(string: 0, fret: 3, note: 67),
          FretboardPosition(string: 1, fret: 0, note: 59),
        ],
      );
    });

    test('should validate correct answer', () {
      final correctAnswer = [
        FretboardPosition(string: 0, fret: 3, note: 67),
        FretboardPosition(string: 1, fret: 0, note: 59),
      ];

      expect(question.isCorrect(correctAnswer), isTrue);
    });

    test('should reject incorrect answer', () {
      final incorrectAnswer = [
        FretboardPosition(string: 0, fret: 2, note: 66),
      ];

      expect(question.isCorrect(incorrectAnswer), isFalse);
    });

    test('should serialize to/from JSON', () {
      final json = question.toJson();
      final reconstructed = InteractiveFretboardQuestion.fromJson(json);

      expect(reconstructed.id, equals(question.id));
      expect(reconstructed.targetPositions, equals(question.targetPositions));
    });
  });
}
```

### Widget Tests
```dart
void main() {
  group('InteractiveFretboardWidget Tests', () {
    testWidgets('should display fretboard and handle taps', (tester) async {
      final question = InteractiveFretboardQuestion(
        // ... question setup ...
      );

      List<FretboardPosition>? selectedAnswer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFretboardWidget(
              question: question,
              onAnswerSelected: (answer) => selectedAnswer = answer,
            ),
          ),
        ),
      );

      // Verify fretboard is displayed
      expect(find.byType(InteractiveFretboardDisplay), findsOneWidget);

      // Simulate tap on fretboard
      await tester.tap(find.byType(InteractiveFretboardDisplay));
      await tester.pump();

      // Verify answer was selected
      expect(selectedAnswer, isNotNull);
    });
  });
}
```

## Best Practices

### 1. Question Type Design
- **Single Responsibility**: Each question type should focus on one type of interaction
- **Consistent Interface**: Follow the same patterns as existing question types
- **Extensible**: Design for future enhancements and modifications
- **Accessible**: Ensure questions work for users with different abilities

### 2. UI/UX Considerations
- **Intuitive Interface**: Make interactions obvious and natural
- **Visual Feedback**: Provide clear feedback for user actions
- **Error Handling**: Handle edge cases gracefully
- **Performance**: Optimize for smooth interactions

### 3. Educational Value
- **Learning Objectives**: Each question type should serve specific learning goals
- **Progressive Difficulty**: Support different skill levels
- **Meaningful Feedback**: Provide constructive explanations
- **Practical Application**: Connect to real-world musical scenarios

### 4. Technical Implementation
- **Type Safety**: Use strong typing for all question data
- **Error Handling**: Implement comprehensive error handling
- **Testing**: Write thorough unit and widget tests
- **Documentation**: Document all public APIs and complex logic

## Migration and Versioning

### Adding New Question Types
1. Create the question model following established patterns
2. Implement the corresponding widget
3. Update the quiz integration components
4. Add comprehensive tests
5. Update documentation

### Versioning Strategy
```dart
class QuizQuestionVersion {
  static const int currentVersion = 2;
  
  static QuizQuestion migrate(Map<String, dynamic> json) {
    final version = json['version'] ?? 1;
    
    switch (version) {
      case 1:
        return _migrateFromV1(json);
      case 2:
        return _createFromV2(json);
      default:
        throw UnsupportedError('Unsupported version: $version');
    }
  }
}
```

This guide provides a comprehensive framework for integrating new question types into the Theorie app. Follow these patterns to ensure consistency, maintainability, and excellent user experience across all question types.