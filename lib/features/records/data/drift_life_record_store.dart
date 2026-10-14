import 'package:drift/drift.dart';

import '../../../core/database/life_database.dart';
import '../domain/life_record.dart';
import '../domain/life_record_repository.dart';

class DriftLifeRecordStore implements LifeRecordLocalStore {
  const DriftLifeRecordStore(this._database);

  final LifeDatabase _database;

  @override
  Future<void> saveProfile(ProfileRecord profile) async {
    validateProfileRecord(profile);
    _requireUid(profile.authUid);
    await _database.transaction(() async {
      final existing = await findProfile(profile.authUid);
      if (existing != null &&
          profile.updatedAtUtc.isBefore(existing.updatedAtUtc)) {
        throw const StaleRecordRevision();
      }
      await _database
          .into(_database.profiles)
          .insertOnConflictUpdate(
            ProfilesCompanion.insert(
              authUid: profile.authUid,
              displayName: profile.displayName,
              createdAtUtcMs: (existing?.createdAtUtc ?? profile.createdAtUtc)
                  .toUtc()
                  .millisecondsSinceEpoch,
              updatedAtUtcMs: profile.updatedAtUtc
                  .toUtc()
                  .millisecondsSinceEpoch,
            ),
          );
    });
  }

  @override
  Future<ProfileRecord?> findProfile(String authUid) async {
    _requireUid(authUid);
    final row = await (_database.select(
      _database.profiles,
    )..where((table) => table.authUid.equals(authUid))).getSingleOrNull();
    if (row == null) return null;
    final profile = ProfileRecord(
      authUid: row.authUid,
      displayName: row.displayName,
      createdAtUtc: _utc(row.createdAtUtcMs),
      updatedAtUtc: _utc(row.updatedAtUtcMs),
    );
    validateProfileRecord(profile);
    return profile;
  }

