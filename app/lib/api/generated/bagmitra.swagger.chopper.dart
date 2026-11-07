// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'bagmitra.swagger.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Bagmitra extends Bagmitra {
  _$Bagmitra([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Bagmitra;

  @override
  Future<Response<LiveResponse>> _healthLiveGet({
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
  }) {
    final Uri $url = Uri.parse('/health/live');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<LiveResponse, LiveResponse>($request);
  }

  @override
  Future<Response<ReadyResponse>> _healthReadyGet({
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
  }) {
    final Uri $url = Uri.parse('/health/ready');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ReadyResponse, ReadyResponse>($request);
  }

  @override
  Future<Response<EventsResponse>> _v1AdminBillingEventsGet({
    int? limit,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/billing/events');
    final Map<String, dynamic> $params = <String, dynamic>{'limit': limit};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<EventsResponse, EventsResponse>($request);
  }

  @override
  Future<Response<SubscriptionOut>> _v1AdminBillingGrantsPost({
    required GrantIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/billing/grants');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SubscriptionOut, SubscriptionOut>($request);
  }

  @override
  Future<Response<SubscriptionOut>> _v1AdminBillingGrantsGrantIdRevokePost({
    required String? grantId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/billing/grants/${grantId}/revoke');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SubscriptionOut, SubscriptionOut>($request);
  }

  @override
  Future<Response<PlansResponse>> _v1AdminBillingPlansGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/billing/plans');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PlansResponse, PlansResponse>($request);
  }

  @override
  Future<Response<PlanOut>> _v1AdminBillingPlansKeyPut({
    required String? key,
    required PlanIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/billing/plans/${key}');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PlanOut, PlanOut>($request);
  }

  @override
  Future<Response<SubscriptionsResponse>> _v1AdminBillingSubscriptionsGet({
    String? subjectId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/billing/subscriptions');
    final Map<String, dynamic> $params = <String, dynamic>{
      'subject_id': subjectId,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SubscriptionsResponse, SubscriptionsResponse>($request);
  }

  @override
  Future<Response<FeedAdminItemsResponse>> _v1AdminFeedItemsGet({
    String? status,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items');
    final Map<String, dynamic> $params = <String, dynamic>{'status': status};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemsResponse, FeedAdminItemsResponse>(
      $request,
    );
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsPost({
    required FeedAdminItemIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdGet({
    required String? itemId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdAiDraftPost({
    required String? itemId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/ai-draft');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdApprovePost({
    required String? itemId,
    required FeedAdminApproveIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/approve');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdCardPut({
    required String? itemId,
    required FeedAdminCardIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/card');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdDatesPut({
    required String? itemId,
    required FeedAdminDatesIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/dates');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdPublishPost({
    required String? itemId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/publish');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdTargetsPut({
    required String? itemId,
    required FeedAdminTargetsIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/targets');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdTextsLangPut({
    required String? itemId,
    required String? lang,
    required FeedAdminTextIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/texts/${lang}');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminItemOut>> _v1AdminFeedItemsItemIdWithdrawPost({
    required String? itemId,
    required FeedAdminWithdrawIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/items/${itemId}/withdraw');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminItemOut, FeedAdminItemOut>($request);
  }

  @override
  Future<Response<FeedAdminSourcesResponse>> _v1AdminFeedSourcesGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/sources');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminSourcesResponse, FeedAdminSourcesResponse>(
      $request,
    );
  }

  @override
  Future<Response<FeedAdminSourceOut>> _v1AdminFeedSourcesKeyTermsPut({
    required String? key,
    required FeedAdminTermsIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/feed/sources/${key}/terms');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedAdminSourceOut, FeedAdminSourceOut>($request);
  }

  @override
  Future<Response<AlertsResponse>> _v1AdminKbAlertsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/alerts');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<AlertsResponse, AlertsResponse>($request);
  }

  @override
  Future<Response<AlertOut>> _v1AdminKbAlertsAlertIdResolvePost({
    required String? alertId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/alerts/${alertId}/resolve');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<AlertOut, AlertOut>($request);
  }

  @override
  Future<Response<CardsResponse>> _v1AdminKbCardsGet({
    String? status,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/cards');
    final Map<String, dynamic> $params = <String, dynamic>{'status': status};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<CardsResponse, CardsResponse>($request);
  }

  @override
  Future<Response<CardOut>> _v1AdminKbCardsCardIdPublishPost({
    required String? cardId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/cards/${cardId}/publish');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<CardOut, CardOut>($request);
  }

  @override
  Future<Response<CardOut>> _v1AdminKbCardsCardIdReviewsPost({
    required String? cardId,
    required ReviewIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/cards/${cardId}/reviews');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<CardOut, CardOut>($request);
  }

  @override
  Future<Response<ImportOut>> _v1AdminKbImportsKindPost({
    required String? kind,
    required ImportIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/imports/${kind}');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ImportOut, ImportOut>($request);
  }

  @override
  Future<Response<SourcesResponse>> _v1AdminKbSourcesGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/sources');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SourcesResponse, SourcesResponse>($request);
  }

  @override
  Future<Response<SourceOut>> _v1AdminKbSourcesKeyDocumentPut({
    required String? key,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/kb/sources/${key}/document');
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SourceOut, SourceOut>($request);
  }

  @override
  Future<Response<ActionsResponse>> _v1AdminMarketLinkActionsGet({
    String? subjectId,
    String? userId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/actions');
    final Map<String, dynamic> $params = <String, dynamic>{
      'subject_id': subjectId,
      'user_id': userId,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<ActionsResponse, ActionsResponse>($request);
  }

  @override
  Future<Response<ActionOut>> _v1AdminMarketLinkActionsPost({
    required ActionIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/actions');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ActionOut, ActionOut>($request);
  }

  @override
  Future<Response<ActionsResponse>> _v1AdminMarketLinkAppealsGet({
    String? state,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/appeals');
    final Map<String, dynamic> $params = <String, dynamic>{'state': state};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<ActionsResponse, ActionsResponse>($request);
  }

  @override
  Future<Response<ActionOut>> _v1AdminMarketLinkAppealsActionIdAcknowledgePost({
    required String? actionId,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/appeals/${actionId}/acknowledge',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ActionOut, ActionOut>($request);
  }

  @override
  Future<Response<ActionOut>> _v1AdminMarketLinkAppealsActionIdDecisionPost({
    required String? actionId,
    required AppealDecisionIn? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/appeals/${actionId}/decision',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ActionOut, ActionOut>($request);
  }

  @override
  Future<Response<PhotoDownloadUrl>>
  _v1AdminMarketLinkAppealsActionIdPhotosIndexUrlGet({
    required String? actionId,
    required int? index,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/appeals/${actionId}/photos/${index}/url',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PhotoDownloadUrl, PhotoDownloadUrl>($request);
  }

  @override
  Future<Response<RatingTagsAdminResponse>> _v1AdminMarketLinkRatingTagsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/rating-tags');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RatingTagsAdminResponse, RatingTagsAdminResponse>(
      $request,
    );
  }

  @override
  Future<Response<RatingTagAdminOut>> _v1AdminMarketLinkRatingTagsTagIdPut({
    required String? tagId,
    required RatingTagIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/rating-tags/${tagId}');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<RatingTagAdminOut, RatingTagAdminOut>($request);
  }

  @override
  Future<Response<ReportsAdminResponse>> _v1AdminMarketLinkReportsGet({
    String? status,
    String? subjectType,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/reports');
    final Map<String, dynamic> $params = <String, dynamic>{
      'status': status,
      'subject_type': subjectType,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<ReportsAdminResponse, ReportsAdminResponse>($request);
  }

  @override
  Future<Response<ReportAdminOut>>
  _v1AdminMarketLinkReportsReportIdAcknowledgePost({
    required String? reportId,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/reports/${reportId}/acknowledge',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ReportAdminOut, ReportAdminOut>($request);
  }

  @override
  Future<Response<ReportAdminOut>>
  _v1AdminMarketLinkReportsReportIdDecisionPost({
    required String? reportId,
    required ReportDecisionIn? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/reports/${reportId}/decision',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ReportAdminOut, ReportAdminOut>($request);
  }

  @override
  Future<Response<ReportAdminOut>>
  _v1AdminMarketLinkReportsReportIdDismissPost({
    required String? reportId,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/reports/${reportId}/dismiss',
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ReportAdminOut, ReportAdminOut>($request);
  }

  @override
  Future<Response<PhotoDownloadUrl>>
  _v1AdminMarketLinkReportsReportIdPhotosIndexUrlGet({
    required String? reportId,
    required int? index,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/reports/${reportId}/photos/${index}/url',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PhotoDownloadUrl, PhotoDownloadUrl>($request);
  }

  @override
  Future<Response<QueueResponse>> _v1AdminMarketLinkVerificationsGet({
    String? subjectType,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/verifications');
    final Map<String, dynamic> $params = <String, dynamic>{
      'subject_type': subjectType,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<QueueResponse, QueueResponse>($request);
  }

  @override
  Future<Response<SubjectDetailOut>>
  _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGet({
    required String? subjectType,
    required String? subjectId,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/verifications/${subjectType}/${subjectId}',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SubjectDetailOut, SubjectDetailOut>($request);
  }

  @override
  Future<Response<SubjectDetailOut>>
  _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPost({
    required String? subjectType,
    required String? subjectId,
    required DecisionIn? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/verifications/${subjectType}/${subjectId}/decision',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SubjectDetailOut, SubjectDetailOut>($request);
  }

  @override
  Future<Response<PhotoDownloadUrl>>
  _v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGet({
    required String? subjectType,
    required String? subjectId,
    required int? index,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/verifications/${subjectType}/${subjectId}/documents/${index}/url',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PhotoDownloadUrl, PhotoDownloadUrl>($request);
  }

  @override
  Future<Response<ManualPricesOut>> _v1AdminMarketPricesPost({
    required ManualPricesIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market/prices');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ManualPricesOut, ManualPricesOut>($request);
  }

  @override
  Future<Response<AppVersionResponse>> _v1AppVersionGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/app/version');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<AppVersionResponse, AppVersionResponse>($request);
  }

  @override
  Future<Response<EntitlementsResponse>> _v1BillingEntitlementsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/billing/entitlements');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<EntitlementsResponse, EntitlementsResponse>($request);
  }

  @override
  Future<Response<FeedResponse>> _v1FeedGet({
    String? lang,
    String? type,
    String? district,
    String? crop,
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
  }) {
    final Uri $url = Uri.parse('/v1/feed');
    final Map<String, dynamic> $params = <String, dynamic>{
      'lang': lang,
      'type': type,
      'district': district,
      'crop': crop,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<FeedResponse, FeedResponse>($request);
  }

  @override
  Future<Response<FeedCheckResponse>> _v1FeedCheckPost({
    String? lang,
    required FeedCheckIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/feed/check');
    final Map<String, dynamic> $params = <String, dynamic>{'lang': lang};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<FeedCheckResponse, FeedCheckResponse>($request);
  }

  @override
  Future<Response<FeedReceiptOut>> _v1FeedItemIdDismissPost({
    required String? itemId,
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
  }) {
    final Uri $url = Uri.parse('/v1/feed/${itemId}/dismiss');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedReceiptOut, FeedReceiptOut>($request);
  }

  @override
  Future<Response<FeedReceiptOut>> _v1FeedItemIdRemindPost({
    required String? itemId,
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
  }) {
    final Uri $url = Uri.parse('/v1/feed/${itemId}/remind');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedReceiptOut, FeedReceiptOut>($request);
  }

  @override
  Future<Response<FeedReceiptOut>> _v1FeedItemIdSeenPost({
    required String? itemId,
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
  }) {
    final Uri $url = Uri.parse('/v1/feed/${itemId}/seen');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedReceiptOut, FeedReceiptOut>($request);
  }

  @override
  Future<Response<InsuranceDeadlinesResponse>> _v1InsuranceDeadlinesGet({
    String? lang,
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
  }) {
    final Uri $url = Uri.parse('/v1/insurance/deadlines');
    final Map<String, dynamic> $params = <String, dynamic>{'lang': lang};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<InsuranceDeadlinesResponse, InsuranceDeadlinesResponse>(
      $request,
    );
  }

  @override
  Future<Response<GrowerCardsResponse>> _v1KnowledgeCardsGet({
    String? crop,
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
  }) {
    final Uri $url = Uri.parse('/v1/knowledge/cards');
    final Map<String, dynamic> $params = <String, dynamic>{'crop': crop};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<GrowerCardsResponse, GrowerCardsResponse>($request);
  }

  @override
  Future<Response<AccountActionsResponse>> _v1MarketLinkAccountActionsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/account-actions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<AccountActionsResponse, AccountActionsResponse>(
      $request,
    );
  }

  @override
  Future<Response<AccountActionOut>>
  _v1MarketLinkAccountActionsActionIdAppealPost({
    required String? actionId,
    required AppealIn? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/market-link/account-actions/${actionId}/appeal',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<AccountActionOut, AccountActionOut>($request);
  }

  @override
  Future<Response<AccountActionOut>>
  _v1MarketLinkAccountActionsActionIdAppealPhotosPost({
    required String? actionId,
    required Object? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/market-link/account-actions/${actionId}/appeal/photos',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<AccountActionOut, AccountActionOut>($request);
  }

  @override
  Future<Response<BlocksResponse>> _v1MarketLinkBlocksGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/blocks');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<BlocksResponse, BlocksResponse>($request);
  }

  @override
  Future<Response<dynamic>> _v1MarketLinkBlocksUserIdDelete({
    required String? userId,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/blocks/${userId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _v1MarketLinkBlocksUserIdPut({
    required String? userId,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/blocks/${userId}');
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<MyAcceptancesOut>> _v1MarketLinkMeAcceptancesGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/me/acceptances');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<MyAcceptancesOut, MyAcceptancesOut>($request);
  }

  @override
  Future<Response<RatingTagsResponse>> _v1MarketLinkRatingTagsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/rating-tags');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RatingTagsResponse, RatingTagsResponse>($request);
  }

  @override
  Future<Response<ReportOut>> _v1MarketLinkReportsPost({
    required ReportIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/reports');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ReportOut, ReportOut>($request);
  }

  @override
  Future<Response<ReportsResponse>> _v1MarketLinkReportsMineGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/reports/mine');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ReportsResponse, ReportsResponse>($request);
  }

  @override
  Future<Response<ReportOut>> _v1MarketLinkReportsReportIdPhotosPost({
    required String? reportId,
    required Object? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/reports/${reportId}/photos');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ReportOut, ReportOut>($request);
  }

  @override
  Future<Response<TermsOut>> _v1MarketLinkTermsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/terms');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<TermsOut, TermsOut>($request);
  }

  @override
  Future<Response<MyAcceptancesOut>> _v1MarketLinkTermsAcceptPost({
    required AcceptIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/terms/accept');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<MyAcceptancesOut, MyAcceptancesOut>($request);
  }

  @override
  Future<Response<MarketPrices>> _v1MarketPricesGet({
    required String? crop,
    String? scope,
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
  }) {
    final Uri $url = Uri.parse('/v1/market/prices');
    final Map<String, dynamic> $params = <String, dynamic>{
      'crop': crop,
      'scope': scope,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<MarketPrices, MarketPrices>($request);
  }

  @override
  Future<Response<AccountDeleted>> _v1MeDelete({
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
  }) {
    final Uri $url = Uri.parse('/v1/me');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<AccountDeleted, AccountDeleted>($request);
  }

  @override
  Future<Response<FarmerProfile>> _v1MeGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/me');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FarmerProfile, FarmerProfile>($request);
  }

  @override
  Future<Response<dynamic>> _v1MeDevicesDelete({
    required DeviceOut? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/me/devices');
    final $body = body;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _v1MeDevicesPost({
    required DeviceIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/me/devices');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<FeedPreferencesBody>> _v1MeFeedPreferencesGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/me/feed-preferences');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FeedPreferencesBody, FeedPreferencesBody>($request);
  }

  @override
  Future<Response<FeedPreferencesBody>> _v1MeFeedPreferencesPut({
    required FeedPreferencesBody? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/me/feed-preferences');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FeedPreferencesBody, FeedPreferencesBody>($request);
  }

  @override
  Future<Response<PlotWeather>> _v1PlotsPlotIdWeatherGet({
    required String? plotId,
    String? lang,
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
  }) {
    final Uri $url = Uri.parse('/v1/plots/${plotId}/weather');
    final Map<String, dynamic> $params = <String, dynamic>{'lang': lang};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<PlotWeather, PlotWeather>($request);
  }

  @override
  Future<Response<LabelClaimsResponse>> _v1ReferenceLabelClaimsGet({
    required String? crop,
    String? target,
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
  }) {
    final Uri $url = Uri.parse('/v1/reference/label-claims');
    final Map<String, dynamic> $params = <String, dynamic>{
      'crop': crop,
      'target': target,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<LabelClaimsResponse, LabelClaimsResponse>($request);
  }

  @override
  Future<Response<RestrictionsResponse>> _v1ReferenceRestrictionsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/reference/restrictions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<RestrictionsResponse, RestrictionsResponse>($request);
  }

  @override
  Future<Response<StageTemplatesResponse>> _v1ReferenceStageTemplatesGet({
    String? crop,
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
  }) {
    final Uri $url = Uri.parse('/v1/reference/stage-templates');
    final Map<String, dynamic> $params = <String, dynamic>{'crop': crop};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<StageTemplatesResponse, StageTemplatesResponse>(
      $request,
    );
  }

  @override
  Future<Response<PhotoUploadUrl>> _v1ScoutingRecordIdPhotoUploadUrlPost({
    required String? recordId,
    required PhotoUploadIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/scouting/${recordId}/photo-upload-url');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PhotoUploadUrl, PhotoUploadUrl>($request);
  }

  @override
  Future<Response<PhotoDownloadUrl>> _v1ScoutingRecordIdPhotoUrlGet({
    required String? recordId,
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
  }) {
    final Uri $url = Uri.parse('/v1/scouting/${recordId}/photo-url');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PhotoDownloadUrl, PhotoDownloadUrl>($request);
  }

  @override
  Future<Response<PullResponse>> _v1SyncPullGet({
    int? since,
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
  }) {
    final Uri $url = Uri.parse('/v1/sync/pull');
    final Map<String, dynamic> $params = <String, dynamic>{'since': since};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<PullResponse, PullResponse>($request);
  }

  @override
  Future<Response<PushResponse>> _v1SyncPushPost({
    required PushRequest? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/sync/push');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PushResponse, PushResponse>($request);
  }
}
