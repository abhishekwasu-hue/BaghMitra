import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/sync_status_banner.dart';
import '../../../theme/app_theme.dart';
import '../domain/market_link_role.dart';
import '../domain/market_lot.dart';
import 'lot_photo_strip.dart';
import 'lot_widgets.dart';
import 'market_link_entry.dart';
import 'package_chip.dart';

/// The grower's lots for sale, newest first, with the sync strip when something is not
/// sent and the short disclaimer (decision k). One main action: show a new lot.
class MyLotsScreen extends StatelessWidget {
  const MyLotsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MarketLinkEntry(role: MarketLinkRole.grower, child: _MyLots());
}

class _MyLots extends ConsumerWidget {
  const _MyLots();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final loaded = ref.watch(marketLotsProvider);
    final lots = loaded.value ?? const [];
    final banner = buildSyncStatusBanner(context, ref);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlMyLotsTitle)),
      body: loaded.isLoading && !loaded.hasValue
          ? LoadingState(label: t.loadingLabel)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BmSpace.lg,
                    BmSpace.xs,
                    BmSpace.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [?banner, const LotDisclaimerNote()],
                  ),
                ),
                Expanded(
                  child: lots.isEmpty
                      ? EmptyState(
                          glyph: BmGlyph.orange,
                          message: t.mlLotsEmpty,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            BmSpace.lg,
                            BmSpace.sm,
                            BmSpace.lg,
                            BmSpace.xxl,
                          ),
                          itemCount: lots.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: BmSpace.sm),
                          itemBuilder: (_, i) => LotCard(lots[i]),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const Key('lot-new'),
            onPressed: () => context.push(Routes.newMarketLot()),
            child: Text(t.mlOpen),
          ),
        ],
      ),
    );
  }
}

/// One lot in the "my lots" list; opens the lot.
class LotCard extends ConsumerWidget {
  const LotCard(this.lot, {super.key});

  final MarketLot lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final crops = ref.watch(cropsProvider).value ?? const [];
    final crop =
        crops.where((x) => x.slug == lot.crop).firstOrNull?.label(lang) ??
        lot.crop;
    final photos = ref.watch(lotPhotosStreamProvider(lot.id)).value ?? const [];
    final rate = lot.askingRatePaise;
    return BmCard(
      key: Key('lot-${lot.id}'),
      elevated: false,
      radius: BmRadius.card,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(BmRadius.card),
        onTap: () => context.push(Routes.marketLot(lot.id)),
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      [crop, ?lot.variety].join(' · '),
                      style: BmType.bodyStrong,
                    ),
                  ),
                  const SizedBox(width: BmSpace.xs),
                  PackagedLotStatusChip(
                    lot.id,
                    lot.status,
                    awaitingCheck: lot.awaitingCheck,
                  ),
                ],
              ),
              const SizedBox(height: BmSpace.xs),
              Text(
                '${t.mlTonnes(formatDecimal(lot.quantityT, lang))} · '
                '${basisLabel(t, lot.basis)}',
                style: BmType.cardTitle.copyWith(color: c.brand),
              ),
              Text(
                windowLabel(t, lot.harvestFrom, lot.harvestTo, lang),
                style: BmType.body.copyWith(color: c.inkMuted),
              ),
              if (rate != null)
                Text(rateLabel(t, lot.basis, rate, lang), style: BmType.body),
              if (lot.status == 'published') PackageChip(lot.id),
              if (photos.isNotEmpty) ...[
                const SizedBox(height: BmSpace.xs),
                LotPhotoStrip(photos: photos.take(4).toList(), size: 56),
              ],
              // Offers come only on a lot traders have seen (L4).
              if (lot.status != 'draft')
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: Key('lot-offers-${lot.id}'),
                    onPressed: () =>
                        context.push(Routes.marketLotOffers(lot.id)),
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: Text(t.mlSeeOffers),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
