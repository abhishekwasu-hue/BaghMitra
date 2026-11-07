import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../market/domain/market_crops.dart';
import '../data/interest_api.dart';
import '../data/registration_api.dart';
import '../domain/interest.dart';
import '../domain/market_link_role.dart';
import '../domain/market_lot.dart';
import 'lot_widgets.dart';
import 'market_link_entry.dart';
import 'profile_widgets.dart';

/// The grower compares the offers on one lot (spec §3 step 4): every card has the same
/// order, rate first, then tonnes and date, then the trader's checked badge, completed
/// deals and stars (and the named middleman). The lot's asking rate and today's stored
/// mandi price (market and date, Q48) sit above. One offer is chosen and accepted: that
/// shares both sides' contacts and closes the others (owner decisions g, k).
class LotOffersScreen extends StatelessWidget {
  const LotOffersScreen({required this.lotId, this.onIntroduced, super.key});

  final String lotId;

  /// Opens the introduction after an acceptance (the contacts screen).
  final void Function(BuildContext context, String dealId)? onIntroduced;

  @override
  Widget build(BuildContext context) => MarketLinkEntry(
    role: MarketLinkRole.grower,
    child: _LotOffers(lotId, onIntroduced),
  );
}

class _LotOffers extends ConsumerStatefulWidget {
  const _LotOffers(this.lotId, this.onIntroduced);

  final String lotId;
  final void Function(BuildContext context, String dealId)? onIntroduced;

  @override
  ConsumerState<_LotOffers> createState() => _LotOffersState();
}

class _LotOffersState extends ConsumerState<_LotOffers> {
  String? _chosen;
  bool _busy = false;

  Future<void> _accept(String interestId) async {
    final t = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.mlAcceptConfirmTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.mlAcceptConfirmBody, style: BmType.body),
              const LotDisclaimerNote(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.mlCancel),
          ),
          FilledButton(
            key: const Key('ml-accept-yes'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.mlAcceptYes),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final dealId = await ref.read(interestApiProvider).accept(interestId);
      ref.invalidate(lotInterestsProvider(widget.lotId));
      _say(t.mlAccepted);
      if (mounted) widget.onIntroduced?.call(context, dealId);
    } on MarketCallException catch (e) {
      ref.invalidate(lotInterestsProvider(widget.lotId));
      _say(switch (e.problem) {
        MarketCallProblem.offline => t.mlOffline,
        MarketCallProblem.refused => t.mlAcceptChanged,
        MarketCallProblem.server => t.mlServerBusy,
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// One main action: open the contacts once accepted, else accept the chosen offer.
  Widget? _bottom(
    AppLocalizations t,
    LotInterest? accepted,
    String? chosen,
    bool anyOpen,
  ) {
    final dealId = accepted?.interest.dealId;
    final open = widget.onIntroduced;
    if (accepted != null) {
      if (dealId == null || open == null) return null;
      return BottomActions(
        children: [
          FilledButton(
            key: const Key('ml-intro-open'),
            onPressed: () => open(context, dealId),
            child: Text(t.mlIntroOpen),
          ),
        ],
      );
    }
    if (!anyOpen) return null;
    return BottomActions(
      children: [
        FilledButton(
          key: const Key('ml-accept'),
          onPressed: chosen == null || _busy ? null : () => _accept(chosen),
          child: Text(t.mlAccept),
        ),
      ],
    );
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final offers = ref.watch(lotInterestsProvider(widget.lotId));
    final lots = ref.watch(marketLotsProvider).value ?? const [];
    final lot = lots.where((l) => l.id == widget.lotId).firstOrNull;
    final list = offers.value ?? const <LotInterest>[];
    final accepted = list
        .where((o) => o.interest.status == InterestStatus.accepted)
        .firstOrNull;
    final open = {
      for (final o in list)
        if (o.interest.status == InterestStatus.open) o.interest.id,
    };
    final chosen = open.contains(_chosen) ? _chosen : null;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlOffersTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.xs,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          if (lot != null) _LotHeader(lot),
          const LotDisclaimerNote(),
          if (offers.error case final error?)
            MarketCallBanner(
              error,
              onRetry: () => ref.invalidate(lotInterestsProvider(widget.lotId)),
            )
          else if (!offers.hasValue)
            LoadingState(label: t.loadingLabel)
          else if (list.isEmpty)
            EmptyState(glyph: BmGlyph.orange, message: t.mlOffersEmpty)
          else ...[
            if (accepted == null && open.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.xs),
                child: Text(t.mlAcceptPick, style: BmType.meta),
              ),
            for (final o in list) ...[
              _OfferCard(
                o,
                chosen: o.interest.id == chosen,
                onTap: open.contains(o.interest.id) && accepted == null
                    ? () => setState(() => _chosen = o.interest.id)
                    : null,
              ),
              const SizedBox(height: BmSpace.sm),
            ],
            InfoNote(t.mlBadgeNote),
          ],
        ],
      ),
      bottomNavigationBar: _bottom(t, accepted, chosen, open.isNotEmpty),
    );
  }
}

