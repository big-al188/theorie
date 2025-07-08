// lib/views/dialogs/settings_sections.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/fretboard/fretboard_config.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';
import '../../constants/music_constants.dart';

class FretboardConfigSection extends StatelessWidget {
  const FretboardConfigSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fretboard Configuration', style: UIConstants.subheadingStyle),
        const SizedBox(height: 16),
        SettingsSlider(
          label: 'Number of Strings',
          value: state.stringCount.toDouble(),
          min: AppConstants.minStrings.toDouble(),
          max: AppConstants.maxStrings.toDouble(),
          onChanged: (value) => state.setStringCount(value.toInt()),
        ),
        SettingsSlider(
          label: 'Number of Frets',
          value: state.fretCount.toDouble(),
          min: AppConstants.minFrets.toDouble(),
          max: AppConstants.maxFrets.toDouble(),
          onChanged: (value) => state.setFretCount(value.toInt()),
        ),
      ],
    );
  }
}

class TuningSection extends StatelessWidget {
  const TuningSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tuning (low → high)', style: UIConstants.subheadingStyle),
        const SizedBox(height: 16),
        for (int i = 0; i < state.stringCount; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TuningRow(stringIndex: i),
          ),
      ],
    );
  }
}

class TuningRow extends StatelessWidget {
  final int stringIndex;

  const TuningRow({super.key, required this.stringIndex});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tuningString = state.tuning[stringIndex];

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
                state.setTuningNote(stringIndex, note, currentOctave);
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
                state.setTuningNote(stringIndex, currentNote, octave);
              }
            },
          ),
        ),
      ],
    );
  }
}

class LayoutSection extends StatelessWidget {
  const LayoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layout', style: UIConstants.subheadingStyle),
        const SizedBox(height: 16),
        DropdownButton<FretboardLayout>(
          value: state.layout,
          isExpanded: true,
          items: FretboardLayout.values
              .map((layout) => DropdownMenuItem(
                    value: layout,
                    child: Text(layout.displayName),
                  ))
              .toList(),
          onChanged: (layout) {
            if (layout != null) {
              state.setLayout(layout);
            }
          },
        ),
      ],
    );
  }
}

class OctaveSection extends StatelessWidget {
  const OctaveSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Octave Selection (0-8)', style: UIConstants.subheadingStyle),
        const SizedBox(height: 16),

        // Current selection display
        Text(
          'Selected: ${_formatOctaves(state.selectedOctaves)} (${state.selectedOctaves.length} octaves)',
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
              onTap: () => state.toggleOctave(octave),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.selectedOctaves.contains(octave)
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: state.selectedOctaves.contains(octave)
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.selectedOctaves.contains(octave)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: state.selectedOctaves.contains(octave)
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
              () => state.setOctaveRange(0, 2),
            ),
            _QuickSelectButton(
              context,
              '3-5 (Mid)',
              () => state.setOctaveRange(3, 5),
            ),
            _QuickSelectButton(
              context,
              '6-8 (High)',
              () => state.setOctaveRange(6, 8),
            ),
            _QuickSelectButton(
              context,
              'Select All',
              () => state.selectAllOctaves(),
            ),
            _QuickSelectButton(
              context,
              'Reset Default',
              () => state.resetToDefaultOctave(),
            ),
          ],
        ),
      ],
    );
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

class PresetSection extends StatelessWidget {
  const PresetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Presets', style: UIConstants.subheadingStyle),
        const SizedBox(height: 16),
        DropdownButton<String>(
          hint: const Text('Apply Standard Tuning'),
          isExpanded: true,
          items: MusicConstants.standardTunings.keys
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (tuningName) {
            if (tuningName != null) {
              state.applyStandardTuning(tuningName);
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            state.resetToDefaults();
            Navigator.of(context).pop();
          },
          child: const Text('Reset to Defaults'),
        ),
      ],
    );
  }
}

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
