import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../home/presentation/home_screen.dart' show openForPlot;
import '../../plots/domain/plot.dart';

/// "All features" (audit H1): one list with an entry to every screen of the app, so no
/// feature is reachable only from deep inside another one. Entries only; nothing new.
/// A block's records open for the grower's block (a short "choose a block" sheet when
/// there are several; with none yet, a short "add your block first" sheet, then the record).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final plots = ref.watch(plotsProvider).value ?? const <Plot>[];

    _Entry page(String id, IconData icon, String title, String route) =>
        (id, icon, title, () => context.push(route));
    _Entry forPlot(
      String id,
      IconData icon,
      String title,
      String Function(String plotId) route,
    ) => (
      id,
      icon,
      title,
      () => openForPlot(context, plots, route, action: title),
    );

    final sections = <(String, List<_Entry>)>[
      (
        t.moreSectionRecords,
        [
          page('plots', Icons.park_outlined, t.myOrchard, Routes.plots),
          forPlot(
            'sprays',
            Icons.sanitizer_outlined,
            t.sprayLogTitle,
            Routes.sprays,
          ),
          forPlot(
            'accounts',
            Icons.account_balance_wallet_outlined,
            t.accountsTitle,
            Routes.accounts,
          ),
          forPlot(
            'field-log',
            Icons.grass_outlined,
            t.fieldLogTitle,
            Routes.fieldLog,
          ),
          forPlot(
            'labour',
            Icons.groups_outlined,
            t.labourTitle,
            Routes.labour,
          ),
          forPlot(
            'harvest',
            Icons.shopping_basket_outlined,
            t.harvestTitle,
            Routes.harvest,
          ),
          forPlot(
            'scouting',
            Icons.photo_camera_outlined,
            t.scoutingTitle,
            Routes.scouting,
          ),
          forPlot(
            'insurance',
            Icons.verified_user_outlined,
            t.insuranceTitle,
            Routes.insurance,
          ),
          forPlot(
            'lab-tests',
            Icons.science_outlined,
            t.labTestsTitle,
            Routes.labTests,
          ),
        ],
      ),
      (
        t.moreSectionWork,
        [
          page('tasks', Icons.checklist_rounded, t.tasksTitle, Routes.tasks),
          page(
            'calendar',
            Icons.calendar_month_outlined,
            t.calendarTitle,
            Routes.calendar,
          ),
        ],
      ),
      (
        t.moreSectionHelp,
        [
          page(
            'practices',
            Icons.menu_book_outlined,
            t.practicesTitle,
            Routes.practices,
          ),
          page(
            'irrigation',
            Icons.water_drop_outlined,
            t.irrigationGuideTitle,
            Routes.irrigation,
          ),
          page(
            'lookalikes',
            Icons.compare_outlined,
            t.lookalikesTitle,
            Routes.lookalikes,
          ),
          page('labs', Icons.biotech_outlined, t.labsTitle, Routes.labs),
        ],
      ),
      (
        t.moreSectionMarket,
        [
          page(
            'market',
            Icons.storefront_outlined,
            t.marketPricesTitle,
            Routes.market,
          ),
          page(
            'market-directory',
            Icons.store_mall_directory_outlined,
            t.marketDirectoryTitle,
            Routes.marketDirectory,
          ),
          if (config.marketLink) ...[
            page(
              'market-link-people',
              Icons.groups_outlined,
              t.mlPeopleTitle,
              Routes.marketLinkPeople,
            ),
            page(
              'market-link-services',
              Icons.local_shipping_outlined,
              t.mlServicesTitle,
              Routes.marketLinkServices,
            ),
            page(
              'market-link-mine',
              Icons.badge_outlined,
              t.mlMyProfilesTitle,
              Routes.marketLinkMine,
            ),
            page(
              'export-info',
              Icons.flight_takeoff_outlined,
              t.exportInfoTitle,
              Routes.exportInfo,
            ),
          ],
        ],
      ),
      (
        t.moreSectionGovt,
        [
          page(
            'schemes',
            Icons.fact_check_outlined,
            t.schemesTitle,
            Routes.schemes,
          ),
          page(
            'claim-kit',
            Icons.assignment_outlined,
            t.claimKitTitle,
            Routes.claimKit,
          ),
          if (config.sarkariSandeshEnabled) ...[
            page(
              'feed',
              Icons.account_balance_outlined,
              t.feedTitle,
              Routes.feed,
            ),
            page(
              'feed-check',
              Icons.manage_search_outlined,
              t.feedCheckTitle,
              Routes.feedCheck,
            ),
          ],
        ],
      ),
      (
        t.moreSectionAccount,
        [
          page('profile', Icons.person_outline, t.profileTitle, Routes.profile),
          if (config.marketLink)
            page(
              'ml-actions',
              Icons.shield_outlined,
              t.mlActionsTitle,
              Routes.mlActions,
            ),
          page(
            'settings',
            Icons.settings_outlined,
            t.settingsTitle,
            Routes.settings,
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.xs,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          for (final (title, entries) in sections) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: BmSpace.md,
                bottom: BmSpace.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(title, style: BmType.section),
              ),
            ),
            BmCard(
              elevated: false,
              padding: const EdgeInsets.symmetric(vertical: BmSpace.xxs),
              radius: BmRadius.card,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (final (id, icon, label, onTap) in entries)
                      ListTile(
                        key: Key('more-$id'),
                        leading: Icon(icon, color: context.bm.brand),
                        title: Text(label, style: BmType.bodyStrong),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: onTap,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

typedef _Entry = (String id, IconData icon, String title, VoidCallback onTap);
