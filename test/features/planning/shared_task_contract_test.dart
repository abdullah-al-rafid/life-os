import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/planning/data/firestore_shared_task_store.dart';

void main() {
  test('shared task snapshot parsing preserves remote lifecycle metadata', () {
    // Metadata is supplied by Firestore snapshots; the value object defaults
    // stay explicit for tests and local UI projections.
    const task = SharedTask(
      id: 'remote-1',
      ownerUid: 'owner',
      assigneeUid: 'assignee',
      title: 'Review',
      date: '2026-10-15',
      priority: 1,
      durationMinutes: 30,
      deadline: null,
      notes: '',
      status: SharedTaskStatus.notDone,
      revoked: false,
    );
    expect(task.pendingWrite, isFalse);
    expect(task.fromCache, isFalse);
    expect(task.revoked, isFalse);
  });

  test('remote task projection does not expose local completion data', () {
    const allowed = {
      'ownerUid',
      'assigneeUid',
      'title',
      'date',
      'priority',
      'durationMinutes',
      'deadline',
      'notes',
      'status',
      'revoked',
      'createdAt',
      'updatedAt',
    };
    expect(allowed, isNot(contains('completionEvidence')));
    expect(allowed, isNot(contains('privateRecord')));
    expect(allowed.length, 12);
  });
}
