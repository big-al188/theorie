// lib/views/pages/quiz_placeholder_page.dart
import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

class QuizPlaceholderPage extends StatelessWidget {
  final String title;
  final String description;
  final String? topicId;
  final String? sectionId;

  const QuizPlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    this.topicId,
    this.sectionId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz',
          style: TextStyle(
            fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
          ),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_getPadding(deviceType, isLandscape)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: deviceType == DeviceType.mobile ? double.infinity : 600.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  _buildQuizIcon(deviceType),
                  SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
                  _buildTitle(context, deviceType),
                  SizedBox(height: deviceType == DeviceType.mobile ? 16.0 : 20.0),
                  _buildDescription(context, deviceType),
                  SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
                  _buildComingSoonCard(context, deviceType),
                  SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
                  _buildFeaturesPreview(context, deviceType),
                  SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
                  _buildBackButton(context, deviceType),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 20.0;
    }
    return deviceType == DeviceType.mobile ? 24.0 : 32.0;
  }

  Widget _buildQuizIcon(DeviceType deviceType) {
    final iconSize = deviceType == DeviceType.mobile ? 80.0 : 100.0;
    
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(iconSize / 2),
        border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 2),
      ),
      child: Icon(
        Icons.quiz,
        size: iconSize * 0.5,
        color: Colors.indigo,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;
    
    return Text(
      title,
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.indigo,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context, DeviceType deviceType) {
    final descriptionFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    
    return Text(
      description,
      style: TextStyle(
        fontSize: descriptionFontSize,
        color: Colors.grey.shade600,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildComingSoonCard(BuildContext context, DeviceType deviceType) {
    final cardPadding = deviceType == DeviceType.mobile ? 20.0 : 24.0;
    final titleFontSize = deviceType == DeviceType.mobile ? 20.0 : 24.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;

    return Card(
      elevation: 4,
      color: Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.construction,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quiz Coming Soon!',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'We\'re working hard to create interactive quizzes that will test your knowledge '
              'and help you master music theory concepts. The quiz system will include:',
              style: TextStyle(
                fontSize: bodyFontSize,
                color: Colors.orange.shade800,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesPreview(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 20.0;
    final bodyFontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;

    final features = [
      {
        'icon': Icons.track_changes,
        'title': 'Progress Tracking',
        'description': 'Track your learning progress and quiz scores',
      },
      {
        'icon': Icons.psychology,
        'title': 'Adaptive Learning',
        'description': 'Questions that adapt to your skill level',
      },
      {
        'icon': Icons.music_note,
        'title': 'Audio Examples',
        'description': 'Listen to musical examples in quiz questions',
      },
      {
        'icon': Icons.emoji_events,
        'title': 'Achievements',
        'description': 'Earn badges and unlock new sections',
      },
    ];

    return Column(
      children: [
        Text(
          'Upcoming Quiz Features',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      feature['description'] as String,
                      style: TextStyle(
                        fontSize: bodyFontSize - 2,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, DeviceType deviceType) {
    final buttonHeight = deviceType == DeviceType.mobile ? 48.0 : 56.0;
    final fontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, size: 20),
        label: Text(
          'Back to Learning',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}