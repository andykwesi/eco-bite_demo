import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import '../models/user.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  Stream<User?> get authStateChanges => _authStateController.stream;
  User? get currentUser => _currentUser;

  // Listen to Firebase auth state changes
  void init() {
    _firebaseAuth.authStateChanges().listen((fbUser) {
      if (fbUser != null) {
        _currentUser = User(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          name: fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
          createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
        );
      } else {
        _currentUser = null;
      }
      _authStateController.add(_currentUser);
    });
  }

  // Login with Firebase
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user!;
    _currentUser = User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  // Register with Firebase
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);
    final fbUser = credential.user!;
    _currentUser = User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: name,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
