import 'dart:convert';

enum LifeRecordKind {
  task,
  routine,
  goal,
  habit,
  prayer,
  fasting,
  learningEvidence,
  screenTimeSummary,
}

enum RecordVisibility { private, shared }

enum RecordSyncStatus { localOnly, pendingUpload, synced, conflict, failed }

class ProfileRecord {
  const ProfileRecord({
    required this.authUid,
    required this.displayName,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String authUid;
  final String displayName;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
}

class LifeRecord {
  const LifeRecord({
    required this.id,
    required this.ownerUid,
    required this.kind,
    required this.visibility,
    required this.payloadJson,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.timezoneId,
    this.syncStatus = RecordSyncStatus.localOnly,
    this.revision = 1,
    this.lastSyncedAtUtc,
    this.remoteConflictJson,
    this.deletedAtUtc,
  });

  final String id;
  final String ownerUid;
  final LifeRecordKind kind;
  final RecordVisibility visibility;
  final String payloadJson;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String? timezoneId;
  final RecordSyncStatus syncStatus;
  final int revision;
  final DateTime? lastSyncedAtUtc;
  final String? remoteConflictJson;
  final DateTime? deletedAtUtc;
}

class OwnershipViolation implements Exception {
  const OwnershipViolation();

  @override
  String toString() => 'A user may only change their own local records.';
}

class UnauthenticatedOperation implements Exception {
  const UnauthenticatedOperation();

  @override
  String toString() => 'Sign in before accessing LIFE OS records.';
}

class RecordValidationFailure implements Exception {
  const RecordValidationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class StaleRecordRevision implements Exception {
  const StaleRecordRevision();

  @override
  String toString() => 'This record changed. Reload it before saving again.';
}

class DeletedRecordMutation implements Exception {
  const DeletedRecordMutation();

  @override
  String toString() =>
      'Deleted records cannot be edited or restored implicitly.';
}

class UnresolvedRecordConflict implements Exception {
  const UnresolvedRecordConflict();

  @override
  String toString() =>
      'Resolve the record conflict before changing this record.';
}

void validateProfileRecord(ProfileRecord profile) {
  _requireNonEmpty(profile.authUid, 'authUid');
  _requireNonEmpty(profile.displayName, 'displayName');
  if (profile.updatedAtUtc.isBefore(profile.createdAtUtc)) {
    throw const RecordValidationFailure(
      'Profile updatedAtUtc cannot be earlier than createdAtUtc.',
    );
  }
}

void validateLifeRecord(LifeRecord record, {bool localMutation = false}) {
  _requireNonEmpty(record.id, 'id');
  _requireNonEmpty(record.ownerUid, 'ownerUid');
  if (record.revision < 1) {
    throw const RecordValidationFailure('Record revision must be at least 1.');
  }
  if (record.updatedAtUtc.isBefore(record.createdAtUtc)) {
    throw const RecordValidationFailure(
      'Record updatedAtUtc cannot be earlier than createdAtUtc.',
    );
  }
  if (record.deletedAtUtc != null &&
      record.deletedAtUtc!.isBefore(record.updatedAtUtc)) {
    throw const RecordValidationFailure(
      'deletedAtUtc cannot be earlier than updatedAtUtc.',
    );
  }
  if (record.timezoneId != null &&
      (record.timezoneId!.trim().isEmpty ||
          record.timezoneId != record.timezoneId!.trim())) {
    throw const RecordValidationFailure(
      'timezoneId must be non-empty and trimmed when supplied.',
    );
  }
  if (record.syncStatus == RecordSyncStatus.localOnly &&
      (record.lastSyncedAtUtc != null || record.remoteConflictJson != null)) {
    throw const RecordValidationFailure(
      'localOnly records cannot include synced or conflict metadata.',
    );
  }
  if (record.syncStatus == RecordSyncStatus.synced &&
      (record.lastSyncedAtUtc == null || record.remoteConflictJson != null)) {
    throw const RecordValidationFailure(
      'synced records need a sync timestamp and cannot include conflict data.',
    );
  }
  if (record.syncStatus == RecordSyncStatus.conflict &&
      (record.lastSyncedAtUtc != null || record.remoteConflictJson == null)) {
    throw const RecordValidationFailure(
      'conflict records need a remote snapshot and cannot be marked synced.',
    );
  }
  if (record.lastSyncedAtUtc != null &&
      record.lastSyncedAtUtc!.isBefore(record.createdAtUtc)) {
    throw const RecordValidationFailure(
      'lastSyncedAtUtc cannot be earlier than createdAtUtc.',
    );
  }
  if (record.remoteConflictJson != null) {
    _requireJsonObject(record.remoteConflictJson!);
  }
  _requireJsonObject(record.payloadJson);

  if (localMutation &&
      (record.syncStatus != RecordSyncStatus.localOnly ||
          record.lastSyncedAtUtc != null ||
          record.remoteConflictJson != null ||
          record.deletedAtUtc != null)) {
    throw const RecordValidationFailure(
      'Local writes cannot set synchronization, conflict, or deletion metadata.',
    );
  }
}

void _requireNonEmpty(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw RecordValidationFailure('$field must be non-empty and trimmed.');
  }
}

void _requireJsonObject(String value) {
  Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    throw const RecordValidationFailure('Record payload must be valid JSON.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const RecordValidationFailure(
      'Record payload must be a JSON object.',
    );
  }
}

class SyncNotEnabled implements Exception {
  const SyncNotEnabled();

