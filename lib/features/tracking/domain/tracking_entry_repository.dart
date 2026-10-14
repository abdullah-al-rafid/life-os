import 'dart:async';
import 'dart:convert';

import '../../records/domain/life_record.dart';
import '../../records/domain/life_record_repository.dart';
import 'tracking_entry.dart';

abstract interface class TrackingEntryStore {
  Future<TrackingEntry?> findVisible(String id, String viewerUid);
  Future<TrackingEntry> insert(TrackingEntry entry);
  Future<TrackingEntry> update(
    TrackingEntry entry, {
    required int expectedRevision,
  });
  Future<void> softDelete(
    String id,
    String ownerUid,
    int expectedRevision,
    DateTime atUtc,
  );
  Stream<List<TrackingEntry>> watchVisible(
    String viewerUid, {
    TrackingEntryKind? kind,
    String? localDate,
  });
}

/// Local repository bound to the active Firebase Auth UID. It has no remote
/// adapter and cannot enqueue or perform cloud writes.
class OfflineTrackingEntryRepository {
  OfflineTrackingEntryRepository(this.store, this.identity, this.records);

  final TrackingEntryStore store;
  final CurrentUserIdentity identity;
  final LifeRecordRepository records;

  String _uid() {
    final uid = identity.currentUid;
    if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
      throw const UnauthenticatedOperation();
    }
    return uid;
  }

  Future<TrackingEntry> create(TrackingEntry entry) async {
    final uid = _uid();
    if (entry.ownerUid != uid) throw const OwnershipViolation();
    if (entry.revision != 1 || entry.deletedAtUtc != null) {
      throw const TrackingEntryValidationFailure(
        'New entries must start at revision 1 without a tombstone.',
      );
    }
    validateTrackingEntry(entry);
    await _ensureProfile();
    if (_uid() != uid || entry.ownerUid != identity.currentUid) {
      throw const OwnershipViolation();
    }
    return store.insert(entry);
  }

  Future<TrackingEntry> update({
    required String id,
    required int expectedRevision,
    required Map<String, Object?> payload,
    RecordVisibility? visibility,
  }) async {
    _requireId(id);
    final uid = _uid();
    final current = await store.findVisible(id, uid);
    if (_uid() != uid) throw const OwnershipViolation();
    if (current == null) throw const TrackingEntryNotFound();
    if (current.ownerUid != uid) throw const OwnershipViolation();
    if (current.deletedAtUtc != null) {
      throw const DeletedTrackingEntryMutation();
    }
    if (current.revision != expectedRevision) {
      throw const StaleTrackingEntryRevision();
    }
    final updated = current.copyWith(
      payloadJson: jsonEncode(payload),
      visibility: visibility,
      updatedAtUtc: DateTime.now().toUtc(),
      revision: expectedRevision + 1,
    );
    validateTrackingEntry(updated);
    if (_uid() != uid) throw const OwnershipViolation();
    return store.update(updated, expectedRevision: expectedRevision);
  }

  Future<void> delete({
    required String id,
    required int expectedRevision,
    required DateTime atUtc,
  }) async {
    _requireId(id);
    final uid = _uid();
    if (!atUtc.isUtc) {
      throw const TrackingEntryValidationFailure(
        'Deletion timestamp must be UTC.',
      );
    }
    final current = await store.findVisible(id, uid);
    if (_uid() != uid) throw const OwnershipViolation();
    if (current == null) throw const TrackingEntryNotFound();
    if (current.ownerUid != uid) throw const OwnershipViolation();
    if (current.revision != expectedRevision) {
      throw const StaleTrackingEntryRevision();
    }
    if (atUtc.isBefore(current.updatedAtUtc)) {
      throw const TrackingEntryValidationFailure(
        'Deletion timestamp cannot be earlier than the last update.',
      );
    }
    if (_uid() != uid) throw const OwnershipViolation();
    await store.softDelete(id, uid, expectedRevision, atUtc);
  }

  Future<TrackingEntry?> findVisible(String id) async {
    _requireId(id);
    final uid = _uid();
    final entry = await store.findVisible(id, uid);
    if (_uid() != uid) throw const OwnershipViolation();
    return entry;
  }

  Stream<List<TrackingEntry>> watch({
    TrackingEntryKind? kind,
    String? localDate,
  }) {
    if (localDate != null && !_validTrackingDate(localDate)) {
      throw const TrackingEntryValidationFailure(
        'localDate must be a real date in YYYY-MM-DD format.',
      );
    }
    late final StreamController<List<TrackingEntry>> output;
    StreamSubscription<String?>? identitySubscription;
    StreamSubscription<List<TrackingEntry>>? entriesSubscription;
    var generation = 0;
    var switchQueue = Future<void>.value();

    Future<void> switchTo(String? uid, int requestGeneration) async {
      try {
        await entriesSubscription?.cancel();
        entriesSubscription = null;
        if (output.isClosed || requestGeneration != generation) return;
        if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
          output.addError(const UnauthenticatedOperation());
          return;
        }
        entriesSubscription = store
            .watchVisible(uid, kind: kind, localDate: localDate)
            .listen((entries) {
              if (!output.isClosed &&
                  requestGeneration == generation &&
                  identity.currentUid == uid) {
                output.add(entries);
              }
            }, onError: output.addError);
      } on Object catch (error, stackTrace) {
        if (!output.isClosed && requestGeneration == generation) {
          output.addError(error, stackTrace);
        }
      }
    }

    output = StreamController<List<TrackingEntry>>(
      onListen: () {
        identitySubscription = identity.uidChanges.listen(
          (uid) {
            final requestGeneration = ++generation;
            switchQueue = switchQueue.then(
              (_) => switchTo(uid, requestGeneration),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            final requestGeneration = ++generation;
            switchQueue = switchQueue.then((_) async {
              await entriesSubscription?.cancel();
              entriesSubscription = null;
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
        await entriesSubscription?.cancel();
        await switchQueue;
      },
    );
    return output.stream;
  }

  Future<void> _ensureProfile() async {
    final uid = _uid();
    if (await records.findCurrentProfile() != null) return;
    final now = DateTime.now().toUtc();
    await records.saveProfile(
      ProfileRecord(
        authUid: uid,
        displayName: 'LIFE OS user',
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
  }
}

void _requireId(String id) {
  if (id.trim().isEmpty || id != id.trim()) {
    throw const TrackingEntryValidationFailure(
      'id must be non-empty trimmed text.',
    );
  }
}

bool _validTrackingDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parts = value.split('-').map(int.parse).toList();
  final date = DateTime(parts[0], parts[1], parts[2]);
  return date.year == parts[0] &&
      date.month == parts[1] &&
      date.day == parts[2];
}
