import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/records/data/drift_life_record_store.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/records/presentation/record_providers.dart';

void main() {
  late LifeDatabase database;
  late DriftLifeRecordStore store;
  late LifeRecordRepository repository;
  late _FakeIdentity identity;

  setUp(() {
    database = LifeDatabase.forTesting(NativeDatabase.memory());
    store = DriftLifeRecordStore(database);
    identity = _FakeIdentity('uid-a');
    repository = OfflineLifeRecordRepository(store, identity);
  });

  tearDown(() async {
    await database.close();
    await identity.dispose();
  });

  test('provider closes its database when its container is disposed', () async {
    final ownedDatabase = _TrackingDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        lifeDatabaseFactoryProvider.overrideWithValue(() => ownedDatabase),
      ],
    );
    expect(
      identical(container.read(lifeDatabaseProvider), ownedDatabase),
      isTrue,
    );

    container.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(ownedDatabase.closeStarted, isTrue);
    await ownedDatabase.close();
  });

  test('profile is keyed to the authenticated UID, not an email', () async {
    identity.currentUid = 'firebase-uid-a';
    final created = DateTime.utc(2026, 10, 1);
    await repository.saveProfile(_profile('firebase-uid-a', created));
    await repository.saveProfile(
      _profile('firebase-uid-a', DateTime.utc(2026, 10, 2), updatedDay: 15),
    );

    final profile = await repository.findCurrentProfile();
    expect(profile?.displayName, 'User firebase-uid-a');
    expect(profile?.createdAtUtc, created);
    await expectLater(
      repository.saveProfile(_profile('firebase-uid-b', created)),
      throwsA(isA<OwnershipViolation>()),
    );
  });

  test('unauthenticated repository calls fail closed', () async {
    identity.currentUid = null;
    await expectLater(
      repository.watchVisibleRecords().first,
      throwsA(isA<UnauthenticatedOperation>()),
    );
    expect(
      repository.findCurrentProfile,
      throwsA(isA<UnauthenticatedOperation>()),
    );
    expect(
      () => repository.saveRecord(_record(id: 'x', owner: 'uid-a')),
      throwsA(isA<UnauthenticatedOperation>()),
    );
    expect(
      () => repository.deleteRecord('x', DateTime.utc(2026, 10, 15)),
      throwsA(isA<UnauthenticatedOperation>()),
    );
  });

  test('viewer sees own private and other users shared records only', () async {
    await _saveProfileAs(repository, identity, 'uid-a');
    await repository.saveRecord(_record(id: 'own-private', owner: 'uid-a'));
    await _saveProfileAs(repository, identity, 'uid-b');
    await repository.saveRecord(
      _record(
        id: 'shared',
        owner: 'uid-b',
        visibility: RecordVisibility.shared,
      ),
    );
    await repository.saveRecord(_record(id: 'other-private', owner: 'uid-b'));

    identity.currentUid = 'uid-a';
    final records = await repository.watchVisibleRecords().first;
    expect(records.map((record) => record.id).toSet(), {
      'own-private',
      'shared',
    });
  });

  test(
    'read stream switches accounts and stops emitting old-user records',
    () async {
      await _saveProfileAs(repository, identity, 'uid-a');
      await repository.saveRecord(_record(id: 'private-a', owner: 'uid-a'));
      await _saveProfileAs(repository, identity, 'uid-b');
      await repository.saveRecord(_record(id: 'private-b', owner: 'uid-b'));
      identity.currentUid = 'uid-a';

      final seen = <String>[];
      final initialA = Completer<void>();
      final initialB = Completer<void>();
      final signedOut = Completer<void>();
      final subscription = repository.watchVisibleRecords().listen(
        (records) {
          final ids = records.map((record) => record.id).join(',');
          seen.add('${identity.currentUid}:$ids');
          if (identity.currentUid == 'uid-a' && ids == 'private-a') {
            initialA.complete();
          }
          if (identity.currentUid == 'uid-b' && ids == 'private-b') {
            initialB.complete();
          }
        },
        onError: (Object error) {
          if (error is UnauthenticatedOperation) signedOut.complete();
        },
      );
      await initialA.future;
      identity.currentUid = 'uid-b';
      await initialB.future.timeout(const Duration(seconds: 2));
      identity.currentUid = null;
      await signedOut.future.timeout(const Duration(seconds: 2));
      expect(seen, ['uid-a:private-a', 'uid-b:private-b']);
      await subscription.cancel();
    },
  );

  test(
    'mismatched users cannot create, overwrite, delete, or read another profile',
    () async {
      await _saveProfileAs(repository, identity, 'uid-a');
      await repository.saveRecord(_record(id: 'own', owner: 'uid-a'));
      await _saveProfileAs(repository, identity, 'uid-b');
      await repository.saveRecord(_record(id: 'private-b', owner: 'uid-b'));

      identity.currentUid = 'uid-a';
      expect(
        () => repository.saveRecord(_record(id: 'impostor', owner: 'uid-b')),
        throwsA(isA<OwnershipViolation>()),
      );
      await expectLater(
        Future<LifeRecord>.sync(
          () => repository.saveRecord(
            _record(
              id: 'private-b',
              owner: 'uid-a',
              payload: '{"changed":true}',
            ),
          ),
        ),
        throwsA(isA<OwnershipViolation>()),
      );
      await expectLater(
        repository.deleteRecord('private-b', DateTime.utc(2026, 10, 15)),
        throwsA(isA<OwnershipViolation>()),
      );
      await expectLater(
        repository.saveProfile(_profile('uid-b', DateTime.utc(2026, 10, 14))),
        throwsA(isA<OwnershipViolation>()),
      );
      expect((await repository.findCurrentProfile())?.authUid, 'uid-a');
      expect((await repository.watchVisibleRecords().first).map((r) => r.id), [
        'own',
      ]);
    },
  );

  test(
    'rejects malformed payloads, fields, revisions, timestamps, and sync metadata',
    () async {
      await _saveProfileAs(repository, identity, 'uid-a');
      final now = DateTime.utc(2026, 10, 14);
      final invalidRecords = [
        _record(id: '', owner: 'uid-a'),
        _record(id: 'bad-owner', owner: ' '),
        _record(id: 'bad-json', owner: 'uid-a', payload: '{broken'),
        _record(id: 'not-object', owner: 'uid-a', payload: '[]'),
        _record(
          id: 'bad-time',
          owner: 'uid-a',
          created: now,
          updated: now.subtract(const Duration(days: 1)),
        ),
        _record(id: 'bad-timezone', owner: 'uid-a', timezoneId: ' '),
        _record(id: 'bad-revision', owner: 'uid-a', revision: 0),
        _record(
          id: 'sync-injection',
          owner: 'uid-a',
          syncStatus: RecordSyncStatus.pendingUpload,
        ),
        _record(
          id: 'sync-time-injection',
          owner: 'uid-a',
          lastSyncedAtUtc: now,
        ),
        _record(id: 'deleted-injection', owner: 'uid-a', deletedAtUtc: now),
      ];
      for (final invalid in invalidRecords) {
        expect(
          () => repository.saveRecord(invalid),
          throwsA(isA<RecordValidationFailure>()),
          reason: 'Rejected malformed record ${invalid.id}',
        );
      }
      await expectLater(
        repository.saveRecord(
          _record(id: 'revision-start', owner: 'uid-a', revision: 2),
        ),
        throwsA(isA<RecordValidationFailure>()),
      );
      await expectLater(
        repository.saveProfile(
          ProfileRecord(
            authUid: 'uid-a',
            displayName: ' ',
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        ),
        throwsA(isA<RecordValidationFailure>()),
      );
      await expectLater(
        repository.saveProfile(
          ProfileRecord(
            authUid: 'uid-a',
            displayName: 'User uid-a',
            createdAtUtc: now,
            updatedAtUtc: now.subtract(const Duration(days: 1)),
          ),
        ),
        throwsA(isA<RecordValidationFailure>()),
      );
    },
  );

  test('stale revisions and persisted invalid enum values fail closed', () async {
    await _saveProfileAs(repository, identity, 'uid-a');
    final stale = _record(id: 'revisioned', owner: 'uid-a');
    await repository.saveRecord(stale);
    await repository.saveRecord(
      _record(
        id: stale.id,
        owner: 'uid-a',
        revision: stale.revision,
        updated: stale.updatedAtUtc.add(const Duration(minutes: 1)),
        payload: '{"value":2}',
      ),
    );
    await expectLater(
      repository.saveRecord(stale),
      throwsA(isA<StaleRecordRevision>()),
    );

    await database.customStatement(
      "UPDATE stored_records SET kind = 'unknown' WHERE id = ?",
      ['revisioned'],
    );
    await expectLater(
      repository.watchVisibleRecords().first,
      throwsA(isA<RecordValidationFailure>()),
    );
    await database.customStatement(
      "UPDATE stored_records SET kind = 'task', visibility = 'unknown' WHERE id = ?",
      ['revisioned'],
    );
    await expectLater(
      repository.watchVisibleRecords().first,
      throwsA(isA<RecordValidationFailure>()),
    );
  });

  test('tombstones are idempotent and cannot be implicitly restored', () async {
    await _saveProfileAs(repository, identity, 'uid-a');
    final now = DateTime.utc(2026, 10, 14, 12);
    final saved = await repository.saveRecord(
      _record(id: 'task-1', owner: 'uid-a', created: now, updated: now),
    );
    await repository.deleteRecord('task-1', now.add(const Duration(days: 1)));
    await repository.deleteRecord('task-1', now.add(const Duration(days: 2)));

    expect(await repository.watchVisibleRecords().first, isEmpty);
    final row = await (database.select(
      database.storedRecords,
    )..where((table) => table.id.equals('task-1'))).getSingle();
    expect(row.revision, 2);
    expect(
      row.deletedAtUtcMs,
      now.add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
    await expectLater(
      repository.saveRecord(saved),
      throwsA(isA<DeletedRecordMutation>()),
    );
    await repository.deleteRecord('task-1', now);
    expect(row.revision, 2);
  });

  test('unresolved local conflict blocks edit and deletion', () async {
    await _saveProfileAs(repository, identity, 'uid-a');
    final saved = await repository.saveRecord(
      _record(id: 'conflicted', owner: 'uid-a'),
    );
    await (database.update(
      database.storedRecords,
    )..where((table) => table.id.equals(saved.id))).write(
      const StoredRecordsCompanion(
        syncStatus: Value('conflict'),
        remoteConflictJson: Value('{"remote":true}'),
      ),
    );

    await expectLater(
      repository.saveRecord(saved),
      throwsA(isA<UnresolvedRecordConflict>()),
    );
    await expectLater(
      repository.deleteRecord(saved.id, DateTime.utc(2026, 10, 15)),
      throwsA(isA<UnresolvedRecordConflict>()),
    );
  });

  test(
    'conflicts preserve full remote state and require an explicit match to clear',
    () async {
      final local = _record(id: 'record', owner: 'uid-a');
      final remote = _record(
        id: 'record',
        owner: 'uid-a',
        visibility: RecordVisibility.shared,
        revision: 2,
        payload: '{"remote":true}',
      );
      final conflict = applyRemoteSnapshot(local, remote);
      expect(conflict.syncStatus, RecordSyncStatus.conflict);
      expect(conflict.payloadJson, '{}');
      expect(conflict.remoteConflictJson, contains('"visibility":"shared"'));
      expect(conflict.remoteConflictJson, contains('"revision":2'));

      final resolved = applyRemoteSnapshot(
        _record(
          id: remote.id,
          owner: remote.ownerUid,
          visibility: remote.visibility,
          revision: remote.revision,
          payload: remote.payloadJson,
          updated: remote.updatedAtUtc,
        ),
        remote,
      );
      expect(resolved.syncStatus, RecordSyncStatus.synced);
      expect(resolved.remoteConflictJson, isNull);
      await expectLater(
        repository.synchronize(),
        throwsA(isA<SyncNotEnabled>()),
      );
    },
  );

  test(
    'version 1 database upgrades to version 3 without losing records',
    () async {
      await database.close();
      final executor = NativeDatabase.memory(
        setup: (db) {
          db.execute('''
          CREATE TABLE profiles (
            auth_uid TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            created_at_utc_ms INTEGER NOT NULL,
            updated_at_utc_ms INTEGER NOT NULL
          )
        ''');
          db.execute('''
          CREATE TABLE stored_records (
            id TEXT NOT NULL PRIMARY KEY,
            owner_uid TEXT NOT NULL REFERENCES profiles(auth_uid),
            kind TEXT NOT NULL,
            visibility TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at_utc_ms INTEGER NOT NULL,
            updated_at_utc_ms INTEGER NOT NULL,
            timezone_id TEXT,
            sync_status TEXT NOT NULL DEFAULT 'localOnly',
            revision INTEGER NOT NULL DEFAULT 1,
            last_synced_at_utc_ms INTEGER,
            remote_conflict_json TEXT
          )
        ''');
          db.execute("INSERT INTO profiles VALUES ('uid-a', 'A', 1, 1)");
          db.execute('''
          INSERT INTO stored_records (
            id, owner_uid, kind, visibility, payload_json,
            created_at_utc_ms, updated_at_utc_ms
          ) VALUES ('old', 'uid-a', 'task', 'private', '{}', 1, 1)
        ''');
          db.execute('PRAGMA user_version = 1');
        },
      );
      final upgraded = LifeDatabase.forTesting(executor);
      addTearDown(upgraded.close);

      final record = await (upgraded.select(
        upgraded.storedRecords,
      )..where((table) => table.id.equals('old'))).getSingle();
      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(record.id, 'old');
      expect(record.deletedAtUtcMs, isNull);
      expect(version.data['user_version'], 3);
      final historyTable = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'activity_history'",
          )
          .getSingleOrNull();
      expect(historyTable, isNotNull);
    },
  );

  test(
    'version 2 database adds history table without changing stored rows',
    () async {
      await database.close();
      final executor = NativeDatabase.memory(
        setup: (db) {
          db.execute('''CREATE TABLE profiles (
        auth_uid TEXT NOT NULL PRIMARY KEY,
        display_name TEXT NOT NULL,
        created_at_utc_ms INTEGER NOT NULL,
        updated_at_utc_ms INTEGER NOT NULL
      )''');
          db.execute('''CREATE TABLE stored_records (
        id TEXT NOT NULL PRIMARY KEY,
        owner_uid TEXT NOT NULL REFERENCES profiles(auth_uid),
        kind TEXT NOT NULL,
        visibility TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at_utc_ms INTEGER NOT NULL,
        updated_at_utc_ms INTEGER NOT NULL,
        timezone_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'localOnly',
        revision INTEGER NOT NULL DEFAULT 1,
        last_synced_at_utc_ms INTEGER,
        remote_conflict_json TEXT,
        deleted_at_utc_ms INTEGER
      )''');
          db.execute("INSERT INTO profiles VALUES ('uid-a', 'A', 1, 1)");
          db.execute(
            "INSERT INTO stored_records (id, owner_uid, kind, visibility, payload_json, created_at_utc_ms, updated_at_utc_ms) VALUES ('preserved', 'uid-a', 'task', 'private', '{\"title\":\"legacy\"}', 1, 1)",
          );
          db.execute('PRAGMA user_version = 2');
        },
      );
      final upgraded = LifeDatabase.forTesting(executor);
      addTearDown(upgraded.close);
      final record = await (upgraded.select(
        upgraded.storedRecords,
      )..where((t) => t.id.equals('preserved'))).getSingle();
      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(record.payloadJson, '{"title":"legacy"}');
      expect(record.deletedAtUtcMs, isNull);
      expect(version.data['user_version'], 3);
      await expectLater(
        upgraded
            .into(upgraded.activityHistory)
            .insert(
              ActivityHistoryCompanion.insert(
                id: 'history',
                ownerUid: 'uid-a',
                definitionId: 'preserved',
                kind: 'goalProgress',
                occurrenceKey: 'first',
                localDate: '2026-10-14',
                visibility: 'private',
                payloadJson: '{"value":1}',
                recordedAtUtcMs: 10,
              ),
            ),
        completes,
      );
    },
  );
}

