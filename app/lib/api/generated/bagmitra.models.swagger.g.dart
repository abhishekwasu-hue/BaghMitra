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

DeviceIn _$DeviceInFromJson(Map<String, dynamic> json) => DeviceIn(
  platform: deviceInPlatformFromJson(json['platform']),
  token: json['token'] as String,
);

Map<String, dynamic> _$DeviceInToJson(DeviceIn instance) => <String, dynamic>{
  'platform': ?deviceInPlatformToJson(instance.platform),
  'token': instance.token,
};

DeviceOut _$DeviceOutFromJson(Map<String, dynamic> json) =>
    DeviceOut(token: json['token'] as String);

Map<String, dynamic> _$DeviceOutToJson(DeviceOut instance) => <String, dynamic>{
  'token': instance.token,
};

EntitlementsOut _$EntitlementsOutFromJson(Map<String, dynamic> json) =>
    EntitlementsOut(
      computedAt: json['computed_at'] as String,
      features: json['features'] as Map<String, dynamic>,
      plans:
          (json['plans'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      validUntil: json['valid_until'] as String,
    );

Map<String, dynamic> _$EntitlementsOutToJson(EntitlementsOut instance) =>
    <String, dynamic>{
      'computed_at': instance.computedAt,
      'features': instance.features,
      'plans': instance.plans,
      'valid_until': instance.validUntil,
    };

EntitlementsResponse _$EntitlementsResponseFromJson(
  Map<String, dynamic> json,
) => EntitlementsResponse(
  entitlements: EntitlementsOut.fromJson(
    json['entitlements'] as Map<String, dynamic>,
  ),
  signature: json['signature'] as String?,
);

Map<String, dynamic> _$EntitlementsResponseToJson(
  EntitlementsResponse instance,
) => <String, dynamic>{
  'entitlements': instance.entitlements.toJson(),
  'signature': ?instance.signature,
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

EventOut _$EventOutFromJson(Map<String, dynamic> json) => EventOut(
  createdAt: DateTime.parse(json['created_at'] as String),
  eventType: json['event_type'] as String,
  id: json['id'] as String,
  provider: json['provider'] as String,
  subscriptionId: json['subscription_id'] as String?,
);

Map<String, dynamic> _$EventOutToJson(EventOut instance) => <String, dynamic>{
  'created_at': instance.createdAt.toIso8601String(),
  'event_type': instance.eventType,
  'id': instance.id,
  'provider': instance.provider,
  'subscription_id': ?instance.subscriptionId,
};

EventsResponse _$EventsResponseFromJson(Map<String, dynamic> json) =>
    EventsResponse(
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => EventOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$EventsResponseToJson(EventsResponse instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
    };

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

FeatureConfig _$FeatureConfigFromJson(Map<String, dynamic> json) =>
    FeatureConfig(
      feature: json['feature'] as String,
      limit: (json['limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FeatureConfigToJson(FeatureConfig instance) =>
    <String, dynamic>{'feature': instance.feature, 'limit': ?instance.limit};

FeatureOut _$FeatureOutFromJson(Map<String, dynamic> json) => FeatureOut(
  enabled: json['enabled'] as bool,
  limit: (json['limit'] as num?)?.toInt(),
);

Map<String, dynamic> _$FeatureOutToJson(FeatureOut instance) =>
    <String, dynamic>{'enabled': instance.enabled, 'limit': ?instance.limit};

GrantIn _$GrantInFromJson(Map<String, dynamic> json) => GrantIn(
  periodEnd: DateTime.parse(json['period_end'] as String),
  planKey: json['plan_key'] as String,
  reason: json['reason'] as String,
  subjectId: json['subject_id'] as String,
  subjectType: grantInSubjectTypeFromJson(json['subject_type']),
);

Map<String, dynamic> _$GrantInToJson(GrantIn instance) => <String, dynamic>{
  'period_end': instance.periodEnd.toIso8601String(),
  'plan_key': instance.planKey,
  'reason': instance.reason,
  'subject_id': instance.subjectId,
  'subject_type': ?grantInSubjectTypeToJson(instance.subjectType),
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

LabelClaimOut _$LabelClaimOutFromJson(Map<String, dynamic> json) =>
    LabelClaimOut(
      activeIngredient: json['active_ingredient'] as String,
      dose: json['dose'] as String,
      formulation: json['formulation'] as String,
      intervalDays: (json['interval_days'] as num?)?.toInt(),
      labelCrop: json['label_crop'] as String,
      maxSprays: (json['max_sprays'] as num?)?.toInt(),
      phiDays: (json['phi_days'] as num?)?.toInt(),
      sourceKey: json['source_key'] as String,
      sourceTitle: json['source_title'] as String,
      sourceUrl: json['source_url'] as String,
      target: json['target'] as String,
    );

Map<String, dynamic> _$LabelClaimOutToJson(LabelClaimOut instance) =>
    <String, dynamic>{
      'active_ingredient': instance.activeIngredient,
      'dose': instance.dose,
      'formulation': instance.formulation,
      'interval_days': ?instance.intervalDays,
      'label_crop': instance.labelCrop,
      'max_sprays': ?instance.maxSprays,
      'phi_days': ?instance.phiDays,
      'source_key': instance.sourceKey,
      'source_title': instance.sourceTitle,
      'source_url': instance.sourceUrl,
      'target': instance.target,
    };

LabelClaimsResponse _$LabelClaimsResponseFromJson(Map<String, dynamic> json) =>
    LabelClaimsResponse(
      claims:
          (json['claims'] as List<dynamic>?)
              ?.map((e) => LabelClaimOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      kind: json['kind'] as String?,
    );

Map<String, dynamic> _$LabelClaimsResponseToJson(
  LabelClaimsResponse instance,
) => <String, dynamic>{
  'claims': instance.claims.map((e) => e.toJson()).toList(),
  'kind': ?instance.kind,
};

LiveResponse _$LiveResponseFromJson(Map<String, dynamic> json) => LiveResponse(
  product: json['product'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$LiveResponseToJson(LiveResponse instance) =>
    <String, dynamic>{'product': instance.product, 'status': instance.status};

ManualPriceIn _$ManualPriceInFromJson(Map<String, dynamic> json) =>
    ManualPriceIn(
      commodity: json['commodity'] as String,
      day: DateTime.parse(json['day'] as String),
      district: json['district'] as String,
      grade: json['grade'] as String?,
      market: json['market'] as String,
      maxRsPerQuintal: (json['max_rs_per_quintal'] as num?)?.toInt(),
      minRsPerQuintal: (json['min_rs_per_quintal'] as num?)?.toInt(),
      modalRsPerQuintal: (json['modal_rs_per_quintal'] as num).toInt(),
      state: json['state'] as String,
      variety: json['variety'] as String?,
    );

Map<String, dynamic> _$ManualPriceInToJson(ManualPriceIn instance) =>
    <String, dynamic>{
      'commodity': instance.commodity,
      'day': ?_dateToJson(instance.day),
      'district': instance.district,
      'grade': ?instance.grade,
      'market': instance.market,
      'max_rs_per_quintal': ?instance.maxRsPerQuintal,
      'min_rs_per_quintal': ?instance.minRsPerQuintal,
      'modal_rs_per_quintal': instance.modalRsPerQuintal,
      'state': instance.state,
      'variety': ?instance.variety,
    };

ManualPricesIn _$ManualPricesInFromJson(Map<String, dynamic> json) =>
    ManualPricesIn(
      prices:
          (json['prices'] as List<dynamic>?)
              ?.map((e) => ManualPriceIn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ManualPricesInToJson(ManualPricesIn instance) =>
    <String, dynamic>{
      'prices': instance.prices.map((e) => e.toJson()).toList(),
    };

ManualPricesOut _$ManualPricesOutFromJson(Map<String, dynamic> json) =>
    ManualPricesOut(stored: (json['stored'] as num).toInt());

Map<String, dynamic> _$ManualPricesOutToJson(ManualPricesOut instance) =>
    <String, dynamic>{'stored': instance.stored};

MarketPriceOut _$MarketPriceOutFromJson(Map<String, dynamic> json) =>
    MarketPriceOut(
      commodity: json['commodity'] as String,
      day: DateTime.parse(json['day'] as String),
      district: json['district'] as String,
      grade: json['grade'] as String?,
      isLocal: json['is_local'] as bool,
      isMajor: json['is_major'] as bool,
      market: json['market'] as String,
      maxRsPerQuintal: (json['max_rs_per_quintal'] as num?)?.toInt(),
      minRsPerQuintal: (json['min_rs_per_quintal'] as num?)?.toInt(),
      modalRsPerQuintal: (json['modal_rs_per_quintal'] as num).toInt(),
      source: json['source'] as String,
      state: json['state'] as String,
      variety: json['variety'] as String?,
    );

Map<String, dynamic> _$MarketPriceOutToJson(MarketPriceOut instance) =>
    <String, dynamic>{
      'commodity': instance.commodity,
      'day': ?_dateToJson(instance.day),
      'district': instance.district,
      'grade': ?instance.grade,
      'is_local': instance.isLocal,
      'is_major': instance.isMajor,
      'market': instance.market,
      'max_rs_per_quintal': ?instance.maxRsPerQuintal,
      'min_rs_per_quintal': ?instance.minRsPerQuintal,
      'modal_rs_per_quintal': instance.modalRsPerQuintal,
      'source': instance.source,
      'state': instance.state,
      'variety': ?instance.variety,
    };

MarketPrices _$MarketPricesFromJson(Map<String, dynamic> json) => MarketPrices(
  prices:
      (json['prices'] as List<dynamic>?)
          ?.map((e) => MarketPriceOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  reason: json['reason'] as String?,
  stale: json['stale'] as bool,
);

Map<String, dynamic> _$MarketPricesToJson(MarketPrices instance) =>
    <String, dynamic>{
      'prices': instance.prices.map((e) => e.toJson()).toList(),
      'reason': ?instance.reason,
      'stale': instance.stale,
    };

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

PlanIn _$PlanInFromJson(Map<String, dynamic> json) => PlanIn(
  active: json['active'] as bool? ?? true,
  features: json['features'] as Object,
  kind: planInKindFromJson(json['kind']),
  names: json['names'] as Map<String, dynamic>,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
);

Map<String, dynamic> _$PlanInToJson(PlanIn instance) => <String, dynamic>{
  'active': ?instance.active,
  'features': instance.features,
  'kind': ?planInKindToJson(instance.kind),
  'names': instance.names,
  'sort_order': ?instance.sortOrder,
};

PlanOut _$PlanOutFromJson(Map<String, dynamic> json) => PlanOut(
  active: json['active'] as bool,
  features:
      (json['features'] as List<dynamic>?)
          ?.map((e) => FeatureConfig.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  key: json['key'] as String,
  kind: json['kind'] as String,
  names: json['names'] as Map<String, dynamic>,
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$PlanOutToJson(PlanOut instance) => <String, dynamic>{
  'active': instance.active,
  'features': instance.features.map((e) => e.toJson()).toList(),
  'key': instance.key,
  'kind': instance.kind,
  'names': instance.names,
  'sort_order': instance.sortOrder,
};

PlansResponse _$PlansResponseFromJson(Map<String, dynamic> json) =>
    PlansResponse(
      plans:
          (json['plans'] as List<dynamic>?)
              ?.map((e) => PlanOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$PlansResponseToJson(PlansResponse instance) =>
    <String, dynamic>{'plans': instance.plans.map((e) => e.toJson()).toList()};

PlotWeather _$PlotWeatherFromJson(Map<String, dynamic> json) => PlotWeather(
  alerts:
      (json['alerts'] as List<dynamic>?)
          ?.map((e) => WeatherAlert.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  days:
      (json['days'] as List<dynamic>?)
          ?.map((e) => WeatherDay.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  stale: json['stale'] as bool,
);

Map<String, dynamic> _$PlotWeatherToJson(PlotWeather instance) =>
    <String, dynamic>{
      'alerts': instance.alerts.map((e) => e.toJson()).toList(),
      'days': instance.days.map((e) => e.toJson()).toList(),
      'stale': instance.stale,
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

RestrictionOut _$RestrictionOutFromJson(Map<String, dynamic> json) =>
    RestrictionOut(
      activeIngredient: json['active_ingredient'] as String,
      cropGroups:
          (json['crop_groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      crops:
          (json['crops'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      kind: json['kind'] as String,
      notification: json['notification'] as String,
    );

Map<String, dynamic> _$RestrictionOutToJson(RestrictionOut instance) =>
    <String, dynamic>{
      'active_ingredient': instance.activeIngredient,
      'crop_groups': instance.cropGroups,
      'crops': instance.crops,
      'effective_from': instance.effectiveFrom.toIso8601String(),
      'kind': instance.kind,
      'notification': instance.notification,
    };

RestrictionsResponse _$RestrictionsResponseFromJson(
  Map<String, dynamic> json,
) => RestrictionsResponse(
  restrictions:
      (json['restrictions'] as List<dynamic>?)
          ?.map((e) => RestrictionOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  synonyms:
      (json['synonyms'] as List<dynamic>?)
          ?.map((e) => SynonymOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$RestrictionsResponseToJson(
  RestrictionsResponse instance,
) => <String, dynamic>{
  'restrictions': instance.restrictions.map((e) => e.toJson()).toList(),
  'synonyms': instance.synonyms.map((e) => e.toJson()).toList(),
};

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
  contentHash: json['content_hash'] as String?,
  fetchError: json['fetch_error'] as String?,
  fetchStatus: json['fetch_status'] as String,
  fetchedAt: json['fetched_at'] == null
      ? null
      : DateTime.parse(json['fetched_at'] as String),
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
  'content_hash': ?instance.contentHash,
  'fetch_error': ?instance.fetchError,
  'fetch_status': instance.fetchStatus,
  'fetched_at': ?instance.fetchedAt?.toIso8601String(),
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

SubscriptionOut _$SubscriptionOutFromJson(Map<String, dynamic> json) =>
    SubscriptionOut(
      id: json['id'] as String,
      periodEnd: DateTime.parse(json['period_end'] as String),
      periodStart: DateTime.parse(json['period_start'] as String),
      planKey: json['plan_key'] as String,
      provider: json['provider'] as String,
      reason: json['reason'] as String?,
      state: json['state'] as String,
      subjectId: json['subject_id'] as String,
      subjectType: json['subject_type'] as String,
    );

Map<String, dynamic> _$SubscriptionOutToJson(SubscriptionOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'period_end': instance.periodEnd.toIso8601String(),
      'period_start': instance.periodStart.toIso8601String(),
      'plan_key': instance.planKey,
      'provider': instance.provider,
      'reason': ?instance.reason,
      'state': instance.state,
      'subject_id': instance.subjectId,
      'subject_type': instance.subjectType,
    };

SubscriptionsResponse _$SubscriptionsResponseFromJson(
  Map<String, dynamic> json,
) => SubscriptionsResponse(
  subscriptions:
      (json['subscriptions'] as List<dynamic>?)
          ?.map((e) => SubscriptionOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$SubscriptionsResponseToJson(
  SubscriptionsResponse instance,
) => <String, dynamic>{
  'subscriptions': instance.subscriptions.map((e) => e.toJson()).toList(),
};

SynonymOut _$SynonymOutFromJson(Map<String, dynamic> json) => SynonymOut(
  activeIngredient: json['active_ingredient'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$SynonymOutToJson(SynonymOut instance) =>
    <String, dynamic>{
      'active_ingredient': instance.activeIngredient,
      'name': instance.name,
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

WeatherAlert _$WeatherAlertFromJson(Map<String, dynamic> json) => WeatherAlert(
  firstDay: DateTime.parse(json['first_day'] as String),
  ruleKey: json['rule_key'] as String,
  source: json['source'] as String,
  status: json['status'] as String,
  text: json['text'] as String,
  units: (json['units'] as num?)?.toDouble(),
  value: (json['value'] as num).toDouble(),
);

Map<String, dynamic> _$WeatherAlertToJson(WeatherAlert instance) =>
    <String, dynamic>{
      'first_day': ?_dateToJson(instance.firstDay),
      'rule_key': instance.ruleKey,
      'source': instance.source,
      'status': instance.status,
      'text': instance.text,
      'units': ?instance.units,
      'value': instance.value,
    };

WeatherDay _$WeatherDayFromJson(Map<String, dynamic> json) => WeatherDay(
  day: DateTime.parse(json['day'] as String),
  precipMm: (json['precip_mm'] as num?)?.toDouble(),
  rhMeanPct: (json['rh_mean_pct'] as num?)?.toDouble(),
  tMaxC: (json['t_max_c'] as num?)?.toDouble(),
  tMinC: (json['t_min_c'] as num?)?.toDouble(),
  windGustKmh: (json['wind_gust_kmh'] as num?)?.toDouble(),
);

Map<String, dynamic> _$WeatherDayToJson(WeatherDay instance) =>
    <String, dynamic>{
      'day': ?_dateToJson(instance.day),
      'precip_mm': ?instance.precipMm,
      'rh_mean_pct': ?instance.rhMeanPct,
      't_max_c': ?instance.tMaxC,
      't_min_c': ?instance.tMinC,
      'wind_gust_kmh': ?instance.windGustKmh,
    };
