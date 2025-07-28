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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        mode.displayName,
                        style: TextStyle(
                          color: mode.isImplemented 
                              ? null 
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    if (!mode.isImplemented)
                      Icon(
                        Icons.construction,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (mode) {
        if (mode != null) {
          // Show a dialog for unimplemented modes
          if (!mode.isImplemented) {
            _showUnimplementedDialog(context, mode);
            return;
          }
          
          if (onChanged != null) {
            onChanged!(mode);
          } else {
            state.setViewMode(mode);
          }
        }
      },
    );
  }

  void _showUnimplementedDialog(BuildContext context, ViewMode mode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.construction,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('${mode.displayName} Mode'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This mode is currently under development and will be available in a future update.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Available modes:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...ViewMode.values.where((m) => m.isImplemented).map((m) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(m.displayName),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Switch to Chord Inversions mode as a fallback
                if (onChanged != null) {
                  onChanged!(ViewMode.chordInversions);
                } else {
                  final state = Provider.of<AppState>(context, listen: false);
                  state.setViewMode(ViewMode.chordInversions);
                }
              },
              child: const Text('Try Chord Inversions'),
            ),
          ],
        );
      },
    );
  }
}