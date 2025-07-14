import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/question_models.dart';

/// View for displaying multiple choice questions
class MultipleChoiceView extends StatefulWidget {
  final MultipleChoiceQuestion question;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;
  final bool showFeedback;
  final bool? isCorrect;

  const MultipleChoiceView({
    Key? key,
    required this.question,
    this.selectedAnswer,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.isCorrect,
  }) : super(key: key);

  @override
  State<MultipleChoiceView> createState() => _MultipleChoiceViewState();
}

class _MultipleChoiceViewState extends State<MultipleChoiceView>
    with SingleTickerProviderStateMixin {
  late List<String> _choices;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _generateChoices();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _generateChoices() {
    // Get the correct answer (randomly pick from variations)
    final random = math.Random();
    final allCorrectAnswers = widget.question.allCorrectAnswers;
    final correctAnswer = allCorrectAnswers[
      random.nextInt(allCorrectAnswers.length)
    ];

    // Get incorrect answers
    final incorrectPool = List<String>.from(widget.question.incorrectAnswerPool);
    incorrectPool.shuffle(random);
    
    final numIncorrect = widget.question.numberOfChoices - 1;
    final incorrectAnswers = incorrectPool.take(
      math.min(numIncorrect, incorrectPool.length)
    ).toList();

    // Combine and shuffle if needed
    _choices = [correctAnswer, ...incorrectAnswers];
    if (widget.question.shuffleAnswers) {
      _choices.shuffle(random);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuestionHeader(theme),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildQuestionText(theme),
                const SizedBox(height: 32),
                _buildAnswerChoices(theme),
                if (widget.showFeedback && widget.selectedAnswer != null) ...[
                  const SizedBox(height: 24),
                  _buildFeedback(theme),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.quiz_outlined,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Multiple Choice',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.question.pointValue.toInt()} ${widget.question.pointValue == 1 ? 'point' : 'points'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionText(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          widget.question.text,
          style: theme.textTheme.titleLarge?.copyWith(
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnswerChoices(ThemeData theme) {
    return Column(
      children: _choices.asMap().entries.map((entry) {
        final index = entry.key;
        final choice = entry.value;
        final isSelected = choice == widget.selectedAnswer;
        final isCorrectChoice = widget.question.allCorrectAnswers.contains(choice);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildAnswerChoice(
            choice: choice,
            index: index,
            isSelected: isSelected,
            isCorrect: isCorrectChoice,
            theme: theme,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnswerChoice({
    required String choice,
    required int index,
    required bool isSelected,
    required bool isCorrect,
    required ThemeData theme,
  }) {
    final showResult = widget.showFeedback && widget.selectedAnswer != null;
    final shouldHighlightCorrect = showResult && isCorrect;
    final shouldShowIncorrect = showResult && isSelected && !isCorrect;

    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;
    IconData? icon;

    if (shouldHighlightCorrect) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (shouldShowIncorrect) {
      backgroundColor = theme.colorScheme.error.withOpacity(0.1);
      borderColor = theme.colorScheme.error;
      textColor = theme.colorScheme.error;
      icon = Icons.cancel;
    } else if (isSelected && !showResult) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
      borderColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.primary;
    }

    Widget choiceCard = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: widget.showFeedback ? null : () {
          if (widget.selectedAnswer == null) {
            widget.onAnswerSelected(choice);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor ?? theme.colorScheme.outline,
              width: isSelected || shouldHighlightCorrect ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor ?? theme.colorScheme.surface,
                  border: Border.all(
                    color: borderColor ?? theme.colorScheme.outline,
                  ),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  choice,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, color: borderColor, size: 24),
            ],
          ),
        ),
      ),
    );

    if (shouldShowIncorrect) {
      return AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: choiceCard,
      );
    }

    return choiceCard;
  }

  Widget _buildFeedback(ThemeData theme) {
    if (widget.isCorrect == null || widget.question.explanation == null) {
      return const SizedBox.shrink();
    }

    final isCorrect = widget.isCorrect!;
    if (!isCorrect && _shakeController.status != AnimationStatus.completed) {
      _shakeController.forward();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : theme.colorScheme.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.info_outline,
                color: isCorrect ? Colors.green : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Not quite right',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isCorrect ? Colors.green.shade700 : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.question.explanation!,
            style: theme.textTheme.bodyMedium,
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Correct answer: ${widget.question.correctAnswer}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}