import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_template.dart';
import '../models/quiz_enums.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/quiz_generator.dart';
import '../controllers/quiz_history_controller.dart';
import '../data/quiz_templates/introduction_templates.dart';
import 'quiz_active_view.dart';
import 'quiz_history_view.dart';

/// Main landing page for quiz selection
class QuizLandingView extends StatefulWidget {
  final String sectionId;
  final String? topicId;

  const QuizLandingView({
    Key? key,
    required this.sectionId,
    this.topicId,
  }) : super(key: key);

  @override
  State<QuizLandingView> createState() => _QuizLandingViewState();
}

class _QuizLandingViewState extends State<QuizLandingView> {
  QuizType _selectedType = QuizType.section;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _navigateToHistory(context),
            tooltip: 'Quiz History',
          ),
        ],
      ),
      body: SafeArea(
        child: _isGenerating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 24),
                    _buildQuizTypeSelector(theme),
                    const SizedBox(height: 24),
                    _buildQuizGrid(theme),
                    const SizedBox(height: 32),
                    _buildPausedQuizSection(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Your Knowledge',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a quiz type to practice what you\'ve learned',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizTypeSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: QuizType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizGrid(ThemeData theme) {
    final templates = _getTemplatesForType();

    if (templates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No quizzes available for this type',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Quizzes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            return _buildQuizCard(templates[index], theme);
          },
        ),
      ],
    );
  }

  Widget _buildQuizCard(QuizTemplate template, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _startQuiz(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconForQuizType(template.quizType),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${template.totalQuestions} questions',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '~${template.estimatedMinutes} minutes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildDifficultyIndicator(template.difficultyRange, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(DifficultyRange range, ThemeData theme) {
    final difficulties = range.difficultiesInRange;
    
    return Row(
      children: [
        Text(
          'Difficulty: ',
          style: theme.textTheme.bodySmall,
        ),
        ...difficulties.map((difficulty) {
          final color = _getColorForDifficulty(difficulty, theme);
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPausedQuizSection(BuildContext context) {
    return Consumer<QuizHistoryController>(
      builder: (context, historyController, child) {
        final pausedQuizzes = historyController.getPausedQuizzes();
        
        if (pausedQuizzes.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume Quiz',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...pausedQuizzes.map((quiz) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getIconForQuizType(quiz.type),
                  color: theme.colorScheme.primary,
                ),
                title: Text(quiz.metadata.title),
                subtitle: Text(
                  'Progress: ${quiz.progress.toStringAsFixed(0)}% • '
                  '${quiz.answers.length}/${quiz.questions.length} answered',
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => _resumeQuiz(quiz.id),
              ),
            )),
          ],
        );
      },
    );
  }

  List<QuizTemplate> _getTemplatesForType() {
    // For now, using Introduction templates
    // In the future, this would check the section
    return IntroductionTemplates.getTemplatesByType(_selectedType);
  }

  IconData _getIconForQuizType(QuizType type) {
    switch (type) {
      case QuizType.section:
        return Icons.folder_outlined;
      case QuizType.topic:
        return Icons.topic_outlined;
      case QuizType.refresher:
        return Icons.refresh;
      case QuizType.custom:
        return Icons.tune;
    }
  }

  Color _getColorForDifficulty(DifficultyLevel difficulty, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return colorScheme.error;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }

  Future<void> _startQuiz(QuizTemplate template) async {
    setState(() => _isGenerating = true);

    try {
      final generator = context.read<QuizGenerator>();
      final controller = context.read<QuizController>();
      
      final quiz = await generator.generateFromTemplate(template);
      await controller.startQuiz(quiz);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const QuizActiveView(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate quiz: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _resumeQuiz(String quizId) async {
    try {
      final controller = context.read<QuizController>();
      await controller.resumeQuiz(quizId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const QuizActiveView(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume quiz: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QuizHistoryView(),
      ),
    );
  }
}