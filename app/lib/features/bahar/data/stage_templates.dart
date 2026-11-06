import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../api/generated/bagmitra.swagger.dart' as api;
import '../../../data/local/database.dart';
import 'bahar_catalog.dart';

/// Where one stage window comes from (owner decision Q57: general information from public
/// sources, shown with the source and the date it was read).
class TemplateSource {
  const TemplateSource({
    required this.name,
    required this.title,
    required this.url,
    required this.read,
  });

  /// Parses the API's `sources` value: "name | title | url | read YYYY-MM-DD".
  static TemplateSource? fromLine(String line) {
    final parts = line.split(' | ');
    if (parts.length != 4 || !parts[3].startsWith('read ')) return null;
    return TemplateSource(
      name: parts[0],
      title: parts[1],
      url: parts[2],
      read: DateTime.tryParse(parts[3].substring(5)),
    );
  }

  final String name;
  final String title;
  final String url;
  final DateTime? read;
}

/// One stage of a template: a day range after an earlier stage, or (anchor `season_start`) a
/// day range in a 365-day reference year starting 1 January of the season year.
class TemplateStage {
  const TemplateStage({
    required this.key,
    required this.labels,
    required this.anchor,
    required this.min,
    required this.max,
    required this.sourceIds,
  });

  static const seasonStart = 'season_start';

  final String key;
  final Map<String, String> labels;
  final String anchor;
  final int min;
  final int max;
  final List<String> sourceIds;
}

class StageTemplate {
  const StageTemplate({
    required this.crop,
    required this.bahar,
    required this.version,
    required this.stages,
    required this.sources,
  });

  final String crop;
  final String bahar;
  final int version;
  final List<TemplateStage> stages;
  final Map<String, TemplateSource> sources;

  TemplateStage? stage(String key) =>
      stages.where((s) => s.key == key).firstOrNull;

  /// The grower's stages plus any template stage they lack (e.g. the stress end), placed right
  /// after the stage it counts from.
  List<LabeledOption> withStages(List<LabeledOption> manual) {
    final out = [...manual];
    for (final s in stages) {
      if (out.any((o) => o.key == s.key)) continue;
      final at = out.indexWhere((o) => o.key == s.anchor);
      out.insert(at < 0 ? out.length : at + 1, LabeledOption(s.key, s.labels));
    }
    return out;
  }

  /// The sources one stage names, in order.
  List<TemplateSource> sourcesFor(String stageKey) => [
    for (final id in stage(stageKey)?.sourceIds ?? const <String>[])
      ?sources[id],
  ];

  /// Every source the template uses, by name, without duplicates.
  List<String> sourceNames() => {
    for (final s in stages)
      for (final id in s.sourceIds)
        if (sources[id] case final src?) src.name,
  }.toList();

  /// When the sources were read (the latest date, if they differ).
  DateTime? checked() {
    DateTime? latest;
    for (final id in {for (final s in stages) ...s.sourceIds}) {
      final r = sources[id]?.read;
      if (r != null && (latest == null || r.isAfter(latest))) latest = r;
    }
    return latest;
  }

  /// The suggested window of every stage that has one. A chained stage counts from the date the
  /// grower entered for its anchor stage, or else from its anchor's own window.
  Map<String, StageWindow> windows(
    int seasonYear, [
    Map<String, DateTime> dates = const {},
  ]) {
    final out = <String, StageWindow>{};
    for (final s in stages) {
      if (s.anchor == TemplateStage.seasonStart) {
        out[s.key] = StageWindow(
          referenceDay(seasonYear, s.min),
          referenceDay(seasonYear, s.max),
        );
        continue;
      }
      final entered = dates[s.anchor];
      final base = out[s.anchor];
      if (entered != null) {
        out[s.key] = StageWindow(
          _addDays(entered, s.min),
          _addDays(entered, s.max),
        );
      } else if (base != null) {
        out[s.key] = StageWindow(
          _addDays(base.from, s.min),
          _addDays(base.to, s.max),
        );
      }
    }
    return out;
  }

  /// The grower's dates plus the start of each window for the stages still without a date, in
  /// stage order, so a chained stage follows the dates filled before it.
  Map<String, DateTime> fillSuggested(
    int seasonYear,
    Map<String, DateTime> dates,
  ) {
    final filled = Map.of(dates);
    for (final s in stages) {
      if (filled.containsKey(s.key)) continue;
      final w = windows(seasonYear, filled)[s.key];
      if (w != null) filled[s.key] = w.from;
    }
    return filled;
  }
}

