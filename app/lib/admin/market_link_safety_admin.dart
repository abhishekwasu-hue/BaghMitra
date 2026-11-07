import 'package:chopper/chopper.dart';

import '../api/generated/bagmitra.swagger.dart';
import 'kb_admin_repository.dart' show KbAdminException, adminErrorMessage;

/// Market link trust and safety for the admin (API `/v1/admin/market-link`, role
/// `market_link_admin`): the report queue, actions with a reason code and the appeals the
/// grievance officer decides (spec v1.5 §4, §4C). Online only.
abstract interface class MarketLinkSafetyAdmin {
  /// Reports in [status] (open / actioned / dismissed), oldest first.
  Future<List<ReportAdminOut>> reports(String status);
  Future<void> acknowledgeReport(String id);

  /// warn / hide / suspend with a platform-rule reason code.
  Future<void> actOnReport(String id, String action, String reasonCode);
  Future<void> dismissReport(String id);
  Future<String> reportPhotoUrl(String id, int index);

  /// Appeals waiting for a decision, oldest first.
  Future<List<ActionOut>> appeals();
  Future<void> acknowledgeAppeal(String actionId);
  Future<void> decideAppeal(String actionId, {required bool upheld});
  Future<String> appealPhotoUrl(String actionId, int index);
}

/// Reason codes an admin may give with warn / hide / suspend: platform rules only, never a
/// payment, weight or quality quarrel (Addendum 5, Q93).
const platformReasons = [
  'fake_identity',
  'fake_lot',
  'impersonation',
  'fake_rating',
  'abuse',
  'duplicate_user',
];

class ApiMarketLinkSafetyAdmin implements MarketLinkSafetyAdmin {
  const ApiMarketLinkSafetyAdmin(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    throw KbAdminException(
      adminErrorMessage(res.error) ?? 'HTTP ${res.statusCode}',
    );
  }

  @override
  Future<List<ReportAdminOut>> reports(String status) async => _ok(
    await _api.v1AdminMarketLinkReportsGet(
      status: V1AdminMarketLinkReportsGetStatus.values.firstWhere(
        (s) => s.value == status,
      ),
    ),
  ).reports;

  @override
  Future<void> acknowledgeReport(String id) async => _ok(
    await _api.v1AdminMarketLinkReportsReportIdAcknowledgePost(reportId: id),
  );

  @override
  Future<void> actOnReport(String id, String action, String reasonCode) async =>
      _ok(
        await _api.v1AdminMarketLinkReportsReportIdDecisionPost(
          reportId: id,
          body: ReportDecisionIn(
            action: ReportDecisionInAction.values.firstWhere(
              (a) => a.value == action,
            ),
            reasonCode: ReportDecisionInReasonCode.values.firstWhere(
              (r) => r.value == reasonCode,
            ),
          ),
        ),
      );

  @override
  Future<void> dismissReport(String id) async =>
      _ok(await _api.v1AdminMarketLinkReportsReportIdDismissPost(reportId: id));

  @override
  Future<String> reportPhotoUrl(String id, int index) async => _ok(
    await _api.v1AdminMarketLinkReportsReportIdPhotosIndexUrlGet(
      reportId: id,
      index: index,
    ),
  ).url;

  @override
  Future<List<ActionOut>> appeals() async =>
      _ok(await _api.v1AdminMarketLinkAppealsGet()).actions;

  @override
  Future<void> acknowledgeAppeal(String actionId) async => _ok(
    await _api.v1AdminMarketLinkAppealsActionIdAcknowledgePost(
      actionId: actionId,
    ),
  );

  @override
  Future<void> decideAppeal(String actionId, {required bool upheld}) async =>
      _ok(
        await _api.v1AdminMarketLinkAppealsActionIdDecisionPost(
          actionId: actionId,
          body: AppealDecisionIn(
            outcome: upheld
                ? AppealDecisionInOutcome.upheld
                : AppealDecisionInOutcome.rejected,
          ),
        ),
      );

  @override
  Future<String> appealPhotoUrl(String actionId, int index) async => _ok(
    await _api.v1AdminMarketLinkAppealsActionIdPhotosIndexUrlGet(
      actionId: actionId,
      index: index,
    ),
  ).url;
}
