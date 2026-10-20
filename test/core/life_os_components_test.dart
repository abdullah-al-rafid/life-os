import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/app/theme/app_theme.dart';
import 'package:life_os/core/widgets/async_state_view.dart';
import 'package:life_os/core/widgets/life_os_components.dart';
import 'package:life_os/features/navigation/presentation/app_shell.dart';

void main() {
  test('navigation sections retain selection on nested routes and aliases', () {
    expect(
      AppSection.values
          .where((section) => section.matches('/plan/import'))
          .toList(),
      [AppSection.plan],
    );
    expect(
      AppSection.values
          .where((section) => section.matches('/plan/rolling'))
          .toList(),
      [AppSection.plan],
    );
    expect(
      AppSection.values
          .where((section) => section.matches('/plan/assigned'))
          .toList(),
      [AppSection.together],
    );
    expect(
      AppSection.values
          .where((section) => section.matches('/together'))
          .toList(),
      [AppSection.together],
    );
    expect(
      AppSection.values
          .where((section) => section.matches('/progress'))
          .toList(),
      [AppSection.progress],
    );
    expect(
      AppSection.values
          .where((section) => section.matches('/insights'))
          .toList(),
      [AppSection.progress],
    );
    expect(
      AppSection.values
          .where((section) => section.matches('/settings'))
          .toList(),
      [AppSection.settings],
    );
  });

  testWidgets(
    'shared components expose status, privacy and workload accessibly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ListView(
              children: [
                const PrivacySourceLabel(source: PrivacySource.privateLocal),
                const TaskStatusSelector(
                  value: TaskVisualStatus.partial,
                  onChanged: _ignoreStatus,
                ),
                const ProgressIndicatorCard(
                  label: 'Daily workload',
                  value: 150,
                  total: 120,
                  trailing: '150 / 120 min',
                  isOverCapacity: true,
                ),
                TaskCard(
                  title: 'Review the plan',
                  subtitle: '45 minutes',
                  source: PrivacySource.localOnly,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Private · on this device'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Partial'), findsOneWidget);
      expect(find.text('Not done'), findsOneWidget);
      expect(find.text('Over daily capacity'), findsOneWidget);
      expect(find.text('Review the plan'), findsOneWidget);
    },
  );

  testWidgets(
    'page scaffold keeps its content scrollable on a phone viewport',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AppPageScaffold(
              title: 'Plan',
              subtitle: '15-day cycle',
              actions: [
                OutlinedButton(onPressed: () {}, child: const Text('Import')),
              ],
              child: SizedBox(height: 1000, child: Text('Cycle content')),
            ),
          ),
        ),
      );

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('15-day cycle'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty states remain scroll-safe in short sliver space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              height: 80,
              child: EmptyStateView(
                title: 'A clear day to begin',
                message: 'Add a task, routine, or habit for today.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('A clear day to begin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error states remain scroll-safe in short sliver space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              height: 80,
              child: ErrorStateView(
                message: 'Local records are unavailable.',
                onRetry: _ignoreRetry,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Local records are unavailable.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _ignoreStatus(TaskVisualStatus _) {}
void _ignoreRetry() {}
