import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../data/firestore_shared_task_store.dart';
import '../data/shared_task_assignment_outbox.dart';
import '../../records/domain/life_record.dart';
import '../../records/presentation/record_providers.dart';
import '../domain/planning_repository.dart';

const _remoteTaskSharingEnabled = bool.fromEnvironment(
  'LIFE_OS_ENABLE_SHARED_TASKS',
  defaultValue: false,
);

class SharedTasksScreen extends ConsumerStatefulWidget {
  const SharedTasksScreen({this.togetherView = false, super.key});

  final bool togetherView;

  @override
  ConsumerState<SharedTasksScreen> createState() => _SharedTasksScreenState();
}

class _SharedTasksScreenState extends ConsumerState<SharedTasksScreen> {
  late final FirestoreSharedTaskStore _store = FirestoreSharedTaskStore();
  bool _busy = false;
  bool _outboxReady = !_remoteTaskSharingEnabled;
  String? _message;
  _SharedTaskDraft? _pendingAssignment;
  StreamSubscription<String?>? _uidSubscription;
  String? _observedUid;

  bool get _enabled => _remoteTaskSharingEnabled;

  @override
  void initState() {
    super.initState();
    final identity = ref.read(currentUserIdentityProvider);
    _observedUid = identity.currentUid;
    _uidSubscription = identity.uidChanges.listen(_handleUidChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restorePending());
  }

  @override
  void dispose() {
    unawaited(_uidSubscription?.cancel());
    super.dispose();
  }

  void _handleUidChange(String? uid) {
    if (!mounted || uid == _observedUid) return;
    _observedUid = uid;
    setState(() {
      _pendingAssignment = null;
      _message = null;
      _outboxReady = uid == null || !_enabled;
    });
    if (uid != null) unawaited(_restorePending());
  }

