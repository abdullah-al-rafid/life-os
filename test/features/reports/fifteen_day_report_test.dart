import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/planning/domain/planning_repository.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/reports/domain/fifteen_day_report.dart';
import 'package:life_os/features/screen_time/data/usage_stats_service.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';

void main() {
  final period = FifteenDayReportPeriod(DateTime(2026, 10, 1));

  test(
    'period contains exactly start through day 15 and rejects incomplete range',
    () {
      expect(period.dayCount, 15);
      expect(period.includes('2026-10-01'), isTrue);
      expect(period.includes('2026-10-15'), isTrue);
      expect(period.includes('2026-09-30'), isFalse);
      expect(period.includes('2026-10-16'), isFalse);
      expect(
        () => period.validateCompleted(today: DateTime(2026, 10, 15)),
        throwsA(isA<ReportValidationFailure>()),
      );
      expect(
        () => period.validateCompleted(today: DateTime(2026, 10, 16)),
        returnsNormally,
      );
    },
  );

  test(
    'aggregates planned statuses, missed notes, extra work and estimates',
    () {
      final planned = _task(
        id: 'planned',
        owner: 'uid-a',
        title: 'Read chapter',
        date: '2026-10-01',
        minutes: 25,
      );
      final second = _task(
        id: 'missed',
        owner: 'uid-a',
        title: 'Walk',
        date: '2026-10-01',
        minutes: 30,
      );
      final extra = _task(
        id: 'extra',
        owner: 'uid-a',
        title: 'Extra study',
        date: '2026-10-02',
        minutes: 40,
      );
      final result = _build(
        items: [planned, second, extra],
        history: [
          _history('h1', planned, '2026-10-01', 'done'),
          _history(
            'h2',
            second,
            '2026-10-01',
            'notDone',
            notes: 'Family emergency',
          ),
          _history('h3', extra, '2026-10-03', 'partial'),
        ],
      );
      final dayOne = result.days.first;
      expect(dayOne.plannedTasks, hasLength(2));
      expect(dayOne.plannedTasks.first.status, ReportTaskStatus.done);
      expect(dayOne.plannedTasks.last.status, ReportTaskStatus.notDone);
      expect(dayOne.plannedTasks.last.notes, 'Family emergency');
      expect(dayOne.extraWork, isEmpty);
      expect(result.days[2].extraWork.single.title, 'Extra study');
      expect(result.days[2].extraWork.single.status, ReportTaskStatus.partial);
      expect(result.estimatedPlannedMinutes, 95);
      expect(result.countStatus(ReportTaskStatus.notRecorded), 1);
      expect(result.countStatus(ReportTaskStatus.notDone), 1);
    },
  );

  test(
    'privacy filtering excludes other private and opt-in local shared records',
    () {
      final own = _task(
        id: 'own',
        owner: 'uid-a',
        title: 'Personal',
        date: '2026-10-01',
      );
      final privatePeer = _task(
        id: 'private-peer',
        owner: 'uid-b',
        title: 'Secret peer task',
        date: '2026-10-01',
      );
      final sharedPeer = _task(
        id: 'shared-peer',
        owner: 'uid-b',
        title: 'Local shared task',
        date: '2026-10-01',
        visibility: RecordVisibility.shared,
      );
      final tracking = [
        _tracking('private-track', 'uid-b', RecordVisibility.private),
        _tracking('shared-track', 'uid-b', RecordVisibility.shared),
      ];
      final hidden = _build(
        items: [own, privatePeer, sharedPeer],
        history: [
          _history('own-h', own, '2026-10-01', 'done'),
          _history('peer-h', privatePeer, '2026-10-01', 'done'),
          _history(
            'shared-h',
            sharedPeer,
            '2026-10-01',
            'partial',
            author: 'uid-b',
            visibility: RecordVisibility.shared,
          ),
        ],
        tracking: tracking,
      );
      expect(hidden.days.first.plannedTasks.map((task) => task.title), [
        'Personal',
      ]);
      expect(hidden.days.first.trackingEntries, isEmpty);

      final included = _build(
        items: [own, privatePeer, sharedPeer],
        history: [
          _history('own-h', own, '2026-10-01', 'done'),
          _history('peer-h', privatePeer, '2026-10-01', 'done'),
          _history(
            'shared-h',
            sharedPeer,
            '2026-10-01',
            'partial',
            author: 'uid-b',
            visibility: RecordVisibility.shared,
          ),
        ],
        tracking: tracking,
        includeSharedLocal: true,
      );
      expect(included.days.first.plannedTasks, hasLength(2));
      expect(
        included.days.first.plannedTasks
            .singleWhere((task) => task.source == ReportDataSource.sharedLocal)
            .source,
        ReportDataSource.sharedLocal,
      );
      expect(included.days.first.trackingEntries, hasLength(1));
      expect(included.days.first.trackingEntries.single.id, 'shared-track');
    },
  );

  test(
    'goal progress is attributed and aggregated only through period end',
    () {
      final goal = _goal('shared-goal', 'uid-a', RecordVisibility.shared);
      final contributions = [
        _history(
          'g1',
          goal,
          '2026-10-02',
          'goalProgress',
          author: 'uid-a',
          visibility: RecordVisibility.shared,
          value: 4,
        ),
        _history(
          'g2',
          goal,
          '2026-10-14',
          'goalProgress',
          author: 'uid-b',
          visibility: RecordVisibility.shared,
          value: 6,
        ),
        _history(
          'g3',
          goal,
          '2026-10-16',
          'goalProgress',
          author: 'uid-a',
          visibility: RecordVisibility.shared,
          value: 10,
        ),
      ];
      final report = _build(
        items: [goal],
        history: contributions,
        includeSharedLocal: true,
      );
      final result = report.goals.single;
      expect(result.totalByPeriodEnd, 10);
      expect(result.completedByPeriodEnd, isTrue);
      expect(result.contributions, hasLength(2));
      expect(result.contributions.map((item) => item.authorLabel), [
        'You',
        'Other local account',
      ]);
      expect(result.source.label, contains('not synced'));
    },
  );

  test('private activity on a shared task stays out of the shared report', () {
    final shared = _task(
      id: 'shared-own',
      owner: 'uid-a',
      title: 'Shared task',
      date: '2026-10-01',
      visibility: RecordVisibility.shared,
    );
    final report = _build(
      items: [shared],
      history: [
        _history(
          'private-completion',
          shared,
          '2026-10-01',
          'done',
          notes: 'Private note',
          visibility: RecordVisibility.private,
        ),
      ],
      includeSharedLocal: true,
    );
    final row = report.days.first.plannedTasks.single;
    expect(row.status, ReportTaskStatus.notRecorded);
    expect(row.notes, isEmpty);
    expect(row.evidenceReferences, isEmpty);
  });

  test('personal report exposes evidence filenames, never storage keys', () {
    final task = _task(
      id: 'evidence-task',
      owner: 'uid-private',
      title: 'Study notes',
      date: '2026-10-01',
    );
    final report = const FifteenDayReportBuilder().build(
      period: period,
      viewerUid: 'uid-private',
      items: [task],
      history: [
        PlanningHistoryEntry(
          id: 'evidence-history',
          ownerUid: 'uid-private',
          definitionId: task.id,
          kind: 'taskCompletion',
          visibility: RecordVisibility.private,
          localDate: '2026-10-01',
          payload:
              '{"status":"done","evidence":[{"name":"notes.pdf","key":"private-storage-key.pdf"}]}',
          recordedAtUtc: DateTime.utc(2026, 10, 1),
        ),
      ],
      trackingEntries: const [],
    );
    final row = report.days.first.plannedTasks.single;
    expect(row.evidenceReferences, ['notes.pdf']);
    expect(
      row.evidenceReferences.join(),
      isNot(contains('private-storage-key')),
    );
  });

  test(
    'empty records stay missing and Screen Time appears only when supplied',
    () {
      final empty = _build(items: [], history: [], tracking: []);
      expect(empty.days, hasLength(15));
      expect(empty.isEmpty, isTrue);
      expect(empty.days.first.plannedTasks, isEmpty);
      expect(empty.days.first.trackingEntries, isEmpty);
      expect(empty.days.first.screenTime, isNull);

      final withUsage = _build(
        items: [],
        history: [],
        screenTime: {
          '2026-10-01': const [
            AppUsageSummary(
              packageName: 'private.package',
              label: 'Browser',
              durationMinutes: 12,
            ),
          ],
        },
        inclusion: ScreenTimeInclusion.included,
      );
      expect(withUsage.days.first.screenTime!.single.label, 'Browser');
      expect(withUsage.days[1].screenTime, isEmpty);
      expect(withUsage.screenTimeInclusion, ScreenTimeInclusion.included);
    },
  );
}

