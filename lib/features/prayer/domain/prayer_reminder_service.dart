import 'dart:async';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../records/domain/life_record_repository.dart';
import '../../tracking/domain/tracking_entry.dart';
import 'prayer_models.dart';
import 'prayer_repository.dart';

const prayerReminderInterval = Duration(minutes: 5);
const prayerReminderMaximum = 6;
const prayerReminderHorizonDays = 7;

typedef PrayerClock = DateTime Function();
typedef PrayerTimezoneReader = Future<String> Function();

enum PrayerReminderAvailability {
  checking,
  unsupportedPlatform,
  remindersDisabled,
  notificationPermissionDenied,
  exactAlarmsUnavailable,
  ready,
  timezoneUnavailable,
  failed,
}

class PrayerReminderStatus {
  const PrayerReminderStatus(this.availability, {this.pendingCount = 0});

  final PrayerReminderAvailability availability;
  final int pendingCount;

  String get message => switch (availability) {
    PrayerReminderAvailability.checking => 'Checking reminder settings…',
    PrayerReminderAvailability.unsupportedPlatform =>
      'Prayer notifications are available on Android.',
    PrayerReminderAvailability.remindersDisabled =>
      'Prayer reminders are turned off.',
    PrayerReminderAvailability.notificationPermissionDenied =>
      'Allow notifications in Android settings to receive prayer reminders. Notification access is separate from exact-alarm access.',
    PrayerReminderAvailability.exactAlarmsUnavailable =>
      'Reminders are scheduled inexactly. Android may deliver them late, especially during battery-saving modes.',
    PrayerReminderAvailability.ready =>
      'Prayer reminders are scheduled locally. Delivery can still be delayed by Android or device battery controls.',
    PrayerReminderAvailability.timezoneUnavailable =>
      'The device timezone could not be verified. No prayer reminders were scheduled.',
    PrayerReminderAvailability.failed =>
      'Prayer reminders could not be updated. Review notification settings and try again.',
  };
}

class PrayerReminderRequest {
  const PrayerReminderRequest({
    required this.id,
    required this.ownerUid,
    required this.localDate,
    required this.prayer,
    required this.kind,
    required this.scheduledAt,
  });

  final int id;
  final String ownerUid;
  final String localDate;
  final PrayerName prayer;
  final PrayerNotificationKind kind;
  final tz.TZDateTime scheduledAt;
}

enum PrayerNotificationKind { azan, reminder, snooze }

class PrayerNotificationAction {
  const PrayerNotificationAction({
    required this.ownerUid,
    required this.localDate,
    required this.prayer,
    required this.action,
  });

  final String ownerUid;
  final String localDate;
  final PrayerName prayer;
  final String action;
}

abstract interface class PrayerNotificationGateway {
  Future<void> initialize(
    Future<void> Function(PrayerNotificationAction) onAction,
  );
  Future<bool> notificationsAllowed();
  Future<bool> requestNotificationPermission();
  Future<void> openNotificationSettings();
  Future<bool> exactAlarmsAllowed();
  Future<bool> requestExactAlarmAccess();
  Future<void> schedule(PrayerReminderRequest request, {required bool exact});
  Future<void> cancel(int id);
  Future<void> cancelOwner(String uid);
  Future<void> cancelAllManaged();
}

class PrayerReminderPreferences {
  PrayerReminderPreferences({
    Set<String>? dismissed,
    Map<String, int>? snoozedAt,
    this.remindersDisabled = false,
  }) : dismissed = Set.unmodifiable(dismissed ?? const {}),
       snoozedAt = Map.unmodifiable(snoozedAt ?? const {});

  final Set<String> dismissed;
  final Map<String, int> snoozedAt;
  final bool remindersDisabled;

  PrayerReminderPreferences copyWith({
    Set<String>? dismissed,
    Map<String, int>? snoozedAt,
    bool? remindersDisabled,
  }) => PrayerReminderPreferences(
    dismissed: dismissed ?? this.dismissed,
    snoozedAt: snoozedAt ?? this.snoozedAt,
    remindersDisabled: remindersDisabled ?? this.remindersDisabled,
  );
}

abstract interface class PrayerReminderPreferencesStore {
  Future<PrayerReminderPreferences> read(String uid);
  Future<void> write(String uid, PrayerReminderPreferences preferences);
}

