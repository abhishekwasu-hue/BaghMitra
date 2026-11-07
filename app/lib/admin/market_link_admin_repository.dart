import 'package:chopper/chopper.dart';

import '../api/generated/bagmitra.swagger.dart';
import 'kb_admin_repository.dart' show KbAdminException, adminErrorMessage;

/// Supabase app_metadata role for the market linkage admin (runbook admin-web §5अ).
const marketLinkAdminRole = 'market_link_admin';

/// Market linkage admin operations (API `/v1/admin/market-link`, role `market_link_admin`,
/// legal gate `MARKET_LINK_ENABLED`): the verification queue, per-check records and the
/// rating tags. Online only.
abstract interface class MarketLinkAdminRepository {
  /// Subjects waiting for a check, oldest first; [type] is buyer / broker / provider.
  Future<List<SubjectOut>> queue({String? type});
  Future<SubjectDetailOut> subject(String type, String id);

  /// Writes a new verification record (approve, or reject with a reason).
  Future<SubjectDetailOut> decide(
    String type,
    String id, {
    required bool approve,
    String? reason,
  });

  /// Records one check done by hand on the official page (L7, spec §4): [kind] is gstin /
  /// apmc / fssai / iec / apeda / phone_call / place_photo; [result] passed / failed /
  /// cancelled; [registeredYear] for GST only.
  Future<SubjectDetailOut> recordCheck(
    String type,
    String id, {
    required String kind,
    required String result,
    int? registeredYear,
  });

  /// A short-lived signed URL for the subject's document at [index].
  Future<String> documentUrl(String type, String id, int index);
  Future<List<RatingTagAdminOut>> ratingTags();
  Future<RatingTagAdminOut> saveRatingTag(String id, RatingTagIn body);
}

class ApiMarketLinkAdminRepository implements MarketLinkAdminRepository {
  const ApiMarketLinkAdminRepository(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    throw KbAdminException(
      adminErrorMessage(res.error) ?? 'HTTP ${res.statusCode}',
    );
  }

  static V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType _type(
    String t,
  ) => V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType.values
      .byName(t);

  @override
  Future<List<SubjectOut>> queue({String? type}) async =>
      _ok(await _api.v1AdminMarketLinkVerificationsGet(subjectType: type))
          .subjects;

  @override
  Future<SubjectDetailOut> subject(String type, String id) async => _ok(
    await _api.v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGet(
      subjectType: _type(type),
      subjectId: id,
    ),
  );

  @override
  Future<SubjectDetailOut> decide(
    String type,
    String id, {
    required bool approve,
    String? reason,
  }) async => _ok(
    await _api.v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPost(
      subjectType:
          V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
              .values
              .byName(type),
      subjectId: id,
      body: DecisionIn(
        status: approve ? DecisionInStatus.approved : DecisionInStatus.rejected,
        reason: reason,
      ),
    ),
  );

  @override
  Future<SubjectDetailOut> recordCheck(
    String type,
    String id, {
    required String kind,
    required String result,
    int? registeredYear,
  }) async => _ok(
    await _api.v1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPost(
      subjectType:
          V1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPostSubjectType
              .values
              .byName(type),
      subjectId: id,
      body: CheckIn(
        kind: CheckInKind.values.firstWhere((k) => k.value == kind),
        result: CheckInResult.values.byName(result),
        registeredYear: registeredYear,
      ),
    ),
  );

  @override
  Future<String> documentUrl(String type, String id, int index) async => _ok(
    await _api
        .v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGet(
          subjectType:
              V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
                  .values
                  .byName(type),
          subjectId: id,
          index: index,
        ),
  ).url;

  @override
  Future<List<RatingTagAdminOut>> ratingTags() async =>
      _ok(await _api.v1AdminMarketLinkRatingTagsGet()).tags;

  @override
  Future<RatingTagAdminOut> saveRatingTag(String id, RatingTagIn body) async =>
      _ok(
        await _api.v1AdminMarketLinkRatingTagsTagIdPut(tagId: id, body: body),
      );
}
