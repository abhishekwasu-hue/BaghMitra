import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart';
import 'kb_pages.dart';

/// Admin web shell (ADR 0006). Sections map to the config tables that keep business
/// values out of code (spec §0.5); editors arrive with the milestones that own them.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.productName, this.kb});

  final String productName;

  /// Null until an admin has signed in; KB sections then explain what is needed.
  final KbAdminRepository? kb;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: BmTheme.light(),
    darkTheme: BmTheme.dark(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: AdminShell(productName: productName, kb: kb),
  );
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.productName, this.kb});

  final String productName;
  final KbAdminRepository? kb;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final kb = widget.kb;
    Widget kbPage(Widget Function(KbAdminRepository) page) =>
        kb == null ? Text(t.adminSignInRequired, style: BmType.body) : page(kb);
    Widget soon(int milestone) =>
        Text(t.adminComingSoon(milestone), style: BmType.body);
    final sections = [
      (
        t.adminCards,
        Icons.menu_book_rounded,
        kbPage((r) => KbCardsPage(kb: r)),
      ),
      (
        t.adminImports,
        Icons.upload_file_rounded,
        kbPage((r) => KbImportPage(kb: r)),
      ),
      (
        t.adminAlerts,
        Icons.notification_important_rounded,
        kbPage((r) => KbAlertsPage(kb: r)),
      ),
      (
        t.adminSources,
        Icons.library_books_rounded,
        kbPage((r) => KbSourcesPage(kb: r)),
      ),
      (t.adminCropTemplates, Icons.eco_rounded, soon(1)),
      (t.adminRiskRules, Icons.thunderstorm_rounded, soon(4)),
      (t.adminPrompts, Icons.auto_awesome_rounded, soon(3)),
      (t.adminTranslations, Icons.translate_rounded, soon(1)),
      (t.adminAiUsage, Icons.query_stats_rounded, soon(3)),
    ];
    final (title, _, body) = sections[_index];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        title: Text(
          t.adminTitle(widget.productName),
          style: BmType.section.copyWith(color: c.onBrand),
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final (label, icon, _) in sections)
                NavigationRailDestination(icon: Icon(icon), label: Text(label)),
            ],
          ),
          VerticalDivider(width: 1, color: c.line),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(BmSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BmType.title.copyWith(color: c.brand)),
                  const SizedBox(height: BmSpace.sm),
                  Expanded(
                    child: KeyedSubtree(key: ValueKey(_index), child: body),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
