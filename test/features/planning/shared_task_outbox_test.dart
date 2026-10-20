import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/planning/data/shared_task_assignment_outbox.dart';

void main() {
  late LifeDatabase database;
  late SharedTaskAssignmentOutboxStore outbox;

  setUp(() {
    database = LifeDatabase.forTesting(NativeDatabase.memory());
    outbox = SharedTaskAssignmentOutboxStore(database);
  });

  tearDown(() async => database.close());

  test(
    'pending assignment is durable in Drift and scoped to its owner UID',
    () async {
      final pending = _assignment('owner-a', 'stable-key');
      await outbox.save(pending);

      expect(await outbox.pendingFor('owner-a'), equals(pending));
      expect(await outbox.pendingFor('owner-b'), isNull);
    },
  );

  test(
    'removing an old retry cannot remove a newer queued assignment',
    () async {
      final old = _assignment('owner-a', 'old-key');
      final current = _assignment('owner-a', 'current-key');
      await outbox.save(old);
      await outbox.save(current);

      await outbox.remove(old);

      expect(await outbox.pendingFor('owner-a'), equals(current));
    },
  );

  test('outbox operations preserve private local records', () async {
    await database
        .into(database.profiles)
        .insert(
          ProfilesCompanion.insert(
            authUid: 'owner-a',
            displayName: 'Local profile',
            createdAtUtcMs: 1,
            updatedAtUtcMs: 1,
          ),
        );
    await database
        .into(database.storedRecords)
        .insert(
          StoredRecordsCompanion.insert(
            id: 'private-record',
            ownerUid: 'owner-a',
            kind: 'task',
            visibility: 'private',
            payloadJson: '{"title":"private"}',
            createdAtUtcMs: 1,
            updatedAtUtcMs: 1,
          ),
        );
    final assignment = _assignment('owner-a', 'stable-key');
    await outbox.save(assignment);
    await outbox.remove(assignment);

    final records = await database.select(database.storedRecords).get();
    expect(records, hasLength(1));
    expect(records.single.id, 'private-record');
    expect(records.single.payloadJson, '{"title":"private"}');
  });
}

PendingSharedTaskAssignment _assignment(String ownerUid, String key) =>
    PendingSharedTaskAssignment(
      ownerUid: ownerUid,
      idempotencyKey: key,
      title: 'Explicit shared task',
      date: '2026-10-15',
      priority: 2,
      durationMinutes: 30,
      deadline: null,
      notes: 'Only task payload',
    );
