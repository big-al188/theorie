// lib/models/subscription/payment_models.dart
import 'package:flutter_stripe/flutter_stripe.dart';

/// Custom subscription payment data model that wraps Stripe's built-in types
/// This avoids naming conflicts with Stripe's PaymentMethodData
class SubscriptionPaymentData {
  final String paymentMethodId;
  final BillingDetails billingDetails;

  SubscriptionPaymentData({
    required this.paymentMethodId,
    required this.billingDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentMethodId': paymentMethodId,
      'billingDetails': {
        'name': billingDetails.name,
        'email': billingDetails.email,
        'phone': billingDetails.phone,
        'address': billingDetails.address != null ? {
          'line1': billingDetails.address!.line1,
          'line2': billingDetails.address!.line2,
          'city': billingDetails.address!.city,
          'state': billingDetails.address!.state,
          'postalCode': billingDetails.address!.postalCode,
          'country': billingDetails.address!.country,
        } : null,
      },
    };
  }

  @override
  String toString() {
    return 'SubscriptionPaymentData(paymentMethodId: $paymentMethodId, billingDetails: $billingDetails)';
  }
}