// lib/views/widgets/quiz/multiple_choice_widget.dart

import 'package:flutter/material.dart';
import '../../../models/quiz/multiple_choice_question.dart';
import '../../../models/quiz/quiz_question.dart';

/// Widget for displaying and interacting with multiple choice questions
///
/// This widget handles the presentation of multiple choice questions including:
/// - Option selection (single or multiple)
/// - Visual feedback for selected/correct/incorrect answers
/// - Clean, non-redundant UI
/// - Accessibility support
class MultipleChoiceWidget extends StatefulWidget {
  const MultipleChoiceWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.onAnswerSelected,
    this.showCorrectAnswer = false,
    this.showExplanation = false,
    this.enabled = true,
    this.randomSeed,
    this.showQuestionText = false, // NEW: Control question text display
  });

  /// The multiple choice question to display
  final MultipleChoiceQuestion question;

  /// Currently selected answer(s)
  final dynamic selectedAnswer;

  /// Callback when an answer is selected
  final ValueChanged<dynamic>? onAnswerSelected;

  /// Whether to highlight the correct answer
  final bool showCorrectAnswer;

  /// Whether to show the explanation
  final bool showExplanation;

  /// Whether the widget accepts input
  final bool enabled;

  /// Optional seed for consistent option ordering
  final int? randomSeed;

  /// Whether to show the question text (to avoid duplication)
  final bool showQuestionText;

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget>
    with TickerProviderStateMixin {
  late List<AnswerOption> _displayOptions;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Selection state
  Set<String> _selectedOptionIds = {};

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _initializeSelection();
    _setupAnimations();
  }

  void _initializeOptions() {
    _displayOptions =
        widget.question.getDisplayOptions(seed: widget.randomSeed);
  }

  void _initializeSelection() {
    _selectedOptionIds.clear();

    if (widget.selectedAnswer != null) {
      if (widget.question.multiSelect) {
        // Handle multiple selection
        if (widget.selectedAnswer is List<AnswerOption>) {
          _selectedOptionIds.addAll(
            (widget.selectedAnswer as List<AnswerOption>).map((o) => o.id),
          );
        } else if (widget.selectedAnswer is List<String>) {
          _selectedOptionIds.addAll(widget.selectedAnswer as List<String>);
        } else if (widget.selectedAnswer is Set<AnswerOption>) {
          _selectedOptionIds.addAll(
            (widget.selectedAnswer as Set<AnswerOption>).map((o) => o.id),
          );
        } else if (widget.selectedAnswer is Set<String>) {
          _selectedOptionIds.addAll(widget.selectedAnswer as Set<String>);
        }
      } else {
        // Handle single selection
        if (widget.selectedAnswer is AnswerOption) {
          _selectedOptionIds.add((widget.selectedAnswer as AnswerOption).id);
        } else if (widget.selectedAnswer is String) {
          _selectedOptionIds.add(widget.selectedAnswer as String);
        }
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(MultipleChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedAnswer != widget.selectedAnswer) {
      _initializeSelection();
    }

    if (oldWidget.question != widget.question) {
      _initializeOptions();
      _initializeSelection();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header (only if requested)
          if (widget.showQuestionText) _buildQuestionHeader(context),

          // Selection instruction - always show this
          _buildSelectionInstruction(context),

          const SizedBox(height: 16),

          // Answer options
          _buildOptionsSection(context),

          // Explanation (if enabled)
          if (widget.showExplanation &&
              widget.question.explanation != null) ...[
            const SizedBox(height: 20),
            _buildExplanation(context),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question metadata
            Row(
              children: [
                _buildTopicChip(context),
                const SizedBox(width: 8),
                _buildDifficultyChip(context),
                const Spacer(),
                _buildPointValue(context),
              ],
            ),
            const SizedBox(height: 16),

            // Question text
            Text(
              widget.question.questionText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionInstruction(BuildContext context) {
    final isMultiSelect = widget.question.multiSelect;
    final icon = isMultiSelect ? Icons.checklist : Icons.radio_button_checked;
    final text =
        isMultiSelect ? 'Select all that apply' : 'Select the best answer';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    return Column(
      children: _displayOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Padding(
          padding: EdgeInsets.only(
              bottom: index < _displayOptions.length - 1 ? 12 : 0),
          child: _buildOptionTile(context, option),
        );
      }).toList(),
    );
  }

  Widget _buildOptionTile(BuildContext context, AnswerOption option) {
    final isSelected = _selectedOptionIds.contains(option.id);
    final isCorrect = option.isCorrect;
    final showResults = widget.showCorrectAnswer;

    Color? backgroundColor;
    Color? borderColor;
    IconData? trailingIcon;

    if (showResults) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        trailingIcon = Icons.check_circle;
      } else if (isSelected) {
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        trailingIcon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
      borderColor = Theme.of(context).primaryColor;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.grey.shade300,
          width: isSelected || showResults ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.enabled && !showResults
              ? () => _handleOptionTap(option)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection indicator
                if (widget.question.multiSelect)
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                  )
                else
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                  ),

                const SizedBox(width: 12),

                // Option text
                Expanded(
                  child: Text(
                    option.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w500 : null,
                        ),
                  ),
                ),

                // Result icon
                if (trailingIcon != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    trailingIcon,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicChip(BuildContext context) {
    return Chip(
      label: Text(
        widget.question.topic.name.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: Theme.of(context).primaryColor),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDifficultyChip(BuildContext context) {
    final difficulty = widget.question.difficulty;
    Color difficultyColor;

    switch (difficulty) {
      case QuestionDifficulty.beginner:
        difficultyColor = Colors.green;
        break;
      case QuestionDifficulty.intermediate:
        difficultyColor = Colors.orange;
        break;
      case QuestionDifficulty.advanced:
        difficultyColor = Colors.red;
        break;
      case QuestionDifficulty.expert:
        difficultyColor = Colors.purple;
        break;
    }

    return Chip(
      label: Text(
        difficulty.name.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: difficultyColor.withOpacity(0.1),
      labelStyle: TextStyle(color: difficultyColor),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPointValue(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.question.pointValue} pts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Explanation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.question.explanation!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _handleOptionTap(AnswerOption option) {
    setState(() {
      if (widget.question.multiSelect) {
        // Multi-select logic
        if (_selectedOptionIds.contains(option.id)) {
          _selectedOptionIds.remove(option.id);
        } else {
          _selectedOptionIds.add(option.id);
        }

        // Create list of selected options
        final selectedOptions = _displayOptions
            .where((o) => _selectedOptionIds.contains(o.id))
            .toList();

        widget.onAnswerSelected?.call(selectedOptions);
      } else {
        // Single select logic
        _selectedOptionIds.clear();
        _selectedOptionIds.add(option.id);

        widget.onAnswerSelected?.call(option);
      }
    });
  }
}
