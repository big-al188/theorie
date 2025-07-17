// lib/views/dialogs/settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/fretboard/fretboard_config.dart';
import '../../constants/ui_constants.dart';
import 'settings_sections.dart';

void showSettingsDialog(BuildContext context) {
  // CRITICAL FIX: Get the AppState instance from the parent context
  // before showing the dialog to ensure it's available in the dialog tree
  final appState = context.read<AppState>();

  showDialog(
    context: context,
    builder: (context) => ChangeNotifierProvider.value(
      value: appState,
      child: Dialog(
        child: Container(
          width: UIConstants.settingsDialogWidth,
          height: UIConstants.settingsDialogHeight,
          padding: const EdgeInsets.all(UIConstants.dialogPadding),
          child: const SettingsContent(),
        ),
      ),
    ),
  );
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Settings', style: UIConstants.headingStyle),
              Row(
                children: [
                  // Quick theme toggle
                  IconButton(
                    icon: Icon(
                      state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    ),
                    tooltip: state.isDarkMode
                        ? 'Switch to Light Theme'
                        : 'Switch to Dark Theme',
                    onPressed: () => state.toggleTheme(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),

          // Settings content
          Expanded(
            child: ListView(
              children: const [
                // Main settings groups
                FretboardDefaultsSection(),
                SizedBox(height: 16),
                AppPreferencesSection(),
                SizedBox(height: 24),

                // Quick actions section
                _QuickActionsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: UIConstants.labelStyle,
              ),
              const SizedBox(height: 12),

              // Action buttons row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickActionButton(
                    icon: Icons.refresh,
                    label: 'Reset Current',
                    tooltip: 'Reset current session to defaults',
                    onPressed: () {
                      state.resetToDefaults();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Current session reset to defaults'),
                        ),
                      );
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.restore,
                    label: 'Reset Defaults',
                    tooltip: 'Reset all default settings',
                    onPressed: () => _showResetDefaultsDialog(context, state),
                    isDestructive: true,
                  ),
                  _QuickActionButton(
                    icon: Icons.restore_page,
                    label: 'Factory Reset',
                    tooltip: 'Reset everything to factory settings',
                    onPressed: () => _showFactoryResetDialog(context, state),
                    isDestructive: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDefaultsDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: state,
        child: AlertDialog(
          title: const Text('Reset Defaults'),
          content: const Text(
            'Reset all default settings (tuning, frets, etc.) to their original values? This will not affect your current session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                state.resetDefaultsToFactorySettings();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Default settings reset'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reset Defaults'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFactoryResetDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: state,
        child: AlertDialog(
          title: const Text('Factory Reset'),
          content: const Text(
            'This will reset ALL settings to factory defaults, including theme, preferences, and current session. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                state.resetAllToFactorySettings();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All settings reset to factory defaults'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reset Everything'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: isDestructive ? Colors.red.shade100 : null,
          foregroundColor: isDestructive ? Colors.red.shade700 : null,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
