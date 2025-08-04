// lib/main.dart - Fixed with proper subscription service integration and loop prevention
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'models/app_state.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/audio_controller.dart';
import 'services/firebase_user_service.dart';
import 'services/user_service.dart';
import 'services/subscription_service.dart';
import 'views/pages/login_page.dart';
import 'views/pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe first
  await _initializeStripe();

  runApp(const TheorieApp());
}

/// Initialize Stripe with proper error handling
Future<void> _initializeStripe() async {
  try {
    // TODO: Replace with your actual Stripe publishable key
    const stripePublishableKey = kDebugMode 
        ? 'pk_test_51Rs7HVILJ0OoLUiBc8PBRibh5acqX5EI2cI7D7Au1us6UcSZzF01hDXn9jo7F0Tv0x8B0V4ydH9pzcSGDqpQGYwg00tQapSRq4'
        : 'pk_live_your_live_key_here';
    
    Stripe.publishableKey = stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.yourcompany.theorie';
    Stripe.urlScheme = 'flutterstripe';
    
    debugPrint('✅ [Stripe] Stripe initialized successfully');
  } catch (e) {
    debugPrint('❌ [Stripe] Error initializing Stripe: $e');
    // Continue without Stripe - app should still work for non-payment features
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
      home: const FirebaseInitializer(),
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

/// Firebase initialization wrapper with enhanced error handling
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

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      debugPrint('🔄 [Firebase] Initializing Firebase...');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firebase for web platform
      if (kIsWeb) {
        await _configureFirebaseForWeb();
      }

      // Initialize core services in proper order
      await _initializeCoreServices();

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
      // Set authentication persistence for web
      await firebase_auth.FirebaseAuth.instance.setPersistence(
          firebase_auth.Persistence.LOCAL);

      // Enable Firestore offline persistence for web
      await FirebaseFirestore.instance
          .enablePersistence(const PersistenceSettings(synchronizeTabs: true));

      debugPrint('✅ [Firebase] Web configuration completed');
    } catch (e) {
      // Persistence might already be enabled, or not supported
      debugPrint('ℹ️ [Firebase] Web configuration note: $e');
      // Don't throw error for persistence issues - they're not critical
    }
  }

  /// Initialize core services in proper order to prevent loops
  Future<void> _initializeCoreServices() async {
    try {
      debugPrint('🔄 [Services] Initializing core services...');

      // 1. Initialize Firebase user service first
      await FirebaseUserService.instance.initialize();
      debugPrint('✅ [Services] Firebase user service initialized');

      // 2. Initialize fallback user service
      await UserService.instance.initialize();
      debugPrint('✅ [Services] User service initialized');

      // 3. Initialize subscription service - FIXED: Only initialize once
      if (!SubscriptionService.instance.isInitialized) {
        await SubscriptionService.instance.initialize();
        debugPrint('✅ [Services] Subscription service initialized');
      } else {
        debugPrint('ℹ️ [Services] Subscription service already initialized');
      }

      debugPrint('✅ [Services] All core services initialized successfully');
    } catch (e) {
      debugPrint('⚠️ [Services] Service initialization warning: $e');
      // Continue with app initialization even if services have issues
      // The services have their own fallback mechanisms
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

    return const MainApp();
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

/// Main application with providers - FIXED: Proper subscription service integration
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core app state provider
        ChangeNotifierProvider(create: (_) => AppState()),

        // Quiz controller provider
        ChangeNotifierProvider(create: (_) => QuizController()),

        // FIXED: Use singleton instance to prevent recreation
        ChangeNotifierProvider.value(
          value: SubscriptionService.instance,
        ),

        // Firebase auth state stream provider
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
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}

/// App lifecycle manager with enhanced audio and subscription management
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
      // Wait for app state to be available
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = this.context;
        if (context.mounted) {
          final appState = context.read<AppState>();
          
          // Initialize audio system with user preferences
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
        // FIXED: Only refresh if service is properly initialized
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

/// Authentication wrapper with enhanced error handling and fixed Firebase loading
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _loadingAttempts = 0;
  static const int _maxLoadingAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      debugPrint('🔄 [Auth] Initializing auth wrapper...');
      _loadingAttempts++;

      // Check for existing user session
      final currentUser = await FirebaseUserService.instance.getCurrentUser();
      debugPrint('ℹ️ [Auth] Current user: ${currentUser?.username ?? 'None'}');

      // Update app state with current user
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
        // If we've tried multiple times and still failing, show error
        if (_loadingAttempts >= _maxLoadingAttempts) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = e.toString();
          });
        } else {
          // Try again after a short delay
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
    // Show loading screen during auth initialization
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
            ],
          ),
        ),
      );
    }

    // Show error screen if auth initialization failed
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

    // Listen to Firebase auth state changes
    return Consumer<firebase_auth.User?>(
      builder: (context, firebaseUser, child) {
        return Consumer<AppState>(
          builder: (context, appState, child) {
            final currentUser = appState.currentUser;

            debugPrint('ℹ️ [Auth] Auth state - Firebase: ${firebaseUser?.uid}, App: ${currentUser?.username}');

            // If we have a current user (either Firebase or guest), show welcome page
            if (currentUser != null) {
              return const WelcomePage();
            }

            // If Firebase user exists but no app user, load the user data
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
                              onPressed: () => setState(() {}), // Retry
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Loading completed, but still no user - show login
                    return const LoginPage();
                  }
                },
              );
            }

            // No user logged in, show login page
            return const LoginPage();
          },
        );
      },
    );
  }

  /// FIXED: Load Firebase user with proper error handling and subscription initialization
  Future<void> _loadFirebaseUser(firebase_auth.User firebaseUser) async {
    try {
      debugPrint('🔄 [Auth] Loading Firebase user data for: ${firebaseUser.uid}');

      // Use FirebaseUserService directly for better integration
      final userService = FirebaseUserService.instance;
      final appUser = await userService.getCurrentUser();

      if (appUser != null && mounted) {
        debugPrint('✅ [Auth] User data loaded successfully: ${appUser.username}');

        // Set user in AppState which will trigger proper progress loading
        final appState = context.read<AppState>();
        await appState.setCurrentUser(appUser);

        // FIXED: Initialize subscription service for this user if not already done
        // This handles the case where users don't have subscription data yet
        if (SubscriptionService.instance.isInitialized) {
          // Just refresh the status, don't re-initialize
          SubscriptionService.instance.refreshSubscriptionStatus();
        }

        debugPrint('✅ [Auth] User successfully loaded and services initialized');
      } else {
        debugPrint('⚠️ [Auth] No app user data found for Firebase user: ${firebaseUser.uid}');

        // If user exists in Firebase but not in Firestore, sign them out
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

      // Update UI state to show error instead of infinite loading
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load user data: ${e.toString()}';
        });
      }

      // If there's an issue loading the user, sign them out
      try {
        await FirebaseUserService.instance.logout();
        debugPrint('ℹ️ [Auth] Signed out user due to loading error');
      } catch (signOutError) {
        debugPrint('❌ [Auth] Error signing out after load failure: $signOutError');
      }
    }
  }
}