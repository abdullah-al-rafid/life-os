import 'dart:async';

import 'life_record.dart';

abstract interface class CurrentUserIdentity {
  String? get currentUid;
  Stream<String?> get uidChanges;
}

abstract interface class LifeRecordLocalStore {
  Future<void> saveProfile(ProfileRecord profile);
  Future<ProfileRecord?> findProfile(String authUid);
  Future<LifeRecord?> findVisibleRecord(String id, String viewerUid);
  Future<LifeRecord> saveOwnedRecord(LifeRecord record, String actorUid);
  Future<void> saveTaskPlanAtomically(
    List<LifeRecord> records,
    TaskPlanImportReceipt receipt,
    String actorUid,
  );
  Future<void> softDeleteOwnedRecord(
    String id,
    String actorUid,
    DateTime atUtc,
  );
  Stream<List<LifeRecord>> watchVisibleRecords(String viewerUid);
}

/// Contract only. No Firebase implementation or remote write is enabled yet.
abstract interface class LifeRecordRemoteStore {
  Future<List<LifeRecord>> fetchChanges(String ownerUid);
  Future<void> writeChanges(List<LifeRecord> records);
}

abstract interface class LifeRecordRepository {
  Future<void> saveProfile(ProfileRecord profile);
  Future<ProfileRecord?> findCurrentProfile();
  Future<LifeRecord?> findCurrentVisibleRecord(String id);
  Future<LifeRecord> saveRecord(LifeRecord record);
  Future<void> saveTaskPlanAtomically(
    List<LifeRecord> records,
    TaskPlanImportReceipt receipt,
  );
  Future<void> deleteRecord(String id, DateTime atUtc);
  Stream<List<LifeRecord>> watchVisibleRecords();
  Future<void> synchronize();
}

class OfflineLifeRecordRepository implements LifeRecordRepository {
  const OfflineLifeRecordRepository(this._localStore, this._identity);

  final LifeRecordLocalStore _localStore;
  final CurrentUserIdentity _identity;

  String _requireCurrentUid() {
    final uid = _identity.currentUid;
    if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
      throw const UnauthenticatedOperation();
    }
    return uid;
  }

  @override
  Future<void> saveProfile(ProfileRecord profile) async {
    final uid = _requireCurrentUid();
    validateProfileRecord(profile);
    if (profile.authUid != uid) throw const OwnershipViolation();
    await _localStore.saveProfile(profile);
  }

  @override
  Future<ProfileRecord?> findCurrentProfile() =>
      _localStore.findProfile(_requireCurrentUid());

  @override
  Future<LifeRecord?> findCurrentVisibleRecord(String id) {
    final uid = _requireCurrentUid();
    if (id.trim().isEmpty || id != id.trim()) {
      throw const RecordValidationFailure('id must be non-empty and trimmed.');
    }
    return _localStore.findVisibleRecord(id, uid);
  }

  @override
  Future<LifeRecord> saveRecord(LifeRecord record) {
    final uid = _requireCurrentUid();
    validateLifeRecord(record, localMutation: true);
    if (record.ownerUid != uid) throw const OwnershipViolation();
    return _localStore.saveOwnedRecord(record, uid);
  }

  @override
  Future<void> saveTaskPlanAtomically(
    List<LifeRecord> records,
    TaskPlanImportReceipt receipt,
  ) {
    final uid = _requireCurrentUid();
    if (receipt.ownerUid != uid ||
        records.any((record) => record.ownerUid != uid)) {
      throw const OwnershipViolation();
    }
    if (records.isEmpty) {
      throw const RecordValidationFailure(
        'An imported plan must contain tasks.',
      );
    }
    for (final record in records) {
      validateLifeRecord(record, localMutation: true);
      if (record.kind != LifeRecordKind.task) {
        throw const RecordValidationFailure(
          'Imported plan records must be tasks.',
        );
      }
    }
    return _localStore.saveTaskPlanAtomically(records, receipt, uid);
  }

  @override
  Future<void> deleteRecord(String id, DateTime atUtc) {
    final uid = _requireCurrentUid();
    if (id.trim().isEmpty || id != id.trim()) {
      throw const RecordValidationFailure('id must be non-empty and trimmed.');
    }
    return _localStore.softDeleteOwnedRecord(id, uid, atUtc.toUtc());
  }

  @override
  Stream<List<LifeRecord>> watchVisibleRecords() {
    late final StreamController<List<LifeRecord>> output;
    StreamSubscription<String?>? identitySubscription;
    StreamSubscription<List<LifeRecord>>? recordsSubscription;
    var generation = 0;
    var switchQueue = Future<void>.value();

    Future<void> switchTo(String? uid, int requestGeneration) async {
      try {
        await recordsSubscription?.cancel();
        recordsSubscription = null;
        if (output.isClosed || requestGeneration != generation) return;
        if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
          output.addError(const UnauthenticatedOperation());
          return;
        }
        recordsSubscription = _localStore.watchVisibleRecords(uid).listen((
          records,
        ) {
          if (!output.isClosed &&
              requestGeneration == generation &&
              _identity.currentUid == uid) {
            output.add(records);
          }
        }, onError: output.addError);
      } on Object catch (error, stackTrace) {
        if (!output.isClosed && requestGeneration == generation) {
          output.addError(error, stackTrace);
        }
      }
    }

    output = StreamController<List<LifeRecord>>(
      onListen: () {
        identitySubscription = _identity.uidChanges.listen(
          (uid) {
            final requestGeneration = ++generation;
            switchQueue = switchQueue.then(
              (_) => switchTo(uid, requestGeneration),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            final requestGeneration = ++generation;
            switchQueue = switchQueue.then((_) async {
              await recordsSubscription?.cancel();
              recordsSubscription = null;
              if (!output.isClosed && requestGeneration == generation) {
                output.addError(error, stackTrace);
              }
            });
          },
        );
      },
      onCancel: () async {
        generation++;
        await identitySubscription?.cancel();
        await recordsSubscription?.cancel();
        await switchQueue;
      },
    );
    return output.stream;
  }

  @override
  Future<void> synchronize() async {
    throw const SyncNotEnabled();
  }
}
