import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/planning/domain/planning_repository.dart';
import 'package:life_os/features/records/data/drift_life_record_store.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';

void main() {
  late LifeDatabase database;
  late _Identity identity;
  late PlanningRepository repository;

  setUp(() {
    database = LifeDatabase.forTesting(NativeDatabase.memory());
    identity = _Identity('uid-a');
    repository = PlanningRepository(
      OfflineLifeRecordRepository(DriftLifeRecordStore(database), identity),
      DriftPlanningHistoryStore(database),
      identity,
    );
  });
  tearDown(() async {
    await identity.dispose();
    await database.close();
  });

  test('validates required fields, dates, recurrence and duration', () async {
    await expectLater(
      repository.save(
        kind: PlanningKind.task,
        title: '  ',
        scheduledDate: '2026-02-30',
      ),
      throwsA(isA<PlanningValidationFailure>()),
    );
    await expectLater(
      repository.save(
        kind: PlanningKind.task,
        title: 'Task',
        scheduledDate: '2026-02-30',
      ),
      throwsA(isA<PlanningValidationFailure>()),
    );
    await expectLater(
      repository.save(
        kind: PlanningKind.task,
        title: 'Task',
        scheduledDate: '2026-10-14',
        durationMinutes: 1441,
      ),
      throwsA(isA<PlanningValidationFailure>()),
    );
    await expectLater(
      repository.save(
        kind: PlanningKind.routine,
        title: 'Routine',
        recurrence: 'monthly',
      ),
      throwsA(isA<PlanningValidationFailure>()),
    );
  });

  test(
    'edits preserve earlier completion snapshots and task results',
    () async {
      final task = await repository.save(
        kind: PlanningKind.task,
        title: 'Read',
        scheduledDate: _today(),
      );
      await repository.complete(
        task,
        DateTime.now(),
        CompletionStatus.partial,
        notes: 'One chapter',
      );
      await repository.save(
        kind: PlanningKind.task,
        id: task.id,
        title: 'Read more',
        scheduledDate: _today(),
      );
      final history = await repository
          .watchHistory(definitionId: task.id)
          .first;
      expect(history, hasLength(1));
      expect(history.single.payload, contains('One chapter'));
      expect(history.single.payload, contains('"title":"Read"'));
    },
  );

  test(
    'stores Done, Partial and Not Done as separate completion results',
    () async {
      final routine = await repository.save(
        kind: PlanningKind.routine,
        title: 'Study',
        recurrence: 'daily',
      );
      await repository.complete(
        routine,
        DateTime(2026, 10, 14),
        CompletionStatus.done,
      );
      await repository.complete(
        routine,
        DateTime(2026, 10, 15),
        CompletionStatus.partial,
        notes: 'Short session',
      );
      await repository.complete(
        routine,
        DateTime(2026, 10, 16),
        CompletionStatus.notDone,
      );
      final history = await repository
          .watchHistory(definitionId: routine.id)
          .first;
      expect(history, hasLength(3));
      expect(
        history.map((e) => e.payload),
        contains(contains('"status":"done"')),
      );
      expect(
        history.map((e) => e.payload),
        contains(contains('"status":"partial"')),
      );
      expect(
        history.map((e) => e.payload),
        contains(contains('"status":"notDone"')),
      );
      expect(
        history.map((e) => e.payload),
        contains(contains('Short session')),
      );
    },
  );

  test(
    'weekly routines recur on selected weekday and keep schedule data',
    () async {
      final routine = await repository.save(
        kind: PlanningKind.routine,
        title: 'Walk',
        recurrence: 'weekly',
        weekdays: [DateTime.wednesday],
      );
      expect(routine.occursOn(DateTime(2026, 10, 14)), isTrue);
      expect(routine.occursOn(DateTime(2026, 10, 15)), isFalse);
      expect(routine.occursOn(DateTime(2026, 10, 21)), isTrue);
    },
  );

  test(
    'one-time, daily and weekday recurrence keep dates predictable',
    () async {
      final once = await repository.save(
        kind: PlanningKind.task,
        title: 'Appointment',
        scheduledDate: '2026-10-14',
      );
      final daily = await repository.save(
        kind: PlanningKind.routine,
        title: 'Daily review',
        recurrence: 'daily',
      );
      final weekdays = await repository.save(
        kind: PlanningKind.routine,
        title: 'Work block',
        recurrence: 'weekdays',
      );

      expect(once.occursOn(DateTime(2026, 10, 14)), isTrue);
      expect(once.occursOn(DateTime(2026, 10, 15)), isFalse);
      expect(daily.occursOn(DateTime(2026, 10, 17)), isTrue);
      expect(weekdays.occursOn(DateTime(2026, 10, 16)), isTrue);
      expect(weekdays.occursOn(DateTime(2026, 10, 17)), isFalse);
    },
  );

  test(
    'habit check-ins are unique per user, definition and local date',
    () async {
      final habit = await repository.save(
        kind: PlanningKind.habit,
        title: 'Stretch',
        recurrence: 'daily',
      );
      final day = DateTime(2026, 10, 14);
      await repository.complete(habit, day, CompletionStatus.done);
      await expectLater(
        repository.complete(habit, day, CompletionStatus.done),
        throwsA(isA<Object>()),
      );
      expect(
        await repository.watchHistory(definitionId: habit.id).first,
        hasLength(1),
      );
    },
  );

  test('goal progress appends measurements instead of overwriting', () async {
    final goal = await repository.save(
      kind: PlanningKind.goal,
      title: 'Read books',
      targetDate: '2026-12-31',
      targetValue: 12,
      targetUnit: 'books',
    );
    await repository.addGoalProgress(goal, DateTime(2026, 10, 14), 1);
    await repository.addGoalProgress(
      goal,
      DateTime(2026, 10, 20),
      2,
      notes: 'Finished second',
    );
    final entries = await repository.watchHistory(definitionId: goal.id).first;
    expect(entries, hasLength(2));
    expect(
      entries.map((e) => e.localDate),
      containsAll(['2026-10-14', '2026-10-20']),
    );
  });

  test('history store rejects malformed local events', () async {
    await expectLater(
      DriftPlanningHistoryStore(database).add(
        ActivityHistoryCompanion.insert(
          id: 'bad-history',
          ownerUid: 'uid-a',
          definitionId: 'missing',
          kind: 'unknown',
          occurrenceKey: 'occurrence',
          localDate: '2026-02-30',
          visibility: 'private',
          payloadJson: '{bad',
          recordedAtUtcMs: 1,
        ),
      ),
      throwsA(isA<PlanningValidationFailure>()),
    );
  });

  test(
    'account switching scopes definitions and history to active UID',
    () async {
      final first = await repository.save(
        kind: PlanningKind.habit,
        title: 'Private A',
        recurrence: 'daily',
      );
      await repository.complete(first, DateTime.now(), CompletionStatus.done);
      identity.switchTo('uid-b');
      final second = await repository.save(
        kind: PlanningKind.habit,
        title: 'Private B',
        recurrence: 'daily',
      );
      final records = await repository.watchItems().first;
      expect(records.map((r) => r.title), ['Private B']);
      expect(await repository.watchHistory().first, isEmpty);
      expect(
        () => repository.complete(first, DateTime.now(), CompletionStatus.done),
        throwsA(isA<OwnershipViolation>()),
      );
      expect(second.ownerUid, 'uid-b');
    },
  );

  test(
    'shared records can be viewed and logged without changing owner',
    () async {
      final shared = await repository.save(
        kind: PlanningKind.routine,
        title: 'Shared walk',
        recurrence: 'daily',
        visibility: RecordVisibility.shared,
      );
      identity.switchTo('uid-b');
      final viewed = (await repository.watchItems().first).single;
      await repository.complete(viewed, DateTime.now(), CompletionStatus.done);
      final entries = await repository
          .watchHistory(definitionId: shared.id)
          .first;
      expect(entries, hasLength(1));
      expect(viewed.ownerUid, 'uid-a');
    },
  );

  test(
    'making a shared definition private hides its history from the other user',
    () async {
      final shared = await repository.save(
        kind: PlanningKind.routine,
        title: 'Shared walk',
        recurrence: 'daily',
        visibility: RecordVisibility.shared,
      );
      identity.switchTo('uid-b');
      await repository.complete(shared, DateTime.now(), CompletionStatus.done);
      identity.switchTo('uid-a');
      await repository.save(
        kind: PlanningKind.routine,
        id: shared.id,
        title: shared.title,
        recurrence: shared.recurrence,
        visibility: RecordVisibility.private,
      );
      identity.switchTo('uid-b');
      expect(
        await repository.watchHistory(definitionId: shared.id).first,
        isEmpty,
      );
    },
  );

  test(
    'archiving a shared definition hides its history from other users',
    () async {
      final shared = await repository.save(
        kind: PlanningKind.habit,
        title: 'Shared stretch',
        recurrence: 'daily',
        visibility: RecordVisibility.shared,
      );
      identity.switchTo('uid-b');
      await repository.complete(shared, DateTime.now(), CompletionStatus.done);
      identity.switchTo('uid-a');
      await repository.save(
        kind: PlanningKind.habit,
        id: shared.id,
        title: shared.title,
        recurrence: shared.recurrence,
        visibility: RecordVisibility.shared,
        archived: true,
      );
      identity.switchTo('uid-b');
      expect(
        await repository.watchHistory(definitionId: shared.id).first,
        isEmpty,
      );
    },
  );
}

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class _Identity implements CurrentUserIdentity {
  _Identity(this.currentUid);
  @override
  String? currentUid;
  final _changes = StreamController<String?>.broadcast();
  void switchTo(String uid) {
    currentUid = uid;
    _changes.add(uid);
  }

  @override
  Stream<String?> get uidChanges => Stream.value(currentUid);
  Future<void> dispose() => _changes.close();
}
