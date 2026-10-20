import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../../planning/domain/planning_repository.dart';
import '../../records/presentation/record_providers.dart';
import '../../screen_time/data/usage_stats_service.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../data/fifteen_day_pdf_service.dart';
import '../domain/fifteen_day_report.dart';

class FifteenDayReportScreen extends ConsumerStatefulWidget {
  const FifteenDayReportScreen({super.key});

  @override
  ConsumerState<FifteenDayReportScreen> createState() =>
      _FifteenDayReportScreenState();
}

class _FifteenDayReportScreenState
    extends ConsumerState<FifteenDayReportScreen> {
  late DateTime _startDate = _latestCompletedStart();
  bool _includeShared = false;
  bool _includeScreenTime = false;
  bool _screenTimeLoading = false;
  ScreenTimeInclusion _screenTimeState = ScreenTimeInclusion.notSelected;
  Map<String, List<AppUsageSummary>>? _screenTime;
  String? _screenTimeMessage;
  late final UsageStatsService _usage = UsageStatsService();

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(planningItemsProvider(null));
    final history = ref.watch(planningHistoryProvider(null));
    final tracking = ref.watch(trackingEntriesProvider((null, null)));
    final uid = ref.watch(currentUserIdentityProvider).currentUid;
    final period = FifteenDayReportPeriod(_startDate);
    final today = DateTime.now();

    return Scaffold(
      body: AppPageScaffold(
        title: '15-Day Reports',
        subtitle:
            'Review a completed 15-day period. The next plan is prepared outside LIFE OS as a CSV.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PrivacySourceLabel(
              source: PrivacySource.localOnly,
              details: 'preview and PDF are built on this device',
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'This report uses local records only. Remote assigned tasks are not included because this device has no verified, dated remote history for a selected past period.',
            ),
            const SizedBox(height: AppSpacing.md),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selected period',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${period.startKey} through ${period.endKey} · exactly 15 days',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('report_choose_start_date'),
                    onPressed: () => _chooseStartDate(today),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Choose period start'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SurfaceCard(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const Key('report_include_shared'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Include explicitly shared local records',
                    ),
                    subtitle: const Text(
                      'Shared goals and contributions are marked local-only; they are not synced.',
                    ),
                    value: _includeShared,
                    onChanged: (value) =>
                        setState(() => _includeShared = value),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    key: const Key('report_include_screen_time'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include Android Screen Time'),
                    subtitle: const Text(
                      'Optional. Usage is queried only after you opt in here and Android Usage Access is granted. Data stays on this device until you export the PDF.',
                    ),
                    value: _includeScreenTime,
                    onChanged: _screenTimeLoading
                        ? null
                        : (value) => _toggleScreenTime(value),
                  ),
                  if (_screenTimeLoading) const LinearProgressIndicator(),
                  if (_screenTimeMessage case final message?)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(message),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (uid == null || uid.trim().isEmpty)
              const ErrorStateView(message: 'Sign in to build a local report.')
            else if (items.isLoading || history.isLoading || tracking.isLoading)
              const LoadingStateView()
            else if (items.hasError || history.hasError || tracking.hasError)
              const ErrorStateView(
                message: 'Local report records could not be loaded. Try again.',
              )
            else
              _reportPreview(
                context,
                uid,
                period,
                items.requireValue,
                history.requireValue,
                tracking.requireValue,
                today,
              ),
          ],
        ),
      ),
    );
  }

  Widget _reportPreview(
    BuildContext context,
    String uid,
    FifteenDayReportPeriod period,
    List<PlanningItem> items,
    List<PlanningHistoryEntry> history,
    List<TrackingEntry> tracking,
    DateTime today,
  ) {
    try {
      period.validateCompleted(today: today);
      final report = const FifteenDayReportBuilder().build(
        period: period,
        viewerUid: uid,
        items: items,
        history: history,
        trackingEntries: tracking,
        includeSharedLocal: _includeShared,
        screenTimeByDate: _screenTime,
        screenTimeInclusion: _screenTimeState,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AggregatePreview(report: report),
          const SizedBox(height: AppSpacing.md),
          for (final day in report.days)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DayPreview(day: day),
            ),
          if (report.goals.isNotEmpty) ...[
            const PageHeader(title: 'Goal progress'),
            const SizedBox(height: AppSpacing.sm),
            for (final goal in report.goals)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _GoalPreview(goal: goal),
              ),
          ],
          if (report.isEmpty)
            const EmptyStateView(
              icon: Icons.summarize_outlined,
              title: 'No records in this period',
              message:
                  'The PDF will still show all 15 dates and clearly mark missing entries as not recorded.',
            ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('report_open_pdf_preview'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FifteenDayPdfPreviewScreen(report: report),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Preview PDF and export'),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Review the complete report before saving or sharing it. It contains local personal data and any local shared data you chose to include.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    } on ReportValidationFailure catch (error) {
      return ErrorStateView(message: error.message);
    }
  }

  Future<void> _chooseStartDate(DateTime today) async {
    final lastAllowed = DateTime(today.year, today.month, today.day - 15);
    final firstAllowed = DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isAfter(lastAllowed) ? lastAllowed : _startDate,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _startDate = DateTime(picked.year, picked.month, picked.day),
    );
    if (_includeScreenTime) unawaited(_loadScreenTime());
  }

  Future<void> _toggleScreenTime(bool enabled) async {
    if (!enabled) {
      setState(() {
        _includeScreenTime = false;
        _screenTimeState = ScreenTimeInclusion.notSelected;
        _screenTime = null;
        _screenTimeMessage = null;
      });
      return;
    }
    setState(() {
      _includeScreenTime = true;
      _screenTimeLoading = true;
      _screenTimeMessage = null;
    });
    try {
      if (!await _usage.hasAccess()) {
        if (!mounted) return;
        setState(() {
          _includeScreenTime = false;
          _screenTimeState = ScreenTimeInclusion.unavailable;
          _screenTimeMessage =
              'Android Usage Access is not granted or is unavailable on this device. Screen Time was not queried.';
        });
        return;
      }
      await _loadScreenTime();
    } on Object {
      if (mounted) {
        setState(() {
          _includeScreenTime = false;
          _screenTime = null;
          _screenTimeState = ScreenTimeInclusion.unavailable;
          _screenTimeMessage =
              'Screen Time could not be read. No usage values were added to the report.';
        });
      }
    } finally {
      if (mounted) setState(() => _screenTimeLoading = false);
    }
  }

  Future<void> _loadScreenTime() async {
    setState(() => _screenTimeLoading = true);
    try {
      if (!await _usage.hasAccess()) {
        throw const UsageStatsUnavailable(
          'Android Usage Access is unavailable.',
        );
      }
      final period = FifteenDayReportPeriod(_startDate);
      final values = <String, List<AppUsageSummary>>{};
      for (final date in period.days) {
        final rows = await _usage.query(
          start: date,
          end: date.add(const Duration(days: 1)),
        );
        values[reportDateKey(date)] = rows;
      }
      if (mounted) {
        setState(() {
          _screenTime = values;
          _screenTimeState = ScreenTimeInclusion.included;
          _screenTimeMessage =
              'On-device app usage loaded for all 15 dates. It is not synced.';
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _includeScreenTime = false;
          _screenTime = null;
          _screenTimeState = ScreenTimeInclusion.unavailable;
          _screenTimeMessage =
              'Screen Time could not be loaded for the whole period; it was omitted.';
        });
      }
    } finally {
      if (mounted) setState(() => _screenTimeLoading = false);
    }
  }
}

