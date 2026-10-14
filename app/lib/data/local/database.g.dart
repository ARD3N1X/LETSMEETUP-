// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventRowsTable extends EventRows
    with TableInfo<$EventRowsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedLocallyMeta =
      const VerificationMeta('lastModifiedLocally');
  @override
  late final GeneratedColumn<DateTime> lastModifiedLocally =
      GeneratedColumn<DateTime>(
        'last_modified_locally',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    data,
    groupId,
    startAt,
    version,
    syncStatus,
    reminderMinutes,
    lastModifiedLocally,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('last_modified_locally')) {
      context.handle(
        _lastModifiedLocallyMeta,
        lastModifiedLocally.isAcceptableOrUnknown(
          data['last_modified_locally']!,
          _lastModifiedLocallyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      lastModifiedLocally: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_locally'],
      ),
    );
  }

  @override
  $EventRowsTable createAlias(String alias) {
    return $EventRowsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String id;
  final String data;
  final String? groupId;
  final DateTime startAt;
  final int version;

  /// `synced` lub `pending` (lokalna zmiana czeka w kolejce).
  final String syncStatus;

  /// Przypomnienie ustawione na tym urządzeniu: null = domyślne, -1 = brak.
  final int? reminderMinutes;
  final DateTime? lastModifiedLocally;
  const EventRow({
    required this.id,
    required this.data,
    this.groupId,
    required this.startAt,
    required this.version,
    required this.syncStatus,
    this.reminderMinutes,
    this.lastModifiedLocally,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['start_at'] = Variable<DateTime>(startAt);
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || lastModifiedLocally != null) {
      map['last_modified_locally'] = Variable<DateTime>(lastModifiedLocally);
    }
    return map;
  }

  EventRowsCompanion toCompanion(bool nullToAbsent) {
    return EventRowsCompanion(
      id: Value(id),
      data: Value(data),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      startAt: Value(startAt),
      version: Value(version),
      syncStatus: Value(syncStatus),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      lastModifiedLocally: lastModifiedLocally == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedLocally),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      lastModifiedLocally: serializer.fromJson<DateTime?>(
        json['lastModifiedLocally'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
      'groupId': serializer.toJson<String?>(groupId),
      'startAt': serializer.toJson<DateTime>(startAt),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'lastModifiedLocally': serializer.toJson<DateTime?>(lastModifiedLocally),
    };
  }

  EventRow copyWith({
    String? id,
    String? data,
    Value<String?> groupId = const Value.absent(),
    DateTime? startAt,
    int? version,
    String? syncStatus,
    Value<int?> reminderMinutes = const Value.absent(),
    Value<DateTime?> lastModifiedLocally = const Value.absent(),
  }) => EventRow(
    id: id ?? this.id,
    data: data ?? this.data,
    groupId: groupId.present ? groupId.value : this.groupId,
    startAt: startAt ?? this.startAt,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    reminderMinutes: reminderMinutes.present
        ? reminderMinutes.value
        : this.reminderMinutes,
    lastModifiedLocally: lastModifiedLocally.present
        ? lastModifiedLocally.value
        : this.lastModifiedLocally,
  );
  EventRow copyWithCompanion(EventRowsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      lastModifiedLocally: data.lastModifiedLocally.present
          ? data.lastModifiedLocally.value
          : this.lastModifiedLocally,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('groupId: $groupId, ')
          ..write('startAt: $startAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('lastModifiedLocally: $lastModifiedLocally')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    data,
    groupId,
    startAt,
    version,
    syncStatus,
    reminderMinutes,
    lastModifiedLocally,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.data == this.data &&
          other.groupId == this.groupId &&
          other.startAt == this.startAt &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.reminderMinutes == this.reminderMinutes &&
          other.lastModifiedLocally == this.lastModifiedLocally);
}

class EventRowsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<String?> groupId;
  final Value<DateTime> startAt;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> reminderMinutes;
  final Value<DateTime?> lastModifiedLocally;
  final Value<int> rowid;
  const EventRowsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.groupId = const Value.absent(),
    this.startAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.lastModifiedLocally = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventRowsCompanion.insert({
    required String id,
    required String data,
    this.groupId = const Value.absent(),
    required DateTime startAt,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.lastModifiedLocally = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       data = Value(data),
       startAt = Value(startAt);
  static Insertable<EventRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<String>? groupId,
    Expression<DateTime>? startAt,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? reminderMinutes,
    Expression<DateTime>? lastModifiedLocally,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (groupId != null) 'group_id': groupId,
      if (startAt != null) 'start_at': startAt,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (lastModifiedLocally != null)
        'last_modified_locally': lastModifiedLocally,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? data,
    Value<String?>? groupId,
    Value<DateTime>? startAt,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? reminderMinutes,
    Value<DateTime?>? lastModifiedLocally,
    Value<int>? rowid,
  }) {
    return EventRowsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      groupId: groupId ?? this.groupId,
      startAt: startAt ?? this.startAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      lastModifiedLocally: lastModifiedLocally ?? this.lastModifiedLocally,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (lastModifiedLocally.present) {
      map['last_modified_locally'] = Variable<DateTime>(
        lastModifiedLocally.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventRowsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('groupId: $groupId, ')
          ..write('startAt: $startAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('lastModifiedLocally: $lastModifiedLocally, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupRowsTable extends GroupRows
    with TableInfo<$GroupRowsTable, GroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, data, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $GroupRowsTable createAlias(String alias) {
    return $GroupRowsTable(attachedDatabase, alias);
  }
}

class GroupRow extends DataClass implements Insertable<GroupRow> {
  final String id;
  final String data;
  final String name;
  const GroupRow({required this.id, required this.data, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    map['name'] = Variable<String>(name);
    return map;
  }

  GroupRowsCompanion toCompanion(bool nullToAbsent) {
    return GroupRowsCompanion(
      id: Value(id),
      data: Value(data),
      name: Value(name),
    );
  }

  factory GroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
      'name': serializer.toJson<String>(name),
    };
  }

  GroupRow copyWith({String? id, String? data, String? name}) => GroupRow(
    id: id ?? this.id,
    data: data ?? this.data,
    name: name ?? this.name,
  );
  GroupRow copyWithCompanion(GroupRowsCompanion data) {
    return GroupRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupRow(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupRow &&
          other.id == this.id &&
          other.data == this.data &&
          other.name == this.name);
}

class GroupRowsCompanion extends UpdateCompanion<GroupRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<String> name;
  final Value<int> rowid;
  const GroupRowsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupRowsCompanion.insert({
    required String id,
    required String data,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       data = Value(data),
       name = Value(name);
  static Insertable<GroupRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? data,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return GroupRowsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupRowsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupVisibilityRowsTable extends GroupVisibilityRows
    with TableInfo<$GroupVisibilityRowsTable, GroupVisibilityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupVisibilityRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibleMeta = const VerificationMeta(
    'visible',
  );
  @override
  late final GeneratedColumn<bool> visible = GeneratedColumn<bool>(
    'visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, visible];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_visibility_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupVisibilityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('visible')) {
      context.handle(
        _visibleMeta,
        visible.isAcceptableOrUnknown(data['visible']!, _visibleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  GroupVisibilityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupVisibilityRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      visible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}visible'],
      )!,
    );
  }

  @override
  $GroupVisibilityRowsTable createAlias(String alias) {
    return $GroupVisibilityRowsTable(attachedDatabase, alias);
  }
}

class GroupVisibilityRow extends DataClass
    implements Insertable<GroupVisibilityRow> {
  final String groupId;
  final bool visible;
  const GroupVisibilityRow({required this.groupId, required this.visible});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['visible'] = Variable<bool>(visible);
    return map;
  }

  GroupVisibilityRowsCompanion toCompanion(bool nullToAbsent) {
    return GroupVisibilityRowsCompanion(
      groupId: Value(groupId),
      visible: Value(visible),
    );
  }

  factory GroupVisibilityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupVisibilityRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      visible: serializer.fromJson<bool>(json['visible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'visible': serializer.toJson<bool>(visible),
    };
  }

  GroupVisibilityRow copyWith({String? groupId, bool? visible}) =>
      GroupVisibilityRow(
        groupId: groupId ?? this.groupId,
        visible: visible ?? this.visible,
      );
  GroupVisibilityRow copyWithCompanion(GroupVisibilityRowsCompanion data) {
    return GroupVisibilityRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      visible: data.visible.present ? data.visible.value : this.visible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupVisibilityRow(')
          ..write('groupId: $groupId, ')
          ..write('visible: $visible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, visible);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupVisibilityRow &&
          other.groupId == this.groupId &&
          other.visible == this.visible);
}

class GroupVisibilityRowsCompanion extends UpdateCompanion<GroupVisibilityRow> {
  final Value<String> groupId;
  final Value<bool> visible;
  final Value<int> rowid;
  const GroupVisibilityRowsCompanion({
    this.groupId = const Value.absent(),
    this.visible = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupVisibilityRowsCompanion.insert({
    required String groupId,
    this.visible = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId);
  static Insertable<GroupVisibilityRow> custom({
    Expression<String>? groupId,
    Expression<bool>? visible,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (visible != null) 'visible': visible,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupVisibilityRowsCompanion copyWith({
    Value<String>? groupId,
    Value<bool>? visible,
    Value<int>? rowid,
  }) {
    return GroupVisibilityRowsCompanion(
      groupId: groupId ?? this.groupId,
      visible: visible ?? this.visible,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (visible.present) {
      map['visible'] = Variable<bool>(visible.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupVisibilityRowsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('visible: $visible, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxRowsTable extends OutboxRows
    with TableInfo<$OutboxRowsTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
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
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    entityId,
    payload,
    attempts,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxRowsTable createAlias(String alias) {
    return $OutboxRowsTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String kind;
  final String entityId;
  final String payload;
  final int attempts;
  final DateTime createdAt;
  const OutboxRow({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.payload,
    required this.attempts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxRowsCompanion toCompanion(bool nullToAbsent) {
    return OutboxRowsCompanion(
      id: Value(id),
      kind: Value(kind),
      entityId: Value(entityId),
      payload: Value(payload),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? kind,
    String? entityId,
    String? payload,
    int? attempts,
    DateTime? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    entityId: entityId ?? this.entityId,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxRowsCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, entityId, payload, attempts, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt);
}

class OutboxRowsCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  const OutboxRowsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxRowsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String entityId,
    required String payload,
    this.attempts = const Value.absent(),
    required DateTime createdAt,
  }) : kind = Value(kind),
       entityId = Value(entityId),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? entityId,
    Value<String>? payload,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
  }) {
    return OutboxRowsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRowsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ConflictLogRowsTable extends ConflictLogRows
    with TableInfo<$ConflictLogRowsTable, ConflictLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
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
  static const VerificationMeta _localDataMeta = const VerificationMeta(
    'localData',
  );
  @override
  late final GeneratedColumn<String> localData = GeneratedColumn<String>(
    'local_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityId,
    kind,
    localData,
    reason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflict_log_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('local_data')) {
      context.handle(
        _localDataMeta,
        localData.isAcceptableOrUnknown(data['local_data']!, _localDataMeta),
      );
    } else if (isInserting) {
      context.missing(_localDataMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      localData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_data'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ConflictLogRowsTable createAlias(String alias) {
    return $ConflictLogRowsTable(attachedDatabase, alias);
  }
}

class ConflictLogRow extends DataClass implements Insertable<ConflictLogRow> {
  final int id;
  final String entityId;
  final String kind;
  final String localData;
  final String reason;
  final DateTime createdAt;
  const ConflictLogRow({
    required this.id,
    required this.entityId,
    required this.kind,
    required this.localData,
    required this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['kind'] = Variable<String>(kind);
    map['local_data'] = Variable<String>(localData);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConflictLogRowsCompanion toCompanion(bool nullToAbsent) {
    return ConflictLogRowsCompanion(
      id: Value(id),
      entityId: Value(entityId),
      kind: Value(kind),
      localData: Value(localData),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory ConflictLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictLogRow(
      id: serializer.fromJson<int>(json['id']),
      entityId: serializer.fromJson<String>(json['entityId']),
      kind: serializer.fromJson<String>(json['kind']),
      localData: serializer.fromJson<String>(json['localData']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityId': serializer.toJson<String>(entityId),
      'kind': serializer.toJson<String>(kind),
      'localData': serializer.toJson<String>(localData),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConflictLogRow copyWith({
    int? id,
    String? entityId,
    String? kind,
    String? localData,
    String? reason,
    DateTime? createdAt,
  }) => ConflictLogRow(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    kind: kind ?? this.kind,
    localData: localData ?? this.localData,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  ConflictLogRow copyWithCompanion(ConflictLogRowsCompanion data) {
    return ConflictLogRow(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      kind: data.kind.present ? data.kind.value : this.kind,
      localData: data.localData.present ? data.localData.value : this.localData,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictLogRow(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('kind: $kind, ')
          ..write('localData: $localData, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityId, kind, localData, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictLogRow &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.kind == this.kind &&
          other.localData == this.localData &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class ConflictLogRowsCompanion extends UpdateCompanion<ConflictLogRow> {
  final Value<int> id;
  final Value<String> entityId;
  final Value<String> kind;
  final Value<String> localData;
  final Value<String> reason;
  final Value<DateTime> createdAt;
  const ConflictLogRowsCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.kind = const Value.absent(),
    this.localData = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ConflictLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required String entityId,
    required String kind,
    required String localData,
    required String reason,
    required DateTime createdAt,
  }) : entityId = Value(entityId),
       kind = Value(kind),
       localData = Value(localData),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<ConflictLogRow> custom({
    Expression<int>? id,
    Expression<String>? entityId,
    Expression<String>? kind,
    Expression<String>? localData,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (kind != null) 'kind': kind,
      if (localData != null) 'local_data': localData,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ConflictLogRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? entityId,
    Value<String>? kind,
    Value<String>? localData,
    Value<String>? reason,
    Value<DateTime>? createdAt,
  }) {
    return ConflictLogRowsCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      kind: kind ?? this.kind,
      localData: localData ?? this.localData,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (localData.present) {
      map['local_data'] = Variable<String>(localData.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('kind: $kind, ')
          ..write('localData: $localData, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KvRowsTable extends KvRows with TableInfo<$KvRowsTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KvRowsTable createAlias(String alias) {
    return $KvRowsTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvRowsCompanion toCompanion(bool nullToAbsent) {
    return KvRowsCompanion(key: Value(key), value: Value(value));
  }

  factory KvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) =>
      KvRow(key: key ?? this.key, value: value ?? this.value);
  KvRow copyWithCompanion(KvRowsCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class KvRowsCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventRowsTable eventRows = $EventRowsTable(this);
  late final $GroupRowsTable groupRows = $GroupRowsTable(this);
  late final $GroupVisibilityRowsTable groupVisibilityRows =
      $GroupVisibilityRowsTable(this);
  late final $OutboxRowsTable outboxRows = $OutboxRowsTable(this);
  late final $ConflictLogRowsTable conflictLogRows = $ConflictLogRowsTable(
    this,
  );
  late final $KvRowsTable kvRows = $KvRowsTable(this);
  late final Index idxEventsStart = Index(
    'idx_events_start',
    'CREATE INDEX idx_events_start ON event_rows (start_at)',
  );
  late final Index idxEventsGroup = Index(
    'idx_events_group',
    'CREATE INDEX idx_events_group ON event_rows (group_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eventRows,
    groupRows,
    groupVisibilityRows,
    outboxRows,
    conflictLogRows,
    kvRows,
    idxEventsStart,
    idxEventsGroup,
  ];
}

typedef $$EventRowsTableCreateCompanionBuilder =
    EventRowsCompanion Function({
      required String id,
      required String data,
      Value<String?> groupId,
      required DateTime startAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> reminderMinutes,
      Value<DateTime?> lastModifiedLocally,
      Value<int> rowid,
    });
typedef $$EventRowsTableUpdateCompanionBuilder =
    EventRowsCompanion Function({
      Value<String> id,
      Value<String> data,
      Value<String?> groupId,
      Value<DateTime> startAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> reminderMinutes,
      Value<DateTime?> lastModifiedLocally,
      Value<int> rowid,
    });

class $$EventRowsTableFilterComposer
    extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableFilterComposer({
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

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedLocally => $composableBuilder(
    column: $table.lastModifiedLocally,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableOrderingComposer({
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

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedLocally => $composableBuilder(
    column: $table.lastModifiedLocally,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModifiedLocally => $composableBuilder(
    column: $table.lastModifiedLocally,
    builder: (column) => column,
  );
}

class $$EventRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventRowsTable,
          EventRow,
          $$EventRowsTableFilterComposer,
          $$EventRowsTableOrderingComposer,
          $$EventRowsTableAnnotationComposer,
          $$EventRowsTableCreateCompanionBuilder,
          $$EventRowsTableUpdateCompanionBuilder,
          (EventRow, BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventRowsTableTableManager(_$AppDatabase db, $EventRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<DateTime> startAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<DateTime?> lastModifiedLocally = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventRowsCompanion(
                id: id,
                data: data,
                groupId: groupId,
                startAt: startAt,
                version: version,
                syncStatus: syncStatus,
                reminderMinutes: reminderMinutes,
                lastModifiedLocally: lastModifiedLocally,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String data,
                Value<String?> groupId = const Value.absent(),
                required DateTime startAt,
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<DateTime?> lastModifiedLocally = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventRowsCompanion.insert(
                id: id,
                data: data,
                groupId: groupId,
                startAt: startAt,
                version: version,
                syncStatus: syncStatus,
                reminderMinutes: reminderMinutes,
                lastModifiedLocally: lastModifiedLocally,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventRowsTable, EventRow>(table),
                  BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventRowsTable,
      EventRow,
      $$EventRowsTableFilterComposer,
      $$EventRowsTableOrderingComposer,
      $$EventRowsTableAnnotationComposer,
      $$EventRowsTableCreateCompanionBuilder,
      $$EventRowsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$GroupRowsTableCreateCompanionBuilder =
    GroupRowsCompanion Function({
      required String id,
      required String data,
      required String name,
      Value<int> rowid,
    });
typedef $$GroupRowsTableUpdateCompanionBuilder =
    GroupRowsCompanion Function({
      Value<String> id,
      Value<String> data,
      Value<String> name,
      Value<int> rowid,
    });

class $$GroupRowsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupRowsTable> {
  $$GroupRowsTableFilterComposer({
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

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupRowsTable> {
  $$GroupRowsTableOrderingComposer({
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

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupRowsTable> {
  $$GroupRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$GroupRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupRowsTable,
          GroupRow,
          $$GroupRowsTableFilterComposer,
          $$GroupRowsTableOrderingComposer,
          $$GroupRowsTableAnnotationComposer,
          $$GroupRowsTableCreateCompanionBuilder,
          $$GroupRowsTableUpdateCompanionBuilder,
          (GroupRow, BaseReferences<_$AppDatabase, $GroupRowsTable, GroupRow>),
          GroupRow,
          PrefetchHooks Function()
        > {
  $$GroupRowsTableTableManager(_$AppDatabase db, $GroupRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupRowsCompanion(
                id: id,
                data: data,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String data,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => GroupRowsCompanion.insert(
                id: id,
                data: data,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupRowsTable, GroupRow>(table),
                  BaseReferences<_$AppDatabase, $GroupRowsTable, GroupRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupRowsTable,
      GroupRow,
      $$GroupRowsTableFilterComposer,
      $$GroupRowsTableOrderingComposer,
      $$GroupRowsTableAnnotationComposer,
      $$GroupRowsTableCreateCompanionBuilder,
      $$GroupRowsTableUpdateCompanionBuilder,
      (GroupRow, BaseReferences<_$AppDatabase, $GroupRowsTable, GroupRow>),
      GroupRow,
      PrefetchHooks Function()
    >;
typedef $$GroupVisibilityRowsTableCreateCompanionBuilder =
    GroupVisibilityRowsCompanion Function({
      required String groupId,
      Value<bool> visible,
      Value<int> rowid,
    });
typedef $$GroupVisibilityRowsTableUpdateCompanionBuilder =
    GroupVisibilityRowsCompanion Function({
      Value<String> groupId,
      Value<bool> visible,
      Value<int> rowid,
    });

class $$GroupVisibilityRowsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupVisibilityRowsTable> {
  $$GroupVisibilityRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupVisibilityRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupVisibilityRowsTable> {
  $$GroupVisibilityRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupVisibilityRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupVisibilityRowsTable> {
  $$GroupVisibilityRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<bool> get visible =>
      $composableBuilder(column: $table.visible, builder: (column) => column);
}

class $$GroupVisibilityRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupVisibilityRowsTable,
          GroupVisibilityRow,
          $$GroupVisibilityRowsTableFilterComposer,
          $$GroupVisibilityRowsTableOrderingComposer,
          $$GroupVisibilityRowsTableAnnotationComposer,
          $$GroupVisibilityRowsTableCreateCompanionBuilder,
          $$GroupVisibilityRowsTableUpdateCompanionBuilder,
          (
            GroupVisibilityRow,
            BaseReferences<
              _$AppDatabase,
              $GroupVisibilityRowsTable,
              GroupVisibilityRow
            >,
          ),
          GroupVisibilityRow,
          PrefetchHooks Function()
        > {
  $$GroupVisibilityRowsTableTableManager(
    _$AppDatabase db,
    $GroupVisibilityRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupVisibilityRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupVisibilityRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GroupVisibilityRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<bool> visible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupVisibilityRowsCompanion(
                groupId: groupId,
                visible: visible,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                Value<bool> visible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupVisibilityRowsCompanion.insert(
                groupId: groupId,
                visible: visible,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupVisibilityRowsTable, GroupVisibilityRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $GroupVisibilityRowsTable,
                    GroupVisibilityRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupVisibilityRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupVisibilityRowsTable,
      GroupVisibilityRow,
      $$GroupVisibilityRowsTableFilterComposer,
      $$GroupVisibilityRowsTableOrderingComposer,
      $$GroupVisibilityRowsTableAnnotationComposer,
      $$GroupVisibilityRowsTableCreateCompanionBuilder,
      $$GroupVisibilityRowsTableUpdateCompanionBuilder,
      (
        GroupVisibilityRow,
        BaseReferences<
          _$AppDatabase,
          $GroupVisibilityRowsTable,
          GroupVisibilityRow
        >,
      ),
      GroupVisibilityRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxRowsTableCreateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> id,
      required String kind,
      required String entityId,
      required String payload,
      Value<int> attempts,
      required DateTime createdAt,
    });
typedef $$OutboxRowsTableUpdateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String> entityId,
      Value<String> payload,
      Value<int> attempts,
      Value<DateTime> createdAt,
    });

class $$OutboxRowsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxRowsTable,
          OutboxRow,
          $$OutboxRowsTableFilterComposer,
          $$OutboxRowsTableOrderingComposer,
          $$OutboxRowsTableAnnotationComposer,
          $$OutboxRowsTableCreateCompanionBuilder,
          $$OutboxRowsTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxRowsTableTableManager(_$AppDatabase db, $OutboxRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxRowsCompanion(
                id: id,
                kind: kind,
                entityId: entityId,
                payload: payload,
                attempts: attempts,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String entityId,
                required String payload,
                Value<int> attempts = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxRowsCompanion.insert(
                id: id,
                kind: kind,
                entityId: entityId,
                payload: payload,
                attempts: attempts,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxRowsTable, OutboxRow>(table),
                  BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxRowsTable,
      OutboxRow,
      $$OutboxRowsTableFilterComposer,
      $$OutboxRowsTableOrderingComposer,
      $$OutboxRowsTableAnnotationComposer,
      $$OutboxRowsTableCreateCompanionBuilder,
      $$OutboxRowsTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$ConflictLogRowsTableCreateCompanionBuilder =
    ConflictLogRowsCompanion Function({
      Value<int> id,
      required String entityId,
      required String kind,
      required String localData,
      required String reason,
      required DateTime createdAt,
    });
typedef $$ConflictLogRowsTableUpdateCompanionBuilder =
    ConflictLogRowsCompanion Function({
      Value<int> id,
      Value<String> entityId,
      Value<String> kind,
      Value<String> localData,
      Value<String> reason,
      Value<DateTime> createdAt,
    });

class $$ConflictLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ConflictLogRowsTable> {
  $$ConflictLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localData => $composableBuilder(
    column: $table.localData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConflictLogRowsTable> {
  $$ConflictLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localData => $composableBuilder(
    column: $table.localData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConflictLogRowsTable> {
  $$ConflictLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get localData =>
      $composableBuilder(column: $table.localData, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ConflictLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConflictLogRowsTable,
          ConflictLogRow,
          $$ConflictLogRowsTableFilterComposer,
          $$ConflictLogRowsTableOrderingComposer,
          $$ConflictLogRowsTableAnnotationComposer,
          $$ConflictLogRowsTableCreateCompanionBuilder,
          $$ConflictLogRowsTableUpdateCompanionBuilder,
          (
            ConflictLogRow,
            BaseReferences<
              _$AppDatabase,
              $ConflictLogRowsTable,
              ConflictLogRow
            >,
          ),
          ConflictLogRow,
          PrefetchHooks Function()
        > {
  $$ConflictLogRowsTableTableManager(
    _$AppDatabase db,
    $ConflictLogRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> localData = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ConflictLogRowsCompanion(
                id: id,
                entityId: entityId,
                kind: kind,
                localData: localData,
                reason: reason,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityId,
                required String kind,
                required String localData,
                required String reason,
                required DateTime createdAt,
              }) => ConflictLogRowsCompanion.insert(
                id: id,
                entityId: entityId,
                kind: kind,
                localData: localData,
                reason: reason,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConflictLogRowsTable, ConflictLogRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConflictLogRowsTable,
                    ConflictLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConflictLogRowsTable,
      ConflictLogRow,
      $$ConflictLogRowsTableFilterComposer,
      $$ConflictLogRowsTableOrderingComposer,
      $$ConflictLogRowsTableAnnotationComposer,
      $$ConflictLogRowsTableCreateCompanionBuilder,
      $$ConflictLogRowsTableUpdateCompanionBuilder,
      (
        ConflictLogRow,
        BaseReferences<_$AppDatabase, $ConflictLogRowsTable, ConflictLogRow>,
      ),
      ConflictLogRow,
      PrefetchHooks Function()
    >;
typedef $$KvRowsTableCreateCompanionBuilder =
    KvRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KvRowsTableUpdateCompanionBuilder =
    KvRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KvRowsTableFilterComposer
    extends Composer<_$AppDatabase, $KvRowsTable> {
  $$KvRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $KvRowsTable> {
  $$KvRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KvRowsTable> {
  $$KvRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvRowsTable,
          KvRow,
          $$KvRowsTableFilterComposer,
          $$KvRowsTableOrderingComposer,
          $$KvRowsTableAnnotationComposer,
          $$KvRowsTableCreateCompanionBuilder,
          $$KvRowsTableUpdateCompanionBuilder,
          (KvRow, BaseReferences<_$AppDatabase, $KvRowsTable, KvRow>),
          KvRow,
          PrefetchHooks Function()
        > {
  $$KvRowsTableTableManager(_$AppDatabase db, $KvRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KvRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  KvRowsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KvRowsTable, KvRow>(table),
                  BaseReferences<_$AppDatabase, $KvRowsTable, KvRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvRowsTable,
      KvRow,
      $$KvRowsTableFilterComposer,
      $$KvRowsTableOrderingComposer,
      $$KvRowsTableAnnotationComposer,
      $$KvRowsTableCreateCompanionBuilder,
      $$KvRowsTableUpdateCompanionBuilder,
      (KvRow, BaseReferences<_$AppDatabase, $KvRowsTable, KvRow>),
      KvRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventRowsTableTableManager get eventRows =>
      $$EventRowsTableTableManager(_db, _db.eventRows);
  $$GroupRowsTableTableManager get groupRows =>
      $$GroupRowsTableTableManager(_db, _db.groupRows);
  $$GroupVisibilityRowsTableTableManager get groupVisibilityRows =>
      $$GroupVisibilityRowsTableTableManager(_db, _db.groupVisibilityRows);
  $$OutboxRowsTableTableManager get outboxRows =>
      $$OutboxRowsTableTableManager(_db, _db.outboxRows);
  $$ConflictLogRowsTableTableManager get conflictLogRows =>
      $$ConflictLogRowsTableTableManager(_db, _db.conflictLogRows);
  $$KvRowsTableTableManager get kvRows =>
      $$KvRowsTableTableManager(_db, _db.kvRows);
}
