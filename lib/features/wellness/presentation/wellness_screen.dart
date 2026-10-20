import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/presentation/record_providers.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../../tracking/domain/tracking_workflows.dart';

class WellnessScreen extends ConsumerStatefulWidget {
  const WellnessScreen({super.key});

  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> {
  DateTime _date = DateTime.now();
  final _sleepDuration = TextEditingController();
  final _sleepNotes = TextEditingController();
  String? _loadedSleepId;
  String? _error;
  bool _savingSleep = false;

  @override
  void dispose() {
    _sleepDuration.dispose();
    _sleepNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sleeps = ref.watch(
      trackingEntriesProvider((TrackingEntryKind.sleep, null)),
    );
    final workouts = ref.watch(
      trackingEntriesProvider((TrackingEntryKind.workout, null)),
    );
    final uid = ref.watch(currentUserIdentityProvider).currentUid;
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('workout_add'),
        onPressed: () => _editWorkout(context),
        icon: const Icon(Icons.add),
        label: const Text('Log workout'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                96,
              ),
              children: [
                const _LocalOnlyLabel(),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  key: const Key('wellness_date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_dateLabel(_date)),
                ),
                const SizedBox(height: AppSpacing.md),
                sleeps.when(
                  loading: () => const LoadingStateView(),
                  error: (_, _) => ErrorStateView(
                    message: 'Sleep records could not be loaded locally.',
                    onRetry: () => ref.invalidate(
                      trackingEntriesProvider((TrackingEntryKind.sleep, null)),
                    ),
                  ),
                  data: (all) {
                    final entries = all
                        .where((entry) => entry.ownerUid == uid)
                        .toList();
                    final selected = entries
                        .where(
                          (entry) => entry.localDate == localDateKey(_date),
                        )
                        .firstOrNull;
                    _syncSleepFields(selected);
                    return _sleepCard(selected, entries);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Workouts', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                workouts.when(
                  loading: () => const LoadingStateView(),
                  error: (_, _) => ErrorStateView(
                    message: 'Workout records could not be loaded locally.',
                    onRetry: () => ref.invalidate(
                      trackingEntriesProvider((
                        TrackingEntryKind.workout,
                        null,
                      )),
                    ),
                  ),
                  data: (all) {
                    final entries = all
                        .where((entry) => entry.ownerUid == uid)
                        .toList();
                    final selected = entries
                        .where(
                          (entry) => entry.localDate == localDateKey(_date),
                        )
                        .toList();
                    if (selected.isEmpty) {
                      return const EmptyStateView(
                        title: 'No workouts for this date',
                        message: 'Log a workout to start a local history.',
                        icon: Icons.fitness_center_outlined,
                      );
                    }
                    return Column(
                      children: [
                        for (final entry in selected)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _WorkoutCard(
                              entry: entry,
                              onEdit: () => _editWorkout(context, entry),
                              onDelete: () => _delete(entry),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Recent history',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RecentWellnessSummary(
                  sleeps: sleeps,
                  workouts: workouts,
                  ownerUid: uid,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sleepCard(
    TrackingEntry? selected,
    List<TrackingEntry> all,
  ) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'One total duration per local wake-up date. Historical dates stay as recorded when the timezone changes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('sleep_duration'),
          controller: _sleepDuration,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Duration in minutes (1–1440)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('sleep_notes'),
          controller: _sleepNotes,
          maxLines: 2,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const Key('sleep_save'),
                onPressed: _savingSleep ? null : () => _saveSleep(selected),
                child: Text(
                  _savingSleep
                      ? 'Saving…'
                      : selected == null
                      ? 'Save sleep'
                      : 'Update sleep',
                ),
              ),
            ),
            if (selected != null) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                key: const Key('sleep_delete'),
                tooltip: 'Delete sleep entry',
                onPressed: () => _delete(selected),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Recorded sleep dates: ${all.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result == null || !mounted) return;
    setState(() {
      _date = DateTime(result.year, result.month, result.day);
      _loadedSleepId = null;
      _sleepDuration.clear();
      _sleepNotes.clear();
      _error = null;
    });
  }

  void _syncSleepFields(TrackingEntry? entry) {
    if (entry == null || entry.id == _loadedSleepId) return;
    final entryId = entry.id;
    _loadedSleepId = entryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedSleepId != entryId) return;
      _sleepDuration.text = '${entry.payload['durationMinutes']}';
      _sleepNotes.text = (entry.payload['notes'] as String?) ?? '';
    });
  }

  Future<void> _saveSleep(TrackingEntry? existing) async {
    final duration = int.tryParse(_sleepDuration.text.trim());
    if (duration == null || duration < 1 || duration > 1440) {
      setState(() => _error = 'Enter a duration from 1 to 1440 minutes.');
      return;
    }
    setState(() {
      _savingSleep = true;
      _error = null;
    });
    try {
      await TrackingWorkflows(
        ref.read(trackingEntryRepositoryProvider),
      ).saveSleep(
        localDate: localDateKey(_date),
        durationMinutes: duration,
        notes: _sleepNotes.text.trim(),
        existing: existing,
      );
    } on DuplicateTrackingEntry {
      if (mounted) {
        setState(
          () => _error =
              'Sleep is already recorded for this wake-up date. Reload and edit it.',
        );
      }
    } on TrackingEntryValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'The sleep entry could not be saved locally.');
      }
    } finally {
      if (mounted) setState(() => _savingSleep = false);
    }
  }

