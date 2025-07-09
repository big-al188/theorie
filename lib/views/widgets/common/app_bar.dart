// lib/views/widgets/common/app_bar.dart
import 'package:flutter/material.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../constants/ui_constants.dart';
import '../../dialogs/settings_dialog.dart';

/// Common app bar for the application with responsive design
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
  Size get preferredSize {
    // Default to mobile height as the most conservative fallback
    return const Size.fromHeight(UIConstants.mobileAppBarHeight);
  }

  /// Get responsive app bar height based on screen width
  static double getAppBarHeight(double screenWidth) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return UIConstants.mobileAppBarHeight;
      case DeviceType.tablet:
        return UIConstants.tabletAppBarHeight;
      case DeviceType.desktop:
        return UIConstants.desktopAppBarHeight;
    }
  }

  /// Get responsive icon size based on screen width
  static double getIconSize(double screenWidth) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return 20.0; // Smaller icons for mobile
      case DeviceType.tablet:
        return 22.0; // Medium icons for tablet
      case DeviceType.desktop:
        return 24.0; // Standard icons for desktop
    }
  }

  /// Get responsive title font size based on screen width
  static double getTitleFontSize(double screenWidth) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return 18.0; // Smaller title for mobile
      case DeviceType.tablet:
        return 19.0; // Medium title for tablet
      case DeviceType.desktop:
        return 20.0; // Standard title for desktop
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = getAppBarHeight(screenWidth);
    final iconSize = getIconSize(screenWidth);
    final titleFontSize = getTitleFontSize(screenWidth);

    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeight),
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(fontSize: titleFontSize),
        ),
        toolbarHeight: appBarHeight,
        actions: [
          if (actions != null)
            ...actions!.map(
                (action) => _wrapActionWithResponsiveSize(action, iconSize)),
          if (showSettings)
            IconButton(
              icon: const Icon(Icons.settings),
              iconSize: iconSize,
              tooltip: 'Settings',
              onPressed: () => showSettingsDialog(context),
            ),
        ],
      ),
    );
  }

  /// Wrap action widgets with responsive icon sizes if they are IconButtons
  Widget _wrapActionWithResponsiveSize(Widget action, double iconSize) {
    if (action is IconButton) {
      return IconButton(
        icon: action.icon,
        iconSize: iconSize,
        onPressed: action.onPressed,
        tooltip: action.tooltip,
        color: action.color,
        padding: action.padding,
        constraints: action.constraints,
      );
    }
    return action;
  }
}

/// Quick view mode selector for app bar with responsive design
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
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final iconSize = TheorieAppBar.getIconSize(screenWidth);

    // For mobile, use more compact segments
    final isCompact = deviceType == DeviceType.mobile;

    return SegmentedButton<ViewMode>(
      segments: ViewMode.values
          .map((mode) => ButtonSegment(
                value: mode,
                label: isCompact
                    ? null // No label text on mobile to save space
                    : Text(
                        mode.displayName,
                        style: TextStyle(
                          fontSize:
                              deviceType == DeviceType.mobile ? 12.0 : 14.0,
                        ),
                      ),
                icon: Icon(
                  _getIconForMode(mode),
                  size: iconSize,
                ),
                tooltip: isCompact
                    ? mode.displayName
                    : null, // Add tooltip for mobile
              ))
          .toList(),
      selected: {currentMode},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
      style: SegmentedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: deviceType == DeviceType.mobile ? 8.0 : 12.0,
          vertical: deviceType == DeviceType.mobile ? 4.0 : 8.0,
        ),
        minimumSize: Size(
          deviceType == DeviceType.mobile ? 32.0 : 40.0,
          deviceType == DeviceType.mobile ? 32.0 : 40.0,
        ),
      ),
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
