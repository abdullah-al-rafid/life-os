import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/planning/domain/planning_repository.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/records/presentation/record_providers.dart';
import 'package:life_os/features/planning/presentation/shared_tasks_screen.dart';

void main() {
  testWidgets('remote sharing stays disabled without verified setup', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningItemsProvider(
            PlanningKind.goal,
          ).overrideWith((ref) => Stream.value(const [])),
          currentUserIdentityProvider.overrideWithValue(_Identity('uid-a')),
        ],
        child: const MaterialApp(home: SharedTasksScreen(togetherView: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remote task sharing is off'), findsOneWidget);
    expect(
      find.textContaining('trusted Firebase administrator'),
      findsOneWidget,
    );
    expect(find.text('Assign task'), findsNothing);
    expect(find.text('Shared goals & contributions'), findsOneWidget);
    expect(
      find.textContaining('shared on this device only · not synced'),
      findsOneWidget,
    );
    expect(find.text('Create shared goal'), findsOneWidget);
  });

  testWidgets('Together lists shared goals and attributed contributions only', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 15);
    final sharedGoal = _goal(
      id: 'shared-goal',
      title: 'Read together',
      owner: 'uid-a',
      visibility: RecordVisibility.shared,
    );
    final privateGoal = _goal(
      id: 'private-goal',
      title: 'Private reading',
      owner: 'uid-a',
      visibility: RecordVisibility.private,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningItemsProvider(
            PlanningKind.goal,
          ).overrideWith((ref) => Stream.value([sharedGoal, privateGoal])),
          planningHistoryProvider('shared-goal').overrideWith(
            (ref) => Stream.value([
              PlanningHistoryEntry(
                id: 'contribution-1',
                ownerUid: 'uid-b',
                definitionId: 'shared-goal',
                kind: 'goalProgress',
                visibility: RecordVisibility.shared,
                localDate: '2026-10-14',
                payload: '{"value":2,"notes":"Two chapters"}',
                recordedAtUtc: now,
              ),
            ]),
          ),
          currentUserIdentityProvider.overrideWithValue(_Identity('uid-a')),
        ],
        child: const MaterialApp(home: SharedTasksScreen(togetherView: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Read together'), findsOneWidget);
    expect(find.text('Private reading'), findsNothing);
    expect(find.textContaining('Other local account'), findsOneWidget);
    expect(find.textContaining('2.0 / 10.0 books'), findsOneWidget);
    expect(find.textContaining('not synced'), findsNWidgets(2));
  });
}

PlanningItem _goal({
  required String id,
  required String title,
  required String owner,
  required RecordVisibility visibility,
}) => PlanningItem(
  id: id,
  ownerUid: owner,
  kind: PlanningKind.goal,
  visibility: visibility,
  title: title,
  description: '',
  category: '',
  priority: 2,
  scheduledDate: null,
  scheduledMinute: 0,
  durationMinutes: 30,
  recurrence: 'once',
  weekdays: const [],
  targetDate: null,
  startDate: '2026-10-01',
  targetValue: 10,
  targetUnit: 'books',
  archived: false,
  createdAtUtc: DateTime.utc(2026, 10, 1),
  updatedAtUtc: DateTime.utc(2026, 10, 1),
  revision: 1,
);

class _Identity implements CurrentUserIdentity {
  const _Identity(this.currentUid);
  @override
  final String currentUid;
  @override
  Stream<String?> get uidChanges => Stream.value(currentUid);
}
