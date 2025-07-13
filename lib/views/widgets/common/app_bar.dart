// lib/views/widgets/common/app_bar.dart
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
  final bool showLogout; // Keep original name for compatibility
  final bool showThemeToggle;
  final bool centerTitle;

  const TheorieAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSettings = true,
    this.showLogout = true, // Keep original name
    this.showThemeToggle = false,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Get responsive icon size based on screen width
  static double getIconSize(double screenWidth) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    return deviceType == DeviceType.mobile ? 20.0 : 24.0;
  }

  /// Get responsive title font size
  static double getTitleFontSize(double screenWidth) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    return deviceType == DeviceType.mobile ? 18.0 : 22.0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
        final iconSize = getIconSize(screenWidth);
        final titleFontSize = getTitleFontSize(screenWidth);

        return AppBar(
          title: Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: centerTitle,
          elevation: 2,
          actions: _buildActions(context, appState, deviceType, iconSize, titleFontSize),
        );
      },
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    AppState appState,
    DeviceType deviceType,
    double iconSize,
    double titleFontSize,
  ) {
    List<Widget> actionsList = [];

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
    
    // 3. Add auth button (logout for regular users, sign in for guests)
    if (showLogout && appState.currentUser != null) {
      if (appState.currentUser!.isDefaultUser) {
        // Guest user - show sign in button
        actionsList.add(
          IconButton(
            icon: const Icon(Icons.login),
            iconSize: iconSize,
            tooltip: 'Sign In',
            onPressed: () => _handleSignIn(context, appState, deviceType),
          ),
        );
      } else {
        // Regular user - show logout button
        actionsList.add(
          IconButton(
            icon: const Icon(Icons.logout),
            iconSize: iconSize,
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context, appState, deviceType),
          ),
        );
      }
    }
    
    // 4. Add user indicator for mobile (rightmost position)
    if (deviceType == DeviceType.mobile && appState.currentUser != null) {
      final displayName = appState.currentUser!.isDefaultUser 
          ? 'Guest'
          : (appState.currentUser!.username.length > 8 
              ? '${appState.currentUser!.username.substring(0, 8)}...'
              : appState.currentUser!.username);
              
      actionsList.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: titleFontSize - 4,
                fontWeight: FontWeight.w500,
                color: appState.currentUser!.isDefaultUser 
                    ? Colors.grey.shade600 
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return actionsList;
  }

  Future<void> _handleSignIn(BuildContext context, AppState appState, DeviceType deviceType) async {
    // Navigate to login page, allowing user to sign in or create account
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
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
      // Logout completely and go back to login page
      await appState.logout(switchToGuest: false);
      
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
                          fontSize: deviceType == DeviceType.mobile ? 12.0 : 14.0,
                        ),
                      ),
                icon: Icon(
                  _getIconForViewMode(mode),
                  size: iconSize,
                ),
              ))
          .toList(),
      selected: {currentMode},
      onSelectionChanged: (Set<ViewMode> selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
      style: SegmentedButton.styleFrom(
        visualDensity: isCompact ? VisualDensity.compact : null,
        padding: isCompact 
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : null,
      ),
    );
  }

  /// Get appropriate icon for each view mode
  IconData _getIconForViewMode(ViewMode mode) {
    switch (mode) {
      case ViewMode.intervals:
        return Icons.analytics;
      case ViewMode.scales:
        return Icons.music_note;
      case ViewMode.chords:
        return Icons.piano;
    }
  }
}