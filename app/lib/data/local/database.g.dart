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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
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
    phone,
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
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
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
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
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

  /// Contact number. For phone sign-ins the server fills it; Google users may add one.
  final String? phone;
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
    this.phone,
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
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
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
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
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
      phone: serializer.fromJson<String?>(json['phone']),
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
      'phone': serializer.toJson<String?>(phone),
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
    Value<String?> phone = const Value.absent(),
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
    phone: phone.present ? phone.value : this.phone,
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
      phone: data.phone.present ? data.phone.value : this.phone,
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
          ..write('phone: $phone, ')
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
    phone,
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
          other.phone == this.phone &&
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
  final Value<String?> phone;
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
    this.phone = const Value.absent(),
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
    this.phone = const Value.absent(),
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
    Expression<String>? phone,
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
      if (phone != null) 'phone': phone,
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
    Value<String?>? phone,
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
      phone: phone ?? this.phone,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
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
          ..write('phone: $phone, ')
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

class $BaharCyclesTable extends BaharCycles
    with TableInfo<$BaharCyclesTable, BaharCycleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BaharCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharMeta = const VerificationMeta('bahar');
  @override
  late final GeneratedColumn<String> bahar = GeneratedColumn<String>(
    'bahar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonYearMeta = const VerificationMeta(
    'seasonYear',
  );
  @override
  late final GeneratedColumn<int> seasonYear = GeneratedColumn<int>(
    'season_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMeta = const VerificationMeta(
    'planned',
  );
  @override
  late final GeneratedColumn<String> planned = GeneratedColumn<String>(
    'planned',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualMeta = const VerificationMeta('actual');
  @override
  late final GeneratedColumn<String> actual = GeneratedColumn<String>(
    'actual',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plotId,
    bahar,
    seasonYear,
    templateId,
    status,
    planned,
    actual,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bahar_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BaharCycleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar')) {
      context.handle(
        _baharMeta,
        bahar.isAcceptableOrUnknown(data['bahar']!, _baharMeta),
      );
    } else if (isInserting) {
      context.missing(_baharMeta);
    }
    if (data.containsKey('season_year')) {
      context.handle(
        _seasonYearMeta,
        seasonYear.isAcceptableOrUnknown(data['season_year']!, _seasonYearMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonYearMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
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
    if (data.containsKey('planned')) {
      context.handle(
        _plannedMeta,
        planned.isAcceptableOrUnknown(data['planned']!, _plannedMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedMeta);
    }
    if (data.containsKey('actual')) {
      context.handle(
        _actualMeta,
        actual.isAcceptableOrUnknown(data['actual']!, _actualMeta),
      );
    } else if (isInserting) {
      context.missing(_actualMeta);
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
  BaharCycleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BaharCycleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      bahar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar'],
      )!,
      seasonYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_year'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      planned: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned'],
      )!,
      actual: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $BaharCyclesTable createAlias(String alias) {
    return $BaharCyclesTable(attachedDatabase, alias);
  }
}

class BaharCycleRow extends DataClass implements Insertable<BaharCycleRow> {
  final String id;
  final String plotId;
  final String bahar;
  final int seasonYear;
  final String? templateId;
  final String status;
  final String planned;
  final String actual;
  final DateTime clientUpdatedAt;
  const BaharCycleRow({
    required this.id,
    required this.plotId,
    required this.bahar,
    required this.seasonYear,
    this.templateId,
    required this.status,
    required this.planned,
    required this.actual,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    map['bahar'] = Variable<String>(bahar);
    map['season_year'] = Variable<int>(seasonYear);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['status'] = Variable<String>(status);
    map['planned'] = Variable<String>(planned);
    map['actual'] = Variable<String>(actual);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  BaharCyclesCompanion toCompanion(bool nullToAbsent) {
    return BaharCyclesCompanion(
      id: Value(id),
      plotId: Value(plotId),
      bahar: Value(bahar),
      seasonYear: Value(seasonYear),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      status: Value(status),
      planned: Value(planned),
      actual: Value(actual),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory BaharCycleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BaharCycleRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      bahar: serializer.fromJson<String>(json['bahar']),
      seasonYear: serializer.fromJson<int>(json['seasonYear']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      status: serializer.fromJson<String>(json['status']),
      planned: serializer.fromJson<String>(json['planned']),
      actual: serializer.fromJson<String>(json['actual']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'bahar': serializer.toJson<String>(bahar),
      'seasonYear': serializer.toJson<int>(seasonYear),
      'templateId': serializer.toJson<String?>(templateId),
      'status': serializer.toJson<String>(status),
      'planned': serializer.toJson<String>(planned),
      'actual': serializer.toJson<String>(actual),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  BaharCycleRow copyWith({
    String? id,
    String? plotId,
    String? bahar,
    int? seasonYear,
    Value<String?> templateId = const Value.absent(),
    String? status,
    String? planned,
    String? actual,
    DateTime? clientUpdatedAt,
  }) => BaharCycleRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    bahar: bahar ?? this.bahar,
    seasonYear: seasonYear ?? this.seasonYear,
    templateId: templateId.present ? templateId.value : this.templateId,
    status: status ?? this.status,
    planned: planned ?? this.planned,
    actual: actual ?? this.actual,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  BaharCycleRow copyWithCompanion(BaharCyclesCompanion data) {
    return BaharCycleRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      bahar: data.bahar.present ? data.bahar.value : this.bahar,
      seasonYear: data.seasonYear.present
          ? data.seasonYear.value
          : this.seasonYear,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      status: data.status.present ? data.status.value : this.status,
      planned: data.planned.present ? data.planned.value : this.planned,
      actual: data.actual.present ? data.actual.value : this.actual,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BaharCycleRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('bahar: $bahar, ')
          ..write('seasonYear: $seasonYear, ')
          ..write('templateId: $templateId, ')
          ..write('status: $status, ')
          ..write('planned: $planned, ')
          ..write('actual: $actual, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    bahar,
    seasonYear,
    templateId,
    status,
    planned,
    actual,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaharCycleRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.bahar == this.bahar &&
          other.seasonYear == this.seasonYear &&
          other.templateId == this.templateId &&
          other.status == this.status &&
          other.planned == this.planned &&
          other.actual == this.actual &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class BaharCyclesCompanion extends UpdateCompanion<BaharCycleRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String> bahar;
  final Value<int> seasonYear;
  final Value<String?> templateId;
  final Value<String> status;
  final Value<String> planned;
  final Value<String> actual;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const BaharCyclesCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.bahar = const Value.absent(),
    this.seasonYear = const Value.absent(),
    this.templateId = const Value.absent(),
    this.status = const Value.absent(),
    this.planned = const Value.absent(),
    this.actual = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BaharCyclesCompanion.insert({
    required String id,
    required String plotId,
    required String bahar,
    required int seasonYear,
    this.templateId = const Value.absent(),
    required String status,
    required String planned,
    required String actual,
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       bahar = Value(bahar),
       seasonYear = Value(seasonYear),
       status = Value(status),
       planned = Value(planned),
       actual = Value(actual),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<BaharCycleRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? bahar,
    Expression<int>? seasonYear,
    Expression<String>? templateId,
    Expression<String>? status,
    Expression<String>? planned,
    Expression<String>? actual,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (bahar != null) 'bahar': bahar,
      if (seasonYear != null) 'season_year': seasonYear,
      if (templateId != null) 'template_id': templateId,
      if (status != null) 'status': status,
      if (planned != null) 'planned': planned,
      if (actual != null) 'actual': actual,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BaharCyclesCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String>? bahar,
    Value<int>? seasonYear,
    Value<String?>? templateId,
    Value<String>? status,
    Value<String>? planned,
    Value<String>? actual,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return BaharCyclesCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      bahar: bahar ?? this.bahar,
      seasonYear: seasonYear ?? this.seasonYear,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      planned: planned ?? this.planned,
      actual: actual ?? this.actual,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (bahar.present) {
      map['bahar'] = Variable<String>(bahar.value);
    }
    if (seasonYear.present) {
      map['season_year'] = Variable<int>(seasonYear.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (planned.present) {
      map['planned'] = Variable<String>(planned.value);
    }
    if (actual.present) {
      map['actual'] = Variable<String>(actual.value);
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
    return (StringBuffer('BaharCyclesCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('bahar: $bahar, ')
          ..write('seasonYear: $seasonYear, ')
          ..write('templateId: $templateId, ')
          ..write('status: $status, ')
          ..write('planned: $planned, ')
          ..write('actual: $actual, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spentOnMeta = const VerificationMeta(
    'spentOn',
  );
  @override
  late final GeneratedColumn<DateTime> spentOn = GeneratedColumn<DateTime>(
    'spent_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    plotId,
    baharCycleId,
    spentOn,
    category,
    amountPaise,
    note,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('spent_on')) {
      context.handle(
        _spentOnMeta,
        spentOn.isAcceptableOrUnknown(data['spent_on']!, _spentOnMeta),
      );
    } else if (isInserting) {
      context.missing(_spentOnMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      spentOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spent_on'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime spentOn;
  final String category;
  final int amountPaise;
  final String? note;
  final DateTime clientUpdatedAt;
  const ExpenseRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.spentOn,
    required this.category,
    required this.amountPaise,
    this.note,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['spent_on'] = Variable<DateTime>(spentOn);
    map['category'] = Variable<String>(category);
    map['amount_paise'] = Variable<int>(amountPaise);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      spentOn: Value(spentOn),
      category: Value(category),
      amountPaise: Value(amountPaise),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      spentOn: serializer.fromJson<DateTime>(json['spentOn']),
      category: serializer.fromJson<String>(json['category']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      note: serializer.fromJson<String?>(json['note']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'spentOn': serializer.toJson<DateTime>(spentOn),
      'category': serializer.toJson<String>(category),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'note': serializer.toJson<String?>(note),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    DateTime? spentOn,
    String? category,
    int? amountPaise,
    Value<String?> note = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => ExpenseRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    spentOn: spentOn ?? this.spentOn,
    category: category ?? this.category,
    amountPaise: amountPaise ?? this.amountPaise,
    note: note.present ? note.value : this.note,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      spentOn: data.spentOn.present ? data.spentOn.value : this.spentOn,
      category: data.category.present ? data.category.value : this.category,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      note: data.note.present ? data.note.value : this.note,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('spentOn: $spentOn, ')
          ..write('category: $category, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    spentOn,
    category,
    amountPaise,
    note,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.spentOn == this.spentOn &&
          other.category == this.category &&
          other.amountPaise == this.amountPaise &&
          other.note == this.note &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<DateTime> spentOn;
  final Value<String> category;
  final Value<int> amountPaise;
  final Value<String?> note;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.spentOn = const Value.absent(),
    this.category = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required DateTime spentOn,
    required String category,
    required int amountPaise,
    this.note = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       spentOn = Value(spentOn),
       category = Value(category),
       amountPaise = Value(amountPaise),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<DateTime>? spentOn,
    Expression<String>? category,
    Expression<int>? amountPaise,
    Expression<String>? note,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (spentOn != null) 'spent_on': spentOn,
      if (category != null) 'category': category,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (note != null) 'note': note,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<DateTime>? spentOn,
    Value<String>? category,
    Value<int>? amountPaise,
    Value<String?>? note,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      spentOn: spentOn ?? this.spentOn,
      category: category ?? this.category,
      amountPaise: amountPaise ?? this.amountPaise,
      note: note ?? this.note,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (spentOn.present) {
      map['spent_on'] = Variable<DateTime>(spentOn.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('spentOn: $spentOn, ')
          ..write('category: $category, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncomesTable extends Incomes with TableInfo<$IncomesTable, IncomeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soldOnMeta = const VerificationMeta('soldOn');
  @override
  late final GeneratedColumn<DateTime> soldOn = GeneratedColumn<DateTime>(
    'sold_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyerNameMeta = const VerificationMeta(
    'buyerName',
  );
  @override
  late final GeneratedColumn<String> buyerName = GeneratedColumn<String>(
    'buyer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityKgMeta = const VerificationMeta(
    'quantityKg',
  );
  @override
  late final GeneratedColumn<double> quantityKg = GeneratedColumn<double>(
    'quantity_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratePaisePerQuintalMeta =
      const VerificationMeta('ratePaisePerQuintal');
  @override
  late final GeneratedColumn<int> ratePaisePerQuintal = GeneratedColumn<int>(
    'rate_paise_per_quintal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deductionsPaiseMeta = const VerificationMeta(
    'deductionsPaise',
  );
  @override
  late final GeneratedColumn<int> deductionsPaise = GeneratedColumn<int>(
    'deductions_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidPaiseMeta = const VerificationMeta(
    'paidPaise',
  );
  @override
  late final GeneratedColumn<int> paidPaise = GeneratedColumn<int>(
    'paid_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidOnMeta = const VerificationMeta('paidOn');
  @override
  late final GeneratedColumn<DateTime> paidOn = GeneratedColumn<DateTime>(
    'paid_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    plotId,
    baharCycleId,
    soldOn,
    buyerName,
    grade,
    quantityKg,
    ratePaisePerQuintal,
    deductionsPaise,
    paymentStatus,
    paidPaise,
    paidOn,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('sold_on')) {
      context.handle(
        _soldOnMeta,
        soldOn.isAcceptableOrUnknown(data['sold_on']!, _soldOnMeta),
      );
    } else if (isInserting) {
      context.missing(_soldOnMeta);
    }
    if (data.containsKey('buyer_name')) {
      context.handle(
        _buyerNameMeta,
        buyerName.isAcceptableOrUnknown(data['buyer_name']!, _buyerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_buyerNameMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('quantity_kg')) {
      context.handle(
        _quantityKgMeta,
        quantityKg.isAcceptableOrUnknown(data['quantity_kg']!, _quantityKgMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityKgMeta);
    }
    if (data.containsKey('rate_paise_per_quintal')) {
      context.handle(
        _ratePaisePerQuintalMeta,
        ratePaisePerQuintal.isAcceptableOrUnknown(
          data['rate_paise_per_quintal']!,
          _ratePaisePerQuintalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ratePaisePerQuintalMeta);
    }
    if (data.containsKey('deductions_paise')) {
      context.handle(
        _deductionsPaiseMeta,
        deductionsPaise.isAcceptableOrUnknown(
          data['deductions_paise']!,
          _deductionsPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deductionsPaiseMeta);
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentStatusMeta);
    }
    if (data.containsKey('paid_paise')) {
      context.handle(
        _paidPaiseMeta,
        paidPaise.isAcceptableOrUnknown(data['paid_paise']!, _paidPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_paidPaiseMeta);
    }
    if (data.containsKey('paid_on')) {
      context.handle(
        _paidOnMeta,
        paidOn.isAcceptableOrUnknown(data['paid_on']!, _paidOnMeta),
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
  IncomeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      soldOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sold_on'],
      )!,
      buyerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buyer_name'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      ),
      quantityKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_kg'],
      )!,
      ratePaisePerQuintal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_paise_per_quintal'],
      )!,
      deductionsPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deductions_paise'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      paidPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_paise'],
      )!,
      paidOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_on'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $IncomesTable createAlias(String alias) {
    return $IncomesTable(attachedDatabase, alias);
  }
}

class IncomeRow extends DataClass implements Insertable<IncomeRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime soldOn;
  final String buyerName;
  final String? grade;
  final double quantityKg;
  final int ratePaisePerQuintal;
  final int deductionsPaise;
  final String paymentStatus;
  final int paidPaise;
  final DateTime? paidOn;
  final DateTime clientUpdatedAt;
  const IncomeRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.soldOn,
    required this.buyerName,
    this.grade,
    required this.quantityKg,
    required this.ratePaisePerQuintal,
    required this.deductionsPaise,
    required this.paymentStatus,
    required this.paidPaise,
    this.paidOn,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['sold_on'] = Variable<DateTime>(soldOn);
    map['buyer_name'] = Variable<String>(buyerName);
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<String>(grade);
    }
    map['quantity_kg'] = Variable<double>(quantityKg);
    map['rate_paise_per_quintal'] = Variable<int>(ratePaisePerQuintal);
    map['deductions_paise'] = Variable<int>(deductionsPaise);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['paid_paise'] = Variable<int>(paidPaise);
    if (!nullToAbsent || paidOn != null) {
      map['paid_on'] = Variable<DateTime>(paidOn);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  IncomesCompanion toCompanion(bool nullToAbsent) {
    return IncomesCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      soldOn: Value(soldOn),
      buyerName: Value(buyerName),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
      quantityKg: Value(quantityKg),
      ratePaisePerQuintal: Value(ratePaisePerQuintal),
      deductionsPaise: Value(deductionsPaise),
      paymentStatus: Value(paymentStatus),
      paidPaise: Value(paidPaise),
      paidOn: paidOn == null && nullToAbsent
          ? const Value.absent()
          : Value(paidOn),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory IncomeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      soldOn: serializer.fromJson<DateTime>(json['soldOn']),
      buyerName: serializer.fromJson<String>(json['buyerName']),
      grade: serializer.fromJson<String?>(json['grade']),
      quantityKg: serializer.fromJson<double>(json['quantityKg']),
      ratePaisePerQuintal: serializer.fromJson<int>(
        json['ratePaisePerQuintal'],
      ),
      deductionsPaise: serializer.fromJson<int>(json['deductionsPaise']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      paidPaise: serializer.fromJson<int>(json['paidPaise']),
      paidOn: serializer.fromJson<DateTime?>(json['paidOn']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'soldOn': serializer.toJson<DateTime>(soldOn),
      'buyerName': serializer.toJson<String>(buyerName),
      'grade': serializer.toJson<String?>(grade),
      'quantityKg': serializer.toJson<double>(quantityKg),
      'ratePaisePerQuintal': serializer.toJson<int>(ratePaisePerQuintal),
      'deductionsPaise': serializer.toJson<int>(deductionsPaise),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'paidPaise': serializer.toJson<int>(paidPaise),
      'paidOn': serializer.toJson<DateTime?>(paidOn),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  IncomeRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    DateTime? soldOn,
    String? buyerName,
    Value<String?> grade = const Value.absent(),
    double? quantityKg,
    int? ratePaisePerQuintal,
    int? deductionsPaise,
    String? paymentStatus,
    int? paidPaise,
    Value<DateTime?> paidOn = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => IncomeRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    soldOn: soldOn ?? this.soldOn,
    buyerName: buyerName ?? this.buyerName,
    grade: grade.present ? grade.value : this.grade,
    quantityKg: quantityKg ?? this.quantityKg,
    ratePaisePerQuintal: ratePaisePerQuintal ?? this.ratePaisePerQuintal,
    deductionsPaise: deductionsPaise ?? this.deductionsPaise,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paidPaise: paidPaise ?? this.paidPaise,
    paidOn: paidOn.present ? paidOn.value : this.paidOn,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  IncomeRow copyWithCompanion(IncomesCompanion data) {
    return IncomeRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      soldOn: data.soldOn.present ? data.soldOn.value : this.soldOn,
      buyerName: data.buyerName.present ? data.buyerName.value : this.buyerName,
      grade: data.grade.present ? data.grade.value : this.grade,
      quantityKg: data.quantityKg.present
          ? data.quantityKg.value
          : this.quantityKg,
      ratePaisePerQuintal: data.ratePaisePerQuintal.present
          ? data.ratePaisePerQuintal.value
          : this.ratePaisePerQuintal,
      deductionsPaise: data.deductionsPaise.present
          ? data.deductionsPaise.value
          : this.deductionsPaise,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      paidPaise: data.paidPaise.present ? data.paidPaise.value : this.paidPaise,
      paidOn: data.paidOn.present ? data.paidOn.value : this.paidOn,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('soldOn: $soldOn, ')
          ..write('buyerName: $buyerName, ')
          ..write('grade: $grade, ')
          ..write('quantityKg: $quantityKg, ')
          ..write('ratePaisePerQuintal: $ratePaisePerQuintal, ')
          ..write('deductionsPaise: $deductionsPaise, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paidPaise: $paidPaise, ')
          ..write('paidOn: $paidOn, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    soldOn,
    buyerName,
    grade,
    quantityKg,
    ratePaisePerQuintal,
    deductionsPaise,
    paymentStatus,
    paidPaise,
    paidOn,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.soldOn == this.soldOn &&
          other.buyerName == this.buyerName &&
          other.grade == this.grade &&
          other.quantityKg == this.quantityKg &&
          other.ratePaisePerQuintal == this.ratePaisePerQuintal &&
          other.deductionsPaise == this.deductionsPaise &&
          other.paymentStatus == this.paymentStatus &&
          other.paidPaise == this.paidPaise &&
          other.paidOn == this.paidOn &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class IncomesCompanion extends UpdateCompanion<IncomeRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<DateTime> soldOn;
  final Value<String> buyerName;
  final Value<String?> grade;
  final Value<double> quantityKg;
  final Value<int> ratePaisePerQuintal;
  final Value<int> deductionsPaise;
  final Value<String> paymentStatus;
  final Value<int> paidPaise;
  final Value<DateTime?> paidOn;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const IncomesCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.soldOn = const Value.absent(),
    this.buyerName = const Value.absent(),
    this.grade = const Value.absent(),
    this.quantityKg = const Value.absent(),
    this.ratePaisePerQuintal = const Value.absent(),
    this.deductionsPaise = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.paidPaise = const Value.absent(),
    this.paidOn = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncomesCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required DateTime soldOn,
    required String buyerName,
    this.grade = const Value.absent(),
    required double quantityKg,
    required int ratePaisePerQuintal,
    required int deductionsPaise,
    required String paymentStatus,
    required int paidPaise,
    this.paidOn = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       soldOn = Value(soldOn),
       buyerName = Value(buyerName),
       quantityKg = Value(quantityKg),
       ratePaisePerQuintal = Value(ratePaisePerQuintal),
       deductionsPaise = Value(deductionsPaise),
       paymentStatus = Value(paymentStatus),
       paidPaise = Value(paidPaise),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<IncomeRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<DateTime>? soldOn,
    Expression<String>? buyerName,
    Expression<String>? grade,
    Expression<double>? quantityKg,
    Expression<int>? ratePaisePerQuintal,
    Expression<int>? deductionsPaise,
    Expression<String>? paymentStatus,
    Expression<int>? paidPaise,
    Expression<DateTime>? paidOn,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (soldOn != null) 'sold_on': soldOn,
      if (buyerName != null) 'buyer_name': buyerName,
      if (grade != null) 'grade': grade,
      if (quantityKg != null) 'quantity_kg': quantityKg,
      if (ratePaisePerQuintal != null)
        'rate_paise_per_quintal': ratePaisePerQuintal,
      if (deductionsPaise != null) 'deductions_paise': deductionsPaise,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paidPaise != null) 'paid_paise': paidPaise,
      if (paidOn != null) 'paid_on': paidOn,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncomesCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<DateTime>? soldOn,
    Value<String>? buyerName,
    Value<String?>? grade,
    Value<double>? quantityKg,
    Value<int>? ratePaisePerQuintal,
    Value<int>? deductionsPaise,
    Value<String>? paymentStatus,
    Value<int>? paidPaise,
    Value<DateTime?>? paidOn,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return IncomesCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      soldOn: soldOn ?? this.soldOn,
      buyerName: buyerName ?? this.buyerName,
      grade: grade ?? this.grade,
      quantityKg: quantityKg ?? this.quantityKg,
      ratePaisePerQuintal: ratePaisePerQuintal ?? this.ratePaisePerQuintal,
      deductionsPaise: deductionsPaise ?? this.deductionsPaise,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidPaise: paidPaise ?? this.paidPaise,
      paidOn: paidOn ?? this.paidOn,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (soldOn.present) {
      map['sold_on'] = Variable<DateTime>(soldOn.value);
    }
    if (buyerName.present) {
      map['buyer_name'] = Variable<String>(buyerName.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (quantityKg.present) {
      map['quantity_kg'] = Variable<double>(quantityKg.value);
    }
    if (ratePaisePerQuintal.present) {
      map['rate_paise_per_quintal'] = Variable<int>(ratePaisePerQuintal.value);
    }
    if (deductionsPaise.present) {
      map['deductions_paise'] = Variable<int>(deductionsPaise.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (paidPaise.present) {
      map['paid_paise'] = Variable<int>(paidPaise.value);
    }
    if (paidOn.present) {
      map['paid_on'] = Variable<DateTime>(paidOn.value);
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
    return (StringBuffer('IncomesCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('soldOn: $soldOn, ')
          ..write('buyerName: $buyerName, ')
          ..write('grade: $grade, ')
          ..write('quantityKg: $quantityKg, ')
          ..write('ratePaisePerQuintal: $ratePaisePerQuintal, ')
          ..write('deductionsPaise: $deductionsPaise, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paidPaise: $paidPaise, ')
          ..write('paidOn: $paidOn, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SprayRecordsTable extends SprayRecords
    with TableInfo<$SprayRecordsTable, SprayRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SprayRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sprayedOnMeta = const VerificationMeta(
    'sprayedOn',
  );
  @override
  late final GeneratedColumn<DateTime> sprayedOn = GeneratedColumn<DateTime>(
    'sprayed_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeIngredientMeta = const VerificationMeta(
    'activeIngredient',
  );
  @override
  late final GeneratedColumn<String> activeIngredient = GeneratedColumn<String>(
    'active_ingredient',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterLitresMeta = const VerificationMeta(
    'waterLitres',
  );
  @override
  late final GeneratedColumn<double> waterLitres = GeneratedColumn<double>(
    'water_litres',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaAcresMeta = const VerificationMeta(
    'areaAcres',
  );
  @override
  late final GeneratedColumn<double> areaAcres = GeneratedColumn<double>(
    'area_acres',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costPaiseMeta = const VerificationMeta(
    'costPaise',
  );
  @override
  late final GeneratedColumn<int> costPaise = GeneratedColumn<int>(
    'cost_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorMeta = const VerificationMeta(
    'operator',
  );
  @override
  late final GeneratedColumn<String> operator = GeneratedColumn<String>(
    'operator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phiDaysMeta = const VerificationMeta(
    'phiDays',
  );
  @override
  late final GeneratedColumn<int> phiDays = GeneratedColumn<int>(
    'phi_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
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
    plotId,
    baharCycleId,
    sprayedOn,
    productName,
    activeIngredient,
    dose,
    waterLitres,
    areaAcres,
    costPaise,
    operator,
    phiDays,
    target,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spray_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SprayRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('sprayed_on')) {
      context.handle(
        _sprayedOnMeta,
        sprayedOn.isAcceptableOrUnknown(data['sprayed_on']!, _sprayedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_sprayedOnMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('active_ingredient')) {
      context.handle(
        _activeIngredientMeta,
        activeIngredient.isAcceptableOrUnknown(
          data['active_ingredient']!,
          _activeIngredientMeta,
        ),
      );
    }
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    }
    if (data.containsKey('water_litres')) {
      context.handle(
        _waterLitresMeta,
        waterLitres.isAcceptableOrUnknown(
          data['water_litres']!,
          _waterLitresMeta,
        ),
      );
    }
    if (data.containsKey('area_acres')) {
      context.handle(
        _areaAcresMeta,
        areaAcres.isAcceptableOrUnknown(data['area_acres']!, _areaAcresMeta),
      );
    }
    if (data.containsKey('cost_paise')) {
      context.handle(
        _costPaiseMeta,
        costPaise.isAcceptableOrUnknown(data['cost_paise']!, _costPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_costPaiseMeta);
    }
    if (data.containsKey('operator')) {
      context.handle(
        _operatorMeta,
        operator.isAcceptableOrUnknown(data['operator']!, _operatorMeta),
      );
    }
    if (data.containsKey('phi_days')) {
      context.handle(
        _phiDaysMeta,
        phiDays.isAcceptableOrUnknown(data['phi_days']!, _phiDaysMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
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
  SprayRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SprayRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      sprayedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sprayed_on'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      activeIngredient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_ingredient'],
      ),
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      ),
      waterLitres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_litres'],
      ),
      areaAcres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}area_acres'],
      ),
      costPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_paise'],
      )!,
      operator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator'],
      ),
      phiDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phi_days'],
      ),
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $SprayRecordsTable createAlias(String alias) {
    return $SprayRecordsTable(attachedDatabase, alias);
  }
}

class SprayRecordRow extends DataClass implements Insertable<SprayRecordRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime sprayedOn;
  final String productName;
  final String? activeIngredient;
  final String? dose;
  final double? waterLitres;
  final double? areaAcres;
  final int costPaise;
  final String? operator;
  final int? phiDays;
  final String? target;
  final DateTime clientUpdatedAt;
  const SprayRecordRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.sprayedOn,
    required this.productName,
    this.activeIngredient,
    this.dose,
    this.waterLitres,
    this.areaAcres,
    required this.costPaise,
    this.operator,
    this.phiDays,
    this.target,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['sprayed_on'] = Variable<DateTime>(sprayedOn);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || activeIngredient != null) {
      map['active_ingredient'] = Variable<String>(activeIngredient);
    }
    if (!nullToAbsent || dose != null) {
      map['dose'] = Variable<String>(dose);
    }
    if (!nullToAbsent || waterLitres != null) {
      map['water_litres'] = Variable<double>(waterLitres);
    }
    if (!nullToAbsent || areaAcres != null) {
      map['area_acres'] = Variable<double>(areaAcres);
    }
    map['cost_paise'] = Variable<int>(costPaise);
    if (!nullToAbsent || operator != null) {
      map['operator'] = Variable<String>(operator);
    }
    if (!nullToAbsent || phiDays != null) {
      map['phi_days'] = Variable<int>(phiDays);
    }
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<String>(target);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  SprayRecordsCompanion toCompanion(bool nullToAbsent) {
    return SprayRecordsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      sprayedOn: Value(sprayedOn),
      productName: Value(productName),
      activeIngredient: activeIngredient == null && nullToAbsent
          ? const Value.absent()
          : Value(activeIngredient),
      dose: dose == null && nullToAbsent ? const Value.absent() : Value(dose),
      waterLitres: waterLitres == null && nullToAbsent
          ? const Value.absent()
          : Value(waterLitres),
      areaAcres: areaAcres == null && nullToAbsent
          ? const Value.absent()
          : Value(areaAcres),
      costPaise: Value(costPaise),
      operator: operator == null && nullToAbsent
          ? const Value.absent()
          : Value(operator),
      phiDays: phiDays == null && nullToAbsent
          ? const Value.absent()
          : Value(phiDays),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory SprayRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SprayRecordRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      sprayedOn: serializer.fromJson<DateTime>(json['sprayedOn']),
      productName: serializer.fromJson<String>(json['productName']),
      activeIngredient: serializer.fromJson<String?>(json['activeIngredient']),
      dose: serializer.fromJson<String?>(json['dose']),
      waterLitres: serializer.fromJson<double?>(json['waterLitres']),
      areaAcres: serializer.fromJson<double?>(json['areaAcres']),
      costPaise: serializer.fromJson<int>(json['costPaise']),
      operator: serializer.fromJson<String?>(json['operator']),
      phiDays: serializer.fromJson<int?>(json['phiDays']),
      target: serializer.fromJson<String?>(json['target']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'sprayedOn': serializer.toJson<DateTime>(sprayedOn),
      'productName': serializer.toJson<String>(productName),
      'activeIngredient': serializer.toJson<String?>(activeIngredient),
      'dose': serializer.toJson<String?>(dose),
      'waterLitres': serializer.toJson<double?>(waterLitres),
      'areaAcres': serializer.toJson<double?>(areaAcres),
      'costPaise': serializer.toJson<int>(costPaise),
      'operator': serializer.toJson<String?>(operator),
      'phiDays': serializer.toJson<int?>(phiDays),
      'target': serializer.toJson<String?>(target),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  SprayRecordRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    DateTime? sprayedOn,
    String? productName,
    Value<String?> activeIngredient = const Value.absent(),
    Value<String?> dose = const Value.absent(),
    Value<double?> waterLitres = const Value.absent(),
    Value<double?> areaAcres = const Value.absent(),
    int? costPaise,
    Value<String?> operator = const Value.absent(),
    Value<int?> phiDays = const Value.absent(),
    Value<String?> target = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => SprayRecordRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    sprayedOn: sprayedOn ?? this.sprayedOn,
    productName: productName ?? this.productName,
    activeIngredient: activeIngredient.present
        ? activeIngredient.value
        : this.activeIngredient,
    dose: dose.present ? dose.value : this.dose,
    waterLitres: waterLitres.present ? waterLitres.value : this.waterLitres,
    areaAcres: areaAcres.present ? areaAcres.value : this.areaAcres,
    costPaise: costPaise ?? this.costPaise,
    operator: operator.present ? operator.value : this.operator,
    phiDays: phiDays.present ? phiDays.value : this.phiDays,
    target: target.present ? target.value : this.target,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  SprayRecordRow copyWithCompanion(SprayRecordsCompanion data) {
    return SprayRecordRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      sprayedOn: data.sprayedOn.present ? data.sprayedOn.value : this.sprayedOn,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      activeIngredient: data.activeIngredient.present
          ? data.activeIngredient.value
          : this.activeIngredient,
      dose: data.dose.present ? data.dose.value : this.dose,
      waterLitres: data.waterLitres.present
          ? data.waterLitres.value
          : this.waterLitres,
      areaAcres: data.areaAcres.present ? data.areaAcres.value : this.areaAcres,
      costPaise: data.costPaise.present ? data.costPaise.value : this.costPaise,
      operator: data.operator.present ? data.operator.value : this.operator,
      phiDays: data.phiDays.present ? data.phiDays.value : this.phiDays,
      target: data.target.present ? data.target.value : this.target,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SprayRecordRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('sprayedOn: $sprayedOn, ')
          ..write('productName: $productName, ')
          ..write('activeIngredient: $activeIngredient, ')
          ..write('dose: $dose, ')
          ..write('waterLitres: $waterLitres, ')
          ..write('areaAcres: $areaAcres, ')
          ..write('costPaise: $costPaise, ')
          ..write('operator: $operator, ')
          ..write('phiDays: $phiDays, ')
          ..write('target: $target, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    sprayedOn,
    productName,
    activeIngredient,
    dose,
    waterLitres,
    areaAcres,
    costPaise,
    operator,
    phiDays,
    target,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SprayRecordRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.sprayedOn == this.sprayedOn &&
          other.productName == this.productName &&
          other.activeIngredient == this.activeIngredient &&
          other.dose == this.dose &&
          other.waterLitres == this.waterLitres &&
          other.areaAcres == this.areaAcres &&
          other.costPaise == this.costPaise &&
          other.operator == this.operator &&
          other.phiDays == this.phiDays &&
          other.target == this.target &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class SprayRecordsCompanion extends UpdateCompanion<SprayRecordRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<DateTime> sprayedOn;
  final Value<String> productName;
  final Value<String?> activeIngredient;
  final Value<String?> dose;
  final Value<double?> waterLitres;
  final Value<double?> areaAcres;
  final Value<int> costPaise;
  final Value<String?> operator;
  final Value<int?> phiDays;
  final Value<String?> target;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const SprayRecordsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.sprayedOn = const Value.absent(),
    this.productName = const Value.absent(),
    this.activeIngredient = const Value.absent(),
    this.dose = const Value.absent(),
    this.waterLitres = const Value.absent(),
    this.areaAcres = const Value.absent(),
    this.costPaise = const Value.absent(),
    this.operator = const Value.absent(),
    this.phiDays = const Value.absent(),
    this.target = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SprayRecordsCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required DateTime sprayedOn,
    required String productName,
    this.activeIngredient = const Value.absent(),
    this.dose = const Value.absent(),
    this.waterLitres = const Value.absent(),
    this.areaAcres = const Value.absent(),
    required int costPaise,
    this.operator = const Value.absent(),
    this.phiDays = const Value.absent(),
    this.target = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       sprayedOn = Value(sprayedOn),
       productName = Value(productName),
       costPaise = Value(costPaise),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<SprayRecordRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<DateTime>? sprayedOn,
    Expression<String>? productName,
    Expression<String>? activeIngredient,
    Expression<String>? dose,
    Expression<double>? waterLitres,
    Expression<double>? areaAcres,
    Expression<int>? costPaise,
    Expression<String>? operator,
    Expression<int>? phiDays,
    Expression<String>? target,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (sprayedOn != null) 'sprayed_on': sprayedOn,
      if (productName != null) 'product_name': productName,
      if (activeIngredient != null) 'active_ingredient': activeIngredient,
      if (dose != null) 'dose': dose,
      if (waterLitres != null) 'water_litres': waterLitres,
      if (areaAcres != null) 'area_acres': areaAcres,
      if (costPaise != null) 'cost_paise': costPaise,
      if (operator != null) 'operator': operator,
      if (phiDays != null) 'phi_days': phiDays,
      if (target != null) 'target': target,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SprayRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<DateTime>? sprayedOn,
    Value<String>? productName,
    Value<String?>? activeIngredient,
    Value<String?>? dose,
    Value<double?>? waterLitres,
    Value<double?>? areaAcres,
    Value<int>? costPaise,
    Value<String?>? operator,
    Value<int?>? phiDays,
    Value<String?>? target,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return SprayRecordsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      sprayedOn: sprayedOn ?? this.sprayedOn,
      productName: productName ?? this.productName,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      dose: dose ?? this.dose,
      waterLitres: waterLitres ?? this.waterLitres,
      areaAcres: areaAcres ?? this.areaAcres,
      costPaise: costPaise ?? this.costPaise,
      operator: operator ?? this.operator,
      phiDays: phiDays ?? this.phiDays,
      target: target ?? this.target,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (sprayedOn.present) {
      map['sprayed_on'] = Variable<DateTime>(sprayedOn.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (activeIngredient.present) {
      map['active_ingredient'] = Variable<String>(activeIngredient.value);
    }
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (waterLitres.present) {
      map['water_litres'] = Variable<double>(waterLitres.value);
    }
    if (areaAcres.present) {
      map['area_acres'] = Variable<double>(areaAcres.value);
    }
    if (costPaise.present) {
      map['cost_paise'] = Variable<int>(costPaise.value);
    }
    if (operator.present) {
      map['operator'] = Variable<String>(operator.value);
    }
    if (phiDays.present) {
      map['phi_days'] = Variable<int>(phiDays.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
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
    return (StringBuffer('SprayRecordsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('sprayedOn: $sprayedOn, ')
          ..write('productName: $productName, ')
          ..write('activeIngredient: $activeIngredient, ')
          ..write('dose: $dose, ')
          ..write('waterLitres: $waterLitres, ')
          ..write('areaAcres: $areaAcres, ')
          ..write('costPaise: $costPaise, ')
          ..write('operator: $operator, ')
          ..write('phiDays: $phiDays, ')
          ..write('target: $target, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InputRecordsTable extends InputRecords
    with TableInfo<$InputRecordsTable, InputRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InputRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliedOnMeta = const VerificationMeta(
    'appliedOn',
  );
  @override
  late final GeneratedColumn<DateTime> appliedOn = GeneratedColumn<DateTime>(
    'applied_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costPaiseMeta = const VerificationMeta(
    'costPaise',
  );
  @override
  late final GeneratedColumn<int> costPaise = GeneratedColumn<int>(
    'cost_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    plotId,
    baharCycleId,
    appliedOn,
    kind,
    productName,
    quantity,
    unit,
    costPaise,
    note,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'input_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<InputRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('applied_on')) {
      context.handle(
        _appliedOnMeta,
        appliedOn.isAcceptableOrUnknown(data['applied_on']!, _appliedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedOnMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('cost_paise')) {
      context.handle(
        _costPaiseMeta,
        costPaise.isAcceptableOrUnknown(data['cost_paise']!, _costPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_costPaiseMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  InputRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InputRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      appliedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_on'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      costPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_paise'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $InputRecordsTable createAlias(String alias) {
    return $InputRecordsTable(attachedDatabase, alias);
  }
}

class InputRecordRow extends DataClass implements Insertable<InputRecordRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime appliedOn;
  final String kind;
  final String productName;
  final double? quantity;
  final String? unit;
  final int costPaise;
  final String? note;
  final DateTime clientUpdatedAt;
  const InputRecordRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.appliedOn,
    required this.kind,
    required this.productName,
    this.quantity,
    this.unit,
    required this.costPaise,
    this.note,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['applied_on'] = Variable<DateTime>(appliedOn);
    map['kind'] = Variable<String>(kind);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['cost_paise'] = Variable<int>(costPaise);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  InputRecordsCompanion toCompanion(bool nullToAbsent) {
    return InputRecordsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      appliedOn: Value(appliedOn),
      kind: Value(kind),
      productName: Value(productName),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      costPaise: Value(costPaise),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory InputRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InputRecordRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      appliedOn: serializer.fromJson<DateTime>(json['appliedOn']),
      kind: serializer.fromJson<String>(json['kind']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      costPaise: serializer.fromJson<int>(json['costPaise']),
      note: serializer.fromJson<String?>(json['note']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'appliedOn': serializer.toJson<DateTime>(appliedOn),
      'kind': serializer.toJson<String>(kind),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'costPaise': serializer.toJson<int>(costPaise),
      'note': serializer.toJson<String?>(note),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  InputRecordRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    DateTime? appliedOn,
    String? kind,
    String? productName,
    Value<double?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? costPaise,
    Value<String?> note = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => InputRecordRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    appliedOn: appliedOn ?? this.appliedOn,
    kind: kind ?? this.kind,
    productName: productName ?? this.productName,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    costPaise: costPaise ?? this.costPaise,
    note: note.present ? note.value : this.note,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  InputRecordRow copyWithCompanion(InputRecordsCompanion data) {
    return InputRecordRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      appliedOn: data.appliedOn.present ? data.appliedOn.value : this.appliedOn,
      kind: data.kind.present ? data.kind.value : this.kind,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      costPaise: data.costPaise.present ? data.costPaise.value : this.costPaise,
      note: data.note.present ? data.note.value : this.note,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InputRecordRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('appliedOn: $appliedOn, ')
          ..write('kind: $kind, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('costPaise: $costPaise, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    appliedOn,
    kind,
    productName,
    quantity,
    unit,
    costPaise,
    note,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InputRecordRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.appliedOn == this.appliedOn &&
          other.kind == this.kind &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.costPaise == this.costPaise &&
          other.note == this.note &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class InputRecordsCompanion extends UpdateCompanion<InputRecordRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<DateTime> appliedOn;
  final Value<String> kind;
  final Value<String> productName;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<int> costPaise;
  final Value<String?> note;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const InputRecordsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.appliedOn = const Value.absent(),
    this.kind = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.costPaise = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InputRecordsCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required DateTime appliedOn,
    required String kind,
    required String productName,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    required int costPaise,
    this.note = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       appliedOn = Value(appliedOn),
       kind = Value(kind),
       productName = Value(productName),
       costPaise = Value(costPaise),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<InputRecordRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<DateTime>? appliedOn,
    Expression<String>? kind,
    Expression<String>? productName,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<int>? costPaise,
    Expression<String>? note,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (appliedOn != null) 'applied_on': appliedOn,
      if (kind != null) 'kind': kind,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (costPaise != null) 'cost_paise': costPaise,
      if (note != null) 'note': note,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InputRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<DateTime>? appliedOn,
    Value<String>? kind,
    Value<String>? productName,
    Value<double?>? quantity,
    Value<String?>? unit,
    Value<int>? costPaise,
    Value<String?>? note,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return InputRecordsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      appliedOn: appliedOn ?? this.appliedOn,
      kind: kind ?? this.kind,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      costPaise: costPaise ?? this.costPaise,
      note: note ?? this.note,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (appliedOn.present) {
      map['applied_on'] = Variable<DateTime>(appliedOn.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (costPaise.present) {
      map['cost_paise'] = Variable<int>(costPaise.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('InputRecordsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('appliedOn: $appliedOn, ')
          ..write('kind: $kind, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('costPaise: $costPaise, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IrrigationRecordsTable extends IrrigationRecords
    with TableInfo<$IrrigationRecordsTable, IrrigationRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IrrigationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _irrigatedOnMeta = const VerificationMeta(
    'irrigatedOn',
  );
  @override
  late final GeneratedColumn<DateTime> irrigatedOn = GeneratedColumn<DateTime>(
    'irrigated_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationHoursMeta = const VerificationMeta(
    'durationHours',
  );
  @override
  late final GeneratedColumn<double> durationHours = GeneratedColumn<double>(
    'duration_hours',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterLitresMeta = const VerificationMeta(
    'waterLitres',
  );
  @override
  late final GeneratedColumn<double> waterLitres = GeneratedColumn<double>(
    'water_litres',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    plotId,
    baharCycleId,
    irrigatedOn,
    durationHours,
    waterLitres,
    note,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'irrigation_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<IrrigationRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('irrigated_on')) {
      context.handle(
        _irrigatedOnMeta,
        irrigatedOn.isAcceptableOrUnknown(
          data['irrigated_on']!,
          _irrigatedOnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_irrigatedOnMeta);
    }
    if (data.containsKey('duration_hours')) {
      context.handle(
        _durationHoursMeta,
        durationHours.isAcceptableOrUnknown(
          data['duration_hours']!,
          _durationHoursMeta,
        ),
      );
    }
    if (data.containsKey('water_litres')) {
      context.handle(
        _waterLitresMeta,
        waterLitres.isAcceptableOrUnknown(
          data['water_litres']!,
          _waterLitresMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  IrrigationRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IrrigationRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      irrigatedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}irrigated_on'],
      )!,
      durationHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_hours'],
      ),
      waterLitres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_litres'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $IrrigationRecordsTable createAlias(String alias) {
    return $IrrigationRecordsTable(attachedDatabase, alias);
  }
}

class IrrigationRecordRow extends DataClass
    implements Insertable<IrrigationRecordRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime irrigatedOn;
  final double? durationHours;
  final double? waterLitres;
  final String? note;
  final DateTime clientUpdatedAt;
  const IrrigationRecordRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.irrigatedOn,
    this.durationHours,
    this.waterLitres,
    this.note,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['irrigated_on'] = Variable<DateTime>(irrigatedOn);
    if (!nullToAbsent || durationHours != null) {
      map['duration_hours'] = Variable<double>(durationHours);
    }
    if (!nullToAbsent || waterLitres != null) {
      map['water_litres'] = Variable<double>(waterLitres);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  IrrigationRecordsCompanion toCompanion(bool nullToAbsent) {
    return IrrigationRecordsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      irrigatedOn: Value(irrigatedOn),
      durationHours: durationHours == null && nullToAbsent
          ? const Value.absent()
          : Value(durationHours),
      waterLitres: waterLitres == null && nullToAbsent
          ? const Value.absent()
          : Value(waterLitres),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory IrrigationRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IrrigationRecordRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      irrigatedOn: serializer.fromJson<DateTime>(json['irrigatedOn']),
      durationHours: serializer.fromJson<double?>(json['durationHours']),
      waterLitres: serializer.fromJson<double?>(json['waterLitres']),
      note: serializer.fromJson<String?>(json['note']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'irrigatedOn': serializer.toJson<DateTime>(irrigatedOn),
      'durationHours': serializer.toJson<double?>(durationHours),
      'waterLitres': serializer.toJson<double?>(waterLitres),
      'note': serializer.toJson<String?>(note),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  IrrigationRecordRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    DateTime? irrigatedOn,
    Value<double?> durationHours = const Value.absent(),
    Value<double?> waterLitres = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => IrrigationRecordRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    irrigatedOn: irrigatedOn ?? this.irrigatedOn,
    durationHours: durationHours.present
        ? durationHours.value
        : this.durationHours,
    waterLitres: waterLitres.present ? waterLitres.value : this.waterLitres,
    note: note.present ? note.value : this.note,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  IrrigationRecordRow copyWithCompanion(IrrigationRecordsCompanion data) {
    return IrrigationRecordRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      irrigatedOn: data.irrigatedOn.present
          ? data.irrigatedOn.value
          : this.irrigatedOn,
      durationHours: data.durationHours.present
          ? data.durationHours.value
          : this.durationHours,
      waterLitres: data.waterLitres.present
          ? data.waterLitres.value
          : this.waterLitres,
      note: data.note.present ? data.note.value : this.note,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IrrigationRecordRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('irrigatedOn: $irrigatedOn, ')
          ..write('durationHours: $durationHours, ')
          ..write('waterLitres: $waterLitres, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    irrigatedOn,
    durationHours,
    waterLitres,
    note,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IrrigationRecordRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.irrigatedOn == this.irrigatedOn &&
          other.durationHours == this.durationHours &&
          other.waterLitres == this.waterLitres &&
          other.note == this.note &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class IrrigationRecordsCompanion extends UpdateCompanion<IrrigationRecordRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<DateTime> irrigatedOn;
  final Value<double?> durationHours;
  final Value<double?> waterLitres;
  final Value<String?> note;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const IrrigationRecordsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.irrigatedOn = const Value.absent(),
    this.durationHours = const Value.absent(),
    this.waterLitres = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IrrigationRecordsCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required DateTime irrigatedOn,
    this.durationHours = const Value.absent(),
    this.waterLitres = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       irrigatedOn = Value(irrigatedOn),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<IrrigationRecordRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<DateTime>? irrigatedOn,
    Expression<double>? durationHours,
    Expression<double>? waterLitres,
    Expression<String>? note,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (irrigatedOn != null) 'irrigated_on': irrigatedOn,
      if (durationHours != null) 'duration_hours': durationHours,
      if (waterLitres != null) 'water_litres': waterLitres,
      if (note != null) 'note': note,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IrrigationRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<DateTime>? irrigatedOn,
    Value<double?>? durationHours,
    Value<double?>? waterLitres,
    Value<String?>? note,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return IrrigationRecordsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      irrigatedOn: irrigatedOn ?? this.irrigatedOn,
      durationHours: durationHours ?? this.durationHours,
      waterLitres: waterLitres ?? this.waterLitres,
      note: note ?? this.note,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (irrigatedOn.present) {
      map['irrigated_on'] = Variable<DateTime>(irrigatedOn.value);
    }
    if (durationHours.present) {
      map['duration_hours'] = Variable<double>(durationHours.value);
    }
    if (waterLitres.present) {
      map['water_litres'] = Variable<double>(waterLitres.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('IrrigationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('irrigatedOn: $irrigatedOn, ')
          ..write('durationHours: $durationHours, ')
          ..write('waterLitres: $waterLitres, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HarvestRecordsTable extends HarvestRecords
    with TableInfo<$HarvestRecordsTable, HarvestRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HarvestRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _harvestedOnMeta = const VerificationMeta(
    'harvestedOn',
  );
  @override
  late final GeneratedColumn<DateTime> harvestedOn = GeneratedColumn<DateTime>(
    'harvested_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeClassMeta = const VerificationMeta(
    'sizeClass',
  );
  @override
  late final GeneratedColumn<String> sizeClass = GeneratedColumn<String>(
    'size_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityKgMeta = const VerificationMeta(
    'quantityKg',
  );
  @override
  late final GeneratedColumn<double> quantityKg = GeneratedColumn<double>(
    'quantity_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    plotId,
    baharCycleId,
    harvestedOn,
    grade,
    sizeClass,
    quantityKg,
    note,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'harvest_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<HarvestRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('harvested_on')) {
      context.handle(
        _harvestedOnMeta,
        harvestedOn.isAcceptableOrUnknown(
          data['harvested_on']!,
          _harvestedOnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_harvestedOnMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('size_class')) {
      context.handle(
        _sizeClassMeta,
        sizeClass.isAcceptableOrUnknown(data['size_class']!, _sizeClassMeta),
      );
    }
    if (data.containsKey('quantity_kg')) {
      context.handle(
        _quantityKgMeta,
        quantityKg.isAcceptableOrUnknown(data['quantity_kg']!, _quantityKgMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityKgMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  HarvestRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HarvestRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      harvestedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}harvested_on'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      ),
      sizeClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size_class'],
      ),
      quantityKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_kg'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $HarvestRecordsTable createAlias(String alias) {
    return $HarvestRecordsTable(attachedDatabase, alias);
  }
}

class HarvestRecordRow extends DataClass
    implements Insertable<HarvestRecordRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime harvestedOn;
  final String? grade;
  final String? sizeClass;
  final double quantityKg;
  final String? note;
  final DateTime clientUpdatedAt;
  const HarvestRecordRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.harvestedOn,
    this.grade,
    this.sizeClass,
    required this.quantityKg,
    this.note,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['harvested_on'] = Variable<DateTime>(harvestedOn);
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<String>(grade);
    }
    if (!nullToAbsent || sizeClass != null) {
      map['size_class'] = Variable<String>(sizeClass);
    }
    map['quantity_kg'] = Variable<double>(quantityKg);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  HarvestRecordsCompanion toCompanion(bool nullToAbsent) {
    return HarvestRecordsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      harvestedOn: Value(harvestedOn),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
      sizeClass: sizeClass == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeClass),
      quantityKg: Value(quantityKg),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory HarvestRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HarvestRecordRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      harvestedOn: serializer.fromJson<DateTime>(json['harvestedOn']),
      grade: serializer.fromJson<String?>(json['grade']),
      sizeClass: serializer.fromJson<String?>(json['sizeClass']),
      quantityKg: serializer.fromJson<double>(json['quantityKg']),
      note: serializer.fromJson<String?>(json['note']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'harvestedOn': serializer.toJson<DateTime>(harvestedOn),
      'grade': serializer.toJson<String?>(grade),
      'sizeClass': serializer.toJson<String?>(sizeClass),
      'quantityKg': serializer.toJson<double>(quantityKg),
      'note': serializer.toJson<String?>(note),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  HarvestRecordRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    DateTime? harvestedOn,
    Value<String?> grade = const Value.absent(),
    Value<String?> sizeClass = const Value.absent(),
    double? quantityKg,
    Value<String?> note = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => HarvestRecordRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    harvestedOn: harvestedOn ?? this.harvestedOn,
    grade: grade.present ? grade.value : this.grade,
    sizeClass: sizeClass.present ? sizeClass.value : this.sizeClass,
    quantityKg: quantityKg ?? this.quantityKg,
    note: note.present ? note.value : this.note,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  HarvestRecordRow copyWithCompanion(HarvestRecordsCompanion data) {
    return HarvestRecordRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      harvestedOn: data.harvestedOn.present
          ? data.harvestedOn.value
          : this.harvestedOn,
      grade: data.grade.present ? data.grade.value : this.grade,
      sizeClass: data.sizeClass.present ? data.sizeClass.value : this.sizeClass,
      quantityKg: data.quantityKg.present
          ? data.quantityKg.value
          : this.quantityKg,
      note: data.note.present ? data.note.value : this.note,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HarvestRecordRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('harvestedOn: $harvestedOn, ')
          ..write('grade: $grade, ')
          ..write('sizeClass: $sizeClass, ')
          ..write('quantityKg: $quantityKg, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    harvestedOn,
    grade,
    sizeClass,
    quantityKg,
    note,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HarvestRecordRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.harvestedOn == this.harvestedOn &&
          other.grade == this.grade &&
          other.sizeClass == this.sizeClass &&
          other.quantityKg == this.quantityKg &&
          other.note == this.note &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class HarvestRecordsCompanion extends UpdateCompanion<HarvestRecordRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<DateTime> harvestedOn;
  final Value<String?> grade;
  final Value<String?> sizeClass;
  final Value<double> quantityKg;
  final Value<String?> note;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const HarvestRecordsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.harvestedOn = const Value.absent(),
    this.grade = const Value.absent(),
    this.sizeClass = const Value.absent(),
    this.quantityKg = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HarvestRecordsCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required DateTime harvestedOn,
    this.grade = const Value.absent(),
    this.sizeClass = const Value.absent(),
    required double quantityKg,
    this.note = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       harvestedOn = Value(harvestedOn),
       quantityKg = Value(quantityKg),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<HarvestRecordRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<DateTime>? harvestedOn,
    Expression<String>? grade,
    Expression<String>? sizeClass,
    Expression<double>? quantityKg,
    Expression<String>? note,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (harvestedOn != null) 'harvested_on': harvestedOn,
      if (grade != null) 'grade': grade,
      if (sizeClass != null) 'size_class': sizeClass,
      if (quantityKg != null) 'quantity_kg': quantityKg,
      if (note != null) 'note': note,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HarvestRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<DateTime>? harvestedOn,
    Value<String?>? grade,
    Value<String?>? sizeClass,
    Value<double>? quantityKg,
    Value<String?>? note,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return HarvestRecordsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      harvestedOn: harvestedOn ?? this.harvestedOn,
      grade: grade ?? this.grade,
      sizeClass: sizeClass ?? this.sizeClass,
      quantityKg: quantityKg ?? this.quantityKg,
      note: note ?? this.note,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (harvestedOn.present) {
      map['harvested_on'] = Variable<DateTime>(harvestedOn.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (sizeClass.present) {
      map['size_class'] = Variable<String>(sizeClass.value);
    }
    if (quantityKg.present) {
      map['quantity_kg'] = Variable<double>(quantityKg.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('HarvestRecordsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('harvestedOn: $harvestedOn, ')
          ..write('grade: $grade, ')
          ..write('sizeClass: $sizeClass, ')
          ..write('quantityKg: $quantityKg, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabourRecordsTable extends LabourRecords
    with TableInfo<$LabourRecordsTable, LabourRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabourRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workerNameMeta = const VerificationMeta(
    'workerName',
  );
  @override
  late final GeneratedColumn<String> workerName = GeneratedColumn<String>(
    'worker_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workedOnMeta = const VerificationMeta(
    'workedOn',
  );
  @override
  late final GeneratedColumn<DateTime> workedOn = GeneratedColumn<DateTime>(
    'worked_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskMeta = const VerificationMeta('task');
  @override
  late final GeneratedColumn<String> task = GeneratedColumn<String>(
    'task',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wagePaiseMeta = const VerificationMeta(
    'wagePaise',
  );
  @override
  late final GeneratedColumn<int> wagePaise = GeneratedColumn<int>(
    'wage_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _advancePaiseMeta = const VerificationMeta(
    'advancePaise',
  );
  @override
  late final GeneratedColumn<int> advancePaise = GeneratedColumn<int>(
    'advance_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledOnMeta = const VerificationMeta(
    'settledOn',
  );
  @override
  late final GeneratedColumn<DateTime> settledOn = GeneratedColumn<DateTime>(
    'settled_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    plotId,
    baharCycleId,
    workerName,
    workedOn,
    task,
    wagePaise,
    advancePaise,
    settledOn,
    note,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'labour_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabourRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('worker_name')) {
      context.handle(
        _workerNameMeta,
        workerName.isAcceptableOrUnknown(data['worker_name']!, _workerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_workerNameMeta);
    }
    if (data.containsKey('worked_on')) {
      context.handle(
        _workedOnMeta,
        workedOn.isAcceptableOrUnknown(data['worked_on']!, _workedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_workedOnMeta);
    }
    if (data.containsKey('task')) {
      context.handle(
        _taskMeta,
        task.isAcceptableOrUnknown(data['task']!, _taskMeta),
      );
    }
    if (data.containsKey('wage_paise')) {
      context.handle(
        _wagePaiseMeta,
        wagePaise.isAcceptableOrUnknown(data['wage_paise']!, _wagePaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_wagePaiseMeta);
    }
    if (data.containsKey('advance_paise')) {
      context.handle(
        _advancePaiseMeta,
        advancePaise.isAcceptableOrUnknown(
          data['advance_paise']!,
          _advancePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_advancePaiseMeta);
    }
    if (data.containsKey('settled_on')) {
      context.handle(
        _settledOnMeta,
        settledOn.isAcceptableOrUnknown(data['settled_on']!, _settledOnMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  LabourRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabourRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      workerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_name'],
      )!,
      workedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}worked_on'],
      )!,
      task: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task'],
      ),
      wagePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wage_paise'],
      )!,
      advancePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_paise'],
      )!,
      settledOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_on'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $LabourRecordsTable createAlias(String alias) {
    return $LabourRecordsTable(attachedDatabase, alias);
  }
}

class LabourRecordRow extends DataClass implements Insertable<LabourRecordRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final String workerName;
  final DateTime workedOn;
  final String? task;
  final int wagePaise;
  final int advancePaise;
  final DateTime? settledOn;
  final String? note;
  final DateTime clientUpdatedAt;
  const LabourRecordRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.workerName,
    required this.workedOn,
    this.task,
    required this.wagePaise,
    required this.advancePaise,
    this.settledOn,
    this.note,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['worker_name'] = Variable<String>(workerName);
    map['worked_on'] = Variable<DateTime>(workedOn);
    if (!nullToAbsent || task != null) {
      map['task'] = Variable<String>(task);
    }
    map['wage_paise'] = Variable<int>(wagePaise);
    map['advance_paise'] = Variable<int>(advancePaise);
    if (!nullToAbsent || settledOn != null) {
      map['settled_on'] = Variable<DateTime>(settledOn);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  LabourRecordsCompanion toCompanion(bool nullToAbsent) {
    return LabourRecordsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      workerName: Value(workerName),
      workedOn: Value(workedOn),
      task: task == null && nullToAbsent ? const Value.absent() : Value(task),
      wagePaise: Value(wagePaise),
      advancePaise: Value(advancePaise),
      settledOn: settledOn == null && nullToAbsent
          ? const Value.absent()
          : Value(settledOn),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory LabourRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabourRecordRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      workerName: serializer.fromJson<String>(json['workerName']),
      workedOn: serializer.fromJson<DateTime>(json['workedOn']),
      task: serializer.fromJson<String?>(json['task']),
      wagePaise: serializer.fromJson<int>(json['wagePaise']),
      advancePaise: serializer.fromJson<int>(json['advancePaise']),
      settledOn: serializer.fromJson<DateTime?>(json['settledOn']),
      note: serializer.fromJson<String?>(json['note']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'workerName': serializer.toJson<String>(workerName),
      'workedOn': serializer.toJson<DateTime>(workedOn),
      'task': serializer.toJson<String?>(task),
      'wagePaise': serializer.toJson<int>(wagePaise),
      'advancePaise': serializer.toJson<int>(advancePaise),
      'settledOn': serializer.toJson<DateTime?>(settledOn),
      'note': serializer.toJson<String?>(note),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  LabourRecordRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    String? workerName,
    DateTime? workedOn,
    Value<String?> task = const Value.absent(),
    int? wagePaise,
    int? advancePaise,
    Value<DateTime?> settledOn = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => LabourRecordRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    workerName: workerName ?? this.workerName,
    workedOn: workedOn ?? this.workedOn,
    task: task.present ? task.value : this.task,
    wagePaise: wagePaise ?? this.wagePaise,
    advancePaise: advancePaise ?? this.advancePaise,
    settledOn: settledOn.present ? settledOn.value : this.settledOn,
    note: note.present ? note.value : this.note,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  LabourRecordRow copyWithCompanion(LabourRecordsCompanion data) {
    return LabourRecordRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      workerName: data.workerName.present
          ? data.workerName.value
          : this.workerName,
      workedOn: data.workedOn.present ? data.workedOn.value : this.workedOn,
      task: data.task.present ? data.task.value : this.task,
      wagePaise: data.wagePaise.present ? data.wagePaise.value : this.wagePaise,
      advancePaise: data.advancePaise.present
          ? data.advancePaise.value
          : this.advancePaise,
      settledOn: data.settledOn.present ? data.settledOn.value : this.settledOn,
      note: data.note.present ? data.note.value : this.note,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabourRecordRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('workerName: $workerName, ')
          ..write('workedOn: $workedOn, ')
          ..write('task: $task, ')
          ..write('wagePaise: $wagePaise, ')
          ..write('advancePaise: $advancePaise, ')
          ..write('settledOn: $settledOn, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    workerName,
    workedOn,
    task,
    wagePaise,
    advancePaise,
    settledOn,
    note,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabourRecordRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.workerName == this.workerName &&
          other.workedOn == this.workedOn &&
          other.task == this.task &&
          other.wagePaise == this.wagePaise &&
          other.advancePaise == this.advancePaise &&
          other.settledOn == this.settledOn &&
          other.note == this.note &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class LabourRecordsCompanion extends UpdateCompanion<LabourRecordRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<String> workerName;
  final Value<DateTime> workedOn;
  final Value<String?> task;
  final Value<int> wagePaise;
  final Value<int> advancePaise;
  final Value<DateTime?> settledOn;
  final Value<String?> note;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const LabourRecordsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.workerName = const Value.absent(),
    this.workedOn = const Value.absent(),
    this.task = const Value.absent(),
    this.wagePaise = const Value.absent(),
    this.advancePaise = const Value.absent(),
    this.settledOn = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabourRecordsCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required String workerName,
    required DateTime workedOn,
    this.task = const Value.absent(),
    required int wagePaise,
    required int advancePaise,
    this.settledOn = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       workerName = Value(workerName),
       workedOn = Value(workedOn),
       wagePaise = Value(wagePaise),
       advancePaise = Value(advancePaise),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<LabourRecordRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<String>? workerName,
    Expression<DateTime>? workedOn,
    Expression<String>? task,
    Expression<int>? wagePaise,
    Expression<int>? advancePaise,
    Expression<DateTime>? settledOn,
    Expression<String>? note,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (workerName != null) 'worker_name': workerName,
      if (workedOn != null) 'worked_on': workedOn,
      if (task != null) 'task': task,
      if (wagePaise != null) 'wage_paise': wagePaise,
      if (advancePaise != null) 'advance_paise': advancePaise,
      if (settledOn != null) 'settled_on': settledOn,
      if (note != null) 'note': note,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabourRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<String>? workerName,
    Value<DateTime>? workedOn,
    Value<String?>? task,
    Value<int>? wagePaise,
    Value<int>? advancePaise,
    Value<DateTime?>? settledOn,
    Value<String?>? note,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return LabourRecordsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      workerName: workerName ?? this.workerName,
      workedOn: workedOn ?? this.workedOn,
      task: task ?? this.task,
      wagePaise: wagePaise ?? this.wagePaise,
      advancePaise: advancePaise ?? this.advancePaise,
      settledOn: settledOn ?? this.settledOn,
      note: note ?? this.note,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (workerName.present) {
      map['worker_name'] = Variable<String>(workerName.value);
    }
    if (workedOn.present) {
      map['worked_on'] = Variable<DateTime>(workedOn.value);
    }
    if (task.present) {
      map['task'] = Variable<String>(task.value);
    }
    if (wagePaise.present) {
      map['wage_paise'] = Variable<int>(wagePaise.value);
    }
    if (advancePaise.present) {
      map['advance_paise'] = Variable<int>(advancePaise.value);
    }
    if (settledOn.present) {
      map['settled_on'] = Variable<DateTime>(settledOn.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('LabourRecordsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('workerName: $workerName, ')
          ..write('workedOn: $workedOn, ')
          ..write('task: $task, ')
          ..write('wagePaise: $wagePaise, ')
          ..write('advancePaise: $advancePaise, ')
          ..write('settledOn: $settledOn, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FarmTasksTable extends FarmTasks
    with TableInfo<$FarmTasksTable, FarmTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FarmTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueOnMeta = const VerificationMeta('dueOn');
  @override
  late final GeneratedColumn<DateTime> dueOn = GeneratedColumn<DateTime>(
    'due_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneOnMeta = const VerificationMeta('doneOn');
  @override
  late final GeneratedColumn<DateTime> doneOn = GeneratedColumn<DateTime>(
    'done_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    plotId,
    baharCycleId,
    title,
    kind,
    dueOn,
    doneOn,
    source,
    note,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'farm_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<FarmTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('due_on')) {
      context.handle(
        _dueOnMeta,
        dueOn.isAcceptableOrUnknown(data['due_on']!, _dueOnMeta),
      );
    } else if (isInserting) {
      context.missing(_dueOnMeta);
    }
    if (data.containsKey('done_on')) {
      context.handle(
        _doneOnMeta,
        doneOn.isAcceptableOrUnknown(data['done_on']!, _doneOnMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  FarmTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FarmTaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      ),
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      dueOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_on'],
      )!,
      doneOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_on'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $FarmTasksTable createAlias(String alias) {
    return $FarmTasksTable(attachedDatabase, alias);
  }
}

class FarmTaskRow extends DataClass implements Insertable<FarmTaskRow> {
  final String id;
  final String? plotId;
  final String? baharCycleId;
  final String title;
  final String kind;
  final DateTime dueOn;
  final DateTime? doneOn;
  final String? source;
  final String? note;
  final DateTime clientUpdatedAt;
  const FarmTaskRow({
    required this.id,
    this.plotId,
    this.baharCycleId,
    required this.title,
    required this.kind,
    required this.dueOn,
    this.doneOn,
    this.source,
    this.note,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || plotId != null) {
      map['plot_id'] = Variable<String>(plotId);
    }
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['title'] = Variable<String>(title);
    map['kind'] = Variable<String>(kind);
    map['due_on'] = Variable<DateTime>(dueOn);
    if (!nullToAbsent || doneOn != null) {
      map['done_on'] = Variable<DateTime>(doneOn);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  FarmTasksCompanion toCompanion(bool nullToAbsent) {
    return FarmTasksCompanion(
      id: Value(id),
      plotId: plotId == null && nullToAbsent
          ? const Value.absent()
          : Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      title: Value(title),
      kind: Value(kind),
      dueOn: Value(dueOn),
      doneOn: doneOn == null && nullToAbsent
          ? const Value.absent()
          : Value(doneOn),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory FarmTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FarmTaskRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String?>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      title: serializer.fromJson<String>(json['title']),
      kind: serializer.fromJson<String>(json['kind']),
      dueOn: serializer.fromJson<DateTime>(json['dueOn']),
      doneOn: serializer.fromJson<DateTime?>(json['doneOn']),
      source: serializer.fromJson<String?>(json['source']),
      note: serializer.fromJson<String?>(json['note']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String?>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(kind),
      'dueOn': serializer.toJson<DateTime>(dueOn),
      'doneOn': serializer.toJson<DateTime?>(doneOn),
      'source': serializer.toJson<String?>(source),
      'note': serializer.toJson<String?>(note),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  FarmTaskRow copyWith({
    String? id,
    Value<String?> plotId = const Value.absent(),
    Value<String?> baharCycleId = const Value.absent(),
    String? title,
    String? kind,
    DateTime? dueOn,
    Value<DateTime?> doneOn = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => FarmTaskRow(
    id: id ?? this.id,
    plotId: plotId.present ? plotId.value : this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    dueOn: dueOn ?? this.dueOn,
    doneOn: doneOn.present ? doneOn.value : this.doneOn,
    source: source.present ? source.value : this.source,
    note: note.present ? note.value : this.note,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  FarmTaskRow copyWithCompanion(FarmTasksCompanion data) {
    return FarmTaskRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      dueOn: data.dueOn.present ? data.dueOn.value : this.dueOn,
      doneOn: data.doneOn.present ? data.doneOn.value : this.doneOn,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FarmTaskRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('dueOn: $dueOn, ')
          ..write('doneOn: $doneOn, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    title,
    kind,
    dueOn,
    doneOn,
    source,
    note,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FarmTaskRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.dueOn == this.dueOn &&
          other.doneOn == this.doneOn &&
          other.source == this.source &&
          other.note == this.note &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class FarmTasksCompanion extends UpdateCompanion<FarmTaskRow> {
  final Value<String> id;
  final Value<String?> plotId;
  final Value<String?> baharCycleId;
  final Value<String> title;
  final Value<String> kind;
  final Value<DateTime> dueOn;
  final Value<DateTime?> doneOn;
  final Value<String?> source;
  final Value<String?> note;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const FarmTasksCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.doneOn = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FarmTasksCompanion.insert({
    required String id,
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    required String title,
    required String kind,
    required DateTime dueOn,
    this.doneOn = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       kind = Value(kind),
       dueOn = Value(dueOn),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<FarmTaskRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<DateTime>? dueOn,
    Expression<DateTime>? doneOn,
    Expression<String>? source,
    Expression<String>? note,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (dueOn != null) 'due_on': dueOn,
      if (doneOn != null) 'done_on': doneOn,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FarmTasksCompanion copyWith({
    Value<String>? id,
    Value<String?>? plotId,
    Value<String?>? baharCycleId,
    Value<String>? title,
    Value<String>? kind,
    Value<DateTime>? dueOn,
    Value<DateTime?>? doneOn,
    Value<String?>? source,
    Value<String?>? note,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return FarmTasksCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      dueOn: dueOn ?? this.dueOn,
      doneOn: doneOn ?? this.doneOn,
      source: source ?? this.source,
      note: note ?? this.note,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (dueOn.present) {
      map['due_on'] = Variable<DateTime>(dueOn.value);
    }
    if (doneOn.present) {
      map['done_on'] = Variable<DateTime>(doneOn.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('FarmTasksCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('dueOn: $dueOn, ')
          ..write('doneOn: $doneOn, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoutingRecordsTable extends ScoutingRecords
    with TableInfo<$ScoutingRecordsTable, ScoutingRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoutingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<String> plotId = GeneratedColumn<String>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baharCycleIdMeta = const VerificationMeta(
    'baharCycleId',
  );
  @override
  late final GeneratedColumn<String> baharCycleId = GeneratedColumn<String>(
    'bahar_cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observedOnMeta = const VerificationMeta(
    'observedOn',
  );
  @override
  late final GeneratedColumn<DateTime> observedOn = GeneratedColumn<DateTime>(
    'observed_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
    'item',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoKeyMeta = const VerificationMeta(
    'photoKey',
  );
  @override
  late final GeneratedColumn<String> photoKey = GeneratedColumn<String>(
    'photo_key',
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
    plotId,
    baharCycleId,
    observedOn,
    item,
    severity,
    note,
    photoPath,
    photoKey,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scouting_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoutingRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('bahar_cycle_id')) {
      context.handle(
        _baharCycleIdMeta,
        baharCycleId.isAcceptableOrUnknown(
          data['bahar_cycle_id']!,
          _baharCycleIdMeta,
        ),
      );
    }
    if (data.containsKey('observed_on')) {
      context.handle(
        _observedOnMeta,
        observedOn.isAcceptableOrUnknown(data['observed_on']!, _observedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_observedOnMeta);
    }
    if (data.containsKey('item')) {
      context.handle(
        _itemMeta,
        item.isAcceptableOrUnknown(data['item']!, _itemMeta),
      );
    } else if (isInserting) {
      context.missing(_itemMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('photo_key')) {
      context.handle(
        _photoKeyMeta,
        photoKey.isAcceptableOrUnknown(data['photo_key']!, _photoKeyMeta),
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
  ScoutingRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoutingRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_id'],
      )!,
      baharCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bahar_cycle_id'],
      ),
      observedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_on'],
      )!,
      item: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      photoKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_key'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
    );
  }

  @override
  $ScoutingRecordsTable createAlias(String alias) {
    return $ScoutingRecordsTable(attachedDatabase, alias);
  }
}

class ScoutingRecordRow extends DataClass
    implements Insertable<ScoutingRecordRow> {
  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime observedOn;
  final String item;
  final String severity;
  final String? note;
  final String? photoPath;
  final String? photoKey;
  final DateTime clientUpdatedAt;
  const ScoutingRecordRow({
    required this.id,
    required this.plotId,
    this.baharCycleId,
    required this.observedOn,
    required this.item,
    required this.severity,
    this.note,
    this.photoPath,
    this.photoKey,
    required this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plot_id'] = Variable<String>(plotId);
    if (!nullToAbsent || baharCycleId != null) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId);
    }
    map['observed_on'] = Variable<DateTime>(observedOn);
    map['item'] = Variable<String>(item);
    map['severity'] = Variable<String>(severity);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || photoKey != null) {
      map['photo_key'] = Variable<String>(photoKey);
    }
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    return map;
  }

  ScoutingRecordsCompanion toCompanion(bool nullToAbsent) {
    return ScoutingRecordsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      baharCycleId: baharCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(baharCycleId),
      observedOn: Value(observedOn),
      item: Value(item),
      severity: Value(severity),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoKey: photoKey == null && nullToAbsent
          ? const Value.absent()
          : Value(photoKey),
      clientUpdatedAt: Value(clientUpdatedAt),
    );
  }

  factory ScoutingRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoutingRecordRow(
      id: serializer.fromJson<String>(json['id']),
      plotId: serializer.fromJson<String>(json['plotId']),
      baharCycleId: serializer.fromJson<String?>(json['baharCycleId']),
      observedOn: serializer.fromJson<DateTime>(json['observedOn']),
      item: serializer.fromJson<String>(json['item']),
      severity: serializer.fromJson<String>(json['severity']),
      note: serializer.fromJson<String?>(json['note']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoKey: serializer.fromJson<String?>(json['photoKey']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plotId': serializer.toJson<String>(plotId),
      'baharCycleId': serializer.toJson<String?>(baharCycleId),
      'observedOn': serializer.toJson<DateTime>(observedOn),
      'item': serializer.toJson<String>(item),
      'severity': serializer.toJson<String>(severity),
      'note': serializer.toJson<String?>(note),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoKey': serializer.toJson<String?>(photoKey),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
    };
  }

  ScoutingRecordRow copyWith({
    String? id,
    String? plotId,
    Value<String?> baharCycleId = const Value.absent(),
    DateTime? observedOn,
    String? item,
    String? severity,
    Value<String?> note = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    Value<String?> photoKey = const Value.absent(),
    DateTime? clientUpdatedAt,
  }) => ScoutingRecordRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    baharCycleId: baharCycleId.present ? baharCycleId.value : this.baharCycleId,
    observedOn: observedOn ?? this.observedOn,
    item: item ?? this.item,
    severity: severity ?? this.severity,
    note: note.present ? note.value : this.note,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    photoKey: photoKey.present ? photoKey.value : this.photoKey,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
  );
  ScoutingRecordRow copyWithCompanion(ScoutingRecordsCompanion data) {
    return ScoutingRecordRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      baharCycleId: data.baharCycleId.present
          ? data.baharCycleId.value
          : this.baharCycleId,
      observedOn: data.observedOn.present
          ? data.observedOn.value
          : this.observedOn,
      item: data.item.present ? data.item.value : this.item,
      severity: data.severity.present ? data.severity.value : this.severity,
      note: data.note.present ? data.note.value : this.note,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoKey: data.photoKey.present ? data.photoKey.value : this.photoKey,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoutingRecordRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('observedOn: $observedOn, ')
          ..write('item: $item, ')
          ..write('severity: $severity, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoKey: $photoKey, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    baharCycleId,
    observedOn,
    item,
    severity,
    note,
    photoPath,
    photoKey,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoutingRecordRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.baharCycleId == this.baharCycleId &&
          other.observedOn == this.observedOn &&
          other.item == this.item &&
          other.severity == this.severity &&
          other.note == this.note &&
          other.photoPath == this.photoPath &&
          other.photoKey == this.photoKey &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class ScoutingRecordsCompanion extends UpdateCompanion<ScoutingRecordRow> {
  final Value<String> id;
  final Value<String> plotId;
  final Value<String?> baharCycleId;
  final Value<DateTime> observedOn;
  final Value<String> item;
  final Value<String> severity;
  final Value<String?> note;
  final Value<String?> photoPath;
  final Value<String?> photoKey;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> rowid;
  const ScoutingRecordsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.baharCycleId = const Value.absent(),
    this.observedOn = const Value.absent(),
    this.item = const Value.absent(),
    this.severity = const Value.absent(),
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoKey = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoutingRecordsCompanion.insert({
    required String id,
    required String plotId,
    this.baharCycleId = const Value.absent(),
    required DateTime observedOn,
    required String item,
    required String severity,
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoKey = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plotId = Value(plotId),
       observedOn = Value(observedOn),
       item = Value(item),
       severity = Value(severity),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<ScoutingRecordRow> custom({
    Expression<String>? id,
    Expression<String>? plotId,
    Expression<String>? baharCycleId,
    Expression<DateTime>? observedOn,
    Expression<String>? item,
    Expression<String>? severity,
    Expression<String>? note,
    Expression<String>? photoPath,
    Expression<String>? photoKey,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (baharCycleId != null) 'bahar_cycle_id': baharCycleId,
      if (observedOn != null) 'observed_on': observedOn,
      if (item != null) 'item': item,
      if (severity != null) 'severity': severity,
      if (note != null) 'note': note,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoKey != null) 'photo_key': photoKey,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoutingRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? plotId,
    Value<String?>? baharCycleId,
    Value<DateTime>? observedOn,
    Value<String>? item,
    Value<String>? severity,
    Value<String?>? note,
    Value<String?>? photoPath,
    Value<String?>? photoKey,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return ScoutingRecordsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      baharCycleId: baharCycleId ?? this.baharCycleId,
      observedOn: observedOn ?? this.observedOn,
      item: item ?? this.item,
      severity: severity ?? this.severity,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      photoKey: photoKey ?? this.photoKey,
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
    if (plotId.present) {
      map['plot_id'] = Variable<String>(plotId.value);
    }
    if (baharCycleId.present) {
      map['bahar_cycle_id'] = Variable<String>(baharCycleId.value);
    }
    if (observedOn.present) {
      map['observed_on'] = Variable<DateTime>(observedOn.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoKey.present) {
      map['photo_key'] = Variable<String>(photoKey.value);
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
    return (StringBuffer('ScoutingRecordsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('baharCycleId: $baharCycleId, ')
          ..write('observedOn: $observedOn, ')
          ..write('item: $item, ')
          ..write('severity: $severity, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoKey: $photoKey, ')
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
  late final $BaharCyclesTable baharCycles = $BaharCyclesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $IncomesTable incomes = $IncomesTable(this);
  late final $SprayRecordsTable sprayRecords = $SprayRecordsTable(this);
  late final $InputRecordsTable inputRecords = $InputRecordsTable(this);
  late final $IrrigationRecordsTable irrigationRecords =
      $IrrigationRecordsTable(this);
  late final $HarvestRecordsTable harvestRecords = $HarvestRecordsTable(this);
  late final $LabourRecordsTable labourRecords = $LabourRecordsTable(this);
  late final $FarmTasksTable farmTasks = $FarmTasksTable(this);
  late final $ScoutingRecordsTable scoutingRecords = $ScoutingRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxEntries,
    farmerProfiles,
    syncMeta,
    plots,
    baharCycles,
    expenses,
    incomes,
    sprayRecords,
    inputRecords,
    irrigationRecords,
    harvestRecords,
    labourRecords,
    farmTasks,
    scoutingRecords,
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
      Value<String?> phone,
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
      Value<String?> phone,
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

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
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

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
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

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

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
                Value<String?> phone = const Value.absent(),
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
                phone: phone,
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
                Value<String?> phone = const Value.absent(),
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
                phone: phone,
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
typedef $$BaharCyclesTableCreateCompanionBuilder =
    BaharCyclesCompanion Function({
      required String id,
      required String plotId,
      required String bahar,
      required int seasonYear,
      Value<String?> templateId,
      required String status,
      required String planned,
      required String actual,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$BaharCyclesTableUpdateCompanionBuilder =
    BaharCyclesCompanion Function({
      Value<String> id,
      Value<String> plotId,
      Value<String> bahar,
      Value<int> seasonYear,
      Value<String?> templateId,
      Value<String> status,
      Value<String> planned,
      Value<String> actual,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$BaharCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $BaharCyclesTable> {
  $$BaharCyclesTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bahar => $composableBuilder(
    column: $table.bahar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonYear => $composableBuilder(
    column: $table.seasonYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planned => $composableBuilder(
    column: $table.planned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actual => $composableBuilder(
    column: $table.actual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BaharCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $BaharCyclesTable> {
  $$BaharCyclesTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bahar => $composableBuilder(
    column: $table.bahar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonYear => $composableBuilder(
    column: $table.seasonYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planned => $composableBuilder(
    column: $table.planned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actual => $composableBuilder(
    column: $table.actual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BaharCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BaharCyclesTable> {
  $$BaharCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get bahar =>
      $composableBuilder(column: $table.bahar, builder: (column) => column);

  GeneratedColumn<int> get seasonYear => $composableBuilder(
    column: $table.seasonYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get planned =>
      $composableBuilder(column: $table.planned, builder: (column) => column);

  GeneratedColumn<String> get actual =>
      $composableBuilder(column: $table.actual, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$BaharCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BaharCyclesTable,
          BaharCycleRow,
          $$BaharCyclesTableFilterComposer,
          $$BaharCyclesTableOrderingComposer,
          $$BaharCyclesTableAnnotationComposer,
          $$BaharCyclesTableCreateCompanionBuilder,
          $$BaharCyclesTableUpdateCompanionBuilder,
          (
            BaharCycleRow,
            BaseReferences<_$AppDatabase, $BaharCyclesTable, BaharCycleRow>,
          ),
          BaharCycleRow,
          PrefetchHooks Function()
        > {
  $$BaharCyclesTableTableManager(_$AppDatabase db, $BaharCyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BaharCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BaharCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BaharCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String> bahar = const Value.absent(),
                Value<int> seasonYear = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> planned = const Value.absent(),
                Value<String> actual = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BaharCyclesCompanion(
                id: id,
                plotId: plotId,
                bahar: bahar,
                seasonYear: seasonYear,
                templateId: templateId,
                status: status,
                planned: planned,
                actual: actual,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                required String bahar,
                required int seasonYear,
                Value<String?> templateId = const Value.absent(),
                required String status,
                required String planned,
                required String actual,
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BaharCyclesCompanion.insert(
                id: id,
                plotId: plotId,
                bahar: bahar,
                seasonYear: seasonYear,
                templateId: templateId,
                status: status,
                planned: planned,
                actual: actual,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BaharCyclesTable, BaharCycleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BaharCyclesTable,
                    BaharCycleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BaharCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BaharCyclesTable,
      BaharCycleRow,
      $$BaharCyclesTableFilterComposer,
      $$BaharCyclesTableOrderingComposer,
      $$BaharCyclesTableAnnotationComposer,
      $$BaharCyclesTableCreateCompanionBuilder,
      $$BaharCyclesTableUpdateCompanionBuilder,
      (
        BaharCycleRow,
        BaseReferences<_$AppDatabase, $BaharCyclesTable, BaharCycleRow>,
      ),
      BaharCycleRow,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String plotId,
  Value<String?> baharCycleId,
  required DateTime spentOn,
  required String category,
  required int amountPaise,
  Value<String?> note,
  required DateTime clientUpdatedAt,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> plotId,
  Value<String?> baharCycleId,
  Value<DateTime> spentOn,
  Value<String> category,
  Value<int> amountPaise,
  Value<String?> note,
  Value<DateTime> clientUpdatedAt,
  Value<int> rowid,
});

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spentOn => $composableBuilder(
    column: $table.spentOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spentOn => $composableBuilder(
    column: $table.spentOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get spentOn =>
      $composableBuilder(column: $table.spentOn, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<DateTime> spentOn = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                spentOn: spentOn,
                category: category,
                amountPaise: amountPaise,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required DateTime spentOn,
                required String category,
                required int amountPaise,
                Value<String?> note = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                spentOn: spentOn,
                category: category,
                amountPaise: amountPaise,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, ExpenseRow>(table),
                  BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>(
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

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (ExpenseRow, BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$IncomesTableCreateCompanionBuilder = IncomesCompanion Function({
  required String id,
  required String plotId,
  Value<String?> baharCycleId,
  required DateTime soldOn,
  required String buyerName,
  Value<String?> grade,
  required double quantityKg,
  required int ratePaisePerQuintal,
  required int deductionsPaise,
  required String paymentStatus,
  required int paidPaise,
  Value<DateTime?> paidOn,
  required DateTime clientUpdatedAt,
  Value<int> rowid,
});
typedef $$IncomesTableUpdateCompanionBuilder = IncomesCompanion Function({
  Value<String> id,
  Value<String> plotId,
  Value<String?> baharCycleId,
  Value<DateTime> soldOn,
  Value<String> buyerName,
  Value<String?> grade,
  Value<double> quantityKg,
  Value<int> ratePaisePerQuintal,
  Value<int> deductionsPaise,
  Value<String> paymentStatus,
  Value<int> paidPaise,
  Value<DateTime?> paidOn,
  Value<DateTime> clientUpdatedAt,
  Value<int> rowid,
});

class $$IncomesTableFilterComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get soldOn => $composableBuilder(
    column: $table.soldOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityKg => $composableBuilder(
    column: $table.quantityKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratePaisePerQuintal => $composableBuilder(
    column: $table.ratePaisePerQuintal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deductionsPaise => $composableBuilder(
    column: $table.deductionsPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidPaise => $composableBuilder(
    column: $table.paidPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IncomesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get soldOn => $composableBuilder(
    column: $table.soldOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityKg => $composableBuilder(
    column: $table.quantityKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratePaisePerQuintal => $composableBuilder(
    column: $table.ratePaisePerQuintal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deductionsPaise => $composableBuilder(
    column: $table.deductionsPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidPaise => $composableBuilder(
    column: $table.paidPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get soldOn =>
      $composableBuilder(column: $table.soldOn, builder: (column) => column);

  GeneratedColumn<String> get buyerName =>
      $composableBuilder(column: $table.buyerName, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<double> get quantityKg => $composableBuilder(
    column: $table.quantityKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ratePaisePerQuintal => $composableBuilder(
    column: $table.ratePaisePerQuintal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deductionsPaise => $composableBuilder(
    column: $table.deductionsPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidPaise =>
      $composableBuilder(column: $table.paidPaise, builder: (column) => column);

  GeneratedColumn<DateTime> get paidOn =>
      $composableBuilder(column: $table.paidOn, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$IncomesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomesTable,
          IncomeRow,
          $$IncomesTableFilterComposer,
          $$IncomesTableOrderingComposer,
          $$IncomesTableAnnotationComposer,
          $$IncomesTableCreateCompanionBuilder,
          $$IncomesTableUpdateCompanionBuilder,
          (IncomeRow, BaseReferences<_$AppDatabase, $IncomesTable, IncomeRow>),
          IncomeRow,
          PrefetchHooks Function()
        > {
  $$IncomesTableTableManager(_$AppDatabase db, $IncomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<DateTime> soldOn = const Value.absent(),
                Value<String> buyerName = const Value.absent(),
                Value<String?> grade = const Value.absent(),
                Value<double> quantityKg = const Value.absent(),
                Value<int> ratePaisePerQuintal = const Value.absent(),
                Value<int> deductionsPaise = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<int> paidPaise = const Value.absent(),
                Value<DateTime?> paidOn = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomesCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                soldOn: soldOn,
                buyerName: buyerName,
                grade: grade,
                quantityKg: quantityKg,
                ratePaisePerQuintal: ratePaisePerQuintal,
                deductionsPaise: deductionsPaise,
                paymentStatus: paymentStatus,
                paidPaise: paidPaise,
                paidOn: paidOn,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required DateTime soldOn,
                required String buyerName,
                Value<String?> grade = const Value.absent(),
                required double quantityKg,
                required int ratePaisePerQuintal,
                required int deductionsPaise,
                required String paymentStatus,
                required int paidPaise,
                Value<DateTime?> paidOn = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => IncomesCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                soldOn: soldOn,
                buyerName: buyerName,
                grade: grade,
                quantityKg: quantityKg,
                ratePaisePerQuintal: ratePaisePerQuintal,
                deductionsPaise: deductionsPaise,
                paymentStatus: paymentStatus,
                paidPaise: paidPaise,
                paidOn: paidOn,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncomesTable, IncomeRow>(table),
                  BaseReferences<_$AppDatabase, $IncomesTable, IncomeRow>(
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

typedef $$IncomesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomesTable,
      IncomeRow,
      $$IncomesTableFilterComposer,
      $$IncomesTableOrderingComposer,
      $$IncomesTableAnnotationComposer,
      $$IncomesTableCreateCompanionBuilder,
      $$IncomesTableUpdateCompanionBuilder,
      (IncomeRow, BaseReferences<_$AppDatabase, $IncomesTable, IncomeRow>),
      IncomeRow,
      PrefetchHooks Function()
    >;
typedef $$SprayRecordsTableCreateCompanionBuilder =
    SprayRecordsCompanion Function({
      required String id,
      required String plotId,
      Value<String?> baharCycleId,
      required DateTime sprayedOn,
      required String productName,
      Value<String?> activeIngredient,
      Value<String?> dose,
      Value<double?> waterLitres,
      Value<double?> areaAcres,
      required int costPaise,
      Value<String?> operator,
      Value<int?> phiDays,
      Value<String?> target,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$SprayRecordsTableUpdateCompanionBuilder =
    SprayRecordsCompanion Function({
      Value<String> id,
      Value<String> plotId,
      Value<String?> baharCycleId,
      Value<DateTime> sprayedOn,
      Value<String> productName,
      Value<String?> activeIngredient,
      Value<String?> dose,
      Value<double?> waterLitres,
      Value<double?> areaAcres,
      Value<int> costPaise,
      Value<String?> operator,
      Value<int?> phiDays,
      Value<String?> target,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$SprayRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SprayRecordsTable> {
  $$SprayRecordsTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sprayedOn => $composableBuilder(
    column: $table.sprayedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeIngredient => $composableBuilder(
    column: $table.activeIngredient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterLitres => $composableBuilder(
    column: $table.waterLitres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get areaAcres => $composableBuilder(
    column: $table.areaAcres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPaise => $composableBuilder(
    column: $table.costPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operator => $composableBuilder(
    column: $table.operator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phiDays => $composableBuilder(
    column: $table.phiDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SprayRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SprayRecordsTable> {
  $$SprayRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sprayedOn => $composableBuilder(
    column: $table.sprayedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeIngredient => $composableBuilder(
    column: $table.activeIngredient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterLitres => $composableBuilder(
    column: $table.waterLitres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get areaAcres => $composableBuilder(
    column: $table.areaAcres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPaise => $composableBuilder(
    column: $table.costPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operator => $composableBuilder(
    column: $table.operator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phiDays => $composableBuilder(
    column: $table.phiDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SprayRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SprayRecordsTable> {
  $$SprayRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sprayedOn =>
      $composableBuilder(column: $table.sprayedOn, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeIngredient => $composableBuilder(
    column: $table.activeIngredient,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<double> get waterLitres => $composableBuilder(
    column: $table.waterLitres,
    builder: (column) => column,
  );

  GeneratedColumn<double> get areaAcres =>
      $composableBuilder(column: $table.areaAcres, builder: (column) => column);

  GeneratedColumn<int> get costPaise =>
      $composableBuilder(column: $table.costPaise, builder: (column) => column);

  GeneratedColumn<String> get operator =>
      $composableBuilder(column: $table.operator, builder: (column) => column);

  GeneratedColumn<int> get phiDays =>
      $composableBuilder(column: $table.phiDays, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$SprayRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SprayRecordsTable,
          SprayRecordRow,
          $$SprayRecordsTableFilterComposer,
          $$SprayRecordsTableOrderingComposer,
          $$SprayRecordsTableAnnotationComposer,
          $$SprayRecordsTableCreateCompanionBuilder,
          $$SprayRecordsTableUpdateCompanionBuilder,
          (
            SprayRecordRow,
            BaseReferences<_$AppDatabase, $SprayRecordsTable, SprayRecordRow>,
          ),
          SprayRecordRow,
          PrefetchHooks Function()
        > {
  $$SprayRecordsTableTableManager(_$AppDatabase db, $SprayRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SprayRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SprayRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SprayRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<DateTime> sprayedOn = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> activeIngredient = const Value.absent(),
                Value<String?> dose = const Value.absent(),
                Value<double?> waterLitres = const Value.absent(),
                Value<double?> areaAcres = const Value.absent(),
                Value<int> costPaise = const Value.absent(),
                Value<String?> operator = const Value.absent(),
                Value<int?> phiDays = const Value.absent(),
                Value<String?> target = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SprayRecordsCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                sprayedOn: sprayedOn,
                productName: productName,
                activeIngredient: activeIngredient,
                dose: dose,
                waterLitres: waterLitres,
                areaAcres: areaAcres,
                costPaise: costPaise,
                operator: operator,
                phiDays: phiDays,
                target: target,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required DateTime sprayedOn,
                required String productName,
                Value<String?> activeIngredient = const Value.absent(),
                Value<String?> dose = const Value.absent(),
                Value<double?> waterLitres = const Value.absent(),
                Value<double?> areaAcres = const Value.absent(),
                required int costPaise,
                Value<String?> operator = const Value.absent(),
                Value<int?> phiDays = const Value.absent(),
                Value<String?> target = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SprayRecordsCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                sprayedOn: sprayedOn,
                productName: productName,
                activeIngredient: activeIngredient,
                dose: dose,
                waterLitres: waterLitres,
                areaAcres: areaAcres,
                costPaise: costPaise,
                operator: operator,
                phiDays: phiDays,
                target: target,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SprayRecordsTable, SprayRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SprayRecordsTable,
                    SprayRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SprayRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SprayRecordsTable,
      SprayRecordRow,
      $$SprayRecordsTableFilterComposer,
      $$SprayRecordsTableOrderingComposer,
      $$SprayRecordsTableAnnotationComposer,
      $$SprayRecordsTableCreateCompanionBuilder,
      $$SprayRecordsTableUpdateCompanionBuilder,
      (
        SprayRecordRow,
        BaseReferences<_$AppDatabase, $SprayRecordsTable, SprayRecordRow>,
      ),
      SprayRecordRow,
      PrefetchHooks Function()
    >;
typedef $$InputRecordsTableCreateCompanionBuilder =
    InputRecordsCompanion Function({
      required String id,
      required String plotId,
      Value<String?> baharCycleId,
      required DateTime appliedOn,
      required String kind,
      required String productName,
      Value<double?> quantity,
      Value<String?> unit,
      required int costPaise,
      Value<String?> note,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$InputRecordsTableUpdateCompanionBuilder =
    InputRecordsCompanion Function({
      Value<String> id,
      Value<String> plotId,
      Value<String?> baharCycleId,
      Value<DateTime> appliedOn,
      Value<String> kind,
      Value<String> productName,
      Value<double?> quantity,
      Value<String?> unit,
      Value<int> costPaise,
      Value<String?> note,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$InputRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $InputRecordsTable> {
  $$InputRecordsTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedOn => $composableBuilder(
    column: $table.appliedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPaise => $composableBuilder(
    column: $table.costPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InputRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $InputRecordsTable> {
  $$InputRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedOn => $composableBuilder(
    column: $table.appliedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPaise => $composableBuilder(
    column: $table.costPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InputRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InputRecordsTable> {
  $$InputRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get appliedOn =>
      $composableBuilder(column: $table.appliedOn, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get costPaise =>
      $composableBuilder(column: $table.costPaise, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$InputRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InputRecordsTable,
          InputRecordRow,
          $$InputRecordsTableFilterComposer,
          $$InputRecordsTableOrderingComposer,
          $$InputRecordsTableAnnotationComposer,
          $$InputRecordsTableCreateCompanionBuilder,
          $$InputRecordsTableUpdateCompanionBuilder,
          (
            InputRecordRow,
            BaseReferences<_$AppDatabase, $InputRecordsTable, InputRecordRow>,
          ),
          InputRecordRow,
          PrefetchHooks Function()
        > {
  $$InputRecordsTableTableManager(_$AppDatabase db, $InputRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InputRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InputRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InputRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<DateTime> appliedOn = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> costPaise = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InputRecordsCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                appliedOn: appliedOn,
                kind: kind,
                productName: productName,
                quantity: quantity,
                unit: unit,
                costPaise: costPaise,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required DateTime appliedOn,
                required String kind,
                required String productName,
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required int costPaise,
                Value<String?> note = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InputRecordsCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                appliedOn: appliedOn,
                kind: kind,
                productName: productName,
                quantity: quantity,
                unit: unit,
                costPaise: costPaise,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InputRecordsTable, InputRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InputRecordsTable,
                    InputRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InputRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InputRecordsTable,
      InputRecordRow,
      $$InputRecordsTableFilterComposer,
      $$InputRecordsTableOrderingComposer,
      $$InputRecordsTableAnnotationComposer,
      $$InputRecordsTableCreateCompanionBuilder,
      $$InputRecordsTableUpdateCompanionBuilder,
      (
        InputRecordRow,
        BaseReferences<_$AppDatabase, $InputRecordsTable, InputRecordRow>,
      ),
      InputRecordRow,
      PrefetchHooks Function()
    >;
typedef $$IrrigationRecordsTableCreateCompanionBuilder =
    IrrigationRecordsCompanion Function({
      required String id,
      required String plotId,
      Value<String?> baharCycleId,
      required DateTime irrigatedOn,
      Value<double?> durationHours,
      Value<double?> waterLitres,
      Value<String?> note,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$IrrigationRecordsTableUpdateCompanionBuilder =
    IrrigationRecordsCompanion Function({
      Value<String> id,
      Value<String> plotId,
      Value<String?> baharCycleId,
      Value<DateTime> irrigatedOn,
      Value<double?> durationHours,
      Value<double?> waterLitres,
      Value<String?> note,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$IrrigationRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $IrrigationRecordsTable> {
  $$IrrigationRecordsTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get irrigatedOn => $composableBuilder(
    column: $table.irrigatedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterLitres => $composableBuilder(
    column: $table.waterLitres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IrrigationRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $IrrigationRecordsTable> {
  $$IrrigationRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get irrigatedOn => $composableBuilder(
    column: $table.irrigatedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterLitres => $composableBuilder(
    column: $table.waterLitres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IrrigationRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IrrigationRecordsTable> {
  $$IrrigationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get irrigatedOn => $composableBuilder(
    column: $table.irrigatedOn,
    builder: (column) => column,
  );

  GeneratedColumn<double> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get waterLitres => $composableBuilder(
    column: $table.waterLitres,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$IrrigationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IrrigationRecordsTable,
          IrrigationRecordRow,
          $$IrrigationRecordsTableFilterComposer,
          $$IrrigationRecordsTableOrderingComposer,
          $$IrrigationRecordsTableAnnotationComposer,
          $$IrrigationRecordsTableCreateCompanionBuilder,
          $$IrrigationRecordsTableUpdateCompanionBuilder,
          (
            IrrigationRecordRow,
            BaseReferences<
              _$AppDatabase,
              $IrrigationRecordsTable,
              IrrigationRecordRow
            >,
          ),
          IrrigationRecordRow,
          PrefetchHooks Function()
        > {
  $$IrrigationRecordsTableTableManager(
    _$AppDatabase db,
    $IrrigationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IrrigationRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IrrigationRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IrrigationRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<DateTime> irrigatedOn = const Value.absent(),
                Value<double?> durationHours = const Value.absent(),
                Value<double?> waterLitres = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IrrigationRecordsCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                irrigatedOn: irrigatedOn,
                durationHours: durationHours,
                waterLitres: waterLitres,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required DateTime irrigatedOn,
                Value<double?> durationHours = const Value.absent(),
                Value<double?> waterLitres = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => IrrigationRecordsCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                irrigatedOn: irrigatedOn,
                durationHours: durationHours,
                waterLitres: waterLitres,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IrrigationRecordsTable, IrrigationRecordRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $IrrigationRecordsTable,
                    IrrigationRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IrrigationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IrrigationRecordsTable,
      IrrigationRecordRow,
      $$IrrigationRecordsTableFilterComposer,
      $$IrrigationRecordsTableOrderingComposer,
      $$IrrigationRecordsTableAnnotationComposer,
      $$IrrigationRecordsTableCreateCompanionBuilder,
      $$IrrigationRecordsTableUpdateCompanionBuilder,
      (
        IrrigationRecordRow,
        BaseReferences<
          _$AppDatabase,
          $IrrigationRecordsTable,
          IrrigationRecordRow
        >,
      ),
      IrrigationRecordRow,
      PrefetchHooks Function()
    >;
typedef $$HarvestRecordsTableCreateCompanionBuilder =
    HarvestRecordsCompanion Function({
      required String id,
      required String plotId,
      Value<String?> baharCycleId,
      required DateTime harvestedOn,
      Value<String?> grade,
      Value<String?> sizeClass,
      required double quantityKg,
      Value<String?> note,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$HarvestRecordsTableUpdateCompanionBuilder =
    HarvestRecordsCompanion Function({
      Value<String> id,
      Value<String> plotId,
      Value<String?> baharCycleId,
      Value<DateTime> harvestedOn,
      Value<String?> grade,
      Value<String?> sizeClass,
      Value<double> quantityKg,
      Value<String?> note,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$HarvestRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $HarvestRecordsTable> {
  $$HarvestRecordsTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get harvestedOn => $composableBuilder(
    column: $table.harvestedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sizeClass => $composableBuilder(
    column: $table.sizeClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityKg => $composableBuilder(
    column: $table.quantityKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HarvestRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $HarvestRecordsTable> {
  $$HarvestRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get harvestedOn => $composableBuilder(
    column: $table.harvestedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sizeClass => $composableBuilder(
    column: $table.sizeClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityKg => $composableBuilder(
    column: $table.quantityKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HarvestRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HarvestRecordsTable> {
  $$HarvestRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get harvestedOn => $composableBuilder(
    column: $table.harvestedOn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get sizeClass =>
      $composableBuilder(column: $table.sizeClass, builder: (column) => column);

  GeneratedColumn<double> get quantityKg => $composableBuilder(
    column: $table.quantityKg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$HarvestRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HarvestRecordsTable,
          HarvestRecordRow,
          $$HarvestRecordsTableFilterComposer,
          $$HarvestRecordsTableOrderingComposer,
          $$HarvestRecordsTableAnnotationComposer,
          $$HarvestRecordsTableCreateCompanionBuilder,
          $$HarvestRecordsTableUpdateCompanionBuilder,
          (
            HarvestRecordRow,
            BaseReferences<
              _$AppDatabase,
              $HarvestRecordsTable,
              HarvestRecordRow
            >,
          ),
          HarvestRecordRow,
          PrefetchHooks Function()
        > {
  $$HarvestRecordsTableTableManager(
    _$AppDatabase db,
    $HarvestRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HarvestRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HarvestRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HarvestRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<DateTime> harvestedOn = const Value.absent(),
                Value<String?> grade = const Value.absent(),
                Value<String?> sizeClass = const Value.absent(),
                Value<double> quantityKg = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HarvestRecordsCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                harvestedOn: harvestedOn,
                grade: grade,
                sizeClass: sizeClass,
                quantityKg: quantityKg,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required DateTime harvestedOn,
                Value<String?> grade = const Value.absent(),
                Value<String?> sizeClass = const Value.absent(),
                required double quantityKg,
                Value<String?> note = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HarvestRecordsCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                harvestedOn: harvestedOn,
                grade: grade,
                sizeClass: sizeClass,
                quantityKg: quantityKg,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HarvestRecordsTable, HarvestRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HarvestRecordsTable,
                    HarvestRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HarvestRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HarvestRecordsTable,
      HarvestRecordRow,
      $$HarvestRecordsTableFilterComposer,
      $$HarvestRecordsTableOrderingComposer,
      $$HarvestRecordsTableAnnotationComposer,
      $$HarvestRecordsTableCreateCompanionBuilder,
      $$HarvestRecordsTableUpdateCompanionBuilder,
      (
        HarvestRecordRow,
        BaseReferences<_$AppDatabase, $HarvestRecordsTable, HarvestRecordRow>,
      ),
      HarvestRecordRow,
      PrefetchHooks Function()
    >;
typedef $$LabourRecordsTableCreateCompanionBuilder =
    LabourRecordsCompanion Function({
      required String id,
      required String plotId,
      Value<String?> baharCycleId,
      required String workerName,
      required DateTime workedOn,
      Value<String?> task,
      required int wagePaise,
      required int advancePaise,
      Value<DateTime?> settledOn,
      Value<String?> note,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$LabourRecordsTableUpdateCompanionBuilder =
    LabourRecordsCompanion Function({
      Value<String> id,
      Value<String> plotId,
      Value<String?> baharCycleId,
      Value<String> workerName,
      Value<DateTime> workedOn,
      Value<String?> task,
      Value<int> wagePaise,
      Value<int> advancePaise,
      Value<DateTime?> settledOn,
      Value<String?> note,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$LabourRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LabourRecordsTable> {
  $$LabourRecordsTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerName => $composableBuilder(
    column: $table.workerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get workedOn => $composableBuilder(
    column: $table.workedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wagePaise => $composableBuilder(
    column: $table.wagePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advancePaise => $composableBuilder(
    column: $table.advancePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get settledOn => $composableBuilder(
    column: $table.settledOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LabourRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LabourRecordsTable> {
  $$LabourRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerName => $composableBuilder(
    column: $table.workerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get workedOn => $composableBuilder(
    column: $table.workedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wagePaise => $composableBuilder(
    column: $table.wagePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advancePaise => $composableBuilder(
    column: $table.advancePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get settledOn => $composableBuilder(
    column: $table.settledOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LabourRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabourRecordsTable> {
  $$LabourRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workerName => $composableBuilder(
    column: $table.workerName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get workedOn =>
      $composableBuilder(column: $table.workedOn, builder: (column) => column);

  GeneratedColumn<String> get task =>
      $composableBuilder(column: $table.task, builder: (column) => column);

  GeneratedColumn<int> get wagePaise =>
      $composableBuilder(column: $table.wagePaise, builder: (column) => column);

  GeneratedColumn<int> get advancePaise => $composableBuilder(
    column: $table.advancePaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get settledOn =>
      $composableBuilder(column: $table.settledOn, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$LabourRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabourRecordsTable,
          LabourRecordRow,
          $$LabourRecordsTableFilterComposer,
          $$LabourRecordsTableOrderingComposer,
          $$LabourRecordsTableAnnotationComposer,
          $$LabourRecordsTableCreateCompanionBuilder,
          $$LabourRecordsTableUpdateCompanionBuilder,
          (
            LabourRecordRow,
            BaseReferences<_$AppDatabase, $LabourRecordsTable, LabourRecordRow>,
          ),
          LabourRecordRow,
          PrefetchHooks Function()
        > {
  $$LabourRecordsTableTableManager(_$AppDatabase db, $LabourRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabourRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabourRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabourRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<String> workerName = const Value.absent(),
                Value<DateTime> workedOn = const Value.absent(),
                Value<String?> task = const Value.absent(),
                Value<int> wagePaise = const Value.absent(),
                Value<int> advancePaise = const Value.absent(),
                Value<DateTime?> settledOn = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabourRecordsCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                workerName: workerName,
                workedOn: workedOn,
                task: task,
                wagePaise: wagePaise,
                advancePaise: advancePaise,
                settledOn: settledOn,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required String workerName,
                required DateTime workedOn,
                Value<String?> task = const Value.absent(),
                required int wagePaise,
                required int advancePaise,
                Value<DateTime?> settledOn = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LabourRecordsCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                workerName: workerName,
                workedOn: workedOn,
                task: task,
                wagePaise: wagePaise,
                advancePaise: advancePaise,
                settledOn: settledOn,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LabourRecordsTable, LabourRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LabourRecordsTable,
                    LabourRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LabourRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabourRecordsTable,
      LabourRecordRow,
      $$LabourRecordsTableFilterComposer,
      $$LabourRecordsTableOrderingComposer,
      $$LabourRecordsTableAnnotationComposer,
      $$LabourRecordsTableCreateCompanionBuilder,
      $$LabourRecordsTableUpdateCompanionBuilder,
      (
        LabourRecordRow,
        BaseReferences<_$AppDatabase, $LabourRecordsTable, LabourRecordRow>,
      ),
      LabourRecordRow,
      PrefetchHooks Function()
    >;
typedef $$FarmTasksTableCreateCompanionBuilder = FarmTasksCompanion Function({
  required String id,
  Value<String?> plotId,
  Value<String?> baharCycleId,
  required String title,
  required String kind,
  required DateTime dueOn,
  Value<DateTime?> doneOn,
  Value<String?> source,
  Value<String?> note,
  required DateTime clientUpdatedAt,
  Value<int> rowid,
});
typedef $$FarmTasksTableUpdateCompanionBuilder = FarmTasksCompanion Function({
  Value<String> id,
  Value<String?> plotId,
  Value<String?> baharCycleId,
  Value<String> title,
  Value<String> kind,
  Value<DateTime> dueOn,
  Value<DateTime?> doneOn,
  Value<String?> source,
  Value<String?> note,
  Value<DateTime> clientUpdatedAt,
  Value<int> rowid,
});

class $$FarmTasksTableFilterComposer
    extends Composer<_$AppDatabase, $FarmTasksTable> {
  $$FarmTasksTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneOn => $composableBuilder(
    column: $table.doneOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FarmTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $FarmTasksTable> {
  $$FarmTasksTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneOn => $composableBuilder(
    column: $table.doneOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FarmTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FarmTasksTable> {
  $$FarmTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get dueOn =>
      $composableBuilder(column: $table.dueOn, builder: (column) => column);

  GeneratedColumn<DateTime> get doneOn =>
      $composableBuilder(column: $table.doneOn, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$FarmTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FarmTasksTable,
          FarmTaskRow,
          $$FarmTasksTableFilterComposer,
          $$FarmTasksTableOrderingComposer,
          $$FarmTasksTableAnnotationComposer,
          $$FarmTasksTableCreateCompanionBuilder,
          $$FarmTasksTableUpdateCompanionBuilder,
          (
            FarmTaskRow,
            BaseReferences<_$AppDatabase, $FarmTasksTable, FarmTaskRow>,
          ),
          FarmTaskRow,
          PrefetchHooks Function()
        > {
  $$FarmTasksTableTableManager(_$AppDatabase db, $FarmTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FarmTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FarmTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FarmTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> dueOn = const Value.absent(),
                Value<DateTime?> doneOn = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FarmTasksCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                title: title,
                kind: kind,
                dueOn: dueOn,
                doneOn: doneOn,
                source: source,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                required String title,
                required String kind,
                required DateTime dueOn,
                Value<DateTime?> doneOn = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FarmTasksCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                title: title,
                kind: kind,
                dueOn: dueOn,
                doneOn: doneOn,
                source: source,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FarmTasksTable, FarmTaskRow>(table),
                  BaseReferences<_$AppDatabase, $FarmTasksTable, FarmTaskRow>(
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

typedef $$FarmTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FarmTasksTable,
      FarmTaskRow,
      $$FarmTasksTableFilterComposer,
      $$FarmTasksTableOrderingComposer,
      $$FarmTasksTableAnnotationComposer,
      $$FarmTasksTableCreateCompanionBuilder,
      $$FarmTasksTableUpdateCompanionBuilder,
      (
        FarmTaskRow,
        BaseReferences<_$AppDatabase, $FarmTasksTable, FarmTaskRow>,
      ),
      FarmTaskRow,
      PrefetchHooks Function()
    >;
typedef $$ScoutingRecordsTableCreateCompanionBuilder =
    ScoutingRecordsCompanion Function({
      required String id,
      required String plotId,
      Value<String?> baharCycleId,
      required DateTime observedOn,
      required String item,
      required String severity,
      Value<String?> note,
      Value<String?> photoPath,
      Value<String?> photoKey,
      required DateTime clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$ScoutingRecordsTableUpdateCompanionBuilder =
    ScoutingRecordsCompanion Function({
      Value<String> id,
      Value<String> plotId,
      Value<String?> baharCycleId,
      Value<DateTime> observedOn,
      Value<String> item,
      Value<String> severity,
      Value<String?> note,
      Value<String?> photoPath,
      Value<String?> photoKey,
      Value<DateTime> clientUpdatedAt,
      Value<int> rowid,
    });

class $$ScoutingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ScoutingRecordsTable> {
  $$ScoutingRecordsTableFilterComposer({
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

  ColumnFilters<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get observedOn => $composableBuilder(
    column: $table.observedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoKey => $composableBuilder(
    column: $table.photoKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScoutingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoutingRecordsTable> {
  $$ScoutingRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get plotId => $composableBuilder(
    column: $table.plotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get observedOn => $composableBuilder(
    column: $table.observedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoKey => $composableBuilder(
    column: $table.photoKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoutingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoutingRecordsTable> {
  $$ScoutingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotId =>
      $composableBuilder(column: $table.plotId, builder: (column) => column);

  GeneratedColumn<String> get baharCycleId => $composableBuilder(
    column: $table.baharCycleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get observedOn => $composableBuilder(
    column: $table.observedOn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoKey =>
      $composableBuilder(column: $table.photoKey, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$ScoutingRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScoutingRecordsTable,
          ScoutingRecordRow,
          $$ScoutingRecordsTableFilterComposer,
          $$ScoutingRecordsTableOrderingComposer,
          $$ScoutingRecordsTableAnnotationComposer,
          $$ScoutingRecordsTableCreateCompanionBuilder,
          $$ScoutingRecordsTableUpdateCompanionBuilder,
          (
            ScoutingRecordRow,
            BaseReferences<
              _$AppDatabase,
              $ScoutingRecordsTable,
              ScoutingRecordRow
            >,
          ),
          ScoutingRecordRow,
          PrefetchHooks Function()
        > {
  $$ScoutingRecordsTableTableManager(
    _$AppDatabase db,
    $ScoutingRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoutingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoutingRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoutingRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plotId = const Value.absent(),
                Value<String?> baharCycleId = const Value.absent(),
                Value<DateTime> observedOn = const Value.absent(),
                Value<String> item = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> photoKey = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoutingRecordsCompanion(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                observedOn: observedOn,
                item: item,
                severity: severity,
                note: note,
                photoPath: photoPath,
                photoKey: photoKey,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plotId,
                Value<String?> baharCycleId = const Value.absent(),
                required DateTime observedOn,
                required String item,
                required String severity,
                Value<String?> note = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> photoKey = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScoutingRecordsCompanion.insert(
                id: id,
                plotId: plotId,
                baharCycleId: baharCycleId,
                observedOn: observedOn,
                item: item,
                severity: severity,
                note: note,
                photoPath: photoPath,
                photoKey: photoKey,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScoutingRecordsTable, ScoutingRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScoutingRecordsTable,
                    ScoutingRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScoutingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScoutingRecordsTable,
      ScoutingRecordRow,
      $$ScoutingRecordsTableFilterComposer,
      $$ScoutingRecordsTableOrderingComposer,
      $$ScoutingRecordsTableAnnotationComposer,
      $$ScoutingRecordsTableCreateCompanionBuilder,
      $$ScoutingRecordsTableUpdateCompanionBuilder,
      (
        ScoutingRecordRow,
        BaseReferences<_$AppDatabase, $ScoutingRecordsTable, ScoutingRecordRow>,
      ),
      ScoutingRecordRow,
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
  $$BaharCyclesTableTableManager get baharCycles =>
      $$BaharCyclesTableTableManager(_db, _db.baharCycles);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$IncomesTableTableManager get incomes =>
      $$IncomesTableTableManager(_db, _db.incomes);
  $$SprayRecordsTableTableManager get sprayRecords =>
      $$SprayRecordsTableTableManager(_db, _db.sprayRecords);
  $$InputRecordsTableTableManager get inputRecords =>
      $$InputRecordsTableTableManager(_db, _db.inputRecords);
  $$IrrigationRecordsTableTableManager get irrigationRecords =>
      $$IrrigationRecordsTableTableManager(_db, _db.irrigationRecords);
  $$HarvestRecordsTableTableManager get harvestRecords =>
      $$HarvestRecordsTableTableManager(_db, _db.harvestRecords);
  $$LabourRecordsTableTableManager get labourRecords =>
      $$LabourRecordsTableTableManager(_db, _db.labourRecords);
  $$FarmTasksTableTableManager get farmTasks =>
      $$FarmTasksTableTableManager(_db, _db.farmTasks);
  $$ScoutingRecordsTableTableManager get scoutingRecords =>
      $$ScoutingRecordsTableTableManager(_db, _db.scoutingRecords);
}