class _AggregatePreview extends StatelessWidget {
  const _AggregatePreview({required this.report});
  final FifteenDayReport report;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('15-day aggregate', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _Metric(label: 'Planned items', value: '${report.plannedTaskCount}'),
        _Metric(
          label: 'Done',
          value: '${report.countStatus(ReportTaskStatus.done)}',
        ),
        _Metric(
          label: 'Partial',
          value: '${report.countStatus(ReportTaskStatus.partial)}',
        ),
        _Metric(
          label: 'Not Done',
          value: '${report.countStatus(ReportTaskStatus.notDone)}',
        ),
        _Metric(
          label: 'Not recorded',
          value: '${report.countStatus(ReportTaskStatus.notRecorded)}',
        ),
        _Metric(label: 'Extra work entries', value: '${report.extraWorkCount}'),
        _Metric(
          label: 'Estimated planned time',
          value: '${report.estimatedPlannedMinutes} min',
        ),
        const Text(
          'Actual task time is unavailable because the app does not record it.',
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'No entry means “not recorded”; it does not mean zero or missed.',
        ),
      ],
    ),
  );
}

class _DayPreview extends StatelessWidget {
  const _DayPreview({required this.day});
  final ReportDay day;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(day.date, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        if (day.plannedTasks.isEmpty)
          const Text('No planned tasks for this day.')
        else
          for (final task in day.plannedTasks) _TaskLine(task: task),
        if (day.extraWork.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text('Extra work'),
          for (final task in day.extraWork) _TaskLine(task: task),
        ],
        if (day.trackingEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Prayer, fasting, wellness: no entries recorded.'),
          )
        else
          for (final entry in day.trackingEntries)
            Text('${entry.kind.name}: ${_trackingPreview(entry)}'),
        if (day.screenTime != null)
          Text(
            day.screenTime!.isEmpty
                ? 'Screen Time: no app rows returned; this does not confirm zero use.'
                : 'Screen Time: ${day.screenTime!.map((app) => '${app.label} ${app.durationMinutes} min').join(', ')}',
          ),
      ],
    ),
  );
}

