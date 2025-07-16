// lib/main.dart - Updated authentication wrapper
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
      print('Initializing Firebase...');

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

      print('Firebase initialized successfully');
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

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _buildErrorScreen();
    }

    if (!_initialized) {
      return _buildLoadingScreen();
    }

    // Firebase initialized successfully - show main app
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

/// Authentication wrapper with improved error handling
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
      print('Initializing auth wrapper...');
      _loadingAttempts++;

      // Check for existing user session
      final currentUser = await FirebaseUserService.instance.getCurrentUser();
      print('Current user: ${currentUser?.username ?? 'None'}');

      // Update app state with current user
      if (mounted && currentUser != null) {
        final appState = context.read<AppState>();
        await appState.setCurrentUser(currentUser);
        print('App state updated with user: ${currentUser.username}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error initializing auth: $e');

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
              Text(
                  'Setting up your session... (${_loadingAttempts}/$_maxLoadingAttempts)'),
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
    return Consumer<User?>(
      builder: (context, firebaseUser, child) {
        return Consumer<AppState>(
          builder: (context, appState, child) {
            final currentUser = appState.currentUser;

            print(
                'Auth state - Firebase: ${firebaseUser?.uid}, App: ${currentUser?.username}');

            // If we have a current user (either Firebase or guest), show welcome page
            if (currentUser != null) {
              return const WelcomePage();
            }

            // If Firebase user exists but no app user, load the user data
            if (firebaseUser != null && currentUser == null) {
              // Use a FutureBuilder for better error handling
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
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            const Text('Failed to load user data'),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
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

  // Replace just this method in your existing AuthWrapper class
  Future<void> _loadFirebaseUser(User firebaseUser) async {
    try {
      print('Loading Firebase user data for: ${firebaseUser.uid}');

      final userService = FirebaseUserService.instance;
      final appUser = await userService.getCurrentUser();

      if (appUser != null && mounted) {
        print('User data loaded successfully: ${appUser.username}');
        final appState = context.read<AppState>();
        await appState.setCurrentUser(appUser);
      } else {
        print('No app user data found for Firebase user: ${firebaseUser.uid}');

        // If user exists in Firebase but not in Firestore, sign them out
        // This prevents infinite loading
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage =
                'User data not found in database. Please try registering again.';
          });
        }

        try {
          await FirebaseUserService.instance.logout();
          print('Signed out user due to missing data');
        } catch (signOutError) {
          print('Error signing out after load failure: $signOutError');
        }
      }
    } catch (e) {
      print('Error loading Firebase user: $e');

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
        print('Signed out user due to loading error');
      } catch (signOutError) {
        print('Error signing out after load failure: $signOutError');
      }
    }
  }
}