  Future<void> _editWorkout(
    BuildContext context, [
    TrackingEntry? existing,
  ]) async {
    final result = await showDialog<_WorkoutDraft>(
      context: context,
      builder: (_) => _WorkoutEditor(existing: existing),
    );
    if (result == null || !mounted) return;
    try {
      await TrackingWorkflows(
        ref.read(trackingEntryRepositoryProvider),
      ).saveWorkout(
        localDate: localDateKey(_date),
        activity: result.activity,
        durationMinutes: result.duration,
        notes: result.notes,
        existing: existing,
      );
      setState(() => _error = null);
    } on TrackingEntryValidationFailure catch (error) {
      setState(() => _error = error.message);
    } on Object {
      setState(() => _error = 'The workout could not be saved locally.');
    }
  }

  Future<void> _delete(TrackingEntry entry) async {
    try {
      await TrackingWorkflows(
        ref.read(trackingEntryRepositoryProvider),
      ).delete(entry);
      if (mounted && entry.kind == TrackingEntryKind.sleep) {
        _loadedSleepId = null;
        _sleepDuration.clear();
        _sleepNotes.clear();
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'The record could not be deleted locally.');
      }
    }
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final TrackingEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        const Icon(Icons.fitness_center_outlined, color: AppColors.cyan),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.payload['activity'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${entry.payload['durationMinutes']} min · ${entry.localDate}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          key: Key('workout_edit_${entry.id}'),
          tooltip: 'Edit workout',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          key: Key('workout_delete_${entry.id}'),
          tooltip: 'Delete workout',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}

class _WorkoutDraft {
  const _WorkoutDraft(this.activity, this.duration, this.notes);
  final String activity;
  final int duration;
  final String notes;
}

class _WorkoutEditor extends StatefulWidget {
  const _WorkoutEditor({this.existing});
  final TrackingEntry? existing;
  @override
  State<_WorkoutEditor> createState() => _WorkoutEditorState();
}

class _WorkoutEditorState extends State<_WorkoutEditor> {
  late final _activity = TextEditingController(
    text: widget.existing?.payload['activity'] as String? ?? '',
  );
  late final _duration = TextEditingController(
    text: widget.existing == null
        ? ''
        : '${widget.existing!.payload['durationMinutes']}',
  );
  late final _notes = TextEditingController(
    text: widget.existing?.payload['notes'] as String? ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _activity.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Log workout' : 'Edit workout'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('workout_activity'),
            controller: _activity,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Activity'),
          ),
          TextField(
            key: const Key('workout_duration'),
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration in minutes (1–1440)',
            ),
          ),
          TextField(
            key: const Key('workout_notes'),
            controller: _notes,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('workout_save'),
        onPressed: _save,
        child: const Text('Save locally'),
      ),
    ],
  );

  void _save() {
    final duration = int.tryParse(_duration.text.trim());
    if (_activity.text.trim().isEmpty ||
        _activity.text.trim().length > 120 ||
        duration == null ||
        duration < 1 ||
        duration > 1440 ||
        _notes.text.length > 500) {
      setState(
        () =>
            _error = 'Enter an activity and a duration from 1 to 1440 minutes.',
      );
      return;
    }
    Navigator.pop(
      context,
      _WorkoutDraft(_activity.text.trim(), duration, _notes.text.trim()),
    );
  }
}

class _RecentWellnessSummary extends StatelessWidget {
  const _RecentWellnessSummary({
    required this.sleeps,
    required this.workouts,
    required this.ownerUid,
  });
  final AsyncValue<List<TrackingEntry>> sleeps;
  final AsyncValue<List<TrackingEntry>> workouts;
  final String? ownerUid;

  @override
  Widget build(BuildContext context) => sleeps.when(
    loading: () => const LoadingStateView(),
    error: (_, _) => const ErrorStateView(
      message: 'Recent wellness summaries could not be loaded.',
    ),
    data: (sleepEntries) => workouts.when(
      loading: () => const LoadingStateView(),
      error: (_, _) => const ErrorStateView(
        message: 'Recent wellness summaries could not be loaded.',
      ),
      data: (workoutEntries) {
        final cutoff = DateTime.now().subtract(const Duration(days: 6));
        final recentSleeps = _recent(
          sleepEntries.where((e) => e.ownerUid == ownerUid).toList(),
          cutoff,
        );
        final recentWorkouts = _recent(
          workoutEntries.where((e) => e.ownerUid == ownerUid).toList(),
          cutoff,
        );
        final avg = recentSleeps.isEmpty
            ? null
            : recentSleeps
                      .map((e) => e.payload['durationMinutes'] as int)
                      .reduce((a, b) => a + b) ~/
                  recentSleeps.length;
        final totalWorkoutMinutes = recentWorkouts.fold<int>(
          0,
          (sum, entry) => sum + (entry.payload['durationMinutes'] as int),
        );
        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 7 recorded days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                avg == null
                    ? 'Sleep: no entries recorded'
                    : 'Average sleep: $avg min (${recentSleeps.length} entries)',
              ),
              Text(
                'Workouts: ${recentWorkouts.length} · $totalWorkoutMinutes min',
              ),
            ],
          ),
        );
      },
    ),
  );
}

List<TrackingEntry> _recent(List<TrackingEntry> entries, DateTime cutoff) =>
    entries.where((entry) {
      final date = parseLocalDateKey(entry.localDate);
      return !date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day));
    }).toList();

class _LocalOnlyLabel extends StatelessWidget {
  const _LocalOnlyLabel();
  @override
  Widget build(BuildContext context) => const PrivacySourceLabel(
    source: PrivacySource.privateLocal,
    details: 'Cloud sync is off',
  );
}

String _dateLabel(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
