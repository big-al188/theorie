import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/quiz_enums.dart';
import '../controllers/quiz_history_controller.dart';
import '../services/quiz_storage_service.dart';

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
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildStatisticsSection(controller, theme),
                ),
                SliverToBoxAdapter(
                  child: _buildPerformanceChart(controller, theme),
                ),
                SliverToBoxAdapter(
                  child: _buildInsightsSection(controller, theme),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Quizzes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = controller.history[index];
                      return _buildHistoryItem(entry, theme);
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 96,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No quiz history yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some quizzes to see your progress here',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Take a Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
    QuizHistoryController controller,
    ThemeData theme,
  ) {
    final stats = controller.statistics;
    final streak = controller.getStreakInfo();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Statistics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Quizzes',
                  value: stats.totalQuizzesTaken.toString(),
                  icon: Icons.quiz,
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Average Score',
                  value: '${stats.averageScore.toStringAsFixed(1)}%',
                  icon: Icons.grade,
                  color: Colors.green,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Current Streak',
                  value: '${streak.currentStreak} days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Time',
                  value: _formatTotalTime(stats.totalTimeSpent),
                  icon: Icons.timer,
                  color: theme.colorScheme.secondary,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(
    QuizHistoryController controller,
    ThemeData theme,
  ) {
    final performanceData = controller.getOverallPerformanceTrend(days: 30);
    
    if (performanceData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Trend',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && 
                                value.toInt() < performanceData.length) {
                              final date = performanceData[value.toInt()].date;
                              return Text(
                                '${date.month}/${date.day}',
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    minX: 0,
                    maxX: (performanceData.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: performanceData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.score,
                          );
                        }).toList(),
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: theme.colorScheme.primary,
                              strokeWidth: 2,
                              strokeColor: theme.colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(
    QuizHistoryController controller,
    ThemeData theme,
  ) {
    final weakTopics = controller.getWeakTopics();
    final strongTopics = controller.getStrongTopics();

    if (weakTopics.isEmpty && strongTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Insights',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (strongTopics.isNotEmpty) ...[
            _buildTopicSection(
              title: 'Your Strengths',
              icon: Icons.star,
              color: Colors.green,
              topics: strongTopics.map((t) => _TopicInfo(
                name: _formatTopicName(t.topicId),
                score: t.averageScore,
                isStrong: true,
              )).toList(),
              theme: theme,
            ),
            const SizedBox(height: 12),
          ],
          if (weakTopics.isNotEmpty) ...[
            _buildTopicSection(
              title: 'Areas for Improvement',
              icon: Icons.trending_up,
              color: theme.colorScheme.error,
              topics: weakTopics.map((t) => _TopicInfo(
                name: _formatTopicName(t.topicId),
                score: t.averageScore,
                isStrong: false,
              )).toList(),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_TopicInfo> topics,
    required ThemeData theme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics.map((topic) {
                return Chip(
                  label: Text(
                    '${topic.name} (${topic.score.toStringAsFixed(0)}%)',
                  ),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.5)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(QuizHistoryEntry entry, ThemeData theme) {
    final icon = _getQuizTypeIcon(entry.quizType);
    final scoreColor = _getScoreColor(entry.score);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(
          entry.metadata.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${_formatDate(entry.completedAt)} • '
          '${_formatDuration(entry.timeSpent)} • '
          '${entry.metadata.coveredTopics.length} topics',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${entry.score.toStringAsFixed(0)}%',
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showQuizDetails(context, entry),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter options would go here
            const Text('Filter options coming soon'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Apply filters
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
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
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all quiz history and statistics. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<QuizHistoryController>().clearAllHistory();
              Navigator.of(context).pop();
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuizDetails(BuildContext context, QuizHistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  entry.metadata.title,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Quiz details would go here
                Text('Quiz details coming soon'),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getQuizTypeIcon(QuizType type) {
    switch (type) {
      case QuizType.section:
        return Icons.folder_outlined;
      case QuizType.topic:
        return Icons.topic_outlined;
      case QuizType.refresher:
        return Icons.refresh;
      case QuizType.custom:
        return Icons.tune;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTotalTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatTopicName(String topicId) {
    return topicId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _TopicInfo {
  final String name;
  final double score;
  final bool isStrong;

  _TopicInfo({
    required this.name,
    required this.score,
    required this.isStrong,
  });
}