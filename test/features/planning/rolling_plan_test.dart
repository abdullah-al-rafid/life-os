import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/planning/domain/planning_repository.dart';
import 'package:life_os/features/planning/domain/rolling_plan.dart';
import 'package:life_os/features/records/domain/life_record.dart';

void main() {
  final now = DateTime.utc(2026, 10, 14);
  PlanningItem task(
    String id, {
    int priority = 2,
    String? importId = 'old-import',
    String date = '2026-10-10',
  }) => PlanningItem(
    id: id,
    ownerUid: 'uid-a',
    kind: PlanningKind.task,
    visibility: RecordVisibility.private,
    title: 'Task $id',
    description: 'Description',
    category: 'Learning',
    priority: priority,
    scheduledDate: date,
    scheduledMinute: 600,
    durationMinutes: 60,
    recurrence: 'once',
    weekdays: const [],
    targetDate: null,
    targetValue: null,
    targetUnit: '',
    archived: false,
    createdAtUtc: now,
    updatedAtUtc: now,
    revision: 1,
    completionCriteria: 'Finish it',
    dependencies: const [],
    sourceReference: '',
    importId: importId,
  );

  test('proposal carries only tasks without a completed snapshot', () {
    final items = [task('done'), task('partial', priority: 1)];
    final history = [
      PlanningHistoryEntry(
        id: 'history-done',
        definitionId: 'done',
        kind: 'taskCompletion',
        localDate: '2026-10-10',
        payload: jsonEncode({'status': 'done'}),
        recordedAtUtc: now,
      ),
      PlanningHistoryEntry(
        id: 'history-partial',
        definitionId: 'partial',
        kind: 'taskCompletion',
        localDate: '2026-10-10',
        payload: jsonEncode({'status': 'partial'}),
        recordedAtUtc: now,
      ),
    ];
    final result = buildRollingPlanProposal(
      items: items,
      history: history,
      startDate: DateTime(2026, 10, 15),
      dailyCapacityMinutes: 180,
    );
    expect(result.completedCount, 1);
    expect(result.drafts, hasLength(1));
    expect(result.drafts.single.title, 'Task partial');
    expect(result.drafts.single.date, '2026-10-15');
    expect(result.drafts.single.sourceReference, contains('2026-10-10'));
    expect(result.fingerprint, hasLength(64));
  });

  test('repeated generation is stable and never edits prior task objects', () {
    final original = task('same');
    RollingPlanProposal generate() => buildRollingPlanProposal(
      items: [original],
      history: const [],
      startDate: DateTime(2026, 10, 15),
      dailyCapacityMinutes: 180,
    );
    final first = generate();
    final second = generate();
    expect(first.fingerprint, second.fingerprint);
    expect(first.drafts.single.id, second.drafts.single.id);
    expect(original.scheduledDate, '2026-10-10');
  });

  test('non-imported and current/future tasks are not carried over', () {
    final items = [
      task('regular', importId: null),
      task('current', date: '2026-10-20'),
    ];
    final result = buildRollingPlanProposal(
      items: items,
      history: const [],
      startDate: DateTime(2026, 10, 15),
      dailyCapacityMinutes: 180,
    );
    expect(result.drafts, isEmpty);
  });

  test('capacity is validated', () {
    expect(
      () => buildRollingPlanProposal(
        items: const [],
        history: const [],
        startDate: DateTime(2026, 10, 15),
        dailyCapacityMinutes: 0,
      ),
      throwsArgumentError,
    );
  });
}
