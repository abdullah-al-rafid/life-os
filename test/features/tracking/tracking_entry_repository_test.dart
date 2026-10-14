import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/records/data/drift_life_record_store.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/tracking/data/drift_tracking_entry_store.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';
import 'package:life_os/features/tracking/domain/tracking_entry_repository.dart';

void main() {
  late LifeDatabase database;
  late _Identity identity;
  late LifeRecordRepository records;
  late OfflineTrackingEntryRepository repository;

  setUp(() {
    database = LifeDatabase.forTesting(NativeDatabase.memory());
    identity = _Identity('uid-a');
    records = OfflineLifeRecordRepository(
      DriftLifeRecordStore(database),
      identity,
    );
    repository = OfflineTrackingEntryRepository(
      DriftTrackingEntryStore(database),
      identity,
      records,
    );
  });

  tearDown(() async {
    await identity.dispose();
    await database.close();
  });

  test(
    'validates dates, common metadata, and kind-specific payloads',
    () async {
      for (final bad in [
        _entry(id: 'bad-date', date: '2026-02-30'),
        _entry(id: 'bad-key', key: 'Fajr', kind: TrackingEntryKind.sleep),
        _entry(
          id: 'bad-duration',
          kind: TrackingEntryKind.sleep,
          payload: {'durationMinutes': 1441},
        ),
        _entry(
          id: 'bad-fast',
          kind: TrackingEntryKind.fasting,
          payload: {'status': 'maybe'},
        ),
        _entry(
          id: 'bad-workout',
          kind: TrackingEntryKind.workout,
          payload: {'activity': ' ', 'durationMinutes': 20},
        ),
        _entry(
          id: 'bad-prayer-snapshot',
          kind: TrackingEntryKind.prayer,
          payload: {
            'status': 'prayedOnTime',
            'scheduleSnapshot': {
              'azanMinute': 600,
              'jamaatMinute': 590,
              'timezoneId': 'Asia/Dhaka',
            },
          },
        ),
        _entry(
          id: 'bad-timezone-id',
          kind: TrackingEntryKind.prayer,
          payload: {
            'status': 'prayedOnTime',
            'scheduleSnapshot': {
              'azanMinute': 600,
              'jamaatMinute': 630,
              'timezoneId': 'Not a timezone',
            },
          },
        ),
        _entry(id: 'bad-json', payloadJson: '{bad'),
      ]) {
        await expectLater(
          repository.create(bad),
          throwsA(isA<TrackingEntryValidationFailure>()),
          reason: 'reject ${bad.id}',
        );
      }
      expect(await database.select(database.trackingEntries).get(), isEmpty);
    },
  );

  test(
    'enforces unique prayer, fasting, and sleep entries per local date',
    () async {
      for (final kind in [
        TrackingEntryKind.prayer,
        TrackingEntryKind.fasting,
        TrackingEntryKind.sleep,
      ]) {
        final first = _entry(id: '${kind.name}-1', kind: kind);
        await repository.create(first);
        await expectLater(
          repository.create(_entry(id: '${kind.name}-2', kind: kind)),
          throwsA(isA<DuplicateTrackingEntry>()),
        );
      }

      await repository.create(
        _entry(
          id: 'workout-1',
          kind: TrackingEntryKind.workout,
          key: 'workout-1',
        ),
      );
      await repository.create(
        _entry(
          id: 'workout-2',
          kind: TrackingEntryKind.workout,
          key: 'workout-2',
        ),
      );
      expect(
        await repository.watch(kind: TrackingEntryKind.workout).first,
        hasLength(2),
      );
    },
  );

  test(
    'sleep uniqueness is enforced for the same owner and wake-up date',
    () async {
      await repository.create(
        _entry(id: 'sleep-a', kind: TrackingEntryKind.sleep),
      );
      await expectLater(
        repository.create(
          _entry(
            id: 'sleep-other-key',
            kind: TrackingEntryKind.sleep,
            key: 'another-key',
          ),
        ),
        throwsA(isA<TrackingEntryValidationFailure>()),
      );
      await expectLater(
        database
            .into(database.trackingEntries)
            .insert(
              TrackingEntriesCompanion.insert(
                id: 'sleep-index-check',
                ownerUid: 'uid-a',
                kind: 'sleep',
                localDate: '2026-10-14',
                entryKey: 'non-daily-key',
                visibility: 'private',
                payloadJson: '{"durationMinutes":420}',
                createdAtUtcMs: 1,
                updatedAtUtcMs: 1,
              ),
            ),
        throwsA(anything),
        reason:
            'the database enforces sleep uniqueness independent of entryKey',
      );

      identity.switchTo('uid-b');
      await repository.create(
        _entry(id: 'sleep-b', owner: 'uid-b', kind: TrackingEntryKind.sleep),
      );
      expect(
        await repository.watch(kind: TrackingEntryKind.sleep).first,
        hasLength(1),
      );
    },
  );

  test(
    'private entries are isolated and shared entries are read-only to others',
    () async {
      await expectLater(
        repository.create(_entry(id: 'spoofed-owner', owner: 'uid-b')),
        throwsA(isA<OwnershipViolation>()),
      );
      await repository.create(_entry(id: 'private-a'));
      await repository.create(
        _entry(
          id: 'shared-a',
          kind: TrackingEntryKind.prayer,
          visibility: RecordVisibility.shared,
        ),
      );
      identity.switchTo('uid-b');
      final visible = await repository.watch().first;
      expect(visible.map((entry) => entry.id), ['shared-a']);
      await expectLater(
        repository.update(
          id: 'shared-a',
          expectedRevision: 1,
          payload: _payload(TrackingEntryKind.prayer),
        ),
        throwsA(isA<OwnershipViolation>()),
      );
    },
  );

  test(
    'watch stream cancels the previous UID after account switching',
    () async {
      await repository.create(_entry(id: 'private-a'));
      identity.switchTo('uid-b');
      await repository.create(_entry(id: 'private-b', owner: 'uid-b'));
      identity.switchTo('uid-a');

      final received = <List<String>>[];
      final switched = Completer<void>();
      final subscription = repository.watch().listen((entries) {
        final ids = entries.map((entry) => entry.id).toList();
        received.add(ids);
        if (ids.contains('private-a') && received.length == 1) {
          identity.switchTo('uid-b');
        }
        if (ids.contains('private-b')) switched.complete();
      });
      await switched.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received, [
        ['private-a'],
        ['private-b'],
      ]);
      await subscription.cancel();
    },
  );

  test(
    'updates use optimistic revisions and tombstones cannot resurrect entries',
    () async {
      final created = await repository.create(
        _entry(id: 'sleep-entry', kind: TrackingEntryKind.sleep),
      );
      final updated = await repository.update(
        id: created.id,
        expectedRevision: created.revision,
        payload: {'durationMinutes': 460, 'notes': 'Rested'},
      );
      expect(updated.revision, 2);
      expect(updated.payload['durationMinutes'], 460);
      await expectLater(
        repository.update(
          id: created.id,
          expectedRevision: 1,
          payload: {'durationMinutes': 480},
        ),
        throwsA(isA<StaleTrackingEntryRevision>()),
      );

      await repository.delete(
        id: updated.id,
        expectedRevision: updated.revision,
        atUtc: DateTime.now().toUtc().add(const Duration(seconds: 1)),
      );
      expect(await repository.watch().first, isEmpty);
      final tombstone = await (database.select(
        database.trackingEntries,
      )..where((row) => row.id.equals(updated.id))).getSingle();
      expect(tombstone.deletedAtUtcMs, isNotNull);
      expect(tombstone.revision, 3);

      final replacement = await repository.create(
        _entry(id: 'sleep-replacement', kind: TrackingEntryKind.sleep),
      );
      expect(replacement.id, 'sleep-replacement');
    },
  );

  test(
    'tracking writes are local and unauthenticated access fails closed',
    () async {
      identity.switchTo(null);
      await expectLater(
        repository.watch().first,
        throwsA(isA<UnauthenticatedOperation>()),
      );
      await expectLater(
        repository.create(_entry(id: 'unauth')),
        throwsA(isA<UnauthenticatedOperation>()),
      );
      expect(await database.select(database.trackingEntries).get(), isEmpty);
    },
  );
}

