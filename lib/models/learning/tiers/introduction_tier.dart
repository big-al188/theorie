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
      ],
    );
  }
}