abstract interface class PrayerReminderService {
  Stream<PrayerReminderStatus> get status;
  Future<void> start();
  Future<void> reconcile();
  Future<void> requestNotifications();
  Future<void> openNotificationSettings();
  Future<void> requestExactAlarms();
  Future<void> setRemindersEnabled(bool enabled);
  Future<void> prayerRecorded(PrayerName prayer, String localDate);
  Future<void> dismissSession(PrayerNotificationAction action);
  Future<void> snoozeSession(PrayerNotificationAction action);
  Future<void> dispose();
}

/// Coordinates local notification state; all data reads remain scoped to the
/// active Auth UID and no network write path is available here.
class LocalPrayerReminderService implements PrayerReminderService {
  LocalPrayerReminderService({
    required this.gateway,
    required this.repository,
    required this.identity,
    required this.preferences,
    required this.readDeviceTimezone,
    required this.clock,
    required this.isAndroid,
  });

  final PrayerNotificationGateway gateway;
  final PrayerRepository repository;
  final CurrentUserIdentity identity;
  final PrayerReminderPreferencesStore preferences;
  final PrayerTimezoneReader readDeviceTimezone;
  final PrayerClock clock;
  final bool isAndroid;

  final StreamController<PrayerReminderStatus> _status =
      StreamController<PrayerReminderStatus>.broadcast();
  Future<void> _queue = Future<void>.value();
  bool _started = false;
  bool _disposed = false;
  String? _scheduledUid;
  PrayerReminderStatus _lastStatus = const PrayerReminderStatus(
    PrayerReminderAvailability.checking,
  );

  @override
  Stream<PrayerReminderStatus> get status => Stream.multi((controller) {
    controller.add(_lastStatus);
    final subscription = _status.stream.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });
  PrayerReminderStatus get currentStatus => _lastStatus;

  StreamSubscription<PrayerSchedule?>? _scheduleSubscription;
  StreamSubscription<String?>? _identitySubscription;
  Timer? _calendarTimer;
  String? _lastTimezoneId;
  String? _lastLocalDate;

