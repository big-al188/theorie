// lib/views/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';
import '../widgets/controls/root_selector.dart';
import '../widgets/controls/view_mode_selector.dart';
import '../widgets/controls/scale_selector.dart';
import '../dialogs/settings_dialog.dart';
import 'fretboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guitar Theory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showSettingsDialog(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: AppConstants.defaultPadding * 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Theorie',
                style: UIConstants.headingStyle.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Interactive Guitar Fretboard Theory',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),

              // Root selector
              const _SettingRow(
                label: 'Root:',
                child: SizedBox(
                  width: 120,
                  child: RootSelector(),
                ),
              ),
              const SizedBox(height: 24),

              // View mode selector
              const _SettingRow(
                label: 'View Mode:',
                child: SizedBox(
                  width: 200,
                  child: ViewModeSelector(),
                ),
              ),
              const SizedBox(height: 16),

              // Scale selector (conditional)
              Consumer<AppState>(
                builder: (context, state, child) {
                  if (state.isScaleMode) {
                    return const Column(
                      children: [
                        _SettingRow(
                          label: 'Scale:',
                          child: SizedBox(
                            width: 200,
                            child: ScaleSelector(),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    );
                  } else if (state.isChordMode) {
                    return Column(
                      children: [
                        Text(
                          'Chord settings are configured per fretboard',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click "Open Fretboard" to select chord types and inversions',
                          style: UIConstants.smallLabelStyle,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 32),

              // Open fretboard button
              ElevatedButton.icon(
                icon: const Icon(Icons.music_note),
                label: const Text('Open Fretboard'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FretboardPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 16),
        child,
      ],
    );
  }
}
