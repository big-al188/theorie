# Sections and Topics Creation Guide

## Overview
This guide covers the complete process of creating new learning sections and topics in the Theorie app. The learning content is organized into 8 tiers (Introduction through Virtuoso) with each tier containing multiple topics that build upon each other.

## Learning Content Architecture

### Tier Structure
The app uses an 8-tier learning system:
1. **Introduction** - Start your musical journey
2. **Fundamentals** - Build essential knowledge
3. **Essentials** - Core concepts for musicians
4. **Intermediate** - Develop deeper understanding
5. **Advanced** - Master complex concepts
6. **Professional** - Industry-level expertise
7. **Master** - Comprehensive mastery
8. **Virtuoso** - Push the boundaries

### File Organization
```
lib/models/learning/
├── learning_content.dart           # Core models and repository
├── tiers/
│   ├── introduction_tier.dart      # Introduction section
│   ├── fundamentals_tier.dart      # Fundamentals section
│   ├── essentials_tier.dart        # Essentials section
│   ├── intermediate_tier.dart      # Intermediate section
│   ├── advanced_tier.dart          # Advanced section
│   ├── professional_tier.dart      # Professional section
│   ├── master_tier.dart            # Master section
│   └── virtuoso_tier.dart          # Virtuoso section
```

## Core Data Models

### LearningSection Model
```dart
class LearningSection {
  final String id;
  final String title;
  final String description;
  final List<LearningTopic> topics;
  final int order;
  final LearningLevel level;

  const LearningSection({
    required this.id,
    required this.title,
    required this.description,
    required this.topics,
    required this.order,
    required this.level,
  });

  // Utility methods
  int get totalTopics => topics.length;
  bool get hasTopics => topics.isNotEmpty;
}
```

### LearningTopic Model
```dart
class LearningTopic {
  final String id;
  final String title;
  final String description;
  final String content;
  final List<String> keyPoints;
  final List<String> examples;
  final int order;
  final Duration estimatedReadTime;

  const LearningTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.keyPoints,
    required this.examples,
    required this.order,
    required this.estimatedReadTime,
  });
}
```

### LearningLevel Enum
```dart
enum LearningLevel {
  introduction('Introduction', 'Start your musical journey'),
  fundamentals('Fundamentals', 'Build essential knowledge'),
  essentials('Essentials', 'Core concepts for musicians'),
  intermediate('Intermediate', 'Develop deeper understanding'),
  advanced('Advanced', 'Master complex concepts'),
  professional('Professional', 'Industry-level expertise'),
  master('Master', 'Comprehensive mastery'),
  virtuoso('Virtuoso', 'Push the boundaries');

  const LearningLevel(this.displayName, this.description);
  final String displayName;
  final String description;
}
```

## Creating a New Section

### Step 1: Create the Tier File
Create a new file in `lib/models/learning/tiers/` following the naming pattern:

```dart
// lib/models/learning/tiers/example_tier.dart

import '../learning_content.dart';

class ExampleTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'example',
      title: 'Example Section',
      description: 'Description of what this section covers',
      level: LearningLevel.fundamentals, // Choose appropriate level
      order: 2, // Order within the tier system
      topics: [
        _createTopic1(),
        _createTopic2(),
        _createTopic3(),
      ],
    );
  }

  static LearningTopic _createTopic1() {
    return LearningTopic(
      id: 'example_topic_1',
      title: 'First Topic',
      description: 'Brief description of the first topic',
      content: _getContent1(),
      keyPoints: [
        'Key point 1',
        'Key point 2',
        'Key point 3',
      ],
      examples: [
        'Example 1',
        'Example 2',
      ],
      order: 1,
      estimatedReadTime: Duration(minutes: 5),
    );
  }

  static String _getContent1() {
    return '''
# First Topic

## Introduction
Detailed explanation of the topic...

## Key Concepts
- Concept 1
- Concept 2
- Concept 3

## Examples
Example explanations...

## Practice Exercises
Suggested exercises...
    ''';
  }

  // Continue with _createTopic2(), _createTopic3(), etc.
}
```

### Step 2: Update the LearningContentRepository
Add your new section to the repository in `lib/models/learning/learning_content.dart`:

