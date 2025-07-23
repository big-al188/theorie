// lib/views/widgets/quiz/scale_strip_question_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../models/quiz/scale_strip_question.dart';
import '../../../constants/ui_constants.dart';
import '../../../utils/color_utils.dart';
import '../../../utils/note_utils.dart';

/// Widget for displaying and interacting with scale strip questions
/// Updated to fix octave handling, dropdown interactions, and highlighting bugs
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
  late Map<int, String> _pendingNoteSelections; // For dropdown mode
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
    _pendingNoteSelections = {};
  }

  void _onPositionTapped(int position, String noteName, {String? octaveInfo}) {
    if (!widget.enabled) return;

    final config = widget.question.configuration;
    
    // Check if position is locked (pre-highlighted)
    if (config.lockPreHighlighted && config.preHighlightedPositions.contains(position)) {
      return; // Don't allow interaction with locked positions
    }

    // Handle dropdown selection mode
    if (config.useDropdownSelection) {
      _showNoteSelectionDropdown(position);
      return;
    }

    setState(() {
      final fullNoteName = octaveInfo != null ? '$noteName$octaveInfo' : noteName;
      
      if (config.allowMultipleSelection) {
        // Toggle selection for multiple selection mode
        if (_selectedPositions.contains(position)) {
          _selectedPositions.remove(position);
          _selectedNotes.remove(fullNoteName);
          _selectedNotes.removeWhere((note) => note.startsWith('$noteName'));
        } else {
          _selectedPositions.add(position);
          _selectedNotes.add(fullNoteName);
        }
      } else {
        // Single selection mode
        _selectedPositions = {position};
        _selectedNotes = {fullNoteName};
      }
    });

    _notifyAnswerChange();
    HapticFeedback.selectionClick();
  }

  void _showNoteSelectionDropdown(int position) {
    final chromaticNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Note for Position ${position + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: chromaticNotes.map((note) {
              return ListTile(
                title: Text(note),
                onTap: () {
                  setState(() {
                    _selectedPositions.add(position);
                    _selectedNotes.add(note);
                    _pendingNoteSelections[position] = note;
                  });
                  Navigator.of(context).pop();
                  _notifyAnswerChange();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _clearSelection() {
    if (!widget.enabled) return;

    setState(() {
      _selectedPositions.clear();
      _selectedNotes.clear();
      _pendingNoteSelections.clear();
    });

    _notifyAnswerChange();
  }

  void _notifyAnswerChange() {
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
        _buildInteractiveScaleStrip(screenWidth, theme),
        
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
        if (config.useDropdownSelection) {
          return 'Tap on empty positions to select the correct note from the dropdown.';
        }
        return 'Identify and tap the correct note names.';
      case ScaleStripQuestionMode.construction:
        return 'Construct the requested scale or chord by tapping the correct notes.';
      case ScaleStripQuestionMode.pattern:
        return 'Identify the pattern by selecting the correct sequence of notes.';
    }
  }

  Widget _buildInteractiveScaleStrip(double screenWidth, ThemeData theme) {
    final config = widget.question.configuration;
    final octaveCount = config.octaveCount;
    final totalPositions = 12 * octaveCount;
    
    // Calculate positions per row to optimize display
    final positionsPerRow = screenWidth > 800 ? 12 : (screenWidth > 600 ? 8 : 6);
    final rows = (totalPositions / positionsPerRow).ceil();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          final startPos = rowIndex * positionsPerRow;
          final endPos = (startPos + positionsPerRow).clamp(0, totalPositions);
          
          return Padding(
            padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 8.0 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(endPos - startPos, (colIndex) {
                final position = startPos + colIndex;
                return _buildScaleStripPosition(position, theme);
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScaleStripPosition(int position, ThemeData theme) {
    final config = widget.question.configuration;
    final isSelected = _selectedPositions.contains(position);
    final isPreHighlighted = config.preHighlightedPositions.contains(position);
    final isLocked = config.lockPreHighlighted && isPreHighlighted;
    final isReference = config.showFirstNoteAsReference && 
                       config.firstNotePosition == position;
    
    // Determine octave for this position
    final octave = (position ~/ 12) + 3; // Start from octave 3
    final chromaticPosition = position % 12;
    final noteName = _getNoteNameForPosition(chromaticPosition, config.rootNote);
    final fullNoteName = config.enableOctaveDistinction ? '$noteName$octave' : noteName;
    
    // Get the display label
    final displayLabel = _getDisplayLabel(position, noteName, isPreHighlighted);
    
    // Determine display styling
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isPreHighlighted) {
      backgroundColor = theme.colorScheme.secondary.withOpacity(0.6);
      borderColor = theme.colorScheme.secondary;
      textColor = theme.colorScheme.onSecondary;
    } else if (isReference) {
      // Fixed: Use normal highlighting instead of gold
      backgroundColor = theme.colorScheme.surfaceVariant;
      borderColor = theme.colorScheme.outline;
      textColor = theme.colorScheme.onSurface;
    } else {
      backgroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outline.withOpacity(0.5);
      textColor = theme.colorScheme.onSurface;
    }
    
    return GestureDetector(
      onTap: isLocked ? null : () => _onPositionTapped(
        position, 
        noteName, 
        octaveInfo: config.enableOctaveDistinction ? octave.toString() : null,
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Note name - always show if we have a display label
            if (displayLabel.isNotEmpty) ...[
              Text(
                displayLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            // Interval label
            if (config.showIntervalLabels) ...[
              const SizedBox(height: 2),
              Text(
                widget.question.getIntervalLabel(chromaticPosition),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
            
            // Octave indicator for multi-octave displays
            if (config.octaveCount > 1 && config.enableOctaveDistinction) ...[
              const SizedBox(height: 1),
              Text(
                octave.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.6),
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDisplayLabel(int position, String noteName, bool isPreHighlighted) {
    final config = widget.question.configuration;
    
    // For dropdown mode, show selected note or placeholder
    if (config.useDropdownSelection) {
      if (_pendingNoteSelections.containsKey(position)) {
        return _pendingNoteSelections[position]!;
      } else if (isPreHighlighted) {
        // Always show the correct note name for pre-highlighted positions
        return noteName;
      } else {
        return '?'; // Show placeholder for unlocked empty positions
      }
    }
    
    // For pre-highlighted positions, always show the correct note
    if (isPreHighlighted) {
      return noteName;
    }
    
    // For selected positions or when showing note labels
    if (config.showNoteLabels || _selectedPositions.contains(position)) {
      return noteName;
    }
    
    return '';
  }

  String _getNoteNameForPosition(int chromaticPosition, String rootNote) {
    const chromaticNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    
    // Find root position
    int rootIndex = chromaticNotes.indexOf(rootNote);
    if (rootIndex == -1) {
      // Handle flat notes
      const flatToSharp = {
        'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#'
      };
      rootIndex = chromaticNotes.indexOf(flatToSharp[rootNote] ?? 'C');
    }
    
    final noteIndex = (chromaticPosition + rootIndex) % 12;
    return chromaticNotes[noteIndex];
  }

  Widget _buildControlButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Clear button
        OutlinedButton.icon(
          onPressed: widget.enabled ? _clearSelection : null,
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
        ),
        
        // Selection info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${_selectedPositions.length} selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerFeedback(ThemeData theme) {
    final correctAnswer = widget.question.correctAnswer;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Correct Answer:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: correctAnswer.selectedNotes.map((note) {
              return Chip(
                label: Text(note),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
              );
            }).toList(),
          ),
          if (widget.question.explanation != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.question.explanation!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}