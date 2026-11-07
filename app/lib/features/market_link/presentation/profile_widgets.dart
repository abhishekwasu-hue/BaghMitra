import 'package:flutter/material.dart';

import '../../../core/formatting.dart';
import '../../../design_system/sync_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../data/registration_api.dart';
import '../domain/registration.dart';

String roleLabel(AppLocalizations t, RegistrationRole role) => switch (role) {
  RegistrationRole.trader => t.mlRoleTrader,
  RegistrationRole.exporter => t.mlRoleExporter,
  RegistrationRole.broker => t.mlRoleBroker,
  RegistrationRole.provider => t.mlRoleProvider,
};

String providerKindLabel(AppLocalizations t, ProviderKind kind) =>
    switch (kind) {
      ProviderKind.weighbridge => t.mlKindWeighbridge,
      ProviderKind.transporter => t.mlKindTransporter,
      ProviderKind.labourGang => t.mlKindLabourGang,
      ProviderKind.crateSupplier => t.mlKindCrateSupplier,
    };

/// The profile's kind as the grower reads it (trader, exporter, broker or a provider kind).
String profileKindLabel(AppLocalizations t, MarketProfile p) =>
    switch (p.kind) {
      'trader' => t.mlRoleTrader,
      'exporter' => t.mlRoleExporter,
      'broker' => t.mlRoleBroker,
      final k => switch (ProviderKind.fromApi(k)) {
        final kind? => providerKindLabel(t, kind),
        null => t.mlRoleProvider,
      },
    };

String docLabel(AppLocalizations t, DocKind doc) => switch (doc) {
  DocKind.gst => t.mlFieldGst,
  DocKind.apmc => t.mlFieldApmc,
  DocKind.fssai => t.mlFieldFssai,
  DocKind.iec => t.mlFieldIec,
  DocKind.apeda => t.mlFieldApeda,
  DocKind.certificate => t.mlDocCertificate,
};

/// What a badge says: what was checked and the date, never a guarantee (spec §4).
String badgeText(AppLocalizations t, ProfileBadge b, String lang) {
  final on = formatDate(b.on, lang);
  return switch (b.kind) {
    'checked' => t.mlBadgeChecked(on),
    'registered_from' => t.mlBadgeRegisteredFrom(b.place ?? '—', on),
    _ => t.mlBadgePlacePhoto(on),
  };
}

/// The banner for a failed market-link call: offline, server, or the server's refusal.
class MarketCallBanner extends StatelessWidget {
  const MarketCallBanner(this.error, {super.key, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final offline =
        error is MarketCallException &&
        (error as MarketCallException).problem == MarketCallProblem.offline;
    return SyncBanner(
      kind: offline ? SyncBannerKind.offline : SyncBannerKind.server,
      message: offline ? t.mlOffline : t.mlServerBusy,
      actionLabel: onRetry == null ? null : t.mlRetry,
      onAction: onRetry,
    );
  }
}
