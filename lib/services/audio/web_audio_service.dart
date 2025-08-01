// lib/services/audio/web_audio_service.dart
import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'audio_service_interface.dart';

/// HTML5 Audio implementation for Flutter web with clean chord synthesis
/// Creates combined waveforms for harmonies to prevent crackling
class WebAudioService implements AudioServiceInterface {
  static WebAudioService? _instance;
  static WebAudioService get instance {
    _instance ??= WebAudioService._();
    return _instance!;
  }

  WebAudioService._();

  bool _isInitialized = false;
  double _volume = 0.7;
  final Map<int, html.AudioElement> _activeAudio = {};
  html.AudioElement? _harmonyAudio; // Single audio element for harmonies

  @override
  Future<bool> initialize() async {
    if (!kIsWeb) {
      debugPrint('❌ [WebAudioService] Not running on web platform');
      return false;
    }

    try {
      debugPrint('🎵 [WebAudioService] Initializing HTML5 Audio service...');
      
      // Test if we can create audio elements
      final testAudio = html.AudioElement();
      testAudio.volume = 0.0; // Silent test
      
      _isInitialized = true;
      debugPrint('✅ [WebAudioService] HTML5 Audio service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [WebAudioService] Failed to initialize: $e');
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await stopAll();
      _activeAudio.clear();
      _harmonyAudio = null;
      _isInitialized = false;
      debugPrint('🎵 [WebAudioService] HTML5 Audio service disposed');
    } catch (e) {
      debugPrint('❌ [WebAudioService] Error disposing: $e');
    }
  }

  @override
  Future<void> playNote(int midiNote, {int velocity = 100, Duration? duration}) async {
    if (!_isInitialized) {
      debugPrint('⚠️ [WebAudioService] Cannot play note - not initialized');
      return;
    }

    try {
      final clampedMidiNote = midiNote.clamp(0, 127);
      final frequency = _midiNoteToFrequency(clampedMidiNote);
      final normalizedVelocity = (velocity / 127.0).clamp(0.0, 1.0);
      
      // Stop existing note if playing
      if (_activeAudio.containsKey(clampedMidiNote)) {
        await stopNote(clampedMidiNote);
      }
      
      // Generate tone as WAV data URL
      final noteDuration = duration ?? const Duration(seconds: 10); // Long default
      final audioDataUrl = _generateSingleToneDataUrl(frequency, noteDuration, normalizedVelocity);
      
      // Create and play audio element
      final audio = html.AudioElement(audioDataUrl);
      audio.volume = _volume * normalizedVelocity;
      
      _activeAudio[clampedMidiNote] = audio;
      
      // Play the audio
      await audio.play();
      
      debugPrint('🎵 [WebAudioService] Playing note: $clampedMidiNote (${frequency.toStringAsFixed(1)}Hz), velocity: ${(normalizedVelocity * 100).toStringAsFixed(0)}%');
      
      // Schedule note off if duration specified
      if (duration != null) {
        Timer(duration, () => stopNote(clampedMidiNote));
      }
    } catch (e) {
      debugPrint('❌ [WebAudioService] Error playing note $midiNote: $e');
    }
  }

  @override
  Future<void> stopNote(int midiNote) async {
    if (!_isInitialized) return;

    try {
      final clampedMidiNote = midiNote.clamp(0, 127);
      final audio = _activeAudio[clampedMidiNote];
      
      if (audio != null) {
        audio.pause();
        audio.currentTime = 0;
        _activeAudio.remove(clampedMidiNote);
        debugPrint('🎵 [WebAudioService] Stopping note: $clampedMidiNote');
      }
    } catch (e) {
      debugPrint('❌ [WebAudioService] Error stopping note $midiNote: $e');
    }
  }

  @override
  Future<void> playMelody(List<int> midiNotes, {
    Duration noteDuration = const Duration(milliseconds: 500),
    Duration gapDuration = const Duration(milliseconds: 50),
    int velocity = 100,
  }) async {
    if (!_isInitialized || midiNotes.isEmpty) {
      debugPrint('⚠️ [WebAudioService] Cannot play melody - not initialized or no notes');
      return;
    }

    debugPrint('🎼 [WebAudioService] Playing melody: $midiNotes');

    for (int i = 0; i < midiNotes.length; i++) {
      await playNote(midiNotes[i], velocity: velocity, duration: noteDuration);
      
      // Wait for note duration plus gap before next note
      if (i < midiNotes.length - 1) {
        await Future.delayed(noteDuration + gapDuration);
      }
    }
  }

  @override
  Future<void> playHarmony(List<int> midiNotes, {
    Duration duration = const Duration(milliseconds: 2000),
    int velocity = 100,
  }) async {
    if (!_isInitialized || midiNotes.isEmpty) {
      debugPrint('⚠️ [WebAudioService] Cannot play harmony - not initialized or no notes');
      return;
    }

    debugPrint('🎵 [WebAudioService] Playing harmony: $midiNotes');

    // Stop any existing harmony
    if (_harmonyAudio != null) {
      _harmonyAudio!.pause();
      _harmonyAudio = null;
    }

    // Convert MIDI notes to frequencies
    final frequencies = midiNotes.map(_midiNoteToFrequency).toList();
    final normalizedVelocity = (velocity / 127.0).clamp(0.0, 1.0);

    // Generate combined chord waveform
    final audioDataUrl = _generateChordDataUrl(frequencies, duration, normalizedVelocity);
    
    // Create and play single audio element for the entire chord
    _harmonyAudio = html.AudioElement(audioDataUrl);
    _harmonyAudio!.volume = _volume;
    
    await _harmonyAudio!.play();
    
    debugPrint('🎵 [WebAudioService] Playing ${frequencies.length}-note chord: ${frequencies.map((f) => f.toStringAsFixed(1)).join(', ')}Hz');
  }

