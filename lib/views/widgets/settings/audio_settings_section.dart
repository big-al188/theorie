// lib/views/widgets/settings/audio_settings_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../controllers/audio_controller.dart';

class AudioSettingsSection extends StatelessWidget {
  const AudioSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context),
                const SizedBox(height: 16),
                
                // Audio Enable Toggle
                _buildAudioToggle(appState),
                
                if (appState.audioEnabled) ...[
                  const Divider(),
                  
                  // Audio Backend Selection
                  _buildBackendSelection(appState),
                  
                  // Volume Control
                  _buildVolumeControl(appState),
                  
                  // Velocity Control
                  _buildVelocityControl(appState),
                  
                  const Divider(),
                  
                  // Melody Settings
                  _buildMelodySettings(appState),
                  
                  // Harmony Settings
                  _buildHarmonySettings(appState),
                  
                  const SizedBox(height: 16),
                  
                  // Test Audio Button
                  _buildTestAudioButton(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.volume_up, 
          size: 24,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Audio Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioToggle(AppState appState) {
    return SwitchListTile(
      title: const Text('Enable Audio'),
      subtitle: const Text('Turn audio playback on or off'),
      value: appState.audioEnabled,
      onChanged: appState.setAudioEnabled,
      secondary: Icon(
        appState.audioEnabled ? Icons.volume_up : Icons.volume_off,
        color: appState.audioEnabled ? Colors.green : Colors.grey,
      ),
    );
  }

  Widget _buildBackendSelection(AppState appState) {
    return ListTile(
      leading: const Icon(Icons.settings_input_component),
      title: const Text('Audio Engine'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current: ${AudioController.instance.serviceName}'),
          if (AudioController.instance.isInitializing)
            const LinearProgressIndicator()
          else if (!AudioController.instance.isReady)
            Text(
              'Audio engine not ready',
              style: TextStyle(color: Colors.orange.shade700),
            ),
        ],
      ),
      trailing: DropdownButton<AudioBackend>(
        value: appState.audioBackend,
        items: AudioBackend.values.map((backend) {
          return DropdownMenuItem(
            value: backend,
            child: Text(AudioController.getBackendDisplayName(backend)),
          );
        }).toList(),
        onChanged: (backend) {
          if (backend != null && backend != appState.audioBackend) {
            appState.setAudioBackend(backend);
          }
        },
      ),
    );
  }

  Widget _buildVolumeControl(AppState appState) {
    return ListTile(
      leading: const Icon(Icons.volume_up),
      title: const Text('Volume'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Slider(
            value: appState.audioVolume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(appState.audioVolume * 100).round()}%',
            onChanged: appState.setAudioVolume,
          ),
          Text('${(appState.audioVolume * 100).round()}%'),
        ],
      ),
    );
  }

  Widget _buildVelocityControl(AppState appState) {
    return ListTile(
      leading: const Icon(Icons.speed),
      title: const Text('Note Velocity'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Controls how hard notes are played (1-127)'),
          Slider(
            value: appState.defaultVelocity.toDouble(),
            min: 1.0,
            max: 127.0,
            divisions: 126,
            label: appState.defaultVelocity.toString(),
            onChanged: (value) => appState.setDefaultVelocity(value.round()),
          ),
          Text('${appState.defaultVelocity}'),
        ],
      ),
    );
  }

  Widget _buildMelodySettings(AppState appState) {
    return ExpansionTile(
      leading: const Icon(Icons.music_note),
      title: const Text('Melody Settings'),
      subtitle: const Text('Configure how melodies play'),
      children: [
        ListTile(
          title: const Text('Note Duration'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How long each note plays'),
              Slider(
                value: appState.melodyNoteDuration.inMilliseconds.toDouble(),
                min: 100.0,
                max: 2000.0,
                divisions: 19,
                label: '${appState.melodyNoteDuration.inMilliseconds}ms',
                onChanged: (value) => appState.setMelodyNoteDuration(
                  Duration(milliseconds: value.round()),
                ),
              ),
              Text('${appState.melodyNoteDuration.inMilliseconds}ms'),
            ],
          ),
        ),
        ListTile(
          title: const Text('Gap Between Notes'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pause between melody notes'),
              Slider(
                value: appState.melodyGapDuration.inMilliseconds.toDouble(),
                min: 0.0,
                max: 500.0,
                divisions: 25,
                label: '${appState.melodyGapDuration.inMilliseconds}ms',
                onChanged: (value) => appState.setMelodyGapDuration(
                  Duration(milliseconds: value.round()),
                ),
              ),
              Text('${appState.melodyGapDuration.inMilliseconds}ms'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHarmonySettings(AppState appState) {
    return ExpansionTile(
      leading: const Icon(Icons.library_music),
      title: const Text('Harmony Settings'),
      subtitle: const Text('Configure how chords play'),
      children: [
        ListTile(
          title: const Text('Chord Duration'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How long harmony notes play together'),
              Slider(
                value: appState.harmonyDuration.inMilliseconds.toDouble(),
                min: 500.0,
                max: 5000.0,
                divisions: 18,
                label: '${(appState.harmonyDuration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                onChanged: (value) => appState.setHarmonyDuration(
                  Duration(milliseconds: value.round()),
                ),
              ),
              Text('${(appState.harmonyDuration.inMilliseconds / 1000).toStringAsFixed(1)}s'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestAudioButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: AudioController.instance.isReady ? _testAudio : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Test Audio'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _testAudio() {
    // Play a simple C major chord (C4, E4, G4)
    final testNotes = [60, 64, 67];
    AudioController.instance.playHarmony(
      testNotes,
      duration: const Duration(milliseconds: 1500),
    );
  }
}