// lib/views/dialogs/settings_sections.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/fretboard/fretboard_config.dart';
import '../../models/music/scale.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';
import '../../constants/music_constants.dart';

// ===== MAIN SECTION WIDGETS =====

class FretboardDefaultsSection extends StatelessWidget {
  const FretboardDefaultsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Fretboard Defaults', style: UIConstants.subheadingStyle),
      subtitle: const Text('Default settings for new fretboards'),
      initiallyExpanded: true,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              DefaultConfigurationSection(),
              SizedBox(height: 24),
              DefaultTuningSection(),
              SizedBox(height: 24),
              DefaultLayoutSection(),
              SizedBox(height: 24),
              DefaultMusicSettingsSection(),
              SizedBox(height: 24),
              DefaultOctaveSection(),
              SizedBox(height: 24),
              PresetTuningsSection(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class AppPreferencesSection extends StatelessWidget {
  const AppPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('App Preferences', style: UIConstants.subheadingStyle),
      subtitle: const Text('Application-wide settings'),
      initiallyExpanded: true,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              ThemeSection(),
              SizedBox(height: 16),
              // Future app preferences can be added here
            ],
          ),
        ),
      ],
    );
  }
}

// ===== FRETBOARD DEFAULTS SUBSECTIONS =====

class DefaultConfigurationSection extends StatelessWidget {
  const DefaultConfigurationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default Configuration', style: UIConstants.labelStyle),
        const SizedBox(height: 12),
        SettingsSlider(
          label: 'Default String Count',
          value: state.defaultStringCount.toDouble(),
          min: AppConstants.minStrings.toDouble(),
          max: AppConstants.maxStrings.toDouble(),
          onChanged: (value) => state.setDefaultStringCount(value.toInt()),
        ),
        SettingsSlider(
          label: 'Default Fret Count',
          value: state.defaultFretCount.toDouble(),
          min: AppConstants.minFrets.toDouble(),
          max: AppConstants.maxFrets.toDouble(),
          onChanged: (value) => state.setDefaultFretCount(value.toInt()),
        ),
      ],
    );
  }
}

class DefaultTuningSection extends StatelessWidget {
  const DefaultTuningSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default Tuning (low → high)', style: UIConstants.labelStyle),
        const SizedBox(height: 12),
        for (int i = 0; i < state.defaultStringCount; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DefaultTuningRow(stringIndex: i),
          ),
      ],
    );
  }
}

class DefaultTuningRow extends StatelessWidget {
  final int stringIndex;

  const DefaultTuningRow({super.key, required this.stringIndex});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tuningString = state.defaultTuning[stringIndex];

    // Parse current tuning
    final match =
        RegExp(r'^([A-G](?:#|♯|b|♭)?)(\d+)$').firstMatch(tuningString);
    final currentNote = match?.group(1) ?? 'C';
    final currentOctave = int.tryParse(match?.group(2) ?? '3') ?? 3;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text('String ${stringIndex + 1}:'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButton<String>(
            value: currentNote,
            isExpanded: true,
            items: const [
              'C',
              'C#',
              'D',
              'D#',
              'E',
              'F',
              'F#',
              'G',
              'G#',
              'A',
              'A#',
              'B'
            ]
                .map((note) => DropdownMenuItem(value: note, child: Text(note)))
                .toList(),
            onChanged: (note) {
              if (note != null) {
                state.setDefaultTuningNote(stringIndex, note, currentOctave);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: DropdownButton<int>(
            value: currentOctave,
            isExpanded: true,
            items: List.generate(9, (i) => i)
                .map((octave) =>
                    DropdownMenuItem(value: octave, child: Text('$octave')))
                .toList(),
            onChanged: (octave) {
              if (octave != null) {
                state.setDefaultTuningNote(stringIndex, currentNote, octave);
              }
            },
          ),
        ),
      ],
    );
  }
}

class DefaultLayoutSection extends StatelessWidget {
  const DefaultLayoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default Layout', style: UIConstants.labelStyle),
        const SizedBox(height: 12),
        DropdownButton<FretboardLayout>(
          value: state.defaultLayout,
          isExpanded: true,
          items: FretboardLayout.values
              .map((layout) => DropdownMenuItem(
                    value: layout,
                    child: Text(layout.displayName),
                  ))
              .toList(),
          onChanged: (layout) {
            if (layout != null) {
              state.setDefaultLayout(layout);
            }
          },
        ),
      ],
    );
  }
}

class DefaultMusicSettingsSection extends StatelessWidget {
  const DefaultMusicSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default Music Settings', style: UIConstants.labelStyle),
        const SizedBox(height: 12),

