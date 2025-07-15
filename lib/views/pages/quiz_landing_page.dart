// lib/views/pages/quiz_landing_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quiz_controller.dart';
import '../../controllers/quiz_question_generator.dart';
import '../../models/quiz/quiz_question.dart';
import '../../models/quiz/quiz_session.dart';
import 'quiz_page.dart';

/// Landing page for quiz selection and configuration
///
/// This page allows users to:
/// - Choose quiz topics and difficulty
/// - Configure quiz settings
/// - Start new quiz sessions
/// - View quiz statistics
class QuizLandingPage extends StatefulWidget {
  const QuizLandingPage({super.key});

  @override
  State<QuizLandingPage> createState() => _QuizLandingPageState();
}

class _QuizLandingPageState extends State<QuizLandingPage> {
  final QuizQuestionGenerator _generator = QuizQuestionGenerator();

  // Quiz configuration
  QuestionTopic? _selectedTopic;
  QuestionDifficulty? _selectedDifficulty;
  int _questionCount = 10;
  int? _timeLimit; // in minutes
  bool _allowSkip = true;
  bool _allowReview = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Theory Quiz'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: 32),
            _buildQuickStartSection(context),
            const SizedBox(height: 32),
            _buildCustomQuizSection(context),
            const SizedBox(height: 32),
            _buildStatsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Welcome to Music Theory Quiz',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Test your knowledge of music theory concepts including notes, intervals, scales, chords, and more. Choose from quick practice sessions or customize your own quiz experience.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickStartCard(
              context,
              'Beginner Review',
              'Basic concepts and fundamentals',
              Icons.school,
              Colors.green,
              () => _startQuickQuiz(QuestionDifficulty.beginner),
            ),
            _buildQuickStartCard(
              context,
              'Intermediate Practice',
              'More challenging questions',
              Icons.trending_up,
              Colors.orange,
              () => _startQuickQuiz(QuestionDifficulty.intermediate),
            ),
            _buildQuickStartCard(
              context,
              'Mixed Review',
              'All topics and difficulties',
              Icons.shuffle,
              Colors.blue,
              () => _startMixedQuiz(),
            ),
            _buildQuickStartCard(
              context,
              'Advanced Challenge',
              'Expert level questions',
              Icons.workspace_premium,
              Colors.purple,
              () => _startQuickQuiz(QuestionDifficulty.advanced),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStartCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomQuizSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Quiz',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic selection
                Text(
                  'Topic (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<QuestionTopic?>(
                  value: _selectedTopic,
                  decoration: const InputDecoration(
                    hintText: 'All topics',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<QuestionTopic?>(
                      value: null,
                      child: Text('All topics'),
                    ),
                    ...QuestionTopic.values.map((topic) => DropdownMenuItem(
                          value: topic,
                          child: Text(_capitalizeFirst(topic.name)),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedTopic = value),
                ),
                const SizedBox(height: 16),

                // Difficulty selection
                Text(
                  'Difficulty (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<QuestionDifficulty?>(
                  value: _selectedDifficulty,
                  decoration: const InputDecoration(
                    hintText: 'All difficulties',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<QuestionDifficulty?>(
                      value: null,
                      child: Text('All difficulties'),
                    ),
                    ...QuestionDifficulty.values
                        .map((difficulty) => DropdownMenuItem(
                              value: difficulty,
                              child: Text(_capitalizeFirst(difficulty.name)),
                            )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedDifficulty = value),
                ),
                const SizedBox(height: 16),

                // Question count
                Text(
                  'Number of Questions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _questionCount.toDouble(),
                        min: 5,
                        max: 20,
                        divisions: 15,
                        label: _questionCount.toString(),
                        onChanged: (value) =>
                            setState(() => _questionCount = value.round()),
                      ),
                    ),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text(
                        '$_questionCount',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time limit
                Row(
                  children: [
                    Checkbox(
                      value: _timeLimit != null,
                      onChanged: (value) => setState(() {
                        _timeLimit = value == true ? 15 : null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time Limit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (_timeLimit != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _timeLimit!.toDouble(),
                                min: 5,
                                max: 30,
                                divisions: 25,
                                label: '${_timeLimit!} min',
                                onChanged: (value) =>
                                    setState(() => _timeLimit = value.round()),
                              ),
                            ),
                            Text('${_timeLimit!} min'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Quiz options
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Allow Skip'),
                        value: _allowSkip,
                        onChanged: (value) =>
                            setState(() => _allowSkip = value ?? true),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Allow Review'),
                        value: _allowReview,
                        onChanged: (value) =>
                            setState(() => _allowReview = value ?? true),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Available questions info
                _buildAvailableQuestionsInfo(),
                const SizedBox(height: 20),

                // Start custom quiz button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canStartCustomQuiz() ? _startCustomQuiz : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Custom Quiz'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableQuestionsInfo() {
    final availableCount = _generator.getAvailableQuestionCount(
      topics: _selectedTopic != null ? [_selectedTopic!] : [],
      difficulties: _selectedDifficulty != null ? [_selectedDifficulty!] : [],
    );

    final color =
        availableCount >= _questionCount ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$availableCount questions available with current filters',
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final stats = _generator.getQuestionPoolStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Pool Statistics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatRow('Total Questions', '${stats['totalQuestions']}'),
                const Divider(),
                Text(
                  'By Topic',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...(stats['topicBreakdown'] as Map<String, int>).entries.map(
                      (entry) => _buildStatRow(
                          _capitalizeFirst(entry.key), '${entry.value}'),
                    ),
                const Divider(),
                Text(
                  'By Difficulty',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...(stats['difficultyBreakdown'] as Map<String, int>)
                    .entries
                    .map(
                      (entry) => _buildStatRow(
                          _capitalizeFirst(entry.key), '${entry.value}'),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Event handlers
  bool _canStartCustomQuiz() {
    final availableCount = _generator.getAvailableQuestionCount(
      topics: _selectedTopic != null ? [_selectedTopic!] : [],
      difficulties: _selectedDifficulty != null ? [_selectedDifficulty!] : [],
    );
    return availableCount >= _questionCount;
  }

  void _startQuickQuiz(QuestionDifficulty difficulty) {
    _startQuiz(
      config: QuizGenerationConfig(
        questionCount: 10,
        difficulties: [difficulty],
      ),
      title: '${_capitalizeFirst(difficulty.name)} Quiz',
    );
  }

  void _startMixedQuiz() {
    _startQuiz(
      config: const QuizGenerationConfig(
        questionCount: 15,
      ),
      title: 'Mixed Review Quiz',
    );
  }

  void _startCustomQuiz() {
    _startQuiz(
      config: QuizGenerationConfig(
        questionCount: _questionCount,
        topics: _selectedTopic != null ? [_selectedTopic!] : [],
        difficulties: _selectedDifficulty != null ? [_selectedDifficulty!] : [],
      ),
      title: _buildCustomQuizTitle(),
      allowSkip: _allowSkip,
      allowReview: _allowReview,
      timeLimit: _timeLimit,
    );
  }

  void _startQuiz({
    required QuizGenerationConfig config,
    required String title,
    bool allowSkip = true,
    bool allowReview = true,
    int? timeLimit,
  }) async {
    try {
      // Generate questions
      final questions = _generator.generateQuiz(config);

      // Get quiz controller
      final quizController =
          Provider.of<QuizController>(context, listen: false);

      // Start the quiz
      await quizController.startQuiz(
        questions: questions,
        quizType: QuizType.practice,
        title: title,
        allowSkip: allowSkip,
        allowReview: allowReview,
        timeLimit: timeLimit,
      );

      // Navigate to quiz page
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizPage(title: title),
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Failed to start quiz: $e');
    }
  }

  String _buildCustomQuizTitle() {
    final parts = <String>[];

    if (_selectedTopic != null) {
      parts.add(_capitalizeFirst(_selectedTopic!.name));
    }

    if (_selectedDifficulty != null) {
      parts.add(_capitalizeFirst(_selectedDifficulty!.name));
    }

    parts.add('Quiz');

    return parts.join(' ');
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