  @override
  Future<LifeRecord?> findVisibleRecord(String id, String viewerUid) async {
    _requireUid(viewerUid);
    final row =
        await (_database.select(_database.storedRecords)..where(
              (table) =>
                  table.id.equals(id) &
                  table.deletedAtUtcMs.isNull() &
                  (table.ownerUid.equals(viewerUid) |
                      table.visibility.equals(RecordVisibility.shared.name)),
            ))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<LifeRecord> saveOwnedRecord(LifeRecord record, String actorUid) async {
    _requireUid(actorUid);
    _requireUid(record.ownerUid);
    if (record.ownerUid != actorUid) throw const OwnershipViolation();
    validateLifeRecord(record, localMutation: true);

    return _database.transaction(() async {
      final existing = await (_database.select(
        _database.storedRecords,
      )..where((table) => table.id.equals(record.id))).getSingleOrNull();
      if (existing != null && existing.ownerUid != actorUid) {
        throw const OwnershipViolation();
      }
      if (existing == null && record.revision != 1) {
        throw const RecordValidationFailure(
          'New records must begin at revision 1.',
        );
      }
      if (existing != null) {
        final existingStatus = _syncStatus(existing.syncStatus);
        if (existingStatus == RecordSyncStatus.conflict) {
          throw const UnresolvedRecordConflict();
        }
        if (existing.deletedAtUtcMs != null) {
          throw const DeletedRecordMutation();
        }
        if (existing.revision < 1 || record.revision != existing.revision) {
          throw const StaleRecordRevision();
        }
        if (record.updatedAtUtc.isBefore(_utc(existing.updatedAtUtcMs))) {
          throw const StaleRecordRevision();
        }
        if (existing.updatedAtUtcMs < existing.createdAtUtcMs) {
          throw const RecordValidationFailure(
            'Stored record timestamps are inconsistent.',
          );
        }
      }

      final saved = LifeRecord(
        id: record.id,
        ownerUid: actorUid,
        kind: record.kind,
        visibility: record.visibility,
        payloadJson: record.payloadJson,
        createdAtUtc: existing == null
            ? record.createdAtUtc.toUtc()
            : _utc(existing.createdAtUtcMs),
        updatedAtUtc: record.updatedAtUtc.toUtc(),
        timezoneId: record.timezoneId,
        syncStatus: RecordSyncStatus.localOnly,
        revision: existing == null ? 1 : existing.revision + 1,
        deletedAtUtc: null,
      );
      await _database
          .into(_database.storedRecords)
          .insertOnConflictUpdate(_toCompanion(saved));
      return saved;
    });
  }

  @override
  Future<void> softDeleteOwnedRecord(
    String id,
    String actorUid,
    DateTime atUtc,
  ) async {
    _requireUid(actorUid);
    _requireUid(id);
    await _database.transaction(() async {
      final existing = await (_database.select(
        _database.storedRecords,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (existing == null) return;
      if (existing.ownerUid != actorUid) throw const OwnershipViolation();
      if (existing.deletedAtUtcMs != null) return;
      if (_syncStatus(existing.syncStatus) == RecordSyncStatus.conflict) {
        throw const UnresolvedRecordConflict();
      }
      if (existing.revision < 1 ||
          existing.updatedAtUtcMs < existing.createdAtUtcMs ||
          atUtc.toUtc().millisecondsSinceEpoch < existing.updatedAtUtcMs) {
        throw const StaleRecordRevision();
      }
      await (_database.update(
        _database.storedRecords,
      )..where((table) => table.id.equals(id))).write(
        StoredRecordsCompanion(
          deletedAtUtcMs: Value(atUtc.toUtc().millisecondsSinceEpoch),
          updatedAtUtcMs: Value(atUtc.toUtc().millisecondsSinceEpoch),
          syncStatus: const Value('localOnly'),
          revision: Value(existing.revision + 1),
        ),
      );
    });
  }

  @override
  Stream<List<LifeRecord>> watchVisibleRecords(String viewerUid) {
    _requireUid(viewerUid);
    return (_database.select(_database.storedRecords)..where(
          (table) =>
              table.deletedAtUtcMs.isNull() &
              (table.ownerUid.equals(viewerUid) |
                  table.visibility.equals(RecordVisibility.shared.name)),
        ))
        .watch()
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  StoredRecordsCompanion _toCompanion(LifeRecord record) =>
      StoredRecordsCompanion.insert(
        id: record.id,
        ownerUid: record.ownerUid,
        kind: record.kind.name,
        visibility: record.visibility.name,
        payloadJson: record.payloadJson,
        createdAtUtcMs: record.createdAtUtc.millisecondsSinceEpoch,
        updatedAtUtcMs: record.updatedAtUtc.millisecondsSinceEpoch,
        timezoneId: Value(record.timezoneId),
        syncStatus: Value(record.syncStatus.name),
        revision: Value(record.revision),
        lastSyncedAtUtcMs: Value(
          record.lastSyncedAtUtc?.millisecondsSinceEpoch,
        ),
        remoteConflictJson: Value(record.remoteConflictJson),
        deletedAtUtcMs: Value(record.deletedAtUtc?.millisecondsSinceEpoch),
      );

  LifeRecord _fromRow(StoredRecord row) {
    final record = LifeRecord(
      id: row.id,
      ownerUid: row.ownerUid,
      kind: _kind(row.kind),
      visibility: _visibility(row.visibility),
      payloadJson: row.payloadJson,
      createdAtUtc: _utc(row.createdAtUtcMs),
      updatedAtUtc: _utc(row.updatedAtUtcMs),
      timezoneId: row.timezoneId,
      syncStatus: _syncStatus(row.syncStatus),
      revision: row.revision,
      lastSyncedAtUtc: row.lastSyncedAtUtcMs == null
          ? null
          : _utc(row.lastSyncedAtUtcMs!),
      remoteConflictJson: row.remoteConflictJson,
      deletedAtUtc: row.deletedAtUtcMs == null
          ? null
          : _utc(row.deletedAtUtcMs!),
    );
    validateLifeRecord(record);
    return record;
  }

  DateTime _utc(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);

  RecordSyncStatus _syncStatus(String value) {
    try {
      return RecordSyncStatus.values.byName(value);
    } on ArgumentError {
      throw const RecordValidationFailure(
        'Stored record has an unknown synchronization state.',
      );
    }
  }

  LifeRecordKind _kind(String value) {
    try {
      return LifeRecordKind.values.byName(value);
    } on ArgumentError {
      throw const RecordValidationFailure('Stored record has an unknown kind.');
    }
  }

  RecordVisibility _visibility(String value) {
    try {
      return RecordVisibility.values.byName(value);
    } on ArgumentError {
      throw const RecordValidationFailure(
        'Stored record has an unknown visibility value.',
      );
    }
  }

  void _requireUid(String uid) {
    if (uid.trim().isEmpty) throw ArgumentError.value(uid, 'uid');
  }
}
