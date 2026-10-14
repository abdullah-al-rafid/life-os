import 'dart:async';
import 'dart:convert';

import '../../records/domain/life_record.dart';
import '../../records/domain/life_record_repository.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../../tracking/domain/tracking_entry_repository.dart';
import '../domain/prayer_models.dart';
import '../domain/prayer_repository.dart';

class OfflinePrayerRepository implements PrayerRepository {
  OfflinePrayerRepository({
    required this.records,
    required this.entries,
    required this.identity,
    required this.deviceTimezone,
  });

  final LifeRecordRepository records;
  final OfflineTrackingEntryRepository entries;
  final CurrentUserIdentity identity;
  final Future<String> Function() deviceTimezone;

  String _uid() {
    final uid = identity.currentUid;
    if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
      throw const UnauthenticatedOperation();
    }
    return uid;
  }

  String _scheduleId(String uid) => 'prayer-schedule:$uid';

  LifeRecord? _ownedSchedule(List<LifeRecord> values, String uid) {
    for (final record in values) {
      if (record.id == _scheduleId(uid) &&
          record.ownerUid == uid &&
          record.kind == LifeRecordKind.prayer) {
        return record;
      }
    }
    return null;
  }

  @override
  Stream<PrayerSchedule?> watchSchedule() =>
      records.watchVisibleRecords().map((values) {
        final uid = _uid();
        final record = _ownedSchedule(values, uid);
        if (record == null) return null;
        try {
          return PrayerSchedule.fromJson(
            jsonDecode(record.payloadJson) as Map<String, dynamic>,
          );
        } on Object catch (error) {
          throw PrayerRepositoryFailure(
            'The saved prayer schedule is invalid: $error',
          );
        }
      });

  @override
  Future<PrayerSchedule> saveSchedule(PrayerSchedule schedule) async {
    schedule.validate();
    final uid = _uid();
    final currentTimezone = await deviceTimezone();
    if (_uid() != uid) throw const OwnershipViolation();
    if (schedule.timezoneId != currentTimezone) {
      throw const DeviceTimezoneFailure(
        'The device timezone changed while saving. Reload the current timezone and try again.',
      );
    }
    final id = _scheduleId(uid);
    final now = DateTime.now().toUtc();
    await _ensureProfile(uid, now);
    final existing = await records.findCurrentVisibleRecord(id);
    if (identity.currentUid != uid) throw const OwnershipViolation();
    if (existing != null &&
        (existing.ownerUid != uid || existing.kind != LifeRecordKind.prayer)) {
      throw const OwnershipViolation();
    }
    final saved = await records.saveRecord(
      LifeRecord(
        id: id,
        ownerUid: uid,
        kind: LifeRecordKind.prayer,
        visibility: defaultPrayerVisibility,
        payloadJson: schedule.encode(),
        createdAtUtc: existing?.createdAtUtc ?? now,
        updatedAtUtc: now,
        timezoneId: schedule.timezoneId,
        revision: existing?.revision ?? 1,
      ),
    );
    if (saved.visibility != RecordVisibility.private ||
        saved.syncStatus != RecordSyncStatus.localOnly) {
      throw const PrayerRepositoryFailure(
        'Prayer schedule must remain local and private.',
      );
    }
    return PrayerSchedule.fromJson(
      jsonDecode(saved.payloadJson) as Map<String, dynamic>,
    );
  }

  Future<void> _ensureProfile(String uid, DateTime now) async {
    if (await records.findCurrentProfile() != null) return;
    if (_uid() != uid) throw const OwnershipViolation();
    await records.saveProfile(
      ProfileRecord(
        authUid: uid,
        displayName: 'LIFE OS user',
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
  }

  @override
  Stream<List<TrackingEntry>> watchPrayerEntries(String localDate) =>
      entries.watch(kind: TrackingEntryKind.prayer, localDate: localDate);

  @override
  Future<TrackingEntry> savePrayerStatus({
    required PrayerName prayer,
    required String localDate,
    required PrayerCompletion status,
    JamaatStatus? jamaatStatus,
    String? notes,
  }) async {
    final uid = _uid();
    final date = DateTime.tryParse(localDate);
    if (date == null || prayerDateKey(date) != localDate) {
      throw const PrayerValidationFailure(
        'Choose a valid local calendar date.',
      );
    }
    final note = notes?.trim();
    if (note != null && note.length > 500) {
      throw const PrayerValidationFailure(
        'Notes must be 500 characters or fewer.',
      );
    }
    final snapshot = await watchSchedule().first;
    if (snapshot == null) {
      throw const PrayerValidationFailure(
        'Set all prayer times before tracking.',
      );
    }
    final slot = snapshot.slots[prayer]!;
    final todaysEntries = await watchPrayerEntries(localDate).first;
    if (identity.currentUid != uid) throw const OwnershipViolation();
    final matches = todaysEntries.where(
      (item) => item.entryKey == prayer.label,
    );
    final existing = matches.isEmpty ? null : matches.first;
    final Map<String, dynamic> scheduleSnapshot;
    if (existing != null) {
      scheduleSnapshot = Map<String, dynamic>.from(
        existing.payload['scheduleSnapshot'] as Map,
      );
    } else {
      final currentTimezone = await deviceTimezone();
      if (identity.currentUid != uid) throw const OwnershipViolation();
      scheduleSnapshot = {
        'azanMinute': slot.azanMinute,
        'jamaatMinute': slot.jamaatMinute,
        'timezoneId': currentTimezone,
      };
    }
    final payload = <String, Object?>{
      'status': status.name,
      'jamaatStatus': jamaatStatus?.name,
      if (note != null && note.isNotEmpty) 'notes': note,
      'scheduleSnapshot': scheduleSnapshot,
    };
    if (existing != null) {
      return entries.update(
        id: existing.id,
        expectedRevision: existing.revision,
        payload: payload,
      );
    }
    final now = DateTime.now().toUtc();
    return entries.create(
      TrackingEntry(
        id: 'prayer:$uid:$localDate:${prayer.name}',
        ownerUid: uid,
        kind: TrackingEntryKind.prayer,
        localDate: localDate,
        entryKey: prayer.label,
        visibility: RecordVisibility.private,
        payloadJson: jsonEncode(payload),
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
  }
}
