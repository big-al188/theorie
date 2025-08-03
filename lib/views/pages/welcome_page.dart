// lib/views/pages/welcome_page.dart - Updated with subscription integration
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/user_service.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
import '../widgets/subscription/subscription_star_widget.dart'; // NEW: Subscription star widget
import '../dialogs/settings_dialog.dart';
import 'instrument_selection_page.dart';
import 'learning_sections_page.dart';
import 'subscription_management_page.dart'; // NEW: Subscription management page
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
          // UPDATED: Modified AppBar to include subscription star widget
          appBar: TheorieAppBar(
            title: 'Theorie',
            showThemeToggle: true,
            showSettings: true,
            showLogout: true,
            actions: [
              // NEW: Add subscription star widget
              const SubscriptionStarWidget(),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: _getHorizontalPadding(deviceType, isLandscape),
                vertical: _getVerticalPadding(deviceType, isLandscape),
              ),
              child: _buildContent(context, appState, deviceType, isLandscape, screenWidth, screenHeight),
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

  Widget _buildContent(BuildContext context, AppState appState, DeviceType deviceType, bool isLandscape, double screenWidth, double screenHeight) {
    // In landscape mode on mobile, use a more compact layout
    if (isLandscape && deviceType == DeviceType.mobile) {
      return _buildLandscapeLayout(context, appState, deviceType, screenWidth);
    }
    
    // For portrait or larger screens, use the centered layout
    return _buildPortraitLayout(context, appState, deviceType, screenWidth, screenHeight);
  }

  Widget _buildLandscapeLayout(BuildContext context, AppState appState, DeviceType deviceType, double screenWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactHeader(context, appState, deviceType),
        const SizedBox(height: 24.0),
        // NEW: Add premium status card if user has premium
        if (appState.hasActiveSubscription) ...[
          _buildPremiumStatusCard(context, appState, deviceType, isCompact: true),
          const SizedBox(height: 16.0),
        ],
        _buildDescription(context, deviceType, isCompact: true),
        const SizedBox(height: 24.0),
        _buildActionButtons(context, deviceType, isLandscape: true),
        const SizedBox(height: 16.0), // Bottom padding for scroll
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, AppState appState, DeviceType deviceType, double screenWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, appState, deviceType),
        SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
        // NEW: Add premium status card if user has premium
        if (appState.hasActiveSubscription) ...[
          _buildPremiumStatusCard(context, appState, deviceType),
          SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
        ],
        _buildDescription(context, deviceType),
        SizedBox(height: deviceType == DeviceType.mobile ? 32.0 : 48.0),
        _buildActionButtons(context, deviceType),
        const SizedBox(height: 32.0), // Bottom padding for scroll
      ],
    );
  }

Widget _buildCompactHeader(BuildContext context, AppState appState, DeviceType deviceType) {
  final user = appState.currentUser;
  return Column(
    children: [
      Text(
        'Welcome back, ${user?.username ?? 'User'}!',
        style: TextStyle(
          fontSize: 24.0, // Smaller in landscape
          fontWeight: FontWeight.bold,
          // FIXED: Use theme-adaptive color that works in both light and dark modes
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      // NEW: Add subscription status indicator
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: appState.hasActiveSubscription ? Colors.amber : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            appState.hasActiveSubscription ? 'Premium Member' : 'Free Account',
            style: TextStyle(
              fontSize: 14,
              color: appState.hasActiveSubscription 
                  ? Colors.amber.shade700 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildHeader(BuildContext context, AppState appState, DeviceType deviceType) {
  final titleFontSize = deviceType == DeviceType.mobile ? 32.0 : 38.0;
  final user = appState.currentUser;
  
  return Column(
    children: [
      Text(
        'Welcome back, ${user?.username ?? 'User'}!',
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          // FIXED: Use theme-adaptive color that works in both light and dark modes
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      // NEW: Add subscription status indicator
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: appState.hasActiveSubscription ? Colors.amber : Colors.grey,
            size: deviceType == DeviceType.mobile ? 20 : 24,
          ),
          const SizedBox(width: 8),
          Text(
            appState.hasActiveSubscription ? 'Premium Member' : 'Free Account',
            style: TextStyle(
              fontSize: deviceType == DeviceType.mobile ? 16 : 18,
              color: appState.hasActiveSubscription 
                  ? Colors.amber.shade700 
                  // FIXED: Use theme-adaptive color for free account text
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  );
}

  /// NEW: Build premium status card for active subscribers
  Widget _buildPremiumStatusCard(BuildContext context, AppState appState, DeviceType deviceType, {bool isCompact = false}) {
    final subscription = appState.currentSubscription;
    final padding = isCompact ? 12.0 : (deviceType == DeviceType.mobile ? 16.0 : 20.0);
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 500.0,
        ),
        child: Card(
          elevation: 3,
          color: Colors.amber.shade50,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: isCompact ? 28 : (deviceType == DeviceType.mobile ? 32 : 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium Active',
                        style: TextStyle(
                          fontSize: isCompact ? 16 : (deviceType == DeviceType.mobile ? 18 : 20),
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      Text(
                        subscription.tier.displayName,
                        style: TextStyle(
                          fontSize: isCompact ? 12 : (deviceType == DeviceType.mobile ? 14 : 16),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (subscription.currentPeriodEnd != null && !isCompact)
                        Text(
                          'Renews ${subscription.formattedPeriodEnd}',
                          style: TextStyle(
                            fontSize: deviceType == DeviceType.mobile ? 12 : 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: isCompact ? 20 : (deviceType == DeviceType.mobile ? 24 : 28),
                ),
              ],
            ),
          ),
        ),
      ),
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