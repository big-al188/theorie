// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/app_state.dart';
import 'controllers/quiz_controller.dart';
import 'services/firebase_user_service.dart';
import 'services/user_service.dart';
import 'views/pages/login_page.dart';
import 'views/pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TheorieApp());
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

  /// Build light theme with simplified theming
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.light,
    );
  }

  /// Build dark theme with simplified theming
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
    );
  }
}

/// Production-ready Firebase initialization wrapper with loading states
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
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firebase for web platform
      if (kIsWeb) {
        await _configureFirebaseForWeb();
      }

      // Initialize services
      await _initializeServices();

      if (mounted) {
        setState(() {
          _initialized = true;
          _error = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Firebase initialization error: $e');

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
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      // Enable Firestore offline persistence for web
      await FirebaseFirestore.instance
          .enablePersistence(const PersistenceSettings(synchronizeTabs: true));

      print('Firebase web configuration completed');
    } catch (e) {
      // Persistence might already be enabled, or not supported
      print('Firebase web configuration note: $e');
      // Don't throw error for persistence issues - they're not critical
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Firebase user service
      await FirebaseUserService.instance.initialize();

      // Initialize fallback user service
      await UserService.instance.initialize();

      print('Services initialized successfully');
    } catch (e) {
      print('Service initialization warning: $e');
      // Continue with app initialization even if services have issues
      // The services have their own fallback mechanisms
    }
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

  @override
  Widget build(BuildContext context) {
    // Show error screen with retry option
    if (_error) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                Text(
                  'Failed to initialize Theorie',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'There was a problem connecting to our services. Please check your internet connection and try again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
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
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const OfflineModeApp(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.wifi_off),
                  label: const Text('Continue Offline'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  ExpansionTile(
                    title: const Text('Error Details'),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _errorMessage ?? 'Unknown error',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Show loading screen during initialization
    if (!_initialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Theorie',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your music theory workspace...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Firebase initialized successfully - show main app
    return const MainApp();
  }
}

/// Main application with all providers and authentication
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

        // Firebase auth state stream provider
        StreamProvider<User?>(
          create: (_) => FirebaseUserService.instance.authStateChanges,
          initialData: null,
        ),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Theorie',
            debugShowCheckedModeBanner: false,

            // Theme configuration
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
    );
  }
}

/// Authentication wrapper with Firebase integration
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check for existing user session
      final currentUser = await FirebaseUserService.instance.getCurrentUser();

      // Update app state with current user
      if (mounted && currentUser != null) {
        final appState = context.read<AppState>();
        await appState.setCurrentUser(currentUser);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing auth: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during auth initialization
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up your session...'),
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
    return Consumer<User?>(
      builder: (context, firebaseUser, child) {
        return Consumer<AppState>(
          builder: (context, appState, child) {
            final currentUser = appState.currentUser;

            // If we have a current user (either Firebase or guest), show welcome page
            if (currentUser != null) {
              return const WelcomePage();
            }

            // If Firebase user exists but no app user, there might be a sync issue
            if (firebaseUser != null && currentUser == null) {
              // Try to load the user from Firebase
              _loadFirebaseUser(firebaseUser);

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
            }

            // No user logged in, show login page
            return const LoginPage();
          },
        );
      },
    );
  }

  Future<void> _loadFirebaseUser(User firebaseUser) async {
    try {
      final userService = FirebaseUserService.instance;
      final appUser = await userService.getCurrentUser();

      if (appUser != null && mounted) {
        final appState = context.read<AppState>();
        await appState.setCurrentUser(appUser);
      }
    } catch (e) {
      print('Error loading Firebase user: $e');

      // If there's an issue loading the user, sign them out
      try {
        await FirebaseUserService.instance.logout();
      } catch (signOutError) {
        print('Error signing out after load failure: $signOutError');
      }
    }
  }
}

/// Offline mode app for when Firebase initialization fails
class OfflineModeApp extends StatelessWidget {
  const OfflineModeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core app state provider
        ChangeNotifierProvider(create: (_) => AppState()),

        // Quiz controller provider
        ChangeNotifierProvider(create: (_) => QuizController()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Theorie - Offline Mode',
            debugShowCheckedModeBanner: false,

            // Theme configuration
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

            home: const OfflineAuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Offline-only authentication wrapper
class OfflineAuthWrapper extends StatefulWidget {
  const OfflineAuthWrapper({super.key});

  @override
  State<OfflineAuthWrapper> createState() => _OfflineAuthWrapperState();
}

class _OfflineAuthWrapperState extends State<OfflineAuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeOfflineMode();
  }

  Future<void> _initializeOfflineMode() async {
    try {
      // Initialize only local user service
      await UserService.instance.initialize();

      final currentUser = await UserService.instance.getCurrentUser();

      if (mounted && currentUser != null) {
        final appState = context.read<AppState>();
        await appState.setCurrentUser(currentUser);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing offline mode: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Starting offline mode...'),
            ],
          ),
        ),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currentUser = appState.currentUser;

        if (currentUser != null) {
          return const WelcomePage();
        }

        return const LoginPage();
      },
    );
  }
}
