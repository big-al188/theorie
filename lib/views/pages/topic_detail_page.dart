// lib/views/pages/topic_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/quiz_integration_service.dart';
import '../../services/progress_tracking_service.dart'; // ADDED: For progress tracking
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
    // ADDED: Listen to progress changes for real-time updates
    ProgressTrackingService.instance.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // ADDED: Clean up progress listener
    ProgressTrackingService.instance.removeListener(_onProgressChanged);
    super.dispose();
  }

  /// ADDED: Handle progress changes and refresh UI
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
        actions: [
          // Quiz button in app bar if available
          if (QuizIntegrationService.isTopicQuizImplemented(
              widget.section.id, widget.topic.id))
            IconButton(
              onPressed: () => _navigateToQuiz(context),
              icon: const Icon(Icons.quiz),
              tooltip: 'Take Quiz',
            ),
          // Completion indicator
          Consumer<AppState>(
            builder: (context, appState, child) {
              final isCompleted = appState.currentUser?.progress
                      .isTopicCompleted(widget.topic.id) ??
                  false;

              if (isCompleted) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(_getPadding(deviceType, isLandscape)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 20.0 : 24.0),
              _buildContent(context, deviceType),
              if (QuizIntegrationService.isTopicQuizImplemented(
                  widget.section.id, widget.topic.id)) ...[
                SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 40.0),
                _buildQuizSection(context, deviceType),
              ],
              SizedBox(height: deviceType == DeviceType.mobile ? 40.0 : 48.0),
            ],
          ),
        ),
      ),
      floatingActionButton: _showFloatingButton &&
              QuizIntegrationService.isTopicQuizImplemented(
                  widget.section.id, widget.topic.id)
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToQuiz(context),
              icon: const Icon(Icons.quiz),
              label: const Text('Take Quiz'),
              backgroundColor: _getLevelColor(widget.section.level),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0; // Reduced padding for landscape mobile
    }
    return deviceType == DeviceType.mobile ? 20.0 : 32.0;
  }

  Widget _buildHeader(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getLevelColor(widget.section.level).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getLevelColor(widget.section.level).withOpacity(0.3),
            ),
          ),
          child: Text(
            widget.section.level.displayName,
            style: TextStyle(
              color: _getLevelColor(widget.section.level),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Topic title
        Text(
          widget.topic.title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),

        // Topic description
        Text(
          widget.topic.description,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Reading time and progress indicator
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.topic.estimatedReadTime.inMinutes} min read',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // ENHANCED: Real-time completion status
            Consumer<AppState>(
              builder: (context, appState, child) {
                final isCompleted = appState.currentUser?.progress
                        .isTopicCompleted(widget.topic.id) ??
                    false;

                if (isCompleted) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, DeviceType deviceType) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Points section
            if (widget.topic.keyPoints.isNotEmpty) ...[
              Text(
                'Key Points',
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
              ),
              const SizedBox(height: 12),
              ...widget.topic.keyPoints
                  .map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getLevelColor(widget.section.level),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  fontSize: deviceType == DeviceType.mobile
                                      ? 14.0
                                      : 16.0,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              const SizedBox(height: 24),
            ],

            // Main Content section
            Text(
              'Content',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
                color: _getLevelColor(widget.section.level),
              ),
            ),
            const SizedBox(height: 12),
            MarkdownBody(
              data: widget.topic.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  height: 1.6,
                ),
                h1: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 20.0 : 24.0,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
                h2: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 18.0 : 22.0,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
                h3: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 16.0 : 20.0,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
                blockquote: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            // Examples section
            if (widget.topic.examples.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Examples',
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
              ),
              const SizedBox(height: 12),
              ...widget.topic.examples
                  .map((example) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(
                            deviceType == DeviceType.mobile ? 12.0 : 16.0),
                        decoration: BoxDecoration(
                          color: _getLevelColor(widget.section.level)
                              .withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getLevelColor(widget.section.level)
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          example,
                          style: TextStyle(
                            fontSize:
                                deviceType == DeviceType.mobile ? 14.0 : 16.0,
                            height: 1.4,
                          ),
                        ),
                      ))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection(BuildContext context, DeviceType deviceType) {
    final questionCount = QuizIntegrationService.getTopicQuestionCount(
        widget.section.id, widget.topic.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getLevelColor(widget.section.level).withOpacity(0.3),
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
                Icon(
                  Icons.quiz,
                  color: _getLevelColor(widget.section.level),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Test Your Knowledge',
                    style: TextStyle(
                      fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(widget.section.level),
                    ),
                  ),
                ),
                // ENHANCED: Completion indicator for quiz section
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    final isCompleted = appState.currentUser?.progress
                            .isTopicCompleted(widget.topic.id) ??
                        false;

                    if (isCompleted) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'PASSED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Take this quiz to check your understanding of the key concepts.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuizStat(context, 'Questions', '$questionCount'),
                ),
                Expanded(
                  child: _buildQuizStat(context, 'Pass Score', '70%'),
                ),
                Expanded(
                  child: _buildQuizStat(context, 'Time Limit',
                      '${(questionCount * 1.5).ceil()} min'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  final isCompleted = appState.currentUser?.progress
                          .isTopicCompleted(widget.topic.id) ??
                      false;

                  return ElevatedButton.icon(
                    onPressed: () => _navigateToQuiz(context),
                    icon: Icon(isCompleted ? Icons.refresh : Icons.play_arrow,
                        size: 20),
                    label: Text(
                        isCompleted ? 'Retake Topic Quiz' : 'Start Topic Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getLevelColor(widget.section.level),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
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
                color: _getLevelColor(widget.section.level),
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

  void _navigateToQuiz(BuildContext context) {
    final quizController = Provider.of<QuizController>(context, listen: false);

    QuizIntegrationService.navigateToTopicQuiz(
      context: context,
      topic: widget.topic,
      section: widget.section,
      quizController: quizController,
    );
  }
}