/// The grower's own lot above the offers: crop, tonnes, asking rate and the stored mandi
/// price beside it.
class _LotHeader extends StatelessWidget {
  const _LotHeader(this.lot);

  final MarketLot lot;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final rate = lot.askingRatePaise;
    return BmCard(
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [marketCropName(lot.crop, lang), ?lot.variety].join(' · '),
            style: BmType.bodyStrong,
          ),
          Text(
            '${t.mlTonnes(formatDecimal(lot.quantityT, lang))} · '
            '${basisLabel(t, lot.basis)}',
            style: BmType.body,
          ),
          if (rate != null)
            Text(
              t.mlYourAsk(rateLabel(t, lot.basis, rate, lang)),
              style: BmType.body,
            ),
          LotMandiNote(crop: lot.crop, basis: lot.basis, ratePaise: rate ?? 0),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard(this.offer, {required this.chosen, this.onTap});

  final LotInterest offer;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final i = offer.interest;
    final trader = offer.trader;
    final overall = trader.overallStars;
    final checked = trader.badges.where((b) => b.kind == 'checked').firstOrNull;
    return BmCard(
      key: Key('ml-lot-offer-${i.id}'),
      elevated: chosen,
      radius: BmRadius.card,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(BmRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onTap != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: BmSpace.xs),
                  child: Icon(
                    chosen
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: chosen ? c.brand : c.inkMuted,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rateLabel(t, i.basis, i.ratePaise, lang),
                      style: BmType.cardTitle.copyWith(color: c.brand),
                    ),
                    Text(
                      [
                        if (i.quantityT case final q?)
                          t.mlTonnes(formatDecimal(q, lang)),
                        t.mlHarvestOn(formatDate(i.harvestDate, lang)),
                      ].join(' · '),
                      style: BmType.body,
                    ),
                    const SizedBox(height: BmSpace.xs),
                    Text(
                      [trader.name, ?trader.firm].join(' · '),
                      style: BmType.bodyStrong,
                    ),
                    Text(
                      [
                        t.mlDeals(formatInt(trader.dealsCompleted, lang)),
                        if (overall != null)
                          t.mlStars(
                            formatDecimal(overall, lang),
                            formatInt(
                              trader.stars
                                  .map((s) => s.count)
                                  .reduce((a, b) => a > b ? a : b),
                              lang,
                            ),
                          ),
                      ].join(' · '),
                      style: BmType.meta.copyWith(color: c.brandStrong),
                    ),
                    if (checked != null)
                      Text(
                        badgeText(t, checked, lang),
                        style: BmType.meta.copyWith(color: c.inkMuted),
                      ),
                    if (offer.broker case final b?)
                      Text(
                        '${t.mlOfferThroughBroker}: ${b.name}',
                        style: BmType.meta,
                      ),
                    if (i.status == InterestStatus.accepted)
                      Text(
                        t.mlOfferAccepted,
                        key: Key('ml-state-${i.id}'),
                        style: BmType.bodyStrong.copyWith(color: c.brandStrong),
                      )
                    else if (i.status != InterestStatus.open)
                      Text(
                        t.mlStatusClosed,
                        key: Key('ml-state-${i.id}'),
                        style: BmType.bodyStrong.copyWith(color: c.inkMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
