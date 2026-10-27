import '../../bahar/domain/bahar_cycle.dart';
import '../../tasks/domain/farm_task.dart';

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
    this.grNumber,
    this.deadline,
    this.validTo,
    this.replacedBy,
    this.mayBeEligibleBecause = const [],
    this.seen = false,
  });

  factory FeedItem.fromJson(Map<String, Object?> j) => FeedItem(
    id: j['id']! as String,
    type: j['type']! as String,
    trust: j['trust']! as String,
    title: j['title']! as String,
    summary: (j['summary'] as String?) ?? '',
    department: j['department'] as String?,
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
  );

  final String id;

  /// `gr`, `circular`, `scheme`, `alert` or `news`.
  final String type;

  /// `official` or `news`.
  final String trust;
  final String title;
  final String summary;
  final String? department;
  final String? grNumber;
  final DateTime publishedAt;
  final String url;
  final DateTime? deadline;
  final DateTime? validTo;
  final String? replacedBy;
  final List<String> mayBeEligibleBecause;

  /// The server's record that this grower already opened the item.
  final bool seen;

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
    'gr_number': grNumber,
    'published_at': publishedAt.toUtc().toIso8601String(),
    'url': url,
    'deadline': deadline == null ? null : BaharCycle.isoDate(deadline!),
    'valid_to': validTo == null ? null : BaharCycle.isoDate(validTo!),
    'replaced_by': replacedBy,
    'may_be_eligible_because': mayBeEligibleBecause,
    'seen': seen,
  };

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}

/// The feed answer: items plus the server's standard footer line.
class FeedPage {
  const FeedPage({required this.items, this.footer = ''});

  factory FeedPage.fromJson(Map<String, Object?> j) => FeedPage(
    items: [
      for (final i in (j['items'] as List?) ?? const [])
        FeedItem.fromJson((i as Map).cast<String, Object?>()),
    ],
    footer: (j['footer'] as String?) ?? '',
  );

  final List<FeedItem> items;
  final String footer;

  Map<String, Object?> toJson() => {
    'items': [for (final i in items) i.toJson()],
    'footer': footer,
  };
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
