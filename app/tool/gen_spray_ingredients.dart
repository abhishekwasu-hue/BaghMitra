// Regenerates the CIB&RC part of assets/config/spray_ingredients.json from the label claims
// the API seeds (api/src/bagmitra_api/kb/seed_data/label_claims_citrus.csv). Rows with any
// other source (the nutrition rows) are kept as they are. Run from app/:
//   dart run tool/gen_spray_ingredients.dart
// test/features/spray/spray_ingredients_test.dart fails when the asset and the CSV differ.
import 'dart:convert';
import 'dart:io';

const csvPath = '../api/src/bagmitra_api/kb/seed_data/label_claims_citrus.csv';
const sourcesPath = '../api/src/bagmitra_api/kb/seed_data/sources.json';
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

/// The KB source rows the CIB&RC entries cite (title, URL, edition note).
Map<String, Object?> cibrcSources(
  List<Map<String, Object?>> entries,
  String sourcesJson,
) {
  final raw = jsonDecode(sourcesJson);
  final list = (raw is Map ? raw['sources'] : raw) as List<Object?>;
  final byKey = {
    for (final s in list.cast<Map<String, Object?>>()) s['key']! as String: s,
  };
  return {
    for (final key in {
      for (final e in entries) e['source']! as String,
    }.toList()..sort())
      key: {
        'title': byKey[key]!['title'],
        'publisher': byKey[key]!['publisher'],
        'url': byKey[key]!['url'],
      },
  };
}

void main() {
  final csv = File(csvPath).readAsStringSync();
  final asset =
      jsonDecode(File(assetPath).readAsStringSync()) as Map<String, Object?>;
  final generated = cibrcEntries(csv);
  final kept = [
    for (final e
        in (asset['entries']! as List<Object?>).cast<Map<String, Object?>>())
      if (!isCibrc(e['source']! as String)) e,
  ];
  final keptSources = {
    for (final e in (asset['sources']! as Map<String, Object?>).entries)
      if (!isCibrc(e.key)) e.key: e.value,
  };
  asset['sources'] = {
    ...cibrcSources(generated, File(sourcesPath).readAsStringSync()),
    ...keptSources,
  };
  asset['entries'] = [...generated, ...kept]..sort(_byName);
  File(
    assetPath,
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(asset)}\n');
  stdout.writeln('${generated.length} CIB&RC entries, ${kept.length} kept');
}
