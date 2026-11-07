import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../market/domain/market_crops.dart';
import '../data/interest_api.dart';
import '../data/registration_api.dart';
import '../domain/interest.dart';
import '../domain/market_link_role.dart';
import 'lot_widgets.dart';
import 'market_link_entry.dart';
import 'profile_widgets.dart';

/// Crop, tonnes and basis, harvest window, asking rate and place of a published lot: what
/// a trader reads before an offer (never the grower's identity, decision g).
class BuyerLotSummary extends StatelessWidget {
  const BuyerLotSummary(this.lot, {super.key});

  final BuyerLot lot;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final rate = lot.askingRatePaise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [marketCropName(lot.crop, lang), ?lot.variety].join(' · '),
          style: BmType.bodyStrong,
        ),
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
        if (lot.quality case final q? when q.trim().isNotEmpty)
          Text(q, style: BmType.meta),
        Text(lot.place, style: BmType.meta.copyWith(color: c.inkMuted)),
      ],
    );
  }
}

/// Published lots for a verified trader or broker, newest first; one main action: my
/// offers. Before the admin check the server answers `not_verified` and the screen says so.
class BrowseLotsScreen extends StatelessWidget {
  const BrowseLotsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MarketLinkEntry(role: MarketLinkRole.trader, child: _Browse());
}

class _Browse extends ConsumerWidget {
  const _Browse();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final lots = ref.watch(buyerLotsProvider);
    final error = lots.error;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlBrowseTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.xs,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          const LotDisclaimerNote(),
          if (error is MarketCallException && error.code == 'not_verified')
            EmptyState(glyph: BmGlyph.orange, message: t.mlNotVerified)
          else if (error != null)
            MarketCallBanner(
              error,
              onRetry: () => ref.invalidate(buyerLotsProvider),
            )
          else if (!lots.hasValue)
            LoadingState(label: t.loadingLabel)
          else if (lots.value!.isEmpty)
            EmptyState(glyph: BmGlyph.orange, message: t.mlBrowseEmpty)
          else
            for (final lot in lots.value!) ...[
              BmCard(
                key: Key('ml-buyer-lot-${lot.id}'),
                elevated: false,
                radius: BmRadius.card,
                padding: const EdgeInsets.all(BmSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [BuyerLotSummary(lot)],
                ),
              ),
              const SizedBox(height: BmSpace.sm),
            ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const Key('ml-my-offers'),
            onPressed: () => context.push(Routes.marketMyOffers),
            child: Text(t.mlMyOffersTitle),
          ),
        ],
      ),
    );
  }
}

/// The caller's offers, newest first, each with its state: waiting, accepted, or closed
/// (the notice that the grower chose another or took the lot off the list).
class MyInterestsScreen extends StatelessWidget {
  const MyInterestsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MarketLinkEntry(role: MarketLinkRole.trader, child: _Mine());
}

class _Mine extends ConsumerWidget {
  const _Mine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final mine = ref.watch(myInterestsProvider);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlMyOffersTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.xs,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          const LotDisclaimerNote(),
          if (mine.error case final error?)
            MarketCallBanner(
              error,
              onRetry: () => ref.invalidate(myInterestsProvider),
            )
          else if (!mine.hasValue)
            LoadingState(label: t.loadingLabel)
          else if (mine.value!.isEmpty)
            EmptyState(glyph: BmGlyph.orange, message: t.mlMyOffersEmpty)
          else
            for (final s in mine.value!) ...[
              BmCard(
                key: Key('ml-sent-${s.interest.id}'),
                elevated: false,
                radius: BmRadius.card,
                padding: const EdgeInsets.all(BmSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        marketCropName(s.lot.crop, lang),
                        ?s.lot.variety,
                      ].join(' · '),
                      style: BmType.bodyStrong,
                    ),
                    Text(
                      rateLabel(
                        t,
                        s.interest.basis,
                        s.interest.ratePaise,
                        lang,
                      ),
                      style: BmType.cardTitle.copyWith(color: c.brand),
                    ),
                    Text(
                      [
                        if (s.interest.quantityT case final q?)
                          t.mlTonnes(formatDecimal(q, lang)),
                        t.mlHarvestOn(formatDate(s.interest.harvestDate, lang)),
                      ].join(' · '),
                      style: BmType.body,
                    ),
                    Text(
                      s.lot.place,
                      style: BmType.meta.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: BmSpace.xs),
                    InterestStateLine(s.interest),
                  ],
                ),
              ),
              const SizedBox(height: BmSpace.sm),
            ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const Key('ml-browse'),
            onPressed: () => context.go(Routes.marketBrowse),
            child: Text(t.mlBrowseTitle),
          ),
        ],
      ),
    );
  }
}

/// The state of an offer in words and colour by meaning: waiting (muted), accepted (green),
/// closed (the notice, muted).
class InterestStateLine extends StatelessWidget {
  const InterestStateLine(this.interest, {super.key});

  final Interest interest;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final (text, color) = switch (interest.status) {
      InterestStatus.accepted => (t.mlOfferAccepted, c.brandStrong),
      InterestStatus.closed ||
      InterestStatus.withdrawn => (t.mlOfferClosed, c.inkMuted),
      InterestStatus.open => (t.mlOfferOpen, c.warnTitle),
    };
    return Text(
      text,
      key: Key('ml-state-${interest.id}'),
      style: BmType.bodyStrong.copyWith(color: color),
    );
  }
}
