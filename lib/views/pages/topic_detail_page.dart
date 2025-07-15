// lib/views/pages/topic_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/quiz_integration_service.dart';
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
              _buildContentSection(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
              _buildKeyPointsSection(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
              _buildExamplesSection(context, deviceType),
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
    final titleFontSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section and topic info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getLevelColor(widget.section.level),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.section.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Topic ${widget.topic.order}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // Quiz availability indicator
            if (QuizIntegrationService.isTopicQuizImplemented(
                widget.section.id, widget.topic.id))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Quiz Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Topic title
        Text(
          widget.topic.title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: _getLevelColor(widget.section.level),
          ),
        ),

        const SizedBox(height: 8),

        // Description and reading time
        Text(
          widget.topic.description,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.topic.estimatedReadTime.inMinutes} min read',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context, DeviceType deviceType) {
    final fontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 20.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 20.0 : 22.0,
                fontWeight: FontWeight.bold,
                color: _getLevelColor(widget.section.level),
              ),
            ),
            const SizedBox(height: 16),
            MarkdownBody(
              data: widget.topic.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: fontSize,
                  height: 1.6,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade200
                      : Colors.grey.shade800,
                ),
                h1: TextStyle(
                  fontSize: fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
                h2: TextStyle(
                  fontSize: fontSize + 6,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
                h3: TextStyle(
                  fontSize: fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(widget.section.level),
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
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 20.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: _getLevelColor(widget.section.level),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Key Points',
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 20.0 : 22.0,
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(widget.section.level),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.topic.keyPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8),
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
                            fontSize:
                                deviceType == DeviceType.mobile ? 16.0 : 18.0,
                            height: 1.5,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                          ),
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

  Widget _buildExamplesSection(BuildContext context, DeviceType deviceType) {
    if (widget.topic.examples.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 20.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: _getLevelColor(widget.section.level),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Examples',
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 20.0 : 22.0,
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(widget.section.level),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.topic.examples.map((example) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _getLevelColor(widget.section.level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getLevelColor(widget.section.level)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 16.0 : 18.0,
                        height: 1.5,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection(BuildContext context, DeviceType deviceType) {
    final questionCount = QuizIntegrationService.getTopicQuestionCount(
      widget.section.id,
      widget.topic.id,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getLevelColor(widget.section.level).withOpacity(0.3),
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
              _getLevelColor(widget.section.level).withOpacity(0.1),
              _getLevelColor(widget.section.level).withOpacity(0.05),
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
                    color: _getLevelColor(widget.section.level),
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
                        'Test Your Knowledge',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getLevelColor(widget.section.level),
                            ),
                      ),
                      Text(
                        'Quiz on "${widget.topic.title}"',
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
            Text(
              'Ready to test what you\'ve learned? Take this quiz to check your understanding of the key concepts.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuizStat(context, 'Questions', '$questionCount'),
                ),
                Expanded(
                  child: _buildQuizStat(context, 'Pass Score', '75%'),
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
              child: ElevatedButton.icon(
                onPressed: () => _navigateToQuiz(context),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Start Topic Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getLevelColor(widget.section.level),
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
