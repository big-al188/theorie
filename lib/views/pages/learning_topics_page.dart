// lib/views/pages/learning_topics_page.dart - Updated for separated models

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../models/user/user.dart';
import '../../models/user/user_progress.dart';  // ADDED: Import separated models
import '../../constants/ui_constants.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/quiz_integration_service.dart';
import '../../services/progress_tracking_service.dart';
import '../widgets/common/app_bar.dart';
import 'topic_detail_page.dart';

class LearningTopicsPage extends StatefulWidget {
  final LearningSection section;

  const LearningTopicsPage({
    super.key,
    required this.section,
  });

  @override
  State<LearningTopicsPage> createState() => _LearningTopicsPageState();
}

class _LearningTopicsPageState extends State<LearningTopicsPage> {
  @override
  void initState() {
    super.initState();
    // Listen to progress changes for real-time updates
    ProgressTrackingService.instance.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: TheorieAppBar(
        title: widget.section.title,
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
              _buildSectionStats(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 20.0 : 24.0),
              _buildTopicsList(context, deviceType, isLandscape),
              SizedBox(height: deviceType == DeviceType.mobile ? 20.0 : 24.0),
              _buildSectionQuizCard(context, deviceType),
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
          'Topics',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.section.description,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionStats(BuildContext context, DeviceType deviceType) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // UPDATED: Use FutureBuilder for async progress loading
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
            int completedTopics = 0;
            int totalTopics = widget.section.topics.length;

            for (final topic in widget.section.topics) {
              if (userProgress.completedTopics.contains(topic.id)) {
                completedTopics++;
              }
            }

            final progressPercentage = totalTopics > 0 ? completedTopics / totalTopics : 0.0;

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Section Progress',
                          style: TextStyle(
                            fontSize: deviceType == DeviceType.mobile ? 16.0 : 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Real-time completion badge
                        if (completedTopics == totalTopics && totalTopics > 0)
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
                                  'COMPLETE',
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedTopics / $totalTopics topics completed',
                          style: TextStyle(
                            fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${(progressPercentage * 100).round()}%',
                          style: TextStyle(
                            fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: progressPercentage == 1.0 ? Colors.green : Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade300,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercentage,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressPercentage == 1.0 ? Colors.green : Theme.of(context).primaryColor,
                          ),
                          minHeight: 8,
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

  Widget _buildTopicsList(BuildContext context, DeviceType deviceType, bool isLandscape) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<UserProgress>(
          future: _getUserProgress(appState),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: widget.section.topics.map((topic) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: deviceType == DeviceType.mobile ? 12.0 : 16.0),
                    child: Card(
                      elevation: 1,
                      child: Container(
                        height: 120,
                        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 12.0 : 16.0),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            final userProgress = snapshot.data ?? UserProgress.empty();

            return Column(
              children: widget.section.topics.map((topic) {
                // Real-time completion status
                final isCompleted = userProgress.completedTopics.contains(topic.id);

                return Padding(
                  padding: EdgeInsets.only(bottom: deviceType == DeviceType.mobile ? 12.0 : 16.0),
                  child: _buildTopicCard(context, topic, isCompleted, deviceType),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildTopicCard(BuildContext context, LearningTopic topic, bool isCompleted, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final hasQuiz = QuizIntegrationService.isTopicQuizImplemented(widget.section.id, topic.id);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic header with completion status
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green.shade700 : null,
                    ),
                  ),
                ),
                // Real-time completion indicator
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Topic description
            Text(
              topic.description,
              style: TextStyle(
                fontSize: bodyFontSize,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Topic metadata
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${topic.estimatedReadTime.inMinutes} min read',
                  style: TextStyle(
                    fontSize: bodyFontSize - 2,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (hasQuiz) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.quiz, size: 14, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Quiz available',
                    style: TextStyle(
                      fontSize: bodyFontSize - 2,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),

            // Action buttons
            if (hasQuiz) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToTopicQuiz(context, topic),
                      icon: const Icon(Icons.quiz, size: 16),
                      label: Text(
                        isCompleted ? 'Retake Quiz' : 'Take Quiz',
                        style: TextStyle(fontSize: bodyFontSize - 2),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isCompleted ? Colors.green : Colors.blue,
                        side: BorderSide(color: isCompleted ? Colors.green : Colors.blue),
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
                      label: Text(
                        'Read Topic',
                        style: TextStyle(fontSize: bodyFontSize - 2),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getLevelColor(widget.section.level),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToTopicDetail(context, topic),
                  icon: const Icon(Icons.book, size: 16),
                  label: Text(
                    'Read Topic',
                    style: TextStyle(fontSize: bodyFontSize - 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getLevelColor(widget.section.level),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionQuizCard(BuildContext context, DeviceType deviceType) {
    final hasQuiz = QuizIntegrationService.isSectionQuizImplemented(widget.section.id);

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return FutureBuilder<UserProgress>(
          future: _getUserProgress(appState),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 2,
                child: Container(
                  height: 150,
                  padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final userProgress = snapshot.data ?? UserProgress.empty();
            final sectionCompleted = userProgress.completedSections.contains(widget.section.id);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: sectionCompleted
                      ? Colors.green.withOpacity(0.3)
                      : Theme.of(context).primaryColor.withOpacity(0.3),
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
                            'Section Quiz',
                            style: TextStyle(
                              fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
                              fontWeight: FontWeight.bold,
                              color: sectionCompleted ? Colors.green.shade700 : null,
                            ),
                          ),
                        ),
                        // Section completion indicator
                        if (sectionCompleted)
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
                      'Test your knowledge of all topics in this section.',
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: hasQuiz ? () => _navigateToSectionQuiz(context) : null,
                        icon: Icon(
                          hasQuiz ? Icons.play_arrow : Icons.construction,
                          size: 20,
                        ),
                        label: Text(
                          hasQuiz
                              ? (sectionCompleted ? 'Retake Section Quiz' : 'Take Section Quiz')
                              : 'Coming Soon',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasQuiz
                              ? (sectionCompleted ? Colors.green : _getLevelColor(widget.section.level))
                              : Colors.grey.shade300,
                          foregroundColor: hasQuiz ? Colors.white : Colors.grey.shade600,
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
          section: widget.section,
        ),
      ),
    );
  }

  void _navigateToTopicQuiz(BuildContext context, LearningTopic topic) {
    final quizController = Provider.of<QuizController>(context, listen: false);

    QuizIntegrationService.navigateToTopicQuiz(
      context: context,
      topic: topic,
      section: widget.section,
      quizController: quizController,
    ).then((_) {
      // Progress will be automatically updated via the listener
      // No need for manual refresh here
    });
  }

  void _navigateToSectionQuiz(BuildContext context) {
    final quizController = Provider.of<QuizController>(context, listen: false);

    QuizIntegrationService.navigateToSectionQuiz(
      context: context,
      section: widget.section,
      quizController: quizController,
    ).then((_) {
      // Progress will be automatically updated via the listener
      // No need for manual refresh here
    });
  }
}