// lib/services/subscription_service.dart - Updated with HTTPS requests
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'dart:html' as html show window;  // ADD THIS LINE
import '../models/subscription/subscription_models.dart';
import '../models/subscription/payment_models.dart';
import './firebase_user_service.dart';
import './user_service.dart';

/// Subscription service using HTTPS Firebase Functions
class SubscriptionService extends ChangeNotifier {
  static SubscriptionService? _instance;
  static SubscriptionService get instance => _instance ??= SubscriptionService._();
  SubscriptionService._();

  // Firebase Functions base URL (update with your project ID)
  static const String _baseUrl = 'https://us-central1-theorie-3ef8a.cloudfunctions.net';
  
  // Local storage keys
  static const String _subscriptionDataKey = 'subscription_data';
  static const String _lastSyncKey = 'subscription_last_sync';

  SharedPreferences? _prefs;
  SubscriptionData? _currentSubscription;
  bool _isInitialized = false;
  bool _isLoading = false;
  Timer? _syncTimer;
  bool _isInitializing = false;
  bool _hasNetworkError = false;

  // Getters
  SubscriptionData get currentSubscription => 
      _currentSubscription ?? SubscriptionData.empty();
  bool get hasActiveSubscription => currentSubscription.hasAccess;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get hasNetworkError => _hasNetworkError;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) {
      debugPrint('ℹ️ [SubscriptionService] Already initialized or initializing, skipping...');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('🔄 [SubscriptionService] Initializing...');
      
      _prefs = await SharedPreferences.getInstance();
      
      // Load subscription data
      await _loadSubscriptionData();
      
      // Start periodic sync for authenticated users
      _startPeriodicSync();
      
      _isInitialized = true;
      debugPrint('✅ [SubscriptionService] Initialized successfully');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error initializing: $e');
      _isInitialized = true;
      _currentSubscription = SubscriptionData.empty();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Get Firebase ID Token for authentication
  Future<String?> _getAuthToken() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('⚠️ [SubscriptionService] No Firebase user found');
        return null;
      }

      final idToken = await firebaseUser.getIdToken(true);
      debugPrint('✅ [SubscriptionService] Got ID token: ${idToken?.length ?? 0} characters');
      return idToken;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error getting auth token: $e');
      return null;
    }
  }

  /// Make authenticated HTTP request to Firebase Functions
  Future<Map<String, dynamic>> _makeHttpRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$endpoint');
      debugPrint('🔄 [SubscriptionService] Making $method request to: $url');

      // Prepare headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add authentication if required
      if (requireAuth) {
        final token = await _getAuthToken();
        if (token == null) {
          throw Exception('Authentication required but no token available');
        }
        headers['Authorization'] = 'Bearer $token';
      }

      debugPrint('📋 [SubscriptionService] Headers: ${headers.keys.join(', ')}');
      if (body != null) {
        debugPrint('📋 [SubscriptionService] Request body: ${jsonEncode(body)}');
      }

      // Make request
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('📋 [SubscriptionService] Response status: ${response.statusCode}');
      debugPrint('📋 [SubscriptionService] Response body: ${response.body}');

      // Parse response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else {
        // Handle error response
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          errorData = {'error': 'HTTP ${response.statusCode}', 'message': response.body};
        }
        
        final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] HTTP request failed: $e');
      rethrow;
    }
  }

  /// Enhanced authentication test with detailed debugging
  Future<Map<String, dynamic>> testAuthentication() async {
    try {
      debugPrint('🔄 [SubscriptionService] Testing authentication...');
      
      // Get current Firebase user
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No Firebase user found');
      }

      debugPrint('📋 [SubscriptionService] Firebase user ID: ${firebaseUser.uid}');
      debugPrint('📋 [SubscriptionService] Firebase user email: ${firebaseUser.email}');

      // Test the testAuth endpoint
      debugPrint('🔄 [SubscriptionService] Calling testAuth endpoint...');
      final result = await _makeHttpRequest('testAuth', 'GET', requireAuth: true);
      debugPrint('✅ [SubscriptionService] testAuth success: $result');
      return result;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Auth test failed: $e');
      debugPrint('❌ [SubscriptionService] Error type: ${e.runtimeType}');
      
      // Provide specific debugging information
      if (e.toString().contains('CORS')) {
        debugPrint('🌐 [SubscriptionService] CORS error detected');
      } else if (e.toString().contains('401')) {
        debugPrint('🔐 [SubscriptionService] Authentication error');
      } else if (e.toString().contains('404')) {
        debugPrint('📍 [SubscriptionService] Function not found - check deployment and URL');
      } else if (e.toString().contains('500')) {
        debugPrint('🔧 [SubscriptionService] Internal server error - check function deployment');
      }
      
      rethrow;
    }
  }

  /// Test basic connectivity without authentication
  Future<Map<String, dynamic>> testBasicConnectivity() async {
    try {
      debugPrint('🔄 [SubscriptionService] Testing basic connectivity...');
      debugPrint('📋 [SubscriptionService] Base URL: $_baseUrl');
      
      // Try calling testAuth endpoint without authentication
      final result = await _makeHttpRequest('testAuth', 'GET', requireAuth: false);
      debugPrint('✅ [SubscriptionService] Basic connectivity successful: $result');
      return result;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Basic connectivity failed: $e');
      debugPrint('❌ [SubscriptionService] Error details: ${e.toString()}');
      
      // Provide specific guidance based on error
      if (e.toString().contains('404')) {
        debugPrint('🔧 [Debug] Function not found - check if functions are deployed');
      } else if (e.toString().contains('500')) {
        debugPrint('🔧 [Debug] Internal error - check Firebase Functions logs');
      } else if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        debugPrint('🔧 [Debug] Network error - check internet connection');
      } else {
        debugPrint('🔧 [Debug] Unknown error - check Firebase configuration');
      }
      
      rethrow;
    }
  }

  /// Load subscription data
  Future<void> _loadSubscriptionData() async {
    try {
      debugPrint('📱 [SubscriptionService] Loading subscription data...');

      // First, load from local storage
      final localData = await _loadFromLocal();
      if (localData != null) {
        _currentSubscription = localData;
        debugPrint('✅ [SubscriptionService] Loaded from local storage');
      } else {
        _currentSubscription = SubscriptionData.empty();
        debugPrint('ℹ️ [SubscriptionService] No local data, using empty subscription');
      }

      // If user is logged in, try to sync with Firebase (but don't block initialization)
      if (FirebaseUserService.instance.isLoggedIn) {
        _syncWithFirebaseInBackground();
      }
      
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error loading subscription: $e');
      _currentSubscription = SubscriptionData.empty();
    }
  }

  /// Background sync with Firebase
  Future<void> _syncWithFirebaseInBackground() async {
    try {
      debugPrint('☁️ [SubscriptionService] Background sync with Firebase...');
      
      // Get latest subscription data from Firebase Function
      final latestData = await _getSubscriptionStatusFromFirebase();
      
      if (latestData != null) {
        _currentSubscription = latestData;
        await _saveToLocal(latestData);
        _hasNetworkError = false;
        debugPrint('✅ [SubscriptionService] Background sync completed');
        notifyListeners();
      } else {
        debugPrint('ℹ️ [SubscriptionService] No subscription data found in Firebase');
      }
    } catch (e) {
      debugPrint('⚠️ [SubscriptionService] Background sync failed: $e');
      
      if (e.toString().contains('network') || 
          e.toString().contains('internet') ||
          e.toString().contains('connection') ||
          e.toString().contains('SocketException')) {
        _hasNetworkError = true;
        debugPrint('🌐 [SubscriptionService] Network error detected - using local data');
      }
    }
  }

  /// Load subscription data from local storage
  Future<SubscriptionData?> _loadFromLocal() async {
    try {
      final jsonString = _prefs?.getString(_subscriptionDataKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return SubscriptionData.fromJson(json);
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error loading from local: $e');
    }
    return null;
  }

  /// Save subscription data to local storage
  Future<void> _saveToLocal(SubscriptionData data) async {
    try {
      final jsonString = jsonEncode(data.toJson());
      await _prefs?.setString(_subscriptionDataKey, jsonString);
      await _prefs?.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error saving to local: $e');
    }
  }

  /// Update subscription data
  Future<void> updateSubscription(SubscriptionData data) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      _setLoading(true);
      
      _currentSubscription = data;
      
      // Save to local storage
      await _saveToLocal(data);
      
      debugPrint('✅ [SubscriptionService] Subscription updated: ${data.status.displayName}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error updating subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

// Updated subscription service method to handle web payments
// Add this method to your SubscriptionService class

  /// Start subscription flow with payment method (updated for web support)
  Future<Map<String, dynamic>> startSubscriptionWithPaymentMethod({
    required SubscriptionTier tier,
    required String paymentMethodId,
    String? customerId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      _setLoading(true);
      debugPrint('🔄 [SubscriptionService] Starting subscription with payment method for tier: ${tier.displayName}');
      
      // Check authentication
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User must be signed in to create subscription');
      }

      debugPrint('🔄 [SubscriptionService] Firebase user ID: ${firebaseUser.uid}');
      debugPrint('🔄 [SubscriptionService] Payment method ID: $paymentMethodId');

      // Get user data
      final currentUser = await UserService.instance.getCurrentUser();
      final email = currentUser?.email ?? firebaseUser.email;
      final name = currentUser?.username ?? firebaseUser.displayName ?? email?.split('@')[0];
      
      if (email == null) {
        debugPrint('❌ [SubscriptionService] No email available from any source');
        throw Exception('User email is required for subscription');
      }

      // Handle web vs mobile flows differently
      if (paymentMethodId.isEmpty) {
        // Web flow - use Stripe Checkout (no payment method provided)
        debugPrint('🔄 [SubscriptionService] Using web checkout flow');
        return await _handleWebCheckoutFlow(tier, email, name);
      } else {
        // Mobile flow - use provided payment method
        debugPrint('🔄 [SubscriptionService] Using mobile payment method flow');
        return await _handleMobilePaymentFlow(tier, email, name, paymentMethodId);
      }
      
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Unexpected error: $e');
      debugPrint('❌ [SubscriptionService] Error type: ${e.runtimeType}');
      
      if (e.toString().contains('network') || 
          e.toString().contains('internet') || 
          e.toString().contains('connection') ||
          e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection and try again');
      } else if (e.toString().contains('401')) {
        throw Exception('Authentication error: Please sign out and sign in again');
      } else if (e.toString().contains('403')) {
        throw Exception('Permission error: Please ensure you have the necessary permissions');
      } else if (e is Exception) {
        rethrow; // Re-throw our custom exceptions
      } else {
        throw Exception('Subscription setup failed: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
      debugPrint('🔄 [SubscriptionService] Subscription attempt completed, loading state cleared');
    }
  }

// Add this method to your SubscriptionService class

/// Get the current app URL for redirect purposes
String _getCurrentAppUrl() {
  if (kIsWeb) {
    // Get current URL from browser
    final currentUrl = Uri.parse(html.window.location.href);
    final origin = '${currentUrl.scheme}://${currentUrl.host}';
    
    // Add port if it's not default (80/443)
    if (currentUrl.hasPort && 
        currentUrl.port != 80 && 
        currentUrl.port != 443) {
      return '$origin:${currentUrl.port}';
    }
    
    return origin;
  } else {
    // For mobile apps, you might want to use deep links
    return 'your-app://subscription';
  }
}

/// Handle web checkout flow (redirects to Stripe Checkout)
Future<Map<String, dynamic>> _handleWebCheckoutFlow(
  SubscriptionTier tier, 
  String email, 
  String? name
) async {
  // Call Firebase Function to create Stripe Checkout Session
  debugPrint('🔄 [SubscriptionService] Calling createSubscriptionSetup for web checkout...');
  
  // Get current app URL for redirects
  final baseUrl = _getCurrentAppUrl();
  
  final requestBody = {
    'tier': tier.id,
    'email': email,
    'name': name,
    // Add redirect URLs based on current environment
    'successUrl': '$baseUrl',             ///subscription/success?session_id={CHECKOUT_SESSION_ID}',
    'cancelUrl': '$baseUrl',              ///subscription/cancel',
    // Don't include paymentMethodId for web checkout flow
  };
  
  debugPrint('🔄 [SubscriptionService] Request body: $requestBody');
  debugPrint('🔄 [SubscriptionService] Success URL: ${requestBody['successUrl']}');
  debugPrint('🔄 [SubscriptionService] Cancel URL: ${requestBody['cancelUrl']}');
  
  final result = await _makeHttpRequest(
    'createSubscriptionSetup', 
    'POST', 
    body: requestBody,
    requireAuth: true,
  );
  
  debugPrint('✅ [SubscriptionService] Firebase Function call successful');
  debugPrint('📋 [SubscriptionService] Response data: $result');
  
  if (result['success'] == true && result.containsKey('checkoutUrl')) {
    debugPrint('🔄 [SubscriptionService] Checkout URL received, redirecting...');
    debugPrint('📋 [SubscriptionService] Checkout URL: ${result['checkoutUrl']}');
    
    // For web, we need to redirect to the checkout URL
    if (kIsWeb) {
      try {
        debugPrint('✅ [SubscriptionService] Web checkout URL ready for redirect');
        return {
          ...result,
          'requiresRedirect': true,
          'redirectUrl': result['checkoutUrl'],
        };
      } catch (e) {
        debugPrint('❌ [SubscriptionService] Failed to redirect to checkout: $e');
        throw Exception('Failed to redirect to checkout: ${e.toString()}');
      }
    } else {
      // For mobile, this shouldn't happen, but handle gracefully
      debugPrint('⚠️ [SubscriptionService] Received checkout URL on mobile platform');
      return result;
    }
  } else if (result['success'] == true && result.containsKey('clientSecret')) {
    // Fallback to payment sheet if clientSecret is provided
    debugPrint('🔄 [SubscriptionService] Client secret received as fallback...');
    
    // Initialize payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: result['clientSecret'],
        merchantDisplayName: 'Theorie App',
        style: ThemeMode.light,
      ),
    );
    
    debugPrint('✅ [SubscriptionService] Payment sheet initialized');

    // Present payment sheet
    debugPrint('🔄 [SubscriptionService] Presenting payment sheet');
    await Stripe.instance.presentPaymentSheet();
    
    debugPrint('✅ [SubscriptionService] Payment sheet completed successfully');
    
    // Refresh subscription status after successful payment
    debugPrint('🔄 [SubscriptionService] Refreshing subscription status');
    await refreshSubscriptionStatus();
    
    debugPrint('✅ [SubscriptionService] Web checkout completed successfully');
    return result;
  } else {
    debugPrint('❌ [SubscriptionService] Invalid response from subscription setup');
    throw Exception('Subscription setup failed: ${result['error'] ?? 'Unknown error'}');
  }
}

  /// Handle mobile payment flow (uses provided payment method)
  Future<Map<String, dynamic>> _handleMobilePaymentFlow(
    SubscriptionTier tier, 
    String email, 
    String? name,
    String paymentMethodId
  ) async {
    // Call Firebase Function to create subscription setup WITH payment method
    debugPrint('🔄 [SubscriptionService] Calling createSubscriptionSetup with payment method...');
    
    final requestBody = {
      'tier': tier.id,
      'email': email,
      'name': name,
      'paymentMethodId': paymentMethodId,
    };
    
    final result = await _makeHttpRequest(
      'createSubscriptionSetup', 
      'POST', 
      body: requestBody,
      requireAuth: true,
    );
    
    debugPrint('✅ [SubscriptionService] Firebase Function call successful');
    debugPrint('📋 [SubscriptionService] Response data: $result');
    
    if (result['success'] == true) {
      // Refresh subscription status after successful creation
      debugPrint('🔄 [SubscriptionService] Refreshing subscription status');
      await refreshSubscriptionStatus();
      
      debugPrint('✅ [SubscriptionService] Mobile payment flow completed successfully');
      return result;
    } else {
      debugPrint('❌ [SubscriptionService] Invalid response from subscription setup');
      throw Exception('Subscription setup failed: ${result['error'] ?? 'Unknown error'}');
    }
  }

  /// Start subscription flow with enhanced debugging and error handling (deprecated - use startSubscriptionWithPaymentMethod)
  Future<Map<String, dynamic>> startSubscription({
    required SubscriptionTier tier,
    String? customerId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      _setLoading(true);
      debugPrint('🔄 [SubscriptionService] Starting subscription for tier: ${tier.displayName}');
      
      // First, test basic connectivity
      debugPrint('🔄 [SubscriptionService] Testing basic connectivity first...');
      await testBasicConnectivity();
      
      // Check authentication
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User must be signed in to create subscription');
      }

      debugPrint('🔄 [SubscriptionService] Firebase user exists: ${firebaseUser != null}');
      debugPrint('🔄 [SubscriptionService] Firebase user ID: ${firebaseUser.uid}');
      debugPrint('🔄 [SubscriptionService] Firebase user email: ${firebaseUser.email}');
      debugPrint('🔄 [SubscriptionService] Firebase user email verified: ${firebaseUser.emailVerified}');

      // Force refresh the ID token
      try {
        final idToken = await firebaseUser.getIdToken(true);
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Failed to obtain valid authentication token');
        }
        debugPrint('✅ [SubscriptionService] ID token refreshed successfully: ${idToken.length} characters');
        if (idToken.length >= 20) {
          debugPrint('🔄 [SubscriptionService] Token starts with: ${idToken.substring(0, 20)}...');
        }
      } catch (tokenError) {
        debugPrint('❌ [SubscriptionService] Failed to refresh token: $tokenError');
        throw Exception('Authentication error: Please sign out and sign in again');
      }
      
      // Get user data
      final currentUser = await UserService.instance.getCurrentUser();
      debugPrint('🔄 [SubscriptionService] Current app user exists: ${currentUser != null}');
      debugPrint('🔄 [SubscriptionService] Current app user: ${currentUser?.username}');
      
      final email = currentUser?.email ?? firebaseUser.email;
      final name = currentUser?.username ?? firebaseUser.displayName ?? email?.split('@')[0];
      
      debugPrint('🔄 [SubscriptionService] Final user data - Email: $email, Name: $name');
      
      if (email == null) {
        debugPrint('❌ [SubscriptionService] No email available from any source');
        throw Exception('User email is required for subscription');
      }
      
      // Call Firebase Function to create subscription setup
      debugPrint('🔄 [SubscriptionService] Calling createSubscriptionSetup endpoint...');
      
      final requestBody = {
        'tier': tier.id,
        'email': email,
        'name': name,
      };
      
      debugPrint('🔄 [SubscriptionService] Request body: $requestBody');
      
      final result = await _makeHttpRequest(
        'createSubscriptionSetup', 
        'POST', 
        body: requestBody,
        requireAuth: true,
      );
      
      debugPrint('✅ [SubscriptionService] Firebase Function call successful');
      debugPrint('📋 [SubscriptionService] Response data: $result');
      
      if (result['success'] == true && result.containsKey('clientSecret')) {
        debugPrint('🔄 [SubscriptionService] Client secret received, initializing payment...');
        debugPrint('📋 [SubscriptionService] Subscription ID: ${result['subscriptionId']}');
        debugPrint('📋 [SubscriptionService] Customer ID: ${result['customerId']}');
        debugPrint('📋 [SubscriptionService] Trial end: ${result['trialEnd']}');
        
        // Initialize payment with Stripe
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: result['clientSecret'],
            merchantDisplayName: 'Theorie App',
            style: ThemeMode.light,
          ),
        );
        
        debugPrint('✅ [SubscriptionService] Payment sheet initialized');

        // Present payment sheet
        debugPrint('🔄 [SubscriptionService] Presenting payment sheet');
        await Stripe.instance.presentPaymentSheet();
        
        debugPrint('✅ [SubscriptionService] Payment sheet completed successfully');
        
        // Refresh subscription status after successful payment
        debugPrint('🔄 [SubscriptionService] Refreshing subscription status');
        await refreshSubscriptionStatus();
        
        debugPrint('✅ [SubscriptionService] Subscription started successfully');
        return result;
      } else {
        debugPrint('❌ [SubscriptionService] Invalid response - missing clientSecret or success flag');
        debugPrint('📋 [SubscriptionService] Response data: $result');
        throw Exception('Invalid response from subscription setup: ${result['error'] ?? 'Unknown error'}');
      }
    } on StripeException catch (e) {
      debugPrint('❌ [SubscriptionService] Stripe error: ${e.error.type} - ${e.error.message}');
      debugPrint('❌ [SubscriptionService] Stripe error code: ${e.error.code}');
      
      // Stripe-specific error handling
      switch (e.error.type) {
        case 'card_error':
          throw Exception('Payment error: ${e.error.message ?? 'Card was declined'}');
        case 'invalid_request_error':
          throw Exception('Payment setup error: ${e.error.message ?? 'Invalid payment request'}');
        case 'api_connection_error':
          throw Exception('Unable to connect to payment service. Please check your internet connection.');
        case 'api_error':
          throw Exception('Payment service error. Please try again.');
        case 'authentication_error':
          throw Exception('Payment authentication error. Please try again.');
        case 'rate_limit_error':
          throw Exception('Too many payment attempts. Please wait and try again.');
        default:
          throw Exception('Payment error: ${e.error.message ?? 'Unknown payment error'}');
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Unexpected error: $e');
      debugPrint('❌ [SubscriptionService] Error type: ${e.runtimeType}');
      
      if (e.toString().contains('network') || 
          e.toString().contains('internet') || 
          e.toString().contains('connection') ||
          e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection and try again');
      } else if (e.toString().contains('401')) {
        throw Exception('Authentication error: Please sign out and sign in again');
      } else if (e.toString().contains('403')) {
        throw Exception('Permission error: Please ensure you have the necessary permissions');
      } else if (e is Exception) {
        rethrow; // Re-throw our custom exceptions
      } else {
        throw Exception('Subscription setup failed: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
      debugPrint('🔄 [SubscriptionService] Subscription attempt completed, loading state cleared');
    }
  }

  /// Cancel subscription using HTTPS endpoint
  Future<void> cancelSubscription({bool immediate = false}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      _setLoading(true);
      
      if (_currentSubscription?.subscriptionId == null) {
        throw Exception('No active subscription to cancel');
      }
      
      debugPrint('🔄 [SubscriptionService] Canceling subscription');
      
      // Call Firebase Function to cancel subscription
      final result = await _makeHttpRequest(
        'cancelSubscription',
        'POST',
        body: {
          'subscriptionId': _currentSubscription!.subscriptionId!,
          'cancelAtPeriodEnd': !immediate, // If immediate is true, set cancelAtPeriodEnd to false
        },
        requireAuth: true,
      );
      
      if (result['success'] != true) {
        throw Exception('Failed to cancel subscription: ${result['error'] ?? 'Unknown error'}');
      }
      
      // Refresh subscription status
      await refreshSubscriptionStatus();
      
      debugPrint('✅ [SubscriptionService] Subscription canceled');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error canceling subscription: $e');
      
      if (e.toString().contains('network') || 
          e.toString().contains('internet') ||
          e.toString().contains('SocketException')) {
        throw Exception('Unable to connect to subscription service. Please try again later.');
      }
      
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Pause subscription (cancel at period end)
  Future<void> pauseSubscription() async {
    return cancelSubscription(immediate: false);
  }

  /// Resume subscription using HTTPS endpoint
  Future<void> resumeSubscription() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      _setLoading(true);
      
      if (_currentSubscription?.subscriptionId == null) {
        throw Exception('No subscription to resume');
      }
      
      debugPrint('🔄 [SubscriptionService] Resuming subscription');
      
      // Call Firebase Function to resume subscription
      final result = await _makeHttpRequest(
        'resumeSubscription',
        'POST',
        body: {
          'subscriptionId': _currentSubscription!.subscriptionId!,
        },
        requireAuth: true,
      );
      
      if (result['success'] != true) {
        throw Exception('Failed to resume subscription: ${result['error'] ?? 'Unknown error'}');
      }
      
      // Refresh subscription status
      await refreshSubscriptionStatus();
      
      debugPrint('✅ [SubscriptionService] Subscription resumed');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error resuming subscription: $e');
      
      if (e.toString().contains('network') || 
          e.toString().contains('internet') ||
          e.toString().contains('SocketException')) {
        throw Exception('Unable to connect to subscription service. Please try again later.');
      }
      
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh subscription status using HTTPS endpoint
  Future<void> refreshSubscriptionStatus() async {
    if (!_isInitialized) {
      debugPrint('ℹ️ [SubscriptionService] Service not initialized, skipping refresh');
      return;
    }
    
    try {
      if (!FirebaseUserService.instance.isLoggedIn) {
        debugPrint('ℹ️ [SubscriptionService] User not logged in, skipping refresh');
        return;
      }

      debugPrint('🔄 [SubscriptionService] Refreshing subscription status');
      
      // Get latest subscription data from Firebase Function
      final latestData = await _getSubscriptionStatusFromFirebase();
      
      if (latestData != null) {
        _currentSubscription = latestData;
        await _saveToLocal(latestData);
        _hasNetworkError = false;
        notifyListeners();
        debugPrint('✅ [SubscriptionService] Subscription status refreshed');
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error refreshing subscription: $e');
      
      if (e.toString().contains('network') || 
          e.toString().contains('internet') ||
          e.toString().contains('SocketException')) {
        _hasNetworkError = true;
        debugPrint('🌐 [SubscriptionService] Network error - using cached data');
      }
    }
  }

  /// Get subscription status from HTTPS endpoint
  Future<SubscriptionData?> _getSubscriptionStatusFromFirebase() async {
    try {
      final result = await _makeHttpRequest(
        'getSubscriptionStatus',
        'GET',
        requireAuth: true,
      );
      
      if (result['success'] == true && result['hasSubscription'] == true && result['subscription'] != null) {
        final subscriptionInfo = result['subscription'] as Map<String, dynamic>;
        
        // Convert HTTPS response to SubscriptionData
        return SubscriptionData(
          status: SubscriptionStatus.fromString(subscriptionInfo['status'] ?? 'none'),
          tier: SubscriptionTier.fromString(subscriptionInfo['tier'] ?? 'free'),
          subscriptionId: subscriptionInfo['id'],
          customerId: subscriptionInfo['customerId'],
          currentPeriodStart: subscriptionInfo['currentPeriodStart'] != null
              ? DateTime.fromMillisecondsSinceEpoch((subscriptionInfo['currentPeriodStart'] as int) * 1000)
              : null,
          currentPeriodEnd: subscriptionInfo['currentPeriodEnd'] != null
              ? DateTime.fromMillisecondsSinceEpoch((subscriptionInfo['currentPeriodEnd'] as int) * 1000)
              : null,
          trialEnd: subscriptionInfo['trialEnd'] != null
              ? DateTime.fromMillisecondsSinceEpoch((subscriptionInfo['trialEnd'] as int) * 1000)
              : null,
          cancelAtPeriodEnd: subscriptionInfo['cancelAtPeriodEnd'] == true ? 'true' : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // No subscription found - return empty subscription
        debugPrint('ℹ️ [SubscriptionService] No subscription data found for user');
        return SubscriptionData.empty();
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error getting subscription status: $e');
      
      // If user not found or no subscription, return empty data
      if (e.toString().contains('404') || e.toString().contains('no subscription')) {
        return SubscriptionData.empty();
      }
      
      return null; // Return null to indicate error, not empty subscription
    }
  }

  /// Start periodic sync for authenticated users
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    
    if (FirebaseUserService.instance.isLoggedIn) {
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        if (_isInitialized) {
          refreshSubscriptionStatus();
        }
      });
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Test Firebase Functions connectivity
  Future<Map<String, dynamic>> testFirebaseFunctions() async {
    try {
      debugPrint('🔄 [SubscriptionService] Testing Firebase Functions connectivity...');
      
      // First test a simple function call
      final result = await _makeHttpRequest('getSubscriptionStatus', 'GET', requireAuth: true);
      
      debugPrint('✅ [SubscriptionService] Firebase Functions test successful');
      debugPrint('📋 [SubscriptionService] Test result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Firebase Functions test failed: $e');
      
      // Provide helpful error information for debugging
      if (e.toString().contains('CORS')) {
        debugPrint('🌐 [SubscriptionService] CORS error - check Firebase Functions CORS configuration');
      } else if (e.toString().contains('401')) {
        debugPrint('🔐 [SubscriptionService] Authentication error - ensure user is signed in');
      } else if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        debugPrint('🌐 [SubscriptionService] Network error - check internet connection');
      }
      
      rethrow;
    }
  }

  /// Clear subscription data (for logout)
  Future<void> clearSubscription() async {
    _currentSubscription = SubscriptionData.empty();
    await _prefs?.remove(_subscriptionDataKey);
    await _prefs?.remove(_lastSyncKey);
    _syncTimer?.cancel();
    notifyListeners();
    debugPrint('🧹 [SubscriptionService] Subscription data cleared');
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}