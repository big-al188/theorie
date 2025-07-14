import 'package:flutter/material.dart';
import '../../../models/question_models.dart';
import '../../../models/quiz_enums.dart';
import '../widgets/quiz_scale_strip.dart';
import '../widgets/quiz_fretboard.dart';

/// View for displaying interactive questions (scale, chord, etc.)
class InteractiveQuestionView extends StatefulWidget {
  final Question question;
  final dynamic previousAnswer;
  final Function(dynamic) onAnswerSubmit;
  final bool showFeedback;
  final String? feedback;

  const InteractiveQuestionView({
    Key? key,
    required this.question,
    this.previousAnswer,
    required this.onAnswerSubmit,
    this.showFeedback = false,
    this.feedback,
  }) : super(key: key);

  @override
  State<InteractiveQuestionView> createState() => _InteractiveQuestionViewState();
}

class _InteractiveQuestionViewState extends State<InteractiveQuestionView> {
  late Map<String, dynamic> _currentState;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    if (widget.previousAnswer != null) {
      _currentState = Map<String, dynamic>.from(widget.previousAnswer);
    } else if (widget.question is ScaleInteractiveQuestion) {
      final scaleQuestion = widget.question as ScaleInteractiveQuestion;
      _currentState = Map<String, dynamic>.from(scaleQuestion.initialState);
    } else if (widget.question is ChordInteractiveQuestion) {
      final chordQuestion = widget.question as ChordInteractiveQuestion;
      _currentState = Map<String, dynamic>.from(chordQuestion.initialState);
    } else {
      _currentState = {};
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
                _buildInteractiveWidget(theme),
                if (!widget.showFeedback && _hasChanges) ...[
                  const SizedBox(height: 24),
                  _buildSubmitButton(theme),
                ],
                if (widget.showFeedback && widget.feedback != null) ...[
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
    String typeLabel = '';
    IconData icon = Icons.music_note;
    
    if (widget.question is ScaleInteractiveQuestion) {
      typeLabel = 'Scale Exercise';
      icon = Icons.piano;
    } else if (widget.question is ChordInteractiveQuestion) {
      typeLabel = 'Chord Exercise';
      icon = Icons.music_note_outlined;
    }

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          typeLabel,
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
        child: Column(
          children: [
            Text(
              widget.question.text,
              style: theme.textTheme.titleLarge?.copyWith(
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.question is ScaleInteractiveQuestion) ...[
              const SizedBox(height: 12),
              _buildScaleInfo(widget.question as ScaleInteractiveQuestion, theme),
            ] else if (widget.question is ChordInteractiveQuestion) ...[
              const SizedBox(height: 12),
              _buildChordInfo(widget.question as ChordInteractiveQuestion, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScaleInfo(ScaleInteractiveQuestion question, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Chip(
          label: Text('${question.scaleKey} ${question.scaleType}'),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(_getInteractionModeLabel(question.interactionMode)),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      ],
    );
  }

  Widget _buildChordInfo(ChordInteractiveQuestion question, ThemeData theme) {
    return Chip(
      label: Text(question.chordName),
      backgroundColor: theme.colorScheme.primaryContainer,
    );
  }

  Widget _buildInteractiveWidget(ThemeData theme) {
    if (widget.question is ScaleInteractiveQuestion) {
      return _buildScaleWidget(widget.question as ScaleInteractiveQuestion, theme);
    } else if (widget.question is ChordInteractiveQuestion) {
      return _buildChordWidget(widget.question as ChordInteractiveQuestion, theme);
    }
    
    return Center(
      child: Text(
        'Interactive widget not implemented for ${widget.question.runtimeType}',
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildScaleWidget(ScaleInteractiveQuestion question, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: QuizScaleStrip(
        scaleKey: question.scaleKey,
        scaleType: question.scaleType,
        displayMode: question.displayMode,
        interactionMode: question.interactionMode,
        initialState: _currentState,
        isReadOnly: widget.showFeedback,
        expectedAnswer: widget.showFeedback ? question.expectedAnswer : null,
        onStateChanged: (newState) {
          setState(() {
            _currentState = newState;
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Widget _buildChordWidget(ChordInteractiveQuestion question, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: QuizFretboard(
        chordName: question.chordName,
        fretboardMode: question.fretboardMode,
        initialState: _currentState,
        isReadOnly: widget.showFeedback,
        acceptablePositions: widget.showFeedback ? question.acceptablePositions : null,
        onStateChanged: (newState) {
          setState(() {
            _currentState = newState;
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _hasChanges ? () => widget.onAnswerSubmit(_currentState) : null,
      icon: const Icon(Icons.check),
      label: const Text('Submit Answer'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildFeedback(ThemeData theme) {
    if (widget.feedback == null) return const SizedBox.shrink();

    // Parse feedback to determine if correct
    final isCorrect = widget.feedback!.toLowerCase().contains('correct') ||
                     widget.feedback!.toLowerCase().contains('perfect');

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
              Expanded(
                child: Text(
                  widget.feedback!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCorrect 
                        ? Colors.green.shade700 
                        : theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          if (widget.question.explanation != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.question.explanation!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _getInteractionModeLabel(ScaleInteractionMode mode) {
    switch (mode) {
      case ScaleInteractionMode.fillNotes:
        return 'Fill in notes';
      case ScaleInteractionMode.fillIntervals:
        return 'Fill in intervals';
      case ScaleInteractionMode.highlight:
        return 'Highlight';
      case ScaleInteractionMode.construct:
        return 'Build scale';
      default:
        return mode.toString().split('.').last;
    }
  }
}