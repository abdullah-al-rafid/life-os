import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/records/domain/life_record_repository.dart';
import 'package:life_os/features/records/presentation/record_providers.dart';
import 'package:life_os/features/reports/presentation/fifteen_day_report_screen.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';

void main() {
  testWidgets(
    'empty report preview shows missing data distinctly and exposes opt-ins',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planningItemsProvider(
              null,
            ).overrideWith((ref) => Stream.value(const [])),
            planningHistoryProvider(
              null,
            ).overrideWith((ref) => Stream.value(const [])),
            trackingEntriesProvider((
              null,
              null,
            )).overrideWith((ref) => Stream.value(const <TrackingEntry>[])),
            currentUserIdentityProvider.overrideWithValue(_Identity()),
          ],
          child: const MaterialApp(home: FifteenDayReportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('exactly 15 days'), findsOneWidget);
      expect(find.text('No records in this period'), findsOneWidget);
      expect(find.text('Not recorded'), findsOneWidget);
      expect(find.text('Include Android Screen Time'), findsOneWidget);
      expect(
        find.text('Include explicitly shared local records'),
        findsOneWidget,
      );
      expect(find.text('Preview PDF and export'), findsOneWidget);
    },
  );
}

class _Identity implements CurrentUserIdentity {
  @override
  String? get currentUid => 'test-user';
  @override
  Stream<String?> get uidChanges => Stream<String?>.value(currentUid);
}
