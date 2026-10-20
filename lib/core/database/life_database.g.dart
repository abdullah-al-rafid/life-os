// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'life_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _authUidMeta = const VerificationMeta(
    'authUid',
  );
  @override
  late final GeneratedColumn<String> authUid = GeneratedColumn<String>(
    'auth_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    authUid,
    displayName,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('auth_uid')) {
      context.handle(
        _authUidMeta,
        authUid.isAcceptableOrUnknown(data['auth_uid']!, _authUidMeta),
      );
    } else if (isInserting) {
      context.missing(_authUidMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {authUid};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      authUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_uid'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String authUid;
  final String displayName;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  const Profile({
    required this.authUid,
    required this.displayName,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['auth_uid'] = Variable<String>(authUid);
    map['display_name'] = Variable<String>(displayName);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      authUid: Value(authUid),
      displayName: Value(displayName),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      authUid: serializer.fromJson<String>(json['authUid']),
      displayName: serializer.fromJson<String>(json['displayName']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'authUid': serializer.toJson<String>(authUid),
      'displayName': serializer.toJson<String>(displayName),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
    };
  }

  Profile copyWith({
    String? authUid,
    String? displayName,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
  }) => Profile(
    authUid: authUid ?? this.authUid,
    displayName: displayName ?? this.displayName,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      authUid: data.authUid.present ? data.authUid.value : this.authUid,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('authUid: $authUid, ')
          ..write('displayName: $displayName, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(authUid, displayName, createdAtUtcMs, updatedAtUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.authUid == this.authUid &&
          other.displayName == this.displayName &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> authUid;
  final Value<String> displayName;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.authUid = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String authUid,
    required String displayName,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.rowid = const Value.absent(),
  }) : authUid = Value(authUid),
       displayName = Value(displayName),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs);
  static Insertable<Profile> custom({
    Expression<String>? authUid,
    Expression<String>? displayName,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (authUid != null) 'auth_uid': authUid,
      if (displayName != null) 'display_name': displayName,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? authUid,
    Value<String>? displayName,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      authUid: authUid ?? this.authUid,
      displayName: displayName ?? this.displayName,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (authUid.present) {
      map['auth_uid'] = Variable<String>(authUid.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('authUid: $authUid, ')
          ..write('displayName: $displayName, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredRecordsTable extends StoredRecords
    with TableInfo<$StoredRecordsTable, StoredRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUidMeta = const VerificationMeta(
    'ownerUid',
  );
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
    'owner_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (auth_uid)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneIdMeta = const VerificationMeta(
    'timezoneId',
  );
  @override
  late final GeneratedColumn<String> timezoneId = GeneratedColumn<String>(
    'timezone_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('localOnly'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastSyncedAtUtcMsMeta = const VerificationMeta(
    'lastSyncedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAtUtcMs = GeneratedColumn<int>(
    'last_synced_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteConflictJsonMeta =
      const VerificationMeta('remoteConflictJson');
  @override
  late final GeneratedColumn<String> remoteConflictJson =
      GeneratedColumn<String>(
        'remote_conflict_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUid,
    kind,
    visibility,
    payloadJson,
    createdAtUtcMs,
    updatedAtUtcMs,
    timezoneId,
    syncStatus,
    revision,
    lastSyncedAtUtcMs,
    remoteConflictJson,
    deletedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerUidMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    } else if (isInserting) {
      context.missing(_visibilityMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('timezone_id')) {
      context.handle(
        _timezoneIdMeta,
        timezoneId.isAcceptableOrUnknown(data['timezone_id']!, _timezoneIdMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('last_synced_at_utc_ms')) {
      context.handle(
        _lastSyncedAtUtcMsMeta,
        lastSyncedAtUtcMs.isAcceptableOrUnknown(
          data['last_synced_at_utc_ms']!,
          _lastSyncedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('remote_conflict_json')) {
      context.handle(
        _remoteConflictJsonMeta,
        remoteConflictJson.isAcceptableOrUnknown(
          data['remote_conflict_json']!,
          _remoteConflictJsonMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      timezoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      lastSyncedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at_utc_ms'],
      ),
      remoteConflictJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_conflict_json'],
      ),
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
    );
  }

  @override
  $StoredRecordsTable createAlias(String alias) {
    return $StoredRecordsTable(attachedDatabase, alias);
  }
}

class StoredRecord extends DataClass implements Insertable<StoredRecord> {
  final String id;
  final String ownerUid;
  final String kind;
  final String visibility;
  final String payloadJson;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  final String? timezoneId;
  final String syncStatus;
  final int revision;
  final int? lastSyncedAtUtcMs;
  final String? remoteConflictJson;
  final int? deletedAtUtcMs;
  const StoredRecord({
    required this.id,
    required this.ownerUid,
    required this.kind,
    required this.visibility,
    required this.payloadJson,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.timezoneId,
    required this.syncStatus,
    required this.revision,
    this.lastSyncedAtUtcMs,
    this.remoteConflictJson,
    this.deletedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_uid'] = Variable<String>(ownerUid);
    map['kind'] = Variable<String>(kind);
    map['visibility'] = Variable<String>(visibility);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    if (!nullToAbsent || timezoneId != null) {
      map['timezone_id'] = Variable<String>(timezoneId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || lastSyncedAtUtcMs != null) {
      map['last_synced_at_utc_ms'] = Variable<int>(lastSyncedAtUtcMs);
    }
    if (!nullToAbsent || remoteConflictJson != null) {
      map['remote_conflict_json'] = Variable<String>(remoteConflictJson);
    }
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    return map;
  }

  StoredRecordsCompanion toCompanion(bool nullToAbsent) {
    return StoredRecordsCompanion(
      id: Value(id),
      ownerUid: Value(ownerUid),
      kind: Value(kind),
      visibility: Value(visibility),
      payloadJson: Value(payloadJson),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      timezoneId: timezoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(timezoneId),
      syncStatus: Value(syncStatus),
      revision: Value(revision),
      lastSyncedAtUtcMs: lastSyncedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAtUtcMs),
      remoteConflictJson: remoteConflictJson == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteConflictJson),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
    );
  }

  factory StoredRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredRecord(
      id: serializer.fromJson<String>(json['id']),
      ownerUid: serializer.fromJson<String>(json['ownerUid']),
      kind: serializer.fromJson<String>(json['kind']),
      visibility: serializer.fromJson<String>(json['visibility']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      timezoneId: serializer.fromJson<String?>(json['timezoneId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      revision: serializer.fromJson<int>(json['revision']),
      lastSyncedAtUtcMs: serializer.fromJson<int?>(json['lastSyncedAtUtcMs']),
      remoteConflictJson: serializer.fromJson<String?>(
        json['remoteConflictJson'],
      ),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerUid': serializer.toJson<String>(ownerUid),
      'kind': serializer.toJson<String>(kind),
      'visibility': serializer.toJson<String>(visibility),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'timezoneId': serializer.toJson<String?>(timezoneId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'revision': serializer.toJson<int>(revision),
      'lastSyncedAtUtcMs': serializer.toJson<int?>(lastSyncedAtUtcMs),
      'remoteConflictJson': serializer.toJson<String?>(remoteConflictJson),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
    };
  }

  StoredRecord copyWith({
    String? id,
    String? ownerUid,
    String? kind,
    String? visibility,
    String? payloadJson,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    Value<String?> timezoneId = const Value.absent(),
    String? syncStatus,
    int? revision,
    Value<int?> lastSyncedAtUtcMs = const Value.absent(),
    Value<String?> remoteConflictJson = const Value.absent(),
    Value<int?> deletedAtUtcMs = const Value.absent(),
  }) => StoredRecord(
    id: id ?? this.id,
    ownerUid: ownerUid ?? this.ownerUid,
    kind: kind ?? this.kind,
    visibility: visibility ?? this.visibility,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    timezoneId: timezoneId.present ? timezoneId.value : this.timezoneId,
    syncStatus: syncStatus ?? this.syncStatus,
    revision: revision ?? this.revision,
    lastSyncedAtUtcMs: lastSyncedAtUtcMs.present
        ? lastSyncedAtUtcMs.value
        : this.lastSyncedAtUtcMs,
    remoteConflictJson: remoteConflictJson.present
        ? remoteConflictJson.value
        : this.remoteConflictJson,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
  );
  StoredRecord copyWithCompanion(StoredRecordsCompanion data) {
    return StoredRecord(
      id: data.id.present ? data.id.value : this.id,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      kind: data.kind.present ? data.kind.value : this.kind,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      timezoneId: data.timezoneId.present
          ? data.timezoneId.value
          : this.timezoneId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      revision: data.revision.present ? data.revision.value : this.revision,
      lastSyncedAtUtcMs: data.lastSyncedAtUtcMs.present
          ? data.lastSyncedAtUtcMs.value
          : this.lastSyncedAtUtcMs,
      remoteConflictJson: data.remoteConflictJson.present
          ? data.remoteConflictJson.value
          : this.remoteConflictJson,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredRecord(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('kind: $kind, ')
          ..write('visibility: $visibility, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('timezoneId: $timezoneId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('revision: $revision, ')
          ..write('lastSyncedAtUtcMs: $lastSyncedAtUtcMs, ')
          ..write('remoteConflictJson: $remoteConflictJson, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUid,
    kind,
    visibility,
    payloadJson,
    createdAtUtcMs,
    updatedAtUtcMs,
    timezoneId,
    syncStatus,
    revision,
    lastSyncedAtUtcMs,
    remoteConflictJson,
    deletedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredRecord &&
          other.id == this.id &&
          other.ownerUid == this.ownerUid &&
          other.kind == this.kind &&
          other.visibility == this.visibility &&
          other.payloadJson == this.payloadJson &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.timezoneId == this.timezoneId &&
          other.syncStatus == this.syncStatus &&
          other.revision == this.revision &&
          other.lastSyncedAtUtcMs == this.lastSyncedAtUtcMs &&
          other.remoteConflictJson == this.remoteConflictJson &&
          other.deletedAtUtcMs == this.deletedAtUtcMs);
}

class StoredRecordsCompanion extends UpdateCompanion<StoredRecord> {
  final Value<String> id;
  final Value<String> ownerUid;
  final Value<String> kind;
  final Value<String> visibility;
  final Value<String> payloadJson;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<String?> timezoneId;
  final Value<String> syncStatus;
  final Value<int> revision;
  final Value<int?> lastSyncedAtUtcMs;
  final Value<String?> remoteConflictJson;
  final Value<int?> deletedAtUtcMs;
  final Value<int> rowid;
  const StoredRecordsCompanion({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.kind = const Value.absent(),
    this.visibility = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.timezoneId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.revision = const Value.absent(),
    this.lastSyncedAtUtcMs = const Value.absent(),
    this.remoteConflictJson = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredRecordsCompanion.insert({
    required String id,
    required String ownerUid,
    required String kind,
    required String visibility,
    required String payloadJson,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.timezoneId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.revision = const Value.absent(),
    this.lastSyncedAtUtcMs = const Value.absent(),
    this.remoteConflictJson = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerUid = Value(ownerUid),
       kind = Value(kind),
       visibility = Value(visibility),
       payloadJson = Value(payloadJson),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs);
  static Insertable<StoredRecord> custom({
    Expression<String>? id,
    Expression<String>? ownerUid,
    Expression<String>? kind,
    Expression<String>? visibility,
    Expression<String>? payloadJson,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<String>? timezoneId,
    Expression<String>? syncStatus,
    Expression<int>? revision,
    Expression<int>? lastSyncedAtUtcMs,
    Expression<String>? remoteConflictJson,
    Expression<int>? deletedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (kind != null) 'kind': kind,
      if (visibility != null) 'visibility': visibility,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (timezoneId != null) 'timezone_id': timezoneId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (revision != null) 'revision': revision,
      if (lastSyncedAtUtcMs != null) 'last_synced_at_utc_ms': lastSyncedAtUtcMs,
      if (remoteConflictJson != null)
        'remote_conflict_json': remoteConflictJson,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerUid,
    Value<String>? kind,
    Value<String>? visibility,
    Value<String>? payloadJson,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<String?>? timezoneId,
    Value<String>? syncStatus,
    Value<int>? revision,
    Value<int?>? lastSyncedAtUtcMs,
    Value<String?>? remoteConflictJson,
    Value<int?>? deletedAtUtcMs,
    Value<int>? rowid,
  }) {
    return StoredRecordsCompanion(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      kind: kind ?? this.kind,
      visibility: visibility ?? this.visibility,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      timezoneId: timezoneId ?? this.timezoneId,
      syncStatus: syncStatus ?? this.syncStatus,
      revision: revision ?? this.revision,
      lastSyncedAtUtcMs: lastSyncedAtUtcMs ?? this.lastSyncedAtUtcMs,
      remoteConflictJson: remoteConflictJson ?? this.remoteConflictJson,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (timezoneId.present) {
      map['timezone_id'] = Variable<String>(timezoneId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (lastSyncedAtUtcMs.present) {
      map['last_synced_at_utc_ms'] = Variable<int>(lastSyncedAtUtcMs.value);
    }
    if (remoteConflictJson.present) {
      map['remote_conflict_json'] = Variable<String>(remoteConflictJson.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredRecordsCompanion(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('kind: $kind, ')
          ..write('visibility: $visibility, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('timezoneId: $timezoneId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('revision: $revision, ')
          ..write('lastSyncedAtUtcMs: $lastSyncedAtUtcMs, ')
          ..write('remoteConflictJson: $remoteConflictJson, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityHistoryTable extends ActivityHistory
    with TableInfo<$ActivityHistoryTable, ActivityHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUidMeta = const VerificationMeta(
    'ownerUid',
  );
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
    'owner_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (auth_uid)',
    ),
  );
  static const VerificationMeta _definitionIdMeta = const VerificationMeta(
    'definitionId',
  );
  @override
  late final GeneratedColumn<String> definitionId = GeneratedColumn<String>(
    'definition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceKeyMeta = const VerificationMeta(
    'occurrenceKey',
  );
  @override
  late final GeneratedColumn<String> occurrenceKey = GeneratedColumn<String>(
    'occurrence_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtUtcMsMeta = const VerificationMeta(
    'recordedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> recordedAtUtcMs = GeneratedColumn<int>(
    'recorded_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUid,
    definitionId,
    kind,
    occurrenceKey,
    localDate,
    visibility,
    payloadJson,
    recordedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerUidMeta);
    }
    if (data.containsKey('definition_id')) {
      context.handle(
        _definitionIdMeta,
        definitionId.isAcceptableOrUnknown(
          data['definition_id']!,
          _definitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('occurrence_key')) {
      context.handle(
        _occurrenceKeyMeta,
        occurrenceKey.isAcceptableOrUnknown(
          data['occurrence_key']!,
          _occurrenceKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceKeyMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    } else if (isInserting) {
      context.missing(_visibilityMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('recorded_at_utc_ms')) {
      context.handle(
        _recordedAtUtcMsMeta,
        recordedAtUtcMs.isAcceptableOrUnknown(
          data['recorded_at_utc_ms']!,
          _recordedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ownerUid, definitionId, kind, occurrenceKey},
  ];
  @override
  ActivityHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
      )!,
      definitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      occurrenceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_key'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      recordedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at_utc_ms'],
      )!,
    );
  }

  @override
  $ActivityHistoryTable createAlias(String alias) {
    return $ActivityHistoryTable(attachedDatabase, alias);
  }
}

class ActivityHistoryData extends DataClass
    implements Insertable<ActivityHistoryData> {
  final String id;
  final String ownerUid;
  final String definitionId;
  final String kind;
  final String occurrenceKey;
  final String localDate;
  final String visibility;
  final String payloadJson;
  final int recordedAtUtcMs;
  const ActivityHistoryData({
    required this.id,
    required this.ownerUid,
    required this.definitionId,
    required this.kind,
    required this.occurrenceKey,
    required this.localDate,
    required this.visibility,
    required this.payloadJson,
    required this.recordedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_uid'] = Variable<String>(ownerUid);
    map['definition_id'] = Variable<String>(definitionId);
    map['kind'] = Variable<String>(kind);
    map['occurrence_key'] = Variable<String>(occurrenceKey);
    map['local_date'] = Variable<String>(localDate);
    map['visibility'] = Variable<String>(visibility);
    map['payload_json'] = Variable<String>(payloadJson);
    map['recorded_at_utc_ms'] = Variable<int>(recordedAtUtcMs);
    return map;
  }

  ActivityHistoryCompanion toCompanion(bool nullToAbsent) {
    return ActivityHistoryCompanion(
      id: Value(id),
      ownerUid: Value(ownerUid),
      definitionId: Value(definitionId),
      kind: Value(kind),
      occurrenceKey: Value(occurrenceKey),
      localDate: Value(localDate),
      visibility: Value(visibility),
      payloadJson: Value(payloadJson),
      recordedAtUtcMs: Value(recordedAtUtcMs),
    );
  }

  factory ActivityHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityHistoryData(
      id: serializer.fromJson<String>(json['id']),
      ownerUid: serializer.fromJson<String>(json['ownerUid']),
      definitionId: serializer.fromJson<String>(json['definitionId']),
      kind: serializer.fromJson<String>(json['kind']),
      occurrenceKey: serializer.fromJson<String>(json['occurrenceKey']),
      localDate: serializer.fromJson<String>(json['localDate']),
      visibility: serializer.fromJson<String>(json['visibility']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      recordedAtUtcMs: serializer.fromJson<int>(json['recordedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerUid': serializer.toJson<String>(ownerUid),
      'definitionId': serializer.toJson<String>(definitionId),
      'kind': serializer.toJson<String>(kind),
      'occurrenceKey': serializer.toJson<String>(occurrenceKey),
      'localDate': serializer.toJson<String>(localDate),
      'visibility': serializer.toJson<String>(visibility),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'recordedAtUtcMs': serializer.toJson<int>(recordedAtUtcMs),
    };
  }

  ActivityHistoryData copyWith({
    String? id,
    String? ownerUid,
    String? definitionId,
    String? kind,
    String? occurrenceKey,
    String? localDate,
    String? visibility,
    String? payloadJson,
    int? recordedAtUtcMs,
  }) => ActivityHistoryData(
    id: id ?? this.id,
    ownerUid: ownerUid ?? this.ownerUid,
    definitionId: definitionId ?? this.definitionId,
    kind: kind ?? this.kind,
    occurrenceKey: occurrenceKey ?? this.occurrenceKey,
    localDate: localDate ?? this.localDate,
    visibility: visibility ?? this.visibility,
    payloadJson: payloadJson ?? this.payloadJson,
    recordedAtUtcMs: recordedAtUtcMs ?? this.recordedAtUtcMs,
  );
  ActivityHistoryData copyWithCompanion(ActivityHistoryCompanion data) {
    return ActivityHistoryData(
      id: data.id.present ? data.id.value : this.id,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      definitionId: data.definitionId.present
          ? data.definitionId.value
          : this.definitionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      occurrenceKey: data.occurrenceKey.present
          ? data.occurrenceKey.value
          : this.occurrenceKey,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      recordedAtUtcMs: data.recordedAtUtcMs.present
          ? data.recordedAtUtcMs.value
          : this.recordedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityHistoryData(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('definitionId: $definitionId, ')
          ..write('kind: $kind, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('localDate: $localDate, ')
          ..write('visibility: $visibility, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('recordedAtUtcMs: $recordedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUid,
    definitionId,
    kind,
    occurrenceKey,
    localDate,
    visibility,
    payloadJson,
    recordedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityHistoryData &&
          other.id == this.id &&
          other.ownerUid == this.ownerUid &&
          other.definitionId == this.definitionId &&
          other.kind == this.kind &&
          other.occurrenceKey == this.occurrenceKey &&
          other.localDate == this.localDate &&
          other.visibility == this.visibility &&
          other.payloadJson == this.payloadJson &&
          other.recordedAtUtcMs == this.recordedAtUtcMs);
}

class ActivityHistoryCompanion extends UpdateCompanion<ActivityHistoryData> {
  final Value<String> id;
  final Value<String> ownerUid;
  final Value<String> definitionId;
  final Value<String> kind;
  final Value<String> occurrenceKey;
  final Value<String> localDate;
  final Value<String> visibility;
  final Value<String> payloadJson;
  final Value<int> recordedAtUtcMs;
  final Value<int> rowid;
  const ActivityHistoryCompanion({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.definitionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.occurrenceKey = const Value.absent(),
    this.localDate = const Value.absent(),
    this.visibility = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.recordedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityHistoryCompanion.insert({
    required String id,
    required String ownerUid,
    required String definitionId,
    required String kind,
    required String occurrenceKey,
    required String localDate,
    required String visibility,
    required String payloadJson,
    required int recordedAtUtcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerUid = Value(ownerUid),
       definitionId = Value(definitionId),
       kind = Value(kind),
       occurrenceKey = Value(occurrenceKey),
       localDate = Value(localDate),
       visibility = Value(visibility),
       payloadJson = Value(payloadJson),
       recordedAtUtcMs = Value(recordedAtUtcMs);
  static Insertable<ActivityHistoryData> custom({
    Expression<String>? id,
    Expression<String>? ownerUid,
    Expression<String>? definitionId,
    Expression<String>? kind,
    Expression<String>? occurrenceKey,
    Expression<String>? localDate,
    Expression<String>? visibility,
    Expression<String>? payloadJson,
    Expression<int>? recordedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (definitionId != null) 'definition_id': definitionId,
      if (kind != null) 'kind': kind,
      if (occurrenceKey != null) 'occurrence_key': occurrenceKey,
      if (localDate != null) 'local_date': localDate,
      if (visibility != null) 'visibility': visibility,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (recordedAtUtcMs != null) 'recorded_at_utc_ms': recordedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerUid,
    Value<String>? definitionId,
    Value<String>? kind,
    Value<String>? occurrenceKey,
    Value<String>? localDate,
    Value<String>? visibility,
    Value<String>? payloadJson,
    Value<int>? recordedAtUtcMs,
    Value<int>? rowid,
  }) {
    return ActivityHistoryCompanion(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      definitionId: definitionId ?? this.definitionId,
      kind: kind ?? this.kind,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      localDate: localDate ?? this.localDate,
      visibility: visibility ?? this.visibility,
      payloadJson: payloadJson ?? this.payloadJson,
      recordedAtUtcMs: recordedAtUtcMs ?? this.recordedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (definitionId.present) {
      map['definition_id'] = Variable<String>(definitionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (occurrenceKey.present) {
      map['occurrence_key'] = Variable<String>(occurrenceKey.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (recordedAtUtcMs.present) {
      map['recorded_at_utc_ms'] = Variable<int>(recordedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityHistoryCompanion(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('definitionId: $definitionId, ')
          ..write('kind: $kind, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('localDate: $localDate, ')
          ..write('visibility: $visibility, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('recordedAtUtcMs: $recordedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackingEntriesTable extends TrackingEntries
    with TableInfo<$TrackingEntriesTable, TrackingEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUidMeta = const VerificationMeta(
    'ownerUid',
  );
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
    'owner_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (auth_uid)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryKeyMeta = const VerificationMeta(
    'entryKey',
  );
  @override
  late final GeneratedColumn<String> entryKey = GeneratedColumn<String>(
    'entry_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUid,
    kind,
    localDate,
    entryKey,
    visibility,
    payloadJson,
    createdAtUtcMs,
    updatedAtUtcMs,
    revision,
    deletedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackingEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerUidMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('entry_key')) {
      context.handle(
        _entryKeyMeta,
        entryKey.isAcceptableOrUnknown(data['entry_key']!, _entryKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entryKeyMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    } else if (isInserting) {
      context.missing(_visibilityMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      entryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_key'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
    );
  }

  @override
  $TrackingEntriesTable createAlias(String alias) {
    return $TrackingEntriesTable(attachedDatabase, alias);
  }
}

class TrackingEntryRow extends DataClass
    implements Insertable<TrackingEntryRow> {
  final String id;
  final String ownerUid;
  final String kind;
  final String localDate;
  final String entryKey;
  final String visibility;
  final String payloadJson;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  final int revision;
  final int? deletedAtUtcMs;
  const TrackingEntryRow({
    required this.id,
    required this.ownerUid,
    required this.kind,
    required this.localDate,
    required this.entryKey,
    required this.visibility,
    required this.payloadJson,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    required this.revision,
    this.deletedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_uid'] = Variable<String>(ownerUid);
    map['kind'] = Variable<String>(kind);
    map['local_date'] = Variable<String>(localDate);
    map['entry_key'] = Variable<String>(entryKey);
    map['visibility'] = Variable<String>(visibility);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    return map;
  }

  TrackingEntriesCompanion toCompanion(bool nullToAbsent) {
    return TrackingEntriesCompanion(
      id: Value(id),
      ownerUid: Value(ownerUid),
      kind: Value(kind),
      localDate: Value(localDate),
      entryKey: Value(entryKey),
      visibility: Value(visibility),
      payloadJson: Value(payloadJson),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      revision: Value(revision),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
    );
  }

  factory TrackingEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingEntryRow(
      id: serializer.fromJson<String>(json['id']),
      ownerUid: serializer.fromJson<String>(json['ownerUid']),
      kind: serializer.fromJson<String>(json['kind']),
      localDate: serializer.fromJson<String>(json['localDate']),
      entryKey: serializer.fromJson<String>(json['entryKey']),
      visibility: serializer.fromJson<String>(json['visibility']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      revision: serializer.fromJson<int>(json['revision']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerUid': serializer.toJson<String>(ownerUid),
      'kind': serializer.toJson<String>(kind),
      'localDate': serializer.toJson<String>(localDate),
      'entryKey': serializer.toJson<String>(entryKey),
      'visibility': serializer.toJson<String>(visibility),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'revision': serializer.toJson<int>(revision),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
    };
  }

  TrackingEntryRow copyWith({
    String? id,
    String? ownerUid,
    String? kind,
    String? localDate,
    String? entryKey,
    String? visibility,
    String? payloadJson,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    int? revision,
    Value<int?> deletedAtUtcMs = const Value.absent(),
  }) => TrackingEntryRow(
    id: id ?? this.id,
    ownerUid: ownerUid ?? this.ownerUid,
    kind: kind ?? this.kind,
    localDate: localDate ?? this.localDate,
    entryKey: entryKey ?? this.entryKey,
    visibility: visibility ?? this.visibility,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    revision: revision ?? this.revision,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
  );
  TrackingEntryRow copyWithCompanion(TrackingEntriesCompanion data) {
    return TrackingEntryRow(
      id: data.id.present ? data.id.value : this.id,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      kind: data.kind.present ? data.kind.value : this.kind,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      entryKey: data.entryKey.present ? data.entryKey.value : this.entryKey,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      revision: data.revision.present ? data.revision.value : this.revision,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEntryRow(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('kind: $kind, ')
          ..write('localDate: $localDate, ')
          ..write('entryKey: $entryKey, ')
          ..write('visibility: $visibility, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('revision: $revision, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUid,
    kind,
    localDate,
    entryKey,
    visibility,
    payloadJson,
    createdAtUtcMs,
    updatedAtUtcMs,
    revision,
    deletedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingEntryRow &&
          other.id == this.id &&
          other.ownerUid == this.ownerUid &&
          other.kind == this.kind &&
          other.localDate == this.localDate &&
          other.entryKey == this.entryKey &&
          other.visibility == this.visibility &&
          other.payloadJson == this.payloadJson &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.revision == this.revision &&
          other.deletedAtUtcMs == this.deletedAtUtcMs);
}

class TrackingEntriesCompanion extends UpdateCompanion<TrackingEntryRow> {
  final Value<String> id;
  final Value<String> ownerUid;
  final Value<String> kind;
  final Value<String> localDate;
  final Value<String> entryKey;
  final Value<String> visibility;
  final Value<String> payloadJson;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int> revision;
  final Value<int?> deletedAtUtcMs;
  final Value<int> rowid;
  const TrackingEntriesCompanion({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.kind = const Value.absent(),
    this.localDate = const Value.absent(),
    this.entryKey = const Value.absent(),
    this.visibility = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.revision = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackingEntriesCompanion.insert({
    required String id,
    required String ownerUid,
    required String kind,
    required String localDate,
    required String entryKey,
    required String visibility,
    required String payloadJson,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.revision = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerUid = Value(ownerUid),
       kind = Value(kind),
       localDate = Value(localDate),
       entryKey = Value(entryKey),
       visibility = Value(visibility),
       payloadJson = Value(payloadJson),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs);
  static Insertable<TrackingEntryRow> custom({
    Expression<String>? id,
    Expression<String>? ownerUid,
    Expression<String>? kind,
    Expression<String>? localDate,
    Expression<String>? entryKey,
    Expression<String>? visibility,
    Expression<String>? payloadJson,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? revision,
    Expression<int>? deletedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (kind != null) 'kind': kind,
      if (localDate != null) 'local_date': localDate,
      if (entryKey != null) 'entry_key': entryKey,
      if (visibility != null) 'visibility': visibility,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (revision != null) 'revision': revision,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackingEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerUid,
    Value<String>? kind,
    Value<String>? localDate,
    Value<String>? entryKey,
    Value<String>? visibility,
    Value<String>? payloadJson,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int>? revision,
    Value<int?>? deletedAtUtcMs,
    Value<int>? rowid,
  }) {
    return TrackingEntriesCompanion(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      kind: kind ?? this.kind,
      localDate: localDate ?? this.localDate,
      entryKey: entryKey ?? this.entryKey,
      visibility: visibility ?? this.visibility,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      revision: revision ?? this.revision,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (entryKey.present) {
      map['entry_key'] = Variable<String>(entryKey.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEntriesCompanion(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('kind: $kind, ')
          ..write('localDate: $localDate, ')
          ..write('entryKey: $entryKey, ')
          ..write('visibility: $visibility, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('revision: $revision, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskPlanImportsTable extends TaskPlanImports
    with TableInfo<$TaskPlanImportsTable, TaskPlanImport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskPlanImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUidMeta = const VerificationMeta(
    'ownerUid',
  );
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
    'owner_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (auth_uid)',
    ),
  );
  static const VerificationMeta _sourceFingerprintMeta = const VerificationMeta(
    'sourceFingerprint',
  );
  @override
  late final GeneratedColumn<String> sourceFingerprint =
      GeneratedColumn<String>(
        'source_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parserVersionMeta = const VerificationMeta(
    'parserVersion',
  );
  @override
  late final GeneratedColumn<String> parserVersion = GeneratedColumn<String>(
    'parser_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdsJsonMeta = const VerificationMeta(
    'taskIdsJson',
  );
  @override
  late final GeneratedColumn<String> taskIdsJson = GeneratedColumn<String>(
    'task_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtUtcMsMeta = const VerificationMeta(
    'importedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> importedAtUtcMs = GeneratedColumn<int>(
    'imported_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUid,
    sourceFingerprint,
    startDate,
    parserVersion,
    taskIdsJson,
    importedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_plan_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskPlanImport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerUidMeta);
    }
    if (data.containsKey('source_fingerprint')) {
      context.handle(
        _sourceFingerprintMeta,
        sourceFingerprint.isAcceptableOrUnknown(
          data['source_fingerprint']!,
          _sourceFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceFingerprintMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('parser_version')) {
      context.handle(
        _parserVersionMeta,
        parserVersion.isAcceptableOrUnknown(
          data['parser_version']!,
          _parserVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parserVersionMeta);
    }
    if (data.containsKey('task_ids_json')) {
      context.handle(
        _taskIdsJsonMeta,
        taskIdsJson.isAcceptableOrUnknown(
          data['task_ids_json']!,
          _taskIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taskIdsJsonMeta);
    }
    if (data.containsKey('imported_at_utc_ms')) {
      context.handle(
        _importedAtUtcMsMeta,
        importedAtUtcMs.isAcceptableOrUnknown(
          data['imported_at_utc_ms']!,
          _importedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importedAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ownerUid, sourceFingerprint, startDate, parserVersion},
  ];
  @override
  TaskPlanImport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskPlanImport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
      )!,
      sourceFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_fingerprint'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      parserVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parser_version'],
      )!,
      taskIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_ids_json'],
      )!,
      importedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_at_utc_ms'],
      )!,
    );
  }

  @override
  $TaskPlanImportsTable createAlias(String alias) {
    return $TaskPlanImportsTable(attachedDatabase, alias);
  }
}

class TaskPlanImport extends DataClass implements Insertable<TaskPlanImport> {
  final String id;
  final String ownerUid;
  final String sourceFingerprint;
  final String startDate;
  final String parserVersion;
  final String taskIdsJson;
  final int importedAtUtcMs;
  const TaskPlanImport({
    required this.id,
    required this.ownerUid,
    required this.sourceFingerprint,
    required this.startDate,
    required this.parserVersion,
    required this.taskIdsJson,
    required this.importedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_uid'] = Variable<String>(ownerUid);
    map['source_fingerprint'] = Variable<String>(sourceFingerprint);
    map['start_date'] = Variable<String>(startDate);
    map['parser_version'] = Variable<String>(parserVersion);
    map['task_ids_json'] = Variable<String>(taskIdsJson);
    map['imported_at_utc_ms'] = Variable<int>(importedAtUtcMs);
    return map;
  }

  TaskPlanImportsCompanion toCompanion(bool nullToAbsent) {
    return TaskPlanImportsCompanion(
      id: Value(id),
      ownerUid: Value(ownerUid),
      sourceFingerprint: Value(sourceFingerprint),
      startDate: Value(startDate),
      parserVersion: Value(parserVersion),
      taskIdsJson: Value(taskIdsJson),
      importedAtUtcMs: Value(importedAtUtcMs),
    );
  }

  factory TaskPlanImport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskPlanImport(
      id: serializer.fromJson<String>(json['id']),
      ownerUid: serializer.fromJson<String>(json['ownerUid']),
      sourceFingerprint: serializer.fromJson<String>(json['sourceFingerprint']),
      startDate: serializer.fromJson<String>(json['startDate']),
      parserVersion: serializer.fromJson<String>(json['parserVersion']),
      taskIdsJson: serializer.fromJson<String>(json['taskIdsJson']),
      importedAtUtcMs: serializer.fromJson<int>(json['importedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerUid': serializer.toJson<String>(ownerUid),
      'sourceFingerprint': serializer.toJson<String>(sourceFingerprint),
      'startDate': serializer.toJson<String>(startDate),
      'parserVersion': serializer.toJson<String>(parserVersion),
      'taskIdsJson': serializer.toJson<String>(taskIdsJson),
      'importedAtUtcMs': serializer.toJson<int>(importedAtUtcMs),
    };
  }

  TaskPlanImport copyWith({
    String? id,
    String? ownerUid,
    String? sourceFingerprint,
    String? startDate,
    String? parserVersion,
    String? taskIdsJson,
    int? importedAtUtcMs,
  }) => TaskPlanImport(
    id: id ?? this.id,
    ownerUid: ownerUid ?? this.ownerUid,
    sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
    startDate: startDate ?? this.startDate,
    parserVersion: parserVersion ?? this.parserVersion,
    taskIdsJson: taskIdsJson ?? this.taskIdsJson,
    importedAtUtcMs: importedAtUtcMs ?? this.importedAtUtcMs,
  );
  TaskPlanImport copyWithCompanion(TaskPlanImportsCompanion data) {
    return TaskPlanImport(
      id: data.id.present ? data.id.value : this.id,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      sourceFingerprint: data.sourceFingerprint.present
          ? data.sourceFingerprint.value
          : this.sourceFingerprint,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      parserVersion: data.parserVersion.present
          ? data.parserVersion.value
          : this.parserVersion,
      taskIdsJson: data.taskIdsJson.present
          ? data.taskIdsJson.value
          : this.taskIdsJson,
      importedAtUtcMs: data.importedAtUtcMs.present
          ? data.importedAtUtcMs.value
          : this.importedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskPlanImport(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('startDate: $startDate, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('taskIdsJson: $taskIdsJson, ')
          ..write('importedAtUtcMs: $importedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUid,
    sourceFingerprint,
    startDate,
    parserVersion,
    taskIdsJson,
    importedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskPlanImport &&
          other.id == this.id &&
          other.ownerUid == this.ownerUid &&
          other.sourceFingerprint == this.sourceFingerprint &&
          other.startDate == this.startDate &&
          other.parserVersion == this.parserVersion &&
          other.taskIdsJson == this.taskIdsJson &&
          other.importedAtUtcMs == this.importedAtUtcMs);
}

class TaskPlanImportsCompanion extends UpdateCompanion<TaskPlanImport> {
  final Value<String> id;
  final Value<String> ownerUid;
  final Value<String> sourceFingerprint;
  final Value<String> startDate;
  final Value<String> parserVersion;
  final Value<String> taskIdsJson;
  final Value<int> importedAtUtcMs;
  final Value<int> rowid;
  const TaskPlanImportsCompanion({
    this.id = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.sourceFingerprint = const Value.absent(),
    this.startDate = const Value.absent(),
    this.parserVersion = const Value.absent(),
    this.taskIdsJson = const Value.absent(),
    this.importedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskPlanImportsCompanion.insert({
    required String id,
    required String ownerUid,
    required String sourceFingerprint,
    required String startDate,
    required String parserVersion,
    required String taskIdsJson,
    required int importedAtUtcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerUid = Value(ownerUid),
       sourceFingerprint = Value(sourceFingerprint),
       startDate = Value(startDate),
       parserVersion = Value(parserVersion),
       taskIdsJson = Value(taskIdsJson),
       importedAtUtcMs = Value(importedAtUtcMs);
  static Insertable<TaskPlanImport> custom({
    Expression<String>? id,
    Expression<String>? ownerUid,
    Expression<String>? sourceFingerprint,
    Expression<String>? startDate,
    Expression<String>? parserVersion,
    Expression<String>? taskIdsJson,
    Expression<int>? importedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (sourceFingerprint != null) 'source_fingerprint': sourceFingerprint,
      if (startDate != null) 'start_date': startDate,
      if (parserVersion != null) 'parser_version': parserVersion,
      if (taskIdsJson != null) 'task_ids_json': taskIdsJson,
      if (importedAtUtcMs != null) 'imported_at_utc_ms': importedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskPlanImportsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerUid,
    Value<String>? sourceFingerprint,
    Value<String>? startDate,
    Value<String>? parserVersion,
    Value<String>? taskIdsJson,
    Value<int>? importedAtUtcMs,
    Value<int>? rowid,
  }) {
    return TaskPlanImportsCompanion(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
      startDate: startDate ?? this.startDate,
      parserVersion: parserVersion ?? this.parserVersion,
      taskIdsJson: taskIdsJson ?? this.taskIdsJson,
      importedAtUtcMs: importedAtUtcMs ?? this.importedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (sourceFingerprint.present) {
      map['source_fingerprint'] = Variable<String>(sourceFingerprint.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (parserVersion.present) {
      map['parser_version'] = Variable<String>(parserVersion.value);
    }
    if (taskIdsJson.present) {
      map['task_ids_json'] = Variable<String>(taskIdsJson.value);
    }
    if (importedAtUtcMs.present) {
      map['imported_at_utc_ms'] = Variable<int>(importedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskPlanImportsCompanion(')
          ..write('id: $id, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('startDate: $startDate, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('taskIdsJson: $taskIdsJson, ')
          ..write('importedAtUtcMs: $importedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SharedTaskAssignmentOutboxTable extends SharedTaskAssignmentOutbox
    with
        TableInfo<
          $SharedTaskAssignmentOutboxTable,
          SharedTaskAssignmentOutboxData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SharedTaskAssignmentOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerUidMeta = const VerificationMeta(
    'ownerUid',
  );
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
    'owner_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<String> deadline = GeneratedColumn<String>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtUtcMsMeta = const VerificationMeta(
    'queuedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> queuedAtUtcMs = GeneratedColumn<int>(
    'queued_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerUid,
    idempotencyKey,
    title,
    date,
    priority,
    durationMinutes,
    deadline,
    notes,
    queuedAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared_task_assignment_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SharedTaskAssignmentOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerUidMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('queued_at_utc_ms')) {
      context.handle(
        _queuedAtUtcMsMeta,
        queuedAtUtcMs.isAcceptableOrUnknown(
          data['queued_at_utc_ms']!,
          _queuedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queuedAtUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerUid};
  @override
  SharedTaskAssignmentOutboxData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SharedTaskAssignmentOutboxData(
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deadline'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      queuedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queued_at_utc_ms'],
      )!,
    );
  }

  @override
  $SharedTaskAssignmentOutboxTable createAlias(String alias) {
    return $SharedTaskAssignmentOutboxTable(attachedDatabase, alias);
  }
}

class SharedTaskAssignmentOutboxData extends DataClass
    implements Insertable<SharedTaskAssignmentOutboxData> {
  final String ownerUid;
  final String idempotencyKey;
  final String title;
  final String date;
  final int priority;
  final int durationMinutes;
  final String? deadline;
  final String notes;
  final int queuedAtUtcMs;
  const SharedTaskAssignmentOutboxData({
    required this.ownerUid,
    required this.idempotencyKey,
    required this.title,
    required this.date,
    required this.priority,
    required this.durationMinutes,
    this.deadline,
    required this.notes,
    required this.queuedAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_uid'] = Variable<String>(ownerUid);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<String>(date);
    map['priority'] = Variable<int>(priority);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<String>(deadline);
    }
    map['notes'] = Variable<String>(notes);
    map['queued_at_utc_ms'] = Variable<int>(queuedAtUtcMs);
    return map;
  }

  SharedTaskAssignmentOutboxCompanion toCompanion(bool nullToAbsent) {
    return SharedTaskAssignmentOutboxCompanion(
      ownerUid: Value(ownerUid),
      idempotencyKey: Value(idempotencyKey),
      title: Value(title),
      date: Value(date),
      priority: Value(priority),
      durationMinutes: Value(durationMinutes),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      notes: Value(notes),
      queuedAtUtcMs: Value(queuedAtUtcMs),
    );
  }

  factory SharedTaskAssignmentOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedTaskAssignmentOutboxData(
      ownerUid: serializer.fromJson<String>(json['ownerUid']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<String>(json['date']),
      priority: serializer.fromJson<int>(json['priority']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      deadline: serializer.fromJson<String?>(json['deadline']),
      notes: serializer.fromJson<String>(json['notes']),
      queuedAtUtcMs: serializer.fromJson<int>(json['queuedAtUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerUid': serializer.toJson<String>(ownerUid),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<String>(date),
      'priority': serializer.toJson<int>(priority),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'deadline': serializer.toJson<String?>(deadline),
      'notes': serializer.toJson<String>(notes),
      'queuedAtUtcMs': serializer.toJson<int>(queuedAtUtcMs),
    };
  }

  SharedTaskAssignmentOutboxData copyWith({
    String? ownerUid,
    String? idempotencyKey,
    String? title,
    String? date,
    int? priority,
    int? durationMinutes,
    Value<String?> deadline = const Value.absent(),
    String? notes,
    int? queuedAtUtcMs,
  }) => SharedTaskAssignmentOutboxData(
    ownerUid: ownerUid ?? this.ownerUid,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    title: title ?? this.title,
    date: date ?? this.date,
    priority: priority ?? this.priority,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    deadline: deadline.present ? deadline.value : this.deadline,
    notes: notes ?? this.notes,
    queuedAtUtcMs: queuedAtUtcMs ?? this.queuedAtUtcMs,
  );
  SharedTaskAssignmentOutboxData copyWithCompanion(
    SharedTaskAssignmentOutboxCompanion data,
  ) {
    return SharedTaskAssignmentOutboxData(
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      priority: data.priority.present ? data.priority.value : this.priority,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      notes: data.notes.present ? data.notes.value : this.notes,
      queuedAtUtcMs: data.queuedAtUtcMs.present
          ? data.queuedAtUtcMs.value
          : this.queuedAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SharedTaskAssignmentOutboxData(')
          ..write('ownerUid: $ownerUid, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('priority: $priority, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('deadline: $deadline, ')
          ..write('notes: $notes, ')
          ..write('queuedAtUtcMs: $queuedAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerUid,
    idempotencyKey,
    title,
    date,
    priority,
    durationMinutes,
    deadline,
    notes,
    queuedAtUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharedTaskAssignmentOutboxData &&
          other.ownerUid == this.ownerUid &&
          other.idempotencyKey == this.idempotencyKey &&
          other.title == this.title &&
          other.date == this.date &&
          other.priority == this.priority &&
          other.durationMinutes == this.durationMinutes &&
          other.deadline == this.deadline &&
          other.notes == this.notes &&
          other.queuedAtUtcMs == this.queuedAtUtcMs);
}

class SharedTaskAssignmentOutboxCompanion
    extends UpdateCompanion<SharedTaskAssignmentOutboxData> {
  final Value<String> ownerUid;
  final Value<String> idempotencyKey;
  final Value<String> title;
  final Value<String> date;
  final Value<int> priority;
  final Value<int> durationMinutes;
  final Value<String?> deadline;
  final Value<String> notes;
  final Value<int> queuedAtUtcMs;
  final Value<int> rowid;
  const SharedTaskAssignmentOutboxCompanion({
    this.ownerUid = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.priority = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.deadline = const Value.absent(),
    this.notes = const Value.absent(),
    this.queuedAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SharedTaskAssignmentOutboxCompanion.insert({
    required String ownerUid,
    required String idempotencyKey,
    required String title,
    required String date,
    required int priority,
    required int durationMinutes,
    this.deadline = const Value.absent(),
    required String notes,
    required int queuedAtUtcMs,
    this.rowid = const Value.absent(),
  }) : ownerUid = Value(ownerUid),
       idempotencyKey = Value(idempotencyKey),
       title = Value(title),
       date = Value(date),
       priority = Value(priority),
       durationMinutes = Value(durationMinutes),
       notes = Value(notes),
       queuedAtUtcMs = Value(queuedAtUtcMs);
  static Insertable<SharedTaskAssignmentOutboxData> custom({
    Expression<String>? ownerUid,
    Expression<String>? idempotencyKey,
    Expression<String>? title,
    Expression<String>? date,
    Expression<int>? priority,
    Expression<int>? durationMinutes,
    Expression<String>? deadline,
    Expression<String>? notes,
    Expression<int>? queuedAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (priority != null) 'priority': priority,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (deadline != null) 'deadline': deadline,
      if (notes != null) 'notes': notes,
      if (queuedAtUtcMs != null) 'queued_at_utc_ms': queuedAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SharedTaskAssignmentOutboxCompanion copyWith({
    Value<String>? ownerUid,
    Value<String>? idempotencyKey,
    Value<String>? title,
    Value<String>? date,
    Value<int>? priority,
    Value<int>? durationMinutes,
    Value<String?>? deadline,
    Value<String>? notes,
    Value<int>? queuedAtUtcMs,
    Value<int>? rowid,
  }) {
    return SharedTaskAssignmentOutboxCompanion(
      ownerUid: ownerUid ?? this.ownerUid,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      title: title ?? this.title,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      deadline: deadline ?? this.deadline,
      notes: notes ?? this.notes,
      queuedAtUtcMs: queuedAtUtcMs ?? this.queuedAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<String>(deadline.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (queuedAtUtcMs.present) {
      map['queued_at_utc_ms'] = Variable<int>(queuedAtUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedTaskAssignmentOutboxCompanion(')
          ..write('ownerUid: $ownerUid, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('priority: $priority, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('deadline: $deadline, ')
          ..write('notes: $notes, ')
          ..write('queuedAtUtcMs: $queuedAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LifeDatabase extends GeneratedDatabase {
  _$LifeDatabase(QueryExecutor e) : super(e);
  $LifeDatabaseManager get managers => $LifeDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $StoredRecordsTable storedRecords = $StoredRecordsTable(this);
  late final $ActivityHistoryTable activityHistory = $ActivityHistoryTable(
    this,
  );
  late final $TrackingEntriesTable trackingEntries = $TrackingEntriesTable(
    this,
  );
  late final $TaskPlanImportsTable taskPlanImports = $TaskPlanImportsTable(
    this,
  );
  late final $SharedTaskAssignmentOutboxTable sharedTaskAssignmentOutbox =
      $SharedTaskAssignmentOutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    storedRecords,
    activityHistory,
    trackingEntries,
    taskPlanImports,
    sharedTaskAssignmentOutbox,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String authUid,
      required String displayName,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> authUid,
      Value<String> displayName,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int> rowid,
    });

final class $$ProfilesTableReferences
    extends BaseReferences<_$LifeDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StoredRecordsTable, List<StoredRecord>>
  _storedRecordsRefsTable(_$LifeDatabase db) => MultiTypedResultKey.fromTable(
    db.storedRecords,
    aliasName: 'profiles__auth_uid__stored_records__owner_uid',
  );

  $$StoredRecordsTableProcessedTableManager get storedRecordsRefs {
    final manager = $$StoredRecordsTableTableManager($_db, $_db.storedRecords)
        .filter(
          (f) =>
              f.ownerUid.authUid.sqlEquals($_itemColumn<String>('auth_uid')!),
        );

    final cache = $_typedResult.readTableOrNull(_storedRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ActivityHistoryTable, List<ActivityHistoryData>>
  _activityHistoryRefsTable(_$LifeDatabase db) => MultiTypedResultKey.fromTable(
    db.activityHistory,
    aliasName: 'profiles__auth_uid__activity_history__owner_uid',
  );

  $$ActivityHistoryTableProcessedTableManager get activityHistoryRefs {
    final manager =
        $$ActivityHistoryTableTableManager($_db, $_db.activityHistory).filter(
          (f) =>
              f.ownerUid.authUid.sqlEquals($_itemColumn<String>('auth_uid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _activityHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrackingEntriesTable, List<TrackingEntryRow>>
  _trackingEntriesRefsTable(_$LifeDatabase db) => MultiTypedResultKey.fromTable(
    db.trackingEntries,
    aliasName: 'profiles__auth_uid__tracking_entries__owner_uid',
  );

  $$TrackingEntriesTableProcessedTableManager get trackingEntriesRefs {
    final manager =
        $$TrackingEntriesTableTableManager($_db, $_db.trackingEntries).filter(
          (f) =>
              f.ownerUid.authUid.sqlEquals($_itemColumn<String>('auth_uid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _trackingEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskPlanImportsTable, List<TaskPlanImport>>
  _taskPlanImportsRefsTable(_$LifeDatabase db) => MultiTypedResultKey.fromTable(
    db.taskPlanImports,
    aliasName: 'profiles__auth_uid__task_plan_imports__owner_uid',
  );

  $$TaskPlanImportsTableProcessedTableManager get taskPlanImportsRefs {
    final manager =
        $$TaskPlanImportsTableTableManager($_db, $_db.taskPlanImports).filter(
          (f) =>
              f.ownerUid.authUid.sqlEquals($_itemColumn<String>('auth_uid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _taskPlanImportsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$LifeDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get authUid => $composableBuilder(
    column: $table.authUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> storedRecordsRefs(
    Expression<bool> Function($$StoredRecordsTableFilterComposer f) f,
  ) {
    final $$StoredRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.storedRecords,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredRecordsTableFilterComposer(
            $db: $db,
            $table: $db.storedRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> activityHistoryRefs(
    Expression<bool> Function($$ActivityHistoryTableFilterComposer f) f,
  ) {
    final $$ActivityHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.activityHistory,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityHistoryTableFilterComposer(
            $db: $db,
            $table: $db.activityHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trackingEntriesRefs(
    Expression<bool> Function($$TrackingEntriesTableFilterComposer f) f,
  ) {
    final $$TrackingEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.trackingEntries,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackingEntriesTableFilterComposer(
            $db: $db,
            $table: $db.trackingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskPlanImportsRefs(
    Expression<bool> Function($$TaskPlanImportsTableFilterComposer f) f,
  ) {
    final $$TaskPlanImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.taskPlanImports,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskPlanImportsTableFilterComposer(
            $db: $db,
            $table: $db.taskPlanImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$LifeDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get authUid => $composableBuilder(
    column: $table.authUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$LifeDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get authUid =>
      $composableBuilder(column: $table.authUid, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  Expression<T> storedRecordsRefs<T extends Object>(
    Expression<T> Function($$StoredRecordsTableAnnotationComposer a) f,
  ) {
    final $$StoredRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.storedRecords,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> activityHistoryRefs<T extends Object>(
    Expression<T> Function($$ActivityHistoryTableAnnotationComposer a) f,
  ) {
    final $$ActivityHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.activityHistory,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.activityHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trackingEntriesRefs<T extends Object>(
    Expression<T> Function($$TrackingEntriesTableAnnotationComposer a) f,
  ) {
    final $$TrackingEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.trackingEntries,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackingEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.trackingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskPlanImportsRefs<T extends Object>(
    Expression<T> Function($$TaskPlanImportsTableAnnotationComposer a) f,
  ) {
    final $$TaskPlanImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authUid,
      referencedTable: $db.taskPlanImports,
      getReferencedColumn: (t) => t.ownerUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskPlanImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskPlanImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$LifeDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, $$ProfilesTableReferences),
          Profile,
          PrefetchHooks Function({
            bool storedRecordsRefs,
            bool activityHistoryRefs,
            bool trackingEntriesRefs,
            bool taskPlanImportsRefs,
          })
        > {
  $$ProfilesTableTableManager(_$LifeDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> authUid = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                authUid: authUid,
                displayName: displayName,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String authUid,
                required String displayName,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                authUid: authUid,
                displayName: displayName,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                storedRecordsRefs = false,
                activityHistoryRefs = false,
                trackingEntriesRefs = false,
                taskPlanImportsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storedRecordsRefs) db.storedRecords,
                    if (activityHistoryRefs) db.activityHistory,
                    if (trackingEntriesRefs) db.trackingEntries,
                    if (taskPlanImportsRefs) db.taskPlanImports,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (storedRecordsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          StoredRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._storedRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).storedRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerUid == item.authUid,
                              ),
                          typedResults: items,
                        ),
                      if (activityHistoryRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          ActivityHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._activityHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).activityHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerUid == item.authUid,
                              ),
                          typedResults: items,
                        ),
                      if (trackingEntriesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          TrackingEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._trackingEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).trackingEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerUid == item.authUid,
                              ),
                          typedResults: items,
                        ),
                      if (taskPlanImportsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          TaskPlanImport
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._taskPlanImportsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskPlanImportsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerUid == item.authUid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, $$ProfilesTableReferences),
      Profile,
      PrefetchHooks Function({
        bool storedRecordsRefs,
        bool activityHistoryRefs,
        bool trackingEntriesRefs,
        bool taskPlanImportsRefs,
      })
    >;
typedef $$StoredRecordsTableCreateCompanionBuilder =
    StoredRecordsCompanion Function({
      required String id,
      required String ownerUid,
      required String kind,
      required String visibility,
      required String payloadJson,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<String?> timezoneId,
      Value<String> syncStatus,
      Value<int> revision,
      Value<int?> lastSyncedAtUtcMs,
      Value<String?> remoteConflictJson,
      Value<int?> deletedAtUtcMs,
      Value<int> rowid,
    });
typedef $$StoredRecordsTableUpdateCompanionBuilder =
    StoredRecordsCompanion Function({
      Value<String> id,
      Value<String> ownerUid,
      Value<String> kind,
      Value<String> visibility,
      Value<String> payloadJson,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<String?> timezoneId,
      Value<String> syncStatus,
      Value<int> revision,
      Value<int?> lastSyncedAtUtcMs,
      Value<String?> remoteConflictJson,
      Value<int?> deletedAtUtcMs,
      Value<int> rowid,
    });

final class $$StoredRecordsTableReferences
    extends BaseReferences<_$LifeDatabase, $StoredRecordsTable, StoredRecord> {
  $$StoredRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _ownerUidTable(_$LifeDatabase db) =>
      db.profiles.createAlias('stored_records__owner_uid__profiles__auth_uid');

  $$ProfilesTableProcessedTableManager get ownerUid {
    final $_column = $_itemColumn<String>('owner_uid')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.authUid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerUidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoredRecordsTableFilterComposer
    extends Composer<_$LifeDatabase, $StoredRecordsTable> {
  $$StoredRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezoneId => $composableBuilder(
    column: $table.timezoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAtUtcMs => $composableBuilder(
    column: $table.lastSyncedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteConflictJson => $composableBuilder(
    column: $table.remoteConflictJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get ownerUid {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredRecordsTableOrderingComposer
    extends Composer<_$LifeDatabase, $StoredRecordsTable> {
  $$StoredRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezoneId => $composableBuilder(
    column: $table.timezoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAtUtcMs => $composableBuilder(
    column: $table.lastSyncedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteConflictJson => $composableBuilder(
    column: $table.remoteConflictJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get ownerUid {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredRecordsTableAnnotationComposer
    extends Composer<_$LifeDatabase, $StoredRecordsTable> {
  $$StoredRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezoneId => $composableBuilder(
    column: $table.timezoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAtUtcMs => $composableBuilder(
    column: $table.lastSyncedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteConflictJson => $composableBuilder(
    column: $table.remoteConflictJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get ownerUid {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredRecordsTableTableManager
    extends
        RootTableManager<
          _$LifeDatabase,
          $StoredRecordsTable,
          StoredRecord,
          $$StoredRecordsTableFilterComposer,
          $$StoredRecordsTableOrderingComposer,
          $$StoredRecordsTableAnnotationComposer,
          $$StoredRecordsTableCreateCompanionBuilder,
          $$StoredRecordsTableUpdateCompanionBuilder,
          (StoredRecord, $$StoredRecordsTableReferences),
          StoredRecord,
          PrefetchHooks Function({bool ownerUid})
        > {
  $$StoredRecordsTableTableManager(_$LifeDatabase db, $StoredRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerUid = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<String?> timezoneId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> lastSyncedAtUtcMs = const Value.absent(),
                Value<String?> remoteConflictJson = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredRecordsCompanion(
                id: id,
                ownerUid: ownerUid,
                kind: kind,
                visibility: visibility,
                payloadJson: payloadJson,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                timezoneId: timezoneId,
                syncStatus: syncStatus,
                revision: revision,
                lastSyncedAtUtcMs: lastSyncedAtUtcMs,
                remoteConflictJson: remoteConflictJson,
                deletedAtUtcMs: deletedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerUid,
                required String kind,
                required String visibility,
                required String payloadJson,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<String?> timezoneId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> lastSyncedAtUtcMs = const Value.absent(),
                Value<String?> remoteConflictJson = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredRecordsCompanion.insert(
                id: id,
                ownerUid: ownerUid,
                kind: kind,
                visibility: visibility,
                payloadJson: payloadJson,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                timezoneId: timezoneId,
                syncStatus: syncStatus,
                revision: revision,
                lastSyncedAtUtcMs: lastSyncedAtUtcMs,
                remoteConflictJson: remoteConflictJson,
                deletedAtUtcMs: deletedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoredRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ownerUid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ownerUid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ownerUid,
                                referencedTable: $$StoredRecordsTableReferences
                                    ._ownerUidTable(db),
                                referencedColumn: $$StoredRecordsTableReferences
                                    ._ownerUidTable(db)
                                    .authUid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StoredRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeDatabase,
      $StoredRecordsTable,
      StoredRecord,
      $$StoredRecordsTableFilterComposer,
      $$StoredRecordsTableOrderingComposer,
      $$StoredRecordsTableAnnotationComposer,
      $$StoredRecordsTableCreateCompanionBuilder,
      $$StoredRecordsTableUpdateCompanionBuilder,
      (StoredRecord, $$StoredRecordsTableReferences),
      StoredRecord,
      PrefetchHooks Function({bool ownerUid})
    >;
typedef $$ActivityHistoryTableCreateCompanionBuilder =
    ActivityHistoryCompanion Function({
      required String id,
      required String ownerUid,
      required String definitionId,
      required String kind,
      required String occurrenceKey,
      required String localDate,
      required String visibility,
      required String payloadJson,
      required int recordedAtUtcMs,
      Value<int> rowid,
    });
typedef $$ActivityHistoryTableUpdateCompanionBuilder =
    ActivityHistoryCompanion Function({
      Value<String> id,
      Value<String> ownerUid,
      Value<String> definitionId,
      Value<String> kind,
      Value<String> occurrenceKey,
      Value<String> localDate,
      Value<String> visibility,
      Value<String> payloadJson,
      Value<int> recordedAtUtcMs,
      Value<int> rowid,
    });

final class $$ActivityHistoryTableReferences
    extends
        BaseReferences<
          _$LifeDatabase,
          $ActivityHistoryTable,
          ActivityHistoryData
        > {
  $$ActivityHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _ownerUidTable(_$LifeDatabase db) => db.profiles
      .createAlias('activity_history__owner_uid__profiles__auth_uid');

  $$ProfilesTableProcessedTableManager get ownerUid {
    final $_column = $_itemColumn<String>('owner_uid')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.authUid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerUidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ActivityHistoryTableFilterComposer
    extends Composer<_$LifeDatabase, $ActivityHistoryTable> {
  $$ActivityHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAtUtcMs => $composableBuilder(
    column: $table.recordedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get ownerUid {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityHistoryTableOrderingComposer
    extends Composer<_$LifeDatabase, $ActivityHistoryTable> {
  $$ActivityHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAtUtcMs => $composableBuilder(
    column: $table.recordedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get ownerUid {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityHistoryTableAnnotationComposer
    extends Composer<_$LifeDatabase, $ActivityHistoryTable> {
  $$ActivityHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedAtUtcMs => $composableBuilder(
    column: $table.recordedAtUtcMs,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get ownerUid {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityHistoryTableTableManager
    extends
        RootTableManager<
          _$LifeDatabase,
          $ActivityHistoryTable,
          ActivityHistoryData,
          $$ActivityHistoryTableFilterComposer,
          $$ActivityHistoryTableOrderingComposer,
          $$ActivityHistoryTableAnnotationComposer,
          $$ActivityHistoryTableCreateCompanionBuilder,
          $$ActivityHistoryTableUpdateCompanionBuilder,
          (ActivityHistoryData, $$ActivityHistoryTableReferences),
          ActivityHistoryData,
          PrefetchHooks Function({bool ownerUid})
        > {
  $$ActivityHistoryTableTableManager(
    _$LifeDatabase db,
    $ActivityHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerUid = const Value.absent(),
                Value<String> definitionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> occurrenceKey = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> recordedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityHistoryCompanion(
                id: id,
                ownerUid: ownerUid,
                definitionId: definitionId,
                kind: kind,
                occurrenceKey: occurrenceKey,
                localDate: localDate,
                visibility: visibility,
                payloadJson: payloadJson,
                recordedAtUtcMs: recordedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerUid,
                required String definitionId,
                required String kind,
                required String occurrenceKey,
                required String localDate,
                required String visibility,
                required String payloadJson,
                required int recordedAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => ActivityHistoryCompanion.insert(
                id: id,
                ownerUid: ownerUid,
                definitionId: definitionId,
                kind: kind,
                occurrenceKey: occurrenceKey,
                localDate: localDate,
                visibility: visibility,
                payloadJson: payloadJson,
                recordedAtUtcMs: recordedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ActivityHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ownerUid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ownerUid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ownerUid,
                                referencedTable:
                                    $$ActivityHistoryTableReferences
                                        ._ownerUidTable(db),
                                referencedColumn:
                                    $$ActivityHistoryTableReferences
                                        ._ownerUidTable(db)
                                        .authUid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ActivityHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeDatabase,
      $ActivityHistoryTable,
      ActivityHistoryData,
      $$ActivityHistoryTableFilterComposer,
      $$ActivityHistoryTableOrderingComposer,
      $$ActivityHistoryTableAnnotationComposer,
      $$ActivityHistoryTableCreateCompanionBuilder,
      $$ActivityHistoryTableUpdateCompanionBuilder,
      (ActivityHistoryData, $$ActivityHistoryTableReferences),
      ActivityHistoryData,
      PrefetchHooks Function({bool ownerUid})
    >;
typedef $$TrackingEntriesTableCreateCompanionBuilder =
    TrackingEntriesCompanion Function({
      required String id,
      required String ownerUid,
      required String kind,
      required String localDate,
      required String entryKey,
      required String visibility,
      required String payloadJson,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int> revision,
      Value<int?> deletedAtUtcMs,
      Value<int> rowid,
    });
typedef $$TrackingEntriesTableUpdateCompanionBuilder =
    TrackingEntriesCompanion Function({
      Value<String> id,
      Value<String> ownerUid,
      Value<String> kind,
      Value<String> localDate,
      Value<String> entryKey,
      Value<String> visibility,
      Value<String> payloadJson,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int> revision,
      Value<int?> deletedAtUtcMs,
      Value<int> rowid,
    });

final class $$TrackingEntriesTableReferences
    extends
        BaseReferences<
          _$LifeDatabase,
          $TrackingEntriesTable,
          TrackingEntryRow
        > {
  $$TrackingEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _ownerUidTable(_$LifeDatabase db) => db.profiles
      .createAlias('tracking_entries__owner_uid__profiles__auth_uid');

  $$ProfilesTableProcessedTableManager get ownerUid {
    final $_column = $_itemColumn<String>('owner_uid')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.authUid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerUidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackingEntriesTableFilterComposer
    extends Composer<_$LifeDatabase, $TrackingEntriesTable> {
  $$TrackingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryKey => $composableBuilder(
    column: $table.entryKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get ownerUid {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackingEntriesTableOrderingComposer
    extends Composer<_$LifeDatabase, $TrackingEntriesTable> {
  $$TrackingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryKey => $composableBuilder(
    column: $table.entryKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get ownerUid {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackingEntriesTableAnnotationComposer
    extends Composer<_$LifeDatabase, $TrackingEntriesTable> {
  $$TrackingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get entryKey =>
      $composableBuilder(column: $table.entryKey, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get ownerUid {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackingEntriesTableTableManager
    extends
        RootTableManager<
          _$LifeDatabase,
          $TrackingEntriesTable,
          TrackingEntryRow,
          $$TrackingEntriesTableFilterComposer,
          $$TrackingEntriesTableOrderingComposer,
          $$TrackingEntriesTableAnnotationComposer,
          $$TrackingEntriesTableCreateCompanionBuilder,
          $$TrackingEntriesTableUpdateCompanionBuilder,
          (TrackingEntryRow, $$TrackingEntriesTableReferences),
          TrackingEntryRow,
          PrefetchHooks Function({bool ownerUid})
        > {
  $$TrackingEntriesTableTableManager(
    _$LifeDatabase db,
    $TrackingEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerUid = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String> entryKey = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackingEntriesCompanion(
                id: id,
                ownerUid: ownerUid,
                kind: kind,
                localDate: localDate,
                entryKey: entryKey,
                visibility: visibility,
                payloadJson: payloadJson,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                revision: revision,
                deletedAtUtcMs: deletedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerUid,
                required String kind,
                required String localDate,
                required String entryKey,
                required String visibility,
                required String payloadJson,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int> revision = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackingEntriesCompanion.insert(
                id: id,
                ownerUid: ownerUid,
                kind: kind,
                localDate: localDate,
                entryKey: entryKey,
                visibility: visibility,
                payloadJson: payloadJson,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                revision: revision,
                deletedAtUtcMs: deletedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrackingEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ownerUid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ownerUid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ownerUid,
                                referencedTable:
                                    $$TrackingEntriesTableReferences
                                        ._ownerUidTable(db),
                                referencedColumn:
                                    $$TrackingEntriesTableReferences
                                        ._ownerUidTable(db)
                                        .authUid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeDatabase,
      $TrackingEntriesTable,
      TrackingEntryRow,
      $$TrackingEntriesTableFilterComposer,
      $$TrackingEntriesTableOrderingComposer,
      $$TrackingEntriesTableAnnotationComposer,
      $$TrackingEntriesTableCreateCompanionBuilder,
      $$TrackingEntriesTableUpdateCompanionBuilder,
      (TrackingEntryRow, $$TrackingEntriesTableReferences),
      TrackingEntryRow,
      PrefetchHooks Function({bool ownerUid})
    >;
typedef $$TaskPlanImportsTableCreateCompanionBuilder =
    TaskPlanImportsCompanion Function({
      required String id,
      required String ownerUid,
      required String sourceFingerprint,
      required String startDate,
      required String parserVersion,
      required String taskIdsJson,
      required int importedAtUtcMs,
      Value<int> rowid,
    });
typedef $$TaskPlanImportsTableUpdateCompanionBuilder =
    TaskPlanImportsCompanion Function({
      Value<String> id,
      Value<String> ownerUid,
      Value<String> sourceFingerprint,
      Value<String> startDate,
      Value<String> parserVersion,
      Value<String> taskIdsJson,
      Value<int> importedAtUtcMs,
      Value<int> rowid,
    });

final class $$TaskPlanImportsTableReferences
    extends
        BaseReferences<_$LifeDatabase, $TaskPlanImportsTable, TaskPlanImport> {
  $$TaskPlanImportsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _ownerUidTable(_$LifeDatabase db) => db.profiles
      .createAlias('task_plan_imports__owner_uid__profiles__auth_uid');

  $$ProfilesTableProcessedTableManager get ownerUid {
    final $_column = $_itemColumn<String>('owner_uid')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.authUid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerUidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskPlanImportsTableFilterComposer
    extends Composer<_$LifeDatabase, $TaskPlanImportsTable> {
  $$TaskPlanImportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskIdsJson => $composableBuilder(
    column: $table.taskIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importedAtUtcMs => $composableBuilder(
    column: $table.importedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get ownerUid {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskPlanImportsTableOrderingComposer
    extends Composer<_$LifeDatabase, $TaskPlanImportsTable> {
  $$TaskPlanImportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskIdsJson => $composableBuilder(
    column: $table.taskIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedAtUtcMs => $composableBuilder(
    column: $table.importedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get ownerUid {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskPlanImportsTableAnnotationComposer
    extends Composer<_$LifeDatabase, $TaskPlanImportsTable> {
  $$TaskPlanImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskIdsJson => $composableBuilder(
    column: $table.taskIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importedAtUtcMs => $composableBuilder(
    column: $table.importedAtUtcMs,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get ownerUid {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUid,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.authUid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskPlanImportsTableTableManager
    extends
        RootTableManager<
          _$LifeDatabase,
          $TaskPlanImportsTable,
          TaskPlanImport,
          $$TaskPlanImportsTableFilterComposer,
          $$TaskPlanImportsTableOrderingComposer,
          $$TaskPlanImportsTableAnnotationComposer,
          $$TaskPlanImportsTableCreateCompanionBuilder,
          $$TaskPlanImportsTableUpdateCompanionBuilder,
          (TaskPlanImport, $$TaskPlanImportsTableReferences),
          TaskPlanImport,
          PrefetchHooks Function({bool ownerUid})
        > {
  $$TaskPlanImportsTableTableManager(
    _$LifeDatabase db,
    $TaskPlanImportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskPlanImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskPlanImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskPlanImportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerUid = const Value.absent(),
                Value<String> sourceFingerprint = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> parserVersion = const Value.absent(),
                Value<String> taskIdsJson = const Value.absent(),
                Value<int> importedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskPlanImportsCompanion(
                id: id,
                ownerUid: ownerUid,
                sourceFingerprint: sourceFingerprint,
                startDate: startDate,
                parserVersion: parserVersion,
                taskIdsJson: taskIdsJson,
                importedAtUtcMs: importedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerUid,
                required String sourceFingerprint,
                required String startDate,
                required String parserVersion,
                required String taskIdsJson,
                required int importedAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => TaskPlanImportsCompanion.insert(
                id: id,
                ownerUid: ownerUid,
                sourceFingerprint: sourceFingerprint,
                startDate: startDate,
                parserVersion: parserVersion,
                taskIdsJson: taskIdsJson,
                importedAtUtcMs: importedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskPlanImportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ownerUid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ownerUid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ownerUid,
                                referencedTable:
                                    $$TaskPlanImportsTableReferences
                                        ._ownerUidTable(db),
                                referencedColumn:
                                    $$TaskPlanImportsTableReferences
                                        ._ownerUidTable(db)
                                        .authUid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskPlanImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeDatabase,
      $TaskPlanImportsTable,
      TaskPlanImport,
      $$TaskPlanImportsTableFilterComposer,
      $$TaskPlanImportsTableOrderingComposer,
      $$TaskPlanImportsTableAnnotationComposer,
      $$TaskPlanImportsTableCreateCompanionBuilder,
      $$TaskPlanImportsTableUpdateCompanionBuilder,
      (TaskPlanImport, $$TaskPlanImportsTableReferences),
      TaskPlanImport,
      PrefetchHooks Function({bool ownerUid})
    >;
typedef $$SharedTaskAssignmentOutboxTableCreateCompanionBuilder =
    SharedTaskAssignmentOutboxCompanion Function({
      required String ownerUid,
      required String idempotencyKey,
      required String title,
      required String date,
      required int priority,
      required int durationMinutes,
      Value<String?> deadline,
      required String notes,
      required int queuedAtUtcMs,
      Value<int> rowid,
    });
typedef $$SharedTaskAssignmentOutboxTableUpdateCompanionBuilder =
    SharedTaskAssignmentOutboxCompanion Function({
      Value<String> ownerUid,
      Value<String> idempotencyKey,
      Value<String> title,
      Value<String> date,
      Value<int> priority,
      Value<int> durationMinutes,
      Value<String?> deadline,
      Value<String> notes,
      Value<int> queuedAtUtcMs,
      Value<int> rowid,
    });

class $$SharedTaskAssignmentOutboxTableFilterComposer
    extends Composer<_$LifeDatabase, $SharedTaskAssignmentOutboxTable> {
  $$SharedTaskAssignmentOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queuedAtUtcMs => $composableBuilder(
    column: $table.queuedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SharedTaskAssignmentOutboxTableOrderingComposer
    extends Composer<_$LifeDatabase, $SharedTaskAssignmentOutboxTable> {
  $$SharedTaskAssignmentOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queuedAtUtcMs => $composableBuilder(
    column: $table.queuedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SharedTaskAssignmentOutboxTableAnnotationComposer
    extends Composer<_$LifeDatabase, $SharedTaskAssignmentOutboxTable> {
  $$SharedTaskAssignmentOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get queuedAtUtcMs => $composableBuilder(
    column: $table.queuedAtUtcMs,
    builder: (column) => column,
  );
}

class $$SharedTaskAssignmentOutboxTableTableManager
    extends
        RootTableManager<
          _$LifeDatabase,
          $SharedTaskAssignmentOutboxTable,
          SharedTaskAssignmentOutboxData,
          $$SharedTaskAssignmentOutboxTableFilterComposer,
          $$SharedTaskAssignmentOutboxTableOrderingComposer,
          $$SharedTaskAssignmentOutboxTableAnnotationComposer,
          $$SharedTaskAssignmentOutboxTableCreateCompanionBuilder,
          $$SharedTaskAssignmentOutboxTableUpdateCompanionBuilder,
          (
            SharedTaskAssignmentOutboxData,
            BaseReferences<
              _$LifeDatabase,
              $SharedTaskAssignmentOutboxTable,
              SharedTaskAssignmentOutboxData
            >,
          ),
          SharedTaskAssignmentOutboxData,
          PrefetchHooks Function()
        > {
  $$SharedTaskAssignmentOutboxTableTableManager(
    _$LifeDatabase db,
    $SharedTaskAssignmentOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SharedTaskAssignmentOutboxTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SharedTaskAssignmentOutboxTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SharedTaskAssignmentOutboxTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerUid = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String?> deadline = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> queuedAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SharedTaskAssignmentOutboxCompanion(
                ownerUid: ownerUid,
                idempotencyKey: idempotencyKey,
                title: title,
                date: date,
                priority: priority,
                durationMinutes: durationMinutes,
                deadline: deadline,
                notes: notes,
                queuedAtUtcMs: queuedAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerUid,
                required String idempotencyKey,
                required String title,
                required String date,
                required int priority,
                required int durationMinutes,
                Value<String?> deadline = const Value.absent(),
                required String notes,
                required int queuedAtUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => SharedTaskAssignmentOutboxCompanion.insert(
                ownerUid: ownerUid,
                idempotencyKey: idempotencyKey,
                title: title,
                date: date,
                priority: priority,
                durationMinutes: durationMinutes,
                deadline: deadline,
                notes: notes,
                queuedAtUtcMs: queuedAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SharedTaskAssignmentOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeDatabase,
      $SharedTaskAssignmentOutboxTable,
      SharedTaskAssignmentOutboxData,
      $$SharedTaskAssignmentOutboxTableFilterComposer,
      $$SharedTaskAssignmentOutboxTableOrderingComposer,
      $$SharedTaskAssignmentOutboxTableAnnotationComposer,
      $$SharedTaskAssignmentOutboxTableCreateCompanionBuilder,
      $$SharedTaskAssignmentOutboxTableUpdateCompanionBuilder,
      (
        SharedTaskAssignmentOutboxData,
        BaseReferences<
          _$LifeDatabase,
          $SharedTaskAssignmentOutboxTable,
          SharedTaskAssignmentOutboxData
        >,
      ),
      SharedTaskAssignmentOutboxData,
      PrefetchHooks Function()
    >;

class $LifeDatabaseManager {
  final _$LifeDatabase _db;
  $LifeDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$StoredRecordsTableTableManager get storedRecords =>
      $$StoredRecordsTableTableManager(_db, _db.storedRecords);
  $$ActivityHistoryTableTableManager get activityHistory =>
      $$ActivityHistoryTableTableManager(_db, _db.activityHistory);
  $$TrackingEntriesTableTableManager get trackingEntries =>
      $$TrackingEntriesTableTableManager(_db, _db.trackingEntries);
  $$TaskPlanImportsTableTableManager get taskPlanImports =>
      $$TaskPlanImportsTableTableManager(_db, _db.taskPlanImports);
  $$SharedTaskAssignmentOutboxTableTableManager
  get sharedTaskAssignmentOutbox =>
      $$SharedTaskAssignmentOutboxTableTableManager(
        _db,
        _db.sharedTaskAssignmentOutbox,
      );
}
