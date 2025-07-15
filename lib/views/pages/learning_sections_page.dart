// lib/views/pages/learning_sections_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/learning/learning_content.dart';
import '../../models/user/user.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
import 'learning_topics_page.dart';
import '../../modules/quiz/views/quiz_landing_view.dart';

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
            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionsList(BuildContext context, DeviceType deviceType, bool isLandscape) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final sections = LearningContentRepository.getAllSections();
        
        if (sections.isEmpty) {
          return _buildEmptyState(context, deviceType);
        }

        return Column(
          children: sections.map((section) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildSectionCard(context, section, deviceType, isLandscape),
          )).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, DeviceType deviceType) {
    final fontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No learning content available',
              style: TextStyle(
                fontSize: fontSize,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, LearningSection section, DeviceType deviceType, bool isLandscape) {
    final theme = Theme.of(context);
    final cardPadding = deviceType == DeviceType.mobile ? 16.0 : 20.0;
    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final descriptionFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    
    // Get section progress
    final sectionProgress = user?.progress.getSectionProgress(section.id);
    final progressPercentage = sectionProgress?.progressPercentage ?? 0.0;
    final completedTopics = sectionProgress?.topicsCompleted ?? 0;
    final totalTopics = section.topics.length;
    final hasTopics = totalTopics > 0;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: hasTopics
            ? () => _navigateToTopics(context, section)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getLevelColor(section.level).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getLevelIcon(section.level),
                      color: _getLevelColor(section.level),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${section.level.displayName} • $totalTopics topics',
                          style: TextStyle(
                            fontSize: descriptionFontSize - 2,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                section.description,
                style: TextStyle(
                  fontSize: descriptionFontSize,
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasTopics) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progressPercentage,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(section.level)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedTopics/$totalTopics topics completed',
                      style: TextStyle(
                        fontSize: descriptionFontSize - 2,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    Text(
                      '${(progressPercentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: descriptionFontSize - 2,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(section.level),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionButtons(context, section, deviceType, hasTopics),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LearningSection section, DeviceType deviceType, bool hasTopics) {
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
              onPressed: hasTopics 
                  ? () => _navigateToTopics(context, section)
                  : null,
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

  IconData _getLevelIcon(LearningLevel level) {
    switch (level) {
      case LearningLevel.introduction:
        return Icons.school;
      case LearningLevel.fundamentals:
        return Icons.foundation;
      case LearningLevel.essentials:
        return Icons.star_border;
      case LearningLevel.intermediate:
        return Icons.piano;
      case LearningLevel.advanced:
        return Icons.music_note;
      case LearningLevel.professional:
        return Icons.workspace_premium;
      case LearningLevel.master:
        return Icons.emoji_events;
      case LearningLevel.virtuoso:
        return Icons.stars;
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizLandingView(
          sectionId: section.id,
        ),
      ),
    );
  }
}