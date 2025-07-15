// lib/views/pages/topic_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
import '../../modules/quiz/views/quiz_landing_view.dart';
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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
          Consumer<AppState>(
            builder: (context, appState, child) {
              final isCompleted = appState.currentUser?.progress.isTopicCompleted(widget.topic.id) ?? false;
              if (isCompleted) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade200,
                    size: 24,
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
              _buildTopicHeader(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
              _buildTopicContent(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
              _buildKeyPoints(context, deviceType),
              if (widget.topic.examples.isNotEmpty) ...[
                SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
                _buildExamples(context, deviceType),
              ],
              SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
              _buildQuizButton(context, deviceType),
              const SizedBox(height: 80), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _showFloatingButton
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToQuiz(context),
              label: const Text('Take Quiz'),
              icon: const Icon(Icons.quiz),
              backgroundColor: _getLevelColor(widget.section.level),
            )
          : null,
    );
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0;
    }
    return deviceType == DeviceType.mobile ? 20.0 : 32.0;
  }

  Widget _buildTopicHeader(BuildContext context, DeviceType deviceType) {
    final subtitleFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getLevelColor(widget.section.level).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.section.title,
                style: TextStyle(
                  fontSize: subtitleFontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: _getLevelColor(widget.section.level),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<AppState>(
              builder: (context, appState, child) {
                final isCompleted = appState.currentUser?.progress.isTopicCompleted(widget.topic.id) ?? false;
                if (isCompleted) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: subtitleFontSize - 2,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
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
        const SizedBox(height: 16),
        Text(
          widget.topic.description,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              'Estimated reading time: ${widget.topic.estimatedReadTime.inMinutes} minutes',
              style: TextStyle(
                fontSize: subtitleFontSize - 2,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopicContent(BuildContext context, DeviceType deviceType) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MarkdownBody(
          data: widget.topic.content,
          styleSheet: MarkdownStyleSheet(
            h1: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            h2: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
            h3: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            p: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
            code: TextStyle(
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              fontFamily: 'monospace',
              fontSize: deviceType == DeviceType.mobile ? 12 : 14,
            ),
            codeblockDecoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            blockquote: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPoints(BuildContext context, DeviceType deviceType) {
    if (widget.topic.keyPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Points',
          style: TextStyle(
            fontSize: titleFontSize,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getLevelColor(widget.section.level).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      fontSize: bodyFontSize - 2,
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(widget.section.level),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: isDark 
                        ? Colors.grey.shade300 
                        : Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildExamples(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Examples',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.topic.examples.map((example) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey.shade900 
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: _getLevelColor(widget.section.level),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    example,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      color: isDark 
                          ? Colors.grey.shade300 
                          : Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildQuizButton(BuildContext context, DeviceType deviceType) {
    final buttonHeight = deviceType == DeviceType.mobile ? 48.0 : 56.0;
    final fontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 300.0,
        ),
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton.icon(
          onPressed: () => _navigateToQuiz(context),
          icon: const Icon(Icons.quiz, size: 24),
          label: Text(
            'Take Quiz',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getLevelColor(widget.section.level),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  void _navigateToQuiz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizLandingView(
          sectionId: widget.section.id,
          topicId: widget.topic.id,
        ),
      ),
    );
  }
}