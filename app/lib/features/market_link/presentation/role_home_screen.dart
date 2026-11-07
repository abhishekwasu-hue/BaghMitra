import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/market_link_providers.dart';
import '../domain/market_link.dart';
import 'role_label.dart';
import 'terms_acceptance_screen.dart';

/// A market-link role's own home (spec v1.5 §2.1). The acceptance screen comes first until
/// the current terms are accepted for this role. For now the home holds the fixed safety
/// notice (§4C), an empty state and the grievance officer; the role's tools come in L2–L6.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key, required this.role});

  final MarketRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accepted = ref.watch(marketRoleAcceptedProvider(role));
    return switch (accepted) {
      AsyncData(value: true) => _Home(role: role),
      AsyncData() || AsyncError() => TermsAcceptanceScreen(
        role: role,
        onBack: () => context.go(Routes.roles),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

const _round = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(BmRadius.card)),
);

class _Home extends ConsumerWidget {
  const _Home({required this.role});

  final MarketRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final terms = ref.watch(marketTermsProvider).value ?? MarketTerms.bundled;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: AppBarTitle(roleLabel(t, role)),
        actions: [
          IconButton(
            key: const Key('switch-role'),
            tooltip: t.mlSwitchRole,
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.push(Routes.roles),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          BmCard(
            key: const Key('safety-notice'),
            elevated: false,
            radius: BmRadius.card,
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: c.brand),
                const SizedBox(width: BmSpace.sm),
                Expanded(
                  child: Text(t.mlSafetyNotice, style: BmType.bodyStrong),
                ),
              ],
            ),
          ),
          EmptyState(
            glyph: BmGlyph.home,
            title: roleLabel(t, role),
            message: t.mlRoleHomeSoon,
          ),
          BmCard(
            elevated: false,
            radius: BmRadius.card,
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              // Clipped to the card, so the pressed header keeps the round corners.
              clipBehavior: Clip.antiAlias,
              key: const Key('grievance'),
              shape: _round,
              collapsedShape: _round,
              tilePadding: const EdgeInsets.symmetric(horizontal: BmSpace.md),
              childrenPadding: const EdgeInsets.fromLTRB(
                BmSpace.md,
                0,
                BmSpace.md,
                BmSpace.md,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              leading: Icon(Icons.support_agent_outlined, color: c.brand),
              title: Text(t.mlGrievanceTitle, style: BmType.bodyStrong),
              children: [
                Text(
                  terms.grievanceName ?? t.mlGrievanceOwner,
                  style: BmType.bodyStrong,
                ),
                if (terms.grievanceContact case final contact?)
                  SelectableText(
                    t.mlGrievanceContact(contact),
                    style: BmType.body,
                  ),
                const SizedBox(height: BmSpace.xxs),
                Text(
                  t.mlGrievanceTimes,
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
