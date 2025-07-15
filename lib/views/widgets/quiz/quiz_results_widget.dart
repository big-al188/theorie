// lib/views/widgets/quiz/quiz_results_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/quiz_controller.dart';
import '../../../models/quiz/quiz_result.dart';
import '../../../models/quiz/quiz_question.dart';
import 'dart:math' as math;

/// Widget that displays comprehensive quiz results
///
/// This widget shows:
/// - Overall score and grade
/// - Performance breakdown by topic
/// - Time statistics
/// - Question review
/// - Recommendations for improvement
class QuizResultsWidget extends StatefulWidget {
  const QuizResultsWidget({
    super.key,
    this.onRetakeQuiz,
    this.onBackToMenu,
    this.showDetailedReview = true,
  });

  /// Callback when user wants to retake the quiz
  final VoidCallback? onRetakeQuiz;

  /// Callback when user wants to go back to menu
  final VoidCallback? onBackToMenu;

  /// Whether to show detailed question review
  final bool showDetailedReview;

  @override
  State<QuizResultsWidget> createState() => _QuizResultsWidgetState();
}

class _QuizResultsWidgetState extends State<QuizResultsWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scoreController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scoreAnimation;

  bool _showDetailedStats = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _scoreController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizController>(
      builder: (context, controller, child) {
        // For this MVP, we'll simulate a result since we don't have
        // access to the actual QuizResult from the completed quiz
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResultsHeader(context, controller),
                  const SizedBox(height: 24),
                  _buildScoreCard(context, controller),
                  const SizedBox(height: 24),
                  _buildStatsToggle(context),
                  if (_showDetailedStats) ...[
                    const SizedBox(height: 16),
                    _buildDetailedStats(context, controller),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsHeader(BuildContext context, QuizController controller) {
    return Column(
      children: [
        Icon(
          Icons.emoji_events,
          size: 64,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Quiz Complete!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Great job completing the quiz',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, QuizController controller) {
    // Calculate mock results based on current performance
    final stats = controller.getCurrentPerformanceStats();
    final accuracy = (stats['accuracy'] as double? ?? 0.0);
    final scorePercentage = accuracy;
    final letterGrade = _calculateLetterGrade(scorePercentage);
    final passed = scorePercentage >= 0.7;

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score circle
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(120, 120),
                  painter: CircularScorePainter(
                    progress: _scoreAnimation.value * scorePercentage,
                    color: passed ? Colors.green : Colors.orange,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_scoreAnimation.value * scorePercentage * 100).round()}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: passed ? Colors.green : Colors.orange,
                              ),
                        ),
                        Text(
                          letterGrade,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: passed ? Colors.green : Colors.orange,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Pass/Fail status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: passed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: passed ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.warning,
                    color: passed ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    passed ? 'PASSED' : 'NEEDS IMPROVEMENT',
                    style: TextStyle(
                      color: passed ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  'Correct',
                  '${stats['questionsCorrect']} / ${stats['questionsAnswered']}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  'Time',
                  _formatTime(stats['timeElapsed'] as int? ?? 0),
                  Icons.schedule,
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  'Accuracy',
                  '${(accuracy * 100).round()}%',
                  Icons.precision_manufacturing,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildStatsToggle(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _showDetailedStats = !_showDetailedStats),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showDetailedStats ? 'Hide Details' : 'Show Detailed Stats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _showDetailedStats ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, QuizController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Topic performance (mock data for MVP)
            _buildTopicPerformance(context),
            const SizedBox(height: 16),

            // Recommendations
            _buildRecommendations(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicPerformance(BuildContext context) {
    // Mock topic data for MVP
    final topics = [
      {'name': 'Notes', 'score': 0.85, 'questions': 3},
      {'name': 'Intervals', 'score': 0.70, 'questions': 2},
      {'name': 'Chords', 'score': 0.90, 'questions': 2},
      {'name': 'Scales', 'score': 0.60, 'questions': 3},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By Topic',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...topics.map((topic) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTopicBar(
                context,
                topic['name'] as String,
                topic['score'] as double,
                topic['questions'] as int,
              ),
            )),
      ],
    );
  }

  Widget _buildTopicBar(
      BuildContext context, String name, double score, int questions) {
    final color = score >= 0.8
        ? Colors.green
        : (score >= 0.6 ? Colors.orange : Colors.red);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${(score * 100).round()}% ($questions questions)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _buildRecommendationItem(
          context,
          'Review scales theory',
          'Your performance on scales questions suggests reviewing major scale patterns',
          Icons.music_note,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildRecommendationItem(
          context,
          'Practice interval recognition',
          'Consider practicing interval identification exercises',
          Icons.hearing,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(BuildContext context, String title,
      String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onRetakeQuiz ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Quiz'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onBackToMenu ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home),
            label: const Text('Back to Menu'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _calculateLetterGrade(double score) {
    if (score >= 0.97) return 'A+';
    if (score >= 0.93) return 'A';
    if (score >= 0.90) return 'A-';
    if (score >= 0.87) return 'B+';
    if (score >= 0.83) return 'B';
    if (score >= 0.80) return 'B-';
    if (score >= 0.77) return 'C+';
    if (score >= 0.73) return 'C';
    if (score >= 0.70) return 'C-';
    if (score >= 0.67) return 'D+';
    if (score >= 0.63) return 'D';
    if (score >= 0.60) return 'D-';
    return 'F';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}

/// Custom painter for circular score display
class CircularScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircularScorePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
