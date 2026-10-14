import 'package:flutter/services.dart';

class AppUsageSummary {
  const AppUsageSummary({
    required this.packageName,
    required this.label,
    required this.durationMinutes,
  });
  final String packageName;
  final String label;
  final int durationMinutes;
}

class UsageStatsUnavailable implements Exception {
  const UsageStatsUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class UsageStatsService {
  UsageStatsService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('life_os/usage_stats');
  final MethodChannel _channel;

  Future<bool> hasAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      throw UsageStatsUnavailable(
        error.message ?? 'Usage Access status could not be read.',
      );
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openUsageSettings');
    } on MissingPluginException {
      throw const UsageStatsUnavailable(
        'Usage Access is available on Android only.',
      );
    } on PlatformException catch (error) {
      throw UsageStatsUnavailable(
        error.message ?? 'Android Usage Access settings could not be opened.',
      );
    }
  }

  Future<List<AppUsageSummary>> query({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!start.isBefore(end)) {
      throw ArgumentError('The end date must be after the start date.');
    }
    try {
      final rows = await _channel.invokeListMethod<Object?>('queryUsage', {
        'startMillis': start.millisecondsSinceEpoch,
        'endMillis': end.millisecondsSinceEpoch,
      });
      return (rows ?? const [])
          .map((value) {
            if (value is! Map) {
              throw const UsageStatsUnavailable(
                'Android returned an invalid usage summary.',
              );
            }
            final packageName = value['packageName'];
            final label = value['label'];
            final minutes = value['durationMinutes'];
            if (packageName is! String ||
                label is! String ||
                minutes is! int ||
                minutes < 0) {
              throw const UsageStatsUnavailable(
                'Android returned an invalid usage summary.',
              );
            }
            return AppUsageSummary(
              packageName: packageName,
              label: label,
              durationMinutes: minutes,
            );
          })
          .toList(growable: false)
        ..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
    } on MissingPluginException {
      throw const UsageStatsUnavailable(
        'App-wise usage summaries are available on Android only.',
      );
    } on PlatformException catch (error) {
      throw UsageStatsUnavailable(
        error.message ?? 'App usage data could not be read.',
      );
    }
  }
}
