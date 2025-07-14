import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_models.dart';
import '../models/question_models.dart';
import '../models/quiz_enums.dart';
import '../controllers/quiz_history_controller.dart';
import 'components/question_views/multiple_choice_view.dart';
import 'components/question_views/interactive_question_view.dart';
import 'quiz_landing_view.dart';

/// View for reviewing completed quiz results
class QuizReviewView extends StatefulWidget {
  final Quiz quiz;
  final QuizResult result;

  const QuizReviewView({
    Key? key,
    required this.quiz,
    required this.result,
  }) : super(key: key);

  @override
  State<QuizReviewView> createState() => _QuizReviewViewState();
}

class _QuizReviewViewState extends State<QuizReviewView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Review'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Questions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(theme),
          _buildQuestionsTab(theme),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, theme),
    );
  }

  Widget _buildSummaryTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreCard(theme),
          const SizedBox(height: 24),
          _buildPerformanceBreakdown(theme),
          const SizedBox(height: 24),
          _buildTopicAnalysis(theme),
          const SizedBox(height: 24),
          _buildRecommendations(theme),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ThemeData theme) {
    final score = widget.result.score;
    final grade = _calculateGrade(score);
    final gradeColor = _getGradeColor(grade);

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              gradeColor.withOpacity(0.1),
              gradeColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Your Score',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  score.toStringAsFixed(0),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: gradeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                grade,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Correct',
                  value: '${widget.result.answers.values.where((a) => a.isCorrect).length}',
                  theme: theme,
                ),
                _buildStatItem(
                  icon: Icons.timer_outlined,
                  label: 'Time',
                  value: _formatDuration(widget.result.timeSpent),
                  theme: theme,
                ),
                _buildStatItem(
                  icon: Icons.speed_outlined,
                  label: 'Avg/Question',
                  value: _formatDuration(
                    Duration(
                      seconds: widget.quiz.questions.isNotEmpty
                          ? widget.result.timeSpent.inSeconds ~/
                              widget.quiz.questions.length
                          : 0,
                    ),
                  ),
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBreakdown(ThemeData theme) {
    final byType = <QuestionType, List<Answer>>{};
    
    for (final question in widget.quiz.questions) {
      final answer = widget.result.answers[question.id];
      if (answer != null) {
        byType.putIfAbsent(question.type, () => []).add(answer);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Question Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...byType.entries.map((entry) {
              final correct = entry.value.where((a) => a.isCorrect).length;
              final total = entry.value.length;
              final percentage = total > 0 ? (correct / total) * 100 : 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              entry.key.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.displayName,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        Text(
                          '$correct/$total (${percentage.toStringAsFixed(0)}%)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(percentage, theme),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicAnalysis(ThemeData theme) {
    final byTopic = <String, List<Answer>>{};
    
    for (final question in widget.quiz.questions) {
      final answer = widget.result.answers[question.id];
      if (answer != null) {
        byTopic.putIfAbsent(question.topicId, () => []).add(answer);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: byTopic.entries.map((entry) {
                final correct = entry.value.where((a) => a.isCorrect).length;
                final total = entry.value.length;
                final percentage = total > 0 ? (correct / total) * 100 : 0;
                final color = _getScoreColor(percentage, theme);
                
                return Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTopicName(entry.key),
                        style: TextStyle(color: color),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(ThemeData theme) {
    final recommendations = <String>[];
    
    if (widget.result.areasForImprovement.isNotEmpty) {
      recommendations.add(
        'Focus on these topics: ${widget.result.areasForImprovement.map(_formatTopicName).join(", ")}',
      );
    }
    
    if (widget.result.score < 70) {
      recommendations.add('Review the lesson materials before attempting another quiz');
    } else if (widget.result.score < 85) {
      recommendations.add('Practice more with topic-specific quizzes');
    } else {
      recommendations.add('Great job! Try a more challenging quiz level');
    }

    if (widget.result.timeSpent.inSeconds < widget.quiz.metadata.estimatedMinutes * 30) {
      recommendations.add('Take your time to read questions carefully');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      rec,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab(ThemeData theme) {
    return Row(
      children: [
        // Question list
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: ListView.builder(
            itemCount: widget.quiz.questions.length,
            itemBuilder: (context, index) {
              final question = widget.quiz.questions[index];
              final answer = widget.result.answers[question.id];
              final isSelected = _selectedQuestionIndex == index;
              
              return ListTile(
                selected: isSelected,
                leading: CircleAvatar(
                  backgroundColor: answer?.isCorrect == true
                      ? Colors.green.withOpacity(0.2)
                      : theme.colorScheme.error.withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: answer?.isCorrect == true
                          ? Colors.green
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  question.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      answer?.isCorrect == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: answer?.isCorrect == true
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      answer?.isCorrect == true ? 'Correct' : 'Incorrect',
                      style: TextStyle(
                        color: answer?.isCorrect == true
                            ? Colors.green
                            : theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedQuestionIndex = index;
                  });
                },
              );
            },
          ),
        ),
        // Question detail
        Expanded(
          child: _selectedQuestionIndex < widget.quiz.questions.length
              ? _buildQuestionReview(
                  widget.quiz.questions[_selectedQuestionIndex],
                  widget.result.answers[
                      widget.quiz.questions[_selectedQuestionIndex].id],
                  theme,
                )
              : const Center(
                  child: Text('Select a question to review'),
                ),
        ),
      ],
    );
  }

  Widget _buildQuestionReview(
    Question question,
    Answer? answer,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question number and type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_selectedQuestionIndex + 1}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: Text(question.type.displayName),
                backgroundColor: theme.colorScheme.secondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Show the question with answer and feedback
          if (question is MultipleChoiceQuestion)
            MultipleChoiceView(
              question: question,
              selectedAnswer: answer?.value,
              onAnswerSelected: (_) {}, // Read-only
              showFeedback: true,
              isCorrect: answer?.isCorrect,
            )
          else
            InteractiveQuestionView(
              question: question,
              previousAnswer: answer?.value,
              onAnswerSubmit: (_) {}, // Read-only
              showFeedback: true,
              feedback: answer?.feedback,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton.icon(
            onPressed: () => _retakeQuiz(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Quiz'),
          ),
          FilledButton.icon(
            onPressed: () => _navigateToHome(context),
            icon: const Icon(Icons.home),
            label: const Text('Back to Quizzes'),
          ),
        ],
      ),
    );
  }

  String _calculateGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  Color _getScoreColor(double score, ThemeData theme) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return theme.colorScheme.error;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTopicName(String topicId) {
    // Convert topic ID to display name
    return topicId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _retakeQuiz(BuildContext context) {
    // Navigate back to quiz landing to retake
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => QuizLandingView(
          sectionId: widget.quiz.sectionId,
          topicId: widget.quiz.topicId,
        ),
      ),
      (route) => false,
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => QuizLandingView(
          sectionId: widget.quiz.sectionId,
        ),
      ),
      (route) => false,
    );
  }
}