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

  ///Set Dates
  ///@param item_id
  Future<chopper.Response<FeedAdminItemOut>> v1AdminFeedItemsItemIdDatesPut({
    required String? itemId,
    required FeedAdminDatesIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedAdminItemOut,
      () => FeedAdminItemOut.fromJsonFactory,
    );

    return _v1AdminFeedItemsItemIdDatesPut(itemId: itemId, body: body);
  }

  ///Set Dates
  ///@param item_id
  @PUT(path: '/v1/admin/feed/items/{item_id}/dates', optionalBody: true)
  Future<chopper.Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdDatesPut({
    @Path('item_id') required String? itemId,
    @Body() required FeedAdminDatesIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Replace deadline / payment / validity dates (a missing or `null` date is cleared). The
dates are output-checked against the stored text; a change to a published item clears its
approval and sends it back to review (an `edited` event with `reopened: true`); the
farmer-facing deadlines are rebuilt when it is published again. Withdrawn: 409.''',
      summary: 'Set Dates',
      operationId: 'admin_feed_set_dates',
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

  ///Admin Add Provider
  Future<chopper.Response<MyProfileOut>> v1AdminMarketLinkProvidersPost({
    required AdminProviderIn? body,
  }) {
    generatedMapping.putIfAbsent(
      MyProfileOut,
      () => MyProfileOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkProvidersPost(body: body);
  }

  ///Admin Add Provider
  @POST(path: '/v1/admin/market-link/providers', optionalBody: true)
  Future<chopper.Response<MyProfileOut>> _v1AdminMarketLinkProvidersPost({
    @Body() required AdminProviderIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Admin adds a provider it knows (no account of its own, spec §2); it waits in the queue
for a decision like any other (Q72).''',
      summary: 'Admin Add Provider',
      operationId: 'admin_market_link_provider_add',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Rating Tags
  Future<chopper.Response<RatingTagsAdminResponse>>
  v1AdminMarketLinkRatingTagsGet() {
    generatedMapping.putIfAbsent(
      RatingTagsAdminResponse,
      () => RatingTagsAdminResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkRatingTagsGet();
  }

  ///Rating Tags
  @GET(path: '/v1/admin/market-link/rating-tags')
  Future<chopper.Response<RatingTagsAdminResponse>>
  _v1AdminMarketLinkRatingTagsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Every tag, drafts and retired ones included.',
      summary: 'Rating Tags',
      operationId: 'admin_market_link_rating_tags',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Update Rating Tag
  ///@param tag_id
  Future<chopper.Response<RatingTagAdminOut>>
  v1AdminMarketLinkRatingTagsTagIdPut({
    required String? tagId,
    required RatingTagIn? body,
  }) {
    generatedMapping.putIfAbsent(
      RatingTagAdminOut,
      () => RatingTagAdminOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkRatingTagsTagIdPut(tagId: tagId, body: body);
  }

  ///Update Rating Tag
  ///@param tag_id
  @PUT(path: '/v1/admin/market-link/rating-tags/{tag_id}', optionalBody: true)
  Future<chopper.Response<RatingTagAdminOut>>
  _v1AdminMarketLinkRatingTagsTagIdPut({
    @Path('tag_id') required String? tagId,
    @Body() required RatingTagIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Edit the three labels and set draft / active / retired (spec §3A: admin only).',
      summary: 'Update Rating Tag',
      operationId: 'admin_market_link_rating_tag_update',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Queue
  ///@param subject_type
  Future<chopper.Response<QueueResponse>> v1AdminMarketLinkVerificationsGet({
    String? subjectType,
  }) {
    generatedMapping.putIfAbsent(
      QueueResponse,
      () => QueueResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkVerificationsGet(subjectType: subjectType);
  }

  ///Queue
  ///@param subject_type
  @GET(path: '/v1/admin/market-link/verifications')
  Future<chopper.Response<QueueResponse>> _v1AdminMarketLinkVerificationsGet({
    @Query('subject_type') String? subjectType,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Subjects waiting for a check (latest record pending, or none yet), oldest first.',
      summary: 'Queue',
      operationId: 'admin_market_link_queue',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Subject History
  ///@param subject_type
  ///@param subject_id
  Future<chopper.Response<SubjectDetailOut>>
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGet({
    required enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType?
    subjectType,
    required String? subjectId,
  }) {
    generatedMapping.putIfAbsent(
      SubjectDetailOut,
      () => SubjectDetailOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGet(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
    );
  }

  ///Subject History
  ///@param subject_type
  ///@param subject_id
  @GET(path: '/v1/admin/market-link/verifications/{subject_type}/{subject_id}')
  Future<chopper.Response<SubjectDetailOut>>
  _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGet({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The subject\'s submitted fields, documents and every verification record.',
      summary: 'Subject History',
      operationId: 'admin_market_link_subject',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Decide
  ///@param subject_type
  ///@param subject_id
  Future<chopper.Response<SubjectDetailOut>>
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPost({
    required enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType?
    subjectType,
    required String? subjectId,
    required DecisionIn? body,
  }) {
    generatedMapping.putIfAbsent(
      SubjectDetailOut,
      () => SubjectDetailOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPost(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
      body: body,
    );
  }

  ///Decide
  ///@param subject_type
  ///@param subject_id
  @POST(
    path: '/v1/admin/market-link/verifications/{subject_type}/{subject_id}/decision',
    optionalBody: true,
  )
  Future<chopper.Response<SubjectDetailOut>>
  _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPost({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @Body() required DecisionIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Approve, or reject with a reason: always a new record with who and when (Q70).',
      summary: 'Decide',
      operationId: 'admin_market_link_decide',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Document Url
  ///@param subject_type
  ///@param subject_id
  ///@param index
  Future<chopper.Response<PhotoDownloadUrl>>
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGet({
    required enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType?
    subjectType,
    required String? subjectId,
    required int? index,
  }) {
    generatedMapping.putIfAbsent(
      PhotoDownloadUrl,
      () => PhotoDownloadUrl.fromJsonFactory,
    );

    return _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGet(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
      index: index,
    );
  }

  ///Document Url
  ///@param subject_type
  ///@param subject_id
  ///@param index
  @GET(
    path: '/v1/admin/market-link/verifications/{subject_type}/{subject_id}/documents/{index}/url',
  )
  Future<chopper.Response<PhotoDownloadUrl>>
  _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGet({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @Path('index') required int? index,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'A short-lived signed URL for one stored document; only keys on record are signed.',
      summary: 'Document Url',
      operationId: 'admin_market_link_document_url',
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

  ///App Version
  Future<chopper.Response<AppVersionResponse>> v1AppVersionGet() {
    generatedMapping.putIfAbsent(
      AppVersionResponse,
      () => AppVersionResponse.fromJsonFactory,
    );

    return _v1AppVersionGet();
  }

  ///App Version
  @GET(path: '/v1/app/version')
  Future<chopper.Response<AppVersionResponse>> _v1AppVersionGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Latest and minimum app version codes (0 = not set) and where to download the APK.',
      summary: 'App Version',
      operationId: 'app_version',
      consumes: [],
      produces: [],
      security: [],
      tags: ["app"],
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

  ///Deadlines
  ///@param lang
  Future<chopper.Response<InsuranceDeadlinesResponse>> v1InsuranceDeadlinesGet({
    enums.V1InsuranceDeadlinesGetLang? lang,
  }) {
    generatedMapping.putIfAbsent(
      InsuranceDeadlinesResponse,
      () => InsuranceDeadlinesResponse.fromJsonFactory,
    );

    return _v1InsuranceDeadlinesGet(lang: lang?.value?.toString());
  }

  ///Deadlines
  ///@param lang
  @GET(path: '/v1/insurance/deadlines')
  Future<chopper.Response<InsuranceDeadlinesResponse>>
  _v1InsuranceDeadlinesGet({
    @Query('lang') String? lang,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Enrolment dates of published official crop insurance notices, soonest first.',
      summary: 'Deadlines',
      operationId: 'insurance_deadlines',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["insurance"],
      deprecated: false,
    ),
  });

  ///Cards
  ///@param crop
  Future<chopper.Response<GrowerCardsResponse>> v1KnowledgeCardsGet({
    String? crop,
  }) {
    generatedMapping.putIfAbsent(
      GrowerCardsResponse,
      () => GrowerCardsResponse.fromJsonFactory,
    );

    return _v1KnowledgeCardsGet(crop: crop);
  }

  ///Cards
  ///@param crop
  @GET(path: '/v1/knowledge/cards')
  Future<chopper.Response<GrowerCardsResponse>> _v1KnowledgeCardsGet({
    @Query('crop') String? crop,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The general part of every live knowledge card (newest version per topic and crop).',
      summary: 'Cards',
      operationId: 'knowledge_cards',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["knowledge"],
      deprecated: false,
    ),
  });

  ///Register Broker
  Future<chopper.Response<MyProfileOut>> v1MarketLinkBrokersPost({
    required BrokerIn? body,
  }) {
    generatedMapping.putIfAbsent(
      MyProfileOut,
      () => MyProfileOut.fromJsonFactory,
    );

    return _v1MarketLinkBrokersPost(body: body);
  }

  ///Register Broker
  @POST(path: '/v1/market-link/brokers', optionalBody: true)
  Future<chopper.Response<MyProfileOut>> _v1MarketLinkBrokersPost({
    @Body() required BrokerIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Broker (मध्यस्थ (दलाल)) registration: phone sign-in + GPS fix; the admin then calls
(spec §4 broker rule; no photo ID, no place photo needed).''',
      summary: 'Register Broker',
      operationId: 'market_link_register_broker',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Introduction
  ///@param deal_id
  Future<chopper.Response<IntroductionOut>> v1MarketLinkDealsDealIdGet({
    required String? dealId,
  }) {
    generatedMapping.putIfAbsent(
      IntroductionOut,
      () => IntroductionOut.fromJsonFactory,
    );

    return _v1MarketLinkDealsDealIdGet(dealId: dealId);
  }

  ///Introduction
  ///@param deal_id
  @GET(path: '/v1/market-link/deals/{deal_id}')
  Future<chopper.Response<IntroductionOut>> _v1MarketLinkDealsDealIdGet({
    @Path('deal_id') required String? dealId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The introduction, for its grower, trader and broker only (404 for anyone else).',
      summary: 'Introduction',
      operationId: 'market_link_introduction',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Deal Done
  ///@param deal_id
  Future<chopper.Response<IntroductionOut>> v1MarketLinkDealsDealIdDonePost({
    required String? dealId,
  }) {
    generatedMapping.putIfAbsent(
      IntroductionOut,
      () => IntroductionOut.fromJsonFactory,
    );

    return _v1MarketLinkDealsDealIdDonePost(dealId: dealId);
  }

  ///Deal Done
  ///@param deal_id
  @POST(path: '/v1/market-link/deals/{deal_id}/done', optionalBody: true)
  Future<chopper.Response<IntroductionOut>> _v1MarketLinkDealsDealIdDonePost({
    @Path('deal_id') required String? dealId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''The grower or the trader says the deal is done (a repeat tap changes nothing). When
both have tapped, the deal is completed and rating opens for 7 days (Q66, Q67).''',
      summary: 'Deal Done',
      operationId: 'market_link_deal_done',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Deal Ratings
  ///@param deal_id
  Future<chopper.Response<DealRatingsOut>> v1MarketLinkDealsDealIdRatingsGet({
    required String? dealId,
  }) {
    generatedMapping.putIfAbsent(
      DealRatingsOut,
      () => DealRatingsOut.fromJsonFactory,
    );

    return _v1MarketLinkDealsDealIdRatingsGet(dealId: dealId);
  }

  ///Deal Ratings
  ///@param deal_id
  @GET(path: '/v1/market-link/deals/{deal_id}/ratings')
  Future<chopper.Response<DealRatingsOut>> _v1MarketLinkDealsDealIdRatingsGet({
    @Path('deal_id') required String? dealId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The caller\'s ratings on this deal, the questions to answer and the window.',
      summary: 'Deal Ratings',
      operationId: 'market_link_deal_ratings',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Rate
  ///@param deal_id
  ///@param ratee_role
  Future<chopper.Response<DealRatingsOut>>
  v1MarketLinkDealsDealIdRatingsRateeRolePut({
    required String? dealId,
    required enums.V1MarketLinkDealsDealIdRatingsRateeRolePutRateeRole?
    rateeRole,
    required RatingIn? body,
  }) {
    generatedMapping.putIfAbsent(
      DealRatingsOut,
      () => DealRatingsOut.fromJsonFactory,
    );

    return _v1MarketLinkDealsDealIdRatingsRateeRolePut(
      dealId: dealId,
      rateeRole: rateeRole?.value?.toString(),
      body: body,
    );
  }

  ///Rate
  ///@param deal_id
  ///@param ratee_role
  @PUT(
    path: '/v1/market-link/deals/{deal_id}/ratings/{ratee_role}',
    optionalBody: true,
  )
  Future<chopper.Response<DealRatingsOut>>
  _v1MarketLinkDealsDealIdRatingsRateeRolePut({
    @Path('deal_id') required String? dealId,
    @Path('ratee_role') required String? rateeRole,
    @Body() required RatingIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Give or change the caller\'s rating of one party of a completed deal: every question
of that role once. Only within 7 days of completion, then 409 `rating_locked`.''',
      summary: 'Rate',
      operationId: 'market_link_rate',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Register Exporter
  Future<chopper.Response<MyProfileOut>> v1MarketLinkExportersPost({
    required BuyerIn? body,
  }) {
    generatedMapping.putIfAbsent(
      MyProfileOut,
      () => MyProfileOut.fromJsonFactory,
    );

    return _v1MarketLinkExportersPost(body: body);
  }

  ///Register Exporter
  @POST(path: '/v1/market-link/exporters', optionalBody: true)
  Future<chopper.Response<MyProfileOut>> _v1MarketLinkExportersPost({
    @Body() required BuyerIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Exporter registration (IEC required, spec §4).',
      summary: 'Register Exporter',
      operationId: 'market_link_register_exporter',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///My Interests
  Future<chopper.Response<SentInterestsResponse>>
  v1MarketLinkInterestsMineGet() {
    generatedMapping.putIfAbsent(
      SentInterestsResponse,
      () => SentInterestsResponse.fromJsonFactory,
    );

    return _v1MarketLinkInterestsMineGet();
  }

  ///My Interests
  @GET(path: '/v1/market-link/interests/mine')
  Future<chopper.Response<SentInterestsResponse>>
  _v1MarketLinkInterestsMineGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Interests where the caller is the trader or the named broker, newest first, with the
lot and, once accepted, the introduction to open; a closed one is the notice that the
grower accepted another or closed the lot.''',
      summary: 'My Interests',
      operationId: 'market_link_my_interests',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Accept Interest
  ///@param interest_id
  Future<chopper.Response<IntroductionOut>>
  v1MarketLinkInterestsInterestIdAcceptPost({required String? interestId}) {
    generatedMapping.putIfAbsent(
      IntroductionOut,
      () => IntroductionOut.fromJsonFactory,
    );

    return _v1MarketLinkInterestsInterestIdAcceptPost(interestId: interestId);
  }

  ///Accept Interest
  ///@param interest_id
  @POST(
    path: '/v1/market-link/interests/{interest_id}/accept',
    optionalBody: true,
  )
  Future<chopper.Response<IntroductionOut>>
  _v1MarketLinkInterestsInterestIdAcceptPost({
    @Path('interest_id') required String? interestId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''The lot\'s grower accepts one open interest: the introduction is recorded, the other
open interests are closed (their senders get a notice), the lot leaves the traders\' list
and both sides see each other\'s contacts. Anyone but the lot\'s grower gets 404.''',
      summary: 'Accept Interest',
      operationId: 'market_link_accept_interest',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Upload Lot Photo
  ///@param photo_id
  Future<chopper.Response<LotPhotoStored>>
  v1MarketLinkLotPhotosPhotoIdPhotoPut({
    required String? photoId,
    required Object? body,
  }) {
    generatedMapping.putIfAbsent(
      LotPhotoStored,
      () => LotPhotoStored.fromJsonFactory,
    );

    return _v1MarketLinkLotPhotosPhotoIdPhotoPut(photoId: photoId, body: body);
  }

  ///Upload Lot Photo
  ///@param photo_id
  @PUT(path: '/v1/market-link/lot-photos/{photo_id}/photo', optionalBody: true)
  Future<chopper.Response<LotPhotoStored>>
  _v1MarketLinkLotPhotosPhotoIdPhotoPut({
    @Path('photo_id') required String? photoId,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Uploads one JPEG of the caller\'s own draft lot through the server, which strips its
EXIF (GPS point, phone model, time) before storing it (spec v1.5 §4B). There is no signed
upload URL for lot photos, so no stored lot photo can keep its metadata.''',
      summary: 'Upload Lot Photo',
      operationId: 'market_link_upload_lot_photo',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Lot Photo Url
  ///@param photo_id
  Future<chopper.Response<LotPhotoUrl>> v1MarketLinkLotPhotosPhotoIdUrlGet({
    required String? photoId,
  }) {
    generatedMapping.putIfAbsent(
      LotPhotoUrl,
      () => LotPhotoUrl.fromJsonFactory,
    );

    return _v1MarketLinkLotPhotosPhotoIdUrlGet(photoId: photoId);
  }

  ///Lot Photo Url
  ///@param photo_id
  @GET(path: '/v1/market-link/lot-photos/{photo_id}/url')
  Future<chopper.Response<LotPhotoUrl>> _v1MarketLinkLotPhotosPhotoIdUrlGet({
    @Path('photo_id') required String? photoId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''A short-lived download URL for an uploaded lot photo: for the grower, or for a
verified buyer / broker while the lot is published, or for the parties of an accepted
interest on it (L4). Only the derived key is signed.''',
      summary: 'Lot Photo Url',
      operationId: 'market_link_lot_photo_url',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///List Lots
  ///@param district
  ///@param taluka
  ///@param crop
  ///@param before
  Future<chopper.Response<BuyerLotsResponse>> v1MarketLinkLotsGet({
    String? district,
    String? taluka,
    String? crop,
    String? before,
  }) {
    generatedMapping.putIfAbsent(
      BuyerLotsResponse,
      () => BuyerLotsResponse.fromJsonFactory,
    );

    return _v1MarketLinkLotsGet(
      district: district,
      taluka: taluka,
      crop: crop,
      before: before,
    );
  }

  ///List Lots
  ///@param district
  ///@param taluka
  ///@param crop
  ///@param before
  @GET(path: '/v1/market-link/lots')
  Future<chopper.Response<BuyerLotsResponse>> _v1MarketLinkLotsGet({
    @Query('district') String? district,
    @Query('taluka') String? taluka,
    @Query('crop') String? crop,
    @Query('before') String? before,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Published lots, newest first, for admin-verified buyers and brokers only (403
`not_verified` for anyone else). Page with `before` = the last `published_at` seen.''',
      summary: 'List Lots',
      operationId: 'market_link_lots',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Close Lot
  ///@param lot_id
  Future<chopper.Response<GrowerLotOut>> v1MarketLinkLotsLotIdClosePost({
    required String? lotId,
  }) {
    generatedMapping.putIfAbsent(
      GrowerLotOut,
      () => GrowerLotOut.fromJsonFactory,
    );

    return _v1MarketLinkLotsLotIdClosePost(lotId: lotId);
  }

  ///Close Lot
  ///@param lot_id
  @POST(path: '/v1/market-link/lots/{lot_id}/close', optionalBody: true)
  Future<chopper.Response<GrowerLotOut>> _v1MarketLinkLotsLotIdClosePost({
    @Path('lot_id') required String? lotId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Takes a published lot off the buyers\' list (the grower sold it or changed their mind);
its open interests are closed and their senders get a notice (L4).''',
      summary: 'Close Lot',
      operationId: 'market_link_close_lot',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Lot Interests
  ///@param lot_id
  Future<chopper.Response<LotInterestsResponse>>
  v1MarketLinkLotsLotIdInterestsGet({required String? lotId}) {
    generatedMapping.putIfAbsent(
      LotInterestsResponse,
      () => LotInterestsResponse.fromJsonFactory,
    );

    return _v1MarketLinkLotsLotIdInterestsGet(lotId: lotId);
  }

  ///Lot Interests
  ///@param lot_id
  @GET(path: '/v1/market-link/lots/{lot_id}/interests')
  Future<chopper.Response<LotInterestsResponse>>
  _v1MarketLinkLotsLotIdInterestsGet({
    @Path('lot_id') required String? lotId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''The interests on the caller\'s own lot, oldest first, to compare side by side. An open
interest whose trader or broker is no longer verified is left out (decision h).''',
      summary: 'Lot Interests',
      operationId: 'market_link_lot_interests',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Send Interest
  ///@param lot_id
  Future<chopper.Response<InterestOut>> v1MarketLinkLotsLotIdInterestsPost({
    required String? lotId,
    required InterestIn? body,
  }) {
    generatedMapping.putIfAbsent(
      InterestOut,
      () => InterestOut.fromJsonFactory,
    );

    return _v1MarketLinkLotsLotIdInterestsPost(lotId: lotId, body: body);
  }

  ///Send Interest
  ///@param lot_id
  @POST(path: '/v1/market-link/lots/{lot_id}/interests', optionalBody: true)
  Future<chopper.Response<InterestOut>> _v1MarketLinkLotsLotIdInterestsPost({
    @Path('lot_id') required String? lotId,
    @Body() required InterestIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''An interest on a published lot from a verified trader / exporter (optionally naming a
verified broker) or from a verified broker for a named verified trader. A trader\'s new
interest replaces their open one on the same lot. The grower gets a push.''',
      summary: 'Send Interest',
      operationId: 'market_link_send_interest',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Publish Lot
  ///@param lot_id
  Future<chopper.Response<GrowerLotOut>> v1MarketLinkLotsLotIdPublishPost({
    required String? lotId,
  }) {
    generatedMapping.putIfAbsent(
      GrowerLotOut,
      () => GrowerLotOut.fromJsonFactory,
    );

    return _v1MarketLinkLotsLotIdPublishPost(lotId: lotId);
  }

  ///Publish Lot
  ///@param lot_id
  @POST(path: '/v1/market-link/lots/{lot_id}/publish', optionalBody: true)
  Future<chopper.Response<GrowerLotOut>> _v1MarketLinkLotsLotIdPublishPost({
    @Path('lot_id') required String? lotId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Shows a draft lot to verified buyers and brokers. Needs 3 to 8 live photos, each
uploaded; crop and variety are copied from the plot again and the place names from the
grower\'s profile (village, taluka, district; never the plot\'s point).''',
      summary: 'Publish Lot',
      operationId: 'market_link_publish_lot',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///My Acceptances
  Future<chopper.Response<MyAcceptancesOut>> v1MarketLinkMeAcceptancesGet() {
    generatedMapping.putIfAbsent(
      MyAcceptancesOut,
      () => MyAcceptancesOut.fromJsonFactory,
    );

    return _v1MarketLinkMeAcceptancesGet();
  }

  ///My Acceptances
  @GET(path: '/v1/market-link/me/acceptances')
  Future<chopper.Response<MyAcceptancesOut>> _v1MarketLinkMeAcceptancesGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'What the signed-in user accepted, and the roles it opens.',
      summary: 'My Acceptances',
      operationId: 'market_link_my_acceptances',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///My Profiles
  Future<chopper.Response<MyProfilesResponse>> v1MarketLinkMeProfilesGet() {
    generatedMapping.putIfAbsent(
      MyProfilesResponse,
      () => MyProfilesResponse.fromJsonFactory,
    );

    return _v1MarketLinkMeProfilesGet();
  }

  ///My Profiles
  @GET(path: '/v1/market-link/me/profiles')
  Future<chopper.Response<MyProfilesResponse>> _v1MarketLinkMeProfilesGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Every market-link profile of the signed-in user, with its check status.',
      summary: 'My Profiles',
      operationId: 'market_link_my_profiles',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Profiles
  ///@param role
  ///@param district
  ///@param taluka
  ///@param sort
  Future<chopper.Response<ProfilesResponse>> v1MarketLinkProfilesGet({
    required enums.V1MarketLinkProfilesGetRole? role,
    String? district,
    String? taluka,
    enums.V1MarketLinkProfilesGetSort? sort,
  }) {
    generatedMapping.putIfAbsent(
      ProfilesResponse,
      () => ProfilesResponse.fromJsonFactory,
    );

    return _v1MarketLinkProfilesGet(
      role: role?.value?.toString(),
      district: district,
      taluka: taluka,
      sort: sort?.value?.toString(),
    );
  }

  ///Profiles
  ///@param role
  ///@param district
  ///@param taluka
  ///@param sort
  @GET(path: '/v1/market-link/profiles')
  Future<chopper.Response<ProfilesResponse>> _v1MarketLinkProfilesGet({
    @Query('role') required String? role,
    @Query('district') String? district,
    @Query('taluka') String? taluka,
    @Query('sort') String? sort,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''The list per taluka (decision g): verified traders, exporters or brokers, by rating
(mean of the question averages; unrated last) or by completed deals.''',
      summary: 'Profiles',
      operationId: 'market_link_profiles',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Profile
  ///@param subject_type
  ///@param subject_id
  Future<chopper.Response<PublicProfileOut>>
  v1MarketLinkProfilesSubjectTypeSubjectIdGet({
    required enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType?
    subjectType,
    required String? subjectId,
  }) {
    generatedMapping.putIfAbsent(
      PublicProfileOut,
      () => PublicProfileOut.fromJsonFactory,
    );

    return _v1MarketLinkProfilesSubjectTypeSubjectIdGet(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
    );
  }

  ///Profile
  ///@param subject_type
  ///@param subject_id
  @GET(path: '/v1/market-link/profiles/{subject_type}/{subject_id}')
  Future<chopper.Response<PublicProfileOut>>
  _v1MarketLinkProfilesSubjectTypeSubjectIdGet({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'One verified profile; an unverified one answers 404 as if absent.',
      summary: 'Profile',
      operationId: 'market_link_profile',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Set Address
  ///@param subject_type
  ///@param subject_id
  Future<chopper.Response<MyProfileOut>>
  v1MarketLinkProfilesSubjectTypeSubjectIdAddressPut({
    required enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType?
    subjectType,
    required String? subjectId,
    required AddressIn? body,
  }) {
    generatedMapping.putIfAbsent(
      MyProfileOut,
      () => MyProfileOut.fromJsonFactory,
    );

    return _v1MarketLinkProfilesSubjectTypeSubjectIdAddressPut(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
      body: body,
    );
  }

  ///Set Address
  ///@param subject_type
  ///@param subject_id
  @PUT(
    path: '/v1/market-link/profiles/{subject_type}/{subject_id}/address',
    optionalBody: true,
  )
  Future<chopper.Response<MyProfileOut>>
  _v1MarketLinkProfilesSubjectTypeSubjectIdAddressPut({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @Body() required AddressIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''The optional address: only the profile owner or a BagMitra representative sets it
(addendum 2); who and when are stored, and a representative\'s entry is also a record.''',
      summary: 'Set Address',
      operationId: 'market_link_profile_address',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Add Document
  ///@param subject_type
  ///@param subject_id
  ///@param doc
  ///@param valid_until
  Future<chopper.Response<MyProfileOut>>
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPost({
    required enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType?
    subjectType,
    required String? subjectId,
    required enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc?
    doc,
    String? validUntil,
    required Object? body,
  }) {
    generatedMapping.putIfAbsent(
      MyProfileOut,
      () => MyProfileOut.fromJsonFactory,
    );

    return _v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPost(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
      doc: doc?.value?.toString(),
      validUntil: validUntil,
      body: body,
    );
  }

  ///Add Document
  ///@param subject_type
  ///@param subject_id
  ///@param doc
  ///@param valid_until
  @POST(
    path: '/v1/market-link/profiles/{subject_type}/{subject_id}/documents',
    optionalBody: true,
  )
  Future<chopper.Response<MyProfileOut>>
  _v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPost({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @Query('doc') required String? doc,
    @Query('valid_until') String? validUntil,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''A document photo for the admin\'s check (in-app camera): GSTIN / APMC / FSSAI / IEC /
APEDA for a trader or exporter, the Legal Metrology certificate (with its valid-until
date) for a weighbridge. Owner only; EXIF stripped before storage (spec §4B).''',
      summary: 'Add Document',
      operationId: 'market_link_profile_document',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Place Photo
  ///@param subject_type
  ///@param subject_id
  ///@param captured_at
  ///@param lat
  ///@param lon
  Future<chopper.Response>
  v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPost({
    required enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType?
    subjectType,
    required String? subjectId,
    required DateTime? capturedAt,
    required num? lat,
    required num? lon,
    required Object? body,
  }) {
    return _v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPost(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
      capturedAt: capturedAt,
      lat: lat,
      lon: lon,
      body: body,
    );
  }

  ///Place Photo
  ///@param subject_type
  ///@param subject_id
  ///@param captured_at
  ///@param lat
  ///@param lon
  @POST(
    path: '/v1/market-link/profiles/{subject_type}/{subject_id}/place-photo',
    optionalBody: true,
  )
  Future<chopper.Response>
  _v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPost({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @Query('captured_at') required DateTime? capturedAt,
    @Query('lat') required num? lat,
    @Query('lon') required num? lon,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''A representative\'s place photo from a visit (in-app camera, time + GPS): who and when
are stored; EXIF is stripped before storage (addendum 2, spec §4B).''',
      summary: 'Place Photo',
      operationId: 'market_link_profile_place_photo',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Directory
  ///@param type
  ///@param district
  ///@param taluka
  ///@param plot_id
  Future<chopper.Response<ProfilesResponse>> v1MarketLinkProvidersGet({
    String? type,
    String? district,
    String? taluka,
    String? plotId,
  }) {
    generatedMapping.putIfAbsent(
      ProfilesResponse,
      () => ProfilesResponse.fromJsonFactory,
    );

    return _v1MarketLinkProvidersGet(
      type: type,
      district: district,
      taluka: taluka,
      plotId: plotId,
    );
  }

  ///Directory
  ///@param type
  ///@param district
  ///@param taluka
  ///@param plot_id
  @GET(path: '/v1/market-link/providers')
  Future<chopper.Response<ProfilesResponse>> _v1MarketLinkProvidersGet({
    @Query('type') String? type,
    @Query('district') String? district,
    @Query('taluka') String? taluka,
    @Query('plot_id') String? plotId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Verified providers near the grower\'s own plot: nearest first when both have a location
(distance in whole km from the provider\'s registration fix, Q80), the rest by district,
taluka and name. A phone number to call; no booking.''',
      summary: 'Directory',
      operationId: 'market_link_providers_near',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Register Provider
  Future<chopper.Response<MyProfileOut>> v1MarketLinkProvidersPost({
    required ProviderIn? body,
  }) {
    generatedMapping.putIfAbsent(
      MyProfileOut,
      () => MyProfileOut.fromJsonFactory,
    );

    return _v1MarketLinkProvidersPost(body: body);
  }

  ///Register Provider
  @POST(path: '/v1/market-link/providers', optionalBody: true)
  Future<chopper.Response<MyProfileOut>> _v1MarketLinkProvidersPost({
    @Body() required ProviderIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Service provider registration (one per kind per user) with the GPS fix.',
      summary: 'Register Provider',
      operationId: 'market_link_register_provider',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Rating Tags
  Future<chopper.Response<RatingTagsResponse>> v1MarketLinkRatingTagsGet() {
    generatedMapping.putIfAbsent(
      RatingTagsResponse,
      () => RatingTagsResponse.fromJsonFactory,
    );

    return _v1MarketLinkRatingTagsGet();
  }

  ///Rating Tags
  @GET(path: '/v1/market-link/rating-tags')
  Future<chopper.Response<RatingTagsResponse>> _v1MarketLinkRatingTagsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The active tick list under each rating question (spec §3A); the app caches it.',
      summary: 'Rating Tags',
      operationId: 'market_link_rating_tags',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Terms
  Future<chopper.Response<TermsOut>> v1MarketLinkTermsGet() {
    generatedMapping.putIfAbsent(TermsOut, () => TermsOut.fromJsonFactory);

    return _v1MarketLinkTermsGet();
  }

  ///Terms
  @GET(path: '/v1/market-link/terms')
  Future<chopper.Response<TermsOut>> _v1MarketLinkTermsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''The current version of each document accepted before a role is used, and the
grievance officer shown on every role home (spec §4C).''',
      summary: 'Terms',
      operationId: 'market_link_terms',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Accept Terms
  Future<chopper.Response<MyAcceptancesOut>> v1MarketLinkTermsAcceptPost({
    required AcceptIn? body,
  }) {
    generatedMapping.putIfAbsent(
      MyAcceptancesOut,
      () => MyAcceptancesOut.fromJsonFactory,
    );

    return _v1MarketLinkTermsAcceptPost(body: body);
  }

  ///Accept Terms
  @POST(path: '/v1/market-link/terms/accept', optionalBody: true)
  Future<chopper.Response<MyAcceptancesOut>> _v1MarketLinkTermsAcceptPost({
    @Body() required AcceptIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Record the acceptance of every document for one role. A version that is no longer
current answers 409 `terms_version_changed`, so the app shows the new text again.''',
      summary: 'Accept Terms',
      operationId: 'market_link_accept_terms',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Register Trader
  Future<chopper.Response<MyProfileOut>> v1MarketLinkTradersPost({
    required BuyerIn? body,
  }) {
    generatedMapping.putIfAbsent(
      MyProfileOut,
      () => MyProfileOut.fromJsonFactory,
    );

    return _v1MarketLinkTradersPost(body: body);
  }

  ///Register Trader
  @POST(path: '/v1/market-link/traders', optionalBody: true)
  Future<chopper.Response<MyProfileOut>> _v1MarketLinkTradersPost({
    @Body() required BuyerIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Trader registration with the GPS fix; lands in the verification queue.',
      summary: 'Register Trader',
      operationId: 'market_link_register_trader',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
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
are shown as published, never estimated, and come from storage only (filled by the scheduled
pull; a request never fetches). `stale` says they are not current and `reason` says why.
`scope` narrows the list to local or major mandis.''',
      summary: 'Get Market Prices',
      operationId: 'market_prices_get',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market"],
      deprecated: false,
    ),
  });

  ///Delete Me
  Future<chopper.Response<AccountDeleted>> v1MeDelete() {
    generatedMapping.putIfAbsent(
      AccountDeleted,
      () => AccountDeleted.fromJsonFactory,
    );

    return _v1MeDelete();
  }

  ///Delete Me
  @DELETE(path: '/v1/me')
  Future<chopper.Response<AccountDeleted>> _v1MeDelete({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Erase the caller\'s account: every record, the sync history, devices, notice receipts,
backed-up photos and (when configured) the sign-in account. It cannot be undone.''',
      summary: 'Delete Me',
      operationId: 'me_delete',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["profile"],
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
      description: '''A short-lived signed download URL for a backed-up photo.

Only the key derived from the caller and the record is ever signed (S-03): the stored
`photo_key` is just the flag that a photo exists, and one that does not match the derived
key (written around the sync check) is treated as no photo.''',
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
