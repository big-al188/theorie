// lib/models/subscription/subscription_models.dart - Fixed null safety issues

/// Subscription status enumeration
enum SubscriptionStatus {
  none('none', 'No Subscription'),
  active('active', 'Active'),
  canceled('canceled', 'Canceled'),
  pastDue('past_due', 'Past Due'),
  paused('paused', 'Paused'),
  trialing('trialing', 'Free Trial'),
  incomplete('incomplete', 'Incomplete'),
  unpaid('unpaid', 'Unpaid');

  const SubscriptionStatus(this.value, this.displayName);
  
  final String value;
  final String displayName;

  bool get isActive => this == SubscriptionStatus.active || this == SubscriptionStatus.trialing;
  bool get hasAccess => isActive;
  bool get needsPaymentUpdate => this == SubscriptionStatus.pastDue || this == SubscriptionStatus.incomplete;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.none,
    );
  }
}

/// Subscription tier enumeration
enum SubscriptionTier {
  free('free', 'Free', 0.0),
  premium('premium', 'Premium', 9.99),
  premiumAnnual('premium_annual', 'Premium Annual', 99.99);

  const SubscriptionTier(this.id, this.displayName, this.price);
  
  final String id;
  final String displayName;
  final double price;

  static SubscriptionTier fromString(String id) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.id == id,
      orElse: () => SubscriptionTier.free,
    );
  }
}

/// Subscription data model
class SubscriptionData {
  final SubscriptionStatus status;
  final SubscriptionTier tier;
  final String? subscriptionId;
  final String? customerId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final String? cancelAtPeriodEnd;
  final DateTime? canceledAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionData({
    required this.status,
    required this.tier,
    this.subscriptionId,
    this.customerId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEnd,
    this.cancelAtPeriodEnd,
    this.canceledAt,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty subscription data
  factory SubscriptionData.empty() {
    final now = DateTime.now();
    return SubscriptionData(
      status: SubscriptionStatus.none,
      tier: SubscriptionTier.free,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create subscription data from JSON
  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      status: SubscriptionStatus.fromString(json['status'] ?? 'none'),
      tier: SubscriptionTier.fromString(json['tier'] ?? 'free'),
      subscriptionId: json['subscription_id'],
      customerId: json['customer_id'],
      currentPeriodStart: json['current_period_start'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['current_period_start'] * 1000)
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['current_period_end'] * 1000)
          : null,
      trialEnd: json['trial_end'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['trial_end'] * 1000)
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'],
      canceledAt: json['canceled_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['canceled_at'] * 1000)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] * 1000)
          : DateTime.now(),
    );
  }

  /// Convert to JSON - FIXED: Handle nullable millisecondsSinceEpoch properly
  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'tier': tier.id,
      'subscription_id': subscriptionId,
      'customer_id': customerId,
      'current_period_start': currentPeriodStart != null 
          ? (currentPeriodStart!.millisecondsSinceEpoch ~/ 1000)
          : null,
      'current_period_end': currentPeriodEnd != null
          ? (currentPeriodEnd!.millisecondsSinceEpoch ~/ 1000)
          : null,
      'trial_end': trialEnd != null
          ? (trialEnd!.millisecondsSinceEpoch ~/ 1000)
          : null,
      'cancel_at_period_end': cancelAtPeriodEnd,
      'canceled_at': canceledAt != null
          ? (canceledAt!.millisecondsSinceEpoch ~/ 1000)
          : null,
      'metadata': metadata,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Copy with method for immutable updates
  SubscriptionData copyWith({
    SubscriptionStatus? status,
    SubscriptionTier? tier,
    String? subscriptionId,
    String? customerId,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? trialEnd,
    String? cancelAtPeriodEnd,
    DateTime? canceledAt,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return SubscriptionData(
      status: status ?? this.status,
      tier: tier ?? this.tier,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      customerId: customerId ?? this.customerId,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      trialEnd: trialEnd ?? this.trialEnd,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      canceledAt: canceledAt ?? this.canceledAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if subscription has access to premium features
  bool get hasAccess => status.hasAccess;

  /// Check if subscription needs payment update
  bool get needsPaymentUpdate => status.needsPaymentUpdate;

  /// Get days until subscription ends
  int? get daysUntilEnd {
    if (currentPeriodEnd == null) return null;
    final difference = currentPeriodEnd!.difference(DateTime.now());
    return difference.inDays;
  }

  /// Get formatted period end date
  String get formattedPeriodEnd {
    if (currentPeriodEnd == null) return 'N/A';
    return '${currentPeriodEnd!.day}/${currentPeriodEnd!.month}/${currentPeriodEnd!.year}';
  }

  /// Get user-friendly status description
  String get statusDescription {
    switch (status) {
      case SubscriptionStatus.none:
        return 'No active subscription';
      case SubscriptionStatus.active:
        return 'Subscription is active and billing normally';
      case SubscriptionStatus.canceled:
        return 'Subscription canceled - access until period end';
      case SubscriptionStatus.pastDue:
        return 'Payment failed - please update payment method';
      case SubscriptionStatus.paused:
        return 'Subscription is paused';
      case SubscriptionStatus.trialing:
        return 'Free trial active';
      case SubscriptionStatus.incomplete:
        return 'Payment incomplete - action required';
      case SubscriptionStatus.unpaid:
        return 'Payment overdue - access restricted';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionData &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          tier == other.tier &&
          subscriptionId == other.subscriptionId &&
          customerId == other.customerId;

  @override
  int get hashCode =>
      status.hashCode ^
      tier.hashCode ^
      subscriptionId.hashCode ^
      customerId.hashCode;

  @override
  String toString() {
    return 'SubscriptionData(status: $status, tier: $tier, subscriptionId: $subscriptionId)';
  }
}