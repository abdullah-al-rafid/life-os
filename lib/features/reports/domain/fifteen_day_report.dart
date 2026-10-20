import 'dart:convert';

import '../../planning/domain/planning_repository.dart';
import '../../records/domain/life_record.dart';
import '../../screen_time/data/usage_stats_service.dart';
import '../../tracking/domain/tracking_entry.dart';

class FifteenDayReportPeriod {
  FifteenDayReportPeriod(DateTime startDate)
    : startDate = DateTime(startDate.year, startDate.month, startDate.day),
      endDate = DateTime(startDate.year, startDate.month, startDate.day + 14);

  final DateTime startDate;
  final DateTime endDate;

  int get dayCount => endDate.difference(startDate).inDays + 1;

  String get startKey => reportDateKey(startDate);
  String get endKey => reportDateKey(endDate);

  Iterable<DateTime> get days sync* {
    for (var offset = 0; offset < 15; offset++) {
      yield startDate.add(Duration(days: offset));
    }
  }

  bool includes(String dateKey) =>
      dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0;

  void validateCompleted({required DateTime today}) {
    if (dayCount != 15) {
      throw const ReportValidationFailure('A report period must be 15 days.');
    }
    final localToday = DateTime(today.year, today.month, today.day);
    if (!endDate.isBefore(localToday)) {
      throw const ReportValidationFailure(
        'Choose a completed 15-day period ending before today.',
      );
    }
  }
}

enum ReportTaskStatus { done, partial, notDone, notRecorded }

extension ReportTaskStatusLabel on ReportTaskStatus {
  String get label => switch (this) {
    ReportTaskStatus.done => 'Done',
    ReportTaskStatus.partial => 'Partial',
    ReportTaskStatus.notDone => 'Not Done',
    ReportTaskStatus.notRecorded => 'Not recorded',
  };
}

enum ReportDataSource { personalLocal, sharedLocal }

extension ReportDataSourceLabel on ReportDataSource {
  String get label => switch (this) {
    ReportDataSource.personalLocal => 'Personal - local',
    ReportDataSource.sharedLocal => 'Shared on this device only - not synced',
  };
}

enum ScreenTimeInclusion { notSelected, unavailable, included }

class ReportTaskLine {
  const ReportTaskLine({
    required this.definitionId,
    required this.title,
    required this.kind,
    required this.priority,
    required this.estimatedMinutes,
    required this.status,
    required this.notes,
    required this.evidenceReferences,
    required this.source,
    required this.isExtraWork,
  });

  final String definitionId, title, kind, notes;
  final int priority, estimatedMinutes;
  final ReportTaskStatus status;
  final List<String> evidenceReferences;
  final ReportDataSource source;
  final bool isExtraWork;
}

class ReportGoalContribution {
  const ReportGoalContribution({
    required this.date,
    required this.authorLabel,
    required this.amount,
    required this.notes,
  });

  final String date, authorLabel, notes;
  final double amount;
}

class ReportGoal {
  const ReportGoal({
    required this.title,
    required this.description,
    required this.target,
    required this.unit,
    required this.startDate,
    required this.deadline,
    required this.totalByPeriodEnd,
    required this.completedByPeriodEnd,
    required this.source,
    required this.contributions,
  });

  final String title, description, unit, startDate;
  final String? deadline;
  final double? target;
  final double totalByPeriodEnd;
  final bool completedByPeriodEnd;
  final ReportDataSource source;
  final List<ReportGoalContribution> contributions;
}

class ReportDay {
  const ReportDay({
    required this.date,
    required this.plannedTasks,
    required this.extraWork,
    required this.trackingEntries,
    required this.screenTime,
  });

  final String date;
  final List<ReportTaskLine> plannedTasks, extraWork;
  final List<TrackingEntry> trackingEntries;
  final List<AppUsageSummary>? screenTime;
}

class FifteenDayReport {
  const FifteenDayReport({
    required this.period,
    required this.days,
    required this.goals,
    required this.screenTimeInclusion,
  });

  final FifteenDayReportPeriod period;
  final List<ReportDay> days;
  final List<ReportGoal> goals;
  final ScreenTimeInclusion screenTimeInclusion;

