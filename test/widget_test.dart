import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/app/app.dart';
import 'package:life_os/features/auth/domain/auth_repository.dart';
import 'package:life_os/features/auth/domain/auth_user.dart';
import 'package:life_os/features/auth/presentation/auth_providers.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/records/presentation/record_providers.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';

void main() {
  testWidgets('missing Firebase setup fails closed behind the setup screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LifeOsApp()));
    await tester.pumpAndSettle();

    expect(find.text('Connect your Firebase project.'), findsOneWidget);
    expect(find.text('Welcome back.'), findsNothing);
    expect(find.text('Make room for\nwhat matters.'), findsNothing);
  });

  testWidgets('unauthenticated users are routed to sign-in', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Make room for\nwhat matters.'), findsNothing);
    expect(
      find.textContaining('any existing account in this Firebase project'),
      findsOneWidget,
    );
  });

  testWidgets('email validation prevents invalid sign-in attempts', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign_in_email')),
      'not-an-email',
    );
    await tester.enterText(
      find.byKey(const Key('sign_in_password')),
      'not-empty',
    );
    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(auth.signInCalls, 0);
  });

  testWidgets('sign-in unlocks the dashboard and sign-out protects it again', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign_in_email')),
      'rafid@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign_in_password')),
      'a-test-password',
    );
    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Make room for\nwhat matters.'), findsOneWidget);
    expect(auth.signInCalls, 1);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('rafid@example.com'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Make room for\nwhat matters.'), findsNothing);
    expect(auth.signOutCalls, 1);
  });

  testWidgets(
    'password reset uses a generic confirmation and no sign-up path',
    (tester) async {
      final auth = FakeAuthRepository();
      await tester.pumpWidget(_app(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Reset password.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('reset_email')),
        'rafid@example.com',
      );
      await tester.tap(find.byKey(const Key('reset_submit')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('If that account is registered'),
        findsOneWidget,
      );
      expect(auth.passwordResetCalls, 1);
      expect(find.textContaining('Create account'), findsNothing);
    },
  );

  testWidgets('wide short layout keeps a scrollable side navigation rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(FakeAuthRepository(initialUser: _testUser)));
    await tester.pumpAndSettle();
    expect(find.text('WORKSPACE'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact navigation reaches each primary destination without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(FakeAuthRepository(initialUser: _testUser)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'on compact Home');

      for (final (label, expected) in [
        ('Plan', 'Today’s plan'),
        ('Goals', 'Goals'),
        ('Together', 'Together'),
        ('Progress', 'Progress & Reports'),
        ('Settings', 'Settings'),
        ('Home', 'Make room for\nwhat matters.'),
      ]) {
        final destination = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        );
        await tester.tap(destination);
        await tester.pumpAndSettle();
        expect(find.text(expected), findsWidgets);
      }
    },
  );

  testWidgets('dashboard exposes a direct 15-day import shortcut', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(FakeAuthRepository(initialUser: _testUser)));
    await tester.pumpAndSettle();
    final shortcut = find.byKey(const Key('dashboard_import_plan'));
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Choose XLSX, CSV, TXT, PDF, or DOCX'),
      findsOneWidget,
    );
  });
}

const _testUser = AuthUser(
  uid: 'test-user',
  email: 'rafid@example.com',
  displayName: 'Test User',
);

Widget _app(FakeAuthRepository repository) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(repository),
    currentUserIdentityProvider.overrideWithValue(_FakeIdentity()),
    trackingEntriesProvider((
      TrackingEntryKind.fasting,
      null,
    )).overrideWith((ref) => Stream.value(<TrackingEntry>[])),
    trackingEntriesProvider((
      TrackingEntryKind.sleep,
      null,
    )).overrideWith((ref) => Stream.value(<TrackingEntry>[])),
    trackingEntriesProvider((
      TrackingEntryKind.workout,
      null,
    )).overrideWith((ref) => Stream.value(<TrackingEntry>[])),
  ],
  child: const LifeOsApp(),
);

class _FakeIdentity implements CurrentUserIdentity {
  @override
  String? currentUid = 'test-user';
  @override
  Stream<String?> get uidChanges => Stream.value(currentUid);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _user = initialUser;

  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  int signInCalls = 0;
  int signOutCalls = 0;
  int passwordResetCalls = 0;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.multi((controller) {
    controller.add(_user);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    _user = AuthUser(uid: 'test-user', email: email.trim().toLowerCase());
    _changes.add(_user);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    passwordResetCalls++;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _changes.add(null);
  }
}
