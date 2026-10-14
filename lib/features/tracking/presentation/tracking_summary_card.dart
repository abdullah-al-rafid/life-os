import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/presentation/record_providers.dart';
import '../domain/tracking_entry.dart';
import '../domain/tracking_workflows.dart';

class TrackingSummaryCard extends ConsumerWidget {
  const TrackingSummaryCard({this.insights = false, super.key});
  final bool insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(
      trackingEntriesProvider((TrackingEntryKind.fasting, null)),
    );
    final sleeps = ref.watch(
      trackingEntriesProvider((TrackingEntryKind.sleep, null)),
    );
    final workouts = ref.watch(
      trackingEntriesProvider((TrackingEntryKind.workout, null)),
    );
    final uid = ref.watch(currentUserIdentityProvider).currentUid;
    if (fasting.hasError || sleeps.hasError || workouts.hasError) {
      return const ErrorStateView(
        message: 'Local fasting and wellness summaries could not be loaded.',
      );
    }
    if (!fasting.hasValue || !sleeps.hasValue || !workouts.hasValue) {
      return const LoadingStateView();
    }
    final fastingEntries = fasting.value!
        .where((entry) => entry.ownerUid == uid)
        .toList();
    final sleepEntries = sleeps.value!
        .where((entry) => entry.ownerUid == uid)
        .toList();
    final workoutEntries = workouts.value!
        .where((entry) => entry.ownerUid == uid)
        .toList();
    if (insights) {
      final today = DateTime.now();
      final cutoff = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 6));
      final recentFasting = _recent(fastingEntries, cutoff);
      final recentSleep = _recent(sleepEntries, cutoff);
      final recentWorkouts = _recent(workoutEntries, cutoff);
      final fasted = recentFasting
          .where((entry) => entry.payload['status'] == 'fasted')
          .length;
      final averageSleep = recentSleep.isEmpty
          ? null
          : recentSleep
                    .map((entry) => entry.payload['durationMinutes'] as int)
                    .reduce((a, b) => a + b) ~/
                recentSleep.length;
      final workoutMinutes = recentWorkouts.fold<int>(
        0,
        (total, entry) => total + (entry.payload['durationMinutes'] as int),
      );
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fasting & wellness · last 7 days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Fasting: $fasted fasted · ${recentFasting.length} recorded days',
            ),
            Text(
              averageSleep == null
                  ? 'Sleep: no entries recorded'
                  : 'Average sleep: $averageSleep min · ${recentSleep.length} entries',
            ),
            Text('Workouts: ${recentWorkouts.length} · $workoutMinutes min'),
            const SizedBox(height: AppSpacing.sm),
            const Text('Unrecorded dates are not counted as missed.'),
          ],
        ),
      );
    }

    final todayKey = localDateKey(DateTime.now());
    final todayFast = fastingEntries
        .where((entry) => entry.localDate == todayKey)
        .firstOrNull;
    final todaySleep = sleepEntries
        .where((entry) => entry.localDate == todayKey)
        .firstOrNull;
    final todayWorkouts = workoutEntries
        .where((entry) => entry.localDate == todayKey)
        .toList();
    final workoutMinutes = todayWorkouts.fold<int>(
      0,
      (total, entry) => total + (entry.payload['durationMinutes'] as int),
    );
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fasting & wellness today',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            todayFast == null
                ? 'Fasting: Unrecorded'
                : 'Fasting: ${todayFast.payload['status'] == 'fasted' ? 'Fasted' : 'Not fasted'}',
          ),
          Text(
            todaySleep == null
                ? 'Sleep: Unrecorded'
                : 'Sleep: ${todaySleep.payload['durationMinutes']} min',
          ),
          Text('Workouts: ${todayWorkouts.length} · $workoutMinutes min'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: () => context.go('/fasting'),
                child: const Text('Fasting'),
              ),
              TextButton(
                onPressed: () => context.go('/wellness'),
                child: const Text('Wellness'),
              ),
            ],
          ),
          const Text('Private local records · Cloud sync off'),
        ],
      ),
    );
  }
}

List<TrackingEntry> _recent(List<TrackingEntry> entries, DateTime cutoff) =>
    entries.where((entry) {
      final date = parseLocalDateKey(entry.localDate);
      return !date.isBefore(cutoff);
    }).toList();
