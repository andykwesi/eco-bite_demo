import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

// Custom auth exception for better error handling
class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.code, this.message);

  @override
  String toString() => message;

  // Helper to convert Firebase Auth error codes to user-friendly messages
  static AuthException fromFirebaseError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthException(e.code, 'The email address is invalid.');
      case 'user-disabled':
        return AuthException(e.code, 'This user has been disabled.');
      case 'user-not-found':
        return AuthException(e.code, 'No user found with this email.');
      case 'wrong-password':
        return AuthException(e.code, 'The password is incorrect.');
      case 'email-already-in-use':
        return AuthException(e.code, 'This email is already registered.');
      case 'weak-password':
        return AuthException(e.code, 'Password is too weak.');
      case 'operation-not-allowed':
        return AuthException(e.code, 'This operation is not allowed.');
      case 'account-exists-with-different-credential':
        return AuthException(
          e.code,
          'An account already exists with a different credential.',
        );
      case 'network-request-failed':
        return AuthException(
          e.code,
          'Network error. Please check your connection.',
        );
      case 'too-many-requests':
        return AuthException(
          e.code,
          'Too many requests. Please try again later.',
        );
      default:
        return AuthException(e.code, e.message ?? 'An unknown error occurred.');
    }
  }
}

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  User? _currentUser;

  // Create controller with a default null value
  final _authStateController = StreamController<User?>.broadcast();

  // Expose the stream
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Get the current user
  User? get currentUser => _currentUser;

  // Get the current user's UID
  String? get currentUserId => _currentUser?.id;

  // Flag to track if initialized
  bool _isInitialized = false;

  // Listen to Firebase auth state changes
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Immediately emit the current auth state
    _updateCurrentUser(_firebaseAuth.currentUser);

    // Listen for future changes
    _firebaseAuth.authStateChanges().listen((fbUser) {
      _updateCurrentUser(fbUser);
    });
  }

  // Helper to update the current user and notify listeners
  void _updateCurrentUser(fb_auth.User? fbUser) {
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

    // Notify listeners
    _authStateController.add(_currentUser);
  }

  // Login with Firebase
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;

      _updateCurrentUser(fbUser);
      return _currentUser!;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        'unknown',
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Register with Firebase
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final displayName = '$firstName $lastName'.trim();
      await credential.user!.updateDisplayName(displayName);
      // Optionally, store firstName and lastName in Firestore if you have a user collection
      _currentUser = User(
        id: credential.user!.uid,
        email: email,
        name: displayName,
        firstName: firstName,
        lastName: lastName,
        createdAt: credential.user!.metadata.creationTime ?? DateTime.now(),
      );
      _authStateController.add(_currentUser);
      return _currentUser!;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        'unknown',
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _updateCurrentUser(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        'unknown',
        'An unexpected error occurred during sign out: ${e.toString()}',
      );
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    _updateCurrentUser(fbUser);
    return _currentUser;
  }

  // Helper method to reload user data
  Future<void> reloadUser() async {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        await fbUser.reload();
        _updateCurrentUser(fbUser);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        'unknown',
        'Failed to reload user data: ${e.toString()}',
      );
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        'unknown',
        'An unexpected error occurred while sending reset email: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