  Future<void> _restorePending() async {
    if (!_enabled) {
      _outboxReady = true;
      return;
    }
    final uid = ref.read(currentUserIdentityProvider).currentUid;
    if (uid == null) {
      if (mounted) setState(() => _outboxReady = true);
      return;
    }
    if (mounted) setState(() => _outboxReady = false);
    try {
      final pending = await ref
          .read(sharedTaskAssignmentOutboxProvider)
          .pendingFor(uid);
      if (!mounted || ref.read(currentUserIdentityProvider).currentUid != uid) {
        return;
      }
      setState(() {
        _pendingAssignment = pending == null
            ? null
            : _SharedTaskDraft.fromPending(pending);
        _outboxReady = true;
      });
    } on Object {
      if (mounted && ref.read(currentUserIdentityProvider).currentUid == uid) {
        setState(() {
          _message = 'Pending assignment could not be loaded from this device.';
          _outboxReady = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTogether = widget.togetherView;
    return Scaffold(
      body: AppPageScaffold(
        title: isTogether ? 'Together' : 'Assigned tasks',
        subtitle:
            'Only explicitly assigned tasks are remote. Personal records remain private on this device.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrivacySourceLabel(
              source: _enabled
                  ? PrivacySource.shared
                  : PrivacySource.unavailable,
              details: _enabled ? 'assigned tasks only' : 'sharing is disabled',
            ),
            const SizedBox(height: AppSpacing.md),
            _sharedGoals(),
            const SizedBox(height: AppSpacing.lg),
            const PageHeader(
              title: 'Assigned tasks',
              subtitle: 'Explicit task assignments use a separate remote gate.',
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!_enabled) const _SharingSetupCard() else _taskList(context),
          ],
        ),
      ),
      floatingActionButton: _enabled
          ? FloatingActionButton.extended(
              onPressed: _busy || !_outboxReady ? null : _create,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(
                _pendingAssignment == null ? 'Assign task' : 'Retry assignment',
              ),
            )
          : null,
    );
  }

  Widget _sharedGoals() {
    final goals = ref.watch(planningItemsProvider(PlanningKind.goal));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Shared goals & contributions',
          subtitle:
              'Only goals explicitly marked shared appear here. Contributions keep their author and history.',
          actions: [
            FilledButton.tonalIcon(
              key: const Key('together_create_shared_goal'),
              onPressed: _createSharedGoal,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Create shared goal'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const PrivacySourceLabel(
          source: PrivacySource.localOnly,
          details: 'shared on this device only · not synced',
        ),
        if (_message case final message?) ...[
          const SizedBox(height: AppSpacing.sm),
          SurfaceCard(child: Text(message)),
        ],
        const SizedBox(height: AppSpacing.md),
        goals.when(
          loading: () => const LoadingStateView(),
          error: (_, _) => const ErrorStateView(
            message: 'Local shared goals could not be loaded.',
          ),
          data: (items) {
            final shared = items
                .where((item) => item.visibility == RecordVisibility.shared)
                .toList(growable: false);
            if (shared.isEmpty) {
              return const EmptyStateView(
                icon: Icons.flag_outlined,
                title: 'No shared goals yet',
                message:
                    'Personal goals remain private. Create a shared goal here or explicitly share one from Goals.',
              );
            }
            return Column(
              children: [
                for (final goal in shared)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TogetherGoalCard(goal: goal),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createSharedGoal() async {
    final draft = await showDialog<_SharedGoalDraft>(
      context: context,
      builder: (_) => const _SharedGoalDialog(),
    );
    if (draft == null || !mounted) return;
    try {
      await ref
          .read(planningRepositoryProvider)
          .save(
            kind: PlanningKind.goal,
            title: draft.title,
            description: draft.description,
            targetValue: draft.target,
            targetUnit: draft.unit,
            startDate: draft.startDate,
            targetDate: draft.deadline,
            visibility: RecordVisibility.shared,
          );
    } on PlanningValidationFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _message = 'The shared goal could not be saved locally.',
        );
      }
    }
  }

  Widget _taskList(BuildContext context) {
    final uid = ref.watch(currentUserIdentityProvider).currentUid;
    if (uid == null) {
      return const ErrorStateView(message: 'Sign in to use assigned tasks.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_message case final message?) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (_pendingAssignment != null)
                  TextButton(
                    onPressed: _busy ? null : _discardPending,
                    child: const Text('Discard retry and create another task'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        StreamBuilder<List<SharedTask>>(
          stream: _store.watchForCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SurfaceCard(
                child: Text(
                  'Assigned tasks are unavailable. Confirm administrator membership and deployed Firestore Rules. ${snapshot.error}',
                ),
              );
            }
            if (!snapshot.hasData) return const LoadingStateView();
            final tasks = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tasks.any((task) => task.fromCache))
                  const SurfaceCard(
                    child: Text(
                      'Showing a cached task snapshot. Current server state, including revocation, is not confirmed while offline.',
                    ),
                  ),
                if (tasks.isEmpty)
                  const EmptyStateView(
                    title: 'No assigned tasks yet',
                    message:
                        'Tasks assigned by the other LIFE OS account will appear here.',
                    icon: Icons.assignment_outlined,
                  )
                else
                  for (final task in tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SharedTaskCard(
                        task: task,
                        assignedToMe: task.assigneeUid == uid,
                        ownedByMe: task.ownerUid == uid,
                        onStatusChanged: (status) => _setStatus(task, status),
                        onRevoke: () => _revoke(task),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _create() async {
    final ownerUid = ref.read(currentUserIdentityProvider).currentUid;
    if (ownerUid == null) {
      setState(() => _message = 'Sign in before assigning a task.');
      return;
    }
    if (_pendingAssignment != null &&
        _pendingAssignment!.ownerUid != ownerUid) {
      setState(() {
        _pendingAssignment = null;
        _outboxReady = false;
      });
      await _restorePending();
      return;
    }
    final draft =
        _pendingAssignment ??
        await showDialog<_SharedTaskDraft>(
          context: context,
          builder: (_) => _SharedTaskDialog(
            ownerUid: ownerUid,
            idempotencyKey: _newIdempotencyKey(),
          ),
        );
    if (draft == null || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
      _pendingAssignment = draft;
    });
    try {
      final pending = draft.toPending();
      await ref.read(sharedTaskAssignmentOutboxProvider).save(pending);
      await _store.assignToTrustedPeer(
        expectedOwnerUid: draft.ownerUid,
        idempotencyKey: draft.idempotencyKey,
        title: draft.title,
        date: draft.date,
        priority: draft.priority,
        durationMinutes: draft.minutes,
        deadline: draft.deadline,
        notes: draft.notes,
      );
      await ref.read(sharedTaskAssignmentOutboxProvider).remove(pending);
      if (mounted) {
        setState(() {
          _pendingAssignment = null;
          _message = 'Task assigned and synced.';
        });
      }
    } on SharedTaskIdempotencyConflict {
      if (mounted) {
        setState(
          () => _message =
              'This retry key belongs to a different task. The saved assignment was left unchanged. Discard this retry before starting another task.',
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Task was not confirmed. Retry this same assignment to safely check whether it was saved, or discard the retry to start another task.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(SharedTask task, SharedTaskStatus status) async {
    try {
      await _store.updateStatus(task, status);
    } on SharedTaskUpdateConflict {
      if (mounted) {
        setState(
          () => _message =
              'This task changed on another device. The latest server version is loading; review it before trying again.',
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Status update did not sync. Your previous status remains.',
        );
      }
    }
  }

  Future<void> _discardPending() async {
    final draft = _pendingAssignment;
    if (draft == null) return;
    try {
      await ref
          .read(sharedTaskAssignmentOutboxProvider)
          .remove(draft.toPending());
      if (mounted) {
        setState(() {
          _pendingAssignment = null;
          _message = null;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _message = 'The pending retry could not be discarded.');
      }
    }
  }

  Future<void> _revoke(SharedTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke task sharing?'),
        content: const Text(
          'The other member will lose access to this task. Its assignment history will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep shared'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke sharing'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _store.revoke(task);
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'Sharing could not be revoked on the server. Check the connection and try again.',
        );
      }
    }
  }
}

class _TogetherGoalCard extends ConsumerWidget {
  const _TogetherGoalCard({required this.goal});
  final PlanningItem goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(planningHistoryProvider(goal.id));
    final uid = ref.watch(currentUserIdentityProvider).currentUid;
    return history.when(
      loading: () => const LoadingStateView(),
      error: (_, _) => const ErrorStateView(
        message: 'Contribution history could not be loaded.',
      ),
      data: (entries) {
        final contributions = entries
            .where((entry) => entry.kind == 'goalProgress')
            .map(GoalContribution.fromHistory)
            .toList(growable: false);
        final summary = GoalProgressSummary.fromHistory(goal, entries);
        final target = goal.targetValue ?? 0;
        return TaskCard(
          title: goal.title,
          subtitle: goal.description.isEmpty ? null : goal.description,
          details:
              'Started ${goal.startDate}${goal.targetDate == null ? '' : ' · Deadline ${goal.targetDate}'}',
          source: PrivacySource.localOnly,
          sourceDetails: 'shared locally · not synced',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressIndicatorCard(
                label: 'Status: ${summary.status}',
                value: summary.total,
                total: target,
                trailing: '${summary.total} / $target ${goal.targetUnit}',
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                key: Key('contribute_${goal.id}'),
                onPressed: summary.completed
                    ? null
                    : () => _addContribution(context, ref, goal),
                icon: const Icon(Icons.add_chart),
                label: const Text('Add contribution'),
              ),
              if (contributions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                for (final contribution in contributions.take(10))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${contribution.amount} ${goal.targetUnit} · ${contribution.authorUid == uid ? 'You' : 'Other local account'}',
                    ),
                    subtitle: Text(
                      contribution.notes.isEmpty
                          ? contribution.date
                          : '${contribution.date} · ${contribution.notes}',
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addContribution(
    BuildContext context,
    WidgetRef ref,
    PlanningItem goal,
  ) async {
    final draft = await showDialog<_ContributionDraft>(
      context: context,
      builder: (_) => _ContributionDialog(unit: goal.targetUnit),
    );
    if (draft == null || !context.mounted) return;
    try {
      await ref
          .read(planningRepositoryProvider)
          .addGoalProgress(
            goal,
            DateTime.now(),
            draft.amount,
            notes: draft.notes,
          );
    } on PlanningValidationFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution could not be saved.')),
        );
      }
    }
  }
}

class _SharedGoalDraft {
  const _SharedGoalDraft(
    this.title,
    this.description,
    this.target,
    this.unit,
    this.startDate,
    this.deadline,
  );
  final String title, description, unit, startDate;
  final double target;
  final String? deadline;
}

class _SharedGoalDialog extends StatefulWidget {
  const _SharedGoalDialog();
  @override
  State<_SharedGoalDialog> createState() => _SharedGoalDialogState();
}

class _SharedGoalDialogState extends State<_SharedGoalDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();
  final _unit = TextEditingController();
  final _start = TextEditingController(text: _today());
  final _deadline = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    _unit.dispose();
    _start.dispose();
    _deadline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create a local shared goal'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Goal title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title.'
                    : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _target,
                decoration: const InputDecoration(labelText: 'Target amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  return number != null && number.isFinite && number > 0
                      ? null
                      : 'Enter a positive target.';
                },
              ),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a unit (for example books or km).'
                    : null,
              ),
              TextFormField(
                controller: _start,
                decoration: const InputDecoration(
                  labelText: 'Start date (YYYY-MM-DD)',
                ),
                validator: _dateValidator,
              ),
              TextFormField(
                controller: _deadline,
                decoration: const InputDecoration(
                  labelText: 'Deadline (optional, YYYY-MM-DD)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final issue = _dateValidator(value);
                  if (issue != null) return issue;
                  return value.trim().compareTo(_start.text.trim()) < 0
                      ? 'Deadline must be on or after the start date.'
                      : null;
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Saved on this device only. It is not sent to Firebase.',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            _SharedGoalDraft(
              _title.text.trim(),
              _description.text.trim(),
              double.parse(_target.text),
              _unit.text.trim(),
              _start.text.trim(),
              _deadline.text.trim().isEmpty ? null : _deadline.text.trim(),
            ),
          );
        },
        child: const Text('Save shared goal'),
      ),
    ],
  );
}

class _ContributionDraft {
  const _ContributionDraft(this.amount, this.notes);
  final double amount;
  final String notes;
}

class _ContributionDialog extends StatefulWidget {
  const _ContributionDialog({required this.unit});
  final String unit;
  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add contribution'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount (${widget.unit})'),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              return amount != null && amount.isFinite && amount > 0
                  ? null
                  : 'Enter a positive amount.';
            },
          ),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 2,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            _ContributionDraft(double.parse(_amount.text), _notes.text.trim()),
          );
        },
        child: const Text('Add contribution'),
      ),
    ],
  );
}

