import 'dart:convert';
import 'dart:math';

import '../../records/domain/life_record.dart';
import 'tracking_entry.dart';
import 'tracking_entry_repository.dart';

String localDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime parseLocalDateKey(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const TrackingEntryValidationFailure('Invalid local date.');
  }
  final parts = value.split('-').map(int.parse).toList();
  final date = DateTime(parts[0], parts[1], parts[2]);
  if (localDateKey(date) != value) {
    throw const TrackingEntryValidationFailure('Invalid local date.');
  }
  return date;
}

/// Creates private local-only records through the UID-bound repository.
class TrackingWorkflows {
  TrackingWorkflows(this.repository);
  final OfflineTrackingEntryRepository repository;

  Future<TrackingEntry> saveFasting({
    required String localDate,
    required bool fasted,
    String notes = '',
    TrackingEntry? existing,
  }) => _save(
    kind: TrackingEntryKind.fasting,
    localDate: localDate,
    payload: {'status': fasted ? 'fasted' : 'notFasted', 'notes': notes},
    existing: existing,
  );

  Future<TrackingEntry> saveSleep({
    required String localDate,
    required int durationMinutes,
    String notes = '',
    TrackingEntry? existing,
  }) => _save(
    kind: TrackingEntryKind.sleep,
    localDate: localDate,
    payload: {'durationMinutes': durationMinutes, 'notes': notes},
    existing: existing,
  );

  Future<TrackingEntry> saveWorkout({
    required String localDate,
    required String activity,
    required int durationMinutes,
    String notes = '',
    TrackingEntry? existing,
  }) => _save(
    kind: TrackingEntryKind.workout,
    localDate: localDate,
    payload: {
      'activity': activity.trim(),
      'durationMinutes': durationMinutes,
      'notes': notes,
    },
    existing: existing,
  );

  Future<TrackingEntry> _save({
    required TrackingEntryKind kind,
    required String localDate,
    required Map<String, Object?> payload,
    TrackingEntry? existing,
  }) async {
    parseLocalDateKey(localDate);
    if (existing != null) {
      if (existing.kind != kind || existing.localDate != localDate) {
        throw const TrackingEntryValidationFailure(
          'An entry cannot be moved to a different kind or date.',
        );
      }
      return repository.update(
        id: existing.id,
        expectedRevision: existing.revision,
        payload: payload,
      );
    }
    final uid = repository.identity.currentUid;
    if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
      throw const UnauthenticatedOperation();
    }
    final now = DateTime.now().toUtc();
    return repository.create(
      TrackingEntry(
        id: _newEntryId(),
        ownerUid: uid,
        kind: kind,
        localDate: localDate,
        entryKey: kind == TrackingEntryKind.workout ? _newEntryId() : 'daily',
        visibility: RecordVisibility.private,
        payloadJson: jsonEncode(payload),
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
  }

  Future<void> delete(TrackingEntry entry) => repository.delete(
    id: entry.id,
    expectedRevision: entry.revision,
    atUtc: DateTime.now().toUtc(),
  );
}

String _newEntryId() {
  final random = Random.secure();
  return '${DateTime.now().microsecondsSinceEpoch}-'
      '${random.nextInt(1 << 32).toRadixString(16)}';
}
