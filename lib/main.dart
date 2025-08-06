// lib/main.dart - UPDATED: Fixed URL parameter handling for GitLab Pages deployment

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:html' as html show window;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'services/firebase_config.dart';
import 'services/stripe_config.dart';
import 'models/app_state.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/audio_controller.dart';
import 'services/firebase_user_service.dart';
import 'services/user_service.dart';
import 'services/subscription_service.dart';
import 'views/pages/login_page.dart';
import 'views/pages/subscription_management_page.dart';
import 'views/pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeStripe();
  runApp(const TheorieApp());
}

Future<void> _initializeStripe() async {
  try {
    debugPrint('🔄 [Stripe] Initializing Stripe with environment variables...');
    await StripeConfig.initialize();
    if (kDebugMode) {
      final info = StripeConfig.getEnvironmentInfo();
      debugPrint('✅ [Stripe] Configuration: $info');
    }
  } catch (e) {
    debugPrint('❌ [Stripe] Error initializing Stripe: $e');
  }
}

class TheorieApp extends StatelessWidget {
  const TheorieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theorie',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      // UPDATED: Simplified routing - always start at home
      home: const FirebaseInitializer(),
      // Remove complex routing logic, handle in FirebaseInitializer
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.light,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
    );
  }
}

/// UPDATED: Firebase initializer with Stripe redirect handling
class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  bool _initialized = false;
  bool _error = false;
  String? _errorMessage;
  bool _isRetrying = false;
  Map<String, String>? _stripeParams;

  @override
  void initState() {
    super.initState();
    _checkForStripeParams();
    _initializeFirebase();
  }

  /// UPDATED: Check for Stripe parameters in URL
  void _checkForStripeParams() {
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      final checkoutStatus = uri.queryParameters['checkout_status'];
      final sessionId = uri.queryParameters['session_id'];
      
      if (checkoutStatus != null || sessionId != null) {
        debugPrint('🔄 [Firebase] Detected Stripe redirect parameters');
        debugPrint('📋 [Firebase] Checkout status: $checkoutStatus');
        debugPrint('📋 [Firebase] Session ID: $sessionId');
        
        _stripeParams = {
          if (checkoutStatus != null) 'checkout_status': checkoutStatus,
          if (sessionId != null) 'session_id': sessionId,
        };
        
        // Clean URL immediately to prevent issues with navigation
        _cleanUrl();
      }
    }
  }

  /// Clean URL by removing query parameters
  void _cleanUrl() {
    if (kIsWeb) {
      final cleanUrl = '${html.window.location.origin}${html.window.location.pathname}';
      html.window.history.replaceState(null, '', cleanUrl);
      debugPrint('🧹 [Firebase] URL cleaned after parameter extraction');
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      debugPrint('🔄 [Firebase] Initializing Firebase with environment variables...');

      await FirebaseConfig.initialize();

      if (kIsWeb) {
        await _configureFirebaseForWeb();
      }

      await _initializeCoreServices();

      if (kDebugMode) {
        AppConfig.logConfiguration();
      }

      if (mounted) {
        setState(() {
          _initialized = true;
          _error = false;
          _errorMessage = null;
        });
      }

      debugPrint('✅ [Firebase] Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ [Firebase] Firebase initialization error: $e');

      if (mounted) {
        setState(() {
          _error = true;
          _errorMessage = e.toString();
          _initialized = false;
        });
      }
    }
  }

  Future<void> _configureFirebaseForWeb() async {
    try {
      await firebase_auth.FirebaseAuth.instance.setPersistence(
          firebase_auth.Persistence.LOCAL);
      await FirebaseFirestore.instance
          .enablePersistence(const PersistenceSettings(synchronizeTabs: true));
      debugPrint('✅ [Firebase] Web configuration completed');
    } catch (e) {
      debugPrint('ℹ️ [Firebase] Web configuration note: $e');
    }
  }

  Future<void> _initializeCoreServices() async {
    try {
      debugPrint('🔄 [Services] Initializing core services...');
      await FirebaseUserService.instance.initialize();
      debugPrint('✅ [Services] Firebase user service initialized');
      await UserService.instance.initialize();
      debugPrint('✅ [Services] User service initialized');
      if (!SubscriptionService.instance.isInitialized) {
        await SubscriptionService.instance.initialize();
        debugPrint('✅ [Services] Subscription service initialized');
      } else {
        debugPrint('ℹ️ [Services] Subscription service already initialized');
      }
      debugPrint('✅ [Services] All core services initialized successfully');
    } catch (e) {
      debugPrint('⚠️ [Services] Service initialization warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _buildErrorScreen();
    }

    if (!_initialized) {
      return _buildLoadingScreen();
    }

    // UPDATED: Pass Stripe parameters to MainApp
    return MainApp(stripeParams: _stripeParams);
  }

  Widget _buildErrorScreen() {
    return MaterialApp(
      title: 'Theorie',
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to initialize Theorie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'There was a problem connecting to our services. Please check your internet connection and try again.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _retryInitialization,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isRetrying ? 'Retrying...' : 'Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return MaterialApp(
      title: 'Theorie',
      home: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 64,
                color: Colors.indigo.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Theorie',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading your music theory workspace...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Environment: ${AppConfig.environment}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.indigo.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retryInitialization() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    await _initializeFirebase();

    if (mounted) {
      setState(() {
        _isRetrying = false;
      });
    }
  }
}

/// UPDATED: Main application with Stripe parameter handling
class MainApp extends StatelessWidget {
  final Map<String, String>? stripeParams;
  
  const MainApp({super.key, this.stripeParams});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => QuizController()),
        ChangeNotifierProvider.value(
          value: SubscriptionService.instance,
        ),
        StreamProvider<firebase_auth.User?>(
          create: (_) => FirebaseUserService.instance.authStateChanges,
          initialData: null,
        ),
      ],
      child: AppLifecycleManager(
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            return MaterialApp(
              title: 'Theorie',
              debugShowCheckedModeBanner: false,
              themeMode: appState.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.indigo,
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.indigo,
                brightness: Brightness.dark,
              ),
              builder: (context, child) {
                if (kDebugMode && !AppConfig.isProduction) {
                  return Stack(
                    children: [
                      child!,
                      Positioned(
                        top: 40,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConfig.isDevelopment ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppConfig.environment.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return child!;
              },
              // UPDATED: Pass Stripe parameters to AuthWrapper
              home: AuthWrapper(stripeParams: stripeParams),
            );
          },
        ),
      ),
    );
  }
}

