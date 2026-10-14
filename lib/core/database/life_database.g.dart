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

abstract class _$LifeDatabase extends GeneratedDatabase {
  _$LifeDatabase(QueryExecutor e) : super(e);
  $LifeDatabaseManager get managers => $LifeDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $StoredRecordsTable storedRecords = $StoredRecordsTable(this);
  late final $ActivityHistoryTable activityHistory = $ActivityHistoryTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    storedRecords,
    activityHistory,
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
              ({storedRecordsRefs = false, activityHistoryRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storedRecordsRefs) db.storedRecords,
                    if (activityHistoryRefs) db.activityHistory,
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
      PrefetchHooks Function({bool storedRecordsRefs, bool activityHistoryRefs})
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

class $LifeDatabaseManager {
  final _$LifeDatabase _db;
  $LifeDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$StoredRecordsTableTableManager get storedRecords =>
      $$StoredRecordsTableTableManager(_db, _db.storedRecords);
  $$ActivityHistoryTableTableManager get activityHistory =>
      $$ActivityHistoryTableTableManager(_db, _db.activityHistory);
}
