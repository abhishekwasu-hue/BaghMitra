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
