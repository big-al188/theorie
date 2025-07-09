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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    
    // Responsive padding
    final horizontalPadding = deviceType == DeviceType.mobile ? 16.0 : 32.0;
    final verticalPadding = deviceType == DeviceType.mobile ? 16.0 : 24.0;
    
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - 
                         kToolbarHeight - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom -
                         (verticalPadding * 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title section
                _buildTitleSection(context, deviceType),
                
                SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),

                // Settings section
                _buildSettingsSection(context, deviceType, screenWidth),
                
                SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),

                // Open fretboard button
                _buildActionButton(context, deviceType),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 28.0 : 32.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    
    return Column(
      children: [
        Text(
          'Theorie',
          style: UIConstants.headingStyle.copyWith(fontSize: titleFontSize),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Interactive Guitar Fretboard Theory',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
                fontSize: subtitleFontSize,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, DeviceType deviceType, double screenWidth) {
    final isCompact = deviceType == DeviceType.mobile || screenWidth < 400;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 500.0,
        ),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 24.0),
            child: isCompact 
                ? _buildCompactSettings(context)
                : _buildExpandedSettings(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSettingItem(
          context,
          'Root:',
          const SizedBox(width: double.infinity, child: RootSelector()),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          context,
          'View Mode:',
          const SizedBox(width: double.infinity, child: ViewModeSelector()),
        ),
        const SizedBox(height: 16),
        Consumer<AppState>(
          builder: (context, state, child) {
            if (state.isScaleMode) {
              return _buildSettingItem(
                context,
                'Scale:',
                const SizedBox(width: double.infinity, child: ScaleSelector()),
              );
            } else if (state.isChordMode) {
              return _buildChordModeInfo(context, compact: true);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildExpandedSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Root selector
        _SettingRow(
          label: 'Root:',
          child: SizedBox(
            width: 120,
            child: RootSelector(),
          ),
        ),
        const SizedBox(height: 24),

        // View mode selector
        _SettingRow(
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
              return Column(
                children: [
                  _SettingRow(
                    label: 'Scale:',
                    child: SizedBox(
                      width: 200,
                      child: ScaleSelector(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            } else if (state.isChordMode) {
              return Column(
                children: [
                  _buildChordModeInfo(context, compact: false),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildChordModeInfo(BuildContext context, {required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, 
                   size: 16, 
                   color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chord Mode Information',
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chord settings are configured per fretboard',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Click "Open Fretboard" to select chord types and inversions',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DeviceType deviceType) {
    final buttonPadding = deviceType == DeviceType.mobile 
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    
    final iconSize = deviceType == DeviceType.mobile ? 20.0 : 24.0;
    final fontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;
    
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.music_note, size: iconSize),
        label: Text(
          'Open Fretboard',
          style: TextStyle(fontSize: fontSize),
        ),
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          elevation: 3,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FretboardPage()),
          );
        },
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
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 16),
        child,
      ],
    );
  }
}