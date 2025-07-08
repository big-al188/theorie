// lib/views/widgets/controls/octave_selector.dart
import 'package:flutter/material.dart';

class OctaveSelector extends StatelessWidget {
  final Set<int> selectedOctaves;
  final bool isChordMode;
  final Function(Set<int>) onChanged;

  const OctaveSelector({
    super.key,
    required this.selectedOctaves,
    required this.isChordMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have at least one octave for display
    final displayOctaves = selectedOctaves.isEmpty ? {3} : selectedOctaves;
    final selectedOctave = displayOctaves.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChordMode ? 'Root Octave (0-8)' : 'Octaves (0-8)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        if (isChordMode) ...[
          const SizedBox(height: 4),
          const Text(
            'Select the octave for the root note of the chord',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(
              9,
              (octave) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isChordMode)
                    Radio<int>(
                      value: octave,
                      groupValue: selectedOctave,
                      onChanged: (_) => _toggleOctave(octave),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  else
                    Checkbox(
                      value: displayOctaves.contains(octave),
                      onChanged: (_) => _toggleOctave(octave),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  Text('$octave', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (!isChordMode) ...[
              const SizedBox(width: 16),
              _QuickOctaveButton('0-2', () => _setOctaveRange(0, 2)),
              _QuickOctaveButton('3-5', () => _setOctaveRange(3, 5)),
              _QuickOctaveButton('6-8', () => _setOctaveRange(6, 8)),
              _QuickOctaveButton('All', () => _selectAllOctaves()),
            ],
          ],
        ),
      ],
    );
  }

  Widget _QuickOctaveButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(50, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  void _toggleOctave(int octave) {
    final newOctaves = Set<int>.from(selectedOctaves);

    if (isChordMode) {
      // Always set to the selected octave (radio button behavior)
      newOctaves.clear();
      newOctaves.add(octave);
    } else {
      // Original behavior for other modes
      if (newOctaves.contains(octave)) {
        if (newOctaves.length > 1) {
          newOctaves.remove(octave);
        }
      } else {
        newOctaves.add(octave);
      }
    }

    // Safety check - ensure we always have at least one octave
    if (newOctaves.isEmpty) {
      newOctaves.add(3);
    }

    onChanged(newOctaves);
  }

  void _setOctaveRange(int start, int end) {
    if (isChordMode) return;

    final newOctaves = <int>{};
    for (int i = start; i <= end; i++) {
      newOctaves.add(i);
    }

    if (newOctaves.isEmpty) {
      newOctaves.add(3);
    }

    onChanged(newOctaves);
  }

  void _selectAllOctaves() {
    if (isChordMode) return;

    final allOctaves = List.generate(9, (i) => i).toSet();
    onChanged(allOctaves);
  }
}
