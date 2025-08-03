// lib/services/subscription_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/subscription/subscription_models.dart';
import '../models/user/user.dart';
import './firebase_user_service.dart';
import './user_service.dart';

/// Subscription service with local storage and Firebase sync
/// Follows the existing service architecture pattern from UserService
class SubscriptionService extends ChangeNotifier {
  static SubscriptionService? _instance;
  static SubscriptionService get instance => _instance ??= SubscriptionService._();
  SubscriptionService._();

  // Local storage keys
  static const String _subscriptionDataKey = 'subscription_data';
  static const String _lastSyncKey = 'subscription_last_sync';

  SharedPreferences? _prefs;
  SubscriptionData? _currentSubscription;
  bool _isInitialized = false;
  bool _isLoading = false;
  Timer? _syncTimer;

  // Getters
  SubscriptionData get currentSubscription => 
      _currentSubscription ?? SubscriptionData.empty();
  bool get hasActiveSubscription => currentSubscription.hasAccess;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 [SubscriptionService] Initializing...');
      
      _prefs = await SharedPreferences.getInstance();
      
      // Load subscription data with Firebase priority
      await _loadSubscriptionWithFirebasePriority();
      
      // Start periodic sync for authenticated users
      _startPeriodicSync();
      
      _isInitialized = true;
      debugPrint('✅ [SubscriptionService] Initialized successfully');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error initializing: $e');
      _isInitialized = true;
      _currentSubscription = SubscriptionData.empty();
    }
    notifyListeners();
  }

  /// Load subscription data with Firebase priority
  Future<void> _loadSubscriptionWithFirebasePriority() async {
    try {
      // Try Firebase first for authenticated users
      if (FirebaseUserService.instance.isLoggedIn) {
        debugPrint('☁️ [SubscriptionService] Loading from Firebase...');
        final firebaseData = await _loadFromFirebase();
        if (firebaseData != null) {
          _currentSubscription = firebaseData;
          await _saveToLocal(firebaseData);
          debugPrint('✅ [SubscriptionService] Loaded from Firebase');
          return;
        }
      }

      // Fallback to local storage
      debugPrint('📱 [SubscriptionService] Loading from local storage...');
      final localData = await _loadFromLocal();
      _currentSubscription = localData ?? SubscriptionData.empty();
      debugPrint('📱 [SubscriptionService] Loaded from local storage');
      
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error loading subscription: $e');
      _currentSubscription = SubscriptionData.empty();
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

  /// Load subscription data from Firebase
  Future<SubscriptionData?> _loadFromFirebase() async {
    try {
      // TODO: Implement Firebase subscription data loading
      // This would integrate with your Firebase Firestore
      debugPrint('🚧 [SubscriptionService] Firebase loading not yet implemented');
      return null;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error loading from Firebase: $e');
      return null;
    }
  }

  /// Save subscription data to Firebase
  Future<void> _saveToFirebase(SubscriptionData data) async {
    try {
      // TODO: Implement Firebase subscription data saving
      // This would integrate with your Firebase Firestore
      debugPrint('🚧 [SubscriptionService] Firebase saving not yet implemented');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error saving to Firebase: $e');
    }
  }

  /// Update subscription data
  Future<void> updateSubscription(SubscriptionData data) async {
    await initialize();
    
    try {
      _setLoading(true);
      
      _currentSubscription = data;
      
      // Save to local storage
      await _saveToLocal(data);
      
      // Save to Firebase for authenticated users
      if (FirebaseUserService.instance.isLoggedIn) {
        await _saveToFirebase(data);
      }
      
      debugPrint('✅ [SubscriptionService] Subscription updated: ${data.status.displayName}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error updating subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Start subscription flow
  Future<Map<String, dynamic>> startSubscription({
    required SubscriptionTier tier,
    String? customerId,
  }) async {
    await initialize();
    
    try {
      _setLoading(true);
      debugPrint('🔄 [SubscriptionService] Starting subscription for tier: ${tier.displayName}');
      
      // Create subscription intent on your backend
      final response = await _createSubscriptionIntent(tier: tier, customerId: customerId);
      
      debugPrint('✅ [SubscriptionService] Subscription intent created');
      return response;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error starting subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription({bool immediate = false}) async {
    await initialize();
    
    try {
      _setLoading(true);
      
      if (_currentSubscription?.subscriptionId == null) {
        throw Exception('No active subscription to cancel');
      }
      
      debugPrint('🔄 [SubscriptionService] Canceling subscription');
      
      // Cancel subscription on your backend
      await _cancelSubscriptionOnBackend(
        subscriptionId: _currentSubscription!.subscriptionId!,
        immediate: immediate,
      );
      
      // Update local status
      final updatedSubscription = _currentSubscription!.copyWith(
        status: immediate ? SubscriptionStatus.canceled : SubscriptionStatus.canceled,
        canceledAt: DateTime.now(),
      );
      
      await updateSubscription(updatedSubscription);
      
      debugPrint('✅ [SubscriptionService] Subscription canceled');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error canceling subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Pause subscription
  Future<void> pauseSubscription() async {
    await initialize();
    
    try {
      _setLoading(true);
      
      if (_currentSubscription?.subscriptionId == null) {
        throw Exception('No active subscription to pause');
      }
      
      debugPrint('🔄 [SubscriptionService] Pausing subscription');
      
      // Pause subscription on your backend
      await _pauseSubscriptionOnBackend(_currentSubscription!.subscriptionId!);
      
      // Update local status
      final updatedSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.paused,
      );
      
      await updateSubscription(updatedSubscription);
      
      debugPrint('✅ [SubscriptionService] Subscription paused');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error pausing subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Resume subscription
  Future<void> resumeSubscription() async {
    await initialize();
    
    try {
      _setLoading(true);
      
      if (_currentSubscription?.subscriptionId == null) {
        throw Exception('No subscription to resume');
      }
      
      debugPrint('🔄 [SubscriptionService] Resuming subscription');
      
      // Resume subscription on your backend
      await _resumeSubscriptionOnBackend(_currentSubscription!.subscriptionId!);
      
      // Update local status
      final updatedSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.active,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 30)), // Adjust based on plan
      );
      
      await updateSubscription(updatedSubscription);
      
      debugPrint('✅ [SubscriptionService] Subscription resumed');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error resuming subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh subscription status from backend
  Future<void> refreshSubscriptionStatus() async {
    await initialize();
    
    try {
      _setLoading(true);
      
      if (_currentSubscription?.customerId == null) {
        debugPrint('ℹ️ [SubscriptionService] No customer ID to refresh');
        return;
      }
      
      debugPrint('🔄 [SubscriptionService] Refreshing subscription status');
      
      // Get latest subscription data from backend
      final latestData = await _getSubscriptionStatus(_currentSubscription!.customerId!);
      
      if (latestData != null) {
        await updateSubscription(latestData);
        debugPrint('✅ [SubscriptionService] Subscription status refreshed');
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error refreshing subscription: $e');
      // Don't rethrow - this is a background refresh
    } finally {
      _setLoading(false);
    }
  }

  /// Create subscription intent on backend
  Future<Map<String, dynamic>> _createSubscriptionIntent({
    required SubscriptionTier tier,
    String? customerId,
  }) async {
    // TODO: Replace with your actual backend endpoint
    const backendUrl = 'https://your-backend.com/api/subscription/create-intent';
    
    // FIXED: Properly await the getCurrentUser() call
    final currentUser = await UserService.instance.getCurrentUser();
    
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tier': tier.id,
        'customer_id': customerId,
        'user_id': currentUser?.id,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create subscription intent: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// Cancel subscription on backend
  Future<void> _cancelSubscriptionOnBackend({
    required String subscriptionId,
    required bool immediate,
  }) async {
    // TODO: Replace with your actual backend endpoint
    const backendUrl = 'https://your-backend.com/api/subscription/cancel';
    
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subscription_id': subscriptionId,
        'immediate': immediate,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel subscription: ${response.body}');
    }
  }

  /// Pause subscription on backend
  Future<void> _pauseSubscriptionOnBackend(String subscriptionId) async {
    // TODO: Replace with your actual backend endpoint
    const backendUrl = 'https://your-backend.com/api/subscription/pause';
    
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subscription_id': subscriptionId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to pause subscription: ${response.body}');
    }
  }

  /// Resume subscription on backend
  Future<void> _resumeSubscriptionOnBackend(String subscriptionId) async {
    // TODO: Replace with your actual backend endpoint
    const backendUrl = 'https://your-backend.com/api/subscription/resume';
    
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subscription_id': subscriptionId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resume subscription: ${response.body}');
    }
  }

  /// Get subscription status from backend
  Future<SubscriptionData?> _getSubscriptionStatus(String customerId) async {
    // TODO: Replace with your actual backend endpoint
    final backendUrl = 'https://your-backend.com/api/subscription/status/$customerId';
    
    final response = await http.get(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SubscriptionData.fromJson(data);
    } else if (response.statusCode == 404) {
      // No subscription found
      return SubscriptionData.empty();
    } else {
      throw Exception('Failed to get subscription status: ${response.body}');
    }
  }

  /// Start periodic sync for authenticated users
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    
    if (FirebaseUserService.instance.isLoggedIn) {
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        refreshSubscriptionStatus();
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