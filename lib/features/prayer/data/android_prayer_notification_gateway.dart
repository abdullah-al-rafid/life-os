import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/prayer_reminder_service.dart';
import '../domain/prayer_models.dart';

class AndroidPrayerNotificationGateway implements PrayerNotificationGateway {
  AndroidPrayerNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'life_os_prayer_reminders';
  static const _channelName = 'Prayer reminders';
  final FlutterLocalNotificationsPlugin _plugin;
  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize(
    Future<void> Function(PrayerNotificationAction) onAction,
  ) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        final actionId = response.actionId;
        if (payload == null ||
            payload.isEmpty ||
            actionId == null ||
            actionId.isEmpty) {
          return;
        }
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          await onAction(
            PrayerNotificationAction(
              ownerUid: json['uid'] as String,
              localDate: json['date'] as String,
              prayer: PrayerName.values.byName(json['prayer'] as String),
              action: actionId,
            ),
          );
        } on Object {
          // Ignore malformed or stale notification action payloads.
        }
      },
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Locally scheduled prayer time reminders.',
        importance: Importance.defaultImportance,
      ),
    );
  }

  @override
  Future<bool> notificationsAllowed() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestNotificationPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<void> openNotificationSettings() async {
    await _android?.openAppNotificationSettings();
  }

  @override
  Future<bool> exactAlarmsAllowed() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  @override
  Future<bool> requestExactAlarmAccess() async =>
      await _android?.requestExactAlarmsPermission() ?? false;

  @override
  Future<void> schedule(
    PrayerReminderRequest request, {
    required bool exact,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Locally scheduled prayer time reminders.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        actions: const [
          AndroidNotificationAction(
            'snooze',
            'Snooze 5 min',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'dismiss',
            'Dismiss prayer',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'disable',
            'Turn off reminders',
            showsUserInterface: true,
          ),
        ],
      ),
    );
    final label = request.prayer.label;
    final title = request.kind == PrayerNotificationKind.azan
        ? '$label Azan time'
        : '$label prayer reminder';
    final body = request.kind == PrayerNotificationKind.azan
        ? 'Azan time. Jamaat is at the time you set in LIFE OS.'
        : 'A gentle reminder before the Jamaat time you set.';
    await _plugin.zonedSchedule(
      id: request.id,
      title: title,
      body: body,
      scheduledDate: request.scheduledAt,
      notificationDetails: details,
      payload: jsonEncode({
        'app': 'life_os_prayer',
        'uid': request.ownerUid,
        'date': request.localDate,
        'prayer': request.prayer.name,
      }),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelOwner(String uid) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload;
      if (payload == null) continue;
      try {
        final value = jsonDecode(payload) as Map<String, dynamic>;
        if (value['app'] == 'life_os_prayer' && value['uid'] == uid) {
          await _plugin.cancel(id: request.id);
        }
      } on Object {
        // Leave notifications with unrelated or malformed payloads untouched.
      }
    }
    final active = await _plugin.getActiveNotifications();
    for (final notification in active) {
      final payload = notification.payload;
      final id = notification.id;
      if (payload == null || id == null) continue;
      try {
        final value = jsonDecode(payload) as Map<String, dynamic>;
        if (value['app'] == 'life_os_prayer' && value['uid'] == uid) {
          await _plugin.cancel(id: id);
        }
      } on Object {
        // Leave notifications with unrelated or malformed payloads untouched.
      }
    }
  }

  @override
  Future<void> cancelAllManaged() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload;
      if (payload == null) continue;
      try {
        final value = jsonDecode(payload) as Map<String, dynamic>;
        if (value['app'] == 'life_os_prayer') {
          await _plugin.cancel(id: request.id);
        }
      } on Object {
        // Leave notifications with unrelated or malformed payloads untouched.
      }
    }
    final active = await _plugin.getActiveNotifications();
    for (final notification in active) {
      final payload = notification.payload;
      final id = notification.id;
      if (payload == null || id == null) continue;
      try {
        final value = jsonDecode(payload) as Map<String, dynamic>;
        if (value['app'] == 'life_os_prayer') await _plugin.cancel(id: id);
      } on Object {
        // Leave notifications with unrelated or malformed payloads untouched.
      }
    }
  }
}
