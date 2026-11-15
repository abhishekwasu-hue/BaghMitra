// Offline questions and answers (owner 2026-11-12, Q144): the search keys equal the
// generator's (shared fixture), matching works across Marathi, Hindi, English and romanised
// text on a fixture, and the shipped asset loads with sources for every answer.
import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/features/ask/data/qa_kb.dart';
import 'package:bagmitra/features/ask/domain/qa_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart' show FileAssetBundle;

QaKb _fixture() => QaKb.fromJson(
  jsonDecode(File('test/fixtures/qa_search_fixture.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  test('words and keys equal the generator (shared fixture)', () {
    final cases = jsonDecode(
      File('test/fixtures/qa_normalise_cases.json').readAsStringSync(),
    ) as List<dynamic>;
    expect(cases.length, greaterThanOrEqualTo(20));
    for (final c in cases.cast<Map<String, dynamic>>()) {
      final text = c['text'] as String;
      expect(qaWords(text), c['words'], reason: text);
      expect(qaIndexKeys([text]), c['keys'], reason: text);
    }
  });

  test('sound keys join Devanagari and romanised spellings', () {
    expect(qaSkeleton('फळगळ'), qaSkeleton('falgal'));
    expect(qaSkeleton('phalgal'), 'plgl');
    expect(qaSkeleton('सायला'), qaSkeleton('saila'));
    expect(qaSkeleton('मोसंबी'), qaSkeleton('mosambi'));
    expect(qaSkeleton('फवारणी'), qaSkeleton('fawarani'));
  });

  group('matching quality on the fixture', () {
    final kb = _fixture();
    const cases = {
      'सायलाची लक्षणे': 'psylla-signs',
      'signs of psylla': 'psylla-signs',
      'सिल्ला के लक्षण': 'psylla-signs',
      'sayla sapale kiti lavayche': 'psylla-traps',
      'yellow sticky traps': 'psylla-traps',
      'santra falgal unhalyat': 'heat-drop',
      'गर्मी में फल गिर रहे हैं': 'heat-drop',
      'संत्र्याची फळगळ': 'heat-drop',
      'dinkya': 'gummosis',
      'खोडातून डिंक येतोय': 'gummosis',
      'mosambi var koli': 'mites',
      'ambiya bahar sathi tan': 'ambia-stress',
      'आंबिया ताण केव्हा': 'ambia-stress',
      'मृग बहार फुलोरा': 'mrig-flowering',
      'फवारणी नोंद': 'spray-record',
      'bill cha photo': 'bill-photo',
      'todni kiti divsani': 'phi',
      'canker kashamule': 'canker',
    };
    for (final MapEntry(key: query, value: id) in cases.entries) {
      test(query, () {
        final hits = kb.search(query);
        expect(hits, isNotEmpty);
        expect(hits.first.entry.id, id, reason: '$query: ${hits.first.score}');
        expect(hits.first.score, greaterThanOrEqualTo(qaAnswerScore));
      });
    }

    test('an unrelated question finds nothing close', () {
      final hits = kb.search('ट्रॅक्टर कर्ज योजना');
      expect(hits.where((h) => h.score >= qaCloseScore), isEmpty);
    });

    test('an empty or stopword-only question finds nothing', () {
      expect(kb.search(''), isEmpty);
      expect(kb.search('काय कसे आहे'), isEmpty);
    });

    test('same section gives related questions', () {
      final signs = kb.entries.firstWhere((e) => e.id == 'psylla-signs');
      expect(kb.sameSection(signs).map((e) => e.id), ['psylla-traps']);
    });
  });

  test('the long-ā key keeps "बाजरी" and "बाजार" apart', () {
    expect(qaSkeleton('बाजरी'), qaSkeleton('बाजार'));
    expect(qaLongASkeleton('बाजरी'), 'bAjr');
    expect(qaLongASkeleton('बाजार'), 'bAjAr');
    expect(qaLongASkeleton('संत्री'), 'sntr');
    expect(qaLongASkeleton('संत्रा'), 'sntrA');
    expect(qaLongASkeleton('मोसंबी'), qaLongASkeleton('मोसम्बी'));
  });

  group(
    'a different word with the same sound key is no match (2026-11-15)',
    () {
      late QaKb kb;
      setUpAll(
        () async => kb = await QaKbConfig(bundle: FileAssetBundle()).load(),
      );

      test('"बाजरी" (pearl millet) finds no market answer', () {
        // Before: "बाजरी" found every "बाजार" entry at 0.8 (same sound key "bjr") and the
        // owner's question was answered with the santra packing entry (0.46).
        expect(kb.search('बाजरी'), isEmpty);
        final hits = kb.search('बाजरी लागवडी संदर्भात सांगा');
        expect(
          hits.where((h) => h.entry.question('mr').contains('बाजार')),
          isEmpty,
        );
        expect(hits.first.score, lessThan(qaAnswerScore));
      });

      test('the market questions still find their answers', () {
        final packing = kb.search('संत्री बाजारात पॅकिंग').first;
        expect(packing.entry.question('mr'), contains('पॅकिंग'));
        expect(packing.score, greaterThanOrEqualTo(qaAnswerScore));
        for (final q in const [
          'बाजारभाव',
          'संत्र्याचा बाजारभाव',
          'bajarbhav',
        ]) {
          final best = kb.search(q).first;
          expect(best.entry.question('mr'), contains('बाजार'), reason: q);
          expect(best.score, greaterThanOrEqualTo(qaAnswerScore), reason: q);
        }
      });

      test('spelling variants and case endings still match', () {
        for (final MapEntry(key: q, value: word) in const {
          'सिलाची लक्षणे': 'सायला',
          'सायल्ला नियंत्रण': 'सायला',
          'psylla': 'सायला',
          'मोसम्बी वर कोळी': 'कोळी',
          'संत्र्याच्या फळगळीसाठी काय करावे': 'फळगळ',
          'कॅन्कर रोग': 'कँकर',
        }.entries) {
          final best = kb.search(q).first;
          expect(best.entry.question('mr'), contains(word), reason: q);
          expect(best.score, greaterThanOrEqualTo(qaAnswerScore), reason: q);
        }
      });
    },
  );

  test('the seed fixture finds the farmer\'s own words', () async {
    final kb = await QaKbConfig(
      bundle: FileAssetBundle(),
      path: 'test/fixtures/qa_kb_seed.json.gz',
    ).load();
    expect(kb.kind, 'seed');
    expect(
      kb.search('सायलाची लक्षणे काय?').first.entry.id,
      'seed-psylla-symptoms',
    );
    expect(kb.search('sayla').first.entry.section, 'psylla');
  });

  test(
    'the shipped asset loads with sources, 3 languages and the seed',
    () async {
      final kb = await QaKbConfig(bundle: FileAssetBundle()).load();
      expect(kb.entries.length, greaterThanOrEqualTo(51));
      for (final e in kb.entries) {
        for (final lang in const ['mr', 'hi', 'en']) {
          expect(e.answers[lang], isNotEmpty, reason: '${e.id} $lang');
          expect(e.questions[lang], isNotEmpty, reason: '${e.id} $lang');
        }
        expect(e.sources, isNotEmpty, reason: e.id);
        expect(e.sources.every(kb.sources.containsKey), isTrue, reason: e.id);
      }
      final ids = {for (final e in kb.entries) e.id};
      for (final id in const [
        'seed-psylla-symptoms',
        'seed-psylla-scouting',
        'seed-phytophthora-symptoms',
        'seed-canker-items',
      ]) {
        expect(ids, contains(id));
      }
      expect(ids.where((id) => id.startsWith('seed-')), hasLength(51));
    },
  );

  test(
    'the shipped asset and the seed carry no note vouching for the answers',
    () {
      // Owner 2026-11-14: no "this information is from checked sources" line.
      for (final path in const [
        'assets/config/qa_kb.json.gz',
        'test/fixtures/qa_kb_seed.json.gz',
      ]) {
        final json = jsonDecode(
          utf8.decode(gzip.decode(File(path).readAsBytesSync())),
        ) as Map<String, dynamic>;
        expect(json.containsKey('note'), isFalse, reason: path);
      }
    },
  );
}
