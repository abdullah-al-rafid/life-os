import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
