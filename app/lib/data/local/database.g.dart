// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
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
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
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
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
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
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<OutboxState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OutboxState>($OutboxEntriesTable.$converterstate);
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    entityId,
    op,
    payload,
    clientUpdatedAt,
    attempts,
    nextAttemptAt,
    state,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      state: $OutboxEntriesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutboxState, String, String> $converterstate =
      const EnumNameConverter<OutboxState>(OutboxState.values);
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  /// Also the server-side idempotency key (client_mutation_id).
  final String id;
  final String entity;
  final String entityId;
  final String op;
  final String payload;
  final DateTime clientUpdatedAt;
  final int attempts;
  final DateTime nextAttemptAt;
  final OutboxState state;
  final String? lastError;
  const OutboxEntry({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.clientUpdatedAt,
    required this.attempts,
    required this.nextAttemptAt,
    required this.state,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    {
      map['state'] = Variable<String>(
        $OutboxEntriesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      entity: Value(entity),
      entityId: Value(entityId),
      op: Value(op),
      payload: Value(payload),
      clientUpdatedAt: Value(clientUpdatedAt),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      state: Value(state),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<String>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      state: $OutboxEntriesTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'state': serializer.toJson<String>(
        $OutboxEntriesTable.$converterstate.toJson(state),
      ),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxEntry copyWith({
    String? id,
    String? entity,
    String? entityId,
    String? op,
    String? payload,
    DateTime? clientUpdatedAt,
    int? attempts,
    DateTime? nextAttemptAt,
    OutboxState? state,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxEntry(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    state: state ?? this.state,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      state: data.state.present ? data.state.value : this.state,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('state: $state, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entity,
    entityId,
    op,
    payload,
    clientUpdatedAt,
    attempts,
    nextAttemptAt,
    state,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.state == this.state &&
          other.lastError == this.lastError);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<String> id;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String> payload;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<OutboxState> state;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.state = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    required String id,
    required String entity,
    required String entityId,
    required String op,
    required String payload,
    required DateTime clientUpdatedAt,
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAt,
    required OutboxState state,
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entity = Value(entity),
       entityId = Value(entityId),
       op = Value(op),
       payload = Value(payload),
       clientUpdatedAt = Value(clientUpdatedAt),
       nextAttemptAt = Value(nextAttemptAt),
       state = Value(state);
  static Insertable<OutboxEntry> custom({
    Expression<String>? id,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? state,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (state != null) 'state': state,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? op,
    Value<String>? payload,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAt,
    Value<OutboxState>? state,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      state: state ?? this.state,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $OutboxEntriesTable.$converterstate.toSql(state.value),
      );
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('state: $state, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FarmerProfilesTable extends FarmerProfiles
    with TableInfo<$FarmerProfilesTable, FarmerProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FarmerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _villageMeta = const VerificationMeta(
    'village',
  );
  @override
  late final GeneratedColumn<String> village = GeneratedColumn<String>(
    'village',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _talukaMeta = const VerificationMeta('taluka');
  @override
  late final GeneratedColumn<String> taluka = GeneratedColumn<String>(
    'taluka',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consentDataProcessingMeta =
      const VerificationMeta('consentDataProcessing');
  @override
  late final GeneratedColumn<bool> consentDataProcessing =
      GeneratedColumn<bool>(
        'consent_data_processing',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("consent_data_processing" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _consentWhatsappMeta = const VerificationMeta(
    'consentWhatsapp',
  );
  @override
  late final GeneratedColumn<bool> consentWhatsapp = GeneratedColumn<bool>(
    'consent_whatsapp',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consent_whatsapp" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    language,
    village,
    taluka,
    district,
    consentDataProcessing,
    consentWhatsapp,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'farmer_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<FarmerProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('village')) {
      context.handle(
        _villageMeta,
        village.isAcceptableOrUnknown(data['village']!, _villageMeta),
      );
    }
    if (data.containsKey('taluka')) {
      context.handle(
        _talukaMeta,
        taluka.isAcceptableOrUnknown(data['taluka']!, _talukaMeta),
      );
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    }
    if (data.containsKey('consent_data_processing')) {
      context.handle(
        _consentDataProcessingMeta,
        consentDataProcessing.isAcceptableOrUnknown(
          data['consent_data_processing']!,
          _consentDataProcessingMeta,
        ),
      );
    }
    if (data.containsKey('consent_whatsapp')) {
      context.handle(
        _consentWhatsappMeta,
        consentWhatsapp.isAcceptableOrUnknown(
          data['consent_whatsapp']!,
          _consentWhatsappMeta,
        ),
      );
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FarmerProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FarmerProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      village: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}village'],
      ),
      taluka: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taluka'],
      ),
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      ),
      consentDataProcessing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consent_data_processing'],
      )!,
      consentWhatsapp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consent_whatsapp'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $FarmerProfilesTable createAlias(String alias) {
    return $FarmerProfilesTable(attachedDatabase, alias);
  }
}

class FarmerProfileRow extends DataClass
    implements Insertable<FarmerProfileRow> {
  final String id;
  final String? displayName;
  final String language;
  final String? village;
  final String? taluka;
  final String? district;
  final bool consentDataProcessing;
  final bool consentWhatsapp;
  final DateTime clientUpdatedAt;
  const FarmerProfileRow({
    required this.id,
    this.displayName,
    required this.language,
    this.village,
    this.taluka,
    this.district,
    required this.consentDataProcessing,
    required this.consentWhatsapp,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || village != null) {
      map['village'] = Variable<String>(village);
    }
    if (!nullToAbsent || taluka != null) {
      map['taluka'] = Variable<String>(taluka);
    }
    if (!nullToAbsent || district != null) {
      map['district'] = Variable<String>(district);
    }
    map['consent_data_processing'] = Variable<bool>(consentDataProcessing);
    map['consent_whatsapp'] = Variable<bool>(consentWhatsapp);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  FarmerProfilesCompanion toCompanion(bool nullToAbsent) {
    return FarmerProfilesCompanion(
      id: Value(id),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      language: Value(language),
      village: village == null && nullToAbsent
          ? const Value.absent()
          : Value(village),
      taluka: taluka == null && nullToAbsent
          ? const Value.absent()
          : Value(taluka),
      district: district == null && nullToAbsent
          ? const Value.absent()
          : Value(district),
      consentDataProcessing: Value(consentDataProcessing),
      consentWhatsapp: Value(consentWhatsapp),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory FarmerProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FarmerProfileRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      language: serializer.fromJson<String>(json['language']),
      village: serializer.fromJson<String?>(json['village']),
      taluka: serializer.fromJson<String?>(json['taluka']),
      district: serializer.fromJson<String?>(json['district']),
      consentDataProcessing: serializer.fromJson<bool>(
        json['consentDataProcessing'],
      ),
      consentWhatsapp: serializer.fromJson<bool>(json['consentWhatsapp']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String?>(displayName),
      'language': serializer.toJson<String>(language),
      'village': serializer.toJson<String?>(village),
      'taluka': serializer.toJson<String?>(taluka),
      'district': serializer.toJson<String?>(district),
      'consentDataProcessing': serializer.toJson<bool>(consentDataProcessing),
      'consentWhatsapp': serializer.toJson<bool>(consentWhatsapp),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  FarmerProfileRow copyWith({
    String? id,
    Value<String?> displayName = const Value.absent(),
    String? language,
    Value<String?> village = const Value.absent(),
    Value<String?> taluka = const Value.absent(),
    Value<String?> district = const Value.absent(),
    bool? consentDataProcessing,
    bool? consentWhatsapp,
    DateTime? clientUpdatedAt,
  }) => FarmerProfileRow(
    id: id ?? this.id,
    displayName: displayName.present ? displayName.value : this.displayName,
    language: language ?? this.language,
    village: village.present ? village.value : this.village,
    taluka: taluka.present ? taluka.value : this.taluka,
    district: district.present ? district.value : this.district,
    consentDataProcessing: consentDataProcessing ?? this.consentDataProcessing,
    consentWhatsapp: consentWhatsapp ?? this.consentWhatsapp,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  FarmerProfileRow copyWithCompanion(FarmerProfilesCompanion data) {
    return FarmerProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      language: data.language.present ? data.language.value : this.language,
      village: data.village.present ? data.village.value : this.village,
      taluka: data.taluka.present ? data.taluka.value : this.taluka,
      district: data.district.present ? data.district.value : this.district,
      consentDataProcessing: data.consentDataProcessing.present
          ? data.consentDataProcessing.value
          : this.consentDataProcessing,
      consentWhatsapp: data.consentWhatsapp.present
          ? data.consentWhatsapp.value
          : this.consentWhatsapp,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FarmerProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('language: $language, ')
          ..write('village: $village, ')
          ..write('taluka: $taluka, ')
          ..write('district: $district, ')
          ..write('consentDataProcessing: $consentDataProcessing, ')
          ..write('consentWhatsapp: $consentWhatsapp, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    language,
    village,
    taluka,
    district,
    consentDataProcessing,
    consentWhatsapp,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FarmerProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.language == this.language &&
          other.village == this.village &&
          other.taluka == this.taluka &&
          other.district == this.district &&
          other.consentDataProcessing == this.consentDataProcessing &&
          other.consentWhatsapp == this.consentWhatsapp &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class FarmerProfilesCompanion extends UpdateCompanion<FarmerProfileRow> {
  final Value<String> id;
  final Value<String?> displayName;
  final Value<String> language;
  final Value<String?> village;
  final Value<String?> taluka;
  final Value<String?> district;
  final Value<bool> consentDataProcessing;
  final Value<bool> consentWhatsapp;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const FarmerProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.language = const Value.absent(),
    this.village = const Value.absent(),
    this.taluka = const Value.absent(),
    this.district = const Value.absent(),
    this.consentDataProcessing = const Value.absent(),
    this.consentWhatsapp = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FarmerProfilesCompanion.insert({
    required String id,
    this.displayName = const Value.absent(),
    required String language,
    this.village = const Value.absent(),
    this.taluka = const Value.absent(),
    this.district = const Value.absent(),
    this.consentDataProcessing = const Value.absent(),
    this.consentWhatsapp = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       language = Value(language),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<FarmerProfileRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? language,
    Expression<String>? village,
    Expression<String>? taluka,
    Expression<String>? district,
    Expression<bool>? consentDataProcessing,
    Expression<bool>? consentWhatsapp,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (language != null) 'language': language,
      if (village != null) 'village': village,
      if (taluka != null) 'taluka': taluka,
      if (district != null) 'district': district,
      if (consentDataProcessing != null)
        'consent_data_processing': consentDataProcessing,
      if (consentWhatsapp != null) 'consent_whatsapp': consentWhatsapp,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FarmerProfilesCompanion copyWith({
    Value<String>? id,
    Value<String?>? displayName,
    Value<String>? language,
    Value<String?>? village,
    Value<String?>? taluka,
    Value<String?>? district,
    Value<bool>? consentDataProcessing,
    Value<bool>? consentWhatsapp,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return FarmerProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      language: language ?? this.language,
      village: village ?? this.village,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      consentDataProcessing:
          consentDataProcessing ?? this.consentDataProcessing,
      consentWhatsapp: consentWhatsapp ?? this.consentWhatsapp,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (village.present) {
      map['village'] = Variable<String>(village.value);
    }
    if (taluka.present) {
      map['taluka'] = Variable<String>(taluka.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (consentDataProcessing.present) {
      map['consent_data_processing'] = Variable<bool>(
        consentDataProcessing.value,
      );
    }
    if (consentWhatsapp.present) {
      map['consent_whatsapp'] = Variable<bool>(consentWhatsapp.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FarmerProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('language: $language, ')
          ..write('village: $village, ')
          ..write('taluka: $taluka, ')
          ..write('district: $district, ')
          ..write('consentDataProcessing: $consentDataProcessing, ')
          ..write('consentWhatsapp: $consentWhatsapp, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
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
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
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
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String value;
  const SyncMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
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

  SyncMetaData copyWith({String? key, String? value}) =>
      SyncMetaData(key: key ?? this.key, value: value ?? this.value);
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
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
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaData> custom({
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

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
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
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlotsTable extends Plots with TableInfo<$PlotsTable, PlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _cropMeta = const VerificationMeta('crop');
  @override
  late final GeneratedColumn<String> crop = GeneratedColumn<String>(
    'crop',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _varietyMeta = const VerificationMeta(
    'variety',
  );
  @override
  late final GeneratedColumn<String> variety = GeneratedColumn<String>(
    'variety',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaSqMMeta = const VerificationMeta(
    'areaSqM',
  );
  @override
  late final GeneratedColumn<double> areaSqM = GeneratedColumn<double>(
    'area_sq_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plantingYearMeta = const VerificationMeta(
    'plantingYear',
  );
  @override
  late final GeneratedColumn<int> plantingYear = GeneratedColumn<int>(
    'planting_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _treeCountMeta = const VerificationMeta(
    'treeCount',
  );
  @override
  late final GeneratedColumn<int> treeCount = GeneratedColumn<int>(
    'tree_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowSpacingMMeta = const VerificationMeta(
    'rowSpacingM',
  );
  @override
  late final GeneratedColumn<double> rowSpacingM = GeneratedColumn<double>(
    'row_spacing_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plantSpacingMMeta = const VerificationMeta(
    'plantSpacingM',
  );
  @override
  late final GeneratedColumn<double> plantSpacingM = GeneratedColumn<double>(
    'plant_spacing_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _irrigationTypeMeta = const VerificationMeta(
    'irrigationType',
  );
  @override
  late final GeneratedColumn<String> irrigationType = GeneratedColumn<String>(
    'irrigation_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterSourceMeta = const VerificationMeta(
    'waterSource',
  );
  @override
  late final GeneratedColumn<String> waterSource = GeneratedColumn<String>(
    'water_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soilTypeMeta = const VerificationMeta(
    'soilType',
  );
  @override
  late final GeneratedColumn<String> soilType = GeneratedColumn<String>(
    'soil_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _centroidLatMeta = const VerificationMeta(
    'centroidLat',
  );
  @override
  late final GeneratedColumn<double> centroidLat = GeneratedColumn<double>(
    'centroid_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _centroidLonMeta = const VerificationMeta(
    'centroidLon',
  );
  @override
  late final GeneratedColumn<double> centroidLon = GeneratedColumn<double>(
    'centroid_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boundaryMeta = const VerificationMeta(
    'boundary',
  );
  @override
  late final GeneratedColumn<String> boundary = GeneratedColumn<String>(
    'boundary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    crop,
    variety,
    areaSqM,
    plantingYear,
    treeCount,
    rowSpacingM,
    plantSpacingM,
    irrigationType,
    waterSource,
    soilType,
    centroidLat,
    centroidLon,
    boundary,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plots';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('crop')) {
      context.handle(
        _cropMeta,
        crop.isAcceptableOrUnknown(data['crop']!, _cropMeta),
      );
    } else if (isInserting) {
      context.missing(_cropMeta);
    }
    if (data.containsKey('variety')) {
      context.handle(
        _varietyMeta,
        variety.isAcceptableOrUnknown(data['variety']!, _varietyMeta),
      );
    }
    if (data.containsKey('area_sq_m')) {
      context.handle(
        _areaSqMMeta,
        areaSqM.isAcceptableOrUnknown(data['area_sq_m']!, _areaSqMMeta),
      );
    } else if (isInserting) {
      context.missing(_areaSqMMeta);
    }
    if (data.containsKey('planting_year')) {
      context.handle(
        _plantingYearMeta,
        plantingYear.isAcceptableOrUnknown(
          data['planting_year']!,
          _plantingYearMeta,
        ),
      );
    }
    if (data.containsKey('tree_count')) {
      context.handle(
        _treeCountMeta,
        treeCount.isAcceptableOrUnknown(data['tree_count']!, _treeCountMeta),
      );
    }
    if (data.containsKey('row_spacing_m')) {
      context.handle(
        _rowSpacingMMeta,
        rowSpacingM.isAcceptableOrUnknown(
          data['row_spacing_m']!,
          _rowSpacingMMeta,
        ),
      );
    }
    if (data.containsKey('plant_spacing_m')) {
      context.handle(
        _plantSpacingMMeta,
        plantSpacingM.isAcceptableOrUnknown(
          data['plant_spacing_m']!,
          _plantSpacingMMeta,
        ),
      );
    }
    if (data.containsKey('irrigation_type')) {
      context.handle(
        _irrigationTypeMeta,
        irrigationType.isAcceptableOrUnknown(
          data['irrigation_type']!,
          _irrigationTypeMeta,
        ),
      );
    }
    if (data.containsKey('water_source')) {
      context.handle(
        _waterSourceMeta,
        waterSource.isAcceptableOrUnknown(
          data['water_source']!,
          _waterSourceMeta,
        ),
      );
    }
    if (data.containsKey('soil_type')) {
      context.handle(
        _soilTypeMeta,
        soilType.isAcceptableOrUnknown(data['soil_type']!, _soilTypeMeta),
      );
    }
    if (data.containsKey('centroid_lat')) {
      context.handle(
        _centroidLatMeta,
        centroidLat.isAcceptableOrUnknown(
          data['centroid_lat']!,
          _centroidLatMeta,
        ),
      );
    }
    if (data.containsKey('centroid_lon')) {
      context.handle(
        _centroidLonMeta,
        centroidLon.isAcceptableOrUnknown(
          data['centroid_lon']!,
          _centroidLonMeta,
        ),
      );
    }
    if (data.containsKey('boundary')) {
      context.handle(
        _boundaryMeta,
        boundary.isAcceptableOrUnknown(data['boundary']!, _boundaryMeta),
      );
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      crop: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop'],
      )!,
      variety: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variety'],
      ),
      areaSqM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}area_sq_m'],
      )!,
      plantingYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planting_year'],
      ),
      treeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tree_count'],
      ),
      rowSpacingM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}row_spacing_m'],
      ),
      plantSpacingM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}plant_spacing_m'],
      ),
      irrigationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}irrigation_type'],
      ),
      waterSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}water_source'],
      ),
      soilType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}soil_type'],
      ),
      centroidLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}centroid_lat'],
      ),
      centroidLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}centroid_lon'],
      ),
      boundary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boundary'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $PlotsTable createAlias(String alias) {
    return $PlotsTable(attachedDatabase, alias);
  }
}

class PlotRow extends DataClass implements Insertable<PlotRow> {
  final String id;
  final String name;
  final String crop;
  final String? variety;
  final double areaSqM;
  final int? plantingYear;
  final int? treeCount;
  final double? rowSpacingM;
  final double? plantSpacingM;
  final String? irrigationType;
  final String? waterSource;
  final String? soilType;
  final double? centroidLat;
  final double? centroidLon;
  final String? boundary;
  final DateTime clientUpdatedAt;
  const PlotRow({
    required this.id,
    required this.name,
    required this.crop,
    this.variety,
    required this.areaSqM,
    this.plantingYear,
    this.treeCount,
    this.rowSpacingM,
    this.plantSpacingM,
    this.irrigationType,
    this.waterSource,
    this.soilType,
    this.centroidLat,
    this.centroidLon,
    this.boundary,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['crop'] = Variable<String>(crop);
    if (!nullToAbsent || variety != null) {
      map['variety'] = Variable<String>(variety);
    }
    map['area_sq_m'] = Variable<double>(areaSqM);
    if (!nullToAbsent || plantingYear != null) {
      map['planting_year'] = Variable<int>(plantingYear);
    }
    if (!nullToAbsent || treeCount != null) {
      map['tree_count'] = Variable<int>(treeCount);
    }
    if (!nullToAbsent || rowSpacingM != null) {
      map['row_spacing_m'] = Variable<double>(rowSpacingM);
    }
    if (!nullToAbsent || plantSpacingM != null) {
      map['plant_spacing_m'] = Variable<double>(plantSpacingM);
    }
    if (!nullToAbsent || irrigationType != null) {
      map['irrigation_type'] = Variable<String>(irrigationType);
    }
    if (!nullToAbsent || waterSource != null) {
      map['water_source'] = Variable<String>(waterSource);
    }
    if (!nullToAbsent || soilType != null) {
      map['soil_type'] = Variable<String>(soilType);
    }
    if (!nullToAbsent || centroidLat != null) {
      map['centroid_lat'] = Variable<double>(centroidLat);
    }
    if (!nullToAbsent || centroidLon != null) {
      map['centroid_lon'] = Variable<double>(centroidLon);
    }
    if (!nullToAbsent || boundary != null) {
      map['boundary'] = Variable<String>(boundary);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  PlotsCompanion toCompanion(bool nullToAbsent) {
    return PlotsCompanion(
      id: Value(id),
      name: Value(name),
      crop: Value(crop),
      variety: variety == null && nullToAbsent
          ? const Value.absent()
          : Value(variety),
      areaSqM: Value(areaSqM),
      plantingYear: plantingYear == null && nullToAbsent
          ? const Value.absent()
          : Value(plantingYear),
      treeCount: treeCount == null && nullToAbsent
          ? const Value.absent()
          : Value(treeCount),
      rowSpacingM: rowSpacingM == null && nullToAbsent
          ? const Value.absent()
          : Value(rowSpacingM),
      plantSpacingM: plantSpacingM == null && nullToAbsent
          ? const Value.absent()
          : Value(plantSpacingM),
      irrigationType: irrigationType == null && nullToAbsent
          ? const Value.absent()
          : Value(irrigationType),
      waterSource: waterSource == null && nullToAbsent
          ? const Value.absent()
          : Value(waterSource),
      soilType: soilType == null && nullToAbsent
          ? const Value.absent()
          : Value(soilType),
      centroidLat: centroidLat == null && nullToAbsent
          ? const Value.absent()
          : Value(centroidLat),
      centroidLon: centroidLon == null && nullToAbsent
          ? const Value.absent()
          : Value(centroidLon),
      boundary: boundary == null && nullToAbsent
          ? const Value.absent()
          : Value(boundary),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory PlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlotRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      crop: serializer.fromJson<String>(json['crop']),
      variety: serializer.fromJson<String?>(json['variety']),
      areaSqM: serializer.fromJson<double>(json['areaSqM']),
      plantingYear: serializer.fromJson<int?>(json['plantingYear']),
      treeCount: serializer.fromJson<int?>(json['treeCount']),
      rowSpacingM: serializer.fromJson<double?>(json['rowSpacingM']),
      plantSpacingM: serializer.fromJson<double?>(json['plantSpacingM']),
      irrigationType: serializer.fromJson<String?>(json['irrigationType']),
      waterSource: serializer.fromJson<String?>(json['waterSource']),
      soilType: serializer.fromJson<String?>(json['soilType']),
      centroidLat: serializer.fromJson<double?>(json['centroidLat']),
      centroidLon: serializer.fromJson<double?>(json['centroidLon']),
      boundary: serializer.fromJson<String?>(json['boundary']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'crop': serializer.toJson<String>(crop),
      'variety': serializer.toJson<String?>(variety),
      'areaSqM': serializer.toJson<double>(areaSqM),
      'plantingYear': serializer.toJson<int?>(plantingYear),
      'treeCount': serializer.toJson<int?>(treeCount),
      'rowSpacingM': serializer.toJson<double?>(rowSpacingM),
      'plantSpacingM': serializer.toJson<double?>(plantSpacingM),
      'irrigationType': serializer.toJson<String?>(irrigationType),
      'waterSource': serializer.toJson<String?>(waterSource),
      'soilType': serializer.toJson<String?>(soilType),
      'centroidLat': serializer.toJson<double?>(centroidLat),
      'centroidLon': serializer.toJson<double?>(centroidLon),
      'boundary': serializer.toJson<String?>(boundary),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  PlotRow copyWith({
    String? id,
    String? name,
    String? crop,
    Value<String?> variety = const Value.absent(),
    double? areaSqM,
    Value<int?> plantingYear = const Value.absent(),
    Value<int?> treeCount = const Value.absent(),
    Value<double?> rowSpacingM = const Value.absent(),
    Value<double?> plantSpacingM = const Value.absent(),
    Value<String?> irrigationType = const Value.absent(),
    Value<String?> waterSource = const Value.absent(),
    Value<String?> soilType = const Value.absent(),
    Value<double?> centroidLat = const Value.absent(),
    Value<double?> centroidLon = const Value.absent(),
    Value<String?> boundary = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => PlotRow(
    id: id ?? this.id,
    name: name ?? this.name,
    crop: crop ?? this.crop,
    variety: variety.present ? variety.value : this.variety,
    areaSqM: areaSqM ?? this.areaSqM,
    plantingYear: plantingYear.present ? plantingYear.value : this.plantingYear,
    treeCount: treeCount.present ? treeCount.value : this.treeCount,
    rowSpacingM: rowSpacingM.present ? rowSpacingM.value : this.rowSpacingM,
    plantSpacingM: plantSpacingM.present
        ? plantSpacingM.value
        : this.plantSpacingM,
    irrigationType: irrigationType.present
        ? irrigationType.value
        : this.irrigationType,
    waterSource: waterSource.present ? waterSource.value : this.waterSource,
    soilType: soilType.present ? soilType.value : this.soilType,
    centroidLat: centroidLat.present ? centroidLat.value : this.centroidLat,
    centroidLon: centroidLon.present ? centroidLon.value : this.centroidLon,
    boundary: boundary.present ? boundary.value : this.boundary,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  PlotRow copyWithCompanion(PlotsCompanion data) {
    return PlotRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      crop: data.crop.present ? data.crop.value : this.crop,
      variety: data.variety.present ? data.variety.value : this.variety,
      areaSqM: data.areaSqM.present ? data.areaSqM.value : this.areaSqM,
      plantingYear: data.plantingYear.present
          ? data.plantingYear.value
          : this.plantingYear,
      treeCount: data.treeCount.present ? data.treeCount.value : this.treeCount,
      rowSpacingM: data.rowSpacingM.present
          ? data.rowSpacingM.value
          : this.rowSpacingM,
      plantSpacingM: data.plantSpacingM.present
          ? data.plantSpacingM.value
          : this.plantSpacingM,
      irrigationType: data.irrigationType.present
          ? data.irrigationType.value
          : this.irrigationType,
      waterSource: data.waterSource.present
          ? data.waterSource.value
          : this.waterSource,
      soilType: data.soilType.present ? data.soilType.value : this.soilType,
      centroidLat: data.centroidLat.present
          ? data.centroidLat.value
          : this.centroidLat,
      centroidLon: data.centroidLon.present
          ? data.centroidLon.value
          : this.centroidLon,
      boundary: data.boundary.present ? data.boundary.value : this.boundary,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlotRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('crop: $crop, ')
          ..write('variety: $variety, ')
          ..write('areaSqM: $areaSqM, ')
          ..write('plantingYear: $plantingYear, ')
          ..write('treeCount: $treeCount, ')
          ..write('rowSpacingM: $rowSpacingM, ')
          ..write('plantSpacingM: $plantSpacingM, ')
          ..write('irrigationType: $irrigationType, ')
          ..write('waterSource: $waterSource, ')
          ..write('soilType: $soilType, ')
          ..write('centroidLat: $centroidLat, ')
          ..write('centroidLon: $centroidLon, ')
          ..write('boundary: $boundary, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    crop,
    variety,
    areaSqM,
    plantingYear,
    treeCount,
    rowSpacingM,
    plantSpacingM,
    irrigationType,
    waterSource,
    soilType,
    centroidLat,
    centroidLon,
    boundary,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlotRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.crop == this.crop &&
          other.variety == this.variety &&
          other.areaSqM == this.areaSqM &&
          other.plantingYear == this.plantingYear &&
          other.treeCount == this.treeCount &&
          other.rowSpacingM == this.rowSpacingM &&
          other.plantSpacingM == this.plantSpacingM &&
          other.irrigationType == this.irrigationType &&
          other.waterSource == this.waterSource &&
          other.soilType == this.soilType &&
          other.centroidLat == this.centroidLat &&
          other.centroidLon == this.centroidLon &&
          other.boundary == this.boundary &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class PlotsCompanion extends UpdateCompanion<PlotRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> crop;
  final Value<String?> variety;
  final Value<double> areaSqM;
  final Value<int?> plantingYear;
  final Value<int?> treeCount;
  final Value<double?> rowSpacingM;
  final Value<double?> plantSpacingM;
  final Value<String?> irrigationType;
  final Value<String?> waterSource;
  final Value<String?> soilType;
  final Value<double?> centroidLat;
  final Value<double?> centroidLon;
  final Value<String?> boundary;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const PlotsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.crop = const Value.absent(),
    this.variety = const Value.absent(),
    this.areaSqM = const Value.absent(),
    this.plantingYear = const Value.absent(),
    this.treeCount = const Value.absent(),
    this.rowSpacingM = const Value.absent(),
    this.plantSpacingM = const Value.absent(),
    this.irrigationType = const Value.absent(),
    this.waterSource = const Value.absent(),
    this.soilType = const Value.absent(),
    this.centroidLat = const Value.absent(),
    this.centroidLon = const Value.absent(),
    this.boundary = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlotsCompanion.insert({
    required String id,
    required String name,
    required String crop,
    this.variety = const Value.absent(),
    required double areaSqM,
    this.plantingYear = const Value.absent(),
    this.treeCount = const Value.absent(),
    this.rowSpacingM = const Value.absent(),
    this.plantSpacingM = const Value.absent(),
    this.irrigationType = const Value.absent(),
    this.waterSource = const Value.absent(),
    this.soilType = const Value.absent(),
    this.centroidLat = const Value.absent(),
    this.centroidLon = const Value.absent(),
    this.boundary = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       crop = Value(crop),
       areaSqM = Value(areaSqM),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<PlotRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? crop,
    Expression<String>? variety,
    Expression<double>? areaSqM,
    Expression<int>? plantingYear,
    Expression<int>? treeCount,
    Expression<double>? rowSpacingM,
    Expression<double>? plantSpacingM,
    Expression<String>? irrigationType,
    Expression<String>? waterSource,
    Expression<String>? soilType,
    Expression<double>? centroidLat,
    Expression<double>? centroidLon,
    Expression<String>? boundary,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (crop != null) 'crop': crop,
      if (variety != null) 'variety': variety,
      if (areaSqM != null) 'area_sq_m': areaSqM,
      if (plantingYear != null) 'planting_year': plantingYear,
      if (treeCount != null) 'tree_count': treeCount,
      if (rowSpacingM != null) 'row_spacing_m': rowSpacingM,
      if (plantSpacingM != null) 'plant_spacing_m': plantSpacingM,
      if (irrigationType != null) 'irrigation_type': irrigationType,
      if (waterSource != null) 'water_source': waterSource,
      if (soilType != null) 'soil_type': soilType,
      if (centroidLat != null) 'centroid_lat': centroidLat,
      if (centroidLon != null) 'centroid_lon': centroidLon,
      if (boundary != null) 'boundary': boundary,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlotsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? crop,
    Value<String?>? variety,
    Value<double>? areaSqM,
    Value<int?>? plantingYear,
    Value<int?>? treeCount,
    Value<double?>? rowSpacingM,
    Value<double?>? plantSpacingM,
    Value<String?>? irrigationType,
    Value<String?>? waterSource,
    Value<String?>? soilType,
    Value<double?>? centroidLat,
    Value<double?>? centroidLon,
    Value<String?>? boundary,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return PlotsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      crop: crop ?? this.crop,
      variety: variety ?? this.variety,
      areaSqM: areaSqM ?? this.areaSqM,
      plantingYear: plantingYear ?? this.plantingYear,
      treeCount: treeCount ?? this.treeCount,
      rowSpacingM: rowSpacingM ?? this.rowSpacingM,
      plantSpacingM: plantSpacingM ?? this.plantSpacingM,
      irrigationType: irrigationType ?? this.irrigationType,
      waterSource: waterSource ?? this.waterSource,
      soilType: soilType ?? this.soilType,
      centroidLat: centroidLat ?? this.centroidLat,
      centroidLon: centroidLon ?? this.centroidLon,
      boundary: boundary ?? this.boundary,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (crop.present) {
      map['crop'] = Variable<String>(crop.value);
    }
    if (variety.present) {
      map['variety'] = Variable<String>(variety.value);
    }
    if (areaSqM.present) {
      map['area_sq_m'] = Variable<double>(areaSqM.value);
    }
    if (plantingYear.present) {
      map['planting_year'] = Variable<int>(plantingYear.value);
    }
    if (treeCount.present) {
      map['tree_count'] = Variable<int>(treeCount.value);
    }
    if (rowSpacingM.present) {
      map['row_spacing_m'] = Variable<double>(rowSpacingM.value);
    }
    if (plantSpacingM.present) {
      map['plant_spacing_m'] = Variable<double>(plantSpacingM.value);
    }
    if (irrigationType.present) {
      map['irrigation_type'] = Variable<String>(irrigationType.value);
    }
    if (waterSource.present) {
      map['water_source'] = Variable<String>(waterSource.value);
    }
    if (soilType.present) {
      map['soil_type'] = Variable<String>(soilType.value);
    }
    if (centroidLat.present) {
      map['centroid_lat'] = Variable<double>(centroidLat.value);
    }
    if (centroidLon.present) {
      map['centroid_lon'] = Variable<double>(centroidLon.value);
    }
    if (boundary.present) {
      map['boundary'] = Variable<String>(boundary.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlotsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('crop: $crop, ')
          ..write('variety: $variety, ')
          ..write('areaSqM: $areaSqM, ')
          ..write('plantingYear: $plantingYear, ')
          ..write('treeCount: $treeCount, ')
          ..write('rowSpacingM: $rowSpacingM, ')
          ..write('plantSpacingM: $plantSpacingM, ')
          ..write('irrigationType: $irrigationType, ')
          ..write('waterSource: $waterSource, ')
          ..write('soilType: $soilType, ')
          ..write('centroidLat: $centroidLat, ')
          ..write('centroidLon: $centroidLon, ')
          ..write('boundary: $boundary, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final $FarmerProfilesTable farmerProfiles = $FarmerProfilesTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $PlotsTable plots = $PlotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxEntries,
    farmerProfiles,
    syncMeta,
    plots,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      required String id,
      required String entity,
      required String entityId,
      required String op,
      required String payload,
      required DateTime clientUpdatedAt,
      Value<int> attempts,
      required DateTime nextAttemptAt,
      required OutboxState state,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<String> id,
      Value<String> entity,
      Value<String> entityId,
      Value<String> op,
      Value<String> payload,
      Value<DateTime> clientUpdatedAt,
      Value<int> attempts,
      Value<DateTime> nextAttemptAt,
      Value<OutboxState> state,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
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

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutboxState, OutboxState, String> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OutboxState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEntriesTable,
          OutboxEntry,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(_$AppDatabase db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<OutboxState> state = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion(
                id: id,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                clientUpdatedAt: clientUpdatedAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                state: state,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entity,
                required String entityId,
                required String op,
                required String payload,
                required DateTime clientUpdatedAt,
                Value<int> attempts = const Value.absent(),
                required DateTime nextAttemptAt,
                required OutboxState state,
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                id: id,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                clientUpdatedAt: clientUpdatedAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                state: state,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxEntriesTable, OutboxEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OutboxEntriesTable,
                    OutboxEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEntriesTable,
      OutboxEntry,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        OutboxEntry,
        BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
      ),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$FarmerProfilesTableCreateCompanionBuilder =
    FarmerProfilesCompanion Function({
      required String id,
      Value<String?> displayName,
      required String language,
      Value<String?> village,
      Value<String?> taluka,
      Value<String?> district,
      Value<bool> consentDataProcessing,
      Value<bool> consentWhatsapp,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$FarmerProfilesTableUpdateCompanionBuilder =
    FarmerProfilesCompanion Function({
      Value<String> id,
      Value<String?> displayName,
      Value<String> language,
      Value<String?> village,
      Value<String?> taluka,
      Value<String?> district,
      Value<bool> consentDataProcessing,
      Value<bool> consentWhatsapp,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$FarmerProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $FarmerProfilesTable> {
  $$FarmerProfilesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get village => $composableBuilder(
    column: $table.village,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taluka => $composableBuilder(
    column: $table.taluka,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consentDataProcessing => $composableBuilder(
    column: $table.consentDataProcessing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consentWhatsapp => $composableBuilder(
    column: $table.consentWhatsapp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FarmerProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $FarmerProfilesTable> {
  $$FarmerProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get village => $composableBuilder(
    column: $table.village,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taluka => $composableBuilder(
    column: $table.taluka,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consentDataProcessing => $composableBuilder(
    column: $table.consentDataProcessing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consentWhatsapp => $composableBuilder(
    column: $table.consentWhatsapp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FarmerProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FarmerProfilesTable> {
  $$FarmerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get village =>
      $composableBuilder(column: $table.village, builder: (column) => column);

  GeneratedColumn<String> get taluka =>
      $composableBuilder(column: $table.taluka, builder: (column) => column);

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<bool> get consentDataProcessing => $composableBuilder(
    column: $table.consentDataProcessing,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consentWhatsapp => $composableBuilder(
    column: $table.consentWhatsapp,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$FarmerProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FarmerProfilesTable,
          FarmerProfileRow,
          $$FarmerProfilesTableFilterComposer,
          $$FarmerProfilesTableOrderingComposer,
          $$FarmerProfilesTableAnnotationComposer,
          $$FarmerProfilesTableCreateCompanionBuilder,
          $$FarmerProfilesTableUpdateCompanionBuilder,
          (
            FarmerProfileRow,
            BaseReferences<
              _$AppDatabase,
              $FarmerProfilesTable,
              FarmerProfileRow
            >,
          ),
          FarmerProfileRow,
          PrefetchHooks Function()
        > {
  $$FarmerProfilesTableTableManager(
    _$AppDatabase db,
    $FarmerProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FarmerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FarmerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FarmerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> village = const Value.absent(),
                Value<String?> taluka = const Value.absent(),
                Value<String?> district = const Value.absent(),
                Value<bool> consentDataProcessing = const Value.absent(),
                Value<bool> consentWhatsapp = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FarmerProfilesCompanion(
                id: id,
                displayName: displayName,
                language: language,
                village: village,
                taluka: taluka,
                district: district,
                consentDataProcessing: consentDataProcessing,
                consentWhatsapp: consentWhatsapp,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> displayName = const Value.absent(),
                required String language,
                Value<String?> village = const Value.absent(),
                Value<String?> taluka = const Value.absent(),
                Value<String?> district = const Value.absent(),
                Value<bool> consentDataProcessing = const Value.absent(),
                Value<bool> consentWhatsapp = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FarmerProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                language: language,
                village: village,
                taluka: taluka,
                district: district,
                consentDataProcessing: consentDataProcessing,
                consentWhatsapp: consentWhatsapp,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FarmerProfilesTable, FarmerProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FarmerProfilesTable,
                    FarmerProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FarmerProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FarmerProfilesTable,
      FarmerProfileRow,
      $$FarmerProfilesTableFilterComposer,
      $$FarmerProfilesTableOrderingComposer,
      $$FarmerProfilesTableAnnotationComposer,
      $$FarmerProfilesTableCreateCompanionBuilder,
      $$FarmerProfilesTableUpdateCompanionBuilder,
      (
        FarmerProfileRow,
        BaseReferences<_$AppDatabase, $FarmerProfilesTable, FarmerProfileRow>,
      ),
      FarmerProfileRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
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

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
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

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
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

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, SyncMetaData>(table),
                  BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>(
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

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
      PrefetchHooks Function()
    >;
typedef $$PlotsTableCreateCompanionBuilder = PlotsCompanion Function({
  required String id,
  required String name,
  required String crop,
  Value<String?> variety,
  required double areaSqM,
  Value<int?> plantingYear,
  Value<int?> treeCount,
  Value<double?> rowSpacingM,
  Value<double?> plantSpacingM,
  Value<String?> irrigationType,
  Value<String?> waterSource,
  Value<String?> soilType,
  Value<double?> centroidLat,
  Value<double?> centroidLon,
  Value<String?> boundary,
  required DateTime clientUpdatedAt,
  Value<int> rowid,
});
typedef $$PlotsTableUpdateCompanionBuilder = PlotsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> crop,
  Value<String?> variety,
  Value<double> areaSqM,
  Value<int?> plantingYear,
  Value<int?> treeCount,
  Value<double?> rowSpacingM,
  Value<double?> plantSpacingM,
  Value<String?> irrigationType,
  Value<String?> waterSource,
  Value<String?> soilType,
  Value<double?> centroidLat,
  Value<double?> centroidLon,
  Value<String?> boundary,
  Value<DateTime> clientUpdatedAt,
  Value<int> rowid,
});

class $$PlotsTableFilterComposer extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crop => $composableBuilder(
    column: $table.crop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variety => $composableBuilder(
    column: $table.variety,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get areaSqM => $composableBuilder(
    column: $table.areaSqM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plantingYear => $composableBuilder(
    column: $table.plantingYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get treeCount => $composableBuilder(
    column: $table.treeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rowSpacingM => $composableBuilder(
    column: $table.rowSpacingM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get plantSpacingM => $composableBuilder(
    column: $table.plantSpacingM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get irrigationType => $composableBuilder(
    column: $table.irrigationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soilType => $composableBuilder(
    column: $table.soilType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centroidLat => $composableBuilder(
    column: $table.centroidLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centroidLon => $composableBuilder(
    column: $table.centroidLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boundary => $composableBuilder(
    column: $table.boundary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crop => $composableBuilder(
    column: $table.crop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variety => $composableBuilder(
    column: $table.variety,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get areaSqM => $composableBuilder(
    column: $table.areaSqM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plantingYear => $composableBuilder(
    column: $table.plantingYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get treeCount => $composableBuilder(
    column: $table.treeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rowSpacingM => $composableBuilder(
    column: $table.rowSpacingM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get plantSpacingM => $composableBuilder(
    column: $table.plantSpacingM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get irrigationType => $composableBuilder(
    column: $table.irrigationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soilType => $composableBuilder(
    column: $table.soilType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centroidLat => $composableBuilder(
    column: $table.centroidLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centroidLon => $composableBuilder(
    column: $table.centroidLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boundary => $composableBuilder(
    column: $table.boundary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get crop =>
      $composableBuilder(column: $table.crop, builder: (column) => column);

  GeneratedColumn<String> get variety =>
      $composableBuilder(column: $table.variety, builder: (column) => column);

  GeneratedColumn<double> get areaSqM =>
      $composableBuilder(column: $table.areaSqM, builder: (column) => column);

  GeneratedColumn<int> get plantingYear => $composableBuilder(
    column: $table.plantingYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get treeCount =>
      $composableBuilder(column: $table.treeCount, builder: (column) => column);

  GeneratedColumn<double> get rowSpacingM => $composableBuilder(
    column: $table.rowSpacingM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get plantSpacingM => $composableBuilder(
    column: $table.plantSpacingM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get irrigationType => $composableBuilder(
    column: $table.irrigationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soilType =>
      $composableBuilder(column: $table.soilType, builder: (column) => column);

  GeneratedColumn<double> get centroidLat => $composableBuilder(
    column: $table.centroidLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get centroidLon => $composableBuilder(
    column: $table.centroidLon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boundary =>
      $composableBuilder(column: $table.boundary, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$PlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlotsTable,
          PlotRow,
          $$PlotsTableFilterComposer,
          $$PlotsTableOrderingComposer,
          $$PlotsTableAnnotationComposer,
          $$PlotsTableCreateCompanionBuilder,
          $$PlotsTableUpdateCompanionBuilder,
          (PlotRow, BaseReferences<_$AppDatabase, $PlotsTable, PlotRow>),
          PlotRow,
          PrefetchHooks Function()
        > {
  $$PlotsTableTableManager(_$AppDatabase db, $PlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> crop = const Value.absent(),
                Value<String?> variety = const Value.absent(),
                Value<double> areaSqM = const Value.absent(),
                Value<int?> plantingYear = const Value.absent(),
                Value<int?> treeCount = const Value.absent(),
                Value<double?> rowSpacingM = const Value.absent(),
                Value<double?> plantSpacingM = const Value.absent(),
                Value<String?> irrigationType = const Value.absent(),
                Value<String?> waterSource = const Value.absent(),
                Value<String?> soilType = const Value.absent(),
                Value<double?> centroidLat = const Value.absent(),
                Value<double?> centroidLon = const Value.absent(),
                Value<String?> boundary = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlotsCompanion(
                id: id,
                name: name,
                crop: crop,
                variety: variety,
                areaSqM: areaSqM,
                plantingYear: plantingYear,
                treeCount: treeCount,
                rowSpacingM: rowSpacingM,
                plantSpacingM: plantSpacingM,
                irrigationType: irrigationType,
                waterSource: waterSource,
                soilType: soilType,
                centroidLat: centroidLat,
                centroidLon: centroidLon,
                boundary: boundary,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String crop,
                Value<String?> variety = const Value.absent(),
                required double areaSqM,
                Value<int?> plantingYear = const Value.absent(),
                Value<int?> treeCount = const Value.absent(),
                Value<double?> rowSpacingM = const Value.absent(),
                Value<double?> plantSpacingM = const Value.absent(),
                Value<String?> irrigationType = const Value.absent(),
                Value<String?> waterSource = const Value.absent(),
                Value<String?> soilType = const Value.absent(),
                Value<double?> centroidLat = const Value.absent(),
                Value<double?> centroidLon = const Value.absent(),
                Value<String?> boundary = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlotsCompanion.insert(
                id: id,
                name: name,
                crop: crop,
                variety: variety,
                areaSqM: areaSqM,
                plantingYear: plantingYear,
                treeCount: treeCount,
                rowSpacingM: rowSpacingM,
                plantSpacingM: plantSpacingM,
                irrigationType: irrigationType,
                waterSource: waterSource,
                soilType: soilType,
                centroidLat: centroidLat,
                centroidLon: centroidLon,
                boundary: boundary,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlotsTable, PlotRow>(table),
                  BaseReferences<_$AppDatabase, $PlotsTable, PlotRow>(
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

typedef $$PlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlotsTable,
      PlotRow,
      $$PlotsTableFilterComposer,
      $$PlotsTableOrderingComposer,
      $$PlotsTableAnnotationComposer,
      $$PlotsTableCreateCompanionBuilder,
      $$PlotsTableUpdateCompanionBuilder,
      (PlotRow, BaseReferences<_$AppDatabase, $PlotsTable, PlotRow>),
      PlotRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
  $$FarmerProfilesTableTableManager get farmerProfiles =>
      $$FarmerProfilesTableTableManager(_db, _db.farmerProfiles);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$PlotsTableTableManager get plots =>
      $$PlotsTableTableManager(_db, _db.plots);
}
