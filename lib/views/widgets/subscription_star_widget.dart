// lib/views/widgets/subscription_star_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription/subscription_models.dart';
import '../pages/subscription_management_page.dart';

/// Subscription status star widget for app bar
/// Shows grey star for free users, gold star for premium subscribers
/// Follows the existing widget pattern from the app
class SubscriptionStarWidget extends StatelessWidget {
  final double? size;
  final EdgeInsets? padding;

  const SubscriptionStarWidget({
    super.key,
    this.size,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, child) {
        final subscription = subscriptionService.currentSubscription;
        final hasActiveSubscription = subscription.hasAccess;
        final isLoading = subscriptionService.isLoading;

        return Padding(
          padding: padding ?? const EdgeInsets.only(right: 8.0),
          child: Stack(
            children: [
              IconButton(
                onPressed: isLoading ? null : () => _navigateToSubscriptionManagement(context),
                icon: Icon(
                  Icons.star,
                  color: hasActiveSubscription 
                      ? Colors.amber // Gold for premium subscribers
                      : Colors.grey.shade600, // Grey for free users
                  size: size ?? 28,
                ),
                tooltip: _getTooltipText(subscription),
                splashRadius: 24,
              ),
              // Loading indicator overlay
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasActiveSubscription ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ),
                ),
              // Premium badge for active subscribers
              if (hasActiveSubscription && !isLoading)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              // Warning badge for issues
              if (subscription.needsPaymentUpdate && !isLoading)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Get appropriate tooltip text based on subscription status
  String _getTooltipText(SubscriptionData subscription) {
    if (subscription.hasAccess) {
      if (subscription.needsPaymentUpdate) {
        return 'Premium - Payment Issue';
      }
      return 'Premium Active - Manage Subscription';
    }
    return 'Upgrade to Premium';
  }

  /// Navigate to subscription management page
  /// Prevents opening multiple instances by checking current route
  void _navigateToSubscriptionManagement(BuildContext context) {
    // Check if we're already on the subscription management page
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    if (currentRoute == '/subscription_management') {
      // Already on the subscription page, do nothing
      return;
    }
    
    // Navigate to subscription management page
    // Use pushReplacement to prevent stacking if coming from certain pages,
    // or regular push for normal navigation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionManagementPage(),
        settings: const RouteSettings(name: '/subscription_management'),
      ),
    );
  }
}

/// Subscription status indicator for other UI elements
class SubscriptionStatusIndicator extends StatelessWidget {
  final bool showText;
  final double iconSize;
  final TextStyle? textStyle;

  const SubscriptionStatusIndicator({
    super.key,
    this.showText = true,
    this.iconSize = 20,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, child) {
        final subscription = subscriptionService.currentSubscription;
        final hasActiveSubscription = subscription.hasAccess;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: hasActiveSubscription ? Colors.amber : Colors.grey,
              size: iconSize,
            ),
            if (showText) ...[
              const SizedBox(width: 4),
              Text(
                hasActiveSubscription ? 'Premium' : 'Free',
                style: textStyle ?? TextStyle(
                  color: hasActiveSubscription ? Colors.amber.shade700 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Subscription benefits badge for UI elements
class SubscriptionBenefitsBadge extends StatelessWidget {
  final Widget child;
  final bool requiresPremium;
  final VoidCallback? onTap;

  const SubscriptionBenefitsBadge({
    super.key,
    required this.child,
    this.requiresPremium = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!requiresPremium) return child;

    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, child) {
        final hasAccess = subscriptionService.hasActiveSubscription;

        return Stack(
          children: [
            // Dimmed content for non-premium users
            Opacity(
              opacity: hasAccess ? 1.0 : 0.5,
              child: this.child,
            ),
            // Premium overlay for locked content
            if (!hasAccess)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap ?? () => _showPremiumDialog(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 32,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Show premium upgrade dialog
  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: const Text(
          'This feature requires a Premium subscription. Upgrade now to unlock all advanced features!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              
              // Check if we're already on the subscription management page
              final currentRoute = ModalRoute.of(context)?.settings.name;
              if (currentRoute != '/subscription_management') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionManagementPage(),
                    settings: const RouteSettings(name: '/subscription_management'),
                  ),
                );
              }
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}