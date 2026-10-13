import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/app/app.dart';

void main() {
  testWidgets(
    'home shell presents LIFE OS and navigates to foundation sections',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: LifeOsApp()));
      await tester.pumpAndSettle();

      expect(find.text('LIFE OS'), findsOneWidget);
      expect(find.text('Make room for\nwhat matters.'), findsOneWidget);
      expect(find.text('Today’s rhythm'), findsOneWidget);

      await tester.tap(find.text('Plan').last);
      await tester.pumpAndSettle();
      expect(find.text('LIFE OS / PLAN'), findsOneWidget);
      expect(find.text('Plan is part of the foundation'), findsOneWidget);
    },
  );

  testWidgets('wide layout shows the persistent navigation rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: LifeOsApp()));
    await tester.pumpAndSettle();

    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
  });
}
