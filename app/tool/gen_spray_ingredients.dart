// Regenerates the generated parts of assets/config/spray_ingredients.json:
// - CIB&RC rows from the label claims the API seeds
//   (api/src/bagmitra_api/kb/seed_data/label_claims_citrus.csv);
// - growth regulators from the KB cards' chemical_options
//   (api/src/bagmitra_api/kb/seed_data/knowledge.json);
// - micronutrient and water-soluble fertiliser grades from the Fertiliser (Control) Order 1985
//   Schedule I extract (api/src/bagmitra_api/kb/seed_data/fco_schedule1_grades.json).
// Rows with any other source are kept as they are, unless an FCO row names the same compound
// (see [fcoReplaces]). Run from app/:
//   dart run tool/gen_spray_ingredients.dart
// test/features/spray/spray_ingredients_test.dart fails when the asset and the data differ.
import 'dart:convert';
import 'dart:io';

const csvPath = '../api/src/bagmitra_api/kb/seed_data/label_claims_citrus.csv';
const sourcesPath = '../api/src/bagmitra_api/kb/seed_data/sources.json';
const knowledgePath = '../api/src/bagmitra_api/kb/seed_data/knowledge.json';
const fcoPath =
    '../api/src/bagmitra_api/kb/seed_data/fco_schedule1_grades.json';
const assetPath = 'assets/config/spray_ingredients.json';

/// The picker type a CIB&RC row belongs to: `bio` when the row's category is bio, else the
/// book its source key names (`cibrc_<book>_<yyyy>_<mm>`). A book with no type here stops the
/// generator, so a new book needs a decision instead of a silent guess.
const bookTypes = {
  'fungicides': 'fungicide',
  'insecticides': 'insecticide',
  'herbicides': 'herbicide',
  'pgr': 'pgr',
};

final _sourceKey = RegExp(r'^cibrc_([a-z_]+?)_\d{4}_\d{2}$');

bool isCibrc(String sourceKey) => _sourceKey.hasMatch(sourceKey);

String typeFor(String sourceKey, String category) {
  if (category == 'bio') return 'bio';
  final book = _sourceKey.firstMatch(sourceKey)?.group(1);
  final type = bookTypes[book];
  if (type == null) {
    throw StateError('No picker type for source "$sourceKey"');
  }
  return type;
}

/// RFC 4180 CSV: quoted fields may hold commas, doubled quotes and newlines.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      row.add(field.toString());
      field.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.any((f) => f.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    if (row.any((f) => f.isNotEmpty)) rows.add(row);
  }
  return rows;
}

int _byName(Map<String, Object?> a, Map<String, Object?> b) {
  final c = (a['name']! as String).toLowerCase().compareTo(
    (b['name']! as String).toLowerCase(),
  );
  return c != 0 ? c : (a['type']! as String).compareTo(b['type']! as String);
}

/// One entry per (type, active ingredient), with every printed formulation and the source
/// pages, sorted by name.
List<Map<String, Object?>> cibrcEntries(String csv) {
  final rows = parseCsv(csv);
  final header = rows.first;
  int col(String name) {
    final i = header.indexOf(name);
    if (i < 0) throw StateError('CSV has no "$name" column');
    return i;
  }

  final source = col('source_key');
  final ai = col('active_ingredient');
  final formulation = col('formulation');
  final category = col('category');
  final page = col('page_ref');
  final byKey = <String, Map<String, Object?>>{};
  for (final r in rows.skip(1)) {
    final type = typeFor(r[source], r[category]);
    final name = r[ai].trim();
    final e = byKey.putIfAbsent(
      '$type|${name.toLowerCase()}',
      () => {
        'type': type,
        'name': name,
        'formulations': <String>[],
        'source': r[source],
        'pages': <String>[],
      },
    );
    if (e['source'] != r[source]) {
      throw StateError('"$name" comes from two sources');
    }
    final f = r[formulation].trim();
    final forms = e['formulations']! as List<String>;
    if (f.isNotEmpty && !forms.contains(f)) forms.add(f);
    final pages = e['pages']! as List<String>;
    final p = r[page].trim();
    if (p.isNotEmpty && !pages.contains(p)) pages.add(p);
  }
  return byKey.values.toList()..sort(_byName);
}

/// Growth regulators the picker lists from our own KB cards' `chemical_options` (owner
/// 2026-11-11: "वाढ नियंत्रक हे शासन मान्य असले पाहिजे असे नाही", so a CIB&RC registration
/// is not required). Each name must appear on at least one card, or the generator stops.
const kbGrowthRegulators = [
  'chlormequat chloride',
  'gibberellic acid',
  'paclobutrazol',
  '2,4-D',
];

bool isFromKb(Map<String, Object?> entry) => entry.containsKey('kb_cards');

String _sentenceCase(String s) => s.isEmpty || !RegExp('[a-z]').hasMatch(s[0])
    ? s
    : '${s[0].toUpperCase()}${s.substring(1)}';

