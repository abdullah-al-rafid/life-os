import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/domain/life_record.dart';
import '../../records/presentation/record_providers.dart';
import '../domain/planning_repository.dart';
import '../domain/task_plan_import.dart';

class TaskPlanImportScreen extends ConsumerStatefulWidget {
  const TaskPlanImportScreen({super.key});

  @override
  ConsumerState<TaskPlanImportScreen> createState() =>
      _TaskPlanImportScreenState();
}

class _TaskPlanImportScreenState extends ConsumerState<TaskPlanImportScreen> {
  String? _fileName;
  Uint8List? _bytes;
  TaskPlanProposal? _proposal;
  String? _error;
  bool _busy = false;
  late final TextEditingController _start = TextEditingController(
    text: _dateKey(DateTime.now()),
  );
  final TextEditingController _capacity = TextEditingController(text: '120');

  @override
  void dispose() {
    _start.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('15-day task planner'),
      leading: IconButton(
        tooltip: 'Back to Plan',
        onPressed: () => context.go('/plan'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Upload → review → approve',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Files are read on this device. The complete 15-day preview stays local until you approve importing it. LIFE OS does not send source files to an AI service.',
              ),
              const SizedBox(height: AppSpacing.md),
              const _LocalOnlyImportNote(),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                key: const Key('select_plan_file'),
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_fileName ?? 'Choose XLSX, CSV, TXT, PDF, or DOCX'),
              ),
              if (_bytes != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('plan_start_date'),
                        controller: _start,
                        decoration: const InputDecoration(
                          labelText: 'Day 1 date (YYYY-MM-DD)',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        key: const Key('plan_daily_capacity'),
                        controller: _capacity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutes available per day',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  key: const Key('generate_plan_preview'),
                  onPressed: _busy ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    _proposal == null
                        ? 'Generate 15-day preview'
                        : 'Regenerate from source',
                  ),
                ),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.md),
                _InlineMessage(error: error, isError: true),
              ],
              if (_proposal case final proposal?) ...[
                const SizedBox(height: AppSpacing.lg),
                _ProposalHeader(proposal: proposal),
                if (proposal.warnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  for (final warning in proposal.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _InlineMessage(error: warning, isError: false),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                for (var day = 1; day <= 15; day++)
                  _PlanDayEditor(
                    day: day,
                    date: proposal.dates[day - 1],
                    tasks: proposal.tasks
                        .where((task) => task.dayOffset == day)
                        .toList(),
                    allTasks: proposal.tasks,
                    onChanged: (changed) => _replaceTask(proposal, changed),
                    onRemove: (task) => _removeTask(proposal, task),
                    onAdd: () => _addTask(proposal, day),
                  ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: const Key('approve_import_plan'),
                  onPressed: _busy || proposal.tasks.isEmpty
                      ? null
                      : _confirmImport,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Approve & import all ${proposal.tasks.length} tasks',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Import creates new, private by default tasks. Existing tasks and completion history are preserved.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _proposal = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'csv', 'txt', 'pdf', 'docx'],
        allowMultiple: false,
        withData: false,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      if (file.size > taskPlanMaxFileBytes) {
        setState(() => _error = 'Files must be 10 MB or smaller.');
        return;
      }
      final bytes = await file.xFile.readAsBytes();
      if (bytes.isEmpty) {
        setState(
          () => _error = 'The selected file is empty or could not be read.',
        );
        return;
      }
      setState(() {
        _fileName = file.name;
        _bytes = bytes;
        _busy = true;
      });
      try {
        final proposal = await _createProposal(file.name, bytes);
        if (mounted) {
          _start.text = _dateKey(proposal.startDate);
          _capacity.text = '${proposal.dailyCapacityMinutes}';
          setState(() => _proposal = proposal);
        }
      } on TaskPlanImportFailure catch (error) {
        if (mounted) setState(() => _error = error.message);
      } on Object {
        if (mounted) {
          setState(() => _error = 'Could not extract this file on the device.');
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Could not open the file picker. Try choosing a local file again.',
        );
      }
    }
  }

  Future<void> _generate() async {
    final start = _parseDate(_start.text);
    final capacity = int.tryParse(_capacity.text.trim());
    if (start == null) {
      setState(() => _error = 'Enter a valid Day 1 date in YYYY-MM-DD format.');
      return;
    }
    if (capacity == null || capacity < 1 || capacity > 1440) {
      setState(() => _error = 'Daily available time must be 1–1440 minutes.');
      return;
    }
    final bytes = _bytes;
    final fileName = _fileName;
    if (bytes == null || fileName == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final proposal = await _createProposal(
        fileName,
        bytes,
        startDate: start,
        capacity: capacity,
      );
      if (mounted) setState(() => _proposal = proposal);
    } on TaskPlanImportFailure catch (error) {
      if (mounted) {
        setState(() {
          _proposal = null;
          _error = error.message;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _proposal = null;
          _error =
              'Could not generate a plan from this file. Review the file and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<TaskPlanProposal> _createProposal(
    String fileName,
    Uint8List bytes, {
    DateTime? startDate,
    int? capacity,
  }) async {
    final existing = await ref
        .read(planningRepositoryProvider)
        .watchItems()
        .first;
    final commitments = existing
        .where((item) => item.kind != PlanningKind.goal)
        .map(
          (item) => TaskPlanCommitment(
            recurrence: item.recurrence,
            scheduledDate: item.scheduledDate,
            durationMinutes: item.durationMinutes,
            weekdays: item.weekdays,
          ),
        )
        .toList(growable: false);
    return ref
        .read(taskPlanImporterProvider)
        .parse(
          fileName: fileName,
          bytes: bytes,
          startDate: startDate,
          dailyCapacityMinutes: capacity,
          existingCommitments: commitments,
        );
  }

  void _replaceTask(TaskPlanProposal proposal, TaskPlanDraft changed) {
    setState(
      () => _proposal = TaskPlanProposal(
        fileName: proposal.fileName,
        fingerprint: proposal.fingerprint,
        startDate: proposal.startDate,
        dailyCapacityMinutes: proposal.dailyCapacityMinutes,
        format: proposal.format,
        warnings: proposal.warnings,
        tasks: proposal.tasks
            .map((task) => task.id == changed.id ? changed : task)
            .toList(growable: false),
      ),
    );
  }

  void _removeTask(TaskPlanProposal proposal, TaskPlanDraft task) {
    setState(
      () => _proposal = TaskPlanProposal(
        fileName: proposal.fileName,
        fingerprint: proposal.fingerprint,
        startDate: proposal.startDate,
        dailyCapacityMinutes: proposal.dailyCapacityMinutes,
        format: proposal.format,
        warnings: proposal.warnings,
        tasks: proposal.tasks
            .where((item) => item.id != task.id)
            .toList(growable: false),
      ),
    );
  }

  void _addTask(TaskPlanProposal proposal, int day) {
    final id = 'edit:${DateTime.now().microsecondsSinceEpoch}';
    final task = TaskPlanDraft(
      id: id,
      dayOffset: day,
      date: proposal.dates[day - 1],
      title: '',
      description: '',
      category: 'Other',
      priority: 2,
      durationMinutes: 30,
      completionCriteria: '',
      dependencies: const [],
      sourceReference: 'User added',
      suggested: false,
      visibility: RecordVisibility.private,
    );
    setState(
      () => _proposal = TaskPlanProposal(
        fileName: proposal.fileName,
        fingerprint: proposal.fingerprint,
        startDate: proposal.startDate,
        dailyCapacityMinutes: proposal.dailyCapacityMinutes,
        format: proposal.format,
        warnings: proposal.warnings,
        tasks: [...proposal.tasks, task],
      ),
    );
  }

  Future<void> _confirmImport() async {
    final proposal = _proposal;
    if (proposal == null) return;
    final invalid = proposal.tasks.indexWhere(
      (task) =>
          task.title.trim().isEmpty ||
          task.category.trim().isEmpty ||
          task.durationMinutes < 1 ||
          task.durationMinutes > 1440 ||
          task.dayOffset < 1 ||
          task.dayOffset > 15 ||
          task.priority < 1 ||
          task.priority > 3,
    );
    if (invalid >= 0) {
      setState(
        () => _error =
            'Complete a title, category, priority, day, and 1–1440 minute estimate for every task before importing.',
      );
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import this 15-day plan?'),
        content: Text(
          'This will create ${proposal.tasks.length} new local tasks beginning ${_dateKey(proposal.startDate)}. Existing tasks and historical completion records will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve import'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(planningRepositoryProvider)
          .importPlan(
            sourceFingerprint: proposal.fingerprint,
            startDate: proposal.startDate,
            tasks: proposal.tasks,
          );
      ref.invalidate(planningItemsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The 15-day plan was imported to your local tasks.'),
          ),
        );
        context.go('/plan');
      }
    } on DuplicateTaskPlanImport {
      if (mounted) {
        setState(
          () => _error =
              'This file was already imported for this start date. Choose another start date or review the existing tasks.',
        );
      }
    } on PlanningValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'The plan was not imported. No partial task schedule was saved. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ProposalHeader extends StatelessWidget {
  const _ProposalHeader({required this.proposal});
  final TaskPlanProposal proposal;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete 15-day preview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${proposal.fileName} · ${proposal.format} · ${proposal.tasks.length} tasks · ${proposal.dailyCapacityMinutes} minutes/day',
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Edit, remove, or reassign tasks below. Empty days remain visible so the whole date range can be reviewed.',
        ),
      ],
    ),
  );
}

class _PlanDayEditor extends StatelessWidget {
  const _PlanDayEditor({
    required this.day,
    required this.date,
    required this.tasks,
    required this.allTasks,
    required this.onChanged,
    required this.onRemove,
    required this.onAdd,
  });
  final int day;
  final String date;
  final List<TaskPlanDraft> tasks;
  final List<TaskPlanDraft> allTasks;
  final ValueChanged<TaskPlanDraft> onChanged;
  final ValueChanged<TaskPlanDraft> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Day $day · $date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Add task to day $day',
                onPressed: onAdd,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No source tasks assigned to this day. Add a task or reassign one here.',
              ),
            ),
          for (final task in tasks)
            _TaskDraftEditor(
              key: ValueKey('draft_${task.id}'),
              task: task,
              allTasks: allTasks,
              onChanged: onChanged,
              onRemove: () => onRemove(task),
            ),
        ],
      ),
    ),
  );
}

