import 'dart:math' as math;

import '../../bahar/domain/bahar_cycle.dart';
import '../../tasks/domain/farm_task.dart';
import 'feed_article.dart';

/// One entry of the Sarkari Sandesh feed (`GET /v1/feed`): a government GR, circular, scheme
/// or alert ([trust] official), or a news report ([trust] news, never presented as official).
class FeedItem {
  const FeedItem({
    required this.id,
    required this.type,
    required this.trust,
    required this.title,
    required this.summary,
    required this.publishedAt,
    required this.url,
    this.department,
    this.level,
    this.grNumber,
    this.deadline,
    this.validTo,
    this.replacedBy,
    this.mayBeEligibleBecause = const [],
    this.seen = false,
    this.article,
    this.threadId,
  });

  factory FeedItem.fromJson(Map<String, Object?> j) => FeedItem(
    id: j['id']! as String,
    type: j['type']! as String,
    trust: j['trust']! as String,
    title: j['title']! as String,
    summary: (j['summary'] as String?) ?? '',
    department: j['department'] as String?,
    level: levelOf(j['level']),
    grNumber: j['gr_number'] as String?,
    publishedAt: DateTime.parse(j['published_at']! as String),
    url: j['url']! as String,
    deadline: _date(j['deadline']),
    validTo: _date(j['valid_to']),
    replacedBy: j['replaced_by'] as String?,
    mayBeEligibleBecause: [
      for (final r in (j['may_be_eligible_because'] as List?) ?? const [])
        r as String,
    ],
    seen: (j['seen'] as bool?) ?? false,
    article: FeedArticle.tryParse(j['article']),
    threadId: j['thread_id'] as String?,
  );

  final String id;

  /// `gr`, `circular`, `scheme`, `alert` or `news`.
  final String type;

  /// `official` or `news`.
  final String trust;
  final String title;
  final String summary;
  final String? department;

  /// "central" (Government of India) or "state" (Maharashtra); null when not known.
  final String? level;
  final String? grNumber;
  final DateTime publishedAt;
  final String url;
  final DateTime? deadline;
  final DateTime? validTo;
  final String? replacedBy;
  final List<String> mayBeEligibleBecause;

  /// The server's record that this grower already opened the item.
  final bool seen;

  /// The AI article from the official source (spec v1.6); null for older items.
  final FeedArticle? article;

  /// The news topic this item belongs to (owner Q139); null for official items and news the
  /// server has not threaded yet.
  final String? threadId;

  bool get isOfficial => trust == 'official';

  bool get isWithdrawn => replacedBy != null;

  /// Past its validity date (the day itself still counts as valid).
  bool isExpired(DateTime now) =>
      validTo != null && dateOnly(validTo!).isBefore(dateOnly(now));

  /// Spec §6: never present a scheme as available once it is withdrawn or expired, so the
  /// "you may be eligible" lines are only shown while the item is still live.
  bool showsEligibility(DateTime now) =>
      mayBeEligibleBecause.isNotEmpty && !isWithdrawn && !isExpired(now);

  /// A reminder only makes sense for a deadline that has not passed.
  bool canRemind(DateTime now) =>
      deadline != null &&
      !isWithdrawn &&
      !dateOnly(deadline!).isBefore(dateOnly(now));

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'trust': trust,
    'title': title,
    'summary': summary,
    'department': department,
    'level': level,
    'article': article?.toJson(),
    'gr_number': grNumber,
    'published_at': publishedAt.toUtc().toIso8601String(),
    'url': url,
    'deadline': deadline == null ? null : BaharCycle.isoDate(deadline!),
    'valid_to': validTo == null ? null : BaharCycle.isoDate(validTo!),
    'replaced_by': replacedBy,
    'may_be_eligible_because': mayBeEligibleBecause,
    'seen': seen,
    'thread_id': threadId,
  };

  /// "central" or "state"; anything else (missing, unknown) is null.
  static String? levelOf(Object? v) => switch (v) {
    'central' || 'state' => v as String,
    _ => null,
  };

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}

/// The feed answer: items plus the server's standard footer line, and the news topics
/// ([threads], owner Q139) the items belong to.
class FeedPage {
  const FeedPage({
    required this.items,
    this.footer = '',
    this.threads = const {},
  });

  factory FeedPage.fromJson(Map<String, Object?> j) => FeedPage(
    items: [
      for (final i in (j['items'] as List?) ?? const [])
        FeedItem.fromJson((i as Map).cast<String, Object?>()),
    ],
    footer: (j['footer'] as String?) ?? '',
    threads: {
      for (final t in [
        for (final raw in (j['threads'] as List?) ?? const [])
          FeedThread.fromJson((raw as Map).cast<String, Object?>()),
      ])
        t.id: t,
    },
  );

  final List<FeedItem> items;
  final String footer;

  /// By thread id.
  final Map<String, FeedThread> threads;

  Map<String, Object?> toJson() => {
    'items': [for (final i in items) i.toJson()],
    'footer': footer,
    'threads': [for (final t in threads.values) t.toJson()],
  };
}

