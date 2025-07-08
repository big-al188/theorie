// lib/views/widgets/controls/interval_selector.dart
import 'package:flutter/material.dart';
import '../../../utils/chord_utils.dart';

class IntervalSelector extends StatefulWidget {
  final Set<int> selectedIntervals;
  final Set<int> selectedOctaves;
  final Function(Set<int>) onChanged;

  const IntervalSelector({
    super.key,
    required this.selectedIntervals,
    required this.selectedOctaves,
    required this.onChanged,
  });

  @override
  State<IntervalSelector> createState() => _IntervalSelectorState();
}

class _IntervalSelectorState extends State<IntervalSelector> {
  bool _showExtendedIntervals = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Selected Intervals',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            // Add current root display
            if (widget.selectedIntervals.length == 1 && !widget.selectedIntervals.contains(0))
              Text(
                '(Will become new root)',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (_hasExtendedIntervals())
              IconButton(
                icon: Icon(_showExtendedIntervals
                    ? Icons.expand_less
                    : Icons.expand_more),
                tooltip:
                    _showExtendedIntervals ? 'Hide Extended' : 'Show Extended',
                iconSize: 20,
                onPressed: () {
                  setState(() {
                    _showExtendedIntervals = !_showExtendedIntervals;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(
              12,
              (interval) => _buildIntervalChip(
                  interval, ChordUtils.getIntervalLabel(interval), context),
            ),
            const SizedBox(width: 16),
            _QuickIntervalButton('All Basic', _selectAllBasicIntervals),
            _QuickIntervalButton('Triad', _selectTriad),
            _QuickIntervalButton('7th', _select7thChord),
            _QuickIntervalButton('Extended', _addExtendedIntervals),
            _QuickIntervalButton('Reset', _resetToRoot),
          ],
        ),

        // Show extended intervals only if there are selected octaves beyond the first
        if (_hasExtendedIntervals())
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showExtendedIntervals
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildExtendedIntervalSections(context),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  bool _hasExtendedIntervals() {
    // Only show extended intervals if there are multiple octaves selected
    return widget.selectedOctaves.length > 1;
  }

  List<Widget> _buildExtendedIntervalSections(BuildContext context) {
    final sections = <Widget>[];
    final sortedOctaves = widget.selectedOctaves.toList()..sort();

    // Skip the first octave (base octave)
    for (int i = 1; i < sortedOctaves.length; i++) {
      final octaveOffset = i;
      sections.add(const SizedBox(height: 12));
      sections.add(Text(
        'Extended Intervals (Octave ${octaveOffset + 1})',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ));
      sections.add(const SizedBox(height: 8));
      sections.add(Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _buildOctaveChips(context, octaveOffset),
      ));
    }

    return sections;
  }

  List<Widget> _buildOctaveChips(BuildContext context, int octaveOffset) {
    return List.generate(12, (i) {
      final interval = i + (octaveOffset * 12);
      return _buildIntervalChip(
          interval, ChordUtils.getExtendedIntervalLabel(interval), context);
    });
  }

  Widget _buildIntervalChip(int interval, String label, BuildContext context) {
    final isSelected = widget.selectedIntervals.contains(interval);
    final willBecomeRoot = widget.selectedIntervals.length == 1 && 
                          isSelected && 
                          interval != 0;
    
    return InkWell(
      onTap: () => _toggleInterval(interval),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: willBecomeRoot
                ? Theme.of(context).primaryColor
                : isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey,
            width: willBecomeRoot ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _QuickIntervalButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(50, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  void _toggleInterval(int interval) {
    final newIntervals = Set<int>.from(widget.selectedIntervals);
    if (newIntervals.contains(interval)) {
      if (newIntervals.length > 1 || interval != 0) {
        newIntervals.remove(interval);
      }
    } else {
      newIntervals.add(interval);
    }
    widget.onChanged(newIntervals);
  }

  void _selectAllBasicIntervals() {
    final basicIntervals = List.generate(12, (i) => i).toSet();
    widget.onChanged(basicIntervals);
  }

  void _selectTriad() {
    widget.onChanged({0, 4, 7});
  }

  void _select7thChord() {
    widget.onChanged({0, 4, 7, 10});
  }

  void _addExtendedIntervals() {
    final currentIntervals = Set<int>.from(widget.selectedIntervals);
    // Add common extended intervals based on selected octaves
    final sortedOctaves = widget.selectedOctaves.toList()..sort();

    if (sortedOctaves.length > 1) {
      // Add 9th, 11th, 13th relative to selected octaves
      currentIntervals.addAll({0, 4, 7, 10, 14, 17, 21});
    } else {
      // If only one octave, just add the basic seventh chord
      currentIntervals.addAll({0, 4, 7, 10});
    }

    widget.onChanged(currentIntervals);
  }

  void _resetToRoot() {
    widget.onChanged({0});
  }
}