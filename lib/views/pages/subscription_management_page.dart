// lib/views/pages/subscription_management_page.dart - Updated with Payment Form Integration
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:html' as html show window;
import '../../services/subscription_service.dart';
import '../../services/firebase_user_service.dart';
import '../../services/user_service.dart';
import '../../models/subscription/subscription_models.dart';
import '../../models/subscription/payment_models.dart';
import '../../constants/ui_constants.dart';
import '../widgets/subscription/subscription_star_widget.dart';
import '../widgets/subscription/payment_form_widget.dart';
import '../widgets/common/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends State<SubscriptionManagementPage> {
  bool _processingPayment = false;
  bool _showDebugPanel = false;
  String _debugOutput = '';
  bool _runningTest = false;
  int _debugTapCount = 0;


  @override
  void initState() {
    super.initState();
    
    // Handle return from Stripe Checkout (web only)
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uri = Uri.parse(html.window.location.href);
        final sessionId = uri.queryParameters['session_id'];
        
        if (sessionId != null) {
          _handleCheckoutSuccess(sessionId);
        } else if (uri.path.contains('/subscription/cancel')) {
          _handleCheckoutCancel();
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: TheorieAppBar(
        title: 'Subscription',
        showSettings: true,
        showLogout: true,
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
                  
                  // Show login prompt if not authenticated
                  if (!FirebaseUserService.instance.isLoggedIn) ...[
                    _buildLoginPrompt(context, deviceType),
                    const SizedBox(height: 24),
                  ],
                  
                  if (!service.hasActiveSubscription && FirebaseUserService.instance.isLoggedIn) ...[
                    _buildPricingTiers(context, service, deviceType),
                    const SizedBox(height: 24),
                  ],
                  
                  if (service.hasActiveSubscription) ...[
                    _buildSubscriptionActions(context, service, deviceType),
                    const SizedBox(height: 24),
                  ],
                  
                  _buildPremiumFeatures(context, service, deviceType),
                  
                  // Debug panel (shown in debug mode or when manually enabled)
                  if (kDebugMode || _showDebugPanel) ...[
                    const SizedBox(height: 32),
                    _buildDebugPanel(context, service, deviceType),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleDebugTap() {
    setState(() {
      _debugTapCount++;
      if (_debugTapCount >= 5) {
        _showDebugPanel = !_showDebugPanel;
        _debugTapCount = 0;
        if (_showDebugPanel) {
          _addDebugOutput('🔧 Debug panel enabled');
        }
      }
    });
    
    // Reset tap count after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _debugTapCount = 0;
        });
      }
    });
  }

  Widget _buildDebugPanel(BuildContext context, SubscriptionService service, DeviceType deviceType) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.orange.shade700,
                  size: deviceType == DeviceType.mobile ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Debug & Testing Panel',
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showDebugPanel = false),
                  icon: Icon(Icons.close, color: Colors.orange.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Test buttons grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  'Basic Connectivity',
                  Icons.wifi,
                  () => _testBasicConnectivity(service),
                  Colors.blue,
                ),
                _buildTestButton(
                  'Authentication',
                  Icons.lock,
                  () => _testAuthentication(service),
                  Colors.green,
                ),
                _buildTestButton(
                  'Get Subscription',
                  Icons.receipt,
                  () => _testGetSubscription(service),
                  Colors.purple,
                ),
                _buildTestButton(
                  'Refresh Status',
                  Icons.refresh,
                  () => _testRefreshStatus(service),
                  Colors.cyan,
                ),
                _buildTestButton(
                  'Clear Local Data',
                  Icons.delete,
                  () => _testClearLocalData(service),
                  Colors.red,
                ),
                _buildTestButton(
                  'Test Functions',
                  Icons.functions,
                  () => _testFirebaseFunctions(service),
                  Colors.indigo,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Debug output area
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Debug Output',
                        style: TextStyle(
                          color: Colors.green.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _debugOutput = ''),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.orange.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _debugOutput.isEmpty ? 'No debug output yet. Run a test to see results.' : _debugOutput,
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_runningTest) ...[
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Running test...',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
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

  Widget _buildTestButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: _runningTest ? null : onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(120, 36),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
      ),
    );
  }

  void _addDebugOutput(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _debugOutput += '[$timestamp] $message\n';
    });
  }

  Future<void> _testBasicConnectivity(SubscriptionService service) async {
    setState(() => _runningTest = true);
    _addDebugOutput('🔄 Testing basic connectivity...');
    
    try {
      final result = await service.testBasicConnectivity();
      _addDebugOutput('✅ Basic connectivity test passed');
      _addDebugOutput('📋 Result: ${result.toString()}');
    } catch (e) {
      _addDebugOutput('❌ Basic connectivity test failed');
      _addDebugOutput('📋 Error: ${e.toString()}');
    } finally {
      setState(() => _runningTest = false);
    }
  }

  Future<void> _testAuthentication(SubscriptionService service) async {
    setState(() => _runningTest = true);
    _addDebugOutput('🔄 Testing authentication...');
    
    try {
      final result = await service.testAuthentication();
      _addDebugOutput('✅ Authentication test passed');
      _addDebugOutput('📋 Authenticated: ${result['authenticated']}');
      _addDebugOutput('📋 User ID: ${result['userId'] ?? 'N/A'}');
      _addDebugOutput('📋 Email: ${result['email'] ?? 'N/A'}');
    } catch (e) {
      _addDebugOutput('❌ Authentication test failed');
      _addDebugOutput('📋 Error: ${e.toString()}');
    } finally {
      setState(() => _runningTest = false);
    }
  }

  Future<void> _testGetSubscription(SubscriptionService service) async {
    setState(() => _runningTest = true);
    _addDebugOutput('🔄 Testing get subscription status...');
    
    try {
      await service.refreshSubscriptionStatus();
      final subscription = service.currentSubscription;
      _addDebugOutput('✅ Get subscription test completed');
      _addDebugOutput('📋 Has subscription: ${service.hasActiveSubscription}');
      _addDebugOutput('📋 Status: ${subscription.status.displayName}');
      _addDebugOutput('📋 Tier: ${subscription.tier.displayName}');
      if (subscription.subscriptionId != null) {
        _addDebugOutput('📋 Subscription ID: ${subscription.subscriptionId}');
      }
    } catch (e) {
      _addDebugOutput('❌ Get subscription test failed');
      _addDebugOutput('📋 Error: ${e.toString()}');
    } finally {
      setState(() => _runningTest = false);
    }
  }

  Future<void> _testRefreshStatus(SubscriptionService service) async {
    setState(() => _runningTest = true);
    _addDebugOutput('🔄 Testing refresh subscription status...');
    
    try {
      await service.refreshSubscriptionStatus();
      _addDebugOutput('✅ Refresh status test completed');
      _addDebugOutput('📋 Current status: ${service.currentSubscription.status.displayName}');
      _addDebugOutput('📋 Has access: ${service.hasActiveSubscription}');
    } catch (e) {
      _addDebugOutput('❌ Refresh status test failed');
      _addDebugOutput('📋 Error: ${e.toString()}');
    } finally {
      setState(() => _runningTest = false);
    }
  }

  Future<void> _testClearLocalData(SubscriptionService service) async {
    setState(() => _runningTest = true);
    _addDebugOutput('🔄 Testing clear local data...');
    
    try {
      await service.clearSubscription();
      _addDebugOutput('✅ Clear local data test completed');
      _addDebugOutput('📋 Local subscription data cleared');
      _addDebugOutput('📋 Current status: ${service.currentSubscription.status.displayName}');
    } catch (e) {
      _addDebugOutput('❌ Clear local data test failed');
      _addDebugOutput('📋 Error: ${e.toString()}');
    } finally {
      setState(() => _runningTest = false);
    }
  }

  Future<void> _testFirebaseFunctions(SubscriptionService service) async {
    setState(() => _runningTest = true);
    _addDebugOutput('🔄 Testing Firebase Functions connectivity...');
    
    try {
      final result = await service.testFirebaseFunctions();
      _addDebugOutput('✅ Firebase Functions test passed');
      _addDebugOutput('📋 Result: ${result.toString()}');
    } catch (e) {
      _addDebugOutput('❌ Firebase Functions test failed');
      _addDebugOutput('📋 Error: ${e.toString()}');
    } finally {
      setState(() => _runningTest = false);
    }
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0;
    }
    return deviceType == DeviceType.mobile ? 20.0 : 32.0;
  }

  Widget _buildLoginPrompt(BuildContext context, DeviceType deviceType) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.login,
              size: 48,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign In Required',
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to your account to manage subscriptions and sync your progress across devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: deviceType == DeviceType.mobile ? 14 : 16,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/auth'),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionService service, DeviceType deviceType) {
    final subscription = service.currentSubscription;
    
    return Material(
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
            // Loading indicator during processing
            if (service.isLoading || _processingPayment) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _processingPayment ? 'Processing payment...' : 'Updating subscription...',
                        style: TextStyle(
                          color: Colors.blue.shade700,
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
                enabled: !service.isLoading && !_processingPayment,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                'Cancel Subscription',
                Icons.cancel,
                () => _handleCancelSubscription(context, service),
                Colors.red,
                deviceType,
                enabled: !service.isLoading && !_processingPayment,
              ),
            ],
            if (subscription.status == SubscriptionStatus.paused || 
                subscription.status == SubscriptionStatus.canceled) ...[
              _buildActionButton(
                context,
                'Resume Subscription',
                Icons.play_arrow,
                () => _handleResumeSubscription(context, service),
                Colors.green,
                deviceType,
                enabled: !service.isLoading && !_processingPayment,
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
    final isLoading = service.isLoading || _processingPayment;

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
          onTap: isLoading ? null : () => _handleSubscribe(context, service, tier),
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
                      if (tier == SubscriptionTier.premiumAnnual) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Save 17% vs monthly',
                          style: TextStyle(
                            fontSize: deviceType == DeviceType.mobile ? 12 : 14,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: deviceType == DeviceType.mobile ? 80 : 100,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleSubscribe(context, service, tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.blue : Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: isLoading
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
            _buildFeatureItem(
              'Unlimited Fretboards',
              'Create and save unlimited custom fretboards',
              Icons.library_music,
              service.hasActiveSubscription,
              deviceType,
            ),
            _buildFeatureItem(
              'Advanced Quizzes',
              'Access to comprehensive music theory quizzes',
              Icons.quiz,
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
    DeviceType deviceType, {
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: deviceType == DeviceType.mobile ? 18 : 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: deviceType == DeviceType.mobile ? 14 : 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade300,
          foregroundColor: enabled ? Colors.white : Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Action handlers with improved error handling and user feedback

  Future<void> _handleSubscribe(BuildContext context, SubscriptionService service, SubscriptionTier tier) async {
    if (!FirebaseUserService.instance.isLoggedIn) {
      _addDebugOutput('❌ Subscribe failed: User not signed in');
      _showErrorSnackBar(context, 'Please sign in to subscribe');
      return;
    }

    _addDebugOutput('🔄 Showing payment form for ${tier.displayName}...');

    // Get user information
    final currentUser = await UserService.instance.getCurrentUser();
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    
    final userEmail = currentUser?.email ?? firebaseUser?.email ?? '';
    final userName = currentUser?.username ?? firebaseUser?.displayName ?? userEmail.split('@')[0];

    if (userEmail.isEmpty) {
      _addDebugOutput('❌ User email not available');
      _showErrorSnackBar(context, 'User email is required for subscription');
      return;
    }

    // Show payment form as bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentFormWidget(
        tier: tier,
        userEmail: userEmail,
        userName: userName,
        onPaymentSubmitted: (paymentMethodData) async {
          // Close the payment form
          Navigator.of(context).pop();
          
          // Process the subscription with payment method
          await _processSubscriptionWithPaymentMethod(
            context, 
            service, 
            tier, 
            paymentMethodData,
          );
        },
        onCancel: () {
          Navigator.of(context).pop();
          _addDebugOutput('ℹ️ Payment form canceled by user');
        },
      ),
    );
  }

  Future<void> _processSubscriptionWithPaymentMethod(
    BuildContext context,
    SubscriptionService service,
    SubscriptionTier tier,
    SubscriptionPaymentData paymentMethodData,
  ) async {
    setState(() => _processingPayment = true);
    _addDebugOutput('🔄 Processing subscription with payment method...');

    try {
      Map<String, dynamic> result;
      
      // Handle empty paymentMethodId (web checkout flow)
      if (paymentMethodData.paymentMethodId.isEmpty) {
        _addDebugOutput('🔄 Using web checkout flow (no payment method provided)');
        
        // For web, we pass empty payment method ID to trigger Stripe Checkout
        result = await service.startSubscriptionWithPaymentMethod(
          tier: tier,
          paymentMethodId: '', // Empty string triggers web checkout
        );
        
        // Handle web redirect if required
        if (result['requiresRedirect'] == true && result.containsKey('redirectUrl')) {
          final redirectUrl = result['redirectUrl'] as String;
          _addDebugOutput('🔄 Redirecting to Stripe Checkout: $redirectUrl');
          
          if (kIsWeb) {
            // Use url_launcher for web-safe redirect
            final uri = Uri.parse(redirectUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, webOnlyWindowName: '_self');
              return; // Don't continue processing after redirect
            } else {
              throw Exception('Cannot open checkout URL: $redirectUrl');
            }
          } else {
            // For mobile (shouldn't happen), show error
            throw Exception('Web checkout URL received on mobile platform');
          }
        }
        
        // Handle direct checkout URL (alternative approach)
        if (result.containsKey('checkoutUrl')) {
          final checkoutUrl = result['checkoutUrl'] as String;
          _addDebugOutput('🔄 Opening Stripe Checkout URL: $checkoutUrl');
          
          final uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            if (kIsWeb) {
              // For web, replace current page
              await launchUrl(uri, webOnlyWindowName: '_self');
            } else {
              // For mobile, open in external browser
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return;
          } else {
            throw Exception('Cannot open checkout URL: $checkoutUrl');
          }
        }
      } else {
        _addDebugOutput('🔄 Using mobile flow with payment method: ${paymentMethodData.paymentMethodId}');
        
        // Call the subscription service method with payment method
        result = await service.startSubscriptionWithPaymentMethod(
          tier: tier,
          paymentMethodId: paymentMethodData.paymentMethodId,
        );
      }
      
      // If we reach here, the subscription was processed successfully without redirect
      if (context.mounted) {
        _addDebugOutput('✅ Subscription completed successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.white),
                const SizedBox(width: 8),
                Text('Welcome to ${tier.displayName}! Your 7-day free trial has started.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on StripeException catch (e) {
      _addDebugOutput('❌ Stripe error: ${e.error.message}');
      if (context.mounted) {
        String errorMessage = 'Payment failed: ';
        switch (e.error.type) {
          case 'card_error':
            errorMessage += e.error.message ?? 'Card was declined';
            break;
          case 'invalid_request_error':
            errorMessage += 'Invalid payment request';
            break;
          default:
            errorMessage += e.error.message ?? 'Unknown payment error';
        }
        _showErrorSnackBar(context, errorMessage);
      }
    } catch (e) {
      _addDebugOutput('❌ Subscription error: ${e.toString()}');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Subscription failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _processingPayment = false);
      }
    }
  }

  Future<void> _handlePauseSubscription(BuildContext context, SubscriptionService service) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Pause Subscription',
      'Are you sure you want to pause your subscription? You can resume it anytime.',
      confirmText: 'Pause',
      confirmColor: Colors.orange,
    );

    if (confirmed && context.mounted) {
      _addDebugOutput('🔄 Pausing subscription...');
      try {
        await service.pauseSubscription();
        if (context.mounted) {
          _addDebugOutput('✅ Subscription paused successfully');
          _showSuccessSnackBar(context, 'Subscription paused successfully');
        }
      } catch (e) {
        _addDebugOutput('❌ Failed to pause subscription: ${e.toString()}');
        if (context.mounted) {
          _showErrorSnackBar(context, 'Failed to pause subscription: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _handleResumeSubscription(BuildContext context, SubscriptionService service) async {
    _addDebugOutput('🔄 Resuming subscription...');
    try {
      await service.resumeSubscription();
      if (context.mounted) {
        _addDebugOutput('✅ Subscription resumed successfully');
        _showSuccessSnackBar(context, 'Subscription resumed successfully');
      }
    } catch (e) {
      _addDebugOutput('❌ Failed to resume subscription: ${e.toString()}');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to resume subscription: ${e.toString()}');
      }
    }
  }

  /// Handle return from Stripe Checkout (success)
  void _handleCheckoutSuccess(String sessionId) {
    _addDebugOutput('✅ Returned from Stripe Checkout successfully: $sessionId');
    
    // Refresh subscription status
    final service = Provider.of<SubscriptionService>(context, listen: false);
    service.refreshSubscriptionStatus().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.white),
                SizedBox(width: 8),
                Text('Welcome to Premium! Your subscription is now active.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }).catchError((error) {
      _addDebugOutput('❌ Failed to refresh subscription after checkout: $error');
    });
  }

  /// Handle return from Stripe Checkout (cancelled)
  void _handleCheckoutCancel() {
    _addDebugOutput('ℹ️ User cancelled Stripe Checkout');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('Checkout was cancelled. You can try again anytime.'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  Future<void> _handleCancelSubscription(BuildContext context, SubscriptionService service) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Cancel Subscription',
      'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.',
      confirmText: 'Cancel Subscription',
      confirmColor: Colors.red,
    );

    if (confirmed && context.mounted) {
      _addDebugOutput('🔄 Canceling subscription...');
      try {
        await service.cancelSubscription();
        if (context.mounted) {
          _addDebugOutput('✅ Subscription canceled successfully');
          _showSuccessSnackBar(context, 'Subscription canceled successfully');
        }
      } catch (e) {
        _addDebugOutput('❌ Failed to cancel subscription: ${e.toString()}');
        if (context.mounted) {
          _showErrorSnackBar(context, 'Failed to cancel subscription: ${e.toString()}');
        }
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context, 
    String title, 
    String content, {
    String confirmText = 'Confirm',
    Color confirmColor = Colors.red,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}