import 'package:drift/drift.dart';

import '../../../core/database/life_database.dart';

/// Local pending assignment. Its key and payload survive screen/app restarts,
/// but records are always selected by the Firebase owner UID.
class PendingSharedTaskAssignment {
  const PendingSharedTaskAssignment({
    required this.ownerUid,
    required this.idempotencyKey,
    required this.title,
    required this.date,
    required this.priority,
    required this.durationMinutes,
    required this.deadline,
    required this.notes,
  });

  final String ownerUid;
  final String idempotencyKey;
  final String title;
  final String date;
  final int priority;
  final int durationMinutes;
  final String? deadline;
  final String notes;

  @override
  bool operator ==(Object other) =>
      other is PendingSharedTaskAssignment &&
      ownerUid == other.ownerUid &&
      idempotencyKey == other.idempotencyKey &&
      title == other.title &&
      date == other.date &&
      priority == other.priority &&
      durationMinutes == other.durationMinutes &&
      deadline == other.deadline &&
      notes == other.notes;

  @override
  int get hashCode => Object.hash(
    ownerUid,
    idempotencyKey,
    title,
    date,
    priority,
    durationMinutes,
    deadline,
    notes,
  );
}

class SharedTaskAssignmentOutboxStore {
  const SharedTaskAssignmentOutboxStore(this._database);

  final LifeDatabase _database;

  Future<PendingSharedTaskAssignment?> pendingFor(String ownerUid) async {
    final rows = await (_database.select(
      _database.sharedTaskAssignmentOutbox,
    )..where((row) => row.ownerUid.equals(ownerUid))).get();
    if (rows.isEmpty) return null;
    final row = rows.single;
    return PendingSharedTaskAssignment(
      ownerUid: row.ownerUid,
      idempotencyKey: row.idempotencyKey,
      title: row.title,
      date: row.date,
      priority: row.priority,
      durationMinutes: row.durationMinutes,
      deadline: row.deadline,
      notes: row.notes,
    );
  }

  Future<void> save(PendingSharedTaskAssignment assignment) async {
    await _database
        .into(_database.sharedTaskAssignmentOutbox)
        .insertOnConflictUpdate(
          SharedTaskAssignmentOutboxCompanion.insert(
            ownerUid: assignment.ownerUid,
            idempotencyKey: assignment.idempotencyKey,
            title: assignment.title,
            date: assignment.date,
            priority: assignment.priority,
            durationMinutes: assignment.durationMinutes,
            deadline: Value(assignment.deadline),
            notes: assignment.notes,
            queuedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> remove(PendingSharedTaskAssignment assignment) async {
    await (_database.delete(_database.sharedTaskAssignmentOutbox)..where(
          (row) =>
              row.ownerUid.equals(assignment.ownerUid) &
              row.idempotencyKey.equals(assignment.idempotencyKey),
        ))
        .go();
  }
}
