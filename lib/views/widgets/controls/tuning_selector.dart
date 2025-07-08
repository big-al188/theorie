// lib/views/widgets/controls/tuning_selector.dart
import 'package:flutter/material.dart';
import '../../../models/music/tuning.dart';

class TuningSelector extends StatelessWidget {
  final List<String> tuning;
  final Function(List<String>) onChanged;

  const TuningSelector({
    super.key,
    required this.tuning,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String? standardTuningName;

    // Find matching standard tuning
    for (final entry in Tuning.all.entries) {
      if (entry.value.equals(tuning)) {
        standardTuningName = entry.key;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tuning',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButton<String>(
          isExpanded: true,
          value: standardTuningName,
          hint: Text(
            'Custom (${tuning.length} strings)',
            style: const TextStyle(fontSize: 12),
          ),
          underline: const SizedBox(),
          items: Tuning.all.keys
              .map((name) => DropdownMenuItem(
                    value: name,
                    child: Text(name, style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (tuningName) {
            if (tuningName != null) {
              final selectedTuning = Tuning.all[tuningName];
              if (selectedTuning != null) {
                onChanged(selectedTuning.strings);
              }
            }
          },
        ),
      ],
    );
  }
}
