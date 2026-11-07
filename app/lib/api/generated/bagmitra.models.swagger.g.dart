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
      'rh_mean_pct': ?instance.rhMeanPct,
      't_max_c': ?instance.tMaxC,
      't_min_c': ?instance.tMinC,
      'weather_code': ?instance.weatherCode,
      'wind_gust_kmh': ?instance.windGustKmh,
    };
