import 'dart:convert';

import 'package:chopper/chopper.dart';

import '../api/generated/bagmitra.swagger.dart';

/// A refused or failed feed admin call, carrying the server's code and reason
/// (e.g. `approve_refused` while output-check issues are open, or `ai_off`).
class FeedAdminException implements Exception {
  const FeedAdminException(this.message, {this.status, this.code});
  final String message;
  final int? status;
  final String? code;

  /// The AI draft answers 503 when FEED_AI_API_KEY is not set (or the model is down).
  bool get aiUnavailable => status == 503;

  @override
  String toString() => message;
}

/// Government feed admin operations (API `/v1/admin/feed`, role `feed_admin`). Online only.
abstract interface class FeedAdminRepository {
  Future<List<FeedAdminItemSummaryOut>> items({String status = 'in_review'});
  Future<FeedAdminItemOut> item(String id);
  Future<FeedAdminItemOut> create(FeedAdminItemIn body);
  Future<FeedAdminItemOut> setText(
    String id,
    String lang,
    String title,
    String? summary,
  );
  Future<FeedAdminItemOut> setTargets(
    String id,
    List<FeedAdminTargetIn> targets,
  );
  Future<FeedAdminItemOut> approve(
    String id, {
    bool acceptCheckIssues = false,
    String? comment,
  });
  Future<FeedAdminItemOut> publish(String id);
  Future<FeedAdminItemOut> withdraw(
    String id,
    String reason,
    String? replacedById,
  );
  Future<FeedAdminItemOut> aiDraft(String id);
  Future<List<FeedAdminSourceOut>> sources();
  Future<FeedAdminSourceOut> setTerms(String key, String status, String? notes);
}

class ApiFeedAdminRepository implements FeedAdminRepository {
  const ApiFeedAdminRepository(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    final (code, message) = _reason(res.error);
    throw FeedAdminException(
      message ?? 'HTTP ${res.statusCode}',
      status: res.statusCode,
      code: code,
    );
  }

  static (String?, String?) _reason(Object? error) {
    Object? decoded = error;
    if (error is String) {
      try {
        decoded = jsonDecode(error);
      } on FormatException {
        return (null, error);
      }
    }
    if (decoded case {
      'error':
          {'message': final String message} && final Map<Object?, Object?> e,
    }) {
      return (
        switch (e['code']) {
          final String code => code,
          _ => null,
        },
        message,
      );
    }
    return (null, null);
  }

  @override
  Future<List<FeedAdminItemSummaryOut>> items({
    String status = 'in_review',
  }) async => _ok(
    await _api.v1AdminFeedItemsGet(
      status: V1AdminFeedItemsGetStatus.values.firstWhere(
        (s) => s.value == status,
      ),
    ),
  ).items;

  @override
  Future<FeedAdminItemOut> item(String id) async =>
      _ok(await _api.v1AdminFeedItemsItemIdGet(itemId: id));

  @override
  Future<FeedAdminItemOut> create(FeedAdminItemIn body) async =>
      _ok(await _api.v1AdminFeedItemsPost(body: body));

  @override
  Future<FeedAdminItemOut> setText(
    String id,
    String lang,
    String title,
    String? summary,
  ) async => _ok(
    await _api.v1AdminFeedItemsItemIdTextsLangPut(
      itemId: id,
      lang: V1AdminFeedItemsItemIdTextsLangPutLang.values.byName(lang),
      body: FeedAdminTextIn(title: title, summary: summary),
    ),
  );

  @override
  Future<FeedAdminItemOut> setTargets(
    String id,
    List<FeedAdminTargetIn> targets,
  ) async => _ok(
    await _api.v1AdminFeedItemsItemIdTargetsPut(
      itemId: id,
      body: FeedAdminTargetsIn(targets: targets),
    ),
  );

  @override
  Future<FeedAdminItemOut> approve(
    String id, {
    bool acceptCheckIssues = false,
    String? comment,
  }) async => _ok(
    await _api.v1AdminFeedItemsItemIdApprovePost(
      itemId: id,
      body: FeedAdminApproveIn(
        acceptCheckIssues: acceptCheckIssues,
        comment: comment,
      ),
    ),
  );

  @override
  Future<FeedAdminItemOut> publish(String id) async =>
      _ok(await _api.v1AdminFeedItemsItemIdPublishPost(itemId: id));

  @override
  Future<FeedAdminItemOut> withdraw(
    String id,
    String reason,
    String? replacedById,
  ) async => _ok(
    await _api.v1AdminFeedItemsItemIdWithdrawPost(
      itemId: id,
      body: FeedAdminWithdrawIn(reason: reason, replacedById: replacedById),
    ),
  );

  @override
  Future<FeedAdminItemOut> aiDraft(String id) async =>
      _ok(await _api.v1AdminFeedItemsItemIdAiDraftPost(itemId: id));

  @override
  Future<List<FeedAdminSourceOut>> sources() async =>
      _ok(await _api.v1AdminFeedSourcesGet()).sources;

  @override
  Future<FeedAdminSourceOut> setTerms(
    String key,
    String status,
    String? notes,
  ) async => _ok(
    await _api.v1AdminFeedSourcesKeyTermsPut(
      key: key,
      body: FeedAdminTermsIn(
        termsStatus: FeedAdminTermsInTermsStatus.values.byName(status),
        notes: notes,
      ),
    ),
  );
}
