import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where an export fact was read: a title, the publisher and, when the research gives one,
/// the page.
class ExportSource {
  const ExportSource({required this.title, this.publisher, this.url});

  final String title;
  final String? publisher;
  final String? url;
}

/// One sourced line of export information (spec v1.5 §4A): what it says per language, the
/// key of its [ExportSource] and the day the source was read.
class ExportFact {
  const ExportFact({
    required this.id,
    required this.section,
    required this.text,
    required this.source,
    required this.read,
  });

  final String id;

  /// destinations | season | specs | rules
  final String section;
  final Map<String, String> text;
  final String source;
  final DateTime read;

  String textIn(String lang) => text[lang] ?? text['en'] ?? id;
}

/// An official page the grower opens in the browser (no data from it is stored).
class ExportLink {
  const ExportLink({
    required this.id,
    required this.label,
    required this.url,
    required this.checked,
  });

  final String id;
  final Map<String, String> label;
  final String url;
  final DateTime checked;

  String labelIn(String lang) => label[lang] ?? label['en'] ?? id;
}

class ExportInfo {
  const ExportInfo({
    required this.sources,
    required this.sections,
    required this.crops,
    required this.rules,
    required this.links,
  });

  final Map<String, ExportSource> sources;

  /// Section keys in the order the page shows them.
  final List<String> sections;

  /// Crop slug → its own facts; [rules] apply to every listed crop (citrus).
  final Map<String, List<ExportFact>> crops;
  final List<ExportFact> rules;
  final List<ExportLink> links;

  /// Every fact of [crop] in one section, the shared rules last.
  List<ExportFact> factsFor(String crop, String section) => [
    for (final f in [...?crops[crop], ...rules])
      if (f.section == section) f,
  ];
}

/// Export information from a config asset, so a reviewer corrects a line without a release.
class ExportInfoConfig {
  ExportInfoConfig({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/export_info.json';

  final AssetBundle _bundle;

  Future<ExportInfo> load() async {
    final json =
        jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>;
    Map<String, String> strings(Object? m) =>
        (m as Map? ?? const {}).cast<String, String>();
    List<ExportFact> facts(Object? list) => [
      for (final f in (list as List<dynamic>).cast<Map<String, dynamic>>())
        ExportFact(
          id: f['id'] as String,
          section: f['section'] as String,
          text: strings(f['text']),
          source: f['source'] as String,
          read: DateTime.parse(f['read'] as String),
        ),
    ];
    return ExportInfo(
      sources: {
        for (final MapEntry(:key, :value)
            in (json['sources'] as Map<String, dynamic>).entries)
          key: ExportSource(
            title: (value as Map)['title'] as String,
            publisher: value['publisher'] as String?,
            url: value['url'] as String?,
          ),
      },
      sections: (json['sections'] as List<dynamic>).cast<String>(),
      crops: {
        for (final MapEntry(:key, :value)
            in (json['crops'] as Map<String, dynamic>).entries)
          key: facts(value),
      },
      rules: facts(json['rules']),
      links: [
        for (final l
            in (json['links'] as List<dynamic>).cast<Map<String, dynamic>>())
          ExportLink(
            id: l['id'] as String,
            label: strings(l['label']),
            url: l['url'] as String,
            checked: DateTime.parse(l['checked'] as String),
          ),
      ],
    );
  }
}

final exportInfoConfigProvider = Provider<ExportInfoConfig>(
  (ref) => ExportInfoConfig(),
);

final exportInfoProvider = FutureProvider<ExportInfo>(
  (ref) => ref.watch(exportInfoConfigProvider).load(),
);
