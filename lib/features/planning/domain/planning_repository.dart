import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/life_database.dart';
import '../../records/domain/life_record.dart';
import '../../records/domain/life_record_repository.dart';

enum PlanningKind { task, routine, goal, habit }

enum CompletionStatus { done, partial, notDone }

class PlanningItem {
  const PlanningItem({
    required this.id,
    required this.ownerUid,
    required this.kind,
    required this.visibility,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.scheduledDate,
    required this.scheduledMinute,
    required this.durationMinutes,
    required this.recurrence,
    required this.weekdays,
    required this.targetDate,
    required this.targetValue,
    required this.targetUnit,
    required this.archived,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.revision,
  });

  final String id,
      ownerUid,
      title,
      description,
      category,
      recurrence,
      targetUnit;
  final PlanningKind kind;
  final RecordVisibility visibility;
  final int priority, scheduledMinute, durationMinutes, revision;
  final String? scheduledDate, targetDate;
  final double? targetValue;
  final List<int> weekdays;
  final bool archived;
  final DateTime createdAtUtc, updatedAtUtc;

  bool occursOn(DateTime date) {
    if (archived) return false;
    if (kind == PlanningKind.goal) return true;
    if (recurrence == 'once' &&
        scheduledDate != null &&
        _dateKey(date) != scheduledDate) {
      return false;
    }
    return switch (recurrence) {
      'daily' => true,
      'weekdays' =>
        date.weekday >= DateTime.monday && date.weekday <= DateTime.friday,
      'weekly' =>
        weekdays.isEmpty
            ? date.weekday == DateTime.monday
            : weekdays.contains(date.weekday),
      _ => scheduledDate == _dateKey(date),
    };
  }

  Map<String, Object?> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'priority': priority,
    'scheduledDate': scheduledDate,
    'scheduledMinute': scheduledMinute,
    'durationMinutes': durationMinutes,
    'recurrence': recurrence,
    'weekdays': weekdays,
    'targetDate': targetDate,
    'targetValue': targetValue,
    'targetUnit': targetUnit,
    'archived': archived,
  };

  factory PlanningItem.fromRecord(LifeRecord record) {
    final json = jsonDecode(record.payloadJson) as Map<String, dynamic>;
    final kind = PlanningKind.values.byName(record.kind.name);
    return PlanningItem(
      id: record.id,
      ownerUid: record.ownerUid,
      kind: kind,
      visibility: record.visibility,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      priority: json['priority'] as int? ?? 2,
      scheduledDate: json['scheduledDate'] as String?,
      scheduledMinute: json['scheduledMinute'] as int? ?? 0,
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      recurrence: json['recurrence'] as String? ?? 'once',
      weekdays: (json['weekdays'] as List<dynamic>? ?? const []).cast<int>(),
      targetDate: json['targetDate'] as String?,
      targetValue: (json['targetValue'] as num?)?.toDouble(),
      targetUnit: json['targetUnit'] as String? ?? '',
      archived: json['archived'] as bool? ?? false,
      createdAtUtc: record.createdAtUtc,
      updatedAtUtc: record.updatedAtUtc,
      revision: record.revision,
    );
  }
}

class PlanningValidationFailure implements Exception {
  const PlanningValidationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class PlanningHistoryEntry {
  const PlanningHistoryEntry({
    required this.id,
    required this.definitionId,
    required this.kind,
    required this.localDate,
    required this.payload,
    required this.recordedAtUtc,
  });
  final String id, definitionId, kind, localDate, payload;
  final DateTime recordedAtUtc;
}

abstract interface class PlanningHistoryStore {
  Future<void> add(ActivityHistoryCompanion row);
  Stream<List<PlanningHistoryEntry>> watch(
    String ownerUid,
    String? definitionId,
  );
}

class DriftPlanningHistoryStore implements PlanningHistoryStore {
  const DriftPlanningHistoryStore(this.database);
  final LifeDatabase database;
  @override
  Future<void> add(ActivityHistoryCompanion row) async {
    _validateHistoryRow(row);
    await database.into(database.activityHistory).insert(row);
  }

