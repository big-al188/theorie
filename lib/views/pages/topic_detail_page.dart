// lib/views/pages/topic_detail_page.dart - Fixed to display topic content
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../models/user/user_progress.dart';
import '../../constants/ui_constants.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/quiz_integration_service.dart';
import '../../services/progress_tracking_service.dart';
import '../widgets/common/app_bar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TopicDetailPage extends StatefulWidget {
  final LearningTopic topic;
  final LearningSection section;

  const TopicDetailPage({
    super.key,
    required this.topic,
    required this.section,
  });

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Listen to progress changes for real-time updates
    ProgressTrackingService.instance.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Clean up progress listener
    ProgressTrackingService.instance.removeListener(_onProgressChanged);
    super.dispose();
  }

  /// Handle progress changes and refresh UI
  void _onProgressChanged() {
    if (mounted) {
      // Force AppState to refresh user data
      final appState = context.read<AppState>();
      appState.refreshUserProgress().then((_) {
        if (mounted) {
          setState(() {
            // This will trigger a rebuild with updated progress
          });
        }
      });
    }
  }

  void _onScroll() {
    // Show quiz button when user has scrolled down significantly
    final showButton = _scrollController.offset > 200;
    if (showButton != _showFloatingButton) {
      setState(() {
        _showFloatingButton = showButton;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: TheorieAppBar(
        title: widget.topic.title,
        showSettings: true,
        showThemeToggle: true,
        showLogout: true,
      ),
      body: SafeArea(
        child: _buildContent(context, deviceType, isLandscape),
      ),
      floatingActionButton: _buildFloatingActionButton(context, deviceType),
    );
  }

  Widget _buildContent(BuildContext context, DeviceType deviceType, bool isLandscape) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(_getPadding(deviceType, isLandscape)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, deviceType),
          const SizedBox(height: 24),
          _buildTopicContent(context, deviceType),
          const SizedBox(height: 32),
          _buildKeyPointsSection(context, deviceType),
          const SizedBox(height: 24),
          _buildExamplesSection(context, deviceType),
          const SizedBox(height: 32),
          _buildQuizSection(context, deviceType),
          const SizedBox(height: 100), // Extra space for floating button
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DeviceType deviceType) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<UserProgress>(
          future: _getUserProgress(appState),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 2,
                child: Container(
                  height: 80,
                  padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final userProgress = snapshot.data ?? UserProgress.empty();
            final isCompleted = userProgress.completedTopics.contains(widget.topic.id);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : _getLevelColor(widget.section.level).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.topic.title,
                                style: TextStyle(
                                  fontSize: deviceType == DeviceType.mobile ? 20.0 : 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? Colors.green.shade700 : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.topic.description,
                                style: TextStyle(
                                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isCompleted ? Colors.green : Colors.grey.shade400,
                              size: deviceType == DeviceType.mobile ? 24.0 : 28.0,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.topic.estimatedReadTime.inMinutes} min',
                              style: TextStyle(
                                fontSize: deviceType == DeviceType.mobile ? 12.0 : 14.0,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopicContent(BuildContext context, DeviceType deviceType) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // FIXED: Display actual topic content using Markdown
            MarkdownBody(
              data: widget.topic.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 20.0 : 24.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                h2: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 18.0 : 22.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                h3: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 16.0 : 20.0,
                  fontWeight: FontWeight.bold,
                ),
                p: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  height: 1.6,
                  color: Colors.grey.shade800,
                ),
                listBullet: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  height: 1.6,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                em: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
                code: TextStyle(
                  backgroundColor: Colors.grey.shade100,
                  fontFamily: 'monospace',
                  fontSize: deviceType == DeviceType.mobile ? 13.0 : 15.0,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                blockquote: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  fontStyle: FontStyle.italic,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPointsSection(BuildContext context, DeviceType deviceType) {
    if (widget.topic.keyPoints.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Points',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.topic.keyPoints.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context, DeviceType deviceType) {
    if (widget.topic.examples.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examples',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.topic.examples.map((example) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                example,
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  height: 1.5,
                  color: Colors.blue.shade800,
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection(BuildContext context, DeviceType deviceType) {
    final hasQuiz = QuizIntegrationService.isTopicQuizImplemented(
        widget.section.id, widget.topic.id);

    if (!hasQuiz) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.construction, color: Colors.orange.shade600, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Quiz Coming Soon',
                    style: TextStyle(
                      fontSize: deviceType == DeviceType.mobile ? 16.0 : 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A quiz for this topic is currently being developed.',
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<UserProgress>(
          future: _getUserProgress(appState),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 2,
                child: Container(
                  height: 120,
                  padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final userProgress = snapshot.data ?? UserProgress.empty();
            final topicAttempts = userProgress.getTopicAttempts(widget.topic.id);
            final hasAttempted = topicAttempts.isNotEmpty;
            final latestResult = hasAttempted ? topicAttempts.last : null;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Your Knowledge',
                                style: TextStyle(
                                  fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasAttempted
                                    ? 'Take the quiz again to improve your score'
                                    : 'Ready to test what you\'ve learned about ${widget.topic.title}?',
                                style: TextStyle(
                                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (latestResult != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getScoreColor(latestResult.score * 100).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _getScoreColor(latestResult.score * 100).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Last Score: ${(latestResult.score * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: deviceType == DeviceType.mobile ? 12.0 : 14.0,
                                      fontWeight: FontWeight.w500,
                                      color: _getScoreColor(latestResult.score * 100),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _startTopicQuiz(context),
                          icon: const Icon(Icons.quiz, size: 20),
                          label: Text(hasAttempted ? 'Retake Quiz' : 'Start Quiz'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: deviceType == DeviceType.mobile ? 16.0 : 20.0,
                              vertical: deviceType == DeviceType.mobile ? 12.0 : 16.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, DeviceType deviceType) {
    if (!_showFloatingButton) return null;

    final hasQuiz = QuizIntegrationService.isTopicQuizImplemented(
        widget.section.id, widget.topic.id);

    if (!hasQuiz) return null;

    return FloatingActionButton.extended(
      onPressed: () => _startTopicQuiz(context),
      icon: const Icon(Icons.quiz),
      label: const Text('Quiz'),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _startTopicQuiz(BuildContext context) async {
    final quizController = context.read<QuizController>();
    await QuizIntegrationService.navigateToTopicQuiz(
      context: context,
      topic: widget.topic,
      section: widget.section,
      quizController: quizController,
    );
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0;
    }
    return deviceType == DeviceType.mobile ? 20.0 : 32.0;
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
        return Colors.deepOrange;
      case LearningLevel.professional:
        return Colors.purple;
      case LearningLevel.master:
        return Colors.deepPurple;
      case LearningLevel.virtuoso:
        return Colors.brown;
    }
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  Future<UserProgress> _getUserProgress(AppState appState) async {
    try {
      // Use ProgressTrackingService to get current progress
      return await ProgressTrackingService.instance.getCurrentProgress();
    } catch (e) {
      // Fallback to cached progress in AppState
      return appState.currentUserProgress ?? UserProgress.empty();
    }
  }
}