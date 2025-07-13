// lib/models/learning/learning_content.dart

/// Represents a learning section (Beginner, Novice, etc.)
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

  /// Get total number of topics in this section
  int get totalTopics => topics.length;

  /// Check if section has topics
  bool get hasTopics => topics.isNotEmpty;
}

/// Represents an individual learning topic
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

/// Learning difficulty levels
enum LearningLevel {
  beginner('Beginner', 'Start your musical journey'),
  novice('Novice', 'Build on the basics'),
  intermediate('Intermediate', 'Develop deeper understanding'),
  advanced('Advanced', 'Master complex concepts'),
  expert('Expert', 'Push the boundaries');

  const LearningLevel(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Available instruments
enum Instrument {
  guitar('Guitar', 'Six-string fretted instrument'),
  piano('Piano', 'Keyboard instrument (Coming Soon)'),
  bass('Bass', 'Four-string bass guitar (Coming Soon)'),
  ukulele('Ukulele', 'Four-string small guitar (Coming Soon)');

  const Instrument(this.displayName, this.description);
  final String displayName;
  final String description;

  bool get isAvailable => this == Instrument.guitar;
}

/// Data repository for learning content
class LearningContentRepository {
  static final Map<LearningLevel, LearningSection> _sections = {
    LearningLevel.beginner: LearningSection(
      id: 'beginner',
      title: 'Beginner',
      description: 'Essential music theory concepts to get you started',
      level: LearningLevel.beginner,
      order: 1,
      topics: [
        LearningTopic(
          id: 'what-is-music-theory',
          title: 'What is Music Theory?',
          description: 'Understanding the language of music',
          order: 1,
          estimatedReadTime: const Duration(minutes: 5),
          content: '''
Music theory is the language that helps us understand how music works. Think of it as a roadmap that explains why certain combinations of sounds are pleasing to our ears and how musicians communicate their ideas to each other.

At its core, music theory is a system that describes the elements of music and how they relate to each other. It covers everything from individual notes and rhythms to complex harmonies and song structures.

Music theory isn't about rules that limit creativity—it's about understanding the tools available to express musical ideas. Whether you're a complete beginner or an experienced musician, music theory provides a framework for understanding and creating music.

Just like learning to read helps you understand literature better, learning music theory helps you understand music on a deeper level. It explains why a sad song makes you feel melancholy, why certain chord progressions sound "right," and how different musical elements work together to create emotion and meaning.
''',
          keyPoints: [
            'Music theory is the language that explains how music works',
            'It describes relationships between musical elements',
            'It provides tools for understanding and creating music',
            'Music theory enhances rather than limits creativity',
            'It helps musicians communicate ideas effectively',
          ],
          examples: [
            'Understanding why certain chords sound happy or sad',
            'Learning how scales create different moods',
            'Discovering patterns in your favorite songs',
            'Communicating musical ideas to other musicians',
          ],
        ),
        LearningTopic(
          id: 'why-learn-music-theory',
          title: 'Why Learn Music Theory?',
          description: 'The benefits of understanding musical concepts',
          order: 2,
          estimatedReadTime: const Duration(minutes: 4),
          content: '''
Learning music theory offers numerous benefits that enhance your musical journey, regardless of your skill level or musical goals.

**Enhanced Understanding**: Music theory helps you understand why music affects you emotionally. You'll begin to recognize patterns and structures that make songs memorable and meaningful.

**Improved Communication**: If you play with other musicians, theory provides a common language. Instead of saying "play that bluesy thing," you can say "play a minor pentatonic scale."

**Faster Learning**: Understanding theory accelerates your learning process. When you understand chord progressions, you can learn songs faster and even predict what comes next.

**Creative Freedom**: Contrary to popular belief, theory doesn't limit creativity—it expands it. Knowing the "rules" helps you break them more effectively and experiment with confidence.

**Problem Solving**: Theory gives you tools to solve musical problems. Stuck on a chord progression? Theory provides options. Need to change a song's key? Theory shows you how.

**Appreciation**: You'll develop a deeper appreciation for music, understanding the craft behind your favorite songs and discovering new musical styles.
''',
          keyPoints: [
            'Accelerates learning and skill development',
            'Provides a common language with other musicians',
            'Enhances creativity rather than limiting it',
            'Deepens appreciation for musical artistry',
            'Offers tools for solving musical challenges',
            'Builds confidence in musical expression',
          ],
          examples: [
            'Learning songs faster by recognizing patterns',
            'Improvising with confidence during jam sessions',
            'Understanding why your favorite songs move you',
            'Transposing songs to different keys',
            'Creating original compositions with intention',
          ],
        ),
        LearningTopic(
          id: 'notes',
          title: 'Notes',
          description: 'The building blocks of music',
          order: 3,
          estimatedReadTime: const Duration(minutes: 6),
          content: '''
Notes are the fundamental building blocks of music—they're the individual sounds that combine to create melodies, harmonies, and chords.

**What is a Note?**
A note represents a specific musical sound with a particular pitch (how high or low it sounds). Each note has a unique frequency that determines its pitch.

**The Musical Alphabet**
Music uses seven letter names: A, B, C, D, E, F, and G. After G, the pattern repeats with A again. This creates an endless cycle of note names.

**Sharps and Flats**
Between most letter names are additional notes called sharps (#) and flats (♭):
- A sharp (A#) is slightly higher than A
- B flat (B♭) is slightly lower than B
- These are the same note! A# = B♭

**The Chromatic Scale**
When we include all sharps and flats, we get 12 different notes before the pattern repeats:
C - C# - D - D# - E - F - F# - G - G# - A - A# - B

**Octaves**
When the same letter name repeats (like C to the next C), that distance is called an octave. The higher C sounds similar to the lower C, just at a different pitch level.

**Enharmonic Equivalents**
Some notes can be spelled in two ways:
- C# = D♭ (C sharp equals D flat)
- F# = G♭ (F sharp equals G flat)
Both names refer to the same pitch but are used in different musical contexts.
''',
          keyPoints: [
            'Notes are individual musical sounds with specific pitches',
            'Seven letter names (A-G) form the musical alphabet',
            'Sharps raise pitch, flats lower pitch by a half-step',
            'There are 12 different pitches in the chromatic scale',
            'Octaves represent the same note at different pitch levels',
            'Enharmonic equivalents are different names for the same pitch',
          ],
          examples: [
            'C to the next C is one octave',
            'C# and D♭ are the same note with different names',
            'Piano white keys represent natural notes (A, B, C, D, E, F, G)',
            'Piano black keys represent sharps and flats',
            'Guitar frets represent half-steps between notes',
          ],
        ),
        LearningTopic(
          id: 'chords',
          title: 'Chords',
          description: 'Multiple notes played together to create harmony',
          order: 4,
          estimatedReadTime: const Duration(minutes: 7),
          content: '''
Chords are groups of notes played simultaneously to create harmony. They form the harmonic foundation of most music and provide the backdrop for melodies.

**What Makes a Chord?**
A chord typically consists of three or more different notes played together. The simplest chords use three notes, called triads.

**Building Basic Triads**
Triads are built using a pattern of intervals (distances between notes):

**Major Triad**: Root - Major 3rd - Perfect 5th
- Example: C major = C - E - G
- Sound: Bright, happy, stable

**Minor Triad**: Root - Minor 3rd - Perfect 5th  
- Example: C minor = C - E♭ - G
- Sound: Darker, sad, contemplative

**Diminished Triad**: Root - Minor 3rd - Diminished 5th
- Example: C diminished = C - E♭ - G♭
- Sound: Tense, unstable, mysterious

**Augmented Triad**: Root - Major 3rd - Augmented 5th
- Example: C augmented = C - E - G#
- Sound: Dreamy, unsettled, floating

**Chord Progressions**
Chords rarely exist in isolation. They move from one to another in patterns called progressions. These progressions create the emotional journey of a song.

**Common Chord Extensions**
Beyond triads, chords can include additional notes:
- 7th chords (add the 7th note): C7, Cmaj7, Cm7
- 9th chords (add the 9th note): C9, Cadd9
- Sus chords (suspend the 3rd): Csus2, Csus4

**Inversions**
Chords can be played with different notes in the bass (lowest position), creating inversions that change the chord's color while maintaining its essential character.
''',
          keyPoints: [
            'Chords are three or more different notes played together',
            'Major chords sound bright and happy',
            'Minor chords sound darker and more emotional',
            'Diminished and augmented chords add tension',
            'Chord progressions create musical movement',
            'Extensions and inversions add color and variety',
          ],
          examples: [
            'C major chord: C-E-G (bright and stable)',
            'A minor chord: A-C-E (melancholy and introspective)',
            'Common progression: C - Am - F - G (found in thousands of songs)',
            'Sus4 chord: creates anticipation before resolving',
            'Jazz uses extended chords like maj7 and 9th chords',
          ],
        ),
        LearningTopic(
          id: 'scales',
          title: 'Scales',
          description: 'Organized sequences of notes that form musical frameworks',
          order: 5,
          estimatedReadTime: const Duration(minutes: 8),
          content: '''
Scales are organized sequences of notes that serve as the foundation for melodies, harmonies, and musical compositions. Think of scales as musical "alphabets" that provide the raw material for creating music.

**What is a Scale?**
A scale is a collection of notes arranged in ascending or descending order. Each scale has a unique pattern of intervals (distances between notes) that gives it its characteristic sound and emotional quality.

**The Major Scale**
The major scale is the most fundamental scale in Western music. It follows the pattern:
Whole - Whole - Half - Whole - Whole - Whole - Half

Example: C Major Scale
C - D - E - F - G - A - B - C

This pattern creates the familiar "Do-Re-Mi-Fa-Sol-La-Ti-Do" sound that sounds bright and optimistic.

**The Natural Minor Scale**
The natural minor scale has a different pattern:
Whole - Half - Whole - Whole - Half - Whole - Whole

Example: A Minor Scale  
A - B - C - D - E - F - G - A

Minor scales typically sound more melancholy or mysterious than major scales.

**Pentatonic Scales**
Pentatonic scales use only five notes and are found in music worldwide:

**Major Pentatonic**: Very common in folk and pop music
Example: C Major Pentatonic = C - D - E - G - A

**Minor Pentatonic**: Heavily used in blues and rock
Example: A Minor Pentatonic = A - C - D - E - G

**Scale Degrees**
Each note in a scale has a number (1-7) and a name:
1. Tonic (Do) - Home base
2. Supertonic (Re) 
3. Mediant (Mi)
4. Subdominant (Fa)
5. Dominant (Sol) - Very important, wants to return to tonic
6. Submediant (La)
7. Leading Tone (Ti) - Wants to resolve up to tonic

**Modes**
Modes are variations of the major scale that start on different degrees:
- Dorian (2nd degree): Minor with a raised 6th
- Mixolydian (5th degree): Major with a lowered 7th
- And five others, each with unique characteristics

**Using Scales**
Scales provide the notes for:
- Creating melodies
- Building chords 
- Improvising solos
- Understanding key signatures
- Analyzing existing music
''',
          keyPoints: [
            'Scales are organized sequences of notes with specific interval patterns',
            'Major scales sound bright and optimistic',
            'Minor scales sound more melancholy or mysterious', 
            'Pentatonic scales use five notes and are globally common',
            'Each scale degree has a function and tendency',
            'Modes are variations that start on different scale degrees',
            'Scales provide raw material for melodies and harmonies',
          ],
          examples: [
            'C major scale contains no sharps or flats',
            'A minor is the relative minor of C major (same notes)',
            'Minor pentatonic is essential for blues and rock solos',
            'Dorian mode gives a sophisticated minor sound',
            'The 5th degree (dominant) strongly wants to resolve to the 1st',
            'Popular songs often use notes from one primary scale',
          ],
        ),
        LearningTopic(
          id: 'melody',
          title: 'Melody',
          description: 'The main tune - sequences of notes that create musical lines',
          order: 6,
          estimatedReadTime: const Duration(minutes: 6),
          content: '''
Melody is the main tune of a piece of music—the part you sing along with, hum, or whistle. It's a sequence of single notes played one after another that creates a meaningful musical line.

**What Makes a Melody?**
A melody combines several elements:
- **Pitch**: How high or low the notes are
- **Rhythm**: How long each note lasts and when it occurs
- **Contour**: The shape of the melody as it rises and falls
- **Phrasing**: How the melody is divided into musical sentences

**Melodic Motion**
Melodies move in three basic ways:

**Step**: Moving to the next note in the scale (C to D)
- Creates smooth, flowing melodies
- Easy to sing and remember

**Skip**: Moving two notes away (C to E)  
- Adds interest while remaining singable
- Common in folk melodies

**Leap**: Moving three or more notes away (C to F or higher)
- Creates drama and excitement
- Can be more challenging to sing

**Melodic Contour**
The overall shape of a melody:
- **Ascending**: Generally rises (creates energy, excitement)
- **Descending**: Generally falls (creates relaxation, resolution)
- **Arch**: Rises then falls (very common, satisfying shape)
- **Wave**: Multiple rises and falls (creates varied interest)

**Scales and Melody**
Melodies typically use notes from a specific scale:
- Major scale melodies often sound bright and optimistic
- Minor scale melodies tend toward melancholy or mystery
- Pentatonic melodies sound universal and easy to sing
- Modal melodies can sound ancient, exotic, or sophisticated

**Melodic Phrases**
Like sentences in language, melodies are organized into phrases:
- **Antecedent**: A musical question (feels incomplete)
- **Consequent**: A musical answer (feels complete)
- **Sequence**: Repeating a melodic pattern at different pitch levels

**Creating Strong Melodies**
Memorable melodies often feature:
- A balance of steps, skips, and occasional leaps
- A clear highest point (climax)
- Repetition with variation
- Strong relationship to the underlying harmony
- Rhythmic interest and variety
- A sense of beginning, development, and conclusion

**Melody and Emotion**
Different melodic characteristics evoke different emotions:
- Rising melodies: Hope, energy, excitement
- Falling melodies: Sadness, resignation, peace
- Large leaps: Drama, surprise, passion
- Smooth steps: Calm, flowing, gentle
- Repeated notes: Insistence, stability, hypnotic quality
''',
          keyPoints: [
            'Melody is the main tune—the singable part of music',
            'Melodies combine pitch, rhythm, contour, and phrasing',
            'Motion can be by step, skip, or leap',
            'Melodic contour creates emotional direction',
            'Melodies use notes from scales to create character',
            'Phrases create musical sentences with questions and answers',
            'Strong melodies balance repetition with variety',
          ],
          examples: [
            '"Happy Birthday" uses mostly steps and small skips',
            '"Somewhere Over the Rainbow" features a dramatic opening leap',
            'Folk melodies often use pentatonic scales',
            'The opening of Beethoven\'s 5th Symphony uses repeated notes',
            'Pop songs often have an arch-shaped melodic contour',
            'Blues melodies frequently use the minor pentatonic scale',
          ],
        ),
        LearningTopic(
          id: 'harmony',
          title: 'Harmony',
          description: 'How chords and multiple notes work together to support melody',
          order: 7,
          estimatedReadTime: const Duration(minutes: 7),
          content: '''
Harmony is the art of combining different notes and chords to create rich, full-sounding music. While melody provides the main tune, harmony provides the musical backdrop that gives depth, emotion, and context to the melody.

**What is Harmony?**
Harmony occurs when two or more different notes are played simultaneously. This can be as simple as two notes played together (an interval) or as complex as jazz chords with many notes.

**Intervals - The Building Blocks**
Intervals are the distance between two notes and form the foundation of harmony:

**Consonant Intervals** (stable, restful):
- Unison (same note)
- Octave (8 notes apart)
- Perfect 5th (7 semitones) - very stable
- Perfect 4th (5 semitones) - stable
- Major and minor 3rds (4 and 3 semitones) - pleasant

**Dissonant Intervals** (tense, want to resolve):
- Minor 2nd (1 semitone) - very tense
- Major 7th (11 semitones) - needs resolution
- Tritone (6 semitones) - maximum tension

**Harmonic Progressions**
Chords rarely exist alone—they move from one to another in progressions that create harmonic rhythm and emotional journey:

**Common Progressions**:
- **I-V-I**: Most fundamental (C-G-C)
- **I-vi-IV-V**: Very popular in pop music (C-Am-F-G)
- **ii-V-I**: Essential in jazz (Dm-G-C in key of C)
- **I-VII-♭VI-♭VII**: Common in rock (C-Bb-Ab-Bb)

**Functional Harmony**
In traditional harmony, chords have specific functions:

**Tonic (I)**: Home base, stability, rest
- Provides resolution and stability
- Where progressions typically begin and end

**Dominant (V)**: Tension, wants to resolve to tonic
- Creates forward momentum
- Often includes the 7th for extra pull toward tonic

**Subdominant (IV)**: Departure from tonic
- Provides contrast without extreme tension
- Bridge between tonic and dominant

**Voice Leading**
Voice leading is how individual notes within chords move from one chord to the next:
- **Smooth voice leading**: Notes move by step when possible
- **Common tones**: Same notes appear in consecutive chords
- **Contrary motion**: Some voices go up while others go down

**Harmonic Rhythm**
This refers to how often chords change:
- **Slow harmonic rhythm**: Chords change infrequently (ballads)
- **Fast harmonic rhythm**: Chords change often (jazz, complex classical)
- **Varied harmonic rhythm**: Changes throughout the piece for interest

**Non-Chord Tones**
Not every note needs to be part of the chord:
- **Passing tones**: Connect chord tones by step
- **Neighbor tones**: Step away from and back to a chord tone
- **Suspensions**: Hold over a note from the previous chord, then resolve

**Modern Harmony**
Contemporary music often uses:
- **Extended chords**: 7ths, 9ths, 11ths, 13ths
- **Altered chords**: Modified notes for color
- **Modal harmony**: Using modes instead of major/minor
- **Quartal harmony**: Building chords in 4ths instead of 3rds
''',
          keyPoints: [
            'Harmony combines multiple notes to support and enrich melody',
            'Consonant intervals sound stable, dissonant intervals create tension',
            'Chord progressions create harmonic movement and emotion',
            'Tonic, dominant, and subdominant have specific functions',
            'Voice leading affects how smooth chord changes sound',
            'Harmonic rhythm controls the pace of chord changes',
            'Non-chord tones add melodic interest over harmony',
            'Modern harmony extends beyond traditional major/minor systems',
          ],
          examples: [
            'Perfect 5th (C-G) sounds very stable and strong',
            'Tritone (C-F#) creates maximum tension',
            'I-V-I progression feels like "departure and return home"',
            'Jazz uses extended chords like Cmaj7 and Dm11',
            'Bach chorales demonstrate masterful voice leading',
            'Pop songs often use the same chord progression repeatedly',
            'Passing tones create smooth melodic lines over chord changes',
          ],
        ),
        LearningTopic(
          id: 'rhythm',
          title: 'Rhythm',
          description: 'The timing and duration of musical sounds',
          order: 8,
          estimatedReadTime: const Duration(minutes: 6),
          content: '''
Rhythm is the element of music that deals with time—how long sounds last, when they occur, and how they're organized into patterns. Rhythm gives music its pulse, its groove, and its forward momentum.

**What is Rhythm?**
Rhythm encompasses several related concepts:
- **Beat**: The steady pulse underlying music
- **Tempo**: How fast or slow the beat moves
- **Meter**: How beats are organized into groups
- **Duration**: How long individual sounds last
- **Syncopation**: Emphasizing off-beats for rhythmic interest

**The Beat**
The beat is music's heartbeat—a steady, recurring pulse that you can tap your foot to. Even when there's no percussion, you can usually feel the underlying beat in most music.

**Note Values**
Different symbols represent different durations:

**Whole Note**: Lasts 4 beats (in 4/4 time)
**Half Note**: Lasts 2 beats  
**Quarter Note**: Lasts 1 beat (usually the basic beat)
**Eighth Note**: Lasts 1/2 beat
**Sixteenth Note**: Lasts 1/4 beat

Each note value is half the duration of the previous one.

**Time Signatures**
Time signatures tell us how to count beats:

**4/4 Time**: 4 quarter-note beats per measure
- Most common in pop, rock, classical
- Count: "1-2-3-4, 1-2-3-4"

**3/4 Time**: 3 quarter-note beats per measure  
- Waltz time
- Count: "1-2-3, 1-2-3"

**2/4 Time**: 2 quarter-note beats per measure
- March time
- Count: "1-2, 1-2"

**6/8 Time**: 6 eighth-note beats per measure
- Often feels like two groups of three
- Count: "1-2-3-4-5-6" or "1-and-a-2-and-a"

**Rhythm Patterns**
Common rhythmic patterns include:

**Straight Rhythm**: Even division of beats
- Rock, pop, classical music
- Eighth notes sound even: "1-and-2-and"

**Swing Rhythm**: Uneven division creating a "shuffling" feel
- Jazz, blues, swing music  
- Eighth notes are long-short: "1-trip-2-trip"

**Syncopation**: Emphasizing weak beats or off-beats
- Creates rhythmic surprise and energy
- Common in jazz, funk, Latin music

**Polyrhythm**: Multiple rhythmic patterns simultaneously
- Two or more conflicting rhythms at once
- Common in African music, modern jazz

**Tempo**
Tempo is measured in BPM (beats per minute):
- **Largo**: Very slow (40-60 BPM)
- **Andante**: Walking pace (76-108 BPM)  
- **Moderato**: Moderate (108-120 BPM)
- **Allegro**: Fast (120-168 BPM)
- **Presto**: Very fast (168+ BPM)

**Rhythmic Feel**
Different styles have characteristic rhythmic feels:
- **Rock**: Strong emphasis on beats 2 and 4
- **Reggae**: Emphasis on beats 2, 3, and 4
- **Country**: Often uses shuffle or swing feel
- **Funk**: Complex syncopation, emphasis on beat 1
- **Latin**: Clave rhythms, polyrhythmic patterns

**Rests**
Silence is also part of rhythm:
- **Whole rest**: 4 beats of silence
- **Half rest**: 2 beats of silence  
- **Quarter rest**: 1 beat of silence
- **Eighth rest**: 1/2 beat of silence

Strategic use of rests creates space, emphasis, and breathing room in music.
''',
          keyPoints: [
            'Rhythm deals with the timing and duration of musical sounds',
            'Beat is the steady pulse underlying music',
            'Note values represent different durations',
            'Time signatures organize beats into measures',
            'Syncopation creates rhythmic interest by emphasizing off-beats',
            'Different musical styles have characteristic rhythmic feels',
            'Tempo controls how fast or slow music moves',
            'Rests (silence) are an important part of rhythm',
          ],
          examples: [
            'Clapping along to your favorite song reveals the beat',
            'Waltzes use 3/4 time signature',
            'Rock music typically emphasizes beats 2 and 4',
            'Jazz swing makes eighth notes uneven',
            'Funk music uses heavy syncopation',
            'A quarter rest creates a one-beat pause',
            'Latin music often uses complex polyrhythmic patterns',
          ],
        ),
      ],
    ),
    // Other sections will be added later
    LearningLevel.novice: LearningSection(
      id: 'novice',
      title: 'Novice',
      description: 'Build upon fundamental concepts',
      level: LearningLevel.novice,
      order: 2,
      topics: [], // To be filled later
    ),
    LearningLevel.intermediate: LearningSection(
      id: 'intermediate',
      title: 'Intermediate',
      description: 'Develop deeper musical understanding',
      level: LearningLevel.intermediate,
      order: 3,
      topics: [], // To be filled later
    ),
    LearningLevel.advanced: LearningSection(
      id: 'advanced',
      title: 'Advanced',
      description: 'Master complex musical concepts',
      level: LearningLevel.advanced,
      order: 4,
      topics: [], // To be filled later
    ),
    LearningLevel.expert: LearningSection(
      id: 'expert',
      title: 'Expert',
      description: 'Push the boundaries of musical knowledge',
      level: LearningLevel.expert,
      order: 5,
      topics: [], // To be filled later
    ),
  };

  /// Get all learning sections
  static List<LearningSection> getAllSections() {
    return _sections.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Get a specific section by level
  static LearningSection? getSection(LearningLevel level) {
    return _sections[level];
  }

  /// Get available instruments
  static List<Instrument> getAvailableInstruments() {
    return Instrument.values.where((instrument) => instrument.isAvailable).toList();
  }

  /// Get all instruments (including coming soon)
  static List<Instrument> getAllInstruments() {
    return Instrument.values;
  }

  /// Find a topic by ID across all sections
  static LearningTopic? findTopicById(String topicId) {
    for (final section in _sections.values) {
      for (final topic in section.topics) {
        if (topic.id == topicId) {
          return topic;
        }
      }
    }
    return null;
  }

  /// Get section that contains a specific topic
  static LearningSection? getSectionForTopic(String topicId) {
    for (final section in _sections.values) {
      if (section.topics.any((topic) => topic.id == topicId)) {
        return section;
      }
    }
    return null;
  }
}