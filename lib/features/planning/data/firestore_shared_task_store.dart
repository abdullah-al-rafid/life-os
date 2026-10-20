import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SharedTaskStatus { done, partial, notDone }

class SharedTask {
  const SharedTask({
    required this.id,
    required this.ownerUid,
    required this.assigneeUid,
    required this.title,
    required this.date,
    required this.priority,
    required this.durationMinutes,
    required this.deadline,
    required this.notes,
    required this.status,
    required this.revoked,
    this.updatedAt,
    this.pendingWrite = false,
    this.fromCache = false,
  });

  final String id, ownerUid, assigneeUid, title, date, notes;
  final int priority, durationMinutes;
  final String? deadline;
  final SharedTaskStatus status;
  final bool revoked;
  final Timestamp? updatedAt;

  /// True while this snapshot contains an unacknowledged Firestore write.
  final bool pendingWrite;

  /// Distinguishes an offline/cache snapshot from a server confirmed snapshot.
  final bool fromCache;

  factory SharedTask.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return SharedTask(
      id: snapshot.id,
      ownerUid: data['ownerUid'] as String,
      assigneeUid: data['assigneeUid'] as String,
      title: data['title'] as String,
      date: data['date'] as String,
      priority: data['priority'] as int,
      durationMinutes: data['durationMinutes'] as int,
      deadline: data['deadline'] as String?,
      notes: data['notes'] as String,
      status: SharedTaskStatus.values.byName(data['status'] as String),
      revoked: data['revoked'] as bool,
      updatedAt: data['updatedAt'] as Timestamp?,
      pendingWrite: snapshot.metadata.hasPendingWrites,
      fromCache: snapshot.metadata.isFromCache,
    );
  }
}

class SharedTaskIdempotencyConflict implements Exception {
  const SharedTaskIdempotencyConflict(this.documentId);

  final String documentId;

  @override
  String toString() =>
      'The idempotency key $documentId is already used for a different task.';
}

class SharedTaskUpdateConflict implements Exception {
  const SharedTaskUpdateConflict(this.documentId);

  final String documentId;

  @override
  String toString() =>
      'Task $documentId changed on another device. Refresh before updating it.';
}