        // Default Root
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('Default Root:', style: UIConstants.smallLabelStyle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: state.defaultRoot,
                isExpanded: true,
                items: MusicConstants.commonRoots
                    .map((root) =>
                        DropdownMenuItem(value: root, child: Text(root)))
                    .toList(),
                onChanged: (root) {
                  if (root != null) {
                    state.setDefaultRoot(root);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Default View Mode
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('Default View:', style: UIConstants.smallLabelStyle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<ViewMode>(
                value: state.defaultViewMode,
                isExpanded: true,
                items: ViewMode.values
                    .map((mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.displayName),
                        ))
                    .toList(),
                onChanged: (mode) {
                  if (mode != null) {
                    state.setDefaultViewMode(mode);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Default Scale (if applicable)
        if (state.defaultViewMode == ViewMode.scales)
          Row(
            children: [
              SizedBox(
                width: 100,
                child:
                    Text('Default Scale:', style: UIConstants.smallLabelStyle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: state.defaultScale,
                  isExpanded: true,
                  items: [
                    'Major',
                    'Natural Minor',
                    'Minor Pentatonic',
                    'Major Pentatonic',
                    'Blues',
                    'Dorian',
                    'Mixolydian'
                  ]
                      .map((scale) =>
                          DropdownMenuItem(value: scale, child: Text(scale)))
                      .toList(),
                  onChanged: (scale) {
                    if (scale != null) {
                      state.setDefaultScale(scale);
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class DefaultOctaveSection extends StatelessWidget {
  const DefaultOctaveSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default Octave Selection (0-8)', style: UIConstants.labelStyle),
        const SizedBox(height: 12),

        // Current selection display
        Text(
          'Selected: ${_formatOctaves(state.defaultSelectedOctaves)} (${state.defaultSelectedOctaves.length} octaves)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),

        // Individual octave checkboxes
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(
            9,
            (octave) => InkWell(
              onTap: () => _toggleDefaultOctave(state, octave),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.defaultSelectedOctaves.contains(octave)
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: state.defaultSelectedOctaves.contains(octave)
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.defaultSelectedOctaves.contains(octave)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: state.defaultSelectedOctaves.contains(octave)
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text('Oct $octave', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick selection buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickSelectButton(
              context,
              '0-2 (Low)',
              () => state.setDefaultSelectedOctaves({0, 1, 2}),
            ),
            _QuickSelectButton(
              context,
              '3-5 (Mid)',
              () => state.setDefaultSelectedOctaves({3, 4, 5}),
            ),
            _QuickSelectButton(
              context,
              '6-8 (High)',
              () => state.setDefaultSelectedOctaves({6, 7, 8}),
            ),
            _QuickSelectButton(
              context,
              'Reset Default',
              () =>
                  state.setDefaultSelectedOctaves({AppConstants.defaultOctave}),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleDefaultOctave(AppState state, int octave) {
    final newOctaves = Set<int>.from(state.defaultSelectedOctaves);

    if (newOctaves.contains(octave)) {
      if (newOctaves.length > 1) {
        newOctaves.remove(octave);
      }
    } else {
      newOctaves.add(octave);
    }

    state.setDefaultSelectedOctaves(newOctaves);
  }

  Widget _QuickSelectButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  String _formatOctaves(Set<int> octaves) {
    if (octaves.isEmpty) return 'None';
    if (octaves.length == 1) return octaves.first.toString();

    final sorted = octaves.toList()..sort();
    if (sorted.length <= 3) {
      return sorted.join(', ');
    }

    // Check for consecutive ranges
    final ranges = <String>[];
    int start = sorted[0];
    int end = sorted[0];

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        if (start == end) {
          ranges.add('$start');
        } else {
          ranges.add('$start-$end');
        }
        start = end = sorted[i];
      }
    }

    if (start == end) {
      ranges.add('$start');
    } else {
      ranges.add('$start-$end');
    }

    return ranges.join(', ');
  }
}

class PresetTuningsSection extends StatelessWidget {
  const PresetTuningsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preset Tunings', style: UIConstants.labelStyle),
        const SizedBox(height: 12),
        DropdownButton<String>(
          hint: const Text('Apply Standard Tuning as Default'),
          isExpanded: true,
          items: MusicConstants.standardTunings.keys
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (tuningName) {
            if (tuningName != null) {
              state.applyStandardTuningAsDefault(tuningName);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                state.resetDefaultsToFactorySettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Fretboard defaults reset to factory settings'),
                  ),
                );
              },
              child: const Text('Reset Defaults'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                state.resetAllToFactorySettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All settings reset to factory defaults'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Reset Everything'),
            ),
          ],
        ),
      ],
    );
  }
}

// ===== APP PREFERENCES SUBSECTIONS =====

class ThemeSection extends StatelessWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: UIConstants.labelStyle),
        const SizedBox(height: 12),

        // Theme mode selector
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_system_daydream),
            ),
          ],
          selected: {state.themeMode},
          onSelectionChanged: (Set<ThemeMode> selected) {
            if (selected.isNotEmpty) {
              state.setThemeMode(selected.first);
            }
          },
        ),

        const SizedBox(height: 8),

        // Theme description
        Text(
          _getThemeDescription(state.themeMode),
          style: UIConstants.smallLabelStyle,
        ),
      ],
    );
  }

  String _getThemeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system theme setting';
    }
  }
}

// ===== UTILITY WIDGETS =====

class SettingsSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const SettingsSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toInt().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
