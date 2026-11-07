import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../market/domain/market_crops.dart';
import '../data/interest_api.dart';
import '../domain/interest.dart';
import '../domain/market_link_role.dart';
import 'lot_widgets.dart';
import 'market_link_entry.dart';
import 'profile_widgets.dart';

/// Opens the phone's own map app at a point (`geo:` link, no map service of ours); false
/// when no app takes it. An interface point so widget tests never leave the app.
typedef MapOpener = Future<bool> Function(double lat, double lon);

final mapOpenerProvider = Provider<MapOpener>(
  (ref) => (lat, lon) async {
    try {
      return await launchUrl(Uri.parse('geo:$lat,$lon?q=$lat,$lon'));
    } on Object {
      return false;
    }
  },
);

/// The introduction (spec §3 step 4): after the grower accepted, both sides see each
/// other's name and phone and the trader sees the orchard's pin; the offer as it was sent.
/// Nothing about their transaction is recorded; the rest is settled off the app (step 5).
class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({
    required this.dealId,
    required this.role,
    super.key,
  });

  final String dealId;

  /// grower when opened from the lot's offers, trader from "my offers".
  final MarketLinkRole role;

  @override
  Widget build(BuildContext context) =>
      MarketLinkEntry(role: role, child: _Intro(dealId, role));
}

class _Intro extends ConsumerWidget {
  const _Intro(this.dealId, this.role);

  final String dealId;
  final MarketLinkRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final loaded = ref.watch(introductionProvider(dealId));
    final intro = loaded.value;
    // The main action calls the other side: the trader for the grower, else the grower.
    final callee = intro == null
        ? null
        : role == MarketLinkRole.grower
        ? intro.trader.phone
        : intro.grower.phone;
    Widget person(String heading, Contact who, String key, {String? place}) =>
        BmCard(
          key: Key('ml-intro-$key'),
          elevated: false,
          radius: BmRadius.card,
          padding: const EdgeInsets.all(BmSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: BmType.meta.copyWith(color: c.inkMuted)),
              Text([who.name, ?who.firm].join(' · '), style: BmType.cardTitle),
              if (place != null && place.isNotEmpty)
                Text(place, style: BmType.meta),
              if (who.phone case final phone?)
                CallRow(phone: phone, keyId: key),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlIntroTitle)),
      body: intro == null
          ? (loaded.error != null
                ? ListView(
                    padding: const EdgeInsets.all(BmSpace.lg),
                    children: [
                      MarketCallBanner(
                        loaded.error!,
                        onRetry: () =>
                            ref.invalidate(introductionProvider(dealId)),
                      ),
                    ],
                  )
                : LoadingState(label: t.loadingLabel))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                BmSpace.xs,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                const LotDisclaimerNote(),
                BmCard(
                  elevated: false,
                  radius: BmRadius.card,
                  padding: const EdgeInsets.all(BmSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          marketCropName(intro.lot.crop, lang),
                          ?intro.lot.variety,
                        ].join(' · '),
                        style: BmType.bodyStrong,
                      ),
                      Text(
                        rateLabel(
                          t,
                          intro.interest.basis,
                          intro.interest.ratePaise,
                          lang,
                        ),
                        style: BmType.cardTitle.copyWith(color: c.brand),
                      ),
                      Text(
                        [
                          if (intro.interest.quantityT case final q?)
                            t.mlTonnes(formatDecimal(q, lang)),
                          t.mlHarvestOn(
                            formatDate(intro.interest.harvestDate, lang),
                          ),
                        ].join(' · '),
                        style: BmType.body,
                      ),
                      Text(
                        t.mlIntroAcceptedOn(
                          formatDate(intro.acceptedAt.toLocal(), lang),
                        ),
                        style: BmType.meta.copyWith(color: c.brandStrong),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BmSpace.sm),
                person(
                  t.mlIntroGrower,
                  intro.grower,
                  'grower',
                  place: [?intro.plotName, intro.growerPlace].join(' · '),
                ),
                if (intro.pin case final pin?)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('ml-intro-map'),
                      onPressed: () =>
                          ref.read(mapOpenerProvider)(pin.lat, pin.lon),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(t.mlIntroOpenMap),
                    ),
                  ),
                const SizedBox(height: BmSpace.sm),
                person(t.mlRoleTrader, intro.trader, 'trader'),
                if (intro.broker case final broker?) ...[
                  const SizedBox(height: BmSpace.sm),
                  person(t.mlRoleBroker, broker, 'broker'),
                ],
                const SizedBox(height: BmSpace.sm),
                InfoNote(t.mlIntroOffApp),
              ],
            ),
      bottomNavigationBar: callee == null
          ? null
          : BottomActions(
              children: [
                FilledButton.icon(
                  key: const Key('ml-intro-call'),
                  onPressed: () => ref.read(phoneDialerProvider)(callee),
                  icon: const Icon(Icons.call_rounded),
                  label: Text(t.mlCallNumber(callee)),
                ),
              ],
            ),
    );
  }
}