/// A news topic (owner Q139): several reports of one event or decision. The title and
/// summary are the latest report's own checked text; the counts cover every report.
class FeedThread {
  const FeedThread({
    required this.id,
    required this.title,
    required this.latestAt,
    required this.itemCount,
    this.summary,
    this.unseenCount = 0,
  });

  factory FeedThread.fromJson(Map<String, Object?> j) => FeedThread(
    id: j['id']! as String,
    title: j['title']! as String,
    summary: j['summary'] as String?,
    latestAt: DateTime.parse(j['latest_at']! as String),
    itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
    unseenCount: (j['unseen_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String title;
  final String? summary;
  final DateTime latestAt;
  final int itemCount;

  /// Reports the grower had not opened when the server answered.
  final int unseenCount;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'latest_at': latestAt.toUtc().toIso8601String(),
    'item_count': itemCount,
    'unseen_count': unseenCount,
    'has_new': unseenCount > 0,
  };
}

/// One topic opened (`GET /v1/feed/threads/{id}`): every report, oldest first.
class FeedThreadPage {
  const FeedThreadPage({
    required this.thread,
    required this.items,
    this.footer = '',
  });

  factory FeedThreadPage.fromJson(Map<String, Object?> j) => FeedThreadPage(
    thread: FeedThread.fromJson((j['thread']! as Map).cast<String, Object?>()),
    items: [
      for (final i in (j['items'] as List?) ?? const [])
        FeedItem.fromJson((i as Map).cast<String, Object?>()),
    ],
    footer: (j['footer'] as String?) ?? '',
  );

  final FeedThread thread;

  /// Oldest first: the dated timeline.
  final List<FeedItem> items;
  final String footer;

  Map<String, Object?> toJson() => {
    'thread': thread.toJson(),
    'items': [for (final i in items) i.toJson()],
    'footer': footer,
  };
}

/// One card of the feed list: a single item, or a topic with several reports.
sealed class FeedEntry {
  const FeedEntry();
}

class FeedItemEntry extends FeedEntry {
  const FeedItemEntry(this.item);

  final FeedItem item;
}

class FeedThreadEntry extends FeedEntry {
  const FeedThreadEntry({
    required this.id,
    required this.title,
    required this.latestAt,
    required this.count,
    required this.items,
    this.serverUnseen = 0,
  });

  final String id;
  final String title;
  final DateTime latestAt;

  /// Reports in the topic (at least the ones in the list).
  final int count;

  /// The topic's reports that are in the list, newest first.
  final List<FeedItem> items;

  /// Unopened reports the server knows of that are not in the list.
  final int serverUnseen;

  /// Any report not opened yet, given the phone's own [seenIds].
  bool hasNew(Set<String> seenIds) =>
      serverUnseen > 0 || items.any((i) => !i.seen && !seenIds.contains(i.id));
}

/// The list cards for [items] (already filtered, newest first): news of one topic become a
/// single card placed where its newest report is (owner Q139); a topic with one report
/// stays a plain item card.
List<FeedEntry> feedEntries(
  List<FeedItem> items,
  Map<String, FeedThread> threads,
) {
  final groups = <String, List<FeedItem>>{};
  final order = <Object>[];
  for (final i in items) {
    final id = i.threadId;
    if (id == null) {
      order.add(i);
      continue;
    }
    final group = groups[id];
    if (group == null) {
      groups[id] = [i];
      order.add(id);
    } else {
      group.add(i);
    }
  }
  return [
    for (final o in order)
      if (o is FeedItem)
        FeedItemEntry(o)
      else
        _threadEntry(groups[o]!, threads[o]),
  ];
}

FeedEntry _threadEntry(List<FeedItem> group, FeedThread? meta) {
  final count = math.max(group.length, meta?.itemCount ?? 0);
  if (count < 2) return FeedItemEntry(group.first);
  final listedUnseen = group.where((i) => !i.seen).length;
  return FeedThreadEntry(
    id: group.first.threadId!,
    title: meta?.title ?? group.first.title,
    latestAt: meta?.latestAt ?? group.first.publishedAt,
    count: count,
    items: group,
    serverUnseen: math.max(0, (meta?.unseenCount ?? 0) - listedUnseen),
  );
}

/// The filter chips; [value] is the API's `type` query value.
enum FeedFilter {
  official('official'),
  scheme('scheme'),
  deadline('deadline'),
  news('news');

  const FeedFilter(this.value);

  final String value;

  bool matches(FeedItem i) => switch (this) {
    FeedFilter.official => i.isOfficial,
    FeedFilter.scheme => i.type == 'scheme',
    FeedFilter.deadline => i.deadline != null,
    FeedFilter.news => !i.isOfficial,
  };
}

/// Newest first, optionally narrowed by one filter.
List<FeedItem> filterFeed(List<FeedItem> items, FeedFilter? filter) {
  final out = [
    for (final i in items)
      if (filter == null || filter.matches(i)) i,
  ]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  return out;
}
