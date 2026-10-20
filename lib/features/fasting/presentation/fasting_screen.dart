import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/presentation/record_providers.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../../tracking/domain/tracking_workflows.dart';

class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen> {
  DateTime _date = DateTime.now();
  bool? _fasted;
  bool _statusChosen = false;
  final _notes = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      trackingEntriesProvider((TrackingEntryKind.fasting, null)),
    );
    final uid = ref.watch(currentUserIdentityProvider).currentUid;
    return Scaffold(
      appBar: AppBar(title: const Text('Fasting')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: entries.when(
              loading: () => const LoadingStateView(),
              error: (_, _) => ErrorStateView(
                message: 'Fasting records could not be loaded locally.',
                onRetry: () => ref.invalidate(
                  trackingEntriesProvider((TrackingEntryKind.fasting, null)),
                ),
              ),
              data: (allEntries) {
                final owned = allEntries
                    .where((entry) => entry.ownerUid == uid)
                    .toList();
                final selectedKey = localDateKey(_date);
                final current = owned
                    .where((entry) => entry.localDate == selectedKey)
                    .firstOrNull;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    const _LocalOnlyLabel(),
                    const SizedBox(height: AppSpacing.md),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily fast',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            key: const Key('fasting_date'),
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(_dateLabel(_date)),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (current == null && !_statusChosen)
                            const Text('No fasting record for this date yet.'),
                          if (current != null && !_statusChosen)
                            Text(
                              current.payload['status'] == 'fasted'
                                  ? 'Recorded: Fasted'
                                  : 'Recorded: Not fasted',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              ChoiceChip(
                                key: const Key('fasting_fasted'),
                                label: const Text('Fasted'),
                                selected: _statusChosen
                                    ? _fasted == true
                                    : current?.payload['status'] == 'fasted',
                                onSelected: (_) => setState(() {
                                  _fasted = true;
                                  _statusChosen = true;
                                }),
                              ),
                              ChoiceChip(
                                key: const Key('fasting_not_fasted'),
                                label: const Text('Not fasted'),
                                selected: _statusChosen
                                    ? _fasted == false
                                    : current?.payload['status'] == 'notFasted',
                                onSelected: (_) => setState(() {
                                  _fasted = false;
                                  _statusChosen = true;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            key: const Key('fasting_notes'),
                            controller: _notes,
                            maxLines: 2,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  key: const Key('fasting_save'),
                                  onPressed:
                                      _saving ||
                                          (!_statusChosen && current == null)
                                      ? null
                                      : () => _save(current),
                                  child: Text(
                                    _saving
                                        ? 'Saving…'
                                        : current == null
                                        ? 'Save record'
                                        : 'Update record',
                                  ),
                                ),
                              ),
                              if (current != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                IconButton(
                                  key: const Key('fasting_delete'),
                                  tooltip: 'Delete fasting record',
                                  onPressed: () => _delete(current),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (owned.isEmpty)
                      const EmptyStateView(
                        title: 'No fasting history',
                        message:
                            'Dates without a saved record remain unrecorded; they are not counted as missed fasts.',
                        icon: Icons.nights_stay_outlined,
                      )
                    else
                      for (final entry in owned)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Semantics(
                            button: true,
                            label:
                                '${entry.localDate}, ${entry.payload['status'] == 'fasted' ? 'Fasted' : 'Not fasted'}',
                            child: InkWell(
                              onTap: () => _selectEntry(entry),
                              child: SurfaceCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_note_outlined,
                                      color: AppColors.cyan,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        '${entry.localDate} · ${entry.payload['status'] == 'fasted' ? 'Fasted' : 'Not fasted'}',
                                      ),
                                    ),
                                    const Icon(Icons.edit_outlined),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

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
      _fasted = null;
      _statusChosen = false;
      _notes.clear();
      _error = null;
    });
  }

  void _selectEntry(TrackingEntry entry) {
    setState(() {
      _date = parseLocalDateKey(entry.localDate);
      _fasted = entry.payload['status'] == 'fasted';
      _statusChosen = false;
      _notes.text = (entry.payload['notes'] as String?) ?? '';
      _error = null;
    });
  }

  Future<void> _save(TrackingEntry? current) async {
    final chosen = _statusChosen
        ? _fasted
        : current?.payload['status'] == 'fasted';
    if (chosen == null) {
      setState(() => _error = 'Choose Fasted or Not fasted.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await TrackingWorkflows(
        ref.read(trackingEntryRepositoryProvider),
      ).saveFasting(
        localDate: localDateKey(_date),
        fasted: chosen,
        notes: _notes.text.trim(),
        existing: current,
      );
      if (mounted) setState(() => _statusChosen = false);
    } on DuplicateTrackingEntry {
      if (mounted) {
        setState(
          () => _error =
              'A record already exists for this date. Reload and edit it.',
        );
      }
    } on TrackingEntryValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _error = 'The fasting record could not be saved locally.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(TrackingEntry entry) async {
    try {
      await TrackingWorkflows(
        ref.read(trackingEntryRepositoryProvider),
      ).delete(entry);
      if (mounted) {
        setState(() {
          _fasted = null;
          _statusChosen = false;
          _notes.clear();
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'The record could not be deleted locally.');
      }
    }
  }
}

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
