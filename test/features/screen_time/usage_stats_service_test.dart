import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/screen_time/data/usage_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/usage_stats');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = UsageStatsService(channel: channel);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reports access and sorts actual app usage descending', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => switch (call.method) {
        'hasUsageAccess' => true,
        'queryUsage' => [
          {'packageName': 'b', 'label': 'B', 'durationMinutes': 3},
          {'packageName': 'a', 'label': 'A', 'durationMinutes': 20},
        ],
        _ => null,
      },
    );
    expect(await service.hasAccess(), isTrue);
    final result = await service.query(
      start: DateTime(2026),
      end: DateTime(2026, 1, 2),
    );
    expect(result.map((item) => item.packageName), ['a', 'b']);
  });

  test('does not claim permission when platform channel is missing', () async {
    expect(await service.hasAccess(), isFalse);
    await expectLater(
      service.query(start: DateTime(2026), end: DateTime(2026, 1, 2)),
      throwsA(isA<UsageStatsUnavailable>()),
    );
  });

  test('rejects malformed native data and invalid date range', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => [
        {'packageName': 'a', 'label': 'A', 'durationMinutes': 'bad'},
      ],
    );
    await expectLater(
      service.query(start: DateTime(2026), end: DateTime(2026, 1, 2)),
      throwsA(isA<UsageStatsUnavailable>()),
    );
    await expectLater(
      service.query(start: DateTime(2026, 1, 2), end: DateTime(2026)),
      throwsArgumentError,
    );
  });
}
