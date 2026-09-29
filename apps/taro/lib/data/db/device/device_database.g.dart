// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_database.dart';

// ignore_for_file: type=lint
class BalanceCache extends Table with TableInfo<BalanceCache, BalanceCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BalanceCache(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY DEFAULT 1 CHECK (id = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ledgerVersionMeta = const VerificationMeta(
    'ledgerVersion',
  );
  late final GeneratedColumn<int> ledgerVersion = GeneratedColumn<int>(
    'ledger_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> serverTime =
      GeneratedColumn<int>(
        'server_time',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(BalanceCache.$converterserverTime);
  late final GeneratedColumnWithTypeConverter<DateTime, int> syncedAt =
      GeneratedColumn<int>(
        'synced_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(BalanceCache.$convertersyncedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    ledgerVersion,
    serverTime,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<BalanceCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('ledger_version')) {
      context.handle(
        _ledgerVersionMeta,
        ledgerVersion.isAcceptableOrUnknown(
          data['ledger_version']!,
          _ledgerVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ledgerVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BalanceCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      ledgerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ledger_version'],
      )!,
      serverTime: BalanceCache.$converterserverTime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}server_time'],
        )!,
      ),
      syncedAt: BalanceCache.$convertersyncedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}synced_at'],
        )!,
      ),
    );
  }

  @override
  BalanceCache createAlias(String alias) {
    return BalanceCache(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterserverTime =
      const InstantConverter();
  static TypeConverter<DateTime, int> $convertersyncedAt =
      const InstantConverter();
  @override
  bool get dontWriteConstraints => true;
}

class BalanceCacheRow extends DataClass implements Insertable<BalanceCacheRow> {
  final int id;
  final String json;
  final int ledgerVersion;
  final DateTime serverTime;
  final DateTime syncedAt;
  const BalanceCacheRow({
    required this.id,
    required this.json,
    required this.ledgerVersion,
    required this.serverTime,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    map['ledger_version'] = Variable<int>(ledgerVersion);
    {
      map['server_time'] = Variable<int>(
        BalanceCache.$converterserverTime.toSql(serverTime),
      );
    }
    {
      map['synced_at'] = Variable<int>(
        BalanceCache.$convertersyncedAt.toSql(syncedAt),
      );
    }
    return map;
  }

  BalanceCacheCompanion toCompanion(bool nullToAbsent) {
    return BalanceCacheCompanion(
      id: Value(id),
      json: Value(json),
      ledgerVersion: Value(ledgerVersion),
      serverTime: Value(serverTime),
      syncedAt: Value(syncedAt),
    );
  }

  factory BalanceCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceCacheRow(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      ledgerVersion: serializer.fromJson<int>(json['ledger_version']),
      serverTime: serializer.fromJson<DateTime>(json['server_time']),
      syncedAt: serializer.fromJson<DateTime>(json['synced_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
      'ledger_version': serializer.toJson<int>(ledgerVersion),
      'server_time': serializer.toJson<DateTime>(serverTime),
      'synced_at': serializer.toJson<DateTime>(syncedAt),
    };
  }

  BalanceCacheRow copyWith({
    int? id,
    String? json,
    int? ledgerVersion,
    DateTime? serverTime,
    DateTime? syncedAt,
  }) => BalanceCacheRow(
    id: id ?? this.id,
    json: json ?? this.json,
    ledgerVersion: ledgerVersion ?? this.ledgerVersion,
    serverTime: serverTime ?? this.serverTime,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  BalanceCacheRow copyWithCompanion(BalanceCacheCompanion data) {
    return BalanceCacheRow(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      ledgerVersion: data.ledgerVersion.present
          ? data.ledgerVersion.value
          : this.ledgerVersion,
      serverTime: data.serverTime.present
          ? data.serverTime.value
          : this.serverTime,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceCacheRow(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('ledgerVersion: $ledgerVersion, ')
          ..write('serverTime: $serverTime, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, json, ledgerVersion, serverTime, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceCacheRow &&
          other.id == this.id &&
          other.json == this.json &&
          other.ledgerVersion == this.ledgerVersion &&
          other.serverTime == this.serverTime &&
          other.syncedAt == this.syncedAt);
}

class BalanceCacheCompanion extends UpdateCompanion<BalanceCacheRow> {
  final Value<int> id;
  final Value<String> json;
  final Value<int> ledgerVersion;
  final Value<DateTime> serverTime;
  final Value<DateTime> syncedAt;
  const BalanceCacheCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.ledgerVersion = const Value.absent(),
    this.serverTime = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  BalanceCacheCompanion.insert({
    this.id = const Value.absent(),
    required String json,
    required int ledgerVersion,
    required DateTime serverTime,
    required DateTime syncedAt,
  }) : json = Value(json),
       ledgerVersion = Value(ledgerVersion),
       serverTime = Value(serverTime),
       syncedAt = Value(syncedAt);
  static Insertable<BalanceCacheRow> custom({
    Expression<int>? id,
    Expression<String>? json,
    Expression<int>? ledgerVersion,
    Expression<int>? serverTime,
    Expression<int>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (ledgerVersion != null) 'ledger_version': ledgerVersion,
      if (serverTime != null) 'server_time': serverTime,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  BalanceCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? json,
    Value<int>? ledgerVersion,
    Value<DateTime>? serverTime,
    Value<DateTime>? syncedAt,
  }) {
    return BalanceCacheCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      ledgerVersion: ledgerVersion ?? this.ledgerVersion,
      serverTime: serverTime ?? this.serverTime,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (ledgerVersion.present) {
      map['ledger_version'] = Variable<int>(ledgerVersion.value);
    }
    if (serverTime.present) {
      map['server_time'] = Variable<int>(
        BalanceCache.$converterserverTime.toSql(serverTime.value),
      );
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(
        BalanceCache.$convertersyncedAt.toSql(syncedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceCacheCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('ledgerVersion: $ledgerVersion, ')
          ..write('serverTime: $serverTime, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class RemoteConfigCache extends Table
    with TableInfo<RemoteConfigCache, RemoteConfigCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RemoteConfigCache(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY DEFAULT 1 CHECK (id = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> fetchedAt =
      GeneratedColumn<int>(
        'fetched_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(RemoteConfigCache.$converterfetchedAt);
  @override
  List<GeneratedColumn> get $columns => [id, json, etag, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_config_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteConfigCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteConfigCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteConfigCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      fetchedAt: RemoteConfigCache.$converterfetchedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}fetched_at'],
        )!,
      ),
    );
  }

  @override
  RemoteConfigCache createAlias(String alias) {
    return RemoteConfigCache(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterfetchedAt =
      const InstantConverter();
  @override
  bool get dontWriteConstraints => true;
}

class RemoteConfigCacheRow extends DataClass
    implements Insertable<RemoteConfigCacheRow> {
  final int id;
  final String json;
  final String? etag;
  final DateTime fetchedAt;
  const RemoteConfigCacheRow({
    required this.id,
    required this.json,
    this.etag,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    {
      map['fetched_at'] = Variable<int>(
        RemoteConfigCache.$converterfetchedAt.toSql(fetchedAt),
      );
    }
    return map;
  }

  RemoteConfigCacheCompanion toCompanion(bool nullToAbsent) {
    return RemoteConfigCacheCompanion(
      id: Value(id),
      json: Value(json),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory RemoteConfigCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteConfigCacheRow(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      etag: serializer.fromJson<String?>(json['etag']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetched_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
      'etag': serializer.toJson<String?>(etag),
      'fetched_at': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  RemoteConfigCacheRow copyWith({
    int? id,
    String? json,
    Value<String?> etag = const Value.absent(),
    DateTime? fetchedAt,
  }) => RemoteConfigCacheRow(
    id: id ?? this.id,
    json: json ?? this.json,
    etag: etag.present ? etag.value : this.etag,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  RemoteConfigCacheRow copyWithCompanion(RemoteConfigCacheCompanion data) {
    return RemoteConfigCacheRow(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      etag: data.etag.present ? data.etag.value : this.etag,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteConfigCacheRow(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, etag, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteConfigCacheRow &&
          other.id == this.id &&
          other.json == this.json &&
          other.etag == this.etag &&
          other.fetchedAt == this.fetchedAt);
}

class RemoteConfigCacheCompanion extends UpdateCompanion<RemoteConfigCacheRow> {
  final Value<int> id;
  final Value<String> json;
  final Value<String?> etag;
  final Value<DateTime> fetchedAt;
  const RemoteConfigCacheCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.etag = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  RemoteConfigCacheCompanion.insert({
    this.id = const Value.absent(),
    required String json,
    this.etag = const Value.absent(),
    required DateTime fetchedAt,
  }) : json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<RemoteConfigCacheRow> custom({
    Expression<int>? id,
    Expression<String>? json,
    Expression<String>? etag,
    Expression<int>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (etag != null) 'etag': etag,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  RemoteConfigCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? json,
    Value<String?>? etag,
    Value<DateTime>? fetchedAt,
  }) {
    return RemoteConfigCacheCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      etag: etag ?? this.etag,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(
        RemoteConfigCache.$converterfetchedAt.toSql(fetchedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteConfigCacheCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class Entitlements extends Table with TableInfo<Entitlements, EntitlementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Entitlements(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<DateTime?, int> verifiedAt =
      GeneratedColumn<int>(
        'verified_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: '',
      ).withConverter<DateTime?>(Entitlements.$converterverifiedAtn);
  @override
  List<GeneratedColumn> get $columns => [key, state, source, verifiedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entitlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntitlementRow> instance, {
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
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  EntitlementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntitlementRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      verifiedAt: Entitlements.$converterverifiedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}verified_at'],
        ),
      ),
    );
  }

  @override
  Entitlements createAlias(String alias) {
    return Entitlements(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterverifiedAt =
      const InstantConverter();
  static TypeConverter<DateTime?, int?> $converterverifiedAtn =
      NullAwareTypeConverter.wrap($converterverifiedAt);
  @override
  bool get dontWriteConstraints => true;
}

class EntitlementRow extends DataClass implements Insertable<EntitlementRow> {
  final String key;
  final String state;
  final String source;
  final DateTime? verifiedAt;
  const EntitlementRow({
    required this.key,
    required this.state,
    required this.source,
    this.verifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['state'] = Variable<String>(state);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<int>(
        Entitlements.$converterverifiedAtn.toSql(verifiedAt),
      );
    }
    return map;
  }

  EntitlementsCompanion toCompanion(bool nullToAbsent) {
    return EntitlementsCompanion(
      key: Value(key),
      state: Value(state),
      source: Value(source),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
    );
  }

  factory EntitlementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntitlementRow(
      key: serializer.fromJson<String>(json['key']),
      state: serializer.fromJson<String>(json['state']),
      source: serializer.fromJson<String>(json['source']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verified_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'state': serializer.toJson<String>(state),
      'source': serializer.toJson<String>(source),
      'verified_at': serializer.toJson<DateTime?>(verifiedAt),
    };
  }

  EntitlementRow copyWith({
    String? key,
    String? state,
    String? source,
    Value<DateTime?> verifiedAt = const Value.absent(),
  }) => EntitlementRow(
    key: key ?? this.key,
    state: state ?? this.state,
    source: source ?? this.source,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
  );
  EntitlementRow copyWithCompanion(EntitlementsCompanion data) {
    return EntitlementRow(
      key: data.key.present ? data.key.value : this.key,
      state: data.state.present ? data.state.value : this.state,
      source: data.source.present ? data.source.value : this.source,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementRow(')
          ..write('key: $key, ')
          ..write('state: $state, ')
          ..write('source: $source, ')
          ..write('verifiedAt: $verifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, state, source, verifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntitlementRow &&
          other.key == this.key &&
          other.state == this.state &&
          other.source == this.source &&
          other.verifiedAt == this.verifiedAt);
}

class EntitlementsCompanion extends UpdateCompanion<EntitlementRow> {
  final Value<String> key;
  final Value<String> state;
  final Value<String> source;
  final Value<DateTime?> verifiedAt;
  final Value<int> rowid;
  const EntitlementsCompanion({
    this.key = const Value.absent(),
    this.state = const Value.absent(),
    this.source = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitlementsCompanion.insert({
    required String key,
    required String state,
    required String source,
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       state = Value(state),
       source = Value(source);
  static Insertable<EntitlementRow> custom({
    Expression<String>? key,
    Expression<String>? state,
    Expression<String>? source,
    Expression<int>? verifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (state != null) 'state': state,
      if (source != null) 'source': source,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitlementsCompanion copyWith({
    Value<String>? key,
    Value<String>? state,
    Value<String>? source,
    Value<DateTime?>? verifiedAt,
    Value<int>? rowid,
  }) {
    return EntitlementsCompanion(
      key: key ?? this.key,
      state: state ?? this.state,
      source: source ?? this.source,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<int>(
        Entitlements.$converterverifiedAtn.toSql(verifiedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementsCompanion(')
          ..write('key: $key, ')
          ..write('state: $state, ')
          ..write('source: $source, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PurchaseOutboxTable extends Table
    with TableInfo<PurchaseOutboxTable, PurchaseOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PurchaseOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _txnKeyMeta = const VerificationMeta('txnKey');
  late final GeneratedColumn<String> txnKey = GeneratedColumn<String>(
    'txn_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (platform IN (\'ios\', \'android\'))',
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _verificationDataMeta = const VerificationMeta(
    'verificationData',
  );
  late final GeneratedColumn<String> verificationData = GeneratedColumn<String>(
    'verification_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status IN (\'awaitingVerification\', \'granted\', \'finished\', \'rejected\'))',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(PurchaseOutboxTable.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(PurchaseOutboxTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    txnKey,
    productId,
    platform,
    transactionId,
    verificationData,
    orderId,
    idempotencyKey,
    status,
    attempts,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('txn_key')) {
      context.handle(
        _txnKeyMeta,
        txnKey.isAcceptableOrUnknown(data['txn_key']!, _txnKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_txnKeyMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('verification_data')) {
      context.handle(
        _verificationDataMeta,
        verificationData.isAcceptableOrUnknown(
          data['verification_data']!,
          _verificationDataMeta,
        ),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {txnKey};
  @override
  PurchaseOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseOutboxRow(
      txnKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}txn_key'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      verificationData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_data'],
      ),
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: PurchaseOutboxTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: PurchaseOutboxTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  PurchaseOutboxTable createAlias(String alias) {
    return PurchaseOutboxTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
  @override
  bool get dontWriteConstraints => true;
}

class PurchaseOutboxRow extends DataClass
    implements Insertable<PurchaseOutboxRow> {
  final String txnKey;
  final String productId;
  final String platform;
  final String? transactionId;
  final String? verificationData;
  final String? orderId;
  final String idempotencyKey;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PurchaseOutboxRow({
    required this.txnKey,
    required this.productId,
    required this.platform,
    this.transactionId,
    this.verificationData,
    this.orderId,
    required this.idempotencyKey,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['txn_key'] = Variable<String>(txnKey);
    map['product_id'] = Variable<String>(productId);
    map['platform'] = Variable<String>(platform);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || verificationData != null) {
      map['verification_data'] = Variable<String>(verificationData);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<String>(orderId);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    {
      map['created_at'] = Variable<int>(
        PurchaseOutboxTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        PurchaseOutboxTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  PurchaseOutboxTableCompanion toCompanion(bool nullToAbsent) {
    return PurchaseOutboxTableCompanion(
      txnKey: Value(txnKey),
      productId: Value(productId),
      platform: Value(platform),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      verificationData: verificationData == null && nullToAbsent
          ? const Value.absent()
          : Value(verificationData),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      idempotencyKey: Value(idempotencyKey),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PurchaseOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseOutboxRow(
      txnKey: serializer.fromJson<String>(json['txn_key']),
      productId: serializer.fromJson<String>(json['product_id']),
      platform: serializer.fromJson<String>(json['platform']),
      transactionId: serializer.fromJson<String?>(json['transaction_id']),
      verificationData: serializer.fromJson<String?>(json['verification_data']),
      orderId: serializer.fromJson<String?>(json['order_id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotency_key']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['last_error']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'txn_key': serializer.toJson<String>(txnKey),
      'product_id': serializer.toJson<String>(productId),
      'platform': serializer.toJson<String>(platform),
      'transaction_id': serializer.toJson<String?>(transactionId),
      'verification_data': serializer.toJson<String?>(verificationData),
      'order_id': serializer.toJson<String?>(orderId),
      'idempotency_key': serializer.toJson<String>(idempotencyKey),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'last_error': serializer.toJson<String?>(lastError),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PurchaseOutboxRow copyWith({
    String? txnKey,
    String? productId,
    String? platform,
    Value<String?> transactionId = const Value.absent(),
    Value<String?> verificationData = const Value.absent(),
    Value<String?> orderId = const Value.absent(),
    String? idempotencyKey,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PurchaseOutboxRow(
    txnKey: txnKey ?? this.txnKey,
    productId: productId ?? this.productId,
    platform: platform ?? this.platform,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    verificationData: verificationData.present
        ? verificationData.value
        : this.verificationData,
    orderId: orderId.present ? orderId.value : this.orderId,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PurchaseOutboxRow copyWithCompanion(PurchaseOutboxTableCompanion data) {
    return PurchaseOutboxRow(
      txnKey: data.txnKey.present ? data.txnKey.value : this.txnKey,
      productId: data.productId.present ? data.productId.value : this.productId,
      platform: data.platform.present ? data.platform.value : this.platform,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      verificationData: data.verificationData.present
          ? data.verificationData.value
          : this.verificationData,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOutboxRow(')
          ..write('txnKey: $txnKey, ')
          ..write('productId: $productId, ')
          ..write('platform: $platform, ')
          ..write('transactionId: $transactionId, ')
          ..write('verificationData: $verificationData, ')
          ..write('orderId: $orderId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    txnKey,
    productId,
    platform,
    transactionId,
    verificationData,
    orderId,
    idempotencyKey,
    status,
    attempts,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOutboxRow &&
          other.txnKey == this.txnKey &&
          other.productId == this.productId &&
          other.platform == this.platform &&
          other.transactionId == this.transactionId &&
          other.verificationData == this.verificationData &&
          other.orderId == this.orderId &&
          other.idempotencyKey == this.idempotencyKey &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PurchaseOutboxTableCompanion extends UpdateCompanion<PurchaseOutboxRow> {
  final Value<String> txnKey;
  final Value<String> productId;
  final Value<String> platform;
  final Value<String?> transactionId;
  final Value<String?> verificationData;
  final Value<String?> orderId;
  final Value<String> idempotencyKey;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PurchaseOutboxTableCompanion({
    this.txnKey = const Value.absent(),
    this.productId = const Value.absent(),
    this.platform = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.verificationData = const Value.absent(),
    this.orderId = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseOutboxTableCompanion.insert({
    required String txnKey,
    required String productId,
    required String platform,
    this.transactionId = const Value.absent(),
    this.verificationData = const Value.absent(),
    this.orderId = const Value.absent(),
    required String idempotencyKey,
    required String status,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : txnKey = Value(txnKey),
       productId = Value(productId),
       platform = Value(platform),
       idempotencyKey = Value(idempotencyKey),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PurchaseOutboxRow> custom({
    Expression<String>? txnKey,
    Expression<String>? productId,
    Expression<String>? platform,
    Expression<String>? transactionId,
    Expression<String>? verificationData,
    Expression<String>? orderId,
    Expression<String>? idempotencyKey,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (txnKey != null) 'txn_key': txnKey,
      if (productId != null) 'product_id': productId,
      if (platform != null) 'platform': platform,
      if (transactionId != null) 'transaction_id': transactionId,
      if (verificationData != null) 'verification_data': verificationData,
      if (orderId != null) 'order_id': orderId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseOutboxTableCompanion copyWith({
    Value<String>? txnKey,
    Value<String>? productId,
    Value<String>? platform,
    Value<String?>? transactionId,
    Value<String?>? verificationData,
    Value<String?>? orderId,
    Value<String>? idempotencyKey,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PurchaseOutboxTableCompanion(
      txnKey: txnKey ?? this.txnKey,
      productId: productId ?? this.productId,
      platform: platform ?? this.platform,
      transactionId: transactionId ?? this.transactionId,
      verificationData: verificationData ?? this.verificationData,
      orderId: orderId ?? this.orderId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (txnKey.present) {
      map['txn_key'] = Variable<String>(txnKey.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (verificationData.present) {
      map['verification_data'] = Variable<String>(verificationData.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        PurchaseOutboxTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        PurchaseOutboxTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOutboxTableCompanion(')
          ..write('txnKey: $txnKey, ')
          ..write('productId: $productId, ')
          ..write('platform: $platform, ')
          ..write('transactionId: $transactionId, ')
          ..write('verificationData: $verificationData, ')
          ..write('orderId: $orderId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ConsentStates extends Table
    with TableInfo<ConsentStates, ConsentStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ConsentStates(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY DEFAULT 1 CHECK (id = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(ConsentStates.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, json, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consent_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsentStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsentStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsentStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      updatedAt: ConsentStates.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  ConsentStates createAlias(String alias) {
    return ConsentStates(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
  @override
  bool get dontWriteConstraints => true;
}

class ConsentStateRow extends DataClass implements Insertable<ConsentStateRow> {
  final int id;
  final String json;
  final DateTime updatedAt;
  const ConsentStateRow({
    required this.id,
    required this.json,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    {
      map['updated_at'] = Variable<int>(
        ConsentStates.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ConsentStatesCompanion toCompanion(bool nullToAbsent) {
    return ConsentStatesCompanion(
      id: Value(id),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConsentStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsentStateRow(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConsentStateRow copyWith({int? id, String? json, DateTime? updatedAt}) =>
      ConsentStateRow(
        id: id ?? this.id,
        json: json ?? this.json,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ConsentStateRow copyWithCompanion(ConsentStatesCompanion data) {
    return ConsentStateRow(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsentStateRow(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsentStateRow &&
          other.id == this.id &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class ConsentStatesCompanion extends UpdateCompanion<ConsentStateRow> {
  final Value<int> id;
  final Value<String> json;
  final Value<DateTime> updatedAt;
  const ConsentStatesCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConsentStatesCompanion.insert({
    this.id = const Value.absent(),
    required String json,
    required DateTime updatedAt,
  }) : json = Value(json),
       updatedAt = Value(updatedAt);
  static Insertable<ConsentStateRow> custom({
    Expression<int>? id,
    Expression<String>? json,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConsentStatesCompanion copyWith({
    Value<int>? id,
    Value<String>? json,
    Value<DateTime>? updatedAt,
  }) {
    return ConsentStatesCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        ConsentStates.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentStatesCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class SyncState extends Table with TableInfo<SyncState, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncState(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
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
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
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
  SyncState createAlias(String alias) {
    return SyncState(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String key;
  final String value;
  const SyncStateRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
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

  SyncStateRow copyWith({String? key, String? value}) =>
      SyncStateRow(key: key ?? this.key, value: value ?? this.value);
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
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
      (other is SyncStateRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateRow> custom({
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

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
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
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PendingAcks extends Table with TableInfo<PendingAcks, PendingAckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PendingAcks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _readingIdMeta = const VerificationMeta(
    'readingId',
  );
  late final GeneratedColumn<String> readingId = GeneratedColumn<String>(
    'reading_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(PendingAcks.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [readingId, attempts, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_acks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingAckRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reading_id')) {
      context.handle(
        _readingIdMeta,
        readingId.isAcceptableOrUnknown(data['reading_id']!, _readingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_readingIdMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {readingId};
  @override
  PendingAckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingAckRow(
      readingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_id'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: PendingAcks.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  PendingAcks createAlias(String alias) {
    return PendingAcks(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const InstantConverter();
  @override
  bool get dontWriteConstraints => true;
}

class PendingAckRow extends DataClass implements Insertable<PendingAckRow> {
  final String readingId;
  final int attempts;
  final DateTime createdAt;
  const PendingAckRow({
    required this.readingId,
    required this.attempts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reading_id'] = Variable<String>(readingId);
    map['attempts'] = Variable<int>(attempts);
    {
      map['created_at'] = Variable<int>(
        PendingAcks.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  PendingAcksCompanion toCompanion(bool nullToAbsent) {
    return PendingAcksCompanion(
      readingId: Value(readingId),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }

  factory PendingAckRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingAckRow(
      readingId: serializer.fromJson<String>(json['reading_id']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reading_id': serializer.toJson<String>(readingId),
      'attempts': serializer.toJson<int>(attempts),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingAckRow copyWith({
    String? readingId,
    int? attempts,
    DateTime? createdAt,
  }) => PendingAckRow(
    readingId: readingId ?? this.readingId,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingAckRow copyWithCompanion(PendingAcksCompanion data) {
    return PendingAckRow(
      readingId: data.readingId.present ? data.readingId.value : this.readingId,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingAckRow(')
          ..write('readingId: $readingId, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(readingId, attempts, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingAckRow &&
          other.readingId == this.readingId &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt);
}

class PendingAcksCompanion extends UpdateCompanion<PendingAckRow> {
  final Value<String> readingId;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingAcksCompanion({
    this.readingId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingAcksCompanion.insert({
    required String readingId,
    this.attempts = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : readingId = Value(readingId),
       createdAt = Value(createdAt);
  static Insertable<PendingAckRow> custom({
    Expression<String>? readingId,
    Expression<int>? attempts,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (readingId != null) 'reading_id': readingId,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingAcksCompanion copyWith({
    Value<String>? readingId,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingAcksCompanion(
      readingId: readingId ?? this.readingId,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (readingId.present) {
      map['reading_id'] = Variable<String>(readingId.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        PendingAcks.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingAcksCompanion(')
          ..write('readingId: $readingId, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DeviceDatabase extends GeneratedDatabase {
  _$DeviceDatabase(QueryExecutor e) : super(e);
  $DeviceDatabaseManager get managers => $DeviceDatabaseManager(this);
  late final BalanceCache balanceCache = BalanceCache(this);
  late final RemoteConfigCache remoteConfigCache = RemoteConfigCache(this);
  late final Entitlements entitlements = Entitlements(this);
  late final PurchaseOutboxTable purchaseOutboxTable = PurchaseOutboxTable(
    this,
  );
  late final ConsentStates consentStates = ConsentStates(this);
  late final SyncState syncState = SyncState(this);
  late final PendingAcks pendingAcks = PendingAcks(this);
  late final CacheDao cacheDao = CacheDao(this as DeviceDatabase);
  late final EntitlementsDao entitlementsDao = EntitlementsDao(
    this as DeviceDatabase,
  );
  late final OutboxDao outboxDao = OutboxDao(this as DeviceDatabase);
  late final PendingAcksDao pendingAcksDao = PendingAcksDao(
    this as DeviceDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    balanceCache,
    remoteConfigCache,
    entitlements,
    purchaseOutboxTable,
    consentStates,
    syncState,
    pendingAcks,
  ];
}

typedef $BalanceCacheCreateCompanionBuilder =
    BalanceCacheCompanion Function({
      Value<int> id,
      required String json,
      required int ledgerVersion,
      required DateTime serverTime,
      required DateTime syncedAt,
    });
typedef $BalanceCacheUpdateCompanionBuilder =
    BalanceCacheCompanion Function({
      Value<int> id,
      Value<String> json,
      Value<int> ledgerVersion,
      Value<DateTime> serverTime,
      Value<DateTime> syncedAt,
    });

class $BalanceCacheFilterComposer
    extends Composer<_$DeviceDatabase, BalanceCache> {
  $BalanceCacheFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ledgerVersion => $composableBuilder(
    column: $table.ledgerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get serverTime =>
      $composableBuilder(
        column: $table.serverTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get syncedAt =>
      $composableBuilder(
        column: $table.syncedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $BalanceCacheOrderingComposer
    extends Composer<_$DeviceDatabase, BalanceCache> {
  $BalanceCacheOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ledgerVersion => $composableBuilder(
    column: $table.ledgerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $BalanceCacheAnnotationComposer
    extends Composer<_$DeviceDatabase, BalanceCache> {
  $BalanceCacheAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get ledgerVersion => $composableBuilder(
    column: $table.ledgerVersion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get serverTime =>
      $composableBuilder(
        column: $table.serverTime,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $BalanceCacheTableManager
    extends
        RootTableManager<
          _$DeviceDatabase,
          BalanceCache,
          BalanceCacheRow,
          $BalanceCacheFilterComposer,
          $BalanceCacheOrderingComposer,
          $BalanceCacheAnnotationComposer,
          $BalanceCacheCreateCompanionBuilder,
          $BalanceCacheUpdateCompanionBuilder,
          (
            BalanceCacheRow,
            BaseReferences<_$DeviceDatabase, BalanceCache, BalanceCacheRow>,
          ),
          BalanceCacheRow,
          PrefetchHooks Function()
        > {
  $BalanceCacheTableManager(_$DeviceDatabase db, BalanceCache table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BalanceCacheFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BalanceCacheOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BalanceCacheAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> ledgerVersion = const Value.absent(),
                Value<DateTime> serverTime = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => BalanceCacheCompanion(
                id: id,
                json: json,
                ledgerVersion: ledgerVersion,
                serverTime: serverTime,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String json,
                required int ledgerVersion,
                required DateTime serverTime,
                required DateTime syncedAt,
              }) => BalanceCacheCompanion.insert(
                id: id,
                json: json,
                ledgerVersion: ledgerVersion,
                serverTime: serverTime,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $BalanceCacheProcessedTableManager =
    ProcessedTableManager<
      _$DeviceDatabase,
      BalanceCache,
      BalanceCacheRow,
      $BalanceCacheFilterComposer,
      $BalanceCacheOrderingComposer,
      $BalanceCacheAnnotationComposer,
      $BalanceCacheCreateCompanionBuilder,
      $BalanceCacheUpdateCompanionBuilder,
      (
        BalanceCacheRow,
        BaseReferences<_$DeviceDatabase, BalanceCache, BalanceCacheRow>,
      ),
      BalanceCacheRow,
      PrefetchHooks Function()
    >;
typedef $RemoteConfigCacheCreateCompanionBuilder =
    RemoteConfigCacheCompanion Function({
      Value<int> id,
      required String json,
      Value<String?> etag,
      required DateTime fetchedAt,
    });
typedef $RemoteConfigCacheUpdateCompanionBuilder =
    RemoteConfigCacheCompanion Function({
      Value<int> id,
      Value<String> json,
      Value<String?> etag,
      Value<DateTime> fetchedAt,
    });

class $RemoteConfigCacheFilterComposer
    extends Composer<_$DeviceDatabase, RemoteConfigCache> {
  $RemoteConfigCacheFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get fetchedAt =>
      $composableBuilder(
        column: $table.fetchedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $RemoteConfigCacheOrderingComposer
    extends Composer<_$DeviceDatabase, RemoteConfigCache> {
  $RemoteConfigCacheOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RemoteConfigCacheAnnotationComposer
    extends Composer<_$DeviceDatabase, RemoteConfigCache> {
  $RemoteConfigCacheAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $RemoteConfigCacheTableManager
    extends
        RootTableManager<
          _$DeviceDatabase,
          RemoteConfigCache,
          RemoteConfigCacheRow,
          $RemoteConfigCacheFilterComposer,
          $RemoteConfigCacheOrderingComposer,
          $RemoteConfigCacheAnnotationComposer,
          $RemoteConfigCacheCreateCompanionBuilder,
          $RemoteConfigCacheUpdateCompanionBuilder,
          (
            RemoteConfigCacheRow,
            BaseReferences<
              _$DeviceDatabase,
              RemoteConfigCache,
              RemoteConfigCacheRow
            >,
          ),
          RemoteConfigCacheRow,
          PrefetchHooks Function()
        > {
  $RemoteConfigCacheTableManager(_$DeviceDatabase db, RemoteConfigCache table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RemoteConfigCacheFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RemoteConfigCacheOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RemoteConfigCacheAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => RemoteConfigCacheCompanion(
                id: id,
                json: json,
                etag: etag,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String json,
                Value<String?> etag = const Value.absent(),
                required DateTime fetchedAt,
              }) => RemoteConfigCacheCompanion.insert(
                id: id,
                json: json,
                etag: etag,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $RemoteConfigCacheProcessedTableManager =
    ProcessedTableManager<
      _$DeviceDatabase,
      RemoteConfigCache,
      RemoteConfigCacheRow,
      $RemoteConfigCacheFilterComposer,
      $RemoteConfigCacheOrderingComposer,
      $RemoteConfigCacheAnnotationComposer,
      $RemoteConfigCacheCreateCompanionBuilder,
      $RemoteConfigCacheUpdateCompanionBuilder,
      (
        RemoteConfigCacheRow,
        BaseReferences<
          _$DeviceDatabase,
          RemoteConfigCache,
          RemoteConfigCacheRow
        >,
      ),
      RemoteConfigCacheRow,
      PrefetchHooks Function()
    >;
typedef $EntitlementsCreateCompanionBuilder =
    EntitlementsCompanion Function({
      required String key,
      required String state,
      required String source,
      Value<DateTime?> verifiedAt,
      Value<int> rowid,
    });
typedef $EntitlementsUpdateCompanionBuilder =
    EntitlementsCompanion Function({
      Value<String> key,
      Value<String> state,
      Value<String> source,
      Value<DateTime?> verifiedAt,
      Value<int> rowid,
    });

class $EntitlementsFilterComposer
    extends Composer<_$DeviceDatabase, Entitlements> {
  $EntitlementsFilterComposer({
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

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get verifiedAt =>
      $composableBuilder(
        column: $table.verifiedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $EntitlementsOrderingComposer
    extends Composer<_$DeviceDatabase, Entitlements> {
  $EntitlementsOrderingComposer({
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

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $EntitlementsAnnotationComposer
    extends Composer<_$DeviceDatabase, Entitlements> {
  $EntitlementsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get verifiedAt =>
      $composableBuilder(
        column: $table.verifiedAt,
        builder: (column) => column,
      );
}

class $EntitlementsTableManager
    extends
        RootTableManager<
          _$DeviceDatabase,
          Entitlements,
          EntitlementRow,
          $EntitlementsFilterComposer,
          $EntitlementsOrderingComposer,
          $EntitlementsAnnotationComposer,
          $EntitlementsCreateCompanionBuilder,
          $EntitlementsUpdateCompanionBuilder,
          (
            EntitlementRow,
            BaseReferences<_$DeviceDatabase, Entitlements, EntitlementRow>,
          ),
          EntitlementRow,
          PrefetchHooks Function()
        > {
  $EntitlementsTableManager(_$DeviceDatabase db, Entitlements table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EntitlementsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EntitlementsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EntitlementsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitlementsCompanion(
                key: key,
                state: state,
                source: source,
                verifiedAt: verifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String state,
                required String source,
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitlementsCompanion.insert(
                key: key,
                state: state,
                source: source,
                verifiedAt: verifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $EntitlementsProcessedTableManager =
    ProcessedTableManager<
      _$DeviceDatabase,
      Entitlements,
      EntitlementRow,
      $EntitlementsFilterComposer,
      $EntitlementsOrderingComposer,
      $EntitlementsAnnotationComposer,
      $EntitlementsCreateCompanionBuilder,
      $EntitlementsUpdateCompanionBuilder,
      (
        EntitlementRow,
        BaseReferences<_$DeviceDatabase, Entitlements, EntitlementRow>,
      ),
      EntitlementRow,
      PrefetchHooks Function()
    >;
typedef $PurchaseOutboxTableCreateCompanionBuilder =
    PurchaseOutboxTableCompanion Function({
      required String txnKey,
      required String productId,
      required String platform,
      Value<String?> transactionId,
      Value<String?> verificationData,
      Value<String?> orderId,
      required String idempotencyKey,
      required String status,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $PurchaseOutboxTableUpdateCompanionBuilder =
    PurchaseOutboxTableCompanion Function({
      Value<String> txnKey,
      Value<String> productId,
      Value<String> platform,
      Value<String?> transactionId,
      Value<String?> verificationData,
      Value<String?> orderId,
      Value<String> idempotencyKey,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $PurchaseOutboxTableFilterComposer
    extends Composer<_$DeviceDatabase, PurchaseOutboxTable> {
  $PurchaseOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get txnKey => $composableBuilder(
    column: $table.txnKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationData => $composableBuilder(
    column: $table.verificationData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $PurchaseOutboxTableOrderingComposer
    extends Composer<_$DeviceDatabase, PurchaseOutboxTable> {
  $PurchaseOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get txnKey => $composableBuilder(
    column: $table.txnKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationData => $composableBuilder(
    column: $table.verificationData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PurchaseOutboxTableAnnotationComposer
    extends Composer<_$DeviceDatabase, PurchaseOutboxTable> {
  $PurchaseOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get txnKey =>
      $composableBuilder(column: $table.txnKey, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verificationData => $composableBuilder(
    column: $table.verificationData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $PurchaseOutboxTableTableManager
    extends
        RootTableManager<
          _$DeviceDatabase,
          PurchaseOutboxTable,
          PurchaseOutboxRow,
          $PurchaseOutboxTableFilterComposer,
          $PurchaseOutboxTableOrderingComposer,
          $PurchaseOutboxTableAnnotationComposer,
          $PurchaseOutboxTableCreateCompanionBuilder,
          $PurchaseOutboxTableUpdateCompanionBuilder,
          (
            PurchaseOutboxRow,
            BaseReferences<
              _$DeviceDatabase,
              PurchaseOutboxTable,
              PurchaseOutboxRow
            >,
          ),
          PurchaseOutboxRow,
          PrefetchHooks Function()
        > {
  $PurchaseOutboxTableTableManager(
    _$DeviceDatabase db,
    PurchaseOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PurchaseOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PurchaseOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PurchaseOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> txnKey = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> verificationData = const Value.absent(),
                Value<String?> orderId = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOutboxTableCompanion(
                txnKey: txnKey,
                productId: productId,
                platform: platform,
                transactionId: transactionId,
                verificationData: verificationData,
                orderId: orderId,
                idempotencyKey: idempotencyKey,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String txnKey,
                required String productId,
                required String platform,
                Value<String?> transactionId = const Value.absent(),
                Value<String?> verificationData = const Value.absent(),
                Value<String?> orderId = const Value.absent(),
                required String idempotencyKey,
                required String status,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOutboxTableCompanion.insert(
                txnKey: txnKey,
                productId: productId,
                platform: platform,
                transactionId: transactionId,
                verificationData: verificationData,
                orderId: orderId,
                idempotencyKey: idempotencyKey,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PurchaseOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$DeviceDatabase,
      PurchaseOutboxTable,
      PurchaseOutboxRow,
      $PurchaseOutboxTableFilterComposer,
      $PurchaseOutboxTableOrderingComposer,
      $PurchaseOutboxTableAnnotationComposer,
      $PurchaseOutboxTableCreateCompanionBuilder,
      $PurchaseOutboxTableUpdateCompanionBuilder,
      (
        PurchaseOutboxRow,
        BaseReferences<
          _$DeviceDatabase,
          PurchaseOutboxTable,
          PurchaseOutboxRow
        >,
      ),
      PurchaseOutboxRow,
      PrefetchHooks Function()
    >;
typedef $ConsentStatesCreateCompanionBuilder =
    ConsentStatesCompanion Function({
      Value<int> id,
      required String json,
      required DateTime updatedAt,
    });
typedef $ConsentStatesUpdateCompanionBuilder =
    ConsentStatesCompanion Function({
      Value<int> id,
      Value<String> json,
      Value<DateTime> updatedAt,
    });

class $ConsentStatesFilterComposer
    extends Composer<_$DeviceDatabase, ConsentStates> {
  $ConsentStatesFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $ConsentStatesOrderingComposer
    extends Composer<_$DeviceDatabase, ConsentStates> {
  $ConsentStatesOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ConsentStatesAnnotationComposer
    extends Composer<_$DeviceDatabase, ConsentStates> {
  $ConsentStatesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $ConsentStatesTableManager
    extends
        RootTableManager<
          _$DeviceDatabase,
          ConsentStates,
          ConsentStateRow,
          $ConsentStatesFilterComposer,
          $ConsentStatesOrderingComposer,
          $ConsentStatesAnnotationComposer,
          $ConsentStatesCreateCompanionBuilder,
          $ConsentStatesUpdateCompanionBuilder,
          (
            ConsentStateRow,
            BaseReferences<_$DeviceDatabase, ConsentStates, ConsentStateRow>,
          ),
          ConsentStateRow,
          PrefetchHooks Function()
        > {
  $ConsentStatesTableManager(_$DeviceDatabase db, ConsentStates table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ConsentStatesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ConsentStatesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ConsentStatesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConsentStatesCompanion(
                id: id,
                json: json,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String json,
                required DateTime updatedAt,
              }) => ConsentStatesCompanion.insert(
                id: id,
                json: json,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ConsentStatesProcessedTableManager =
    ProcessedTableManager<
      _$DeviceDatabase,
      ConsentStates,
      ConsentStateRow,
      $ConsentStatesFilterComposer,
      $ConsentStatesOrderingComposer,
      $ConsentStatesAnnotationComposer,
      $ConsentStatesCreateCompanionBuilder,
      $ConsentStatesUpdateCompanionBuilder,
      (
        ConsentStateRow,
        BaseReferences<_$DeviceDatabase, ConsentStates, ConsentStateRow>,
      ),
      ConsentStateRow,
      PrefetchHooks Function()
    >;
typedef $SyncStateCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $SyncStateUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $SyncStateFilterComposer extends Composer<_$DeviceDatabase, SyncState> {
  $SyncStateFilterComposer({
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

class $SyncStateOrderingComposer extends Composer<_$DeviceDatabase, SyncState> {
  $SyncStateOrderingComposer({
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

class $SyncStateAnnotationComposer
    extends Composer<_$DeviceDatabase, SyncState> {
  $SyncStateAnnotationComposer({
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

class $SyncStateTableManager
    extends
        RootTableManager<
          _$DeviceDatabase,
          SyncState,
          SyncStateRow,
          $SyncStateFilterComposer,
          $SyncStateOrderingComposer,
          $SyncStateAnnotationComposer,
          $SyncStateCreateCompanionBuilder,
          $SyncStateUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$DeviceDatabase, SyncState, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $SyncStateTableManager(_$DeviceDatabase db, SyncState table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncStateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncStateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncStateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncStateProcessedTableManager =
    ProcessedTableManager<
      _$DeviceDatabase,
      SyncState,
      SyncStateRow,
      $SyncStateFilterComposer,
      $SyncStateOrderingComposer,
      $SyncStateAnnotationComposer,
      $SyncStateCreateCompanionBuilder,
      $SyncStateUpdateCompanionBuilder,
      (SyncStateRow, BaseReferences<_$DeviceDatabase, SyncState, SyncStateRow>),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $PendingAcksCreateCompanionBuilder =
    PendingAcksCompanion Function({
      required String readingId,
      Value<int> attempts,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $PendingAcksUpdateCompanionBuilder =
    PendingAcksCompanion Function({
      Value<String> readingId,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $PendingAcksFilterComposer
    extends Composer<_$DeviceDatabase, PendingAcks> {
  $PendingAcksFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get readingId => $composableBuilder(
    column: $table.readingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $PendingAcksOrderingComposer
    extends Composer<_$DeviceDatabase, PendingAcks> {
  $PendingAcksOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get readingId => $composableBuilder(
    column: $table.readingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PendingAcksAnnotationComposer
    extends Composer<_$DeviceDatabase, PendingAcks> {
  $PendingAcksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get readingId =>
      $composableBuilder(column: $table.readingId, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $PendingAcksTableManager
    extends
        RootTableManager<
          _$DeviceDatabase,
          PendingAcks,
          PendingAckRow,
          $PendingAcksFilterComposer,
          $PendingAcksOrderingComposer,
          $PendingAcksAnnotationComposer,
          $PendingAcksCreateCompanionBuilder,
          $PendingAcksUpdateCompanionBuilder,
          (
            PendingAckRow,
            BaseReferences<_$DeviceDatabase, PendingAcks, PendingAckRow>,
          ),
          PendingAckRow,
          PrefetchHooks Function()
        > {
  $PendingAcksTableManager(_$DeviceDatabase db, PendingAcks table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PendingAcksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PendingAcksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PendingAcksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> readingId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingAcksCompanion(
                readingId: readingId,
                attempts: attempts,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String readingId,
                Value<int> attempts = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingAcksCompanion.insert(
                readingId: readingId,
                attempts: attempts,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PendingAcksProcessedTableManager =
    ProcessedTableManager<
      _$DeviceDatabase,
      PendingAcks,
      PendingAckRow,
      $PendingAcksFilterComposer,
      $PendingAcksOrderingComposer,
      $PendingAcksAnnotationComposer,
      $PendingAcksCreateCompanionBuilder,
      $PendingAcksUpdateCompanionBuilder,
      (
        PendingAckRow,
        BaseReferences<_$DeviceDatabase, PendingAcks, PendingAckRow>,
      ),
      PendingAckRow,
      PrefetchHooks Function()
    >;

class $DeviceDatabaseManager {
  final _$DeviceDatabase _db;
  $DeviceDatabaseManager(this._db);
  $BalanceCacheTableManager get balanceCache =>
      $BalanceCacheTableManager(_db, _db.balanceCache);
  $RemoteConfigCacheTableManager get remoteConfigCache =>
      $RemoteConfigCacheTableManager(_db, _db.remoteConfigCache);
  $EntitlementsTableManager get entitlements =>
      $EntitlementsTableManager(_db, _db.entitlements);
  $PurchaseOutboxTableTableManager get purchaseOutboxTable =>
      $PurchaseOutboxTableTableManager(_db, _db.purchaseOutboxTable);
  $ConsentStatesTableManager get consentStates =>
      $ConsentStatesTableManager(_db, _db.consentStates);
  $SyncStateTableManager get syncState =>
      $SyncStateTableManager(_db, _db.syncState);
  $PendingAcksTableManager get pendingAcks =>
      $PendingAcksTableManager(_db, _db.pendingAcks);
}
