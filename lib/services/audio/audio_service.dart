// lib/services/audio/audio_service.dart
import 'dart:async';

/// Abstract interface for audio playback services
/// This allows easy swapping between MIDI, audio files, or other audio backends
abstract class AudioService {
  /// Initialize the audio service
  Future<void> initialize();
  
  /// Dispose of resources
  Future<void> dispose();
  
  /// Play a single note
  Future<void> playNote(int midiNumber, {int velocity = 127, Duration? duration});
  
  /// Play multiple notes as a melody (one after another)
  Future<void> playMelody(List<int> midiNumbers, {
    Duration noteDuration = const Duration(milliseconds: 500),
    Duration gapDuration = const Duration(milliseconds: 50),
    int velocity = 127,
  });
  
  /// Play multiple notes as harmony (simultaneously)
  Future<void> playHarmony(List<int> midiNumbers, {
    Duration duration = const Duration(milliseconds: 2000),
    int velocity = 127,
  });
  
  /// Stop all currently playing notes
  Future<void> stopAll();
  
  /// Set master volume (0.0 to 1.0)
  Future<void> setVolume(double volume);
  
  /// Check if the service is ready to play audio
  bool get isReady;
  
  /// Get the display name of this audio service
  String get serviceName;
}