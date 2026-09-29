// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_database.dart';

// ignore_for_file: type=lint
class Readings extends Table with TableInfo<Readings, ReadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Readings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _spreadIdMeta = const VerificationMeta(
    'spreadId',
  );
  late final GeneratedColumn<String> spreadId = GeneratedColumn<String>(
    'spread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _spreadVersionMeta = const VerificationMeta(
    'spreadVersion',
  );
  late final GeneratedColumn<int> spreadVersion = GeneratedColumn<int>(
    'spread_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status IN (\'pending\', \'complete\', \'failed\', \'refused\', \'classic\'))',
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _safetyJsonMeta = const VerificationMeta(
    'safetyJson',
  );
  late final GeneratedColumn<String> safetyJson = GeneratedColumn<String>(
    'safety_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _failureJsonMeta = const VerificationMeta(
    'failureJson',
  );
  late final GeneratedColumn<String> failureJson = GeneratedColumn<String>(
    'failure_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _contentLocaleMeta = const VerificationMeta(
    'contentLocale',
  );
  late final GeneratedColumn<String> contentLocale = GeneratedColumn<String>(
    'content_locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  late final GeneratedColumn<String> promptVersion = GeneratedColumn<String>(
    'prompt_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _chargeSourceMeta = const VerificationMeta(
    'chargeSource',
  );
  late final GeneratedColumn<String> chargeSource = GeneratedColumn<String>(
    'charge_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _favouriteMeta = const VerificationMeta(
    'favourite',
  );
  late final GeneratedColumn<bool> favourite = GeneratedColumn<bool>(
    'favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (rating IN (\'up\', \'down\'))',
  );
  static const VerificationMeta _ratingReasonMeta = const VerificationMeta(
    'ratingReason',
  );
  late final GeneratedColumn<String> ratingReason = GeneratedColumn<String>(
    'rating_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deliveryAckedMeta = const VerificationMeta(
    'deliveryAcked',
  );
  late final GeneratedColumn<bool> deliveryAcked = GeneratedColumn<bool>(
    'delivery_acked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _reportedMeta = const VerificationMeta(
    'reported',
  );
  late final GeneratedColumn<bool> reported = GeneratedColumn<bool>(
    'reported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> drawnAt =
      GeneratedColumn<int>(
        'drawn_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(Readings.$converterdrawnAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(Readings.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(Readings.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    spreadId,
    spreadVersion,
    localDate,
    question,
    status,
    contentJson,
    safetyJson,
    failureJson,
    contentLocale,
    promptVersion,
    modelId,
    chargeSource,
    note,
    favourite,
    rating,
    ratingReason,
    deliveryAcked,
    reported,
    drawnAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('spread_id')) {
      context.handle(
        _spreadIdMeta,
        spreadId.isAcceptableOrUnknown(data['spread_id']!, _spreadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spreadIdMeta);
    }
    if (data.containsKey('spread_version')) {
      context.handle(
        _spreadVersionMeta,
        spreadVersion.isAcceptableOrUnknown(
          data['spread_version']!,
          _spreadVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_spreadVersionMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    }
    if (data.containsKey('safety_json')) {
      context.handle(
        _safetyJsonMeta,
        safetyJson.isAcceptableOrUnknown(data['safety_json']!, _safetyJsonMeta),
      );
    }
    if (data.containsKey('failure_json')) {
      context.handle(
        _failureJsonMeta,
        failureJson.isAcceptableOrUnknown(
          data['failure_json']!,
          _failureJsonMeta,
        ),
      );
    }
    if (data.containsKey('content_locale')) {
      context.handle(
        _contentLocaleMeta,
        contentLocale.isAcceptableOrUnknown(
          data['content_locale']!,
          _contentLocaleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentLocaleMeta);
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('charge_source')) {
      context.handle(
        _chargeSourceMeta,
        chargeSource.isAcceptableOrUnknown(
          data['charge_source']!,
          _chargeSourceMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('favourite')) {
      context.handle(
        _favouriteMeta,
        favourite.isAcceptableOrUnknown(data['favourite']!, _favouriteMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('rating_reason')) {
      context.handle(
        _ratingReasonMeta,
        ratingReason.isAcceptableOrUnknown(
          data['rating_reason']!,
          _ratingReasonMeta,
        ),
      );
    }
    if (data.containsKey('delivery_acked')) {
      context.handle(
        _deliveryAckedMeta,
        deliveryAcked.isAcceptableOrUnknown(
          data['delivery_acked']!,
          _deliveryAckedMeta,
        ),
      );
    }
    if (data.containsKey('reported')) {
      context.handle(
        _reportedMeta,
        reported.isAcceptableOrUnknown(data['reported']!, _reportedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      spreadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spread_id'],
      )!,
      spreadVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spread_version'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      ),
      safetyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safety_json'],
      ),
      failureJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_json'],
      ),
      contentLocale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_locale'],
      )!,
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_version'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      chargeSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}charge_source'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      favourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favourite'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      ratingReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_reason'],
      ),
      deliveryAcked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}delivery_acked'],
      )!,
      reported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reported'],
      )!,
      drawnAt: Readings.$converterdrawnAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}drawn_at'],
        )!,
      ),
      createdAt: Readings.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: Readings.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  Readings createAlias(String alias) {
    return Readings(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdrawnAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
  @override
  bool get dontWriteConstraints => true;
}

class ReadingRow extends DataClass implements Insertable<ReadingRow> {
  final String id;
  final String spreadId;
  final int spreadVersion;
  final String localDate;
  final String? question;
  final String status;
  final String? contentJson;
  final String? safetyJson;
  final String? failureJson;
  final String contentLocale;
  final String? promptVersion;
  final String? modelId;
  final String? chargeSource;
  final String? note;
  final bool favourite;
  final String? rating;
  final String? ratingReason;
  final bool deliveryAcked;
  final bool reported;
  final DateTime drawnAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ReadingRow({
    required this.id,
    required this.spreadId,
    required this.spreadVersion,
    required this.localDate,
    this.question,
    required this.status,
    this.contentJson,
    this.safetyJson,
    this.failureJson,
    required this.contentLocale,
    this.promptVersion,
    this.modelId,
    this.chargeSource,
    this.note,
    required this.favourite,
    this.rating,
    this.ratingReason,
    required this.deliveryAcked,
    required this.reported,
    required this.drawnAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['spread_id'] = Variable<String>(spreadId);
    map['spread_version'] = Variable<int>(spreadVersion);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || question != null) {
      map['question'] = Variable<String>(question);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || contentJson != null) {
      map['content_json'] = Variable<String>(contentJson);
    }
    if (!nullToAbsent || safetyJson != null) {
      map['safety_json'] = Variable<String>(safetyJson);
    }
    if (!nullToAbsent || failureJson != null) {
      map['failure_json'] = Variable<String>(failureJson);
    }
    map['content_locale'] = Variable<String>(contentLocale);
    if (!nullToAbsent || promptVersion != null) {
      map['prompt_version'] = Variable<String>(promptVersion);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || chargeSource != null) {
      map['charge_source'] = Variable<String>(chargeSource);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['favourite'] = Variable<bool>(favourite);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    if (!nullToAbsent || ratingReason != null) {
      map['rating_reason'] = Variable<String>(ratingReason);
    }
    map['delivery_acked'] = Variable<bool>(deliveryAcked);
    map['reported'] = Variable<bool>(reported);
    {
      map['drawn_at'] = Variable<int>(
        Readings.$converterdrawnAt.toSql(drawnAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        Readings.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        Readings.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      spreadId: Value(spreadId),
      spreadVersion: Value(spreadVersion),
      localDate: Value(localDate),
      question: question == null && nullToAbsent
          ? const Value.absent()
          : Value(question),
      status: Value(status),
      contentJson: contentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contentJson),
      safetyJson: safetyJson == null && nullToAbsent
          ? const Value.absent()
          : Value(safetyJson),
      failureJson: failureJson == null && nullToAbsent
          ? const Value.absent()
          : Value(failureJson),
      contentLocale: Value(contentLocale),
      promptVersion: promptVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(promptVersion),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      chargeSource: chargeSource == null && nullToAbsent
          ? const Value.absent()
          : Value(chargeSource),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      favourite: Value(favourite),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      ratingReason: ratingReason == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingReason),
      deliveryAcked: Value(deliveryAcked),
      reported: Value(reported),
      drawnAt: Value(drawnAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingRow(
      id: serializer.fromJson<String>(json['id']),
      spreadId: serializer.fromJson<String>(json['spread_id']),
      spreadVersion: serializer.fromJson<int>(json['spread_version']),
      localDate: serializer.fromJson<String>(json['local_date']),
      question: serializer.fromJson<String?>(json['question']),
      status: serializer.fromJson<String>(json['status']),
      contentJson: serializer.fromJson<String?>(json['content_json']),
      safetyJson: serializer.fromJson<String?>(json['safety_json']),
      failureJson: serializer.fromJson<String?>(json['failure_json']),
      contentLocale: serializer.fromJson<String>(json['content_locale']),
      promptVersion: serializer.fromJson<String?>(json['prompt_version']),
      modelId: serializer.fromJson<String?>(json['model_id']),
      chargeSource: serializer.fromJson<String?>(json['charge_source']),
      note: serializer.fromJson<String?>(json['note']),
      favourite: serializer.fromJson<bool>(json['favourite']),
      rating: serializer.fromJson<String?>(json['rating']),
      ratingReason: serializer.fromJson<String?>(json['rating_reason']),
      deliveryAcked: serializer.fromJson<bool>(json['delivery_acked']),
      reported: serializer.fromJson<bool>(json['reported']),
      drawnAt: serializer.fromJson<DateTime>(json['drawn_at']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spread_id': serializer.toJson<String>(spreadId),
      'spread_version': serializer.toJson<int>(spreadVersion),
      'local_date': serializer.toJson<String>(localDate),
      'question': serializer.toJson<String?>(question),
      'status': serializer.toJson<String>(status),
      'content_json': serializer.toJson<String?>(contentJson),
      'safety_json': serializer.toJson<String?>(safetyJson),
      'failure_json': serializer.toJson<String?>(failureJson),
      'content_locale': serializer.toJson<String>(contentLocale),
      'prompt_version': serializer.toJson<String?>(promptVersion),
      'model_id': serializer.toJson<String?>(modelId),
      'charge_source': serializer.toJson<String?>(chargeSource),
      'note': serializer.toJson<String?>(note),
      'favourite': serializer.toJson<bool>(favourite),
      'rating': serializer.toJson<String?>(rating),
      'rating_reason': serializer.toJson<String?>(ratingReason),
      'delivery_acked': serializer.toJson<bool>(deliveryAcked),
      'reported': serializer.toJson<bool>(reported),
      'drawn_at': serializer.toJson<DateTime>(drawnAt),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingRow copyWith({
    String? id,
    String? spreadId,
    int? spreadVersion,
    String? localDate,
    Value<String?> question = const Value.absent(),
    String? status,
    Value<String?> contentJson = const Value.absent(),
    Value<String?> safetyJson = const Value.absent(),
    Value<String?> failureJson = const Value.absent(),
    String? contentLocale,
    Value<String?> promptVersion = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    Value<String?> chargeSource = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? favourite,
    Value<String?> rating = const Value.absent(),
    Value<String?> ratingReason = const Value.absent(),
    bool? deliveryAcked,
    bool? reported,
    DateTime? drawnAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReadingRow(
    id: id ?? this.id,
    spreadId: spreadId ?? this.spreadId,
    spreadVersion: spreadVersion ?? this.spreadVersion,
    localDate: localDate ?? this.localDate,
    question: question.present ? question.value : this.question,
    status: status ?? this.status,
    contentJson: contentJson.present ? contentJson.value : this.contentJson,
    safetyJson: safetyJson.present ? safetyJson.value : this.safetyJson,
    failureJson: failureJson.present ? failureJson.value : this.failureJson,
    contentLocale: contentLocale ?? this.contentLocale,
    promptVersion: promptVersion.present
        ? promptVersion.value
        : this.promptVersion,
    modelId: modelId.present ? modelId.value : this.modelId,
    chargeSource: chargeSource.present ? chargeSource.value : this.chargeSource,
    note: note.present ? note.value : this.note,
    favourite: favourite ?? this.favourite,
    rating: rating.present ? rating.value : this.rating,
    ratingReason: ratingReason.present ? ratingReason.value : this.ratingReason,
    deliveryAcked: deliveryAcked ?? this.deliveryAcked,
    reported: reported ?? this.reported,
    drawnAt: drawnAt ?? this.drawnAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingRow copyWithCompanion(ReadingsCompanion data) {
    return ReadingRow(
      id: data.id.present ? data.id.value : this.id,
      spreadId: data.spreadId.present ? data.spreadId.value : this.spreadId,
      spreadVersion: data.spreadVersion.present
          ? data.spreadVersion.value
          : this.spreadVersion,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      question: data.question.present ? data.question.value : this.question,
      status: data.status.present ? data.status.value : this.status,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
      safetyJson: data.safetyJson.present
          ? data.safetyJson.value
          : this.safetyJson,
      failureJson: data.failureJson.present
          ? data.failureJson.value
          : this.failureJson,
      contentLocale: data.contentLocale.present
          ? data.contentLocale.value
          : this.contentLocale,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      chargeSource: data.chargeSource.present
          ? data.chargeSource.value
          : this.chargeSource,
      note: data.note.present ? data.note.value : this.note,
      favourite: data.favourite.present ? data.favourite.value : this.favourite,
      rating: data.rating.present ? data.rating.value : this.rating,
      ratingReason: data.ratingReason.present
          ? data.ratingReason.value
          : this.ratingReason,
      deliveryAcked: data.deliveryAcked.present
          ? data.deliveryAcked.value
          : this.deliveryAcked,
      reported: data.reported.present ? data.reported.value : this.reported,
      drawnAt: data.drawnAt.present ? data.drawnAt.value : this.drawnAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRow(')
          ..write('id: $id, ')
          ..write('spreadId: $spreadId, ')
          ..write('spreadVersion: $spreadVersion, ')
          ..write('localDate: $localDate, ')
          ..write('question: $question, ')
          ..write('status: $status, ')
          ..write('contentJson: $contentJson, ')
          ..write('safetyJson: $safetyJson, ')
          ..write('failureJson: $failureJson, ')
          ..write('contentLocale: $contentLocale, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('modelId: $modelId, ')
          ..write('chargeSource: $chargeSource, ')
          ..write('note: $note, ')
          ..write('favourite: $favourite, ')
          ..write('rating: $rating, ')
          ..write('ratingReason: $ratingReason, ')
          ..write('deliveryAcked: $deliveryAcked, ')
          ..write('reported: $reported, ')
          ..write('drawnAt: $drawnAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    spreadId,
    spreadVersion,
    localDate,
    question,
    status,
    contentJson,
    safetyJson,
    failureJson,
    contentLocale,
    promptVersion,
    modelId,
    chargeSource,
    note,
    favourite,
    rating,
    ratingReason,
    deliveryAcked,
    reported,
    drawnAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingRow &&
          other.id == this.id &&
          other.spreadId == this.spreadId &&
          other.spreadVersion == this.spreadVersion &&
          other.localDate == this.localDate &&
          other.question == this.question &&
          other.status == this.status &&
          other.contentJson == this.contentJson &&
          other.safetyJson == this.safetyJson &&
          other.failureJson == this.failureJson &&
          other.contentLocale == this.contentLocale &&
          other.promptVersion == this.promptVersion &&
          other.modelId == this.modelId &&
          other.chargeSource == this.chargeSource &&
          other.note == this.note &&
          other.favourite == this.favourite &&
          other.rating == this.rating &&
          other.ratingReason == this.ratingReason &&
          other.deliveryAcked == this.deliveryAcked &&
          other.reported == this.reported &&
          other.drawnAt == this.drawnAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReadingsCompanion extends UpdateCompanion<ReadingRow> {
  final Value<String> id;
  final Value<String> spreadId;
  final Value<int> spreadVersion;
  final Value<String> localDate;
  final Value<String?> question;
  final Value<String> status;
  final Value<String?> contentJson;
  final Value<String?> safetyJson;
  final Value<String?> failureJson;
  final Value<String> contentLocale;
  final Value<String?> promptVersion;
  final Value<String?> modelId;
  final Value<String?> chargeSource;
  final Value<String?> note;
  final Value<bool> favourite;
  final Value<String?> rating;
  final Value<String?> ratingReason;
  final Value<bool> deliveryAcked;
  final Value<bool> reported;
  final Value<DateTime> drawnAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.spreadId = const Value.absent(),
    this.spreadVersion = const Value.absent(),
    this.localDate = const Value.absent(),
    this.question = const Value.absent(),
    this.status = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.safetyJson = const Value.absent(),
    this.failureJson = const Value.absent(),
    this.contentLocale = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.modelId = const Value.absent(),
    this.chargeSource = const Value.absent(),
    this.note = const Value.absent(),
    this.favourite = const Value.absent(),
    this.rating = const Value.absent(),
    this.ratingReason = const Value.absent(),
    this.deliveryAcked = const Value.absent(),
    this.reported = const Value.absent(),
    this.drawnAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingsCompanion.insert({
    required String id,
    required String spreadId,
    required int spreadVersion,
    required String localDate,
    this.question = const Value.absent(),
    required String status,
    this.contentJson = const Value.absent(),
    this.safetyJson = const Value.absent(),
    this.failureJson = const Value.absent(),
    required String contentLocale,
    this.promptVersion = const Value.absent(),
    this.modelId = const Value.absent(),
    this.chargeSource = const Value.absent(),
    this.note = const Value.absent(),
    this.favourite = const Value.absent(),
    this.rating = const Value.absent(),
    this.ratingReason = const Value.absent(),
    this.deliveryAcked = const Value.absent(),
    this.reported = const Value.absent(),
    required DateTime drawnAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       spreadId = Value(spreadId),
       spreadVersion = Value(spreadVersion),
       localDate = Value(localDate),
       status = Value(status),
       contentLocale = Value(contentLocale),
       drawnAt = Value(drawnAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingRow> custom({
    Expression<String>? id,
    Expression<String>? spreadId,
    Expression<int>? spreadVersion,
    Expression<String>? localDate,
    Expression<String>? question,
    Expression<String>? status,
    Expression<String>? contentJson,
    Expression<String>? safetyJson,
    Expression<String>? failureJson,
    Expression<String>? contentLocale,
    Expression<String>? promptVersion,
    Expression<String>? modelId,
    Expression<String>? chargeSource,
    Expression<String>? note,
    Expression<bool>? favourite,
    Expression<String>? rating,
    Expression<String>? ratingReason,
    Expression<bool>? deliveryAcked,
    Expression<bool>? reported,
    Expression<int>? drawnAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spreadId != null) 'spread_id': spreadId,
      if (spreadVersion != null) 'spread_version': spreadVersion,
      if (localDate != null) 'local_date': localDate,
      if (question != null) 'question': question,
      if (status != null) 'status': status,
      if (contentJson != null) 'content_json': contentJson,
      if (safetyJson != null) 'safety_json': safetyJson,
      if (failureJson != null) 'failure_json': failureJson,
      if (contentLocale != null) 'content_locale': contentLocale,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (modelId != null) 'model_id': modelId,
      if (chargeSource != null) 'charge_source': chargeSource,
      if (note != null) 'note': note,
      if (favourite != null) 'favourite': favourite,
      if (rating != null) 'rating': rating,
      if (ratingReason != null) 'rating_reason': ratingReason,
      if (deliveryAcked != null) 'delivery_acked': deliveryAcked,
      if (reported != null) 'reported': reported,
      if (drawnAt != null) 'drawn_at': drawnAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingsCompanion copyWith({
    Value<String>? id,
    Value<String>? spreadId,
    Value<int>? spreadVersion,
    Value<String>? localDate,
    Value<String?>? question,
    Value<String>? status,
    Value<String?>? contentJson,
    Value<String?>? safetyJson,
    Value<String?>? failureJson,
    Value<String>? contentLocale,
    Value<String?>? promptVersion,
    Value<String?>? modelId,
    Value<String?>? chargeSource,
    Value<String?>? note,
    Value<bool>? favourite,
    Value<String?>? rating,
    Value<String?>? ratingReason,
    Value<bool>? deliveryAcked,
    Value<bool>? reported,
    Value<DateTime>? drawnAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReadingsCompanion(
      id: id ?? this.id,
      spreadId: spreadId ?? this.spreadId,
      spreadVersion: spreadVersion ?? this.spreadVersion,
      localDate: localDate ?? this.localDate,
      question: question ?? this.question,
      status: status ?? this.status,
      contentJson: contentJson ?? this.contentJson,
      safetyJson: safetyJson ?? this.safetyJson,
      failureJson: failureJson ?? this.failureJson,
      contentLocale: contentLocale ?? this.contentLocale,
      promptVersion: promptVersion ?? this.promptVersion,
      modelId: modelId ?? this.modelId,
      chargeSource: chargeSource ?? this.chargeSource,
      note: note ?? this.note,
      favourite: favourite ?? this.favourite,
      rating: rating ?? this.rating,
      ratingReason: ratingReason ?? this.ratingReason,
      deliveryAcked: deliveryAcked ?? this.deliveryAcked,
      reported: reported ?? this.reported,
      drawnAt: drawnAt ?? this.drawnAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (spreadId.present) {
      map['spread_id'] = Variable<String>(spreadId.value);
    }
    if (spreadVersion.present) {
      map['spread_version'] = Variable<int>(spreadVersion.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (safetyJson.present) {
      map['safety_json'] = Variable<String>(safetyJson.value);
    }
    if (failureJson.present) {
      map['failure_json'] = Variable<String>(failureJson.value);
    }
    if (contentLocale.present) {
      map['content_locale'] = Variable<String>(contentLocale.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<String>(promptVersion.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (chargeSource.present) {
      map['charge_source'] = Variable<String>(chargeSource.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (favourite.present) {
      map['favourite'] = Variable<bool>(favourite.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (ratingReason.present) {
      map['rating_reason'] = Variable<String>(ratingReason.value);
    }
    if (deliveryAcked.present) {
      map['delivery_acked'] = Variable<bool>(deliveryAcked.value);
    }
    if (reported.present) {
      map['reported'] = Variable<bool>(reported.value);
    }
    if (drawnAt.present) {
      map['drawn_at'] = Variable<int>(
        Readings.$converterdrawnAt.toSql(drawnAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        Readings.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        Readings.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('spreadId: $spreadId, ')
          ..write('spreadVersion: $spreadVersion, ')
          ..write('localDate: $localDate, ')
          ..write('question: $question, ')
          ..write('status: $status, ')
          ..write('contentJson: $contentJson, ')
          ..write('safetyJson: $safetyJson, ')
          ..write('failureJson: $failureJson, ')
          ..write('contentLocale: $contentLocale, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('modelId: $modelId, ')
          ..write('chargeSource: $chargeSource, ')
          ..write('note: $note, ')
          ..write('favourite: $favourite, ')
          ..write('rating: $rating, ')
          ..write('ratingReason: $ratingReason, ')
          ..write('deliveryAcked: $deliveryAcked, ')
          ..write('reported: $reported, ')
          ..write('drawnAt: $drawnAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ReadingCards extends Table with TableInfo<ReadingCards, ReadingCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ReadingCards(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _readingIdMeta = const VerificationMeta(
    'readingId',
  );
  late final GeneratedColumn<String> readingId = GeneratedColumn<String>(
    'reading_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES readings(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _positionIdMeta = const VerificationMeta(
    'positionId',
  );
  late final GeneratedColumn<String> positionId = GeneratedColumn<String>(
    'position_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _positionOrderMeta = const VerificationMeta(
    'positionOrder',
  );
  late final GeneratedColumn<int> positionOrder = GeneratedColumn<int>(
    'position_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _reversedMeta = const VerificationMeta(
    'reversed',
  );
  late final GeneratedColumn<bool> reversed = GeneratedColumn<bool>(
    'reversed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    readingId,
    positionId,
    positionOrder,
    cardId,
    reversed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingCardRow> instance, {
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
    if (data.containsKey('position_id')) {
      context.handle(
        _positionIdMeta,
        positionId.isAcceptableOrUnknown(data['position_id']!, _positionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_positionIdMeta);
    }
    if (data.containsKey('position_order')) {
      context.handle(
        _positionOrderMeta,
        positionOrder.isAcceptableOrUnknown(
          data['position_order']!,
          _positionOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionOrderMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('reversed')) {
      context.handle(
        _reversedMeta,
        reversed.isAcceptableOrUnknown(data['reversed']!, _reversedMeta),
      );
    } else if (isInserting) {
      context.missing(_reversedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {readingId, positionId};
  @override
  ReadingCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingCardRow(
      readingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_id'],
      )!,
      positionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position_id'],
      )!,
      positionOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_order'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      reversed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reversed'],
      )!,
    );
  }

  @override
  ReadingCards createAlias(String alias) {
    return ReadingCards(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(reading_id, position_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ReadingCardRow extends DataClass implements Insertable<ReadingCardRow> {
  final String readingId;
  final String positionId;
  final int positionOrder;
  final String cardId;
  final bool reversed;
  const ReadingCardRow({
    required this.readingId,
    required this.positionId,
    required this.positionOrder,
    required this.cardId,
    required this.reversed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reading_id'] = Variable<String>(readingId);
    map['position_id'] = Variable<String>(positionId);
    map['position_order'] = Variable<int>(positionOrder);
    map['card_id'] = Variable<String>(cardId);
    map['reversed'] = Variable<bool>(reversed);
    return map;
  }

  ReadingCardsCompanion toCompanion(bool nullToAbsent) {
    return ReadingCardsCompanion(
      readingId: Value(readingId),
      positionId: Value(positionId),
      positionOrder: Value(positionOrder),
      cardId: Value(cardId),
      reversed: Value(reversed),
    );
  }

  factory ReadingCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingCardRow(
      readingId: serializer.fromJson<String>(json['reading_id']),
      positionId: serializer.fromJson<String>(json['position_id']),
      positionOrder: serializer.fromJson<int>(json['position_order']),
      cardId: serializer.fromJson<String>(json['card_id']),
      reversed: serializer.fromJson<bool>(json['reversed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reading_id': serializer.toJson<String>(readingId),
      'position_id': serializer.toJson<String>(positionId),
      'position_order': serializer.toJson<int>(positionOrder),
      'card_id': serializer.toJson<String>(cardId),
      'reversed': serializer.toJson<bool>(reversed),
    };
  }

  ReadingCardRow copyWith({
    String? readingId,
    String? positionId,
    int? positionOrder,
    String? cardId,
    bool? reversed,
  }) => ReadingCardRow(
    readingId: readingId ?? this.readingId,
    positionId: positionId ?? this.positionId,
    positionOrder: positionOrder ?? this.positionOrder,
    cardId: cardId ?? this.cardId,
    reversed: reversed ?? this.reversed,
  );
  ReadingCardRow copyWithCompanion(ReadingCardsCompanion data) {
    return ReadingCardRow(
      readingId: data.readingId.present ? data.readingId.value : this.readingId,
      positionId: data.positionId.present
          ? data.positionId.value
          : this.positionId,
      positionOrder: data.positionOrder.present
          ? data.positionOrder.value
          : this.positionOrder,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      reversed: data.reversed.present ? data.reversed.value : this.reversed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingCardRow(')
          ..write('readingId: $readingId, ')
          ..write('positionId: $positionId, ')
          ..write('positionOrder: $positionOrder, ')
          ..write('cardId: $cardId, ')
          ..write('reversed: $reversed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(readingId, positionId, positionOrder, cardId, reversed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingCardRow &&
          other.readingId == this.readingId &&
          other.positionId == this.positionId &&
          other.positionOrder == this.positionOrder &&
          other.cardId == this.cardId &&
          other.reversed == this.reversed);
}

class ReadingCardsCompanion extends UpdateCompanion<ReadingCardRow> {
  final Value<String> readingId;
  final Value<String> positionId;
  final Value<int> positionOrder;
  final Value<String> cardId;
  final Value<bool> reversed;
  final Value<int> rowid;
  const ReadingCardsCompanion({
    this.readingId = const Value.absent(),
    this.positionId = const Value.absent(),
    this.positionOrder = const Value.absent(),
    this.cardId = const Value.absent(),
    this.reversed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingCardsCompanion.insert({
    required String readingId,
    required String positionId,
    required int positionOrder,
    required String cardId,
    required bool reversed,
    this.rowid = const Value.absent(),
  }) : readingId = Value(readingId),
       positionId = Value(positionId),
       positionOrder = Value(positionOrder),
       cardId = Value(cardId),
       reversed = Value(reversed);
  static Insertable<ReadingCardRow> custom({
    Expression<String>? readingId,
    Expression<String>? positionId,
    Expression<int>? positionOrder,
    Expression<String>? cardId,
    Expression<bool>? reversed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (readingId != null) 'reading_id': readingId,
      if (positionId != null) 'position_id': positionId,
      if (positionOrder != null) 'position_order': positionOrder,
      if (cardId != null) 'card_id': cardId,
      if (reversed != null) 'reversed': reversed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingCardsCompanion copyWith({
    Value<String>? readingId,
    Value<String>? positionId,
    Value<int>? positionOrder,
    Value<String>? cardId,
    Value<bool>? reversed,
    Value<int>? rowid,
  }) {
    return ReadingCardsCompanion(
      readingId: readingId ?? this.readingId,
      positionId: positionId ?? this.positionId,
      positionOrder: positionOrder ?? this.positionOrder,
      cardId: cardId ?? this.cardId,
      reversed: reversed ?? this.reversed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (readingId.present) {
      map['reading_id'] = Variable<String>(readingId.value);
    }
    if (positionId.present) {
      map['position_id'] = Variable<String>(positionId.value);
    }
    if (positionOrder.present) {
      map['position_order'] = Variable<int>(positionOrder.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (reversed.present) {
      map['reversed'] = Variable<bool>(reversed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingCardsCompanion(')
          ..write('readingId: $readingId, ')
          ..write('positionId: $positionId, ')
          ..write('positionOrder: $positionOrder, ')
          ..write('cardId: $cardId, ')
          ..write('reversed: $reversed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DailyCards extends Table with TableInfo<DailyCards, DailyCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DailyCards(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _reversedMeta = const VerificationMeta(
    'reversed',
  );
  late final GeneratedColumn<bool> reversed = GeneratedColumn<bool>(
    'reversed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> drawnAt =
      GeneratedColumn<int>(
        'drawn_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(DailyCards.$converterdrawnAt);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _favouriteMeta = const VerificationMeta(
    'favourite',
  );
  late final GeneratedColumn<bool> favourite = GeneratedColumn<bool>(
    'favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(DailyCards.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(DailyCards.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    localDate,
    cardId,
    reversed,
    drawnAt,
    note,
    favourite,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('reversed')) {
      context.handle(
        _reversedMeta,
        reversed.isAcceptableOrUnknown(data['reversed']!, _reversedMeta),
      );
    } else if (isInserting) {
      context.missing(_reversedMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('favourite')) {
      context.handle(
        _favouriteMeta,
        favourite.isAcceptableOrUnknown(data['favourite']!, _favouriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localDate};
  @override
  DailyCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCardRow(
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      reversed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reversed'],
      )!,
      drawnAt: DailyCards.$converterdrawnAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}drawn_at'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      favourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favourite'],
      )!,
      createdAt: DailyCards.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: DailyCards.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  DailyCards createAlias(String alias) {
    return DailyCards(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdrawnAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
  @override
  bool get dontWriteConstraints => true;
}

class DailyCardRow extends DataClass implements Insertable<DailyCardRow> {
  final String localDate;
  final String cardId;
  final bool reversed;
  final DateTime drawnAt;
  final String? note;
  final bool favourite;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyCardRow({
    required this.localDate,
    required this.cardId,
    required this.reversed,
    required this.drawnAt,
    this.note,
    required this.favourite,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_date'] = Variable<String>(localDate);
    map['card_id'] = Variable<String>(cardId);
    map['reversed'] = Variable<bool>(reversed);
    {
      map['drawn_at'] = Variable<int>(
        DailyCards.$converterdrawnAt.toSql(drawnAt),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['favourite'] = Variable<bool>(favourite);
    {
      map['created_at'] = Variable<int>(
        DailyCards.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        DailyCards.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  DailyCardsCompanion toCompanion(bool nullToAbsent) {
    return DailyCardsCompanion(
      localDate: Value(localDate),
      cardId: Value(cardId),
      reversed: Value(reversed),
      drawnAt: Value(drawnAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      favourite: Value(favourite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCardRow(
      localDate: serializer.fromJson<String>(json['local_date']),
      cardId: serializer.fromJson<String>(json['card_id']),
      reversed: serializer.fromJson<bool>(json['reversed']),
      drawnAt: serializer.fromJson<DateTime>(json['drawn_at']),
      note: serializer.fromJson<String?>(json['note']),
      favourite: serializer.fromJson<bool>(json['favourite']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'local_date': serializer.toJson<String>(localDate),
      'card_id': serializer.toJson<String>(cardId),
      'reversed': serializer.toJson<bool>(reversed),
      'drawn_at': serializer.toJson<DateTime>(drawnAt),
      'note': serializer.toJson<String?>(note),
      'favourite': serializer.toJson<bool>(favourite),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyCardRow copyWith({
    String? localDate,
    String? cardId,
    bool? reversed,
    DateTime? drawnAt,
    Value<String?> note = const Value.absent(),
    bool? favourite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DailyCardRow(
    localDate: localDate ?? this.localDate,
    cardId: cardId ?? this.cardId,
    reversed: reversed ?? this.reversed,
    drawnAt: drawnAt ?? this.drawnAt,
    note: note.present ? note.value : this.note,
    favourite: favourite ?? this.favourite,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyCardRow copyWithCompanion(DailyCardsCompanion data) {
    return DailyCardRow(
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      reversed: data.reversed.present ? data.reversed.value : this.reversed,
      drawnAt: data.drawnAt.present ? data.drawnAt.value : this.drawnAt,
      note: data.note.present ? data.note.value : this.note,
      favourite: data.favourite.present ? data.favourite.value : this.favourite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCardRow(')
          ..write('localDate: $localDate, ')
          ..write('cardId: $cardId, ')
          ..write('reversed: $reversed, ')
          ..write('drawnAt: $drawnAt, ')
          ..write('note: $note, ')
          ..write('favourite: $favourite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localDate,
    cardId,
    reversed,
    drawnAt,
    note,
    favourite,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCardRow &&
          other.localDate == this.localDate &&
          other.cardId == this.cardId &&
          other.reversed == this.reversed &&
          other.drawnAt == this.drawnAt &&
          other.note == this.note &&
          other.favourite == this.favourite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyCardsCompanion extends UpdateCompanion<DailyCardRow> {
  final Value<String> localDate;
  final Value<String> cardId;
  final Value<bool> reversed;
  final Value<DateTime> drawnAt;
  final Value<String?> note;
  final Value<bool> favourite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyCardsCompanion({
    this.localDate = const Value.absent(),
    this.cardId = const Value.absent(),
    this.reversed = const Value.absent(),
    this.drawnAt = const Value.absent(),
    this.note = const Value.absent(),
    this.favourite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyCardsCompanion.insert({
    required String localDate,
    required String cardId,
    required bool reversed,
    required DateTime drawnAt,
    this.note = const Value.absent(),
    this.favourite = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localDate = Value(localDate),
       cardId = Value(cardId),
       reversed = Value(reversed),
       drawnAt = Value(drawnAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DailyCardRow> custom({
    Expression<String>? localDate,
    Expression<String>? cardId,
    Expression<bool>? reversed,
    Expression<int>? drawnAt,
    Expression<String>? note,
    Expression<bool>? favourite,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localDate != null) 'local_date': localDate,
      if (cardId != null) 'card_id': cardId,
      if (reversed != null) 'reversed': reversed,
      if (drawnAt != null) 'drawn_at': drawnAt,
      if (note != null) 'note': note,
      if (favourite != null) 'favourite': favourite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyCardsCompanion copyWith({
    Value<String>? localDate,
    Value<String>? cardId,
    Value<bool>? reversed,
    Value<DateTime>? drawnAt,
    Value<String?>? note,
    Value<bool>? favourite,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DailyCardsCompanion(
      localDate: localDate ?? this.localDate,
      cardId: cardId ?? this.cardId,
      reversed: reversed ?? this.reversed,
      drawnAt: drawnAt ?? this.drawnAt,
      note: note ?? this.note,
      favourite: favourite ?? this.favourite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (reversed.present) {
      map['reversed'] = Variable<bool>(reversed.value);
    }
    if (drawnAt.present) {
      map['drawn_at'] = Variable<int>(
        DailyCards.$converterdrawnAt.toSql(drawnAt.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (favourite.present) {
      map['favourite'] = Variable<bool>(favourite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        DailyCards.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        DailyCards.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyCardsCompanion(')
          ..write('localDate: $localDate, ')
          ..write('cardId: $cardId, ')
          ..write('reversed: $reversed, ')
          ..write('drawnAt: $drawnAt, ')
          ..write('note: $note, ')
          ..write('favourite: $favourite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Settings extends Table with TableInfo<Settings, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  Settings createAlias(String alias) {
    return Settings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String valueJson;
  const SettingRow({required this.key, required this.valueJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), valueJson: Value(valueJson));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['value_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value_json': serializer.toJson<String>(valueJson),
    };
  }

  SettingRow copyWith({String? key, String? valueJson}) =>
      SettingRow(key: key ?? this.key, valueJson: valueJson ?? this.valueJson);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class JournalSearchRefs extends Table
    with TableInfo<JournalSearchRefs, JournalSearchRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  JournalSearchRefs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ftsRowidMeta = const VerificationMeta(
    'ftsRowid',
  );
  late final GeneratedColumn<int> ftsRowid = GeneratedColumn<int>(
    'fts_rowid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'reading\', \'daily\'))',
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [ftsRowid, kind, ref];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_search_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalSearchRef> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fts_rowid')) {
      context.handle(
        _ftsRowidMeta,
        ftsRowid.isAcceptableOrUnknown(data['fts_rowid']!, _ftsRowidMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref')) {
      context.handle(
        _refMeta,
        ref.isAcceptableOrUnknown(data['ref']!, _refMeta),
      );
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ftsRowid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {kind, ref},
  ];
  @override
  JournalSearchRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalSearchRef(
      ftsRowid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fts_rowid'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      )!,
    );
  }

  @override
  JournalSearchRefs createAlias(String alias) {
    return JournalSearchRefs(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(kind, ref)'];
  @override
  bool get dontWriteConstraints => true;
}

class JournalSearchRef extends DataClass
    implements Insertable<JournalSearchRef> {
  final int ftsRowid;
  final String kind;
  final String ref;
  const JournalSearchRef({
    required this.ftsRowid,
    required this.kind,
    required this.ref,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fts_rowid'] = Variable<int>(ftsRowid);
    map['kind'] = Variable<String>(kind);
    map['ref'] = Variable<String>(ref);
    return map;
  }

  JournalSearchRefsCompanion toCompanion(bool nullToAbsent) {
    return JournalSearchRefsCompanion(
      ftsRowid: Value(ftsRowid),
      kind: Value(kind),
      ref: Value(ref),
    );
  }

  factory JournalSearchRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalSearchRef(
      ftsRowid: serializer.fromJson<int>(json['fts_rowid']),
      kind: serializer.fromJson<String>(json['kind']),
      ref: serializer.fromJson<String>(json['ref']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fts_rowid': serializer.toJson<int>(ftsRowid),
      'kind': serializer.toJson<String>(kind),
      'ref': serializer.toJson<String>(ref),
    };
  }

  JournalSearchRef copyWith({int? ftsRowid, String? kind, String? ref}) =>
      JournalSearchRef(
        ftsRowid: ftsRowid ?? this.ftsRowid,
        kind: kind ?? this.kind,
        ref: ref ?? this.ref,
      );
  JournalSearchRef copyWithCompanion(JournalSearchRefsCompanion data) {
    return JournalSearchRef(
      ftsRowid: data.ftsRowid.present ? data.ftsRowid.value : this.ftsRowid,
      kind: data.kind.present ? data.kind.value : this.kind,
      ref: data.ref.present ? data.ref.value : this.ref,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalSearchRef(')
          ..write('ftsRowid: $ftsRowid, ')
          ..write('kind: $kind, ')
          ..write('ref: $ref')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ftsRowid, kind, ref);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalSearchRef &&
          other.ftsRowid == this.ftsRowid &&
          other.kind == this.kind &&
          other.ref == this.ref);
}

class JournalSearchRefsCompanion extends UpdateCompanion<JournalSearchRef> {
  final Value<int> ftsRowid;
  final Value<String> kind;
  final Value<String> ref;
  const JournalSearchRefsCompanion({
    this.ftsRowid = const Value.absent(),
    this.kind = const Value.absent(),
    this.ref = const Value.absent(),
  });
  JournalSearchRefsCompanion.insert({
    this.ftsRowid = const Value.absent(),
    required String kind,
    required String ref,
  }) : kind = Value(kind),
       ref = Value(ref);
  static Insertable<JournalSearchRef> custom({
    Expression<int>? ftsRowid,
    Expression<String>? kind,
    Expression<String>? ref,
  }) {
    return RawValuesInsertable({
      if (ftsRowid != null) 'fts_rowid': ftsRowid,
      if (kind != null) 'kind': kind,
      if (ref != null) 'ref': ref,
    });
  }

  JournalSearchRefsCompanion copyWith({
    Value<int>? ftsRowid,
    Value<String>? kind,
    Value<String>? ref,
  }) {
    return JournalSearchRefsCompanion(
      ftsRowid: ftsRowid ?? this.ftsRowid,
      kind: kind ?? this.kind,
      ref: ref ?? this.ref,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ftsRowid.present) {
      map['fts_rowid'] = Variable<int>(ftsRowid.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalSearchRefsCompanion(')
          ..write('ftsRowid: $ftsRowid, ')
          ..write('kind: $kind, ')
          ..write('ref: $ref')
          ..write(')'))
        .toString();
  }
}

class JournalFts extends Table
    with
        TableInfo<JournalFts, JournalFt>,
        VirtualTableInfo<JournalFts, JournalFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  JournalFts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [question, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_fts';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalFt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  JournalFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalFt(
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  JournalFts createAlias(String alias) {
    return JournalFts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(question, note, tokenize = \'trigram case_sensitive 0 remove_diacritics 1\')';
}

class JournalFt extends DataClass implements Insertable<JournalFt> {
  final String question;
  final String note;
  const JournalFt({required this.question, required this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question'] = Variable<String>(question);
    map['note'] = Variable<String>(note);
    return map;
  }

  JournalFtsCompanion toCompanion(bool nullToAbsent) {
    return JournalFtsCompanion(question: Value(question), note: Value(note));
  }

  factory JournalFt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalFt(
      question: serializer.fromJson<String>(json['question']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'question': serializer.toJson<String>(question),
      'note': serializer.toJson<String>(note),
    };
  }

  JournalFt copyWith({String? question, String? note}) =>
      JournalFt(question: question ?? this.question, note: note ?? this.note);
  JournalFt copyWithCompanion(JournalFtsCompanion data) {
    return JournalFt(
      question: data.question.present ? data.question.value : this.question,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalFt(')
          ..write('question: $question, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(question, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalFt &&
          other.question == this.question &&
          other.note == this.note);
}

class JournalFtsCompanion extends UpdateCompanion<JournalFt> {
  final Value<String> question;
  final Value<String> note;
  final Value<int> rowid;
  const JournalFtsCompanion({
    this.question = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalFtsCompanion.insert({
    required String question,
    required String note,
    this.rowid = const Value.absent(),
  }) : question = Value(question),
       note = Value(note);
  static Insertable<JournalFt> custom({
    Expression<String>? question,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (question != null) 'question': question,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalFtsCompanion copyWith({
    Value<String>? question,
    Value<String>? note,
    Value<int>? rowid,
  }) {
    return JournalFtsCompanion(
      question: question ?? this.question,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalFtsCompanion(')
          ..write('question: $question, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$JournalDatabase extends GeneratedDatabase {
  _$JournalDatabase(QueryExecutor e) : super(e);
  $JournalDatabaseManager get managers => $JournalDatabaseManager(this);
  late final Readings readings = Readings(this);
  late final ReadingCards readingCards = ReadingCards(this);
  late final DailyCards dailyCards = DailyCards(this);
  late final Settings settings = Settings(this);
  late final Index readingsCreatedAt = Index(
    'readings_created_at',
    'CREATE INDEX readings_created_at ON readings (created_at DESC)',
  );
  late final Index readingsFavouriteCreatedAt = Index(
    'readings_favourite_created_at',
    'CREATE INDEX readings_favourite_created_at ON readings (favourite, created_at)',
  );
  late final Index readingCardsCardId = Index(
    'reading_cards_card_id',
    'CREATE INDEX reading_cards_card_id ON reading_cards (card_id)',
  );
  late final JournalSearchRefs journalSearchRefs = JournalSearchRefs(this);
  late final JournalFts journalFts = JournalFts(this);
  late final Trigger readingsFtsInsert = Trigger(
    'CREATE TRIGGER readings_fts_insert AFTER INSERT ON readings BEGIN INSERT INTO journal_search_refs (kind, ref) VALUES (\'reading\', new.id);INSERT INTO journal_fts ("rowid", question, note) VALUES ((SELECT fts_rowid FROM journal_search_refs WHERE kind = \'reading\' AND ref = new.id), new.question, new.note);END',
    'readings_fts_insert',
  );
  late final Trigger readingsFtsUpdate = Trigger(
    'CREATE TRIGGER readings_fts_update AFTER UPDATE OF question, note ON readings BEGIN UPDATE journal_fts SET question = new.question, note = new.note WHERE "rowid" = (SELECT fts_rowid FROM journal_search_refs WHERE kind = \'reading\' AND ref = old.id);END',
    'readings_fts_update',
  );
  late final Trigger readingsFtsDelete = Trigger(
    'CREATE TRIGGER readings_fts_delete AFTER DELETE ON readings BEGIN DELETE FROM journal_fts WHERE "rowid" = (SELECT fts_rowid FROM journal_search_refs WHERE kind = \'reading\' AND ref = old.id);DELETE FROM journal_search_refs WHERE kind = \'reading\' AND ref = old.id;END',
    'readings_fts_delete',
  );
  late final Trigger dailyCardsFtsInsert = Trigger(
    'CREATE TRIGGER daily_cards_fts_insert AFTER INSERT ON daily_cards BEGIN INSERT INTO journal_search_refs (kind, ref) VALUES (\'daily\', new.local_date);INSERT INTO journal_fts ("rowid", question, note) VALUES ((SELECT fts_rowid FROM journal_search_refs WHERE kind = \'daily\' AND ref = new.local_date), NULL, new.note);END',
    'daily_cards_fts_insert',
  );
  late final Trigger dailyCardsFtsUpdate = Trigger(
    'CREATE TRIGGER daily_cards_fts_update AFTER UPDATE OF note ON daily_cards BEGIN UPDATE journal_fts SET note = new.note WHERE "rowid" = (SELECT fts_rowid FROM journal_search_refs WHERE kind = \'daily\' AND ref = old.local_date);END',
    'daily_cards_fts_update',
  );
  late final Trigger dailyCardsFtsDelete = Trigger(
    'CREATE TRIGGER daily_cards_fts_delete AFTER DELETE ON daily_cards BEGIN DELETE FROM journal_fts WHERE "rowid" = (SELECT fts_rowid FROM journal_search_refs WHERE kind = \'daily\' AND ref = old.local_date);DELETE FROM journal_search_refs WHERE kind = \'daily\' AND ref = old.local_date;END',
    'daily_cards_fts_delete',
  );
  late final ReadingsDao readingsDao = ReadingsDao(this as JournalDatabase);
  late final DailyCardsDao dailyCardsDao = DailyCardsDao(
    this as JournalDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as JournalDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    readings,
    readingCards,
    dailyCards,
    settings,
    readingsCreatedAt,
    readingsFavouriteCreatedAt,
    readingCardsCardId,
    journalSearchRefs,
    journalFts,
    readingsFtsInsert,
    readingsFtsUpdate,
    readingsFtsDelete,
    dailyCardsFtsInsert,
    dailyCardsFtsUpdate,
    dailyCardsFtsDelete,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'readings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'readings',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('journal_search_refs', kind: UpdateKind.insert),
        TableUpdate('journal_fts', kind: UpdateKind.insert),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'readings',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('journal_fts', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'readings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('journal_fts', kind: UpdateKind.delete),
        TableUpdate('journal_search_refs', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'daily_cards',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('journal_search_refs', kind: UpdateKind.insert),
        TableUpdate('journal_fts', kind: UpdateKind.insert),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'daily_cards',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('journal_fts', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'daily_cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('journal_fts', kind: UpdateKind.delete),
        TableUpdate('journal_search_refs', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $ReadingsCreateCompanionBuilder =
    ReadingsCompanion Function({
      required String id,
      required String spreadId,
      required int spreadVersion,
      required String localDate,
      Value<String?> question,
      required String status,
      Value<String?> contentJson,
      Value<String?> safetyJson,
      Value<String?> failureJson,
      required String contentLocale,
      Value<String?> promptVersion,
      Value<String?> modelId,
      Value<String?> chargeSource,
      Value<String?> note,
      Value<bool> favourite,
      Value<String?> rating,
      Value<String?> ratingReason,
      Value<bool> deliveryAcked,
      Value<bool> reported,
      required DateTime drawnAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $ReadingsUpdateCompanionBuilder =
    ReadingsCompanion Function({
      Value<String> id,
      Value<String> spreadId,
      Value<int> spreadVersion,
      Value<String> localDate,
      Value<String?> question,
      Value<String> status,
      Value<String?> contentJson,
      Value<String?> safetyJson,
      Value<String?> failureJson,
      Value<String> contentLocale,
      Value<String?> promptVersion,
      Value<String?> modelId,
      Value<String?> chargeSource,
      Value<String?> note,
      Value<bool> favourite,
      Value<String?> rating,
      Value<String?> ratingReason,
      Value<bool> deliveryAcked,
      Value<bool> reported,
      Value<DateTime> drawnAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $ReadingsReferences
    extends BaseReferences<_$JournalDatabase, Readings, ReadingRow> {
  $ReadingsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<ReadingCards, List<ReadingCardRow>>
  _readingCardsRefsTable(_$JournalDatabase db) => MultiTypedResultKey.fromTable(
    db.readingCards,
    aliasName: 'readings__id__reading_cards__reading_id',
  );

  $ReadingCardsProcessedTableManager get readingCardsRefs {
    final manager = $ReadingCardsTableManager(
      $_db,
      $_db.readingCards,
    ).filter((f) => f.readingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ReadingsFilterComposer extends Composer<_$JournalDatabase, Readings> {
  $ReadingsFilterComposer({
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

  ColumnFilters<String> get spreadId => $composableBuilder(
    column: $table.spreadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spreadVersion => $composableBuilder(
    column: $table.spreadVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safetyJson => $composableBuilder(
    column: $table.safetyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureJson => $composableBuilder(
    column: $table.failureJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentLocale => $composableBuilder(
    column: $table.contentLocale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chargeSource => $composableBuilder(
    column: $table.chargeSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratingReason => $composableBuilder(
    column: $table.ratingReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deliveryAcked => $composableBuilder(
    column: $table.deliveryAcked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reported => $composableBuilder(
    column: $table.reported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get drawnAt =>
      $composableBuilder(
        column: $table.drawnAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
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

  Expression<bool> readingCardsRefs(
    Expression<bool> Function($ReadingCardsFilterComposer f) f,
  ) {
    final $ReadingCardsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingCards,
      getReferencedColumn: (t) => t.readingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReadingCardsFilterComposer(
            $db: $db,
            $table: $db.readingCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ReadingsOrderingComposer extends Composer<_$JournalDatabase, Readings> {
  $ReadingsOrderingComposer({
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

  ColumnOrderings<String> get spreadId => $composableBuilder(
    column: $table.spreadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spreadVersion => $composableBuilder(
    column: $table.spreadVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safetyJson => $composableBuilder(
    column: $table.safetyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureJson => $composableBuilder(
    column: $table.failureJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentLocale => $composableBuilder(
    column: $table.contentLocale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chargeSource => $composableBuilder(
    column: $table.chargeSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratingReason => $composableBuilder(
    column: $table.ratingReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deliveryAcked => $composableBuilder(
    column: $table.deliveryAcked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reported => $composableBuilder(
    column: $table.reported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get drawnAt => $composableBuilder(
    column: $table.drawnAt,
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

class $ReadingsAnnotationComposer
    extends Composer<_$JournalDatabase, Readings> {
  $ReadingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get spreadId =>
      $composableBuilder(column: $table.spreadId, builder: (column) => column);

  GeneratedColumn<int> get spreadVersion => $composableBuilder(
    column: $table.spreadVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get safetyJson => $composableBuilder(
    column: $table.safetyJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureJson => $composableBuilder(
    column: $table.failureJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentLocale => $composableBuilder(
    column: $table.contentLocale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get chargeSource => $composableBuilder(
    column: $table.chargeSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get favourite =>
      $composableBuilder(column: $table.favourite, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get ratingReason => $composableBuilder(
    column: $table.ratingReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deliveryAcked => $composableBuilder(
    column: $table.deliveryAcked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reported =>
      $composableBuilder(column: $table.reported, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get drawnAt =>
      $composableBuilder(column: $table.drawnAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> readingCardsRefs<T extends Object>(
    Expression<T> Function($ReadingCardsAnnotationComposer a) f,
  ) {
    final $ReadingCardsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingCards,
      getReferencedColumn: (t) => t.readingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReadingCardsAnnotationComposer(
            $db: $db,
            $table: $db.readingCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ReadingsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          Readings,
          ReadingRow,
          $ReadingsFilterComposer,
          $ReadingsOrderingComposer,
          $ReadingsAnnotationComposer,
          $ReadingsCreateCompanionBuilder,
          $ReadingsUpdateCompanionBuilder,
          (ReadingRow, $ReadingsReferences),
          ReadingRow,
          PrefetchHooks Function({bool readingCardsRefs})
        > {
  $ReadingsTableManager(_$JournalDatabase db, Readings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ReadingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ReadingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ReadingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> spreadId = const Value.absent(),
                Value<int> spreadVersion = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String?> question = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<String?> safetyJson = const Value.absent(),
                Value<String?> failureJson = const Value.absent(),
                Value<String> contentLocale = const Value.absent(),
                Value<String?> promptVersion = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> chargeSource = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> ratingReason = const Value.absent(),
                Value<bool> deliveryAcked = const Value.absent(),
                Value<bool> reported = const Value.absent(),
                Value<DateTime> drawnAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingsCompanion(
                id: id,
                spreadId: spreadId,
                spreadVersion: spreadVersion,
                localDate: localDate,
                question: question,
                status: status,
                contentJson: contentJson,
                safetyJson: safetyJson,
                failureJson: failureJson,
                contentLocale: contentLocale,
                promptVersion: promptVersion,
                modelId: modelId,
                chargeSource: chargeSource,
                note: note,
                favourite: favourite,
                rating: rating,
                ratingReason: ratingReason,
                deliveryAcked: deliveryAcked,
                reported: reported,
                drawnAt: drawnAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String spreadId,
                required int spreadVersion,
                required String localDate,
                Value<String?> question = const Value.absent(),
                required String status,
                Value<String?> contentJson = const Value.absent(),
                Value<String?> safetyJson = const Value.absent(),
                Value<String?> failureJson = const Value.absent(),
                required String contentLocale,
                Value<String?> promptVersion = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> chargeSource = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> ratingReason = const Value.absent(),
                Value<bool> deliveryAcked = const Value.absent(),
                Value<bool> reported = const Value.absent(),
                required DateTime drawnAt,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingsCompanion.insert(
                id: id,
                spreadId: spreadId,
                spreadVersion: spreadVersion,
                localDate: localDate,
                question: question,
                status: status,
                contentJson: contentJson,
                safetyJson: safetyJson,
                failureJson: failureJson,
                contentLocale: contentLocale,
                promptVersion: promptVersion,
                modelId: modelId,
                chargeSource: chargeSource,
                note: note,
                favourite: favourite,
                rating: rating,
                ratingReason: ratingReason,
                deliveryAcked: deliveryAcked,
                reported: reported,
                drawnAt: drawnAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $ReadingsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({readingCardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (readingCardsRefs) db.readingCards],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (readingCardsRefs)
                    await $_getPrefetchedData<
                      ReadingRow,
                      Readings,
                      ReadingCardRow
                    >(
                      currentTable: table,
                      referencedTable: $ReadingsReferences
                          ._readingCardsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $ReadingsReferences(db, table, p0).readingCardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.readingId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $ReadingsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      Readings,
      ReadingRow,
      $ReadingsFilterComposer,
      $ReadingsOrderingComposer,
      $ReadingsAnnotationComposer,
      $ReadingsCreateCompanionBuilder,
      $ReadingsUpdateCompanionBuilder,
      (ReadingRow, $ReadingsReferences),
      ReadingRow,
      PrefetchHooks Function({bool readingCardsRefs})
    >;
typedef $ReadingCardsCreateCompanionBuilder =
    ReadingCardsCompanion Function({
      required String readingId,
      required String positionId,
      required int positionOrder,
      required String cardId,
      required bool reversed,
      Value<int> rowid,
    });
typedef $ReadingCardsUpdateCompanionBuilder =
    ReadingCardsCompanion Function({
      Value<String> readingId,
      Value<String> positionId,
      Value<int> positionOrder,
      Value<String> cardId,
      Value<bool> reversed,
      Value<int> rowid,
    });

final class $ReadingCardsReferences
    extends BaseReferences<_$JournalDatabase, ReadingCards, ReadingCardRow> {
  $ReadingCardsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Readings _readingIdTable(_$JournalDatabase db) =>
      db.readings.createAlias('reading_cards__reading_id__readings__id');

  $ReadingsProcessedTableManager get readingId {
    final $_column = $_itemColumn<String>('reading_id')!;

    final manager = $ReadingsTableManager(
      $_db,
      $_db.readings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_readingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ReadingCardsFilterComposer
    extends Composer<_$JournalDatabase, ReadingCards> {
  $ReadingCardsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get positionId => $composableBuilder(
    column: $table.positionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionOrder => $composableBuilder(
    column: $table.positionOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reversed => $composableBuilder(
    column: $table.reversed,
    builder: (column) => ColumnFilters(column),
  );

  $ReadingsFilterComposer get readingId {
    final $ReadingsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readingId,
      referencedTable: $db.readings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReadingsFilterComposer(
            $db: $db,
            $table: $db.readings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReadingCardsOrderingComposer
    extends Composer<_$JournalDatabase, ReadingCards> {
  $ReadingCardsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get positionId => $composableBuilder(
    column: $table.positionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionOrder => $composableBuilder(
    column: $table.positionOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reversed => $composableBuilder(
    column: $table.reversed,
    builder: (column) => ColumnOrderings(column),
  );

  $ReadingsOrderingComposer get readingId {
    final $ReadingsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readingId,
      referencedTable: $db.readings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReadingsOrderingComposer(
            $db: $db,
            $table: $db.readings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReadingCardsAnnotationComposer
    extends Composer<_$JournalDatabase, ReadingCards> {
  $ReadingCardsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get positionId => $composableBuilder(
    column: $table.positionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionOrder => $composableBuilder(
    column: $table.positionOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<bool> get reversed =>
      $composableBuilder(column: $table.reversed, builder: (column) => column);

  $ReadingsAnnotationComposer get readingId {
    final $ReadingsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readingId,
      referencedTable: $db.readings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReadingsAnnotationComposer(
            $db: $db,
            $table: $db.readings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReadingCardsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          ReadingCards,
          ReadingCardRow,
          $ReadingCardsFilterComposer,
          $ReadingCardsOrderingComposer,
          $ReadingCardsAnnotationComposer,
          $ReadingCardsCreateCompanionBuilder,
          $ReadingCardsUpdateCompanionBuilder,
          (ReadingCardRow, $ReadingCardsReferences),
          ReadingCardRow,
          PrefetchHooks Function({bool readingId})
        > {
  $ReadingCardsTableManager(_$JournalDatabase db, ReadingCards table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ReadingCardsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ReadingCardsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ReadingCardsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> readingId = const Value.absent(),
                Value<String> positionId = const Value.absent(),
                Value<int> positionOrder = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<bool> reversed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingCardsCompanion(
                readingId: readingId,
                positionId: positionId,
                positionOrder: positionOrder,
                cardId: cardId,
                reversed: reversed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String readingId,
                required String positionId,
                required int positionOrder,
                required String cardId,
                required bool reversed,
                Value<int> rowid = const Value.absent(),
              }) => ReadingCardsCompanion.insert(
                readingId: readingId,
                positionId: positionId,
                positionOrder: positionOrder,
                cardId: cardId,
                reversed: reversed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $ReadingCardsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({readingId = false}) {
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
                    if (readingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.readingId,
                                referencedTable: $ReadingCardsReferences
                                    ._readingIdTable(db),
                                referencedColumn: $ReadingCardsReferences
                                    ._readingIdTable(db)
                                    .id,
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

typedef $ReadingCardsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      ReadingCards,
      ReadingCardRow,
      $ReadingCardsFilterComposer,
      $ReadingCardsOrderingComposer,
      $ReadingCardsAnnotationComposer,
      $ReadingCardsCreateCompanionBuilder,
      $ReadingCardsUpdateCompanionBuilder,
      (ReadingCardRow, $ReadingCardsReferences),
      ReadingCardRow,
      PrefetchHooks Function({bool readingId})
    >;
typedef $DailyCardsCreateCompanionBuilder =
    DailyCardsCompanion Function({
      required String localDate,
      required String cardId,
      required bool reversed,
      required DateTime drawnAt,
      Value<String?> note,
      Value<bool> favourite,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $DailyCardsUpdateCompanionBuilder =
    DailyCardsCompanion Function({
      Value<String> localDate,
      Value<String> cardId,
      Value<bool> reversed,
      Value<DateTime> drawnAt,
      Value<String?> note,
      Value<bool> favourite,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $DailyCardsFilterComposer
    extends Composer<_$JournalDatabase, DailyCards> {
  $DailyCardsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reversed => $composableBuilder(
    column: $table.reversed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get drawnAt =>
      $composableBuilder(
        column: $table.drawnAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favourite => $composableBuilder(
    column: $table.favourite,
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

class $DailyCardsOrderingComposer
    extends Composer<_$JournalDatabase, DailyCards> {
  $DailyCardsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reversed => $composableBuilder(
    column: $table.reversed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get drawnAt => $composableBuilder(
    column: $table.drawnAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favourite => $composableBuilder(
    column: $table.favourite,
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

class $DailyCardsAnnotationComposer
    extends Composer<_$JournalDatabase, DailyCards> {
  $DailyCardsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<bool> get reversed =>
      $composableBuilder(column: $table.reversed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get drawnAt =>
      $composableBuilder(column: $table.drawnAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get favourite =>
      $composableBuilder(column: $table.favourite, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $DailyCardsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          DailyCards,
          DailyCardRow,
          $DailyCardsFilterComposer,
          $DailyCardsOrderingComposer,
          $DailyCardsAnnotationComposer,
          $DailyCardsCreateCompanionBuilder,
          $DailyCardsUpdateCompanionBuilder,
          (
            DailyCardRow,
            BaseReferences<_$JournalDatabase, DailyCards, DailyCardRow>,
          ),
          DailyCardRow,
          PrefetchHooks Function()
        > {
  $DailyCardsTableManager(_$JournalDatabase db, DailyCards table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DailyCardsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DailyCardsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DailyCardsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localDate = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<bool> reversed = const Value.absent(),
                Value<DateTime> drawnAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyCardsCompanion(
                localDate: localDate,
                cardId: cardId,
                reversed: reversed,
                drawnAt: drawnAt,
                note: note,
                favourite: favourite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localDate,
                required String cardId,
                required bool reversed,
                required DateTime drawnAt,
                Value<String?> note = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyCardsCompanion.insert(
                localDate: localDate,
                cardId: cardId,
                reversed: reversed,
                drawnAt: drawnAt,
                note: note,
                favourite: favourite,
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

typedef $DailyCardsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      DailyCards,
      DailyCardRow,
      $DailyCardsFilterComposer,
      $DailyCardsOrderingComposer,
      $DailyCardsAnnotationComposer,
      $DailyCardsCreateCompanionBuilder,
      $DailyCardsUpdateCompanionBuilder,
      (
        DailyCardRow,
        BaseReferences<_$JournalDatabase, DailyCards, DailyCardRow>,
      ),
      DailyCardRow,
      PrefetchHooks Function()
    >;
typedef $SettingsCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String valueJson,
      Value<int> rowid,
    });
typedef $SettingsUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> rowid,
    });

class $SettingsFilterComposer extends Composer<_$JournalDatabase, Settings> {
  $SettingsFilterComposer({
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

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $SettingsOrderingComposer extends Composer<_$JournalDatabase, Settings> {
  $SettingsOrderingComposer({
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

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SettingsAnnotationComposer
    extends Composer<_$JournalDatabase, Settings> {
  $SettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);
}

class $SettingsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          Settings,
          SettingRow,
          $SettingsFilterComposer,
          $SettingsOrderingComposer,
          $SettingsAnnotationComposer,
          $SettingsCreateCompanionBuilder,
          $SettingsUpdateCompanionBuilder,
          (SettingRow, BaseReferences<_$JournalDatabase, Settings, SettingRow>),
          SettingRow,
          PrefetchHooks Function()
        > {
  $SettingsTableManager(_$JournalDatabase db, Settings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SettingsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      Settings,
      SettingRow,
      $SettingsFilterComposer,
      $SettingsOrderingComposer,
      $SettingsAnnotationComposer,
      $SettingsCreateCompanionBuilder,
      $SettingsUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$JournalDatabase, Settings, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $JournalSearchRefsCreateCompanionBuilder =
    JournalSearchRefsCompanion Function({
      Value<int> ftsRowid,
      required String kind,
      required String ref,
    });
typedef $JournalSearchRefsUpdateCompanionBuilder =
    JournalSearchRefsCompanion Function({
      Value<int> ftsRowid,
      Value<String> kind,
      Value<String> ref,
    });

class $JournalSearchRefsFilterComposer
    extends Composer<_$JournalDatabase, JournalSearchRefs> {
  $JournalSearchRefsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ftsRowid => $composableBuilder(
    column: $table.ftsRowid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnFilters(column),
  );
}

class $JournalSearchRefsOrderingComposer
    extends Composer<_$JournalDatabase, JournalSearchRefs> {
  $JournalSearchRefsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ftsRowid => $composableBuilder(
    column: $table.ftsRowid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnOrderings(column),
  );
}

class $JournalSearchRefsAnnotationComposer
    extends Composer<_$JournalDatabase, JournalSearchRefs> {
  $JournalSearchRefsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ftsRowid =>
      $composableBuilder(column: $table.ftsRowid, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);
}

class $JournalSearchRefsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          JournalSearchRefs,
          JournalSearchRef,
          $JournalSearchRefsFilterComposer,
          $JournalSearchRefsOrderingComposer,
          $JournalSearchRefsAnnotationComposer,
          $JournalSearchRefsCreateCompanionBuilder,
          $JournalSearchRefsUpdateCompanionBuilder,
          (
            JournalSearchRef,
            BaseReferences<
              _$JournalDatabase,
              JournalSearchRefs,
              JournalSearchRef
            >,
          ),
          JournalSearchRef,
          PrefetchHooks Function()
        > {
  $JournalSearchRefsTableManager(_$JournalDatabase db, JournalSearchRefs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $JournalSearchRefsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $JournalSearchRefsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $JournalSearchRefsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ftsRowid = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> ref = const Value.absent(),
              }) => JournalSearchRefsCompanion(
                ftsRowid: ftsRowid,
                kind: kind,
                ref: ref,
              ),
          createCompanionCallback:
              ({
                Value<int> ftsRowid = const Value.absent(),
                required String kind,
                required String ref,
              }) => JournalSearchRefsCompanion.insert(
                ftsRowid: ftsRowid,
                kind: kind,
                ref: ref,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $JournalSearchRefsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      JournalSearchRefs,
      JournalSearchRef,
      $JournalSearchRefsFilterComposer,
      $JournalSearchRefsOrderingComposer,
      $JournalSearchRefsAnnotationComposer,
      $JournalSearchRefsCreateCompanionBuilder,
      $JournalSearchRefsUpdateCompanionBuilder,
      (
        JournalSearchRef,
        BaseReferences<_$JournalDatabase, JournalSearchRefs, JournalSearchRef>,
      ),
      JournalSearchRef,
      PrefetchHooks Function()
    >;
typedef $JournalFtsCreateCompanionBuilder =
    JournalFtsCompanion Function({
      required String question,
      required String note,
      Value<int> rowid,
    });
typedef $JournalFtsUpdateCompanionBuilder =
    JournalFtsCompanion Function({
      Value<String> question,
      Value<String> note,
      Value<int> rowid,
    });

class $JournalFtsFilterComposer
    extends Composer<_$JournalDatabase, JournalFts> {
  $JournalFtsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $JournalFtsOrderingComposer
    extends Composer<_$JournalDatabase, JournalFts> {
  $JournalFtsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $JournalFtsAnnotationComposer
    extends Composer<_$JournalDatabase, JournalFts> {
  $JournalFtsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $JournalFtsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          JournalFts,
          JournalFt,
          $JournalFtsFilterComposer,
          $JournalFtsOrderingComposer,
          $JournalFtsAnnotationComposer,
          $JournalFtsCreateCompanionBuilder,
          $JournalFtsUpdateCompanionBuilder,
          (JournalFt, BaseReferences<_$JournalDatabase, JournalFts, JournalFt>),
          JournalFt,
          PrefetchHooks Function()
        > {
  $JournalFtsTableManager(_$JournalDatabase db, JournalFts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $JournalFtsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $JournalFtsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $JournalFtsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> question = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalFtsCompanion(
                question: question,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String question,
                required String note,
                Value<int> rowid = const Value.absent(),
              }) => JournalFtsCompanion.insert(
                question: question,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $JournalFtsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      JournalFts,
      JournalFt,
      $JournalFtsFilterComposer,
      $JournalFtsOrderingComposer,
      $JournalFtsAnnotationComposer,
      $JournalFtsCreateCompanionBuilder,
      $JournalFtsUpdateCompanionBuilder,
      (JournalFt, BaseReferences<_$JournalDatabase, JournalFts, JournalFt>),
      JournalFt,
      PrefetchHooks Function()
    >;

class $JournalDatabaseManager {
  final _$JournalDatabase _db;
  $JournalDatabaseManager(this._db);
  $ReadingsTableManager get readings =>
      $ReadingsTableManager(_db, _db.readings);
  $ReadingCardsTableManager get readingCards =>
      $ReadingCardsTableManager(_db, _db.readingCards);
  $DailyCardsTableManager get dailyCards =>
      $DailyCardsTableManager(_db, _db.dailyCards);
  $SettingsTableManager get settings =>
      $SettingsTableManager(_db, _db.settings);
  $JournalSearchRefsTableManager get journalSearchRefs =>
      $JournalSearchRefsTableManager(_db, _db.journalSearchRefs);
  $JournalFtsTableManager get journalFts =>
      $JournalFtsTableManager(_db, _db.journalFts);
}
