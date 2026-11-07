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
  Future<Response<PackageCompanyOut>>
  _v1AdminMarketLinkPackageCompanyProfileGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/package/company-profile');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PackageCompanyOut, PackageCompanyOut>($request);
  }

  @override
  Future<Response<PackageCompanyOut>>
  _v1AdminMarketLinkPackageCompanyProfilePut({
    required PackageCompanyIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/package/company-profile');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PackageCompanyOut, PackageCompanyOut>($request);
  }

  @override
  Future<Response<dynamic>>
  _v1AdminMarketLinkPackageCompanyProfileMerchantQrGet({
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/package/company-profile/merchant-qr',
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<PackageCompanyOut>>
  _v1AdminMarketLinkPackageCompanyProfileMerchantQrPut({
    required Object? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/package/company-profile/merchant-qr',
    );
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PackageCompanyOut, PackageCompanyOut>($request);
  }

  @override
  Future<Response<PackageGrantsResponse>> _v1AdminMarketLinkPackageGrantsGet({
    String? growerId,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/package/grants');
    final Map<String, dynamic> $params = <String, dynamic>{
      'grower_id': growerId,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<PackageGrantsResponse, PackageGrantsResponse>($request);
  }

  @override
  Future<Response<PackageGrantOut>> _v1AdminMarketLinkPackageGrantsPost({
    required PackageGrantIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/package/grants');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PackageGrantOut, PackageGrantOut>($request);
  }

  @override
  Future<Response<PackageGrantOut>>
  _v1AdminMarketLinkPackageGrantsGrantIdRevokePost({
    required String? grantId,
    required PackageRevokeIn? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/v1/admin/market-link/package/grants/${grantId}/revoke',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PackageGrantOut, PackageGrantOut>($request);
  }

  @override
  Future<Response<PackageGrowersResponse>> _v1AdminMarketLinkPackageGrowersGet({
    required String? phone,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/package/growers');
    final Map<String, dynamic> $params = <String, dynamic>{'phone': phone};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<PackageGrowersResponse, PackageGrowersResponse>(
      $request,
    );
  }

  @override
  Future<Response<PackageSettingsOut>> _v1AdminMarketLinkPackageSettingsGet({
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/package/settings');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PackageSettingsOut, PackageSettingsOut>($request);
  }

  @override
  Future<Response<PackageSettingsOut>> _v1AdminMarketLinkPackageSettingsPut({
    required PackageSettingsIn? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/admin/market-link/package/settings');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PackageSettingsOut, PackageSettingsOut>($request);
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
  Future<Response<LotPhotoStored>> _v1MarketLinkLotPhotosPhotoIdPhotoPut({
    required String? photoId,
    required Object? body,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/lot-photos/${photoId}/photo');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<LotPhotoStored, LotPhotoStored>($request);
  }

  @override
  Future<Response<LotPhotoUrl>> _v1MarketLinkLotPhotosPhotoIdUrlGet({
    required String? photoId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''A short-lived download URL for an uploaded lot photo: for the grower, or for a
verified buyer / broker while `lot_visible_to_traders` shows the lot. Only the derived
key is signed.''',
      summary: 'Lot Photo Url',
      operationId: 'market_link_lot_photo_url',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/v1/market-link/lot-photos/${photoId}/url');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<LotPhotoUrl, LotPhotoUrl>($request);
  }

  @override
  Future<Response<BuyerLotsResponse>> _v1MarketLinkLotsGet({
    String? district,
    String? crop,
    String? before,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/lots');
    final Map<String, dynamic> $params = <String, dynamic>{
      'district': district,
      'crop': crop,
      'before': before,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<BuyerLotsResponse, BuyerLotsResponse>($request);
  }

  @override
  Future<Response<GrowerLotOut>> _v1MarketLinkLotsLotIdClosePost({
    required String? lotId,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Takes a published lot off the buyers\' list (the grower sold it or changed their mind).',
      summary: 'Close Lot',
      operationId: 'market_link_close_lot',
      consumes: [],
      produces: [],
      security: ["HTTPBearer"],
      tags: ["market-link"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/v1/market-link/lots/${lotId}/close');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<GrowerLotOut, GrowerLotOut>($request);
  }

  @override
  Future<Response<GrowerLotOut>> _v1MarketLinkLotsLotIdPublishPost({
    required String? lotId,
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
  }) {
    final Uri $url = Uri.parse('/v1/market-link/lots/${lotId}/publish');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<GrowerLotOut, GrowerLotOut>($request);
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
