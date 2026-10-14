import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/life_database.dart';
import 'package:life_os/features/planning/domain/planning_repository.dart';
import 'package:life_os/features/planning/presentation/planning_screens.dart';
import 'package:life_os/features/planning/presentation/task_plan_import_screen.dart';
import 'package:life_os/features/records/data/drift_life_record_store.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/records/presentation/record_providers.dart';

void main() {
  testWidgets(
    '15-day import screen explains local preview and supported files',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TaskPlanImportScreen())),
      );
      expect(find.text('15-day task planner'), findsOneWidget);
      expect(find.byKey(const Key('select_plan_file')), findsOneWidget);
      expect(find.text('Local-only · no upload or cloud sync'), findsOneWidget);
      expect(
        find.textContaining('XLSX, CSV, TXT, PDF, or DOCX'),
        findsOneWidget,
      );
    },
  );

  testWidgets('create task validates title then displays the local task', (
    tester,
  ) async {
    final database = LifeDatabase.forTesting(NativeDatabase.memory());
    final identity = _Identity();
    final repo = PlanningRepository(
      OfflineLifeRecordRepository(DriftLifeRecordStore(database), identity),
      DriftPlanningHistoryStore(database),
      identity,
    );
    addTearDown(() async {
      await identity.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningRepositoryProvider.overrideWithValue(repo),
          planningItemsProvider(
            null,
          ).overrideWith((ref) => Stream.value(<PlanningItem>[])),
        ],
        child: const MaterialApp(home: PlanningScreen(kind: null)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planning_add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planning_save')));
    await tester.pumpAndSettle();
    expect(find.text('Title is required.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('planning_title')),
      'Read for 20 minutes',
    );
    await tester.tap(find.byKey(const Key('planning_save')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Could not save this item'), findsNothing);
    final saved = (await database.select(database.storedRecords).get()).single;
    expect(saved.payloadJson, contains('Read for 20 minutes'));
    expect(find.textContaining('Cloud sync is off'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Plan date selector shows an imported task on its assigned date', (
    tester,
  ) async {
    final database = LifeDatabase.forTesting(NativeDatabase.memory());
    final identity = _Identity();
    final repo = PlanningRepository(
      OfflineLifeRecordRepository(DriftLifeRecordStore(database), identity),
      DriftPlanningHistoryStore(database),
      identity,
    );
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final date =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final task = await repo.save(
      kind: PlanningKind.task,
      title: 'Future planner task',
      scheduledDate: date,
      description: 'Assigned to tomorrow',
    );
    addTearDown(() async {
      await identity.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningRepositoryProvider.overrideWithValue(repo),
          planningItemsProvider(
            null,
          ).overrideWith((ref) => Stream.value([task])),
        ],
        child: const MaterialApp(home: PlanningScreen(kind: null)),
      ),
    );
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Future planner task'), findsNothing);
    await tester.tap(find.byTooltip('Next day'));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Future planner task'), findsOneWidget);
    expect(find.textContaining('Complete when:'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

class _Identity implements CurrentUserIdentity {
  @override
  String? currentUid = 'widget-user';
  @override
  Stream<String?> get uidChanges => Stream.value(currentUid);

  Future<void> dispose() async {}
}
