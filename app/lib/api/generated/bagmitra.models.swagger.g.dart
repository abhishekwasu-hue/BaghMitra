// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bagmitra.models.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptIn _$AcceptInFromJson(Map<String, dynamic> json) => AcceptIn(
  adultDeclared: json['adult_declared'] as bool,
  disclaimerVersion: json['disclaimer_version'] as String,
  privacyVersion: json['privacy_version'] as String,
  role: acceptInRoleFromJson(json['role']),
  termsVersion: json['terms_version'] as String,
);

Map<String, dynamic> _$AcceptInToJson(AcceptIn instance) => <String, dynamic>{
  'adult_declared': instance.adultDeclared,
  'disclaimer_version': instance.disclaimerVersion,
  'privacy_version': instance.privacyVersion,
  'role': ?acceptInRoleToJson(instance.role),
  'terms_version': instance.termsVersion,
};

AcceptanceOut _$AcceptanceOutFromJson(Map<String, dynamic> json) =>
    AcceptanceOut(
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
      docKind: json['doc_kind'] as String,
      role: json['role'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$AcceptanceOutToJson(AcceptanceOut instance) =>
    <String, dynamic>{
      'accepted_at': instance.acceptedAt.toIso8601String(),
      'doc_kind': instance.docKind,
      'role': instance.role,
      'version': instance.version,
    };

AccountActionOut _$AccountActionOutFromJson(Map<String, dynamic> json) =>
    AccountActionOut(
      actedAt: DateTime.parse(json['acted_at'] as String),
      action: json['action'] as String,
      appealDecidedAt: json['appeal_decided_at'] == null
          ? null
          : DateTime.parse(json['appeal_decided_at'] as String),
      appealPhotoCount: (json['appeal_photo_count'] as num).toInt(),
      appealReason: json['appeal_reason'] as String?,
      appealState: json['appeal_state'] as String,
      appealedAt: json['appealed_at'] == null
          ? null
          : DateTime.parse(json['appealed_at'] as String),
      canAppeal: json['can_appeal'] as bool,
      id: json['id'] as String,
      reasonCode: json['reason_code'] as String,
      subjectId: json['subject_id'] as String,
      subjectType: json['subject_type'] as String,
    );

Map<String, dynamic> _$AccountActionOutToJson(AccountActionOut instance) =>
    <String, dynamic>{
      'acted_at': instance.actedAt.toIso8601String(),
      'action': instance.action,
      'appeal_decided_at': ?instance.appealDecidedAt?.toIso8601String(),
      'appeal_photo_count': instance.appealPhotoCount,
      'appeal_reason': ?instance.appealReason,
      'appeal_state': instance.appealState,
      'appealed_at': ?instance.appealedAt?.toIso8601String(),
      'can_appeal': instance.canAppeal,
      'id': instance.id,
      'reason_code': instance.reasonCode,
      'subject_id': instance.subjectId,
      'subject_type': instance.subjectType,
    };

AccountActionsResponse _$AccountActionsResponseFromJson(
  Map<String, dynamic> json,
) => AccountActionsResponse(
  actions:
      (json['actions'] as List<dynamic>?)
          ?.map((e) => AccountActionOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$AccountActionsResponseToJson(
  AccountActionsResponse instance,
) => <String, dynamic>{
  'actions': instance.actions.map((e) => e.toJson()).toList(),
};

AccountDeleted _$AccountDeletedFromJson(Map<String, dynamic> json) =>
    AccountDeleted(
      photosDeleted: (json['photos_deleted'] as num).toInt(),
      rowsDeleted: (json['rows_deleted'] as num).toInt(),
      signInAccountRemoved: json['sign_in_account_removed'] as bool,
    );

Map<String, dynamic> _$AccountDeletedToJson(AccountDeleted instance) =>
    <String, dynamic>{
      'photos_deleted': instance.photosDeleted,
      'rows_deleted': instance.rowsDeleted,
      'sign_in_account_removed': instance.signInAccountRemoved,
    };

ActionIn _$ActionInFromJson(Map<String, dynamic> json) => ActionIn(
  action: actionInActionFromJson(json['action']),
  reasonCode: actionInReasonCodeFromJson(json['reason_code']),
  subjectId: json['subject_id'] as String,
  subjectType: actionInSubjectTypeFromJson(json['subject_type']),
);

Map<String, dynamic> _$ActionInToJson(ActionIn instance) => <String, dynamic>{
  'action': ?actionInActionToJson(instance.action),
  'reason_code': ?actionInReasonCodeToJson(instance.reasonCode),
  'subject_id': instance.subjectId,
  'subject_type': ?actionInSubjectTypeToJson(instance.subjectType),
};

ActionOut _$ActionOutFromJson(Map<String, dynamic> json) => ActionOut(
  ackOverdue: json['ack_overdue'] as bool,
  actedAt: DateTime.parse(json['acted_at'] as String),
  action: json['action'] as String,
  actorId: json['actor_id'] as String,
  appealAcknowledgedAt: json['appeal_acknowledged_at'] == null
      ? null
      : DateTime.parse(json['appeal_acknowledged_at'] as String),
  appealDecidedAt: json['appeal_decided_at'] == null
      ? null
      : DateTime.parse(json['appeal_decided_at'] as String),
  appealDecidedBy: json['appeal_decided_by'] as String?,
  appealPhotoCount: (json['appeal_photo_count'] as num).toInt(),
  appealReason: json['appeal_reason'] as String?,
  appealState: json['appeal_state'] as String,
  appealedAt: json['appealed_at'] == null
      ? null
      : DateTime.parse(json['appealed_at'] as String),
  closeOverdue: json['close_overdue'] as bool,
  id: json['id'] as String,
  reasonCode: json['reason_code'] as String,
  subjectId: json['subject_id'] as String,
  subjectType: json['subject_type'] as String,
  userId: json['user_id'] as String?,
);

Map<String, dynamic> _$ActionOutToJson(ActionOut instance) => <String, dynamic>{
  'ack_overdue': instance.ackOverdue,
  'acted_at': instance.actedAt.toIso8601String(),
  'action': instance.action,
  'actor_id': instance.actorId,
  'appeal_acknowledged_at': ?instance.appealAcknowledgedAt?.toIso8601String(),
  'appeal_decided_at': ?instance.appealDecidedAt?.toIso8601String(),
  'appeal_decided_by': ?instance.appealDecidedBy,
  'appeal_photo_count': instance.appealPhotoCount,
  'appeal_reason': ?instance.appealReason,
  'appeal_state': instance.appealState,
  'appealed_at': ?instance.appealedAt?.toIso8601String(),
  'close_overdue': instance.closeOverdue,
  'id': instance.id,
  'reason_code': instance.reasonCode,
  'subject_id': instance.subjectId,
  'subject_type': instance.subjectType,
  'user_id': ?instance.userId,
};

ActionsResponse _$ActionsResponseFromJson(Map<String, dynamic> json) =>
    ActionsResponse(
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((e) => ActionOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ActionsResponseToJson(ActionsResponse instance) =>
    <String, dynamic>{
      'actions': instance.actions.map((e) => e.toJson()).toList(),
    };

AddressIn _$AddressInFromJson(Map<String, dynamic> json) =>
    AddressIn(address: json['address'] as String?);

Map<String, dynamic> _$AddressInToJson(AddressIn instance) => <String, dynamic>{
  'address': ?instance.address,
};

AdminFixOut _$AdminFixOutFromJson(Map<String, dynamic> json) => AdminFixOut(
  accuracyM: (json['accuracy_m'] as num).toDouble(),
  capturedAt: DateTime.parse(json['captured_at'] as String),
  district: json['district'] as String?,
  isMocked: json['is_mocked'] as bool,
  lat: (json['lat'] as num).toDouble(),
  lon: (json['lon'] as num).toDouble(),
  pin: json['pin'] as String?,
  place: json['place'] as String?,
  state: json['state'] as String?,
);

Map<String, dynamic> _$AdminFixOutToJson(AdminFixOut instance) =>
    <String, dynamic>{
      'accuracy_m': instance.accuracyM,
      'captured_at': instance.capturedAt.toIso8601String(),
      'district': ?instance.district,
      'is_mocked': instance.isMocked,
      'lat': instance.lat,
      'lon': instance.lon,
      'pin': ?instance.pin,
      'place': ?instance.place,
      'state': ?instance.state,
    };

AdminProviderIn _$AdminProviderInFromJson(Map<String, dynamic> json) =>
    AdminProviderIn(
      address: json['address'] as String?,
      capacityT: (json['capacity_t'] as num?)?.toDouble(),
      carrierRegNo: json['carrier_reg_no'] as String?,
      certValidUntil: json['cert_valid_until'] == null
          ? null
          : DateTime.parse(json['cert_valid_until'] as String),
      district: json['district'] as String,
      fix: json['fix'] == null
          ? null
          : RegistrationFixIn.fromJson(json['fix'] as Map<String, dynamic>),
      kind: adminProviderInKindFromJson(json['kind']),
      name: json['name'] as String,
      phone: json['phone'] as String,
      refrigerated: json['refrigerated'] as bool?,
      serviceAreas:
          (json['service_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      taluka: json['taluka'] as String?,
      vehicleNumbers:
          (json['vehicle_numbers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      village: json['village'] as String,
    );

Map<String, dynamic> _$AdminProviderInToJson(AdminProviderIn instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'capacity_t': ?instance.capacityT,
      'carrier_reg_no': ?instance.carrierRegNo,
      'cert_valid_until': ?_dateToJson(instance.certValidUntil),
      'district': instance.district,
      'fix': ?instance.fix?.toJson(),
      'kind': ?adminProviderInKindToJson(instance.kind),
      'name': instance.name,
      'phone': instance.phone,
      'refrigerated': ?instance.refrigerated,
      'service_areas': ?instance.serviceAreas,
      'taluka': ?instance.taluka,
      'vehicle_numbers': ?instance.vehicleNumbers,
      'village': instance.village,
    };

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

AnswerIn _$AnswerInFromJson(Map<String, dynamic> json) => AnswerIn(
  questionKey: json['question_key'] as String,
  stars: (json['stars'] as num).toInt(),
  tagIds:
      (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$AnswerInToJson(AnswerIn instance) => <String, dynamic>{
  'question_key': instance.questionKey,
  'stars': instance.stars,
  'tag_ids': ?instance.tagIds,
};

AnswerOut _$AnswerOutFromJson(Map<String, dynamic> json) => AnswerOut(
  questionKey: json['question_key'] as String,
  stars: (json['stars'] as num).toInt(),
  tagIds:
      (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$AnswerOutToJson(AnswerOut instance) => <String, dynamic>{
  'question_key': instance.questionKey,
  'stars': instance.stars,
  'tag_ids': instance.tagIds,
};

AppVersionResponse _$AppVersionResponseFromJson(Map<String, dynamic> json) =>
    AppVersionResponse(
      downloadUrl: json['download_url'] as String,
      latestVersionCode: (json['latest_version_code'] as num).toInt(),
      latestVersionName: json['latest_version_name'] as String,
      minVersionCode: (json['min_version_code'] as num).toInt(),
    );

Map<String, dynamic> _$AppVersionResponseToJson(AppVersionResponse instance) =>
    <String, dynamic>{
      'download_url': instance.downloadUrl,
      'latest_version_code': instance.latestVersionCode,
      'latest_version_name': instance.latestVersionName,
      'min_version_code': instance.minVersionCode,
    };

AppealDecisionIn _$AppealDecisionInFromJson(Map<String, dynamic> json) =>
    AppealDecisionIn(outcome: appealDecisionInOutcomeFromJson(json['outcome']));

Map<String, dynamic> _$AppealDecisionInToJson(AppealDecisionIn instance) =>
    <String, dynamic>{
      'outcome': ?appealDecisionInOutcomeToJson(instance.outcome),
    };

AppealIn _$AppealInFromJson(Map<String, dynamic> json) =>
    AppealIn(reason: appealInReasonFromJson(json['reason']));

Map<String, dynamic> _$AppealInToJson(AppealIn instance) => <String, dynamic>{
  'reason': ?appealInReasonToJson(instance.reason),
};

ArticleChartOut _$ArticleChartOutFromJson(Map<String, dynamic> json) =>
    ArticleChartOut(
      data:
          (json['data'] as List<dynamic>?)
              ?.map(
                (e) => ArticleChartPointOut.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      title: json['title'] as String,
      type: json['type'] as String,
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$ArticleChartOutToJson(ArticleChartOut instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
      'title': instance.title,
      'type': instance.type,
      'unit': instance.unit,
    };

ArticleChartPointOut _$ArticleChartPointOutFromJson(
  Map<String, dynamic> json,
) => ArticleChartPointOut(
  label: json['label'] as String,
  value: (json['value'] as num).toDouble(),
);

Map<String, dynamic> _$ArticleChartPointOutToJson(
  ArticleChartPointOut instance,
) => <String, dynamic>{'label': instance.label, 'value': instance.value};

ArticleDateOut _$ArticleDateOutFromJson(Map<String, dynamic> json) =>
    ArticleDateOut(
      date: DateTime.parse(json['date'] as String),
      label: json['label'] as String,
    );

Map<String, dynamic> _$ArticleDateOutToJson(ArticleDateOut instance) =>
    <String, dynamic>{
      'date': ?_dateToJson(instance.date),
      'label': instance.label,
    };

ArticleFactOut _$ArticleFactOutFromJson(Map<String, dynamic> json) =>
    ArticleFactOut(
      label: json['label'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$ArticleFactOutToJson(ArticleFactOut instance) =>
    <String, dynamic>{'label': instance.label, 'value': instance.value};

ArticleOut _$ArticleOutFromJson(Map<String, dynamic> json) => ArticleOut(
  charts:
      (json['charts'] as List<dynamic>?)
          ?.map((e) => ArticleChartOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  facts:
      (json['facts'] as List<dynamic>?)
          ?.map((e) => ArticleFactOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  headline: json['headline'] as String,
  keyDates:
      (json['key_dates'] as List<dynamic>?)
          ?.map((e) => ArticleDateOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  keyPoints:
      (json['key_points'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => ArticleSectionOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  sources:
      (json['sources'] as List<dynamic>?)
          ?.map((e) => ArticleSourceOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  standfirst: json['standfirst'] as String,
);

Map<String, dynamic> _$ArticleOutToJson(ArticleOut instance) =>
    <String, dynamic>{
      'charts': instance.charts.map((e) => e.toJson()).toList(),
      'facts': instance.facts.map((e) => e.toJson()).toList(),
      'headline': instance.headline,
      'key_dates': instance.keyDates.map((e) => e.toJson()).toList(),
      'key_points': instance.keyPoints,
      'sections': instance.sections.map((e) => e.toJson()).toList(),
      'sources': instance.sources.map((e) => e.toJson()).toList(),
      'standfirst': instance.standfirst,
    };

ArticleSectionOut _$ArticleSectionOutFromJson(Map<String, dynamic> json) =>
    ArticleSectionOut(
      body: json['body'] as String,
      heading: json['heading'] as String,
    );

Map<String, dynamic> _$ArticleSectionOutToJson(ArticleSectionOut instance) =>
    <String, dynamic>{'body': instance.body, 'heading': instance.heading};

ArticleSourceOut _$ArticleSourceOutFromJson(Map<String, dynamic> json) =>
    ArticleSourceOut(
      title: json['title'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$ArticleSourceOutToJson(ArticleSourceOut instance) =>
    <String, dynamic>{'title': instance.title, 'url': instance.url};

BadgeOut _$BadgeOutFromJson(Map<String, dynamic> json) => BadgeOut(
  kind: badgeOutKindFromJson(json['kind']),
  on: DateTime.parse(json['on'] as String),
  place: json['place'] as String?,
  sinceYear: (json['since_year'] as num?)?.toInt(),
);

Map<String, dynamic> _$BadgeOutToJson(BadgeOut instance) => <String, dynamic>{
  'kind': ?badgeOutKindToJson(instance.kind),
  'on': ?_dateToJson(instance.on),
  'place': ?instance.place,
  'since_year': ?instance.sinceYear,
};

BillingSettingsOut _$BillingSettingsOutFromJson(Map<String, dynamic> json) =>
    BillingSettingsOut(
      enabled: json['enabled'] as bool,
      photoLimits: PhotoLimitsOut.fromJson(
        json['photo_limits'] as Map<String, dynamic>,
      ),
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => RolePriceOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startsOn: json['starts_on'] == null
          ? null
          : DateTime.parse(json['starts_on'] as String),
    );

Map<String, dynamic> _$BillingSettingsOutToJson(BillingSettingsOut instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'photo_limits': instance.photoLimits.toJson(),
      'roles': instance.roles.map((e) => e.toJson()).toList(),
      'starts_on': ?_dateToJson(instance.startsOn),
    };

BlockedClaimOut _$BlockedClaimOutFromJson(Map<String, dynamic> json) =>
    BlockedClaimOut(
      activeIngredient: json['active_ingredient'] as String,
      formulation: json['formulation'] as String,
      labelCrop: json['label_crop'] as String,
      notification: json['notification'] as String,
      reason: blockedClaimOutReasonFromJson(json['reason']),
      target: json['target'] as String,
    );

Map<String, dynamic> _$BlockedClaimOutToJson(BlockedClaimOut instance) =>
    <String, dynamic>{
      'active_ingredient': instance.activeIngredient,
      'formulation': instance.formulation,
      'label_crop': instance.labelCrop,
      'notification': instance.notification,
      'reason': ?blockedClaimOutReasonToJson(instance.reason),
      'target': instance.target,
    };

BlocksResponse _$BlocksResponseFromJson(Map<String, dynamic> json) =>
    BlocksResponse(
      blockedUserIds:
          (json['blocked_user_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$BlocksResponseToJson(BlocksResponse instance) =>
    <String, dynamic>{'blocked_user_ids': instance.blockedUserIds};

BodyPhotoAnalysisCreate _$BodyPhotoAnalysisCreateFromJson(
  Map<String, dynamic> json,
) => BodyPhotoAnalysisCreate(
  $part: json['part'] as String?,
  photo: json['photo'] as String,
  scoutingItem: json['scouting_item'] as String?,
);

Map<String, dynamic> _$BodyPhotoAnalysisCreateToJson(
  BodyPhotoAnalysisCreate instance,
) => <String, dynamic>{
  'part': ?instance.$part,
  'photo': instance.photo,
  'scouting_item': ?instance.scoutingItem,
};

BrokerIn _$BrokerInFromJson(Map<String, dynamic> json) => BrokerIn(
  address: json['address'] as String?,
  crops:
      (json['crops'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  district: json['district'] as String,
  fix: RegistrationFixIn.fromJson(json['fix'] as Map<String, dynamic>),
  name: json['name'] as String,
  phone: json['phone'] as String,
  serviceAreas:
      (json['service_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  taluka: json['taluka'] as String?,
  village: json['village'] as String,
);

Map<String, dynamic> _$BrokerInToJson(BrokerIn instance) => <String, dynamic>{
  'address': ?instance.address,
  'crops': ?instance.crops,
  'district': instance.district,
  'fix': instance.fix.toJson(),
  'name': instance.name,
  'phone': instance.phone,
  'service_areas': ?instance.serviceAreas,
  'taluka': ?instance.taluka,
  'village': instance.village,
};

BuyerIn _$BuyerInFromJson(Map<String, dynamic> json) => BuyerIn(
  address: json['address'] as String?,
  apedaNo: json['apeda_no'] as String?,
  apmcLicenceNo: json['apmc_licence_no'] as String?,
  crops:
      (json['crops'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  district: json['district'] as String,
  firm: json['firm'] as String?,
  fix: RegistrationFixIn.fromJson(json['fix'] as Map<String, dynamic>),
  fssaiNo: json['fssai_no'] as String?,
  gstNo: json['gst_no'] as String?,
  iecNo: json['iec_no'] as String?,
  markets:
      (json['markets'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  name: json['name'] as String,
  phone: json['phone'] as String,
  taluka: json['taluka'] as String?,
);

Map<String, dynamic> _$BuyerInToJson(BuyerIn instance) => <String, dynamic>{
  'address': ?instance.address,
  'apeda_no': ?instance.apedaNo,
  'apmc_licence_no': ?instance.apmcLicenceNo,
  'crops': ?instance.crops,
  'district': instance.district,
  'firm': ?instance.firm,
  'fix': instance.fix.toJson(),
  'fssai_no': ?instance.fssaiNo,
  'gst_no': ?instance.gstNo,
  'iec_no': ?instance.iecNo,
  'markets': ?instance.markets,
  'name': instance.name,
  'phone': instance.phone,
  'taluka': ?instance.taluka,
};

BuyerLotOut _$BuyerLotOutFromJson(Map<String, dynamic> json) => BuyerLotOut(
  acres: (json['acres'] as num?)?.toDouble(),
  crop: json['crop'] as String,
  district: json['district'] as String?,
  firstName: json['first_name'] as String?,
  harvestFrom: DateTime.parse(json['harvest_from'] as String),
  harvestTo: DateTime.parse(json['harvest_to'] as String),
  id: json['id'] as String,
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => LotPhotoView.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  publishedAt: DateTime.parse(json['published_at'] as String),
  quality: json['quality'] as String?,
  quantityT: (json['quantity_t'] as num).toDouble(),
  variety: json['variety'] as String?,
);

Map<String, dynamic> _$BuyerLotOutToJson(BuyerLotOut instance) =>
    <String, dynamic>{
      'acres': ?instance.acres,
      'crop': instance.crop,
      'district': ?instance.district,
      'first_name': ?instance.firstName,
      'harvest_from': ?_dateToJson(instance.harvestFrom),
      'harvest_to': ?_dateToJson(instance.harvestTo),
      'id': instance.id,
      'photos': instance.photos.map((e) => e.toJson()).toList(),
      'published_at': instance.publishedAt.toIso8601String(),
      'quality': ?instance.quality,
      'quantity_t': instance.quantityT,
      'variety': ?instance.variety,
    };

BuyerLotsResponse _$BuyerLotsResponseFromJson(Map<String, dynamic> json) =>
    BuyerLotsResponse(
      lots:
          (json['lots'] as List<dynamic>?)
              ?.map((e) => BuyerLotOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$BuyerLotsResponseToJson(BuyerLotsResponse instance) =>
    <String, dynamic>{'lots': instance.lots.map((e) => e.toJson()).toList()};

CandidateOut _$CandidateOutFromJson(Map<String, dynamic> json) => CandidateOut(
  confidence: (json['confidence'] as num).toDouble(),
  explanation: LocalizedText.fromJson(
    json['explanation'] as Map<String, dynamic>,
  ),
  key: json['key'] as String,
  name: LocalizedText.fromJson(json['name'] as Map<String, dynamic>),
  signs: LocalizedSigns.fromJson(json['signs'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CandidateOutToJson(CandidateOut instance) =>
    <String, dynamic>{
      'confidence': instance.confidence,
      'explanation': instance.explanation.toJson(),
      'key': instance.key,
      'name': instance.name.toJson(),
      'signs': instance.signs.toJson(),
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

CardSourceOut _$CardSourceOutFromJson(Map<String, dynamic> json) =>
    CardSourceOut(
      checked: json['checked'] == null
          ? null
          : DateTime.parse(json['checked'] as String),
      publisher: json['publisher'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$CardSourceOutToJson(CardSourceOut instance) =>
    <String, dynamic>{
      'checked': ?_dateToJson(instance.checked),
      'publisher': instance.publisher,
      'title': instance.title,
      'url': instance.url,
    };

CardText _$CardTextFromJson(Map<String, dynamic> json) => CardText(
  cultural: json['cultural'] as String?,
  summary: json['summary'] as String?,
  title: json['title'] as String?,
  warnings: json['warnings'] as String?,
  whenToCallExpert: json['when_to_call_expert'] as String?,
);

Map<String, dynamic> _$CardTextToJson(CardText instance) => <String, dynamic>{
  'cultural': ?instance.cultural,
  'summary': ?instance.summary,
  'title': ?instance.title,
  'warnings': ?instance.warnings,
  'when_to_call_expert': ?instance.whenToCallExpert,
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

CheckIn _$CheckInFromJson(Map<String, dynamic> json) => CheckIn(
  kind: checkInKindFromJson(json['kind']),
  registeredYear: (json['registered_year'] as num?)?.toInt(),
  result: checkInResultFromJson(json['result']),
);

Map<String, dynamic> _$CheckInToJson(CheckIn instance) => <String, dynamic>{
  'kind': ?checkInKindToJson(instance.kind),
  'registered_year': ?instance.registeredYear,
  'result': ?checkInResultToJson(instance.result),
};

CheckOut _$CheckOutFromJson(Map<String, dynamic> json) => CheckOut(
  checkedAt: DateTime.parse(json['checked_at'] as String),
  checkedBy: json['checked_by'] as String,
  id: json['id'] as String,
  kind: json['kind'] as String,
  number: json['number'] as String?,
  officialUrl: json['official_url'] as String?,
  recheckListedAt: json['recheck_listed_at'] == null
      ? null
      : DateTime.parse(json['recheck_listed_at'] as String),
  registeredYear: (json['registered_year'] as num?)?.toInt(),
  result: json['result'] as String,
);

Map<String, dynamic> _$CheckOutToJson(CheckOut instance) => <String, dynamic>{
  'checked_at': instance.checkedAt.toIso8601String(),
  'checked_by': instance.checkedBy,
  'id': instance.id,
  'kind': instance.kind,
  'number': ?instance.number,
  'official_url': ?instance.officialUrl,
  'recheck_listed_at': ?instance.recheckListedAt?.toIso8601String(),
  'registered_year': ?instance.registeredYear,
  'result': instance.result,
};

DealRatingsOut _$DealRatingsOutFromJson(Map<String, dynamic> json) =>
    DealRatingsOut(
      given:
          (json['given'] as List<dynamic>?)
              ?.map((e) => GivenRatingOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      questions: json['questions'] as Map<String, dynamic>,
      state: DealStateOut.fromJson(json['state'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DealRatingsOutToJson(DealRatingsOut instance) =>
    <String, dynamic>{
      'given': instance.given.map((e) => e.toJson()).toList(),
      'questions': instance.questions,
      'state': instance.state.toJson(),
    };

DealStateOut _$DealStateOutFromJson(Map<String, dynamic> json) => DealStateOut(
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  growerDoneAt: json['grower_done_at'] == null
      ? null
      : DateTime.parse(json['grower_done_at'] as String),
  myRole: dealStateOutMyRoleFromJson(json['my_role']),
  rates: dealStateOutRatesListFromJson(json['rates'] as List?),
  ratingLocked: json['rating_locked'] as bool,
  ratingUntil: json['rating_until'] == null
      ? null
      : DateTime.parse(json['rating_until'] as String),
  traderDoneAt: json['trader_done_at'] == null
      ? null
      : DateTime.parse(json['trader_done_at'] as String),
);

Map<String, dynamic> _$DealStateOutToJson(DealStateOut instance) =>
    <String, dynamic>{
      'completed_at': ?instance.completedAt?.toIso8601String(),
      'grower_done_at': ?instance.growerDoneAt?.toIso8601String(),
      'my_role': ?dealStateOutMyRoleToJson(instance.myRole),
      'rates': dealStateOutRatesListToJson(instance.rates),
      'rating_locked': instance.ratingLocked,
      'rating_until': ?instance.ratingUntil?.toIso8601String(),
      'trader_done_at': ?instance.traderDoneAt?.toIso8601String(),
    };

DecisionIn _$DecisionInFromJson(Map<String, dynamic> json) => DecisionIn(
  reason: json['reason'] as String?,
  status: decisionInStatusFromJson(json['status']),
);

Map<String, dynamic> _$DecisionInToJson(DecisionIn instance) =>
    <String, dynamic>{
      'reason': ?instance.reason,
      'status': ?decisionInStatusToJson(instance.status),
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
  details: json['details'],
  message: json['message'] as String,
  requestId: json['request_id'] as String,
);

Map<String, dynamic> _$ErrorBodyToJson(ErrorBody instance) => <String, dynamic>{
  'code': instance.code,
  'details': ?instance.details,
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
  dateIsFirstSeen: json['date_is_first_seen'] as bool? ?? false,
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
      'date_is_first_seen': ?instance.dateIsFirstSeen,
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
  dateIsFirstSeen: json['date_is_first_seen'] as bool? ?? false,
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
  'date_is_first_seen': ?instance.dateIsFirstSeen,
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
  article: json['article'] == null
      ? null
      : ArticleOut.fromJson(json['article'] as Map<String, dynamic>),
  dateIsFirstSeen: json['date_is_first_seen'] as bool? ?? false,
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  department: json['department'] as String?,
  grNumber: json['gr_number'] as String?,
  id: json['id'] as String,
  level: json['level'] as String?,
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
      'article': ?instance.article?.toJson(),
      'date_is_first_seen': ?instance.dateIsFirstSeen,
      'deadline': ?_dateToJson(instance.deadline),
      'department': ?instance.department,
      'gr_number': ?instance.grNumber,
      'id': instance.id,
      'level': ?instance.level,
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

FeedbackIn _$FeedbackInFromJson(Map<String, dynamic> json) => FeedbackIn(
  appVersion: json['app_version'] as String,
  clientId: json['client_id'] as String,
  device: json['device'] as String,
  kind: feedbackInKindFromJson(json['kind']),
  text: json['text'] as String,
);

Map<String, dynamic> _$FeedbackInToJson(FeedbackIn instance) =>
    <String, dynamic>{
      'app_version': instance.appVersion,
      'client_id': instance.clientId,
      'device': instance.device,
      'kind': ?feedbackInKindToJson(instance.kind),
      'text': instance.text,
    };

FeedbackList _$FeedbackListFromJson(Map<String, dynamic> json) => FeedbackList(
  feedback:
      (json['feedback'] as List<dynamic>?)
          ?.map((e) => FeedbackOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$FeedbackListToJson(FeedbackList instance) =>
    <String, dynamic>{
      'feedback': instance.feedback.map((e) => e.toJson()).toList(),
    };

FeedbackOut _$FeedbackOutFromJson(Map<String, dynamic> json) => FeedbackOut(
  appVersion: json['app_version'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  device: json['device'] as String,
  id: json['id'] as String,
  kind: json['kind'] as String,
  screenshotUrl: json['screenshot_url'] as String?,
  status: json['status'] as String,
  text: json['text'] as String,
);

Map<String, dynamic> _$FeedbackOutToJson(FeedbackOut instance) =>
    <String, dynamic>{
      'app_version': instance.appVersion,
      'created_at': instance.createdAt.toIso8601String(),
      'device': instance.device,
      'id': instance.id,
      'kind': instance.kind,
      'screenshot_url': ?instance.screenshotUrl,
      'status': instance.status,
      'text': instance.text,
    };

GivenRatingOut _$GivenRatingOutFromJson(Map<String, dynamic> json) =>
    GivenRatingOut(
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rateeRole: givenRatingOutRateeRoleFromJson(json['ratee_role']),
    );

Map<String, dynamic> _$GivenRatingOutToJson(GivenRatingOut instance) =>
    <String, dynamic>{
      'answers': instance.answers.map((e) => e.toJson()).toList(),
      'ratee_role': ?givenRatingOutRateeRoleToJson(instance.rateeRole),
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

GrievanceOfficerOut _$GrievanceOfficerOutFromJson(Map<String, dynamic> json) =>
    GrievanceOfficerOut(
      contact: json['contact'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$GrievanceOfficerOutToJson(
  GrievanceOfficerOut instance,
) => <String, dynamic>{'contact': ?instance.contact, 'name': ?instance.name};

GrowerCardOut _$GrowerCardOutFromJson(Map<String, dynamic> json) =>
    GrowerCardOut(
      crop: json['crop'] as String,
      reviewed: json['reviewed'] as bool,
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => CardSourceOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      text: json['text'] as Map<String, dynamic>,
      topic: json['topic'] as String,
      topicKind: json['topic_kind'] as String,
      topicLabels: json['topic_labels'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$GrowerCardOutToJson(GrowerCardOut instance) =>
    <String, dynamic>{
      'crop': instance.crop,
      'reviewed': instance.reviewed,
      'sources': instance.sources.map((e) => e.toJson()).toList(),
      'text': instance.text,
      'topic': instance.topic,
      'topic_kind': instance.topicKind,
      'topic_labels': instance.topicLabels,
    };

GrowerCardsResponse _$GrowerCardsResponseFromJson(Map<String, dynamic> json) =>
    GrowerCardsResponse(
      cards:
          (json['cards'] as List<dynamic>?)
              ?.map((e) => GrowerCardOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      kind: json['kind'] as String?,
    );

Map<String, dynamic> _$GrowerCardsResponseToJson(
  GrowerCardsResponse instance,
) => <String, dynamic>{
  'cards': instance.cards.map((e) => e.toJson()).toList(),
  'kind': ?instance.kind,
};

GrowerContactOut _$GrowerContactOutFromJson(Map<String, dynamic> json) =>
    GrowerContactOut(
      district: json['district'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      pin: json['pin'] == null
          ? null
          : PinOut.fromJson(json['pin'] as Map<String, dynamic>),
      plotName: json['plot_name'] as String?,
      taluka: json['taluka'] as String?,
      village: json['village'] as String?,
    );

Map<String, dynamic> _$GrowerContactOutToJson(GrowerContactOut instance) =>
    <String, dynamic>{
      'district': ?instance.district,
      'name': ?instance.name,
      'phone': ?instance.phone,
      'pin': ?instance.pin?.toJson(),
      'plot_name': ?instance.plotName,
      'taluka': ?instance.taluka,
      'village': ?instance.village,
    };

GrowerInterestOut _$GrowerInterestOutFromJson(Map<String, dynamic> json) =>
    GrowerInterestOut(
      basis: json['basis'] as String,
      broker: json['broker'] == null
          ? null
          : PublicProfileOut.fromJson(json['broker'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      dealId: json['deal_id'] as String?,
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      id: json['id'] as String,
      lotId: json['lot_id'] as String,
      quantityT: (json['quantity_t'] as num?)?.toDouble(),
      ratePaise: (json['rate_paise'] as num).toInt(),
      status: json['status'] as String,
      trader: PublicProfileOut.fromJson(json['trader'] as Map<String, dynamic>),
      viaBroker: json['via_broker'] as bool,
    );

Map<String, dynamic> _$GrowerInterestOutToJson(GrowerInterestOut instance) =>
    <String, dynamic>{
      'basis': instance.basis,
      'broker': ?instance.broker?.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
      'deal_id': ?instance.dealId,
      'harvest_date': ?_dateToJson(instance.harvestDate),
      'id': instance.id,
      'lot_id': instance.lotId,
      'quantity_t': ?instance.quantityT,
      'rate_paise': instance.ratePaise,
      'status': instance.status,
      'trader': instance.trader.toJson(),
      'via_broker': instance.viaBroker,
    };

GrowerLotOut _$GrowerLotOutFromJson(Map<String, dynamic> json) => GrowerLotOut(
  crop: json['crop'] as String,
  district: json['district'] as String?,
  id: json['id'] as String,
  orchardCheck: json['orchard_check'] as String?,
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
  status: json['status'] as String,
  taluka: json['taluka'] as String?,
  variety: json['variety'] as String?,
  village: json['village'] as String?,
);

Map<String, dynamic> _$GrowerLotOutToJson(GrowerLotOut instance) =>
    <String, dynamic>{
      'crop': instance.crop,
      'district': ?instance.district,
      'id': instance.id,
      'orchard_check': ?instance.orchardCheck,
      'published_at': ?instance.publishedAt?.toIso8601String(),
      'status': instance.status,
      'taluka': ?instance.taluka,
      'variety': ?instance.variety,
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

InsuranceDeadlineOut _$InsuranceDeadlineOutFromJson(
  Map<String, dynamic> json,
) => InsuranceDeadlineOut(
  dueDate: DateTime.parse(json['due_date'] as String),
  itemId: json['item_id'] as String,
  season: json['season'] as String?,
  title: json['title'] as String,
  url: json['url'] as String,
);

Map<String, dynamic> _$InsuranceDeadlineOutToJson(
  InsuranceDeadlineOut instance,
) => <String, dynamic>{
  'due_date': ?_dateToJson(instance.dueDate),
  'item_id': instance.itemId,
  'season': ?instance.season,
  'title': instance.title,
  'url': instance.url,
};

InsuranceDeadlinesResponse _$InsuranceDeadlinesResponseFromJson(
  Map<String, dynamic> json,
) => InsuranceDeadlinesResponse(
  footer: json['footer'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => InsuranceDeadlineOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$InsuranceDeadlinesResponseToJson(
  InsuranceDeadlinesResponse instance,
) => <String, dynamic>{
  'footer': instance.footer,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

InterestIn _$InterestInFromJson(Map<String, dynamic> json) => InterestIn(
  basis: interestInBasisFromJson(json['basis']),
  brokerId: json['broker_id'] as String?,
  harvestDate: DateTime.parse(json['harvest_date'] as String),
  quantityT: (json['quantity_t'] as num?)?.toDouble(),
  ratePaise: (json['rate_paise'] as num).toInt(),
  traderId: json['trader_id'] as String?,
);

Map<String, dynamic> _$InterestInToJson(InterestIn instance) =>
    <String, dynamic>{
      'basis': ?interestInBasisToJson(instance.basis),
      'broker_id': ?instance.brokerId,
      'harvest_date': ?_dateToJson(instance.harvestDate),
      'quantity_t': ?instance.quantityT,
      'rate_paise': instance.ratePaise,
      'trader_id': ?instance.traderId,
    };

InterestOut _$InterestOutFromJson(Map<String, dynamic> json) => InterestOut(
  basis: json['basis'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  dealId: json['deal_id'] as String?,
  harvestDate: DateTime.parse(json['harvest_date'] as String),
  id: json['id'] as String,
  lotId: json['lot_id'] as String,
  quantityT: (json['quantity_t'] as num?)?.toDouble(),
  ratePaise: (json['rate_paise'] as num).toInt(),
  status: json['status'] as String,
  viaBroker: json['via_broker'] as bool,
);

Map<String, dynamic> _$InterestOutToJson(InterestOut instance) =>
    <String, dynamic>{
      'basis': instance.basis,
      'created_at': instance.createdAt.toIso8601String(),
      'deal_id': ?instance.dealId,
      'harvest_date': ?_dateToJson(instance.harvestDate),
      'id': instance.id,
      'lot_id': instance.lotId,
      'quantity_t': ?instance.quantityT,
      'rate_paise': instance.ratePaise,
      'status': instance.status,
      'via_broker': instance.viaBroker,
    };

IntroductionOut _$IntroductionOutFromJson(Map<String, dynamic> json) =>
    IntroductionOut(
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
      broker: json['broker'] == null
          ? null
          : PartyContactOut.fromJson(json['broker'] as Map<String, dynamic>),
      dealId: json['deal_id'] as String,
      grower: GrowerContactOut.fromJson(json['grower'] as Map<String, dynamic>),
      interest: InterestOut.fromJson(json['interest'] as Map<String, dynamic>),
      lot: LotBrief.fromJson(json['lot'] as Map<String, dynamic>),
      state: DealStateOut.fromJson(json['state'] as Map<String, dynamic>),
      trader: PartyContactOut.fromJson(json['trader'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$IntroductionOutToJson(IntroductionOut instance) =>
    <String, dynamic>{
      'accepted_at': instance.acceptedAt.toIso8601String(),
      'broker': ?instance.broker?.toJson(),
      'deal_id': instance.dealId,
      'grower': instance.grower.toJson(),
      'interest': instance.interest.toJson(),
      'lot': instance.lot.toJson(),
      'state': instance.state.toJson(),
      'trader': instance.trader.toJson(),
    };

LabelClaimOut _$LabelClaimOutFromJson(Map<String, dynamic> json) =>
    LabelClaimOut(
      activeIngredient: json['active_ingredient'] as String,
      brandNames:
          (json['brand_names'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: LabelClaimOut.labelClaimOutCategoryCategoryNullableFromJson(
        json['category'],
      ),
      description: json['description'] as String?,
      dilution: json['dilution'] as String?,
      dose: json['dose'] as String,
      formulation: json['formulation'] as String,
      intervalDays: (json['interval_days'] as num?)?.toInt(),
      labelCrop: json['label_crop'] as String,
      makerUrl: json['maker_url'] as String?,
      maxSprays: (json['max_sprays'] as num?)?.toInt(),
      pageRef: json['page_ref'] as String?,
      phiDays: (json['phi_days'] as num?)?.toInt(),
      photoUrl: json['photo_url'] as String?,
      sourceKey: json['source_key'] as String,
      sourceTitle: json['source_title'] as String,
      sourceUrl: json['source_url'] as String,
      target: json['target'] as String,
    );

Map<String, dynamic> _$LabelClaimOutToJson(LabelClaimOut instance) =>
    <String, dynamic>{
      'active_ingredient': instance.activeIngredient,
      'brand_names': ?instance.brandNames,
      'category': ?labelClaimOutCategoryNullableToJson(instance.category),
      'description': ?instance.description,
      'dilution': ?instance.dilution,
      'dose': instance.dose,
      'formulation': instance.formulation,
      'interval_days': ?instance.intervalDays,
      'label_crop': instance.labelCrop,
      'maker_url': ?instance.makerUrl,
      'max_sprays': ?instance.maxSprays,
      'page_ref': ?instance.pageRef,
      'phi_days': ?instance.phiDays,
      'photo_url': ?instance.photoUrl,
      'source_key': instance.sourceKey,
      'source_title': instance.sourceTitle,
      'source_url': instance.sourceUrl,
      'target': instance.target,
    };

LabelClaimsResponse _$LabelClaimsResponseFromJson(Map<String, dynamic> json) =>
    LabelClaimsResponse(
      blocked:
          (json['blocked'] as List<dynamic>?)
              ?.map((e) => BlockedClaimOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
  'blocked': ?instance.blocked?.map((e) => e.toJson()).toList(),
  'claims': instance.claims.map((e) => e.toJson()).toList(),
  'kind': ?instance.kind,
};

LabelIn _$LabelInFromJson(Map<String, dynamic> json) => LabelIn(
  label: json['label'] as String,
  source: LabelIn.labelInSourceSourceNullableFromJson(json['source']),
);

Map<String, dynamic> _$LabelInToJson(LabelIn instance) => <String, dynamic>{
  'label': instance.label,
  'source': ?labelInSourceNullableToJson(instance.source),
};

LiveResponse _$LiveResponseFromJson(Map<String, dynamic> json) => LiveResponse(
  product: json['product'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$LiveResponseToJson(LiveResponse instance) =>
    <String, dynamic>{'product': instance.product, 'status': instance.status};

LocalizedSigns _$LocalizedSignsFromJson(
  Map<String, dynamic> json,
) => LocalizedSigns(
  en: (json['en'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  hi: (json['hi'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  mr: (json['mr'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
);

Map<String, dynamic> _$LocalizedSignsToJson(LocalizedSigns instance) =>
    <String, dynamic>{'en': instance.en, 'hi': instance.hi, 'mr': instance.mr};

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) =>
    LocalizedText(
      en: json['en'] as String,
      hi: json['hi'] as String,
      mr: json['mr'] as String,
    );

Map<String, dynamic> _$LocalizedTextToJson(LocalizedText instance) =>
    <String, dynamic>{'en': instance.en, 'hi': instance.hi, 'mr': instance.mr};

LotBrief _$LotBriefFromJson(Map<String, dynamic> json) => LotBrief(
  basis: json['basis'] as String,
  crop: json['crop'] as String,
  district: json['district'] as String?,
  id: json['id'] as String,
  quantityT: (json['quantity_t'] as num).toDouble(),
  status: json['status'] as String,
  taluka: json['taluka'] as String?,
  variety: json['variety'] as String?,
  village: json['village'] as String?,
);

Map<String, dynamic> _$LotBriefToJson(LotBrief instance) => <String, dynamic>{
  'basis': instance.basis,
  'crop': instance.crop,
  'district': ?instance.district,
  'id': instance.id,
  'quantity_t': instance.quantityT,
  'status': instance.status,
  'taluka': ?instance.taluka,
  'variety': ?instance.variety,
  'village': ?instance.village,
};

LotInterestsResponse _$LotInterestsResponseFromJson(
  Map<String, dynamic> json,
) => LotInterestsResponse(
  interests:
      (json['interests'] as List<dynamic>?)
          ?.map((e) => GrowerInterestOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$LotInterestsResponseToJson(
  LotInterestsResponse instance,
) => <String, dynamic>{
  'interests': instance.interests.map((e) => e.toJson()).toList(),
};

LotPhotoStored _$LotPhotoStoredFromJson(Map<String, dynamic> json) =>
    LotPhotoStored(photoKey: json['photo_key'] as String);

Map<String, dynamic> _$LotPhotoStoredToJson(LotPhotoStored instance) =>
    <String, dynamic>{'photo_key': instance.photoKey};

LotPhotoUrl _$LotPhotoUrlFromJson(Map<String, dynamic> json) => LotPhotoUrl(
  expiresIn: (json['expires_in'] as num).toInt(),
  url: json['url'] as String,
);

Map<String, dynamic> _$LotPhotoUrlToJson(LotPhotoUrl instance) =>
    <String, dynamic>{'expires_in': instance.expiresIn, 'url': instance.url};

LotPhotoView _$LotPhotoViewFromJson(Map<String, dynamic> json) => LotPhotoView(
  capturedAt: DateTime.parse(json['captured_at'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$LotPhotoViewToJson(LotPhotoView instance) =>
    <String, dynamic>{
      'captured_at': instance.capturedAt.toIso8601String(),
      'id': instance.id,
    };

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

MarketPriceHistory _$MarketPriceHistoryFromJson(Map<String, dynamic> json) =>
    MarketPriceHistory(
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => PriceDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      grade: json['grade'] as String?,
      market: json['market'] as String,
      reason: json['reason'] as String?,
      stale: json['stale'] as bool,
      variety: json['variety'] as String?,
    );

Map<String, dynamic> _$MarketPriceHistoryToJson(MarketPriceHistory instance) =>
    <String, dynamic>{
      'days': instance.days.map((e) => e.toJson()).toList(),
      'grade': ?instance.grade,
      'market': instance.market,
      'reason': ?instance.reason,
      'stale': instance.stale,
      'variety': ?instance.variety,
    };

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

MigrateIn _$MigrateInFromJson(Map<String, dynamic> json) =>
    MigrateIn(confirm: json['confirm'] as bool);

Map<String, dynamic> _$MigrateInToJson(MigrateIn instance) => <String, dynamic>{
  'confirm': instance.confirm,
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

MyAcceptancesOut _$MyAcceptancesOutFromJson(Map<String, dynamic> json) =>
    MyAcceptancesOut(
      acceptances:
          (json['acceptances'] as List<dynamic>?)
              ?.map((e) => AcceptanceOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
    );

Map<String, dynamic> _$MyAcceptancesOutToJson(MyAcceptancesOut instance) =>
    <String, dynamic>{
      'acceptances': instance.acceptances.map((e) => e.toJson()).toList(),
      'roles': instance.roles,
    };

MyProfileOut _$MyProfileOutFromJson(Map<String, dynamic> json) => MyProfileOut(
  address: json['address'] as String?,
  areas:
      (json['areas'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => BadgeOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  crops:
      (json['crops'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  district: json['district'] as String,
  documents: (json['documents'] as num).toInt(),
  firm: json['firm'] as String?,
  fix: json['fix'] == null
      ? null
      : AdminFixOut.fromJson(json['fix'] as Map<String, dynamic>),
  flags:
      (json['flags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  hasCertificatePhoto: json['has_certificate_photo'] as bool,
  id: json['id'] as String,
  kind: json['kind'] as String,
  markets:
      (json['markets'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  name: json['name'] as String,
  numbers: json['numbers'] == null
      ? null
      : NumbersOut.fromJson(json['numbers'] as Map<String, dynamic>),
  phone: json['phone'] as String,
  provider: json['provider'] == null
      ? null
      : ProviderDetailsOut.fromJson(json['provider'] as Map<String, dynamic>),
  reason: json['reason'] as String?,
  status: json['status'] as String,
  subjectType: json['subject_type'] as String,
  taluka: json['taluka'] as String?,
  village: json['village'] as String?,
);

Map<String, dynamic> _$MyProfileOutToJson(MyProfileOut instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'areas': instance.areas,
      'badges': instance.badges.map((e) => e.toJson()).toList(),
      'crops': instance.crops,
      'district': instance.district,
      'documents': instance.documents,
      'firm': ?instance.firm,
      'fix': ?instance.fix?.toJson(),
      'flags': instance.flags,
      'has_certificate_photo': instance.hasCertificatePhoto,
      'id': instance.id,
      'kind': instance.kind,
      'markets': instance.markets,
      'name': instance.name,
      'numbers': ?instance.numbers?.toJson(),
      'phone': instance.phone,
      'provider': ?instance.provider?.toJson(),
      'reason': ?instance.reason,
      'status': instance.status,
      'subject_type': instance.subjectType,
      'taluka': ?instance.taluka,
      'village': ?instance.village,
    };

MyProfilesResponse _$MyProfilesResponseFromJson(Map<String, dynamic> json) =>
    MyProfilesResponse(
      profiles:
          (json['profiles'] as List<dynamic>?)
              ?.map((e) => MyProfileOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MyProfilesResponseToJson(MyProfilesResponse instance) =>
    <String, dynamic>{
      'profiles': instance.profiles.map((e) => e.toJson()).toList(),
    };

NumbersOut _$NumbersOutFromJson(Map<String, dynamic> json) => NumbersOut(
  apedaNo: json['apeda_no'] as String?,
  apmcLicenceNo: json['apmc_licence_no'] as String?,
  fssaiNo: json['fssai_no'] as String?,
  gstNo: json['gst_no'] as String?,
  iecNo: json['iec_no'] as String?,
);

Map<String, dynamic> _$NumbersOutToJson(NumbersOut instance) =>
    <String, dynamic>{
      'apeda_no': ?instance.apedaNo,
      'apmc_licence_no': ?instance.apmcLicenceNo,
      'fssai_no': ?instance.fssaiNo,
      'gst_no': ?instance.gstNo,
      'iec_no': ?instance.iecNo,
    };

OfficialLinkOut _$OfficialLinkOutFromJson(Map<String, dynamic> json) =>
    OfficialLinkOut(
      kind: json['kind'] as String,
      number: json['number'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$OfficialLinkOutToJson(OfficialLinkOut instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'number': ?instance.number,
      'url': ?instance.url,
    };

PackageCompanyIn _$PackageCompanyInFromJson(Map<String, dynamic> json) =>
    PackageCompanyIn(
      address: json['address'] as String?,
      bankAccountLast4: json['bank_account_last4'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      gstRatePercent: json['gst_rate_percent'] as String?,
      gstin: json['gstin'] as String?,
      invoicePrefix: json['invoice_prefix'] as String?,
      legalName: json['legal_name'] as String?,
      pan: json['pan'] as String?,
      tradeName: json['trade_name'] as String?,
      upiId: json['upi_id'] as String?,
    );

Map<String, dynamic> _$PackageCompanyInToJson(PackageCompanyIn instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'bank_account_last4': ?instance.bankAccountLast4,
      'bank_account_name': ?instance.bankAccountName,
      'bank_ifsc': ?instance.bankIfsc,
      'gst_rate_percent': ?instance.gstRatePercent,
      'gstin': ?instance.gstin,
      'invoice_prefix': ?instance.invoicePrefix,
      'legal_name': ?instance.legalName,
      'pan': ?instance.pan,
      'trade_name': ?instance.tradeName,
      'upi_id': ?instance.upiId,
    };

PackageCompanyOut _$PackageCompanyOutFromJson(Map<String, dynamic> json) =>
    PackageCompanyOut(
      address: json['address'] as String?,
      bankAccountLast4: json['bank_account_last4'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      gstRatePercent: json['gst_rate_percent'] as String?,
      gstin: json['gstin'] as String?,
      invoicePrefix: json['invoice_prefix'] as String?,
      legalName: json['legal_name'] as String?,
      merchantQr: json['merchant_qr'] as bool,
      pan: json['pan'] as String?,
      tradeName: json['trade_name'] as String?,
      upiId: json['upi_id'] as String?,
    );

Map<String, dynamic> _$PackageCompanyOutToJson(PackageCompanyOut instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'bank_account_last4': ?instance.bankAccountLast4,
      'bank_account_name': ?instance.bankAccountName,
      'bank_ifsc': ?instance.bankIfsc,
      'gst_rate_percent': ?instance.gstRatePercent,
      'gstin': ?instance.gstin,
      'invoice_prefix': ?instance.invoicePrefix,
      'legal_name': ?instance.legalName,
      'merchant_qr': instance.merchantQr,
      'pan': ?instance.pan,
      'trade_name': ?instance.tradeName,
      'upi_id': ?instance.upiId,
    };

PackageCover _$PackageCoverFromJson(Map<String, dynamic> json) => PackageCover(
  lotId: json['lot_id'] as String?,
  validUntil: DateTime.parse(json['valid_until'] as String),
);

Map<String, dynamic> _$PackageCoverToJson(PackageCover instance) =>
    <String, dynamic>{
      'lot_id': ?instance.lotId,
      'valid_until': instance.validUntil.toIso8601String(),
    };

PackageGrantIn _$PackageGrantInFromJson(Map<String, dynamic> json) =>
    PackageGrantIn(
      amountPaise: (json['amount_paise'] as num).toInt(),
      growerId: json['grower_id'] as String,
      lotId: json['lot_id'] as String?,
      method: packageGrantInMethodFromJson(json['method']),
      paidOn: DateTime.parse(json['paid_on'] as String),
      paymentRef: json['payment_ref'] as String,
    );

Map<String, dynamic> _$PackageGrantInToJson(PackageGrantIn instance) =>
    <String, dynamic>{
      'amount_paise': instance.amountPaise,
      'grower_id': instance.growerId,
      'lot_id': ?instance.lotId,
      'method': ?packageGrantInMethodToJson(instance.method),
      'paid_on': ?_dateToJson(instance.paidOn),
      'payment_ref': instance.paymentRef,
    };

PackageGrantOut _$PackageGrantOutFromJson(Map<String, dynamic> json) =>
    PackageGrantOut(
      activatedAt: DateTime.parse(json['activated_at'] as String),
      adminId: json['admin_id'] as String,
      amountPaise: (json['amount_paise'] as num).toInt(),
      growerId: json['grower_id'] as String,
      id: json['id'] as String,
      lotId: json['lot_id'] as String?,
      method: json['method'] as String,
      paidOn: DateTime.parse(json['paid_on'] as String),
      paymentRef: json['payment_ref'] as String,
      receiptNo: json['receipt_no'] as String,
      revokedAt: json['revoked_at'] == null
          ? null
          : DateTime.parse(json['revoked_at'] as String),
      revokedReason: json['revoked_reason'] as String?,
      validUntil: DateTime.parse(json['valid_until'] as String),
    );

Map<String, dynamic> _$PackageGrantOutToJson(PackageGrantOut instance) =>
    <String, dynamic>{
      'activated_at': instance.activatedAt.toIso8601String(),
      'admin_id': instance.adminId,
      'amount_paise': instance.amountPaise,
      'grower_id': instance.growerId,
      'id': instance.id,
      'lot_id': ?instance.lotId,
      'method': instance.method,
      'paid_on': ?_dateToJson(instance.paidOn),
      'payment_ref': instance.paymentRef,
      'receipt_no': instance.receiptNo,
      'revoked_at': ?instance.revokedAt?.toIso8601String(),
      'revoked_reason': ?instance.revokedReason,
      'valid_until': instance.validUntil.toIso8601String(),
    };

PackageGrantsResponse _$PackageGrantsResponseFromJson(
  Map<String, dynamic> json,
) => PackageGrantsResponse(
  grants:
      (json['grants'] as List<dynamic>?)
          ?.map((e) => PackageGrantOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PackageGrantsResponseToJson(
  PackageGrantsResponse instance,
) => <String, dynamic>{
  'grants': instance.grants.map((e) => e.toJson()).toList(),
};

PackageGrowerLot _$PackageGrowerLotFromJson(Map<String, dynamic> json) =>
    PackageGrowerLot(
      crop: json['crop'] as String,
      id: json['id'] as String,
      status: json['status'] as String,
      variety: json['variety'] as String?,
    );

Map<String, dynamic> _$PackageGrowerLotToJson(PackageGrowerLot instance) =>
    <String, dynamic>{
      'crop': instance.crop,
      'id': instance.id,
      'status': instance.status,
      'variety': ?instance.variety,
    };

PackageGrowerOut _$PackageGrowerOutFromJson(Map<String, dynamic> json) =>
    PackageGrowerOut(
      district: json['district'] as String?,
      id: json['id'] as String,
      lots:
          (json['lots'] as List<dynamic>?)
              ?.map((e) => PackageGrowerLot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      village: json['village'] as String?,
    );

Map<String, dynamic> _$PackageGrowerOutToJson(PackageGrowerOut instance) =>
    <String, dynamic>{
      'district': ?instance.district,
      'id': instance.id,
      'lots': instance.lots.map((e) => e.toJson()).toList(),
      'name': ?instance.name,
      'phone': ?instance.phone,
      'village': ?instance.village,
    };

PackageGrowersResponse _$PackageGrowersResponseFromJson(
  Map<String, dynamic> json,
) => PackageGrowersResponse(
  growers:
      (json['growers'] as List<dynamic>?)
          ?.map((e) => PackageGrowerOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PackageGrowersResponseToJson(
  PackageGrowersResponse instance,
) => <String, dynamic>{
  'growers': instance.growers.map((e) => e.toJson()).toList(),
};

PackageRevokeIn _$PackageRevokeInFromJson(Map<String, dynamic> json) =>
    PackageRevokeIn(reason: json['reason'] as String);

Map<String, dynamic> _$PackageRevokeInToJson(PackageRevokeIn instance) =>
    <String, dynamic>{'reason': instance.reason};

PackageSettingsIn _$PackageSettingsInFromJson(Map<String, dynamic> json) =>
    PackageSettingsIn(
      enabled: json['enabled'] as bool,
      pricePaise: (json['price_paise'] as num?)?.toInt(),
      startsAt: json['starts_at'] == null
          ? null
          : DateTime.parse(json['starts_at'] as String),
      validityDays: (json['validity_days'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PackageSettingsInToJson(PackageSettingsIn instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'price_paise': ?instance.pricePaise,
      'starts_at': ?_dateToJson(instance.startsAt),
      'validity_days': ?instance.validityDays,
    };

PackageSettingsOut _$PackageSettingsOutFromJson(Map<String, dynamic> json) =>
    PackageSettingsOut(
      enabled: json['enabled'] as bool,
      missing:
          (json['missing'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pricePaise: (json['price_paise'] as num?)?.toInt(),
      startsAt: json['starts_at'] == null
          ? null
          : DateTime.parse(json['starts_at'] as String),
      validityDays: (json['validity_days'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PackageSettingsOutToJson(PackageSettingsOut instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'missing': instance.missing,
      'price_paise': ?instance.pricePaise,
      'starts_at': ?_dateToJson(instance.startsAt),
      'validity_days': ?instance.validityDays,
    };

PackageStatus _$PackageStatusFromJson(Map<String, dynamic> json) =>
    PackageStatus(
      active:
          (json['active'] as List<dynamic>?)
              ?.map((e) => PackageCover.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      switchOn: json['switch_on'] as bool,
    );

Map<String, dynamic> _$PackageStatusToJson(PackageStatus instance) =>
    <String, dynamic>{
      'active': instance.active.map((e) => e.toJson()).toList(),
      'switch_on': instance.switchOn,
    };

PartyContactOut _$PartyContactOutFromJson(Map<String, dynamic> json) =>
    PartyContactOut(
      firm: json['firm'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$PartyContactOutToJson(PartyContactOut instance) =>
    <String, dynamic>{
      'firm': ?instance.firm,
      'name': instance.name,
      'phone': instance.phone,
    };

PhotoAnalysisOut _$PhotoAnalysisOutFromJson(Map<String, dynamic> json) =>
    PhotoAnalysisOut(
      candidates:
          (json['candidates'] as List<dynamic>?)
              ?.map((e) => CandidateOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      photoId: json['photo_id'] as String,
      unsure: json['unsure'] as bool,
    );

Map<String, dynamic> _$PhotoAnalysisOutToJson(PhotoAnalysisOut instance) =>
    <String, dynamic>{
      'candidates': instance.candidates.map((e) => e.toJson()).toList(),
      'photo_id': instance.photoId,
      'unsure': instance.unsure,
    };

PhotoDownloadUrl _$PhotoDownloadUrlFromJson(Map<String, dynamic> json) =>
    PhotoDownloadUrl(
      expiresIn: (json['expires_in'] as num).toInt(),
      photoKey: json['photo_key'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$PhotoDownloadUrlToJson(PhotoDownloadUrl instance) =>
    <String, dynamic>{
      'expires_in': instance.expiresIn,
      'photo_key': instance.photoKey,
      'url': instance.url,
    };

PhotoLimitsIn _$PhotoLimitsInFromJson(Map<String, dynamic> json) =>
    PhotoLimitsIn(
      dailyTotal: (json['daily_total'] as num?)?.toInt(),
      freeDaily: (json['free_daily'] as num?)?.toInt(),
      freeMonthly: (json['free_monthly'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PhotoLimitsInToJson(PhotoLimitsIn instance) =>
    <String, dynamic>{
      'daily_total': ?instance.dailyTotal,
      'free_daily': ?instance.freeDaily,
      'free_monthly': ?instance.freeMonthly,
    };

PhotoLimitsOut _$PhotoLimitsOutFromJson(Map<String, dynamic> json) =>
    PhotoLimitsOut(
      dailyTotal: (json['daily_total'] as num?)?.toInt(),
      defaultDaily: (json['default_daily'] as num?)?.toInt(),
      defaultMonthly: (json['default_monthly'] as num?)?.toInt(),
      freeDaily: (json['free_daily'] as num?)?.toInt(),
      freeMonthly: (json['free_monthly'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PhotoLimitsOutToJson(PhotoLimitsOut instance) =>
    <String, dynamic>{
      'daily_total': ?instance.dailyTotal,
      'default_daily': ?instance.defaultDaily,
      'default_monthly': ?instance.defaultMonthly,
      'free_daily': ?instance.freeDaily,
      'free_monthly': ?instance.freeMonthly,
    };

PhotoUploadIn _$PhotoUploadInFromJson(Map<String, dynamic> json) =>
    PhotoUploadIn(
      contentType: json['content_type'] as String?,
      sizeBytes: (json['size_bytes'] as num).toInt(),
    );

Map<String, dynamic> _$PhotoUploadInToJson(PhotoUploadIn instance) =>
    <String, dynamic>{
      'content_type': ?instance.contentType,
      'size_bytes': instance.sizeBytes,
    };

PhotoUploadUrl _$PhotoUploadUrlFromJson(Map<String, dynamic> json) =>
    PhotoUploadUrl(
      contentType: json['content_type'] as String?,
      expiresIn: (json['expires_in'] as num).toInt(),
      maxBytes: (json['max_bytes'] as num).toInt(),
      photoKey: json['photo_key'] as String,
      uploadUrl: json['upload_url'] as String,
    );

Map<String, dynamic> _$PhotoUploadUrlToJson(PhotoUploadUrl instance) =>
    <String, dynamic>{
      'content_type': ?instance.contentType,
      'expires_in': instance.expiresIn,
      'max_bytes': instance.maxBytes,
      'photo_key': instance.photoKey,
      'upload_url': instance.uploadUrl,
    };

PinOut _$PinOutFromJson(Map<String, dynamic> json) => PinOut(
  lat: (json['lat'] as num).toDouble(),
  lon: (json['lon'] as num).toDouble(),
);

Map<String, dynamic> _$PinOutToJson(PinOut instance) => <String, dynamic>{
  'lat': instance.lat,
  'lon': instance.lon,
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

PlanOfferOut _$PlanOfferOutFromJson(Map<String, dynamic> json) => PlanOfferOut(
  accountId: json['account_id'] as String,
  basePlanId: json['base_plan_id'] as String?,
  covered: json['covered'] as bool,
  inForce: json['in_force'] as bool,
  locked:
      (json['locked'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  priceChange: json['price_change'] == null
      ? null
      : PriceChangeOut.fromJson(json['price_change'] as Map<String, dynamic>),
  productId: json['product_id'] as String?,
  role: json['role'] as String?,
);

Map<String, dynamic> _$PlanOfferOutToJson(PlanOfferOut instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'base_plan_id': ?instance.basePlanId,
      'covered': instance.covered,
      'in_force': instance.inForce,
      'locked': instance.locked,
      'price_change': ?instance.priceChange?.toJson(),
      'product_id': ?instance.productId,
      'role': ?instance.role,
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

PriceChangeOut _$PriceChangeOutFromJson(Map<String, dynamic> json) =>
    PriceChangeOut(
      chargeTime: json['charge_time'] as String?,
      currency: json['currency'] as String?,
      mode: json['mode'] as String?,
      newPricePaise: (json['new_price_paise'] as num).toInt(),
      state: json['state'] as String?,
    );

Map<String, dynamic> _$PriceChangeOutToJson(PriceChangeOut instance) =>
    <String, dynamic>{
      'charge_time': ?instance.chargeTime,
      'currency': ?instance.currency,
      'mode': ?instance.mode,
      'new_price_paise': instance.newPricePaise,
      'state': ?instance.state,
    };

PriceDay _$PriceDayFromJson(Map<String, dynamic> json) => PriceDay(
  day: DateTime.parse(json['day'] as String),
  maxRsPerQuintal: (json['max_rs_per_quintal'] as num?)?.toInt(),
  minRsPerQuintal: (json['min_rs_per_quintal'] as num?)?.toInt(),
  modalRsPerQuintal: (json['modal_rs_per_quintal'] as num).toInt(),
  source: json['source'] as String,
);

Map<String, dynamic> _$PriceDayToJson(PriceDay instance) => <String, dynamic>{
  'day': ?_dateToJson(instance.day),
  'max_rs_per_quintal': ?instance.maxRsPerQuintal,
  'min_rs_per_quintal': ?instance.minRsPerQuintal,
  'modal_rs_per_quintal': instance.modalRsPerQuintal,
  'source': instance.source,
};

ProfilesResponse _$ProfilesResponseFromJson(Map<String, dynamic> json) =>
    ProfilesResponse(
      profiles:
          (json['profiles'] as List<dynamic>?)
              ?.map((e) => PublicProfileOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ProfilesResponseToJson(ProfilesResponse instance) =>
    <String, dynamic>{
      'profiles': instance.profiles.map((e) => e.toJson()).toList(),
    };

ProviderDetailsOut _$ProviderDetailsOutFromJson(Map<String, dynamic> json) =>
    ProviderDetailsOut(
      capacityT: (json['capacity_t'] as num?)?.toDouble(),
      carrierRegNo: json['carrier_reg_no'] as String?,
      certValidUntil: json['cert_valid_until'] == null
          ? null
          : DateTime.parse(json['cert_valid_until'] as String),
      certificateExpired: json['certificate_expired'] as bool,
      refrigerated: json['refrigerated'] as bool?,
      vehicleNumbers:
          (json['vehicle_numbers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ProviderDetailsOutToJson(ProviderDetailsOut instance) =>
    <String, dynamic>{
      'capacity_t': ?instance.capacityT,
      'carrier_reg_no': ?instance.carrierRegNo,
      'cert_valid_until': ?_dateToJson(instance.certValidUntil),
      'certificate_expired': instance.certificateExpired,
      'refrigerated': ?instance.refrigerated,
      'vehicle_numbers': instance.vehicleNumbers,
    };

ProviderIn _$ProviderInFromJson(Map<String, dynamic> json) => ProviderIn(
  address: json['address'] as String?,
  capacityT: (json['capacity_t'] as num?)?.toDouble(),
  carrierRegNo: json['carrier_reg_no'] as String?,
  certValidUntil: json['cert_valid_until'] == null
      ? null
      : DateTime.parse(json['cert_valid_until'] as String),
  district: json['district'] as String,
  fix: RegistrationFixIn.fromJson(json['fix'] as Map<String, dynamic>),
  kind: providerInKindFromJson(json['kind']),
  name: json['name'] as String,
  phone: json['phone'] as String,
  refrigerated: json['refrigerated'] as bool?,
  serviceAreas:
      (json['service_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  taluka: json['taluka'] as String?,
  vehicleNumbers:
      (json['vehicle_numbers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  village: json['village'] as String,
);

Map<String, dynamic> _$ProviderInToJson(ProviderIn instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'capacity_t': ?instance.capacityT,
      'carrier_reg_no': ?instance.carrierRegNo,
      'cert_valid_until': ?_dateToJson(instance.certValidUntil),
      'district': instance.district,
      'fix': instance.fix.toJson(),
      'kind': ?providerInKindToJson(instance.kind),
      'name': instance.name,
      'phone': instance.phone,
      'refrigerated': ?instance.refrigerated,
      'service_areas': ?instance.serviceAreas,
      'taluka': ?instance.taluka,
      'vehicle_numbers': ?instance.vehicleNumbers,
      'village': instance.village,
    };

PublicProfileOut _$PublicProfileOutFromJson(
  Map<String, dynamic> json,
) => PublicProfileOut(
  address: json['address'] as String?,
  areas:
      (json['areas'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => BadgeOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  crops:
      (json['crops'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  dealsCompleted: (json['deals_completed'] as num).toInt(),
  distanceKm: (json['distance_km'] as num?)?.toInt(),
  district: json['district'] as String,
  firm: json['firm'] as String?,
  id: json['id'] as String,
  kind: json['kind'] as String,
  markets:
      (json['markets'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  name: json['name'] as String,
  phone: json['phone'] as String,
  provider: json['provider'] == null
      ? null
      : ProviderDetailsOut.fromJson(json['provider'] as Map<String, dynamic>),
  stars:
      (json['stars'] as List<dynamic>?)
          ?.map((e) => QuestionStarsOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  subjectType: json['subject_type'] as String,
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => TagCountOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  taluka: json['taluka'] as String?,
  village: json['village'] as String?,
);

Map<String, dynamic> _$PublicProfileOutToJson(PublicProfileOut instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'areas': instance.areas,
      'badges': instance.badges.map((e) => e.toJson()).toList(),
      'crops': instance.crops,
      'deals_completed': instance.dealsCompleted,
      'distance_km': ?instance.distanceKm,
      'district': instance.district,
      'firm': ?instance.firm,
      'id': instance.id,
      'kind': instance.kind,
      'markets': instance.markets,
      'name': instance.name,
      'phone': instance.phone,
      'provider': ?instance.provider?.toJson(),
      'stars': instance.stars.map((e) => e.toJson()).toList(),
      'subject_type': instance.subjectType,
      'tags': instance.tags.map((e) => e.toJson()).toList(),
      'taluka': ?instance.taluka,
      'village': ?instance.village,
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

QuestionStarsOut _$QuestionStarsOutFromJson(Map<String, dynamic> json) =>
    QuestionStarsOut(
      average: (json['average'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
      questionKey: json['question_key'] as String,
    );

Map<String, dynamic> _$QuestionStarsOutToJson(QuestionStarsOut instance) =>
    <String, dynamic>{
      'average': instance.average,
      'count': instance.count,
      'question_key': instance.questionKey,
    };

QueueResponse _$QueueResponseFromJson(Map<String, dynamic> json) =>
    QueueResponse(
      subjects:
          (json['subjects'] as List<dynamic>?)
              ?.map((e) => SubjectOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$QueueResponseToJson(QueueResponse instance) =>
    <String, dynamic>{
      'subjects': instance.subjects.map((e) => e.toJson()).toList(),
    };

RatingIn _$RatingInFromJson(Map<String, dynamic> json) => RatingIn(
  answers:
      (json['answers'] as List<dynamic>?)
          ?.map((e) => AnswerIn.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$RatingInToJson(RatingIn instance) => <String, dynamic>{
  'answers': instance.answers.map((e) => e.toJson()).toList(),
};

RatingTagAdminOut _$RatingTagAdminOutFromJson(Map<String, dynamic> json) =>
    RatingTagAdminOut(
      id: json['id'] as String,
      key: json['key'] as String,
      labelEn: json['label_en'] as String,
      labelHi: json['label_hi'] as String,
      labelMr: json['label_mr'] as String,
      polarity: json['polarity'] as String,
      questionKey: json['question_key'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$RatingTagAdminOutToJson(RatingTagAdminOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'label_en': instance.labelEn,
      'label_hi': instance.labelHi,
      'label_mr': instance.labelMr,
      'polarity': instance.polarity,
      'question_key': instance.questionKey,
      'sort_order': instance.sortOrder,
      'status': instance.status,
    };

RatingTagIn _$RatingTagInFromJson(Map<String, dynamic> json) => RatingTagIn(
  labelEn: json['label_en'] as String,
  labelHi: json['label_hi'] as String,
  labelMr: json['label_mr'] as String,
  status: ratingTagInStatusFromJson(json['status']),
);

Map<String, dynamic> _$RatingTagInToJson(RatingTagIn instance) =>
    <String, dynamic>{
      'label_en': instance.labelEn,
      'label_hi': instance.labelHi,
      'label_mr': instance.labelMr,
      'status': ?ratingTagInStatusToJson(instance.status),
    };

RatingTagOut _$RatingTagOutFromJson(Map<String, dynamic> json) => RatingTagOut(
  id: json['id'] as String,
  key: json['key'] as String,
  labelEn: json['label_en'] as String,
  labelHi: json['label_hi'] as String,
  labelMr: json['label_mr'] as String,
  polarity: json['polarity'] as String,
  questionKey: json['question_key'] as String,
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$RatingTagOutToJson(RatingTagOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'label_en': instance.labelEn,
      'label_hi': instance.labelHi,
      'label_mr': instance.labelMr,
      'polarity': instance.polarity,
      'question_key': instance.questionKey,
      'sort_order': instance.sortOrder,
    };

RatingTagsAdminResponse _$RatingTagsAdminResponseFromJson(
  Map<String, dynamic> json,
) => RatingTagsAdminResponse(
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => RatingTagAdminOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$RatingTagsAdminResponseToJson(
  RatingTagsAdminResponse instance,
) => <String, dynamic>{'tags': instance.tags.map((e) => e.toJson()).toList()};

RatingTagsResponse _$RatingTagsResponseFromJson(Map<String, dynamic> json) =>
    RatingTagsResponse(
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => RatingTagOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RatingTagsResponseToJson(RatingTagsResponse instance) =>
    <String, dynamic>{'tags': instance.tags.map((e) => e.toJson()).toList()};

ReadyResponse _$ReadyResponseFromJson(Map<String, dynamic> json) =>
    ReadyResponse(
      database: json['database'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$ReadyResponseToJson(ReadyResponse instance) =>
    <String, dynamic>{'database': instance.database, 'status': instance.status};

ReceiptGst _$ReceiptGstFromJson(Map<String, dynamic> json) => ReceiptGst(
  gstPaise: (json['gst_paise'] as num).toInt(),
  ratePercent: json['rate_percent'] as String,
  taxablePaise: (json['taxable_paise'] as num).toInt(),
);

Map<String, dynamic> _$ReceiptGstToJson(ReceiptGst instance) =>
    <String, dynamic>{
      'gst_paise': instance.gstPaise,
      'rate_percent': instance.ratePercent,
      'taxable_paise': instance.taxablePaise,
    };

ReceiptOut _$ReceiptOutFromJson(Map<String, dynamic> json) => ReceiptOut(
  address: json['address'] as String,
  amountPaise: (json['amount_paise'] as num).toInt(),
  growerName: json['grower_name'] as String?,
  growerPhone: json['grower_phone'] as String?,
  gst: json['gst'] == null
      ? null
      : ReceiptGst.fromJson(json['gst'] as Map<String, dynamic>),
  gstin: json['gstin'] as String?,
  issuedOn: DateTime.parse(json['issued_on'] as String),
  legalName: json['legal_name'] as String,
  lot: json['lot'] as String?,
  method: json['method'] as String,
  paidOn: DateTime.parse(json['paid_on'] as String),
  pan: json['pan'] as String?,
  paymentRef: json['payment_ref'] as String,
  receiptNo: json['receipt_no'] as String,
  revoked: json['revoked'] as bool,
  tradeName: json['trade_name'] as String?,
  validFrom: DateTime.parse(json['valid_from'] as String),
  validUntil: DateTime.parse(json['valid_until'] as String),
);

Map<String, dynamic> _$ReceiptOutToJson(ReceiptOut instance) =>
    <String, dynamic>{
      'address': instance.address,
      'amount_paise': instance.amountPaise,
      'grower_name': ?instance.growerName,
      'grower_phone': ?instance.growerPhone,
      'gst': ?instance.gst?.toJson(),
      'gstin': ?instance.gstin,
      'issued_on': ?_dateToJson(instance.issuedOn),
      'legal_name': instance.legalName,
      'lot': ?instance.lot,
      'method': instance.method,
      'paid_on': ?_dateToJson(instance.paidOn),
      'pan': ?instance.pan,
      'payment_ref': instance.paymentRef,
      'receipt_no': instance.receiptNo,
      'revoked': instance.revoked,
      'trade_name': ?instance.tradeName,
      'valid_from': ?_dateToJson(instance.validFrom),
      'valid_until': ?_dateToJson(instance.validUntil),
    };

RecheckItemOut _$RecheckItemOutFromJson(Map<String, dynamic> json) =>
    RecheckItemOut(
      checkId: json['check_id'] as String,
      checkedAt: DateTime.parse(json['checked_at'] as String),
      kind: json['kind'] as String,
      listedAt: DateTime.parse(json['listed_at'] as String),
      name: json['name'] as String,
      number: json['number'] as String?,
      subjectId: json['subject_id'] as String,
      subjectType: json['subject_type'] as String,
    );

Map<String, dynamic> _$RecheckItemOutToJson(RecheckItemOut instance) =>
    <String, dynamic>{
      'check_id': instance.checkId,
      'checked_at': instance.checkedAt.toIso8601String(),
      'kind': instance.kind,
      'listed_at': instance.listedAt.toIso8601String(),
      'name': instance.name,
      'number': ?instance.number,
      'subject_id': instance.subjectId,
      'subject_type': instance.subjectType,
    };

RecheckResponse _$RecheckResponseFromJson(Map<String, dynamic> json) =>
    RecheckResponse(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RecheckItemOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RecheckResponseToJson(RecheckResponse instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

RegistrationFixIn _$RegistrationFixInFromJson(Map<String, dynamic> json) =>
    RegistrationFixIn(
      accuracyM: (json['accuracy_m'] as num).toDouble(),
      capturedAt: DateTime.parse(json['captured_at'] as String),
      district: json['district'] as String?,
      isMocked: json['is_mocked'] as bool? ?? false,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      pin: json['pin'] as String?,
      place: json['place'] as String?,
      state: json['state'] as String?,
    );

Map<String, dynamic> _$RegistrationFixInToJson(RegistrationFixIn instance) =>
    <String, dynamic>{
      'accuracy_m': instance.accuracyM,
      'captured_at': instance.capturedAt.toIso8601String(),
      'district': ?instance.district,
      'is_mocked': ?instance.isMocked,
      'lat': instance.lat,
      'lon': instance.lon,
      'pin': ?instance.pin,
      'place': ?instance.place,
      'state': ?instance.state,
    };

RelatedOut _$RelatedOutFromJson(Map<String, dynamic> json) => RelatedOut(
  flag: json['flag'] as String,
  name: json['name'] as String,
  subjectId: json['subject_id'] as String,
  subjectType: json['subject_type'] as String,
  why: json['why'] as String,
);

Map<String, dynamic> _$RelatedOutToJson(RelatedOut instance) =>
    <String, dynamic>{
      'flag': instance.flag,
      'name': instance.name,
      'subject_id': instance.subjectId,
      'subject_type': instance.subjectType,
      'why': instance.why,
    };

ReportAdminOut _$ReportAdminOutFromJson(Map<String, dynamic> json) =>
    ReportAdminOut(
      ackOverdue: json['ack_overdue'] as bool,
      acknowledgedAt: json['acknowledged_at'] == null
          ? null
          : DateTime.parse(json['acknowledged_at'] as String),
      adminActionId: json['admin_action_id'] as String?,
      closeOverdue: json['close_overdue'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      decidedAt: json['decided_at'] == null
          ? null
          : DateTime.parse(json['decided_at'] as String),
      decidedBy: json['decided_by'] as String?,
      id: json['id'] as String,
      photoCount: (json['photo_count'] as num).toInt(),
      reason: json['reason'] as String,
      reporterId: json['reporter_id'] as String,
      status: json['status'] as String,
      subjectId: json['subject_id'] as String,
      subjectType: json['subject_type'] as String,
      subjectUserId: json['subject_user_id'] as String?,
    );

Map<String, dynamic> _$ReportAdminOutToJson(ReportAdminOut instance) =>
    <String, dynamic>{
      'ack_overdue': instance.ackOverdue,
      'acknowledged_at': ?instance.acknowledgedAt?.toIso8601String(),
      'admin_action_id': ?instance.adminActionId,
      'close_overdue': instance.closeOverdue,
      'created_at': instance.createdAt.toIso8601String(),
      'decided_at': ?instance.decidedAt?.toIso8601String(),
      'decided_by': ?instance.decidedBy,
      'id': instance.id,
      'photo_count': instance.photoCount,
      'reason': instance.reason,
      'reporter_id': instance.reporterId,
      'status': instance.status,
      'subject_id': instance.subjectId,
      'subject_type': instance.subjectType,
      'subject_user_id': ?instance.subjectUserId,
    };

ReportDecisionIn _$ReportDecisionInFromJson(Map<String, dynamic> json) =>
    ReportDecisionIn(
      action: reportDecisionInActionFromJson(json['action']),
      reasonCode: reportDecisionInReasonCodeFromJson(json['reason_code']),
    );

Map<String, dynamic> _$ReportDecisionInToJson(ReportDecisionIn instance) =>
    <String, dynamic>{
      'action': ?reportDecisionInActionToJson(instance.action),
      'reason_code': ?reportDecisionInReasonCodeToJson(instance.reasonCode),
    };

ReportIn _$ReportInFromJson(Map<String, dynamic> json) => ReportIn(
  reason: reportInReasonFromJson(json['reason']),
  subjectId: json['subject_id'] as String,
  subjectType: reportInSubjectTypeFromJson(json['subject_type']),
);

Map<String, dynamic> _$ReportInToJson(ReportIn instance) => <String, dynamic>{
  'reason': ?reportInReasonToJson(instance.reason),
  'subject_id': instance.subjectId,
  'subject_type': ?reportInSubjectTypeToJson(instance.subjectType),
};

ReportOut _$ReportOutFromJson(Map<String, dynamic> json) => ReportOut(
  createdAt: DateTime.parse(json['created_at'] as String),
  decidedAt: json['decided_at'] == null
      ? null
      : DateTime.parse(json['decided_at'] as String),
  id: json['id'] as String,
  photoCount: (json['photo_count'] as num).toInt(),
  reason: json['reason'] as String,
  status: json['status'] as String,
  subjectId: json['subject_id'] as String,
  subjectType: json['subject_type'] as String,
);

Map<String, dynamic> _$ReportOutToJson(ReportOut instance) => <String, dynamic>{
  'created_at': instance.createdAt.toIso8601String(),
  'decided_at': ?instance.decidedAt?.toIso8601String(),
  'id': instance.id,
  'photo_count': instance.photoCount,
  'reason': instance.reason,
  'status': instance.status,
  'subject_id': instance.subjectId,
  'subject_type': instance.subjectType,
};

ReportsAdminResponse _$ReportsAdminResponseFromJson(
  Map<String, dynamic> json,
) => ReportsAdminResponse(
  reports:
      (json['reports'] as List<dynamic>?)
          ?.map((e) => ReportAdminOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$ReportsAdminResponseToJson(
  ReportsAdminResponse instance,
) => <String, dynamic>{
  'reports': instance.reports.map((e) => e.toJson()).toList(),
};

ReportsResponse _$ReportsResponseFromJson(Map<String, dynamic> json) =>
    ReportsResponse(
      reports:
          (json['reports'] as List<dynamic>?)
              ?.map((e) => ReportOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ReportsResponseToJson(ReportsResponse instance) =>
    <String, dynamic>{
      'reports': instance.reports.map((e) => e.toJson()).toList(),
    };

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

RoleAmountIn _$RoleAmountInFromJson(Map<String, dynamic> json) =>
    RoleAmountIn(amountPaise: (json['amount_paise'] as num?)?.toInt());

Map<String, dynamic> _$RoleAmountInToJson(RoleAmountIn instance) =>
    <String, dynamic>{'amount_paise': ?instance.amountPaise};

RolePhotoLimitsIn _$RolePhotoLimitsInFromJson(Map<String, dynamic> json) =>
    RolePhotoLimitsIn(
      daily: (json['daily'] as num?)?.toInt(),
      monthly: (json['monthly'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RolePhotoLimitsInToJson(RolePhotoLimitsIn instance) =>
    <String, dynamic>{'daily': ?instance.daily, 'monthly': ?instance.monthly};

RolePriceOut _$RolePriceOutFromJson(Map<String, dynamic> json) => RolePriceOut(
  amountPaise: (json['amount_paise'] as num?)?.toInt(),
  photoAiDaily: (json['photo_ai_daily'] as num?)?.toInt(),
  photoAiMonthly: (json['photo_ai_monthly'] as num?)?.toInt(),
  playCurrency: json['play_currency'] as String?,
  playPricePaise: (json['play_price_paise'] as num?)?.toInt(),
  playSyncedAt: json['play_synced_at'] == null
      ? null
      : DateTime.parse(json['play_synced_at'] as String),
  role: json['role'] as String,
);

Map<String, dynamic> _$RolePriceOutToJson(RolePriceOut instance) =>
    <String, dynamic>{
      'amount_paise': ?instance.amountPaise,
      'photo_ai_daily': ?instance.photoAiDaily,
      'photo_ai_monthly': ?instance.photoAiMonthly,
      'play_currency': ?instance.playCurrency,
      'play_price_paise': ?instance.playPricePaise,
      'play_synced_at': ?instance.playSyncedAt?.toIso8601String(),
      'role': instance.role,
    };

SampleOut _$SampleOutFromJson(Map<String, dynamic> json) => SampleOut(
  candidates:
      (json['candidates'] as List<dynamic>?)
          ?.map((e) => CandidateOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  createdAt: DateTime.parse(json['created_at'] as String),
  id: json['id'] as String,
  label: json['label'] as String?,
  labelSource: json['label_source'] as String?,
  model: json['model'] as String,
  $part: json['part'] as String?,
  photoUrl: json['photo_url'] as String?,
  plotId: json['plot_id'] as String,
  scoutingItem: json['scouting_item'] as String?,
  unsure: json['unsure'] as bool,
);

Map<String, dynamic> _$SampleOutToJson(SampleOut instance) => <String, dynamic>{
  'candidates': instance.candidates.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt.toIso8601String(),
  'id': instance.id,
  'label': ?instance.label,
  'label_source': ?instance.labelSource,
  'model': instance.model,
  'part': ?instance.$part,
  'photo_url': ?instance.photoUrl,
  'plot_id': instance.plotId,
  'scouting_item': ?instance.scoutingItem,
  'unsure': instance.unsure,
};

SamplesOut _$SamplesOutFromJson(Map<String, dynamic> json) => SamplesOut(
  samples:
      (json['samples'] as List<dynamic>?)
          ?.map((e) => SampleOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$SamplesOutToJson(SamplesOut instance) =>
    <String, dynamic>{
      'samples': instance.samples.map((e) => e.toJson()).toList(),
    };

SentInterestOut _$SentInterestOutFromJson(Map<String, dynamic> json) =>
    SentInterestOut(
      basis: json['basis'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      dealId: json['deal_id'] as String?,
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      id: json['id'] as String,
      lot: LotBrief.fromJson(json['lot'] as Map<String, dynamic>),
      lotId: json['lot_id'] as String,
      quantityT: (json['quantity_t'] as num?)?.toDouble(),
      ratePaise: (json['rate_paise'] as num).toInt(),
      status: json['status'] as String,
      viaBroker: json['via_broker'] as bool,
    );

Map<String, dynamic> _$SentInterestOutToJson(SentInterestOut instance) =>
    <String, dynamic>{
      'basis': instance.basis,
      'created_at': instance.createdAt.toIso8601String(),
      'deal_id': ?instance.dealId,
      'harvest_date': ?_dateToJson(instance.harvestDate),
      'id': instance.id,
      'lot': instance.lot.toJson(),
      'lot_id': instance.lotId,
      'quantity_t': ?instance.quantityT,
      'rate_paise': instance.ratePaise,
      'status': instance.status,
      'via_broker': instance.viaBroker,
    };

SentInterestsResponse _$SentInterestsResponseFromJson(
  Map<String, dynamic> json,
) => SentInterestsResponse(
  interests:
      (json['interests'] as List<dynamic>?)
          ?.map((e) => SentInterestOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$SentInterestsResponseToJson(
  SentInterestsResponse instance,
) => <String, dynamic>{
  'interests': instance.interests.map((e) => e.toJson()).toList(),
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

StatusIn _$StatusInFromJson(Map<String, dynamic> json) =>
    StatusIn(status: statusInStatusFromJson(json['status']));

Map<String, dynamic> _$StatusInToJson(StatusIn instance) => <String, dynamic>{
  'status': ?statusInStatusToJson(instance.status),
};

SubjectDetailOut _$SubjectDetailOutFromJson(Map<String, dynamic> json) =>
    SubjectDetailOut(
      checks:
          (json['checks'] as List<dynamic>?)
              ?.map((e) => CheckOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => VerificationOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      links:
          (json['links'] as List<dynamic>?)
              ?.map((e) => OfficialLinkOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subject: SubjectOut.fromJson(json['subject'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubjectDetailOutToJson(SubjectDetailOut instance) =>
    <String, dynamic>{
      'checks': ?instance.checks?.map((e) => e.toJson()).toList(),
      'history': instance.history.map((e) => e.toJson()).toList(),
      'links': ?instance.links?.map((e) => e.toJson()).toList(),
      'subject': instance.subject.toJson(),
    };

SubjectOut _$SubjectOutFromJson(Map<String, dynamic> json) => SubjectOut(
  documentKeys:
      (json['document_keys'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  fields: json['fields'] as Map<String, dynamic>,
  flags:
      (json['flags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  name: json['name'] as String,
  registrationFix: json['registration_fix'] == null
      ? null
      : AdminFixOut.fromJson(json['registration_fix'] as Map<String, dynamic>),
  related:
      (json['related'] as List<dynamic>?)
          ?.map((e) => RelatedOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  status: json['status'] as String,
  subjectId: json['subject_id'] as String,
  subjectType: json['subject_type'] as String,
  waitingSince: DateTime.parse(json['waiting_since'] as String),
);

Map<String, dynamic> _$SubjectOutToJson(SubjectOut instance) =>
    <String, dynamic>{
      'document_keys': instance.documentKeys,
      'fields': instance.fields,
      'flags': ?instance.flags,
      'name': instance.name,
      'registration_fix': ?instance.registrationFix?.toJson(),
      'related': ?instance.related?.map((e) => e.toJson()).toList(),
      'status': instance.status,
      'subject_id': instance.subjectId,
      'subject_type': instance.subjectType,
      'waiting_since': instance.waitingSince.toIso8601String(),
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

SwitchIn _$SwitchInFromJson(Map<String, dynamic> json) => SwitchIn(
  enabled: json['enabled'] as bool,
  startsOn: json['starts_on'] == null
      ? null
      : DateTime.parse(json['starts_on'] as String),
);

Map<String, dynamic> _$SwitchInToJson(SwitchIn instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'starts_on': ?_dateToJson(instance.startsOn),
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

TagCountOut _$TagCountOutFromJson(Map<String, dynamic> json) => TagCountOut(
  count: (json['count'] as num).toInt(),
  key: json['key'] as String,
  labelEn: json['label_en'] as String,
  labelHi: json['label_hi'] as String,
  labelMr: json['label_mr'] as String,
  polarity: json['polarity'] as String,
  questionKey: json['question_key'] as String,
  tagId: json['tag_id'] as String,
);

Map<String, dynamic> _$TagCountOutToJson(TagCountOut instance) =>
    <String, dynamic>{
      'count': instance.count,
      'key': instance.key,
      'label_en': instance.labelEn,
      'label_hi': instance.labelHi,
      'label_mr': instance.labelMr,
      'polarity': instance.polarity,
      'question_key': instance.questionKey,
      'tag_id': instance.tagId,
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

TermsDocOut _$TermsDocOutFromJson(Map<String, dynamic> json) => TermsDocOut(
  kind: termsDocOutKindFromJson(json['kind']),
  url: json['url'] as String?,
  version: json['version'] as String,
);

Map<String, dynamic> _$TermsDocOutToJson(TermsDocOut instance) =>
    <String, dynamic>{
      'kind': ?termsDocOutKindToJson(instance.kind),
      'url': ?instance.url,
      'version': instance.version,
    };

TermsOut _$TermsOutFromJson(Map<String, dynamic> json) => TermsOut(
  documents:
      (json['documents'] as List<dynamic>?)
          ?.map((e) => TermsDocOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  grievanceOfficer: GrievanceOfficerOut.fromJson(
    json['grievance_officer'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$TermsOutToJson(TermsOut instance) => <String, dynamic>{
  'documents': instance.documents.map((e) => e.toJson()).toList(),
  'grievance_officer': instance.grievanceOfficer.toJson(),
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

VerificationOut _$VerificationOutFromJson(Map<String, dynamic> json) =>
    VerificationOut(
      checkedAt: json['checked_at'] == null
          ? null
          : DateTime.parse(json['checked_at'] as String),
      checkedBy: json['checked_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      documentKeys:
          (json['document_keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      id: json['id'] as String,
      reason: json['reason'] as String?,
      status: json['status'] as String,
    );

Map<String, dynamic> _$VerificationOutToJson(VerificationOut instance) =>
    <String, dynamic>{
      'checked_at': ?instance.checkedAt?.toIso8601String(),
      'checked_by': ?instance.checkedBy,
      'created_at': instance.createdAt.toIso8601String(),
      'document_keys': instance.documentKeys,
      'id': instance.id,
      'reason': ?instance.reason,
      'status': instance.status,
    };

VerifyIn _$VerifyInFromJson(Map<String, dynamic> json) =>
    VerifyIn(purchaseToken: json['purchase_token'] as String);

Map<String, dynamic> _$VerifyInToJson(VerifyIn instance) => <String, dynamic>{
  'purchase_token': instance.purchaseToken,
};

WeatherAlert _$WeatherAlertFromJson(Map<String, dynamic> json) => WeatherAlert(
  action: json['action'] as String?,
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
      'action': ?instance.action,
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
  rainProbPct: (json['rain_prob_pct'] as num?)?.toDouble(),
  rhMeanPct: (json['rh_mean_pct'] as num?)?.toDouble(),
  tMaxC: (json['t_max_c'] as num?)?.toDouble(),
  tMinC: (json['t_min_c'] as num?)?.toDouble(),
  weatherCode: (json['weather_code'] as num?)?.toDouble(),
  windGustKmh: (json['wind_gust_kmh'] as num?)?.toDouble(),
);

Map<String, dynamic> _$WeatherDayToJson(WeatherDay instance) =>
    <String, dynamic>{
      'day': ?_dateToJson(instance.day),
      'precip_mm': ?instance.precipMm,
      'rain_prob_pct': ?instance.rainProbPct,
      'rh_mean_pct': ?instance.rhMeanPct,
      't_max_c': ?instance.tMaxC,
      't_min_c': ?instance.tMinC,
      'weather_code': ?instance.weatherCode,
      'wind_gust_kmh': ?instance.windGustKmh,
    };
