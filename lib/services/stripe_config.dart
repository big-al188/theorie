// lib/services/stripe_config.dart - Stripe initialization and configuration
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe configuration service
class StripeConfig {
  // Stripe Publishable Keys - Replace with your actual keys
  static const String _testPublishableKey = 'pk_test_your_test_publishable_key_here';
  static const String _livePublishableKey = 'pk_live_your_live_publishable_key_here';
  
  // Use test key for development, live key for production
  static const bool _useTestKey = kDebugMode; // Automatically use test in debug mode
  
  static String get publishableKey => _useTestKey ? _testPublishableKey : _livePublishableKey;
  
  /// Initialize Stripe with configuration
  static Future<void> initialize() async {
    try {
      debugPrint('🔄 [StripeConfig] Initializing Stripe...');
      
      Stripe.publishableKey = publishableKey;
      
      // Configure Stripe settings
      await Stripe.instance.applySettings();
      
      debugPrint('✅ [StripeConfig] Stripe initialized successfully');
      debugPrint('🔑 [StripeConfig] Using ${_useTestKey ? 'TEST' : 'LIVE'} environment');
    } catch (e) {
      debugPrint('❌ [StripeConfig] Error initializing Stripe: $e');
      rethrow;
    }
  }
  
  /// Get environment info for debugging
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'isTestMode': _useTestKey,
      'publishableKey': publishableKey.substring(0, 12) + '...', // Masked for security
      'isDebugMode': kDebugMode,
    };
  }
}

/// Extension for common Stripe operations
extension StripeHelpers on Stripe {
  /// Initialize payment sheet with common parameters
  static Future<void> initializePaymentSheet({
    required String clientSecret,
    String? customerId,
    String? ephemeralKeySecret,
    String merchantDisplayName = 'Theorie App',
    ThemeMode style = ThemeMode.system,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        customerEphemeralKeySecret: ephemeralKeySecret,
        customerId: customerId,
        merchantDisplayName: merchantDisplayName,
        style: style,
        appearance: PaymentSheetAppearance(
          primaryButton: PaymentSheetPrimaryButtonAppearance(
            colors: PaymentSheetPrimaryButtonTheme(
              light: PaymentSheetPrimaryButtonThemeColors(
                background: const Color(0xFF007AFF),
                text: const Color(0xFFFFFFFF),
              ),
              dark: PaymentSheetPrimaryButtonThemeColors(
                background: const Color(0xFF0A84FF),
                text: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Present payment sheet and handle result
  static Future<PaymentSheetPaymentOption?> presentPaymentSheetWithResult() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return await Stripe.instance.retrievePaymentIntent();
    } catch (e) {
      debugPrint('❌ [StripeHelpers] Payment sheet error: $e');
      rethrow;
    }
  }
}