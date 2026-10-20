import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../core/database/life_database.dart';
import '../../records/domain/life_record.dart';
import '../../records/domain/life_record_repository.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../domain/local_backup.dart';

const localBackupFormat = 'life_os_local_backup';
const localBackupVersion = 1;
const localBackupMaxBytes = 50 * 1024 * 1024;

/// Versioned, account-bound JSON backup for the local Drift database.
/// Only records owned by the currently authenticated account are exported.
/// Shared records owned by another account and the remote assigned-task store
/// are intentionally excluded. Evidence file contents and storage keys never
/// leave this device; exported attachment metadata is marked unavailable.
class LocalJsonBackupService {
  const LocalJsonBackupService({
    required this.database,
    required this.identity,
  });

  final LifeDatabase database;
  final CurrentUserIdentity identity;

  String _uid() {
    final value = identity.currentUid;
    if (value == null || value.trim().isEmpty || value != value.trim()) {
      throw const LocalBackupFailure('Sign in to back up this account.');
    }
    return value;
  }

  String _accountFingerprint(String uid) =>
      sha256.convert(utf8.encode(uid)).toString();

  Future<Uint8List> exportJson() async {
    final uid = _uid();
    return database.transaction(() async {
      final profile = await (database.select(
        database.profiles,
      )..where((row) => row.authUid.equals(uid))).getSingleOrNull();
      final records = await (database.select(
        database.storedRecords,
      )..where((row) => row.ownerUid.equals(uid))).get();
      final history = await (database.select(
        database.activityHistory,
      )..where((row) => row.ownerUid.equals(uid))).get();
      final tracking = await (database.select(
        database.trackingEntries,
      )..where((row) => row.ownerUid.equals(uid))).get();
      final receipts = await (database.select(
        database.taskPlanImports,
      )..where((row) => row.ownerUid.equals(uid))).get();

      final envelope = <String, Object?>{
        'format': localBackupFormat,
        'version': localBackupVersion,
        'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
        'accountFingerprint': _accountFingerprint(uid),
        if (profile != null)
          'profile': {
            'displayName': profile.displayName,
            'createdAtUtcMs': profile.createdAtUtcMs,
            'updatedAtUtcMs': profile.updatedAtUtcMs,
          },
        'records': records.map((row) => _recordJson(row, uid)).toList(),
        'history': history.map((row) => _historyJson(row)).toList(),
        'tracking': tracking.map((row) => _trackingJson(row)).toList(),
        'importReceipts': receipts.map((row) => _receiptJson(row)).toList(),
        'evidencePolicy':
            'Evidence file contents and local storage keys are excluded. Attachment names and metadata remain as unavailable references.',
      };
      final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(envelope)),
      );
      if (bytes.length > localBackupMaxBytes) {
        throw const LocalBackupFailure(
          'This account backup exceeds the supported 50 MB size. No file was saved.',
        );
      }
      return bytes;
    });
  }

  Future<LocalBackupPreview> preview(Uint8List bytes) async {
    final uid = _uid();
    if (bytes.isEmpty || bytes.length > localBackupMaxBytes) {
      return _failedPreview('Backup file must be between 1 byte and 50 MB.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on Object {
      return _failedPreview('The selected file is not valid UTF-8 JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      return _failedPreview('Backup root must be a JSON object.');
    }
    if (decoded['format'] != localBackupFormat) {
      return _failedPreview('This is not a LIFE OS local backup.');
    }
    final version = decoded['version'];
    if (version is! int) {
      return _failedPreview('Backup version is missing or invalid.');
    }
    if (version != localBackupVersion) {
      return _failedPreview('Backup version $version is not supported.');
    }
    final fingerprint = decoded['accountFingerprint'];
    final accountMatches =
        fingerprint is String && fingerprint == _accountFingerprint(uid);
    final errors = <String>[];
    if (!accountMatches) {
      errors.add(
        'This backup belongs to a different account. Sign in to its original account before restoring.',
      );
    }

    final profile = _parseProfile(decoded['profile'], errors);
    final records = _parseRecords(decoded['records'], uid, errors);
    final history = _parseHistory(decoded['history'], errors);
    final tracking = _parseTracking(decoded['tracking'], uid, errors);
    final receipts = _parseReceipts(decoded['importReceipts'], errors);
    final bundle = _BackupBundle(
      profile: profile,
      records: records,
      history: history,
      tracking: tracking,
      receipts: receipts,
      accountFingerprint: fingerprint as String? ?? '',
    );
    _checkInputDuplicates(bundle, errors);
    final fileCounts = LocalBackupCounts(
      records: _rawRowCount(decoded['records']),
      history: _rawRowCount(decoded['history']),
      tracking: _rawRowCount(decoded['tracking']),
      importReceipts: _rawRowCount(decoded['importReceipts']),
    );
    if (errors.isNotEmpty) {
      return LocalBackupPreview(
        sourceVersion: version,
        fileCounts: fileCounts,
        additions: const LocalBackupCounts(
          records: 0,
          history: 0,
          tracking: 0,
          importReceipts: 0,
        ),
        duplicates: const LocalBackupCounts(
          records: 0,
          history: 0,
          tracking: 0,
          importReceipts: 0,
        ),
        errors: List.unmodifiable(errors),
        notes: const [],
        accountMatches: accountMatches,
        parsed: bundle,
      );
    }
    final classification = await _classify(bundle, uid);
    errors.addAll(classification.errors);
    return LocalBackupPreview(
      sourceVersion: version,
      fileCounts: fileCounts,
      additions: classification.additions,
      duplicates: classification.duplicates,
      errors: List.unmodifiable(errors),
      notes: const [
        'Restore only adds records that do not already exist. Existing records and history are never overwritten or deleted.',
        'Evidence file contents and storage keys are not included. Restored evidence entries remain as metadata-only references.',
        'Records shared locally by another account and remote assigned tasks are excluded from this account backup.',
      ],
      accountMatches: accountMatches,
      parsed: bundle,
    );
  }

  Future<LocalBackupRestoreResult> restore(LocalBackupPreview preview) async {
    final uid = _uid();
    if (!preview.accountMatches || preview.errors.isNotEmpty) {
      throw const LocalBackupFailure(
        'Resolve the backup validation errors before restoring.',
      );
    }
    final bundle = preview.parsed;
    if (bundle is! _BackupBundle ||
        bundle.accountFingerprint != _accountFingerprint(uid)) {
      throw const LocalBackupFailure('Backup account identity does not match.');
    }

    late _Classification result;
    await database.transaction(() async {
      if (identity.currentUid != uid) {
        throw const LocalBackupFailure(
          'The signed-in account changed. Re-select the backup and preview it again.',
        );
      }
      result = await _classify(bundle, uid);
      if (result.errors.isNotEmpty) {
        throw LocalBackupFailure(result.errors.join('\n'));
      }
      if (result.additions.total == 0) return;

      final profile = await (database.select(
        database.profiles,
      )..where((row) => row.authUid.equals(uid))).getSingleOrNull();
      if (profile == null) {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await database
            .into(database.profiles)
            .insert(
              ProfilesCompanion.insert(
                authUid: uid,
                displayName:
                    bundle.profile?['displayName'] as String? ?? 'LIFE OS user',
                createdAtUtcMs:
                    bundle.profile?['createdAtUtcMs'] as int? ?? now,
                updatedAtUtcMs:
                    bundle.profile?['updatedAtUtcMs'] as int? ?? now,
              ),
            );
      }

      for (final row in result.recordsToAdd) {
        final id = _restoreRecordId(row['id'] as String, uid);
        final payload = _jsonMap(row['payload']);
        await database
            .into(database.storedRecords)
            .insert(
              StoredRecordsCompanion.insert(
                id: id,
                ownerUid: uid,
                kind: row['kind'] as String,
                visibility: row['visibility'] as String,
                payloadJson: jsonEncode(payload),
                createdAtUtcMs: row['createdAtUtcMs'] as int,
                updatedAtUtcMs: row['updatedAtUtcMs'] as int,
                timezoneId: Value(row['timezoneId'] as String?),
                syncStatus: const Value('localOnly'),
                revision: Value(row['revision'] as int),
                deletedAtUtcMs: Value(row['deletedAtUtcMs'] as int?),
              ),
            );
      }
      for (final row in result.historyToAdd) {
        await database
            .into(database.activityHistory)
            .insert(
              ActivityHistoryCompanion.insert(
                id: row['id'] as String,
                ownerUid: uid,
                definitionId: _restoreRecordId(
                  row['definitionId'] as String,
                  uid,
                ),
                kind: row['kind'] as String,
                occurrenceKey: row['occurrenceKey'] as String,
                localDate: row['localDate'] as String,
                visibility: row['visibility'] as String,
                payloadJson: jsonEncode(_jsonMap(row['payload'])),
                recordedAtUtcMs: row['recordedAtUtcMs'] as int,
              ),
            );
      }
      for (final row in result.trackingToAdd) {
        await database
            .into(database.trackingEntries)
            .insert(
              TrackingEntriesCompanion.insert(
                id: row['id'] as String,
                ownerUid: uid,
                kind: row['kind'] as String,
                localDate: row['localDate'] as String,
                entryKey: row['entryKey'] as String,
                visibility: row['visibility'] as String,
                payloadJson: jsonEncode(_jsonMap(row['payload'])),
                createdAtUtcMs: row['createdAtUtcMs'] as int,
                updatedAtUtcMs: row['updatedAtUtcMs'] as int,
                revision: Value(row['revision'] as int),
                deletedAtUtcMs: Value(row['deletedAtUtcMs'] as int?),
              ),
            );
      }
      for (final row in result.receiptsToAdd) {
        await database
            .into(database.taskPlanImports)
            .insert(
              TaskPlanImportsCompanion.insert(
                id: row['id'] as String,
                ownerUid: uid,
                sourceFingerprint: row['sourceFingerprint'] as String,
                startDate: row['startDate'] as String,
                parserVersion: row['parserVersion'] as String,
                taskIdsJson: jsonEncode(row['taskIds']),
                importedAtUtcMs: row['importedAtUtcMs'] as int,
              ),
            );
      }
    });
    return LocalBackupRestoreResult(
      added: result.additions,
      skippedDuplicates: result.duplicates,
    );
  }

  LocalBackupPreview _failedPreview(String message) => LocalBackupPreview(
    sourceVersion: null,
    fileCounts: const LocalBackupCounts(
      records: 0,
      history: 0,
      tracking: 0,
      importReceipts: 0,
    ),
    additions: const LocalBackupCounts(
      records: 0,
      history: 0,
      tracking: 0,
      importReceipts: 0,
    ),
    duplicates: const LocalBackupCounts(
      records: 0,
      history: 0,
      tracking: 0,
      importReceipts: 0,
    ),
    errors: [message],
    notes: const [],
    accountMatches: false,
    parsed: null,
  );

  int _rawRowCount(Object? value) => value is List ? value.length : 0;

  Map<String, Object?> _recordJson(StoredRecord row, String uid) => {
    'id': row.id == 'prayer-reminder-state:$uid'
        ? 'prayer-reminder-state:self'
        : row.id,
    'kind': row.kind,
    'visibility': row.visibility,
    'payload': _sanitizePayload(_decodeObject(row.payloadJson)),
    'createdAtUtcMs': row.createdAtUtcMs,
    'updatedAtUtcMs': row.updatedAtUtcMs,
    'timezoneId': row.timezoneId,
    'revision': row.revision,
    'deletedAtUtcMs': row.deletedAtUtcMs,
  };

  Map<String, Object?> _historyJson(ActivityHistoryData row) => {
    'id': row.id,
    'definitionId': row.definitionId,
    'kind': row.kind,
    'occurrenceKey': row.occurrenceKey,
    'localDate': row.localDate,
    'visibility': row.visibility,
    'payload': _sanitizePayload(_decodeObject(row.payloadJson)),
    'recordedAtUtcMs': row.recordedAtUtcMs,
  };

  Map<String, Object?> _trackingJson(TrackingEntryRow row) => {
    'id': row.id,
    'kind': row.kind,
    'localDate': row.localDate,
    'entryKey': row.entryKey,
    'visibility': row.visibility,
    'payload': _sanitizePayload(_decodeObject(row.payloadJson)),
    'createdAtUtcMs': row.createdAtUtcMs,
    'updatedAtUtcMs': row.updatedAtUtcMs,
    'revision': row.revision,
    'deletedAtUtcMs': row.deletedAtUtcMs,
  };

  Map<String, Object?> _receiptJson(TaskPlanImport row) => {
    'id': row.id,
    'sourceFingerprint': row.sourceFingerprint,
    'startDate': row.startDate,
    'parserVersion': row.parserVersion,
    'taskIds': _decodeStringList(row.taskIdsJson),
    'importedAtUtcMs': row.importedAtUtcMs,
  };

  Object? _sanitizePayload(Object? value, {bool insideEvidence = false}) {
    if (value is List) {
      return value
          .map((item) => _sanitizePayload(item, insideEvidence: insideEvidence))
          .toList(growable: false);
    }
    if (value is Map) {
      final output = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) continue;
        final key = entry.key as String;
        final normalizedKey = key.toLowerCase();
        if (normalizedKey == 'uid' ||
            normalizedKey.endsWith('uid') ||
            const {
              'ownerUid',
              'authUid',
              'password',
              'credential',
              'accessToken',
              'refreshToken',
              'secret',
            }.contains(key)) {
          continue;
        }
        if (insideEvidence &&
            const {
              'key',
              'path',
              'filePath',
              'localPath',
              'storageKey',
              'fileUri',
              'uri',
              'bytes',
              'contents',
            }.contains(key)) {
          continue;
        }
        if (key == 'evidence' && entry.value is List) {
          output[key] = (entry.value as List)
              .map((attachment) {
                if (attachment is! Map) return null;
                final safe = _sanitizePayload(attachment, insideEvidence: true);
                if (safe is! Map<String, Object?>) return null;
                return {...safe, 'fileIncluded': false};
              })
              .whereType<Map<String, Object?>>()
              .toList(growable: false);
        } else if (key == 'evidenceReference') {
          output[key] = null;
          output['evidenceReferenceAvailable'] = false;
        } else {
          output[key] = _sanitizePayload(
            entry.value,
            insideEvidence: insideEvidence,
          );
        }
      }
      return output;
    }
    return value;
  }

  Map<String, dynamic> _decodeObject(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const LocalBackupFailure(
        'A local database payload is not a JSON object and cannot be backed up.',
      );
    }
    return decoded;
  }

  List<String> _decodeStringList(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List || decoded.any((item) => item is! String)) {
      throw const LocalBackupFailure(
        'A local import receipt contains an invalid task ID list.',
      );
    }
    return decoded.cast<String>();
  }

  Map<String, Object?>? _parseProfile(Object? value, List<String> errors) {
    if (value == null) return null;
    if (value is! Map<String, dynamic> ||
        value['displayName'] is! String ||
        (value['displayName'] as String).trim().isEmpty ||
        value['createdAtUtcMs'] is! int ||
        value['updatedAtUtcMs'] is! int ||
        (value['updatedAtUtcMs'] as int) < (value['createdAtUtcMs'] as int)) {
      errors.add('Profile metadata is malformed.');
      return null;
    }
    return {
      'displayName': value['displayName'],
      'createdAtUtcMs': value['createdAtUtcMs'],
      'updatedAtUtcMs': value['updatedAtUtcMs'],
    };
  }

  List<Map<String, Object?>> _parseRecords(
    Object? value,
    String uid,
    List<String> errors,
  ) => _parseRows(value, 'records', errors, (row, index) {
    final id = row['id'];
    final kind = row['kind'];
    final visibility = row['visibility'];
    final payload = row['payload'];
    final created = row['createdAtUtcMs'];
    final updated = row['updatedAtUtcMs'];
    final revision = row['revision'];
    final deleted = row['deletedAtUtcMs'];
    final timezone = row['timezoneId'];
    if (id is! String ||
        id.trim().isEmpty ||
        id != id.trim() ||
        kind is! String ||
        !_enumContains(LifeRecordKind.values, kind) ||
        visibility is! String ||
        !_enumContains(RecordVisibility.values, visibility) ||
        payload is! Map<String, dynamic> ||
        created is! int ||
        updated is! int ||
        updated < created ||
        revision is! int ||
        revision < 1 ||
        (deleted != null && (deleted is! int || deleted < updated)) ||
        (timezone != null && timezone is! String)) {
      throw FormatException('records[$index] is malformed.');
    }
    final sanitizedPayload = _sanitizePayload(payload);
    final record = LifeRecord(
      id: _restoreRecordId(id, uid),
      ownerUid: uid,
      kind: LifeRecordKind.values.byName(kind),
      visibility: RecordVisibility.values.byName(visibility),
      payloadJson: jsonEncode(sanitizedPayload),
      createdAtUtc: _utc(created),
      updatedAtUtc: _utc(updated),
      timezoneId: timezone as String?,
      syncStatus: RecordSyncStatus.localOnly,
      revision: revision,
      deletedAtUtc: deleted == null ? null : _utc(deleted as int),
    );
    validateLifeRecord(record);
    return {
      'id': id,
      'kind': kind,
      'visibility': visibility,
      'payload': sanitizedPayload,
      'createdAtUtcMs': created,
      'updatedAtUtcMs': updated,
      'timezoneId': timezone,
      'revision': revision,
      'deletedAtUtcMs': deleted,
    };
  });

  List<Map<String, Object?>> _parseHistory(
    Object? value,
    List<String> errors,
  ) => _parseRows(value, 'history', errors, (row, index) {
    final requiredStrings = [
      'id',
      'definitionId',
      'kind',
      'occurrenceKey',
      'localDate',
      'visibility',
    ];
    if (requiredStrings.any((key) => row[key] is! String) ||
        (row['payload'] is! Map<String, dynamic>) ||
        row['recordedAtUtcMs'] is! int ||
        !_validDate(row['localDate'] as String) ||
        !_enumContains(RecordVisibility.values, row['visibility'] as String)) {
      throw FormatException('history[$index] is malformed.');
    }
    for (final key in requiredStrings) {
      final text = row[key] as String;
      if (text.trim().isEmpty || text != text.trim()) {
        throw FormatException(
          'history[$index] has an empty or untrimmed $key.',
        );
      }
    }
    return {
      for (final key in requiredStrings) key: row[key],
      'payload': _sanitizePayload(row['payload']),
      'recordedAtUtcMs': row['recordedAtUtcMs'],
    };
  });

  List<Map<String, Object?>> _parseTracking(
    Object? value,
    String uid,
    List<String> errors,
  ) => _parseRows(value, 'tracking', errors, (row, index) {
    final kind = row['kind'];
    if (row['id'] is! String ||
        kind is! String ||
        !_enumContains(TrackingEntryKind.values, kind) ||
        row['localDate'] is! String ||
        !_validDate(row['localDate'] as String) ||
        row['entryKey'] is! String ||
        !_enumContains(
          RecordVisibility.values,
          row['visibility'] as String? ?? '',
        ) ||
        row['payload'] is! Map<String, dynamic> ||
        row['createdAtUtcMs'] is! int ||
        row['updatedAtUtcMs'] is! int ||
        (row['deletedAtUtcMs'] != null && row['deletedAtUtcMs'] is! int)) {
      throw FormatException('tracking[$index] is malformed.');
    }
    final entry = TrackingEntry(
      id: row['id'] as String,
      ownerUid: uid,
      kind: TrackingEntryKind.values.byName(kind),
      localDate: row['localDate'] as String,
      entryKey: row['entryKey'] as String,
      visibility: RecordVisibility.values.byName(row['visibility'] as String),
      payloadJson: jsonEncode(_sanitizePayload(row['payload'])),
      createdAtUtc: _utc(row['createdAtUtcMs'] as int),
      updatedAtUtc: _utc(row['updatedAtUtcMs'] as int),
      revision: row['revision'] is int ? row['revision'] as int : 1,
      deletedAtUtc: row['deletedAtUtcMs'] == null
          ? null
          : _utc(row['deletedAtUtcMs'] as int),
    );
    validateTrackingEntry(entry);
    if (entry.id.trim().isEmpty ||
        entry.id != entry.id.trim() ||
        entry.updatedAtUtc.isBefore(entry.createdAtUtc) ||
        (entry.deletedAtUtc != null &&
            entry.deletedAtUtc!.isBefore(entry.updatedAtUtc))) {
      throw FormatException('tracking[$index] has invalid timestamps or ID.');
    }
    return {
      'id': entry.id,
      'kind': kind,
      'localDate': entry.localDate,
      'entryKey': entry.entryKey,
      'visibility': entry.visibility.name,
      'payload': _sanitizePayload(_jsonMap(jsonDecode(entry.payloadJson))),
      'createdAtUtcMs': entry.createdAtUtc.millisecondsSinceEpoch,
      'updatedAtUtcMs': entry.updatedAtUtc.millisecondsSinceEpoch,
      'revision': entry.revision,
      'deletedAtUtcMs': entry.deletedAtUtc?.millisecondsSinceEpoch,
    };
  });

  List<Map<String, Object?>> _parseReceipts(
    Object? value,
    List<String> errors,
  ) => _parseRows(value, 'importReceipts', errors, (row, index) {
    final taskIds = row['taskIds'];
    if (row['id'] is! String ||
        row['sourceFingerprint'] is! String ||
        (row['sourceFingerprint'] as String).isEmpty ||
        row['startDate'] is! String ||
        !_validDate(row['startDate'] as String) ||
        row['parserVersion'] is! String ||
        (row['parserVersion'] as String).isEmpty ||
        taskIds is! List ||
        taskIds.any((id) => id is! String || id.trim().isEmpty) ||
        row['importedAtUtcMs'] is! int) {
      throw FormatException('importReceipts[$index] is malformed.');
    }
    return {
      'id': row['id'],
      'sourceFingerprint': row['sourceFingerprint'],
      'startDate': row['startDate'],
      'parserVersion': row['parserVersion'],
      'taskIds': taskIds.cast<String>(),
      'importedAtUtcMs': row['importedAtUtcMs'],
    };
  });

  List<Map<String, Object?>> _parseRows(
    Object? value,
    String section,
    List<String> errors,
    Map<String, Object?> Function(Map<String, dynamic>, int) parseRow,
  ) {
    if (value is! List) {
      errors.add('The $section section is missing or malformed.');
      return const [];
    }
    final rows = <Map<String, Object?>>[];
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! Map<String, dynamic>) {
        errors.add('$section[$index] is not an object.');
        continue;
      }
      try {
        rows.add(parseRow(item, index));
      } on Object catch (error) {
        errors.add(
          error is FormatException
              ? error.message
              : '$section[$index] is invalid.',
        );
      }
    }
    return rows;
  }

  void _checkInputDuplicates(_BackupBundle bundle, List<String> errors) {
    void duplicateIds(List<Map<String, Object?>> rows, String section) {
      final ids = <String>{};
      for (final row in rows) {
        final id = row['id'] as String;
        if (!ids.add(id)) errors.add('The $section section repeats ID "$id".');
      }
    }

    duplicateIds(bundle.records, 'records');
    duplicateIds(bundle.history, 'history');
    duplicateIds(bundle.tracking, 'tracking');
    duplicateIds(bundle.receipts, 'import receipts');
    _duplicateTuple(
      bundle.history,
      'history',
      (row) => '${row['definitionId']}|${row['kind']}|${row['occurrenceKey']}',
      errors,
    );
    _duplicateTuple(
      bundle.tracking,
      'tracking',
      (row) => '${row['kind']}|${row['localDate']}|${row['entryKey']}',
      errors,
    );
    _duplicateTuple(
      bundle.receipts,
      'import receipts',
      (row) =>
          '${row['sourceFingerprint']}|${row['startDate']}|${row['parserVersion']}',
      errors,
    );
  }

  void _duplicateTuple(
    List<Map<String, Object?>> rows,
    String section,
    String Function(Map<String, Object?>) key,
    List<String> errors,
  ) {
    final keys = <String>{};
    for (final row in rows) {
      if (!keys.add(key(row))) {
        errors.add('The $section section contains a duplicate key.');
      }
    }
  }

  Future<_Classification> _classify(_BackupBundle bundle, String uid) async {
    final localRecords = await (database.select(
      database.storedRecords,
    )..where((row) => row.ownerUid.equals(uid))).get();
    final localHistory = await (database.select(
      database.activityHistory,
    )..where((row) => row.ownerUid.equals(uid))).get();
    final localTracking = await (database.select(
      database.trackingEntries,
    )..where((row) => row.ownerUid.equals(uid))).get();
    final localReceipts = await (database.select(
      database.taskPlanImports,
    )..where((row) => row.ownerUid.equals(uid))).get();
    final errors = <String>[];
    final addRecords = <Map<String, Object?>>[];
    final addHistory = <Map<String, Object?>>[];
    final addTracking = <Map<String, Object?>>[];
    final addReceipts = <Map<String, Object?>>[];
    var dupRecords = 0, dupHistory = 0, dupTracking = 0, dupReceipts = 0;
    final recordById = {for (final row in localRecords) row.id: row};
    final recordJsonById = {
      for (final row in localRecords)
        _exportId(row.id, uid): _recordJson(row, uid),
    };
    final allDefinitionIds = {
      ...recordJsonById.keys,
      ...bundle.records.map((r) => r['id'] as String),
    };

    for (final incoming in bundle.records) {
      final id = incoming['id'] as String;
      final existing = recordById[_restoreRecordId(id, uid)];
      if (existing == null) {
        addRecords.add(incoming);
      } else if (_same(recordJsonById[id], incoming)) {
        dupRecords++;
      } else {
        errors.add(
          'Record ID "$id" already exists with different data. Nothing will be overwritten.',
        );
      }
    }

    final historyById = {for (final row in localHistory) row.id: row};
    final historyByKey = {
      for (final row in localHistory)
        '${row.definitionId}|${row.kind}|${row.occurrenceKey}': row,
    };
    for (final incoming in bundle.history) {
      final definitionId = _restoreRecordId(
        incoming['definitionId'] as String,
        uid,
      );
      if (!allDefinitionIds.contains(incoming['definitionId'])) {
        errors.add(
          'History entry "${incoming['id']}" has no matching record definition.',
        );
        continue;
      }
      final existing =
          historyById[incoming['id']] ??
          historyByKey['$definitionId|${incoming['kind']}|${incoming['occurrenceKey']}'];
      if (existing == null) {
        addHistory.add(incoming);
      } else if (_same(_historyJson(existing), incoming)) {
        dupHistory++;
      } else {
        errors.add(
          'History key for "${incoming['id']}" conflicts with existing history.',
        );
      }
    }

    final trackingById = {for (final row in localTracking) row.id: row};
    final activeTrackingByKey = {
      for (final row in localTracking)
        if (row.deletedAtUtcMs == null)
          '${row.kind}|${row.localDate}|${row.entryKey}': row,
    };
    for (final incoming in bundle.tracking) {
      final existing =
          trackingById[incoming['id']] ??
          (incoming['deletedAtUtcMs'] == null
              ? activeTrackingByKey['${incoming['kind']}|${incoming['localDate']}|${incoming['entryKey']}']
              : null);
      if (existing == null) {
        addTracking.add(incoming);
      } else if (_same(_trackingJson(existing), incoming)) {
        dupTracking++;
      } else {
        errors.add(
          'Tracking key for "${incoming['id']}" conflicts with existing data.',
        );
      }
    }

    final receiptsById = {for (final row in localReceipts) row.id: row};
    final receiptsByKey = {
      for (final row in localReceipts)
        '${row.sourceFingerprint}|${row.startDate}|${row.parserVersion}': row,
    };
    for (final incoming in bundle.receipts) {
      final existing =
          receiptsById[incoming['id']] ??
          receiptsByKey['${incoming['sourceFingerprint']}|${incoming['startDate']}|${incoming['parserVersion']}'];
      if (existing == null) {
        addReceipts.add(incoming);
      } else if (_same(_receiptJson(existing), incoming)) {
        dupReceipts++;
      } else {
        errors.add(
          'Import receipt "${incoming['id']}" conflicts with an existing receipt.',
        );
      }
    }

    final existingTaskIds = {
      ...localRecords
          .where((row) => row.kind == LifeRecordKind.task.name)
          .map((r) => r.id),
      ...bundle.records
          .where((row) => row['kind'] == LifeRecordKind.task.name)
          .map((row) => _restoreRecordId(row['id'] as String, uid)),
    };
    for (final receipt in bundle.receipts) {
      final missing = (receipt['taskIds'] as List<String>).where(
        (id) => !existingTaskIds.contains(id),
      );
      if (missing.isNotEmpty) {
        errors.add(
          'Import receipt "${receipt['id']}" references missing task records.',
        );
      }
    }

    return _Classification(
      recordsToAdd: addRecords,
      historyToAdd: addHistory,
      trackingToAdd: addTracking,
      receiptsToAdd: addReceipts,
      additions: LocalBackupCounts(
        records: addRecords.length,
        history: addHistory.length,
        tracking: addTracking.length,
        importReceipts: addReceipts.length,
      ),
      duplicates: LocalBackupCounts(
        records: dupRecords,
        history: dupHistory,
        tracking: dupTracking,
        importReceipts: dupReceipts,
      ),
      errors: errors,
    );
  }

  String _exportId(String id, String uid) =>
      id == 'prayer-reminder-state:$uid' ? 'prayer-reminder-state:self' : id;

  String _restoreRecordId(String id, String uid) =>
      id == 'prayer-reminder-state:self' ? 'prayer-reminder-state:$uid' : id;

  String _canonicalJson(Object? value) => jsonEncode(_canonical(value));
  bool _same(Object? left, Object? right) =>
      _canonicalJson(left) == _canonicalJson(right);

  Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.whereType<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList(growable: false);
    return value;
  }

  Map<String, dynamic> _jsonMap(Object? value) =>
      Map<String, dynamic>.from(value as Map);

  DateTime _utc(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);

  bool _validDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parts = value.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    return date.year == parts[0] &&
        date.month == parts[1] &&
        date.day == parts[2];
  }

  bool _enumContains<T extends Enum>(List<T> values, String value) =>
      values.any((item) => item.name == value);
}

class _BackupBundle {
  const _BackupBundle({
    required this.profile,
    required this.records,
    required this.history,
    required this.tracking,
    required this.receipts,
    required this.accountFingerprint,
  });
  final Map<String, Object?>? profile;
  final List<Map<String, Object?>> records, history, tracking, receipts;
  final String accountFingerprint;
  LocalBackupCounts get counts => LocalBackupCounts(
    records: records.length,
    history: history.length,
    tracking: tracking.length,
    importReceipts: receipts.length,
  );
}

class _Classification {
  const _Classification({
    required this.recordsToAdd,
    required this.historyToAdd,
    required this.trackingToAdd,
    required this.receiptsToAdd,
    required this.additions,
    required this.duplicates,
    required this.errors,
  });
  final List<Map<String, Object?>> recordsToAdd,
      historyToAdd,
      trackingToAdd,
      receiptsToAdd;
  final LocalBackupCounts additions, duplicates;
  final List<String> errors;
}
