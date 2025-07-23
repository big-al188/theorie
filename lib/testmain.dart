// lib/main.dart - Temporary modification for QuestionWidget testing

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'controllers/unified_quiz_generator.dart';
import 'models/quiz/scale_strip_question.dart';
import 'models/quiz/quiz_question.dart';
import 'views/widgets/quiz/question_widget.dart';

void main() {
  runApp(const QuestionWidgetTestApp());
}

class QuestionWidgetTestApp extends StatelessWidget {
  const QuestionWidgetTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Question Widget Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const QuestionWidgetTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QuestionWidgetTestPage extends StatefulWidget {
  const QuestionWidgetTestPage({super.key});

  @override
  State<QuestionWidgetTestPage> createState() => _QuestionWidgetTestPageState();
}

class _QuestionWidgetTestPageState extends State<QuestionWidgetTestPage> {
  QuizQuestion? _testQuestion;
  dynamic _selectedAnswer;
  String _debugInfo = 'Loading...';
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _runTests() {
    setState(() {
      _debugInfo = 'Running tests...';
    });

    try {
      // Test 1: Check if enum exists
      final enumTest = _testEnum();
      
      // Test 2: Generate question
      final questionTest = _testQuestionGeneration();
      
      // Test 3: Test widget creation
      final widgetTest = _testWidgetCreation();
      
      setState(() {
        _testResults = '''
📊 TEST RESULTS:
===============

1. ENUM TEST:
$enumTest

2. QUESTION GENERATION TEST:
$questionTest

3. WIDGET CREATION TEST:
$widgetTest
        ''';
      });
      
    } catch (e, stackTrace) {
      setState(() {
        _debugInfo = 'Test failed: $e';
        _testResults = 'Stack trace:\n$stackTrace';
      });
    }
  }

  String _testEnum() {
    try {
      final scaleStripType = QuestionType.scaleStrip;
      final allTypes = QuestionType.values;
      
      return '''
✅ QuestionType.scaleStrip exists: $scaleStripType
✅ All available types: ${allTypes.map((t) => t.toString().split('.').last)}
✅ Enum count: ${allTypes.length}''';
    } catch (e) {
      return '❌ Enum test failed: $e';
    }
  }

  String _testQuestionGeneration() {
    try {
      final generator = UnifiedQuizGenerator();
      
      // Check if topic is implemented
      final isImplemented = generator.isTopicImplemented('introduction', 'scale-strip-quiz');
      final questionCount = generator.getTopicQuestionCount('introduction', 'scale-strip-quiz');
      
      if (!isImplemented || questionCount == 0) {
        return '''
❌ Topic not properly implemented
   - Is implemented: $isImplemented
   - Question count: $questionCount''';
      }
      
      // Generate questions
      final questions = generator.generateTopicQuiz(
        sectionId: 'introduction',
        topicId: 'scale-strip-quiz',
        questionCount: 1,
      );
      
      if (questions.isEmpty) {
        return '❌ No questions generated';
      }
      
      final question = questions.first;
      setState(() {
        _testQuestion = question;
        _selectedAnswer = question is ScaleStripQuestion 
          ? const ScaleStripAnswer(selectedPositions: {}, selectedNotes: {})
          : null;
      });
      
      return '''
✅ Question generated successfully
   - ID: ${question.id}
   - Type: ${question.type}
   - Runtime Type: ${question.runtimeType}
   - Is ScaleStripQuestion: ${question is ScaleStripQuestion}
   - Type equals scaleStrip: ${question.type == QuestionType.scaleStrip}''';
      
    } catch (e) {
      return '❌ Question generation failed: $e';
    }
  }

  String _testWidgetCreation() {
    if (_testQuestion == null) {
      return '❌ No test question available';
    }
    
    try {
      final question = _testQuestion!;
      
      // Test the logic that QuestionWidget uses
      if (question.type == QuestionType.scaleStrip) {
        if (question is ScaleStripQuestion) {
          return '''
✅ Widget creation should succeed
   - Type check passed: ${question.type == QuestionType.scaleStrip}
   - Runtime check passed: ${question is ScaleStripQuestion}
   - Ready for QuestionWidget''';
        } else {
          return '''
❌ Type mismatch detected
   - Type check: ${question.type == QuestionType.scaleStrip}
   - Runtime check: ${question is ScaleStripQuestion}
   - This will cause QuestionWidget to fail''';
        }
      } else {
        return '''
❌ Question type is not scaleStrip
   - Expected: QuestionType.scaleStrip
   - Actual: ${question.type}''';
      }
    } catch (e) {
      return '❌ Widget creation test failed: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Widget Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _testResults,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _runTests,
                      child: const Text('Re-run Tests'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Question Widget Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QuestionWidget Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_testQuestion != null) ...[
                      Text(
                        'Testing with question: ${_testQuestion!.id}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // The actual QuestionWidget test
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QuestionWidget(
                          question: _testQuestion!,
                          selectedAnswer: _selectedAnswer,
                          onAnswerSelected: (answer) {
                            setState(() {
                              _selectedAnswer = answer;
                            });
                            print('✅ Answer selected: $answer');
                          },
                          showCorrectAnswer: false,
                          enabled: true,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'No test question available. Check test results above.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Debug Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _debugInfo,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_selectedAnswer != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Current Answer: $_selectedAnswer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}