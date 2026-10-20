import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:life_os/features/prayer/domain/prayer_models.dart';
import 'package:life_os/features/prayer/domain/prayer_reminder_service.dart';
import 'package:life_os/features/prayer/domain/prayer_repository.dart';
import 'package:life_os/features/prayer/presentation/prayer_providers.dart';
import 'package:life_os/features/prayer/presentation/prayer_reminder_lifecycle.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';

void main() {
  group('LocalPrayerReminderService', () {
    testWidgets('app resume triggers notification reconciliation', (
      tester,
    ) async {
      final service = CountingReminderService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prayerReminderServiceProvider.overrideWithValue(service),
            prayerReminderStatusProvider.overrideWith(
              (ref) => Stream.value(service.currentStatus),
            ),
          ],
          child: const PrayerReminderLifecycle(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(service.reconcileCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    test(
      'notification permission denial is distinct from exact alarm access',
      () async {
        final fixture = ReminderFixture();
        fixture.gateway.allowed = false;
        await fixture.start();
        expect(
          fixture.service.currentStatus.availability,
          PrayerReminderAvailability.notificationPermissionDenied,
        );
        expect(fixture.gateway.scheduled, isEmpty);
        expect(fixture.gateway.exactChecks, 0);
        await fixture.dispose();
      },
    );

    test(
      'uses inexact scheduling and exposes warning without exact access',
      () async {
        final fixture = ReminderFixture()..gateway.exact = false;
        await fixture.start();
        expect(
          fixture.service.currentStatus.availability,
          PrayerReminderAvailability.exactAlarmsUnavailable,
        );
        final today = fixture.todayKey;
        final fajr = fixture.gateway.scheduled.values
            .where(
              (request) =>
                  request.localDate == today &&
                  request.prayer == PrayerName.fajr,
            )
            .toList();
        expect(fajr, hasLength(7)); // Azan plus six reminders before Jamaat.
        expect(fixture.gateway.modes.values, everyElement(isFalse));
        expect(fajr.map((request) => request.id).toSet(), hasLength(7));
        await fixture.dispose();
      },
    );

    test('stable ids and reconciliation prevent duplicate schedules', () async {
      final fixture = ReminderFixture();
      await fixture.start();
      final first = Map<int, PrayerReminderRequest>.from(
        fixture.gateway.scheduled,
      );
      await fixture.service.reconcile();
      expect(fixture.gateway.scheduled.keys, unorderedEquals(first.keys));
      expect(
        stablePrayerNotificationId(
          'user-a',
          fixture.todayKey,
          PrayerName.fajr,
          PrayerNotificationKind.azan,
          0,
        ),
        stablePrayerNotificationId(
          'user-a',
          fixture.todayKey,
          PrayerName.fajr,
          PrayerNotificationKind.azan,
          0,
        ),
      );
      await fixture.dispose();
    });

    test('skips past times and stops reminders at Jamaat', () async {
      final fixture = ReminderFixture()
        // 05:12 in Asia/Dhaka, expressed as a UTC instant so the test does not
        // depend on the host machine's timezone.
        ..now = DateTime.utc(2026, 10, 13, 23, 12)
        ..repository.schedule = fixtureSchedule(jamaatMinute: 320);
      await fixture.start();
      final requests = fixture.gateway.scheduled.values
          .where(
            (request) =>
                request.localDate == fixture.todayKey &&
                request.prayer == PrayerName.fajr,
          )
          .toList();
      expect(requests, hasLength(1));
      expect(requests.single.kind, PrayerNotificationKind.reminder);
      expect(requests.single.scheduledAt.minute, 15);
      expect(
        requests.every((request) => request.scheduledAt.minute < 20),
        isTrue,
      );
      await fixture.dispose();
    });

    test(
      'completion cancels the session and reconciliation does not restore it',
      () async {
        final fixture = ReminderFixture();
        await fixture.start();
        final sessionIds = fixture.gateway.scheduled.values
            .where(
              (request) =>
                  request.localDate == fixture.todayKey &&
                  request.prayer == PrayerName.fajr,
            )
            .map((request) => request.id)
            .toSet();
        fixture.repository.entries.add(
          trackingEntry('user-a', fixture.todayKey, PrayerName.fajr),
        );
        await fixture.service.prayerRecorded(PrayerName.fajr, fixture.todayKey);
        expect(
          sessionIds.intersection(fixture.gateway.scheduled.keys.toSet()),
          isEmpty,
        );
        await fixture.service.reconcile();
        expect(
          sessionIds.intersection(fixture.gateway.scheduled.keys.toSet()),
          isEmpty,
        );
        await fixture.dispose();
      },
    );

    test(
      'schedule edits, revoked permission, and timezone changes reconcile',
      () async {
        final fixture = ReminderFixture();
        await fixture.start();
        final priorIds = fixture.gateway.scheduled.keys.toSet();
        fixture.repository.schedule = fixtureSchedule(
          azanMinute: 360,
          jamaatMinute: 380,
        );
        await fixture.service.reconcile();
        expect(fixture.gateway.scheduled.keys.toSet(), isNot(priorIds));
        expect(
          fixture.gateway.scheduled.values.any(
            (request) => request.scheduledAt.hour == 6,
          ),
          isTrue,
        );
        fixture.gateway.allowed = false;
        await fixture.service.reconcile();
        expect(fixture.gateway.scheduled, isEmpty);
        expect(
          fixture.service.currentStatus.availability,
          PrayerReminderAvailability.notificationPermissionDenied,
        );
        fixture.gateway.allowed = true;
        fixture.timezone = 'Asia/Kolkata';
        await fixture.service.reconcile();
        expect(fixture.gateway.scheduled, isNotEmpty);
        await fixture.dispose();
      },
    );

    test('timezone failure never schedules with a UTC fallback', () async {
      final fixture = ReminderFixture()..timezoneFailure = true;
      await fixture.start();
      expect(fixture.gateway.scheduled, isEmpty);
      expect(
        fixture.service.currentStatus.availability,
        PrayerReminderAvailability.timezoneUnavailable,
      );
      await fixture.dispose();
    });

    test(
      'account switching cancels prior UID and only schedules active user',
      () async {
        final fixture = ReminderFixture();
        fixture.repository.schedules['user-b'] = fixtureSchedule(
          azanMinute: 400,
          jamaatMinute: 430,
        );
        await fixture.start();
        expect(
          fixture.gateway.scheduled.values.every(
            (request) => request.ownerUid == 'user-a',
          ),
          isTrue,
        );
        fixture.identity.setUid('user-b');
        await fixture.service.reconcile();
        expect(fixture.gateway.scheduled.values, isNotEmpty);
        expect(
          fixture.gateway.scheduled.values.every(
            (request) => request.ownerUid == 'user-b',
          ),
          isTrue,
        );
        await fixture.dispose();
      },
    );

    test(
      'dismissal persists and snooze is limited to one per session',
      () async {
        final fixture = ReminderFixture();
        await fixture.start();
        final action = PrayerNotificationAction(
          ownerUid: 'user-a',
          localDate: fixture.todayKey,
          prayer: PrayerName.fajr,
          action: 'dismiss',
        );
        await fixture.service.dismissSession(action);
        expect(
          fixture.storedPreferences['user-a']?.dismissed,
          contains('${fixture.todayKey}_fajr'),
        );
        expect(
          fixture.gateway.scheduled.values.any(
            (request) =>
                request.localDate == fixture.todayKey &&
                request.prayer == PrayerName.fajr,
          ),
          isFalse,
        );

        final dhuhr = PrayerNotificationAction(
          ownerUid: 'user-a',
          localDate: fixture.todayKey,
          prayer: PrayerName.dhuhr,
          action: 'snooze',
        );
        // 05:01 in Asia/Dhaka, expressed as a UTC instant.
        fixture.now = DateTime.utc(2026, 10, 13, 23, 1);
        await fixture.service.snoozeSession(dhuhr);
        await fixture.service.snoozeSession(dhuhr);
        final snoozes = fixture.gateway.scheduled.values.where(
          (request) =>
              request.localDate == fixture.todayKey &&
              request.prayer == PrayerName.dhuhr &&
              request.kind == PrayerNotificationKind.snooze,
        );
        expect(snoozes, hasLength(1));
        await fixture.dispose();
      },
    );

    test(
      'turn off notification action cancels and persists the preference',
      () async {
        final fixture = ReminderFixture();
        await fixture.start();
        await fixture.service.setRemindersEnabled(false);
        expect(fixture.gateway.scheduled, isEmpty);
        expect(fixture.storedPreferences['user-a']?.remindersDisabled, isTrue);
        await fixture.service.reconcile();
        expect(fixture.gateway.scheduled, isEmpty);
        await fixture.service.setRemindersEnabled(true);
        expect(fixture.gateway.scheduled, isNotEmpty);
        await fixture.dispose();
      },
    );
  });
}

class ReminderFixture {
  final identity = FakeIdentity('user-a');
  final repository = FakePrayerRepository();
  final gateway = FakeGateway();
  final storedPreferences = <String, PrayerReminderPreferences>{};
  // 04:00 in Asia/Dhaka, expressed as a UTC instant. CI runners and developer
  // machines can have different local timezones.
  DateTime now = DateTime.utc(2026, 10, 13, 22);
  String timezone = 'Asia/Dhaka';
  bool timezoneFailure = false;
  late final service = LocalPrayerReminderService(
    gateway: gateway,
    repository: repository,
    identity: identity,
    preferences: FakePreferences(storedPreferences),
    readDeviceTimezone: () async {
      if (timezoneFailure) throw const DeviceTimezoneFailure('No timezone');
      return timezone;
    },
    clock: () => now,
    isAndroid: true,
  );

  ReminderFixture() {
    repository.identity = identity;
    repository.schedule = fixtureSchedule();
  }

  String get todayKey {
    final localNow = tz.TZDateTime.from(now, tz.getLocation(timezone));
    return prayerDateKey(DateTime(localNow.year, localNow.month, localNow.day));
  }

  Future<void> start() async {
    await service.start();
    await service.reconcile();
  }

  Future<void> dispose() => service.dispose();
}

PrayerSchedule fixtureSchedule({
  int azanMinute = 300,
  int jamaatMinute = 340,
}) => PrayerSchedule(
  timezoneId: 'Asia/Dhaka',
  remindersEnabled: true,
  slots: {
    for (final prayer in PrayerName.values)
      prayer: PrayerTimes(azanMinute: azanMinute, jamaatMinute: jamaatMinute),
  },
);

TrackingEntry trackingEntry(String uid, String date, PrayerName prayer) =>
    TrackingEntry(
      id: 'prayer:$uid:$date:${prayer.name}',
      ownerUid: uid,
      kind: TrackingEntryKind.prayer,
      localDate: date,
      entryKey: prayer.label,
      visibility: RecordVisibility.private,
      payloadJson: '{"status":"prayedOnTime"}',
      createdAtUtc: DateTime.utc(2026, 10, 14),
      updatedAtUtc: DateTime.utc(2026, 10, 14),
    );

class FakeIdentity implements CurrentUserIdentity {
  FakeIdentity(this.currentUid);
  @override
  String? currentUid;
  final changes = StreamController<String?>.broadcast();
  @override
  Stream<String?> get uidChanges => changes.stream;
  void setUid(String uid) {
    currentUid = uid;
    changes.add(uid);
  }
}

class CountingReminderService implements PrayerReminderService {
  int reconcileCount = 0;
  final currentStatus = const PrayerReminderStatus(
    PrayerReminderAvailability.ready,
    pendingCount: 1,
  );

  @override
  Stream<PrayerReminderStatus> get status => Stream.value(currentStatus);
  @override
  Future<void> start() async {}
  @override
  Future<void> reconcile() async => reconcileCount++;
  @override
  Future<void> requestNotifications() async {}
  @override
  Future<void> openNotificationSettings() async {}
  @override
  Future<void> requestExactAlarms() async {}
  @override
  Future<void> setRemindersEnabled(bool enabled) async {}
  @override
  Future<void> prayerRecorded(PrayerName prayer, String localDate) async {}
  @override
  Future<void> dismissSession(PrayerNotificationAction action) async {}
  @override
  Future<void> snoozeSession(PrayerNotificationAction action) async {}
  @override
  Future<void> dispose() async {}
}

class FakePrayerRepository implements PrayerRepository {
  FakeIdentity? identity;
  PrayerSchedule? schedule;
  final Map<String, PrayerSchedule?> schedules = {};
  final List<TrackingEntry> entries = [];

  @override
  Stream<PrayerSchedule?> watchSchedule() =>
      Stream.value(schedules[identity?.currentUid] ?? schedule);

  @override
  Stream<List<TrackingEntry>> watchPrayerEntries(String localDate) =>
      Stream.value(
        entries.where((entry) => entry.localDate == localDate).toList(),
      );

  @override
  Future<PrayerSchedule> saveSchedule(PrayerSchedule schedule) async =>
      schedule;

  @override
  Future<TrackingEntry> savePrayerStatus({
    required PrayerName prayer,
    required String localDate,
    required PrayerCompletion status,
    JamaatStatus? jamaatStatus,
    String? notes,
  }) async => trackingEntry(identity!.currentUid!, localDate, prayer);
}

class FakeGateway implements PrayerNotificationGateway {
  bool allowed = true;
  bool exact = true;
  int exactChecks = 0;
  final Map<int, PrayerReminderRequest> scheduled = {};
  final Map<int, bool> modes = {};
  Future<void> Function(PrayerNotificationAction)? onAction;

  @override
  Future<void> initialize(
    Future<void> Function(PrayerNotificationAction) onAction,
  ) async => this.onAction = onAction;

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> requestNotificationPermission() async => allowed = true;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<bool> exactAlarmsAllowed() async {
    exactChecks++;
    return exact;
  }

  @override
  Future<bool> requestExactAlarmAccess() async => exact = true;

  @override
  Future<void> schedule(
    PrayerReminderRequest request, {
    required bool exact,
  }) async {
    scheduled[request.id] = request;
    modes[request.id] = exact;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    modes.remove(id);
  }

  @override
  Future<void> cancelOwner(String uid) async {
    final ids = scheduled.entries
        .where((entry) => entry.value.ownerUid == uid)
        .map((entry) => entry.key)
        .toList();
    for (final id in ids) {
      await cancel(id);
    }
  }

  @override
  Future<void> cancelAllManaged() async {
    scheduled.clear();
    modes.clear();
  }
}

class FakePreferences implements PrayerReminderPreferencesStore {
  FakePreferences(this.values);
  final Map<String, PrayerReminderPreferences> values;
  @override
  Future<PrayerReminderPreferences> read(String uid) async =>
      values[uid] ?? PrayerReminderPreferences();
  @override
  Future<void> write(String uid, PrayerReminderPreferences preferences) async =>
      values[uid] = preferences;
}
