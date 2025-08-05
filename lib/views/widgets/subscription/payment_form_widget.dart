// lib/widgets/subscription/payment_form_widget.dart - Simple Platform Fix
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../models/subscription/subscription_models.dart';
import '../../../models/subscription/payment_models.dart';
import '../../../constants/ui_constants.dart';

class PaymentFormWidget extends StatefulWidget {
  final SubscriptionTier tier;
  final String userEmail;
  final String userName;
  final Function(SubscriptionPaymentData paymentMethodData) onPaymentSubmitted;
  final VoidCallback onCancel;

  const PaymentFormWidget({
    super.key,
    required this.tier,
    required this.userEmail,
    required this.userName,
    required this.onPaymentSubmitted,
    required this.onCancel,
  });

  @override
  State<PaymentFormWidget> createState() => _PaymentFormWidgetState();
}

class _PaymentFormWidgetState extends State<PaymentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  CardEditController? _cardController;
  
  // Billing address controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isProcessing = false;
  bool _cardComplete = false;
  String? _cardError;

  // Platform detection
  bool get _isWeb => kIsWeb;
  bool get _canUseCardField => !_isWeb;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill user information
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    _countryController.text = 'US';
    
    // Only initialize CardController on supported platforms
    if (_canUseCardField) {
      try {
        _cardController = CardEditController();
        _cardController!.addListener(_onCardChanged);
      } catch (e) {
        debugPrint('Failed to initialize CardEditController: $e');
        // CardField not available, will use alternative approach
      }
    }
  }

  @override
  void dispose() {
    _cardController?.removeListener(_onCardChanged);
    _cardController?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _onCardChanged() {
    if (_cardController != null) {
      setState(() {
        _cardComplete = _cardController!.complete;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: Colors.blue.shade600,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscribe to ${widget.tier.displayName}',
                            style: TextStyle(
                              fontSize: deviceType == DeviceType.mobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${widget.tier.price}/${widget.tier == SubscriptionTier.premiumAnnual ? 'year' : 'month'}',
                            style: TextStyle(
                              fontSize: deviceType == DeviceType.mobile ? 14 : 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                
                // 7-day trial notice
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Start your 7-day free trial. Cancel anytime.',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20 + keyboardHeight,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Information Section
                    _buildSectionHeader('Payment Information', Icons.credit_card),
                    const SizedBox(height: 16),
                    
                    // Platform-specific card input
                    if (_canUseCardField && _cardController != null) ...[
                      // Native CardField for mobile
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _cardError != null ? Colors.red : Colors.grey.shade300,
                            width: _cardError != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CardField(
                          controller: _cardController!,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: false,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Web fallback - show message and redirect to Stripe
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.web,
                              color: Colors.blue.shade600,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Web Payment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'For web payments, you\'ll be redirected to a secure Stripe checkout page to complete your subscription.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (_cardError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _cardError!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Billing Information Section
                    _buildSectionHeader('Billing Information', Icons.location_on),
                    const SizedBox(height: 16),
                    
                    // Name and Email Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                return 'Invalid email format';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address Line 1
                    _buildTextField(
                      controller: _addressLine1Controller,
                      label: 'Address Line 1',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address Line 2 (Optional)
                    _buildTextField(
                      controller: _addressLine2Controller,
                      label: 'Address Line 2 (Optional)',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // City, State, Postal Code Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'City is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State',
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'State is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _postalCodeController,
                            label: 'ZIP Code',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'ZIP is required';
                              }
                              if (value!.length < 5) {
                                return 'Invalid ZIP';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Country
                    _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Country is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing || (_canUseCardField && !_cardComplete) ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isWeb ? 'Continue to Secure Checkout' : 'Start 7-Day Free Trial',
                                style: TextStyle(
                                  fontSize: deviceType == DeviceType.mobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Security notice
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isWeb 
                                ? 'You\'ll be redirected to Stripe\'s secure payment page'
                                : 'Your payment information is encrypted and secure',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For web, we need a different approach since CardField doesn't work
    if (_isWeb) {
      await _handleWebPayment();
      return;
    }

    // For mobile with CardField
    if (!_cardComplete) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Create billing details using Stripe's built-in types
      final billingDetails = BillingDetails(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: Address(
          line1: _addressLine1Controller.text.trim(),
          line2: _addressLine2Controller.text.trim().isEmpty 
              ? null 
              : _addressLine2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
        ),
      );

      // Create payment method using Stripe's built-in API
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      // Return payment method data using our custom wrapper
      widget.onPaymentSubmitted(SubscriptionPaymentData(
        paymentMethodId: paymentMethod.id,
        billingDetails: billingDetails,
      ));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Payment method creation failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleWebPayment() async {
    setState(() => _isProcessing = true);

    try {
      // For web, we create billing details and let the backend handle Stripe Checkout
      final billingDetails = BillingDetails(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: Address(
          line1: _addressLine1Controller.text.trim(),
          line2: _addressLine2Controller.text.trim().isEmpty 
              ? null 
              : _addressLine2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
        ),
      );

      // For web, we pass null paymentMethodId to trigger the Checkout flow
      widget.onPaymentSubmitted(SubscriptionPaymentData(
        paymentMethodId: '', // Empty string indicates web checkout flow
        billingDetails: billingDetails,
      ));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}