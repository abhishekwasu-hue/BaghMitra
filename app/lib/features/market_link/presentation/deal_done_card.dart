import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/interest_api.dart';
import '../data/registration_api.dart';
import '../domain/deal_rating.dart';
import '../domain/interest.dart';
import 'lot_widgets.dart';

/// The grower's own sale record from the introduction (spec §3 step 7): buyer, kilograms
/// and the rate per quintal as Accounts keeps it. Per tonne divides by 10; a lump sum is
/// spread over the agreed (or the lot's) tonnes; per crate has no quintal rate, so the
/// grower types it (Q114). Payment is never filled: BagMitra records nothing about it.
({String buyer, double kg, int? ratePaisePerQuintal}) saleFromDeal(
  Introduction intro,
) {
  final tonnes = intro.interest.quantityT ?? intro.lot.quantityT;
  final rate = intro.interest.ratePaise;
  return (
    buyer: [intro.trader.name, ?intro.trader.firm].join(' · '),
    kg: tonnes * 1000,
    ratePaisePerQuintal: switch (intro.interest.basis) {
      'per_tonne' => (rate / 10).round(),
      'lump_sum' when tonnes > 0 => (rate / (tonnes * 10)).round(),
      _ => null,
    },
  );
}

/// "व्यवहार झाला" on the introduction (spec §3 step 7, Q67): who has tapped, the grower's or
/// the trader's own tap, the wait for the other side, then the rating window and the
/// grower's copy into Accounts. The broker sees the state; only grower and trader tap.
class DealDoneCard extends ConsumerStatefulWidget {
  const DealDoneCard(this.intro, {super.key});

  final Introduction intro;

  @override
  ConsumerState<DealDoneCard> createState() => _DealDoneCardState();
}

class _DealDoneCardState extends ConsumerState<DealDoneCard> {
  bool _busy = false;

  Future<void> _tap() async {
    final t = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.mlDealDoneAsk),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.mlDealDoneAskBody, style: BmType.body),
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
            key: const Key('ml-deal-done-yes'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.mlDealDone),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(interestApiProvider).dealDone(widget.intro.dealId);
    } on MarketCallException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                e.problem == MarketCallProblem.offline
                    ? t.mlOffline
                    : t.mlServerBusy,
              ),
            ),
          );
      }
    } finally {
      ref.invalidate(introductionProvider(widget.intro.dealId));
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final lot = await ref
        .read(marketLotRepositoryProvider)
        .find(widget.intro.lot.id);
    if (lot == null || !mounted) return;
    final sale = saleFromDeal(widget.intro);
    await context.push(
      Routes.addSale(
        lot.plotId,
        buyer: sale.buyer,
        kg: sale.kg,
        ratePaise: sale.ratePaisePerQuintal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final s = widget.intro.state;
    Widget side(String who, DateTime? at, String key) => Padding(
      key: Key('ml-done-$key'),
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xxs),
      child: Row(
        children: [
          Icon(
            at == null ? Icons.hourglass_empty_rounded : Icons.check_circle,
            color: at == null ? c.inkMuted : c.brandStrong,
          ),
          const SizedBox(width: BmSpace.sm),
          Expanded(
            child: Text(
              '$who: ${at == null ? t.mlDealNotYet : t.mlDealSaidDone}',
              style: BmType.body,
            ),
          ),
        ],
      ),
    );
    final until = s.ratingUntil == null
        ? ''
        : formatDate(s.ratingUntil!.toLocal(), lang);
    return BmCard(
      key: const Key('ml-deal-done-card'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.mlDealDone, style: BmType.cardTitle),
          side(t.mlIntroGrower, s.growerDoneAt, 'grower'),
          side(t.mlRoleTrader, s.traderDoneAt, 'trader'),
          const SizedBox(height: BmSpace.xs),
          if (!s.completed && s.iTap && !s.iTapped)
            FilledButton.tonalIcon(
              key: const Key('ml-deal-done'),
              onPressed: _busy ? null : _tap,
              icon: const Icon(Icons.handshake_outlined),
              label: Text(t.mlDealDone),
            )
          else if (!s.completed)
            InfoNote(s.iTap ? t.mlDealWaitOther : t.mlDealWaitBoth)
          else if (s.ratingLocked)
            InfoNote(t.mlRateLocked(until))
          else ...[
            FilledButton.tonalIcon(
              key: const Key('ml-rate-open'),
              onPressed: () => context.push(
                Routes.marketRate(
                  widget.intro.dealId,
                  asGrower: s.myRole == DealRole.grower,
                ),
              ),
              icon: const Icon(Icons.star_outline_rounded),
              label: Text(t.mlRateOpen),
            ),
            const SizedBox(height: BmSpace.xxs),
            Text(
              t.mlRateUntil(until),
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
          ],
          if (s.completed && s.myRole == DealRole.grower)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('ml-copy-accounts'),
                onPressed: _copy,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(t.mlCopyToAccounts),
              ),
            ),
        ],
      ),
    );
  }
}