  @override
  String toString() =>
      'Remote synchronization is disabled until server security rules are implemented and tested.';
}

/// A remote snapshot is held for review; divergent edits are never auto-merged.
LifeRecord applyRemoteSnapshot(LifeRecord local, LifeRecord remote) {
  validateLifeRecord(local);
  validateLifeRecord(remote);
  if (local.id != remote.id || local.ownerUid != remote.ownerUid) {
    throw const OwnershipViolation();
  }
  if (local.revision == remote.revision &&
      local.kind == remote.kind &&
      local.visibility == remote.visibility &&
      local.payloadJson == remote.payloadJson &&
      local.timezoneId == remote.timezoneId &&
      local.deletedAtUtc == remote.deletedAtUtc) {
    return local.copyWithSync(
      status: RecordSyncStatus.synced,
      lastSyncedAtUtc: remote.updatedAtUtc,
      conflictJson: null,
    );
  }
  return local.copyWithSync(
    status: RecordSyncStatus.conflict,
    lastSyncedAtUtc: null,
    conflictJson: jsonEncode({
      'id': remote.id,
      'ownerUid': remote.ownerUid,
      'kind': remote.kind.name,
      'visibility': remote.visibility.name,
      'payloadJson': remote.payloadJson,
      'createdAtUtcMs': remote.createdAtUtc.toUtc().millisecondsSinceEpoch,
      'updatedAtUtcMs': remote.updatedAtUtc.toUtc().millisecondsSinceEpoch,
      'timezoneId': remote.timezoneId,
      'revision': remote.revision,
      'deletedAtUtcMs': remote.deletedAtUtc?.toUtc().millisecondsSinceEpoch,
    }),
  );
}

extension LifeRecordSyncCopy on LifeRecord {
  LifeRecord copyWithSync({
    required RecordSyncStatus status,
    required DateTime? lastSyncedAtUtc,
    required String? conflictJson,
  }) => LifeRecord(
    id: id,
    ownerUid: ownerUid,
    kind: kind,
    visibility: visibility,
    payloadJson: payloadJson,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: updatedAtUtc,
    timezoneId: timezoneId,
    syncStatus: status,
    revision: revision,
    lastSyncedAtUtc: lastSyncedAtUtc,
    remoteConflictJson: conflictJson,
    deletedAtUtc: deletedAtUtc,
  );
}
