// lib/modules/quiz/views/quiz_history_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_enums.dart';
import '../controllers/quiz_history_controller.dart';
import '../services/quiz_storage_service.dart';
import '../models/quiz_models.dart';

/// View for displaying quiz history and performance analytics
class QuizHistoryView extends StatefulWidget {
  const QuizHistoryView({Key? key}) : super(key: key);

  @override
  State<QuizHistoryView> createState() => _QuizHistoryViewState();
}

class _QuizHistoryViewState extends State<QuizHistoryView> {
  String? _selectedFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    // Load history when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizHistoryController>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear History'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<QuizHistoryController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(controller.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadHistory(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!controller.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64),
                  SizedBox(height: 16),
                  Text('No quiz history yet'),
                  SizedBox(height: 8),
                  Text('Complete some quizzes to see your progress!'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildStatisticsCard(context, controller),
                ),
                SliverToBoxAdapter(
                  child: _buildPerformanceTrend(context, controller),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Quizzes',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = controller.history[index];
                      return _buildHistoryItem(context, entry);
                    },
                    childCount: controller.history.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, QuizHistoryController controller) {
    final theme = Theme.of(context);
    final stats = controller.statistics;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Statistics',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Quizzes',
                    stats.totalQuizzes.toString(),
                    Icons.quiz,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Average Score',
                    '${stats.averageScore.toStringAsFixed(1)}%',
                    Icons.score,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Best Score',
                    '${stats.bestScore.toStringAsFixed(1)}%',
                    Icons.emoji_events,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Time',
                    _formatDuration(stats.totalTimeSpent),
                    Icons.timer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPerformanceTrend(BuildContext context, QuizHistoryController controller) {
    final theme = Theme.of(context);
    final performanceData = controller.getOverallPerformanceTrend(days: 30);

    if (performanceData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trend',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: _buildSimpleChart(context, performanceData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context, List<PerformancePoint> data) {
    final theme = Theme.of(context);
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data to display',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Take last 10 data points for display
    final displayData = data.length > 10 ? data.sublist(data.length - 10) : data;
    final maxScore = displayData.map((p) => p.score).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: displayData.map((point) {
        final barHeight = (point.score / (maxScore > 0 ? maxScore : 100)) * 150;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: '${point.score.toStringAsFixed(1)}%',
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: _getScoreColor(point.score, theme),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${point.date.day}/${point.date.month}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryItem(BuildContext context, QuizHistoryEntry entry) {
    final theme = Theme.of(context);
    final percentage = (entry.score / entry.totalQuestions) * 100;
    final color = _getScoreColor(percentage, theme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(entry.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.questionsAnswered}/${entry.totalQuestions} questions • ${_formatDuration(entry.timeSpent)}',
            ),
            Text(
              _formatDate(entry.completedAt),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _getQuizTypeIcon(entry.type),
        onTap: () => _showQuizDetails(context, entry),
      ),
    );
  }

  Color _getScoreColor(double score, ThemeData theme) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _getQuizTypeIcon(QuizType type) {
    switch (type) {
      case QuizType.section:
        return const Icon(Icons.folder_outlined);
      case QuizType.topic:
        return const Icon(Icons.topic_outlined);
      case QuizType.refresher:
        return const Icon(Icons.refresh);
      case QuizType.custom:
        return const Icon(Icons.tune);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showFilterDialog(BuildContext context) {
    // Implement filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter History'),
        content: const Text('Filter options coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuizDetails(BuildContext context, QuizHistoryEntry entry) {
    // Implement quiz details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${entry.score}/${entry.totalQuestions}'),
            Text('Accuracy: ${entry.accuracy.toStringAsFixed(1)}%'),
            Text('Time: ${_formatDuration(entry.timeSpent)}'),
            Text('Date: ${_formatDate(entry.completedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'refresh':
        context.read<QuizHistoryController>().refresh();
        break;
      case 'clear':
        _confirmClearHistory(context);
        break;
    }
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all quiz history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<QuizHistoryController>().clearAllHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}