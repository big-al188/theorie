// lib/views/pages/topic_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
import 'quiz_placeholder_page.dart';
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
              SizedBox(height: deviceType == DeviceType.mobile ? 20.0 : 24.0),
              _buildTopicContent(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
              _buildKeyPoints(context, deviceType),
              if (widget.topic.examples.isNotEmpty) ...[
                SizedBox(height: deviceType == DeviceType.mobile ? 20.0 : 24.0),
                _buildExamples(context, deviceType),
              ],
              SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
              _buildQuizButton(context, deviceType),
              const SizedBox(height: 32.0), // Extra bottom padding
            ],
          ),
        ),
      ),
      floatingActionButton: _showFloatingButton
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToQuiz(context),
              backgroundColor: _getLevelColor(widget.section.level),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.quiz),
              label: const Text('Take Quiz'),
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
    final titleFontSize = deviceType == DeviceType.mobile ? 28.0 : 32.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isCompleted = appState.currentUser?.progress.isTopicCompleted(widget.topic.id) ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic title
            Text(
              widget.topic.title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: _getLevelColor(widget.section.level),
                height: 1.2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Topic metadata
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(widget.section.level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.section.level.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getLevelColor(widget.section.level),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${widget.topic.estimatedReadTime.inMinutes} min read',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Topic description
            Text(
              widget.topic.description,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.grey.shade700,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopicContent(BuildContext context, DeviceType deviceType) {
    final bodyFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.article,
                color: _getLevelColor(widget.section.level),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Topic Content',
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: widget.topic.content,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: bodyFontSize,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
              strong: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
              h2: TextStyle(
                fontSize: bodyFontSize + 4,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
              listBullet: TextStyle(
                fontSize: bodyFontSize,
                color: _getLevelColor(widget.section.level),
              ),
              blockquote: TextStyle(
                fontSize: bodyFontSize,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPoints(BuildContext context, DeviceType deviceType) {
    if (widget.topic.keyPoints.isEmpty) return const SizedBox.shrink();

    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: _getLevelColor(widget.section.level).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getLevelColor(widget.section.level).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: _getLevelColor(widget.section.level),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Points',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
              ),
            ],
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
                    color: _getLevelColor(widget.section.level),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildExamples(BuildContext context, DeviceType deviceType) {
    if (widget.topic.examples.isEmpty) return const SizedBox.shrink();

    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: _getLevelColor(widget.section.level).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getLevelColor(widget.section.level).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: _getLevelColor(widget.section.level),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Examples',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.topic.examples.map((example) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: _getLevelColor(widget.section.level),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Text(
                    example,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      color: Theme.of(context).brightness == Brightness.dark 
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
      ),
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
        builder: (_) => QuizPlaceholderPage(
          title: '${widget.topic.title} Quiz',
          description: 'Test your understanding of "${widget.topic.title}" concepts.',
          topicId: widget.topic.id,
        ),
      ),
    );
  }
}