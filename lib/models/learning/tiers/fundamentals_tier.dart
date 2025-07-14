// lib/models/learning/tiers/fundamentals_tier.dart

import '../learning_content.dart';

class FundamentalsTier {
  static LearningSection getSection() {
    return LearningSection(
      id: 'fundamentals',
      title: 'Fundamentals',
      description: 'Build essential knowledge of music theory',
      level: LearningLevel.fundamentals,
      order: 2,
      topics: [
        LearningTopic(
          id: 'musical-alphabet',
          title: 'The Musical Alphabet',
          description: 'Learn the seven letters that make all music',
          order: 1,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
The musical alphabet is super simple - it only has 7 letters! These are: A, B, C, D, E, F, and G.

Think of these letters like the colors of a rainbow. Just like you can make any picture using different colors, you can make any song using these 7 musical letters!

**How It Works:**
When we get to G, we start over again at A. It's like climbing stairs - when you reach the top, the pattern starts again on the next floor:
A → B → C → D → E → F → G → A → B → C... and so on!

**Where Do We Find These Letters?**
• On a piano, each white key has one of these letter names
• On a guitar, each fret helps you play different letters
• When we sing, we're making these letter sounds with our voice

**The Special Pattern:**
Not all letters are the same distance apart. Some are like next-door neighbors (very close), and some have a little more space between them. We'll learn more about this in future lessons!

**Fun Memory Trick:**
To remember the musical alphabet, think: "All Big Cats Dance Every Friday Gently" - the first letter of each word gives you A, B, C, D, E, F, G!

Remember: Every song you've ever heard uses only these 7 letters in different combinations. That's the magic of music!
''',
          keyPoints: [
            'Music uses only 7 letters: A, B, C, D, E, F, G',
            'After G, we start again at A',
            'These letters repeat like a pattern',
            'Every instrument uses these same letters',
            'All music is made from these 7 letters',
          ],
          examples: [
            'Piano white keys are named with these letters',
            '"Twinkle Twinkle" uses letters like C, C, G, G, A, A, G',
            'The "Happy Birthday" song uses different combinations of these letters',
            'Your name in music letters might be: B-E-A or D-A-D',
          ],
        ),
        LearningTopic(
          id: 'important-terminology',
          title: 'Important Terminology',
          description: 'Essential music words every musician should know',
          order: 2,
          estimatedReadTime: const Duration(minutes: 6),
          content: '''
Just like any new subject, music has its own special words. Let's learn the most important ones - think of them as your music vocabulary!

**Note**
A note is a single musical sound. It's like a single letter in a word. When you press one piano key or pluck one guitar string, you make a note!

**Pitch**
Pitch is how high or low a sound is. Think of it like this:
• A mouse has a high pitch (squeaky voice)
• A lion has a low pitch (deep roar)

**Rhythm**
Rhythm is the pattern of long and short sounds in music. It's like the heartbeat of a song - the part that makes you want to dance or tap your feet!

**Melody**
A melody is a series of notes that make a tune you can sing. It's the part of a song you hum or whistle - like "Happy Birthday" or your favorite song's main tune.

**Harmony**
Harmony happens when different notes sound good together at the same time. It's like when friends sing different parts but they sound beautiful together!

**Tempo**
Tempo is how fast or slow music goes. Like walking slowly in a park (slow tempo) or running in a race (fast tempo)!

**Beat**
The beat is the steady pulse in music - like a clock ticking. It's what you clap along to in a song.

**Scale**
A scale is a group of notes that sound good together, arranged from low to high (or high to low). It's like a musical ladder!

**Chord**
A chord is when you play three or more notes at the same time, and they sound nice together. It's like a musical sandwich - multiple layers that taste great together!

**Octave**
An octave is the distance from one letter to the same letter higher or lower. Like from one C to the next C - they sound similar but one is higher!

Remember: These words are tools to help you talk about and understand music better. The more you use them, the more natural they'll become!
''',
          keyPoints: [
            'Note = single musical sound',
            'Pitch = how high or low',
            'Rhythm = pattern of sounds',
            'Melody = tune you can sing',
            'Harmony = notes that sound good together',
            'Tempo = speed of music',
            'Beat = steady pulse',
            'Scale = group of notes in order',
            'Chord = multiple notes played together',
            'Octave = same note, higher or lower',
          ],
          examples: [
            'Bird chirps = high pitch, Thunder = low pitch',
            'Clapping pattern in "We Will Rock You" = rhythm',
            'The tune of "Jingle Bells" = melody',
            'Slow song for sleeping = slow tempo',
            'Fast song for exercising = fast tempo',
          ],
        ),
        LearningTopic(
          id: 'chromatic-scale',
          title: 'The Chromatic Scale',
          description: 'Discover all 12 musical sounds',
          order: 3,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Remember our 7 musical letters? Well, there's more to the story! Between some of these letters, there are extra notes - like secret steps between stairs!

**The Complete Musical Rainbow**
The chromatic scale includes ALL 12 different sounds we use in music. It's like having a box of 12 different colored crayons instead of just 7.

**Sharps and Flats**
The extra notes between our letter notes have special names:
• **Sharp (#)** means "a tiny bit higher" - like taking a small step up
• **Flat (♭)** means "a tiny bit lower" - like taking a small step down

**The 12 Notes Are:**
1. A
2. A# (or B♭)
3. B
4. C
5. C# (or D♭)
6. D
7. D# (or E♭)
8. E
9. F
10. F# (or G♭)
11. G
12. G# (or A♭)

Then it starts over at A again!

**Why Do Some Notes Have Two Names?**
Some notes can be called by two different names, like how you might be called by your first name or a nickname. A# and B♭ are the same sound, just with different names!

**The Special Pattern**
Notice something interesting? There's no sharp/flat between:
• B and C
• E and F

These pairs are already as close as notes can be - they're like best friends standing right next to each other!

**Where Do We See This?**
On a piano:
• White keys = letter notes
• Black keys = sharps and flats

Think of the chromatic scale as having every possible musical color available - you might not use them all in one song, but they're there when you need them!
''',
          keyPoints: [
            'There are 12 different notes in total',
            'Sharp (#) means slightly higher',
            'Flat (♭) means slightly lower',
            'Some notes have two names',
            'No sharp/flat between B-C and E-F',
            'White keys = natural notes, Black keys = sharps/flats',
          ],
          examples: [
            'C to C# is like adding a pinch of salt to food - just a little change',
            'Sliding up a guitar string makes the pitch go through all 12 notes',
            'Police sirens use the chromatic scale when they go up and down',
            'The "Jaws" theme uses notes that are very close together',
          ],
        ),
        LearningTopic(
          id: 'introduction-to-intervals',
          title: 'Introduction to Intervals',
          description: 'Learn about the space between notes',
          order: 4,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
An interval is simply the distance between two notes. It's like measuring how many steps there are between where you are and where you want to go!

**What Are Intervals?**
Think of notes as houses on a street. An interval tells us how many houses apart two notes are. Some are next-door neighbors, and some live many blocks away!

**Why Are Intervals Important?**
Intervals are the building blocks of melodies and chords. They help us understand:
• Why some notes sound happy together
• Why some create tension or sadness
• How to build melodies that sound good

**Basic Interval Types:**
Let's start with the simplest intervals:

**Unison**
When two notes are exactly the same - like two people singing the exact same note. No distance at all!

**Steps**
• **Half Step**: The smallest distance in music (like C to C#)
• **Whole Step**: Two half steps (like C to D)

**Simple Intervals**
• **Third**: Skipping one letter (C to E)
• **Fourth**: Skipping two letters (C to F)  
• **Fifth**: Skipping three letters (C to G)
• **Octave**: Same letter, higher or lower (C to C)

**How Intervals Sound:**
• Small intervals (like half steps) can sound tense or mysterious
• Medium intervals often sound pleasant and stable
• Large intervals can sound dramatic or exciting

**Fun Interval Game:**
Try singing:
• "Twinkle, Twinkle" - the first two notes are the same (unison)
• "Happy Birthday" - starts with a small jump up
• "Somewhere Over the Rainbow" - starts with a big jump (octave)!

Remember: Every melody is just a series of intervals - notes jumping different distances to create a tune!
''',
          keyPoints: [
            'Interval = distance between two notes',
            'Half step = smallest distance',
            'Whole step = two half steps',
            'Different intervals create different feelings',
            'Every melody uses intervals',
            'Same intervals can be found in many songs',
          ],
          examples: [
            'Doorbell "ding-dong" is often a fourth interval',
            'Emergency sirens use half steps to sound urgent',
            '"Star Wars" theme starts with a big fifth jump',
            'Steps on a staircase are like whole steps in music',
          ],
        ),
        LearningTopic(
          id: 'major-scale',
          title: 'The Major Scale',
          description: 'The happy-sounding foundation of music',
          order: 5,
          estimatedReadTime: const Duration(minutes: 6),
          content: '''
The major scale is one of the most important patterns in music. It's the "happy" scale that sounds bright and cheerful - like sunshine in musical form!

**What Is a Major Scale?**
A major scale is a specific pattern of 7 notes that sounds complete and satisfying. It's like a recipe - if you follow the pattern starting from any note, you'll always get that happy major sound!

**The Magic Pattern**
The major scale follows this pattern of whole steps (W) and half steps (H):
W - W - H - W - W - W - H

Let's see this with C major (the easiest major scale):
• C to D = Whole step
• D to E = Whole step  
• E to F = Half step
• F to G = Whole step
• G to A = Whole step
• A to B = Whole step
• B to C = Half step

**Do-Re-Mi!**
You already know a major scale! The song "Do-Re-Mi" from The Sound of Music is a major scale:
Do - Re - Mi - Fa - Sol - La - Ti - Do

These silly syllables (called solfège) help us sing the major scale pattern!

**Why Is It Called "Major"?**
"Major" means "greater" or "larger" - this scale sounds big, bright, and important. Most happy songs use the major scale!

**The Home Note**
The first note of a major scale (like C in C major) is called the "tonic" or "home" note. It's where the scale starts and ends, and it feels like coming home when you hear it.

**Major Scale Feelings:**
• Sounds happy, bright, and positive
• Used in celebration songs
• Makes people feel good
• Common in pop, folk, and children's songs

**Try This!**
Sing "Twinkle, Twinkle, Little Star" - it uses notes from the major scale. Notice how it starts and ends on the same note? That's the "home" feeling of the major scale!

Remember: Once you know this pattern, you can build a major scale starting from any note. It's like having a recipe that always works!
''',
          keyPoints: [
            'Major scale = happy sounding pattern',
            'Uses pattern: W-W-H-W-W-W-H',
            'Has 7 different notes',
            'Do-Re-Mi is a major scale',
            'Starts and ends on the "home" note',
            'Most common scale in happy music',
          ],
          examples: [
            '"Happy Birthday" uses the major scale',
            '"Twinkle Twinkle" is in a major scale',
            'National anthems often use major scales',
            'The "ABC" song follows major scale patterns',
            'Wedding marches usually use major scales',
          ],
        ),
        LearningTopic(
          id: 'natural-minor-scale',
          title: 'The Natural Minor Scale',
          description: 'The mysterious and emotional scale',
          order: 6,
          estimatedReadTime: const Duration(minutes: 6),
          content: '''
If the major scale is like a sunny day, the natural minor scale is like a cloudy evening - not necessarily sad, but more serious and mysterious!

**What Is a Natural Minor Scale?**
The natural minor scale is another pattern of 7 notes, but with a different recipe than the major scale. It creates a more somber, thoughtful, or mysterious mood.

**The Minor Pattern**
The natural minor scale follows this pattern:
W - H - W - W - H - W - W

Let's see A minor (the easiest minor scale):
• A to B = Whole step
• B to C = Half step
• C to D = Whole step
• D to E = Whole step
• E to F = Half step
• F to G = Whole step
• G to A = Whole step

**Major vs. Minor - What's the Difference?**
The pattern is different! This small change makes a big difference in how the scale sounds and feels. It's like the difference between a smile and a thoughtful expression.

**Minor Scale Feelings:**
• Can sound sad, but also mysterious or cool
• Often used in lullabies
• Creates drama and emotion
• Used in rock, blues, and film music

**The Relative Relationship**
Here's something cool: Every major scale has a "relative" minor scale that uses the exact same notes but starts in a different place! C major and A minor are relatives - same notes, different starting point, different feeling!

**Where Do We Hear Minor Scales?**
• Spooky music often uses minor scales
• Many rock and metal songs
• Traditional folk songs from around the world
• Emotional moments in movies

**Try This!**
Think of the "Pink Panther" theme or the beginning of "Smoke on the Water" - these use minor scales to create their cool, mysterious sound!

Remember: Minor doesn't always mean sad - it can mean thoughtful, mysterious, cool, or even powerful. It's just another color in your musical paint box!
''',
          keyPoints: [
            'Minor scale = more serious or mysterious sound',
            'Uses pattern: W-H-W-W-H-W-W',
            'Different pattern than major scale',
            'Can express many emotions',
            'Every major has a relative minor',
            'Common in rock, blues, and film music',
          ],
          examples: [
            '"Greensleeves" is in minor',
            'The "Imperial March" from Star Wars uses minor',
            '"House of the Rising Sun" is minor',
            'Many lullabies use minor scales',
            'Detective show themes often use minor',
          ],
        ),
        LearningTopic(
          id: 'rhythm',
          title: 'Rhythm',
          description: 'The heartbeat and movement of music',
          order: 7,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Rhythm is what makes music move and groove! It's the pattern of long and short sounds that makes you want to tap your feet, clap your hands, or dance.

**What Is Rhythm?**
Rhythm is how we organize sounds in time. It's like the heartbeat of music - without rhythm, notes would just be random sounds instead of music!

**The Building Blocks of Rhythm:**

**Beat**
The steady pulse you feel in music - like a clock ticking. Try clapping along to your favorite song - you're clapping the beat!

**Note Values**
Different notes last for different amounts of time:
• **Whole Note**: Holds for 4 beats (like saying "goooooal" in soccer)
• **Half Note**: Holds for 2 beats (like saying "hello")
• **Quarter Note**: 1 beat each (like walking steps)
• **Eighth Note**: Half a beat (like running steps)

**Rests**
Silence is part of music too! Rests tell us when NOT to play:
• Just like notes, rests have different lengths
• They create space and breathing room in music

**Patterns Make It Interesting**
Rhythm gets exciting when we mix different note values:
• Long - short - short - long
• Quick - quick - slow
• Ta - ta - ti-ti - ta

**Feel the Groove**
Different rhythms create different feelings:
• March: Strong, steady beat (LEFT-right-LEFT-right)
• Waltz: 1-2-3, 1-2-3 (like dancing in circles)
• Rock: Usually emphasizes beats 2 and 4
• Latin: Often has syncopation (unexpected accents)

**Rhythm Is Everywhere!**
• Your heartbeat has rhythm
• Walking has rhythm
• Speaking has rhythm
• Even breathing has rhythm!

**Try This Rhythm Game:**
Clap these patterns:
1. "Coffee" = two quick claps
2. "Hamburger" = three medium claps
3. "Watermelon" = four quick claps

Remember: Rhythm is what makes music come alive. It's the difference between just notes and actual music that makes you want to move!
''',
          keyPoints: [
            'Rhythm organizes sounds in time',
            'Beat = steady pulse',
            'Different note values = different lengths',
            'Rests = important silences',
            'Patterns create interest',
            'Rhythm creates movement and feeling',
          ],
          examples: [
            'Heartbeat: boom-boom, boom-boom',
            'Train wheels: clickety-clack, clickety-clack',
            '"We Will Rock You": stomp-stomp-CLAP',
            'Horse galloping: da-da-DUM, da-da-DUM',
            'Popcorn popping: random quick rhythms',
          ],
        ),
        LearningTopic(
          id: 'harmony',
          title: 'Harmony',
          description: 'When notes work together to create magic',
          order: 8,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Harmony is what happens when different notes sound at the same time and create something beautiful together. It's like musical teamwork!

**What Is Harmony?**
Imagine singing with friends where everyone sings a different note, but they all sound great together - that's harmony! It's the art of combining different pitches to create richer, fuller sound.

**Why Is Harmony Special?**
One note alone is like a single color. But when you combine notes (harmony), it's like mixing colors to create new, beautiful shades. Harmony adds depth and emotion to music!

**Types of Harmony:**

**Consonance - The Sweet Sounds**
When notes sound smooth and pleasant together, like:
• Best friends holding hands
• Colors that match perfectly
• Flavors that taste great together

**Dissonance - The Spicy Sounds**
When notes create tension or clash a bit:
• Not bad, just different!
• Like spicy food - adds excitement
• Often used to create drama, then resolved to consonance

**Simple Harmony Examples:**
• **Thirds**: Like C and E together - very sweet!
• **Fifths**: Like C and G together - strong and stable
• **Octaves**: Same note, different heights - perfect blend

**Harmony in Real Life:**
• When a group sings "Happy Birthday" and some people naturally sing higher or lower
• Church choirs singing in parts
• Backup singers supporting the main singer
• Guitar chords under a melody

**How Harmony Makes Us Feel:**
• Major harmony = happy, bright, positive
• Minor harmony = thoughtful, mysterious, emotional
• Dissonant harmony = tense, exciting, needs resolution

**Try This!**
Sing a note, then ask someone to sing a different note with you. Listen to how they blend together. That's harmony in action!

Remember: Harmony is like friendship in music - different notes coming together to create something more beautiful than any could make alone!
''',
          keyPoints: [
            'Harmony = different notes sounding together',
            'Creates fuller, richer sound',
            'Consonance = smooth and pleasant',
            'Dissonance = tension that adds interest',
            'Different harmonies create different moods',
            'Foundation of chords and accompaniment',
          ],
          examples: [
            'Choir singing in different parts',
            'Piano left and right hands playing together',
            'Barbershop quartets',
            'Orchestra sections playing different notes',
            'Friends singing rounds like "Row, Row, Row Your Boat"',
          ],
        ),
        LearningTopic(
          id: 'melody',
          title: 'Melody',
          description: 'The tune that gets stuck in your head',
          order: 9,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Melody is the part of a song you sing in the shower, whistle while you work, or can't get out of your head. It's the musical line that tells the story!

**What Is Melody?**
A melody is a series of notes played one after another that creates a tune. If music were a sentence, melody would be the words that tell the story. It's usually the most memorable part of any song!

**The Star of the Show**
In most music, melody is like the main character in a movie:
• It's what we follow and remember
• Other parts (harmony, rhythm) support it
• It's usually the part we sing

**What Makes a Good Melody?**

**Shape and Direction**
Melodies move in different ways:
• **Ascending**: Going up (like climbing stairs)
• **Descending**: Going down (like sliding)
• **Arc**: Up then down (like throwing a ball)
• **Wave**: Up and down repeatedly (like ocean waves)

**Steps and Leaps**
• **Stepwise**: Notes right next to each other (smooth and easy)
• **Leaps**: Jumping to faraway notes (dramatic and exciting)

**Repetition and Variation**
Great melodies often:
• Repeat ideas so we remember them
• Change slightly to keep things interesting
• Have a "hook" - the super catchy part

**Melody Moods:**
• High melodies can sound bright or excited
• Low melodies can sound serious or calm
• Fast melodies feel energetic
• Slow melodies feel peaceful or sad

**Famous Melodies You Know:**
Think about these super memorable melodies:
• "Happy Birthday"
• Your national anthem
• Your school song
• Theme songs from movies or shows

**Creating Melodies:**
Start simple! Try:
• Humming random notes
• Making up tunes to words
• Changing familiar melodies slightly
• Following the rhythm of spoken words

Remember: Melody is what makes each song unique. It's the musical fingerprint that makes "Twinkle Twinkle" different from "Mary Had a Little Lamb" even though they might use similar notes!
''',
          keyPoints: [
            'Melody = the main tune of a song',
            'Notes played one after another',
            'The most memorable part of music',
            'Has shape, direction, and movement',
            'Uses repetition and variation',
            'Creates the emotional message',
          ],
          examples: [
            'The tune you hum from your favorite song',
            'Ring tones on phones',
            'Ice cream truck jingles',
            'Sports team chants',
            'Commercial jingles that stick in your head',
          ],
        ),
        LearningTopic(
          id: 'meter',
          title: 'Meter',
          description: 'How music organizes its beats',
          order: 10,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Meter is how we group beats in music to create patterns. It's like organizing words into sentences - it helps music make sense and gives it structure!

**What Is Meter?**
Think of meter as the way we count music. Just like poems have patterns (roses are red, violets are blue), music has patterns too. Meter tells us which beats are strong and which are weak.

**The Basics of Meter:**

**Measures (or Bars)**
Music is divided into small sections called measures, like dividing a long story into paragraphs. Each measure contains a specific number of beats.

**Strong and Weak Beats**
Not all beats are equal! Some are naturally stronger (accented) than others:
• Strong beats feel like stepping DOWN
• Weak beats feel like stepping UP
• This creates the "feel" of the music

**Common Meters:**

**Duple Meter (Groups of 2)**
Pattern: STRONG-weak, STRONG-weak
• Feels like marching: LEFT-right, LEFT-right
• Very common in pop and rock music

**Triple Meter (Groups of 3)**
Pattern: STRONG-weak-weak, STRONG-weak-weak
• Feels like waltzing: ONE-two-three, ONE-two-three
• Creates a spinning, circular feeling

**Quadruple Meter (Groups of 4)**
Pattern: STRONG-weak-medium-weak
• Most common meter in popular music
• Feels balanced and even

**How to Feel Meter:**
Try these movements:
• Duple: March in place
• Triple: Sway side to side
• Quadruple: Nod your head to pop music

**Meter in Daily Life:**
• Walking = duple meter (left-right)
• Waltz dancing = triple meter
• Your heartbeat = duple meter
• Skipping = compound meter

**Why Meter Matters:**
• Helps musicians play together
• Creates the groove and feel
• Makes music predictable and satisfying
• Different meters create different moods

Remember: Meter is the framework that holds music together. It's why you can dance to music - your body naturally feels the meter and wants to move with it!
''',
          keyPoints: [
            'Meter = how beats are grouped',
            'Creates patterns of strong and weak beats',
            'Measures divide music into sections',
            'Common meters: 2, 3, and 4 beats',
            'Different meters create different feels',
            'Helps musicians stay together',
          ],
          examples: [
            'Marching = duple meter (1-2, 1-2)',
            'Waltz = triple meter (1-2-3, 1-2-3)',
            'Rock music = usually quadruple meter',
            'Lullabies often use triple meter',
            '"We Will Rock You" = clear duple meter',
          ],
        ),
        LearningTopic(
          id: 'time-signatures',
          title: 'Time Signatures',
          description: 'The numbers that tell us how to count music',
          order: 11,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Time signatures are like a map for reading music. Those two numbers you see at the beginning of sheet music? They tell musicians how to count and feel the beat!

**What Is a Time Signature?**
A time signature looks like a fraction (but it's not math, don't worry!). It appears as two numbers stacked on top of each other:
• Top number = How many beats in each measure
• Bottom number = What type of note gets one beat

**Common Time Signatures:**

**4/4 Time ("Common Time")**
• 4 beats per measure
• Quarter note = 1 beat
• Sounds like: 1-2-3-4, 1-2-3-4
• Used in most pop, rock, and hip-hop
• So common it's sometimes shown as "C"

**3/4 Time ("Waltz Time")**
• 3 beats per measure
• Quarter note = 1 beat
• Sounds like: 1-2-3, 1-2-3
• Perfect for dancing in circles
• Used in waltzes and some ballads

**2/4 Time ("March Time")**
• 2 beats per measure
• Quarter note = 1 beat
• Sounds like: 1-2, 1-2
• Great for marching
• Used in polkas and some children's songs

**6/8 Time ("Compound Time")**
• 6 beats per measure (but felt in 2 big beats)
• Eighth note = 1 beat
• Feels like: 1-2-3, 4-5-6
• Lilting, rolling feeling
• Used in ballads and Irish jigs

**How to Count Different Time Signatures:**
• 4/4: Count "1, 2, 3, 4" repeatedly
• 3/4: Count "1, 2, 3" repeatedly
• 2/4: Count "1, 2" repeatedly
• 6/8: Count "1, 2, 3, 4, 5, 6" with emphasis on 1 and 4

**Time Signature Feelings:**
• 4/4 = Steady, balanced, "normal"
• 3/4 = Graceful, spinning, dance-like
• 2/4 = Marchlike, direct, simple
• 6/8 = Rolling, gentle, boat-rocking

Remember: Time signatures are just a way to organize music. Once you feel the pattern, counting becomes natural - like knowing when to clap along to your favorite song!
''',
          keyPoints: [
            'Two numbers that show how to count',
            'Top = beats per measure',
            'Bottom = which note gets the beat',
            '4/4 is most common',
            '3/4 creates waltz feel',
            'Different signatures create different feels',
          ],
          examples: [
            '"Twinkle Twinkle" = 4/4 time',
            '"Happy Birthday" = 3/4 time',
            '"Stars and Stripes Forever" = 2/4 time',
            '"Nothing Else Matters" = 6/8 time',
            'Most dance music = 4/4 time',
          ],
        ),
        LearningTopic(
          id: 'what-are-chords',
          title: 'What are Chords?',
          description: 'Musical building blocks made of multiple notes',
          order: 12,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Chords are what happen when we play several notes at the same time to create a rich, full sound. They're like musical sandwiches - multiple ingredients layered together to create something delicious!

**What Makes a Chord?**
A chord needs at least three different notes played together. It's like:
• A team needs multiple players
• A sandwich needs multiple ingredients
• A chord needs multiple notes!

**Why Are Chords Important?**
Chords are the foundation of most music:
• They support the melody (like a foundation supports a house)
• They create the mood and emotion
• They make music sound full and complete
• They're what guitarists and pianists play to accompany singers

**Basic Chord Ingredients:**
Every basic chord has:
1. **Root**: The main note that names the chord
2. **Third**: Determines if it's major (happy) or minor (serious)
3. **Fifth**: Adds stability and fullness

It's like making a pizza:
• Root = the dough (foundation)
• Third = the sauce (gives it character)
• Fifth = the cheese (completes it)

**Major vs. Minor Chords:**
• **Major Chords**: Sound bright, happy, positive
• **Minor Chords**: Sound darker, thoughtful, emotional

The only difference is one note, but what a difference it makes!

**Where Do We Hear Chords?**
• When someone plays guitar around a campfire
• Piano players using both hands
• When a group sings in harmony
• The background of almost every song

**Chord Progressions:**
Chords rarely stand alone - they move from one to another creating "progressions":
• Like words forming sentences
• Different progressions create different feelings
• Some progressions are used in thousands of songs!

**Simple Chord Magic:**
With just 3 or 4 chords, you can play:
• Most folk songs
• Many pop songs
• Campfire favorites
• Simple rock songs

Remember: Chords are like colors for a painter. Once you know how to use them, you can create endless musical pictures!
''',
          keyPoints: [
            'Chords = 3 or more notes played together',
            'Create fullness and support melody',
            'Major = happy, Minor = thoughtful',
            'Made of root, third, and fifth',
            'Foundation of accompaniment',
            'Move in progressions to create songs',
          ],
          examples: [
            'Guitar strumming at campfires',
            'Piano playing with both hands',
            'Ukulele accompanying singing',
            'Band\'s rhythm section',
            'Orchestra playing together',
          ],
        ),
        LearningTopic(
          id: 'introduction-to-triads',
          title: 'Introduction to Triads',
          description: 'The simplest and most important chords',
          order: 13,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Triads are the simplest type of chord - just three notes that sound great together! They're called "triads" because "tri" means three. These are the building blocks for almost all other chords.

**What Is a Triad?**
A triad is like a three-layer cake:
• Bottom layer: Root (the name of the chord)
• Middle layer: Third (makes it major or minor)
• Top layer: Fifth (adds fullness)

Each layer is important and adds its own flavor!

**Building Triads - The Simple Recipe:**
Starting from any note:
1. Pick your root note (like C)
2. Skip a letter, add the third (E)
3. Skip another letter, add the fifth (G)
4. Play all three together = C major triad!

**The Four Types of Triads:**

**Major Triads**
• Sound: Happy, bright, strong
• Recipe: Root + Major third + Perfect fifth
• Example: C-E-G
• Like a sunny day!

**Minor Triads**
• Sound: Sad, mysterious, thoughtful
• Recipe: Root + Minor third + Perfect fifth
• Example: A-C-E
• Like a cloudy day

**Diminished Triads**
• Sound: Tense, scary, unstable
• Recipe: Root + Minor third + Diminished fifth
• Example: B-D-F
• Like suspense in a movie!

**Augmented Triads**
• Sound: Strange, dreamy, mysterious
• Recipe: Root + Major third + Augmented fifth
• Example: C-E-G#
• Like a magic spell!

**Triads Are Everywhere!**
• Every song you know uses triads
• They're in piano music, guitar music, orchestras
• Even when people sing in groups, they often form triads
• Door bells often play triads!

**Playing Triads:**
On piano: Play every other white key starting from any note
On guitar: Many chord shapes are just triads spread out

Remember: Master triads and you've mastered the foundation of all harmony. They're simple but powerful - just three notes that can express any emotion!
''',
          keyPoints: [
            'Triads = 3-note chords',
            'Most basic and important chords',
            'Made of root, third, and fifth',
            'Four types: major, minor, diminished, augmented',
            'Major = happy, Minor = sad',
            'Foundation of all other chords',
          ],
          examples: [
            'C-E-G = C major (sounds happy)',
            'A-C-E = A minor (sounds thoughtful)',
            'Doorbell "ding-dong" = often a triad',
            'Power chords in rock = incomplete triads',
            'Church organ music = lots of triads',
          ],
        ),
        LearningTopic(
          id: 'open-chords',
          title: 'Open Chords',
          description: 'The first chords every guitarist learns',
          order: 14,
          estimatedReadTime: const Duration(minutes: 6),
          content: '''
Open chords are the friendly, easy-to-play chords that use open strings on the guitar. They're called "open" because some strings ring out without being pressed down - they're open and free!

**What Are Open Chords?**
Open chords are:
• Played near the guitar's headstock (top)
• Use some strings that aren't pressed (open strings)
• Usually the first chords beginners learn
• Sound full and ringy
• Perfect for campfire songs!

**Why Learn Open Chords First?**
• Easier on your fingers
• Sound great right away
• Used in thousands of songs
• Build finger strength gradually
• Create a full, rich sound

**The Essential Open Chords:**

**Major Open Chords:**
• **C Major**: Bright and happy
• **G Major**: Full and strong
• **D Major**: Clear and cheerful
• **A Major**: Warm and friendly
• **E Major**: Big and bold

**Minor Open Chords:**
• **A Minor**: Thoughtful and mellow
• **E Minor**: Deep and emotional
• **D Minor**: Gentle and sad

**The Magic of Open Strings:**
Open strings vibrate freely, creating:
• Natural resonance
• Fuller sound
• Easier transitions
• Less finger fatigue
• Beautiful ringing tones

**Songs You Can Play:**
With just 3-4 open chords:
• "Wonderwall" (G, D, C, Em)
• "Let It Be" (C, G, Am, F)
• "Stand By Me" (G, Em, C, D)
• Hundreds of folk songs
• Most campfire favorites

**Tips for Open Chords:**
• Press firmly but don't squeeze too hard
• Keep fingers curved
• Strum only the strings you need
• Practice changing between chords slowly
• Let open strings ring clearly

**Open Chord Families:**
Some open chords are "friends" - they sound great together:
• G, C, and D
• A, D, and E
• Am, F, and C
• Em, G, and D

Remember: Open chords are your gateway to playing real music on guitar. Master these, and you'll be playing songs in no time!
''',
          keyPoints: [
            'Use open (unpressed) strings',
            'Played near the guitar headstock',
            'First chords beginners learn',
            'Sound full and resonant',
            'Foundation for playing songs',
            'Major = happy, Minor = thoughtful',
          ],
          examples: [
            'G-C-D = thousands of pop songs',
            'Am-F-C-G = pop progression',
            'Em-G-D-C = rock ballads',
            'E-A-D = blues and rock',
            'C-Am-F-G = doo-wop progression',
          ],
        ),
      ],
    );
  }
}