// lib/models/learning/tiers/introduction_tier.dart

import '../learning_content.dart';

class IntroductionTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'introduction',
      title: 'Introduction',
      description: 'Start your musical journey with the basics',
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
Imagine music as a big puzzle, and music theory helps us understand how all the pieces fit together!

Music theory is like learning the ABCs of music. Just like we use letters to make words and sentences, musicians use notes to make melodies and songs. Music theory teaches us how these musical building blocks work together.

Think of it this way: When you listen to your favorite song, there are patterns and rules that make it sound good to your ears. Music theory helps us understand these patterns, just like knowing why the sky is blue or why plants need water.

Learning music theory is like getting a special decoder ring that helps you understand the secret language that all musicians use. It's not about making music harder - it's about making it easier to understand and more fun to play!

When you know music theory, you can:
• Understand why some songs make you happy and others make you feel calm
• Learn new songs faster
• Create your own music
• Talk about music with other musicians
• Discover the magic behind your favorite tunes

Remember, every famous musician started by learning these basics, just like you're doing now!
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
            'Letters make words, notes make melodies',
            'Traffic lights have rules, music has patterns',
            'Recipes tell us how to cook, music theory tells us how songs work',
            'A map shows us where to go, music theory guides us through songs',
          ],
        ),
        LearningTopic(
          id: 'why-learn-music-theory',
          title: 'Why Learn Music Theory?',
          description: 'Discover the amazing benefits of understanding music',
          order: 2,
          estimatedReadTime: const Duration(minutes: 4),
          content: '''
Learning music theory is like getting superpowers for your musical journey! Let's explore why it's so cool and helpful.

**It's Like Having X-Ray Vision for Music!**
When you know music theory, you can "see" inside songs. You'll understand why your favorite tune sounds happy, sad, exciting, or peaceful. It's like being able to see the ingredients in a delicious cake!

**Make Friends Through Music**
Music theory gives you a special language to talk with other musicians. Instead of saying "play that thing that goes up and down," you can use the right words that everyone understands. It's like learning a secret code that musicians all over the world know!

**Learn Songs Lightning Fast**
Once you understand patterns in music, learning new songs becomes much easier. It's like knowing that many stories have a beginning, middle, and end - once you know the pattern, you can follow along better!

**Create Your Own Musical Magic**
Understanding music theory is like having a big box of colorful LEGOs. You know which pieces fit together, so you can build amazing musical creations of your own!

**Have More Fun!**
The best part? Music becomes even more fun when you understand it better. It's like watching a magic trick when you know how it's done - it doesn't make it less magical, it makes you appreciate it even more!

Remember: Music theory isn't about rules that say "you can't do this" - it's about understanding why things sound good, so you can make even better music!
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
Learning music theory is an adventure, and like any adventure, it's more fun when you know some helpful tricks! Here are some super tips to make your learning journey amazing.

**Little and Often Wins the Race!**
Practice for just 10-15 minutes every day instead of one long session once a week. It's like watering a plant - a little bit each day helps it grow strong! Your brain loves learning in small, fun chunks.

**Make It a Game!**
Turn your practice into fun challenges:
• See how fast you can name all the notes
• Create silly songs using what you've learned
• Challenge a friend or family member to music theory games
• Give yourself points for each new thing you learn

**Use All Your Senses**
Don't just read about music - experience it!
• Sing the notes out loud
• Clap rhythms with your hands
• Draw pictures of musical concepts
• Move your body to different beats
• Listen to examples in real songs

**Connect to Your Favorite Music**
Take songs you love and find the theory concepts in them. It's like going on a treasure hunt in your favorite tunes! This makes theory real and exciting, not just words on a page.

**Be Patient and Kind to Yourself**
Remember, everyone learns at their own speed. Some days will be easier than others, and that's perfectly normal! Celebrate small victories:
• "I learned one new thing today!"
• "I understood something that was tricky yesterday!"
• "I practiced even when I didn't feel like it!"

**Create a Practice Routine**
Make practice a special time:
• Find a quiet, comfortable spot
• Have your materials ready
• Start with something you know well to warm up
• Try one new thing each session
• End with something fun you enjoy

**Track Your Progress**
Keep a music journal or chart where you can:
• Draw stars for each practice day
• Write down cool things you discovered
• Note questions to explore later
• Celebrate your achievements

Remember: Every professional musician was once a beginner too. The secret is to keep going, have fun, and enjoy the journey!
''',
          keyPoints: [
            'Practice a little bit every day',
            'Make learning fun with games and challenges',
            'Use singing, clapping, and movement',
            'Connect theory to songs you love',
            'Be patient and celebrate small wins',
            'Create a comfortable practice routine',
            'Track your progress to see improvement',
          ],
          examples: [
            'Set a timer for 10 minutes of focused practice',
            'Create flashcards with colorful drawings',
            'Practice while listening to favorite songs',
            'Reward yourself with stickers for each practice day',
            'Teach what you learned to a stuffed animal or pet',
          ],
        ),
      ],
    );
  }
}