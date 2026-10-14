import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/surface_card.dart';
import '../data/usage_stats_service.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key, this.service});
  final UsageStatsService? service;
  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen>
    with WidgetsBindingObserver {
  late final UsageStatsService _service = widget.service ?? UsageStatsService();
  DateTime _day = DateTime.now();
  bool _loading = true;
  bool _allowed = false;
  String? _error;
  List<AppUsageSummary> _rows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final access = await _service.hasAccess();
      final start = DateTime(_day.year, _day.month, _day.day);
      final rows = access
          ? await _service.query(
              start: start,
              end: DateTime(_day.year, _day.month, _day.day + 1),
            )
          : const <AppUsageSummary>[];
      if (mounted) {
        setState(() {
          _allowed = access;
          _rows = rows;
          _loading = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Screen Time')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text(
          'Usage data stays on this device. LIFE OS reads it only after Android Usage Access is granted.',
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous day',
                onPressed: () {
                  setState(() => _day = _day.subtract(const Duration(days: 1)));
                  unawaited(_refresh());
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_day.year}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: () {
                  setState(() => _day = _day.add(const Duration(days: 1)));
                  unawaited(_refresh());
                },
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Choose date',
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loading)
          const LoadingStateView()
        else if (_error != null)
          ErrorStateView(message: _error!, onRetry: _refresh)
        else if (!_allowed)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usage Access is off',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Android requires you to grant Usage Access in system settings. No app usage is shown until permission is granted.',
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await _service.openSettings();
                    } on Object catch (error) {
                      if (mounted) setState(() => _error = error.toString());
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Usage Access settings'),
                ),
              ],
            ),
          )
        else if (_rows.isEmpty)
          const EmptyStateView(
            title: 'No usage data available',
            message: 'Android returned no app usage for this date.',
            icon: Icons.query_stats_outlined,
          )
        else ...[
          Text(
            'App-wise foreground use',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final row in _rows)
            SurfaceCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(row.label),
                subtitle: Text(row.packageName),
                trailing: Text('${row.durationMinutes} min'),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Android usage statistics may be delayed and do not include time while an app was not in the foreground.',
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _day = picked);
      await _refresh();
    }
  }
}