```dart
class LearningContentRepository {
  static final Map<LearningLevel, LearningSection> _sections = {
    LearningLevel.introduction: IntroductionTier.getSection(),
    LearningLevel.fundamentals: FundamentalsTier.getSection(),
    LearningLevel.essentials: EssentialsTier.getSection(),
    LearningLevel.example: ExampleTier.getSection(), // Add your section
    // ... other sections
  };
}
```

### Step 3: Update the LearningLevel Enum
If creating a new tier level, add it to the enum:

```dart
enum LearningLevel {
  introduction('Introduction', 'Start your musical journey'),
  fundamentals('Fundamentals', 'Build essential knowledge'),
  example('Example', 'Example tier description'), // Add new level
  // ... other levels
}
```

## Creating New Topics

### Topic Structure Guidelines
Each topic should follow this structure:

1. **Clear Title** - Descriptive and engaging
2. **Brief Description** - One-sentence summary
3. **Comprehensive Content** - Detailed explanation with examples
4. **Key Points** - 3-5 bullet points of main concepts
5. **Examples** - Practical applications
6. **Estimated Read Time** - Realistic time estimate

### Content Writing Guidelines

#### 1. Use Clear, Progressive Structure
```dart
static String _getScaleContent() {
  return '''
# Major Scales

## What is a Major Scale?
A major scale is a sequence of seven notes that creates a happy, bright sound...

## How to Build a Major Scale
The major scale follows a specific pattern of whole and half steps:
W-W-H-W-W-W-H

## Examples
- C Major: C-D-E-F-G-A-B-C
- G Major: G-A-B-C-D-E-F#-G

## Practice Exercises
1. Play the C major scale on your guitar
2. Identify the pattern on the fretboard
3. Try other keys following the same pattern
  ''';
}
```

#### 2. Include Practical Examples
```dart
examples: [
  'C Major scale: C-D-E-F-G-A-B-C',
  'G Major scale: G-A-B-C-D-E-F#-G',
  'Practice on frets 3-5 for C Major',
],
```

#### 3. Provide Clear Key Points
```dart
keyPoints: [
  'Major scales use the W-W-H-W-W-W-H pattern',
  'There are 12 major scales, one for each note',
  'Major scales create a bright, happy sound',
  'Practice scales to improve finger dexterity',
],
```

### Topic ID Naming Convention
Follow this naming pattern for topic IDs:
- `{section_id}_{topic_name}` 
- Use lowercase with underscores
- Be descriptive but concise

Examples:
- `fundamentals_major_scales`
- `essentials_chord_progressions`
- `intermediate_modal_theory`

## Real-World Example: Adding a Chord Theory Section

### Step 1: Create the Section File
```dart
// lib/models/learning/tiers/chord_theory_tier.dart

import '../learning_content.dart';

class ChordTheoryTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'chord_theory',
      title: 'Chord Theory',
      description: 'Learn how chords are constructed and used in music',
      level: LearningLevel.essentials,
      order: 3,
      topics: [
        _createTriadsBasics(),
        _createChordConstruction(),
        _createChordInversions(),
        _createChordProgressions(),
      ],
    );
  }

  static LearningTopic _createTriadsBasics() {
    return LearningTopic(
      id: 'chord_theory_triads_basics',
      title: 'Basic Triads',
      description: 'Understanding three-note chords and their construction',
      content: _getTriadsContent(),
      keyPoints: [
        'Triads are three-note chords',
        'Major triads have a major third and perfect fifth',
        'Minor triads have a minor third and perfect fifth',
        'Diminished triads have a minor third and diminished fifth',
      ],
      examples: [
        'C Major triad: C-E-G',
        'C Minor triad: C-Eb-G',
        'C Diminished triad: C-Eb-Gb',
      ],
      order: 1,
      estimatedReadTime: Duration(minutes: 8),
    );
  }

  static String _getTriadsContent() {
    return '''
# Basic Triads

## What are Triads?
Triads are the foundation of harmony in Western music. They consist of three notes played simultaneously, forming the basis of most chords you'll encounter.

## Types of Triads

### Major Triads
- Built with a major third (4 semitones) and perfect fifth (7 semitones)
- Create a bright, stable sound
- Formula: Root + Major 3rd + Perfect 5th

### Minor Triads
- Built with a minor third (3 semitones) and perfect fifth (7 semitones)
- Create a darker, more emotional sound
- Formula: Root + Minor 3rd + Perfect 5th

### Diminished Triads
- Built with a minor third (3 semitones) and diminished fifth (6 semitones)
- Create tension and instability
- Formula: Root + Minor 3rd + Diminished 5th

## Practice Exercises
1. Play C major, C minor, and C diminished triads
2. Identify the intervals in each triad
3. Practice triads in different keys
4. Listen to the different qualities of each triad type
    ''';
  }

  // Continue with other topic creation methods...
}
```

