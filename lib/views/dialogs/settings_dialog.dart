// lib/views/dialogs/settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/fretboard/fretboard_config.dart';
import '../../constants/ui_constants.dart';
import 'settings_sections.dart';

void showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        width: UIConstants.settingsDialogWidth,
        height: UIConstants.settingsDialogHeight,
        padding: const EdgeInsets.all(UIConstants.dialogPadding),
        child: const SettingsContent(),
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
    final state = context.watch<AppState>();

    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: UIConstants.labelStyle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _QuickActionButton(
                  icon: Icons.refresh,
                  label: 'Reset Current Session',
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
                  tooltip: 'Reset fretboard defaults to factory settings',
                  onPressed: () {
                    state.resetDefaultsToFactorySettings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Fretboard defaults reset to factory settings'),
                      ),
                    );
                  },
                ),
                _QuickActionButton(
                  icon: Icons.delete_forever,
                  label: 'Factory Reset',
                  tooltip: 'Reset everything to factory defaults',
                  isDestructive: true,
                  onPressed: () => _showFactoryResetDialog(context, state),
                ),
                _QuickActionButton(
                  icon: state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  label: state.isDarkMode ? 'Light Theme' : 'Dark Theme',
                  tooltip: 'Toggle theme',
                  onPressed: () => state.toggleTheme(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFactoryResetDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset'),
        content: const Text(
          'This will reset ALL settings to factory defaults, including:\n\n'
          '• All fretboard defaults\n'
          '• Theme preferences\n'
          '• Current session state\n\n'
          'This action cannot be undone. Continue?',
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

// Settings preview widget for showing current state
class SettingsPreview extends StatelessWidget {
  const SettingsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) => Card(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Defaults Preview',
                style: UIConstants.labelStyle,
              ),
              const SizedBox(height: 8),
              _PreviewItem('Strings', '${state.defaultStringCount}'),
              _PreviewItem('Frets', '${state.defaultFretCount}'),
              _PreviewItem('Layout', state.defaultLayout.displayName),
              _PreviewItem('Root', state.defaultRoot),
              _PreviewItem('View Mode', state.defaultViewMode.displayName),
              if (state.defaultViewMode == ViewMode.scales)
                _PreviewItem('Scale', state.defaultScale),
              _PreviewItem(
                  'Octaves', '${state.defaultSelectedOctaves.length} selected'),
              _PreviewItem('Theme', _getThemeName(state.themeMode)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _PreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