  @override
  Stream<List<PlanningHistoryEntry>> watch(
    String ownerUid,
    String? definitionId,
  ) {
    final query =
        database.select(database.activityHistory).join([
          innerJoin(
            database.storedRecords,
            database.storedRecords.id.equalsExp(
              database.activityHistory.definitionId,
            ),
          ),
        ])..where(
          ((database.activityHistory.ownerUid.equals(ownerUid) &
                      database.storedRecords.ownerUid.equals(ownerUid)) |
                  (database.activityHistory.visibility.equals(
                        RecordVisibility.shared.name,
                      ) &
                      database.storedRecords.visibility.equals(
                        RecordVisibility.shared.name,
                      ) &
                      database.storedRecords.deletedAtUtcMs.isNull())) &
              (definitionId == null
                  ? const Constant(true)
                  : database.activityHistory.definitionId.equals(definitionId)),
        );
    query.orderBy([OrderingTerm.desc(database.activityHistory.localDate)]);
    return query.watch().map(
      (rows) => rows
          .where((row) {
            final definition = row.readTable(database.storedRecords);
            if (definition.ownerUid == ownerUid) return true;
            try {
              final item = PlanningItem.fromRecord(
                LifeRecord(
                  id: definition.id,
                  ownerUid: definition.ownerUid,
                  kind: LifeRecordKind.values.byName(definition.kind),
                  visibility: RecordVisibility.values.byName(
                    definition.visibility,
                  ),
                  payloadJson: definition.payloadJson,
                  createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
                    definition.createdAtUtcMs,
                    isUtc: true,
                  ),
                  updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
                    definition.updatedAtUtcMs,
                    isUtc: true,
                  ),
                  revision: definition.revision,
                ),
              );
              return !item.archived;
            } on Object {
              // A malformed definition must not expose its associated history
              // to another account.
              return false;
            }
          })
          .map((row) {
            final r = row.readTable(database.activityHistory);
            return PlanningHistoryEntry(
              id: r.id,
              definitionId: r.definitionId,
              kind: r.kind,
              localDate: r.localDate,
              payload: r.payloadJson,
              recordedAtUtc: DateTime.fromMillisecondsSinceEpoch(
                r.recordedAtUtcMs,
                isUtc: true,
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

/// User-bound local feature repository. Definitions use the hardened record
/// repository; immutable history uses a separate additive SQLite table.
class PlanningRepository {
  PlanningRepository(this.records, this.history, this.identity);
  final LifeRecordRepository records;
  final PlanningHistoryStore history;
  final CurrentUserIdentity identity;

  String _uid() {
    final uid = identity.currentUid;
    if (uid == null || uid.trim().isEmpty || uid != uid.trim()) {
      throw const UnauthenticatedOperation();
    }
    return uid;
  }

  Stream<List<PlanningItem>> watchItems({
    PlanningKind? kind,
    bool includeArchived = false,
  }) => records.watchVisibleRecords().map(
    (items) => items
        .where((r) => PlanningKind.values.any((k) => k.name == r.kind.name))
        .map(PlanningItem.fromRecord)
        .where(
          (i) =>
              (kind == null || i.kind == kind) &&
              (includeArchived || !i.archived),
        )
        .toList(growable: false),
  );

  Future<PlanningItem> save({
    required PlanningKind kind,
    String? id,
    required String title,
    String description = '',
    String category = '',
    int priority = 2,
    String? scheduledDate,
    int scheduledMinute = 0,
    int durationMinutes = 30,
    String recurrence = 'once',
    List<int> weekdays = const [],
    String? targetDate,
    double? targetValue,
    String targetUnit = '',
    RecordVisibility visibility = RecordVisibility.private,
    bool archived = false,
  }) async {
    _validate(
      kind,
      title,
      priority,
      scheduledDate,
      scheduledMinute,
      durationMinutes,
      recurrence,
      weekdays,
      targetDate,
      targetValue,
      targetUnit,
    );
    final uid = _uid();
    await _ensureProfile(uid);
    final previous = id == null
        ? null
        : await records.findCurrentVisibleRecord(id);
    if (previous != null && previous.ownerUid != uid) {
      throw const OwnershipViolation();
    }
    final now = DateTime.now().toUtc();
    final recordId = id ?? _newId();
    final item = PlanningItem(
      id: recordId,
      ownerUid: uid,
      kind: kind,
      visibility: visibility,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      priority: priority,
      scheduledDate: scheduledDate,
      scheduledMinute: scheduledMinute,
      durationMinutes: durationMinutes,
      recurrence: recurrence,
      weekdays: List.unmodifiable(weekdays),
      targetDate: targetDate,
      targetValue: targetValue,
      targetUnit: targetUnit.trim(),
      archived: archived,
      createdAtUtc: previous?.createdAtUtc ?? now,
      updatedAtUtc: now,
      revision: previous?.revision ?? 1,
    );
    final recordKind = LifeRecordKind.values.byName(kind.name);
    await records.saveRecord(
      LifeRecord(
        id: recordId,
        ownerUid: uid,
        kind: recordKind,
        visibility: visibility,
        payloadJson: jsonEncode(item.toJson()),
        createdAtUtc: item.createdAtUtc,
        updatedAtUtc: now,
        revision: item.revision,
      ),
    );
    return item;
  }

  Future<void> delete(String id) =>
      records.deleteRecord(id, DateTime.now().toUtc());

  Future<void> _ensureProfile(String uid) async {
    if (await records.findCurrentProfile() != null) return;
    final now = DateTime.now().toUtc();
    await records.saveProfile(
      ProfileRecord(
        authUid: uid,
        displayName: 'LIFE OS user',
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
  }

  Future<void> complete(
    PlanningItem item,
    DateTime date,
    CompletionStatus status, {
    String notes = '',
  }) async {
    final uid = _uid();
    await _ensureProfile(uid);
    final currentItem = await _currentDefinition(item, uid);
    if (!currentItem.occursOn(date)) {
      throw const PlanningValidationFailure(
        'This item is not scheduled for that date.',
      );
    }
    final localDate = _dateKey(date);
    final occurrence = currentItem.kind == PlanningKind.habit
        ? localDate
        : '$localDate-${currentItem.scheduledMinute}';
    await history.add(
      ActivityHistoryCompanion.insert(
        id: _newId(),
        ownerUid: uid,
        definitionId: currentItem.id,
        kind: '${currentItem.kind.name}Completion',
        occurrenceKey: occurrence,
        localDate: localDate,
        visibility: currentItem.visibility.name,
        payloadJson: jsonEncode({
          'status': status.name,
          'notes': notes.trim(),
          'title': currentItem.title,
        }),
        recordedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> addGoalProgress(
    PlanningItem item,
    DateTime date,
    double value, {
    String notes = '',
  }) async {
    final uid = _uid();
    await _ensureProfile(uid);
    final currentItem = await _currentDefinition(item, uid);
    if (currentItem.kind != PlanningKind.goal || !value.isFinite || value < 0) {
      throw const PlanningValidationFailure(
        'Enter a valid non-negative goal measurement.',
      );
    }
    final localDate = _dateKey(date);
    await history.add(
      ActivityHistoryCompanion.insert(
        id: _newId(),
        ownerUid: uid,
        definitionId: currentItem.id,
        kind: 'goalProgress',
        occurrenceKey: _newId(),
        localDate: localDate,
        visibility: currentItem.visibility.name,
        payloadJson: jsonEncode({
          'value': value,
          'notes': notes.trim(),
          'title': currentItem.title,
          'unit': currentItem.targetUnit,
        }),
        recordedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  Stream<List<PlanningHistoryEntry>> watchHistory({String? definitionId}) =>
      history.watch(_uid(), definitionId);

  Future<PlanningItem> _currentDefinition(PlanningItem item, String uid) async {
    if (item.ownerUid != uid && item.visibility != RecordVisibility.shared) {
      throw const OwnershipViolation();
    }
    final record = await records.findCurrentVisibleRecord(item.id);
    if (record == null || record.kind.name != item.kind.name) {
      throw const OwnershipViolation();
    }
    final latest = PlanningItem.fromRecord(record);
    if (latest.archived) {
      throw const PlanningValidationFailure(
        'Archived items cannot be tracked.',
      );
    }
    return latest;
  }

  static void _validate(
    PlanningKind kind,
    String title,
    int priority,
    String? scheduledDate,
    int minute,
    int duration,
    String recurrence,
    List<int> weekdays,
    String? targetDate,
    double? targetValue,
    String unit,
  ) {
    if (title.trim().isEmpty) {
      throw const PlanningValidationFailure('Title is required.');
    }
    if (priority < 1 || priority > 3) {
      throw const PlanningValidationFailure(
        'Priority must be High, Normal, or Low.',
      );
    }
    if (minute < 0 || minute >= 1440) {
      throw const PlanningValidationFailure('Choose a valid scheduled time.');
    }
    if (duration < 1 || duration > 1440) {
      throw const PlanningValidationFailure(
        'Duration must be between 1 and 1440 minutes.',
      );
    }
    if (!{'once', 'daily', 'weekdays', 'weekly'}.contains(recurrence)) {
      throw const PlanningValidationFailure('Choose a supported recurrence.');
    }
    if (weekdays.any((day) => day < 1 || day > 7)) {
      throw const PlanningValidationFailure(
        'Weekdays must be between 1 and 7.',
      );
    }
    if (kind != PlanningKind.goal &&
        recurrence == 'once' &&
        !_validDate(scheduledDate)) {
      throw const PlanningValidationFailure('Choose a valid scheduled date.');
    }
    if (kind == PlanningKind.goal &&
        (!_validDate(targetDate) ||
            targetValue == null ||
            !targetValue.isFinite ||
            targetValue <= 0 ||
            unit.trim().isEmpty)) {
      throw const PlanningValidationFailure(
        'Goals need a target date, positive measurable target, and unit.',
      );
    }
  }
}

bool _validDate(String? value) {
  if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return false;
  }
  final parts = value.split('-').map(int.parse).toList();
  final date = DateTime(parts[0], parts[1], parts[2]);
  return date.year == parts[0] &&
      date.month == parts[1] &&
      date.day == parts[2];
}

void _validateHistoryRow(ActivityHistoryCompanion row) {
  final identifiers = [
    row.id.value,
    row.ownerUid.value,
    row.definitionId.value,
    row.kind.value,
    row.occurrenceKey.value,
  ];
  if (identifiers.any(
    (value) => value.trim().isEmpty || value != value.trim(),
  )) {
    throw const RecordValidationFailure(
      'History identifiers and kinds must be non-empty and trimmed.',
    );
  }
  if (!_validDate(row.localDate.value)) {
    throw const PlanningValidationFailure(
      'History date must be a valid local date.',
    );
  }
  if (!{
    'taskCompletion',
    'routineCompletion',
    'habitCompletion',
    'goalProgress',
  }.contains(row.kind.value)) {
    throw const RecordValidationFailure('Unknown activity history kind.');
  }
  try {
    RecordVisibility.values.byName(row.visibility.value);
  } on ArgumentError {
    throw const RecordValidationFailure('Unknown history visibility value.');
  }
  if (row.recordedAtUtcMs.value < 0) {
    throw const RecordValidationFailure(
      'History timestamp cannot be negative.',
    );
  }
  try {
    if (jsonDecode(row.payloadJson.value) is! Map<String, dynamic>) {
      throw const RecordValidationFailure(
        'History payload must be a JSON object.',
      );
    }
  } on FormatException {
    throw const RecordValidationFailure('History payload must be valid JSON.');
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String _newId() => List<int>.generate(
  20,
  (_) => Random.secure().nextInt(16),
).map((n) => n.toRadixString(16)).join();
