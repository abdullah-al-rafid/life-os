import 'dart:convert';

import '../../records/domain/life_record.dart';

enum TrackingEntryKind { prayer, fasting, sleep, workout }

class TrackingEntry {
  const TrackingEntry({
    required this.id,
    required this.ownerUid,
    required this.kind,
    required this.localDate,
    required this.entryKey,
    required this.visibility,
    required this.payloadJson,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.revision = 1,
    this.deletedAtUtc,
  });

  final String id;
  final String ownerUid;
  final TrackingEntryKind kind;
  final String localDate;
  final String entryKey;
  final RecordVisibility visibility;
  final String payloadJson;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final int revision;
  final DateTime? deletedAtUtc;

  Map<String, dynamic> get payload =>
      jsonDecode(payloadJson) as Map<String, dynamic>;

  TrackingEntry copyWith({
    String? payloadJson,
    RecordVisibility? visibility,
    DateTime? updatedAtUtc,
    int? revision,
    DateTime? deletedAtUtc,
    bool clearDeletedAt = false,
  }) => TrackingEntry(
    id: id,
    ownerUid: ownerUid,
    kind: kind,
    localDate: localDate,
    entryKey: entryKey,
    visibility: visibility ?? this.visibility,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    revision: revision ?? this.revision,
    deletedAtUtc: clearDeletedAt ? null : deletedAtUtc ?? this.deletedAtUtc,
  );
}

class TrackingEntryValidationFailure implements Exception {
  const TrackingEntryValidationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class DuplicateTrackingEntry implements Exception {
  const DuplicateTrackingEntry();
  @override
  String toString() =>
      'A matching tracking entry already exists for this date.';
}

class TrackingEntryNotFound implements Exception {
  const TrackingEntryNotFound();
  @override
  String toString() => 'The tracking entry is unavailable.';
}

class DeletedTrackingEntryMutation implements Exception {
  const DeletedTrackingEntryMutation();
  @override
  String toString() =>
      'A deleted tracking entry cannot be restored implicitly.';
}

class StaleTrackingEntryRevision implements Exception {
  const StaleTrackingEntryRevision();
  @override
  String toString() => 'This entry changed. Reload it before saving again.';
}

void validateTrackingEntry(TrackingEntry entry) {
  _requireTrimmed(entry.id, 'id');
  _requireTrimmed(entry.ownerUid, 'ownerUid');
  _requireTrimmed(entry.entryKey, 'entryKey');
  if (!_validDate(entry.localDate)) {
    throw const TrackingEntryValidationFailure(
      'localDate must be a real date in YYYY-MM-DD format.',
    );
  }
  if (entry.revision < 1) {
    throw const TrackingEntryValidationFailure('Revision must be at least 1.');
  }
  if (!entry.createdAtUtc.isUtc || !entry.updatedAtUtc.isUtc) {
    throw const TrackingEntryValidationFailure(
      'Tracking timestamps must be UTC.',
    );
  }
  if (entry.updatedAtUtc.isBefore(entry.createdAtUtc)) {
    throw const TrackingEntryValidationFailure(
      'updatedAtUtc cannot be earlier than createdAtUtc.',
    );
  }
  if (entry.deletedAtUtc != null &&
      (!entry.deletedAtUtc!.isUtc ||
          entry.deletedAtUtc!.isBefore(entry.updatedAtUtc))) {
    throw const TrackingEntryValidationFailure(
      'deletedAtUtc must be UTC and cannot be earlier than updatedAtUtc.',
    );
  }

  final Map<String, dynamic> payload;
  try {
    final decoded = jsonDecode(entry.payloadJson);
    if (decoded is! Map<String, dynamic>) {
      throw const TrackingEntryValidationFailure(
        'Tracking payload must be a JSON object.',
      );
    }
    payload = decoded;
  } on FormatException {
    throw const TrackingEntryValidationFailure(
      'Tracking payload must be valid JSON.',
    );
  }

  switch (entry.kind) {
    case TrackingEntryKind.prayer:
      if (!const {
        'prayedOnTime',
        'prayedLate',
        'missed',
      }.contains(payload['status'])) {
        throw const TrackingEntryValidationFailure(
          'Prayer status must be prayedOnTime, prayedLate, or missed.',
        );
      }
      if (!const {
        'Fajr',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      }.contains(entry.entryKey)) {
        throw const TrackingEntryValidationFailure(
          'Prayer entryKey must name one of the five daily prayers.',
        );
      }
      _optionalString(payload, 'notes');
      final jamaatStatus = payload['jamaatStatus'];
      if (jamaatStatus != null &&
          !const {'jamaat', 'individual', 'unknown'}.contains(jamaatStatus)) {
        throw const TrackingEntryValidationFailure(
          'Jamaat status must be jamaat, individual, or unknown.',
        );
      }
      _validatePrayerSnapshot(payload['scheduleSnapshot']);
      break;
    case TrackingEntryKind.fasting:
      if (entry.entryKey != 'daily' ||
          !const {'fasted', 'notFasted'}.contains(payload['status'])) {
        throw const TrackingEntryValidationFailure(
          'Fasting entries need the daily key and a fasted/notFasted status.',
        );
      }
      _optionalString(payload, 'notes');
      break;
    case TrackingEntryKind.sleep:
      if (entry.entryKey != 'daily') {
        throw const TrackingEntryValidationFailure(
          'Sleep entries must use the daily key.',
        );
      }
      final duration = payload['durationMinutes'];
      if (duration is! int || duration < 1 || duration > 1440) {
        throw const TrackingEntryValidationFailure(
          'Sleep duration must be between 1 and 1440 minutes.',
        );
      }
      _optionalString(payload, 'notes');
      break;
    case TrackingEntryKind.workout:
      _requireTrimmed(payload['activity'], 'activity');
      final duration = payload['durationMinutes'];
      if (duration is! int || duration < 1 || duration > 1440) {
        throw const TrackingEntryValidationFailure(
          'Workout duration must be between 1 and 1440 minutes.',
        );
      }
      _optionalString(payload, 'notes');
      break;
  }
}

void _validatePrayerSnapshot(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const TrackingEntryValidationFailure(
      'Prayer entries need a schedule snapshot.',
    );
  }
  final azan = value['azanMinute'];
  final jamaat = value['jamaatMinute'];
  final timezoneId = value['timezoneId'];
  if (azan is! int ||
      jamaat is! int ||
      azan < 0 ||
      azan >= 1440 ||
      jamaat <= azan ||
      jamaat >= 1440 ||
      timezoneId is! String ||
      timezoneId.trim().isEmpty ||
      timezoneId != timezoneId.trim() ||
      !RegExp(
        r'^(?:UTC|GMT|[A-Za-z][A-Za-z0-9_+-]*(?:/[A-Za-z0-9_+-]+)+)$',
      ).hasMatch(timezoneId)) {
    throw const TrackingEntryValidationFailure(
      'Prayer schedule snapshot must have valid times and a timezone ID.',
    );
  }
}

void _optionalString(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value != null && value is! String) {
    throw TrackingEntryValidationFailure('$key must be text when supplied.');
  }
}

void _requireTrimmed(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw TrackingEntryValidationFailure(
      '$field must be non-empty trimmed text.',
    );
  }
}

bool _validDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parts = value.split('-').map(int.parse).toList();
  final date = DateTime(parts[0], parts[1], parts[2]);
  return date.year == parts[0] &&
      date.month == parts[1] &&
      date.day == parts[2];
}
