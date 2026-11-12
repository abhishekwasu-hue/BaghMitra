/// An AI news article written from an official source (spec v1.6): headline, standfirst,
/// key points, sections, a facts table, bar / pie charts, key dates and the sources. The
/// server checked every number against the source before publishing it. A knowledge article
/// (ज्ञान लेख, Q141) has the same shape with only sections and sources filled.
class FeedArticle {
  const FeedArticle({
    required this.headline,
    required this.standfirst,
    required this.keyPoints,
    required this.sections,
    required this.facts,
    required this.charts,
    required this.keyDates,
    required this.sources,
    this.cardSection,
  });

  /// Null when [json] is missing or not an article (old caches, a damaged entry).
  static FeedArticle? tryParse(Object? json) {
    if (json is! Map) return null;
    try {
      final j = json.cast<String, Object?>();
      List<Map<String, Object?>> list(String key) => [
        for (final e in (j[key] as List?) ?? const [])
          (e as Map).cast<String, Object?>(),
      ];
      return FeedArticle(
        headline: j['headline']! as String,
        standfirst: j['standfirst']! as String,
        keyPoints: [for (final k in j['key_points']! as List) k as String],
        sections: [
          for (final s in list('sections'))
            (heading: s['heading']! as String, body: s['body']! as String),
        ],
        facts: [
          for (final f in list('facts'))
            (label: f['label']! as String, value: f['value']! as String),
        ],
        charts: [for (final c in list('charts')) ?FeedChart.tryParse(c)],
        keyDates: [
          for (final d in list('key_dates'))
            (
              date: DateTime.parse(d['date']! as String),
              label: d['label']! as String,
            ),
        ],
        sources: [
          for (final s in list('sources'))
            (title: s['title']! as String, url: s['url']! as String),
        ],
        cardSection: j['card_section'] as String?,
      );
    } on Object {
      return null;
    }
  }

  final String headline;
  final String standfirst;
  final List<String> keyPoints;
  final List<({String heading, String body})> sections;
  final List<({String label, String value})> facts;
  final List<FeedChart> charts;
  final List<({DateTime date, String label})> keyDates;
  final List<({String title, String url})> sources;

  /// A knowledge article (Q141): the practice-card section it was written from, opened by
  /// "उपाय व माहिती पहा"; null for news articles and scheme explainers.
  final String? cardSection;

  Map<String, Object?> toJson() => {
    'headline': headline,
    'standfirst': standfirst,
    'key_points': keyPoints,
    'sections': [
      for (final s in sections) {'heading': s.heading, 'body': s.body},
    ],
    'facts': [
      for (final f in facts) {'label': f.label, 'value': f.value},
    ],
    'charts': [for (final c in charts) c.toJson()],
    'key_dates': [
      for (final d in keyDates)
        {
          'date':
              '${d.date.year.toString().padLeft(4, '0')}-'
              '${d.date.month.toString().padLeft(2, '0')}-'
              '${d.date.day.toString().padLeft(2, '0')}',
          'label': d.label,
        },
    ],
    'sources': [
      for (final s in sources) {'title': s.title, 'url': s.url},
    ],
    'card_section': ?cardSection,
  };
}

enum FeedChartType { bar, pie }

class FeedChart {
  const FeedChart({
    required this.type,
    required this.title,
    required this.unit,
    required this.points,
  });

  static FeedChart? tryParse(Map<String, Object?> c) {
    final type = switch (c['type']) {
      'bar' => FeedChartType.bar,
      'pie' => FeedChartType.pie,
      _ => null,
    };
    if (type == null) return null;
    final points = [
      for (final p in c['data']! as List)
        (
          label: (p as Map)['label']! as String,
          value: (p['value']! as num).toDouble(),
        ),
    ];
    if (points.length < 2 || points.any((p) => p.value < 0)) return null;
    return FeedChart(
      type: type,
      title: c['title']! as String,
      unit: (c['unit'] as String?) ?? '',
      points: points,
    );
  }

  final FeedChartType type;
  final String title;
  final String unit;
  final List<({String label, double value})> points;

  Map<String, Object?> toJson() => {
    'type': type.name,
    'title': title,
    'unit': unit,
    'data': [
      for (final p in points) {'label': p.label, 'value': p.value},
    ],
  };
}