TrackingEntry _entry({
  required String id,
  String owner = 'uid-a',
  TrackingEntryKind kind = TrackingEntryKind.fasting,
  String date = '2026-10-14',
  String? key,
  RecordVisibility visibility = RecordVisibility.private,
  Map<String, Object?>? payload,
  String? payloadJson,
  int revision = 1,
  DateTime? created,
  DateTime? updated,
}) => TrackingEntry(
  id: id,
  ownerUid: owner,
  kind: kind,
  localDate: date,
  entryKey: key ?? (kind == TrackingEntryKind.prayer ? 'Fajr' : 'daily'),
  visibility: visibility,
  payloadJson: payloadJson ?? jsonEncode(payload ?? _payload(kind)),
  createdAtUtc: created ?? DateTime.utc(2026, 10, 14),
  updatedAtUtc: updated ?? DateTime.utc(2026, 10, 14),
  revision: revision,
);

Map<String, Object?> _payload(TrackingEntryKind kind) => switch (kind) {
  TrackingEntryKind.prayer => {
    'status': 'prayedOnTime',
    'jamaatStatus': 'jamaat',
    'notes': '',
    'scheduleSnapshot': {
      'azanMinute': 600,
      'jamaatMinute': 630,
      'timezoneId': 'Asia/Dhaka',
    },
  },
  TrackingEntryKind.fasting => {'status': 'fasted', 'notes': ''},
  TrackingEntryKind.sleep => {'durationMinutes': 420, 'notes': ''},
  TrackingEntryKind.workout => {
    'activity': 'Strength training',
    'durationMinutes': 45,
    'notes': '',
  },
};

class _Identity implements CurrentUserIdentity {
  _Identity(this.currentUid);
  @override
  String? currentUid;
  final _changes = StreamController<String?>.broadcast();

  void switchTo(String? uid) {
    currentUid = uid;
    _changes.add(uid);
  }

  @override
  Stream<String?> get uidChanges => Stream<String?>.multi((controller) {
    controller.add(currentUid);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  Future<void> dispose() => _changes.close();
}
