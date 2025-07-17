// lib/views/pages/topic_detail_page.dart - Updated for separated models
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../models/user/user_progress.dart';  // ADDED: Import separated models
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
            // UPDATED: Use separated model to check completion
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
                              const SizedBox(height: 4),
                              Text(
                                'Section: ${widget.section.title}',
                                style: TextStyle(
                                  fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // UPDATED: Real-time completion indicator
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
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
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Estimated reading time: ${widget.topic.estimatedReadTime.inMinutes} minutes',
                          style: TextStyle(
                            fontSize: deviceType == DeviceType.mobile ? 12.0 : 14.0,
                            color: Colors.grey.shade600,
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
              'Topic Overview',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.topic.description,
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Content would go here - using placeholder for now
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.article,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Topic Content',
                    style: TextStyle(
                      fontSize: deviceType == DeviceType.mobile ? 16.0 : 18.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detailed content for this topic will be displayed here. This includes explanations, examples, and interactive elements to help you learn ${widget.topic.title}.',
                    style: TextStyle(
                      fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
            // UPDATED: Use separated model to check completion
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
                        Icon(
                          Icons.quiz,
                          color: _getLevelColor(widget.section.level),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Topic Quiz',
                            style: TextStyle(
                              fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.green.shade700 : null,
                            ),
                          ),
                        ),
                        // UPDATED: Real-time completion status
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
                      'Test your understanding of this topic with interactive questions.',
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                        color: Colors.grey.shade600,
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
                          backgroundColor: isCompleted
                              ? Colors.green
                              : _getLevelColor(widget.section.level),
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
      },
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, DeviceType deviceType) {
    final hasQuiz = QuizIntegrationService.isTopicQuizImplemented(
        widget.section.id, widget.topic.id);

    if (!hasQuiz || !_showFloatingButton) {
      return null;
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<UserProgress>(
          future: _getUserProgress(appState),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return FloatingActionButton(
                onPressed: null,
                backgroundColor: Colors.grey.shade300,
                child: const CircularProgressIndicator(strokeWidth: 2),
              );
            }

            final userProgress = snapshot.data ?? UserProgress.empty();
            // UPDATED: Use separated model to check completion
            final isCompleted = userProgress.completedTopics.contains(widget.topic.id);

            return FloatingActionButton.extended(
              onPressed: () => _navigateToQuiz(context),
              backgroundColor: isCompleted ? Colors.green : _getLevelColor(widget.section.level),
              icon: const Icon(Icons.quiz, color: Colors.white),
              label: Text(
                isCompleted ? 'Retake Quiz' : 'Take Quiz',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ADDED: Helper method to get user progress
  Future<UserProgress> _getUserProgress(AppState appState) async {
    if (appState.currentUser == null) {
      return UserProgress.empty();
    }

    try {
      // Try to get progress from the progress tracking service
      return await ProgressTrackingService.instance.getCurrentProgress();
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      // Fallback to cached progress in AppState
      return appState.currentUserProgress ?? UserProgress.empty();
    }
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
    ).then((_) {
      // Progress will be automatically updated via the listener
      // No need for manual refresh here
    });
  }
}