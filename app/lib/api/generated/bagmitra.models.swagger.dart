// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

import 'dart:convert';

import 'bagmitra.enums.swagger.dart' as enums;

part 'bagmitra.models.swagger.g.dart';

@JsonSerializable(explicitToJson: true)
class Change {
  const Change({
    required this.data,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.seq,
    required this.updatedAt,
  });

  factory Change.fromJson(Map<String, dynamic> json) => _$ChangeFromJson(json);

  static const toJsonFactory = _$ChangeToJson;
  Map<String, dynamic> toJson() => _$ChangeToJson(this);

  @JsonKey(name: 'data', includeIfNull: false)
  final Map<String, dynamic> data;
  @JsonKey(name: 'entity', includeIfNull: false)
  final String entity;
  @JsonKey(name: 'entity_id', includeIfNull: false)
  final String entityId;
  @JsonKey(
    name: 'op',
    includeIfNull: false,
    toJson: changeOpToJson,
    fromJson: changeOpFromJson,
  )
  final enums.ChangeOp op;
  @JsonKey(name: 'seq', includeIfNull: false)
  final int seq;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime updatedAt;
  static const fromJsonFactory = _$ChangeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Change &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)) &&
            (identical(other.entity, entity) ||
                const DeepCollectionEquality().equals(other.entity, entity)) &&
            (identical(other.entityId, entityId) ||
                const DeepCollectionEquality().equals(
                  other.entityId,
                  entityId,
                )) &&
            (identical(other.op, op) ||
                const DeepCollectionEquality().equals(other.op, op)) &&
            (identical(other.seq, seq) ||
                const DeepCollectionEquality().equals(other.seq, seq)) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(data) ^
      const DeepCollectionEquality().hash(entity) ^
      const DeepCollectionEquality().hash(entityId) ^
      const DeepCollectionEquality().hash(op) ^
      const DeepCollectionEquality().hash(seq) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      runtimeType.hashCode;
}

