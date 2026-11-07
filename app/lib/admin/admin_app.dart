import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'admin_auth.dart';
import 'admin_sign_in.dart';
import 'document_picker.dart';
import 'feed_admin_repository.dart';
import 'feed_pages.dart';
import 'kb_admin_repository.dart';
import 'kb_pages.dart';
import 'market_link_admin_repository.dart';
import 'market_link_appeals_page.dart';
import 'market_link_pages.dart';
import 'market_link_rechecks.dart';
import 'market_link_safety_admin.dart';
import 'market_link_safety_pages.dart';

/// Admin web shell (ADR 0006). Sections map to the config tables that keep business
/// values out of code (spec §0.5); editors arrive with the milestones that own them.
class AdminApp extends StatelessWidget {
  const AdminApp({
    super.key,
    required this.productName,
    this.kb,
    this.feed,
    this.documents,
    this.marketLink,
    this.safety,
    this.auth,
  });

  final String productName;

  /// Null when no admin can sign in (no backend); KB sections then explain why.
  final KbAdminRepository? kb;

  /// Government feed review (API `/v1/admin/feed`); shown only to role `feed_admin`.
  final FeedAdminRepository? feed;

  /// GR document picker for the feed upload (defaults to `file_picker`).
  final DocumentPicker? documents;

  /// Market linkage verification queue and rating tags; null unless the build has
  /// `MARKET_LINK` on (decision j). Shown only to role `market_link_admin`.
  final MarketLinkAdminRepository? marketLink;

  /// Market linkage reports and appeals (L6); same gate and role as [marketLink].
  final MarketLinkSafetyAdmin? safety;

  /// When set, the shell is shown only to a signed-in staff account.
  final AdminAuth? auth;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: BmTheme.light(),
    darkTheme: BmTheme.dark(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: switch (auth) {
      null => AdminShell(
        productName: productName,
        kb: kb,
        feed: feed,
        documents: documents,
        marketLink: marketLink,
        safety: safety,
      ),
      final a => StreamBuilder<void>(
        stream: a.changes,
        builder: (context, _) => a.accessToken == null
            ? AdminSignInScreen(auth: a, productName: productName)
            : AdminShell(
                productName: productName,
                kb: kb,
                feed: feed,
                documents: documents,
                marketLink: marketLink,
                safety: safety,
                roles: a.roles,
                onSignOut: a.signOut,
              ),
      ),
    },
  );
}

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.productName,
    this.kb,
    this.feed,
    this.documents,
    this.marketLink,
    this.safety,
    this.roles = const {},
    this.onSignOut,
  });

  final String productName;
  final KbAdminRepository? kb;
  final FeedAdminRepository? feed;
  final DocumentPicker? documents;
  final MarketLinkAdminRepository? marketLink;
  final MarketLinkSafetyAdmin? safety;

  /// Supabase app_metadata roles of the signed-in account (gates the feed section).
  final Set<String> roles;
  final VoidCallback? onSignOut;

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
      if (widget.feed case final feed?
          when widget.roles.contains(feedAdminRole))
        (
          t.adminFeed,
          Icons.campaign_rounded,
          FeedAdminSection(feed: feed, documents: widget.documents),
        ),
      if (widget.marketLink case final ml?
          when widget.roles.contains(marketLinkAdminRole)) ...[
        (
          t.adminMlQueue,
          Icons.verified_user_rounded,
          VerificationQueuePage(repo: ml),
        ),
        (
          t.adminMlRechecks,
          Icons.event_repeat_rounded,
          RecheckListPage(repo: ml),
        ),
        (t.adminMlTags, Icons.sell_rounded, RatingTagsPage(repo: ml)),
        if (widget.safety case final safety?) ...[
          (t.adminMlReports, Icons.flag_rounded, ReportsPage(repo: safety)),
          (t.adminMlAppeals, Icons.gavel_rounded, AppealsPage(repo: safety)),
        ],
      ],
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
        actions: [
          if (widget.onSignOut case final signOut?)
            IconButton(
              tooltip: t.adminSignOut,
              onPressed: signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: Row(
        children: [
          // Scrolls when the sections outgrow a short window (a laptop at 800 px).
          LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final (label, icon, _) in sections)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          label: Text(label),
                        ),
                    ],
                  ),
                ),
              ),
            ),
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
