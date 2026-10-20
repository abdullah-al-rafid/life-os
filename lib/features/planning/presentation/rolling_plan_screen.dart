import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/presentation/record_providers.dart';
import '../domain/planning_repository.dart';
import '../domain/rolling_plan.dart';
import '../domain/task_plan_import.dart';

class RollingPlanScreen extends ConsumerStatefulWidget {
  const RollingPlanScreen({super.key});

  @override
  ConsumerState<RollingPlanScreen> createState() => _RollingPlanScreenState();
}

class _RollingPlanScreenState extends ConsumerState<RollingPlanScreen> {
  int _capacity = 180;
  RollingPlanProposal? _proposal;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(planningItemsProvider(null));
    final history = ref.watch(planningHistoryProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('Next 15-day proposal')),
      body: SafeArea(
        child: items.when(
          loading: () => const LoadingStateView(),
          error: (_, _) => const ErrorStateView(
            message: 'Your local plan history could not be loaded.',
          ),
          data: (allItems) => history.when(
            loading: () => const LoadingStateView(),
            error: (_, _) => const ErrorStateView(
              message: 'Your local completion history could not be loaded.',
            ),
            data: (entries) => _content(allItems, entries),
          ),
        ),
      ),
    );
  }

  Widget _content(
    List<PlanningItem> items,
    List<PlanningHistoryEntry> history,
  ) {
    final eligible = items.any(
      (item) =>
          item.kind == PlanningKind.task &&
          item.importId != null &&
          !item.archived,
    );
    if (!eligible) {
      return const EmptyStateView(
        title: 'No previous imported plan',
        message:
            'Import a 15-day plan first. A rolling proposal will use its incomplete tasks.',
        icon: Icons.event_repeat_outlined,
      );
    }
    _proposal ??= _generate(items, history);
    final proposal = _proposal!;
    final dayLoads = <int, int>{};
    for (final task in proposal.drafts) {
      dayLoads.update(
        task.dayOffset,
        (minutes) => minutes + task.durationMinutes,
        ifAbsent: () => task.durationMinutes,
      );
    }
    final sortedLoads = dayLoads.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('This is a draft. Nothing changes until you approve it.'),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previous cycle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${proposal.completedCount} of ${proposal.previousTasks.length} imported tasks completed',
              ),
              Text(
                '${proposal.drafts.length} incomplete tasks proposed for carryover',
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                key: const Key('rolling_capacity'),
                initialValue: _capacity,
                decoration: const InputDecoration(
                  labelText: 'Daily available minutes',
                ),
                items: const [60, 120, 180, 240, 360, 480]
                    .map(
                      (v) =>
                          DropdownMenuItem(value: v, child: Text('$v min/day')),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                        _capacity = value ?? 180;
                        _proposal = _generate(items, history);
                      }),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final entry in sortedLoads)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ProgressIndicatorCard(
              label: 'Day ${entry.key} workload',
              value: entry.value.toDouble(),
              total: proposal.capacityMinutes.toDouble(),
              trailing: '${entry.value} / ${proposal.capacityMinutes} min',
              isOverCapacity: entry.value > proposal.capacityMinutes,
            ),
          ),
        if (sortedLoads.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        for (final warning in proposal.warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: MaterialBanner(
              content: Text(warning),
              actions: [const SizedBox.shrink()],
            ),
          ),
        if (proposal.drafts.isEmpty)
          const EmptyStateView(
            title: 'Nothing to carry forward',
            message: 'All prior imported tasks are complete.',
            icon: Icons.task_alt,
          ),
        for (final task in proposal.drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${task.dayOffset} · ${task.date} · ${task.durationMinutes} min',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${task.category} · Priority ${task.priority} · ${task.sourceReference}',
                  ),
                  if (task.description.isNotEmpty) Text(task.description),
                  TextButton(
                    onPressed: _saving ? null : () => _editTask(task),
                    child: const Text('Edit title'),
                  ),
                ],
              ),
            ),
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: const Key('rolling_regenerate'),
          onPressed: _saving
              ? null
              : () => setState(() => _proposal = _generate(items, history)),
          icon: const Icon(Icons.refresh),
          label: const Text('Regenerate proposal'),
        ),
        FilledButton.icon(
          key: const Key('rolling_approve'),
          onPressed: _saving || proposal.drafts.isEmpty
              ? null
              : () => _approve(proposal),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Approve and add as new tasks'),
        ),
      ],
    );
  }

  RollingPlanProposal _generate(
    List<PlanningItem> items,
    List<PlanningHistoryEntry> history,
  ) => buildRollingPlanProposal(
    items: items,
    history: history,
    startDate: DateTime.now().add(const Duration(days: 1)),
    dailyCapacityMinutes: _capacity,
  );

  Future<void> _editTask(TaskPlanDraft task) async {
    final controller = TextEditingController(text: task.title);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit proposed task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Task title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted || _proposal == null) return;
    setState(
      () => _proposal = RollingPlanProposal(
        startDate: _proposal!.startDate,
        previousTasks: _proposal!.previousTasks,
        completedCount: _proposal!.completedCount,
        drafts: _proposal!.drafts
            .map(
              (item) => item.id == task.id ? item.copyWith(title: value) : item,
            )
            .toList(growable: false),
        capacityMinutes: _proposal!.capacityMinutes,
        warnings: _proposal!.warnings,
        fingerprint: _proposal!.fingerprint,
      ),
    );
  }

  Future<void> _approve(RollingPlanProposal proposal) async {
    final overloads = <int, int>{};
    for (final task in proposal.drafts) {
      overloads.update(
        task.dayOffset,
        (minutes) => minutes + task.durationMinutes,
        ifAbsent: () => task.durationMinutes,
      );
    }
    final overloadedDays = overloads.entries
        .where((entry) => entry.value > proposal.capacityMinutes)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (overloadedDays.isNotEmpty) {
      var acknowledged = false;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Review overloaded days'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All ${proposal.drafts.length} carryover tasks will be kept. Days ${overloadedDays.join(', ')} exceed ${proposal.capacityMinutes} minutes. Reassign or change capacity, or acknowledge the overload to continue.',
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: acknowledged,
                  onChanged: (value) =>
                      setDialogState(() => acknowledged = value ?? false),
                  title: const Text('I reviewed and accept these overloads.'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Review again'),
              ),
              FilledButton(
                onPressed: acknowledged
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Approve carryover'),
              ),
            ],
          ),
        ),
      );
      if (accepted != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(planningRepositoryProvider)
          .importPlan(
            sourceFingerprint: proposal.fingerprint,
            startDate: proposal.startDate,
            tasks: proposal.drafts,
          );
      ref.invalidate(planningItemsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'New tasks added. Earlier tasks and history were preserved.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
