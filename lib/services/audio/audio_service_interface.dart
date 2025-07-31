// lib/services/audio/audio_service_interface.dart
/// Abstract interface for audio service implementations
/// This allows switching between different audio backends (MIDI, Web Audio, etc.)
abstract class AudioServiceInterface {
  /// Initialize the audio service
  /// Returns true if initialization was successful
  Future<bool> initialize();

  /// Clean up resources and dispose of the service
  Future<void> dispose();

  /// Play a single note
  /// 
  /// [midiNote] - MIDI note number (0-127)
  /// [velocity] - Note velocity (1-127), defaults to 100
  /// [duration] - Optional duration to play the note, if null note continues until stopped
  Future<void> playNote(int midiNote, {int velocity = 100, Duration? duration});

  /// Stop a currently playing note
  /// 
  /// [midiNote] - MIDI note number to stop
  Future<void> stopNote(int midiNote);

  /// Play a sequence of notes one after another (melody)
  /// 
  /// [midiNotes] - List of MIDI note numbers to play
  /// [noteDuration] - Duration each note should play
  /// [gapDuration] - Gap between notes
  /// [velocity] - Velocity for all notes
  Future<void> playMelody(List<int> midiNotes, {
    Duration noteDuration = const Duration(milliseconds: 500),
    Duration gapDuration = const Duration(milliseconds: 50),
    int velocity = 100,
  });

  /// Play multiple notes simultaneously (harmony/chord)
  /// 
  /// [midiNotes] - List of MIDI note numbers to play together
  /// [duration] - How long to play the harmony
  /// [velocity] - Velocity for all notes
  Future<void> playHarmony(List<int> midiNotes, {
    Duration duration = const Duration(milliseconds: 2000),
    int velocity = 100,
  });

  /// Stop all currently playing notes
  Future<void> stopAll();

  /// Set the master volume
  /// 
  /// [volume] - Volume level (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Check if the service is initialized and ready to use
  bool get isInitialized;

  /// Get current volume level
  double get volume;
}