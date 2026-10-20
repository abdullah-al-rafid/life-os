import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/domain/life_record.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../domain/prayer_models.dart';
import 'prayer_providers.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  DateTime _date = DateTime.now();
  final Set<String> _saving = {};
  final Map<PrayerName, JamaatStatus?> _jamaat = {};
  final Set<PrayerName> _jamaatTouched = {};
  final Map<PrayerName, String> _notes = {};
  final Map<PrayerName, TrackingEntry?> _currentEntries = {};

  @override
  Widget build(BuildContext context) {
    final dateKey = prayerDateKey(_date);
    final schedule = ref.watch(prayerScheduleProvider);
    final entries = ref.watch(prayerDayEntriesProvider(dateKey));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Prayer',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ),
                            IconButton(
                              key: const Key('prayer_settings'),
                              tooltip: 'Prayer settings',
                              onPressed: () => context.go('/prayer/settings'),
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const PrivacySourceLabel(
                          source: PrivacySource.privateLocal,
                          details: 'Prayer records stay on this device',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DateSelector(
                          date: _date,
                          onPrevious: () => setState(
                            () =>
                                _date = _date.subtract(const Duration(days: 1)),
                          ),
                          onNext: () => setState(
                            () => _date = _date.add(const Duration(days: 1)),
                          ),
                          onPick: (value) => setState(() => _date = value),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                schedule.when(
                  loading: () =>
                      const SliverFillRemaining(child: LoadingStateView()),
                  error: (_, _) => SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: ErrorStateView(
                        message:
                            'The local prayer schedule could not be loaded.',
                        onRetry: () => ref.invalidate(prayerScheduleProvider),
                      ),
                    ),
                  ),
                  data: (value) {
                    if (value == null) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: EmptyStateView(
                            title: 'Set your prayer times',
                            message:
                                'Add Azan and Jamaat times for all five prayers. LIFE OS does not calculate prayer times.',
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                      );
                    }
                    return entries.when(
                      loading: () =>
                          const SliverFillRemaining(child: LoadingStateView()),
                      error: (_, _) => SliverFillRemaining(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: ErrorStateView(
                            message:
                                'Prayer records for this date could not be loaded.',
                            onRetry: () => ref.invalidate(
                              prayerDayEntriesProvider(dateKey),
                            ),
                          ),
                        ),
                      ),
                      data: (values) {
                        final byPrayer = {
                          for (final entry in values) entry.entryKey: entry,
                        };
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          sliver: SliverList.separated(
                            itemCount: PrayerName.values.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final prayer = PrayerName.values[index];
                              final entry = byPrayer[prayer.label];
                              _currentEntries[prayer] = entry;
                              return _PrayerCard(
                                prayer: prayer,
                                times: value.slots[prayer]!,
                                entry: entry,
                                saving: _saving.contains(prayer.name),
                                selectedJamaat: _jamaatTouched.contains(prayer)
                                    ? _jamaat[prayer]
                                    : _jamaatFromEntry(entry),
                                notes:
                                    _notes[prayer] ??
                                    (entry?.payload['notes'] as String? ?? ''),
                                onJamaatChanged: (v) => setState(() {
                                  _jamaatTouched.add(prayer);
                                  _jamaat[prayer] = v;
                                }),
                                onNotesChanged: (v) => _notes[prayer] = v,
                                onSave: (status) =>
                                    _save(prayer, dateKey, status),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  JamaatStatus? _jamaatFromEntry(TrackingEntry? entry) {
    final value = entry?.payload['jamaatStatus'];
    if (value is! String) return null;
    for (final status in JamaatStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  Future<void> _save(
    PrayerName prayer,
    String date,
    PrayerCompletion status,
  ) async {
    setState(() => _saving.add(prayer.name));
    try {
      await ref
          .read(prayerRepositoryProvider)
          .savePrayerStatus(
            prayer: prayer,
            localDate: date,
            status: status,
            jamaatStatus: _jamaatTouched.contains(prayer)
                ? _jamaat[prayer]
                : _jamaatFromEntry(_currentEntries[prayer]),
            notes: _notes[prayer],
          );
      try {
        await ref
            .read(prayerReminderServiceProvider)
            .prayerRecorded(prayer, date);
      } on Object {
        // The saved local prayer record remains authoritative if Android
        // notification cancellation is temporarily unavailable.
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prayer record saved on this device.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_prayerError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving.remove(prayer.name));
    }
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.prayer,
    required this.times,
    required this.entry,
    required this.saving,
    required this.selectedJamaat,
    required this.notes,
    required this.onJamaatChanged,
    required this.onNotesChanged,
    required this.onSave,
  });

  final PrayerName prayer;
  final PrayerTimes times;
  final dynamic entry;
  final bool saving;
  final JamaatStatus? selectedJamaat;
  final String notes;
  final ValueChanged<JamaatStatus?> onJamaatChanged;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<PrayerCompletion> onSave;

  @override
  Widget build(BuildContext context) {
    final completion = entry?.payload['status'] as String?;
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prayer.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                'Azan ${formatPrayerMinute(times.azanMinute)}  ·  Jamaat ${formatPrayerMinute(times.jamaatMinute)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            completion == null ? 'Not recorded' : _statusLabel(completion),
            style: TextStyle(
              color: completion == null
                  ? AppColors.textSecondary
                  : AppColors.cyan,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final status in PrayerCompletion.values)
                OutlinedButton(
                  key: Key('prayer_${prayer.name}_${status.name}'),
                  onPressed: saving ? null : () => onSave(status),
                  style: completion == status.name
                      ? OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cyan,
                          side: const BorderSide(color: AppColors.cyan),
                        )
                      : null,
                  child: Text(_statusLabel(status.name)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<JamaatStatus?>(
            key: Key('jamaat_${prayer.name}'),
            initialValue: selectedJamaat,
            decoration: const InputDecoration(
              labelText: 'Prayer setting (optional)',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<JamaatStatus?>(
                value: null,
                child: Text('Not recorded'),
              ),
              for (final value in JamaatStatus.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(switch (value) {
                    JamaatStatus.jamaat => 'Jamaat',
                    JamaatStatus.individual => 'Individual',
                    JamaatStatus.unknown => 'Unknown',
                  }),
                ),
            ],
            onChanged: saving ? null : onJamaatChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: Key('prayer_notes_${prayer.name}'),
            initialValue: notes,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            onChanged: onNotesChanged,
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });
  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onPick;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Previous day',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: TextButton.icon(
            key: const Key('prayer_date'),
            onPressed: () async {
              final value = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (value != null) onPick(value);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next day',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}

String _statusLabel(String status) => switch (status) {
  'prayedOnTime' => 'Prayed on time',
  'prayedLate' => 'Prayed late',
  'missed' => 'Missed',
  _ => 'Not recorded',
};

String _prayerError(Object error) => switch (error) {
  PrayerValidationFailure() => error.toString(),
  DeviceTimezoneFailure() => error.toString(),
  StaleTrackingEntryRevision() =>
    'This prayer record changed. Reload the date and try again.',
  UnauthenticatedOperation() => 'Sign in to access local prayer records.',
  _ => 'The prayer record could not be saved. Please try again.',
};