  void _emit(PrayerReminderAvailability availability, {int pending = 0}) {
    _lastStatus = PrayerReminderStatus(availability, pendingCount: pending);
    if (!_disposed) _status.add(_lastStatus);
  }

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!isAndroid) {
      _emit(PrayerReminderAvailability.unsupportedPlatform);
      return;
    }
    try {
      tzdata.initializeTimeZones();
      await gateway.initialize(_handleAction);
      _scheduleSubscription = repository.watchSchedule().listen(
        (_) => unawaited(reconcile()),
        onError: (Object _) => _emit(PrayerReminderAvailability.failed),
      );
      _identitySubscription = identity.uidChanges.listen(
        (_) => unawaited(reconcile()),
        onError: (Object _) => _emit(PrayerReminderAvailability.failed),
      );
      _calendarTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => unawaited(_checkCalendarChange()),
      );
      await reconcile();
    } on Object {
      _emit(PrayerReminderAvailability.failed);
    }
  }

  @override
  Future<void> reconcile() {
    final next = _queue.then((_) async {
      try {
        await _reconcile();
      } on Object {
        _emit(PrayerReminderAvailability.failed);
      }
    });
    _queue = next;
    return next;
  }

  Future<void> _reconcile() async {
    if (_disposed || !isAndroid) {
      if (!isAndroid) _emit(PrayerReminderAvailability.unsupportedPlatform);
      return;
    }
    final uid = identity.currentUid;
    if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
      final previous = _scheduledUid;
      if (previous != null) {
        await _cancelHorizon(previous);
      } else {
        await gateway.cancelAllManaged();
      }
      _scheduledUid = null;
      _emit(PrayerReminderAvailability.remindersDisabled);
      return;
    }
    final previousUid = _scheduledUid;
    if (previousUid == null) await gateway.cancelAllManaged();
    if (previousUid != null && previousUid != uid) {
      await _cancelHorizon(previousUid);
    }
    _scheduledUid = uid;

    // Cancel known stable IDs before recreating them. This makes reconciliation
    // idempotent and removes stale times after schedule edits or timezone shifts.
    await _cancelHorizon(uid);
    if (identity.currentUid != uid) return;

    final schedule = await repository.watchSchedule().first;
    if (identity.currentUid != uid) return;
    if (schedule == null || !schedule.remindersEnabled) {
      _emit(PrayerReminderAvailability.remindersDisabled);
      return;
    }
    if (!await gateway.notificationsAllowed()) {
      _emit(PrayerReminderAvailability.notificationPermissionDenied);
      return;
    }
    final savedPreferences = await preferences.read(uid);
    if (identity.currentUid != uid) return;
    if (savedPreferences.remindersDisabled) {
      _emit(PrayerReminderAvailability.remindersDisabled);
      return;
    }

    final String timezoneId;
    try {
      timezoneId = await readDeviceTimezone();
    } on Object {
      _emit(PrayerReminderAvailability.timezoneUnavailable);
      return;
    }
    if (identity.currentUid != uid) return;

    _lastTimezoneId = timezoneId;

    final tz.Location location;
    try {
      location = tz.getLocation(timezoneId);
    } on Object {
      _emit(PrayerReminderAvailability.timezoneUnavailable);
      return;
    }
    final exact = await gateway.exactAlarmsAllowed();
    if (identity.currentUid != uid) return;
    final localNow = tz.TZDateTime.from(clock(), location);
    _lastLocalDate = prayerDateKey(
      DateTime(localNow.year, localNow.month, localNow.day),
    );
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    var count = 0;

    for (
      var dayOffset = 0;
      dayOffset < prayerReminderHorizonDays;
      dayOffset++
    ) {
      if (identity.currentUid != uid) return;
      final day = DateTime(today.year, today.month, today.day + dayOffset);
      final dateKey = prayerDateKey(day);
      final dateEntries = await repository.watchPrayerEntries(dateKey).first;
      if (identity.currentUid != uid) return;
      final completed = dateEntries
          .where(
            (entry) =>
                entry.ownerUid == uid && entry.kind == TrackingEntryKind.prayer,
          )
          .map((entry) => entry.entryKey)
          .toSet();

      for (final prayer in PrayerName.values) {
        final session = _sessionKey(dateKey, prayer);
        if (completed.contains(prayer.label) ||
            savedPreferences.dismissed.contains(session)) {
          continue;
        }
        final times = schedule.slots[prayer]!;
        final azan = tz.TZDateTime(
          location,
          day.year,
          day.month,
          day.day,
          times.azanMinute ~/ 60,
          times.azanMinute % 60,
        );
        final jamaat = tz.TZDateTime(
          location,
          day.year,
          day.month,
          day.day,
          times.jamaatMinute ~/ 60,
          times.jamaatMinute % 60,
        );
        if (azan.isAfter(localNow)) {
          await _schedule(
            uid,
            dateKey,
            prayer,
            PrayerNotificationKind.azan,
            0,
            azan,
            exact,
          );
          count++;
        }
        for (var ordinal = 1; ordinal <= prayerReminderMaximum; ordinal++) {
          final reminderAt = azan.add(prayerReminderInterval * ordinal);
          if (!reminderAt.isBefore(jamaat)) break;
          if (reminderAt.isAfter(localNow)) {
            await _schedule(
              uid,
              dateKey,
              prayer,
              PrayerNotificationKind.reminder,
              ordinal,
              reminderAt,
              exact,
            );
            count++;
          }
        }
        final snoozedAt = savedPreferences.snoozedAt[session];
        if (snoozedAt != null) {
          final snoozeAt = tz.TZDateTime.from(
            DateTime.fromMillisecondsSinceEpoch(snoozedAt, isUtc: true),
            location,
          );
          if (snoozeAt.isAfter(localNow) && snoozeAt.isBefore(jamaat)) {
            await _schedule(
              uid,
              dateKey,
              prayer,
              PrayerNotificationKind.snooze,
              7,
              snoozeAt,
              exact,
            );
            count++;
          }
        }
      }
    }
    if (identity.currentUid == uid) {
      _emit(
        exact
            ? PrayerReminderAvailability.ready
            : PrayerReminderAvailability.exactAlarmsUnavailable,
        pending: count,
      );
    }
  }

  Future<void> _checkCalendarChange() async {
    if (_disposed || identity.currentUid == null) return;
    try {
      final timezoneId = await readDeviceTimezone();
      final now = clock();
      final localDate = prayerDateKey(now);
      if (timezoneId != _lastTimezoneId || localDate != _lastLocalDate) {
        await reconcile();
      }
    } on Object {
      if (_lastTimezoneId != null) await reconcile();
    }
  }

  Future<void> _schedule(
    String uid,
    String date,
    PrayerName prayer,
    PrayerNotificationKind kind,
    int ordinal,
    tz.TZDateTime at,
    bool exact,
  ) => gateway.schedule(
    PrayerReminderRequest(
      id: stablePrayerNotificationId(uid, date, prayer, kind, ordinal),
      ownerUid: uid,
      localDate: date,
      prayer: prayer,
      kind: kind,
      scheduledAt: at,
    ),
    exact: exact,
  );

  Future<void> _cancelHorizon(String uid) async {
    await gateway.cancelOwner(uid);
  }

  @override
  Future<void> requestNotifications() async {
    if (!isAndroid) return;
    await gateway.requestNotificationPermission();
    await reconcile();
  }

  @override
  Future<void> openNotificationSettings() async {
    if (!isAndroid) return;
    await gateway.openNotificationSettings();
  }

  @override
  Future<void> requestExactAlarms() async {
    if (!isAndroid) return;
    await gateway.requestExactAlarmAccess();
    await reconcile();
  }

  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    final uid = identity.currentUid;
    if (uid == null || uid.trim().isEmpty) return;
    final current = await preferences.read(uid);
    if (identity.currentUid != uid) return;
    await preferences.write(uid, current.copyWith(remindersDisabled: !enabled));
    await reconcile();
  }

  @override
  Future<void> prayerRecorded(PrayerName prayer, String localDate) async {
    final uid = identity.currentUid;
    if (uid == null) return;
    try {
      await _cancelSession(uid, localDate, prayer);
      await reconcile();
    } on Object {
      _emit(PrayerReminderAvailability.failed);
      await reconcile();
    }
  }

  @override
  Future<void> dismissSession(PrayerNotificationAction action) async {
    final uid = identity.currentUid;
    if (uid == null || uid != action.ownerUid) {
      return;
    }
    final current = await preferences.read(uid);
    await preferences.write(
      uid,
      current.copyWith(
        dismissed: {
          ...current.dismissed,
          _sessionKey(action.localDate, action.prayer),
        },
      ),
    );
    await _cancelSession(uid, action.localDate, action.prayer);
    await reconcile();
  }

  @override
  Future<void> snoozeSession(PrayerNotificationAction action) async {
    final uid = identity.currentUid;
    if (uid == null || uid != action.ownerUid) return;
    final session = _sessionKey(action.localDate, action.prayer);
    final current = await preferences.read(uid);
    if (current.snoozedAt.containsKey(session) ||
        current.dismissed.contains(session)) {
      return;
    }
    final updated = current.copyWith(
      snoozedAt: {
        ...current.snoozedAt,
        session:
            clock().toUtc().millisecondsSinceEpoch +
            prayerReminderInterval.inMilliseconds,
      },
    );
    await preferences.write(uid, updated);
    await reconcile();
  }

  Future<void> _cancelSession(
    String uid,
    String date,
    PrayerName prayer,
  ) async {
    for (final kind in PrayerNotificationKind.values) {
      for (var ordinal = 0; ordinal <= prayerReminderMaximum + 1; ordinal++) {
        await gateway.cancel(
          stablePrayerNotificationId(uid, date, prayer, kind, ordinal),
        );
      }
    }
  }

  Future<void> _handleAction(PrayerNotificationAction action) async {
    if (action.action == 'dismiss') {
      await dismissSession(action);
    } else if (action.action == 'snooze') {
      await snoozeSession(action);
    } else if (action.action == 'disable') {
      await setRemindersEnabled(false);
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _calendarTimer?.cancel();
    await _scheduleSubscription?.cancel();
    await _identitySubscription?.cancel();
    await _status.close();
  }
}

String _sessionKey(String date, PrayerName prayer) => '${date}_${prayer.name}';

/// FNV-1a 32-bit gives stable IDs across app launches and Dart processes.
int stablePrayerNotificationId(
  String uid,
  String date,
  PrayerName prayer,
  PrayerNotificationKind kind,
  int ordinal,
) {
  final value = '$uid|$date|${prayer.name}|${kind.name}|$ordinal';
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}
