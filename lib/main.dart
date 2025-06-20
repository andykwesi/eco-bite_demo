import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      // Already initialized, ignore
    } else {
      rethrow;
    }
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AuthService().init();
  runApp(const EcoBiteApp());
}

class EcoBiteApp extends StatefulWidget {
  const EcoBiteApp({super.key});

  @override
  State<EcoBiteApp> createState() => _EcoBiteAppState();
}

class _EcoBiteAppState extends State<EcoBiteApp> {
  final _authService = AuthService();

  // Bypassing authentication for development
  bool _bypassAuth = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoBite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF97B380),
          primary: const Color(0xFF97B380),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
      // Go directly to home screen
      home: _bypassAuth ? const LoginScreen() : const HomeScreen(),
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
