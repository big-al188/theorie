// lib/services/audio/midi_audio_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'audio_service_interface.dart';

/// MIDI-based audio service implementation
class MidiAudioService implements AudioServiceInterface {
  static MidiAudioService? _instance;
  static MidiAudioService get instance {
    _instance ??= MidiAudioService._();
    return _instance!;
  }

  MidiAudioService._();

  final MidiCommand _midiCommand = MidiCommand(); // NOTE: Changed from FlutterMidiCommand
  bool _isInitialized = false;
  double _volume = 0.7;
  MidiDevice? _selectedDevice;
  List<MidiDevice> _availableDevices = [];
  final Set<int> _activeNotes = <int>{};

  @override
  Future<bool> initialize() async {
    try {
      debugPrint('🎹 [MidiAudioService] Initializing MIDI service...');
      
      // NOTE: No setup() method needed - MidiCommand is ready to use
      
      // Scan for available MIDI devices
      await _scanForDevices();
      
      // Try to connect to first available device (or create virtual device)
      if (_availableDevices.isNotEmpty) {
        await _connectToDevice(_availableDevices.first);
      } else {
        // Create a virtual MIDI device if no physical devices available
        await _createVirtualDevice();
      }
      
      // Set default instrument (piano) if we have a connected device
      if (_selectedDevice != null) {
        _sendMidiData([0xC0, 0]); // Program change to piano
      }
      
      _isInitialized = true;
      debugPrint('✅ [MidiAudioService] MIDI service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Failed to initialize: $e');
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await stopAll();
      if (_selectedDevice != null) {
        _midiCommand.disconnectDevice(_selectedDevice!);
        _selectedDevice = null;
      }
      _activeNotes.clear();
      _isInitialized = false;
      debugPrint('🎹 [MidiAudioService] MIDI service disposed');
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Error disposing: $e');
    }
  }

  @override
  Future<void> playNote(int midiNote, {int velocity = 100, Duration? duration}) async {
    if (!_isInitialized) {
      debugPrint('⚠️ [MidiAudioService] Cannot play note - not initialized');
      return;
    }

    try {
      final clampedMidiNote = midiNote.clamp(0, 127);
      final adjustedVelocity = (_volume * velocity).round().clamp(1, 127);
      
      // Stop the note if it's already playing
      if (_activeNotes.contains(clampedMidiNote)) {
        await stopNote(clampedMidiNote);
      }
      
      // Send MIDI note on
      _sendMidiData([0x90, clampedMidiNote, adjustedVelocity]); // Channel 1, Note On
      _activeNotes.add(clampedMidiNote);
      
      debugPrint('🎵 [MidiAudioService] Playing MIDI note: $clampedMidiNote, velocity: $adjustedVelocity');
      
      // If duration is specified, schedule note off
      if (duration != null) {
        Timer(duration, () => stopNote(clampedMidiNote));
      }
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Error playing note $midiNote: $e');
    }
  }

  @override
  Future<void> stopNote(int midiNote) async {
    if (!_isInitialized) return;

    try {
      final clampedMidiNote = midiNote.clamp(0, 127);
      
      // Send MIDI note off
      _sendMidiData([0x80, clampedMidiNote, 0]); // Channel 1, Note Off
      _activeNotes.remove(clampedMidiNote);
      
      debugPrint('🎵 [MidiAudioService] Stopping MIDI note: $clampedMidiNote');
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Error stopping note $midiNote: $e');
    }
  }

  @override
  Future<void> playMelody(List<int> midiNotes, {
    Duration noteDuration = const Duration(milliseconds: 500),
    Duration gapDuration = const Duration(milliseconds: 50),
    int velocity = 100,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ [MidiAudioService] Cannot play melody - not initialized');
      return;
    }

    debugPrint('🎼 [MidiAudioService] Playing melody: $midiNotes');

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
    if (!_isInitialized) {
      debugPrint('⚠️ [MidiAudioService] Cannot play harmony - not initialized');
      return;
    }

    debugPrint('🎵 [MidiAudioService] Playing harmony: $midiNotes');

    // Play all notes simultaneously
    for (final note in midiNotes) {
      await playNote(note, velocity: velocity);
    }

    // Stop all notes after duration
    Timer(duration, () async {
      for (final note in midiNotes) {
        await stopNote(note);
      }
    });
  }

