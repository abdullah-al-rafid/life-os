import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../records/presentation/record_providers.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../data/offline_prayer_repository.dart';
import '../data/android_prayer_notification_gateway.dart';
import '../data/drift_prayer_reminder_preferences_store.dart';
import '../domain/prayer_models.dart';
import '../domain/prayer_repository.dart';
import '../domain/prayer_reminder_service.dart';

const _timezoneChannel = MethodChannel('life_os/device_timezone');

Future<String> readDeviceTimezone() async {
  final String? value;
  try {
    value = await _timezoneChannel.invokeMethod<String>('getTimeZone');
  } on MissingPluginException {
    throw const DeviceTimezoneFailure(
      'Device timezone lookup is unavailable in this build.',
    );
  } on PlatformException {
    throw const DeviceTimezoneFailure(
      'The device timezone could not be read. Check the system timezone and try again.',
    );
  } on TypeError {
    throw const DeviceTimezoneFailure(
      'The device returned an unsupported timezone response.',
    );
  }
  if (value == null || !_isSupportedTimezoneId(value)) {
    throw const DeviceTimezoneFailure(
      'The device returned a missing, invalid, or unsupported timezone ID.',
    );
  }
  return value;
}

bool _isSupportedTimezoneId(String value) => RegExp(
  r'^(?:UTC|GMT|[A-Za-z][A-Za-z0-9_+-]*(?:/[A-Za-z][A-Za-z0-9_+-]*)+)$',
).hasMatch(value);

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return OfflinePrayerRepository(
    records: ref.watch(lifeRecordRepositoryProvider),
    entries: ref.watch(trackingEntryRepositoryProvider),
    identity: ref.watch(currentUserIdentityProvider),
    deviceTimezone: ref.watch(deviceTimezoneProvider),
  );
});

final prayerNotificationGatewayProvider = Provider<PrayerNotificationGateway>(
  (ref) => AndroidPrayerNotificationGateway(),
);

final prayerClockProvider = Provider<PrayerClock>((ref) => DateTime.now);

final prayerIsAndroidProvider = Provider<bool>(
  (ref) => defaultTargetPlatform == TargetPlatform.android,
);

final prayerReminderServiceProvider = Provider<PrayerReminderService>((ref) {
  final service = LocalPrayerReminderService(
    gateway: ref.watch(prayerNotificationGatewayProvider),
    repository: ref.watch(prayerRepositoryProvider),
    identity: ref.watch(currentUserIdentityProvider),
    preferences: DriftPrayerReminderPreferencesStore(
      records: ref.watch(lifeRecordRepositoryProvider),
      identity: ref.watch(currentUserIdentityProvider),
    ),
    readDeviceTimezone: ref.watch(deviceTimezoneProvider),
    clock: ref.watch(prayerClockProvider),
    isAndroid: ref.watch(prayerIsAndroidProvider),
  );
  unawaited(service.start());
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final prayerReminderStatusProvider =
    StreamProvider.autoDispose<PrayerReminderStatus>(
      (ref) => ref.watch(prayerReminderServiceProvider).status,
    );

final deviceTimezoneProvider = Provider<Future<String> Function()>(
  (ref) => readDeviceTimezone,
);

final prayerScheduleProvider = StreamProvider.autoDispose<PrayerSchedule?>(
  (ref) => ref.watch(prayerRepositoryProvider).watchSchedule(),
);

final prayerDayEntriesProvider = StreamProvider.autoDispose
    .family<List<TrackingEntry>, String>(
      (ref, localDate) =>
          ref.watch(prayerRepositoryProvider).watchPrayerEntries(localDate),
    );