### Step 2: Update Imports
In `lib/models/learning/learning_content.dart`, add the import:

```dart
import 'tiers/chord_theory_tier.dart';
```

### Step 3: Register the Section
Add to the repository:

```dart
static final Map<LearningLevel, LearningSection> _sections = {
  LearningLevel.introduction: IntroductionTier.getSection(),
  LearningLevel.fundamentals: FundamentalsTier.getSection(),
  LearningLevel.essentials: EssentialsTier.getSection(),
  LearningLevel.chord_theory: ChordTheoryTier.getSection(),
  // ... other sections
};
```

## Content Guidelines

### Writing Style
- **Clear and Concise**: Use simple, direct language
- **Progressive**: Build from basic to advanced concepts
- **Practical**: Include real-world applications
- **Engaging**: Use examples and analogies

### Technical Accuracy
- **Music Theory**: Ensure all theory is correct
- **Examples**: Verify all musical examples
- **Terminology**: Use standard music terminology
- **Consistency**: Maintain consistent explanations

### Content Structure
1. **Introduction** - What is this topic?
2. **Theory** - How does it work?
3. **Examples** - Real-world applications
4. **Practice** - Exercises and suggestions

## Integration with Quiz System

### Topic-Quiz Integration
When creating topics, consider the quiz questions that will accompany them:

```dart
// Topic creation should align with quiz questions
static LearningTopic _createScalesTopic() {
  return LearningTopic(
    id: 'fundamentals_major_scales', // Must match quiz topic ID
    title: 'Major Scales',
    // ... other properties
  );
}
```

### Quiz Question Topics
Ensure your topic IDs match the quiz question topic IDs in:
- `lib/models/quiz/sections/{section}/`
- `lib/controllers/unified_quiz_generator.dart`

## Best Practices

### 1. Maintain Consistency
- Use consistent naming conventions
- Follow the same content structure
- Maintain similar topic complexity within sections

### 2. Progressive Difficulty
- Each topic should build on previous knowledge
- Introduce concepts gradually
- Provide adequate practice opportunities

### 3. File Organization
- Keep section files under 500 lines
- Use private methods for topic creation
- Group related topics together

### 4. Content Quality
- Proofread all content thoroughly
- Verify musical examples
- Test estimated read times
- Ensure accessibility

## Testing New Content

### Manual Testing
1. **Content Display**: Verify topics appear correctly in the app
2. **Navigation**: Test navigation between topics
3. **Quiz Integration**: Ensure quizzes work with new topics
4. **Progress Tracking**: Verify progress is tracked correctly

### Automated Testing
```dart
void main() {
  group('ChordTheoryTier Tests', () {
    test('should create valid section', () {
      final section = ChordTheoryTier.getSection();
      
      expect(section.id, equals('chord_theory'));
      expect(section.topics.length, greaterThan(0));
      expect(section.level, equals(LearningLevel.essentials));
    });
    
    test('should have valid topic IDs', () {
      final section = ChordTheoryTier.getSection();
      
      for (final topic in section.topics) {
        expect(topic.id, isNotEmpty);
        expect(topic.id, startsWith('chord_theory_'));
      }
    });
  });
}
```

## Common Pitfalls to Avoid

1. **Topic ID Conflicts**: Ensure all topic IDs are unique
2. **Missing Integration**: Don't forget to update the repository
3. **Inconsistent Difficulty**: Maintain appropriate progression
4. **Poor Content Quality**: Thoroughly review all content
5. **Missing Examples**: Always include practical examples

## Maintenance and Updates

### Updating Existing Topics
1. Modify the topic creation method
2. Update estimated read times if needed
3. Test the changes thoroughly
4. Consider impact on existing user progress

### Adding Topics to Existing Sections
1. Add the new topic creation method
2. Update the section's topics list
3. Ensure proper ordering
4. Test integration with existing content

This guide provides a comprehensive approach to creating new sections and topics in the Theorie app. Follow these patterns and guidelines to ensure consistent, high-quality educational content that integrates seamlessly with the rest of the application.