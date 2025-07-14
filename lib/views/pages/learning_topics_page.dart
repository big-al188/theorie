// lib/views/pages/learning_topics_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
import 'topic_detail_page.dart';

class LearningTopicsPage extends StatelessWidget {
  final LearningSection section;

  const LearningTopicsPage({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: TheorieAppBar(
        title: '${section.title} Topics',
        showSettings: true,
        showThemeToggle: true,
        showLogout: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_getPadding(deviceType, isLandscape)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 20.0 : 24.0),
              _buildTopicsList(context, deviceType),
            ],
          ),
        ),
      ),
    );
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0;
    }
    return deviceType == DeviceType.mobile ? 20.0 : 32.0;
  }

  Widget _buildHeader(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: _getLevelColor(section.level),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.description,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _buildProgressSummary(context, deviceType),
      ],
    );
  }

  Widget _buildProgressSummary(BuildContext context, DeviceType deviceType) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final user = appState.currentUser;
        if (user == null) return const SizedBox.shrink();

        final completedTopics = section.topics
            .where((topic) => user.progress.isTopicCompleted(topic.id))
            .length;
        final totalTopics = section.topics.length;
        final progressPercentage = totalTopics > 0 ? completedTopics / totalTopics : 0.0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getLevelColor(section.level).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getLevelColor(section.level).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.track_changes,
                color: _getLevelColor(section.level),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: _getLevelColor(section.level),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedTopics of $totalTopics topics completed',
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 12.0 : 14.0,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(section.level)),
                strokeWidth: 3,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicsList(BuildContext context, DeviceType deviceType) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          children: section.topics.map((topic) {
            final isCompleted = appState.currentUser?.progress.isTopicCompleted(topic.id) ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTopicCard(context, topic, isCompleted, deviceType),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopicCard(BuildContext context, LearningTopic topic, bool isCompleted, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;

    return Card(
      elevation: isCompleted ? 2 : 4,
      child: InkWell(
        onTap: () => _navigateToTopicDetail(context, topic),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCompleted ? Colors.green.shade50 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green 
                          : _getLevelColor(section.level).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '${topic.order}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getLevelColor(section.level),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.green.shade700 : null,
                          ),
                        ),
                        Text(
                          '${topic.estimatedReadTime.inMinutes} min read',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                topic.description,
                style: TextStyle(
                  fontSize: bodyFontSize,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Key points preview
              if (topic.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Key concepts: ${topic.keyPoints.take(2).join(', ')}${topic.keyPoints.length > 2 ? '...' : ''}',
                  style: TextStyle(
                    fontSize: subtitleFontSize - 2,
                    color: _getLevelColor(section.level).withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(LearningLevel level) {
    switch (level) {
      case LearningLevel.introduction:
        return Colors.green;
      case LearningLevel.fundamentals:
        return Colors.blue;
      case LearningLevel.essentials:
        return Colors.cyan;
      case LearningLevel.intermediate:
        return Colors.orange;
      case LearningLevel.advanced:
        return Colors.red;
      case LearningLevel.professional:
        return Colors.purple;
      case LearningLevel.master:
        return Colors.deepPurple;
      case LearningLevel.virtuoso:
        return Colors.brown;
    }
  }

  void _navigateToTopicDetail(BuildContext context, LearningTopic topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopicDetailPage(
          topic: topic,
          section: section,
        ),
      ),
    );
  }
}