// lib/views/widgets/quiz/question_widget.dart

import 'package:flutter/material.dart';
import '../../../models/quiz/quiz_question.dart';
import '../../../models/quiz/multiple_choice_question.dart';
import '../../../models/quiz/scale_strip_question.dart';
import 'multiple_choice_widget.dart';
import 'scale_strip_question_widget.dart';

/// Centralized widget for rendering all question types
/// 
/// This widget acts as a factory that routes different question types
/// to their appropriate specialized widgets, providing a single point
/// of integration for the quiz system.
class QuestionWidget extends StatelessWidget {
  const QuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.onAnswerSelected,
    this.showCorrectAnswer = false,
    this.enabled = true,
    this.showQuestionText = true,
  });

  final QuizQuestion question;
  final dynamic selectedAnswer;
  final ValueChanged<dynamic>? onAnswerSelected;
  final bool showCorrectAnswer;
  final bool enabled;
  final bool showQuestionText;

  @override
  Widget build(BuildContext context) {
    // Route to appropriate widget based on question type
    switch (question.type) {
      case QuestionType.multipleChoice:
        if (question is MultipleChoiceQuestion) {
          return MultipleChoiceWidget(
            question: question as MultipleChoiceQuestion,
            selectedAnswer: selectedAnswer,
            onAnswerSelected: onAnswerSelected,
            showCorrectAnswer: showCorrectAnswer,
            enabled: enabled,
            showQuestionText: showQuestionText,
          );
        } else {
          return _buildErrorWidget(
            context, 
            'Question type mismatch: expected MultipleChoiceQuestion, got ${question.runtimeType}'
          );
        }

      case QuestionType.scaleStrip:
        if (question is ScaleStripQuestion) {
          return ScaleStripQuestionWidget(
            question: question as ScaleStripQuestion,
            selectedAnswer: selectedAnswer,
            onAnswerSelected: onAnswerSelected,
            showCorrectAnswer: showCorrectAnswer,
            enabled: enabled,
            // Note: ScaleStripQuestionWidget doesn't support showQuestionText parameter
          );
        } else {
          return _buildErrorWidget(
            context, 
            'Question type mismatch: expected ScaleStripQuestion, got ${question.runtimeType}'
          );
        }

      case QuestionType.interactive:
      case QuestionType.trueFalse:
      case QuestionType.fillInBlank:
        return _buildNotImplementedWidget(context, question.type);

      default:
        return _buildErrorWidget(
          context,
          'Unknown question type: ${question.type}'
        );
    }
  }

  /// Build widget for not-yet-implemented question types
  Widget _buildNotImplementedWidget(BuildContext context, QuestionType type) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: Colors.orange.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Coming Soon!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Question type "${type.displayName}" is under development.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.orange.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build widget for error states
  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Question Error',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}