/// UPDATED: App lifecycle manager (unchanged)
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudioSystem();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioController.instance.dispose();
    super.dispose();
  }

  Future<void> _initializeAudioSystem() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = this.context;
        if (context.mounted) {
          final appState = context.read<AppState>();
          await AudioController.instance.initialize(appState.audioBackend);
          await AudioController.instance.setVolume(appState.audioVolume);
          debugPrint('✅ [Audio] Audio system initialized successfully');
        }
      });
    } catch (e) {
      debugPrint('❌ [Audio] Failed to initialize audio system: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('🔄 [Lifecycle] App resumed');
        if (SubscriptionService.instance.isInitialized) {
          SubscriptionService.instance.refreshSubscriptionStatus();
        }
        AudioController.instance.onAppResume();
        break;
      case AppLifecycleState.paused:
        debugPrint('⏸️ [Lifecycle] App paused');
        AudioController.instance.onAppPause();
        break;
      case AppLifecycleState.detached:
        debugPrint('🔌 [Lifecycle] App detached');
        AudioController.instance.dispose();
        break;
      case AppLifecycleState.inactive:
        debugPrint('😴 [Lifecycle] App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('🙈 [Lifecycle] App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// UPDATED: Authentication wrapper with Stripe redirect handling
class AuthWrapper extends StatefulWidget {
  final Map<String, String>? stripeParams;
  
  const AuthWrapper({super.key, this.stripeParams});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _loadingAttempts = 0;
  static const int _maxLoadingAttempts = 3;
  bool _shouldShowSubscriptionPage = false;

  @override
  void initState() {
    super.initState();
    _checkForStripeRedirect();
    _initializeAuth();
  }

  /// UPDATED: Check if we should show subscription page based on Stripe params
  void _checkForStripeRedirect() {
    if (widget.stripeParams != null) {
      debugPrint('🔄 [Auth] Processing Stripe redirect with params: ${widget.stripeParams}');
      _shouldShowSubscriptionPage = true;
    }
  }

  Future<void> _initializeAuth() async {
    try {
      debugPrint('🔄 [Auth] Initializing auth wrapper...');
      _loadingAttempts++;

      final currentUser = await FirebaseUserService.instance.getCurrentUser();
      debugPrint('ℹ️ [Auth] Current user: ${currentUser?.username ?? 'None'}');

      if (mounted && currentUser != null) {
        final appState = context.read<AppState>();
        await appState.setCurrentUser(currentUser);
        debugPrint('✅ [Auth] App state updated with user: ${currentUser.username}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Auth] Error initializing auth: $e');

      if (mounted) {
        if (_loadingAttempts >= _maxLoadingAttempts) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = e.toString();
          });
        } else {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            _initializeAuth();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Setting up your session... (${_loadingAttempts}/$_maxLoadingAttempts)'),
              if (_loadingAttempts > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'This is taking longer than expected...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Text(
                  'Environment: ${AppConfig.environment}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication Setup Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _loadingAttempts = 0;
                  });
                  _initializeAuth();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('Continue to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<firebase_auth.User?>(
      builder: (context, firebaseUser, child) {
        return Consumer<AppState>(
          builder: (context, appState, child) {
            final currentUser = appState.currentUser;

            debugPrint('ℹ️ [Auth] Auth state - Firebase: ${firebaseUser?.uid}, App: ${currentUser?.username}');

            // UPDATED: If we have Stripe params and a user, show subscription page
            if (_shouldShowSubscriptionPage && currentUser != null) {
              debugPrint('🔄 [Auth] Showing subscription page with Stripe params');
              return SubscriptionManagementPage(stripeParams: widget.stripeParams);
            }

            if (currentUser != null) {
              return const WelcomePage();
            }

            if (firebaseUser != null && currentUser == null) {
              return FutureBuilder<void>(
                future: _loadFirebaseUser(firebaseUser),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading user data...'),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            const Text('Failed to load user data'),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const LoginPage();
                  }
                },
              );
            }

            return const LoginPage();
          },
        );
      },
    );
  }

  Future<void> _loadFirebaseUser(firebase_auth.User firebaseUser) async {
    try {
      debugPrint('🔄 [Auth] Loading Firebase user data for: ${firebaseUser.uid}');

      final userService = FirebaseUserService.instance;
      final appUser = await userService.getCurrentUser();

      if (appUser != null && mounted) {
        debugPrint('✅ [Auth] User data loaded successfully: ${appUser.username}');

        final appState = context.read<AppState>();
        await appState.setCurrentUser(appUser);

        if (SubscriptionService.instance.isInitialized) {
          SubscriptionService.instance.refreshSubscriptionStatus();
        }

        debugPrint('✅ [Auth] User successfully loaded and services initialized');
      } else {
        debugPrint('⚠️ [Auth] No app user data found for Firebase user: ${firebaseUser.uid}');

        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'User data not found in database. Please try registering again.';
          });
        }

        try {
          await FirebaseUserService.instance.logout();
          debugPrint('ℹ️ [Auth] Signed out user due to missing data');
        } catch (signOutError) {
          debugPrint('❌ [Auth] Error signing out after load failure: $signOutError');
        }
      }
    } catch (e) {
      debugPrint('❌ [Auth] Error loading Firebase user: $e');

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load user data: ${e.toString()}';
        });
      }

      try {
        await FirebaseUserService.instance.logout();
        debugPrint('ℹ️ [Auth] Signed out user due to loading error');
      } catch (signOutError) {
        debugPrint('❌ [Auth] Error signing out after load failure: $signOutError');
      }
    }
  }
}