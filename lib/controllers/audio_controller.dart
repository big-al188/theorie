// lib/controllers/audio_controller.dart
import 'package:flutter/foundation.dart';
import '../services/audio/audio_service_interface.dart';
import '../services/audio/midi_audio_service.dart';
import '../services/audio/file_audio_service.dart';
// NEW: Import WebAudioService for web platform
import '../services/audio/web_audio_service.dart' if (dart.library.io) '../services/audio/file_audio_service.dart';
import '../controllers/fretboard_controller.dart';
import '../models/fretboard/fretboard_config.dart';

enum AudioBackend { midi, files }

/// Controller for managing audio playback throughout the app
/// Automatically selects appropriate audio service based on platform
class AudioController {
  static AudioController? _instance;
  static AudioController get instance => _instance ??= AudioController._();
  
  AudioController._();
  
  AudioServiceInterface? _currentService;
  AudioBackend _currentBackend = AudioBackend.midi;
  bool _isInitializing = false;
  
  AudioServiceInterface? get currentService => _currentService;
  AudioBackend get currentBackend => _currentBackend;
  bool get isReady => _currentService?.isInitialized ?? false;
  bool get isInitializing => _isInitializing;
  String get serviceName => _currentService?.runtimeType.toString() ?? 'No Audio Service';
  
  /// Initialize with the specified backend
  Future<void> initialize(AudioBackend backend) async {
    if (_isInitializing) {
      if (kDebugMode) {
        print('Audio controller already initializing, skipping...');
      }
      return;
    }
    
    _isInitializing = true;
    
    try {
      await dispose();
      
      _currentBackend = backend;
      
      if (kDebugMode) {
        print('Initializing audio controller with backend: $backend');
        print('Platform: ${kIsWeb ? 'Web' : 'Native'}');
      }
      
      // Select appropriate service based on backend and platform
      _currentService = _selectAudioService(backend);
      
      await _currentService?.initialize();
      
      if (kDebugMode) {
        print('Audio controller initialized successfully with ${_currentService.runtimeType}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize audio controller: $e');
      }
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Select the appropriate audio service based on backend and platform
  AudioServiceInterface _selectAudioService(AudioBackend backend) {
    switch (backend) {
      case AudioBackend.midi:
        if (kIsWeb) {
          // On web, MIDI often has permission issues
          // Fall back to WebAudioService for better compatibility
          if (kDebugMode) {
            print('Web platform detected: Using WebAudioService instead of MIDI for better compatibility');
          }
          return WebAudioService.instance;
        } else {
          // Native platforms can use MIDI service
          return MidiAudioService.instance;
        }
        
      case AudioBackend.files:
        if (kIsWeb) {
          // Use WebAudioService for web platform
          return WebAudioService.instance;
        } else {
          // Use FileAudioService for native platforms
          return FileAudioService.instance;
        }
    }
  }
  
  /// Switch to a different audio backend
  Future<void> switchBackend(AudioBackend backend) async {
    if (backend != _currentBackend) {
      if (kDebugMode) {
        print('Switching audio backend from $_currentBackend to $backend');
      }
      await initialize(backend);
    }
  }
  
  /// Dispose of current service
  Future<void> dispose() async {
    if (_currentService != null) {
      if (kDebugMode) {
        print('Disposing audio service: ${_currentService.runtimeType}');
      }
      await _currentService?.dispose();
      _currentService = null;
    }
  }
  
  /// Call this when the app is paused/backgrounded
  Future<void> onAppPause() async {
    if (kDebugMode) {
      print('Audio controller: App paused, stopping all audio');
    }
    await stopAll();
  }
  
  /// Call this when the app is resumed/foregrounded
  Future<void> onAppResume() async {
    if (kDebugMode) {
      print('Audio controller: App resumed');
    }
    // Audio system should already be initialized
    // Nothing specific needed for resume
  }
  
  // Delegate methods to current service
  Future<void> playNote(int midiNumber, {int velocity = 127, Duration? duration}) async {
    if (!isReady) {
      if (kDebugMode) {
        print('Audio service not ready, cannot play note $midiNumber');
      }
      return;
    }
    
    await _currentService?.playNote(midiNumber, velocity: velocity, duration: duration);
  }
  
  Future<void> playMelody(List<int> midiNumbers, {
    Duration noteDuration = const Duration(milliseconds: 500),
    Duration gapDuration = const Duration(milliseconds: 50),
    int velocity = 127,
  }) async {
    if (!isReady || midiNumbers.isEmpty) {
      if (kDebugMode) {
        print('Audio service not ready or no notes provided for melody');
      }
      return;
    }
    
    await _currentService?.playMelody(
      midiNumbers,
      noteDuration: noteDuration,
      gapDuration: gapDuration,
      velocity: velocity,
    );
  }
  
  Future<void> playHarmony(List<int> midiNumbers, {
    Duration duration = const Duration(milliseconds: 2000),
    int velocity = 127,
  }) async {
    if (!isReady || midiNumbers.isEmpty) {
      if (kDebugMode) {
        print('Audio service not ready or no notes provided for harmony');
      }
      return;
    }
    
    await _currentService?.playHarmony(midiNumbers, duration: duration, velocity: velocity);
  }
  
  Future<void> stopAll() async {
    await _currentService?.stopAll();
  }
  
  Future<void> setVolume(double volume) async {
    await _currentService?.setVolume(volume);
  }
  
  /// Get MIDI notes from a fretboard configuration's highlighted intervals
  static List<int> getNotesFromConfig(FretboardConfig config) {
    final highlightMap = FretboardController.getHighlightMap(config);
    final midiNumbers = highlightMap.keys.toList()..sort();
    
    if (kDebugMode) {
      print('AudioController.getNotesFromConfig: Found ${midiNumbers.length} notes for ${config.viewMode.displayName} mode');
      print('MIDI notes: $midiNumbers');
    }
    
    return midiNumbers;
  }
  
  /// Get available backends
  static List<AudioBackend> getAvailableBackends() {
    return AudioBackend.values;
  }
  
  /// Get display name for backend with platform-specific details
  static String getBackendDisplayName(AudioBackend backend) {
    switch (backend) {
      case AudioBackend.midi:
        if (kIsWeb) {
          return 'MIDI Synthesizer (Web Audio)';
        } else {
          return 'MIDI Synthesizer';
        }
      case AudioBackend.files:
        if (kIsWeb) {
          return 'Audio Files (Web Audio)';
        } else {
          return 'Audio Files';
        }
    }
  }
  
  /// Get platform-specific recommendations
  static String getBackendDescription(AudioBackend backend) {
    switch (backend) {
      case AudioBackend.midi:
        if (kIsWeb) {
          return 'Uses Web Audio synthesis for reliable browser compatibility';
        } else {
          return 'Uses MIDI devices for high-quality synthesis';
        }
      case AudioBackend.files:
        if (kIsWeb) {
          return 'Web Audio synthesis with customizable waveforms';
        } else {
          return 'Pre-recorded audio files for authentic instrument sounds';
        }
    }
  }
}