class _SharingSetupCard extends StatelessWidget {
  const _SharingSetupCard();

  @override
  Widget build(BuildContext context) => const SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remote task sharing is off',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Before enabling it, a trusted Firebase administrator must verify both Auth UIDs and create reciprocal active lifeOsMembers records for those accounts. Email addresses are not used as authorization.',
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Identity verification, production memberships, and deployed rules have not been verified. This task projection also has no offline retry queue or conflict handling. Keep sharing off until the rules and membership are reviewed and production use is separately approved. Never enter a UID here; the recipient is read from the signed-in account’s protected membership.',
        ),
      ],
    ),
  );
}

class _SharedTaskCard extends StatelessWidget {
  const _SharedTaskCard({
    required this.task,
    required this.assignedToMe,
    required this.ownedByMe,
    required this.onStatusChanged,
    required this.onRevoke,
  });
  final SharedTask task;
  final bool assignedToMe;
  final bool ownedByMe;
  final ValueChanged<SharedTaskStatus> onStatusChanged;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) => TaskCard(
    title: task.title,
    subtitle:
        'Due ${task.date} · ${_priorityLabel(task.priority)} · ${task.durationMinutes} min${task.deadline == null ? '' : ' · Deadline ${task.deadline}'}',
    details: task.notes.isEmpty ? null : task.notes,
    source: PrivacySource.shared,
    sourceDetails: task.fromCache
        ? 'cached · server state unconfirmed'
        : task.pendingWrite
        ? 'write pending'
        : 'server confirmed',
    content: ownedByMe && !task.revoked
        ? Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: task.fromCache || task.pendingWrite ? null : onRevoke,
              icon: const Icon(Icons.link_off),
              label: const Text('Revoke sharing'),
            ),
          )
        : task.revoked
        ? const Text('Sharing revoked')
        : null,
    status: TaskVisualStatus.values.byName(task.status.name),
    statusEnabled:
        assignedToMe && !task.fromCache && !task.pendingWrite && !task.revoked,
    onStatusChanged:
        assignedToMe && !task.fromCache && !task.pendingWrite && !task.revoked
        ? (status) =>
              onStatusChanged(SharedTaskStatus.values.byName(status.name))
        : null,
  );
}

