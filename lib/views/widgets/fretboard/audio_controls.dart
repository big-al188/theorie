// lib/views/widgets/fretboard/audio_controls.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../controllers/audio_controller.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../constants/ui_constants.dart';

class AudioControls extends StatefulWidget {
  final FretboardConfig config;
  
  const AudioControls({
    super.key,
    required this.config,
  });

  @override
  State<AudioControls> createState() => _AudioControlsState();
}

class _AudioControlsState extends State<AudioControls> {
  bool _isPlayingMelody = false;
  bool _isPlayingHarmony = false;

  @override
  Widget build(BuildContext context) {
    // UPDATED: Remove interval mode restriction - show audio controls for ALL modes
    // OLD: if (!widget.config.isIntervalMode) return const SizedBox.shrink();
    
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Don't show if audio is disabled
        if (!appState.audioEnabled) return const SizedBox.shrink();
        
        final highlightedNotes = AudioController.getNotesFromConfig(widget.config);
        final hasNotes = highlightedNotes.isNotEmpty;
        final isReady = AudioController.instance.isReady;
        final screenWidth = MediaQuery.of(context).size.width;
        final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
        
        // Determine if we should use compact layout
        final isCompact = deviceType == DeviceType.mobile;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 6.0 : 8.0),
            child: isCompact ? _buildCompactLayout(hasNotes, isReady, appState, highlightedNotes) 
                            : _buildFullLayout(hasNotes, isReady, appState, highlightedNotes),
          ),
        );
      },
    );
  }

  Widget _buildCompactLayout(bool hasNotes, bool isReady, AppState appState, List<int> highlightedNotes) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMelodyButton(hasNotes, isReady, appState, highlightedNotes, isCompact: true),
        const SizedBox(width: 4),
        _buildHarmonyButton(hasNotes, isReady, appState, highlightedNotes, isCompact: true),
        const SizedBox(width: 4),
        _buildStopButton(isCompact: true),
      ],
    );
  }

  Widget _buildFullLayout(bool hasNotes, bool isReady, AppState appState, List<int> highlightedNotes) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMelodyButton(hasNotes, isReady, appState, highlightedNotes),
        const SizedBox(width: 8),
        _buildHarmonyButton(hasNotes, isReady, appState, highlightedNotes),
        const SizedBox(width: 8),
        _buildStopButton(),
        const SizedBox(width: 8),
        _buildStatusIndicator(isReady, highlightedNotes.length),
      ],
    );
  }

  Widget _buildMelodyButton(bool hasNotes, bool isReady, AppState appState, List<int> highlightedNotes, {bool isCompact = false}) {
    final isEnabled = hasNotes && isReady && !_isPlayingMelody;
    
    if (isCompact) {
      return IconButton(
        onPressed: isEnabled ? () => _playMelody(appState, highlightedNotes) : null,
        icon: _isPlayingMelody 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.music_note, size: 20),
        tooltip: 'Play Melody',
        style: IconButton.styleFrom(
          backgroundColor: isEnabled ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: isEnabled ? () => _playMelody(appState, highlightedNotes) : null,
        icon: _isPlayingMelody 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.music_note),
        label: const Text('Melody'),
      );
    }
  }

  Widget _buildHarmonyButton(bool hasNotes, bool isReady, AppState appState, List<int> highlightedNotes, {bool isCompact = false}) {
    final isEnabled = hasNotes && isReady && !_isPlayingHarmony && highlightedNotes.length > 1;
    
    if (isCompact) {
      return IconButton(
        onPressed: isEnabled ? () => _playHarmony(appState, highlightedNotes) : null,
        icon: _isPlayingHarmony
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.library_music, size: 20),
        tooltip: 'Play Harmony',
        style: IconButton.styleFrom(
          backgroundColor: isEnabled ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: isEnabled ? () => _playHarmony(appState, highlightedNotes) : null,
        icon: _isPlayingHarmony
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.library_music),
        label: const Text('Harmony'),
      );
    }
  }

  Widget _buildStopButton({bool isCompact = false}) {
    if (isCompact) {
      return IconButton(
        onPressed: _stopAll,
        icon: const Icon(Icons.stop, size: 20),
        tooltip: 'Stop Audio',
        style: IconButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _stopAll,
        icon: const Icon(Icons.stop),
        label: const Text('Stop'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildStatusIndicator(bool isReady, int noteCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.volume_up : Icons.volume_off,
            size: 16,
            color: isReady ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            noteCount > 0 ? '$noteCount notes' : 'No notes',
            style: TextStyle(
              fontSize: 12,
              color: isReady ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playMelody(AppState appState, List<int> midiNumbers) async {
    if (_isPlayingMelody) return;

    setState(() {
      _isPlayingMelody = true;
    });

    try {
      await AudioController.instance.playMelody(
        midiNumbers,
        noteDuration: appState.melodyNoteDuration,
        gapDuration: appState.melodyGapDuration,
        velocity: appState.defaultVelocity,
      );
      
      // Wait for the melody to finish
      final totalDuration = (appState.melodyNoteDuration + appState.melodyGapDuration) * midiNumbers.length;
      await Future.delayed(totalDuration);
    } catch (e) {
      debugPrint('Error playing melody: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPlayingMelody = false;
        });
      }
    }
  }

  Future<void> _playHarmony(AppState appState, List<int> midiNumbers) async {
    if (_isPlayingHarmony) return;

    setState(() {
      _isPlayingHarmony = true;
    });

    try {
      await AudioController.instance.playHarmony(
        midiNumbers,
        duration: appState.harmonyDuration,
        velocity: appState.defaultVelocity,
      );
      
      // Wait for the harmony to finish
      await Future.delayed(appState.harmonyDuration);
    } catch (e) {
      debugPrint('Error playing harmony: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPlayingHarmony = false;
        });
      }
    }
  }

  Future<void> _stopAll() async {
    await AudioController.instance.stopAll();
    
    if (mounted) {
      setState(() {
        _isPlayingMelody = false;
        _isPlayingHarmony = false;
      });
    }
  }
}