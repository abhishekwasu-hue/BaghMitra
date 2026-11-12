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
        if (gen.sourceKeys(e).any(gen.isCibrc)) e,
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
    'growth regulators are exactly what our KB cards name (owner '
    '2026-11-11: no registration needed), each citing its cards\' sources',
    () {
      final fromKb = gen.kbEntries(File(gen.knowledgePath).readAsStringSync());
      final inAsset = [
        for (final e in _entries())
          if (gen.isFromKb(e)) e,
      ];
      expect(jsonDecode(jsonEncode(inAsset)), jsonDecode(jsonEncode(fromKb)));
      expect(inAsset.map((e) => e['name']), [
        '2,4-D',
        'Chlormequat chloride',
        'Gibberellic acid',
        'Paclobutrazol',
      ]);
      expect(inAsset.every((e) => e['type'] == 'pgr'), isTrue);
      final ga = inAsset.singleWhere((e) => e['name'] == 'Gibberellic acid');
      expect(ga['kb_cards'], ['bahar_ambia (santra)', 'fruit_drop (santra)']);
      expect(ga['sources'], contains('pau_fruit_drop'));
      // A name no card gives stops the generator instead of being typed in.
      expect(
        () => gen.kbEntries(jsonEncode({'cards': <Object>[]})),
        throwsStateError,
      );
    },
  );

  test('micronutrient and water-soluble rows are exactly the FCO 1985 '
      'Schedule I extract, each citing the FCO source', () {
    final extract = File(gen.fcoPath).readAsStringSync();
    final fromExtract = gen.fcoEntries(extract);
    final inAsset = [
      for (final e in _entries())
        if (gen.sourceKeys(e).any(gen.isFco)) e,
    ];
    expect(
      jsonDecode(jsonEncode(inAsset)),
      jsonDecode(jsonEncode(fromExtract)),
    );
    // Every row of the extract has the FCO source and is in its printed heading.
    final rows = ((jsonDecode(extract) as Map)['entries'] as List)
        .cast<Map<String, dynamic>>();
    String bare(String s) => s.replaceAll(RegExp(r'\s+'), '');
    for (final r in rows) {
      expect(r['source'], 'fco_1985_odisha_2009', reason: r['name'] as String);
      expect(
        bare(r['printed'] as String),
        contains(bare(r['name'] as String)),
        reason: r['name'] as String,
      );
      expect(r['schedule_ref'], startsWith('Schedule I, Part A, 1('));
    }
    final kbSources =
        ((jsonDecode(File(gen.sourcesPath).readAsStringSync())
                    as Map)['sources']
                as List)
            .cast<Map<String, dynamic>>();
    final fco = kbSources.singleWhere(
      (s) => s['key'] == 'fco_1985_odisha_2009',
    );
    expect(
      fco['url'],
      'https://odishaagrilicense.nic.in/actsRules/Fertiliser_Control_Order_1985.pdf',
    );
    // Only the two nutrition types come from the FCO; the hand-kept KB card rows they
    // replace (same compounds) are gone.
    expect(inAsset.map((e) => e['type']).toSet(), {
      'micronutrient',
      'water_soluble',
    });
    expect(
      _entries().where(
        (e) =>
            gen.sourceKeys(e).contains('ccri_monthly_november') &&
            !gen.isFromKb(e),
      ),
      isEmpty,
    );
    expect(
      [
        for (final e in inAsset)
          if (e['type'] == 'water_soluble') e['name'],
      ],
      [
        'Calcium Nitrate',
        'Mono Ammonium Phosphate 12:61:0 (100% water soluble)',
        'Mono – Potasium Phosphate (0-52-34) (100% water Soluble)',
        'NPK 13:40:13 (100% water soluble)',
        'NPK 13:5:26 (100% water soluble)',
        'NPK 18:18:18 (100% water soluble)',
        'NPK 19:19:19 (100% water soluble)',
        'NPK 20:20:20 (100% water soluble)',
        'NPK 6:12:36 (100% water soluble)',
        'Potassium Magnesium Sulphate',
        'Pottasium Nitrate (13-0-45)',
      ],
    );
    // A row with another type, another source or a name not in its heading stops the
    // generator instead of being listed.
    Map<String, Object?> row(String type, String source, String printed) => {
      'entries': [
        {
          'type': type,
          'name': 'Calcium Nitrate',
          'printed': printed,
          'schedule_ref': 'Schedule I, Part A, 1(h), 4',
          'source': source,
        },
      ],
    };
    for (final bad in [
      row('fungicide', 'fco_1985_odisha_2009', '4. Calcium Nitrate'),
      row('water_soluble', 'ccri_monthly_november', '4. Calcium Nitrate'),
      row('water_soluble', 'fco_1985_odisha_2009', '4. Calcium Ammonium'),
    ]) {
      expect(() => gen.fcoEntries(jsonEncode(bad)), throwsStateError);
    }
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
        'pgr': 4,
        'micronutrient': 13,
        'water_soluble': 11,
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
      final keys = gen.sourceKeys(e);
      expect(keys, isNotEmpty, reason: e['name'] as String);
      for (final key in keys) {
        final s = sources[key] as Map<String, dynamic>?;
        expect(s, isNotNull, reason: '${e['name']}: $key');
        expect((s!['url'] as String).startsWith('https://'), isTrue);
        final kbRow = kbSources.where((k) => k['key'] == key).single;
        expect(s['url'], kbRow['url']);
        expect(s['title'], kbRow['title']);
      }
      if (!keys.any((k) => gen.isCibrc(k) || gen.isFco(k)) &&
          !gen.isFromKb(e)) {
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
    expect(
      data.match('NPK 19:19:19 (100% water soluble)')!.display,
      'NPK 19:19:19 (100% water soluble)',
    );
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
