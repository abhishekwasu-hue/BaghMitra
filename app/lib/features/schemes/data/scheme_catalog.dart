import 'dart:convert';

import 'package:flutter/services.dart';

import '../../feed/domain/feed_item.dart';

typedef Labels = Map<String, String>;

String _pick(Labels labels, String lang) => labels[lang] ?? labels['en'] ?? '';

/// One document a scheme usually asks for. [verified]: an official page said so in the
/// research of [SchemesData.checkedOn]; otherwise only secondary sources did.
class SchemeDocument {
  const SchemeDocument(this.key, {required this.verified});

  final String key;
  final bool verified;
}

/// Where to apply: a portal (with its official [url]) or a place (bank, CSC).
class SchemeApplyPlace {
  const SchemeApplyPlace(this.labels, {this.url, required this.verified});

  final Labels labels;
  final String? url;
  final bool verified;

  String label(String lang) => _pick(labels, lang);
}

class SchemeSource {
  const SchemeSource(this.title, this.url, {required this.official});

  final String title;
  final String url;
  final bool official;
}

/// A scheme relevant to santra / mosambi growers: what it is, who can apply in general
/// terms, the documents usually asked for and where to apply. Never an eligibility
/// decision and never an amount.
class Scheme {
  const Scheme({
    required this.id,
    required this.names,
    required this.summaries,
    required this.who,
    required this.documents,
    required this.apply,
    required this.feedKeywords,
    required this.sources,
  });

  final String id;
  final Labels names;
  final Labels summaries;
  final Labels who;
  final List<SchemeDocument> documents;
  final List<SchemeApplyPlace> apply;

  /// Lower-case words that mark a govt feed item as about this scheme.
  final List<String> feedKeywords;
  final List<SchemeSource> sources;

  String name(String lang) => _pick(names, lang);
  String summary(String lang) => _pick(summaries, lang);
  String whoCanApply(String lang) => _pick(who, lang);

  /// Feed items whose title or summary names this scheme, live ones only.
  List<FeedItem> matchingFeedItems(Iterable<FeedItem> items, DateTime now) => [
    for (final item in items)
      if (!item.isWithdrawn &&
          !item.isExpired(now) &&
          _mentions('${item.title}\n${item.summary}'.toLowerCase()))
        item,
  ];

  bool _mentions(String text) => feedKeywords.any(text.contains);
}

class SchemesData {
  const SchemesData({
    required this.checkedOn,
    required this.documentLabels,
    required this.schemes,
  });

  /// When the facts were last checked against the sources.
  final DateTime checkedOn;
  final Map<String, Labels> documentLabels;
  final List<Scheme> schemes;

  String documentLabel(String key, String lang) =>
      _pick(documentLabels[key] ?? {'en': key}, lang);

  Scheme? byId(String id) {
    for (final s in schemes) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Scheme cards from config (`assets/config/schemes.json`), so a reviewer can correct them
/// without a release.
class SchemeCatalog {
  SchemeCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/schemes.json';
  final AssetBundle _bundle;

  Future<SchemesData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Labels labels(Object? m) => (m! as Map).cast<String, String>();
    List<Map<String, dynamic>> list(Object? l) =>
        (l as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    return SchemesData(
      checkedOn: DateTime.parse(json['checked_on'] as String),
      documentLabels: (json['documents'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, labels(v)),
      ),
      schemes: [
        for (final s in list(json['schemes']))
          Scheme(
            id: s['id'] as String,
            names: labels(s['names']),
            summaries: labels(s['summary']),
            who: labels(s['who']),
            documents: [
              for (final d in list(s['documents']))
                SchemeDocument(
                  d['key'] as String,
                  verified: d['verified'] as bool,
                ),
            ],
            apply: [
              for (final a in list(s['apply']))
                SchemeApplyPlace(
                  labels(a['labels']),
                  url: a['url'] as String?,
                  verified: a['verified'] as bool,
                ),
            ],
            feedKeywords: [
              for (final k in (s['feed_keywords'] as List<dynamic>))
                (k as String).toLowerCase(),
            ],
            sources: [
              for (final src in list(s['sources']))
                SchemeSource(
                  src['title'] as String,
                  src['url'] as String,
                  official: src['official'] as bool,
                ),
            ],
          ),
      ],
    );
  }
}