  bool get isEmpty =>
      days.every(
        (day) =>
            day.plannedTasks.isEmpty &&
            day.extraWork.isEmpty &&
            day.trackingEntries.isEmpty &&
            (day.screenTime == null || day.screenTime!.isEmpty),
      ) &&
      goals.every((goal) => goal.contributions.isEmpty);

  int get plannedTaskCount =>
      days.fold(0, (sum, day) => sum + day.plannedTasks.length);
  int get extraWorkCount =>
      days.fold(0, (sum, day) => sum + day.extraWork.length);
  int countStatus(ReportTaskStatus status) => days.fold(
    0,
    (sum, day) =>
        sum + day.plannedTasks.where((task) => task.status == status).length,
  );
  int get estimatedPlannedMinutes => days.fold(
    0,
    (sum, day) =>
        sum +
        day.plannedTasks.fold(
          0,
          (subtotal, task) => subtotal + task.estimatedMinutes,
        ),
  );
}

class ReportValidationFailure implements Exception {
  const ReportValidationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class FifteenDayReportBuilder {
  const FifteenDayReportBuilder();

  FifteenDayReport build({
    required FifteenDayReportPeriod period,
    required String viewerUid,
    required List<PlanningItem> items,
    required List<PlanningHistoryEntry> history,
    required List<TrackingEntry> trackingEntries,
    bool includeSharedLocal = false,
    Map<String, List<AppUsageSummary>>? screenTimeByDate,
    ScreenTimeInclusion screenTimeInclusion = ScreenTimeInclusion.notSelected,
  }) {
    if (viewerUid.trim().isEmpty || viewerUid != viewerUid.trim()) {
      throw const ReportValidationFailure(
        'Sign in to build a local report for this account.',
      );
    }
    if (period.dayCount != 15) {
      throw const ReportValidationFailure('A report period must be 15 days.');
    }
    final visibleItems = items
        .where((item) {
          if (item.archived) return false;
          if (item.visibility == RecordVisibility.shared) {
            return includeSharedLocal;
          }
          if (item.ownerUid == viewerUid) return true;
          return false;
        })
        .toList(growable: false);
    final byId = {for (final item in visibleItems) item.id: item};
    final visibleHistory = history
        .where((entry) {
          final definition = byId[entry.definitionId];
          if (definition == null) return false;
          if (definition.visibility == RecordVisibility.private) {
            return entry.ownerUid == viewerUid &&
                definition.ownerUid == viewerUid;
          }
          return includeSharedLocal &&
              entry.visibility == RecordVisibility.shared &&
              definition.visibility == RecordVisibility.shared;
        })
        .toList(growable: false);

    final days = <ReportDay>[];
    for (final date in period.days) {
      final key = reportDateKey(date);
      final planned = visibleItems
          .where(
            (item) => item.kind != PlanningKind.goal && item.occursOn(date),
          )
          .where((item) => item.kind != PlanningKind.goal)
          .toList(growable: false);
      final dayHistory = visibleHistory
          .where((entry) => entry.localDate == key)
          .toList(growable: false);
      final plannedIds = planned.map((item) => item.id).toSet();
      final plannedRows =
          planned
              .map((item) => _taskLine(item, dayHistory, isExtra: false))
              .toList(growable: false)
            ..sort((a, b) {
              final itemA = byId[a.definitionId]!;
              final itemB = byId[b.definitionId]!;
              final byTime = itemA.scheduledMinute.compareTo(
                itemB.scheduledMinute,
              );
              return byTime == 0 ? a.title.compareTo(b.title) : byTime;
            });
      final extras = <ReportTaskLine>[];
      for (final entry in dayHistory.where(
        (entry) => entry.kind.endsWith('Completion'),
      )) {
        if (plannedIds.contains(entry.definitionId)) continue;
        final item = byId[entry.definitionId];
        if (item == null || item.kind == PlanningKind.goal) continue;
        extras.add(_taskLine(item, [entry], isExtra: true));
      }
      final track =
          trackingEntries
              .where((entry) {
                if (entry.localDate != key) return false;
                if (entry.visibility == RecordVisibility.shared) {
                  return includeSharedLocal;
                }
                return entry.ownerUid == viewerUid;
              })
              .toList(growable: false)
            ..sort((a, b) {
              final byKind = a.kind.index.compareTo(b.kind.index);
              return byKind == 0 ? a.entryKey.compareTo(b.entryKey) : byKind;
            });
      days.add(
        ReportDay(
          date: key,
          plannedTasks: plannedRows,
          extraWork: extras,
          trackingEntries: track,
          screenTime: screenTimeByDate == null
              ? null
              : screenTimeByDate[key] ?? const <AppUsageSummary>[],
        ),
      );
    }

    final goals = <ReportGoal>[];
    for (final goal in visibleItems.where(
      (item) => item.kind == PlanningKind.goal,
    )) {
      final entries = visibleHistory.where(
        (entry) =>
            entry.definitionId == goal.id &&
            entry.kind == 'goalProgress' &&
            entry.localDate.compareTo(period.endKey) <= 0,
      );
      final parsed = <(PlanningHistoryEntry, GoalContribution)>[];
      for (final entry in entries) {
        try {
          parsed.add((entry, GoalContribution.fromHistory(entry)));
        } on Object {
          // Malformed local history is not interpreted as valid progress.
        }
      }
      final total = parsed.fold<double>(0, (sum, row) => sum + row.$2.amount);
      final periodContributions = parsed
          .where((row) => period.includes(row.$1.localDate))
          .map(
            (row) => ReportGoalContribution(
              date: row.$2.date,
              authorLabel: row.$2.authorUid == viewerUid
                  ? 'You'
                  : 'Other local account',
              amount: row.$2.amount,
              notes: row.$2.notes,
            ),
          )
          .toList(growable: false);
      goals.add(
        ReportGoal(
          title: goal.title,
          description: goal.description,
          target: goal.targetValue,
          unit: goal.targetUnit,
          startDate: goal.startDate,
          deadline: goal.targetDate,
          totalByPeriodEnd: total,
          completedByPeriodEnd:
              goal.targetValue != null && total >= goal.targetValue!,
          source: goal.visibility == RecordVisibility.shared
              ? ReportDataSource.sharedLocal
              : ReportDataSource.personalLocal,
          contributions: periodContributions,
        ),
      );
    }
    return FifteenDayReport(
      period: period,
      days: days,
      goals: goals,
      screenTimeInclusion: screenTimeInclusion,
    );
  }

  ReportTaskLine _taskLine(
    PlanningItem item,
    List<PlanningHistoryEntry> dayHistory, {
    required bool isExtra,
  }) {
    final matches =
        dayHistory
            .where(
              (entry) =>
                  entry.definitionId == item.id &&
                  entry.kind.endsWith('Completion'),
            )
            .toList(growable: false)
          ..sort((a, b) => b.recordedAtUtc.compareTo(a.recordedAtUtc));
    final latest = matches.firstOrNull;
    var status = ReportTaskStatus.notRecorded;
    var notes = '';
    var evidence = const <String>[];
    if (latest != null) {
      try {
        final payload = jsonDecode(latest.payload) as Map<String, dynamic>;
        status = switch (payload['status']) {
          'done' => ReportTaskStatus.done,
          'partial' => ReportTaskStatus.partial,
          'notDone' => ReportTaskStatus.notDone,
          _ => ReportTaskStatus.notRecorded,
        };
        notes = payload['notes'] as String? ?? '';
        final raw = payload['evidence'];
        if (raw is List) {
          evidence = raw
              .whereType<Map>()
              .map((file) => file['name'])
              .whereType<String>()
              .where((name) => name.trim().isNotEmpty)
              .toList(growable: false);
        }
      } on Object {
        status = ReportTaskStatus.notRecorded;
      }
    }
    return ReportTaskLine(
      definitionId: item.id,
      title: item.title,
      kind: item.kind.name,
      priority: item.priority,
      estimatedMinutes: item.durationMinutes,
      status: status,
      notes: notes,
      evidenceReferences: evidence,
      source: item.visibility == RecordVisibility.shared
          ? ReportDataSource.sharedLocal
          : ReportDataSource.personalLocal,
      isExtraWork: isExtra,
    );
  }
}

String reportDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
