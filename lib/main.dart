import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables (optional - only if .env file exists)
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');

      // Debug: Check if API key is loaded
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      print('DEBUG: API key loaded: ${apiKey != null ? 'Yes' : 'No'}');
      if (apiKey != null) {
        print('DEBUG: API key length: ${apiKey.length}');
        print(
          'DEBUG: API key starts with: ${apiKey.substring(0, apiKey.length > 20 ? 20 : apiKey.length)}',
        );
      }
    } catch (e) {
      print(
        'Warning: .env file not found. Some features may not work without proper configuration.',
      );
      // Continue without environment variables
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'duplicate-app') {
        // Already initialized, ignore
        print('Firebase already initialized');
      } else {
        print('Firebase initialization error: $e');
        rethrow;
      }
    }

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    AuthService().init();
    print('App initialization completed successfully');
    runApp(const EcoBiteApp());
  } catch (e, stackTrace) {
    print('Fatal error during app initialization: $e');
    print('Stack trace: $stackTrace');
    // Show a simple error screen instead of crashing
    runApp(const ErrorApp());
  }
}

class EcoBiteApp extends StatefulWidget {
  const EcoBiteApp({super.key});

  @override
  State<EcoBiteApp> createState() => _EcoBiteAppState();
}

class _EcoBiteAppState extends State<EcoBiteApp> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Short delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoBite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          background: const Color(0xFFF8F8F8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
          labelLarge: TextStyle(fontFamily: 'Poppins'),
        ),
        useMaterial3: true,
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
      home: _isInitializing ? const SplashScreen() : AuthStateRedirect(),
    );
  }
}

// Separate widget to handle auth state redirection
class AuthStateRedirect extends StatelessWidget {
  const AuthStateRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // If we have a user, go to home screen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // If we don't have a user or there's an error, go to login screen
        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF97B380),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ECOBITE',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    blurRadius: 3.0,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Reduce Waste, Cook Smart',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Error app to show when initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoBite - Error',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[600]),
                const SizedBox(height: 24),
                Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'The app encountered an error during startup. Please check the console for more details and try restarting the app.',
                  style: TextStyle(fontSize: 16, color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart the app
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
