// lib/views/widgets/controls/mode_selector.dart
import 'package:flutter/material.dart';
import '../../../controllers/music_controller.dart';

class ModeSelector extends StatelessWidget {
  final String scale;
  final int value;
  final Function(int) onChanged;

  const ModeSelector({
    super.key,
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final availableModes = MusicController.getAvailableModes(scale);

    if (availableModes.isEmpty) {
      return const SizedBox();
    }

    final validModeIndex = value.clamp(0, availableModes.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButton<int>(
          value: validModeIndex,
          isExpanded: true,
          underline: const SizedBox(),
          items: availableModes
              .asMap()
              .entries
              .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      '${entry.key + 1}. ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (index) {
            if (index != null) {
              onChanged(index);
            }
          },
        ),
      ],
    );
  }
}
