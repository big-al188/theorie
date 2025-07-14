import 'package:flutter/material.dart';
import '../../../models/quiz_enums.dart';

/// Interactive scale strip widget for quiz questions
class QuizScaleStrip extends StatefulWidget {
  final String scaleKey;
  final String scaleType;
  final ScaleDisplayMode displayMode;
  final ScaleInteractionMode interactionMode;
  final Map<String, dynamic> initialState;
  final Map<String, dynamic>? expectedAnswer;
  final bool isReadOnly;
  final Function(Map<String, dynamic>)? onStateChanged;

  const QuizScaleStrip({
    Key? key,
    required this.scaleKey,
    required this.scaleType,
    required this.displayMode,
    required this.interactionMode,
    required this.initialState,
    this.expectedAnswer,
    this.isReadOnly = false,
    this.onStateChanged,
  }) : super(key: key);

  @override
  State<QuizScaleStrip> createState() => _QuizScaleStripState();
}

class _QuizScaleStripState extends State<QuizScaleStrip> {
  late Map<String, dynamic> _currentState;
  late List<String> _scaleNotes;
  late List<String> _intervals;
  final Map<int, TextEditingController> _textControllers = {};
  
  // Colors for visual feedback
  static const Color _correctColor = Colors.green;
  static const Color _incorrectColor = Colors.red;
  static const Color _neutralColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initializeScale();
    _currentState = Map<String, dynamic>.from(widget.initialState);
  }

  @override
  void dispose() {
    _textControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeScale() {
    // Initialize scale based on key and type
    _scaleNotes = _generateScaleNotes(widget.scaleKey, widget.scaleType);
    _intervals = _generateIntervals(widget.scaleType);
  }

  List<String> _generateScaleNotes(String key, String type) {
    // Simplified scale generation - in a real app, this would be more comprehensive
    final scales = {
      'C_major': ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'],
      'G_major': ['G', 'A', 'B', 'C', 'D', 'E', 'F#', 'G'],
      'D_major': ['D', 'E', 'F#', 'G', 'A', 'B', 'C#', 'D'],
      'F_major': ['F', 'G', 'A', 'Bb', 'C', 'D', 'E', 'F'],
      'A_minor': ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'A'],
      'E_chromatic': ['E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E'],
    };
    
    final scaleKey = '${key}_$type';
    return scales[scaleKey] ?? scales['C_major']!;
  }

  List<String> _generateIntervals(String type) {
    // Generate intervals based on scale type
    if (type == 'major' || type == 'minor') {
      return ['W', 'W', 'H', 'W', 'W', 'W', 'H'];
    } else if (type == 'chromatic') {
      return List.filled(11, 'H'); // All half steps
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInstructions(theme),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildScaleStrip(theme),
        ),
        if (widget.interactionMode == ScaleInteractionMode.construct) ...[
          const SizedBox(height: 16),
          _buildNoteSelector(theme),
        ],
      ],
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    String instruction = '';
    
    switch (widget.interactionMode) {
      case ScaleInteractionMode.fillNotes:
        instruction = 'Fill in the missing note names';
        break;
      case ScaleInteractionMode.fillIntervals:
        instruction = 'Fill in the intervals (W = Whole step, H = Half step)';
        break;
      case ScaleInteractionMode.highlight:
        instruction = 'Tap to highlight the requested notes';
        break;
      case ScaleInteractionMode.construct:
        instruction = 'Build the scale by selecting the correct notes';
        break;
      default:
        instruction = 'Study the scale pattern';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            instruction,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleStrip(ThemeData theme) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Build note positions
          for (int i = 0; i < _scaleNotes.length; i++) ...[
            _buildNotePosition(i, theme),
            if (i < _scaleNotes.length - 1) _buildInterval(i, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildNotePosition(int index, ThemeData theme) {
    final note = _scaleNotes[index];
    final isVisible = _isNoteVisible(index);
    final isHighlighted = _currentState['highlightedNotes']?.contains(index) ?? false;
    final isCorrect = _checkNoteCorrectness(index);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Note circle
        GestureDetector(
          onTap: !widget.isReadOnly ? () => _handleNoteTap(index) : null,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getNoteColor(isHighlighted, isCorrect, theme),
              border: Border.all(
                color: _getNoteBorderColor(isHighlighted, isCorrect, theme),
                width: 3,
              ),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: _buildNoteContent(index, note, isVisible, theme),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Scale degree
        Text(
          '${index + 1}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteContent(int index, String note, bool isVisible, ThemeData theme) {
    if (widget.interactionMode == ScaleInteractionMode.fillNotes && !isVisible) {
      // Text input for filling notes
      return SizedBox(
        width: 40,
        height: 30,
        child: TextField(
          controller: _getTextController(index),
          enabled: !widget.isReadOnly,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '?',
          ),
          onChanged: (value) => _handleNoteInput(index, value),
        ),
      );
    } else if (isVisible || widget.isReadOnly) {
      // Display note
      return Text(
        note,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      );
    } else {
      // Hidden note
      return Text(
        '?',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
  }

  Widget _buildInterval(int index, ThemeData theme) {
    final interval = _intervals[index];
    final isVisible = _isIntervalVisible(index);

    return Container(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.interactionMode == ScaleInteractionMode.fillIntervals && !isVisible)
            SizedBox(
              width: 30,
              height: 30,
              child: TextField(
                controller: _getTextController(100 + index), // Offset for intervals
                enabled: !widget.isReadOnly,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.zero,
                  hintText: '?',
                ),
                onChanged: (value) => _handleIntervalInput(index, value),
              ),
            )
          else if (isVisible || widget.isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                interval,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              '?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 4),
          // Interval line
          Container(
            height: 2,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSelector(ThemeData theme) {
    final availableNotes = _currentState['availableNotes'] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Notes:',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableNotes.map((note) {
            final isUsed = _currentState['notes']?.values.contains(note) ?? false;
            
            return ActionChip(
              label: Text(note),
              onPressed: !widget.isReadOnly && !isUsed
                  ? () => _selectNoteForConstruction(note)
                  : null,
              backgroundColor: isUsed
                  ? theme.colorScheme.surfaceVariant
                  : theme.colorScheme.secondaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isNoteVisible(int index) {
    if (widget.displayMode == ScaleDisplayMode.showAll) return true;
    
    final visibleNotes = _currentState['visibleNotes'] as List<String>? ?? [];
    final hiddenNotes = _currentState['hiddenNotes'] as List<String>? ?? [];
    
    if (widget.displayMode == ScaleDisplayMode.hideNotes) {
      return !hiddenNotes.contains(_scaleNotes[index]);
    }
    
    return visibleNotes.contains(_scaleNotes[index]);
  }

  bool _isIntervalVisible(int index) {
    if (widget.displayMode == ScaleDisplayMode.showAll) return true;
    if (widget.displayMode == ScaleDisplayMode.hideIntervals) return false;
    
    final visibleIntervals = _currentState['visibleIntervals'] as List<dynamic>? ?? [];
    return visibleIntervals.contains(index) || visibleIntervals.contains(_intervals[index]);
  }

  bool _checkNoteCorrectness(int index) {
    if (!widget.isReadOnly || widget.expectedAnswer == null) return true;
    
    final userNotes = _currentState['notes'] as Map<String, dynamic>? ?? {};
    final expectedNotes = widget.expectedAnswer!['notes'] as Map<String, dynamic>? ?? {};
    
    final userNote = userNotes[index.toString()];
    final expectedNote = expectedNotes[index.toString()];
    
    return userNote == expectedNote;
  }

  Color _getNoteColor(bool isHighlighted, bool isCorrect, ThemeData theme) {
    if (widget.isReadOnly && !isCorrect) {
      return _incorrectColor.withOpacity(0.2);
    }
    if (isHighlighted) {
      return theme.colorScheme.primary.withOpacity(0.2);
    }
    return theme.colorScheme.primaryContainer;
  }

  Color _getNoteBorderColor(bool isHighlighted, bool isCorrect, ThemeData theme) {
    if (widget.isReadOnly && !isCorrect) {
      return _incorrectColor;
    }
    if (isHighlighted) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.outline;
  }

  void _handleNoteTap(int index) {
    if (widget.interactionMode == ScaleInteractionMode.highlight) {
      setState(() {
        final highlighted = List<int>.from(_currentState['highlightedNotes'] ?? []);
        if (highlighted.contains(index)) {
          highlighted.remove(index);
        } else {
          highlighted.add(index);
        }
        _currentState['highlightedNotes'] = highlighted;
      });
      widget.onStateChanged?.call(_currentState);
    }
  }

  void _handleNoteInput(int index, String value) {
    setState(() {
      final notes = Map<String, dynamic>.from(_currentState['notes'] ?? {});
      notes[index.toString()] = value.toUpperCase();
      _currentState['notes'] = notes;
    });
    widget.onStateChanged?.call(_currentState);
  }

  void _handleIntervalInput(int index, String value) {
    setState(() {
      final intervals = Map<String, dynamic>.from(_currentState['intervals'] ?? {});
      intervals['$index-${index + 1}'] = value.toUpperCase();
      _currentState['intervals'] = intervals;
    });
    widget.onStateChanged?.call(_currentState);
  }

  void _selectNoteForConstruction(String note) {
    // Find next empty position
    final notes = Map<String, dynamic>.from(_currentState['notes'] ?? {});
    for (int i = 0; i < _scaleNotes.length; i++) {
      if (!notes.containsKey(i.toString())) {
        setState(() {
          notes[i.toString()] = note;
          _currentState['notes'] = notes;
        });
        widget.onStateChanged?.call(_currentState);
        break;
      }
    }
  }

  TextEditingController _getTextController(int key) {
    return _textControllers.putIfAbsent(
      key,
      () => TextEditingController(),
    );
  }
}