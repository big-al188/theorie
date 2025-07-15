// lib/views/widgets/quiz/multiple_choice_widget.dart

import 'package:flutter/material.dart';
import '../../../models/quiz/multiple_choice_question.dart';
import '../../../models/quiz/quiz_question.dart';

/// Widget for displaying and interacting with multiple choice questions
///
/// FIXED: Enhanced for UI stability - minimizes rebuilds and layout shifts
/// during answer selection to provide a smooth user experience.
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

  // FIXED: Stable selection state management
  Set<String> _selectedOptionIds = {};
  Set<String> _lastNotifiedSelection = {};

  // FIXED: Animation controller for subtle feedback only
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _initializeSelection();
    _setupFeedbackAnimation();
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

    _lastNotifiedSelection = Set<String>.from(_selectedOptionIds);
  }

  // FIXED: Minimal animation setup for subtle feedback
  void _setupFeedbackAnimation() {
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this as TickerProvider,
    );

    _feedbackAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(MultipleChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only reinitialize if question actually changed
    if (oldWidget.question.id != widget.question.id) {
      _initializeOptions();
      _initializeSelection();
    } else if (oldWidget.selectedAnswer != widget.selectedAnswer) {
      // FIXED: Only update selection state, don't rebuild entire widget
      _initializeSelection();
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED: Static question header - doesn't change during selection
        _buildStaticQuestionHeader(context),
        const SizedBox(height: 24),

        // FIXED: Stable options list with minimal rebuilds
        _buildStableOptionsList(context),

        // FIXED: Static explanation section
        if (widget.showExplanation && widget.question.explanation != null) ...[
          const SizedBox(height: 24),
          _buildStaticExplanation(context),
        ],
      ],
    );
  }

  // FIXED: Static header that doesn't rebuild during selection
  Widget _buildStaticQuestionHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.multiSelect
                  ? 'Select all that apply:'
                  : 'Select the best answer:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (widget.question.questionText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.question.questionText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // FIXED: Stable options list that minimizes rebuilds
  Widget _buildStableOptionsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _displayOptions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = _displayOptions[index];
        return _buildStableOptionTile(context, option);
      },
    );
  }

  // FIXED: Stable option tile with efficient state management
  Widget _buildStableOptionTile(BuildContext context, AnswerOption option) {
    final isSelected = _selectedOptionIds.contains(option.id);
    final isCorrect = option.isCorrect;
    final showResult = widget.showCorrectAnswer;

    // FIXED: Determine styling efficiently
    final styling =
        _getOptionStyling(context, isSelected, isCorrect, showResult);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.enabled && !showResult
              ? () => _handleOptionSelection(option)
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: styling.backgroundColor,
              border: Border.all(
                color: styling.borderColor,
                width: styling.borderWidth,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // FIXED: Stable selection indicator
                _buildSelectionIndicator(styling, isSelected),
                const SizedBox(width: 16),

                // FIXED: Stable option text
                Expanded(
                  child: Text(
                    option.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: styling.textColor,
                          fontWeight: isSelected ? FontWeight.w500 : null,
                        ),
                  ),
                ),

                // FIXED: Result icon (only when showing results)
                if (showResult && styling.trailingIcon != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    styling.trailingIcon,
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

  // FIXED: Stable selection indicator that doesn't cause layout shifts
  Widget _buildSelectionIndicator(_OptionStyling styling, bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape:
            widget.question.multiSelect ? BoxShape.rectangle : BoxShape.circle,
        borderRadius:
            widget.question.multiSelect ? BorderRadius.circular(4) : null,
        border: Border.all(
          color: styling.borderColor,
          width: 2,
        ),
        color: isSelected ? styling.borderColor : null,
      ),
      child: isSelected
          ? Icon(
              widget.question.multiSelect ? Icons.check : Icons.circle,
              size: widget.question.multiSelect ? 16 : 12,
              color: Colors.white,
            )
          : null,
    );
  }

  // FIXED: Static explanation that doesn't rebuild
  Widget _buildStaticExplanation(BuildContext context) {
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

  // FIXED: Efficient option selection handling
  void _handleOptionSelection(AnswerOption option) {
    // Provide immediate visual feedback
    _feedbackController.forward().then((_) {
      _feedbackController.reverse();
    });

    setState(() {
      if (widget.question.multiSelect) {
        // Multi-select logic
        if (_selectedOptionIds.contains(option.id)) {
          _selectedOptionIds.remove(option.id);
        } else {
          _selectedOptionIds.add(option.id);
        }
      } else {
        // Single select logic
        _selectedOptionIds.clear();
        _selectedOptionIds.add(option.id);
      }
    });

    // FIXED: Only notify parent if selection actually changed
    if (!_selectedOptionIds.setEquals(_lastNotifiedSelection)) {
      _lastNotifiedSelection = Set<String>.from(_selectedOptionIds);

      if (widget.question.multiSelect) {
        // Create list of selected options for multi-select
        final selectedOptions = _displayOptions
            .where((o) => _selectedOptionIds.contains(o.id))
            .toList();
        widget.onAnswerSelected?.call(selectedOptions);
      } else {
        // Return single option for single-select
        if (_selectedOptionIds.isNotEmpty) {
          final selectedOption = _displayOptions
              .firstWhere((o) => o.id == _selectedOptionIds.first);
          widget.onAnswerSelected?.call(selectedOption);
        }
      }
    }
  }

  // FIXED: Efficient styling calculation
  _OptionStyling _getOptionStyling(
    BuildContext context,
    bool isSelected,
    bool isCorrect,
    bool showResult,
  ) {
    Color? backgroundColor;
    Color borderColor = Colors.grey.shade300;
    double borderWidth = 1;
    Color? textColor;
    IconData? trailingIcon;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
        trailingIcon = Icons.check_circle;
        borderWidth = 2;
      } else if (isSelected) {
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
        trailingIcon = Icons.cancel;
        borderWidth = 2;
      }
    } else if (isSelected) {
      backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
      borderColor = Theme.of(context).primaryColor;
      textColor = Theme.of(context).primaryColor;
      borderWidth = 2;
    }

    return _OptionStyling(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      textColor: textColor,
      trailingIcon: trailingIcon,
    );
  }
}

// FIXED: Helper class for efficient styling calculations
class _OptionStyling {
  const _OptionStyling({
    this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    this.textColor,
    this.trailingIcon,
  });

  final Color? backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color? textColor;
  final IconData? trailingIcon;
}

// FIXED: Extension for set comparison
extension SetEquality<T> on Set<T> {
  bool setEquals(Set<T> other) {
    if (length != other.length) return false;
    return every(other.contains);
  }
}
