import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    throw const AuthFailure(
      'Firebase is not configured. Follow the Firebase setup steps in README.md.',
    );
  }
  return FirebaseAuthRepository(firebase.FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
