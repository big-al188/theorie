// lib/services/stripe_config.dart - Environment-aware Stripe configuration
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_config.dart'; // Import AppConfig

/// Stripe configuration service with environment variable support
class StripeConfig {
  // Get publishable key from environment variables or fallback to hardcoded for local dev
  static String get publishableKey {
    final envKey = AppConfig.stripePublishableKey;
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // Fallback for local development
    return kDebugMode 
        ? 'pk_test_51Rs7HVILJ0OoLUiBc8PBRibh5acqX5EI2cI7D7Au1us6UcSZzF01hDXn9jo7F0Tv0x8B0V4ydH9pzcSGDqpQGYwg00tQapSRq4'
        : '';
  }
  
  /// Initialize Stripe with configuration
  static Future<void> initialize() async {
    try {
      debugPrint('🔄 [StripeConfig] Initializing Stripe...');
      
      if (publishableKey.isEmpty) {
        throw Exception('Stripe publishable key not configured');
      }
      
      Stripe.publishableKey = publishableKey;
      
      // Set additional Stripe configuration
      Stripe.merchantIdentifier = 'merchant.com.yourcompany.theorie';
      Stripe.urlScheme = 'flutterstripe';
      
      // Configure Stripe settings
      await Stripe.instance.applySettings();
      
      debugPrint('✅ [StripeConfig] Stripe initialized successfully');
      debugPrint('🔑 [StripeConfig] Using ${AppConfig.environment} environment');
      debugPrint('🔒 [StripeConfig] Key: ${publishableKey.substring(0, 12)}...');
      debugPrint('🧪 [StripeConfig] Test mode: ${isTestMode ? "YES" : "NO"}');
    } catch (e) {
      debugPrint('❌ [StripeConfig] Error initializing Stripe: $e');
      rethrow;
    }
  }
  
  /// Get environment info for debugging
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': AppConfig.environment,
      'isTestMode': isTestMode,
      'isLiveMode': isLiveMode,
      'publishableKey': publishableKey.isNotEmpty 
        ? '${publishableKey.substring(0, 12)}...' 
        : 'Not configured',
      'isDebugMode': kDebugMode,
      'isConfigured': isConfigured,
    };
  }
  
  /// Validate Stripe configuration
  static bool get isConfigured => publishableKey.isNotEmpty;
  static bool get isTestMode => publishableKey.startsWith('pk_test_');
  static bool get isLiveMode => publishableKey.startsWith('pk_live_');
}

/// Extension for common Stripe operations
extension StripeHelpers on Stripe {
  /// Initialize payment sheet with common parameters
  static Future<void> initializePaymentSheet({
    required String clientSecret,
    String? customerId,
    String? ephemeralKeySecret,
    String merchantDisplayName = 'Theorie Music Learning',
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
                background: Colors.blue,
                text: Colors.white,
              ),
              dark: PaymentSheetPrimaryButtonThemeColors(
                background: Colors.lightBlue,
                text: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Present payment sheet and handle result
  static Future<bool> presentPaymentSheetWithResult() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return true; // Payment successful
    } catch (e) {
      debugPrint('❌ [StripeHelpers] Payment sheet error: $e');
      if (e is StripeException) {
        debugPrint('❌ [StripeHelpers] Stripe error code: ${e.error.code}');
        debugPrint('❌ [StripeHelpers] Stripe error message: ${e.error.message}');
      }
      return false; // Payment failed or cancelled
    }
  }
}