  @override
  Future<void> stopAll() async {
    if (!_isInitialized) return;

    try {
      // Stop all currently active notes
      final notesToStop = List<int>.from(_activeNotes);
      for (final midiNote in notesToStop) {
        await stopNote(midiNote);
      }
      
      // Send All Notes Off message (CC 123) for each channel as backup
      for (int channel = 0; channel < 16; channel++) {
        _sendMidiData([0xB0 + channel, 123, 0]); // All Notes Off
      }
      
      _activeNotes.clear();
      debugPrint('🎵 [MidiAudioService] All notes stopped');
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Error stopping all notes: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    
    // Send MIDI volume change (CC 7) if we have a device
    if (_isInitialized && _selectedDevice != null) {
      try {
        final midiVolume = (_volume * 127).round();
        _sendMidiData([0xB0, 7, midiVolume]); // Channel 1, Volume
        
        debugPrint('🔊 [MidiAudioService] Volume set to: $_volume (MIDI: $midiVolume)');
      } catch (e) {
        debugPrint('❌ [MidiAudioService] Error setting volume: $e');
      }
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  double get volume => _volume;

  // MIDI-specific methods

  /// Send MIDI data using the correct API
  void _sendMidiData(List<int> data) {
    if (_selectedDevice != null) {
      // NOTE: sendData returns void, so no await
      _midiCommand.sendData(
        Uint8List.fromList(data),
        deviceId: _selectedDevice!.id,
      );
    }
  }

  /// Scan for available MIDI devices
  Future<void> _scanForDevices() async {
    try {
      final devices = await _midiCommand.devices;
      _availableDevices = devices ?? [];
      
      debugPrint('🎹 [MidiAudioService] Found ${_availableDevices.length} MIDI devices:');
      for (final device in _availableDevices) {
        debugPrint('  - ${device.name} (${device.type})');
      }
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Error scanning for devices: $e');
      _availableDevices = [];
    }
  }

  /// Connect to a specific MIDI device
  Future<bool> _connectToDevice(MidiDevice device) async {
    try {
      await _midiCommand.connectToDevice(device);
      _selectedDevice = device;
      
      debugPrint('✅ [MidiAudioService] Connected to MIDI device: ${device.name}');
      return true;
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Failed to connect to device ${device.name}: $e');
      return false;
    }
  }

  /// Create a virtual MIDI device for output
  Future<void> _createVirtualDevice() async {
    try {
      _midiCommand.addVirtualDevice(name: "Theorie Audio");
      debugPrint('🎹 [MidiAudioService] Created virtual MIDI device: Theorie Audio');
      
      // For virtual devices, we don't have a specific device object
      // but we can still send MIDI data
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Failed to create virtual device: $e');
    }
  }

  /// Get list of available MIDI devices
  List<MidiDevice> get availableDevices => List.unmodifiable(_availableDevices);

  /// Get currently selected MIDI device
  MidiDevice? get selectedDevice => _selectedDevice;

  /// Manually select and connect to a MIDI device
  Future<bool> selectDevice(MidiDevice device) async {
    if (!_isInitialized) return false;

    // Disconnect from current device if any
    if (_selectedDevice != null) {
      _midiCommand.disconnectDevice(_selectedDevice!);
    }

    return await _connectToDevice(device);
  }

  /// Refresh the list of available MIDI devices
  Future<void> refreshDevices() async {
    await _scanForDevices();
  }

  /// Start Bluetooth scanning for BLE MIDI devices
  Future<void> startBluetoothScanning() async {
    try {
      await _midiCommand.startBluetoothCentral();
      await _midiCommand.startScanningForBluetoothDevices();
      debugPrint('🔵 [MidiAudioService] Started Bluetooth MIDI scanning');
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Error starting Bluetooth scanning: $e');
    }
  }

  /// Stop Bluetooth scanning
  void stopBluetoothScanning() {
    try {
      _midiCommand.stopScanningForBluetoothDevices();
      debugPrint('🔵 [MidiAudioService] Stopped Bluetooth MIDI scanning');
    } catch (e) {
      debugPrint('❌ [MidiAudioService] Error stopping Bluetooth scanning: $e');
    }
  }
}