import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/surface_card.dart';
import '../../planning/domain/planning_repository.dart';
import '../../records/presentation/record_providers.dart';
import '../../tracking/presentation/tracking_summary_card.dart';
import '../../prayer/presentation/prayer_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(planningItemsProvider(null));
    final history = ref.watch(planningHistoryProvider(null));
    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIFE OS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.cyan,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Make room for\nwhat matters.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _date(now),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const TrackingSummaryCard(),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        key: const Key('dashboard_import_plan'),
                        onPressed: () => context.go('/plan/import'),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Import 15-Day Plan'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    items.when(
                      loading: () => const LoadingStateView(),
                      error: (_, _) => const ErrorStateView(
                        message: 'Goal and sharing summaries are unavailable.',
                      ),
                      data: (values) {
                        final goals = values
                            .where((item) => item.kind == PlanningKind.goal)
                            .length;
                        final shared = values
                            .where((item) => item.visibility.name == 'shared')
                            .length;
                        return SurfaceCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                color: AppColors.purple,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  '$goals active goals · $shared records marked shared locally. Cloud sync is off.',
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/insights'),
                                child: const Text('Progress'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PrayerSummary(dateKey: todayKey),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/screen-time'),
                        icon: const Icon(Icons.query_stats_outlined),
                        label: const Text('Screen Time'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Row(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          color: AppColors.purple,
                          size: 17,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Offline ready · Saved on this device · Cloud sync off',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SurfaceCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.purple,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Build a steady rhythm',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Small, deliberate actions add up.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/plan'),
                            child: const Text('Open plan'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Today',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/insights'),
                          child: const Text('View insights'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    history.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text(
                        'Today’s completion progress is unavailable.',
                      ),
                      data: (entries) {
                        final tasks =
                            items.asData?.value
                                .where(
                                  (item) =>
                                      item.kind == PlanningKind.task &&
                                      item.occursOn(now),
                                )
                                .toList() ??
                            const <PlanningItem>[];
                        final taskIds = tasks.map((item) => item.id).toSet();
                        final completedIds = <String>{};
                        for (final entry in entries) {
                          if (entry.kind != 'taskCompletion' ||
                              entry.localDate != todayKey ||
                              !taskIds.contains(entry.definitionId)) {
                            continue;
                          }
                          try {
                            final payload =
                                jsonDecode(entry.payload)
                                    as Map<String, dynamic>;
                            if (payload['status'] ==
                                CompletionStatus.done.name) {
                              completedIds.add(entry.definitionId);
                            }
                          } on Object {
                            // Invalid historical payloads do not count as done.
                          }
                        }
                        return Text(
                          'Completion progress: ${completedIds.length}/${tasks.length} tasks done',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            items.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: LoadingStateView(),
                ),
              ),
              error: (_, _) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: ErrorStateView(
                    message: 'Your local dashboard could not be loaded.',
                  ),
                ),
              ),
              data: (all) {
                final today =
                    all
                        .where(
                          (i) =>
                              i.kind != PlanningKind.goal &&
                              (i.occursOn(now) ||
                                  (i.kind == PlanningKind.task &&
                                      i.scheduledDate != null &&
                                      i.scheduledDate!.compareTo(todayKey) <
                                          0)),
                        )
                        .toList()
                      ..sort((a, b) {
                        final aOverdue =
                            a.scheduledDate != null &&
                            a.scheduledDate!.compareTo(todayKey) < 0;
                        final bOverdue =
                            b.scheduledDate != null &&
                            b.scheduledDate!.compareTo(todayKey) < 0;
                        if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
                        final byPriority = a.priority.compareTo(b.priority);
                        return byPriority != 0
                            ? byPriority
                            : a.scheduledMinute.compareTo(b.scheduledMinute);
                      });
                if (today.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: EmptyStateView(
                        title: 'Your day is open',
                        message:
                            'Add a task, routine, or habit in Plan to see your real schedule here.',
                        icon: Icons.event_available_outlined,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverList.separated(
                    itemCount: today.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = today[index];
                      final completion = _completionFor(
                        history.asData?.value ?? const [],
                        item.id,
                        todayKey,
                      );
                      return SurfaceCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.circle_outlined,
                                  color: AppColors.cyan,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (item.visibility.name == 'shared')
                                  const Chip(label: Text('Shared · local')),
                              ],
                            ),
                            Text(
                              '${item.scheduledDate != null && item.scheduledDate!.compareTo(todayKey) < 0 ? 'Overdue · ' : ''}${item.kind.name} · Priority ${item.priority} · ${item.durationMinutes} min${item.targetDate == null ? '' : ' · Deadline ${item.targetDate}'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (completion != null)
                              Text(
                                'Today: ${completion.name}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (item.kind != PlanningKind.goal)
                              Wrap(
                                spacing: 2,
                                children: [
                                  _QuickCompletionButton(
                                    label: 'Done',
                                    item: item,
                                    status: CompletionStatus.done,
                                    date: now,
                                  ),
                                  _QuickCompletionButton(
                                    label: 'Partial',
                                    item: item,
                                    status: CompletionStatus.partial,
                                    date: now,
                                  ),
                                  _QuickCompletionButton(
                                    label: 'Not Done',
                                    item: item,
                                    status: CompletionStatus.notDone,
                                    date: now,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerSummary extends ConsumerWidget {
  const _PrayerSummary({required this.dateKey});
  final String dateKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(prayerDayEntriesProvider(dateKey));
    final uid = ref.watch(currentUserIdentityProvider).currentUid;
    return SurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.mosque_outlined, color: AppColors.cyan),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: entries.when(
              loading: () => const Text('Loading today’s prayer records…'),
              error: (_, _) => const Text('Prayer summary is unavailable.'),
              data: (values) {
                final own = values
                    .where((entry) => entry.ownerUid == uid)
                    .toList();
                final prayed = own
                    .where(
                      (entry) => const {
                        'prayedOnTime',
                        'prayedLate',
                      }.contains(entry.payload['status']),
                    )
                    .length;
                return Text(
                  'Prayer today · $prayed prayed · ${own.length} of 5 recorded · ${5 - own.length} unrecorded',
                );
              },
            ),
          ),
          TextButton(
            onPressed: () => context.go('/prayer'),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _QuickCompletionButton extends ConsumerWidget {
  const _QuickCompletionButton({
    required this.label,
    required this.item,
    required this.status,
    required this.date,
  });
  final String label;
  final PlanningItem item;
  final CompletionStatus status;
  final DateTime date;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: () async {
      try {
        await ref.read(planningRepositoryProvider).complete(item, date, status);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$label saved locally.')));
        }
      } on Object catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not save this result. It may already be recorded.',
              ),
            ),
          );
        }
      }
    },
    child: Text(label),
  );
}

CompletionStatus? _completionFor(
  List<PlanningHistoryEntry> history,
  String id,
  String date,
) {
  for (final entry in history) {
    if (entry.definitionId != id ||
        entry.localDate != date ||
        !entry.kind.endsWith('Completion')) {
      continue;
    }
    try {
      return CompletionStatus.values.byName(
        (jsonDecode(entry.payload) as Map<String, dynamic>)['status'] as String,
      );
    } on Object {
      return null;
    }
  }
  return null;
}

String _date(DateTime date) =>
    '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}';
String _weekday(int day) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
