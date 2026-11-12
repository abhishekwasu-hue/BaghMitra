import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/feed_receipts.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import 'feed_screen.dart';

/// A news topic in the feed list (owner Q139): the latest report's title, its date and how
/// many reports the topic has. Calm like the item cards; the dot marks unopened reports.
class FeedThreadCard extends StatelessWidget {
  const FeedThreadCard({
    super.key,
    required this.entry,
    required this.lang,
    required this.hasNew,
  });

  final FeedThreadEntry entry;
  final String lang;
  final bool hasNew;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    // Its own Material, so the card's box moves with its text (see the item card).
    return Material(
      color: c.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BmRadius.tile),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        key: Key('feed-thread-${entry.id}'),
        onTap: () => context.push(Routes.feedThread(entry.id)),
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FeedBadge(
                      item: entry.items.first,
                      lang: lang,
                      date: entry.latestAt,
                    ),
                    const SizedBox(height: BmSpace.xxs),
                    Text(entry.title, style: BmType.bodyStrong),
                    const SizedBox(height: BmSpace.xxs),
                    Row(
                      children: [
                        Icon(
                          Icons.view_timeline_outlined,
                          size: 18,
                          color: c.inkMuted,
                        ),
                        const SizedBox(width: BmSpace.xxs),
                        Expanded(
                          child: Text(
                            t.feedThreadCount(formatInt(entry.count, lang)),
                            key: Key('feed-thread-count-${entry.id}'),
                            style: BmType.meta.copyWith(color: c.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasNew)
                FeedUnseenDot(dotKey: Key('feed-thread-unseen-${entry.id}')),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small "new" dot of the list cards.
class FeedUnseenDot extends StatelessWidget {
  const FeedUnseenDot({super.key, required this.dotKey});

  final Key dotKey;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Padding(
      padding: const EdgeInsets.only(left: BmSpace.xs),
      child: Semantics(
        label: t.feedUnseen,
        child: Container(
          key: dotKey,
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// The reports of one topic: the topic's saved copy (`GET /v1/feed/threads/{id}`) and any
/// of its reports in the saved feed, newest copy of each, oldest first.
List<FeedItem> threadItems(
  String threadId,
  FeedThreadPage? page,
  List<FeedItem> feed,
  Set<String> dismissed,
) {
  final byId = <String, FeedItem>{
    for (final i in page?.items ?? const <FeedItem>[]) i.id: i,
    for (final i in feed)
      if (i.threadId == threadId) i.id: i,
  };
  return [
    for (final i in byId.values)
      if (!dismissed.contains(i.id)) i,
  ]..sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
}

/// One news topic opened (owner Q139): a dated timeline of every report, oldest first, each
/// with its checked summary and source link; a report opens in full on tap. Works offline
/// from the saved copies. Opening it marks every report seen; the reports that were new stay
/// marked "New" for this visit.
class FeedThreadScreen extends ConsumerStatefulWidget {
  const FeedThreadScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<FeedThreadScreen> createState() => _FeedThreadScreenState();
}

class _FeedThreadScreenState extends ConsumerState<FeedThreadScreen> {
  /// Reports that were not opened when this visit saw them first.
  final _newOnOpen = <String>{};
  final _handled = <String>{};

  void _markSeen(List<FeedItem> items, Set<String> seenIds) {
    final fresh = [
      for (final i in items)
        if (!_handled.contains(i.id)) i,
    ];
    if (fresh.isEmpty) return;
    for (final i in fresh) {
      _handled.add(i.id);
      if (!i.seen && !seenIds.contains(i.id)) _newOnOpen.add(i.id);
    }
    final toSend = [
      for (final i in fresh)
        if (_newOnOpen.contains(i.id)) i.id,
    ];
    if (toSend.isEmpty) return;
    final store = ref.read(feedReceiptsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final id in toSend) {
        await store.record(id, FeedReceiptAction.seen);
      }
      if (mounted) ref.invalidate(feedReceiptStateProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final threadId = widget.threadId;
    final feed = ref.watch(feedProvider(lang));
    final thread = ref.watch(feedThreadProvider((lang, threadId)));
    final receipts =
        ref.watch(feedReceiptStateProvider).value ?? const FeedReceiptState();
    final items = threadItems(
      threadId,
      thread.value?.page,
      feed.value?.page.items ?? const [],
      receipts.dismissed,
    );
    if (items.isNotEmpty) _markSeen(items, receipts.seen);
    final loading =
        (feed.isLoading && !feed.hasValue) ||
        (thread.isLoading && !thread.hasValue);
    final footer = thread.value?.page.footer ?? feed.value?.page.footer;

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.feedTitle)),
      body: items.isEmpty
          ? loading
                ? LoadingState(label: t.loadingLabel)
                : Center(child: Text(t.feedNotFound, style: BmType.meta))
          : ListView(
              key: const Key('feed-thread-list'),
              padding: const EdgeInsets.all(BmSpace.lg),
              children: [
                FeedBadge(item: items.last, lang: lang),
                const SizedBox(height: BmSpace.xxs),
                Text(items.last.title, style: BmType.cardTitle),
                const SizedBox(height: BmSpace.xxs),
                Text(
                  [
                    t.feedThreadCount(formatInt(items.length, lang)),
                    t.feedThreadLatest(
                      formatDate(items.last.publishedAt.toLocal(), lang),
                    ),
                  ].join(' · '),
                  key: const Key('feed-thread-meta'),
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: BmSpace.lg),
                Text(t.feedThreadTimeline, style: BmType.formLabel),
                const SizedBox(height: BmSpace.sm),
                for (final (n, item) in items.indexed)
                  _TimelineEntry(
                    item: item,
                    threadId: threadId,
                    lang: lang,
                    isNew: _newOnOpen.contains(item.id),
                    last: n == items.length - 1,
                  ),
                const SizedBox(height: BmSpace.xs),
                FeedFooter(serverFooter: footer),
              ],
            ),
    );
  }
}

/// One report on the timeline: a dot and a line on the left, the date, title, checked
/// summary and source link on the right. Tapping the text opens the report in full.
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.item,
    required this.threadId,
    required this.lang,
    required this.isNew,
    required this.last,
  });

  final FeedItem item;
  final String threadId;
  final String lang;
  final bool isNew;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return IntrinsicHeight(
      key: Key('feed-thread-item-${item.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: last ? c.brandStrong : c.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.brandStrong, width: 2),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: BmSpace.xxs),
                      color: c.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: BmSpace.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : BmSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    hint: t.feedThreadOpenItem,
                    child: InkWell(
                      key: Key('feed-thread-open-${item.id}'),
                      borderRadius: BorderRadius.circular(BmRadius.chip),
                      onTap: () => context.push(
                        Routes.feedItem(item.id, threadId: threadId),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: BmSpace.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                formatDate(item.publishedAt.toLocal(), lang),
                                style: BmType.label.copyWith(color: c.inkMuted),
                              ),
                              if (isNew)
                                Text(
                                  t.feedUnseen,
                                  key: Key('feed-thread-new-${item.id}'),
                                  style: BmType.label.copyWith(
                                    color: c.brandStrong,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: BmSpace.xxs),
                          Text(item.title, style: BmType.bodyStrong),
                          if (item.summary.isNotEmpty) ...[
                            const SizedBox(height: BmSpace.xxs),
                            Text(item.summary, style: BmType.body),
                          ],
                        ],
                      ),
                    ),
                  ),
                  FeedSourceLink(url: item.url),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
