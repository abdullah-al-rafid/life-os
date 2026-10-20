import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

const _useFirebaseEmulators = bool.fromEnvironment(
  'LIFE_OS_USE_FIREBASE_EMULATORS',
  defaultValue: false,
);
const _firebaseEmulatorHost = String.fromEnvironment(
  'LIFE_OS_FIREBASE_EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);
const _firebaseEmulatorProjectId = String.fromEnvironment(
  'LIFE_OS_FIREBASE_EMULATOR_PROJECT_ID',
  defaultValue: 'demo-life-os',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(
      options: _useFirebaseEmulators
          ? options.copyWith(projectId: _firebaseEmulatorProjectId)
          : options,
    );
    if (_useFirebaseEmulators) {
      FirebaseAuth.instance.useAuthEmulator(_firebaseEmulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(
        _firebaseEmulatorHost,
        8080,
      );
    }
  } on Object {
    // The auth gate presents the configuration recovery page. Do not expose
    // project details or credentials in logs or UI.
  }
  runApp(const ProviderScope(child: LifeOsApp()));
}
