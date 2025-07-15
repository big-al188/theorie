// lib/views/widgets/quiz/multiple_choice_widget.dart

import 'package:flutter/material.dart';
import '../../../models/quiz/multiple_choice_question.dart';
import '../../../models/quiz/quiz_question.dart'; // Add this import

/// Widget for displaying and interacting with multiple choice questions
///
/// This widget handles the presentation of multiple choice questions including:
/// - Question text display
/// - Option selection (single or multiple)
/// - Visual feedback for selected/correct/incorrect answers
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(MultipleChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize if question changed
    if (oldWidget.question.id != widget.question.id) {
      _initializeOptions();
      _initializeSelection();
      _animationController.reset();
      _animationController.forward();
    }

    // Update selection if selectedAnswer changed
    if (oldWidget.selectedAnswer != widget.selectedAnswer) {
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
          _buildQuestionHeader(context),
          const SizedBox(height: 24),
          _buildOptions(context),
          if (widget.showExplanation &&
              widget.question.explanation != null) ...[
            const SizedBox(height: 24),
            _buildExplanation(context),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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

            // Selection instruction
            if (widget.question.multiSelect) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Select all correct answers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ],
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
      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
    );
  }

  Widget _buildDifficultyChip(BuildContext context) {
    final difficulty = widget.question.difficulty;
    Color color;
    switch (difficulty) {
      case QuestionDifficulty.beginner:
        color = Colors.green;
        break;
      case QuestionDifficulty.intermediate:
        color = Colors.orange;
        break;
      case QuestionDifficulty.advanced:
        color = Colors.red;
        break;
      case QuestionDifficulty.expert:
        color = Colors.purple;
        break;
    }

    return Chip(
      label: Text(
        difficulty.name.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildPointValue(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${widget.question.pointValue} pts',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
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
    final showResult = widget.showCorrectAnswer;

    // Determine colors and styling
    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;
    IconData? trailingIcon;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
        trailingIcon = Icons.check_circle;
      } else if (isSelected) {
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
        trailingIcon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
      borderColor = Theme.of(context).primaryColor;
      textColor = Theme.of(context).primaryColor;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.enabled && !showResult
              ? () => _handleOptionTap(option)
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: borderColor ?? Colors.grey.shade300,
                width: isSelected || (showResult && isCorrect) ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: widget.question.multiSelect
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    borderRadius: widget.question.multiSelect
                        ? BorderRadius.circular(4)
                        : null,
                    border: Border.all(
                      color: borderColor ?? Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected
                        ? (borderColor ?? Theme.of(context).primaryColor)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          widget.question.multiSelect
                              ? Icons.check
                              : Icons.circle,
                          size: widget.question.multiSelect ? 16 : 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Option text
                Expanded(
                  child: Text(
                    option.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor,
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
