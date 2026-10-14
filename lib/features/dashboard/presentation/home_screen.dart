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
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/screen-time'),
                        icon: const Icon(Icons.query_stats_outlined),
                        label: const Text('Screen Time'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SurfaceCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mosque_outlined,
                            color: AppColors.cyan,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prayer',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Track today’s prayers and manage local times.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/prayer'),
                            child: const Text('Open'),
                          ),
                        ],
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
                    itemCount: today.take(6).length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => SurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle_outlined,
                            color: AppColors.cyan,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  today[index].title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  '${today[index].scheduledDate != null && today[index].scheduledDate!.compareTo(todayKey) < 0 ? 'Overdue · ' : ''}${today[index].kind.name} · Priority ${today[index].priority} · ${today[index].durationMinutes} min',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
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
