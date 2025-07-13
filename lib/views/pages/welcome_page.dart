// lib/views/pages/welcome_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/user_service.dart';
import '../../constants/ui_constants.dart';
import '../dialogs/settings_dialog.dart';
import 'instrument_selection_page.dart';
import 'learning_sections_page.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isLandscape = orientation == Orientation.landscape;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Theorie',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 20.0 : 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              // User info
              if (appState.currentUser != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Text(
                      'Hi, ${appState.currentUser!.username}',
                      style: TextStyle(
                        fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              
              // Settings button
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => showSettingsDialog(context),
                tooltip: 'Settings',
              ),
              
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _handleLogout(context),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: _getHorizontalPadding(deviceType, isLandscape),
                vertical: _getVerticalPadding(deviceType, isLandscape),
              ),
              child: _buildContent(context, deviceType, isLandscape, screenWidth, screenHeight),
            ),
          ),
        );
      },
    );
  }

  double _getHorizontalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 32.0; // More padding in landscape to use the wider space better
    }
    return deviceType == DeviceType.mobile ? 24.0 : 48.0;
  }

  double _getVerticalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0; // Much less vertical padding in landscape
    }
    return deviceType == DeviceType.mobile ? 24.0 : 32.0;
  }

  Widget _buildContent(BuildContext context, DeviceType deviceType, bool isLandscape, double screenWidth, double screenHeight) {
    // In landscape mode on mobile, use a more compact layout
    if (isLandscape && deviceType == DeviceType.mobile) {
      return _buildLandscapeLayout(context, deviceType, screenWidth);
    }
    
    // For portrait or larger screens, use the centered layout
    return _buildPortraitLayout(context, deviceType, screenWidth, screenHeight);
  }

  Widget _buildLandscapeLayout(BuildContext context, DeviceType deviceType, double screenWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactHeader(context, deviceType),
        const SizedBox(height: 24.0),
        _buildDescription(context, deviceType, isCompact: true),
        const SizedBox(height: 24.0),
        _buildActionButtons(context, deviceType, isLandscape: true),
        const SizedBox(height: 16.0), // Bottom padding for scroll
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, DeviceType deviceType, double screenWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, deviceType),
        SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
        _buildDescription(context, deviceType),
        SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
        _buildActionButtons(context, deviceType),
        const SizedBox(height: 32.0), // Bottom padding for scroll
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context, DeviceType deviceType) {
    return Column(
      children: [
        Text(
          'Welcome to Theorie!',
          style: TextStyle(
            fontSize: 28.0, // Smaller in landscape
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 36.0 : 42.0;
    
    return Column(
      children: [
        Text(
          'Welcome to Theorie!',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, DeviceType deviceType, {bool isCompact = false}) {
    final textFontSize = isCompact 
        ? 14.0 
        : (deviceType == DeviceType.mobile ? 16.0 : 18.0);
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 600.0,
        ),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(
              isCompact ? 16.0 : (deviceType == DeviceType.mobile ? 20.0 : 32.0),
            ),
            child: Text(
              'An interactive app for learning music theory across many instruments such as Guitar, Piano and more! '
              'Explore topics on your own, and quiz your knowledge to progress as far as your heart desires. '
              'The goal of Theorie is to be your one stop shop to musical understanding.',
              style: TextStyle(
                fontSize: textFontSize,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DeviceType deviceType, {bool isLandscape = false}) {
    final buttonPadding = deviceType == DeviceType.mobile 
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
        : const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    
    final iconSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;
    final fontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    
    final spacing = isLandscape ? 16.0 : 24.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 500.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Explore my Instrument button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InstrumentSelectionPage()),
                  );
                },
                icon: Icon(Icons.music_note, size: iconSize),
                label: Text(
                  'Explore my Instrument',
                  style: TextStyle(fontSize: fontSize),
                ),
                style: ElevatedButton.styleFrom(
                  padding: buttonPadding,
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
              ),
            ),
            
            SizedBox(height: spacing),
            
            // Begin Learning button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LearningSectionsPage()),
                  );
                },
                icon: Icon(Icons.school, size: iconSize),
                label: Text(
                  'Begin Learning',
                  style: TextStyle(fontSize: fontSize),
                ),
                style: ElevatedButton.styleFrom(
                  padding: buttonPadding,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final appState = context.read<AppState>();
      await appState.logout();
      
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }
}