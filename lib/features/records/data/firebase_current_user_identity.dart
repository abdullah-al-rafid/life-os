import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../domain/life_record_repository.dart';

class FirebaseCurrentUserIdentity implements CurrentUserIdentity {
  const FirebaseCurrentUserIdentity(this._auth);

  final firebase.FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<String?> get uidChanges =>
      _auth.authStateChanges().map((user) => user?.uid);
}
