// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element_parameter

import 'package:json_annotation/json_annotation.dart';
import 'package:json_annotation/json_annotation.dart' as json;
import 'package:collection/collection.dart';

import 'dart:convert';

import 'bagmitra.models.swagger.dart';

import 'package:chopper/chopper.dart';

import 'client_mapping.dart';

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/http.dart' show MultipartFile;
import 'package:chopper/chopper.dart' as chopper;

import 'bagmitra.enums.swagger.dart' as enums;
import 'bagmitra.metadata.swagger.dart';
export 'bagmitra.enums.swagger.dart';
export 'bagmitra.models.swagger.dart';

part 'bagmitra.swagger.chopper.dart';

// **************************************************************************
// SwaggerChopperGenerator
// **************************************************************************

@ChopperApi()
abstract class Bagmitra extends ChopperService {
  static Bagmitra create({
    ChopperClient? client,
    http.Client? httpClient,
    Authenticator? authenticator,
    ErrorConverter? errorConverter,
    Converter? converter,
    Uri? baseUrl,
    List<Interceptor>? interceptors,
  }) {
    if (client != null) {
      return _$Bagmitra(client);
    }

    final newClient = ChopperClient(
      services: [_$Bagmitra()],
      converter: converter ?? $JsonSerializableConverter(),
      interceptors: interceptors ?? [],
      client: httpClient,
      authenticator: authenticator,
      errorConverter: errorConverter,
      baseUrl: baseUrl ?? Uri.parse('http://'),
    );
    return _$Bagmitra(newClient);
  }

  ///Live
  Future<chopper.Response<LiveResponse>> healthLiveGet() {
    generatedMapping.putIfAbsent(
      LiveResponse,
      () => LiveResponse.fromJsonFactory,
    );

    return _healthLiveGet();
  }

