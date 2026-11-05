import 'package:chopper/chopper.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../sync/account_guard.dart';
import '../../auth/domain/auth.dart';

/// The deletion could not reach the server or the server refused it; nothing on the phone
/// was touched, so the grower can try again.
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.reason);
  final String reason;

  @override
  String toString() => 'AccountDeletionException($reason)';
}

/// Erases the signed-in account on the server (`DELETE /v1/me`).
abstract interface class AccountDeletionApi {
  Future<void> eraseServerAccount();
}

class HttpAccountDeletionApi implements AccountDeletionApi {
  const HttpAccountDeletionApi(this._api);
  final Bagmitra _api;

  @override
  Future<void> eraseServerAccount() async {
    final Response<AccountDeleted> resp;
    try {
      resp = await _api.v1MeDelete();
    } on Exception catch (e) {
      throw AccountDeletionException('network: ${e.runtimeType}');
    }
    if (!resp.isSuccessful) {
      throw AccountDeletionException('http ${resp.statusCode}');
    }
  }
}

/// Demo builds have no server: there is nothing to erase there.
class NoServerAccountDeletionApi implements AccountDeletionApi {
  const NoServerAccountDeletionApi();

  @override
  Future<void> eraseServerAccount() async {}
}

/// "Delete my account and data" (S-10 / Play account deletion): the server first, so a
/// failure leaves everything as it was; then this phone's records and photos; then sign-out.
class AccountDeletion {
  const AccountDeletion({
    required this._api,
    required this._guard,
    required this._auth,
  });

  final AccountDeletionApi _api;
  final AccountGuard _guard;
  final AuthRepository _auth;

  /// Throws [AccountDeletionException] when the server part fails (nothing changed).
  Future<void> run() async {
    await _api.eraseServerAccount();
    await _guard.eraseAll();
    // A sync that was already on its way may have pushed a last write after the first
    // call: erase once more while the session still exists. Best effort.
    try {
      await _api.eraseServerAccount();
    } on AccountDeletionException {
      // The first call already erased the account; this one only catches a straggler.
    }
    await _auth.signOut();
  }
}
