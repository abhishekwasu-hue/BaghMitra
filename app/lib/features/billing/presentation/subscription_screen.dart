import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_update/data/app_update_providers.dart' show urlOpenerProvider;
import '../../auth/domain/auth.dart' show googleRedirectUri;
import '../data/play_billing.dart';
import '../data/subscription_flow.dart';

/// The Android package, for Play's subscription page link.
final String appPackage = Uri.parse(googleRedirectUri).scheme;

/// The required in-app notice of a Play price increase (billing addendum §7): no amount (the
/// user sees the new price in Google Play), the date, and a link to Play's subscription page.
class PriceChangeNotice extends StatelessWidget {
  const PriceChangeNotice({
    required this.plan,
    required this.onOpenPlay,
    super.key,
  });

  final PlanOffer plan;
  final VoidCallback onOpenPlay;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final when = DateTime.tryParse(plan.priceChange?.chargeTime ?? '');
    final date = when == null
        ? ''
        : DateFormat.yMMMd(t.localeName).format(when.toLocal());
    return Container(
      key: const Key('billing-change-notice'),
      padding: const EdgeInsets.all(BmSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: c.warnBg),
        border: Border.all(color: c.warnBorder),
        borderRadius: BorderRadius.circular(BmRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.billingChangeTitle,
            style: BmType.bodyStrong.copyWith(color: c.warnTitle),
          ),
          const SizedBox(height: BmSpace.xxs),
          Text(
            t.billingChangeBody(date),
            style: BmType.body.copyWith(color: c.warnBody),
          ),
          const SizedBox(height: BmSpace.sm),
          OutlinedButton.icon(
            key: const Key('billing-open-play'),
            onPressed: onOpenPlay,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(t.billingOpenPlay),
          ),
        ],
      ),
    );
  }
}

/// Subscription page (addendum §2.3, §7): opened only while the switch is ON and the user's
/// role has an amount. Shows Play's own localized price, what is included, the renewal and
/// cancel terms, Subscribe, Restore and Manage subscription. A purchase counts only after
/// the server confirmed it.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  PlanOffer? _plan;
  PlayOffer? _offer;
  bool _loaded = false;
  bool _hasPlay = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final flow = ref.read(subscriptionFlowProvider);
    final plan = await ref.read(billingServerProvider).plan();
    final hasPlay = await flow.play.available();
    PlayOffer? offer;
    if (hasPlay && plan != null && plan.showsPlan) {
      await flow.start();
      offer = await flow.play.offer(plan.productId!, plan.basePlanId!);
    }
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _offer = offer;
      _hasPlay = hasPlay;
      _loaded = true;
    });
  }

  Future<void> _openPlay() => ref.read(urlOpenerProvider)(
    playSubscriptionPage(
      productId: _plan?.productId ?? '',
      package: appPackage,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final flow = ref.watch(subscriptionFlowProvider);
    final plan = _plan;
    final offer = _offer;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.billingTitle)),
      body: !_loaded
          ? LoadingState(label: t.billingTitle)
          : ListView(
              padding: const EdgeInsets.all(BmSpace.lg),
              children: [
                if (plan?.priceChange != null) ...[
                  PriceChangeNotice(plan: plan!, onOpenPlay: _openPlay),
                  const SizedBox(height: BmSpace.md),
                ],
                BmCard(
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan?.covered ?? false)
                        Text(
                          t.billingActive,
                          key: const Key('billing-active'),
                          style: BmType.title.copyWith(color: c.brandStrong),
                        )
                      else if (offer != null)
                        Text(
                          t.billingPerMonth(offer.price),
                          key: const Key('billing-price'),
                          style: BmType.title.copyWith(color: c.brandStrong),
                        )
                      else if (!_hasPlay)
                        Text(t.billingNeedsPlay, style: BmType.body),
                      const SizedBox(height: BmSpace.xs),
                      Text(t.billingIncluded, style: BmType.bodyStrong),
                      const SizedBox(height: BmSpace.xs),
                      Text(
                        t.billingTerms,
                        style: BmType.body.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BmSpace.md),
                ValueListenableBuilder<FlowStep>(
                  valueListenable: flow.step,
                  builder: (context, step, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (switch (step) {
                            FlowStep.pending => t.billingPending,
                            FlowStep.verifying => t.billingVerifying,
                            FlowStep.done => t.billingActive,
                            FlowStep.failed => t.billingRetry,
                            _ => null,
                          }
                          case final note?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: BmSpace.sm),
                          child: Text(note, style: BmType.bodyStrong),
                        ),
                      if (offer != null && !(plan?.covered ?? false))
                        FilledButton(
                          key: const Key('billing-subscribe'),
                          onPressed: step == FlowStep.verifying
                              ? null
                              : () => flow.buy(offer, plan!),
                          child: Text(t.billingSubscribe),
                        ),
                      const SizedBox(height: BmSpace.sm),
                      if (_hasPlay)
                        OutlinedButton(
                          key: const Key('billing-restore'),
                          onPressed: flow.restore,
                          child: Text(t.billingRestore),
                        ),
                      TextButton.icon(
                        key: const Key('billing-manage'),
                        onPressed: _openPlay,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(t.billingManage),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
