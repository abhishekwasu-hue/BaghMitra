import 'dart:convert';
import 'dart:typed_data';

import 'package:chopper/chopper.dart';

import '../api/generated/bagmitra.swagger.dart';
import 'kb_admin_repository.dart' show KbAdminException, adminErrorMessage;

/// Season sale package admin (API `/v1/admin/market-link/package`, role
/// `market_link_admin`, spec v1.5 §4E). Admin web only; online only.
abstract interface class PackageAdminRepository {
  Future<PackageCompanyOut> company();
  Future<PackageCompanyOut> saveCompany(PackageCompanyIn body);

  /// [type] is image/png or image/jpeg.
  Future<PackageCompanyOut> uploadQr(Uint8List bytes, String type);
  Future<Uint8List> merchantQr();
  Future<PackageSettingsOut> settings();
  Future<PackageSettingsOut> saveSettings(PackageSettingsIn body);
  Future<List<PackageGrowerOut>> findGrower(String phone);
  Future<PackageGrantOut> recordGrant(PackageGrantIn body);
  Future<List<PackageGrantOut>> grants(String growerId);
  Future<PackageGrantOut> revoke(String grantId, String reason);

  /// What the receipt PDF shows; refused while the company profile is empty.
  Future<ReceiptOut> receipt(String grantId);
}

/// The API's error code and message (the page shows the message; `missing: ...` names the
/// empty guard fields).
class PackageAdminException extends KbAdminException {
  const PackageAdminException(super.message, this.code);
  final String? code;
}

class ApiPackageAdminRepository implements PackageAdminRepository {
  const ApiPackageAdminRepository(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    throw PackageAdminException(
      adminErrorMessage(res.error) ?? 'HTTP ${res.statusCode}',
      _code(res.error),
    );
  }

  static String? _code(Object? error) {
    Object? decoded = error;
    if (error is String) {
      try {
        decoded = jsonDecode(error);
      } on FormatException {
        return null;
      }
    }
    return switch (decoded) {
      {'error': {'code': final String c}} => c,
      _ => null,
    };
  }

  static const _qrPath =
      '/v1/admin/market-link/package/company-profile/merchant-qr';

  @override
  Future<PackageCompanyOut> company() async =>
      _ok(await _api.v1AdminMarketLinkPackageCompanyProfileGet());

  @override
  Future<PackageCompanyOut> saveCompany(PackageCompanyIn body) async =>
      _ok(await _api.v1AdminMarketLinkPackageCompanyProfilePut(body: body));

  @override
  Future<PackageCompanyOut> uploadQr(Uint8List bytes, String type) async {
    // Raw image bytes: built on the same client (base URL, sign-in header).
    final res = await _api.client.send<PackageCompanyOut, PackageCompanyOut>(
      Request(
        'PUT',
        Uri.parse(_qrPath),
        _api.client.baseUrl,
        body: bytes,
        headers: {'Content-Type': type},
      ),
    );
    return _ok(res);
  }

  @override
  Future<Uint8List> merchantQr() async {
    final res = await _api.client.send<Uint8List, Uint8List>(
      Request('GET', Uri.parse(_qrPath), _api.client.baseUrl),
    );
    if (!res.isSuccessful) {
      throw PackageAdminException('HTTP ${res.statusCode}', null);
    }
    return res.bodyBytes;
  }

  @override
  Future<PackageSettingsOut> settings() async =>
      _ok(await _api.v1AdminMarketLinkPackageSettingsGet());

  @override
  Future<PackageSettingsOut> saveSettings(PackageSettingsIn body) async =>
      _ok(await _api.v1AdminMarketLinkPackageSettingsPut(body: body));

  @override
  Future<List<PackageGrowerOut>> findGrower(String phone) async =>
      _ok(await _api.v1AdminMarketLinkPackageGrowersGet(phone: phone)).growers;

  @override
  Future<PackageGrantOut> recordGrant(PackageGrantIn body) async =>
      _ok(await _api.v1AdminMarketLinkPackageGrantsPost(body: body));

  @override
  Future<List<PackageGrantOut>> grants(String growerId) async =>
      _ok(await _api.v1AdminMarketLinkPackageGrantsGet(growerId: growerId))
          .grants;

  @override
  Future<PackageGrantOut> revoke(String grantId, String reason) async => _ok(
    await _api.v1AdminMarketLinkPackageGrantsGrantIdRevokePost(
      grantId: grantId,
      body: PackageRevokeIn(reason: reason),
    ),
  );

  @override
  Future<ReceiptOut> receipt(String grantId) async => _ok(
    await _api.v1AdminMarketLinkPackageGrantsGrantIdReceiptGet(
      grantId: grantId,
    ),
  );
}