FifteenDayReport _build({
  required List<PlanningItem> items,
  required List<PlanningHistoryEntry> history,
  List<TrackingEntry> tracking = const [],
  bool includeSharedLocal = false,
  Map<String, List<AppUsageSummary>>? screenTime,
  ScreenTimeInclusion inclusion = ScreenTimeInclusion.notSelected,
}) => const FifteenDayReportBuilder().build(
  period: FifteenDayReportPeriod(DateTime(2026, 10, 1)),
  viewerUid: 'uid-a',
  items: items,
  history: history,
  trackingEntries: tracking,
  includeSharedLocal: includeSharedLocal,
  screenTimeByDate: screenTime,
  screenTimeInclusion: inclusion,
);

PlanningItem _task({
  required String id,
  required String owner,
  required String title,
  required String date,
  int minutes = 30,
  RecordVisibility visibility = RecordVisibility.private,
}) => PlanningItem(
  id: id,
  ownerUid: owner,
  kind: PlanningKind.task,
  visibility: visibility,
  title: title,
  description: '',
  category: 'Personal',
  priority: 2,
  scheduledDate: date,
  scheduledMinute: 540,
  durationMinutes: minutes,
  recurrence: 'once',
  weekdays: const [],
  targetDate: null,
  startDate: date,
  targetValue: null,
  targetUnit: '',
  archived: false,
  createdAtUtc: DateTime.utc(2026, 9, 1),
  updatedAtUtc: DateTime.utc(2026, 9, 1),
  revision: 1,
);

