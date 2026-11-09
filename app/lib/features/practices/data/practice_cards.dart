import 'dart:convert';

import 'package:flutter/services.dart';

/// A published page a practice comes from.
class PracticeSource {
  const PracticeSource(this.title, this.url, {this.publisher, this.checked});

  final String title;
  final String url;

  /// A short publisher name for the "general information" mark, e.g. "NHB".
  final String? publisher;

  /// The day the source was read (yyyy-mm-dd), when known.
  final DateTime? checked;
}

/// One sourced text of a problem profile (what you see, when it comes, how to scout, ...).
class PracticePart {
  const PracticePart(this.labels, this.source, this.sourceKeys);

  final Map<String, String> labels;
  final String source;
  final List<String> sourceKeys;

  String label(String lang) => labels[lang] ?? labels['en'] ?? '';
}

/// One organic / bio option: a registered bio-agent or botanical named without a dose
/// (`registered`: dose from the label), or a home-made preparation with the rate as published
/// (`home`, with [preparation] pointing to [PracticeCardsData.preparations]).
class PracticeBio {
  const PracticeBio({
    required this.id,
    required this.kind,
    required this.labels,
    required this.source,
    required this.sourceKeys,
    required this.evidence,
    this.preparation,
  });

  static const kinds = {'registered', 'home'};

  final String id;
  final String kind;
  final Map<String, String> labels;
  final String source;
  final List<String> sourceKeys;
  final List<String> evidence;
  final String? preparation;

  String label(String lang) => labels[lang] ?? labels['en'] ?? '';
}

/// What a problem section says beyond its practices (owner decision Q57: general information
/// from public sources, with source and date).
class PracticeProfile {
  const PracticeProfile({
    required this.kind,
    required this.crops,
    required this.bio,
    this.checked,
    this.symptoms,
    this.when,
    this.scouting,
    this.actionLevel,
    this.labelTarget,
    this.kbTopic,
    this.figure,
  });

  static const kinds = {'pest', 'disease', 'disorder', 'crop', 'nutrition'};

  final String kind;
  final List<String> crops;
  final DateTime? checked;
  final PracticePart? symptoms;
  final PracticePart? when;
  final PracticePart? scouting;

  /// A published action level; null when none was found.
  final PracticePart? actionLevel;
  final List<PracticeBio> bio;

  /// The target the label screen ("label-approved products") opens with.
  final String? labelTarget;

  /// The knowledge card topic for the same problem, if there is one.
  final String? kbTopic;

  /// What the grower sees, as a labelled drawing; null when there is none.
  final PracticeFigure? figure;

  Iterable<String> get sourceKeys => [
    for (final p in [symptoms, when, scouting, actionLevel])
      if (p != null) ...p.sourceKeys,
    for (final b in bio) ...b.sourceKeys,
  ];
}

/// One non-chemical orchard practice, with where it comes from and how strong that source is.
/// A drawing the app makes for a practice or a symptom (owner 2026-11-09: show how the work
/// is done). [values] are the measures drawn on it, in the order the kind defines; each
/// one is stated in the practice text (tested).
enum PracticeFigureKind {
  gummosisTrunk,
  drainageTrench, // values: width cm, depth cm
  doubleRing,
  pruneCut, // values: healthy wood cm
  rootSun, // values: days from, days to
  barkStrip,
  twiceYearly,
}

class PracticeFigure {
  const PracticeFigure(this.kind, [this.values = const []]);

  static PracticeFigure? tryParse(Object? json) {
    if (json is! Map) return null;
    final kind = PracticeFigureKind.values.asNameMap()[json['kind']];
    if (kind == null) return null;
    return PracticeFigure(kind, [
      for (final v in (json['values'] as List?) ?? const []) v as int,
    ]);
  }

  final PracticeFigureKind kind;
  final List<int> values;
}

class PracticeItem {
  const PracticeItem({
    required this.id,
    required this.labels,
    required this.source,
    required this.sourceKeys,
    required this.evidence,
    this.figure,
  });

  /// How the work is done, as a drawing; null for most practices.
  final PracticeFigure? figure;

