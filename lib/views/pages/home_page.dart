// lib/views/pages/home_page.dart - Fixed mobile landscape layout with TheorieAppBar
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';
import '../widgets/controls/root_selector.dart';
import '../widgets/controls/view_mode_selector.dart';
import '../widgets/controls/scale_selector.dart';
import '../widgets/common/app_bar.dart';
import 'fretboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isLandscape = orientation == Orientation.landscape;
    
    // More aggressive responsive padding, especially for landscape
    final horizontalPadding = _getHorizontalPadding(deviceType, isLandscape);
    final verticalPadding = _getVerticalPadding(deviceType, isLandscape);
    
    return Scaffold(
      appBar: const TheorieAppBar(
        title: 'Guitar Theory',
        showSettings: true,
        showThemeToggle: true,
        showLogout: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: _buildContent(context, deviceType, isLandscape, screenWidth, screenHeight),
        ),
      ),
    );
  }

  double _getHorizontalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 24.0; // More padding in landscape to use the wider space better
    }
    return deviceType == DeviceType.mobile ? 16.0 : 32.0;
  }

  double _getVerticalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 8.0; // Much less vertical padding in landscape
    }
    return deviceType == DeviceType.mobile ? 16.0 : 24.0;
  }

  Widget _buildContent(BuildContext context, DeviceType deviceType, bool isLandscape, double screenWidth, double screenHeight) {
    return Column(
      children: [
        // Title section - compact in mobile landscape mode
        if (isLandscape && deviceType == DeviceType.mobile)
          _buildCompactTitleSection(context, deviceType)
        else
          _buildTitleSection(context, deviceType),
        
        SizedBox(height: deviceType == DeviceType.mobile && !isLandscape ? 32.0 : 48.0),

        // Settings section - horizontal layout in landscape mode
        if (isLandscape && deviceType == DeviceType.mobile)
          _buildCompactSettingsSection(context, deviceType, screenWidth)
        else
          _buildSettingsSection(context, deviceType, screenWidth),
        
        SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),

        // Open fretboard button
        _buildActionButton(context, deviceType),
        
        // Add some bottom padding to ensure scrollability
        const SizedBox(height: 32.0),
      ],
    );
  }

  Widget _buildCompactTitleSection(BuildContext context, DeviceType deviceType) {
    return Column(
      children: [
        Text(
          'Theorie',
          style: UIConstants.headingStyle.copyWith(fontSize: 24.0), // Smaller in landscape
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Interactive Guitar Fretboard Theory',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
                fontSize: 14.0, // Smaller subtitle
              ),
          textAlign: TextAlign.center,
        ),
      ],
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

  Widget _buildCompactSettingsSection(BuildContext context, DeviceType deviceType, double screenWidth) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600.0), // Wider for landscape
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Less padding
            child: _buildHorizontalSettings(context), // Horizontal layout
          ),
        ),
      ),
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

  Widget _buildHorizontalSettings(BuildContext context) {
    return Column(
      children: [
        // First row: Root and View Mode
        Row(
          children: [
            Expanded(
              child: _buildSmallSettingItem(context, 'Root:', const RootSelector()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSmallSettingItem(context, 'View Mode:', const ViewModeSelector()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Second row: Scale (if needed) or info
        Consumer<AppState>(
          builder: (context, state, child) {
            if (state.isScaleMode) {
              return _buildSmallSettingItem(context, 'Scale:', const ScaleSelector());
            } else if (state.isChordMode) {
              return _buildChordModeInfo(context, compact: true);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSmallSettingItem(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
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
              return _buildChordModeInfo(context);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildChordModeInfo(BuildContext context, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 8.0 : 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: compact ? 16 : 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Open fretboard for chord selection',
              style: TextStyle(
                fontSize: compact ? 12.0 : 14.0,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, DeviceType deviceType) {
    final buttonHeight = deviceType == DeviceType.mobile ? 48.0 : 56.0;
    final fontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    
    return Center(
      child: SizedBox(
        width: deviceType == DeviceType.mobile ? double.infinity : 300.0,
        height: buttonHeight,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FretboardPage(),
              ),
            );
          },
          icon: const Icon(Icons.music_note),
          label: Text(
            'Open Fretboard',
            style: TextStyle(fontSize: fontSize),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child,
      ],
    );
  }
}