PlanningItem _goal(String id, String owner, RecordVisibility visibility) =>
    PlanningItem(
      id: id,
      ownerUid: owner,
      kind: PlanningKind.goal,
      visibility: visibility,
      title: 'Read together',
      description: 'Shared reading target',
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

PlanningHistoryEntry _history(
  String id,
  PlanningItem item,
  String date,
  String kind, {
  String? notes,
  String? author,
  RecordVisibility visibility = RecordVisibility.private,
  double? value,
}) => PlanningHistoryEntry(
  id: id,
  ownerUid: author ?? item.ownerUid,
  definitionId: item.id,
  kind: kind == 'goalProgress' ? kind : 'taskCompletion',
  visibility: visibility,
  localDate: date,
  payload: kind == 'goalProgress'
      ? '{"value":$value,"notes":"${notes ?? ''}"}'
      : '{"status":"$kind","notes":"${notes ?? ''}"}',
  recordedAtUtc: DateTime.utc(2026, 10, 1),
);

TrackingEntry _tracking(String id, String owner, RecordVisibility visibility) =>
    TrackingEntry(
      id: id,
      ownerUid: owner,
      kind: TrackingEntryKind.fasting,
      localDate: '2026-10-01',
      entryKey: 'daily',
      visibility: visibility,
      payloadJson: '{"status":"fasted"}',
      createdAtUtc: DateTime.utc(2026, 10, 1),
      updatedAtUtc: DateTime.utc(2026, 10, 1),
    );
