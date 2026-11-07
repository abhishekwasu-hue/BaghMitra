import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/sync_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../market/domain/market_crops.dart';
import '../data/registration_api.dart';
import '../domain/registration.dart';

/// Opens the phone's dialer with [phone] (tap-to-call, spec §3 step 6); false when the
/// phone has no dialer. An interface point so widget tests never leave the app.
typedef PhoneDialer = Future<bool> Function(String phone);

final phoneDialerProvider = Provider<PhoneDialer>(
  (ref) => (phone) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: phone));
    } on Object {
      return false;
    }
  },
);

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
    'place_photo' => t.mlBadgePlacePhoto(on),
    'gst_checked' => switch (b.sinceYear) {
      final year? => t.mlBadgeGstSince(on, formatYear(year, lang)),
      null => t.mlBadgeGstChecked(on),
    },
    'apmc_seen' => t.mlBadgeApmcSeen(on),
    'fssai_checked' => t.mlBadgeFssaiChecked(on),
    'iec_active' => t.mlBadgeIecActive(on),
    'apeda_listed' => t.mlBadgeApedaListed(on),
    // A kind this app version does not know: say only that BagMitra checked, and when.
    _ => t.mlBadgeChecked(on),
  };
}

String questionLabel(AppLocalizations t, String key) => switch (key) {
  'trader_on_date' => t.mlQTraderOnDate,
  'trader_weighing_correct' => t.mlQTraderWeighing,
  'trader_paid_as_agreed' => t.mlQTraderPaid,
  'trader_kept_conditions' => t.mlQTraderConditions,
  'broker_honest' => t.mlQBrokerHonest,
  'broker_trader_kept_deal' => t.mlQBrokerTraderKept,
  'grower_produce_matched' => t.mlQGrowerProduce,
  'grower_ready_on_date' => t.mlQGrowerReady,
  _ => key,
};

String cropsText(List<String> crops, String lang) =>
    crops.map((c) => marketCropName(c, lang)).join(', ');

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

/// Tap-to-call with the number shown; copying the number is the fallback (no booking).
class CallRow extends ConsumerWidget {
  const CallRow({super.key, required this.phone, required this.keyId});

  final String phone;
  final String keyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Row(
      children: [
        Expanded(child: Text(phone, style: BmType.bodyStrong)),
        IconButton(
          key: Key('ml-copy-$keyId'),
          tooltip: t.directoryCopyNumber,
          color: c.brandStrong,
          constraints: const BoxConstraints(
            minWidth: BmSpace.tapTarget,
            minHeight: BmSpace.tapTarget,
          ),
          icon: const Icon(Icons.copy_rounded),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: phone));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(t.directoryNumberCopied)),
                );
            }
          },
        ),
        IconButton.filled(
          key: Key('ml-call-$keyId'),
          tooltip: t.mlCall,
          constraints: const BoxConstraints(
            minWidth: BmSpace.tapTarget,
            minHeight: BmSpace.tapTarget,
          ),
          icon: const Icon(Icons.call_rounded),
          onPressed: () => ref.read(phoneDialerProvider)(phone),
        ),
      ],
    );
  }
}

/// One profile in a list: name, kind and place first, then numbers (deals, stars, km),
/// badges with dates, the expired-certificate warning, and the phone to call.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile, this.onTap});

  final MarketProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final p = profile;
    final overall = p.overallStars;
    final numbers = [
      if (p.subjectType != 'provider')
        t.mlDeals(formatInt(p.dealsCompleted, lang)),
      if (overall != null)
        t.mlStars(
          formatDecimal(overall, lang),
          formatInt(
            p.stars.map((s) => s.count).reduce((a, b) => a > b ? a : b),
            lang,
          ),
        ),
      if (p.distanceKm case final km?) t.mlDistanceKm(formatInt(km, lang)),
    ];
    return BmCard(
      key: Key('ml-profile-${p.id}'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: BmType.cardTitle),
            Text(
              [profileKindLabel(t, p), ?p.firm].join(' · '),
              style: BmType.meta,
            ),
            Text(p.place, style: BmType.meta.copyWith(color: c.inkMuted)),
            if (numbers.isNotEmpty) ...[
              const SizedBox(height: BmSpace.xs),
              Text(
                numbers.join(' · '),
                style: BmType.bodyStrong.copyWith(color: c.brandStrong),
              ),
            ],
            if (p.certificateExpired) ...[
              const SizedBox(height: BmSpace.xs),
              Text(
                t.mlCertExpired(formatDate(p.certValidUntil!, lang)),
                key: Key('ml-cert-expired-${p.id}'),
                style: BmType.bodyStrong.copyWith(color: c.danger),
              ),
            ],
            const SizedBox(height: BmSpace.xs),
            for (final b in p.badges)
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.task_alt_rounded, size: 18, color: c.brand),
                    const SizedBox(width: BmSpace.xs),
                    Expanded(
                      child: Text(badgeText(t, b, lang), style: BmType.meta),
                    ),
                  ],
                ),
              ),
            CallRow(phone: p.phone, keyId: p.id),
          ],
        ),
      ),
    );
  }
}
