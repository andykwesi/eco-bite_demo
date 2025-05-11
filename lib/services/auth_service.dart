import 'dart:async';
import '../models/user.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // In a real app, this would connect to Firebase Auth or another backend
  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  Stream<User?> get authStateChanges => _authStateController.stream;
  User? get currentUser => _currentUser;

  // Mock login function
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (password.length < 6) {
      throw Exception('Invalid password. Must be at least 6 characters.');
    }

    _currentUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: email.split('@').first,
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  // Mock registration function
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (password.length < 6) {
      throw Exception('Invalid password. Must be at least 6 characters.');
    }

    _currentUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  // Sign out
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