class _SharedTaskDraft {
  const _SharedTaskDraft(
    this.ownerUid,
    this.idempotencyKey,
    this.title,
    this.date,
    this.priority,
    this.minutes,
    this.deadline,
    this.notes,
  );
  final String ownerUid, idempotencyKey;
  final String title, date, notes;
  final int priority, minutes;
  final String? deadline;

  factory _SharedTaskDraft.fromPending(PendingSharedTaskAssignment pending) =>
      _SharedTaskDraft(
        pending.ownerUid,
        pending.idempotencyKey,
        pending.title,
        pending.date,
        pending.priority,
        pending.durationMinutes,
        pending.deadline,
        pending.notes,
      );

  PendingSharedTaskAssignment toPending() => PendingSharedTaskAssignment(
    ownerUid: ownerUid,
    idempotencyKey: idempotencyKey,
    title: title,
    date: date,
    priority: priority,
    durationMinutes: minutes,
    deadline: deadline,
    notes: notes,
  );
}

class _SharedTaskDialog extends StatefulWidget {
  const _SharedTaskDialog({
    required this.ownerUid,
    required this.idempotencyKey,
  });
  final String ownerUid, idempotencyKey;
  @override
  State<_SharedTaskDialog> createState() => _SharedTaskDialogState();
}

