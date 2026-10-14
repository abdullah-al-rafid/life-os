import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/prayer/data/offline_prayer_repository.dart';
import 'package:life_os/features/prayer/domain/prayer_models.dart';
import 'package:life_os/features/records/data/drift_life_record_store.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/tracking/data/drift_tracking_entry_store.dart';
import 'package:life_os/features/tracking/domain/tracking_entry_repository.dart';

void main() {
  late LifeDatabase database;
  late _Identity identity;
  late OfflinePrayerRepository repository;
  var currentTimezone = 'Asia/Dhaka';
  Future<String> Function() timezoneReader = () async => 'Asia/Dhaka';

  setUp(() {
    currentTimezone = 'Asia/Dhaka';
    timezoneReader = () async => currentTimezone;
    database = LifeDatabase.forTesting(NativeDatabase.memory());
    identity = _Identity('user-a');
    final records = OfflineLifeRecordRepository(
      DriftLifeRecordStore(database),
      identity,
    );
    final entries = OfflineTrackingEntryRepository(
      DriftTrackingEntryStore(database),
      identity,
      records,
    );
    repository = OfflinePrayerRepository(
      records: records,
      entries: entries,
      identity: identity,
      deviceTimezone: () => timezoneReader(),
    );
  });

  tearDown(() async {
    await identity.dispose();
    await database.close();
  });

  test(
    'requires all five valid prayer times and persists schedule privately',
    () async {
      expect(
        () => PrayerSchedule(timezoneId: 'Asia/Dhaka', slots: {}),
        throwsA(isA<PrayerValidationFailure>()),
      );
      expect(
        () => PrayerSchedule(
          timezoneId: 'Asia/Dhaka',
          slots: {
            for (final prayer in PrayerName.values)
              prayer: const PrayerTimes(azanMinute: 600, jamaatMinute: 599),
          },
        ),
        throwsA(isA<PrayerValidationFailure>()),
      );
      final saved = await repository.saveSchedule(_schedule());
      expect(saved.slots, hasLength(5));
      final stored = await database.select(database.storedRecords).getSingle();
      expect(stored.kind, 'prayer');
      expect(stored.visibility, 'private');
      expect(stored.syncStatus, 'localOnly');
      expect(
        (await repository.watchSchedule().first)?.timezoneId,
        'Asia/Dhaka',
      );
    },
  );

  test('legacy prayer schedules default reminders to disabled', () {
    final legacyJson = _schedule().toJson()..remove('remindersEnabled');
    final decoded = PrayerSchedule.fromJson(legacyJson);
    expect(decoded.remindersEnabled, isFalse);
    expect(
      () => PrayerSchedule.fromJson({...legacyJson, 'remindersEnabled': 'yes'}),
      throwsA(isA<PrayerValidationFailure>()),
    );
  });

  test(
    'records dated status and preserves its schedule snapshot after edits',
    () async {
      await repository.saveSchedule(_schedule());
      final first = await repository.savePrayerStatus(
        prayer: PrayerName.fajr,
        localDate: '2026-10-14',
        status: PrayerCompletion.prayedOnTime,
        jamaatStatus: JamaatStatus.jamaat,
        notes: 'At the mosque',
      );
      final firstSnapshot = first.payload['scheduleSnapshot'];
      expect(first.visibility, RecordVisibility.private);
      expect(first.localDate, '2026-10-14');
      expect(firstSnapshot, {
        'azanMinute': 300,
        'jamaatMinute': 330,
        'timezoneId': 'Asia/Dhaka',
      });

      currentTimezone = 'Asia/Kuala_Lumpur';
      timezoneReader = () async => currentTimezone;
      await repository.saveSchedule(
        _schedule(azan: 310, jamaat: 340, timezone: currentTimezone),
      );
      timezoneReader = () async => throw const DeviceTimezoneFailure(
        'Timezone temporarily unavailable.',
      );
      final updated = await repository.savePrayerStatus(
        prayer: PrayerName.fajr,
        localDate: '2026-10-14',
        status: PrayerCompletion.prayedLate,
        notes: 'After work',
      );
      expect(updated.revision, 2);
      expect(updated.payload['status'], 'prayedLate');
      expect(updated.payload['notes'], 'After work');
      expect(updated.payload['scheduleSnapshot'], firstSnapshot);
      expect(
        await database.select(database.trackingEntries).get(),
        hasLength(1),
      );
    },
  );

  test(
    'a missing prayer remains unrecorded and accounts stay isolated',
    () async {
      await repository.saveSchedule(_schedule());
      expect(await repository.watchPrayerEntries('2026-10-14').first, isEmpty);
      await repository.savePrayerStatus(
        prayer: PrayerName.isha,
        localDate: '2026-10-14',
        status: PrayerCompletion.missed,
      );
      identity.switchTo('user-b');
      expect(await repository.watchPrayerEntries('2026-10-14').first, isEmpty);
      await expectLater(
        repository.savePrayerStatus(
          prayer: PrayerName.isha,
          localDate: '2026-10-14',
          status: PrayerCompletion.missed,
        ),
        throwsA(isA<PrayerValidationFailure>()),
        reason: 'the other account has no private schedule',
      );
    },
  );

  test('rejects impossible local date before writing', () async {
    await repository.saveSchedule(_schedule());
    await expectLater(
      repository.savePrayerStatus(
        prayer: PrayerName.fajr,
        localDate: '2026-02-30',
        status: PrayerCompletion.missed,
      ),
      throwsA(isA<PrayerValidationFailure>()),
    );
    expect(await database.select(database.trackingEntries).get(), isEmpty);
  });

  test('timezone failure blocks schedule and new snapshot writes', () async {
    timezoneReader = () async =>
        throw const DeviceTimezoneFailure('Timezone unavailable.');
    await expectLater(
      repository.saveSchedule(_schedule()),
      throwsA(isA<DeviceTimezoneFailure>()),
    );
    expect(await database.select(database.storedRecords).get(), isEmpty);

    timezoneReader = () async => 'Asia/Dhaka';
    await repository.saveSchedule(_schedule());
    timezoneReader = () async =>
        throw const DeviceTimezoneFailure('Timezone unavailable.');
    await expectLater(
      repository.savePrayerStatus(
        prayer: PrayerName.fajr,
        localDate: '2026-10-14',
        status: PrayerCompletion.missed,
      ),
      throwsA(isA<DeviceTimezoneFailure>()),
    );
    expect(await database.select(database.trackingEntries).get(), isEmpty);
  });

  test(
    'rejects a stale timezone value when saving schedule settings',
    () async {
      currentTimezone = 'Asia/Kuala_Lumpur';
      timezoneReader = () async => currentTimezone;
      await expectLater(
        repository.saveSchedule(_schedule()),
        throwsA(isA<DeviceTimezoneFailure>()),
      );
      expect(await database.select(database.storedRecords).get(), isEmpty);
    },
  );
}

PrayerSchedule _schedule({
  int azan = 300,
  int jamaat = 330,
  String timezone = 'Asia/Dhaka',
}) => PrayerSchedule(
  timezoneId: timezone,
  slots: {
    for (final prayer in PrayerName.values)
      prayer: PrayerTimes(azanMinute: azan, jamaatMinute: jamaat),
  },
);

class _Identity implements CurrentUserIdentity {
  _Identity(this.currentUid);
  @override
  String? currentUid;
  final _changes = StreamController<String?>.broadcast();
  void switchTo(String? uid) {
    currentUid = uid;
    _changes.add(uid);
  }

  @override
  Stream<String?> get uidChanges => Stream<String?>.multi((controller) {
    controller.add(currentUid);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
  Future<void> dispose() => _changes.close();
}
