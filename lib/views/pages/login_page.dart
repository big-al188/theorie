// lib/views/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/user_service.dart';
import '../../constants/ui_constants.dart';
import 'welcome_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameEmailController = TextEditingController(); // For login (username OR email)
  final _usernameController = TextEditingController(); // For registration username
  final _emailController = TextEditingController(); // For registration email
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameEmailController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: _getHorizontalPadding(deviceType, isLandscape),
                vertical: _getVerticalPadding(deviceType, isLandscape),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - _getVerticalPadding(deviceType, isLandscape) * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(deviceType, isLandscape),
                    SizedBox(height: isLandscape ? 24 : 48),
                    _buildLoginForm(deviceType),
                    SizedBox(height: isLandscape ? 16 : 32),
                    _buildGuestLoginButton(deviceType),
                    SizedBox(height: isLandscape ? 16 : 24),
                    _buildToggleButton(deviceType),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getHorizontalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 32.0; // More padding in landscape
    }
    return deviceType == DeviceType.mobile ? 24.0 : 48.0;
  }

  double _getVerticalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0; // Less vertical padding in landscape
    }
    return deviceType == DeviceType.mobile ? 24.0 : 48.0;
  }

  Widget _buildHeader(DeviceType deviceType, bool isLandscape) {
    final titleFontSize = isLandscape
        ? (deviceType == DeviceType.mobile ? 28.0 : 36.0)
        : (deviceType == DeviceType.mobile ? 32.0 : 48.0);
    
    final subtitleFontSize = isLandscape
        ? (deviceType == DeviceType.mobile ? 14.0 : 16.0)
        : (deviceType == DeviceType.mobile ? 16.0 : 18.0);

    return Column(
      children: [
        Icon(
          Icons.music_note,
          size: isLandscape ? 60 : 80,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: isLandscape ? 16 : 24),
        Text(
          'Theorie',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isLandscape ? 8 : 16),
        Text(
          'Learn Music Theory & Guitar Fretboard',
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(DeviceType deviceType) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 400.0,
        ),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLogin ? 'Sign In' : 'Create Account',
                    style: TextStyle(
                      fontSize: deviceType == DeviceType.mobile ? 20.0 : 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Login: Single field for username OR email
                  if (_isLogin) ...[
                    _buildTextField(
                      controller: _usernameEmailController,
                      label: 'Username or Email',
                      icon: Icons.person,
                      required: false, // Optional for login (can use guest)
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Registration: Separate fields for username and email
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Password field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password (coming soon)',
                    icon: Icons.lock,
                    obscureText: _obscurePassword,
                    required: false, // Not required yet
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Auth button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isLogin ? 'Sign In' : 'Create Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info text about password
                  Text(
                    'Note: Password authentication will be added in a future update. For now, leave password empty.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool required = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: required ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        if (label.contains('Email') && !_isValidEmail(value)) {
          return 'Please enter a valid email';
        }
        if (label == 'Username or Email' && value.isNotEmpty) {
          // For combined field, check if it's a valid email OR username
          if (value.contains('@') && !_isValidEmail(value)) {
            return 'Please enter a valid email or username';
          }
        }
        return null;
      } : null,
    );
  }

  Widget _buildGuestLoginButton(DeviceType deviceType) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 400.0,
        ),
        child: OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleGuestLogin,
          icon: const Icon(Icons.login),
          label: const Text('Continue as Guest'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            side: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(DeviceType deviceType) {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          // Clear form when switching modes
          _usernameEmailController.clear();
          _usernameController.clear();
          _emailController.clear();
          _passwordController.clear();
        });
      },
      child: Text(
        _isLogin 
            ? "Don't have an account? Create one"
            : "Already have an account? Sign in",
        style: TextStyle(
          fontSize: deviceType == DeviceType.mobile ? 14.0 : 16.0,
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Login: Use combined username/email field
        final usernameOrEmail = _usernameEmailController.text.trim();
        
        if (usernameOrEmail.isEmpty) {
          _showError('Please enter your username or email to sign in.');
          return;
        }
        
        // Determine if input is email or username
        final isEmail = usernameOrEmail.contains('@');
        
        final user = await UserService.instance.loginUser(
          username: isEmail ? null : usernameOrEmail,
          email: isEmail ? usernameOrEmail : null,
        );
        
        if (user == null) {
          _showError('User not found. Please check your credentials or create an account.');
          return;
        }
        
        await _loginSuccess(user);
      } else {
        // Registration: Use separate username and email fields
        final username = _usernameController.text.trim();
        final email = _emailController.text.trim();
        
        if (username.isEmpty || email.isEmpty) {
          _showError('Username and email are required for registration.');
          return;
        }
        
        final user = await UserService.instance.registerUser(
          username: username,
          email: email,
        );
        
        await _loginSuccess(user);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('UserServiceException: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the explicit guest login method for clarity
      final user = await UserService.instance.loginAsGuest();
      await _loginSuccess(user);
    } catch (e) {
      _showError('Failed to sign in as guest. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginSuccess(user) async {
    // Update app state with user
    final appState = context.read<AppState>();
    await appState.setCurrentUser(user);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}