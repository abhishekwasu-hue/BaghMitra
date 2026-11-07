import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../market/domain/market_crops.dart';
import '../data/interest_api.dart';
import '../data/registration_api.dart';
import '../domain/interest.dart';
import '../domain/market_link_role.dart';
import '../domain/market_lot.dart';
import '../domain/registration.dart';
import 'lot_widgets.dart';
import 'market_link_entry.dart';
import 'people_screen.dart';
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
                  children: [
                    BuyerLotSummary(lot),
                    const SizedBox(height: BmSpace.xs),
                    OutlinedButton(
                      key: Key('ml-offer-${lot.id}'),
                      onPressed: () => context.push(Routes.marketOffer(lot.id)),
                      child: Text(t.mlMakeOffer),
                    ),
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
            key: const Key('ml-my-offers'),
            onPressed: () => context.push(Routes.marketMyOffers),
            child: Text(t.mlMyOffersTitle),
          ),
        ],
      ),
    );
  }
}

/// An offer on one lot: basis, rate, quantity, proposed harvest date and, for a trader, an
/// optional named broker (a broker names the trader instead). Nothing else (spec §3 step 3).
class SendInterestScreen extends StatelessWidget {
  const SendInterestScreen({required this.lotId, super.key});

  final String lotId;

  @override
  Widget build(BuildContext context) =>
      MarketLinkEntry(role: MarketLinkRole.trader, child: _SendInterest(lotId));
}

class _SendInterest extends ConsumerStatefulWidget {
  const _SendInterest(this.lotId);

  final String lotId;

  @override
  ConsumerState<_SendInterest> createState() => _SendInterestState();
}

class _SendInterestState extends ConsumerState<_SendInterest> {
  final _form = GlobalKey<FormState>();
  final _rate = TextEditingController();
  final _tonnes = TextEditingController();
  String? _basis;
  DateTime? _date;
  ({String id, String name})? _party;
  bool _busy = false;

  @override
  void dispose() {
    _rate.dispose();
    _tonnes.dispose();
    super.dispose();
  }

  double? get _quantity {
    const devanagari = '०१२३४५६७८९';
    final ascii = _tonnes.text.trim().split('').map((ch) {
      final i = devanagari.indexOf(ch);
      return i < 0 ? ch : '$i';
    }).join();
    return double.tryParse(ascii);
  }

  /// Acting as a broker when the user has a checked broker profile and no checked trader /
  /// exporter one: the trader must then be named.
  bool _asBroker(List<MarketProfile> mine) {
    bool ok(String type) =>
        mine.any((p) => p.subjectType == type && p.status == 'approved');
    return !ok('buyer') && ok('broker');
  }

