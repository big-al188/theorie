// lib/views/widgets/quiz/quiz_progress_bar.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget that displays quiz progress with optional time tracking
///
/// This widget shows:
/// - Question progress (current/total)
/// - Visual progress bar
/// - Optional time remaining countdown
/// - Animated transitions between states
class QuizProgressBar extends StatefulWidget {
  const QuizProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.timeRemaining,
    this.showPercentage = true,
    this.showQuestionNumbers = true,
    this.showTimeWarning = true,
    this.lowTimeThreshold = const Duration(minutes: 2),
    this.criticalTimeThreshold = const Duration(minutes: 1),
  });

  /// Current question number (1-based)
  final int current;

  /// Total number of questions
  final int total;

  /// Time remaining in the quiz (null if no time limit)
  final Duration? timeRemaining;

  /// Whether to show percentage completion
  final bool showPercentage;

  /// Whether to show "X of Y" question numbers
  final bool showQuestionNumbers;

  /// Whether to show warning for low time
  final bool showTimeWarning;

  /// Threshold for showing low time warning
  final Duration lowTimeThreshold;

  /// Threshold for showing critical time warning
  final Duration criticalTimeThreshold;

  @override
  State<QuizProgressBar> createState() => _QuizProgressBarState();
}

class _QuizProgressBarState extends State<QuizProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _updateProgress();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticInOut,
    ));
  }

  void _updateProgress() {
    final newProgress = widget.current / widget.total;

    if (newProgress != _previousProgress) {
      _progressController.reset();
      _progressController.forward();

      // Pulse animation for progress updates
      if (newProgress > _previousProgress) {
        _pulseController.reset();
        _pulseController.forward();
      }

      _previousProgress = newProgress;
    }
  }

  @override
  void didUpdateWidget(QuizProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.current != widget.current ||
        oldWidget.total != widget.total) {
      _updateProgress();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProgressHeader(context),
        const SizedBox(height: 12),
        _buildProgressBar(context),
        if (widget.timeRemaining != null) ...[
          const SizedBox(height: 12),
          _buildTimeDisplay(context),
        ],
      ],
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.showQuestionNumbers)
          ScaleTransition(
            scale: _pulseAnimation,
            child: Text(
              'Question ${widget.current} of ${widget.total}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        if (widget.showPercentage)
          Text(
            '${(_previousProgress * 100).round()}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value * _previousProgress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context) {
    final timeRemaining = widget.timeRemaining!;
    final isLowTime = timeRemaining <= widget.lowTimeThreshold;
    final isCriticalTime = timeRemaining <= widget.criticalTimeThreshold;

    Color timeColor = Colors.grey.shade600;
    IconData timeIcon = Icons.schedule;

    if (widget.showTimeWarning) {
      if (isCriticalTime) {
        timeColor = Colors.red;
        timeIcon = Icons.warning;
      } else if (isLowTime) {
        timeColor = Colors.orange;
        timeIcon = Icons.schedule;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: timeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            timeIcon,
            size: 16,
            color: timeColor,
          ),
          const SizedBox(width: 6),
          Text(
            _formatDuration(timeRemaining),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: timeColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (isCriticalTime) ...[
            const SizedBox(width: 6),
            _buildPulsingDot(timeColor),
          ],
        ],
      ),
    );
  }

  Widget _buildPulsingDot(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