class _TaskLine extends StatelessWidget {
  const _TaskLine({required this.task});
  final ReportTaskLine task;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${task.title} · ${task.status.label} · est. ${task.estimatedMinutes} min',
        ),
        Text(
          '${task.kind} · ${task.source.label}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (task.notes.isNotEmpty) Text('Notes: ${task.notes}'),
        if (task.evidenceReferences.isNotEmpty)
          Text(
            'Evidence references only: ${task.evidenceReferences.join(', ')}',
          ),
      ],
    ),
  );
}

class _GoalPreview extends StatelessWidget {
  const _GoalPreview({required this.goal});
  final ReportGoal goal;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
        Text(goal.source.label),
        Text(
          '${goal.target == null ? 'No measurable target' : '${goal.totalByPeriodEnd} / ${goal.target} ${goal.unit}'} - ${goal.completedByPeriodEnd ? 'Completed' : 'Active'}',
        ),
        for (final contribution in goal.contributions)
          Text(
            '${contribution.date} · ${contribution.authorLabel} · ${contribution.amount} ${goal.unit}${contribution.notes.isEmpty ? '' : ' · ${contribution.notes}'}',
          ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}

String _trackingPreview(TrackingEntry entry) {
  final payload = entry.payload;
  return switch (entry.kind) {
    TrackingEntryKind.prayer => '${entry.entryKey} · ${payload['status']}',
    TrackingEntryKind.fasting => '${payload['status']}',
    TrackingEntryKind.sleep => '${payload['durationMinutes']} min',
    TrackingEntryKind.workout =>
      '${payload['activity']} · ${payload['durationMinutes']} min',
  };
}

DateTime _latestCompletedStart() {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day - 15);
}

class FifteenDayPdfPreviewScreen extends StatefulWidget {
  const FifteenDayPdfPreviewScreen({required this.report, super.key});
  final FifteenDayReport report;

  @override
  State<FifteenDayPdfPreviewScreen> createState() =>
      _FifteenDayPdfPreviewScreenState();
}

class _FifteenDayPdfPreviewScreenState
    extends State<FifteenDayPdfPreviewScreen> {
  late final FifteenDayPdfService _service = FifteenDayPdfService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('PDF preview'),
      actions: [
        IconButton(
          key: const Key('report_print_pdf'),
          tooltip: 'Print or save a copy',
          onPressed: _busy ? null : _print,
          icon: const Icon(Icons.print_outlined),
        ),
        IconButton(
          key: const Key('report_save_pdf'),
          tooltip: 'Save PDF on this device',
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save_alt),
        ),
        IconButton(
          key: const Key('report_share_pdf'),
          tooltip: 'Share PDF',
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.share_outlined),
        ),
      ],
    ),
    body: _busy
        ? const LoadingStateView(message: 'Preparing your local PDF…')
        : PdfPreview(
            build: (_) => _service.generate(widget.report),
            allowPrinting: false,
            allowSharing: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            onError: (context, _) => ErrorStateView(
              message: 'The PDF preview could not be generated.',
            ),
          ),
  );

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final path = await _service.save(widget.report);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved on this device: $path')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF could not be saved on this device.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    setState(() => _busy = true);
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _service.generate(widget.report),
        name: FifteenDayPdfService.reportFilename(widget.report),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The print or save dialog could not be opened.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await _service.share(widget.report);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The Android share sheet could not be opened.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