extension $ChangeExtension on Change {
  Change copyWith({
    Map<String, dynamic>? data,
    String? entity,
    String? entityId,
    enums.ChangeOp? op,
    int? seq,
    DateTime? updatedAt,
  }) {
    return Change(
      data: data ?? this.data,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      seq: seq ?? this.seq,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Change copyWithWrapped({
    Wrapped<Map<String, dynamic>>? data,
    Wrapped<String>? entity,
    Wrapped<String>? entityId,
    Wrapped<enums.ChangeOp>? op,
    Wrapped<int>? seq,
    Wrapped<DateTime>? updatedAt,
  }) {
    return Change(
      data: (data != null ? data.value : this.data),
      entity: (entity != null ? entity.value : this.entity),
      entityId: (entityId != null ? entityId.value : this.entityId),
      op: (op != null ? op.value : this.op),
      seq: (seq != null ? seq.value : this.seq),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ErrorBody {
  const ErrorBody({
    required this.code,
    required this.message,
    required this.requestId,
  });

  factory ErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ErrorBodyFromJson(json);

  static const toJsonFactory = _$ErrorBodyToJson;
  Map<String, dynamic> toJson() => _$ErrorBodyToJson(this);

  @JsonKey(name: 'code', includeIfNull: false)
  final String code;
  @JsonKey(name: 'message', includeIfNull: false)
  final String message;
  @JsonKey(name: 'request_id', includeIfNull: false)
  final String requestId;
  static const fromJsonFactory = _$ErrorBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ErrorBody &&
            (identical(other.code, code) ||
                const DeepCollectionEquality().equals(other.code, code)) &&
            (identical(other.message, message) ||
                const DeepCollectionEquality().equals(
                  other.message,
                  message,
                )) &&
            (identical(other.requestId, requestId) ||
                const DeepCollectionEquality().equals(
                  other.requestId,
                  requestId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(code) ^
      const DeepCollectionEquality().hash(message) ^
      const DeepCollectionEquality().hash(requestId) ^
      runtimeType.hashCode;
}

extension $ErrorBodyExtension on ErrorBody {
  ErrorBody copyWith({String? code, String? message, String? requestId}) {
    return ErrorBody(
      code: code ?? this.code,
      message: message ?? this.message,
      requestId: requestId ?? this.requestId,
    );
  }

  ErrorBody copyWithWrapped({
    Wrapped<String>? code,
    Wrapped<String>? message,
    Wrapped<String>? requestId,
  }) {
    return ErrorBody(
      code: (code != null ? code.value : this.code),
      message: (message != null ? message.value : this.message),
      requestId: (requestId != null ? requestId.value : this.requestId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ErrorResponse {
  const ErrorResponse({required this.error});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  static const toJsonFactory = _$ErrorResponseToJson;
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @JsonKey(name: 'error', includeIfNull: false)
  final ErrorBody error;
  static const fromJsonFactory = _$ErrorResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ErrorResponse &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(error) ^ runtimeType.hashCode;
}

extension $ErrorResponseExtension on ErrorResponse {
  ErrorResponse copyWith({ErrorBody? error}) {
    return ErrorResponse(error: error ?? this.error);
  }

  ErrorResponse copyWithWrapped({Wrapped<ErrorBody>? error}) {
    return ErrorResponse(error: (error != null ? error.value : this.error));
  }
}

@JsonSerializable(explicitToJson: true)
class FarmerProfile {
  const FarmerProfile({
    required this.consentDataProcessing,
    required this.consentWhatsapp,
    required this.displayName,
    required this.district,
    required this.id,
    required this.language,
    required this.phone,
    required this.taluka,
    required this.village,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) =>
      _$FarmerProfileFromJson(json);

  static const toJsonFactory = _$FarmerProfileToJson;
  Map<String, dynamic> toJson() => _$FarmerProfileToJson(this);

  @JsonKey(name: 'consent_data_processing', includeIfNull: false)
  final bool consentDataProcessing;
  @JsonKey(name: 'consent_whatsapp', includeIfNull: false)
  final bool consentWhatsapp;
  @JsonKey(name: 'display_name', includeIfNull: false)
  final String? displayName;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'language', includeIfNull: false)
  final String language;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String? phone;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'village', includeIfNull: false)
  final String? village;
  static const fromJsonFactory = _$FarmerProfileFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FarmerProfile &&
            (identical(other.consentDataProcessing, consentDataProcessing) ||
                const DeepCollectionEquality().equals(
                  other.consentDataProcessing,
                  consentDataProcessing,
                )) &&
            (identical(other.consentWhatsapp, consentWhatsapp) ||
                const DeepCollectionEquality().equals(
                  other.consentWhatsapp,
                  consentWhatsapp,
                )) &&
            (identical(other.displayName, displayName) ||
                const DeepCollectionEquality().equals(
                  other.displayName,
                  displayName,
                )) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.language, language) ||
                const DeepCollectionEquality().equals(
                  other.language,
                  language,
                )) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(consentDataProcessing) ^
      const DeepCollectionEquality().hash(consentWhatsapp) ^
      const DeepCollectionEquality().hash(displayName) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(language) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $FarmerProfileExtension on FarmerProfile {
  FarmerProfile copyWith({
    bool? consentDataProcessing,
    bool? consentWhatsapp,
    String? displayName,
    String? district,
    String? id,
    String? language,
    String? phone,
    String? taluka,
    String? village,
  }) {
    return FarmerProfile(
      consentDataProcessing:
          consentDataProcessing ?? this.consentDataProcessing,
      consentWhatsapp: consentWhatsapp ?? this.consentWhatsapp,
      displayName: displayName ?? this.displayName,
      district: district ?? this.district,
      id: id ?? this.id,
      language: language ?? this.language,
      phone: phone ?? this.phone,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
    );
  }

  FarmerProfile copyWithWrapped({
    Wrapped<bool>? consentDataProcessing,
    Wrapped<bool>? consentWhatsapp,
    Wrapped<String?>? displayName,
    Wrapped<String?>? district,
    Wrapped<String>? id,
    Wrapped<String>? language,
    Wrapped<String?>? phone,
    Wrapped<String?>? taluka,
    Wrapped<String?>? village,
  }) {
    return FarmerProfile(
      consentDataProcessing: (consentDataProcessing != null
          ? consentDataProcessing.value
          : this.consentDataProcessing),
      consentWhatsapp: (consentWhatsapp != null
          ? consentWhatsapp.value
          : this.consentWhatsapp),
      displayName: (displayName != null ? displayName.value : this.displayName),
      district: (district != null ? district.value : this.district),
      id: (id != null ? id.value : this.id),
      language: (language != null ? language.value : this.language),
      phone: (phone != null ? phone.value : this.phone),
      taluka: (taluka != null ? taluka.value : this.taluka),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class HTTPValidationError {
  const HTTPValidationError({this.detail});

  factory HTTPValidationError.fromJson(Map<String, dynamic> json) =>
      _$HTTPValidationErrorFromJson(json);

  static const toJsonFactory = _$HTTPValidationErrorToJson;
  Map<String, dynamic> toJson() => _$HTTPValidationErrorToJson(this);

  @JsonKey(
    name: 'detail',
    includeIfNull: false,
    defaultValue: <ValidationError>[],
  )
  final List<ValidationError>? detail;
  static const fromJsonFactory = _$HTTPValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is HTTPValidationError &&
            (identical(other.detail, detail) ||
                const DeepCollectionEquality().equals(other.detail, detail)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(detail) ^ runtimeType.hashCode;
}

extension $HTTPValidationErrorExtension on HTTPValidationError {
  HTTPValidationError copyWith({List<ValidationError>? detail}) {
    return HTTPValidationError(detail: detail ?? this.detail);
  }

  HTTPValidationError copyWithWrapped({
    Wrapped<List<ValidationError>?>? detail,
  }) {
    return HTTPValidationError(
      detail: (detail != null ? detail.value : this.detail),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LiveResponse {
  const LiveResponse({required this.product, required this.status});

  factory LiveResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveResponseFromJson(json);

  static const toJsonFactory = _$LiveResponseToJson;
  Map<String, dynamic> toJson() => _$LiveResponseToJson(this);

  @JsonKey(name: 'product', includeIfNull: false)
  final String product;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  static const fromJsonFactory = _$LiveResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LiveResponse &&
            (identical(other.product, product) ||
                const DeepCollectionEquality().equals(
                  other.product,
                  product,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(product) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $LiveResponseExtension on LiveResponse {
  LiveResponse copyWith({String? product, String? status}) {
    return LiveResponse(
      product: product ?? this.product,
      status: status ?? this.status,
    );
  }

  LiveResponse copyWithWrapped({
    Wrapped<String>? product,
    Wrapped<String>? status,
  }) {
    return LiveResponse(
      product: (product != null ? product.value : this.product),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Mutation {
  const Mutation({
    required this.clientMutationId,
    required this.clientUpdatedAt,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
  });

  factory Mutation.fromJson(Map<String, dynamic> json) =>
      _$MutationFromJson(json);

  static const toJsonFactory = _$MutationToJson;
  Map<String, dynamic> toJson() => _$MutationToJson(this);

  @JsonKey(name: 'client_mutation_id', includeIfNull: false)
  final String clientMutationId;
  @JsonKey(name: 'client_updated_at', includeIfNull: false)
  final DateTime clientUpdatedAt;
  @JsonKey(name: 'entity', includeIfNull: false)
  final String entity;
  @JsonKey(name: 'entity_id', includeIfNull: false)
  final String entityId;
  @JsonKey(
    name: 'op',
    includeIfNull: false,
    toJson: mutationOpToJson,
    fromJson: mutationOpFromJson,
  )
  final enums.MutationOp op;
  @JsonKey(name: 'payload', includeIfNull: false)
  final Map<String, dynamic> payload;
  static const fromJsonFactory = _$MutationFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Mutation &&
            (identical(other.clientMutationId, clientMutationId) ||
                const DeepCollectionEquality().equals(
                  other.clientMutationId,
                  clientMutationId,
                )) &&
            (identical(other.clientUpdatedAt, clientUpdatedAt) ||
                const DeepCollectionEquality().equals(
                  other.clientUpdatedAt,
                  clientUpdatedAt,
                )) &&
            (identical(other.entity, entity) ||
                const DeepCollectionEquality().equals(other.entity, entity)) &&
            (identical(other.entityId, entityId) ||
                const DeepCollectionEquality().equals(
                  other.entityId,
                  entityId,
                )) &&
            (identical(other.op, op) ||
                const DeepCollectionEquality().equals(other.op, op)) &&
            (identical(other.payload, payload) ||
                const DeepCollectionEquality().equals(other.payload, payload)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(clientMutationId) ^
      const DeepCollectionEquality().hash(clientUpdatedAt) ^
      const DeepCollectionEquality().hash(entity) ^
      const DeepCollectionEquality().hash(entityId) ^
      const DeepCollectionEquality().hash(op) ^
      const DeepCollectionEquality().hash(payload) ^
      runtimeType.hashCode;
}

extension $MutationExtension on Mutation {
  Mutation copyWith({
    String? clientMutationId,
    DateTime? clientUpdatedAt,
    String? entity,
    String? entityId,
    enums.MutationOp? op,
    Map<String, dynamic>? payload,
  }) {
    return Mutation(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
    );
  }

  Mutation copyWithWrapped({
    Wrapped<String>? clientMutationId,
    Wrapped<DateTime>? clientUpdatedAt,
    Wrapped<String>? entity,
    Wrapped<String>? entityId,
    Wrapped<enums.MutationOp>? op,
    Wrapped<Map<String, dynamic>>? payload,
  }) {
    return Mutation(
      clientMutationId: (clientMutationId != null
          ? clientMutationId.value
          : this.clientMutationId),
      clientUpdatedAt: (clientUpdatedAt != null
          ? clientUpdatedAt.value
          : this.clientUpdatedAt),
      entity: (entity != null ? entity.value : this.entity),
      entityId: (entityId != null ? entityId.value : this.entityId),
      op: (op != null ? op.value : this.op),
      payload: (payload != null ? payload.value : this.payload),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class MutationResult {
  const MutationResult({
    required this.clientMutationId,
    this.error,
    required this.status,
  });

  factory MutationResult.fromJson(Map<String, dynamic> json) =>
      _$MutationResultFromJson(json);

  static const toJsonFactory = _$MutationResultToJson;
  Map<String, dynamic> toJson() => _$MutationResultToJson(this);

  @JsonKey(name: 'client_mutation_id', includeIfNull: false)
  final String clientMutationId;
  @JsonKey(name: 'error', includeIfNull: false)
  final String? error;
  @JsonKey(
    name: 'status',
    includeIfNull: false,
    toJson: mutationResultStatusToJson,
    fromJson: mutationResultStatusFromJson,
  )
  final enums.MutationResultStatus status;
  static const fromJsonFactory = _$MutationResultFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MutationResult &&
            (identical(other.clientMutationId, clientMutationId) ||
                const DeepCollectionEquality().equals(
                  other.clientMutationId,
                  clientMutationId,
                )) &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(clientMutationId) ^
      const DeepCollectionEquality().hash(error) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $MutationResultExtension on MutationResult {
  MutationResult copyWith({
    String? clientMutationId,
    String? error,
    enums.MutationResultStatus? status,
  }) {
    return MutationResult(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }

  MutationResult copyWithWrapped({
    Wrapped<String>? clientMutationId,
    Wrapped<String?>? error,
    Wrapped<enums.MutationResultStatus>? status,
  }) {
    return MutationResult(
      clientMutationId: (clientMutationId != null
          ? clientMutationId.value
          : this.clientMutationId),
      error: (error != null ? error.value : this.error),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PullResponse {
  const PullResponse({required this.changes, required this.cursor});

  factory PullResponse.fromJson(Map<String, dynamic> json) =>
      _$PullResponseFromJson(json);

  static const toJsonFactory = _$PullResponseToJson;
  Map<String, dynamic> toJson() => _$PullResponseToJson(this);

  @JsonKey(name: 'changes', includeIfNull: false, defaultValue: <Change>[])
  final List<Change> changes;
  @JsonKey(name: 'cursor', includeIfNull: false)
  final int cursor;
  static const fromJsonFactory = _$PullResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PullResponse &&
            (identical(other.changes, changes) ||
                const DeepCollectionEquality().equals(
                  other.changes,
                  changes,
                )) &&
            (identical(other.cursor, cursor) ||
                const DeepCollectionEquality().equals(other.cursor, cursor)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(changes) ^
      const DeepCollectionEquality().hash(cursor) ^
      runtimeType.hashCode;
}

extension $PullResponseExtension on PullResponse {
  PullResponse copyWith({List<Change>? changes, int? cursor}) {
    return PullResponse(
      changes: changes ?? this.changes,
      cursor: cursor ?? this.cursor,
    );
  }

  PullResponse copyWithWrapped({
    Wrapped<List<Change>>? changes,
    Wrapped<int>? cursor,
  }) {
    return PullResponse(
      changes: (changes != null ? changes.value : this.changes),
      cursor: (cursor != null ? cursor.value : this.cursor),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PushRequest {
  const PushRequest({required this.mutations});

  factory PushRequest.fromJson(Map<String, dynamic> json) =>
      _$PushRequestFromJson(json);

  static const toJsonFactory = _$PushRequestToJson;
  Map<String, dynamic> toJson() => _$PushRequestToJson(this);

  @JsonKey(name: 'mutations', includeIfNull: false, defaultValue: <Mutation>[])
  final List<Mutation> mutations;
  static const fromJsonFactory = _$PushRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PushRequest &&
            (identical(other.mutations, mutations) ||
                const DeepCollectionEquality().equals(
                  other.mutations,
                  mutations,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(mutations) ^ runtimeType.hashCode;
}

extension $PushRequestExtension on PushRequest {
  PushRequest copyWith({List<Mutation>? mutations}) {
    return PushRequest(mutations: mutations ?? this.mutations);
  }

  PushRequest copyWithWrapped({Wrapped<List<Mutation>>? mutations}) {
    return PushRequest(
      mutations: (mutations != null ? mutations.value : this.mutations),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PushResponse {
  const PushResponse({required this.results});

  factory PushResponse.fromJson(Map<String, dynamic> json) =>
      _$PushResponseFromJson(json);

  static const toJsonFactory = _$PushResponseToJson;
  Map<String, dynamic> toJson() => _$PushResponseToJson(this);

  @JsonKey(
    name: 'results',
    includeIfNull: false,
    defaultValue: <MutationResult>[],
  )
  final List<MutationResult> results;
  static const fromJsonFactory = _$PushResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PushResponse &&
            (identical(other.results, results) ||
                const DeepCollectionEquality().equals(other.results, results)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(results) ^ runtimeType.hashCode;
}

extension $PushResponseExtension on PushResponse {
  PushResponse copyWith({List<MutationResult>? results}) {
    return PushResponse(results: results ?? this.results);
  }

  PushResponse copyWithWrapped({Wrapped<List<MutationResult>>? results}) {
    return PushResponse(
      results: (results != null ? results.value : this.results),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReadyResponse {
  const ReadyResponse({required this.database, required this.status});

  factory ReadyResponse.fromJson(Map<String, dynamic> json) =>
      _$ReadyResponseFromJson(json);

  static const toJsonFactory = _$ReadyResponseToJson;
  Map<String, dynamic> toJson() => _$ReadyResponseToJson(this);

  @JsonKey(name: 'database', includeIfNull: false)
  final String database;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  static const fromJsonFactory = _$ReadyResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReadyResponse &&
            (identical(other.database, database) ||
                const DeepCollectionEquality().equals(
                  other.database,
                  database,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(database) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $ReadyResponseExtension on ReadyResponse {
  ReadyResponse copyWith({String? database, String? status}) {
    return ReadyResponse(
      database: database ?? this.database,
      status: status ?? this.status,
    );
  }

  ReadyResponse copyWithWrapped({
    Wrapped<String>? database,
    Wrapped<String>? status,
  }) {
    return ReadyResponse(
      database: (database != null ? database.value : this.database),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class StageTemplate {
  const StageTemplate({
    required this.bahar,
    required this.crop,
    required this.id,
    required this.labels,
    required this.sources,
    required this.stages,
    required this.updatedAt,
    required this.version,
  });

  factory StageTemplate.fromJson(Map<String, dynamic> json) =>
      _$StageTemplateFromJson(json);

  static const toJsonFactory = _$StageTemplateToJson;
  Map<String, dynamic> toJson() => _$StageTemplateToJson(this);

  @JsonKey(name: 'bahar', includeIfNull: false)
  final String bahar;
  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'labels', includeIfNull: false)
  final Map<String, dynamic> labels;
  @JsonKey(name: 'sources', includeIfNull: false)
  final Map<String, dynamic> sources;
  @JsonKey(
    name: 'stages',
    includeIfNull: false,
    defaultValue: <TemplateStage>[],
  )
  final List<TemplateStage> stages;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime updatedAt;
  @JsonKey(name: 'version', includeIfNull: false)
  final int version;
  static const fromJsonFactory = _$StageTemplateFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StageTemplate &&
            (identical(other.bahar, bahar) ||
                const DeepCollectionEquality().equals(other.bahar, bahar)) &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)) &&
            (identical(other.sources, sources) ||
                const DeepCollectionEquality().equals(
                  other.sources,
                  sources,
                )) &&
            (identical(other.stages, stages) ||
                const DeepCollectionEquality().equals(other.stages, stages)) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bahar) ^
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(labels) ^
      const DeepCollectionEquality().hash(sources) ^
      const DeepCollectionEquality().hash(stages) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $StageTemplateExtension on StageTemplate {
  StageTemplate copyWith({
    String? bahar,
    String? crop,
    String? id,
    Map<String, dynamic>? labels,
    Map<String, dynamic>? sources,
    List<TemplateStage>? stages,
    DateTime? updatedAt,
    int? version,
  }) {
    return StageTemplate(
      bahar: bahar ?? this.bahar,
      crop: crop ?? this.crop,
      id: id ?? this.id,
      labels: labels ?? this.labels,
      sources: sources ?? this.sources,
      stages: stages ?? this.stages,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  StageTemplate copyWithWrapped({
    Wrapped<String>? bahar,
    Wrapped<String>? crop,
    Wrapped<String>? id,
    Wrapped<Map<String, dynamic>>? labels,
    Wrapped<Map<String, dynamic>>? sources,
    Wrapped<List<TemplateStage>>? stages,
    Wrapped<DateTime>? updatedAt,
    Wrapped<int>? version,
  }) {
    return StageTemplate(
      bahar: (bahar != null ? bahar.value : this.bahar),
      crop: (crop != null ? crop.value : this.crop),
      id: (id != null ? id.value : this.id),
      labels: (labels != null ? labels.value : this.labels),
      sources: (sources != null ? sources.value : this.sources),
      stages: (stages != null ? stages.value : this.stages),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class StageTemplatesResponse {
  const StageTemplatesResponse({required this.templates});

  factory StageTemplatesResponse.fromJson(Map<String, dynamic> json) =>
      _$StageTemplatesResponseFromJson(json);

  static const toJsonFactory = _$StageTemplatesResponseToJson;
  Map<String, dynamic> toJson() => _$StageTemplatesResponseToJson(this);

  @JsonKey(
    name: 'templates',
    includeIfNull: false,
    defaultValue: <StageTemplate>[],
  )
  final List<StageTemplate> templates;
  static const fromJsonFactory = _$StageTemplatesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StageTemplatesResponse &&
            (identical(other.templates, templates) ||
                const DeepCollectionEquality().equals(
                  other.templates,
                  templates,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(templates) ^ runtimeType.hashCode;
}

extension $StageTemplatesResponseExtension on StageTemplatesResponse {
  StageTemplatesResponse copyWith({List<StageTemplate>? templates}) {
    return StageTemplatesResponse(templates: templates ?? this.templates);
  }

  StageTemplatesResponse copyWithWrapped({
    Wrapped<List<StageTemplate>>? templates,
  }) {
    return StageTemplatesResponse(
      templates: (templates != null ? templates.value : this.templates),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class TemplateStage {
  const TemplateStage({
    required this.anchor,
    required this.key,
    required this.labels,
    required this.offsetDaysMax,
    required this.offsetDaysMin,
    required this.sourceIds,
  });

  factory TemplateStage.fromJson(Map<String, dynamic> json) =>
      _$TemplateStageFromJson(json);

  static const toJsonFactory = _$TemplateStageToJson;
  Map<String, dynamic> toJson() => _$TemplateStageToJson(this);

  @JsonKey(name: 'anchor', includeIfNull: false)
  final String anchor;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'labels', includeIfNull: false)
  final Map<String, dynamic> labels;
  @JsonKey(name: 'offset_days_max', includeIfNull: false)
  final int offsetDaysMax;
  @JsonKey(name: 'offset_days_min', includeIfNull: false)
  final int offsetDaysMin;
  @JsonKey(name: 'source_ids', includeIfNull: false, defaultValue: <String>[])
  final List<String> sourceIds;
  static const fromJsonFactory = _$TemplateStageFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TemplateStage &&
            (identical(other.anchor, anchor) ||
                const DeepCollectionEquality().equals(other.anchor, anchor)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)) &&
            (identical(other.offsetDaysMax, offsetDaysMax) ||
                const DeepCollectionEquality().equals(
                  other.offsetDaysMax,
                  offsetDaysMax,
                )) &&
            (identical(other.offsetDaysMin, offsetDaysMin) ||
                const DeepCollectionEquality().equals(
                  other.offsetDaysMin,
                  offsetDaysMin,
                )) &&
            (identical(other.sourceIds, sourceIds) ||
                const DeepCollectionEquality().equals(
                  other.sourceIds,
                  sourceIds,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(anchor) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(labels) ^
      const DeepCollectionEquality().hash(offsetDaysMax) ^
      const DeepCollectionEquality().hash(offsetDaysMin) ^
      const DeepCollectionEquality().hash(sourceIds) ^
      runtimeType.hashCode;
}

extension $TemplateStageExtension on TemplateStage {
  TemplateStage copyWith({
    String? anchor,
    String? key,
    Map<String, dynamic>? labels,
    int? offsetDaysMax,
    int? offsetDaysMin,
    List<String>? sourceIds,
  }) {
    return TemplateStage(
      anchor: anchor ?? this.anchor,
      key: key ?? this.key,
      labels: labels ?? this.labels,
      offsetDaysMax: offsetDaysMax ?? this.offsetDaysMax,
      offsetDaysMin: offsetDaysMin ?? this.offsetDaysMin,
      sourceIds: sourceIds ?? this.sourceIds,
    );
  }

  TemplateStage copyWithWrapped({
    Wrapped<String>? anchor,
    Wrapped<String>? key,
    Wrapped<Map<String, dynamic>>? labels,
    Wrapped<int>? offsetDaysMax,
    Wrapped<int>? offsetDaysMin,
    Wrapped<List<String>>? sourceIds,
  }) {
    return TemplateStage(
      anchor: (anchor != null ? anchor.value : this.anchor),
      key: (key != null ? key.value : this.key),
      labels: (labels != null ? labels.value : this.labels),
      offsetDaysMax: (offsetDaysMax != null
          ? offsetDaysMax.value
          : this.offsetDaysMax),
      offsetDaysMin: (offsetDaysMin != null
          ? offsetDaysMin.value
          : this.offsetDaysMin),
      sourceIds: (sourceIds != null ? sourceIds.value : this.sourceIds),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ValidationError {
  const ValidationError({
    required this.loc,
    required this.msg,
    required this.type,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);

  static const toJsonFactory = _$ValidationErrorToJson;
  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @JsonKey(name: 'loc', includeIfNull: false, defaultValue: <Object>[])
  final List<Object> loc;
  @JsonKey(name: 'msg', includeIfNull: false)
  final String msg;
  @JsonKey(name: 'type', includeIfNull: false)
  final String type;
  static const fromJsonFactory = _$ValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ValidationError &&
            (identical(other.loc, loc) ||
                const DeepCollectionEquality().equals(other.loc, loc)) &&
            (identical(other.msg, msg) ||
                const DeepCollectionEquality().equals(other.msg, msg)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(loc) ^
      const DeepCollectionEquality().hash(msg) ^
      const DeepCollectionEquality().hash(type) ^
      runtimeType.hashCode;
}

extension $ValidationErrorExtension on ValidationError {
  ValidationError copyWith({List<Object>? loc, String? msg, String? type}) {
    return ValidationError(
      loc: loc ?? this.loc,
      msg: msg ?? this.msg,
      type: type ?? this.type,
    );
  }

  ValidationError copyWithWrapped({
    Wrapped<List<Object>>? loc,
    Wrapped<String>? msg,
    Wrapped<String>? type,
  }) {
    return ValidationError(
      loc: (loc != null ? loc.value : this.loc),
      msg: (msg != null ? msg.value : this.msg),
      type: (type != null ? type.value : this.type),
    );
  }
}

String? changeOpNullableToJson(enums.ChangeOp? changeOp) {
  return changeOp?.value;
}

String? changeOpToJson(enums.ChangeOp changeOp) {
  return changeOp.value;
}

enums.ChangeOp changeOpFromJson(
  Object? changeOp, [
  enums.ChangeOp? defaultValue,
]) {
  return enums.ChangeOp.values.firstWhereOrNull((e) => e.value == changeOp) ??
      defaultValue ??
      enums.ChangeOp.swaggerGeneratedUnknown;
}

enums.ChangeOp? changeOpNullableFromJson(
  Object? changeOp, [
  enums.ChangeOp? defaultValue,
]) {
  if (changeOp == null) {
    return null;
  }
  return enums.ChangeOp.values.firstWhereOrNull((e) => e.value == changeOp) ??
      defaultValue;
}

String changeOpExplodedListToJson(List<enums.ChangeOp>? changeOp) {
  return changeOp?.map((e) => e.value!).join(',') ?? '';
}

List<String> changeOpListToJson(List<enums.ChangeOp>? changeOp) {
  if (changeOp == null) {
    return [];
  }

  return changeOp.map((e) => e.value!).toList();
}

List<enums.ChangeOp> changeOpListFromJson(
  List? changeOp, [
  List<enums.ChangeOp>? defaultValue,
]) {
  if (changeOp == null) {
    return defaultValue ?? [];
  }

  return changeOp.map((e) => changeOpFromJson(e.toString())).toList();
}

List<enums.ChangeOp>? changeOpNullableListFromJson(
  List? changeOp, [
  List<enums.ChangeOp>? defaultValue,
]) {
  if (changeOp == null) {
    return defaultValue;
  }

  return changeOp.map((e) => changeOpFromJson(e.toString())).toList();
}

String? mutationOpNullableToJson(enums.MutationOp? mutationOp) {
  return mutationOp?.value;
}

String? mutationOpToJson(enums.MutationOp mutationOp) {
  return mutationOp.value;
}

enums.MutationOp mutationOpFromJson(
  Object? mutationOp, [
  enums.MutationOp? defaultValue,
]) {
  return enums.MutationOp.values.firstWhereOrNull(
        (e) => e.value == mutationOp,
      ) ??
      defaultValue ??
      enums.MutationOp.swaggerGeneratedUnknown;
}

enums.MutationOp? mutationOpNullableFromJson(
  Object? mutationOp, [
  enums.MutationOp? defaultValue,
]) {
  if (mutationOp == null) {
    return null;
  }
  return enums.MutationOp.values.firstWhereOrNull(
        (e) => e.value == mutationOp,
      ) ??
      defaultValue;
}

String mutationOpExplodedListToJson(List<enums.MutationOp>? mutationOp) {
  return mutationOp?.map((e) => e.value!).join(',') ?? '';
}

List<String> mutationOpListToJson(List<enums.MutationOp>? mutationOp) {
  if (mutationOp == null) {
    return [];
  }

  return mutationOp.map((e) => e.value!).toList();
}

List<enums.MutationOp> mutationOpListFromJson(
  List? mutationOp, [
  List<enums.MutationOp>? defaultValue,
]) {
  if (mutationOp == null) {
    return defaultValue ?? [];
  }

  return mutationOp.map((e) => mutationOpFromJson(e.toString())).toList();
}

List<enums.MutationOp>? mutationOpNullableListFromJson(
  List? mutationOp, [
  List<enums.MutationOp>? defaultValue,
]) {
  if (mutationOp == null) {
    return defaultValue;
  }

  return mutationOp.map((e) => mutationOpFromJson(e.toString())).toList();
}

String? mutationResultStatusNullableToJson(
  enums.MutationResultStatus? mutationResultStatus,
) {
  return mutationResultStatus?.value;
}

String? mutationResultStatusToJson(
  enums.MutationResultStatus mutationResultStatus,
) {
  return mutationResultStatus.value;
}

enums.MutationResultStatus mutationResultStatusFromJson(
  Object? mutationResultStatus, [
  enums.MutationResultStatus? defaultValue,
]) {
  return enums.MutationResultStatus.values.firstWhereOrNull(
        (e) => e.value == mutationResultStatus,
      ) ??
      defaultValue ??
      enums.MutationResultStatus.swaggerGeneratedUnknown;
}

enums.MutationResultStatus? mutationResultStatusNullableFromJson(
  Object? mutationResultStatus, [
  enums.MutationResultStatus? defaultValue,
]) {
  if (mutationResultStatus == null) {
    return null;
  }
  return enums.MutationResultStatus.values.firstWhereOrNull(
        (e) => e.value == mutationResultStatus,
      ) ??
      defaultValue;
}

String mutationResultStatusExplodedListToJson(
  List<enums.MutationResultStatus>? mutationResultStatus,
) {
  return mutationResultStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> mutationResultStatusListToJson(
  List<enums.MutationResultStatus>? mutationResultStatus,
) {
  if (mutationResultStatus == null) {
    return [];
  }

  return mutationResultStatus.map((e) => e.value!).toList();
}

List<enums.MutationResultStatus> mutationResultStatusListFromJson(
  List? mutationResultStatus, [
  List<enums.MutationResultStatus>? defaultValue,
]) {
  if (mutationResultStatus == null) {
    return defaultValue ?? [];
  }

  return mutationResultStatus
      .map((e) => mutationResultStatusFromJson(e.toString()))
      .toList();
}

List<enums.MutationResultStatus>? mutationResultStatusNullableListFromJson(
  List? mutationResultStatus, [
  List<enums.MutationResultStatus>? defaultValue,
]) {
  if (mutationResultStatus == null) {
    return defaultValue;
  }

  return mutationResultStatus
      .map((e) => mutationResultStatusFromJson(e.toString()))
      .toList();
}

// ignore: unused_element
String? _dateToJson(DateTime? date) {
  if (date == null) {
    return null;
  }

  final year = date.year.toString();
  final month = date.month < 10 ? '0${date.month}' : date.month.toString();
  final day = date.day < 10 ? '0${date.day}' : date.day.toString();

  return '$year-$month-$day';
}

class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}