  ///Live
  @GET(path: '/health/live')
  Future<chopper.Response<LiveResponse>> _healthLiveGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Live',
      operationId: 'health_live',
      consumes: [],
      produces: [],
      security: [],
      tags: ["health"],
      deprecated: false,
    ),
  });

  ///Ready
  Future<chopper.Response<ReadyResponse>> healthReadyGet() {
    generatedMapping.putIfAbsent(
      ReadyResponse,
      () => ReadyResponse.fromJsonFactory,
    );

    return _healthReadyGet();
  }

  ///Ready
  @GET(path: '/health/ready')
  Future<chopper.Response<ReadyResponse>> _healthReadyGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Ready',
      operationId: 'health_ready',
      consumes: [],
      produces: [],
      security: [],
      tags: ["health"],
      deprecated: false,
    ),
  });

  ///Events
  ///@param limit
  Future<chopper.Response<EventsResponse>> v1AdminBillingEventsGet({
    int? limit,
  }) {
    generatedMapping.putIfAbsent(
      EventsResponse,
      () => EventsResponse.fromJsonFactory,
    );

    return _v1AdminBillingEventsGet(limit: limit);
  }

  ///Events
  ///@param limit
  @GET(path: '/v1/admin/billing/events')
  Future<chopper.Response<EventsResponse>> _v1AdminBillingEventsGet({
    @Query('limit') int? limit,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Events',
      operationId: 'admin_billing_events',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Grant
  Future<chopper.Response<SubscriptionOut>> v1AdminBillingGrantsPost({
    required GrantIn? body,
  }) {
    generatedMapping.putIfAbsent(
      SubscriptionOut,
      () => SubscriptionOut.fromJsonFactory,
    );

    return _v1AdminBillingGrantsPost(body: body);
  }

  ///Grant
  @POST(path: '/v1/admin/billing/grants', optionalBody: true)
  Future<chopper.Response<SubscriptionOut>> _v1AdminBillingGrantsPost({
    @Body() required GrantIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Grant',
      operationId: 'admin_billing_grant',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Revoke
  ///@param grant_id
  Future<chopper.Response<SubscriptionOut>>
  v1AdminBillingGrantsGrantIdRevokePost({required String? grantId}) {
    generatedMapping.putIfAbsent(
      SubscriptionOut,
      () => SubscriptionOut.fromJsonFactory,
    );

    return _v1AdminBillingGrantsGrantIdRevokePost(grantId: grantId);
  }

  ///Revoke
  ///@param grant_id
  @POST(path: '/v1/admin/billing/grants/{grant_id}/revoke', optionalBody: true)
  Future<chopper.Response<SubscriptionOut>>
  _v1AdminBillingGrantsGrantIdRevokePost({
    @Path('grant_id') required String? grantId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Revoke',
      operationId: 'admin_billing_revoke',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Plans
  Future<chopper.Response<PlansResponse>> v1AdminBillingPlansGet() {
    generatedMapping.putIfAbsent(
      PlansResponse,
      () => PlansResponse.fromJsonFactory,
    );

    return _v1AdminBillingPlansGet();
  }

  ///Plans
  @GET(path: '/v1/admin/billing/plans')
  Future<chopper.Response<PlansResponse>> _v1AdminBillingPlansGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Plans',
      operationId: 'admin_billing_plans',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Put Plan
  ///@param key
  Future<chopper.Response<PlanOut>> v1AdminBillingPlansKeyPut({
    required String? key,
    required PlanIn? body,
  }) {
    generatedMapping.putIfAbsent(PlanOut, () => PlanOut.fromJsonFactory);

    return _v1AdminBillingPlansKeyPut(key: key, body: body);
  }

  ///Put Plan
  ///@param key
  @PUT(path: '/v1/admin/billing/plans/{key}', optionalBody: true)
  Future<chopper.Response<PlanOut>> _v1AdminBillingPlansKeyPut({
    @Path('key') required String? key,
    @Body() required PlanIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Put Plan',
      operationId: 'admin_billing_put_plan',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Subscriptions
  ///@param subject_id
  Future<chopper.Response<SubscriptionsResponse>>
  v1AdminBillingSubscriptionsGet({String? subjectId}) {
    generatedMapping.putIfAbsent(
      SubscriptionsResponse,
      () => SubscriptionsResponse.fromJsonFactory,
    );

    return _v1AdminBillingSubscriptionsGet(subjectId: subjectId);
  }

  ///Subscriptions
  ///@param subject_id
  @GET(path: '/v1/admin/billing/subscriptions')
  Future<chopper.Response<SubscriptionsResponse>>
  _v1AdminBillingSubscriptionsGet({
    @Query('subject_id') String? subjectId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Subscriptions',
      operationId: 'admin_billing_subscriptions',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Items
  ///@param status
  Future<chopper.Response<FeedAdminItemsResponse>> v1AdminFeedItemsGet({
    enums.V1AdminFeedItemsGetStatus? status,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemsResponse,
      () => FeedAdminItemsResponse.fromJsonFactory,
    );

    return _v1AdminFeedItemsGet(status: status?.value?.toString());
  }

  ///Items
  ///@param status
  @GET(path: '/v1/admin/feed/items')
  Future<chopper.Response<FeedAdminItemsResponse>> _v1AdminFeedItemsGet({
    @Query('status') String? status,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'The review queue by default (`status=in_review`), newest first.',
      summary: 'Items',
      operationId: 'admin_feed_items',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Create Item
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsPost({
    required FeedAdminItemIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsPost(body: body);
  }

  ///Create Item
  @POST(path: '/v1/admin/feed/items', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>> _v1AdminFeedItemsPost({
    @Body() required FeedAdminItemIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Manual upload: metadata, optional document (hashed), optional text. Lands in review.',
      summary: 'Create Item',
      operationId: 'admin_feed_create_item',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Item Detail
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsItemIdGet({
    required String? itemId,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdGet(itemId: itemId);
  }

  ///Item Detail
  ///@param item_id
  @GET(path: '/v1/admin/feed/items/{item_id}')
  Future<chopper.Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdGet({
    @Path('item_id') required String? itemId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Item Detail',
      operationId: 'admin_feed_item',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Ai Draft
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsItemIdAiDraftPost({
    required String? itemId,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdAiDraftPost(itemId: itemId);
  }

  ///Ai Draft
  ///@param item_id
  @POST(path: '/v1/admin/feed/items/{item_id}/ai-draft', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>>
  _v1AdminFeedItemsItemIdAiDraftPost({
    @Path('item_id') required String? itemId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Classify and summarise the item\'s text into a review draft (AI off without
FEED_AI_API_KEY). Irrelevant documents move to `draft`, out of the queue.''',
      summary: 'Ai Draft',
      operationId: 'admin_feed_ai_draft',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Approve
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsItemIdApprovePost({
    required String? itemId,
    required FeedAdminApproveIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdApprovePost(itemId: itemId, body: body);
  }

  ///Approve
  ///@param item_id
  @POST(path: '/v1/admin/feed/items/{item_id}/approve', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>>
  _v1AdminFeedItemsItemIdApprovePost({
    @Path('item_id') required String? itemId,
    @Body() required FeedAdminApproveIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Approve',
      operationId: 'admin_feed_approve',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Set Card
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsItemIdCardPut({
    required String? itemId,
    required FeedAdminCardIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdCardPut(itemId: itemId, body: body);
  }

  ///Set Card
  ///@param item_id
  @PUT(path: '/v1/admin/feed/items/{item_id}/card', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdCardPut({
    @Path('item_id') required String? itemId,
    @Body() required FeedAdminCardIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Set Card',
      operationId: 'admin_feed_set_card',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Publish
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsItemIdPublishPost({
    required String? itemId,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdPublishPost(itemId: itemId);
  }

  ///Publish
  ///@param item_id
  @POST(path: '/v1/admin/feed/items/{item_id}/publish', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>>
  _v1AdminFeedItemsItemIdPublishPost({
    @Path('item_id') required String? itemId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Publish',
      operationId: 'admin_feed_publish',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Set Targets
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsItemIdTargetsPut({
    required String? itemId,
    required FeedAdminTargetsIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdTargetsPut(itemId: itemId, body: body);
  }

  ///Set Targets
  ///@param item_id
  @PUT(path: '/v1/admin/feed/items/{item_id}/targets', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdTargetsPut({
    @Path('item_id') required String? itemId,
    @Body() required FeedAdminTargetsIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Set Targets',
      operationId: 'admin_feed_set_targets',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Set Text
  ///@param item_id
  ///@param lang
  Future<chopper.Response<FeedAdminItemOut>>
  v1AdminFeedItemsItemIdTextsLangPut({
    required String? itemId,
    required enums.V1AdminFeedItemsItemIdTextsLangPutLang? lang,
    required FeedAdminTextIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdTextsLangPut(
      itemId: itemId,
      lang: lang?.value?.toString(),
      body: body,
    );
  }

  ///Set Text
  ///@param item_id
  ///@param lang
  @PUT(path: '/v1/admin/feed/items/{item_id}/texts/{lang}', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>>
  _v1AdminFeedItemsItemIdTextsLangPut({
    @Path('item_id') required String? itemId,
    @Path('lang') required String? lang,
    @Body() required FeedAdminTextIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Set Text',
      operationId: 'admin_feed_set_text',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Withdraw
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>>
  v1AdminFeedItemsItemIdWithdrawPost({
    required String? itemId,
    required FeedAdminWithdrawIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdWithdrawPost(itemId: itemId, body: body);
  }

  ///Withdraw
  ///@param item_id
  @POST(path: '/v1/admin/feed/items/{item_id}/withdraw', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>>
  _v1AdminFeedItemsItemIdWithdrawPost({
    @Path('item_id') required String? itemId,
    @Body() required FeedAdminWithdrawIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Withdraw',
      operationId: 'admin_feed_withdraw',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Sources
  Future<chopper.Response<FeedAdminSourcesResponse>> v1AdminFeedSourcesGet() {
    generatedMapping.putIfAbsent(
      FeedAdminSourcesResponse,
      () => FeedAdminSourcesResponse.fromJsonFactory,
    );

    return _v1AdminFeedSourcesGet();
  }

  ///Sources
  @GET(path: '/v1/admin/feed/sources')
  Future<chopper.Response<FeedAdminSourcesResponse>> _v1AdminFeedSourcesGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Sources',
      operationId: 'admin_feed_sources',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Set Terms
  ///@param key
  Future<chopper.Response<FeedAdminSourceOut>> v1AdminFeedSourcesKeyTermsPut({
    required String? key,
    required FeedAdminTermsIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminSourceOut,
      () => FeedAdminSourceOut.fromJsonFactory,
    );

    return _v1AdminFeedSourcesKeyTermsPut(key: key, body: body);
  }

  ///Set Terms
  ///@param key
  @PUT(path: '/v1/admin/feed/sources/{key}/terms', optionalBody: true)
  Future<chopper.Response<FeedAdminSourceOut>> _v1AdminFeedSourcesKeyTermsPut({
    @Path('key') required String? key,
    @Body() required FeedAdminTermsIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Record the owner\'s check of the source\'s terms of use and robots. Also clears a
recorded fetch failure, so the next scheduled run tries once more.''',
      summary: 'Set Terms',
      operationId: 'admin_feed_source_terms',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Alerts
  Future<chopper.Response<AlertsResponse>> v1AdminKbAlertsGet() {
    generatedMapping.putIfAbsent(
      AlertsResponse,
      () => AlertsResponse.fromJsonFactory,
    );

    return _v1AdminKbAlertsGet();
  }

  ///Alerts
  @GET(path: '/v1/admin/kb/alerts')
  Future<chopper.Response<AlertsResponse>> _v1AdminKbAlertsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Alerts',
      operationId: 'admin_kb_alerts',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Resolve Alert
  ///@param alert_id
  Future<chopper.Response<AlertOut>> v1AdminKbAlertsAlertIdResolvePost({
    required String? alertId,
  }) {
    generatedMapping.putIfAbsent(AlertOut, () => AlertOut.fromJsonFactory);

    return _v1AdminKbAlertsAlertIdResolvePost(alertId: alertId);
  }

  ///Resolve Alert
  ///@param alert_id
  @POST(path: '/v1/admin/kb/alerts/{alert_id}/resolve', optionalBody: true)
  Future<chopper.Response<AlertOut>> _v1AdminKbAlertsAlertIdResolvePost({
    @Path('alert_id') required String? alertId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Resolve Alert',
      operationId: 'admin_kb_resolve_alert',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Cards
  ///@param status
  Future<chopper.Response<CardsResponse>> v1AdminKbCardsGet({String? status}) {
    generatedMapping.putIfAbsent(
      CardsResponse,
      () => CardsResponse.fromJsonFactory,
    );

    return _v1AdminKbCardsGet(status: status);
  }

  ///Cards
  ///@param status
  @GET(path: '/v1/admin/kb/cards')
  Future<chopper.Response<CardsResponse>> _v1AdminKbCardsGet({
    @Query('status') String? status,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Cards',
      operationId: 'admin_kb_cards',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Publish Card
  ///@param card_id
  Future<chopper.Response<CardOut>> v1AdminKbCardsCardIdPublishPost({
    required String? cardId,
  }) {
    generatedMapping.putIfAbsent(CardOut, () => CardOut.fromJsonFactory);

    return _v1AdminKbCardsCardIdPublishPost(cardId: cardId);
  }

  ///Publish Card
  ///@param card_id
  @POST(path: '/v1/admin/kb/cards/{card_id}/publish', optionalBody: true)
  Future<chopper.Response<CardOut>> _v1AdminKbCardsCardIdPublishPost({
    @Path('card_id') required String? cardId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Publish Card',
      operationId: 'admin_kb_publish',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Review
  ///@param card_id
  Future<chopper.Response<CardOut>> v1AdminKbCardsCardIdReviewsPost({
    required String? cardId,
    required ReviewIn? body,
  }) {
    generatedMapping.putIfAbsent(CardOut, () => CardOut.fromJsonFactory);

    return _v1AdminKbCardsCardIdReviewsPost(cardId: cardId, body: body);
  }

  ///Review
  ///@param card_id
  @POST(path: '/v1/admin/kb/cards/{card_id}/reviews', optionalBody: true)
  Future<chopper.Response<CardOut>> _v1AdminKbCardsCardIdReviewsPost({
    @Path('card_id') required String? cardId,
    @Body() required ReviewIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Review',
      operationId: 'admin_kb_review',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Run Import
  ///@param kind
  Future<chopper.Response<ImportOut>> v1AdminKbImportsKindPost({
    required enums.V1AdminKbImportsKindPostKind? kind,
    required ImportIn? body,
  }) {
    generatedMapping.putIfAbsent(ImportOut, () => ImportOut.fromJsonFactory);

    return _v1AdminKbImportsKindPost(kind: kind?.value?.toString(), body: body);
  }

  ///Run Import
  ///@param kind
  @POST(path: '/v1/admin/kb/imports/{kind}', optionalBody: true)
  Future<chopper.Response<ImportOut>> _v1AdminKbImportsKindPost({
    @Path('kind') required String? kind,
    @Body() required ImportIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Run Import',
      operationId: 'admin_kb_import',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Sources
  Future<chopper.Response<SourcesResponse>> v1AdminKbSourcesGet() {
    generatedMapping.putIfAbsent(
      SourcesResponse,
      () => SourcesResponse.fromJsonFactory,
    );

    return _v1AdminKbSourcesGet();
  }

  ///Sources
  @GET(path: '/v1/admin/kb/sources')
  Future<chopper.Response<SourcesResponse>> _v1AdminKbSourcesGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Sources',
      operationId: 'admin_kb_sources',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Upload Source Document
  ///@param key
  Future<chopper.Response<SourceOut>> v1AdminKbSourcesKeyDocumentPut({
    required String? key,
  }) {
    generatedMapping.putIfAbsent(SourceOut, () => SourceOut.fromJsonFactory);

    return _v1AdminKbSourcesKeyDocumentPut(key: key);
  }

  ///Upload Source Document
  ///@param key
  @PUT(path: '/v1/admin/kb/sources/{key}/document', optionalBody: true)
  Future<chopper.Response<SourceOut>> _v1AdminKbSourcesKeyDocumentPut({
    @Path('key') required String? key,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Record a document an admin downloaded by hand (the server could not fetch it). The body
is the raw file; only its hash, size and time are kept.''',
      summary: 'Upload Source Document',
      operationId: 'admin_kb_upload_source_document',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Upload Prices
  Future<chopper.Response<ManualPricesOut>> v1AdminMarketPricesPost({
    required ManualPricesIn? body,
  }) {
    generatedMapping.putIfAbsent(
      ManualPricesOut,
      () => ManualPricesOut.fromJsonFactory,
    );

    return _v1AdminMarketPricesPost(body: body);
  }

  ///Upload Prices
  @POST(path: '/v1/admin/market/prices', optionalBody: true)
  Future<chopper.Response<ManualPricesOut>> _v1AdminMarketPricesPost({
    @Body() required ManualPricesIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Store prices typed in from a mandi\'s published rate list (same day and mandi replace).',
      summary: 'Upload Prices',
      operationId: 'admin_market_prices_upload',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Entitlements
  Future<chopper.Response<EntitlementsResponse>> v1BillingEntitlementsGet() {
    generatedMapping.putIfAbsent(
      EntitlementsResponse,
      () => EntitlementsResponse.fromJsonFactory,
    );

    return _v1BillingEntitlementsGet();
  }

  ///Entitlements
  @GET(path: '/v1/billing/entitlements')
  Future<chopper.Response<EntitlementsResponse>> _v1BillingEntitlementsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Entitlements',
      operationId: 'billing_entitlements',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["billing"],
      deprecated: false,
    ),
  });

  ///Feed
  ///@param lang
  ///@param type
  ///@param district
  ///@param crop
  Future<chopper.Response<FeedResponse>> v1FeedGet({
    enums.V1FeedGetLang? lang,
    String? type,
    String? district,
    String? crop,
  }) {
    generatedMapping.putIfAbsent(
      FeedResponse,
      () => FeedResponse.fromJsonFactory,
    );

    return _v1FeedGet(
      lang: lang?.value?.toString(),
      type: type,
      district: district,
      crop: crop,
    );
  }

  ///Feed
  ///@param lang
  ///@param type
  ///@param district
  ///@param crop
  @GET(path: '/v1/feed')
  Future<chopper.Response<FeedResponse>> _v1FeedGet({
    @Query('lang') String? lang,
    @Query('type') String? type,
    @Query('district') String? district,
    @Query('crop') String? crop,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Newest first. `district` / `crop` narrow the list to items meant for them (items for
everyone always pass); `may_be_eligible_because` is computed from the caller\'s own
profile and plots.''',
      summary: 'Feed',
      operationId: 'feed_list',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feed"],
      deprecated: false,
    ),
  });

  ///Check
  ///@param lang
  Future<chopper.Response<FeedCheckResponse>> v1FeedCheckPost({
    enums.V1FeedCheckPostLang? lang,
    required FeedCheckIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedCheckResponse,
      () => FeedCheckResponse.fromJsonFactory,
    );

    return _v1FeedCheckPost(lang: lang?.value?.toString(), body: body);
  }

  ///Check
  ///@param lang
  @POST(path: '/v1/feed/check', optionalBody: true)
  Future<chopper.Response<FeedCheckResponse>> _v1FeedCheckPost({
    @Query('lang') String? lang,
    @Body() required FeedCheckIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Compares the pasted text with published official items only. Never says a message is
fake: without a match the note says none was found and points to the official portal.''',
      summary: 'Check',
      operationId: 'feed_check',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feed"],
      deprecated: false,
    ),
  });

  ///Dismiss
  ///@param item_id
  Future<chopper.Response<FeedReceiptOut>> v1FeedItemIdDismissPost({
    required String? itemId,
  }) {
    generatedMapping.putIfAbsent(
      FeedReceiptOut,
      () => FeedReceiptOut.fromJsonFactory,
    );

    return _v1FeedItemIdDismissPost(itemId: itemId);
  }

  ///Dismiss
  ///@param item_id
  @POST(path: '/v1/feed/{item_id}/dismiss', optionalBody: true)
  Future<chopper.Response<FeedReceiptOut>> _v1FeedItemIdDismissPost({
    @Path('item_id') required String? itemId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Hide the item from the caller\'s pushes (reminders and digest stop for it).',
      summary: 'Dismiss',
      operationId: 'feed_dismiss',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feed"],
      deprecated: false,
    ),
  });

  ///Remind
  ///@param item_id
  Future<chopper.Response<FeedReceiptOut>> v1FeedItemIdRemindPost({
    required String? itemId,
  }) {
    generatedMapping.putIfAbsent(
      FeedReceiptOut,
      () => FeedReceiptOut.fromJsonFactory,
    );

    return _v1FeedItemIdRemindPost(itemId: itemId);
  }

  ///Remind
  ///@param item_id
  @POST(path: '/v1/feed/{item_id}/remind', optionalBody: true)
  Future<chopper.Response<FeedReceiptOut>> _v1FeedItemIdRemindPost({
    @Path('item_id') required String? itemId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Record that the caller wants this item\'s date reminders even if it was not matched to
their profile; undoes a dismiss. Only for a published item that has a date.''',
      summary: 'Remind',
      operationId: 'feed_remind',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feed"],
      deprecated: false,
    ),
  });

  ///Mark Seen
  ///@param item_id
  Future<chopper.Response<FeedReceiptOut>> v1FeedItemIdSeenPost({
    required String? itemId,
  }) {
    generatedMapping.putIfAbsent(
      FeedReceiptOut,
      () => FeedReceiptOut.fromJsonFactory,
    );

    return _v1FeedItemIdSeenPost(itemId: itemId);
  }

  ///Mark Seen
  ///@param item_id
  @POST(path: '/v1/feed/{item_id}/seen', optionalBody: true)
  Future<chopper.Response<FeedReceiptOut>> _v1FeedItemIdSeenPost({
    @Path('item_id') required String? itemId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Mark Seen',
      operationId: 'feed_mark_seen',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feed"],
      deprecated: false,
    ),
  });

  ///Get Market Prices
  ///@param crop
  ///@param scope
  Future<chopper.Response<MarketPrices>> v1MarketPricesGet({
    required String? crop,
    enums.V1MarketPricesGetScope? scope,
  }) {
    generatedMapping.putIfAbsent(
      MarketPrices,
      () => MarketPrices.fromJsonFactory,
    );

    return _v1MarketPricesGet(crop: crop, scope: scope?.value?.toString());
  }

  ///Get Market Prices
  ///@param crop
  ///@param scope
  @GET(path: '/v1/market/prices')
  Future<chopper.Response<MarketPrices>> _v1MarketPricesGet({
    @Query('crop') required String? crop,
    @Query('scope') String? scope,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Latest published price (₹ per quintal) at every reporting mandi in India for the crop:
the local APMCs first, then the major terminal markets, then all others by state. Prices
are shown as published, never estimated; `stale` says the source could not be reached and
`reason` says why. `scope` narrows the list to local or major mandis.''',
      summary: 'Get Market Prices',
      operationId: 'market_prices_get',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market"],
      deprecated: false,
    ),
  });

  ///Get Me
  Future<chopper.Response<FarmerProfile>> v1MeGet() {
    generatedMapping.putIfAbsent(
      FarmerProfile,
      () => FarmerProfile.fromJsonFactory,
    );

    return _v1MeGet();
  }

  ///Get Me
  @GET(path: '/v1/me')
  Future<chopper.Response<FarmerProfile>> _v1MeGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Me',
      operationId: 'me_get',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["profile"],
      deprecated: false,
    ),
  });

  ///Unregister Device
  Future<chopper.Response> v1MeDevicesDelete({required DeviceOut? body}) {
    return _v1MeDevicesDelete(body: body);
  }

  ///Unregister Device
  @DELETE(path: '/v1/me/devices')
  Future<chopper.Response> _v1MeDevicesDelete({
    @Body() required DeviceOut? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Stop push alerts to this phone (sign-out); unknown tokens are ignored.',
      summary: 'Unregister Device',
      operationId: 'me_device_unregister',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["profile"],
      deprecated: false,
    ),
  });

  ///Register Device
  Future<chopper.Response> v1MeDevicesPost({required DeviceIn? body}) {
    return _v1MeDevicesPost(body: body);
  }

  ///Register Device
  @POST(path: '/v1/me/devices', optionalBody: true)
  Future<chopper.Response> _v1MeDevicesPost({
    @Body() required DeviceIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Register this phone for push alerts; repeating it is harmless.',
      summary: 'Register Device',
      operationId: 'me_device_register',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["profile"],
      deprecated: false,
    ),
  });

  ///Get Preferences
  Future<chopper.Response<FeedPreferencesBody>> v1MeFeedPreferencesGet() {
    generatedMapping.putIfAbsent(
      FeedPreferencesBody,
      () => FeedPreferencesBody.fromJsonFactory,
    );

    return _v1MeFeedPreferencesGet();
  }

  ///Get Preferences
  @GET(path: '/v1/me/feed-preferences')
  Future<chopper.Response<FeedPreferencesBody>> _v1MeFeedPreferencesGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The caller\'s settings, or the defaults (21:00-07:00, 3 a week, digest on).',
      summary: 'Get Preferences',
      operationId: 'feed_preferences_get',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feed"],
      deprecated: false,
    ),
  });

  ///Put Preferences
  Future<chopper.Response<FeedPreferencesBody>> v1MeFeedPreferencesPut({
    required FeedPreferencesBody? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedPreferencesBody,
      () => FeedPreferencesBody.fromJsonFactory,
    );

    return _v1MeFeedPreferencesPut(body: body);
  }

  ///Put Preferences
  @PUT(path: '/v1/me/feed-preferences', optionalBody: true)
  Future<chopper.Response<FeedPreferencesBody>> _v1MeFeedPreferencesPut({
    @Body() required FeedPreferencesBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Put Preferences',
      operationId: 'feed_preferences_put',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feed"],
      deprecated: false,
    ),
  });

  ///Get Plot Weather
  ///@param plot_id
  ///@param lang
  Future<chopper.Response<PlotWeather>> v1PlotsPlotIdWeatherGet({
    required String? plotId,
    String? lang,
  }) {
    generatedMapping.putIfAbsent(
      PlotWeather,
      () => PlotWeather.fromJsonFactory,
    );

    return _v1PlotsPlotIdWeatherGet(plotId: plotId, lang: lang);
  }

  ///Get Plot Weather
  ///@param plot_id
  ///@param lang
  @GET(path: '/v1/plots/{plot_id}/weather')
  Future<chopper.Response<PlotWeather>> _v1PlotsPlotIdWeatherGet({
    @Path('plot_id') required String? plotId,
    @Query('lang') String? lang,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Recent and forecast days for the plot\'s location, with rule-based risk alerts.

Alerts come only from the configured rules (never from AI) and carry no chemical advice.''',
      summary: 'Get Plot Weather',
      operationId: 'plot_weather_get',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["weather"],
      deprecated: false,
    ),
  });

  ///Label Claims
  ///@param crop
  ///@param target
  Future<chopper.Response<LabelClaimsResponse>> v1ReferenceLabelClaimsGet({
    required String? crop,
    String? target,
  }) {
    generatedMapping.putIfAbsent(
      LabelClaimsResponse,
      () => LabelClaimsResponse.fromJsonFactory,
    );

    return _v1ReferenceLabelClaimsGet(crop: crop, target: target);
  }

  ///Label Claims
  ///@param crop
  ///@param target
  @GET(path: '/v1/reference/label-claims')
  Future<chopper.Response<LabelClaimsResponse>> _v1ReferenceLabelClaimsGet({
    @Query('crop') required String? crop,
    @Query('target') String? target,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''What CIB&RC registered labels say for the crop (owner, 2026-10-26: label information
only). Only claims valid today whose active ingredient is neither banned nor restricted
for the crop pass the legal gate; doses are quoted exactly as the label states them.
The app shows this as label information with "read the label; confirm with KVK", never
as BagMitra\'s own advice.''',
      summary: 'Label Claims',
      operationId: 'reference_label_claims',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["reference"],
      deprecated: false,
    ),
  });

  ///Restrictions
  Future<chopper.Response<RestrictionsResponse>> v1ReferenceRestrictionsGet() {
    generatedMapping.putIfAbsent(
      RestrictionsResponse,
      () => RestrictionsResponse.fromJsonFactory,
    );

    return _v1ReferenceRestrictionsGet();
  }

  ///Restrictions
  @GET(path: '/v1/reference/restrictions')
  Future<chopper.Response<RestrictionsResponse>> _v1ReferenceRestrictionsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Gazette bans / restrictions and trade names, cached by the app so spray records can
be checked offline. Facts only; no advice text.''',
      summary: 'Restrictions',
      operationId: 'reference_restrictions',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["reference"],
      deprecated: false,
    ),
  });

  ///Stage Templates
  ///@param crop
  Future<chopper.Response<StageTemplatesResponse>>
  v1ReferenceStageTemplatesGet({String? crop}) {
    generatedMapping.putIfAbsent(
      StageTemplatesResponse,
      () => StageTemplatesResponse.fromJsonFactory,
    );

    return _v1ReferenceStageTemplatesGet(crop: crop);
  }

  ///Stage Templates
  ///@param crop
  @GET(path: '/v1/reference/stage-templates')
  Future<chopper.Response<StageTemplatesResponse>>
  _v1ReferenceStageTemplatesGet({
    @Query('crop') String? crop,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Stage Templates',
      operationId: 'reference_stage_templates',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["reference"],
      deprecated: false,
    ),
  });

  ///Create Photo Upload Url
  ///@param record_id
  Future<chopper.Response<PhotoUploadUrl>>
  v1ScoutingRecordIdPhotoUploadUrlPost({
    required String? recordId,
    required PhotoUploadIn? body,
  }) {
    generatedMapping.putIfAbsent(
      PhotoUploadUrl,
      () => PhotoUploadUrl.fromJsonFactory,
    );

    return _v1ScoutingRecordIdPhotoUploadUrlPost(
      recordId: recordId,
      body: body,
    );
  }

  ///Create Photo Upload Url
  ///@param record_id
  @POST(path: '/v1/scouting/{record_id}/photo-upload-url', optionalBody: true)
  Future<chopper.Response<PhotoUploadUrl>>
  _v1ScoutingRecordIdPhotoUploadUrlPost({
    @Path('record_id') required String? recordId,
    @Body() required PhotoUploadIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''A signed upload URL for this record\'s photo (JPEG only, at most `max_bytes`).

The phone PUTs the file to `upload_url` with `Content-Type: image/jpeg`, then records
`photo_key` on the scouting record through the normal outbox.''',
      summary: 'Create Photo Upload Url',
      operationId: 'scouting_photo_upload_url',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["scouting"],
      deprecated: false,
    ),
  });

  ///Get Photo Url
  ///@param record_id
  Future<chopper.Response<PhotoDownloadUrl>> v1ScoutingRecordIdPhotoUrlGet({
    required String? recordId,
  }) {
    generatedMapping.putIfAbsent(
      PhotoDownloadUrl,
      () => PhotoDownloadUrl.fromJsonFactory,
    );

    return _v1ScoutingRecordIdPhotoUrlGet(recordId: recordId);
  }

  ///Get Photo Url
  ///@param record_id
  @GET(path: '/v1/scouting/{record_id}/photo-url')
  Future<chopper.Response<PhotoDownloadUrl>> _v1ScoutingRecordIdPhotoUrlGet({
    @Path('record_id') required String? recordId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'A short-lived signed download URL for a backed-up photo.',
      summary: 'Get Photo Url',
      operationId: 'scouting_photo_url',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["scouting"],
      deprecated: false,
    ),
  });

  ///Pull
  ///@param since
  Future<chopper.Response<PullResponse>> v1SyncPullGet({int? since}) {
    generatedMapping.putIfAbsent(
      PullResponse,
      () => PullResponse.fromJsonFactory,
    );

    return _v1SyncPullGet(since: since);
  }

  ///Pull
  ///@param since
  @GET(path: '/v1/sync/pull')
  Future<chopper.Response<PullResponse>> _v1SyncPullGet({
    @Query('since') int? since,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Pull',
      operationId: 'sync_pull',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["sync"],
      deprecated: false,
    ),
  });

  ///Push
  Future<chopper.Response<PushResponse>> v1SyncPushPost({
    required PushRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      PushResponse,
      () => PushResponse.fromJsonFactory,
    );

    return _v1SyncPushPost(body: body);
  }

  ///Push
  @POST(path: '/v1/sync/push', optionalBody: true)
  Future<chopper.Response<PushResponse>> _v1SyncPushPost({
    @Body() required PushRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Apply a batch of offline mutations. Each mutation gets its own result; the batch
never fails as a whole because of one bad mutation.''',
      summary: 'Push',
      operationId: 'sync_push',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["sync"],
      deprecated: false,
    ),
  });
}

typedef $JsonFactory<T> = T Function(Map<String, dynamic> json);

class $CustomJsonDecoder {
  $CustomJsonDecoder(this.factories);

  final Map<Type, $JsonFactory> factories;

  dynamic decode<T>(dynamic entity) {
    if (entity is Iterable) {
      return _decodeList<T>(entity);
    }

    if (entity is T) {
      return entity;
    }

    if (isTypeOf<T, Map>()) {
      return entity;
    }

    if (isTypeOf<T, Iterable>()) {
      return entity;
    }

    if (entity is Map<String, dynamic>) {
      return _decodeMap<T>(entity);
    }

    return entity;
  }

  T _decodeMap<T>(Map<String, dynamic> values) {
    final jsonFactory = factories[T];
    if (jsonFactory == null || jsonFactory is! $JsonFactory<T>) {
      return throw "Could not find factory for type $T. Is '$T: $T.fromJsonFactory' included in the CustomJsonDecoder instance creation in bootstrapper.dart?";
    }

    return jsonFactory(values);
  }

  List<T> _decodeList<T>(Iterable values) =>
      values.where((v) => v != null).map<T>((v) => decode<T>(v) as T).toList();
}

class $JsonSerializableConverter extends chopper.JsonConverter {
  @override
  FutureOr<chopper.Response<ResultType>> convertResponse<ResultType, Item>(
    chopper.Response response,
  ) async {
    if (response.bodyString.isEmpty) {
      // In rare cases, when let's say 204 (no content) is returned -
      // we cannot decode the missing json with the result type specified
      return chopper.Response(response.base, null, error: response.error);
    }

    if (ResultType == String) {
      return response.copyWith();
    }

    if (ResultType == DateTime) {
      return response.copyWith(
        body: DateTime.parse(
          (response.body as String).replaceAll('"', ''),
        ) as ResultType,
      );
    }

    final jsonRes = await super.convertResponse(response);
    return jsonRes.copyWith<ResultType>(
      body: $jsonDecoder.decode<Item>(jsonRes.body) as ResultType,
    );
  }
}

final $jsonDecoder = $CustomJsonDecoder(generatedMapping);
