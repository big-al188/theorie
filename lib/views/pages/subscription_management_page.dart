// lib/views/pages/subscription_management_page.dart - Fixed imports and responsive design
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription/subscription_models.dart';
import '../../constants/ui_constants.dart'; // Use existing ResponsiveConstants
import '../widgets/subscription_star_widget.dart';
import '../widgets/common/app_bar.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends State<SubscriptionManagementPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth); // FIXED: Use ResponsiveConstants
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: TheorieAppBar(
        title: 'Subscription',
        showSettings: true,
        showLogout: true,
        actions: [
          SubscriptionStarWidget(size: 24),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_getPadding(deviceType, isLandscape)),
          child: Consumer<SubscriptionService>(
            builder: (context, service, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(context, service, deviceType),
                  const SizedBox(height: 24),
                  if (!service.hasActiveSubscription) ...[
                    _buildPricingTiers(context, service, deviceType),
                    const SizedBox(height: 24),
                  ],
                  if (service.hasActiveSubscription) ...[
                    _buildSubscriptionActions(context, service, deviceType),
                    const SizedBox(height: 24),
                  ],
                  _buildPremiumFeatures(context, service, deviceType),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0;
    }
    return deviceType == DeviceType.mobile ? 20.0 : 32.0;
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionService service, DeviceType deviceType) {
    final subscription = service.currentSubscription;
    
    return Material( // FIXED: Use Material instead of Card to avoid import conflict
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: subscription.hasAccess ? Colors.green.shade50 : Colors.blue.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  subscription.hasAccess ? Icons.star : Icons.star_border,
                  color: subscription.hasAccess ? Colors.amber : Colors.blue,
                  size: deviceType == DeviceType.mobile ? 28 : 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.hasAccess ? 'Premium Active' : 'Free Account',
                        style: TextStyle(
                          fontSize: deviceType == DeviceType.mobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: subscription.hasAccess ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        subscription.tier.displayName,
                        style: TextStyle(
                          fontSize: deviceType == DeviceType.mobile ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subscription.hasAccess)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: deviceType == DeviceType.mobile ? 24 : 28,
                  ),
              ],
            ),
            if (subscription.currentPeriodEnd != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subscription.hasAccess 
                      ? 'Renews ${subscription.formattedPeriodEnd}'
                      : subscription.statusDescription,
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 12 : 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
            if (subscription.needsPaymentUpdate) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment method needs updating',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionActions(BuildContext context, SubscriptionService service, DeviceType deviceType) {
    final subscription = service.currentSubscription;
    
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Subscription',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (subscription.status == SubscriptionStatus.active) ...[
              _buildActionButton(
                context,
                'Pause Subscription',
                Icons.pause,
                () => _handlePauseSubscription(context, service),
                Colors.orange,
                deviceType,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                'Cancel Subscription',
                Icons.cancel,
                () => _handleCancelSubscription(context, service),
                Colors.red,
                deviceType,
              ),
            ],
            if (subscription.status == SubscriptionStatus.paused) ...[
              _buildActionButton(
                context,
                'Resume Subscription',
                Icons.play_arrow,
                () => _handleResumeSubscription(context, service),
                Colors.green,
                deviceType,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTiers(BuildContext context, SubscriptionService service, DeviceType deviceType) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPricingTier(
              context,
              service,
              SubscriptionTier.premium,
              deviceType,
              isPopular: true,
            ),
            const SizedBox(height: 12),
            _buildPricingTier(
              context,
              service,
              SubscriptionTier.premiumAnnual,
              deviceType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTier(
    BuildContext context,
    SubscriptionService service,
    SubscriptionTier tier,
    DeviceType deviceType, {
    bool isPopular = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? Colors.blue : Colors.grey.shade300,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: isPopular ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: service.isLoading ? null : () => _handleSubscribe(context, service, tier),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.displayName,
                            style: TextStyle(
                              fontSize: deviceType == DeviceType.mobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Popular',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: deviceType == DeviceType.mobile ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${tier.price}/${tier == SubscriptionTier.premiumAnnual ? 'year' : 'month'}',
                        style: TextStyle(
                          fontSize: deviceType == DeviceType.mobile ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: deviceType == DeviceType.mobile ? 80 : 100,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: service.isLoading ? null : () => _handleSubscribe(context, service, tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.blue : Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: service.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Subscribe',
                            style: TextStyle(
                              fontSize: deviceType == DeviceType.mobile ? 12 : 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context, SubscriptionService service, DeviceType deviceType) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Features',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              'Advanced Analytics',
              'Detailed progress tracking and insights',
              Icons.analytics,
              service.hasActiveSubscription,
              deviceType,
            ),
            _buildFeatureItem(
              'Cloud Sync',
              'Sync your progress across all devices',
              Icons.cloud_sync,
              service.hasActiveSubscription,
              deviceType,
            ),
            _buildFeatureItem(
              'Premium Themes',
              'Access to exclusive app themes',
              Icons.palette,
              service.hasActiveSubscription,
              deviceType,
            ),
            _buildFeatureItem(
              'Priority Support',
              'Get help faster with premium support',
              Icons.support_agent,
              service.hasActiveSubscription,
              deviceType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    String title,
    String description,
    IconData icon,
    bool hasAccess,
    DeviceType deviceType,
  ) {
    return Padding(
      padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 14 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasAccess ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasAccess ? Icons.check : icon,
              color: hasAccess ? Colors.green : Colors.grey,
              size: deviceType == DeviceType.mobile ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: hasAccess ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
    Color color,
    DeviceType deviceType,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: deviceType == DeviceType.mobile ? 18 : 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: deviceType == DeviceType.mobile ? 14 : 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Action handlers
  Future<void> _handleSubscribe(BuildContext context, SubscriptionService service, SubscriptionTier tier) async {
    try {
      final result = await service.startSubscription(tier: tier);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription started for ${tier.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePauseSubscription(BuildContext context, SubscriptionService service) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Pause Subscription',
      'Are you sure you want to pause your subscription? You can resume it anytime.',
    );

    if (confirmed && context.mounted) {
      try {
        await service.pauseSubscription();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription paused successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResumeSubscription(BuildContext context, SubscriptionService service) async {
    try {
      await service.resumeSubscription();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription resumed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelSubscription(BuildContext context, SubscriptionService service) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Cancel Subscription',
      'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.',
    );

    if (confirmed && context.mounted) {
      try {
        await service.cancelSubscription();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription canceled successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }
}