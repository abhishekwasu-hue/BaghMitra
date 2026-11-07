import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';

/// Report reasons (spec v1.5 §4, Q82): codes only, no free text anywhere.
const reportReasons = [
  'fake_identity',
  'fake_lot',
  'impersonation',
  'fake_rating',
  'abuse',
];

/// The one appeal: a predefined reason (Q92), no free text.
const appealReasons = [
  'identity_genuine',
  'lot_genuine',
  'rating_genuine',
  'behaviour_proper',
  'not_duplicate',
];

/// What can be reported: a trader / exporter, broker or provider profile, a lot, a
/// rating or a user (`/v1/market-link/reports`).
const reportTargets = ['buyer', 'broker', 'provider', 'lot', 'rating', 'user'];

class SafetyException implements Exception {
  const SafetyException(this.status);
  final int status;
  @override
  String toString() => 'SafetyException($status)';
}

/// Trust and safety in the market link (spec v1.5 §4, §4C): report, block, the admin actions
/// about oneself and the one appeal. Online only; behind `AppConfig.marketLink`.
abstract interface class SafetyRepository {
  Future<void> report(
    String subjectType,
    String subjectId,
    String reason, {
    List<int>? photo,
  });
  Future<Set<String>> blockedUsers();
  Future<void> setBlocked(String userId, {required bool blocked});
  Future<List<AccountActionOut>> myActions();
  Future<void> appeal(String actionId, String reason, {List<int>? photo});
}

/// The generated enum member whose wire value is [code] (`fake_identity` -> `fakeIdentity`).
T _code<T>(List<T> values, String? Function(T) wire, String code) =>
    values.firstWhere((v) => wire(v) == code);

class ApiSafetyRepository implements SafetyRepository {
  const ApiSafetyRepository(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    throw SafetyException(res.statusCode);
  }

  /// A JPEG straight to the server, which strips its EXIF before storing (spec §4B).
  Future<void> _upload(String path, List<int> jpeg) async {
    final res = await _api.client.send<Object?, Object?>(
      Request(
        'POST',
        Uri.parse(path),
        _api.client.baseUrl,
        body: jpeg,
        headers: const {'Content-Type': 'image/jpeg'},
      ),
    );
    if (!res.isSuccessful) throw SafetyException(res.statusCode);
  }

  @override
  Future<void> report(
    String subjectType,
    String subjectId,
    String reason, {
    List<int>? photo,
  }) async {
    final out = _ok(
      await _api.v1MarketLinkReportsPost(
        body: ReportIn(
          subjectType: _code(
            ReportInSubjectType.values,
            (e) => e.value,
            subjectType,
          ),
          subjectId: subjectId,
          reason: _code(ReportInReason.values, (e) => e.value, reason),
        ),
      ),
    );
    if (photo != null) {
      await _upload('/v1/market-link/reports/${out.id}/photos', photo);
    }
  }

  @override
  Future<Set<String>> blockedUsers() async =>
      _ok(await _api.v1MarketLinkBlocksGet()).blockedUserIds.toSet();

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) async {
    final res = blocked
        ? await _api.v1MarketLinkBlocksUserIdPut(userId: userId)
        : await _api.v1MarketLinkBlocksUserIdDelete(userId: userId);
    if (!res.isSuccessful) throw SafetyException(res.statusCode);
  }

  @override
  Future<List<AccountActionOut>> myActions() async =>
      _ok(await _api.v1MarketLinkAccountActionsGet()).actions;

  @override
  Future<void> appeal(
    String actionId,
    String reason, {
    List<int>? photo,
  }) async {
    _ok(
      await _api.v1MarketLinkAccountActionsActionIdAppealPost(
        actionId: actionId,
        body: AppealIn(
          reason: _code(AppealInReason.values, (e) => e.value, reason),
        ),
      ),
    );
    if (photo != null) {
      await _upload(
        '/v1/market-link/account-actions/$actionId/appeal/photos',
        photo,
      );
    }
  }
}

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => ApiSafetyRepository(ref.watch(apiProvider)),
);

/// The grievance officer shown in the app (IT Rules 2021, spec §4C). L1 sets it from
/// `GET /v1/market-link/terms` by overriding this provider; until then it is null and the
/// screen names the default (the owner of BagMitra).
typedef GrievanceOfficer = ({String? name, String? contact});

final grievanceOfficerProvider = FutureProvider<GrievanceOfficer?>(
  (ref) async => null,
);