  Future<void> _pickParty(bool asBroker) async {
    final t = AppLocalizations.of(context);
    final people = await ref.read(
      marketPeopleProvider((
        role: asBroker ? 'trader' : 'broker',
        sort: 'rating',
        taluka: null,
        district: null,
      )).future,
    );
    if (!mounted) return;
    final picked = await showModalBottomSheet<({String id, String name})?>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          if (!asBroker)
            ListTile(
              key: const Key('ml-party-none'),
              title: Text(t.mlOfferDirect),
              onTap: () => Navigator.pop(context, (id: '', name: '')),
            ),
          for (final p in people)
            ListTile(
              key: Key('ml-party-${p.id}'),
              title: Text(p.name),
              subtitle: Text(p.place),
              onTap: () => Navigator.pop(context, (id: p.id, name: p.name)),
            ),
        ],
      ),
    );
    if (picked != null && mounted) {
      setState(() => _party = picked.id.isEmpty ? null : picked);
    }
  }

  Future<void> _send(BuyerLot lot, bool asBroker) async {
    final t = AppLocalizations.of(context);
    if (!(_form.currentState?.validate() ?? false)) return;
    if (asBroker && _party == null) {
      _say(t.mlErrPickTrader);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(interestApiProvider).send(lot.id, (
        basis: _basis ?? lot.basis,
        ratePaise: parseRupeesToPaise(_rate.text)!,
        quantityT: _tonnes.text.trim().isEmpty ? null : _quantity,
        harvestDate: _date ?? lot.harvestFrom,
        brokerId: asBroker ? null : _party?.id,
        traderId: asBroker ? _party?.id : null,
      ));
      ref.invalidate(myInterestsProvider);
      _say(t.mlOfferSent);
      if (mounted) context.pushReplacement(Routes.marketMyOffers);
    } on MarketCallException catch (e) {
      _say(switch ((e.problem, e.code)) {
        (MarketCallProblem.offline, _) => t.mlOffline,
        (_, 'lot_not_found') => t.mlErrLotGone,
        (_, 'not_verified') => t.mlNotVerified,
        _ => t.mlPublishFailed,
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    final lots = ref.watch(buyerLotsProvider);
    final lot = lots.value?.where((l) => l.id == widget.lotId).firstOrNull;
    final mine = ref.watch(myMarketProfilesProvider).value ?? const [];
    final asBroker = _asBroker(mine);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlOfferTitle)),
      body: lot == null
          ? (lots.isLoading
                ? LoadingState(label: t.loadingLabel)
                : EmptyState(glyph: BmGlyph.orange, message: t.mlErrLotGone))
          : Form(key: _form, child: _fields(lot, asBroker)),
      bottomNavigationBar: lot == null
          ? null
          : BottomActions(
              children: [
                FilledButton(
                  key: const Key('ml-offer-send'),
                  onPressed: _busy ? null : () => _send(lot, asBroker),
                  child: Text(t.mlOfferSend),
                ),
              ],
            ),
    );
  }

  Widget _fields(BuyerLot lot, bool asBroker) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final basis = _basis ?? lot.basis;
    final date = _date ?? lot.harvestFrom;
    final paise = parseRupeesToPaise(_rate.text);
    const gap = SizedBox(height: BmSpace.md);
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: BmSpace.md, bottom: BmSpace.xs),
      child: Text(text, style: BmType.bodyStrong),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BmSpace.lg,
        BmSpace.xs,
        BmSpace.lg,
        BmSpace.xxl,
      ),
      children: [
        BmCard(
          elevated: false,
          radius: BmRadius.card,
          padding: const EdgeInsets.all(BmSpace.md),
          child: BuyerLotSummary(lot),
        ),
        const LotDisclaimerNote(),
        title(t.mlBasis),
        Wrap(
          spacing: BmSpace.xs,
          runSpacing: BmSpace.xs,
          children: [
            for (final b in lotBases)
              ChoiceChip(
                key: Key('ml-offer-basis-$b'),
                label: Text(basisLabel(t, b)),
                selected: basis == b,
                onSelected: (_) => setState(() => _basis = b),
              ),
          ],
        ),
        gap,
        TextFormField(
          key: const Key('ml-offer-rate'),
          controller: _rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t.mlOfferRate),
          validator: (v) =>
              (parseRupeesToPaise(v ?? '') ?? 0) > 0 ? null : t.mlErrRate,
          onChanged: (_) => setState(() {}),
        ),
        if (paise != null && paise > 0)
          Padding(
            padding: const EdgeInsets.only(top: BmSpace.xs),
            child: Text(
              rateLabel(t, basis, paise, lang),
              key: const Key('ml-offer-rate-preview'),
              style: BmType.cardTitle.copyWith(color: c.brand),
            ),
          ),
        gap,
        TextFormField(
          key: const Key('ml-offer-tonnes'),
          controller: _tonnes,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.०-९]')),
          ],
          decoration: InputDecoration(labelText: t.mlOfferQuantity),
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return null;
            final q = _quantity;
            return q != null && q > 0 && q <= 10000 ? null : t.mlErrQuantity;
          },
        ),
        title(t.mlOfferHarvestDate),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionChip(
            key: const Key('ml-offer-date'),
            avatar: const Icon(Icons.event_rounded),
            label: Text(formatDate(date, lang)),
            onPressed: () async {
              final now = ref.read(clockProvider)();
              final today = DateTime(now.year, now.month, now.day);
              final picked = await showDatePicker(
                context: context,
                initialDate: date.isBefore(today) ? today : date,
                firstDate: today,
                lastDate: DateTime(today.year + 2, today.month, today.day),
              );
              if (picked != null && mounted) setState(() => _date = picked);
            },
          ),
        ),
        title(asBroker ? t.mlOfferForTrader : t.mlOfferThroughBroker),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionChip(
            key: const Key('ml-offer-party'),
            avatar: const Icon(Icons.person_search_rounded),
            label: Text(
              _party?.name ?? (asBroker ? t.mlErrPickTrader : t.mlOfferDirect),
            ),
            onPressed: () => _pickParty(asBroker),
          ),
        ),
        gap,
        InfoNote(t.mlOfferOnlyThese),
      ],
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
                    if (s.interest.dealId case final dealId?)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          key: Key('ml-sent-intro-${s.interest.id}'),
                          onPressed: () =>
                              context.push(Routes.marketIntro(dealId)),
                          icon: const Icon(Icons.contacts_outlined),
                          label: Text(t.mlIntroOpen),
                        ),
                      ),
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
