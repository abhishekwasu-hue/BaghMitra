// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

import 'dart:convert';

import 'bagmitra.enums.swagger.dart' as enums;

part 'bagmitra.models.swagger.g.dart';

@JsonSerializable(explicitToJson: true)
class AlertOut {
  const AlertOut({
    required this.cardId,
    required this.createdAt,
    required this.detail,
    required this.id,
    required this.kind,
  });

  factory AlertOut.fromJson(Map<String, dynamic> json) =>
      _$AlertOutFromJson(json);

  static const toJsonFactory = _$AlertOutToJson;
  Map<String, dynamic> toJson() => _$AlertOutToJson(this);

  @JsonKey(name: 'card_id', includeIfNull: false)
  final String? cardId;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'detail', includeIfNull: false)
  final String detail;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  static const fromJsonFactory = _$AlertOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AlertOut &&
            (identical(other.cardId, cardId) ||
                const DeepCollectionEquality().equals(other.cardId, cardId)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.detail, detail) ||
                const DeepCollectionEquality().equals(other.detail, detail)) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cardId) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(detail) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(kind) ^
      runtimeType.hashCode;
}

extension $AlertOutExtension on AlertOut {
  AlertOut copyWith({
    String? cardId,
    DateTime? createdAt,
    String? detail,
    String? id,
    String? kind,
  }) {
    return AlertOut(
      cardId: cardId ?? this.cardId,
      createdAt: createdAt ?? this.createdAt,
      detail: detail ?? this.detail,
      id: id ?? this.id,
      kind: kind ?? this.kind,
    );
  }

