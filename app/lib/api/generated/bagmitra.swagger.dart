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

  ///Put Photo Limits
  Future<chopper.Response<BillingSettingsOut>> v1AdminBillingPhotoLimitsPut({
    required PhotoLimitsIn? body,
  }) {
    generatedMapping.putIfAbsent(
      BillingSettingsOut,
      () => BillingSettingsOut.fromJsonFactory,
    );

    return _v1AdminBillingPhotoLimitsPut(body: body);
  }

  ///Put Photo Limits
  @PUT(path: '/v1/admin/billing/photo-limits', optionalBody: true)
  Future<chopper.Response<BillingSettingsOut>> _v1AdminBillingPhotoLimitsPut({
    @Body() required PhotoLimitsIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Photo analysis limits for farmers without a plan, and the optional overall cap (Q135).',
      summary: 'Put Photo Limits',
      operationId: 'admin_billing_put_photo_limits',
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

  ///Put Role Amount
  ///@param role
  Future<chopper.Response<BillingSettingsOut>>
  v1AdminBillingRolesRoleAmountPut({
    required enums.V1AdminBillingRolesRoleAmountPutRole? role,
    required RoleAmountIn? body,
  }) {
    generatedMapping.putIfAbsent(
      BillingSettingsOut,
      () => BillingSettingsOut.fromJsonFactory,
    );

    return _v1AdminBillingRolesRoleAmountPut(
      role: role?.value?.toString(),
      body: body,
    );
  }

  ///Put Role Amount
  ///@param role
  @PUT(path: '/v1/admin/billing/roles/{role}/amount', optionalBody: true)
  Future<chopper.Response<BillingSettingsOut>>
  _v1AdminBillingRolesRoleAmountPut({
    @Path('role') required String? role,
    @Body() required RoleAmountIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Put Role Amount',
      operationId: 'admin_billing_put_role_amount',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Migrate Prices
  ///@param role
  Future<chopper.Response<BillingSettingsOut>>
  v1AdminBillingRolesRoleMigratePricesPost({
    required enums.V1AdminBillingRolesRoleMigratePricesPostRole? role,
    required MigrateIn? body,
  }) {
    generatedMapping.putIfAbsent(
      BillingSettingsOut,
      () => BillingSettingsOut.fromJsonFactory,
    );

    return _v1AdminBillingRolesRoleMigratePricesPost(
      role: role?.value?.toString(),
      body: body,
    );
  }

  ///Migrate Prices
  ///@param role
  @POST(
    path: '/v1/admin/billing/roles/{role}/migrate-prices',
    optionalBody: true,
  )
  Future<chopper.Response<BillingSettingsOut>>
  _v1AdminBillingRolesRoleMigratePricesPost({
    @Path('role') required String? role,
    @Body() required MigrateIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Migrate Prices',
      operationId: 'admin_billing_migrate_prices',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Put Role Photo Limits
  ///@param role
  Future<chopper.Response<BillingSettingsOut>>
  v1AdminBillingRolesRolePhotoLimitsPut({
    required enums.V1AdminBillingRolesRolePhotoLimitsPutRole? role,
    required RolePhotoLimitsIn? body,
  }) {
    generatedMapping.putIfAbsent(
      BillingSettingsOut,
      () => BillingSettingsOut.fromJsonFactory,
    );

    return _v1AdminBillingRolesRolePhotoLimitsPut(
      role: role?.value?.toString(),
      body: body,
    );
  }

  ///Put Role Photo Limits
  ///@param role
  @PUT(path: '/v1/admin/billing/roles/{role}/photo-limits', optionalBody: true)
  Future<chopper.Response<BillingSettingsOut>>
  _v1AdminBillingRolesRolePhotoLimitsPut({
    @Path('role') required String? role,
    @Body() required RolePhotoLimitsIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Photo analysis limits per farmer on this role\'s plan (Q135).',
      summary: 'Put Role Photo Limits',
      operationId: 'admin_billing_put_role_photo_limits',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Get Billing Settings
  Future<chopper.Response<BillingSettingsOut>> v1AdminBillingSettingsGet() {
    generatedMapping.putIfAbsent(
      BillingSettingsOut,
      () => BillingSettingsOut.fromJsonFactory,
    );

    return _v1AdminBillingSettingsGet();
  }

  ///Get Billing Settings
  @GET(path: '/v1/admin/billing/settings')
  Future<chopper.Response<BillingSettingsOut>> _v1AdminBillingSettingsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Billing Settings',
      operationId: 'admin_billing_settings',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Put Switch
  Future<chopper.Response<BillingSettingsOut>> v1AdminBillingSettingsPut({
    required SwitchIn? body,
  }) {
    generatedMapping.putIfAbsent(
      BillingSettingsOut,
      () => BillingSettingsOut.fromJsonFactory,
    );

    return _v1AdminBillingSettingsPut(body: body);
  }

  ///Put Switch
  @PUT(path: '/v1/admin/billing/settings', optionalBody: true)
  Future<chopper.Response<BillingSettingsOut>> _v1AdminBillingSettingsPut({
    @Body() required SwitchIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Put Switch',
      operationId: 'admin_billing_put_switch',
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

  ///Admin List
  ///@param status
  ///@param limit
  Future<chopper.Response<FeedbackList>> v1AdminFeedbackGet({
    String? status,
    int? limit,
  }) {
    generatedMapping.putIfAbsent(
      FeedbackList,
      () => FeedbackList.fromJsonFactory,
    );

    return _v1AdminFeedbackGet(status: status, limit: limit);
  }

  ///Admin List
  ///@param status
  ///@param limit
  @GET(path: '/v1/admin/feedback')
  Future<chopper.Response<FeedbackList>> _v1AdminFeedbackGet({
    @Query('status') String? status,
    @Query('limit') int? limit,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Admin List',
      operationId: 'admin_feedback_list',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feedback", "admin"],
      deprecated: false,
    ),
  });

  ///Admin Status
  ///@param feedback_id
  Future<chopper.Response<FeedbackOut>> v1AdminFeedbackFeedbackIdPut({
    required String? feedbackId,
    required StatusIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedbackOut,
      () => FeedbackOut.fromJsonFactory,
    );

    return _v1AdminFeedbackFeedbackIdPut(feedbackId: feedbackId, body: body);
  }

  ///Admin Status
  ///@param feedback_id
  @PUT(path: '/v1/admin/feedback/{feedback_id}', optionalBody: true)
  Future<chopper.Response<FeedbackOut>> _v1AdminFeedbackFeedbackIdPut({
    @Path('feedback_id') required String? feedbackId,
    @Body() required StatusIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Admin Status',
      operationId: 'admin_feedback_status',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feedback", "admin"],
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

  ///Actions
  ///@param subject_id
  ///@param user_id
  Future<chopper.Response<ActionsResponse>> v1AdminMarketLinkActionsGet({
    String? subjectId,
    String? userId,
  }) {
    generatedMapping.putIfAbsent(
      ActionsResponse,
      () => ActionsResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkActionsGet(subjectId: subjectId, userId: userId);
  }

  ///Actions
  ///@param subject_id
  ///@param user_id
  @GET(path: '/v1/admin/market-link/actions')
  Future<chopper.Response<ActionsResponse>> _v1AdminMarketLinkActionsGet({
    @Query('subject_id') String? subjectId,
    @Query('user_id') String? userId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The action log, newest first (at most 200 rows).',
      summary: 'Actions',
      operationId: 'admin_market_link_actions',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Act
  Future<chopper.Response<ActionOut>> v1AdminMarketLinkActionsPost({
    required ActionIn? body,
  }) {
    generatedMapping.putIfAbsent(ActionOut, () => ActionOut.fromJsonFactory);

    return _v1AdminMarketLinkActionsPost(body: body);
  }

  ///Act
  @POST(path: '/v1/admin/market-link/actions', optionalBody: true)
  Future<chopper.Response<ActionOut>> _v1AdminMarketLinkActionsPost({
    @Body() required ActionIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'An action without a report (e.g. restore after a check, or hide a duplicate user).',
      summary: 'Act',
      operationId: 'admin_market_link_act',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Appeals
  ///@param state
  Future<chopper.Response<ActionsResponse>> v1AdminMarketLinkAppealsGet({
    enums.V1AdminMarketLinkAppealsGetState? state,
  }) {
    generatedMapping.putIfAbsent(
      ActionsResponse,
      () => ActionsResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkAppealsGet(state: state?.value?.toString());
  }

  ///Appeals
  ///@param state
  @GET(path: '/v1/admin/market-link/appeals')
  Future<chopper.Response<ActionsResponse>> _v1AdminMarketLinkAppealsGet({
    @Query('state') String? state,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Appeals in one state, oldest appeal first.',
      summary: 'Appeals',
      operationId: 'admin_market_link_appeals',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Acknowledge Appeal
  ///@param action_id
  Future<chopper.Response<ActionOut>>
  v1AdminMarketLinkAppealsActionIdAcknowledgePost({required String? actionId}) {
    generatedMapping.putIfAbsent(ActionOut, () => ActionOut.fromJsonFactory);

    return _v1AdminMarketLinkAppealsActionIdAcknowledgePost(actionId: actionId);
  }

  ///Acknowledge Appeal
  ///@param action_id
  @POST(
    path: '/v1/admin/market-link/appeals/{action_id}/acknowledge',
    optionalBody: true,
  )
  Future<chopper.Response<ActionOut>>
  _v1AdminMarketLinkAppealsActionIdAcknowledgePost({
    @Path('action_id') required String? actionId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Acknowledge Appeal',
      operationId: 'admin_market_link_appeal_ack',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Decide Appeal
  ///@param action_id
  Future<chopper.Response<ActionOut>>
  v1AdminMarketLinkAppealsActionIdDecisionPost({
    required String? actionId,
    required AppealDecisionIn? body,
  }) {
    generatedMapping.putIfAbsent(ActionOut, () => ActionOut.fromJsonFactory);

    return _v1AdminMarketLinkAppealsActionIdDecisionPost(
      actionId: actionId,
      body: body,
    );
  }

  ///Decide Appeal
  ///@param action_id
  @POST(
    path: '/v1/admin/market-link/appeals/{action_id}/decision',
    optionalBody: true,
  )
  Future<chopper.Response<ActionOut>>
  _v1AdminMarketLinkAppealsActionIdDecisionPost({
    @Path('action_id') required String? actionId,
    @Body() required AppealDecisionIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Uphold (a hide / suspend is lifted by a new restore row, reason `appeal_upheld`) or
reject. Decided once.''',
      summary: 'Decide Appeal',
      operationId: 'admin_market_link_appeal_decide',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Appeal Photo Url
  ///@param action_id
  ///@param index
  Future<chopper.Response<PhotoDownloadUrl>>
  v1AdminMarketLinkAppealsActionIdPhotosIndexUrlGet({
    required String? actionId,
    required int? index,
  }) {
    generatedMapping.putIfAbsent(
      PhotoDownloadUrl,
      () => PhotoDownloadUrl.fromJsonFactory,
    );

    return _v1AdminMarketLinkAppealsActionIdPhotosIndexUrlGet(
      actionId: actionId,
      index: index,
    );
  }

  ///Appeal Photo Url
  ///@param action_id
  ///@param index
  @GET(path: '/v1/admin/market-link/appeals/{action_id}/photos/{index}/url')
  Future<chopper.Response<PhotoDownloadUrl>>
  _v1AdminMarketLinkAppealsActionIdPhotosIndexUrlGet({
    @Path('action_id') required String? actionId,
    @Path('index') required int? index,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Appeal Photo Url',
      operationId: 'admin_market_link_appeal_photo',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Get Company Profile
  Future<chopper.Response<PackageCompanyOut>>
  v1AdminMarketLinkPackageCompanyProfileGet() {
    generatedMapping.putIfAbsent(
      PackageCompanyOut,
      () => PackageCompanyOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageCompanyProfileGet();
  }

  ///Get Company Profile
  @GET(path: '/v1/admin/market-link/package/company-profile')
  Future<chopper.Response<PackageCompanyOut>>
  _v1AdminMarketLinkPackageCompanyProfileGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Company Profile',
      operationId: 'package_company_profile',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Save Company Profile
  Future<chopper.Response<PackageCompanyOut>>
  v1AdminMarketLinkPackageCompanyProfilePut({required PackageCompanyIn? body}) {
    generatedMapping.putIfAbsent(
      PackageCompanyOut,
      () => PackageCompanyOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageCompanyProfilePut(body: body);
  }

  ///Save Company Profile
  @PUT(
    path: '/v1/admin/market-link/package/company-profile',
    optionalBody: true,
  )
  Future<chopper.Response<PackageCompanyOut>>
  _v1AdminMarketLinkPackageCompanyProfilePut({
    @Body() required PackageCompanyIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Saves the fields sent (an empty string clears one). While the switch is ON a guard
field cannot be cleared.''',
      summary: 'Save Company Profile',
      operationId: 'package_save_company_profile',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Merchant Qr
  Future<chopper.Response>
  v1AdminMarketLinkPackageCompanyProfileMerchantQrGet() {
    return _v1AdminMarketLinkPackageCompanyProfileMerchantQrGet();
  }

  ///Merchant Qr
  @GET(path: '/v1/admin/market-link/package/company-profile/merchant-qr')
  Future<chopper.Response>
  _v1AdminMarketLinkPackageCompanyProfileMerchantQrGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Merchant Qr',
      operationId: 'package_merchant_qr',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Upload Merchant Qr
  Future<chopper.Response<PackageCompanyOut>>
  v1AdminMarketLinkPackageCompanyProfileMerchantQrPut({required Object? body}) {
    generatedMapping.putIfAbsent(
      PackageCompanyOut,
      () => PackageCompanyOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageCompanyProfileMerchantQrPut(body: body);
  }

  ///Upload Merchant Qr
  @PUT(
    path: '/v1/admin/market-link/package/company-profile/merchant-qr',
    optionalBody: true,
  )
  Future<chopper.Response<PackageCompanyOut>>
  _v1AdminMarketLinkPackageCompanyProfileMerchantQrPut({
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The bank\'s merchant QR image (PNG / JPEG) for the representatives\' printed card.',
      summary: 'Upload Merchant Qr',
      operationId: 'package_upload_merchant_qr',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///List Grants
  ///@param grower_id
  Future<chopper.Response<PackageGrantsResponse>>
  v1AdminMarketLinkPackageGrantsGet({String? growerId}) {
    generatedMapping.putIfAbsent(
      PackageGrantsResponse,
      () => PackageGrantsResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageGrantsGet(growerId: growerId);
  }

  ///List Grants
  ///@param grower_id
  @GET(path: '/v1/admin/market-link/package/grants')
  Future<chopper.Response<PackageGrantsResponse>>
  _v1AdminMarketLinkPackageGrantsGet({
    @Query('grower_id') String? growerId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Grants newest first (one grower\'s with `grower_id`).',
      summary: 'List Grants',
      operationId: 'package_grants',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Create Grant
  Future<chopper.Response<PackageGrantOut>> v1AdminMarketLinkPackageGrantsPost({
    required PackageGrantIn? body,
  }) {
    generatedMapping.putIfAbsent(
      PackageGrantOut,
      () => PackageGrantOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageGrantsPost(body: body);
  }

  ///Create Grant
  @POST(path: '/v1/admin/market-link/package/grants', optionalBody: true)
  Future<chopper.Response<PackageGrantOut>>
  _v1AdminMarketLinkPackageGrantsPost({
    @Body() required PackageGrantIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Records a payment received outside the app and activates the package: the lot (or
every lot of the grower) is shown to traders until `valid_until`. 409
`duplicate_payment_ref` for a used UTR; 409 `package_fields_missing` while legal name,
GSTIN, UPI ID, price or validity is empty.''',
      summary: 'Create Grant',
      operationId: 'package_record_grant',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Grant Receipt
  ///@param grant_id
  Future<chopper.Response<ReceiptOut>>
  v1AdminMarketLinkPackageGrantsGrantIdReceiptGet({required String? grantId}) {
    generatedMapping.putIfAbsent(ReceiptOut, () => ReceiptOut.fromJsonFactory);

    return _v1AdminMarketLinkPackageGrantsGrantIdReceiptGet(grantId: grantId);
  }

  ///Grant Receipt
  ///@param grant_id
  @GET(path: '/v1/admin/market-link/package/grants/{grant_id}/receipt')
  Future<chopper.Response<ReceiptOut>>
  _v1AdminMarketLinkPackageGrantsGrantIdReceiptGet({
    @Path('grant_id') required String? grantId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''What the receipt PDF shows (the admin web draws it): company profile, receipt number,
grower, amount, GST line only when GSTIN and GST rate are set, payment reference and
validity. 409 `company_profile_empty` while legal name or address is empty.''',
      summary: 'Grant Receipt',
      operationId: 'package_grant_receipt',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Revoke
  ///@param grant_id
  Future<chopper.Response<PackageGrantOut>>
  v1AdminMarketLinkPackageGrantsGrantIdRevokePost({
    required String? grantId,
    required PackageRevokeIn? body,
  }) {
    generatedMapping.putIfAbsent(
      PackageGrantOut,
      () => PackageGrantOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageGrantsGrantIdRevokePost(
      grantId: grantId,
      body: body,
    );
  }

  ///Revoke
  ///@param grant_id
  @POST(
    path: '/v1/admin/market-link/package/grants/{grant_id}/revoke',
    optionalBody: true,
  )
  Future<chopper.Response<PackageGrantOut>>
  _v1AdminMarketLinkPackageGrantsGrantIdRevokePost({
    @Path('grant_id') required String? grantId,
    @Body() required PackageRevokeIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Ends the grant now with a reason (logged); the lot hides from traders if no other
grant covers it.''',
      summary: 'Revoke',
      operationId: 'package_revoke_grant',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Find Grower
  ///@param phone
  Future<chopper.Response<PackageGrowersResponse>>
  v1AdminMarketLinkPackageGrowersGet({required String? phone}) {
    generatedMapping.putIfAbsent(
      PackageGrowersResponse,
      () => PackageGrowersResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageGrowersGet(phone: phone);
  }

  ///Find Grower
  ///@param phone
  @GET(path: '/v1/admin/market-link/package/growers')
  Future<chopper.Response<PackageGrowersResponse>>
  _v1AdminMarketLinkPackageGrowersGet({
    @Query('phone') required String? phone,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Growers with this mobile number (10 digits, with or without +91) and their lots.',
      summary: 'Find Grower',
      operationId: 'package_find_grower',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Get Package Settings
  Future<chopper.Response<PackageSettingsOut>>
  v1AdminMarketLinkPackageSettingsGet() {
    generatedMapping.putIfAbsent(
      PackageSettingsOut,
      () => PackageSettingsOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageSettingsGet();
  }

  ///Get Package Settings
  @GET(path: '/v1/admin/market-link/package/settings')
  Future<chopper.Response<PackageSettingsOut>>
  _v1AdminMarketLinkPackageSettingsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Package Settings',
      operationId: 'package_settings',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Save Settings
  Future<chopper.Response<PackageSettingsOut>>
  v1AdminMarketLinkPackageSettingsPut({required PackageSettingsIn? body}) {
    generatedMapping.putIfAbsent(
      PackageSettingsOut,
      () => PackageSettingsOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkPackageSettingsPut(body: body);
  }

  ///Save Settings
  @PUT(path: '/v1/admin/market-link/package/settings', optionalBody: true)
  Future<chopper.Response<PackageSettingsOut>>
  _v1AdminMarketLinkPackageSettingsPut({
    @Body() required PackageSettingsIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Switch, price, validity, start date. The switch cannot turn (or stay) ON while legal
name, GSTIN, UPI ID or price is empty: 409 `package_fields_missing` names the fields.''',
      summary: 'Save Settings',
      operationId: 'package_save_settings',
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

  ///Rechecks
  Future<chopper.Response<RecheckResponse>> v1AdminMarketLinkRechecksGet() {
    generatedMapping.putIfAbsent(
      RecheckResponse,
      () => RecheckResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkRechecksGet();
  }

  ///Rechecks
  @GET(path: '/v1/admin/market-link/rechecks')
  Future<chopper.Response<RecheckResponse>> _v1AdminMarketLinkRechecksGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Checks the yearly job listed as due and not re-checked since, oldest first.',
      summary: 'Rechecks',
      operationId: 'admin_market_link_rechecks',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Reports
  ///@param status
  ///@param subject_type
  Future<chopper.Response<ReportsAdminResponse>> v1AdminMarketLinkReportsGet({
    enums.V1AdminMarketLinkReportsGetStatus? status,
    String? subjectType,
  }) {
    generatedMapping.putIfAbsent(
      ReportsAdminResponse,
      () => ReportsAdminResponse.fromJsonFactory,
    );

    return _v1AdminMarketLinkReportsGet(
      status: status?.value?.toString(),
      subjectType: subjectType,
    );
  }

  ///Reports
  ///@param status
  ///@param subject_type
  @GET(path: '/v1/admin/market-link/reports')
  Future<chopper.Response<ReportsAdminResponse>> _v1AdminMarketLinkReportsGet({
    @Query('status') String? status,
    @Query('subject_type') String? subjectType,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Reports in one state, oldest first (the grievance timeline runs from creation).',
      summary: 'Reports',
      operationId: 'admin_market_link_reports',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Acknowledge Report
  ///@param report_id
  Future<chopper.Response<ReportAdminOut>>
  v1AdminMarketLinkReportsReportIdAcknowledgePost({required String? reportId}) {
    generatedMapping.putIfAbsent(
      ReportAdminOut,
      () => ReportAdminOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkReportsReportIdAcknowledgePost(reportId: reportId);
  }

  ///Acknowledge Report
  ///@param report_id
  @POST(
    path: '/v1/admin/market-link/reports/{report_id}/acknowledge',
    optionalBody: true,
  )
  Future<chopper.Response<ReportAdminOut>>
  _v1AdminMarketLinkReportsReportIdAcknowledgePost({
    @Path('report_id') required String? reportId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Acknowledge Report',
      operationId: 'admin_market_link_report_ack',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Decide Report
  ///@param report_id
  Future<chopper.Response<ReportAdminOut>>
  v1AdminMarketLinkReportsReportIdDecisionPost({
    required String? reportId,
    required ReportDecisionIn? body,
  }) {
    generatedMapping.putIfAbsent(
      ReportAdminOut,
      () => ReportAdminOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkReportsReportIdDecisionPost(
      reportId: reportId,
      body: body,
    );
  }

  ///Decide Report
  ///@param report_id
  @POST(
    path: '/v1/admin/market-link/reports/{report_id}/decision',
    optionalBody: true,
  )
  Future<chopper.Response<ReportAdminOut>>
  _v1AdminMarketLinkReportsReportIdDecisionPost({
    @Path('report_id') required String? reportId,
    @Body() required ReportDecisionIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Warn, hide or suspend the reported subject with a reason code; this closes every open
report of the same subject with that action.''',
      summary: 'Decide Report',
      operationId: 'admin_market_link_report_decide',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Dismiss Report
  ///@param report_id
  Future<chopper.Response<ReportAdminOut>>
  v1AdminMarketLinkReportsReportIdDismissPost({required String? reportId}) {
    generatedMapping.putIfAbsent(
      ReportAdminOut,
      () => ReportAdminOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkReportsReportIdDismissPost(reportId: reportId);
  }

  ///Dismiss Report
  ///@param report_id
  @POST(
    path: '/v1/admin/market-link/reports/{report_id}/dismiss',
    optionalBody: true,
  )
  Future<chopper.Response<ReportAdminOut>>
  _v1AdminMarketLinkReportsReportIdDismissPost({
    @Path('report_id') required String? reportId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'No platform rule is broken: the report closes without an action.',
      summary: 'Dismiss Report',
      operationId: 'admin_market_link_report_dismiss',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Report Photo Url
  ///@param report_id
  ///@param index
  Future<chopper.Response<PhotoDownloadUrl>>
  v1AdminMarketLinkReportsReportIdPhotosIndexUrlGet({
    required String? reportId,
    required int? index,
  }) {
    generatedMapping.putIfAbsent(
      PhotoDownloadUrl,
      () => PhotoDownloadUrl.fromJsonFactory,
    );

    return _v1AdminMarketLinkReportsReportIdPhotosIndexUrlGet(
      reportId: reportId,
      index: index,
    );
  }

  ///Report Photo Url
  ///@param report_id
  ///@param index
  @GET(path: '/v1/admin/market-link/reports/{report_id}/photos/{index}/url')
  Future<chopper.Response<PhotoDownloadUrl>>
  _v1AdminMarketLinkReportsReportIdPhotosIndexUrlGet({
    @Path('report_id') required String? reportId,
    @Path('index') required int? index,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Report Photo Url',
      operationId: 'admin_market_link_report_photo',
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
      description: 'The subject\'s submitted fields, documents, every verification and check record.',
      summary: 'Subject History',
      operationId: 'admin_market_link_subject',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["admin"],
      deprecated: false,
    ),
  });

  ///Record Check
  ///@param subject_type
  ///@param subject_id
  Future<chopper.Response<SubjectDetailOut>>
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPost({
    required enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPostSubjectType?
    subjectType,
    required String? subjectId,
    required CheckIn? body,
  }) {
    generatedMapping.putIfAbsent(
      SubjectDetailOut,
      () => SubjectDetailOut.fromJsonFactory,
    );

    return _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPost(
      subjectType: subjectType?.value?.toString(),
      subjectId: subjectId,
      body: body,
    );
  }

  ///Record Check
  ///@param subject_type
  ///@param subject_id
  @POST(
    path: '/v1/admin/market-link/verifications/{subject_type}/{subject_id}/checks',
    optionalBody: true,
  )
  Future<chopper.Response<SubjectDetailOut>>
  _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPost({
    @Path('subject_type') required String? subjectType,
    @Path('subject_id') required String? subjectId,
    @Body() required CheckIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Record one check done by hand on the official page: a new record with who and when.',
      summary: 'Record Check',
      operationId: 'admin_market_link_record_check',
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
      description: '''Approve, or reject with a reason: always a new record with who and when (Q70). An
approval needs the spec §4 checks on record (trader: GSTIN / APMC / IEC; exporter: IEC;
broker: the phone call), else 422 `verified_rule_not_met`.''',
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

  ///Admin Samples
  ///@param labelled true: the training export
  ///@param limit
  Future<chopper.Response<SamplesOut>> v1AdminPhotoAnalysisSamplesGet({
    bool? labelled,
    int? limit,
  }) {
    generatedMapping.putIfAbsent(SamplesOut, () => SamplesOut.fromJsonFactory);

    return _v1AdminPhotoAnalysisSamplesGet(labelled: labelled, limit: limit);
  }

  ///Admin Samples
  ///@param labelled true: the training export
  ///@param limit
  @GET(path: '/v1/admin/photo-analysis/samples')
  Future<chopper.Response<SamplesOut>> _v1AdminPhotoAnalysisSamplesGet({
    @Query('labelled') bool? labelled,
    @Query('limit') int? limit,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Training export: labelled samples with a signed photo link (1 hour) and the label.
`labelled=false` lists the samples still to label. No owner id is listed.''',
      summary: 'Admin Samples',
      operationId: 'admin_photo_analysis_samples',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["photo-analysis", "admin"],
      deprecated: false,
    ),
  });

  ///Admin Label
  ///@param photo_id
  Future<chopper.Response<SampleOut>>
  v1AdminPhotoAnalysisSamplesPhotoIdLabelPut({
    required String? photoId,
    required LabelIn? body,
  }) {
    generatedMapping.putIfAbsent(SampleOut, () => SampleOut.fromJsonFactory);

    return _v1AdminPhotoAnalysisSamplesPhotoIdLabelPut(
      photoId: photoId,
      body: body,
    );
  }

  ///Admin Label
  ///@param photo_id
  @PUT(
    path: '/v1/admin/photo-analysis/samples/{photo_id}/label',
    optionalBody: true,
  )
  Future<chopper.Response<SampleOut>>
  _v1AdminPhotoAnalysisSamplesPhotoIdLabelPut({
    @Path('photo_id') required String? photoId,
    @Body() required LabelIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Confirms what a sample shows (a profile key, `healthy` or `other`) for training.',
      summary: 'Admin Label',
      operationId: 'admin_photo_analysis_label',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["photo-analysis", "admin"],
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

  ///Create Bill Photo Upload Url
  ///@param kind
  ///@param record_id
  Future<chopper.Response<PhotoUploadUrl>>
  v1BillPhotosKindRecordIdUploadUrlPost({
    required enums.V1BillPhotosKindRecordIdUploadUrlPostKind? kind,
    required String? recordId,
    required PhotoUploadIn? body,
  }) {
    generatedMapping.putIfAbsent(
      PhotoUploadUrl,
      () => PhotoUploadUrl.fromJsonFactory,
    );

    return _v1BillPhotosKindRecordIdUploadUrlPost(
      kind: kind?.value?.toString(),
      recordId: recordId,
      body: body,
    );
  }

  ///Create Bill Photo Upload Url
  ///@param kind
  ///@param record_id
  @POST(
    path: '/v1/bill-photos/{kind}/{record_id}/upload-url',
    optionalBody: true,
  )
  Future<chopper.Response<PhotoUploadUrl>>
  _v1BillPhotosKindRecordIdUploadUrlPost({
    @Path('kind') required String? kind,
    @Path('record_id') required String? recordId,
    @Body() required PhotoUploadIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''A signed upload URL for this record\'s bill photo (JPEG only, at most `max_bytes`).

The phone PUTs the file to `upload_url`, then records `photo_key` as the record\'s
`bill_photo_key` through the normal outbox.''',
      summary: 'Create Bill Photo Upload Url',
      operationId: 'bill_photo_upload_url',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["bill-photos"],
      deprecated: false,
    ),
  });

  ///Get Bill Photo Url
  ///@param kind
  ///@param record_id
  Future<chopper.Response<PhotoDownloadUrl>> v1BillPhotosKindRecordIdUrlGet({
    required enums.V1BillPhotosKindRecordIdUrlGetKind? kind,
    required String? recordId,
  }) {
    generatedMapping.putIfAbsent(
      PhotoDownloadUrl,
      () => PhotoDownloadUrl.fromJsonFactory,
    );

    return _v1BillPhotosKindRecordIdUrlGet(
      kind: kind?.value?.toString(),
      recordId: recordId,
    );
  }

  ///Get Bill Photo Url
  ///@param kind
  ///@param record_id
  @GET(path: '/v1/bill-photos/{kind}/{record_id}/url')
  Future<chopper.Response<PhotoDownloadUrl>> _v1BillPhotosKindRecordIdUrlGet({
    @Path('kind') required String? kind,
    @Path('record_id') required String? recordId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''A short-lived signed download URL for a backed-up bill photo. Only the key derived
from the caller and the record is ever signed; a stored key that differs is no photo.''',
      summary: 'Get Bill Photo Url',
      operationId: 'bill_photo_url',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["bill-photos"],
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

  ///Rtdn
  ///@param authorization
  Future<chopper.Response> v1BillingGoogleRtdnPost({
    String? authorization,
    required Object? body,
  }) {
    return _v1BillingGoogleRtdnPost(
      authorization: authorization?.toString(),
      body: body,
    );
  }

  ///Rtdn
  ///@param authorization
  @POST(path: '/v1/billing/google/rtdn', optionalBody: true)
  Future<chopper.Response> _v1BillingGoogleRtdnPost({
    @Header('authorization') String? authorization,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Pub/Sub push of a Play notification (no user session: Google\'s OIDC token instead).',
      summary: 'Rtdn',
      operationId: 'billing_google_rtdn',
      consumes: [],
      produces: [],
      security: [],
      tags: ["billing"],
      deprecated: false,
    ),
  });

  ///Verify
  Future<chopper.Response<EntitlementsResponse>> v1BillingGoogleVerifyPost({
    required VerifyIn? body,
  }) {
    generatedMapping.putIfAbsent(
      EntitlementsResponse,
      () => EntitlementsResponse.fromJsonFactory,
    );

    return _v1BillingGoogleVerifyPost(body: body);
  }

  ///Verify
  @POST(path: '/v1/billing/google/verify', optionalBody: true)
  Future<chopper.Response<EntitlementsResponse>> _v1BillingGoogleVerifyPost({
    @Body() required VerifyIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''The app sends the purchase token; only after Google confirms it does the snapshot
change. The server acknowledges the purchase.''',
      summary: 'Verify',
      operationId: 'billing_google_verify',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["billing"],
      deprecated: false,
    ),
  });

  ///Plan
  Future<chopper.Response<PlanOfferOut>> v1BillingPlanGet() {
    generatedMapping.putIfAbsent(
      PlanOfferOut,
      () => PlanOfferOut.fromJsonFactory,
    );

    return _v1BillingPlanGet();
  }

  ///Plan
  @GET(path: '/v1/billing/plan')
  Future<chopper.Response<PlanOfferOut>> _v1BillingPlanGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Plan',
      operationId: 'billing_plan',
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

  ///Send
  Future<chopper.Response<FeedbackOut>> v1FeedbackPost({
    required FeedbackIn? body,
  }) {
    generatedMapping.putIfAbsent(
      FeedbackOut,
      () => FeedbackOut.fromJsonFactory,
    );

    return _v1FeedbackPost(body: body);
  }

  ///Send
  @POST(path: '/v1/feedback', optionalBody: true)
  Future<chopper.Response<FeedbackOut>> _v1FeedbackPost({
    @Body() required FeedbackIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Send',
      operationId: 'feedback_send',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feedback"],
      deprecated: false,
    ),
  });

  ///Screenshot
  ///@param feedback_id
  Future<chopper.Response> v1FeedbackFeedbackIdScreenshotPut({
    required String? feedbackId,
    required Object? body,
  }) {
    return _v1FeedbackFeedbackIdScreenshotPut(
      feedbackId: feedbackId,
      body: body,
    );
  }

  ///Screenshot
  ///@param feedback_id
  @PUT(path: '/v1/feedback/{feedback_id}/screenshot', optionalBody: true)
  Future<chopper.Response> _v1FeedbackFeedbackIdScreenshotPut({
    @Path('feedback_id') required String? feedbackId,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Screenshot',
      operationId: 'feedback_screenshot',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["feedback"],
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

  ///Account Actions
  Future<chopper.Response<AccountActionsResponse>>
  v1MarketLinkAccountActionsGet() {
    generatedMapping.putIfAbsent(
      AccountActionsResponse,
      () => AccountActionsResponse.fromJsonFactory,
    );

    return _v1MarketLinkAccountActionsGet();
  }

  ///Account Actions
  @GET(path: '/v1/market-link/account-actions')
  Future<chopper.Response<AccountActionsResponse>>
  _v1MarketLinkAccountActionsGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Every admin action about the caller, newest first, with its reason code (§4C).',
      summary: 'Account Actions',
      operationId: 'market_link_account_actions',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Appeal
  ///@param action_id
  Future<chopper.Response<AccountActionOut>>
  v1MarketLinkAccountActionsActionIdAppealPost({
    required String? actionId,
    required AppealIn? body,
  }) {
    generatedMapping.putIfAbsent(
      AccountActionOut,
      () => AccountActionOut.fromJsonFactory,
    );

    return _v1MarketLinkAccountActionsActionIdAppealPost(
      actionId: actionId,
      body: body,
    );
  }

  ///Appeal
  ///@param action_id
  @POST(
    path: '/v1/market-link/account-actions/{action_id}/appeal',
    optionalBody: true,
  )
  Future<chopper.Response<AccountActionOut>>
  _v1MarketLinkAccountActionsActionIdAppealPost({
    @Path('action_id') required String? actionId,
    @Body() required AppealIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'The one appeal against a warn, hide or suspend; the grievance officer decides.',
      summary: 'Appeal',
      operationId: 'market_link_appeal',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Appeal Photo
  ///@param action_id
  Future<chopper.Response<AccountActionOut>>
  v1MarketLinkAccountActionsActionIdAppealPhotosPost({
    required String? actionId,
    required Object? body,
  }) {
    generatedMapping.putIfAbsent(
      AccountActionOut,
      () => AccountActionOut.fromJsonFactory,
    );

    return _v1MarketLinkAccountActionsActionIdAppealPhotosPost(
      actionId: actionId,
      body: body,
    );
  }

  ///Appeal Photo
  ///@param action_id
  @POST(
    path: '/v1/market-link/account-actions/{action_id}/appeal/photos',
    optionalBody: true,
  )
  Future<chopper.Response<AccountActionOut>>
  _v1MarketLinkAccountActionsActionIdAppealPhotosPost({
    @Path('action_id') required String? actionId,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Adds one optional JPEG to the caller\'s open appeal (EXIF stripped by the server).',
      summary: 'Appeal Photo',
      operationId: 'market_link_appeal_photo',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Blocks
  Future<chopper.Response<BlocksResponse>> v1MarketLinkBlocksGet() {
    generatedMapping.putIfAbsent(
      BlocksResponse,
      () => BlocksResponse.fromJsonFactory,
    );

    return _v1MarketLinkBlocksGet();
  }

  ///Blocks
  @GET(path: '/v1/market-link/blocks')
  Future<chopper.Response<BlocksResponse>> _v1MarketLinkBlocksGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Blocks',
      operationId: 'market_link_blocks',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Unblock
  ///@param user_id
  Future<chopper.Response> v1MarketLinkBlocksUserIdDelete({
    required String? userId,
  }) {
    return _v1MarketLinkBlocksUserIdDelete(userId: userId);
  }

  ///Unblock
  ///@param user_id
  @DELETE(path: '/v1/market-link/blocks/{user_id}')
  Future<chopper.Response> _v1MarketLinkBlocksUserIdDelete({
    @Path('user_id') required String? userId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Unblock',
      operationId: 'market_link_unblock',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Block
  ///@param user_id
  Future<chopper.Response> v1MarketLinkBlocksUserIdPut({
    required String? userId,
  }) {
    return _v1MarketLinkBlocksUserIdPut(userId: userId);
  }

  ///Block
  ///@param user_id
  @PUT(path: '/v1/market-link/blocks/{user_id}', optionalBody: true)
  Future<chopper.Response> _v1MarketLinkBlocksUserIdPut({
    @Path('user_id') required String? userId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Block a user: neither sees the other in lists or interests. Repeating it is a no-op.',
      summary: 'Block',
      operationId: 'market_link_block',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
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
of that role once. Only within 7 days of completion, then 409 `rating_locked`; accounts
seen on one phone cannot rate each other (409 `same_device`, spec §4C).''',
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
verified buyer / broker while `lot_visible_to_traders` shows the lot, or for the parties
of an accepted interest on it (L4). Only the derived key is signed.''',
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
  ///@param crop
  ///@param before
  Future<chopper.Response<BuyerLotsResponse>> v1MarketLinkLotsGet({
    String? district,
    String? crop,
    String? before,
  }) {
    generatedMapping.putIfAbsent(
      BuyerLotsResponse,
      () => BuyerLotsResponse.fromJsonFactory,
    );

    return _v1MarketLinkLotsGet(district: district, crop: crop, before: before);
  }

  ///List Lots
  ///@param district
  ///@param crop
  ///@param before
  @GET(path: '/v1/market-link/lots')
  Future<chopper.Response<BuyerLotsResponse>> _v1MarketLinkLotsGet({
    @Query('district') String? district,
    @Query('crop') String? crop,
    @Query('before') String? before,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Published lots, newest first, for admin-verified buyers and brokers only (403
`not_verified` for anyone else); while the season package is ON, only lots with an active
package (§4E). Page with `before` = the last `published_at` seen.''',
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
      description: '''The interests on the caller\'s own lot, oldest first, to compare side by side. An
interest whose trader or broker is no longer verified (decision h), is hidden, suspended
or deleted, or blocked either way with the grower (§4C), is left out.''',
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

  ///Package Status
  Future<chopper.Response<PackageStatus>> v1MarketLinkPackageGet() {
    generatedMapping.putIfAbsent(
      PackageStatus,
      () => PackageStatus.fromJsonFactory,
    );

    return _v1MarketLinkPackageGet();
  }

  ///Package Status
  @GET(path: '/v1/market-link/package')
  Future<chopper.Response<PackageStatus>> _v1MarketLinkPackageGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''While the switch is ON, the caller\'s active packages (end dates); the app shows
"package active until <date>" or "not active" on each published lot.''',
      summary: 'Package Status',
      operationId: 'market_link_package_status',
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
(mean of the question averages; unrated last) or by completed deals. Hidden, suspended,
deleted and blocked (either way) profiles are left out (§4C).''',
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
      description: '''One verified profile; an unverified, hidden, suspended, deleted or blocked one answers
404 as if absent.''',
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

  ///Report
  Future<chopper.Response<ReportOut>> v1MarketLinkReportsPost({
    required ReportIn? body,
  }) {
    generatedMapping.putIfAbsent(ReportOut, () => ReportOut.fromJsonFactory);

    return _v1MarketLinkReportsPost(body: body);
  }

  ///Report
  @POST(path: '/v1/market-link/reports', optionalBody: true)
  Future<chopper.Response<ReportOut>> _v1MarketLinkReportsPost({
    @Body() required ReportIn? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Report to the admin queue. A second report of the same subject by the same person
while the first is open returns the first.''',
      summary: 'Report',
      operationId: 'market_link_report',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///My Reports
  Future<chopper.Response<ReportsResponse>> v1MarketLinkReportsMineGet() {
    generatedMapping.putIfAbsent(
      ReportsResponse,
      () => ReportsResponse.fromJsonFactory,
    );

    return _v1MarketLinkReportsMineGet();
  }

  ///My Reports
  @GET(path: '/v1/market-link/reports/mine')
  Future<chopper.Response<ReportsResponse>> _v1MarketLinkReportsMineGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'My Reports',
      operationId: 'market_link_my_reports',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  });

  ///Report Photo
  ///@param report_id
  Future<chopper.Response<ReportOut>> v1MarketLinkReportsReportIdPhotosPost({
    required String? reportId,
    required Object? body,
  }) {
    generatedMapping.putIfAbsent(ReportOut, () => ReportOut.fromJsonFactory);

    return _v1MarketLinkReportsReportIdPhotosPost(
      reportId: reportId,
      body: body,
    );
  }

  ///Report Photo
  ///@param report_id
  @POST(path: '/v1/market-link/reports/{report_id}/photos', optionalBody: true)
  Future<chopper.Response<ReportOut>> _v1MarketLinkReportsReportIdPhotosPost({
    @Path('report_id') required String? reportId,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Adds one optional JPEG to the caller\'s open report (EXIF stripped by the server).',
      summary: 'Report Photo',
      operationId: 'market_link_report_photo',
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

  ///Get Market Price History
  ///@param crop
  ///@param market
  ///@param variety
  ///@param grade
  ///@param days
  Future<chopper.Response<MarketPriceHistory>> v1MarketPricesHistoryGet({
    required String? crop,
    required String? market,
    String? variety,
    String? grade,
    int? days,
  }) {
    generatedMapping.putIfAbsent(
      MarketPriceHistory,
      () => MarketPriceHistory.fromJsonFactory,
    );

    return _v1MarketPricesHistoryGet(
      crop: crop,
      market: market,
      variety: variety,
      grade: grade,
      days: days,
    );
  }

  ///Get Market Price History
  ///@param crop
  ///@param market
  ///@param variety
  ///@param grade
  ///@param days
  @GET(path: '/v1/market/prices/history')
  Future<chopper.Response<MarketPriceHistory>> _v1MarketPricesHistoryGet({
    @Query('crop') required String? crop,
    @Query('market') required String? market,
    @Query('variety') String? variety,
    @Query('grade') String? grade,
    @Query('days') int? days,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Owner 2026-11-09 (price trend chart): the stored price (₹ per quintal) of one mandi for
each day of the last `days` days (at most 90), oldest first, as published. A day without a
published price is absent, never estimated. `variety` / `grade` are as in /market/prices
(empty when the source left them blank); `stale` / `reason` as there.''',
      summary: 'Get Market Price History',
      operationId: 'market_price_history_get',
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
backed-up photos and (when configured) the sign-in account. It cannot be undone.
Market-link profiles and lots are hidden at once and erased after 180 days (Q68).''',
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
      description: '''Register this phone for push alerts; repeating it is harmless. With the market link on,
the account is also remembered on this phone (hashed token) so that two accounts on one
phone cannot rate each other (spec v1.5 §4C, Q100).''',
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

  ///Delete Sample
  ///@param photo_id
  Future<chopper.Response> v1PhotoAnalysisPhotoIdDelete({
    required String? photoId,
  }) {
    return _v1PhotoAnalysisPhotoIdDelete(photoId: photoId);
  }

  ///Delete Sample
  ///@param photo_id
  @DELETE(path: '/v1/photo-analysis/{photo_id}')
  Future<chopper.Response> _v1PhotoAnalysisPhotoIdDelete({
    @Path('photo_id') required String? photoId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Deletes the caller\'s own analysed photo and its result (also when the app deletes the
scouting entry it belongs to). 502 when storage fails; nothing is deleted then.''',
      summary: 'Delete Sample',
      operationId: 'photo_analysis_delete',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["photo-analysis"],
      deprecated: false,
    ),
  });

  ///Analyse Photo
  ///@param plot_id
  Future<chopper.Response<PhotoAnalysisOut>> v1PlotsPlotIdPhotoAnalysisPost({
    required String? plotId,
    required BodyPhotoAnalysisCreate body,
  }) {
    generatedMapping.putIfAbsent(
      PhotoAnalysisOut,
      () => PhotoAnalysisOut.fromJsonFactory,
    );

    return _v1PlotsPlotIdPhotoAnalysisPost(plotId: plotId, body: body);
  }

  ///Analyse Photo
  ///@param plot_id
  @POST(path: '/v1/plots/{plot_id}/photo-analysis', optionalBody: true)
  @Multipart()
  Future<chopper.Response<PhotoAnalysisOut>> _v1PlotsPlotIdPhotoAnalysisPost({
    @Path('plot_id') required String? plotId,
    @Part() required BodyPhotoAnalysisCreate body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''Analyses one crop photo of the caller\'s own plot (owner Q135).

429 `analysis_limit`: `error.details` has `limit` (daily | monthly | total), `max` and
`resets_at` (UTC); the `Retry-After` header has the seconds until then. 503
`analysis_unavailable`: no API key on the server. 502 `analysis_failed`: the model could
not answer; nothing is stored or counted.''',
      summary: 'Analyse Photo',
      operationId: 'photo_analysis_create',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["photo-analysis"],
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