/// Firestore projection for explicitly assigned tasks. Rules require trusted,
/// administrator-provisioned membership before any read or write succeeds.
class FirestoreSharedTaskStore {
  FirestoreSharedTaskStore({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<SharedTask>> watchForCurrentUser() {
    return Stream<List<SharedTask>>.multi((controller) {
      StreamSubscription<User?>? authSubscription;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? taskSubscription;
      var switches = Future<void>.value();

      authSubscription = _auth.userChanges().listen((user) {
        switches = switches.then((_) async {
          await taskSubscription?.cancel();
          taskSubscription = null;
          // Clear the previous account's projection before subscribing to
          // the new UID. Cached snapshots are marked and non-mutable below.
          controller.add(const []);
          final uid = user?.uid;
          if (uid == null) {
            controller.addError(StateError('Sign in to view assigned tasks.'));
            return;
          }
          final filter = Filter.or(
            Filter('ownerUid', isEqualTo: uid),
            Filter.and(
              Filter('assigneeUid', isEqualTo: uid),
              Filter('revoked', isEqualTo: false),
            ),
          );
          taskSubscription = _firestore
              .collection('sharedTasks')
              .where(filter)
              .snapshots(includeMetadataChanges: true)
              .listen((snapshot) {
                if (_auth.currentUser?.uid != uid) return;
                final tasks = snapshot.docs
                    .map(SharedTask.fromSnapshot)
                    .toList();
                tasks.sort((a, b) => a.date.compareTo(b.date));
                controller.add(tasks);
              }, onError: controller.addError);
        });
      }, onError: controller.addError);

      controller.onCancel = () async {
        await authSubscription?.cancel();
        await switches;
        await taskSubscription?.cancel();
      };
    });
  }

  Future<void> assignToTrustedPeer({
    required String expectedOwnerUid,
    required String idempotencyKey,
    required String title,
    required String date,
    required int priority,
    required int durationMinutes,
    required String? deadline,
    required String notes,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before assigning a task.');
    if (uid != expectedOwnerUid) {
      throw StateError('Account changed before assigning the task.');
    }
    final membership = await _firestore
        .collection('lifeOsMembers')
        .doc(uid)
        .get();
    final peerUid = membership.data()?['peerUid'];
    if (membership.data()?['active'] != true ||
        peerUid is! String ||
        peerUid.isEmpty ||
        peerUid == uid) {
      throw StateError('No administrator-verified task-sharing peer is set.');
    }
    if (currentUid != uid) {
      throw StateError(
        'Account changed while loading task-sharing membership.',
      );
    }
    await assign(
      idempotencyKey: idempotencyKey,
      assigneeUid: peerUid,
      title: title,
      date: date,
      priority: priority,
      durationMinutes: durationMinutes,
      deadline: deadline,
      notes: notes,
    );
  }

  Future<void> assign({
    String? idempotencyKey,
    required String assigneeUid,
    required String title,
    required String date,
    required int priority,
    required int durationMinutes,
    required String? deadline,
    required String notes,
  }) async {
    final ownerUid = currentUid;
    if (ownerUid == null) throw StateError('Sign in before assigning a task.');
    if (assigneeUid.isEmpty || assigneeUid == ownerUid) {
      throw ArgumentError('Choose the other verified LIFE OS member.');
    }
    final createdByUid = ownerUid;
    final documentId = idempotencyKey == null
        ? null
        : sha256
              .convert(utf8.encode('$ownerUid\u0000$idempotencyKey'))
              .toString();
    final payload = <String, Object?>{
      'ownerUid': ownerUid,
      'assigneeUid': assigneeUid,
      'title': title.trim(),
      'date': date,
      'priority': priority,
      'durationMinutes': durationMinutes,
      'deadline': deadline,
      'notes': notes.trim(),
      'status': SharedTaskStatus.notDone.name,
      'revoked': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (documentId == null) {
      await _firestore.collection('sharedTasks').add(payload);
    } else {
      final reference = _firestore.collection('sharedTasks').doc(documentId);
      await _firestore.runTransaction<void>((transaction) async {
        if (_auth.currentUser?.uid != createdByUid) {
          throw StateError('Account changed while assigning the task.');
        }
        final existing = await transaction.get(reference);
        if (existing.exists) {
          final data = existing.data()!;
          final sameAssignment =
              data['ownerUid'] == ownerUid &&
              data['assigneeUid'] == assigneeUid &&
              data['title'] == payload['title'] &&
              data['date'] == date &&
              data['priority'] == priority &&
              data['durationMinutes'] == durationMinutes &&
              data['deadline'] == deadline &&
              data['notes'] == payload['notes'];
          if (!sameAssignment) {
            throw SharedTaskIdempotencyConflict(documentId);
          }
          return;
        }
        transaction.set(reference, payload);
      });
    }
    if (_auth.currentUser?.uid != createdByUid) {
      throw StateError('Account changed while assigning the task.');
    }
  }

  Future<void> updateStatus(SharedTask task, SharedTaskStatus status) async {
    final uid = currentUid;
    if (task.assigneeUid != uid || task.revoked) {
      throw StateError('Only the assigned member can update this task status.');
    }
    final expectedUpdatedAt = task.updatedAt;
    if (expectedUpdatedAt == null) {
      throw StateError('Refresh the task before changing its status.');
    }
    final reference = _firestore.collection('sharedTasks').doc(task.id);
    await _firestore.runTransaction<void>((transaction) async {
      if (_auth.currentUser?.uid != uid) {
        throw StateError('Account changed while updating task status.');
      }
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null ||
          data['assigneeUid'] != uid ||
          data['revoked'] != false) {
        throw StateError('This task is no longer available to update.');
      }
      if (data['status'] == status.name) return;
      final currentUpdatedAt = data['updatedAt'];
      if (currentUpdatedAt is! Timestamp ||
          currentUpdatedAt.seconds != expectedUpdatedAt.seconds ||
          currentUpdatedAt.nanoseconds != expectedUpdatedAt.nanoseconds) {
        throw SharedTaskUpdateConflict(task.id);
      }
      transaction.update(reference, {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    if (_auth.currentUser?.uid != uid) {
      throw StateError('Account changed while updating task status.');
    }
  }

  /// Owner-only, tombstone-style access revocation. Assignment fields and task
  /// history remain unchanged; Firestore rules enforce the same boundary.
  Future<void> revoke(SharedTask task) async {
    final uid = currentUid;
    if (uid == null || task.ownerUid != uid || task.revoked) {
      throw StateError('Only the task owner can revoke sharing.');
    }
    final reference = _firestore.collection('sharedTasks').doc(task.id);
    await _firestore.runTransaction<void>((transaction) async {
      if (_auth.currentUser?.uid != uid) {
        throw StateError('Account changed while revoking task sharing.');
      }
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null || data['ownerUid'] != uid) {
        throw StateError('This task is no longer owned by this account.');
      }
      if (data['revoked'] == true) return;
      transaction.update(reference, {
        'revoked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    if (_auth.currentUser?.uid != uid) {
      throw StateError('Account changed while revoking task sharing.');
    }
  }
}
