import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/fasting/presentation/fasting_screen.dart';
import 'package:life_os/features/records/data/drift_life_record_store.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/records/presentation/record_providers.dart';
import 'package:life_os/features/tracking/data/drift_tracking_entry_store.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';
import 'package:life_os/features/tracking/domain/tracking_entry_repository.dart';
import 'package:life_os/features/wellness/presentation/wellness_screen.dart';

void main() {
  testWidgets('fasting screen records a date and marks missing dates clearly', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await fixture.dispose();
    });
    await tester.pumpWidget(fixture.wrap(const FastingScreen()));
    await tester.pumpAndSettle();
    expect(find.text('No fasting record for this date yet.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('fasting_fasted')));
    await tester.tap(find.byKey(const Key('fasting_fasted')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('fasting_fasted')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('fasting_save')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(
      find.textContaining('could not be saved locally'),
      findsNothing,
      reason: 'A valid fasting selection should save without an error state.',
    );
    final rows = await fixture.database
        .select(fixture.database.trackingEntries)
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.kind, 'fasting');
    expect(rows.single.visibility, 'private');
  });

  testWidgets('wellness validates sleep and allows multiple workout logs', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await fixture.dispose();
    });
    await tester.pumpWidget(fixture.wrap(const WellnessScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('sleep_save')));
    await tester.tap(find.byKey(const Key('sleep_save')));
    await tester.pump();
    expect(
      find.text('Enter a duration from 1 to 1440 minutes.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('sleep_duration')), '420');
    await tester.ensureVisible(find.byKey(const Key('sleep_save')));
    await tester.tap(find.byKey(const Key('sleep_save')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.tap(find.byKey(const Key('workout_add')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('workout_activity')),
      'Strength training',
    );
    await tester.enterText(find.byKey(const Key('workout_duration')), '45');
    await tester.tap(find.byKey(const Key('workout_save')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.tap(find.byKey(const Key('workout_add')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('workout_activity')), 'Walk');
    await tester.enterText(find.byKey(const Key('workout_duration')), '30');
    await tester.tap(find.byKey(const Key('workout_save')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    final rows = await fixture.database
        .select(fixture.database.trackingEntries)
        .get();
    expect(rows.where((row) => row.kind == 'sleep'), hasLength(1));
    expect(rows.where((row) => row.kind == 'workout'), hasLength(2));
  });
}

class _Fixture {
  final database = LifeDatabase.forTesting(NativeDatabase.memory());
  final identity = _Identity();
  late final repository = OfflineTrackingEntryRepository(
    DriftTrackingEntryStore(database),
    identity,
    OfflineLifeRecordRepository(DriftLifeRecordStore(database), identity),
  );

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      trackingEntryRepositoryProvider.overrideWithValue(repository),
      currentUserIdentityProvider.overrideWithValue(identity),
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
    child: MaterialApp(home: child),
  );

  Future<void> dispose() async {
    await identity.dispose();
    await database.close();
  }
}

class _Identity implements CurrentUserIdentity {
  @override
  String? currentUid = 'widget-user';
  @override
  Stream<String?> get uidChanges => Stream.value(currentUid);
  Future<void> dispose() async {}
}
