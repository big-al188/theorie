// lib/views/dialogs/settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Settings', style: UIConstants.headingStyle),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
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
        ],
      ),
    );
  }
}
