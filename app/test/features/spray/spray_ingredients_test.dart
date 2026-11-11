import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/features/spray/data/spray_ingredients.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/gen_spray_ingredients.dart' as gen;

Map<String, dynamic> _asset() =>
    jsonDecode(File(SprayIngredientsConfig.asset).readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _entries() =>
    (_asset()['entries'] as List).cast<Map<String, dynamic>>();

void main() {
  test('the CIB&RC rows are exactly what the API seeds (regenerate with '
      'dart run tool/gen_spray_ingredients.dart)', () {
    final csv = File(gen.csvPath).readAsStringSync();
    final fromCsv = gen.cibrcEntries(csv);
    final inAsset = [
      for (final e in _entries())
        if (gen.isCibrc(e['source'] as String)) e,
    ];
    expect(jsonDecode(jsonEncode(inAsset)), jsonDecode(jsonEncode(fromCsv)));
    // Every active ingredient in the CSV is offered once.
    final ais = {
      for (final r in gen.parseCsv(csv).skip(1)) r[5].trim().toLowerCase(),
    };
    expect(
      inAsset.map((e) => (e['name'] as String).toLowerCase()).toSet(),
      ais,
    );
    expect(ais, hasLength(24));
  });

  test(
    'types come from the data; no acaricide type while no book marks one',
    () {
      final data = SprayIngredients.parse(_asset());
      final counts = {
        for (final t in data.types) t.key: data.ofType(t.key).length,
      };
      expect(counts, {
        'fungicide': 12,
        'insecticide': 9,
        'herbicide': 2,
        'bio': 1,
        'pgr': 0,
        'micronutrient': 4,
        'water_soluble': 0,
        'tonic': 0,
      });
      for (final t in data.types) {
        expect(t.labels.keys.toSet(), {'en', 'mr', 'hi'}, reason: t.key);
      }
      expect(data.types.first.label('mr'), 'बुरशीनाशक');
      expect(gen.typeFor('cibrc_fungicides_2026_09', 'chemical'), 'fungicide');
      expect(gen.typeFor('cibrc_bio_insecticides_2026_09', 'bio'), 'bio');
      expect(
        () => gen.typeFor('cibrc_acaricides_2027_03', 'chemical'),
        throwsStateError,
      );
    },
  );

  test('every entry cites a source; hand-kept rows quote the words they '
      'were read from', () {
    final asset = _asset();
    final sources = (asset['sources'] as Map).cast<String, Object?>();
    final kb = File('../api/src/bagmitra_api/kb/seed_data/knowledge.json')
        .readAsStringSync();
    final kbSources =
        ((jsonDecode(File(gen.sourcesPath).readAsStringSync())
                    as Map)['sources']
                as List)
            .cast<Map<String, dynamic>>();
    for (final e in _entries()) {
      final key = e['source'] as String;
      final s = sources[key] as Map<String, dynamic>?;
      expect(s, isNotNull, reason: e['name'] as String);
      expect((s!['url'] as String).startsWith('https://'), isTrue);
      final kbRow = kbSources.where((k) => k['key'] == key).single;
      expect(s['url'], kbRow['url']);
      expect(s['title'], kbRow['title']);
      if (!gen.isCibrc(key)) {
        final quote = e['quote'] as String;
        expect(kb, contains(quote), reason: e['name'] as String);
        final first = (e['name'] as String).split(' ').first.toLowerCase();
        expect(
          quote.toLowerCase(),
          contains(first),
          reason: e['name'] as String,
        );
      }
    }
  });

  test('the list is sorted and shows the formulation beside the name', () {
    final data = SprayIngredients.parse(_asset());
    final names = data.ofType('fungicide').map((e) => e.name).toList();
    expect(
      names,
      [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
    );
    expect(data.match('captan')!.display, 'Captan 75% WP');
    expect(
      data.match('Streptomycin Sulphate + Tetracycline Hydrochloride')!.display,
      'Streptomycin Sulphate + Tetracycline Hydrochloride '
      '90% + 10% SP, 9% + 1% SP',
    );
    expect(data.match('Borax')!.display, 'Borax');
  });

  test('a filled-in value matches by name or name with formulation', () {
    final data = SprayIngredients.parse(_asset());
    expect(data.match('  CAPTAN  ')!.name, 'Captan');
    expect(data.match('Captan 75% WP')!.name, 'Captan');
    expect(data.match('imidacloprid 17.80% sl')!.type, 'insecticide');
    expect(data.match('Kelthane'), isNull);
    expect(data.match(''), isNull);
  });

  test('the CSV reader keeps quoted commas and doubled quotes', () {
    expect(gen.parseCsv('a,"b, c","say ""hi"""\n1,2,3\n'), [
      ['a', 'b, c', 'say "hi"'],
      ['1', '2', '3'],
    ]);
  });
}
