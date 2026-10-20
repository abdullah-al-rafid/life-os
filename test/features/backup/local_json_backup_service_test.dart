import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/backup/data/local_json_backup_service.dart';
import 'package:life_os/features/backup/domain/local_backup.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';

void main() {
  setUpAll(() {
    // The round-trip tests intentionally open independent in-memory databases.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late LifeDatabase source;
  late LifeDatabase destination;
  late _Identity identity;

  setUp(() {
    source = LifeDatabase.forTesting(NativeDatabase.memory());
    destination = LifeDatabase.forTesting(NativeDatabase.memory());
    identity = _Identity('test-account-uid');
  });

  tearDown(() async {
    await source.close();
    await destination.close();
    await identity.close();
  });

  LocalJsonBackupService service(LifeDatabase db) =>
      LocalJsonBackupService(database: db, identity: identity);

  test(
    'round trips records, append-only history, tracking and plan receipts',
    () async {
      await _seed(source, identity.currentUid!);
      final bytes = await service(source).exportJson();
      final raw = utf8.decode(bytes);
      expect(raw, contains('life_os_local_backup'));
      expect(raw, isNot(contains(identity.currentUid!)));

      final preview = await service(destination).preview(bytes);
      expect(preview.canRestore, isTrue);
      expect(preview.fileCounts.records, 1);
      expect(preview.fileCounts.history, 1);
      expect(preview.fileCounts.tracking, 1);
      expect(preview.fileCounts.importReceipts, 1);
      final result = await service(destination).restore(preview);
      expect(result.added.total, 4);
      expect(
        (await destination.select(destination.storedRecords).get()).single.id,
        'task-1',
      );
      expect(
        (await destination.select(destination.activityHistory).get())
            .single
            .payloadJson,
        contains('evidenceReferenceAvailable'),
      );
      expect(
        (await destination.select(destination.trackingEntries).get())
            .single
            .ownerUid,
        identity.currentUid,
      );
      expect(
        (await destination.select(destination.taskPlanImports).get())
            .single
            .taskIdsJson,
        '["task-1"]',
      );
    },
  );

  test(
    'rejects invalid JSON, foreign account, and unsupported versions',
    () async {
      final invalid = await service(
        destination,
      ).preview(Uint8List.fromList(utf8.encode('{bad')));
      expect(invalid.errors.single, contains('UTF-8 JSON'));

      final bytes = await service(source).exportJson();
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      envelope['version'] = 99;
      final unsupported = await service(
        destination,
      ).preview(Uint8List.fromList(utf8.encode(jsonEncode(envelope))));
      expect(unsupported.errors.single, contains('not supported'));

      identity.currentUid = 'different-account-uid';
      final mismatch = await service(destination).preview(bytes);
      expect(mismatch.accountMatches, isFalse);
      expect(mismatch.canRestore, isFalse);
      expect(
        (await destination.select(destination.storedRecords).get()),
        isEmpty,
      );
    },
  );

  test(
    'skips exact duplicates and preserves existing records on conflict',
    () async {
      await _seed(source, identity.currentUid!);
      final bytes = await service(source).exportJson();
      await _seed(destination, identity.currentUid!);
      final duplicatePreview = await service(destination).preview(bytes);
      expect(duplicatePreview.additions.total, 0);
      expect(duplicatePreview.duplicates.total, 4);

      await (destination.update(
        destination.storedRecords,
      )..where((row) => row.id.equals('task-1'))).write(
        const StoredRecordsCompanion(payloadJson: Value('{"title":"local"}')),
      );
      final conflict = await service(destination).preview(bytes);
      expect(conflict.errors.join(), contains('Nothing will be overwritten'));
      expect(conflict.canRestore, isFalse);
      expect(
        (await destination.select(destination.storedRecords).getSingle())
            .payloadJson,
        '{"title":"local"}',
      );
    },
  );

  test('adds a backup alongside unrelated pre-existing records', () async {
    await _seed(source, identity.currentUid!);
    await _insertProfile(destination, identity.currentUid!);
    await destination
        .into(destination.storedRecords)
        .insert(
          StoredRecordsCompanion.insert(
            id: 'already-here',
            ownerUid: identity.currentUid!,
            kind: 'goal',
            visibility: 'private',
            payloadJson: '{"title":"Keep this"}',
            createdAtUtcMs: 1,
            updatedAtUtcMs: 1,
          ),
        );
    final backup = await service(source).exportJson();
    final preview = await service(destination).preview(backup);
    expect(preview.canRestore, isTrue);
    final result = await service(destination).restore(preview);
    expect(result.added.total, 4);
    final records = await destination.select(destination.storedRecords).get();
    expect(records.map((row) => row.id).toSet(), {'already-here', 'task-1'});
    expect(
      records.singleWhere((row) => row.id == 'already-here').payloadJson,
      '{"title":"Keep this"}',
    );
  });

  test(
    'malformed partial input is reported and makes no database changes',
    () async {
      final bytes = await service(source).exportJson();
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      envelope['records'] = [
        {'id': 'bad', 'kind': 'not-a-kind'},
      ];
      final preview = await service(
        destination,
      ).preview(Uint8List.fromList(utf8.encode(jsonEncode(envelope))));
      expect(preview.fileCounts.records, 1);
      expect(preview.errors, isNotEmpty);
      expect(preview.canRestore, isFalse);
      await expectLater(
        service(destination).restore(preview),
        throwsA(isA<LocalBackupFailure>()),
      );
      expect(
        await destination.select(destination.storedRecords).get(),
        isEmpty,
      );
    },
  );

  test(
    'export excludes other account data, UID fields, evidence keys and contents',
    () async {
      await _seed(source, identity.currentUid!);
      await _insertProfile(source, 'other-account-uid');
      await source
          .into(source.storedRecords)
          .insert(
            StoredRecordsCompanion.insert(
              id: 'other-private',
              ownerUid: 'other-account-uid',
              kind: 'task',
              visibility: 'private',
              payloadJson: '{"title":"private to peer"}',
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          );
      final text = utf8.decode(await service(source).exportJson());
      expect(text, isNot(contains('other-private')));
      expect(text, isNot(contains('other-account-uid')));
      expect(text, isNot(contains('secret-evidence-content')));
      expect(text, isNot(contains('evidence-storage-key')));
      expect(text, contains('scan.jpg'));
      expect(text, contains('fileIncluded'));
    },
  );
}

Future<void> _seed(LifeDatabase db, String uid) async {
  await _insertProfile(db, uid);
  await db
      .into(db.storedRecords)
      .insert(
        StoredRecordsCompanion.insert(
          id: 'task-1',
          ownerUid: uid,
          kind: 'task',
          visibility: 'private',
          payloadJson: jsonEncode({
            'title': 'Read',
            'evidence': [
              {
                'name': 'scan.jpg',
                'key': 'evidence-storage-key',
                'contents': 'secret-evidence-content',
              },
            ],
          }),
          createdAtUtcMs: 1,
          updatedAtUtcMs: 1,
        ),
      );
  await db
      .into(db.activityHistory)
      .insert(
        ActivityHistoryCompanion.insert(
          id: 'history-1',
          ownerUid: uid,
          definitionId: 'task-1',
          kind: 'taskCompletion',
          occurrenceKey: 'day-1',
          localDate: '2026-10-14',
          visibility: 'private',
          payloadJson: '{"status":"done","evidenceReference":"private-key"}',
          recordedAtUtcMs: 2,
        ),
      );
  await db
      .into(db.trackingEntries)
      .insert(
        TrackingEntriesCompanion.insert(
          id: 'tracking-1',
          ownerUid: uid,
          kind: 'fasting',
          localDate: '2026-10-14',
          entryKey: 'daily',
          visibility: 'private',
          payloadJson: '{"status":"fasted"}',
          createdAtUtcMs: 1,
          updatedAtUtcMs: 1,
        ),
      );
  await db
      .into(db.taskPlanImports)
      .insert(
        TaskPlanImportsCompanion.insert(
          id: 'receipt-1',
          ownerUid: uid,
          sourceFingerprint: 'fingerprint',
          startDate: '2026-10-01',
          parserVersion: 'v1',
          taskIdsJson: '["task-1"]',
          importedAtUtcMs: 3,
        ),
      );
}

Future<void> _insertProfile(LifeDatabase db, String uid) async {
  await db
      .into(db.profiles)
      .insert(
        ProfilesCompanion.insert(
          authUid: uid,
          displayName: 'Test user',
          createdAtUtcMs: 1,
          updatedAtUtcMs: 1,
        ),
      );
}

class _Identity implements CurrentUserIdentity {
  _Identity(this.currentUid);
  @override
  String? currentUid;
  @override
  Stream<String?> get uidChanges => Stream.value(currentUid);
  Future<void> close() async {}
}
