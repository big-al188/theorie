// lib/views/widgets/quiz/quiz_results_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/quiz_controller.dart';
import '../../../models/quiz/quiz_result.dart';
import '../../../models/quiz/quiz_question.dart';
import '../../../models/quiz/multiple_choice_question.dart';
import '../../../constants/quiz_constants.dart';
import 'dart:math' as math;

/// Widget that displays comprehensive quiz results
///
/// This widget shows:
/// - Overall score and grade
/// - Performance breakdown by topic
/// - Time statistics
/// - Detailed question review with missed questions and explanations
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
  bool _showQuestionReview = false;
  String _reviewFilter = 'all'; // 'all', 'incorrect', 'correct', 'skipped'

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
                  if (widget.showDetailedReview) ...[
                    const SizedBox(height: 24),
                    _buildQuestionReviewToggle(context, controller),
                    if (_showQuestionReview) ...[
                      const SizedBox(height: 16),
                      _buildQuestionReview(context, controller),
                    ],
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
    final result = controller.lastResult;

    if (result != null) {
      final scorePercentage = result.scorePercentage;
      final letterGrade = result.letterGrade;
      final passed = result.passed;

      return Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Score circle with actual data
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
              const SizedBox(height: 16),

              // Pass/Fail status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (passed ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: passed ? Colors.green : Colors.orange,
                    width: 1,
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

              // Quick stats with actual result data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    context,
                    'Correct',
                    '${result.questionsCorrect} / ${result.questionsAnswered}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    context,
                    'Time',
                    _formatDuration(result.timeSpent),
                    Icons.schedule,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    context,
                    'Accuracy',
                    '${(result.accuracy * 100).round()}%',
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

    // Fallback to current performance stats if no result yet
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
            const SizedBox(height: 16),

            // Quick stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  'Answered',
                  '${stats['answered'] ?? 0}',
                  Icons.quiz,
                  Colors.blue,
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
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
            _buildTopicPerformance(context, controller),
            const SizedBox(height: 16),
            _buildRecommendations(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicPerformance(
      BuildContext context, QuizController controller) {
    final result = controller.lastResult;

    if (result != null && result.topicPerformance.isNotEmpty) {
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
          ...result.topicPerformance.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTopicBar(
                  context,
                  topic.topic.displayName,
                  topic.scorePercentage,
                  topic.questionsAttempted,
                ),
              )),
        ],
      );
    }

    return const Text('No topic performance data available');
  }

  Widget _buildTopicBar(BuildContext context, String topicName, double score,
      int questionsAttempted) {
    final percentage = (score * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                topicName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Text(
              '$percentage% ($questionsAttempted questions)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            score >= 0.8 ? Colors.green : score >= 0.6 ? Colors.orange : Colors.red,
          ),
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
        const SizedBox(height: 8),
        const Text(
          '• Review topics with lower scores\n'
          '• Practice with additional quiz questions\n'
          '• Focus on areas where you spent more time\n'
          '• Retake the quiz to improve your score',
        ),
      ],
    );
  }

  // NEW: Toggle for question review section
  Widget _buildQuestionReviewToggle(BuildContext context, QuizController controller) {
    final result = controller.lastResult;
    if (result == null || result.questionResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final incorrectCount = result.incorrectQuestions.length;
    final skippedCount = result.skippedQuestions.length;

    return Card(
      child: InkWell(
        onTap: () => setState(() => _showQuestionReview = !_showQuestionReview),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.quiz,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question Review',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$incorrectCount missed • $skippedCount skipped',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _showQuestionReview ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Detailed question review section
  Widget _buildQuestionReview(BuildContext context, QuizController controller) {
    final result = controller.lastResult;
    if (result == null || result.questionResults.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No question details available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter tabs
            _buildQuestionFilters(context, result),
            const SizedBox(height: 16),
            
            // Filtered questions
            _buildFilteredQuestions(context, result),
          ],
        ),
      ),
    );
  }

  // NEW: Filter tabs for question review
  Widget _buildQuestionFilters(BuildContext context, QuizResult result) {
    final filters = [
      ('all', 'All Questions', result.questionResults.length),
      ('incorrect', 'Missed', result.incorrectQuestions.length),
      ('correct', 'Correct', result.questionResults.where((q) => q.isCorrect).length),
      ('skipped', 'Skipped', result.skippedQuestions.length),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _reviewFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${filter.$2} (${filter.$3})'),
              selected: isSelected,
              onSelected: (_) => setState(() => _reviewFilter = filter.$1),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  // NEW: Display filtered questions
  Widget _buildFilteredQuestions(BuildContext context, QuizResult result) {
    List<QuestionResultDetail> filteredQuestions;
    
    switch (_reviewFilter) {
      case 'incorrect':
        filteredQuestions = result.incorrectQuestions;
        break;
      case 'correct':
        filteredQuestions = result.questionResults.where((q) => q.isCorrect).toList();
        break;
      case 'skipped':
        filteredQuestions = result.skippedQuestions;
        break;
      default:
        filteredQuestions = result.questionResults;
    }

    if (filteredQuestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No questions to show for this filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      );
    }

    return Column(
      children: filteredQuestions.asMap().entries.map((entry) {
        final index = entry.key;
        final questionDetail = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildQuestionCard(context, questionDetail, index + 1),
        );
      }).toList(),
    );
  }

  // NEW: Individual question card with details
  Widget _buildQuestionCard(BuildContext context, QuestionResultDetail questionDetail, int questionNumber) {
    final question = questionDetail.question;
    final isCorrect = questionDetail.isCorrect;
    final wasSkipped = questionDetail.wasSkipped;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: wasSkipped 
              ? Colors.grey 
              : isCorrect 
                  ? Colors.green 
                  : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: wasSkipped 
                        ? Colors.grey 
                        : isCorrect 
                            ? Colors.green 
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      questionNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  wasSkipped 
                      ? Icons.skip_next 
                      : isCorrect 
                          ? Icons.check_circle 
                          : Icons.cancel,
                  color: wasSkipped 
                      ? Colors.grey 
                      : isCorrect 
                          ? Colors.green 
                          : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wasSkipped 
                        ? 'Skipped' 
                        : isCorrect 
                            ? 'Correct' 
                            : 'Incorrect',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: wasSkipped 
                              ? Colors.grey 
                              : isCorrect 
                                  ? Colors.green 
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  _formatDuration(questionDetail.timeSpent),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Question text
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Answer details for multiple choice questions
            if (question is MultipleChoiceQuestion) 
              _buildMultipleChoiceDetails(context, question, questionDetail),
            
            // Explanation
            if (question.explanation?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explanation',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.explanation!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // NEW: Display multiple choice answer details
  Widget _buildMultipleChoiceDetails(BuildContext context, MultipleChoiceQuestion question, QuestionResultDetail questionDetail) {
    final wasSkipped = questionDetail.wasSkipped;
    
    // Handle different types of user answers
    List<String> userAnswerIds = [];
    if (!wasSkipped && questionDetail.userAnswer != null) {
      final userAnswer = questionDetail.userAnswer;
      
      if (userAnswer is AnswerOption) {
        // Single select - userAnswer is a single AnswerOption
        userAnswerIds = [userAnswer.id];
      } else if (userAnswer is List<AnswerOption>) {
        // Multi-select - userAnswer is a List<AnswerOption>
        userAnswerIds = userAnswer.map((option) => option.id).toList();
      } else if (userAnswer is String) {
        // Single select - userAnswer is an option ID string
        userAnswerIds = [userAnswer];
      } else if (userAnswer is List<String>) {
        // Multi-select - userAnswer is a List<String> of option IDs
        userAnswerIds = userAnswer;
      } else if (userAnswer is List) {
        // Handle generic List and try to extract IDs
        userAnswerIds = userAnswer.map((item) {
          if (item is AnswerOption) {
            return item.id;
          } else if (item is String) {
            return item;
          } else {
            return item.toString();
          }
        }).toList();
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.options.map((option) {
        final isCorrect = option.isCorrect;
        final wasSelected = userAnswerIds.contains(option.id);
        
        Color backgroundColor;
        Color borderColor;
        IconData? icon;
        
        if (wasSkipped) {
          backgroundColor = Colors.grey.withOpacity(0.1);
          borderColor = Colors.grey.withOpacity(0.3);
          icon = isCorrect ? Icons.check_circle : null;
        } else if (isCorrect && wasSelected) {
          // Correct answer that was selected
          backgroundColor = Colors.green.withOpacity(0.1);
          borderColor = Colors.green;
          icon = Icons.check_circle;
        } else if (isCorrect && !wasSelected) {
          // Correct answer that wasn't selected
          backgroundColor = Colors.green.withOpacity(0.05);
          borderColor = Colors.green.withOpacity(0.5);
          icon = Icons.check_circle_outline;
        } else if (!isCorrect && wasSelected) {
          // Incorrect answer that was selected
          backgroundColor = Colors.red.withOpacity(0.1);
          borderColor = Colors.red;
          icon = Icons.cancel;
        } else {
          // Incorrect answer that wasn't selected
          backgroundColor = Colors.transparent;
          borderColor = Colors.grey.withOpacity(0.3);
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    option.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: wasSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                  ),
                ),
                if (wasSelected && !wasSkipped) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Your answer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
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