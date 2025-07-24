// lib/views/widgets/quiz/scale_strip_question_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/quiz/scale_strip_question.dart';
import '../../../models/music/note.dart';
import '../../../utils/music_utils.dart';

/// Enhanced scale strip question widget with improved layout and dropdown functionality
/// UPDATED: Added automatic root note selection and locked position handling
class ScaleStripQuestionWidget extends StatefulWidget {
  const ScaleStripQuestionWidget({
    Key? key,
    required this.question,
    this.selectedAnswer,
    this.onAnswerSelected,
    this.showCorrectAnswer = false,
    this.enabled = true,
  }) : super(key: key);

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
  late Map<int, String> _dropdownSelections;

  @override
  void initState() {
    super.initState();
    _initializeAnswer();
  }

  @override
  void didUpdateWidget(ScaleStripQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAnswer != widget.selectedAnswer) {
      _initializeAnswer();
    }
  }

  void _initializeAnswer() {
    final answer = widget.selectedAnswer;
    final config = widget.question.configuration;
    
    // NEW: Initialize with user selections only (exclude pre-highlighted positions)
    _selectedPositions = answer?.selectedPositions.toSet() ?? <int>{};
    
    // PRESERVED: Better initialization of dropdown selections
    _dropdownSelections = <int, String>{};
    
    if (answer?.selectedNotes != null && answer!.selectedNotes.isNotEmpty) {
      // For dropdown questions, we need to map notes back to positions
      final selectedNotesList = answer.selectedNotes.toList();
      
      // Try to match notes to their positions
      for (int position in _selectedPositions) {
        // Find the best matching note for this position
        final preferredNote = config.getPreferredNoteForPosition(position);
        
        // Look for exact match first
        if (selectedNotesList.contains(preferredNote)) {
          _dropdownSelections[position] = preferredNote;
          continue;
        }
        
        // Look for enharmonic equivalents
        bool found = false;
        for (final note in selectedNotesList) {
          if (_areEnharmonicallyEquivalent(note, preferredNote)) {
            _dropdownSelections[position] = note;
            found = true;
            break;
          }
        }
        
        // If no match found, use the first available note (fallback)
        if (!found && selectedNotesList.isNotEmpty) {
          _dropdownSelections[position] = selectedNotesList.first;
        }
      }
    }

    // Clear selections if configured to do so
    if (widget.question.configuration.clearSelectionOnStart) {
      _selectedPositions.clear();
      _dropdownSelections.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ENHANCED: Question instructions with auto-selection context
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // NEW: Show auto-selection info if applicable
              if (_hasAutoSelection()) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Root note automatically selected and locked',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Scale strip
        LayoutBuilder(
          builder: (context, constraints) {
            return _buildEnhancedScaleStrip(constraints.maxWidth, theme);
          },
        ),
        
        const SizedBox(height: 16),
        
        // ENHANCED: Control buttons with selection info
        _buildControlButtons(theme),
        
        // Answer feedback
        if (widget.showCorrectAnswer) ...[
          const SizedBox(height: 16),
          _buildAnswerFeedback(theme),
        ],
      ],
    );
  }

  /// NEW: Check if this question has automatic selection
  bool _hasAutoSelection() {
    final config = widget.question.configuration;
    return config.preHighlightedPositions.isNotEmpty && config.lockPreHighlighted;
  }

  /// ENHANCED: Instruction text with auto-selection context
  String _getInstructionText() {
    final config = widget.question.configuration;
    
    // NEW: Enhanced instructions for automatic root selection
    if (config.preHighlightedPositions.isNotEmpty && config.lockPreHighlighted) {
      switch (widget.question.questionMode) {
        case ScaleStripQuestionMode.intervals:
          return 'The root note is automatically selected and locked. Select the target interval position.';
        case ScaleStripQuestionMode.construction:
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
    
    // PRESERVED: Default instructions for questions without automatic selection
    switch (widget.question.questionMode) {
      case ScaleStripQuestionMode.construction:
        return 'Select the positions that correspond to the scale intervals.';
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

  Widget _buildEnhancedScaleStrip(double screenWidth, ThemeData theme) {
    final config = widget.question.configuration;
    final totalPositions = config.totalPositions;
    
    // Calculate optimal sizing for full screen width utilization
    const minPositionWidth = 32.0;
    const maxPositionWidth = 80.0;
    const horizontalPadding = 16.0;
    const stripPadding = 8.0;
    
    final availableWidth = screenWidth - (horizontalPadding * 2) - (stripPadding * 2);
    var positionWidth = availableWidth / totalPositions;
    
    // Clamp to reasonable bounds
    positionWidth = positionWidth.clamp(minPositionWidth, maxPositionWidth);
    
    // Determine if we need scrolling
    final totalRequiredWidth = totalPositions * positionWidth;
    final needsScrolling = totalRequiredWidth > availableWidth;
    
    return Container(
      width: screenWidth - (horizontalPadding * 2),
      height: 100,
      padding: const EdgeInsets.all(stripPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: needsScrolling 
          ? _buildScrollableStrip(totalPositions, positionWidth, theme)
          : _buildFixedStrip(totalPositions, positionWidth, availableWidth, theme),
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
        // Enhanced scroll indicator
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe_left,
                  size: 14,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Scroll',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedStrip(int totalPositions, double positionWidth, double availableWidth, ThemeData theme) {
    // If we have extra space, distribute it evenly
    final totalUsedWidth = totalPositions * positionWidth;
    final extraSpace = availableWidth - totalUsedWidth;
    final spacingBetween = extraSpace > 0 ? extraSpace / (totalPositions - 1) : 0;
    
    if (spacingBetween > 0) {
      // Use spaced layout
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(totalPositions, (index) {
          return _buildScalePosition(index, positionWidth, theme);
        }),
      );
    } else {
      // Use tight layout
      return Row(
        children: List.generate(totalPositions, (index) {
          return _buildScalePosition(index, positionWidth, theme);
        }),
      );
    }
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
    final isOctavePosition = position == 12; // Special handling for octave position

    // ENHANCED: Color logic with auto-selection styling
    Color backgroundColor;
    Color textColor = theme.colorScheme.onSurface;
    Color borderColor = theme.colorScheme.outline.withOpacity(0.3);
    
    // NEW: Add visual indicator for locked pre-highlighted positions
    bool showLockIndicator = isPreHighlighted && config.lockPreHighlighted;

    if (isCorrect && widget.showCorrectAnswer) {
      backgroundColor = Colors.green.withOpacity(0.8);
      textColor = Colors.white;
      borderColor = Colors.green;
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.8);
      textColor = theme.colorScheme.onPrimary;
      borderColor = theme.colorScheme.primary;
    } else if (isReference) {
      backgroundColor = Colors.orange.withOpacity(0.3);
      borderColor = Colors.orange;
    } else if (isPreHighlighted) {
      // NEW: Enhanced styling for auto-selected root notes
      backgroundColor = theme.colorScheme.secondary.withOpacity(0.6);
      textColor = theme.colorScheme.onSecondary;
      borderColor = theme.colorScheme.secondary;
    } else if (isOctavePosition) {
      // PRESERVED: Make octave position styling more consistent with other positions
      backgroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.primary.withOpacity(0.4);
    } else {
      backgroundColor = theme.colorScheme.surface;
    }

    // PRESERVED: Determine display text with proper root note handling
    String displayText = '';
    if (config.showNoteLabels || (config.showPreHighlightedLabels && isPreHighlighted)) {
      final noteName = _getNoteNameForPosition(position);
      displayText = config.octaveCount > 1 ? '$noteName$octave' : noteName;
    } else if (config.showIntervalLabels) {
      displayText = _getIntervalLabel(positionInOctave);
    } else if (config.useDropdownSelection && !isPreHighlighted) {
      // PRESERVED: Show selected note name instead of "?"
      displayText = _dropdownSelections[position] ?? '?';
    }

    // Override with reference label if specified
    if (isReference && config.referenceNoteLabel != null) {
      displayText = config.referenceNoteLabel!;
    }

    // Responsive font size
    double fontSize = _calculateFontSize(width);

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: GestureDetector(
        onTap: isLocked ? () => _showLockedPositionMessage(position) : () => _onPositionTapped(position),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor, 
              width: isOctavePosition ? 2.0 : 1.5,
            ),
            // NEW: Enhanced shadow for locked positions
            boxShadow: isSelected || isCorrect || showLockIndicator
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.3),
                      blurRadius: showLockIndicator ? 6 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (displayText.isNotEmpty)
                      Text(
                        displayText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    // Root indicator
                    if (position == 0 && config.highlightRoot)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: textColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    // PRESERVED: Improved octave indicator
                    if (isOctavePosition)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OCT',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: fontSize * 0.6,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // NEW: Lock indicator for pre-highlighted positions
              if (showLockIndicator)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 10,
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateFontSize(double width) {
    if (width >= 60) return 14;
    if (width >= 45) return 12;
    if (width >= 35) return 10;
    return 8;
  }

  bool _isPositionLocked(int position) {
    final config = widget.question.configuration;
    return !widget.enabled ||
           (config.lockPreHighlighted && config.preHighlightedPositions.contains(position)) ||
           (config.lockReferenceNote && config.firstNotePosition == position);
  }

  /// NEW: Show message when user tries to interact with locked position
  void _showLockedPositionMessage(int position) {
    final config = widget.question.configuration;
    final noteName = _getNoteNameForPosition(position);
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Root note $noteName is automatically selected and cannot be changed',
          style: const TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
    
    // Provide haptic feedback for locked interaction attempt
    HapticFeedback.mediumImpact();
  }

  void _onPositionTapped(int position) {
    if (!widget.enabled) return;

    final config = widget.question.configuration;

    if (config.useDropdownSelection && !config.preHighlightedPositions.contains(position)) {
      _showNoteSelectionDropdown(position);
    } else {
      _togglePositionSelection(position);
    }

    HapticFeedback.selectionClick();

    if (config.validateSelectionOnChange) {
      _validateSelection();
    }
  }

  void _showNoteSelectionDropdown(int position) {
    // PRESERVED: Show ALL possible note names, not just position-specific ones
    final allNotes = _getAllPossibleNoteNames();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select note for position ${position + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose the correct note for this position:'),
              const SizedBox(height: 16),
              ...allNotes.map((note) => ListTile(
                title: Text(note),
                onTap: () {
                  _selectNoteForPosition(position, note);
                  Navigator.of(context).pop();
                },
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // PRESERVED: Return ALL possible note names for educational purposes
  List<String> _getAllPossibleNoteNames() {
    return const [
      'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 
      'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B'
    ];
  }

  void _selectNoteForPosition(int position, String note) {
    setState(() {
      // PRESERVED: Properly update all state variables
      _dropdownSelections[position] = note;
      _selectedPositions.add(position);
    });
    // PRESERVED: Call notification after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyAnswerChange();
    });
  }

  void _togglePositionSelection(int position) {
    final config = widget.question.configuration;
    
    setState(() {
      if (_selectedPositions.contains(position)) {
        _selectedPositions.remove(position);
        _dropdownSelections.remove(position);
      } else {
        if (!config.allowMultipleSelection) {
          // Clear previous selections for single-select mode
          _selectedPositions.clear();
          _dropdownSelections.clear();
        }
        _selectedPositions.add(position);
        
        // Set note name if available
        final noteName = _getNoteNameForPosition(position);
        if (noteName.isNotEmpty) {
          _dropdownSelections[position] = noteName;
        }
      }
    });

    _notifyAnswerChange();
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
      _dropdownSelections.clear();
    });

    _notifyAnswerChange();
    HapticFeedback.selectionClick();
  }

  void _notifyAnswerChange() {
    // PRESERVED: Properly construct the answer with selected notes from dropdowns
    final selectedNotes = <String>{};
    
    // Only include notes for selected positions
    for (final position in _selectedPositions) {
      final note = _dropdownSelections[position];
      if (note != null && note != '?') {
        selectedNotes.add(note);
      }
    }
    
    // Debug logging for development
    if (mounted) {
      print('Answer update:');
      print('Selected positions: $_selectedPositions');
      print('Dropdown selections: $_dropdownSelections');
      print('Final selected notes: $selectedNotes');
    }
    
    final answer = ScaleStripAnswer(
      selectedPositions: _selectedPositions,
      selectedNotes: selectedNotes,
    );
    widget.onAnswerSelected?.call(answer);
  }

  /// PRESERVED: Get note name for position with proper root handling
  String _getNoteNameForPosition(int position) {
    final config = widget.question.configuration;
    
    if (position == 12) {
      // Octave position - same as root note
      return config.rootNote;
    }
    
    if (_dropdownSelections.containsKey(position)) {
      return _dropdownSelections[position]!;
    }
    
    // PRESERVED: Use proper key context for note naming
    return config.getPreferredNoteForPosition(position);
  }

  String _getIntervalLabel(int positionInOctave) {
    const intervalLabels = [
      '1', '♭2', '2', '♭3', '3', '4', '♭5', '5', '♭6', '6', '♭7', '7'
    ];
    return intervalLabels[positionInOctave % 12];
  }

  /// PRESERVED: Helper method to check enharmonic equivalence
  bool _areEnharmonicallyEquivalent(String note1, String note2) {
    try {
      final pc1 = Note.fromString(note1).pitchClass;
      final pc2 = Note.fromString(note2).pitchClass;
      return pc1 == pc2;
    } catch (e) {
      return false;
    }
  }

  /// ENHANCED: Control buttons with auto-selection info
  Widget _buildControlButtons(ThemeData theme) {
    final config = widget.question.configuration;
    final preHighlightedCount = config.preHighlightedPositions.length;
    final userSelectedCount = _selectedPositions.length;
    
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: widget.enabled ? _clearSelection : null,
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Clear'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceVariant,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        
        // NEW: Enhanced selection info with auto vs manual breakdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected: $userSelectedCount',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (preHighlightedCount > 0)
              Text(
                'Auto-selected: $preHighlightedCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        
        if (widget.question.configuration.keyContext != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Key: ${widget.question.configuration.keyContext}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnswerFeedback(ThemeData theme) {
    final correctPositions = widget.question.correctAnswer.selectedPositions;
    final userPositions = _selectedPositions;
    final missing = correctPositions.difference(userPositions);
    final extra = userPositions.difference(correctPositions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer Feedback',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (missing.isNotEmpty)
            Text(
              'Missing positions: ${missing.map((p) => p + 1).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
              ),
            ),
          if (extra.isNotEmpty)
            Text(
              'Extra positions: ${extra.map((p) => p + 1).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
              ),
            ),
          if (missing.isEmpty && extra.isEmpty)
            Text(
              'Perfect! All positions are correct.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}