import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/domain/life_record.dart';
import '../../records/presentation/record_providers.dart';
import '../domain/planning_repository.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({required this.kind, super.key});
  final PlanningKind? kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(planningItemsProvider(kind));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('planning_add'),
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(kind == PlanningKind.goal ? 'New goal' : 'New item'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(child: _Header(kind: kind)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(child: const _LocalOnlyBadge()),
                ),
                items.when(
                  loading: () =>
                      const SliverFillRemaining(child: LoadingStateView()),
                  error: (error, _) => SliverFillRemaining(
                    child: ErrorStateView(
                      message:
                          'Your local items could not be loaded. Check the app database and try again.',
                      onRetry: () =>
                          ref.invalidate(planningItemsProvider(kind)),
                    ),
                  ),
                  data: (values) {
                    final visible = kind == null
                        ? values
                              .where(
                                (i) =>
                                    i.kind != PlanningKind.goal &&
                                    i.occursOn(DateTime.now()),
                              )
                              .toList()
                        : values;
                    if (visible.isEmpty) {
                      return SliverFillRemaining(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: EmptyStateView(
                            icon: kind == PlanningKind.goal
                                ? Icons.flag_outlined
                                : Icons.event_note_outlined,
                            title: kind == PlanningKind.goal
                                ? 'No goals yet'
                                : 'A clear day to begin',
                            message: kind == PlanningKind.goal
                                ? 'Add a measurable goal and record progress over time.'
                                : 'Add a task, routine, or habit. Your records stay on this device.',
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => _ItemCard(
                          item: visible[index],
                          onEdit: () => _edit(context, ref, visible[index]),
                          onAction: (action) =>
                              _act(context, ref, visible[index], action),
                        ),
                      ),
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

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    PlanningItem? item,
  ]) async {
    var selectedKind = kind ?? item?.kind;
    if (selectedKind == null) {
      selectedKind = await showDialog<PlanningKind>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('What would you like to add?'),
          children: [
            for (final option in [
              PlanningKind.task,
              PlanningKind.routine,
              PlanningKind.habit,
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    option.name[0].toUpperCase() + option.name.substring(1),
                  ),
                ),
              ),
          ],
        ),
      );
      if (selectedKind == null || !context.mounted) return;
    }
    final chosen = await showDialog<_PlanningDraft>(
      context: context,
      builder: (_) => _PlanningForm(kind: selectedKind!, item: item),
    );
    if (chosen == null || !context.mounted) return;
    try {
      await ref
          .read(planningRepositoryProvider)
          .save(
            kind: chosen.kind,
            id: item?.id,
            title: chosen.title,
            description: chosen.description,
            category: chosen.category,
            priority: chosen.priority,
            scheduledDate: chosen.scheduledDate,
            scheduledMinute: chosen.scheduledMinute,
            durationMinutes: chosen.duration,
            recurrence: chosen.recurrence,
            targetDate: chosen.targetDate,
            weekdays: chosen.weekdays,
            targetValue: chosen.targetValue,
            targetUnit: chosen.targetUnit,
            visibility: chosen.visibility,
          );
    } on PlanningValidationFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this item. Check your connection to local storage and try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    PlanningItem item,
    String action,
  ) async {
    try {
      if (action == 'edit') return _edit(context, ref, item);
      if (action == 'archive') {
        await ref
            .read(planningRepositoryProvider)
            .save(
              kind: item.kind,
              id: item.id,
              title: item.title,
              description: item.description,
              category: item.category,
              priority: item.priority,
              scheduledDate: item.scheduledDate,
              scheduledMinute: item.scheduledMinute,
              durationMinutes: item.durationMinutes,
              recurrence: item.recurrence,
              weekdays: item.weekdays,
              targetDate: item.targetDate,
              targetValue: item.targetValue,
              targetUnit: item.targetUnit,
              visibility: item.visibility,
              archived: true,
            );
      } else if (action == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete this item?'),
            content: const Text(
              'The definition will be hidden. Existing completion and progress history remains on this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(planningRepositoryProvider).delete(item.id);
        }
      } else if (action == 'progress') {
        final value = await _numberDialog(
          context,
          'Record progress',
          'Measurement',
        );
        if (value != null) {
          await ref
              .read(planningRepositoryProvider)
              .addGoalProgress(item, DateTime.now(), value);
        }
      } else if (action == 'complete') {
        final result = await _completionDialog(context);
        if (result == null) return;
        await ref
            .read(planningRepositoryProvider)
            .complete(item, DateTime.now(), result.$1, notes: result.$2);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved locally.')));
        }
      }
    } catch (error) {
      if (!context.mounted) return;
      final message = error is PlanningValidationFailure
          ? error.message
          : error is RecordValidationFailure
          ? error.message
          : 'This action could not be saved locally.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class PlanningInsightsScreen extends ConsumerWidget {
  const PlanningInsightsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(planningHistoryProvider(null));
    final items = ref.watch(planningItemsProvider(null));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'LIFE OS / INSIGHTS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.cyan,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your consistency',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _LocalOnlyBadge(),
                const SizedBox(height: AppSpacing.lg),
                records.when(
                  loading: () => const LoadingStateView(),
                  error: (_, _) => const ErrorStateView(
                    message: 'Local progress history could not be loaded.',
                  ),
                  data: (entries) {
                    final sevenDaysAgo = DateTime.now().subtract(
                      const Duration(days: 6),
                    );
                    final recent = entries.where((e) {
                      final p = e.localDate.split('-').map(int.parse).toList();
                      return !DateTime(p[0], p[1], p[2]).isBefore(
                        DateTime(
                          sevenDaysAgo.year,
                          sevenDaysAgo.month,
                          sevenDaysAgo.day,
                        ),
                      );
                    }).toList();
                    final habitDates = <String>{
                      for (final e in recent.where(
                        (e) => e.kind == 'habitCompletion',
                      ))
                        '${e.definitionId}:${e.localDate}',
                    };
                    return SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last 7 days',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _MetricLine(
                            label: 'Saved activity records',
                            value: '${recent.length}',
                          ),
                          _MetricLine(
                            label: 'Habit days completed',
                            value: '${habitDates.length}',
                          ),
                          _MetricLine(
                            label: 'Goal measurements',
                            value:
                                '${recent.where((e) => e.kind == 'goalProgress').length}',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Habits', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                items.when(
                  data: (list) {
                    final habits = list
                        .where((i) => i.kind == PlanningKind.habit)
                        .toList();
                    return habits.isEmpty
                        ? const EmptyStateView(
                            title: 'No habit history yet',
                            message:
                                'Create a habit in Plan and check in on the days you complete it.',
                          )
                        : Column(
                            children: [
                              for (final habit in habits)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _HabitSummary(item: habit),
                                ),
                            ],
                          );
                  },
                  loading: () => const LoadingStateView(),
                  error: (_, _) => const ErrorStateView(
                    message: 'Habits could not be loaded.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _HabitSummary extends ConsumerWidget {
  const _HabitSummary({required this.item});
  final PlanningItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(planningHistoryProvider(item.id));
    return history.when(
      data: (entries) {
        final dates = entries
            .where((e) => e.kind == 'habitCompletion')
            .map((e) => e.localDate)
            .toSet();
        return SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${dates.length} day${dates.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) =>
          const ErrorStateView(message: 'Habit summary unavailable.'),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.kind});
  final PlanningKind? kind;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'LIFE OS / ${(kind?.name ?? 'PLAN').toUpperCase()}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.cyan,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        kind == PlanningKind.goal
            ? 'Goals'
            : kind == null
            ? 'Today’s plan'
            : '${kind!.name[0].toUpperCase()}${kind!.name.substring(1)}s',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        kind == PlanningKind.goal
            ? 'Set a measurable target and keep each progress entry.'
            : 'Tasks, recurring routines, and habits for today.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _LocalOnlyBadge extends StatelessWidget {
  const _LocalOnlyBadge();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: AppColors.purple, size: 17),
        const SizedBox(width: 7),
        Text(
          'Offline ready · Stored on this device · Cloud sync is off',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onAction,
  });
  final PlanningItem item;
  final VoidCallback onEdit;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history =
        ref.watch(planningHistoryProvider(item.id)).asData?.value ??
        const <PlanningHistoryEntry>[];
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onAction,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (!item.archived)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          if (item.description.isNotEmpty)
            Text(
              item.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(label: Text(item.kind.name)),
              if (item.category.isNotEmpty) Chip(label: Text(item.category)),
              if (item.durationMinutes > 0 && item.kind != PlanningKind.goal)
                Chip(label: Text('${item.durationMinutes} min')),
              if (item.recurrence != 'once') Chip(label: Text(item.recurrence)),
            ],
          ),
          if (item.kind == PlanningKind.goal) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Target ${item.targetValue} ${item.targetUnit} · ${history.length} recorded measurements',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Builder(
                builder: (context) {
                  final latest =
                      jsonDecode(history.first.payload) as Map<String, dynamic>;
                  final value = (latest['value'] as num).toDouble();
                  final target = item.targetValue ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest: $value ${item.targetUnit} / $target ${item.targetUnit}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: target <= 0 ? 0 : (value / target).clamp(0, 1),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => onAction('progress'),
              icon: const Icon(Icons.add_chart),
              label: const Text('Record progress'),
            ),
            ...history.take(3).map((entry) {
              final data = jsonDecode(entry.payload) as Map<String, dynamic>;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${data['value']} ${data['unit']}'),
                subtitle: Text(entry.localDate),
              );
            }),
          ] else ...[
            if (history.isNotEmpty)
              Text(
                '${history.length} completion record${history.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onAction('complete'),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  item.kind == PlanningKind.habit
                      ? 'Check in today'
                      : 'Record result',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanningDraft {
  const _PlanningDraft(
    this.kind,
    this.title,
    this.description,
    this.category,
    this.priority,
    this.scheduledDate,
    this.scheduledMinute,
    this.duration,
    this.recurrence,
    this.weekdays,
    this.targetDate,
    this.targetValue,
    this.targetUnit,
    this.visibility,
  );
  final PlanningKind kind;
  final String title, description, category, recurrence, targetUnit;
  final int priority, scheduledMinute, duration;
  final List<int> weekdays;
  final String? scheduledDate, targetDate;
  final double? targetValue;
  final RecordVisibility visibility;
}

class _PlanningForm extends StatefulWidget {
  const _PlanningForm({required this.kind, this.item});
  final PlanningKind kind;
  final PlanningItem? item;
  @override
  State<_PlanningForm> createState() => _PlanningFormState();
}

class _PlanningFormState extends State<_PlanningForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title);
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late final _category = TextEditingController(text: widget.item?.category);
  late final _target = TextEditingController(
    text: widget.item?.targetValue?.toString(),
  );
  late final _unit = TextEditingController(text: widget.item?.targetUnit);
  late String _date = widget.item?.scheduledDate ?? _todayKey();
  late String _targetDate = widget.item?.targetDate ?? _date;
  late int _minute = widget.item?.scheduledMinute ?? 540;
  late int _duration = widget.item?.durationMinutes ?? 30;
  late int _priority = widget.item?.priority ?? 2;
  late String _recurrence =
      widget.item?.recurrence ??
      (widget.kind == PlanningKind.task ? 'once' : 'daily');
  late int _weekday =
      widget.item?.weekdays.firstOrNull ?? DateTime.now().weekday;
  late RecordVisibility _visibility =
      widget.item?.visibility ?? RecordVisibility.private;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.item == null
          ? 'Create ${widget.kind.name}'
          : 'Edit ${widget.kind.name}',
    ),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('planning_title'),
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required.' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              if (widget.kind != PlanningKind.goal) ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('High')),
                    DropdownMenuItem(value: 2, child: Text('Normal')),
                    DropdownMenuItem(value: 3, child: Text('Low')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 2),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _recurrence,
                  decoration: const InputDecoration(labelText: 'Schedule'),
                  items: const [
                    DropdownMenuItem(value: 'once', child: Text('One time')),
                    DropdownMenuItem(value: 'daily', child: Text('Every day')),
                    DropdownMenuItem(
                      value: 'weekdays',
                      child: Text('Weekdays'),
                    ),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (v) => setState(() => _recurrence = v ?? 'once'),
                ),
                if (_recurrence == 'weekly')
                  DropdownButtonFormField<int>(
                    initialValue: _weekday,
                    decoration: const InputDecoration(labelText: 'Day of week'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Monday')),
                      DropdownMenuItem(value: 2, child: Text('Tuesday')),
                      DropdownMenuItem(value: 3, child: Text('Wednesday')),
                      DropdownMenuItem(value: 4, child: Text('Thursday')),
                      DropdownMenuItem(value: 5, child: Text('Friday')),
                      DropdownMenuItem(value: 6, child: Text('Saturday')),
                      DropdownMenuItem(value: 7, child: Text('Sunday')),
                    ],
                    onChanged: (v) => setState(() => _weekday = v ?? 1),
                  ),
                if (_recurrence == 'once')
                  TextFormField(
                    initialValue: _date,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                    ),
                    onChanged: (v) => _date = v,
                  ),
                TextFormField(
                  initialValue:
                      '${(_minute ~/ 60).toString().padLeft(2, '0')}:${(_minute % 60).toString().padLeft(2, '0')}',
                  decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
                  validator: (v) =>
                      v != null &&
                          RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v)
                      ? null
                      : 'Use 24-hour time, for example 09:30.',
                  onChanged: (v) {
                    final p = v.split(':');
                    if (p.length == 2 &&
                        int.tryParse(p[0]) != null &&
                        int.tryParse(p[1]) != null) {
                      _minute = int.parse(p[0]) * 60 + int.parse(p[1]);
                    }
                  },
                ),
                TextFormField(
                  initialValue: '$_duration',
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n != null && n > 0 && n <= 1440
                        ? null
                        : 'Enter 1–1440 minutes.';
                  },
                  onChanged: (v) => _duration = int.tryParse(v) ?? 0,
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _target,
                  decoration: const InputDecoration(
                    labelText: 'Measurable target',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n != null && n > 0
                        ? null
                        : 'Enter a positive target.';
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit (e.g. books, km, hours)',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'A target unit is required.'
                      : null,
                ),
                TextFormField(
                  initialValue: _targetDate,
                  decoration: const InputDecoration(
                    labelText: 'Target date (YYYY-MM-DD)',
                  ),
                  onChanged: (v) => _targetDate = v,
                ),
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share with the other account'),
                subtitle: const Text(
                  'Visible to the other signed-in account on this device.',
                ),
                value: _visibility == RecordVisibility.shared,
                onChanged: (value) => setState(
                  () => _visibility = value
                      ? RecordVisibility.shared
                      : RecordVisibility.private,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('planning_save'),
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            _PlanningDraft(
              widget.kind,
              _title.text.trim(),
              _description.text,
              _category.text,
              _priority,
              _date,
              _minute,
              _duration,
              _recurrence,
              _recurrence == 'weekly' ? [_weekday] : const [],
              _targetDate,
              double.tryParse(_target.text),
              _unit.text,
              _visibility,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

Future<(CompletionStatus, String)?> _completionDialog(
  BuildContext context,
) async {
  var status = CompletionStatus.done;
  final notes = TextEditingController();
  final result = await showDialog<(CompletionStatus, String)>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Record completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<CompletionStatus>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Result'),
              items: const [
                DropdownMenuItem(
                  value: CompletionStatus.done,
                  child: Text('Done'),
                ),
                DropdownMenuItem(
                  value: CompletionStatus.partial,
                  child: Text('Partial'),
                ),
                DropdownMenuItem(
                  value: CompletionStatus.notDone,
                  child: Text('Not Done'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => status = v ?? CompletionStatus.done),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: notes,
              decoration: const InputDecoration(
                labelText: 'Completion notes (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, (status, notes.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  notes.dispose();
  return result;
}

Future<double?> _numberDialog(
  BuildContext context,
  String title,
  String label,
) async {
  final controller = TextEditingController();
  final value = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = double.tryParse(controller.text);
            if (parsed != null && parsed.isFinite && parsed >= 0) {
              Navigator.pop(ctx, parsed);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}

String _todayKey() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
