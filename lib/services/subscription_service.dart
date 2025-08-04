// lib/services/subscription_service.dart - Updated to use Firebase Callable Functions
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart'; // NEW: Firebase Functions
import '../models/subscription/subscription_models.dart';
import '../models/user/user.dart';
import './firebase_user_service.dart';
import './user_service.dart';

/// Subscription service using Firebase Callable Functions
class SubscriptionService extends ChangeNotifier {
  static SubscriptionService? _instance;
  static SubscriptionService get instance => _instance ??= SubscriptionService._();
  SubscriptionService._();

  // Firebase Functions instance
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
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
          e.toString().contains('connection')) {
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

  /// Start subscription flow using Firebase Callable Function
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
      
      // Get current user info
      final currentUser = await UserService.instance.getCurrentUser();
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      
      // FIXED: Better data validation and fallbacks
      final email = currentUser?.email ?? firebaseUser?.email;
      final name = currentUser?.username ?? firebaseUser?.displayName ?? email?.split('@')[0];
      
      debugPrint('🔄 [SubscriptionService] User data - Email: $email, Name: $name');
      
      if (email == null) {
        throw Exception('User email is required for subscription');
      }
      
      // Call Firebase Function to create subscription setup
      final callable = _functions.httpsCallable('createSubscriptionSetup');
      
      debugPrint('🔄 [SubscriptionService] Calling Firebase Function with data: {tier: ${tier.id}, email: $email, name: $name}');
      
      final result = await callable.call({
        'tier': tier.id,
        'email': email,
        'name': name,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data.containsKey('clientSecret')) {
        // Initialize payment with Stripe
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: data['clientSecret'],
            merchantDisplayName: 'Theorie App',
            style: ThemeMode.light,
          ),
        );

        // Present payment sheet
        await Stripe.instance.presentPaymentSheet();
        
        // Refresh subscription status after successful payment
        await refreshSubscriptionStatus();
        
        debugPrint('✅ [SubscriptionService] Subscription started successfully');
        return data;
      } else {
        throw Exception('Invalid response from subscription setup');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [SubscriptionService] Firebase Functions error: ${e.message}');
      throw Exception('Subscription setup failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error starting subscription: $e');
      
      // Provide user-friendly error messages
      if (e.toString().contains('network') || e.toString().contains('internet')) {
        throw Exception('Unable to connect to subscription service. Please check your internet connection and try again.');
      }
      
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription using Firebase Callable Function
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
      final callable = _functions.httpsCallable('cancelSubscription');
      await callable.call({
        'subscriptionId': _currentSubscription!.subscriptionId!,
        'cancelAtPeriodEnd': !immediate, // If immediate is true, set cancelAtPeriodEnd to false
      });
      
      // Refresh subscription status
      await refreshSubscriptionStatus();
      
      debugPrint('✅ [SubscriptionService] Subscription canceled');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [SubscriptionService] Firebase Functions error: ${e.message}');
      throw Exception('Failed to cancel subscription: ${e.message}');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error canceling subscription: $e');
      
      if (e.toString().contains('network') || e.toString().contains('internet')) {
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

  /// Resume subscription using Firebase Callable Function
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
      final callable = _functions.httpsCallable('resumeSubscription');
      await callable.call({
        'subscriptionId': _currentSubscription!.subscriptionId!,
      });
      
      // Refresh subscription status
      await refreshSubscriptionStatus();
      
      debugPrint('✅ [SubscriptionService] Subscription resumed');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [SubscriptionService] Firebase Functions error: ${e.message}');
      throw Exception('Failed to resume subscription: ${e.message}');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error resuming subscription: $e');
      
      if (e.toString().contains('network') || e.toString().contains('internet')) {
        throw Exception('Unable to connect to subscription service. Please try again later.');
      }
      
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh subscription status using Firebase Callable Function
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
      
      if (e.toString().contains('network') || e.toString().contains('internet')) {
        _hasNetworkError = true;
        debugPrint('🌐 [SubscriptionService] Network error - using cached data');
      }
    }
  }

  /// Get subscription status from Firebase Callable Function
  Future<SubscriptionData?> _getSubscriptionStatusFromFirebase() async {
    try {
      final callable = _functions.httpsCallable('getSubscriptionStatus');
      final result = await callable.call();
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['hasSubscription'] == true && data['subscription'] != null) {
        final subscriptionInfo = data['subscription'] as Map<String, dynamic>;
        
        // Convert Firebase Callable Function response to SubscriptionData
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
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [SubscriptionService] Firebase Functions error: ${e.message}');
      
      // If user not found or no subscription, return empty data
      if (e.code == 'not-found' || e.message?.contains('no subscription') == true) {
        return SubscriptionData.empty();
      }
      
      return null; // Return null to indicate error, not empty subscription
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error getting subscription status: $e');
      return null;
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

  /// Test Firebase Functions connectivity (for debugging)
  Future<void> testFirebaseFunctions() async {
    try {
      debugPrint('🔄 [SubscriptionService] Testing Firebase Functions connectivity...');
      
      final callable = _functions.httpsCallable('getSubscriptionStatus');
      final result = await callable.call();
      
      debugPrint('✅ [SubscriptionService] Firebase Functions test successful');
      debugPrint('📋 [SubscriptionService] Test result: ${result.data}');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Firebase Functions test failed: $e');
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