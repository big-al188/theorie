// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'services/user_service.dart';
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
    return ChangeNotifierProvider(
      create: (_) => AppState(),
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

/// Wrapper to handle authentication state
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
      final user = await UserService.instance.getCurrentUser();
      if (user != null && mounted) {
        // Load user preferences into app state
        final appState = context.read<AppState>();
        await appState.setCurrentUser(user);
        
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
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
              Text('Loading Theorie...'),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? const WelcomePage() : const LoginPage();
  }
}