  AlertOut copyWithWrapped({
    Wrapped<String?>? cardId,
    Wrapped<DateTime>? createdAt,
    Wrapped<String>? detail,
    Wrapped<String>? id,
    Wrapped<String>? kind,
  }) {
    return AlertOut(
      cardId: (cardId != null ? cardId.value : this.cardId),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      detail: (detail != null ? detail.value : this.detail),
      id: (id != null ? id.value : this.id),
      kind: (kind != null ? kind.value : this.kind),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AlertsResponse {
  const AlertsResponse({required this.alerts});

  factory AlertsResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertsResponseFromJson(json);

  static const toJsonFactory = _$AlertsResponseToJson;
  Map<String, dynamic> toJson() => _$AlertsResponseToJson(this);

  @JsonKey(name: 'alerts', includeIfNull: false, defaultValue: <AlertOut>[])
  final List<AlertOut> alerts;
  static const fromJsonFactory = _$AlertsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AlertsResponse &&
            (identical(other.alerts, alerts) ||
                const DeepCollectionEquality().equals(other.alerts, alerts)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(alerts) ^ runtimeType.hashCode;
}

extension $AlertsResponseExtension on AlertsResponse {
  AlertsResponse copyWith({List<AlertOut>? alerts}) {
    return AlertsResponse(alerts: alerts ?? this.alerts);
  }

  AlertsResponse copyWithWrapped({Wrapped<List<AlertOut>>? alerts}) {
    return AlertsResponse(
      alerts: (alerts != null ? alerts.value : this.alerts),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CardOut {
  const CardOut({
    required this.crop,
    required this.hasChemicalOptions,
    required this.id,
    required this.reviewDueAt,
    required this.status,
    required this.title,
    required this.topic,
    required this.version,
  });

  factory CardOut.fromJson(Map<String, dynamic> json) =>
      _$CardOutFromJson(json);

  static const toJsonFactory = _$CardOutToJson;
  Map<String, dynamic> toJson() => _$CardOutToJson(this);

  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'has_chemical_options', includeIfNull: false)
  final bool hasChemicalOptions;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'review_due_at', includeIfNull: false)
  final DateTime? reviewDueAt;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(name: 'topic', includeIfNull: false)
  final String topic;
  @JsonKey(name: 'version', includeIfNull: false)
  final int version;
  static const fromJsonFactory = _$CardOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CardOut &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.hasChemicalOptions, hasChemicalOptions) ||
                const DeepCollectionEquality().equals(
                  other.hasChemicalOptions,
                  hasChemicalOptions,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.reviewDueAt, reviewDueAt) ||
                const DeepCollectionEquality().equals(
                  other.reviewDueAt,
                  reviewDueAt,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.topic, topic) ||
                const DeepCollectionEquality().equals(other.topic, topic)) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(hasChemicalOptions) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(reviewDueAt) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(topic) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $CardOutExtension on CardOut {
  CardOut copyWith({
    String? crop,
    bool? hasChemicalOptions,
    String? id,
    DateTime? reviewDueAt,
    String? status,
    String? title,
    String? topic,
    int? version,
  }) {
    return CardOut(
      crop: crop ?? this.crop,
      hasChemicalOptions: hasChemicalOptions ?? this.hasChemicalOptions,
      id: id ?? this.id,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
      status: status ?? this.status,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      version: version ?? this.version,
    );
  }

  CardOut copyWithWrapped({
    Wrapped<String>? crop,
    Wrapped<bool>? hasChemicalOptions,
    Wrapped<String>? id,
    Wrapped<DateTime?>? reviewDueAt,
    Wrapped<String>? status,
    Wrapped<String>? title,
    Wrapped<String>? topic,
    Wrapped<int>? version,
  }) {
    return CardOut(
      crop: (crop != null ? crop.value : this.crop),
      hasChemicalOptions: (hasChemicalOptions != null
          ? hasChemicalOptions.value
          : this.hasChemicalOptions),
      id: (id != null ? id.value : this.id),
      reviewDueAt: (reviewDueAt != null ? reviewDueAt.value : this.reviewDueAt),
      status: (status != null ? status.value : this.status),
      title: (title != null ? title.value : this.title),
      topic: (topic != null ? topic.value : this.topic),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CardsResponse {
  const CardsResponse({required this.cards});

  factory CardsResponse.fromJson(Map<String, dynamic> json) =>
      _$CardsResponseFromJson(json);

  static const toJsonFactory = _$CardsResponseToJson;
  Map<String, dynamic> toJson() => _$CardsResponseToJson(this);

  @JsonKey(name: 'cards', includeIfNull: false, defaultValue: <CardOut>[])
  final List<CardOut> cards;
  static const fromJsonFactory = _$CardsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CardsResponse &&
            (identical(other.cards, cards) ||
                const DeepCollectionEquality().equals(other.cards, cards)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cards) ^ runtimeType.hashCode;
}

extension $CardsResponseExtension on CardsResponse {
  CardsResponse copyWith({List<CardOut>? cards}) {
    return CardsResponse(cards: cards ?? this.cards);
  }

  CardsResponse copyWithWrapped({Wrapped<List<CardOut>>? cards}) {
    return CardsResponse(cards: (cards != null ? cards.value : this.cards));
  }
}

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
class EntitlementsOut {
  const EntitlementsOut({
    required this.computedAt,
    required this.features,
    required this.plans,
    required this.validUntil,
  });

  factory EntitlementsOut.fromJson(Map<String, dynamic> json) =>
      _$EntitlementsOutFromJson(json);

  static const toJsonFactory = _$EntitlementsOutToJson;
  Map<String, dynamic> toJson() => _$EntitlementsOutToJson(this);

  @JsonKey(name: 'computed_at', includeIfNull: false)
  final String computedAt;
  @JsonKey(name: 'features', includeIfNull: false)
  final Map<String, dynamic> features;
  @JsonKey(name: 'plans', includeIfNull: false, defaultValue: <String>[])
  final List<String> plans;
  @JsonKey(name: 'valid_until', includeIfNull: false)
  final String validUntil;
  static const fromJsonFactory = _$EntitlementsOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EntitlementsOut &&
            (identical(other.computedAt, computedAt) ||
                const DeepCollectionEquality().equals(
                  other.computedAt,
                  computedAt,
                )) &&
            (identical(other.features, features) ||
                const DeepCollectionEquality().equals(
                  other.features,
                  features,
                )) &&
            (identical(other.plans, plans) ||
                const DeepCollectionEquality().equals(other.plans, plans)) &&
            (identical(other.validUntil, validUntil) ||
                const DeepCollectionEquality().equals(
                  other.validUntil,
                  validUntil,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(computedAt) ^
      const DeepCollectionEquality().hash(features) ^
      const DeepCollectionEquality().hash(plans) ^
      const DeepCollectionEquality().hash(validUntil) ^
      runtimeType.hashCode;
}

extension $EntitlementsOutExtension on EntitlementsOut {
  EntitlementsOut copyWith({
    String? computedAt,
    Map<String, dynamic>? features,
    List<String>? plans,
    String? validUntil,
  }) {
    return EntitlementsOut(
      computedAt: computedAt ?? this.computedAt,
      features: features ?? this.features,
      plans: plans ?? this.plans,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  EntitlementsOut copyWithWrapped({
    Wrapped<String>? computedAt,
    Wrapped<Map<String, dynamic>>? features,
    Wrapped<List<String>>? plans,
    Wrapped<String>? validUntil,
  }) {
    return EntitlementsOut(
      computedAt: (computedAt != null ? computedAt.value : this.computedAt),
      features: (features != null ? features.value : this.features),
      plans: (plans != null ? plans.value : this.plans),
      validUntil: (validUntil != null ? validUntil.value : this.validUntil),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class EntitlementsResponse {
  const EntitlementsResponse({
    required this.entitlements,
    required this.signature,
  });

  factory EntitlementsResponse.fromJson(Map<String, dynamic> json) =>
      _$EntitlementsResponseFromJson(json);

  static const toJsonFactory = _$EntitlementsResponseToJson;
  Map<String, dynamic> toJson() => _$EntitlementsResponseToJson(this);

  @JsonKey(name: 'entitlements', includeIfNull: false)
  final EntitlementsOut entitlements;
  @JsonKey(name: 'signature', includeIfNull: false)
  final String? signature;
  static const fromJsonFactory = _$EntitlementsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EntitlementsResponse &&
            (identical(other.entitlements, entitlements) ||
                const DeepCollectionEquality().equals(
                  other.entitlements,
                  entitlements,
                )) &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(entitlements) ^
      const DeepCollectionEquality().hash(signature) ^
      runtimeType.hashCode;
}

extension $EntitlementsResponseExtension on EntitlementsResponse {
  EntitlementsResponse copyWith({
    EntitlementsOut? entitlements,
    String? signature,
  }) {
    return EntitlementsResponse(
      entitlements: entitlements ?? this.entitlements,
      signature: signature ?? this.signature,
    );
  }

  EntitlementsResponse copyWithWrapped({
    Wrapped<EntitlementsOut>? entitlements,
    Wrapped<String?>? signature,
  }) {
    return EntitlementsResponse(
      entitlements: (entitlements != null
          ? entitlements.value
          : this.entitlements),
      signature: (signature != null ? signature.value : this.signature),
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
class EventOut {
  const EventOut({
    required this.createdAt,
    required this.eventType,
    required this.id,
    required this.provider,
    required this.subscriptionId,
  });

  factory EventOut.fromJson(Map<String, dynamic> json) =>
      _$EventOutFromJson(json);

  static const toJsonFactory = _$EventOutToJson;
  Map<String, dynamic> toJson() => _$EventOutToJson(this);

  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'event_type', includeIfNull: false)
  final String eventType;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'provider', includeIfNull: false)
  final String provider;
  @JsonKey(name: 'subscription_id', includeIfNull: false)
  final String? subscriptionId;
  static const fromJsonFactory = _$EventOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EventOut &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.eventType, eventType) ||
                const DeepCollectionEquality().equals(
                  other.eventType,
                  eventType,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.provider, provider) ||
                const DeepCollectionEquality().equals(
                  other.provider,
                  provider,
                )) &&
            (identical(other.subscriptionId, subscriptionId) ||
                const DeepCollectionEquality().equals(
                  other.subscriptionId,
                  subscriptionId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(eventType) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(provider) ^
      const DeepCollectionEquality().hash(subscriptionId) ^
      runtimeType.hashCode;
}

extension $EventOutExtension on EventOut {
  EventOut copyWith({
    DateTime? createdAt,
    String? eventType,
    String? id,
    String? provider,
    String? subscriptionId,
  }) {
    return EventOut(
      createdAt: createdAt ?? this.createdAt,
      eventType: eventType ?? this.eventType,
      id: id ?? this.id,
      provider: provider ?? this.provider,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }

  EventOut copyWithWrapped({
    Wrapped<DateTime>? createdAt,
    Wrapped<String>? eventType,
    Wrapped<String>? id,
    Wrapped<String>? provider,
    Wrapped<String?>? subscriptionId,
  }) {
    return EventOut(
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      eventType: (eventType != null ? eventType.value : this.eventType),
      id: (id != null ? id.value : this.id),
      provider: (provider != null ? provider.value : this.provider),
      subscriptionId: (subscriptionId != null
          ? subscriptionId.value
          : this.subscriptionId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class EventsResponse {
  const EventsResponse({required this.events});

  factory EventsResponse.fromJson(Map<String, dynamic> json) =>
      _$EventsResponseFromJson(json);

  static const toJsonFactory = _$EventsResponseToJson;
  Map<String, dynamic> toJson() => _$EventsResponseToJson(this);

  @JsonKey(name: 'events', includeIfNull: false, defaultValue: <EventOut>[])
  final List<EventOut> events;
  static const fromJsonFactory = _$EventsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EventsResponse &&
            (identical(other.events, events) ||
                const DeepCollectionEquality().equals(other.events, events)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(events) ^ runtimeType.hashCode;
}

extension $EventsResponseExtension on EventsResponse {
  EventsResponse copyWith({List<EventOut>? events}) {
    return EventsResponse(events: events ?? this.events);
  }

  EventsResponse copyWithWrapped({Wrapped<List<EventOut>>? events}) {
    return EventsResponse(
      events: (events != null ? events.value : this.events),
    );
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
class FeatureConfig {
  const FeatureConfig({required this.feature, required this.limit});

  factory FeatureConfig.fromJson(Map<String, dynamic> json) =>
      _$FeatureConfigFromJson(json);

  static const toJsonFactory = _$FeatureConfigToJson;
  Map<String, dynamic> toJson() => _$FeatureConfigToJson(this);

  @JsonKey(name: 'feature', includeIfNull: false)
  final String feature;
  @JsonKey(name: 'limit', includeIfNull: false)
  final int? limit;
  static const fromJsonFactory = _$FeatureConfigFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeatureConfig &&
            (identical(other.feature, feature) ||
                const DeepCollectionEquality().equals(
                  other.feature,
                  feature,
                )) &&
            (identical(other.limit, limit) ||
                const DeepCollectionEquality().equals(other.limit, limit)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(feature) ^
      const DeepCollectionEquality().hash(limit) ^
      runtimeType.hashCode;
}

extension $FeatureConfigExtension on FeatureConfig {
  FeatureConfig copyWith({String? feature, int? limit}) {
    return FeatureConfig(
      feature: feature ?? this.feature,
      limit: limit ?? this.limit,
    );
  }

  FeatureConfig copyWithWrapped({
    Wrapped<String>? feature,
    Wrapped<int?>? limit,
  }) {
    return FeatureConfig(
      feature: (feature != null ? feature.value : this.feature),
      limit: (limit != null ? limit.value : this.limit),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeatureOut {
  const FeatureOut({required this.enabled, required this.limit});

  factory FeatureOut.fromJson(Map<String, dynamic> json) =>
      _$FeatureOutFromJson(json);

  static const toJsonFactory = _$FeatureOutToJson;
  Map<String, dynamic> toJson() => _$FeatureOutToJson(this);

  @JsonKey(name: 'enabled', includeIfNull: false)
  final bool enabled;
  @JsonKey(name: 'limit', includeIfNull: false)
  final int? limit;
  static const fromJsonFactory = _$FeatureOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeatureOut &&
            (identical(other.enabled, enabled) ||
                const DeepCollectionEquality().equals(
                  other.enabled,
                  enabled,
                )) &&
            (identical(other.limit, limit) ||
                const DeepCollectionEquality().equals(other.limit, limit)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(enabled) ^
      const DeepCollectionEquality().hash(limit) ^
      runtimeType.hashCode;
}

extension $FeatureOutExtension on FeatureOut {
  FeatureOut copyWith({bool? enabled, int? limit}) {
    return FeatureOut(
      enabled: enabled ?? this.enabled,
      limit: limit ?? this.limit,
    );
  }

  FeatureOut copyWithWrapped({Wrapped<bool>? enabled, Wrapped<int?>? limit}) {
    return FeatureOut(
      enabled: (enabled != null ? enabled.value : this.enabled),
      limit: (limit != null ? limit.value : this.limit),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class GrantIn {
  const GrantIn({
    required this.periodEnd,
    required this.planKey,
    required this.reason,
    required this.subjectId,
    required this.subjectType,
  });

  factory GrantIn.fromJson(Map<String, dynamic> json) =>
      _$GrantInFromJson(json);

  static const toJsonFactory = _$GrantInToJson;
  Map<String, dynamic> toJson() => _$GrantInToJson(this);

  @JsonKey(name: 'period_end', includeIfNull: false)
  final DateTime periodEnd;
  @JsonKey(name: 'plan_key', includeIfNull: false)
  final String planKey;
  @JsonKey(name: 'reason', includeIfNull: false)
  final String reason;
  @JsonKey(name: 'subject_id', includeIfNull: false)
  final String subjectId;
  @JsonKey(
    name: 'subject_type',
    includeIfNull: false,
    toJson: grantInSubjectTypeToJson,
    fromJson: grantInSubjectTypeFromJson,
  )
  final enums.GrantInSubjectType subjectType;
  static const fromJsonFactory = _$GrantInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GrantIn &&
            (identical(other.periodEnd, periodEnd) ||
                const DeepCollectionEquality().equals(
                  other.periodEnd,
                  periodEnd,
                )) &&
            (identical(other.planKey, planKey) ||
                const DeepCollectionEquality().equals(
                  other.planKey,
                  planKey,
                )) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.subjectId, subjectId) ||
                const DeepCollectionEquality().equals(
                  other.subjectId,
                  subjectId,
                )) &&
            (identical(other.subjectType, subjectType) ||
                const DeepCollectionEquality().equals(
                  other.subjectType,
                  subjectType,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(periodEnd) ^
      const DeepCollectionEquality().hash(planKey) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(subjectId) ^
      const DeepCollectionEquality().hash(subjectType) ^
      runtimeType.hashCode;
}

extension $GrantInExtension on GrantIn {
  GrantIn copyWith({
    DateTime? periodEnd,
    String? planKey,
    String? reason,
    String? subjectId,
    enums.GrantInSubjectType? subjectType,
  }) {
    return GrantIn(
      periodEnd: periodEnd ?? this.periodEnd,
      planKey: planKey ?? this.planKey,
      reason: reason ?? this.reason,
      subjectId: subjectId ?? this.subjectId,
      subjectType: subjectType ?? this.subjectType,
    );
  }

  GrantIn copyWithWrapped({
    Wrapped<DateTime>? periodEnd,
    Wrapped<String>? planKey,
    Wrapped<String>? reason,
    Wrapped<String>? subjectId,
    Wrapped<enums.GrantInSubjectType>? subjectType,
  }) {
    return GrantIn(
      periodEnd: (periodEnd != null ? periodEnd.value : this.periodEnd),
      planKey: (planKey != null ? planKey.value : this.planKey),
      reason: (reason != null ? reason.value : this.reason),
      subjectId: (subjectId != null ? subjectId.value : this.subjectId),
      subjectType: (subjectType != null ? subjectType.value : this.subjectType),
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
class ImportIn {
  const ImportIn({required this.csv, required this.sourceKey});

  factory ImportIn.fromJson(Map<String, dynamic> json) =>
      _$ImportInFromJson(json);

  static const toJsonFactory = _$ImportInToJson;
  Map<String, dynamic> toJson() => _$ImportInToJson(this);

  @JsonKey(name: 'csv', includeIfNull: false)
  final String csv;
  @JsonKey(name: 'source_key', includeIfNull: false)
  final String sourceKey;
  static const fromJsonFactory = _$ImportInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ImportIn &&
            (identical(other.csv, csv) ||
                const DeepCollectionEquality().equals(other.csv, csv)) &&
            (identical(other.sourceKey, sourceKey) ||
                const DeepCollectionEquality().equals(
                  other.sourceKey,
                  sourceKey,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(csv) ^
      const DeepCollectionEquality().hash(sourceKey) ^
      runtimeType.hashCode;
}

extension $ImportInExtension on ImportIn {
  ImportIn copyWith({String? csv, String? sourceKey}) {
    return ImportIn(
      csv: csv ?? this.csv,
      sourceKey: sourceKey ?? this.sourceKey,
    );
  }

  ImportIn copyWithWrapped({Wrapped<String>? csv, Wrapped<String>? sourceKey}) {
    return ImportIn(
      csv: (csv != null ? csv.value : this.csv),
      sourceKey: (sourceKey != null ? sourceKey.value : this.sourceKey),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ImportOut {
  const ImportOut({
    required this.added,
    required this.cardsPulled,
    required this.changed,
    required this.removed,
    required this.unchanged,
  });

  factory ImportOut.fromJson(Map<String, dynamic> json) =>
      _$ImportOutFromJson(json);

  static const toJsonFactory = _$ImportOutToJson;
  Map<String, dynamic> toJson() => _$ImportOutToJson(this);

  @JsonKey(name: 'added', includeIfNull: false)
  final int added;
  @JsonKey(name: 'cards_pulled', includeIfNull: false)
  final int cardsPulled;
  @JsonKey(name: 'changed', includeIfNull: false)
  final int changed;
  @JsonKey(name: 'removed', includeIfNull: false)
  final int removed;
  @JsonKey(name: 'unchanged', includeIfNull: false)
  final int unchanged;
  static const fromJsonFactory = _$ImportOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ImportOut &&
            (identical(other.added, added) ||
                const DeepCollectionEquality().equals(other.added, added)) &&
            (identical(other.cardsPulled, cardsPulled) ||
                const DeepCollectionEquality().equals(
                  other.cardsPulled,
                  cardsPulled,
                )) &&
            (identical(other.changed, changed) ||
                const DeepCollectionEquality().equals(
                  other.changed,
                  changed,
                )) &&
            (identical(other.removed, removed) ||
                const DeepCollectionEquality().equals(
                  other.removed,
                  removed,
                )) &&
            (identical(other.unchanged, unchanged) ||
                const DeepCollectionEquality().equals(
                  other.unchanged,
                  unchanged,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(added) ^
      const DeepCollectionEquality().hash(cardsPulled) ^
      const DeepCollectionEquality().hash(changed) ^
      const DeepCollectionEquality().hash(removed) ^
      const DeepCollectionEquality().hash(unchanged) ^
      runtimeType.hashCode;
}

extension $ImportOutExtension on ImportOut {
  ImportOut copyWith({
    int? added,
    int? cardsPulled,
    int? changed,
    int? removed,
    int? unchanged,
  }) {
    return ImportOut(
      added: added ?? this.added,
      cardsPulled: cardsPulled ?? this.cardsPulled,
      changed: changed ?? this.changed,
      removed: removed ?? this.removed,
      unchanged: unchanged ?? this.unchanged,
    );
  }

  ImportOut copyWithWrapped({
    Wrapped<int>? added,
    Wrapped<int>? cardsPulled,
    Wrapped<int>? changed,
    Wrapped<int>? removed,
    Wrapped<int>? unchanged,
  }) {
    return ImportOut(
      added: (added != null ? added.value : this.added),
      cardsPulled: (cardsPulled != null ? cardsPulled.value : this.cardsPulled),
      changed: (changed != null ? changed.value : this.changed),
      removed: (removed != null ? removed.value : this.removed),
      unchanged: (unchanged != null ? unchanged.value : this.unchanged),
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
class PlanIn {
  const PlanIn({
    this.active,
    required this.features,
    required this.kind,
    required this.names,
    this.sortOrder,
  });

  factory PlanIn.fromJson(Map<String, dynamic> json) => _$PlanInFromJson(json);

  static const toJsonFactory = _$PlanInToJson;
  Map<String, dynamic> toJson() => _$PlanInToJson(this);

  @JsonKey(name: 'active', includeIfNull: false, defaultValue: true)
  final bool? active;
  @JsonKey(name: 'features', includeIfNull: false)
  final Object features;
  @JsonKey(
    name: 'kind',
    includeIfNull: false,
    toJson: planInKindToJson,
    fromJson: planInKindFromJson,
  )
  final enums.PlanInKind kind;
  @JsonKey(name: 'names', includeIfNull: false)
  final Map<String, dynamic> names;
  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int? sortOrder;
  static const fromJsonFactory = _$PlanInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlanIn &&
            (identical(other.active, active) ||
                const DeepCollectionEquality().equals(other.active, active)) &&
            (identical(other.features, features) ||
                const DeepCollectionEquality().equals(
                  other.features,
                  features,
                )) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.names, names) ||
                const DeepCollectionEquality().equals(other.names, names)) &&
            (identical(other.sortOrder, sortOrder) ||
                const DeepCollectionEquality().equals(
                  other.sortOrder,
                  sortOrder,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(active) ^
      const DeepCollectionEquality().hash(features) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(names) ^
      const DeepCollectionEquality().hash(sortOrder) ^
      runtimeType.hashCode;
}

extension $PlanInExtension on PlanIn {
  PlanIn copyWith({
    bool? active,
    Object? features,
    enums.PlanInKind? kind,
    Map<String, dynamic>? names,
    int? sortOrder,
  }) {
    return PlanIn(
      active: active ?? this.active,
      features: features ?? this.features,
      kind: kind ?? this.kind,
      names: names ?? this.names,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  PlanIn copyWithWrapped({
    Wrapped<bool?>? active,
    Wrapped<Object>? features,
    Wrapped<enums.PlanInKind>? kind,
    Wrapped<Map<String, dynamic>>? names,
    Wrapped<int?>? sortOrder,
  }) {
    return PlanIn(
      active: (active != null ? active.value : this.active),
      features: (features != null ? features.value : this.features),
      kind: (kind != null ? kind.value : this.kind),
      names: (names != null ? names.value : this.names),
      sortOrder: (sortOrder != null ? sortOrder.value : this.sortOrder),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PlanOut {
  const PlanOut({
    required this.active,
    required this.features,
    required this.key,
    required this.kind,
    required this.names,
    required this.sortOrder,
  });

  factory PlanOut.fromJson(Map<String, dynamic> json) =>
      _$PlanOutFromJson(json);

  static const toJsonFactory = _$PlanOutToJson;
  Map<String, dynamic> toJson() => _$PlanOutToJson(this);

  @JsonKey(name: 'active', includeIfNull: false)
  final bool active;
  @JsonKey(
    name: 'features',
    includeIfNull: false,
    defaultValue: <FeatureConfig>[],
  )
  final List<FeatureConfig> features;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  @JsonKey(name: 'names', includeIfNull: false)
  final Map<String, dynamic> names;
  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int sortOrder;
  static const fromJsonFactory = _$PlanOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlanOut &&
            (identical(other.active, active) ||
                const DeepCollectionEquality().equals(other.active, active)) &&
            (identical(other.features, features) ||
                const DeepCollectionEquality().equals(
                  other.features,
                  features,
                )) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.names, names) ||
                const DeepCollectionEquality().equals(other.names, names)) &&
            (identical(other.sortOrder, sortOrder) ||
                const DeepCollectionEquality().equals(
                  other.sortOrder,
                  sortOrder,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(active) ^
      const DeepCollectionEquality().hash(features) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(names) ^
      const DeepCollectionEquality().hash(sortOrder) ^
      runtimeType.hashCode;
}

extension $PlanOutExtension on PlanOut {
  PlanOut copyWith({
    bool? active,
    List<FeatureConfig>? features,
    String? key,
    String? kind,
    Map<String, dynamic>? names,
    int? sortOrder,
  }) {
    return PlanOut(
      active: active ?? this.active,
      features: features ?? this.features,
      key: key ?? this.key,
      kind: kind ?? this.kind,
      names: names ?? this.names,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  PlanOut copyWithWrapped({
    Wrapped<bool>? active,
    Wrapped<List<FeatureConfig>>? features,
    Wrapped<String>? key,
    Wrapped<String>? kind,
    Wrapped<Map<String, dynamic>>? names,
    Wrapped<int>? sortOrder,
  }) {
    return PlanOut(
      active: (active != null ? active.value : this.active),
      features: (features != null ? features.value : this.features),
      key: (key != null ? key.value : this.key),
      kind: (kind != null ? kind.value : this.kind),
      names: (names != null ? names.value : this.names),
      sortOrder: (sortOrder != null ? sortOrder.value : this.sortOrder),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PlansResponse {
  const PlansResponse({required this.plans});

  factory PlansResponse.fromJson(Map<String, dynamic> json) =>
      _$PlansResponseFromJson(json);

  static const toJsonFactory = _$PlansResponseToJson;
  Map<String, dynamic> toJson() => _$PlansResponseToJson(this);

  @JsonKey(name: 'plans', includeIfNull: false, defaultValue: <PlanOut>[])
  final List<PlanOut> plans;
  static const fromJsonFactory = _$PlansResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlansResponse &&
            (identical(other.plans, plans) ||
                const DeepCollectionEquality().equals(other.plans, plans)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(plans) ^ runtimeType.hashCode;
}

extension $PlansResponseExtension on PlansResponse {
  PlansResponse copyWith({List<PlanOut>? plans}) {
    return PlansResponse(plans: plans ?? this.plans);
  }

  PlansResponse copyWithWrapped({Wrapped<List<PlanOut>>? plans}) {
    return PlansResponse(plans: (plans != null ? plans.value : this.plans));
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
class RestrictionOut {
  const RestrictionOut({
    required this.activeIngredient,
    required this.cropGroups,
    required this.crops,
    required this.effectiveFrom,
    required this.kind,
    required this.notification,
  });

  factory RestrictionOut.fromJson(Map<String, dynamic> json) =>
      _$RestrictionOutFromJson(json);

  static const toJsonFactory = _$RestrictionOutToJson;
  Map<String, dynamic> toJson() => _$RestrictionOutToJson(this);

  @JsonKey(name: 'active_ingredient', includeIfNull: false)
  final String activeIngredient;
  @JsonKey(name: 'crop_groups', includeIfNull: false, defaultValue: <String>[])
  final List<String> cropGroups;
  @JsonKey(name: 'crops', includeIfNull: false, defaultValue: <String>[])
  final List<String> crops;
  @JsonKey(name: 'effective_from', includeIfNull: false)
  final DateTime effectiveFrom;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  @JsonKey(name: 'notification', includeIfNull: false)
  final String notification;
  static const fromJsonFactory = _$RestrictionOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestrictionOut &&
            (identical(other.activeIngredient, activeIngredient) ||
                const DeepCollectionEquality().equals(
                  other.activeIngredient,
                  activeIngredient,
                )) &&
            (identical(other.cropGroups, cropGroups) ||
                const DeepCollectionEquality().equals(
                  other.cropGroups,
                  cropGroups,
                )) &&
            (identical(other.crops, crops) ||
                const DeepCollectionEquality().equals(other.crops, crops)) &&
            (identical(other.effectiveFrom, effectiveFrom) ||
                const DeepCollectionEquality().equals(
                  other.effectiveFrom,
                  effectiveFrom,
                )) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.notification, notification) ||
                const DeepCollectionEquality().equals(
                  other.notification,
                  notification,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activeIngredient) ^
      const DeepCollectionEquality().hash(cropGroups) ^
      const DeepCollectionEquality().hash(crops) ^
      const DeepCollectionEquality().hash(effectiveFrom) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(notification) ^
      runtimeType.hashCode;
}

extension $RestrictionOutExtension on RestrictionOut {
  RestrictionOut copyWith({
    String? activeIngredient,
    List<String>? cropGroups,
    List<String>? crops,
    DateTime? effectiveFrom,
    String? kind,
    String? notification,
  }) {
    return RestrictionOut(
      activeIngredient: activeIngredient ?? this.activeIngredient,
      cropGroups: cropGroups ?? this.cropGroups,
      crops: crops ?? this.crops,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      kind: kind ?? this.kind,
      notification: notification ?? this.notification,
    );
  }

  RestrictionOut copyWithWrapped({
    Wrapped<String>? activeIngredient,
    Wrapped<List<String>>? cropGroups,
    Wrapped<List<String>>? crops,
    Wrapped<DateTime>? effectiveFrom,
    Wrapped<String>? kind,
    Wrapped<String>? notification,
  }) {
    return RestrictionOut(
      activeIngredient: (activeIngredient != null
          ? activeIngredient.value
          : this.activeIngredient),
      cropGroups: (cropGroups != null ? cropGroups.value : this.cropGroups),
      crops: (crops != null ? crops.value : this.crops),
      effectiveFrom: (effectiveFrom != null
          ? effectiveFrom.value
          : this.effectiveFrom),
      kind: (kind != null ? kind.value : this.kind),
      notification: (notification != null
          ? notification.value
          : this.notification),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RestrictionsResponse {
  const RestrictionsResponse({
    required this.restrictions,
    required this.synonyms,
  });

  factory RestrictionsResponse.fromJson(Map<String, dynamic> json) =>
      _$RestrictionsResponseFromJson(json);

  static const toJsonFactory = _$RestrictionsResponseToJson;
  Map<String, dynamic> toJson() => _$RestrictionsResponseToJson(this);

  @JsonKey(
    name: 'restrictions',
    includeIfNull: false,
    defaultValue: <RestrictionOut>[],
  )
  final List<RestrictionOut> restrictions;
  @JsonKey(name: 'synonyms', includeIfNull: false, defaultValue: <SynonymOut>[])
  final List<SynonymOut> synonyms;
  static const fromJsonFactory = _$RestrictionsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestrictionsResponse &&
            (identical(other.restrictions, restrictions) ||
                const DeepCollectionEquality().equals(
                  other.restrictions,
                  restrictions,
                )) &&
            (identical(other.synonyms, synonyms) ||
                const DeepCollectionEquality().equals(
                  other.synonyms,
                  synonyms,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(restrictions) ^
      const DeepCollectionEquality().hash(synonyms) ^
      runtimeType.hashCode;
}

extension $RestrictionsResponseExtension on RestrictionsResponse {
  RestrictionsResponse copyWith({
    List<RestrictionOut>? restrictions,
    List<SynonymOut>? synonyms,
  }) {
    return RestrictionsResponse(
      restrictions: restrictions ?? this.restrictions,
      synonyms: synonyms ?? this.synonyms,
    );
  }

  RestrictionsResponse copyWithWrapped({
    Wrapped<List<RestrictionOut>>? restrictions,
    Wrapped<List<SynonymOut>>? synonyms,
  }) {
    return RestrictionsResponse(
      restrictions: (restrictions != null
          ? restrictions.value
          : this.restrictions),
      synonyms: (synonyms != null ? synonyms.value : this.synonyms),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReviewIn {
  const ReviewIn({this.comments, required this.decision});

  factory ReviewIn.fromJson(Map<String, dynamic> json) =>
      _$ReviewInFromJson(json);

  static const toJsonFactory = _$ReviewInToJson;
  Map<String, dynamic> toJson() => _$ReviewInToJson(this);

  @JsonKey(name: 'comments', includeIfNull: false)
  final String? comments;
  @JsonKey(
    name: 'decision',
    includeIfNull: false,
    toJson: reviewInDecisionToJson,
    fromJson: reviewInDecisionFromJson,
  )
  final enums.ReviewInDecision decision;
  static const fromJsonFactory = _$ReviewInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReviewIn &&
            (identical(other.comments, comments) ||
                const DeepCollectionEquality().equals(
                  other.comments,
                  comments,
                )) &&
            (identical(other.decision, decision) ||
                const DeepCollectionEquality().equals(
                  other.decision,
                  decision,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(comments) ^
      const DeepCollectionEquality().hash(decision) ^
      runtimeType.hashCode;
}

extension $ReviewInExtension on ReviewIn {
  ReviewIn copyWith({String? comments, enums.ReviewInDecision? decision}) {
    return ReviewIn(
      comments: comments ?? this.comments,
      decision: decision ?? this.decision,
    );
  }

  ReviewIn copyWithWrapped({
    Wrapped<String?>? comments,
    Wrapped<enums.ReviewInDecision>? decision,
  }) {
    return ReviewIn(
      comments: (comments != null ? comments.value : this.comments),
      decision: (decision != null ? decision.value : this.decision),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SourceOut {
  const SourceOut({
    required this.allowedUse,
    required this.contentHash,
    required this.fetchError,
    required this.fetchStatus,
    required this.fetchedAt,
    required this.id,
    required this.key,
    required this.publisher,
    required this.tier,
    required this.title,
    required this.url,
    required this.verification,
  });

  factory SourceOut.fromJson(Map<String, dynamic> json) =>
      _$SourceOutFromJson(json);

  static const toJsonFactory = _$SourceOutToJson;
  Map<String, dynamic> toJson() => _$SourceOutToJson(this);

  @JsonKey(name: 'allowed_use', includeIfNull: false)
  final String allowedUse;
  @JsonKey(name: 'content_hash', includeIfNull: false)
  final String? contentHash;
  @JsonKey(name: 'fetch_error', includeIfNull: false)
  final String? fetchError;
  @JsonKey(name: 'fetch_status', includeIfNull: false)
  final String fetchStatus;
  @JsonKey(name: 'fetched_at', includeIfNull: false)
  final DateTime? fetchedAt;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'publisher', includeIfNull: false)
  final String publisher;
  @JsonKey(name: 'tier', includeIfNull: false)
  final String tier;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  @JsonKey(name: 'verification', includeIfNull: false)
  final String verification;
  static const fromJsonFactory = _$SourceOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SourceOut &&
            (identical(other.allowedUse, allowedUse) ||
                const DeepCollectionEquality().equals(
                  other.allowedUse,
                  allowedUse,
                )) &&
            (identical(other.contentHash, contentHash) ||
                const DeepCollectionEquality().equals(
                  other.contentHash,
                  contentHash,
                )) &&
            (identical(other.fetchError, fetchError) ||
                const DeepCollectionEquality().equals(
                  other.fetchError,
                  fetchError,
                )) &&
            (identical(other.fetchStatus, fetchStatus) ||
                const DeepCollectionEquality().equals(
                  other.fetchStatus,
                  fetchStatus,
                )) &&
            (identical(other.fetchedAt, fetchedAt) ||
                const DeepCollectionEquality().equals(
                  other.fetchedAt,
                  fetchedAt,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.publisher, publisher) ||
                const DeepCollectionEquality().equals(
                  other.publisher,
                  publisher,
                )) &&
            (identical(other.tier, tier) ||
                const DeepCollectionEquality().equals(other.tier, tier)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
            (identical(other.verification, verification) ||
                const DeepCollectionEquality().equals(
                  other.verification,
                  verification,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(allowedUse) ^
      const DeepCollectionEquality().hash(contentHash) ^
      const DeepCollectionEquality().hash(fetchError) ^
      const DeepCollectionEquality().hash(fetchStatus) ^
      const DeepCollectionEquality().hash(fetchedAt) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(publisher) ^
      const DeepCollectionEquality().hash(tier) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(verification) ^
      runtimeType.hashCode;
}

extension $SourceOutExtension on SourceOut {
  SourceOut copyWith({
    String? allowedUse,
    String? contentHash,
    String? fetchError,
    String? fetchStatus,
    DateTime? fetchedAt,
    String? id,
    String? key,
    String? publisher,
    String? tier,
    String? title,
    String? url,
    String? verification,
  }) {
    return SourceOut(
      allowedUse: allowedUse ?? this.allowedUse,
      contentHash: contentHash ?? this.contentHash,
      fetchError: fetchError ?? this.fetchError,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      id: id ?? this.id,
      key: key ?? this.key,
      publisher: publisher ?? this.publisher,
      tier: tier ?? this.tier,
      title: title ?? this.title,
      url: url ?? this.url,
      verification: verification ?? this.verification,
    );
  }

  SourceOut copyWithWrapped({
    Wrapped<String>? allowedUse,
    Wrapped<String?>? contentHash,
    Wrapped<String?>? fetchError,
    Wrapped<String>? fetchStatus,
    Wrapped<DateTime?>? fetchedAt,
    Wrapped<String>? id,
    Wrapped<String>? key,
    Wrapped<String>? publisher,
    Wrapped<String>? tier,
    Wrapped<String>? title,
    Wrapped<String>? url,
    Wrapped<String>? verification,
  }) {
    return SourceOut(
      allowedUse: (allowedUse != null ? allowedUse.value : this.allowedUse),
      contentHash: (contentHash != null ? contentHash.value : this.contentHash),
      fetchError: (fetchError != null ? fetchError.value : this.fetchError),
      fetchStatus: (fetchStatus != null ? fetchStatus.value : this.fetchStatus),
      fetchedAt: (fetchedAt != null ? fetchedAt.value : this.fetchedAt),
      id: (id != null ? id.value : this.id),
      key: (key != null ? key.value : this.key),
      publisher: (publisher != null ? publisher.value : this.publisher),
      tier: (tier != null ? tier.value : this.tier),
      title: (title != null ? title.value : this.title),
      url: (url != null ? url.value : this.url),
      verification: (verification != null
          ? verification.value
          : this.verification),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SourcesResponse {
  const SourcesResponse({required this.sources});

  factory SourcesResponse.fromJson(Map<String, dynamic> json) =>
      _$SourcesResponseFromJson(json);

  static const toJsonFactory = _$SourcesResponseToJson;
  Map<String, dynamic> toJson() => _$SourcesResponseToJson(this);

  @JsonKey(name: 'sources', includeIfNull: false, defaultValue: <SourceOut>[])
  final List<SourceOut> sources;
  static const fromJsonFactory = _$SourcesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SourcesResponse &&
            (identical(other.sources, sources) ||
                const DeepCollectionEquality().equals(other.sources, sources)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(sources) ^ runtimeType.hashCode;
}

extension $SourcesResponseExtension on SourcesResponse {
  SourcesResponse copyWith({List<SourceOut>? sources}) {
    return SourcesResponse(sources: sources ?? this.sources);
  }

  SourcesResponse copyWithWrapped({Wrapped<List<SourceOut>>? sources}) {
    return SourcesResponse(
      sources: (sources != null ? sources.value : this.sources),
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
class SubscriptionOut {
  const SubscriptionOut({
    required this.id,
    required this.periodEnd,
    required this.periodStart,
    required this.planKey,
    required this.provider,
    required this.reason,
    required this.state,
    required this.subjectId,
    required this.subjectType,
  });

  factory SubscriptionOut.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionOutFromJson(json);

  static const toJsonFactory = _$SubscriptionOutToJson;
  Map<String, dynamic> toJson() => _$SubscriptionOutToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'period_end', includeIfNull: false)
  final DateTime periodEnd;
  @JsonKey(name: 'period_start', includeIfNull: false)
  final DateTime periodStart;
  @JsonKey(name: 'plan_key', includeIfNull: false)
  final String planKey;
  @JsonKey(name: 'provider', includeIfNull: false)
  final String provider;
  @JsonKey(name: 'reason', includeIfNull: false)
  final String? reason;
  @JsonKey(name: 'state', includeIfNull: false)
  final String state;
  @JsonKey(name: 'subject_id', includeIfNull: false)
  final String subjectId;
  @JsonKey(name: 'subject_type', includeIfNull: false)
  final String subjectType;
  static const fromJsonFactory = _$SubscriptionOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubscriptionOut &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.periodEnd, periodEnd) ||
                const DeepCollectionEquality().equals(
                  other.periodEnd,
                  periodEnd,
                )) &&
            (identical(other.periodStart, periodStart) ||
                const DeepCollectionEquality().equals(
                  other.periodStart,
                  periodStart,
                )) &&
            (identical(other.planKey, planKey) ||
                const DeepCollectionEquality().equals(
                  other.planKey,
                  planKey,
                )) &&
            (identical(other.provider, provider) ||
                const DeepCollectionEquality().equals(
                  other.provider,
                  provider,
                )) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.subjectId, subjectId) ||
                const DeepCollectionEquality().equals(
                  other.subjectId,
                  subjectId,
                )) &&
            (identical(other.subjectType, subjectType) ||
                const DeepCollectionEquality().equals(
                  other.subjectType,
                  subjectType,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(periodEnd) ^
      const DeepCollectionEquality().hash(periodStart) ^
      const DeepCollectionEquality().hash(planKey) ^
      const DeepCollectionEquality().hash(provider) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(subjectId) ^
      const DeepCollectionEquality().hash(subjectType) ^
      runtimeType.hashCode;
}

extension $SubscriptionOutExtension on SubscriptionOut {
  SubscriptionOut copyWith({
    String? id,
    DateTime? periodEnd,
    DateTime? periodStart,
    String? planKey,
    String? provider,
    String? reason,
    String? state,
    String? subjectId,
    String? subjectType,
  }) {
    return SubscriptionOut(
      id: id ?? this.id,
      periodEnd: periodEnd ?? this.periodEnd,
      periodStart: periodStart ?? this.periodStart,
      planKey: planKey ?? this.planKey,
      provider: provider ?? this.provider,
      reason: reason ?? this.reason,
      state: state ?? this.state,
      subjectId: subjectId ?? this.subjectId,
      subjectType: subjectType ?? this.subjectType,
    );
  }

  SubscriptionOut copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<DateTime>? periodEnd,
    Wrapped<DateTime>? periodStart,
    Wrapped<String>? planKey,
    Wrapped<String>? provider,
    Wrapped<String?>? reason,
    Wrapped<String>? state,
    Wrapped<String>? subjectId,
    Wrapped<String>? subjectType,
  }) {
    return SubscriptionOut(
      id: (id != null ? id.value : this.id),
      periodEnd: (periodEnd != null ? periodEnd.value : this.periodEnd),
      periodStart: (periodStart != null ? periodStart.value : this.periodStart),
      planKey: (planKey != null ? planKey.value : this.planKey),
      provider: (provider != null ? provider.value : this.provider),
      reason: (reason != null ? reason.value : this.reason),
      state: (state != null ? state.value : this.state),
      subjectId: (subjectId != null ? subjectId.value : this.subjectId),
      subjectType: (subjectType != null ? subjectType.value : this.subjectType),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SubscriptionsResponse {
  const SubscriptionsResponse({required this.subscriptions});

  factory SubscriptionsResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionsResponseFromJson(json);

  static const toJsonFactory = _$SubscriptionsResponseToJson;
  Map<String, dynamic> toJson() => _$SubscriptionsResponseToJson(this);

  @JsonKey(
    name: 'subscriptions',
    includeIfNull: false,
    defaultValue: <SubscriptionOut>[],
  )
  final List<SubscriptionOut> subscriptions;
  static const fromJsonFactory = _$SubscriptionsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubscriptionsResponse &&
            (identical(other.subscriptions, subscriptions) ||
                const DeepCollectionEquality().equals(
                  other.subscriptions,
                  subscriptions,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(subscriptions) ^ runtimeType.hashCode;
}

extension $SubscriptionsResponseExtension on SubscriptionsResponse {
  SubscriptionsResponse copyWith({List<SubscriptionOut>? subscriptions}) {
    return SubscriptionsResponse(
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }

  SubscriptionsResponse copyWithWrapped({
    Wrapped<List<SubscriptionOut>>? subscriptions,
  }) {
    return SubscriptionsResponse(
      subscriptions: (subscriptions != null
          ? subscriptions.value
          : this.subscriptions),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SynonymOut {
  const SynonymOut({required this.activeIngredient, required this.name});

  factory SynonymOut.fromJson(Map<String, dynamic> json) =>
      _$SynonymOutFromJson(json);

  static const toJsonFactory = _$SynonymOutToJson;
  Map<String, dynamic> toJson() => _$SynonymOutToJson(this);

  @JsonKey(name: 'active_ingredient', includeIfNull: false)
  final String activeIngredient;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  static const fromJsonFactory = _$SynonymOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SynonymOut &&
            (identical(other.activeIngredient, activeIngredient) ||
                const DeepCollectionEquality().equals(
                  other.activeIngredient,
                  activeIngredient,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activeIngredient) ^
      const DeepCollectionEquality().hash(name) ^
      runtimeType.hashCode;
}

extension $SynonymOutExtension on SynonymOut {
  SynonymOut copyWith({String? activeIngredient, String? name}) {
    return SynonymOut(
      activeIngredient: activeIngredient ?? this.activeIngredient,
      name: name ?? this.name,
    );
  }

  SynonymOut copyWithWrapped({
    Wrapped<String>? activeIngredient,
    Wrapped<String>? name,
  }) {
    return SynonymOut(
      activeIngredient: (activeIngredient != null
          ? activeIngredient.value
          : this.activeIngredient),
      name: (name != null ? name.value : this.name),
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

String? grantInSubjectTypeNullableToJson(
  enums.GrantInSubjectType? grantInSubjectType,
) {
  return grantInSubjectType?.value;
}

String? grantInSubjectTypeToJson(enums.GrantInSubjectType grantInSubjectType) {
  return grantInSubjectType.value;
}

enums.GrantInSubjectType grantInSubjectTypeFromJson(
  Object? grantInSubjectType, [
  enums.GrantInSubjectType? defaultValue,
]) {
  return enums.GrantInSubjectType.values.firstWhereOrNull(
        (e) => e.value == grantInSubjectType,
      ) ??
      defaultValue ??
      enums.GrantInSubjectType.swaggerGeneratedUnknown;
}

enums.GrantInSubjectType? grantInSubjectTypeNullableFromJson(
  Object? grantInSubjectType, [
  enums.GrantInSubjectType? defaultValue,
]) {
  if (grantInSubjectType == null) {
    return null;
  }
  return enums.GrantInSubjectType.values.firstWhereOrNull(
        (e) => e.value == grantInSubjectType,
      ) ??
      defaultValue;
}

String grantInSubjectTypeExplodedListToJson(
  List<enums.GrantInSubjectType>? grantInSubjectType,
) {
  return grantInSubjectType?.map((e) => e.value!).join(',') ?? '';
}

List<String> grantInSubjectTypeListToJson(
  List<enums.GrantInSubjectType>? grantInSubjectType,
) {
  if (grantInSubjectType == null) {
    return [];
  }

  return grantInSubjectType.map((e) => e.value!).toList();
}

List<enums.GrantInSubjectType> grantInSubjectTypeListFromJson(
  List? grantInSubjectType, [
  List<enums.GrantInSubjectType>? defaultValue,
]) {
  if (grantInSubjectType == null) {
    return defaultValue ?? [];
  }

  return grantInSubjectType
      .map((e) => grantInSubjectTypeFromJson(e.toString()))
      .toList();
}

List<enums.GrantInSubjectType>? grantInSubjectTypeNullableListFromJson(
  List? grantInSubjectType, [
  List<enums.GrantInSubjectType>? defaultValue,
]) {
  if (grantInSubjectType == null) {
    return defaultValue;
  }

  return grantInSubjectType
      .map((e) => grantInSubjectTypeFromJson(e.toString()))
      .toList();
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

String? planInKindNullableToJson(enums.PlanInKind? planInKind) {
  return planInKind?.value;
}

String? planInKindToJson(enums.PlanInKind planInKind) {
  return planInKind.value;
}

enums.PlanInKind planInKindFromJson(
  Object? planInKind, [
  enums.PlanInKind? defaultValue,
]) {
  return enums.PlanInKind.values.firstWhereOrNull(
        (e) => e.value == planInKind,
      ) ??
      defaultValue ??
      enums.PlanInKind.swaggerGeneratedUnknown;
}

enums.PlanInKind? planInKindNullableFromJson(
  Object? planInKind, [
  enums.PlanInKind? defaultValue,
]) {
  if (planInKind == null) {
    return null;
  }
  return enums.PlanInKind.values.firstWhereOrNull(
        (e) => e.value == planInKind,
      ) ??
      defaultValue;
}

String planInKindExplodedListToJson(List<enums.PlanInKind>? planInKind) {
  return planInKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> planInKindListToJson(List<enums.PlanInKind>? planInKind) {
  if (planInKind == null) {
    return [];
  }

  return planInKind.map((e) => e.value!).toList();
}

List<enums.PlanInKind> planInKindListFromJson(
  List? planInKind, [
  List<enums.PlanInKind>? defaultValue,
]) {
  if (planInKind == null) {
    return defaultValue ?? [];
  }

  return planInKind.map((e) => planInKindFromJson(e.toString())).toList();
}

List<enums.PlanInKind>? planInKindNullableListFromJson(
  List? planInKind, [
  List<enums.PlanInKind>? defaultValue,
]) {
  if (planInKind == null) {
    return defaultValue;
  }

  return planInKind.map((e) => planInKindFromJson(e.toString())).toList();
}

String? reviewInDecisionNullableToJson(
  enums.ReviewInDecision? reviewInDecision,
) {
  return reviewInDecision?.value;
}

String? reviewInDecisionToJson(enums.ReviewInDecision reviewInDecision) {
  return reviewInDecision.value;
}

enums.ReviewInDecision reviewInDecisionFromJson(
  Object? reviewInDecision, [
  enums.ReviewInDecision? defaultValue,
]) {
  return enums.ReviewInDecision.values.firstWhereOrNull(
        (e) => e.value == reviewInDecision,
      ) ??
      defaultValue ??
      enums.ReviewInDecision.swaggerGeneratedUnknown;
}

enums.ReviewInDecision? reviewInDecisionNullableFromJson(
  Object? reviewInDecision, [
  enums.ReviewInDecision? defaultValue,
]) {
  if (reviewInDecision == null) {
    return null;
  }
  return enums.ReviewInDecision.values.firstWhereOrNull(
        (e) => e.value == reviewInDecision,
      ) ??
      defaultValue;
}

String reviewInDecisionExplodedListToJson(
  List<enums.ReviewInDecision>? reviewInDecision,
) {
  return reviewInDecision?.map((e) => e.value!).join(',') ?? '';
}

List<String> reviewInDecisionListToJson(
  List<enums.ReviewInDecision>? reviewInDecision,
) {
  if (reviewInDecision == null) {
    return [];
  }

  return reviewInDecision.map((e) => e.value!).toList();
}

List<enums.ReviewInDecision> reviewInDecisionListFromJson(
  List? reviewInDecision, [
  List<enums.ReviewInDecision>? defaultValue,
]) {
  if (reviewInDecision == null) {
    return defaultValue ?? [];
  }

  return reviewInDecision
      .map((e) => reviewInDecisionFromJson(e.toString()))
      .toList();
}

List<enums.ReviewInDecision>? reviewInDecisionNullableListFromJson(
  List? reviewInDecision, [
  List<enums.ReviewInDecision>? defaultValue,
]) {
  if (reviewInDecision == null) {
    return defaultValue;
  }

  return reviewInDecision
      .map((e) => reviewInDecisionFromJson(e.toString()))
      .toList();
}

String? v1AdminKbImportsKindPostKindNullableToJson(
  enums.V1AdminKbImportsKindPostKind? v1AdminKbImportsKindPostKind,
) {
  return v1AdminKbImportsKindPostKind?.value;
}

String? v1AdminKbImportsKindPostKindToJson(
  enums.V1AdminKbImportsKindPostKind v1AdminKbImportsKindPostKind,
) {
  return v1AdminKbImportsKindPostKind.value;
}

enums.V1AdminKbImportsKindPostKind v1AdminKbImportsKindPostKindFromJson(
  Object? v1AdminKbImportsKindPostKind, [
  enums.V1AdminKbImportsKindPostKind? defaultValue,
]) {
  return enums.V1AdminKbImportsKindPostKind.values.firstWhereOrNull(
        (e) => e.value == v1AdminKbImportsKindPostKind,
      ) ??
      defaultValue ??
      enums.V1AdminKbImportsKindPostKind.swaggerGeneratedUnknown;
}

enums.V1AdminKbImportsKindPostKind?
v1AdminKbImportsKindPostKindNullableFromJson(
  Object? v1AdminKbImportsKindPostKind, [
  enums.V1AdminKbImportsKindPostKind? defaultValue,
]) {
  if (v1AdminKbImportsKindPostKind == null) {
    return null;
  }
  return enums.V1AdminKbImportsKindPostKind.values.firstWhereOrNull(
        (e) => e.value == v1AdminKbImportsKindPostKind,
      ) ??
      defaultValue;
}

String v1AdminKbImportsKindPostKindExplodedListToJson(
  List<enums.V1AdminKbImportsKindPostKind>? v1AdminKbImportsKindPostKind,
) {
  return v1AdminKbImportsKindPostKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1AdminKbImportsKindPostKindListToJson(
  List<enums.V1AdminKbImportsKindPostKind>? v1AdminKbImportsKindPostKind,
) {
  if (v1AdminKbImportsKindPostKind == null) {
    return [];
  }

  return v1AdminKbImportsKindPostKind.map((e) => e.value!).toList();
}

List<enums.V1AdminKbImportsKindPostKind>
v1AdminKbImportsKindPostKindListFromJson(
  List? v1AdminKbImportsKindPostKind, [
  List<enums.V1AdminKbImportsKindPostKind>? defaultValue,
]) {
  if (v1AdminKbImportsKindPostKind == null) {
    return defaultValue ?? [];
  }

  return v1AdminKbImportsKindPostKind
      .map((e) => v1AdminKbImportsKindPostKindFromJson(e.toString()))
      .toList();
}

List<enums.V1AdminKbImportsKindPostKind>?
v1AdminKbImportsKindPostKindNullableListFromJson(
  List? v1AdminKbImportsKindPostKind, [
  List<enums.V1AdminKbImportsKindPostKind>? defaultValue,
]) {
  if (v1AdminKbImportsKindPostKind == null) {
    return defaultValue;
  }

  return v1AdminKbImportsKindPostKind
      .map((e) => v1AdminKbImportsKindPostKindFromJson(e.toString()))
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