  final int id;
  final Map<String, String> labels;

  /// The reference inside the sources, e.g. "N1 §5.7.1".
  final String source;
  final List<String> sourceKeys;

  /// Any of [PracticeCardsData.evidenceKinds].
  final List<String> evidence;

  String label(String lang) => labels[lang] ?? labels['en'] ?? '';
}

class PracticeSection {
  const PracticeSection(this.key, this.labels, this.items, {this.profile});

  final String key;
  final Map<String, String> labels;
  final List<PracticeItem> items;
  final PracticeProfile? profile;

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;
}

class PracticeCardsData {
  const PracticeCardsData({
    required this.sources,
    required this.sections,
    required this.gaps,
    this.preparations = const {},
    this.isDraft = true,
  });

  static const evidenceKinds = {
    'official',
    'university',
    'research',
    'inferred',
  };

  final Map<String, PracticeSource> sources;
  final List<PracticeSection> sections;

  /// Problems with no non-chemical practice in the sources, per language.
  final List<Map<String, String>> gaps;

  /// Home-made preparations, exactly as published, by key.
  final Map<String, PracticePart> preparations;

  /// Kept for the reviewer; the screen does not show it (owner 2026-10-26, Q30).
  final bool isDraft;
}

/// Sourced practice cards from config, so a reviewer can correct them without a release.
class PracticeCardsConfig {
  PracticeCardsConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/practice_cards.json';
  final AssetBundle _bundle;

  Future<PracticeCardsData> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, String> strings(Object? m) =>
        (m as Map? ?? const {}).cast<String, String>();
    List<Map<String, dynamic>> list(Object? l) =>
        (l as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    List<String> keys(Object? l) =>
        (l as List<dynamic>? ?? const []).cast<String>();
    DateTime? day(Object? v) => v is String ? DateTime.tryParse(v) : null;
    PracticePart? part(Object? m) => m is Map<String, dynamic>
        ? PracticePart(
            strings(m['labels']),
            m['source'] as String,
            keys(m['source_keys']),
          )
        : null;
    PracticeProfile? profile(Object? m) => m is Map<String, dynamic>
        ? PracticeProfile(
            kind: m['kind'] as String,
            crops: keys(m['crops']),
            checked: day(m['checked']),
            symptoms: part(m['symptoms']),
            when: part(m['when']),
            scouting: part(m['scouting']),
            actionLevel: part(m['action_level']),
            labelTarget: m['label_target'] as String?,
            kbTopic: m['kb_topic'] as String?,
            figure: PracticeFigure.tryParse(m['figure']),
            bio: [
              for (final b in list(m['bio']))
                PracticeBio(
                  id: b['id'] as String,
                  kind: b['kind'] as String,
                  labels: strings(b['labels']),
                  source: b['source'] as String,
                  sourceKeys: keys(b['source_keys']),
                  evidence: keys(b['evidence']),
                  preparation: b['preparation'] as String?,
                ),
            ],
          )
        : null;
    final sources = (json['sources'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        k,
        PracticeSource(
          (v as Map<String, dynamic>)['title'] as String,
          v['url'] as String,
          publisher: v['publisher'] as String?,
          checked: day(v['checked']),
        ),
      ),
    );
    return PracticeCardsData(
      sources: sources,
      sections: [
        for (final s in list(json['sections']))
          PracticeSection(s['key'] as String, strings(s['labels']), [
            for (final i in list(s['items']))
              PracticeItem(
                id: i['id'] as int,
                labels: strings(i['labels']),
                source: i['source'] as String,
                sourceKeys: keys(i['source_keys']),
                evidence: keys(i['evidence']),
                figure: PracticeFigure.tryParse(i['figure']),
              ),
          ], profile: profile(s['profile'])),
      ],
      gaps: [for (final g in list(json['gaps'])) strings(g)],
      preparations: {
        for (final e
            in (json['preparations'] as Map<String, dynamic>? ??
                    const <String, dynamic>{})
                .entries)
          e.key: part(e.value)!,
      },
      isDraft: json['status'] != 'reviewed',
    );
  }
}