class _TaskDraftEditor extends StatelessWidget {
  const _TaskDraftEditor({
    super.key,
    required this.task,
    required this.allTasks,
    required this.onChanged,
    required this.onRemove,
  });
  final TaskPlanDraft task;
  final List<TaskPlanDraft> allTasks;
  final ValueChanged<TaskPlanDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          children: [
            TextFormField(
              initialValue: task.title,
              decoration: const InputDecoration(labelText: 'Task title'),
              onChanged: (value) => onChanged(task.copyWith(title: value)),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: task.description,
              decoration: const InputDecoration(
                labelText: 'Description / outcome',
              ),
              maxLines: 2,
              onChanged: (value) =>
                  onChanged(task.copyWith(description: value)),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: task.completionCriteria,
              decoration: const InputDecoration(
                labelText: 'Measurable completion criterion (optional)',
              ),
              onChanged: (value) =>
                  onChanged(task.copyWith(completionCriteria: value)),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: task.dependencies
                  .map(
                    (id) =>
                        allTasks
                            .where((item) => item.id == id)
                            .firstOrNull
                            ?.title ??
                        id,
                  )
                  .join(', '),
              decoration: const InputDecoration(
                labelText:
                    'Prerequisite task titles (comma separated, optional)',
              ),
              maxLines: 2,
              onChanged: (value) {
                final titles = value
                    .split(',')
                    .map((item) => item.trim().toLowerCase())
                    .where((item) => item.isNotEmpty);
                final ids = titles
                    .map(
                      (title) =>
                          allTasks
                              .where(
                                (item) =>
                                    item.title.trim().toLowerCase() == title,
                              )
                              .firstOrNull
                              ?.id ??
                          'unresolved:$title',
                    )
                    .toList(growable: false);
                onChanged(task.copyWith(dependencies: ids));
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: task.category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    onChanged: (value) =>
                        onChanged(task.copyWith(category: value)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: '${task.durationMinutes}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minutes'),
                    onChanged: (value) => onChanged(
                      task.copyWith(durationMinutes: int.tryParse(value) ?? 0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue:
                  '${(task.scheduledMinute ~/ 60).toString().padLeft(2, '0')}:${(task.scheduledMinute % 60).toString().padLeft(2, '0')}',
              decoration: const InputDecoration(
                labelText: 'Preferred time (24-hour, HH:MM)',
              ),
              onChanged: (value) {
                final match = RegExp(
                  r'^(\d{1,2}):(\d{2})$',
                ).firstMatch(value.trim());
                if (match == null) return;
                final hour = int.parse(match[1]!);
                final minute = int.parse(match[2]!);
                if (hour < 24 && minute < 60) {
                  onChanged(task.copyWith(scheduledMinute: hour * 60 + minute));
                }
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: task.dayOffset,
                    decoration: const InputDecoration(labelText: 'Plan day'),
                    items: [
                      for (var day = 1; day <= 15; day++)
                        DropdownMenuItem(value: day, child: Text('Day $day')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(
                          task.copyWith(
                            dayOffset: value,
                            date: _dateKey(
                              DateTime.parse(
                                _startDateFromCurrentDate(
                                  task.date,
                                  task.dayOffset,
                                ),
                              ).add(Duration(days: value - task.dayOffset)),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: task.priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('High')),
                      DropdownMenuItem(value: 2, child: Text('Normal')),
                      DropdownMenuItem(value: 3, child: Text('Low')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(task.copyWith(priority: value));
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Remove task',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (task.dependencies.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Depends on: ${task.dependencies.map((id) => allTasks.where((item) => item.id == id).firstOrNull?.title ?? id).join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Source: ${task.sourceReference}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share with the other account'),
              value: task.visibility == RecordVisibility.shared,
              onChanged: (shared) => onChanged(
                task.copyWith(
                  visibility: shared
                      ? RecordVisibility.shared
                      : RecordVisibility.private,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.error, required this.isError});
  final String error;
  final bool isError;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: isError
          ? Colors.red.withValues(alpha: .12)
          : AppColors.purple.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isError ? Icons.error_outline : Icons.info_outline, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(error)),
      ],
    ),
  );
}

class _LocalOnlyImportNote extends StatelessWidget {
  const _LocalOnlyImportNote();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.cloud_off_outlined, size: 18),
      SizedBox(width: AppSpacing.xs),
      Expanded(child: Text('Local-only · no upload or cloud sync')),
    ],
  );
}

String _startDateFromCurrentDate(String date, int dayOffset) =>
    _dateKey(DateTime.parse(date).subtract(Duration(days: dayOffset - 1)));
DateTime? _parseDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final date = DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  if (date.year != int.parse(match[1]!) ||
      date.month != int.parse(match[2]!) ||
      date.day != int.parse(match[3]!)) {
    return null;
  }
  return date;
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
