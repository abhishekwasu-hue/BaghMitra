import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart' show MarketPriceOut;
import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../accounts/domain/fair_price.dart';
import '../domain/lot_form_rules.dart';

String basisLabel(AppLocalizations t, String basis) => switch (basis) {
  'per_crate' => t.mlBasisPerCrate,
  'lump_sum' => t.mlBasisLumpSum,
  _ => t.mlBasisPerQuintal,
};

String rateLabel(AppLocalizations t, String basis, int paise, String lang) {
  final rate = formatPaise(paise, lang);
  return switch (basis) {
    'per_crate' => t.mlRatePerCrate(rate),
    'lump_sum' => t.mlRateLumpSum(rate),
    _ => t.mlRatePerQuintal(rate),
  };
}

/// The asking-rate field's label for the chosen basis (Q138).
String askingRateLabel(AppLocalizations t, String? basis) => switch (basis) {
  'per_quintal' => t.mlAskingRatePerQuintal,
  'per_crate' => t.mlAskingRatePerCrate,
  'lump_sum' => t.mlAskingRateLumpSum,
  _ => t.mlAskingRate,
};

/// The allowed asking-rate range of a basis as a short line, e.g. "₹२,५०० – ₹१०,००० प्रति
/// क्विंटल"; null for a basis without a range.
String? rateRangeLabel(
  AppLocalizations t,
  String? basis,
  RateRange? range,
  String lang,
) {
  if (range == null) return null;
  final (lo, hi) = (formatPaise(range.min, lang), formatPaise(range.max, lang));
  return switch (basis) {
    'per_quintal' => t.mlRateRangePerQuintal(lo, hi),
    'per_crate' => t.mlRateRangePerCrate(lo, hi),
    _ => null,
  };
}

String windowLabel(
  AppLocalizations t,
  DateTime from,
  DateTime to,
  String lang,
) => t.mlWindowRange(formatDate(from, lang), formatDate(to, lang));

/// The compact "not a buyer, seller, commission agent or transporter" note on every lot
/// screen (decision k).
class LotDisclaimerNote extends StatelessWidget {
  const LotDisclaimerNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('ml-disclaimer-note'),
    padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
    child: InfoNote(AppLocalizations.of(context).mlDisclaimerShort),
  );
}

/// Today's mandi modal price for the crop beside the asking rate (Q48 logic): the stored
/// published price with market and date, never a forecast; nothing when none was published
/// today. A per-quintal rate also shows how far it is from that price.
class LotMandiNote extends ConsumerWidget {
  const LotMandiNote({
    required this.crop,
    required this.basis,
    required this.ratePaise,
    super.key,
  });

  final String crop;
  final String? basis;
  final int ratePaise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedMarketPricesProvider(crop)).value;
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final prices = [
      for (final p in saved?.prices.prices ?? const <MarketPriceOut>[])
        MandiPrice(
          market: p.market,
          day: p.day,
          modalRsPerQuintal: p.modalRsPerQuintal,
          isLocal: p.isLocal,
          isMajor: p.isMajor,
        ),
    ];
    final pick = mandiPriceOn(today, prices);
    if (pick == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final comparison = basis == 'per_quintal' && ratePaise > 0
        ? compareWithMandi(
            ratePaisePerQuintal: ratePaise,
            soldOn: today,
            prices: prices,
          )
        : null;
    final pct = comparison?.percent;
    return Padding(
      key: const Key('lot-mandi'),
      padding: const EdgeInsets.only(top: BmSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.fairPriceMandi(
              formatDate(pick.day, lang),
              pick.market,
              formatRupees(pick.modalRsPerQuintal, lang),
            ),
            style: BmType.meta,
          ),
          if (pct != null)
            Text(
              pct > 0
                  ? t.fairPriceAbove(formatInt(pct, lang))
                  : pct < 0
                  ? t.fairPriceBelow(formatInt(-pct, lang))
                  : t.fairPriceSame,
              style: BmType.bodyStrong.copyWith(
                color: pct < 0 ? c.caution : c.brandStrong,
              ),
            ),
        ],
      ),
    );
  }
}

/// Short status chip of a lot: draft, shown to traders, or closed.
class LotStatusChip extends StatelessWidget {
  const LotStatusChip(
    this.status, {
    this.awaitingCheck = false,
    this.hiddenByPackage = false,
    super.key,
  });

  final String status;

  /// Published, but the season package switch is ON and no active package covers the lot,
  /// so traders do not see it (spec v1.5 §4E): never say "shown to traders" then.
  final bool hiddenByPackage;

  /// Published, but waiting for the admin's orchard check (spec §4C).
  final bool awaitingCheck;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final (label, fg, bg) = switch (status) {
      'published' when awaitingCheck => (
        t.mlStatusReview,
        c.warnTitle,
        c.nowTint,
      ),
      'published' when hiddenByPackage => (
        t.mlPackageHiddenNow,
        c.inkMuted,
        c.card,
      ),
      'published' => (t.mlStatusPublished, c.brandStrong, c.doneTint),
      'closed' => (t.mlStatusClosed, c.inkMuted, c.card),
      _ => (t.mlStatusDraft, c.warnTitle, c.nowTint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BmSpace.sm,
        vertical: BmSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: status == 'published' && hiddenByPackage
            ? Border.all(color: c.line)
            : null,
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Text(label, style: BmType.label.copyWith(color: fg)),
    );
  }
}
