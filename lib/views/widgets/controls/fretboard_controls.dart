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
              else if (instance.viewMode == ViewMode.chords)
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
              else if (instance.viewMode == ViewMode.chords)
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
                  isChordMode: instance.viewMode == ViewMode.chords, // FIXED: Added required parameter
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
                    selectedOctaves: instance.selectedOctaves,
                    onChanged: (intervals) { // FIXED: Changed from onIntervalsChanged to onChanged
                      onUpdate(instance.copyWith(selectedIntervals: intervals));
                    },
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),

          // Tuning selector
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Tuning',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Text(
                          '${instance.stringCount} strings',
                          style: TextStyle(
                              fontSize: 11, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TuningSelector(
                      tuning: instance.tuning,
                      onChanged: (tuning) { // FIXED: Changed from onTuningChanged to onChanged, removed stringCount
                        onUpdate(instance.copyWith(
                          tuning: tuning,
                          stringCount: tuning.length, // Update string count based on tuning length
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Improved fret range selector
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FretRangeSelector(
                  visibleFretStart: instance.visibleFretStart,
                  visibleFretEnd: instance.visibleFretEnd,
                  maxFrets: globalFretCount, // Use actual global fret count
                  onChanged: (start, end) {
                    onUpdate(instance.copyWith(
                      visibleFretStart: start,
                      visibleFretEnd: end,
                    ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    if (chord == null) return const SizedBox();

    final availableInversions = chord.availableInversions;
    final currentInversion =
        availableInversions.contains(value) ? value : ChordInversion.root;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inversion',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButton<ChordInversion>(
          value: currentInversion,
          isExpanded: true,
          underline: const SizedBox(),
          items: availableInversions
              .map((inversion) => DropdownMenuItem(
                    value: inversion,
                    child: Text(inversion.displayName,
                        style: const TextStyle(fontSize: 12)),
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

// IMPROVED: Dual-handle range slider for fret range selection
class _FretRangeSelector extends StatelessWidget {
  final int visibleFretStart;
  final int visibleFretEnd;
  final int maxFrets;
  final Function(int, int) onChanged;

  const _FretRangeSelector({
    required this.visibleFretStart,
    required this.visibleFretEnd,
    required this.maxFrets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure values are within bounds
    final safeStart = visibleFretStart.clamp(0, maxFrets - 1);
    final safeEnd = visibleFretEnd.clamp(safeStart + 1, maxFrets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Visible Fret Range',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$safeStart - $safeEnd',
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Dual-handle range slider
        RangeSlider(
          values: RangeValues(safeStart.toDouble(), safeEnd.toDouble()),
          min: 0,
          max: maxFrets.toDouble(),
          divisions: maxFrets,
          labels: RangeLabels(
            safeStart.toString(),
            safeEnd.toString(),
          ),
          onChanged: (RangeValues values) {
            final newStart = values.start.round();
            final newEnd = values.end.round();
            
            // Ensure minimum range of 1 fret
            if (newEnd > newStart) {
              onChanged(newStart, newEnd);
            }
          },
        ),
        
        // Helper text showing fret range info
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range: ${safeEnd - safeStart} frets',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Max: $maxFrets frets',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}