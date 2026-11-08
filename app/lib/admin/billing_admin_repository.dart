import 'package:chopper/chopper.dart';

import '../api/generated/bagmitra.enums.swagger.dart' as enums;
import '../api/generated/bagmitra.swagger.dart';
import 'package_admin_repository.dart' show PackageAdminException;

/// Role that may change the subscription switch and the per-role amounts.
const billingAdminRole = 'billing_admin';

/// The five roles with one monthly plan each (billing addendum §7), in page order.
const billingRoles = ['grower', 'trader', 'broker', 'exporter', 'provider'];

/// Subscription switch and per-role monthly amounts (API `/v1/admin/billing`, role
/// `billing_admin`, addendum §7). Admin web only; online only. A saved amount goes to
/// Google Play first; the page shows the price Play reports.
abstract interface class BillingAdminRepository {
  Future<BillingSettingsOut> settings();
  Future<BillingSettingsOut> saveSwitch({
    required bool enabled,
    DateTime? startsOn,
  });

  /// [paise] null clears the amount (the role is free again).
  Future<BillingSettingsOut> saveAmount(String role, int? paise);

  /// Existing subscribers of [role] move to the last Play price (opt-in increase).
  Future<BillingSettingsOut> migratePrices(String role);
}

class ApiBillingAdminRepository implements BillingAdminRepository {
  const ApiBillingAdminRepository(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    final code = switch (res.statusCode) {
      503 => 'play_not_set_up',
      502 => 'play_error',
      409 => 'no_play_price',
      _ => null,
    };
    throw PackageAdminException(code ?? 'HTTP ${res.statusCode}', code);
  }

  @override
  Future<BillingSettingsOut> settings() async =>
      _ok(await _api.v1AdminBillingSettingsGet());

  @override
  Future<BillingSettingsOut> saveSwitch({
    required bool enabled,
    DateTime? startsOn,
  }) async => _ok(
    await _api.v1AdminBillingSettingsPut(
      body: SwitchIn(enabled: enabled, startsOn: startsOn),
    ),
  );

  @override
  Future<BillingSettingsOut> saveAmount(String role, int? paise) async => _ok(
    await _api.v1AdminBillingRolesRoleAmountPut(
      role: enums.V1AdminBillingRolesRoleAmountPutRole.values.byName(role),
      body: RoleAmountIn(amountPaise: paise),
    ),
  );

  @override
  Future<BillingSettingsOut> migratePrices(String role) async => _ok(
    await _api.v1AdminBillingRolesRoleMigratePricesPost(
      role: enums.V1AdminBillingRolesRoleMigratePricesPostRole.values.byName(
        role,
      ),
      body: const MigrateIn(confirm: true),
    ),
  );
}
