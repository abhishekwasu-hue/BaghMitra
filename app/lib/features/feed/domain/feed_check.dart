/// What `POST /v1/feed/check` says about a pasted message: whether an official item in
/// the feed matches it. Never a judgement on the message itself.
enum FeedCheckVerdict {
  officialMatch('official_match'),
  possibleMatch('possible_match'),
  noOfficialMatch('no_official_match');

  const FeedCheckVerdict(this.value);

  final String value;

  /// Anything the app does not know is read as "no official match".
  static FeedCheckVerdict parse(Object? v) => values.firstWhere(
    (e) => e.value == v,
    orElse: () => FeedCheckVerdict.noOfficialMatch,
  );
}

class FeedCheckMatch {
  const FeedCheckMatch({
    required this.id,
    required this.title,
    required this.url,
    this.grNumber,
    this.publishedAt,
    this.score = 0,
  });

  factory FeedCheckMatch.fromJson(Map<String, Object?> j) => FeedCheckMatch(
    id: j['id']! as String,
    title: j['title']! as String,
    url: j['url']! as String,
    grNumber: j['gr_number'] as String?,
    publishedAt: switch (j['published_at']) {
      final String s => DateTime.tryParse(s),
      _ => null,
    },
    score: (j['score'] as num?)?.toDouble() ?? 0,
  );

  final String id;
  final String title;
  final String url;
  final String? grNumber;
  final DateTime? publishedAt;
  final double score;
}

class FeedCheckResult {
  const FeedCheckResult({
    required this.verdict,
    this.matches = const [],
    this.note = '',
  });

  factory FeedCheckResult.fromJson(Map<String, Object?> j) => FeedCheckResult(
    verdict: FeedCheckVerdict.parse(j['verdict']),
    matches: [
      for (final m in (j['matches'] as List?) ?? const [])
        FeedCheckMatch.fromJson((m as Map).cast<String, Object?>()),
    ],
    note: (j['note'] as String?) ?? '',
  );

  final FeedCheckVerdict verdict;
  final List<FeedCheckMatch> matches;
  final String note;
}
