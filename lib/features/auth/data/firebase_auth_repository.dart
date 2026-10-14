import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final firebase.FirebaseAuth _auth;

  @override
  Stream<AuthUser?> get authStateChanges => _auth.authStateChanges().map(
    (user) => user == null
        ? null
        : AuthUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
          ),
  );

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthFailure(_signInMessage(error.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on firebase.FirebaseAuthException catch (error) {
      // Keep the same result for unknown accounts to avoid account discovery.
      if (error.code != 'user-not-found') {
        throw AuthFailure(_resetMessage(error.code));
      }
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _signInMessage(String code) => switch (code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' =>
      'This account is currently unavailable. Contact the LIFE OS administrator.',
    'network-request-failed' =>
      'Could not connect. Check your internet connection and try again.',
    'too-many-requests' =>
      'Too many attempts. Wait a little before trying again.',
    'operation-not-allowed' =>
      'Email sign-in is not enabled for this LIFE OS project yet.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'The email or password could not be verified.',
    _ => 'Sign-in could not be completed. Try again shortly.',
  };

  String _resetMessage(String code) => switch (code) {
    'network-request-failed' =>
      'Could not connect. Check your internet connection and try again.',
    'too-many-requests' =>
      'Too many requests. Wait a little before trying again.',
    'operation-not-allowed' =>
      'Email sign-in is not enabled for this LIFE OS project yet.',
    _ =>
      'The password reset request could not be completed. Try again shortly.',
  };
}
