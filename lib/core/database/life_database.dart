import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'life_database.g.dart';

class Profiles extends Table {
  TextColumn get authUid => text()();
  TextColumn get displayName => text()();
  IntColumn get createdAtUtcMs => integer()();
  IntColumn get updatedAtUtcMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {authUid};
}

class StoredRecords extends Table {
  TextColumn get id => text()();
  TextColumn get ownerUid => text().references(Profiles, #authUid)();
  TextColumn get kind => text()();
  TextColumn get visibility => text()();
  TextColumn get payloadJson => text()();
  IntColumn get createdAtUtcMs => integer()();
  IntColumn get updatedAtUtcMs => integer()();
  TextColumn get timezoneId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  IntColumn get lastSyncedAtUtcMs => integer().nullable()();
  TextColumn get remoteConflictJson => text().nullable()();
  IntColumn get deletedAtUtcMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Append-only occurrence and measurement history. The unique key prevents
/// duplicate habit check-ins while allowing distinct scheduled occurrences.
class ActivityHistory extends Table {
  TextColumn get id => text()();
  TextColumn get ownerUid => text().references(Profiles, #authUid)();
  TextColumn get definitionId => text()();
  TextColumn get kind => text()();
  TextColumn get occurrenceKey => text()();
  TextColumn get localDate => text()();
  TextColumn get visibility => text()();
  TextColumn get payloadJson => text()();
  IntColumn get recordedAtUtcMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {ownerUid, definitionId, kind, occurrenceKey},
  ];
}

/// Mutable date-keyed prayer, fasting, sleep, and workout records.
@DataClassName('TrackingEntryRow')
class TrackingEntries extends Table {
  TextColumn get id => text()();
  TextColumn get ownerUid => text().references(Profiles, #authUid)();
  TextColumn get kind => text()();
  TextColumn get localDate => text()();
  TextColumn get entryKey => text()();
  TextColumn get visibility => text()();
  TextColumn get payloadJson => text()();
  IntColumn get createdAtUtcMs => integer()();
  IntColumn get updatedAtUtcMs => integer()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  IntColumn get deletedAtUtcMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Profiles, StoredRecords, ActivityHistory, TrackingEntries],
)
class LifeDatabase extends _$LifeDatabase {
  LifeDatabase() : super(_openConnection());

  LifeDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createTrackingEntryIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(storedRecords, storedRecords.deletedAtUtcMs);
      }
      if (from < 3) {
        await m.createTable(activityHistory);
      }
      if (from < 4) {
        await m.createTable(trackingEntries);
        await _createTrackingEntryIndexes();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createTrackingEntryIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS tracking_entries_active_key
      ON tracking_entries (owner_uid, kind, local_date, entry_key)
      WHERE deleted_at_utc_ms IS NULL
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS tracking_entries_active_sleep_day
      ON tracking_entries (owner_uid, local_date)
      WHERE kind = 'sleep' AND deleted_at_utc_ms IS NULL
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS tracking_entries_owner_date_kind
      ON tracking_entries (owner_uid, local_date, kind)
    ''');
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'life_os.sqlite'));
  return NativeDatabase.createInBackground(file);
});
