import 'package:flutter/material.dart';

/// Progress bar widget for quiz navigation
class QuizProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final double progress;
  final bool showLabels;
  final double height;

  const QuizProgressBar({
    Key? key,
    required this.current,
    required this.total,
    required this.progress,
    this.showLabels = true,
    this.height = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLabels) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question $current of $total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${progress.toStringAsFixed(0)}% Complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Stack(
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 8,
                width: MediaQuery.of(context).size.width * (progress / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Question dots
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: List.generate(total, (index) {
                        final isCompleted = index < current - 1;
                        final isCurrent = index == current - 1;
                        final dotPosition = (index + 0.5) / total;
                        
                        return Expanded(
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isCurrent ? 14 : 10,
                              height: isCurrent ? 14 : 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? colorScheme.primary
                                    : isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.surface,
                                border: Border.all(
                                  color: isCompleted || isCurrent
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                  width: isCurrent ? 2 : 1,
                                ),
                              ),
                              child: isCompleted
                                  ? Icon(
                                      Icons.check,
                                      size: 8,
                                      color: colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}