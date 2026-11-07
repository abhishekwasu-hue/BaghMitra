import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_update/data/app_update_providers.dart';
import '../data/market_link_providers.dart';
import '../domain/market_link.dart';
import 'role_label.dart';

/// The gate before any market-link action in [role] (the grower's lot in L3 calls this):
/// true when the current terms are accepted, else once the acceptance screen is accepted.
Future<bool> ensureMarketRoleAccepted(
  BuildContext context,
  WidgetRef ref,
  MarketRole role,
) async {
  if (await ref.read(marketRoleAcceptedProvider(role).future)) return true;
  if (!context.mounted) return false;
  return await context.push<bool>(Routes.roleTerms(role)) ?? false;
}

/// Terms, privacy notice and disclaimer before a role is first used (spec v1.5 §4C), shown
/// again when a version changes. Short points, the full documents behind links, the 18+
/// declaration and "read and agree"; the main button opens only when both are ticked.
/// [onBack] null: pops with false (pushed by [ensureMarketRoleAccepted]).
class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceScreen({super.key, required this.role, this.onBack});

  final MarketRole role;
  final VoidCallback? onBack;

  @override
  ConsumerState<TermsAcceptanceScreen> createState() => _TermsState();
}

class _TermsState extends ConsumerState<TermsAcceptanceScreen> {
  bool _adult = false;
  bool _agree = false;
  bool _saving = false;

  Future<void> _accept() async {
    final user = ref.read(sessionProvider).value?.userId;
    if (user == null) return;
    setState(() => _saving = true);
    // Saved on the phone first; posted now or when the phone is next online (Q85).
    await ref.read(marketLinkStoreProvider).accept(user, widget.role);
    ref.invalidate(marketRoleAcceptedProvider(widget.role));
    if (!mounted) return;
    setState(() => _saving = false);
    if (widget.onBack == null) context.pop(true);
  }

  void _back() => widget.onBack == null ? context.pop(false) : widget.onBack!();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final terms = ref.watch(marketTermsProvider).value ?? MarketTerms.bundled;
    final base = Uri.parse(ref.watch(appConfigProvider).apiBaseUrl);
    final points = [
      t.mlTermsIntroOnly,
      t.mlTermsNotParty,
      t.mlTermsNoMoney,
      t.mlTermsNoGainLoss,
      t.mlTermsNoPart,
      t.mlTermsAfterDeal,
      if (widget.role != MarketRole.grower) ...[
        t.mlTermsPublicPhone,
        t.mlTermsGpsOnce,
      ],
    ];
    Widget link(String key, String label, String? url) => url == null
        ? const SizedBox.shrink()
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: Key(key),
              icon: const Icon(Icons.open_in_new),
              label: Text(label),
              onPressed: () => ref.read(urlOpenerProvider)(base.resolve(url)),
            ),
          );
    Widget tick(String key, String label, bool value, ValueChanged<bool> on) =>
        CheckboxListTile(
          key: Key(key),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(label, style: BmType.bodyStrong),
          value: value,
          onChanged: (v) => setState(() => on(v ?? false)),
        );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: AppBarTitle(t.mlTermsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(
            t.mlTermsRole(roleLabel(t, widget.role)),
            style: BmType.section.copyWith(color: c.brand),
          ),
          const SizedBox(height: BmSpace.sm),
          BmCard(
            elevated: false,
            radius: BmRadius.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in points)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: BmSpace.xxs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•  ',
                          style: BmType.body.copyWith(color: c.brand),
                        ),
                        Expanded(child: Text(p, style: BmType.body)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          link('terms-full', t.mlTermsFull, terms.termsUrl),
          link('terms-privacy', t.profilePrivacy, terms.privacyUrl),
          tick('terms-adult', t.mlTermsAdult, _adult, (v) => _adult = v),
          tick('terms-agree', t.mlTermsAgree, _agree, (v) => _agree = v),
        ],
      ),
      bottomNavigationBar: BottomActions(
        stacked: true,
        children: [
          FilledButton(
            key: const Key('terms-accept'),
            onPressed: _adult && _agree && !_saving ? _accept : null,
            child: Text(t.mlTermsAccept),
          ),
          OutlinedButton(
            key: const Key('terms-back'),
            onPressed: _back,
            child: Text(t.mlTermsBack),
          ),
        ],
      ),
    );
  }
}