/// One `pgr` entry per growth regulator, citing every card that names it: the cards'
/// own source keys, the card topics and the uses the cards give.
List<Map<String, Object?>> kbEntries(String knowledgeJson) {
  final cards = ((jsonDecode(knowledgeJson) as Map)['cards'] as List)
      .cast<Map<String, Object?>>();
  final out = <Map<String, Object?>>[];
  for (final ai in kbGrowthRegulators) {
    final sources = <String>[];
    final topics = <String>[];
    final uses = <String>[];
    for (final c in cards) {
      final options = ((c['chemical_options'] as List?) ?? const [])
          .cast<Map<String, Object?>>();
      final hits = options.where(
        (o) =>
            (o['active_ingredient']! as String).trim().toLowerCase() ==
            ai.toLowerCase(),
      );
      if (hits.isEmpty) continue;
      final topic = '${c['topic']} (${c['crop']})';
      if (!topics.contains(topic)) topics.add(topic);
      for (final h in hits) {
        final use = (h['target']! as String).trim();
        if (use.isNotEmpty && !uses.contains(use)) uses.add(use);
      }
      for (final s
          in ((c['sources'] as List?) ?? const [])
              .cast<Map<String, Object?>>()) {
        final key = s['source']! as String;
        if (!sources.contains(key)) sources.add(key);
      }
    }
    if (topics.isEmpty) {
      throw StateError('No KB card names the growth regulator "$ai"');
    }
    out.add({
      'type': 'pgr',
      'name': _sentenceCase(ai),
      'sources': sources,
      'kb_cards': topics,
      'uses': uses,
    });
  }
  return out..sort(_byName);
}

/// FCO extract rows carry a source key `fco_...`.
bool isFco(String sourceKey) => sourceKey.startsWith('fco_');

/// The picker types the FCO extract may fill; any other type stops the generator.
const fcoTypes = {'micronutrient', 'water_soluble'};

/// Hand-kept rows an FCO grade replaces (the same compound, read from a KB card before the FCO
/// text was reachable). A name kept by hand that is not listed here stays.
const fcoReplaces = {
  'zinc sulphate',
  'ferrous sulphate',
  'manganese sulphate',
  'borax',
};

/// The notes the FCO-filled types carry in the asset.
const fcoTypeNotes = {
  'micronutrient':
      'Fertiliser (Control) Order 1985, Schedule I Part A 1(f) MICRONUTRIENTS, from '
      'kb/seed_data/fco_schedule1_grades.json (tool/gen_spray_ingredients.dart).',
  'water_soluble':
      'Fertiliser (Control) Order 1985, Schedule I Part A 1(h) 100% water soluble complex '
      'fertilisers, from kb/seed_data/fco_schedule1_grades.json '
      '(tool/gen_spray_ingredients.dart).',
};

/// The text of a name or printed heading with every space removed (PDF text layers split
/// formulas: "CuSO 4.5H2O").
String _bare(String s) => s.replaceAll(RegExp(r'\s+'), '');

/// One entry per FCO Schedule I grade, as the extract names it, with its schedule serial.
List<Map<String, Object?>> fcoEntries(String extractJson) {
  final rows = ((jsonDecode(extractJson) as Map)['entries'] as List)
      .cast<Map<String, Object?>>();
  final out = <Map<String, Object?>>[];
  for (final r in rows) {
    final type = r['type']! as String;
    final name = (r['name']! as String).trim();
    final source = r['source']! as String;
    if (!fcoTypes.contains(type)) {
      throw StateError('FCO row "$name" has the type "$type"');
    }
    if (!isFco(source)) {
      throw StateError('FCO row "$name" cites "$source"');
    }
    if (!_bare(r['printed']! as String).contains(_bare(name))) {
      throw StateError('FCO row "$name" is not in its printed heading');
    }
    out.add({
      'type': type,
      'name': name,
      'source': source,
      'schedule_ref': r['schedule_ref']! as String,
    });
  }
  return out..sort(_byName);
}

/// Every source key an entry cites.
List<String> sourceKeys(Map<String, Object?> entry) => [
  if (entry['source'] case final String s) s,
  ...((entry['sources'] as List?) ?? const []).cast<String>(),
];

/// The KB source rows the generated entries cite (title, publisher, URL).
Map<String, Object?> sourceRows(
  List<Map<String, Object?>> entries,
  String sourcesJson,
) {
  final raw = jsonDecode(sourcesJson);
  final list = (raw is Map ? raw['sources'] : raw) as List<Object?>;
  final byKey = {
    for (final s in list.cast<Map<String, Object?>>()) s['key']! as String: s,
  };
  final keys = {for (final e in entries) ...sourceKeys(e)}.toList()..sort();
  return {
    for (final key in keys)
      key: {
        'title': byKey[key]!['title'],
        'publisher': byKey[key]!['publisher'],
        'url': byKey[key]!['url'],
      },
  };
}

void main() {
  final asset =
      jsonDecode(File(assetPath).readAsStringSync()) as Map<String, Object?>;
  final generated = [
    ...cibrcEntries(File(csvPath).readAsStringSync()),
    ...kbEntries(File(knowledgePath).readAsStringSync()),
    ...fcoEntries(File(fcoPath).readAsStringSync()),
  ];
  final kept = [
    for (final e
        in (asset['entries']! as List<Object?>).cast<Map<String, Object?>>())
      if (!isFromKb(e) &&
          !sourceKeys(e).any((k) => isCibrc(k) || isFco(k)) &&
          !fcoReplaces.contains((e['name']! as String).toLowerCase()))
        e,
  ];
  for (final t
      in (asset['types']! as List<Object?>).cast<Map<String, Object?>>()) {
    if (fcoTypeNotes[t['key']] case final String note) t['note'] = note;
  }
  final oldSources = asset['sources']! as Map<String, Object?>;
  final keptKeys = {for (final e in kept) ...sourceKeys(e)};
  asset['sources'] = {
    ...sourceRows(generated, File(sourcesPath).readAsStringSync()),
    for (final k in keptKeys) k: oldSources[k],
  };
  asset['entries'] = [...generated, ...kept]..sort(_byName);
  File(
    assetPath,
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(asset)}\n');
  stdout.writeln('${generated.length} generated entries, ${kept.length} kept');
}
