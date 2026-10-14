import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/prayer/domain/prayer_models.dart';
import 'package:life_os/features/prayer/domain/prayer_repository.dart';
import 'package:life_os/features/prayer/presentation/prayer_providers.dart';
import 'package:life_os/features/prayer/domain/prayer_reminder_service.dart';
import 'package:life_os/features/prayer/presentation/prayer_screen.dart';
import 'package:life_os/features/prayer/presentation/prayer_settings_screen.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';

void main() {
  testWidgets(
    'prayer screen distinguishes unrecorded prayers and saves a status',
    (tester) async {
      final repository = _FakePrayerRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prayerRepositoryProvider.overrideWithValue(repository),
            prayerScheduleProvider.overrideWith(
              (ref) => Stream.value(_schedule()),
            ),
            prayerDayEntriesProvider(
              prayerDateKey(DateTime.now()),
            ).overrideWith((ref) => Stream.value(<TrackingEntry>[])),
          ],
          child: const MaterialApp(home: PrayerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Not recorded'), findsAtLeastNWidgets(1));
      await tester.tap(find.byKey(const Key('prayer_fajr_prayedLate')));
      await tester.pumpAndSettle();
      expect(repository.savedPrayer, PrayerName.fajr);
      expect(repository.savedStatus, PrayerCompletion.prayedLate);
      expect(find.text('Prayer record saved on this device.'), findsOneWidget);
    },
  );

  testWidgets('prayer screen shows setup empty state if schedule is absent', (
    tester,
  ) async {
    final repository = _FakePrayerRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(repository),
          deviceTimezoneProvider.overrideWithValue(() async => 'Asia/Dhaka'),
          prayerScheduleProvider.overrideWith((ref) => Stream.value(null)),
          prayerDayEntriesProvider(
            prayerDateKey(DateTime.now()),
          ).overrideWith((ref) => Stream.value(<TrackingEntry>[])),
        ],
        child: const MaterialApp(home: PrayerScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set your prayer times'), findsOneWidget);
    expect(
      find.textContaining('does not calculate prayer times'),
      findsOneWidget,
    );
  });

  testWidgets('schedule settings reports missing times as validation', (
    tester,
  ) async {
    final repository = _FakePrayerRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(repository),
          deviceTimezoneProvider.overrideWithValue(() async => 'Asia/Dhaka'),
          prayerScheduleProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: PrayerSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prayer_schedule_save')));
    await tester.pumpAndSettle();
    expect(find.text('Configure all five daily prayers.'), findsOneWidget);
  });

  testWidgets('notification denial is explained separately from exact alarms', (
    tester,
  ) async {
    final repository = _FakePrayerRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(repository),
          prayerScheduleProvider.overrideWith((ref) => Stream.value(null)),
          prayerReminderStatusProvider.overrideWith(
            (ref) => Stream.value(
              const PrayerReminderStatus(
                PrayerReminderAvailability.notificationPermissionDenied,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: PrayerSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Notification access is separate'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prayer_request_notification_permission')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('prayer_request_exact_alarms')), findsNothing);
    expect(
      find.byKey(const Key('prayer_open_notification_settings')),
      findsOneWidget,
    );
  });

  testWidgets('prayer records show an error state when local data fails', (
    tester,
  ) async {
    final repository = _FakePrayerRepository();
    final date = prayerDateKey(DateTime.now());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(repository),
          prayerScheduleProvider.overrideWith(
            (ref) => Stream.value(_schedule()),
          ),
          prayerDayEntriesProvider(
            date,
          ).overrideWith((ref) => Stream.error(StateError('database failure'))),
        ],
        child: const MaterialApp(home: PrayerScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Prayer records for this date could not be loaded.'),
      findsOneWidget,
    );
  });

  testWidgets('timezone lookup failure is shown and prevents schedule saving', (
    tester,
  ) async {
    final repository = _FakePrayerRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(repository),
          deviceTimezoneProvider.overrideWithValue(
            () async => throw const DeviceTimezoneFailure(
              'Timezone lookup failed clearly.',
            ),
          ),
          prayerScheduleProvider.overrideWith(
            (ref) => Stream.value(_schedule()),
          ),
        ],
        child: const MaterialApp(home: PrayerSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prayer_schedule_save')));
    await tester.pumpAndSettle();
    expect(find.text('Timezone lookup failed clearly.'), findsOneWidget);
    expect(repository.scheduleSaveCalled, isFalse);
  });
}

PrayerSchedule _schedule() => PrayerSchedule(
  timezoneId: 'Asia/Dhaka',
  slots: {
    for (final prayer in PrayerName.values)
      prayer: const PrayerTimes(azanMinute: 300, jamaatMinute: 330),
  },
);

class _FakePrayerRepository implements PrayerRepository {
  PrayerName? savedPrayer;
  PrayerCompletion? savedStatus;
  bool scheduleSaveCalled = false;
  @override
  Stream<PrayerSchedule?> watchSchedule() => Stream.value(_schedule());
  @override
  Future<PrayerSchedule> saveSchedule(PrayerSchedule schedule) async {
    scheduleSaveCalled = true;
    return schedule;
  }

  @override
  Stream<List<TrackingEntry>> watchPrayerEntries(String localDate) =>
      Stream.value([]);
  @override
  Future<TrackingEntry> savePrayerStatus({
    required PrayerName prayer,
    required String localDate,
    required PrayerCompletion status,
    JamaatStatus? jamaatStatus,
    String? notes,
  }) async {
    savedPrayer = prayer;
    savedStatus = status;
    final now = DateTime.now().toUtc();
    return TrackingEntry(
      id: 'fake-entry',
      ownerUid: 'test-user',
      kind: TrackingEntryKind.prayer,
      localDate: localDate,
      entryKey: prayer.label,
      visibility: RecordVisibility.private,
      payloadJson:
          '{"status":"${status.name}","scheduleSnapshot":{"azanMinute":300,"jamaatMinute":330,"timezoneId":"Asia/Dhaka"}}',
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }
}
