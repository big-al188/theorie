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

  /// ADDED: Helper method to get theme-aware body text colors (gray in dark mode)
  Color _getBodyTextColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade800;
  }

  /// ADDED: Helper method to get theme-aware header colors (white in dark mode)
  Color _getHeaderColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade200 : Theme.of(context).primaryColor;
  }

  /// ADDED: Helper method to get theme-aware secondary text colors
  Color _getSecondaryTextColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
  }

  /// ADDED: Helper method to get theme-aware code background colors
  Color _getCodeBackgroundColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
  }

  /// ADDED: Helper method to get theme-aware examples background colors
  Color _getExamplesBackgroundColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade800 : Colors.blue.shade50;
  }

  /// ADDED: Helper method to get theme-aware examples border colors
  Color _getExamplesBorderColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade600 : Colors.blue.shade200;
  }

  /// ADDED: Helper method to get theme-aware examples text colors
  Color _getExamplesTextColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade200 : Colors.blue.shade800;
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
    final padding = _getPadding(deviceType, isLandscape);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, deviceType),
          const SizedBox(height: 24),
          _buildMainContent(context, deviceType),
          const SizedBox(height: 24),
          _buildKeyPointsSection(context, deviceType),
          const SizedBox(height: 24),
          _buildExamplesSection(context, deviceType),
          const SizedBox(height: 24),
          _buildQuizSection(context, deviceType),
          const SizedBox(height: 100), // Extra space for floating button
        ],
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
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Check if topic is completed
        final userProgress = appState.currentUserProgress;
        final isCompleted = userProgress?.completedTopics.contains(widget.topic.id) ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.topic.title,
                    style: TextStyle(
                      fontSize: deviceType == DeviceType.mobile ? 24.0 : 28.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.topic.description,
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 16.0 : 18.0,
                color: _getSecondaryTextColor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: _getSecondaryTextColor(context)),
                const SizedBox(width: 4),
                Text(
                  '${widget.topic.estimatedReadTime.inMinutes} min read',
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                    color: _getSecondaryTextColor(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, DeviceType deviceType) {
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
            // UPDATED: Display actual topic content using Markdown with theme-aware styling
            MarkdownBody(
              data: widget.topic.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 20.0 : 24.0,
                  fontWeight: FontWeight.bold,
                  color: _getHeaderColor(context),
                ),
                h2: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 18.0 : 22.0,
                  fontWeight: FontWeight.bold,
                  color: _getHeaderColor(context),
                ),
                h3: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 16.0 : 20.0,
                  fontWeight: FontWeight.bold,
                  color: _getHeaderColor(context),
                ),
                p: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  height: 1.6,
                  color: _getBodyTextColor(context),
                ),
                listBullet: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  height: 1.6,
                  color: _getBodyTextColor(context),
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getHeaderColor(context),
                ),
                em: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: _getBodyTextColor(context),
                ),
                code: TextStyle(
                  backgroundColor: _getCodeBackgroundColor(context),
                  color: _getBodyTextColor(context),
                  fontFamily: 'monospace',
                  fontSize: deviceType == DeviceType.mobile ? 13.0 : 15.0,
                ),
                codeblockDecoration: BoxDecoration(
                  color: _getCodeBackgroundColor(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                blockquote: TextStyle(
                  color: _getSecondaryTextColor(context),
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  fontStyle: FontStyle.italic,
                ),
                blockquoteDecoration: BoxDecoration(
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
            ...widget.topic.keyPoints.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                        height: 1.5,
                        color: _getBodyTextColor(context),
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
                color: _getExamplesBackgroundColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getExamplesBorderColor(context)),
              ),
              child: Text(
                example,
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  height: 1.5,
                  color: _getExamplesTextColor(context),
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
                      fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'A quiz for this topic is currently under development. Check back soon!',
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                  color: _getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final userProgress = appState.currentUserProgress;
        final isCompleted = userProgress?.completedTopics.contains(widget.topic.id) ?? false;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isCompleted ? Colors.green.withOpacity(0.3) : Theme.of(context).primaryColor.withOpacity(0.3),
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
                          color: isCompleted ? Colors.green.shade700 : null,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              'PASSED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Take a quick quiz to test your understanding of this topic.',
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                    color: _getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToQuiz(context),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: Text(
                      isCompleted ? 'Retake Quiz' : 'Take Quiz',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? Colors.green : _getLevelColor(widget.section.level),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, DeviceType deviceType) {
    final hasQuiz = QuizIntegrationService.isTopicQuizImplemented(
        widget.section.id, widget.topic.id);

    if (!hasQuiz || !_showFloatingButton) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _navigateToQuiz(context),
      icon: const Icon(Icons.quiz),
      label: const Text('Take Quiz'),
      backgroundColor: _getLevelColor(widget.section.level),
      foregroundColor: Colors.white,
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