class StageWindow {
  const StageWindow(this.from, this.to);

  final DateTime from;
  final DateTime to;
}

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

const _monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

/// Day [offset] of a 365-day reference year (no 29 February) that starts on 1 January of
/// [seasonYear]; 365 is 1 January of the next year, -1 is 31 December of the year before.
DateTime referenceDay(int seasonYear, int offset) {
  final shift = (offset / 365).floor();
  var day = offset - shift * 365;
  var month = 0;
  while (day >= _monthDays[month]) {
    day -= _monthDays[month];
    month++;
  }
  return DateTime(seasonYear + shift, month + 1, day + 1);
}

/// Templates by `crop/bahar`.
typedef StageTemplateSet = Map<String, StageTemplate>;

String templateKey(String crop, String bahar) => '$crop/$bahar';

/// The bundled templates (the same file the API seeds from), and the published copy from the
/// API cached on the phone. The cached copy wins where it has the template; refreshing is best
/// effort and a failure keeps what is cached.
class StageTemplatesStore {
  StageTemplatesStore(this._db, {required this._api, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/config/stage_templates.json';
  static const metaKey = 'reference.stage_templates';

  final AppDatabase _db;
  final api.Bagmitra _api;
  final AssetBundle _bundle;

  Future<StageTemplateSet> load() async {
    final bundled = parseBundled(
      jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>,
    );
    final raw = await _db.readMeta(metaKey);
    if (raw == null) return bundled;
    final cached = parseCached(jsonDecode(raw) as List<dynamic>);
    return {...bundled, ...cached};
  }

  /// Returns true when a fresh list was stored.
  Future<bool> refresh() async {
    try {
      final res = await _api.v1ReferenceStageTemplatesGet();
      final body = res.body;
      if (!res.isSuccessful || body == null) return false;
      final rows = [
        for (final t in body.templates)
          {
            'crop': t.crop,
            'bahar': t.bahar,
            'version': t.version,
            'stages': [
              for (final s in t.stages)
                {
                  'key': s.key,
                  'labels': s.labels,
                  'anchor': s.anchor,
                  'offset_days_min': s.offsetDaysMin,
                  'offset_days_max': s.offsetDaysMax,
                  'source_ids': s.sourceIds,
                },
            ],
            'sources': {for (final e in t.sources.entries) e.key: '${e.value}'},
          },
      ];
      await _db.writeMeta(metaKey, jsonEncode(rows));
      return true;
    } on Exception {
      return false;
    }
  }

  static TemplateStage _stage(Map<String, dynamic> s) => TemplateStage(
    key: s['key'] as String,
    labels: ((s['labels'] as Map?) ?? const {}).cast<String, String>(),
    anchor: s['anchor'] as String,
    min: s['offset_days_min'] as int,
    max: s['offset_days_max'] as int,
    sourceIds: (s['source_ids'] as List).cast<String>(),
  );

  static List<TemplateStage> _stages(Object? list) => [
    for (final s in (list as List).cast<Map<String, dynamic>>()) _stage(s),
  ];

  static StageTemplateSet parseBundled(Map<String, dynamic> json) {
    final sources = {
      for (final e in (json['sources'] as Map<String, dynamic>).entries)
        e.key: TemplateSource(
          name: (e.value as Map)['name'] as String,
          title: (e.value as Map)['title'] as String,
          url: (e.value as Map)['url'] as String,
          read: DateTime.tryParse((e.value as Map)['read'] as String),
        ),
    };
    return {
      for (final t in (json['templates'] as List).cast<Map<String, dynamic>>())
        if (t['status'] == 'published')
          templateKey(t['crop'] as String, t['bahar'] as String): StageTemplate(
            crop: t['crop'] as String,
            bahar: t['bahar'] as String,
            version: t['version'] as int,
            stages: _stages(t['stages']),
            sources: sources,
          ),
    };
  }

  static StageTemplateSet parseCached(List<dynamic> rows) => {
    for (final t in rows.cast<Map<String, dynamic>>())
      templateKey(t['crop'] as String, t['bahar'] as String): StageTemplate(
        crop: t['crop'] as String,
        bahar: t['bahar'] as String,
        version: t['version'] as int,
        stages: _stages(t['stages']),
        sources: {
          for (final e in (t['sources'] as Map<String, dynamic>).entries)
            e.key: ?TemplateSource.fromLine(e.value as String),
        },
      ),
  };
}
