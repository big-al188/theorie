// lib/views/widgets/quiz/scale_strip_question_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../models/quiz/scale_strip_question.dart';
import '../../../constants/ui_constants.dart';
import '../../../utils/color_utils.dart';
import '../../../utils/note_utils.dart';

/// Widget for displaying and interacting with scale strip questions
class ScaleStripQuestionWidget extends StatefulWidget {
  const ScaleStripQuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.onAnswerSelected,
    this.showCorrectAnswer = false,
    this.enabled = true,
  });

  final ScaleStripQuestion question;
  final ScaleStripAnswer? selectedAnswer;
  final ValueChanged<ScaleStripAnswer>? onAnswerSelected;
  final bool showCorrectAnswer;
  final bool enabled;

  @override
  State<ScaleStripQuestionWidget> createState() => _ScaleStripQuestionWidgetState();
}

class _ScaleStripQuestionWidgetState extends State<ScaleStripQuestionWidget> {
  late Set<int> _selectedPositions;
  late Set<String> _selectedNotes;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(ScaleStripQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAnswer != widget.selectedAnswer) {
      _initializeState();
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _initializeState() {
    _selectedPositions = widget.selectedAnswer?.selectedPositions ?? {};
    _selectedNotes = widget.selectedAnswer?.selectedNotes ?? {};
  }

  void _onPositionTapped(int position, String noteName) {
    if (!widget.enabled) return;

    setState(() {
      if (widget.question.configuration.allowMultipleSelection) {
        // Toggle selection for multiple selection mode
        if (_selectedPositions.contains(position)) {
          _selectedPositions.remove(position);
          _selectedNotes.remove(noteName);
        } else {
          _selectedPositions.add(position);
          _selectedNotes.add(noteName);
        }
      } else {
        // Single selection mode
        _selectedPositions = {position};
        _selectedNotes = {noteName};
      }
    });

    // Notify parent of answer change
    final answer = ScaleStripAnswer(
      selectedPositions: _selectedPositions,
      selectedNotes: _selectedNotes,
    );
    widget.onAnswerSelected?.call(answer);

    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }

  void _clearSelection() {
    if (!widget.enabled) return;

    setState(() {
      _selectedPositions.clear();
      _selectedNotes.clear();
    });

    final answer = ScaleStripAnswer(
      selectedPositions: _selectedPositions,
      selectedNotes: _selectedNotes,
    );
    widget.onAnswerSelected?.call(answer);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question instructions
        _buildInstructions(theme),
        
        const SizedBox(height: 16),
        
        // Interactive scale strip
        _buildInteractiveScaleStrip(screenWidth),
        
        const SizedBox(height: 16),
        
        // Control buttons
        _buildControlButtons(theme),
        
        const SizedBox(height: 8),
        
        // Answer feedback
        if (widget.showCorrectAnswer) _buildAnswerFeedback(theme),
      ],
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.questionText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_getInstructionText().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _getInstructionText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getInstructionText() {
    final config = widget.question.configuration;
    
    switch (widget.question.questionMode) {
      case ScaleStripQuestionMode.intervals:
        return 'Tap the positions that correspond to the scale intervals.';
      case ScaleStripQuestionMode.notes:
        return 'Identify and tap the correct note names.';
      case ScaleStripQuestionMode.construction:
        return 'Construct the requested scale or chord by tapping the correct notes.';
      case ScaleStripQuestionMode.pattern:
        return 'Identify the pattern by selecting the correct sequence of notes.';
    }
  }

  Widget _buildInteractiveScaleStrip(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InteractiveScaleStrip(
        configuration: widget.question.configuration,
        selectedPositions: _selectedPositions,
        correctPositions: widget.showCorrectAnswer 
          ? widget.question.correctAnswer.selectedPositions 
          : {},
        onPositionTapped: _onPositionTapped,
        enabled: widget.enabled,
        screenWidth: screenWidth,
      ),
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    return Row(
      children: [
        // Clear selection button
        OutlinedButton.icon(
          onPressed: widget.enabled && _selectedPositions.isNotEmpty 
            ? _clearSelection 
            : null,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Selection count indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_selectedPositions.length} selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const Spacer(),
        
        // Hint button
        if (widget.question.hints.isNotEmpty && widget.enabled)
          IconButton(
            onPressed: () => _showHint(context),
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Show hint',
          ),
      ],
    );
  }

  Widget _buildAnswerFeedback(ThemeData theme) {
    final correctAnswer = widget.question.correctAnswer;
    final userAnswer = ScaleStripAnswer(
      selectedPositions: _selectedPositions,
      selectedNotes: _selectedNotes,
    );
    
    final result = widget.question.validateAnswer(userAnswer);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.isCorrect 
          ? Colors.green.shade50 
          : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isCorrect 
            ? Colors.green.shade300 
            : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isCorrect ? Icons.check_circle : Icons.info,
                color: result.isCorrect ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.isCorrect ? 'Correct!' : 'Review your answer',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: result.isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(result.finalScore * 100).round()}%', // Fixed: Use finalScore instead of score
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: result.isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.feedback ?? 'No feedback available', // Fixed: Handle null feedback
            style: theme.textTheme.bodyMedium?.copyWith(
              color: result.isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          if (widget.question.explanation != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.question.explanation!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showHint(BuildContext context) {
    if (widget.question.hints.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hint'),
        content: Text(widget.question.hints.first),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Interactive scale strip that handles user taps and shows selections
class InteractiveScaleStrip extends StatelessWidget {
  const InteractiveScaleStrip({
    super.key,
    required this.configuration,
    required this.selectedPositions,
    required this.correctPositions,
    required this.onPositionTapped,
    required this.enabled,
    required this.screenWidth,
  });

  final ScaleStripConfiguration configuration;
  final Set<int> selectedPositions;
  final Set<int> correctPositions;
  final Function(int position, String noteName) onPositionTapped;
  final bool enabled;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate responsive dimensions
    final noteCount = 12 * configuration.octaveCount + 1; // Include octave
    final availableWidth = screenWidth - 64; // Account for padding
    final noteWidth = (availableWidth / noteCount).clamp(30.0, 80.0);
    final noteHeight = 60.0;
    
    return Container(
      height: noteHeight + 40, // Extra space for labels
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _buildNotePositions(theme, noteWidth, noteHeight),
        ),
      ),
    );
  }

  List<Widget> _buildNotePositions(ThemeData theme, double noteWidth, double noteHeight) {
    final positions = <Widget>[];
    final chromaticNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    
    for (int octave = 0; octave < configuration.octaveCount; octave++) {
      for (int i = 0; i < 12; i++) {
        final position = i;
        final noteName = chromaticNotes[i];
        final isSelected = selectedPositions.contains(position);
        final isCorrect = correctPositions.contains(position);
        final isPreHighlighted = configuration.preHighlightedPositions.contains(position);
        final isRoot = i == 0 && configuration.highlightRoot;
        
        positions.add(_buildNotePosition(
          theme,
          position,
          noteName,
          noteWidth,
          noteHeight,
          isSelected,
          isCorrect,
          isPreHighlighted,
          isRoot,
        ));
      }
    }
    
    // Add final octave note
    final finalPosition = 12 * configuration.octaveCount;
    final finalNoteName = chromaticNotes[0]; // C of next octave
    positions.add(_buildNotePosition(
      theme,
      finalPosition,
      finalNoteName,
      noteWidth,
      noteHeight,
      selectedPositions.contains(finalPosition),
      correctPositions.contains(finalPosition),
      configuration.preHighlightedPositions.contains(finalPosition),
      false,
    ));
    
    return positions;
  }

  Widget _buildNotePosition(
    ThemeData theme,
    int position,
    String noteName,
    double width,
    double height,
    bool isSelected,
    bool isCorrect,
    bool isPreHighlighted,
    bool isRoot,
  ) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isCorrect && correctPositions.isNotEmpty) {
      // Show correct answer
      backgroundColor = Colors.green.shade100;
      borderColor = Colors.green;
      textColor = Colors.green.shade800;
    } else if (isSelected) {
      // User selection
      backgroundColor = theme.colorScheme.primary.withOpacity(0.2);
      borderColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.primary;
    } else if (isPreHighlighted) {
      // Pre-highlighted positions
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade300;
      textColor = Colors.blue.shade700;
    } else if (isRoot) {
      // Root note
      backgroundColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade700;
    } else {
      // Normal note
      backgroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outline.withOpacity(0.3);
      textColor = theme.colorScheme.onSurface;
    }
    
    return GestureDetector(
      onTap: enabled ? () => onPositionTapped(position, noteName) : null,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Note name (if enabled)
            if (configuration.showNoteLabels || configuration.displayMode == ScaleStripMode.fillInBlanks)
              Text(
                _getDisplayText(position, noteName),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            
            // Interval number (if enabled)
            if (configuration.showIntervalLabels && configuration.displayMode == ScaleStripMode.intervals)
              Text(
                _getIntervalText(position),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText(int position, String noteName) {
    switch (configuration.displayMode) {
      case ScaleStripMode.noteNames:
        return noteName;
      case ScaleStripMode.intervals:
        return _getIntervalText(position);
      case ScaleStripMode.fillInBlanks:
        return selectedPositions.contains(position) ? noteName : '?';
      case ScaleStripMode.construction:
        return noteName;
    }
  }

  String _getIntervalText(int position) {
    // Convert chromatic position to interval number
    final interval = (position % 12) + 1;
    return interval.toString();
  }
}