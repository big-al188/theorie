// lib/views/widgets/quiz/scale_strip_question_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../models/quiz/scale_strip_question.dart';
import '../../../models/music/note.dart';
import '../../../constants/ui_constants.dart';
import '../../../utils/color_utils.dart';

/// Enhanced widget for scale strip questions with better generalization
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
  late Map<int, String> _dropdownSelections;
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
    final config = widget.question.configuration;

    if (config.clearSelectionOnStart || widget.selectedAnswer == null) {
      _selectedPositions = <int>{};
      _selectedNotes = <String>{};
    } else {
      _selectedPositions = Set.from(widget.selectedAnswer!.selectedPositions);
      _selectedNotes = Set.from(widget.selectedAnswer!.selectedNotes);
    }

    _dropdownSelections = <int, String>{};
  }

  void _onPositionTapped(int position) {
    if (!widget.enabled) return;

    final config = widget.question.configuration;

    // Check if position is locked
    if (_isPositionLocked(position)) return;

    if (config.useDropdownSelection) {
      _showNoteSelectionDropdown(position);
    } else {
      _togglePosition(position);
    }
  }

  bool _isPositionLocked(int position) {
    final config = widget.question.configuration;

    // Check pre-highlighted locks
    if (config.lockPreHighlighted && config.preHighlightedPositions.contains(position)) {
      return true;
    }

    // Check reference note locks
    if (config.lockReferenceNote &&
        config.firstNotePosition != null &&
        position == config.firstNotePosition) {
      return true;
    }

    return false;
  }

  void _togglePosition(int position) {
    setState(() {
      if (_selectedPositions.contains(position)) {
        _selectedPositions.remove(position);
        // Remove corresponding note
        final noteName = _getNoteNameForPosition(position);
        _selectedNotes.removeWhere((note) => note.startsWith(noteName));
      } else {
        _selectedPositions.add(position);
        final noteName = _getNoteNameForPosition(position);
        _selectedNotes.add(noteName);
      }
    });

    _notifyAnswerChange();

    if (widget.question.configuration.validateSelectionOnChange) {
      _validateSelection();
    }
  }

  void _showNoteSelectionDropdown(int position) {
    final availableNotes = _getAvailableNotesForPosition(position);

    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select note for position ${position + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableNotes.map((note) {
              return ListTile(
                title: Text(note),
                onTap: () {
                  _selectNoteFromDropdown(position, note);
                  Navigator.of(context).pop();
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

  void _selectNoteFromDropdown(int position, String note) {
    setState(() {
      _selectedPositions.add(position);
      _selectedNotes.add(note);
      _dropdownSelections[position] = note;
    });

    _notifyAnswerChange();

    if (widget.question.configuration.validateSelectionOnChange) {
      _validateSelection();
    }
  }

  void _validateSelection() {
    // Provide immediate feedback
    final isPartiallyCorrect = _isSelectionPartiallyCorrect();
    if (isPartiallyCorrect) {
      HapticFeedback.lightImpact();
    }
  }

  bool _isSelectionPartiallyCorrect() {
    final correctPositions = widget.question.correctAnswer.selectedPositions;
    return _selectedPositions.every((pos) => correctPositions.contains(pos));
  }

  void _clearSelection() {
    if (!widget.enabled) return;

    setState(() {
      _selectedPositions.clear();
      _selectedNotes.clear();
      _dropdownSelections.clear();
    });

    _notifyAnswerChange();
    HapticFeedback.selectionClick();
  }

  void _notifyAnswerChange() {
    final answer = ScaleStripAnswer(
      selectedPositions: _selectedPositions,
      selectedNotes: _selectedNotes,
    );
    widget.onAnswerSelected?.call(answer);
  }

  List<String> _getAvailableNotesForPosition(int position) {
    // Get chromatic note options for this position
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final config = widget.question.configuration;
    final rootPc = Note.fromString(config.rootNote).pitchClass;
    final actualPosition = (rootPc + position) % 12;

    final baseNote = noteNames[actualPosition];

    // Provide enharmonic options for sharps
    if (baseNote.contains('#')) {
      final flatEquivalent = _getEnharmonicFlat(baseNote);
      return [baseNote, flatEquivalent];
    }

    return [baseNote];
  }

  String _getEnharmonicFlat(String sharpNote) {
    const sharpToFlat = {
      'C#': 'Db', 'D#': 'Eb', 'F#': 'Gb', 'G#': 'Ab', 'A#': 'Bb',
    };
    return sharpToFlat[sharpNote] ?? sharpNote;
  }

  String _getNoteNameForPosition(int position) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final config = widget.question.configuration;
    final rootPc = Note.fromString(config.rootNote).pitchClass;
    final actualPosition = (rootPc + position) % 12;
    return noteNames[actualPosition];
  }

  String _getIntervalLabel(int position) {
    const intervalLabels = ['1', '♭2', '2', '♭3', '3', '4', '♭5', '5', '♭6', '6', '♭7', '7'];
    return intervalLabels[position % 12];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructions(theme),
        const SizedBox(height: 16),
        _buildScaleStrip(screenWidth, theme),
        const SizedBox(height: 16),
        _buildControlButtons(theme),
        if (widget.showCorrectAnswer) ...[
          const SizedBox(height: 16),
          _buildAnswerFeedback(theme),
        ],
      ],
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
          const SizedBox(height: 8),
          Text(
            _getInstructionText(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getInstructionText() {
    final config = widget.question.configuration;

    switch (widget.question.questionMode) {
      case ScaleStripQuestionMode.construction:
        return 'Tap the positions to select the correct notes.';
      case ScaleStripQuestionMode.intervals:
        return 'Select the positions that correspond to the scale intervals.';
      case ScaleStripQuestionMode.notes:
        if (config.useDropdownSelection) {
          return 'Tap empty positions to select notes from the dropdown.';
        }
        return 'Tap positions to select the correct note names.';
      case ScaleStripQuestionMode.pattern:
        return 'Select notes that follow the specified pattern.';
    }
  }

  Widget _buildScaleStrip(double screenWidth, ThemeData theme) {
    final config = widget.question.configuration;
    final totalPositions = 12 * config.octaveCount;
    final availableWidth = screenWidth - 32;
    
    // Calculate optimal positioning
    const minPositionWidth = 28.0;
    const maxPositionWidth = 60.0;
    final idealWidth = availableWidth / totalPositions;
    
    // Determine if we need scrolling or wrapping
    final needsScrolling = idealWidth < minPositionWidth;
    final positionWidth = needsScrolling 
        ? minPositionWidth 
        : idealWidth.clamp(minPositionWidth, maxPositionWidth);

    return Container(
      width: availableWidth,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: needsScrolling 
          ? _buildScrollableStrip(totalPositions, positionWidth, theme)
          : _buildFixedStrip(totalPositions, positionWidth, theme),
    );
  }

  Widget _buildScrollableStrip(int totalPositions, double positionWidth, ThemeData theme) {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(totalPositions, (index) {
              return _buildScalePosition(index, positionWidth, theme);
            }),
          ),
        ),
        // Scroll indicator
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe_left,
                  size: 12,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 2),
                Text(
                  'Scroll',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedStrip(int totalPositions, double positionWidth, ThemeData theme) {
    return Row(
      children: List.generate(totalPositions, (index) {
        return _buildScalePosition(index, positionWidth, theme);
      }),
    );
  }

  Widget _buildScalePosition(int position, double width, ThemeData theme) {
    final config = widget.question.configuration;
    final positionInOctave = position % 12;
    final octave = position ~/ 12;

    final isSelected = _selectedPositions.contains(position);
    final isPreHighlighted = config.preHighlightedPositions.contains(position);
    final isCorrect = widget.showCorrectAnswer &&
                     widget.question.correctAnswer.selectedPositions.contains(position);
    final isLocked = _isPositionLocked(position);
    final isReference = config.showFirstNoteAsReference &&
                       config.firstNotePosition == position;

    // Determine colors
    Color backgroundColor;
    Color textColor = theme.colorScheme.onSurface;

    if (isCorrect && widget.showCorrectAnswer) {
      backgroundColor = Colors.green.withOpacity(0.8);
      textColor = Colors.white;
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.8);
      textColor = Colors.white;
    } else if (isReference) {
      backgroundColor = Colors.orange.withOpacity(0.3);
    } else if (isPreHighlighted) {
      backgroundColor = theme.colorScheme.secondary.withOpacity(0.3);
    } else {
      backgroundColor = theme.colorScheme.surface;
    }

    // Determine display text
    String displayText = '';
    if (config.showNoteLabels || (config.showPreHighlightedLabels && isPreHighlighted)) {
      final noteName = _getNoteNameForPosition(positionInOctave);
      displayText = config.octaveCount > 1 ? '$noteName$octave' : noteName;
    } else if (config.showIntervalLabels) {
      displayText = _getIntervalLabel(positionInOctave);
    } else if (config.useDropdownSelection && !isPreHighlighted) {
      displayText = _dropdownSelections[position] ?? '?';
    }

    // Override with reference label if specified
    if (isReference && config.referenceNoteLabel != null) {
      displayText = config.referenceNoteLabel!;
    }

    // Adjust font size based on width
    double fontSize;
    if (width >= 50) {
      fontSize = 12;
    } else if (width >= 35) {
      fontSize = 10;
    } else {
      fontSize = 8;
    }

    return GestureDetector(
      onTap: isLocked ? null : () => _onPositionTapped(position),
      child: Container(
        width: width,
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: isSelected || isReference ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
            textAlign: TextAlign.center,
            maxLines: width < 30 ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: widget.enabled ? _clearSelection : null,
          icon: const Icon(Icons.clear, size: 16),
          label: const Text('Clear'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceVariant,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Selected: ${_selectedPositions.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (_selectedNotes.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notes: ${_selectedNotes.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnswerFeedback(ThemeData theme) {
    final correctAnswer = widget.question.correctAnswer;
    final isCorrect = setEquals(_selectedPositions, correctAnswer.selectedPositions);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.info,
                color: isCorrect ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Correct answer:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCorrect ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${correctAnswer.selectedNotes.join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Positions: ${correctAnswer.selectedPositions.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}