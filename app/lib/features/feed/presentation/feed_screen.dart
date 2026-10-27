import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../tasks/domain/farm_task.dart';
import '../data/feed_receipts.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';

/// Sarkari Sandesh: official GRs, circulars, schemes and alerts, plus clearly marked news,
/// newest first, from the phone's cache so it works offline. Information, not advice: the
/// "check the official GR/portal" footer is always on screen.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedFilter? _filter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final cached = ref.watch(feedProvider(lang)).value;
    final receipts =
        ref.watch(feedReceiptStateProvider).value ?? const FeedReceiptState();
    final items = [
      for (final i in filterFeed(cached?.page.items ?? const [], _filter))
        if (!receipts.dismissed.contains(i.id)) i,
    ];
    final now = ref.watch(clockProvider)();

    final filters = <FeedFilter?, String>{
      null: t.feedFilterAll,
      FeedFilter.official: t.feedFilterOfficial,
      FeedFilter.scheme: t.feedFilterSchemes,
      FeedFilter.deadline: t.feedFilterDeadlines,
      FeedFilter.news: t.feedFilterNews,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.feedTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
        actions: [
          IconButton(
            key: const Key('feed-open-check'),
            tooltip: t.feedCheckTitle,
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () => context.push(Routes.feedCheck),
          ),
          IconButton(
            key: const Key('feed-open-settings'),
            tooltip: t.feedPrefsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(Routes.feedSettings),
          ),
        ],
      ),
      bottomNavigationBar: FeedFooter(serverFooter: cached?.page.footer),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              for (final MapEntry(key: f, value: label) in filters.entries)
                ChoiceChip(
                  key: Key('feed-filter-${f?.value ?? 'all'}'),
                  label: Text(label),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          if (cached != null) ...[
            const SizedBox(height: BmSpace.xs),
            Text(
              t.feedUpdated(formatDate(cached.savedAt.toLocal(), lang)),
              style: BmType.meta,
            ),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BmSpace.lg),
              child: Text(t.feedEmpty, style: BmType.meta),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.sm),
              child: InkWell(
                key: Key('feed-item-${item.id}'),
                borderRadius: BorderRadius.circular(BmRadius.tile),
                onTap: () => context.push(Routes.feedItem(item.id)),
                child: Ink(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(BmRadius.tile),
                    border: Border.all(color: c.line),
                  ),
                  padding: const EdgeInsets.all(BmSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ItemBody(item: item, now: now, lang: lang),
                      ),
                      if (!item.seen && !receipts.seen.contains(item.id))
                        Padding(
                          padding: const EdgeInsets.only(left: BmSpace.xs),
                          child: Semantics(
                            label: t.feedUnseen,
                            child: Container(
                              key: Key('feed-unseen-${item.id}'),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One feed item: trust badge, title, status banners, deadline and eligibility lines.
class _ItemBody extends StatelessWidget {
  const _ItemBody({
    required this.item,
    required this.now,
    required this.lang,
    this.detail = false,
  });

  final FeedItem item;
  final DateTime now;
  final String lang;
  final bool detail;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedBadge(item: item, lang: lang),
        const SizedBox(height: BmSpace.xxs),
        Text(item.title, style: detail ? BmType.cardTitle : BmType.bodyStrong),
        if (item.replacedBy case final replacement?)
          _Banner(
            key: Key('feed-replaced-${item.id}'),
            text: t.feedReplacedBy(replacement),
          )
        else if (item.isExpired(now))
          _Banner(
            key: Key('feed-expired-${item.id}'),
            text: t.feedExpired(formatDate(item.validTo!, lang)),
          ),
        if (detail && item.summary.isNotEmpty) ...[
          const SizedBox(height: BmSpace.xs),
          Text(item.summary, style: BmType.body),
        ],
        if (item.deadline case final deadline?)
          Padding(
            padding: const EdgeInsets.only(top: BmSpace.xxs),
            child: Text(
              t.feedDeadline(formatDate(deadline, lang)),
              style: BmType.meta.copyWith(color: c.accent),
            ),
          ),
        if (item.showsEligibility(now))
          for (final reason in item.mayBeEligibleBecause)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xxs),
              child: Text(
                t.feedMayBeEligible(reason),
                style: BmType.meta.copyWith(color: c.brandStrong),
              ),
            ),
      ],
    );
  }
}

/// "Official · GR no · date · department" for government items; "News — not official"
/// (with the date) for news, so the two are never confused.
class FeedBadge extends StatelessWidget {
  const FeedBadge({super.key, required this.item, required this.lang});

  final FeedItem item;
  final String lang;

  static String text(AppLocalizations t, FeedItem item, String lang) {
    final date = formatDate(item.publishedAt.toLocal(), lang);
    if (!item.isOfficial) return '${t.feedBadgeNews} · $date';
    return [
      t.feedBadgeOfficial,
      if (item.grNumber case final n?) t.feedGrNumber(n),
      date,
      ?item.department,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final official = item.isOfficial;
    return DecoratedBox(
      key: Key('feed-badge-${item.id}'),
      decoration: BoxDecoration(
        color: official ? c.brandSoft : c.accentSoft,
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BmSpace.xs,
          vertical: BmSpace.xxs,
        ),
        child: Text(
          text(t, item, lang),
          style: BmType.label.copyWith(
            color: official ? c.brandStrong : c.warnTitle,
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: BmSpace.xs),
      padding: const EdgeInsets.all(BmSpace.xs),
      decoration: BoxDecoration(
        border: Border.all(color: c.warnBorder),
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Text(text, style: BmType.meta.copyWith(color: c.warnTitle)),
    );
  }
}

/// The standing "check the official GR/portal before acting" line (plus the server's own
/// footer when it says something else), pinned to the bottom so it is always visible.
class FeedFooter extends StatelessWidget {
  const FeedFooter({super.key, this.serverFooter});

  final String? serverFooter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final extra = serverFooter;
    return SafeArea(
      child: DecoratedBox(
        key: const Key('feed-footer'),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BmSpace.lg,
            vertical: BmSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.feedFooter, style: BmType.bodyStrong),
              if (extra != null && extra.isNotEmpty && extra != t.feedFooter)
                Text(extra, style: BmType.meta),
            ],
          ),
        ),
      ),
    );
  }
}

