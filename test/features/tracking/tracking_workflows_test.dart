import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/records/data/drift_life_record_store.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/tracking/data/drift_tracking_entry_store.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';
import 'package:life_os/features/tracking/domain/tracking_entry_repository.dart';
import 'package:life_os/features/tracking/domain/tracking_workflows.dart';

void main() {
  late LifeDatabase database;
  late _Identity identity;
  late OfflineTrackingEntryRepository repository;
  late TrackingWorkflows workflows;

  setUp(() {
    database = LifeDatabase.forTesting(NativeDatabase.memory());
    identity = _Identity('uid-a');
    repository = OfflineTrackingEntryRepository(
      DriftTrackingEntryStore(database),
      identity,
      OfflineLifeRecordRepository(DriftLifeRecordStore(database), identity),
    );
    workflows = TrackingWorkflows(repository);
  });

  tearDown(() async {
    await identity.dispose();
    await database.close();
  });

  test('local date keys preserve the selected calendar date', () {
    final selectedDate = DateTime(2026, 3, 8);
    expect(localDateKey(selectedDate), '2026-03-08');
    expect(parseLocalDateKey('2026-03-08'), selectedDate);
    expect(
      () => parseLocalDateKey('2026-02-30'),
      throwsA(isA<TrackingEntryValidationFailure>()),
    );
  });

  test(
    'sleep edits keep the historical wake-up date and use revisions',
    () async {
      final sleep = await workflows.saveSleep(
        localDate: '2026-03-08',
        durationMinutes: 420,
      );
      final updated = await workflows.saveSleep(
        localDate: '2026-03-08',
        durationMinutes: 450,
        notes: 'Updated measurement',
        existing: sleep,
      );
      expect(updated.localDate, '2026-03-08');
      expect(updated.revision, 2);
      expect(updated.payload['durationMinutes'], 450);
      await expectLater(
        workflows.saveSleep(
          localDate: '2026-03-09',
          durationMinutes: 450,
          existing: updated,
        ),
        throwsA(isA<TrackingEntryValidationFailure>()),
      );
    },
  );

  test(
    'fasting is private and dates without records remain unrecorded',
    () async {
      final fasting = await workflows.saveFasting(
        localDate: '2026-10-14',
        fasted: true,
        notes: 'Optional note',
      );
      expect(fasting.visibility.name, 'private');
      expect(fasting.payload['status'], 'fasted');
      expect(fasting.localDate, '2026-10-14');
      expect(
        await repository
            .watch(kind: TrackingEntryKind.fasting, localDate: '2026-10-15')
            .first,
        isEmpty,
      );
    },
  );

  test(
    'multiple workouts can be logged for one date and safely deleted',
    () async {
      final first = await workflows.saveWorkout(
        localDate: '2026-10-14',
        activity: 'Strength training',
        durationMinutes: 45,
      );
      await workflows.saveWorkout(
        localDate: '2026-10-14',
        activity: 'Walking',
        durationMinutes: 30,
      );
      expect(
        await repository.watch(kind: TrackingEntryKind.workout).first,
        hasLength(2),
      );
      await workflows.delete(first);
      expect(
        await repository.watch(kind: TrackingEntryKind.workout).first,
        hasLength(1),
      );
    },
  );

  test(
    'workflow creation follows the active UID and fails signed out',
    () async {
      identity.currentUid = null;
      await expectLater(
        workflows.saveFasting(localDate: '2026-10-14', fasted: false),
        throwsA(isA<UnauthenticatedOperation>()),
      );
    },
  );
}

class _Identity implements CurrentUserIdentity {
  _Identity(this.currentUid);
  @override
  String? currentUid;
  final _changes = StreamController<String?>.broadcast();
  @override
  Stream<String?> get uidChanges => Stream<String?>.multi((controller) {
    controller.add(currentUid);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
  Future<void> dispose() => _changes.close();
}
