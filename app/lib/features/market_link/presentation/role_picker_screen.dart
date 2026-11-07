import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/market_link_providers.dart';
import '../domain/market_link.dart';
import 'role_label.dart';

Widget roleIcon(BuildContext context, MarketRole role) {
  final color = context.bm.brand;
  return switch (role) {
    MarketRole.grower => const GlyphIcon(BmGlyph.orchard, size: 32),
    MarketRole.trader => Icon(
      Icons.storefront_outlined,
      color: color,
      size: 32,
    ),
    MarketRole.broker => Icon(Icons.handshake_outlined, color: color, size: 32),
    MarketRole.exporter => Icon(Icons.public, color: color, size: 32),
    MarketRole.provider => Icon(
      Icons.local_shipping_outlined,
      color: color,
      size: 32,
    ),
  };
}

/// The five role cards (spec v1.5 §2.1, "5 darvaje"). Signed out, the card picks the role
/// and the same sign-in follows; signed in, it switches the role. The grower card opens the
/// existing grower app; every other role opens its own home (terms first).
class RolePickerScreen extends ConsumerWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final current = ref.watch(activeMarketRoleProvider).value;
    final signedIn = ref.watch(sessionProvider).value != null;
    Future<void> pick(MarketRole role) async {
      await ref.read(activeMarketRoleProvider.notifier).choose(role);
      if (!context.mounted) return;
      context.go(
        !signedIn
            ? Routes.login
            : role == MarketRole.grower
            ? Routes.home
            : Routes.roleHome(role),
      );
    }

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlRolesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(t.mlRolesIntro, style: BmType.body.copyWith(color: c.inkMuted)),
          for (final role in MarketRole.values) ...[
            const SizedBox(height: BmSpace.sm),
            BmCard(
              elevated: false,
              padding: EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  key: Key('role-${role.name}'),
                  minVerticalPadding: BmSpace.md,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: BmSpace.lg,
                  ),
                  leading: roleIcon(context, role),
                  title: Text(roleLabel(t, role), style: BmType.section),
                  subtitle: role == MarketRole.provider
                      ? Text(t.mlRoleProviderKinds, style: BmType.meta)
                      : null,
                  trailing: role == current && signedIn
                      ? Icon(
                          Icons.check_circle,
                          color: c.brand,
                          semanticLabel: t.mlRoleCurrent,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () => pick(role),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
