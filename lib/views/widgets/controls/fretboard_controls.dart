// lib/views/widgets/controls/fretboard_controls.dart
import 'package:flutter/material.dart';
import '../../../models/fretboard/fretboard_instance.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/music/chord.dart';
import '../../../models/music/note.dart';
import 'root_selector.dart';
import 'view_mode_selector.dart';
import 'scale_selector.dart';
import 'chord_selector.dart';
import 'mode_selector.dart';
import 'octave_selector.dart';
import 'interval_selector.dart';
import 'tuning_selector.dart';

class FretboardControls extends StatelessWidget {
  final FretboardInstance instance;
  final Function(FretboardInstance) onUpdate;
  final int globalFretCount; // Added for proper fret count handling

  const FretboardControls({
    super.key,
    required this.instance,
    required this.onUpdate,
    required this.globalFretCount, // Added parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // First row: Root, View Mode, Scale/Chord, Mode/Inversion
          Row(
            children: [
              // Root selector
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Root',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    RootSelector(
                      value: instance.root,
                      onChanged: (root) {
                        debugPrint('FretboardControls: Root changed to $root');
                        final newIntervals =
                            instance.viewMode == ViewMode.intervals
                                ? {0}
                                : instance.selectedIntervals;
                        onUpdate(instance.copyWith(
                          root: root,
                          selectedIntervals: newIntervals,
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // View mode selector
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('View Mode',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    ViewModeSelector(
                      value: instance.viewMode,
                      onChanged: (mode) {
                        final newIntervals = mode == ViewMode.intervals
                            ? {0}
                            : instance.selectedIntervals;
                        onUpdate(instance.copyWith(
                          viewMode: mode,
                          selectedIntervals: newIntervals,
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Scale/Chord selector
              if (instance.viewMode == ViewMode.scales)
                Expanded(
                  flex: 2,
                  child: ScaleSelector(
                    value: instance.scale,
                    onChanged: (scale) {
                      onUpdate(instance.copyWith(
                        scale: scale,
                        modeIndex: 0,
                      ));
                    },
                  ),
                )
              else if (instance.viewMode == ViewMode.chordInversions)
                Expanded(
                  flex: 2,
                  child: ChordSelector(
                    currentChordType: instance.chordType,
                    onChordSelected: (chordType) {
                      onUpdate(instance.copyWith(
                        chordType: chordType,
                        chordInversion: ChordInversion.root,
                      ));
                    },
                  ),
                )
              else if (_isUnimplementedChordMode(instance.viewMode))
                Expanded(
                  flex: 2,
                  child: _buildUnimplementedSelector(context, instance.viewMode),
                )
              else
                const Expanded(flex: 2, child: SizedBox()),
              const SizedBox(width: 8),

              // Mode/Inversion selector
              if (instance.viewMode == ViewMode.scales)
                Expanded(
                  flex: 2,
                  child: ModeSelector(
                    scale: instance.scale,
                    value: instance.modeIndex,
                    onChanged: (index) {
                      onUpdate(instance.copyWith(modeIndex: index));
                    },
                  ),
                )
              else if (instance.viewMode == ViewMode.chordInversions)
                Expanded(
                  flex: 2,
                  child: _ChordInversionSelector(
                    chordType: instance.chordType,
                    value: instance.chordInversion,
                    onChanged: (inversion) {
                      onUpdate(instance.copyWith(chordInversion: inversion));
                    },
                  ),
                )
              else if (_isUnimplementedChordMode(instance.viewMode))
                Expanded(
                  flex: 2,
                  child: _buildUnimplementedVariationSelector(context, instance.viewMode),
                )
              else
                const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
          const SizedBox(height: 12),

          // Second row: Octaves and Intervals
          Row(
            children: [
              Expanded(
                child: OctaveSelector(
                  selectedOctaves: instance.selectedOctaves,
                  isChordMode: _isAnyChordMode(instance.viewMode),
                  onChanged: (octaves) {
                    onUpdate(instance.copyWith(selectedOctaves: octaves));
                  },
                ),
              ),
              const SizedBox(width: 16),
              if (instance.viewMode == ViewMode.intervals)
                Expanded(
                  child: IntervalSelector(
                    selectedIntervals: instance.selectedIntervals,
                    selectedOctaves: instance.selectedOctaves, // FIXED: Added missing parameter
                    onChanged: (intervals) {
                      onUpdate(instance.copyWith(selectedIntervals: intervals));
                    },
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 12),

          // Third row: Advanced settings
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tuning',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TuningSelector(
                      tuning: instance.tuning,
                      onChanged: (tuning) { // FIXED: Changed from onTuningChanged to onChanged
                        onUpdate(instance.copyWith(
                          tuning: tuning,
                          stringCount: tuning.length,
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fret Range',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    _FretRangeSlider( // RESTORED: Use slider instead of dropdowns
                      start: instance.visibleFretStart,
                      end: instance.visibleFretEnd,
                      maxFrets: globalFretCount,
                      onChanged: (start, end) {
                        onUpdate(instance.copyWith(
                          visibleFretStart: start,
                          visibleFretEnd: end,
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isAnyChordMode(ViewMode viewMode) {
    return viewMode == ViewMode.chordInversions ||
           viewMode == ViewMode.openChords ||
           viewMode == ViewMode.barreChords ||
           viewMode == ViewMode.advancedChords;
  }

  bool _isUnimplementedChordMode(ViewMode viewMode) {
    return viewMode == ViewMode.openChords ||
           viewMode == ViewMode.barreChords ||
           viewMode == ViewMode.advancedChords;
  }

  Widget _buildUnimplementedSelector(BuildContext context, ViewMode viewMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${viewMode.displayName.split(' ').first} Type',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade50,
          ),
          child: const Center(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnimplementedVariationSelector(BuildContext context, ViewMode viewMode) {
    String label = 'Variation';
    if (viewMode == ViewMode.openChords) {
      label = 'Position';
    } else if (viewMode == ViewMode.barreChords) {
      label = 'Barre Type';
    } else if (viewMode == ViewMode.advancedChords) {
      label = 'Extension';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade50,
          ),
          child: const Center(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Chord inversion selector widget
class _ChordInversionSelector extends StatelessWidget {
  final String chordType;
  final ChordInversion value;
  final Function(ChordInversion) onChanged;

  const _ChordInversionSelector({
    required this.chordType,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chord = Chord.get(chordType);
    final availableInversions = chord?.availableInversions ?? [ChordInversion.root];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inversion',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButton<ChordInversion>(
          value: availableInversions.contains(value) ? value : availableInversions.first,
          isExpanded: true,
          underline: const SizedBox(),
          items: availableInversions
              .map((inversion) => DropdownMenuItem(
                    value: inversion,
                    child: Text(
                      inversion.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ))
              .toList(),
          onChanged: (inversion) {
            if (inversion != null) {
              onChanged(inversion);
            }
          },
        ),
      ],
    );
  }
}

// Fret range slider widget - RESTORED from original implementation
class _FretRangeSlider extends StatelessWidget {
  final int start;
  final int end;
  final int maxFrets;
  final Function(int, int) onChanged;

  const _FretRangeSlider({
    required this.start,
    required this.end,
    required this.maxFrets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Range display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fret $start',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              'Fret $end',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Range slider
        RangeSlider(
          values: RangeValues(start.toDouble(), end.toDouble()),
          min: 0.0,
          max: maxFrets.toDouble(),
          divisions: maxFrets,
          labels: RangeLabels('$start', '$end'),
          onChanged: (RangeValues values) {
            final newStart = values.start.round();
            final newEnd = values.end.round();
            
            // Ensure minimum range of 1 fret
            if (newEnd > newStart) {
              onChanged(newStart, newEnd);
            }
          },
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }
}