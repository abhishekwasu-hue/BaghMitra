// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bagmitra.models.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertOut _$AlertOutFromJson(Map<String, dynamic> json) => AlertOut(
  cardId: json['card_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  detail: json['detail'] as String,
  id: json['id'] as String,
  kind: json['kind'] as String,
);

Map<String, dynamic> _$AlertOutToJson(AlertOut instance) => <String, dynamic>{
  'card_id': ?instance.cardId,
  'created_at': instance.createdAt.toIso8601String(),
  'detail': instance.detail,
  'id': instance.id,
  'kind': instance.kind,
};

AlertsResponse _$AlertsResponseFromJson(Map<String, dynamic> json) =>
    AlertsResponse(
      alerts:
          (json['alerts'] as List<dynamic>?)
              ?.map((e) => AlertOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AlertsResponseToJson(AlertsResponse instance) =>
    <String, dynamic>{
      'alerts': instance.alerts.map((e) => e.toJson()).toList(),
    };

CardOut _$CardOutFromJson(Map<String, dynamic> json) => CardOut(
  crop: json['crop'] as String,
  hasChemicalOptions: json['has_chemical_options'] as bool,
  id: json['id'] as String,
  reviewDueAt: json['review_due_at'] == null
      ? null
      : DateTime.parse(json['review_due_at'] as String),
  status: json['status'] as String,
  title: json['title'] as String,
  topic: json['topic'] as String,
  version: (json['version'] as num).toInt(),
);

Map<String, dynamic> _$CardOutToJson(CardOut instance) => <String, dynamic>{
  'crop': instance.crop,
  'has_chemical_options': instance.hasChemicalOptions,
  'id': instance.id,
  'review_due_at': ?instance.reviewDueAt?.toIso8601String(),
  'status': instance.status,
  'title': instance.title,
  'topic': instance.topic,
  'version': instance.version,
};

CardsResponse _$CardsResponseFromJson(Map<String, dynamic> json) =>
    CardsResponse(
      cards:
          (json['cards'] as List<dynamic>?)
              ?.map((e) => CardOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$CardsResponseToJson(CardsResponse instance) =>
    <String, dynamic>{'cards': instance.cards.map((e) => e.toJson()).toList()};

Change _$ChangeFromJson(Map<String, dynamic> json) => Change(
  data: json['data'] as Map<String, dynamic>,
  entity: json['entity'] as String,
  entityId: json['entity_id'] as String,
  op: changeOpFromJson(json['op']),
  seq: (json['seq'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ChangeToJson(Change instance) => <String, dynamic>{
  'data': instance.data,
  'entity': instance.entity,
  'entity_id': instance.entityId,
  'op': ?changeOpToJson(instance.op),
  'seq': instance.seq,
  'updated_at': instance.updatedAt.toIso8601String(),
};

ErrorBody _$ErrorBodyFromJson(Map<String, dynamic> json) => ErrorBody(
  code: json['code'] as String,
  message: json['message'] as String,
  requestId: json['request_id'] as String,
);

Map<String, dynamic> _$ErrorBodyToJson(ErrorBody instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'request_id': instance.requestId,
};

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      error: ErrorBody.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{'error': instance.error.toJson()};

FarmerProfile _$FarmerProfileFromJson(Map<String, dynamic> json) =>
    FarmerProfile(
      consentDataProcessing: json['consent_data_processing'] as bool,
      consentWhatsapp: json['consent_whatsapp'] as bool,
      displayName: json['display_name'] as String?,
      district: json['district'] as String?,
      id: json['id'] as String,
      language: json['language'] as String,
      phone: json['phone'] as String?,
      taluka: json['taluka'] as String?,
      village: json['village'] as String?,
    );

Map<String, dynamic> _$FarmerProfileToJson(FarmerProfile instance) =>
    <String, dynamic>{
      'consent_data_processing': instance.consentDataProcessing,
      'consent_whatsapp': instance.consentWhatsapp,
      'display_name': ?instance.displayName,
      'district': ?instance.district,
      'id': instance.id,
      'language': instance.language,
      'phone': ?instance.phone,
      'taluka': ?instance.taluka,
      'village': ?instance.village,
    };

HTTPValidationError _$HTTPValidationErrorFromJson(Map<String, dynamic> json) =>
    HTTPValidationError(
      detail:
          (json['detail'] as List<dynamic>?)
              ?.map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$HTTPValidationErrorToJson(
  HTTPValidationError instance,
) => <String, dynamic>{
  'detail': ?instance.detail?.map((e) => e.toJson()).toList(),
};

ImportIn _$ImportInFromJson(Map<String, dynamic> json) => ImportIn(
  csv: json['csv'] as String,
  sourceKey: json['source_key'] as String,
);

Map<String, dynamic> _$ImportInToJson(ImportIn instance) => <String, dynamic>{
  'csv': instance.csv,
  'source_key': instance.sourceKey,
};

ImportOut _$ImportOutFromJson(Map<String, dynamic> json) => ImportOut(
  added: (json['added'] as num).toInt(),
  cardsPulled: (json['cards_pulled'] as num).toInt(),
  changed: (json['changed'] as num).toInt(),
  removed: (json['removed'] as num).toInt(),
  unchanged: (json['unchanged'] as num).toInt(),
);

Map<String, dynamic> _$ImportOutToJson(ImportOut instance) => <String, dynamic>{
  'added': instance.added,
  'cards_pulled': instance.cardsPulled,
  'changed': instance.changed,
  'removed': instance.removed,
  'unchanged': instance.unchanged,
};

LiveResponse _$LiveResponseFromJson(Map<String, dynamic> json) => LiveResponse(
  product: json['product'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$LiveResponseToJson(LiveResponse instance) =>
    <String, dynamic>{'product': instance.product, 'status': instance.status};

Mutation _$MutationFromJson(Map<String, dynamic> json) => Mutation(
  clientMutationId: json['client_mutation_id'] as String,
  clientUpdatedAt: DateTime.parse(json['client_updated_at'] as String),
  entity: json['entity'] as String,
  entityId: json['entity_id'] as String,
  op: mutationOpFromJson(json['op']),
  payload: json['payload'] as Map<String, dynamic>,
);

Map<String, dynamic> _$MutationToJson(Mutation instance) => <String, dynamic>{
  'client_mutation_id': instance.clientMutationId,
  'client_updated_at': instance.clientUpdatedAt.toIso8601String(),
  'entity': instance.entity,
  'entity_id': instance.entityId,
  'op': ?mutationOpToJson(instance.op),
  'payload': instance.payload,
};

MutationResult _$MutationResultFromJson(Map<String, dynamic> json) =>
    MutationResult(
      clientMutationId: json['client_mutation_id'] as String,
      error: json['error'] as String?,
      status: mutationResultStatusFromJson(json['status']),
    );

Map<String, dynamic> _$MutationResultToJson(MutationResult instance) =>
    <String, dynamic>{
      'client_mutation_id': instance.clientMutationId,
      'error': ?instance.error,
      'status': ?mutationResultStatusToJson(instance.status),
    };

PullResponse _$PullResponseFromJson(Map<String, dynamic> json) => PullResponse(
  changes:
      (json['changes'] as List<dynamic>?)
          ?.map((e) => Change.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  cursor: (json['cursor'] as num).toInt(),
);

Map<String, dynamic> _$PullResponseToJson(PullResponse instance) =>
    <String, dynamic>{
      'changes': instance.changes.map((e) => e.toJson()).toList(),
      'cursor': instance.cursor,
    };

PushRequest _$PushRequestFromJson(Map<String, dynamic> json) => PushRequest(
  mutations:
      (json['mutations'] as List<dynamic>?)
          ?.map((e) => Mutation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PushRequestToJson(PushRequest instance) =>
    <String, dynamic>{
      'mutations': instance.mutations.map((e) => e.toJson()).toList(),
    };

PushResponse _$PushResponseFromJson(Map<String, dynamic> json) => PushResponse(
  results:
      (json['results'] as List<dynamic>?)
          ?.map((e) => MutationResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PushResponseToJson(PushResponse instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
    };

ReadyResponse _$ReadyResponseFromJson(Map<String, dynamic> json) =>
    ReadyResponse(
      database: json['database'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$ReadyResponseToJson(ReadyResponse instance) =>
    <String, dynamic>{'database': instance.database, 'status': instance.status};

ReviewIn _$ReviewInFromJson(Map<String, dynamic> json) => ReviewIn(
  comments: json['comments'] as String?,
  decision: reviewInDecisionFromJson(json['decision']),
);

Map<String, dynamic> _$ReviewInToJson(ReviewIn instance) => <String, dynamic>{
  'comments': ?instance.comments,
  'decision': ?reviewInDecisionToJson(instance.decision),
};

SourceOut _$SourceOutFromJson(Map<String, dynamic> json) => SourceOut(
  allowedUse: json['allowed_use'] as String,
  id: json['id'] as String,
  key: json['key'] as String,
  publisher: json['publisher'] as String,
  tier: json['tier'] as String,
  title: json['title'] as String,
  url: json['url'] as String,
  verification: json['verification'] as String,
);

Map<String, dynamic> _$SourceOutToJson(SourceOut instance) => <String, dynamic>{
  'allowed_use': instance.allowedUse,
  'id': instance.id,
  'key': instance.key,
  'publisher': instance.publisher,
  'tier': instance.tier,
  'title': instance.title,
  'url': instance.url,
  'verification': instance.verification,
};

SourcesResponse _$SourcesResponseFromJson(Map<String, dynamic> json) =>
    SourcesResponse(
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => SourceOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$SourcesResponseToJson(SourcesResponse instance) =>
    <String, dynamic>{
      'sources': instance.sources.map((e) => e.toJson()).toList(),
    };

StageTemplate _$StageTemplateFromJson(Map<String, dynamic> json) =>
    StageTemplate(
      bahar: json['bahar'] as String,
      crop: json['crop'] as String,
      id: json['id'] as String,
      labels: json['labels'] as Map<String, dynamic>,
      sources: json['sources'] as Map<String, dynamic>,
      stages:
          (json['stages'] as List<dynamic>?)
              ?.map((e) => TemplateStage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: DateTime.parse(json['updated_at'] as String),
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$StageTemplateToJson(StageTemplate instance) =>
    <String, dynamic>{
      'bahar': instance.bahar,
      'crop': instance.crop,
      'id': instance.id,
      'labels': instance.labels,
      'sources': instance.sources,
      'stages': instance.stages.map((e) => e.toJson()).toList(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'version': instance.version,
    };

StageTemplatesResponse _$StageTemplatesResponseFromJson(
  Map<String, dynamic> json,
) => StageTemplatesResponse(
  templates:
      (json['templates'] as List<dynamic>?)
          ?.map((e) => StageTemplate.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$StageTemplatesResponseToJson(
  StageTemplatesResponse instance,
) => <String, dynamic>{
  'templates': instance.templates.map((e) => e.toJson()).toList(),
};

TemplateStage _$TemplateStageFromJson(Map<String, dynamic> json) =>
    TemplateStage(
      anchor: json['anchor'] as String,
      key: json['key'] as String,
      labels: json['labels'] as Map<String, dynamic>,
      offsetDaysMax: (json['offset_days_max'] as num).toInt(),
      offsetDaysMin: (json['offset_days_min'] as num).toInt(),
      sourceIds:
          (json['source_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$TemplateStageToJson(TemplateStage instance) =>
    <String, dynamic>{
      'anchor': instance.anchor,
      'key': instance.key,
      'labels': instance.labels,
      'offset_days_max': instance.offsetDaysMax,
      'offset_days_min': instance.offsetDaysMin,
      'source_ids': instance.sourceIds,
    };

ValidationError _$ValidationErrorFromJson(
  Map<String, dynamic> json,
) => ValidationError(
  loc: (json['loc'] as List<dynamic>?)?.map((e) => e as Object).toList() ?? [],
  msg: json['msg'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$ValidationErrorToJson(ValidationError instance) =>
    <String, dynamic>{
      'loc': instance.loc,
      'msg': instance.msg,
      'type': instance.type,
    };
