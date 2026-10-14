import 'dart:convert';

import '../../records/domain/life_record.dart';
import '../../records/domain/life_record_repository.dart';
import '../domain/prayer_reminder_service.dart';

class DriftPrayerReminderPreferencesStore
    implements PrayerReminderPreferencesStore {
  DriftPrayerReminderPreferencesStore({
    required this.records,
    required this.identity,
  });

  final LifeRecordRepository records;
  final CurrentUserIdentity identity;

  String _id(String uid) => 'prayer-reminder-state:$uid';

  void _checkUid(String uid) {
    if (uid.isEmpty || identity.currentUid != uid) {
      throw const OwnershipViolation();
    }
  }

  @override
  Future<PrayerReminderPreferences> read(String uid) async {
    _checkUid(uid);
    final record = await records.findCurrentVisibleRecord(_id(uid));
    _checkUid(uid);
    if (record == null) return PrayerReminderPreferences();
    if (record.ownerUid != uid ||
        record.kind != LifeRecordKind.prayer ||
        record.visibility != RecordVisibility.private ||
        record.syncStatus != RecordSyncStatus.localOnly) {
      throw const OwnershipViolation();
    }
    try {
      final value = jsonDecode(record.payloadJson) as Map<String, dynamic>;
      final dismissed = value['dismissed'];
      final snoozed = value['snoozedAt'];
      if (dismissed is! List || snoozed is! Map) {
        throw const FormatException();
      }
      return PrayerReminderPreferences(
        dismissed: dismissed.whereType<String>().toSet(),
        snoozedAt: {
          for (final entry in snoozed.entries)
            if (entry.key is String && entry.value is int)
              entry.key as String: entry.value as int,
        },
        remindersDisabled: value['remindersDisabled'] == true,
      );
    } on Object {
      throw const RecordValidationFailure(
        'Saved prayer reminder preferences are invalid.',
      );
    }
  }

  @override
  Future<void> write(String uid, PrayerReminderPreferences preferences) async {
    _checkUid(uid);
    final id = _id(uid);
    final existing = await records.findCurrentVisibleRecord(id);
    _checkUid(uid);
    if (existing != null &&
        (existing.ownerUid != uid ||
            existing.kind != LifeRecordKind.prayer ||
            existing.visibility != RecordVisibility.private)) {
      throw const OwnershipViolation();
    }
    final now = DateTime.now().toUtc();
    await records.saveRecord(
      LifeRecord(
        id: id,
        ownerUid: uid,
        kind: LifeRecordKind.prayer,
        visibility: RecordVisibility.private,
        payloadJson: jsonEncode({
          'recordType': 'prayerReminderPreferences',
          'schemaVersion': 1,
          'dismissed': preferences.dismissed.toList()..sort(),
          'snoozedAt': preferences.snoozedAt,
          'remindersDisabled': preferences.remindersDisabled,
        }),
        createdAtUtc: existing?.createdAtUtc ?? now,
        updatedAtUtc: now,
        revision: existing?.revision ?? 1,
      ),
    );
    _checkUid(uid);
  }
}
