// lib/views/pages/learning_topics_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/quiz_integration_service.dart';
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
        actions: [
          // Section quiz button in app bar
          if (QuizIntegrationService.isSectionQuizImplemented(section.id))
            IconButton(
              onPressed: () => _navigateToSectionQuiz(context),
              icon: const Icon(Icons.quiz),
              tooltip: 'Section Quiz',
            ),
        ],
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
              if (QuizIntegrationService.isSectionQuizImplemented(
                  section.id)) ...[
                SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
                _buildSectionQuizCard(context, deviceType),
              ],
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
        if (QuizIntegrationService.isSectionQuizImplemented(section.id)) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text(
                  'Interactive quizzes available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopicsList(BuildContext context, DeviceType deviceType) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          children: section.topics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;
            final isCompleted =
                appState.currentUser?.progress.isTopicCompleted(topic.id) ??
                    false;

            return Padding(
              padding: EdgeInsets.only(
                bottom: deviceType == DeviceType.mobile ? 12.0 : 16.0,
              ),
              child: _buildTopicCard(context, topic, isCompleted, deviceType),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopicCard(BuildContext context, LearningTopic topic,
      bool isCompleted, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final hasQuiz =
        QuizIntegrationService.isTopicQuizImplemented(section.id, topic.id);

    return Card(
      elevation: isCompleted ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : _getLevelColor(section.level).withOpacity(0.2),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTopicDetail(context, topic),
        child: Padding(
          padding:
              EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
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
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
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
                  // Quiz availability indicator
                  if (hasQuiz)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.quiz,
                          size: 14, color: Colors.blue.shade700),
                    ),
                  const SizedBox(width: 8),
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
                    fontSize: bodyFontSize - 2,
                    color: _getLevelColor(section.level),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Action buttons row
              if (hasQuiz) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToTopicQuiz(context, topic),
                        icon: const Icon(Icons.quiz, size: 16),
                        label: const Text('Topic Quiz'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToTopicDetail(context, topic),
                        icon: const Icon(Icons.book, size: 16),
                        label: const Text('Read Topic'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getLevelColor(section.level),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionQuizCard(BuildContext context, DeviceType deviceType) {
    final stats = QuizIntegrationService.getSectionQuizStats(section.id);
    final totalQuestions = stats['totalQuestions'] as int;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getLevelColor(section.level).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getLevelColor(section.level).withOpacity(0.1),
              _getLevelColor(section.level).withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getLevelColor(section.level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${section.title} Section Quiz',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getLevelColor(section.level),
                            ),
                      ),
                      Text(
                        'Test your knowledge of all topics',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child:
                      _buildQuizStat(context, 'Questions', '$totalQuestions'),
                ),
                Expanded(
                  child: _buildQuizStat(context, 'Time Limit', '15 min'),
                ),
                Expanded(
                  child: _buildQuizStat(context, 'Pass Score', '70%'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSectionQuiz(context),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Start Section Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getLevelColor(section.level),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getLevelColor(section.level),
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
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

  void _navigateToTopicQuiz(BuildContext context, LearningTopic topic) {
    final quizController = Provider.of<QuizController>(context, listen: false);

    QuizIntegrationService.navigateToTopicQuiz(
      context: context,
      topic: topic,
      section: section,
      quizController: quizController,
    );
  }

  void _navigateToSectionQuiz(BuildContext context) {
    final quizController = Provider.of<QuizController>(context, listen: false);

    QuizIntegrationService.navigateToSectionQuiz(
      context: context,
      section: section,
      quizController: quizController,
    );
  }
}