  @override
  Future<void> stopAll() async {
    if (!_isInitialized) return;

    try {
      // Stop individual notes
      final notesToStop = List.from(_activeAudio.keys);
      for (final midiNote in notesToStop) {
        await stopNote(midiNote);
      }
      
      // Stop harmony
      if (_harmonyAudio != null) {
        _harmonyAudio!.pause();
        _harmonyAudio = null;
      }
      
      debugPrint('🎵 [WebAudioService] All notes stopped');
    } catch (e) {
      debugPrint('❌ [WebAudioService] Error stopping all notes: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    
    // Update volume for all active audio elements
    for (final audio in _activeAudio.values) {
      audio.volume = _volume;
    }
    
    // Update harmony volume
    if (_harmonyAudio != null) {
      _harmonyAudio!.volume = _volume;
    }
    
    debugPrint('🔊 [WebAudioService] Volume set to: ${(_volume * 100).toStringAsFixed(0)}%');
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  double get volume => _volume;

  /// Convert MIDI note number to frequency in Hz
  double _midiNoteToFrequency(int midiNote) {
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }

  /// Generate a WAV data URL for a single frequency
  String _generateSingleToneDataUrl(double frequency, Duration duration, double amplitude) {
    const sampleRate = 44100;
    final samples = (sampleRate * duration.inMilliseconds / 1000).round();
    
    // Generate sine wave samples with gentle envelope
    final audioData = <int>[];
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      
      // Apply gentle attack and release envelope
      double envelope = 1.0;
      final attackTime = 0.02; // 20ms attack
      final releaseTime = 0.1;  // 100ms release
      final totalDuration = duration.inMilliseconds / 1000.0;
      
      if (t < attackTime) {
        envelope = t / attackTime;
      } else if (t > totalDuration - releaseTime) {
        envelope = (totalDuration - t) / releaseTime;
      }
      
      final sample = (amplitude * envelope * 16383 * math.sin(2 * math.pi * frequency * t)).round();
      audioData.addAll(_int16ToBytes(sample.clamp(-32767, 32767)));
    }
    
    return _createWavDataUrl(audioData, sampleRate);
  }

  /// Generate a WAV data URL for multiple frequencies combined into one waveform
  String _generateChordDataUrl(List<double> frequencies, Duration duration, double amplitude) {
    const sampleRate = 44100;
    final samples = (sampleRate * duration.inMilliseconds / 1000).round();
    
    // Calculate per-note amplitude to prevent clipping
    final perNoteAmplitude = amplitude / math.sqrt(frequencies.length);
    
    // Generate combined waveform
    final audioData = <int>[];
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      
      // Apply gentle attack and release envelope
      double envelope = 1.0;
      final attackTime = 0.02; // 20ms attack
      final releaseTime = 0.1;  // 100ms release
      final totalDuration = duration.inMilliseconds / 1000.0;
      
      if (t < attackTime) {
        envelope = t / attackTime;
      } else if (t > totalDuration - releaseTime) {
        envelope = (totalDuration - t) / releaseTime;
      }
      
      // Sum all frequencies for this sample
      double combinedSample = 0.0;
      for (final frequency in frequencies) {
        combinedSample += perNoteAmplitude * math.sin(2 * math.pi * frequency * t);
      }
      
      // Apply envelope and convert to 16-bit integer
      final sample = (envelope * combinedSample * 16383).round();
      audioData.addAll(_int16ToBytes(sample.clamp(-32767, 32767)));
    }
    
    return _createWavDataUrl(audioData, sampleRate);
  }

  /// Create a complete WAV data URL from audio sample data
  String _createWavDataUrl(List<int> audioData, int sampleRate) {
    // Create WAV header
    final header = <int>[
      // "RIFF" chunk descriptor
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      ...(_int32ToBytes(36 + audioData.length)), // File size - 8
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      
      // "fmt " sub-chunk
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      ..._int32ToBytes(16), // Sub-chunk size
      ..._int16ToBytes(1), // PCM format
      ..._int16ToBytes(1), // Mono
      ..._int32ToBytes(sampleRate), // Sample rate
      ..._int32ToBytes(sampleRate * 2), // Byte rate
      ..._int16ToBytes(2), // Block align
      ..._int16ToBytes(16), // Bits per sample
      
      // "data" sub-chunk
      0x64, 0x61, 0x74, 0x61, // "data"
      ...(_int32ToBytes(audioData.length)), // Data size
    ];
    
    // Combine header and data
    final wavData = Uint8List.fromList([...header, ...audioData]);
    
    // Convert to base64 data URL
    final base64Data = _uint8ListToBase64(wavData);
    return 'data:audio/wav;base64,$base64Data';
  }

  /// Convert int32 to little-endian bytes
  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  /// Convert int16 to little-endian bytes
  List<int> _int16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }

  /// Convert Uint8List to base64 string
  String _uint8ListToBase64(Uint8List data) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';
    
    for (int i = 0; i < data.length; i += 3) {
      final int byte1 = data[i];
      final int byte2 = i + 1 < data.length ? data[i + 1] : 0;
      final int byte3 = i + 2 < data.length ? data[i + 2] : 0;
      
      final int combined = (byte1 << 16) | (byte2 << 8) | byte3;
      
      result += chars[(combined >> 18) & 0x3F];
      result += chars[(combined >> 12) & 0x3F];
      result += i + 1 < data.length ? chars[(combined >> 6) & 0x3F] : '=';
      result += i + 2 < data.length ? chars[combined & 0x3F] : '=';
    }
    
    return result;
  }
}