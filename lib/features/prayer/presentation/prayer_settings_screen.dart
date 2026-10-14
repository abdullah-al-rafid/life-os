import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/prayer_models.dart';
import '../domain/prayer_reminder_service.dart';
import 'prayer_providers.dart';

class PrayerSettingsScreen extends ConsumerStatefulWidget {
  const PrayerSettingsScreen({super.key});
  @override
  ConsumerState<PrayerSettingsScreen> createState() =>
      _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends ConsumerState<PrayerSettingsScreen> {
  final Map<PrayerName, int?> _azans = {};
  final Map<PrayerName, int?> _jamaats = {};
  bool _initialized = false;
  bool _saving = false;
  bool _remindersEnabled = false;
  bool _remindersTouched = false;
  String? _validation;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerScheduleProvider);
    final reminderStatus = ref.watch(prayerReminderStatusProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: state.when(
              loading: () => const LoadingStateView(),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ErrorStateView(
                  message: 'Prayer settings could not be loaded.',
                  onRetry: () => ref.invalidate(prayerScheduleProvider),
                ),
              ),
              data: (schedule) {
                if (!_initialized) {
                  _initialized = true;
                  if (schedule != null) {
                    _remindersEnabled = schedule.remindersEnabled;
                    for (final prayer in PrayerName.values) {
                      _azans[prayer] = schedule.slots[prayer]!.azanMinute;
                      _jamaats[prayer] = schedule.slots[prayer]!.jamaatMinute;
                    }
                  }
                }
                final notificationActionDisabled =
                    !_remindersTouched &&
                    schedule?.remindersEnabled == true &&
                    reminderStatus.asData?.value.availability ==
                        PrayerReminderAvailability.remindersDisabled;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/prayer'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: Text(
                            'Prayer settings',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Set your local Azan and Jamaat times manually. LIFE OS does not calculate prayer times.',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Schedule follows the device timezone. Historical dates and saved snapshots are not rewritten.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SurfaceCard(
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: AppColors.cyan),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Saved privately on this device · Cloud sync off',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile.adaptive(
                            key: const Key('prayer_reminders_enabled'),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Prayer reminders'),
                            subtitle: const Text(
                              'Azan plus reminders every 5 minutes, up to 6 before Jamaat. Save the schedule to apply.',
                            ),
                            value:
                                _remindersEnabled &&
                                !notificationActionDisabled,
                            onChanged: (value) => setState(() {
                              _remindersTouched = true;
                              _remindersEnabled = value;
                            }),
                          ),
                          Text(
                            reminderStatus.when(
                              data: (value) => value.message,
                              loading: () => 'Checking notification access…',
                              error: (_, _) =>
                                  'Notification settings could not be checked.',
                            ),
                            key: const Key('prayer_reminder_status'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              OutlinedButton.icon(
                                key: const Key(
                                  'prayer_request_notification_permission',
                                ),
                                onPressed: _requestNotificationPermission,
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                ),
                                label: const Text('Allow notifications'),
                              ),
                              OutlinedButton.icon(
                                key: const Key(
                                  'prayer_open_notification_settings',
                                ),
                                onPressed: _openNotificationSettings,
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text('Notification settings'),
                              ),
                              if (reminderStatus.asData?.value.availability ==
                                  PrayerReminderAvailability
                                      .exactAlarmsUnavailable)
                                OutlinedButton.icon(
                                  key: const Key('prayer_request_exact_alarms'),
                                  onPressed: _requestExactAlarmAccess,
                                  icon: const Icon(Icons.alarm_outlined),
                                  label: const Text('Allow exact timing'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final prayer in PrayerName.values) ...[
                      _PrayerTimeEditor(
                        prayer: prayer,
                        azanMinute: _azans[prayer],
                        jamaatMinute: _jamaats[prayer],
                        onAzan: () => _pickTime(prayer, isAzan: true),
                        onJamaat: () => _pickTime(prayer, isAzan: false),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_validation != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _validation!,
                        key: const Key('prayer_schedule_validation'),
                        style: const TextStyle(color: Color(0xFFFF7D91)),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      key: const Key('prayer_schedule_save'),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        schedule == null ? 'Save prayer times' : 'Save changes',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(PrayerName prayer, {required bool isAzan}) async {
    final initialMinute = isAzan ? _azans[prayer] : _jamaats[prayer];
    final picked = await showTimePicker(
      context: context,
      initialTime: initialMinute == null
          ? TimeOfDay(hour: isAzan ? 5 : 5, minute: isAzan ? 0 : 30)
          : TimeOfDay(hour: initialMinute ~/ 60, minute: initialMinute % 60),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final minute = picked.hour * 60 + picked.minute;
      if (isAzan) {
        _azans[prayer] = minute;
      } else {
        _jamaats[prayer] = minute;
      }
      _validation = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _validation = null;
    });
    try {
      final timezone = await ref.read(deviceTimezoneProvider)();
      final next = PrayerSchedule(
        timezoneId: timezone,
        remindersEnabled: _remindersEnabled,
        slots: {
          for (final prayer in PrayerName.values)
            if (_azans[prayer] != null && _jamaats[prayer] != null)
              prayer: PrayerTimes(
                azanMinute: _azans[prayer]!,
                jamaatMinute: _jamaats[prayer]!,
              ),
        },
      );
      await ref.read(prayerRepositoryProvider).saveSchedule(next);
      await ref
          .read(prayerReminderServiceProvider)
          .setRemindersEnabled(_remindersEnabled);
      if (mounted) {
        setState(() => _remindersTouched = false);
        ref.invalidate(prayerScheduleProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prayer times saved privately on this device.'),
          ),
        );
      }
    } on PrayerValidationFailure catch (error) {
      if (mounted) setState(() => _validation = error.message);
    } on DeviceTimezoneFailure catch (error) {
      if (mounted) setState(() => _validation = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _validation =
              'Prayer times could not be saved. Check the local account and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await ref.read(prayerReminderServiceProvider).requestNotifications();
    } on Object {
      if (mounted) {
        setState(
          () => _validation = 'Notification permission could not be requested.',
        );
      }
    }
  }

  Future<void> _requestExactAlarmAccess() async {
    try {
      await ref.read(prayerReminderServiceProvider).requestExactAlarms();
    } on Object {
      if (mounted) {
        setState(
          () => _validation =
              'Exact-alarm access could not be opened. Inexact reminders remain available.',
        );
      }
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      await ref.read(prayerReminderServiceProvider).openNotificationSettings();
    } on Object {
      if (mounted) {
        setState(
          () => _validation =
              'Android notification settings could not be opened.',
        );
      }
    }
  }
}

class _PrayerTimeEditor extends StatelessWidget {
  const _PrayerTimeEditor({
    required this.prayer,
    required this.azanMinute,
    required this.jamaatMinute,
    required this.onAzan,
    required this.onJamaat,
  });
  final PrayerName prayer;
  final int? azanMinute;
  final int? jamaatMinute;
  final VoidCallback onAzan;
  final VoidCallback onJamaat;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prayer.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              key: Key('prayer_azan_${prayer.name}'),
              onPressed: onAzan,
              icon: const Icon(Icons.notifications_none_rounded),
              label: Text(
                azanMinute == null
                    ? 'Set Azan'
                    : 'Azan · ${formatPrayerMinute(azanMinute!)}',
              ),
            ),
            OutlinedButton.icon(
              key: Key('prayer_jamaat_${prayer.name}'),
              onPressed: onJamaat,
              icon: const Icon(Icons.groups_2_outlined),
              label: Text(
                jamaatMinute == null
                    ? 'Set Jamaat'
                    : 'Jamaat · ${formatPrayerMinute(jamaatMinute!)}',
              ),
            ),
          ],
        ),
        if (azanMinute != null &&
            jamaatMinute != null &&
            jamaatMinute! <= azanMinute!)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Jamaat must be later than Azan.',
              style: TextStyle(color: Color(0xFFFF7D91)),
            ),
          ),
      ],
    ),
  );
}
