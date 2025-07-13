// Enhanced lib/views/widgets/common/app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../models/fretboard/fretboard_config.dart';
import '../../../constants/ui_constants.dart';
import '../../dialogs/settings_dialog.dart';
import '../../pages/login_page.dart';

/// Common app bar for the application with responsive design and quick actions
class TheorieAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSettings;
  final bool showLogout;
  final bool showThemeToggle;

  const TheorieAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSettings = true,
    this.showLogout = true,
    this.showThemeToggle = true,
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
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return PreferredSize(
          preferredSize: Size.fromHeight(appBarHeight),
          child: AppBar(
            title: Text(
              title,
              style: TextStyle(fontSize: titleFontSize),
            ),
            toolbarHeight: appBarHeight,
            actions: _buildActionsList(context, appState, iconSize, titleFontSize, deviceType),
          ),
        );
      },
    );
  }

  /// Build the complete actions list with proper ordering and responsive sizing
  List<Widget> _buildActionsList(
    BuildContext context, 
    AppState appState, 
    double iconSize, 
    double titleFontSize, 
    DeviceType deviceType
  ) {
    final actionsList = <Widget>[];

    // 1. Add custom page-specific actions first (leftmost position)
    if (actions != null) {
      actionsList.addAll(
        actions!.map((action) => _wrapActionWithResponsiveSize(action, iconSize))
      );
    }

    // 2. Add common quick access actions (middle positions)
    
    // Theme toggle button (quick access)
    if (showThemeToggle) {
      actionsList.add(
        IconButton(
          icon: Icon(
            appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          iconSize: iconSize,
          tooltip: appState.isDarkMode
              ? 'Switch to Light Theme'
              : 'Switch to Dark Theme',
          onPressed: () => appState.toggleTheme(),
        ),
      );
    }
    
    // Settings button
    if (showSettings) {
      actionsList.add(
        IconButton(
          icon: const Icon(Icons.settings),
          iconSize: iconSize,
          tooltip: 'Settings',
          onPressed: () => showSettingsDialog(context),
        ),
      );
    }
    
    // 3. Add logout button (second to last position)
    if (showLogout && appState.currentUser != null && !appState.currentUser!.isDefaultUser) {
      actionsList.add(
        IconButton(
          icon: const Icon(Icons.logout),
          iconSize: iconSize,
          tooltip: 'Logout',
          onPressed: () => _handleLogout(context, appState, deviceType),
        ),
      );
    }
    
    // 4. Add user indicator for mobile (rightmost position)
    if (deviceType == DeviceType.mobile && 
        appState.currentUser != null && 
        !appState.currentUser!.isDefaultUser) {
      actionsList.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: Text(
              appState.currentUser!.username.length > 8 
                  ? '${appState.currentUser!.username.substring(0, 8)}...'
                  : appState.currentUser!.username,
              style: TextStyle(
                fontSize: titleFontSize - 4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return actionsList;
  }
  Future<void> _handleLogout(BuildContext context, AppState appState, DeviceType deviceType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await appState.logout();
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
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
                          fontSize: deviceType == DeviceType.mobile ? 10.0 : 12.0,
                        ),
                      ),
                icon: Icon(
                  _getIconForViewMode(mode),
                  size: iconSize - 4,
                ),
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

  IconData _getIconForViewMode(ViewMode mode) {
    switch (mode) {
      case ViewMode.scales:
        return Icons.music_note;
      case ViewMode.chords:
        return Icons.piano;
      case ViewMode.intervals:
        return Icons.straighten;
    }
  }
}