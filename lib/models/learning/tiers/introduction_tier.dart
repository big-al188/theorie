// lib/models/learning/tiers/introduction_tier.dart

import '../learning_content.dart';

class IntroductionTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'introduction',
      title: 'Introduction',
      description: 'Uncover the what and why behind Theorie',
      level: LearningLevel.introduction,
      order: 1,
      topics: [
        LearningTopic(
          id: 'what-is-music-theory',
          title: 'What is Music Theory?',
          description: 'Understanding the language of music',
          order: 1,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Imagine music is the universe, and music theory helps us understand where we can go. It shows us the paths between sounds, the connections that make melodies soar and harmonies resonate.

Music theory is like learning the ABCs of music. Just as letters combine to form words and sentences, musical notes combine to create melodies and songs. The beauty is that once you understand these patterns, you can apply them to any song - whether it's classical, rock, jazz, or pop.

**Why Does This Matter?**
When you understand music theory, you're not just playing notes - you're speaking the language of music. You can:
- Understand why certain notes sound good together
- Learn new songs faster because you recognize the patterns
- Create your own music with confidence
- Communicate ideas with other musicians
- Take any song and understand its structure

**The Universal Language**
Music theory isn't about making music complicated - it's about revealing the simple patterns that all music shares. Every song you've ever loved follows these same basic principles, and now you're going to learn them too.

Remember: every great musician started exactly where you are now, learning these fundamental concepts that unlock the entire musical universe.
''',
          keyPoints: [
            'Music theory is the language of music',
            'It helps us understand how musical sounds work together',
            'Like learning ABCs, but for music',
            'Makes learning and creating music easier',
            'Helps musicians communicate with each other',
            'Every musician starts with these basics',
          ],
          examples: [
            'Figure out the chords to your favorite song just by listening',
            'Write your own melody that perfectly captures how you feel',
            'Understand why that guitar solo gives you goosebumps',
            'Jam with other musicians without needing sheet music',
            'Transform a simple idea into a complete song',
            'Recognize patterns that connect your favorite songs',
          ],
        ),
        LearningTopic(
          id: 'why-learn-music-theory',
          title: 'Why Learn Music Theory?',
          description: 'Discover the amazing benefits of understanding music',
          order: 2,
          estimatedReadTime: const Duration(minutes: 4),
          content: '''
Learning music theory opens doors to experiences that make your musical journey richer and more enjoyable. Here's what awaits you:

**Make Musical Friends**
Music theory gives you a common language to connect with other musicians. Whether you're at a jam session, in a band, or just hanging out with friends who play instruments, you'll be able to:
- Join in when someone says "let's play in the key of G"
- Suggest chord changes that could make a song better
- Share musical ideas clearly and confidently
- Be part of the worldwide community of musicians who speak this language

**Learn Songs You Love - Faster**
Instead of memorizing every single note, music theory helps you see the patterns:
- Recognize common chord progressions that appear in thousands of songs
- Figure out songs by ear because you understand how music works
- Learn one song and automatically understand similar ones
- Spend less time struggling and more time playing

**Create Your Own Music**
This is where the real magic happens. Music theory gives you the tools to:
- Turn that melody in your head into a real song
- Know which chords will support your ideas
- Express your emotions through music that others can play
- Build from simple ideas to complete compositions

**Have More Fun!**
When you understand what you're playing, everything becomes more enjoyable:
- Playing feels less like work and more like play
- You can experiment confidently, knowing what might sound good
- Jam sessions become exciting rather than intimidating
- Every practice session brings new discoveries

The best part? You don't need to master everything at once. Each concept you learn immediately makes music more fun and accessible. 
It's not about becoming a theory expert - it's about enhancing your musical journey every step of the way.
''',
          keyPoints: [
            'Helps you understand why music sounds the way it does',
            'Makes it easier to talk about music with others',
            'Speeds up learning new songs',
            'Gives you tools to create your own music',
            'Makes playing music more enjoyable',
            'Opens up a whole new world of musical understanding',
          ],
          examples: [
            'Like having a map when exploring a new place',
            'Similar to knowing game rules - makes playing more fun',
            'Like understanding how colors mix to make new colors',
            'Like learning to read - opens up new worlds of stories',
          ],
        ),
        LearningTopic(
          id: 'practice-tips',
          title: 'Practice Tips',
          description: 'Smart ways to learn music theory and have fun doing it',
          order: 3,
          estimatedReadTime: const Duration(minutes: 4),
          content: '''
Learning music theory is a journey. Here are tips to help you along the way.

**A Little Goes a Long Way**
10-15 minutes daily beats hours once a week. Your brain learns better in small, consistent doses.

**Test Your Knowledge to Identify Pain Points**
Quiz yourself regularly. When you find something challenging, that's valuable – now you know where to focus.

**Gamify Your Practice**
Make it fun: Set challenges, create point systems, race against time, compete with friends, reward milestones.

**Use Your Senses**
Don't just read – experience. Sing notes, tap rhythms, draw diagrams, listen actively, move to the music.

**Connect to Music You Enjoy**
Apply theory to songs you love. Find the chords, analyze melodies, identify patterns. Make it personal.

**Be Patient and Kind to Yourself**
Progress happens over time, not overnight. Every musician struggles before mastering. Be your own friend.

**Create a Practice Routine**
Pick a regular time. Set up your space. Start easy, learn one new thing, end with fun.

**Push Yourself Outside the Comfortable Norm**
Growth lives at the edge of comfort. When something's easy, reach for the next challenge.

**Track Your Progress in the App**
Use the app's features to see your journey. Watch streaks grow, celebrate completions.

**Celebrate Your Achievements**
Every milestone matters. Acknowledge how far you've come. Feel proud.

Remember: Every professional musician was once a beginner too. The secret is to keep going, have fun, and enjoy the journey!
''',
          keyPoints: [
            '10-15 minutes daily beats cramming',
            'Test yourself to find weak spots',
            'Turn practice into games and challenges',
            'Engage all senses - sing, tap, move',
            'Apply theory to songs you love',
            'Progress takes time - be patient',
            'Build consistent practice habits',
            'Growth happens outside comfort zones',
            'Use app features to track progress',
            'Celebrate every achievement',
          ],
          examples: [
            'Set a daily 15-minute practice alarm',
            'Quiz yourself on yesterdays concepts',
            'Tap out rhythms while listening to music',
            'Find the chords in your favorite song',
            'Journal one thing you learned each week',
            'Try a harder chord progression',
            'Check your practice streak in the app',
            'Share your progress with a friend',
          ],
        ),
        LearningTopic(
          id: 'scale-strip-quiz',
          title: 'Scale Strip Quiz',
          description: 'Interactive scale and chord exercises using the scale strip interface',
          order: 4,
          estimatedReadTime: const Duration(minutes: 10),
          hasQuiz: true,
          content: '''
# Scale Strip Quiz

Welcome to the interactive Scale Strip Quiz! This section introduces you to hands-on music theory exercises using our scale strip interface.

## What is the Scale Strip?

The scale strip is a visual representation of musical notes laid out in chromatic order. It shows all 12 notes of the chromatic scale, making it easy to see the relationships between notes, intervals, and scales.

Think of it as a musical keyboard flattened out - every note from C to B is displayed in order, and you can see exactly how many steps (semitones) are between any two notes.

## Types of Exercises

### 1. Interval Recognition
Learn to identify and select scale intervals by their numerical positions (1st, 2nd, 3rd, etc.). This helps you understand how scales are constructed using specific interval patterns.

**Example**: "Fill out the intervals for a major scale"
- You'll see a scale strip with note names
- Select the positions that correspond to 1, 2, 3, 4, 5, 6, 7, 8
- Learn the W-W-H-W-W-W-H pattern (W=whole step, H=half step)

### 2. Missing Note Completion
Practice completing scales by filling in missing notes. Some positions will be pre-highlighted, and you need to identify what's missing.

**Example**: "Fill in the missing intervals for the minor scale"
- Some scale degrees are already shown (like 1, 3, 5, 8)
- You identify and select the missing intervals (2, 4, 6, 7)
- Reinforces your understanding of scale construction

### 3. Note Name Identification
Develop your knowledge of note names by identifying missing notes in various scales and progressions.

**Example**: "Label the missing notes in the chromatic scale"
- Some notes are labeled (C, D, F, G)
- You identify the missing sharps/flats (C#, D#, F#, G#, A, A#, B)
- Strengthens your understanding of the chromatic sequence

### 4. Chord Construction
Learn to build chords by selecting the correct combination of notes from the scale strip.

**Example**: "Construct a C Major Triad"
- The scale strip shows all available notes
- You select C, E, and G to build the triad
- Understand how chords relate to scale degrees

## Benefits of Scale Strip Exercises

### Visual Learning
- **See the physical relationships** between notes
- **Understand interval distances** visually
- **Connect theory concepts** to visual patterns
- **Recognize common patterns** across different keys

### Interactive Practice
- **Hands-on engagement** reinforces learning
- **Immediate feedback** on your selections
- **Multiple attempts** to master concepts
- **Real-time validation** shows correct answers

### Pattern Recognition
- **Identify common scale patterns** (major, minor, pentatonic)
- **Recognize interval relationships** across different keys
- **Build muscle memory** for theoretical concepts
- **Connect patterns** to songs you know

### Foundation Building
- **Essential preparation** for advanced theory topics
- **Bridge between basic note recognition** and complex harmony
- **Practical application** of theoretical knowledge
- **Strong foundation** for instrument playing

## Getting Started

1. **Read each question carefully** - Understand what type of selection is required
2. **Use the visual cues** - Pre-highlighted notes and root indicators help guide you
3. **Think in patterns** - Most scales and chords follow predictable patterns
4. **Don't rush** - Take time to consider interval relationships
5. **Learn from feedback** - Review explanations to understand your mistakes

## Tips for Success

### Major Scales
- **Remember the pattern**: W-W-H-W-W-W-H (whole-whole-half-whole-whole-whole-half)
- **Start from the root** and count intervals carefully
- **All major scales** follow the same pattern, just starting from different notes

### Minor Scales
- **Natural minor pattern**: W-H-W-W-H-W-W
- **Notice the flattened degrees**: 3rd, 6th, and 7th are lowered
- **Compare to major**: Think of it as a major scale with ♭3, ♭6, ♭7

### Chromatic Scales
- **Include all 12 notes** within an octave
- **No sharps between E-F and B-C** (these are natural half steps)
- **Every other position** has a sharp/flat

### Chord Construction
- **Triads use the 1st, 3rd, and 5th degrees** of scales
- **Major triads**: major 3rd (4 semitones) + perfect 5th (7 semitones)
- **Minor triads**: minor 3rd (3 semitones) + perfect 5th (7 semitones)
- **Count semitones** to verify your chord construction

## Practice Strategy

### Start Simple
1. **Begin with C major scale** - no sharps or flats to confuse you
2. **Master the major scale pattern** before moving to minor
3. **Practice chromatic scale** to learn all note names
4. **Build basic triads** (major and minor)

### Build Complexity
1. **Try different keys** - apply patterns to F, G, D major scales
2. **Explore minor scales** - natural, harmonic, and melodic
3. **Construct seventh chords** - add the 7th to your triads
4. **Practice mode recognition** - identify Dorian, Mixolydian, etc.

### Apply to Music
1. **Find scales in songs you know** - identify the key and scale type
2. **Analyze chord progressions** - see how chords relate to scales
3. **Create your own progressions** - use the scale strip to experiment
4. **Connect to your instrument** - apply what you learn to guitar, piano, etc.

## Common Challenges and Solutions

### "I keep forgetting which notes have sharps"
- **Practice the chromatic scale** regularly
- **Remember**: no sharps between E-F and B-C
- **Use mnemonics**: "Every Good Boy Does Fine" for line notes

### "The patterns seem random"
- **Focus on the W-H patterns** rather than individual notes
- **Count semitones** consistently
- **Practice the same pattern** in different keys

### "I can't remember chord formulas"
- **Start with triads only** - master these first
- **Count intervals from the root** - 1-3-5 for basic triads
- **Use the scale strip** to visualize the distances

### "It's hard to see the patterns"
- **Use the highlighting features** to your advantage
- **Focus on one octave** at a time
- **Practice with familiar keys** first (C, G, F)

Remember, these exercises are designed to build your foundational understanding of music theory through interactive practice. Take your time, think through each problem, and don't hesitate to review the explanations when you need clarification.

The scale strip is a powerful tool for visualizing music theory concepts. With practice, you'll develop intuitive understanding of scales, intervals, and chords that will serve you throughout your musical journey.

**Ready to start?** Try the quiz to test your understanding of scale strips and see how these concepts work in practice!
''',
          keyPoints: [
            'Interactive visual learning with immediate feedback',
            'Covers scales, intervals, chords, and note relationships',
            'Multiple exercise types: intervals, notes, construction, patterns',
            'Builds foundation for advanced music theory concepts',
            'Pattern recognition across different keys and scales',
            'Hands-on practice reinforces theoretical knowledge',
          ],
          examples: [
            'Fill out intervals for major scales (1-2-3-4-5-6-7-8)',
            'Complete missing notes in minor scales',
            'Identify missing sharps/flats in chromatic sequences',
            'Construct triads by selecting correct note combinations',
            'Recognize scale patterns across different starting notes',
            'Build chord progressions using scale relationships',
          ],
        ),
      ],
    );
  }
}