class _SharedTaskDialogState extends State<_SharedTaskDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _date = TextEditingController(text: _today());
  final _minutes = TextEditingController(text: '30');
  final _deadline = TextEditingController();
  final _notes = TextEditingController();
  int _priority = 2;

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _minutes.dispose();
    _deadline.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Assign a task'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Task title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a title.' : null,
              ),
              TextFormField(
                controller: _date,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
                validator: _dateValidator,
              ),
              DropdownButtonFormField<int>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Normal')),
                  DropdownMenuItem(value: 3, child: Text('Low')),
                ],
                onChanged: (value) => setState(() => _priority = value ?? 2),
              ),
              TextFormField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n != null && n > 0 && n <= 1440
                      ? null
                      : 'Enter 1–1440 minutes.';
                },
              ),
              TextFormField(
                controller: _deadline,
                decoration: const InputDecoration(
                  labelText: 'Deadline (optional, YYYY-MM-DD)',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? null : _dateValidator(v),
              ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            _SharedTaskDraft(
              widget.ownerUid,
              widget.idempotencyKey,
              _title.text.trim(),
              _date.text.trim(),
              _priority,
              int.parse(_minutes.text),
              _deadline.text.trim().isEmpty ? null : _deadline.text.trim(),
              _notes.text.trim(),
            ),
          );
        },
        child: const Text('Assign'),
      ),
    ],
  );
}

String _newIdempotencyKey() {
  final random = math.Random.secure();
  return List<int>.generate(
    32,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String? _dateValidator(String? value) =>
    value != null && _isValidDate(value.trim())
    ? null
    : 'Use a valid YYYY-MM-DD date.';

bool _isValidDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parts = value.split('-').map(int.parse).toList(growable: false);
  final date = DateTime(parts[0], parts[1], parts[2]);
  return date.year == parts[0] &&
      date.month == parts[1] &&
      date.day == parts[2];
}

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _priorityLabel(int value) => switch (value) {
  1 => 'High',
  3 => 'Low',
  _ => 'Normal',
};
