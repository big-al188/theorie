// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'controllers/quiz_controller.dart';
import 'services/user_service.dart';
// COMMENTED OUT: Don't import progress service until we fix the type conflicts
// import 'services/progress_tracking_service.dart';
import 'views/pages/login_page.dart';
import 'views/pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize user service
  await UserService.instance.initialize();

  runApp(const TheorieApp());
}

class TheorieApp extends StatelessWidget {
  const TheorieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Existing app state provider
        ChangeNotifierProvider(create: (_) => AppState()),

        // Existing quiz controller provider
        ChangeNotifierProvider(create: (_) => QuizController()),

        // TODO: Add progress tracking service once we fix type conflicts
        // ChangeNotifierProvider(create: (_) => ProgressTrackingService.instance),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Theorie',
            debugShowCheckedModeBanner: false,

            // Theme configuration
            themeMode: appState.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),

            home: const AuthWrapper(),
          );
        },
      ),
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

/// Wrapper to handle authentication state with improved guest user handling
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check if there's a current user
      final user = await UserService.instance.getCurrentUser();

      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
          _isLoading = false;
        });

        // Update app state if user found
        if (user != null) {
          final appState = context.read<AppState>();
          await appState.setCurrentUser(user);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const WelcomePage() : const LoginPage();
  }
}
