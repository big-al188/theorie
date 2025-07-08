// lib/views/widgets/controls/view_mode_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../models/fretboard/fretboard_config.dart';

class ViewModeSelector extends StatelessWidget {
  final Function(ViewMode)? onChanged;
  final ViewMode? value;

  const ViewModeSelector({
    super.key,
    this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentValue = value ?? state.viewMode;

    return DropdownButton<ViewMode>(
      value: currentValue,
      isExpanded: true,
      underline: const SizedBox(),
      items: ViewMode.values
          .map((mode) => DropdownMenuItem(
                value: mode,
                child: Text(mode.displayName),
              ))
          .toList(),
      onChanged: (mode) {
        if (mode != null) {
          if (onChanged != null) {
            onChanged!(mode);
          } else {
            state.setViewMode(mode);
          }
        }
      },
    );
  }
}
