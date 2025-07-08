// lib/views/widgets/fretboard/fretboard_container.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../models/fretboard/fretboard_instance.dart';
import '../../../controllers/fretboard_controller.dart';
import 'fretboard_widget.dart';

/// Stateful container that manages fretboard instance state
class FretboardContainer extends StatefulWidget {
  final FretboardInstance instance;
  final Function(FretboardInstance) onUpdate;
  final bool showControls;

  const FretboardContainer({
    super.key,
    required this.instance,
    required this.onUpdate,
    this.showControls = true,
  });

  @override
  State<FretboardContainer> createState() => _FretboardContainerState();
}

class _FretboardContainerState extends State<FretboardContainer> {
  void _handleFretTap(int stringIndex, int fretIndex) {
    if (widget.instance.viewMode == ViewMode.intervals) {
      final appState = context.read<AppState>();
      final config = widget.instance.toConfig(
        layout: appState.layout,
        globalFretCount: appState.fretCount,
      );

      FretboardController.handleIntervalModeTap(
        config,
        stringIndex,
        fretIndex,
        (newIntervals) {
          widget.onUpdate(
            widget.instance.copyWith(selectedIntervals: newIntervals),
          );
        },
      );
    }
  }

  void _handleScaleNoteTap(int midiNote) {
    debugPrint('Scale note tapped: MIDI $midiNote');
    // Handle scale strip taps if needed
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final config = widget.instance.toConfig(
          layout: appState.layout,
          globalFretCount: appState.fretCount,
        );

        return FretboardWidget(
          config: config,
          onFretTap: _handleFretTap,
          onScaleNoteTap: _handleScaleNoteTap,
          onRangeChanged: widget.showControls
              ? (start, end) {
                  widget.onUpdate(widget.instance.copyWith(
                    visibleFretStart: start,
                    visibleFretEnd: end,
                  ));
                }
              : null,
        );
      },
    );
  }
}
