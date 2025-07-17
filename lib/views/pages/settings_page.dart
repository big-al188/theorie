// lib/views/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../widgets/common/app_bar.dart';
import '../dialogs/settings_sections.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TheorieAppBar(
        title: 'Settings',
        showSettings: false,
        actions: [
          Consumer<AppState>(
            builder: (context, state, child) => IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Reset to Defaults',
              onPressed: () => _showResetDialog(context, state),
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            FretboardConfigSection(),
            SizedBox(height: 24),
            TuningSection(),
            SizedBox(height: 24),
            LayoutSection(),
            SizedBox(height: 24),
            OctaveSection(),
            SizedBox(height: 24),
            PresetSection(),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: state,
        child: AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'This will reset all settings to their default values. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                state.resetToDefaults();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                  ),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
