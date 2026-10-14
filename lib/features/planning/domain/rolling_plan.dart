import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'planning_repository.dart';
import 'task_plan_import.dart';

/// Builds an approval-only proposal from unfinished tasks in prior imported
/// plans. It never mutates definitions or completion history.
RollingPlanProposal buildRollingPlanProposal({
  required List<PlanningItem> items,
  required List<PlanningHistoryEntry> history,
  required DateTime startDate,
  required int dailyCapacityMinutes,
}) {
  if (dailyCapacityMinutes < 30 || dailyCapacityMinutes > 1440) {
    throw ArgumentError.value(dailyCapacityMinutes, 'dailyCapacityMinutes');
  }
  final prior =
      items
          .where(
            (item) =>
                item.kind == PlanningKind.task &&
                item.importId != null &&
                !item.archived &&
                item.scheduledDate != null &&
                item.scheduledDate!.compareTo(_date(startDate)) < 0,
          )
          .toList()
        ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));
  final completionByTask = <String, List<CompletionStatus>>{};
  for (final entry in history) {
    if (entry.kind != 'taskCompletion') continue;
    try {
      final status = CompletionStatus.values.byName(
        (jsonDecode(entry.payload) as Map<String, dynamic>)['status'] as String,
      );
      completionByTask.putIfAbsent(entry.definitionId, () => []).add(status);
    } on Object {
      // Malformed history is not treated as evidence of completion.
    }
  }
  final carried = prior.where((item) {
    final statuses = completionByTask[item.id] ?? const <CompletionStatus>[];
    return !statuses.contains(CompletionStatus.done);
  }).toList();
  if (carried.isEmpty) {
    return RollingPlanProposal(
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      previousTasks: prior,
      completedCount: prior
          .where(
            (i) => (completionByTask[i.id] ?? const []).contains(
              CompletionStatus.done,
            ),
          )
          .length,
      drafts: const [],
      capacityMinutes: dailyCapacityMinutes,
      warnings: const [
        'No incomplete tasks were found in earlier imported plans.',
      ],
      fingerprint: _fingerprint(startDate),
    );
  }

  final loads = List<int>.filled(15, 0);
  final drafts = <TaskPlanDraft>[];
  final sorted = carried
    ..sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      return byPriority != 0
          ? byPriority
          : a.scheduledDate!.compareTo(b.scheduledDate!);
    });
  for (var index = 0; index < sorted.length; index++) {
    final task = sorted[index];
    final eligible = List<int>.generate(15, (i) => i)
      ..sort((a, b) => loads[a].compareTo(loads[b]));
    final day = eligible.first;
    loads[day] += task.durationMinutes;
    drafts.add(
      TaskPlanDraft(
        id: 'carry-${task.id}',
        dayOffset: day + 1,
        date: _date(startDate.add(Duration(days: day))),
        title: task.title,
        description: task.description,
        category: task.category.isEmpty ? 'Carryover' : task.category,
        priority: task.priority,
        durationMinutes: task.durationMinutes,
        completionCriteria: task.completionCriteria,
        dependencies: const [],
        sourceReference: 'Carryover from ${task.scheduledDate}',
        suggested: true,
        visibility: task.visibility,
        scheduledMinute: task.scheduledMinute,
      ),
    );
  }
  final warnings = <String>[];
  if (loads.any((minutes) => minutes > dailyCapacityMinutes)) {
    warnings.add(
      'Some days exceed the selected daily capacity. Review before approval.',
    );
  }
  if (sorted.length > 15) {
    warnings.add('More than one carryover may be scheduled on some days.');
  }
  return RollingPlanProposal(
    startDate: DateTime(startDate.year, startDate.month, startDate.day),
    previousTasks: prior,
    completedCount: prior
        .where(
          (i) => (completionByTask[i.id] ?? const []).contains(
            CompletionStatus.done,
          ),
        )
        .length,
    drafts: List.unmodifiable(drafts),
    capacityMinutes: dailyCapacityMinutes,
    warnings: List.unmodifiable(warnings),
    fingerprint: _fingerprint(startDate),
  );
}

class RollingPlanProposal {
  const RollingPlanProposal({
    required this.startDate,
    required this.previousTasks,
    required this.completedCount,
    required this.drafts,
    required this.capacityMinutes,
    required this.warnings,
    required this.fingerprint,
  });

  final DateTime startDate;
  final List<PlanningItem> previousTasks;
  final int completedCount;
  final List<TaskPlanDraft> drafts;
  final int capacityMinutes;
  final List<String> warnings;
  final String fingerprint;
}

String _fingerprint(DateTime date) {
  // One receipt per authenticated user's cycle prevents re-import after
  // changing capacity or the source set.
  return sha256.convert(utf8.encode('rolling-v1|${_date(date)}')).toString();
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
