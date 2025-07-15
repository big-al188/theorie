// lib/views/pages/learning_sections_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../models/user/user.dart';
import '../../constants/ui_constants.dart';
import '../../controllers/quiz_controller.dart';
import '../../services/quiz_integration_service.dart';
import '../widgets/common/app_bar.dart';
import 'learning_topics_page.dart';

class LearningSectionsPage extends StatelessWidget {
  const LearningSectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: const TheorieAppBar(
        title: 'Learning Sections',
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
              SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
              _buildSectionsList(context, deviceType, isLandscape),
            ],
          ),
        ),
      ),
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
        Text(
          'Choose Your Learning Path',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Progress through different levels of music theory, from beginner to expert. '
          'Each section contains topics and quizzes to test your knowledge.',
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionsList(
      BuildContext context, DeviceType deviceType, bool isLandscape) {
    final sections = LearningContentRepository.getAllSections();

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          children: sections.map((section) {
            final progress =
                appState.currentUser?.progress.getSectionProgress(section.id) ??
                    SectionProgress(
                      topicsCompleted: 0,
                      totalTopics: section.totalTopics,
                      sectionQuizCompleted: false,
                    );

            return Padding(
              padding: EdgeInsets.only(
                bottom: deviceType == DeviceType.mobile ? 16.0 : 20.0,
              ),
              child: _buildSectionCard(context, section, progress, deviceType),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionCard(BuildContext context, LearningSection section,
      SectionProgress progress, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final hasTopics = section.hasTopics;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getLevelColor(section.level).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with level indicator
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(section.level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level ${section.order}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(section.level),
                    ),
                  ),
                ),
                // Quiz availability indicator
                if (QuizIntegrationService.isSectionQuizImplemented(section.id))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz,
                            size: 12, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Quiz Ready',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              section.description,
              style: TextStyle(
                fontSize: bodyFontSize,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Progress indicator
            if (hasTopics)
              _buildProgressIndicator(context, progress, deviceType),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(context, section, hasTopics, deviceType),

            // Coming soon indicator for sections without topics
            if (!hasTopics) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.construction,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Content coming soon...',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
      BuildContext context, SectionProgress progress, DeviceType deviceType) {
    final progressPercentage = progress.progressPercentage;
    final completedTopics = progress.topicsCompleted;
    final totalTopics = progress.totalTopics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$completedTopics / $totalTopics topics',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 12.0 : 14.0,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progressPercentage,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            progressPercentage == 1.0
                ? Colors.green
                : Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, LearningSection section,
      bool hasTopics, DeviceType deviceType) {
    final buttonHeight = deviceType == DeviceType.mobile ? 40.0 : 48.0;
    final fontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;

    return Row(
      children: [
        // Explore Topics button
        Expanded(
          flex: 2,
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton.icon(
              onPressed:
                  hasTopics ? () => _navigateToTopics(context, section) : null,
              icon: const Icon(Icons.book, size: 18),
              label: Text(
                'Explore Topics',
                style: TextStyle(fontSize: fontSize),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getLevelColor(section.level),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Quiz Section button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: buttonHeight,
            child: OutlinedButton.icon(
              onPressed: hasTopics
                  ? () => _navigateToSectionQuiz(context, section)
                  : null,
              icon: const Icon(Icons.quiz, size: 18),
              label: Text(
                'Quiz',
                style: TextStyle(fontSize: fontSize),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getLevelColor(section.level),
                side: BorderSide(color: _getLevelColor(section.level)),
              ),
            ),
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

  void _navigateToTopics(BuildContext context, LearningSection section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearningTopicsPage(section: section),
      ),
    );
  }

  void _navigateToSectionQuiz(BuildContext context, LearningSection section) {
    final quizController = Provider.of<QuizController>(context, listen: false);

    QuizIntegrationService.navigateToSectionQuiz(
      context: context,
      section: section,
      quizController: quizController,
    );
  }
}
