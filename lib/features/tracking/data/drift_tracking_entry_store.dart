import 'package:drift/drift.dart';

import '../../../core/database/life_database.dart';
import '../../records/domain/life_record.dart';
import '../domain/tracking_entry.dart';
import '../domain/tracking_entry_repository.dart';

class DriftTrackingEntryStore implements TrackingEntryStore {
  const DriftTrackingEntryStore(this.database);
  final LifeDatabase database;

  @override
  Future<TrackingEntry?> findVisible(String id, String viewerUid) async {
    final row =
        await (database.select(database.trackingEntries)..where(
              (entry) =>
                  entry.id.equals(id) &
                  entry.deletedAtUtcMs.isNull() &
                  (entry.ownerUid.equals(viewerUid) |
                      entry.visibility.equals(RecordVisibility.shared.name)),
            ))
            .getSingleOrNull();
    return row == null ? null : _fromData(row);
  }

  @override
  Future<TrackingEntry> insert(TrackingEntry entry) async {
    final duplicate = await _findActiveKey(entry);
    if (duplicate) throw const DuplicateTrackingEntry();
    try {
      await database.into(database.trackingEntries).insert(_toCompanion(entry));
    } on Object {
      // The partial unique indexes remain authoritative for concurrent writes.
      if (await _findActiveKey(entry)) {
        throw const DuplicateTrackingEntry();
      }
      rethrow;
    }
    return entry;
  }

  @override
  Future<TrackingEntry> update(
    TrackingEntry entry, {
    required int expectedRevision,
  }) async {
    final changed =
        await (database.update(database.trackingEntries)..where(
              (row) =>
                  row.id.equals(entry.id) &
                  row.ownerUid.equals(entry.ownerUid) &
                  row.revision.equals(expectedRevision) &
                  row.deletedAtUtcMs.isNull(),
            ))
            .write(
              TrackingEntriesCompanion(
                visibility: Value(entry.visibility.name),
                payloadJson: Value(entry.payloadJson),
                updatedAtUtcMs: Value(
                  entry.updatedAtUtc.millisecondsSinceEpoch,
                ),
                revision: Value(entry.revision),
              ),
            );
    if (changed == 0) await _throwUpdateFailure(entry, expectedRevision);
    return entry;
  }

  @override
  Future<void> softDelete(
    String id,
    String ownerUid,
    int expectedRevision,
    DateTime atUtc,
  ) async {
    final changed =
        await (database.update(database.trackingEntries)..where(
              (row) =>
                  row.id.equals(id) &
                  row.ownerUid.equals(ownerUid) &
                  row.revision.equals(expectedRevision) &
                  row.deletedAtUtcMs.isNull(),
            ))
            .write(
              TrackingEntriesCompanion(
                updatedAtUtcMs: Value(atUtc.millisecondsSinceEpoch),
                revision: Value(expectedRevision + 1),
                deletedAtUtcMs: Value(atUtc.millisecondsSinceEpoch),
              ),
            );
    if (changed == 0) {
      final row = await (database.select(
        database.trackingEntries,
      )..where((entry) => entry.id.equals(id))).getSingleOrNull();
      if (row == null || row.ownerUid != ownerUid) {
        throw const TrackingEntryNotFound();
      }
      if (row.deletedAtUtcMs != null) {
        throw const DeletedTrackingEntryMutation();
      }
      throw const StaleTrackingEntryRevision();
    }
  }

  @override
  Stream<List<TrackingEntry>> watchVisible(
    String viewerUid, {
    TrackingEntryKind? kind,
    String? localDate,
  }) {
    final query = database.select(database.trackingEntries)
      ..where(
        (entry) =>
            entry.deletedAtUtcMs.isNull() &
            (entry.ownerUid.equals(viewerUid) |
                entry.visibility.equals(RecordVisibility.shared.name)) &
            (kind == null
                ? const Constant(true)
                : entry.kind.equals(kind.name)) &
            (localDate == null
                ? const Constant(true)
                : entry.localDate.equals(localDate)),
      )
      ..orderBy([
        (entry) => OrderingTerm.desc(entry.localDate),
        (entry) => OrderingTerm.asc(entry.kind),
        (entry) => OrderingTerm.asc(entry.entryKey),
      ]);
    return query.watch().map(
      (rows) => rows.map(_fromData).toList(growable: false),
    );
  }

  Future<bool> _findActiveKey(TrackingEntry entry) async {
    final row =
        await (database.select(database.trackingEntries)..where(
              (row) =>
                  row.ownerUid.equals(entry.ownerUid) &
                  row.kind.equals(entry.kind.name) &
                  row.localDate.equals(entry.localDate) &
                  row.entryKey.equals(entry.entryKey) &
                  row.deletedAtUtcMs.isNull(),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> _throwUpdateFailure(
    TrackingEntry entry,
    int expectedRevision,
  ) async {
    final row =
        await (database.select(database.trackingEntries)..where(
              (candidate) =>
                  candidate.id.equals(entry.id) &
                  candidate.ownerUid.equals(entry.ownerUid),
            ))
            .getSingleOrNull();
    if (row == null) throw const TrackingEntryNotFound();
    if (row.deletedAtUtcMs != null) {
      throw const DeletedTrackingEntryMutation();
    }
    if (row.revision != expectedRevision) {
      throw const StaleTrackingEntryRevision();
    }
    throw const TrackingEntryNotFound();
  }

  TrackingEntriesCompanion _toCompanion(TrackingEntry entry) =>
      TrackingEntriesCompanion.insert(
        id: entry.id,
        ownerUid: entry.ownerUid,
        kind: entry.kind.name,
        localDate: entry.localDate,
        entryKey: entry.entryKey,
        visibility: entry.visibility.name,
        payloadJson: entry.payloadJson,
        createdAtUtcMs: entry.createdAtUtc.millisecondsSinceEpoch,
        updatedAtUtcMs: entry.updatedAtUtc.millisecondsSinceEpoch,
        revision: Value(entry.revision),
      );

  TrackingEntry _fromData(TrackingEntryRow row) {
    try {
      final entry = TrackingEntry(
        id: row.id,
        ownerUid: row.ownerUid,
        kind: TrackingEntryKind.values.byName(row.kind),
        localDate: row.localDate,
        entryKey: row.entryKey,
        visibility: RecordVisibility.values.byName(row.visibility),
        payloadJson: row.payloadJson,
        createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
          row.createdAtUtcMs,
          isUtc: true,
        ),
        updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
          row.updatedAtUtcMs,
          isUtc: true,
        ),
        revision: row.revision,
        deletedAtUtc: row.deletedAtUtcMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                row.deletedAtUtcMs!,
                isUtc: true,
              ),
      );
      validateTrackingEntry(entry);
      return entry;
    } on ArgumentError {
      throw const TrackingEntryValidationFailure(
        'Stored tracking entry has an unknown kind or visibility.',
      );
    }
  }
}
