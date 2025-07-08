// lib/views/widgets/common/app_bar.dart
import 'package:flutter/material.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../dialogs/settings_dialog.dart';

/// Common app bar for the application
class TheorieAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSettings;

  const TheorieAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSettings = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (actions != null) ...actions!,
        if (showSettings)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => showSettingsDialog(context),
          ),
      ],
    );
  }
}

/// Quick view mode selector for app bar
class ViewModeToggle extends StatelessWidget {
  final ViewMode currentMode;
  final Function(ViewMode) onChanged;

  const ViewModeToggle({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ViewMode>(
      segments: ViewMode.values
          .map((mode) => ButtonSegment(
                value: mode,
                label: Text(mode.displayName),
                icon: Icon(_getIconForMode(mode)),
              ))
          .toList(),
      selected: {currentMode},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
    );
  }

  IconData _getIconForMode(ViewMode mode) {
    switch (mode) {
      case ViewMode.intervals:
        return Icons.numbers;
      case ViewMode.scales:
        return Icons.music_note;
      case ViewMode.chords:
        return Icons.piano;
    }
  }
}