/// The short text "Share" hands on: title, last date, the source link and the footer, in
/// the grower's language. Never more than the item says.
String feedShareText(AppLocalizations t, FeedItem item, String lang) => [
  item.title,
  FeedBadge.text(t, item, lang),
  if (item.replacedBy case final r?) t.feedReplacedBy(r),
  if (item.deadline case final d?) t.feedDeadline(formatDate(d, lang)),
  t.feedSource(item.url),
  t.feedFooter,
].join('\n');

/// One item in full: summary, deadline, source link, and the remind / share / hide
/// actions. Opening it marks it seen (on the phone at once, on the server when online).
class FeedItemScreen extends ConsumerStatefulWidget {
  const FeedItemScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<FeedItemScreen> createState() => _FeedItemScreenState();
}

class _FeedItemScreenState extends ConsumerState<FeedItemScreen> {
  bool _markedSeen = false;

  String get itemId => widget.itemId;

  /// Records a receipt; [receipts] is read up front by callers that await first.
  Future<void> _receipt(
    String id,
    FeedReceiptAction action, [
    FeedReceipts? receipts,
  ]) async {
    if (receipts == null && !mounted) return;
    final FeedReceipts store = receipts ?? ref.read(feedReceiptsProvider);
    await store.record(id, action);
    if (mounted) ref.invalidate(feedReceiptStateProvider);
  }

  void _markSeen(FeedItem item) {
    if (_markedSeen || item.seen) return;
    _markedSeen = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _receipt(item.id, FeedReceiptAction.seen),
    );
  }

  Future<void> _dismiss(FeedItem item) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    await _receipt(item.id, FeedReceiptAction.dismiss);
    messenger.showSnackBar(SnackBar(content: Text(t.feedDismissed)));
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final cached = ref.watch(feedProvider(lang)).value;
    final now = ref.watch(clockProvider)();
    final item = cached?.page.items.where((i) => i.id == itemId).firstOrNull;
    if (item != null) _markSeen(item);
    final tasks = ref.watch(tasksProvider).value ?? const <FarmTask>[];
    final reminded =
        item != null &&
        tasks.any((task) => task.source == feedTaskSource(item));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.feedTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      bottomNavigationBar: FeedFooter(serverFooter: cached?.page.footer),
      body: item == null
          ? Center(child: Text(t.feedNotFound, style: BmType.meta))
          : ListView(
              padding: const EdgeInsets.all(BmSpace.lg),
              children: [
                _ItemBody(item: item, now: now, lang: lang, detail: true),
                const SizedBox(height: BmSpace.md),
                SelectableText(t.feedSource(item.url), style: BmType.meta),
                const SizedBox(height: BmSpace.md),
                Wrap(
                  spacing: BmSpace.xs,
                  runSpacing: BmSpace.xs,
                  children: [
                    if (reminded)
                      Chip(
                        key: const Key('feed-reminded'),
                        avatar: const Icon(Icons.check),
                        label: Text(t.feedReminderExists),
                      )
                    else if (item.canRemind(now))
                      FilledButton.icon(
                        key: const Key('feed-remind'),
                        icon: const Icon(Icons.alarm_add_outlined),
                        label: Text(t.feedRemindMe),
                        onPressed: () => _remind(item),
                      ),
                    OutlinedButton.icon(
                      key: const Key('feed-share'),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(t.feedShare),
                      onPressed: () => ref
                          .read(textSharerProvider)
                          .shareText(feedShareText(t, item, lang)),
                    ),
                    OutlinedButton.icon(
                      key: const Key('feed-copy-link'),
                      icon: const Icon(Icons.link),
                      label: Text(t.feedCopyLink),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: item.url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.feedLinkCopied)),
                          );
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      key: const Key('feed-dismiss'),
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: Text(t.feedDismiss),
                      onPressed: () => _dismiss(item),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// Adds an orchard-wide task due on the item's last date (once per item), and tells the
  /// server so its reminder alert goes out too.
  Future<void> _remind(FeedItem item) async {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(tasksRepositoryProvider);
    final receipts = ref.read(feedReceiptsProvider);
    final deadline = item.deadline!;
    await repo.save(
      FarmTask(
        id: repo.newId(),
        title: item.title,
        kind: 'other',
        dueOn: DateTime(deadline.year, deadline.month, deadline.day),
        source: feedTaskSource(item),
        note: item.url,
      ),
    );
    messenger.showSnackBar(
      SnackBar(content: Text(t.feedReminderAdded(formatDate(deadline, lang)))),
    );
    await _receipt(item.id, FeedReceiptAction.remind, receipts);
  }
}

/// The task `source` that marks a reminder made from a feed item.
String feedTaskSource(FeedItem item) => 'feed:${item.id}';
