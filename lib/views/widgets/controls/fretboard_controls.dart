// lib/views/widgets/controls/fretboard_controls.dart
import 'package:flutter/material.dart';
import '../../../models/fretboard/fretboard_instance.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/music/chord.dart';
// import '../../../models/music/tuning.dart';
// import '../../../constants/music_constants.dart';
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

  const FretboardControls({
    super.key,
    required this.instance,
    required this.onUpdate,
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
                        var newOctaves = instance.selectedOctaves;

                        // Ensure single octave for chord mode
                        if (mode == ViewMode.chords && newOctaves.length > 1) {
                          newOctaves = {newOctaves.first};
                        }

                        onUpdate(instance.copyWith(
                          viewMode: mode,
                          selectedIntervals: newIntervals,
                          selectedOctaves: newOctaves,
                          chordInversion: ChordInversion.root,
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Scale/Chord selector based on mode
              if (instance.viewMode == ViewMode.scales)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scale',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      ScaleSelector(
                        value: instance.scale,
                        onChanged: (scale) {
                          onUpdate(
                              instance.copyWith(scale: scale, modeIndex: 0));
                        },
                      ),
                    ],
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

          // Tuning selector
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TuningSelector(
                  tuning: instance.tuning,
                  onChanged: (tuning) {
                    onUpdate(instance.copyWith(
                      tuning: tuning,
                      stringCount: tuning.length,
                    ));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Octave selector
          Row(
            children: [
              Expanded(
                child: OctaveSelector(
                  selectedOctaves: instance.selectedOctaves,
                  isChordMode: instance.viewMode == ViewMode.chords,
                  onChanged: (octaves) {
                    onUpdate(instance.copyWith(selectedOctaves: octaves));
                  },
                ),
              ),
            ],
          ),
          // Interval selector (only for interval mode)
          if (instance.viewMode == ViewMode.intervals) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: IntervalSelector(
                    selectedIntervals: instance.selectedIntervals,
                    selectedOctaves: instance.selectedOctaves,
                    onChanged: (intervals) {
                      onUpdate(instance.copyWith(selectedIntervals: intervals));
                    },
                  ),
                ),
              ],
            ),
          ],

          // Fret range selector
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FretRangeSelector(
                  visibleFretStart: instance.visibleFretStart,
                  visibleFretEnd: instance.visibleFretEnd,
                  maxFrets: 24, // This should come from global state
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visible Fret Range: $visibleFretStart-$visibleFretEnd',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text('Start Fret: $visibleFretStart',
            style: const TextStyle(fontSize: 10)),
        Slider(
          value: visibleFretStart.toDouble(),
          min: 0,
          max: (maxFrets - 1).toDouble(),
          divisions: maxFrets - 1,
          onChanged: (value) {
            final newStart = value.toInt();
            if (newStart < visibleFretEnd) {
              onChanged(newStart, visibleFretEnd);
            }
          },
        ),
        const SizedBox(height: 4),
        Text('End Fret: $visibleFretEnd', style: const TextStyle(fontSize: 10)),
        Slider(
          value: visibleFretEnd
              .toDouble()
              .clamp((visibleFretStart + 1).toDouble(), maxFrets.toDouble()),
          min: (visibleFretStart + 1).toDouble(),
          max: maxFrets.toDouble(),
          divisions: maxFrets - visibleFretStart,
          onChanged: (value) {
            final newEnd = value.toInt();
            if (newEnd > visibleFretStart && newEnd <= maxFrets) {
              onChanged(visibleFretStart, newEnd);
            }
          },
        ),
      ],
    );
  }
}
