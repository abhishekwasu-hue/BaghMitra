import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart' show MarketPriceOut;
import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../accounts/domain/fair_price.dart';

String basisLabel(AppLocalizations t, String basis) => switch (basis) {
  'per_crate' => t.mlBasisPerCrate,
  'lump_sum' => t.mlBasisLumpSum,
  _ => t.mlBasisPerTonne,
};

String rateLabel(AppLocalizations t, String basis, int paise, String lang) {
  final rate = formatPaise(paise, lang);
  return switch (basis) {
    'per_crate' => t.mlRatePerCrate(rate),
    'lump_sum' => t.mlRateLumpSum(rate),
    _ => t.mlRatePerTonne(rate),
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
/// today. A per-tonne rate also shows how far it is from that price.
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
    final comparison = basis == 'per_tonne' && ratePaise > 0
        ? compareWithMandi(
            ratePaisePerQuintal: ratePaise ~/ 10,
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
  const LotStatusChip(this.status, {this.awaitingCheck = false, super.key});

  final String status;

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
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Text(label, style: BmType.label.copyWith(color: fg)),
    );
  }
}
