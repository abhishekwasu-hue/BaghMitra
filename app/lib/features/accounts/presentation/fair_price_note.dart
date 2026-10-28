import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart' show MarketPriceOut;
import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/fair_price.dart';

/// A sale's rate beside the mandi modal price for the same crop and day, from the prices
/// already saved on the phone: market, date, modal price, then "X% above / below". Shows
/// nothing when no price was published that day. A published number, never a forecast.
class FairPriceNote extends ConsumerWidget {
  const FairPriceNote({
    super.key,
    required this.crop,
    required this.soldOn,
    required this.ratePaisePerQuintal,
  });

  final String crop;
  final DateTime soldOn;
  final int ratePaisePerQuintal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedMarketPricesProvider(crop)).value;
    final comparison = compareWithMandi(
      ratePaisePerQuintal: ratePaisePerQuintal,
      soldOn: soldOn,
      prices: [
        for (final p in saved?.prices.prices ?? const <MarketPriceOut>[])
          MandiPrice(
            market: p.market,
            day: p.day,
            modalRsPerQuintal: p.modalRsPerQuintal,
            isLocal: p.isLocal,
            isMajor: p.isMajor,
          ),
      ],
    );
    if (comparison == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final pct = comparison.percent;
    return Padding(
      key: const Key('fair-price'),
      padding: const EdgeInsets.only(top: BmSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.fairPriceMandi(
              formatDate(comparison.day, lang),
              comparison.market,
              formatRupees(comparison.modalRsPerQuintal, lang),
            ),
            style: BmType.meta,
          ),
          Text(
            pct > 0
                ? t.fairPriceAbove(formatInt(pct, lang))
                : pct < 0
                ? t.fairPriceBelow(formatInt(-pct, lang))
                : t.fairPriceSame,
            style: BmType.bodyStrong.copyWith(
              color: pct < 0 ? c.accentInk : c.brandStrong,
            ),
          ),
        ],
      ),
    );
  }
}