class _FakeIdentity implements CurrentUserIdentity {
  _FakeIdentity(this._currentUid);

  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();
  String? _currentUid;

  @override
  String? get currentUid => _currentUid;

  set currentUid(String? uid) {
    _currentUid = uid;
    _changes.add(uid);
  }

  @override
  Stream<String?> get uidChanges => Stream<String?>.multi((controller) {
    controller.add(_currentUid);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  Future<void> dispose() => _changes.close();
}

class _TrackingDatabase extends LifeDatabase {
  _TrackingDatabase(super.executor) : super.forTesting();

  bool closeStarted = false;

  @override
  Future<void> close() {
    closeStarted = true;
    return super.close();
  }
}

Future<void> _saveProfileAs(
  LifeRecordRepository repository,
  _FakeIdentity identity,
  String uid,
) async {
  identity.currentUid = uid;
  final now = DateTime.utc(2026, 10, 14);
  await repository.saveProfile(_profile(uid, now));
}

ProfileRecord _profile(String uid, DateTime created, {int updatedDay = 14}) =>
    ProfileRecord(
      authUid: uid,
      displayName: 'User $uid',
      createdAtUtc: created,
      updatedAtUtc: DateTime.utc(created.year, created.month, updatedDay),
    );

LifeRecord _record({
  required String id,
  required String owner,
  RecordVisibility visibility = RecordVisibility.private,
  String payload = '{}',
  DateTime? created,
  DateTime? updated,
  String? timezoneId,
  int revision = 1,
  RecordSyncStatus syncStatus = RecordSyncStatus.localOnly,
  DateTime? lastSyncedAtUtc,
  String? remoteConflictJson,
  DateTime? deletedAtUtc,
}) {
  final now = DateTime.utc(2026, 10, 14);
  return LifeRecord(
    id: id,
    ownerUid: owner,
    kind: LifeRecordKind.task,
    visibility: visibility,
    payloadJson: payload,
    createdAtUtc: created ?? now,
    updatedAtUtc: updated ?? now,
    timezoneId: timezoneId,
    revision: revision,
    syncStatus: syncStatus,
    lastSyncedAtUtc: lastSyncedAtUtc,
    remoteConflictJson: remoteConflictJson,
    deletedAtUtc: deletedAtUtc,
  );
}
