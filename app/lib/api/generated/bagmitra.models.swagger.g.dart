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

FeedAdminApproveIn _$FeedAdminApproveInFromJson(Map<String, dynamic> json) =>
    FeedAdminApproveIn(
      acceptCheckIssues: json['accept_check_issues'] as bool? ?? false,
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$FeedAdminApproveInToJson(FeedAdminApproveIn instance) =>
    <String, dynamic>{
      'accept_check_issues': ?instance.acceptCheckIssues,
      'comment': ?instance.comment,
    };

FeedAdminCardFieldIn _$FeedAdminCardFieldInFromJson(
  Map<String, dynamic> json,
) => FeedAdminCardFieldIn(
  page: json['page'] as String?,
  value: json['value'] as String,
);

Map<String, dynamic> _$FeedAdminCardFieldInToJson(
  FeedAdminCardFieldIn instance,
) => <String, dynamic>{'page': ?instance.page, 'value': instance.value};

FeedAdminCardIn _$FeedAdminCardInFromJson(Map<String, dynamic> json) =>
    FeedAdminCardIn(fields: json['fields'] as Map<String, dynamic>);

Map<String, dynamic> _$FeedAdminCardInToJson(FeedAdminCardIn instance) =>
    <String, dynamic>{'fields': instance.fields};

FeedAdminCardOut _$FeedAdminCardOutFromJson(Map<String, dynamic> json) =>
    FeedAdminCardOut(
      fields: json['fields'] as Map<String, dynamic>,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$FeedAdminCardOutToJson(FeedAdminCardOut instance) =>
    <String, dynamic>{'fields': instance.fields, 'version': instance.version};

FeedAdminCheckIssue _$FeedAdminCheckIssueFromJson(Map<String, dynamic> json) =>
    FeedAdminCheckIssue(
      kind: json['kind'] as String,
      text: json['text'] as String,
      where: json['where'] as String,
    );

Map<String, dynamic> _$FeedAdminCheckIssueToJson(
  FeedAdminCheckIssue instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'text': instance.text,
  'where': instance.where,
};

FeedAdminDatesIn _$FeedAdminDatesInFromJson(Map<String, dynamic> json) =>
    FeedAdminDatesIn(
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      paymentDate: json['payment_date'] == null
          ? null
          : DateTime.parse(json['payment_date'] as String),
      validFrom: json['valid_from'] == null
          ? null
          : DateTime.parse(json['valid_from'] as String),
      validTo: json['valid_to'] == null
          ? null
          : DateTime.parse(json['valid_to'] as String),
    );

Map<String, dynamic> _$FeedAdminDatesInToJson(FeedAdminDatesIn instance) =>
    <String, dynamic>{
      'deadline': ?_dateToJson(instance.deadline),
      'payment_date': ?_dateToJson(instance.paymentDate),
      'valid_from': ?_dateToJson(instance.validFrom),
      'valid_to': ?_dateToJson(instance.validTo),
    };

FeedAdminEventOut _$FeedAdminEventOutFromJson(Map<String, dynamic> json) =>
    FeedAdminEventOut(
      actorId: json['actor_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      detail: json['detail'] as Map<String, dynamic>,
      kind: json['kind'] as String,
    );

Map<String, dynamic> _$FeedAdminEventOutToJson(FeedAdminEventOut instance) =>
    <String, dynamic>{
      'actor_id': ?instance.actorId,
      'created_at': instance.createdAt.toIso8601String(),
      'detail': instance.detail,
      'kind': instance.kind,
    };

FeedAdminItemIn _$FeedAdminItemInFromJson(Map<String, dynamic> json) =>
    FeedAdminItemIn(
      card: json['card'],
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      department: json['department'] as String?,
      documentBase64: json['document_base64'] as String?,
      documentType: json['document_type'] as String?,
      externalId: json['external_id'] as String?,
      extractedText: json['extracted_text'] as String?,
      grNumber: json['gr_number'] as String?,
      paymentDate: json['payment_date'] == null
          ? null
          : DateTime.parse(json['payment_date'] as String),
      publishedAt: DateTime.parse(json['published_at'] as String),
      sourceKey: json['source_key'] as String,
      targets:
          (json['targets'] as List<dynamic>?)
              ?.map(
                (e) => FeedAdminTargetIn.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      texts: json['texts'] as Map<String, dynamic>?,
      type: feedAdminItemInTypeFromJson(json['type']),
      url: json['url'] as String,
      validFrom: json['valid_from'] == null
          ? null
          : DateTime.parse(json['valid_from'] as String),
      validTo: json['valid_to'] == null
          ? null
          : DateTime.parse(json['valid_to'] as String),
    );

Map<String, dynamic> _$FeedAdminItemInToJson(FeedAdminItemIn instance) =>
    <String, dynamic>{
      'card': ?instance.card,
      'deadline': ?_dateToJson(instance.deadline),
      'department': ?instance.department,
      'document_base64': ?instance.documentBase64,
      'document_type': ?instance.documentType,
      'external_id': ?instance.externalId,
      'extracted_text': ?instance.extractedText,
      'gr_number': ?instance.grNumber,
      'payment_date': ?_dateToJson(instance.paymentDate),
      'published_at': instance.publishedAt.toIso8601String(),
      'source_key': instance.sourceKey,
      'targets': ?instance.targets?.map((e) => e.toJson()).toList(),
      'texts': ?instance.texts,
      'type': ?feedAdminItemInTypeToJson(instance.type),
      'url': instance.url,
      'valid_from': ?_dateToJson(instance.validFrom),
      'valid_to': ?_dateToJson(instance.validTo),
    };

FeedAdminItemOut _$FeedAdminItemOutFromJson(
  Map<String, dynamic> json,
) => FeedAdminItemOut(
  approved: json['approved'] as bool,
  card: json['card'] == null
      ? null
      : FeedAdminCardOut.fromJson(json['card'] as Map<String, dynamic>),
  checkIssues:
      (json['check_issues'] as List<dynamic>?)
          ?.map((e) => FeedAdminCheckIssue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  department: json['department'] as String?,
  events:
      (json['events'] as List<dynamic>?)
          ?.map((e) => FeedAdminEventOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  externalId: json['external_id'] as String?,
  extractedText: json['extracted_text'] as String?,
  extractedTextTruncated: json['extracted_text_truncated'] as bool? ?? false,
  grNumber: json['gr_number'] as String?,
  hasText: json['has_text'] as bool,
  id: json['id'] as String,
  paymentDate: json['payment_date'] == null
      ? null
      : DateTime.parse(json['payment_date'] as String),
  publishedAt: DateTime.parse(json['published_at'] as String),
  rawBytes: (json['raw_bytes'] as num?)?.toInt(),
  rawHash: json['raw_hash'] as String?,
  replacedById: json['replaced_by_id'] as String?,
  sourceKey: json['source_key'] as String,
  status: json['status'] as String,
  targets:
      (json['targets'] as List<dynamic>?)
          ?.map((e) => FeedAdminTargetOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  texts: json['texts'] as Map<String, dynamic>,
  title: json['title'] as String?,
  trust: json['trust'] as String,
  type: json['type'] as String,
  url: json['url'] as String,
  validFrom: json['valid_from'] == null
      ? null
      : DateTime.parse(json['valid_from'] as String),
  validTo: json['valid_to'] == null
      ? null
      : DateTime.parse(json['valid_to'] as String),
);

Map<String, dynamic> _$FeedAdminItemOutToJson(FeedAdminItemOut instance) =>
    <String, dynamic>{
      'approved': instance.approved,
      'card': ?instance.card?.toJson(),
      'check_issues': instance.checkIssues.map((e) => e.toJson()).toList(),
      'deadline': ?_dateToJson(instance.deadline),
      'department': ?instance.department,
      'events': instance.events.map((e) => e.toJson()).toList(),
      'external_id': ?instance.externalId,
      'extracted_text': ?instance.extractedText,
      'extracted_text_truncated': ?instance.extractedTextTruncated,
      'gr_number': ?instance.grNumber,
      'has_text': instance.hasText,
      'id': instance.id,
      'payment_date': ?_dateToJson(instance.paymentDate),
      'published_at': instance.publishedAt.toIso8601String(),
      'raw_bytes': ?instance.rawBytes,
      'raw_hash': ?instance.rawHash,
      'replaced_by_id': ?instance.replacedById,
      'source_key': instance.sourceKey,
      'status': instance.status,
      'targets': instance.targets.map((e) => e.toJson()).toList(),
      'texts': instance.texts,
      'title': ?instance.title,
      'trust': instance.trust,
      'type': instance.type,
      'url': instance.url,
      'valid_from': ?_dateToJson(instance.validFrom),
      'valid_to': ?_dateToJson(instance.validTo),
    };

FeedAdminItemSummaryOut _$FeedAdminItemSummaryOutFromJson(
  Map<String, dynamic> json,
) => FeedAdminItemSummaryOut(
  approved: json['approved'] as bool,
  checkIssues:
      (json['check_issues'] as List<dynamic>?)
          ?.map((e) => FeedAdminCheckIssue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  department: json['department'] as String?,
  grNumber: json['gr_number'] as String?,
  id: json['id'] as String,
  publishedAt: DateTime.parse(json['published_at'] as String),
  status: json['status'] as String,
  title: json['title'] as String?,
  trust: json['trust'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$FeedAdminItemSummaryOutToJson(
  FeedAdminItemSummaryOut instance,
) => <String, dynamic>{
  'approved': instance.approved,
  'check_issues': instance.checkIssues.map((e) => e.toJson()).toList(),
  'department': ?instance.department,
  'gr_number': ?instance.grNumber,
  'id': instance.id,
  'published_at': instance.publishedAt.toIso8601String(),
  'status': instance.status,
  'title': ?instance.title,
  'trust': instance.trust,
  'type': instance.type,
};

FeedAdminItemTextOut _$FeedAdminItemTextOutFromJson(
  Map<String, dynamic> json,
) => FeedAdminItemTextOut(
  summary: json['summary'] as String?,
  title: json['title'] as String,
);

Map<String, dynamic> _$FeedAdminItemTextOutToJson(
  FeedAdminItemTextOut instance,
) => <String, dynamic>{'summary': ?instance.summary, 'title': instance.title};

FeedAdminItemsResponse _$FeedAdminItemsResponseFromJson(
  Map<String, dynamic> json,
) => FeedAdminItemsResponse(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => FeedAdminItemSummaryOut.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$FeedAdminItemsResponseToJson(
  FeedAdminItemsResponse instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

FeedAdminSourceOut _$FeedAdminSourceOutFromJson(Map<String, dynamic> json) =>
    FeedAdminSourceOut(
      fetchMethod: json['fetch_method'] as String,
      fetchStatus: json['fetch_status'] as String,
      id: json['id'] as String,
      key: json['key'] as String,
      lastError: json['last_error'] as String?,
      lastOkAt: json['last_ok_at'] == null
          ? null
          : DateTime.parse(json['last_ok_at'] as String),
      name: json['name'] as String,
      notes: json['notes'] as String?,
      termsStatus: json['terms_status'] as String,
      tier: json['tier'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$FeedAdminSourceOutToJson(FeedAdminSourceOut instance) =>
    <String, dynamic>{
      'fetch_method': instance.fetchMethod,
      'fetch_status': instance.fetchStatus,
      'id': instance.id,
      'key': instance.key,
      'last_error': ?instance.lastError,
      'last_ok_at': ?instance.lastOkAt?.toIso8601String(),
      'name': instance.name,
      'notes': ?instance.notes,
      'terms_status': instance.termsStatus,
      'tier': instance.tier,
      'url': instance.url,
    };

FeedAdminSourcesResponse _$FeedAdminSourcesResponseFromJson(
  Map<String, dynamic> json,
) => FeedAdminSourcesResponse(
  sources:
      (json['sources'] as List<dynamic>?)
          ?.map((e) => FeedAdminSourceOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$FeedAdminSourcesResponseToJson(
  FeedAdminSourcesResponse instance,
) => <String, dynamic>{
  'sources': instance.sources.map((e) => e.toJson()).toList(),
};

FeedAdminTargetIn _$FeedAdminTargetInFromJson(Map<String, dynamic> json) =>
    FeedAdminTargetIn(
      crop: json['crop'] as String?,
      district: json['district'] as String?,
      maxHa: (json['max_ha'] as num?)?.toDouble(),
      minHa: (json['min_ha'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FeedAdminTargetInToJson(FeedAdminTargetIn instance) =>
    <String, dynamic>{
      'crop': ?instance.crop,
      'district': ?instance.district,
      'max_ha': ?instance.maxHa,
      'min_ha': ?instance.minHa,
    };

FeedAdminTargetOut _$FeedAdminTargetOutFromJson(Map<String, dynamic> json) =>
    FeedAdminTargetOut(
      crop: json['crop'] as String?,
      district: json['district'] as String?,
      maxHa: (json['max_ha'] as num?)?.toDouble(),
      minHa: (json['min_ha'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FeedAdminTargetOutToJson(FeedAdminTargetOut instance) =>
    <String, dynamic>{
      'crop': ?instance.crop,
      'district': ?instance.district,
      'max_ha': ?instance.maxHa,
      'min_ha': ?instance.minHa,
    };

FeedAdminTargetsIn _$FeedAdminTargetsInFromJson(Map<String, dynamic> json) =>
    FeedAdminTargetsIn(
      targets:
          (json['targets'] as List<dynamic>?)
              ?.map(
                (e) => FeedAdminTargetIn.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$FeedAdminTargetsInToJson(FeedAdminTargetsIn instance) =>
    <String, dynamic>{
      'targets': instance.targets.map((e) => e.toJson()).toList(),
    };

FeedAdminTermsIn _$FeedAdminTermsInFromJson(Map<String, dynamic> json) =>
    FeedAdminTermsIn(
      notes: json['notes'] as String?,
      termsStatus: feedAdminTermsInTermsStatusFromJson(json['terms_status']),
    );

Map<String, dynamic> _$FeedAdminTermsInToJson(FeedAdminTermsIn instance) =>
    <String, dynamic>{
      'notes': ?instance.notes,
      'terms_status': ?feedAdminTermsInTermsStatusToJson(instance.termsStatus),
    };

FeedAdminTextIn _$FeedAdminTextInFromJson(Map<String, dynamic> json) =>
    FeedAdminTextIn(
      summary: json['summary'] as String?,
      title: json['title'] as String,
    );

Map<String, dynamic> _$FeedAdminTextInToJson(FeedAdminTextIn instance) =>
    <String, dynamic>{'summary': ?instance.summary, 'title': instance.title};

FeedAdminWithdrawIn _$FeedAdminWithdrawInFromJson(Map<String, dynamic> json) =>
    FeedAdminWithdrawIn(
      reason: json['reason'] as String,
      replacedById: json['replaced_by_id'] as String?,
    );

Map<String, dynamic> _$FeedAdminWithdrawInToJson(
  FeedAdminWithdrawIn instance,
) => <String, dynamic>{
  'reason': instance.reason,
  'replaced_by_id': ?instance.replacedById,
};

FeedCheckIn _$FeedCheckInFromJson(Map<String, dynamic> json) =>
    FeedCheckIn(text: json['text'] as String);

Map<String, dynamic> _$FeedCheckInToJson(FeedCheckIn instance) =>
    <String, dynamic>{'text': instance.text};

FeedCheckMatch _$FeedCheckMatchFromJson(Map<String, dynamic> json) =>
    FeedCheckMatch(
      grNumber: json['gr_number'] as String?,
      id: json['id'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      score: (json['score'] as num).toDouble(),
      title: json['title'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$FeedCheckMatchToJson(FeedCheckMatch instance) =>
    <String, dynamic>{
      'gr_number': ?instance.grNumber,
      'id': instance.id,
      'published_at': instance.publishedAt.toIso8601String(),
      'score': instance.score,
      'title': instance.title,
      'url': instance.url,
    };

FeedCheckResponse _$FeedCheckResponseFromJson(Map<String, dynamic> json) =>
    FeedCheckResponse(
      matches:
          (json['matches'] as List<dynamic>?)
              ?.map((e) => FeedCheckMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      note: json['note'] as String,
      verdict: feedCheckResponseVerdictFromJson(json['verdict']),
    );

Map<String, dynamic> _$FeedCheckResponseToJson(FeedCheckResponse instance) =>
    <String, dynamic>{
      'matches': instance.matches.map((e) => e.toJson()).toList(),
      'note': instance.note,
      'verdict': ?feedCheckResponseVerdictToJson(instance.verdict),
    };

FeedItemOut _$FeedItemOutFromJson(Map<String, dynamic> json) => FeedItemOut(
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  department: json['department'] as String?,
  grNumber: json['gr_number'] as String?,
  id: json['id'] as String,
  mayBeEligibleBecause:
      (json['may_be_eligible_because'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  publishedAt: DateTime.parse(json['published_at'] as String),
  replacedBy: json['replaced_by'] as String?,
  seen: json['seen'] as bool? ?? false,
  summary: json['summary'] as String?,
  title: json['title'] as String,
  trust: feedItemOutTrustFromJson(json['trust']),
  type: json['type'] as String,
  url: json['url'] as String,
  validTo: json['valid_to'] == null
      ? null
      : DateTime.parse(json['valid_to'] as String),
);

Map<String, dynamic> _$FeedItemOutToJson(FeedItemOut instance) =>
    <String, dynamic>{
      'deadline': ?_dateToJson(instance.deadline),
      'department': ?instance.department,
      'gr_number': ?instance.grNumber,
      'id': instance.id,
      'may_be_eligible_because': instance.mayBeEligibleBecause,
      'published_at': instance.publishedAt.toIso8601String(),
      'replaced_by': ?instance.replacedBy,
      'seen': ?instance.seen,
      'summary': ?instance.summary,
      'title': instance.title,
      'trust': ?feedItemOutTrustToJson(instance.trust),
      'type': instance.type,
      'url': instance.url,
      'valid_to': ?_dateToJson(instance.validTo),
    };

FeedPreferencesBody _$FeedPreferencesBodyFromJson(Map<String, dynamic> json) =>
    FeedPreferencesBody(
      digestWeekly: json['digest_weekly'] as bool,
      optedOut: feedPreferencesBodyOptedOutListFromJson(
        json['opted_out'] as List?,
      ),
      quietEnd: json['quiet_end'] as String,
      quietStart: json['quiet_start'] as String,
      weeklyCap: (json['weekly_cap'] as num).toInt(),
    );

Map<String, dynamic> _$FeedPreferencesBodyToJson(
  FeedPreferencesBody instance,
) => <String, dynamic>{
  'digest_weekly': instance.digestWeekly,
  'opted_out': feedPreferencesBodyOptedOutListToJson(instance.optedOut),
  'quiet_end': instance.quietEnd,
  'quiet_start': instance.quietStart,
  'weekly_cap': instance.weeklyCap,
};

FeedReceiptOut _$FeedReceiptOutFromJson(Map<String, dynamic> json) =>
    FeedReceiptOut(
      dismissed: json['dismissed'] as bool,
      itemId: json['item_id'] as String,
      remind: json['remind'] as bool,
      seen: json['seen'] as bool,
    );

Map<String, dynamic> _$FeedReceiptOutToJson(FeedReceiptOut instance) =>
    <String, dynamic>{
      'dismissed': instance.dismissed,
      'item_id': instance.itemId,
      'remind': instance.remind,
      'seen': instance.seen,
    };

FeedResponse _$FeedResponseFromJson(Map<String, dynamic> json) => FeedResponse(
  footer: json['footer'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => FeedItemOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$FeedResponseToJson(FeedResponse instance) =>
    <String, dynamic>{
      'footer': instance.footer,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

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
