// The crops a question names (owner 2026-11-15): a question about a crop the stored answers
// are not for (बाजरी, कापूस, ...) gets no citrus answer. Names come from config; words that
// also mean something else (केला, बोर, gram, lime) are never read as a crop; no stored
// question is ever taken for another crop's.
import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/features/ask/data/ask_crops_config.dart';
import 'package:bagmitra/features/ask/domain/ask_crops.dart';
import 'package:bagmitra/features/crop_guides/data/crop_guides.dart';
import 'package:bagmitra/features/plots/data/crop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart' show FileAssetBundle;

Future<AskCrops> loadAskCrops() async => buildAskCrops(
  await AskCropsConfig(bundle: FileAssetBundle()).load(),
  await CropCatalog(bundle: FileAssetBundle()).loadAll(),
  await CropGuidesConfig(bundle: FileAssetBundle()).load(),
);

void main() {
  late AskCrops crops;
  setUpAll(() async => crops = await loadAskCrops());

  List<String> other(String q) => [
    for (final c in crops.otherCropsIn(q)) c.slug,
  ];

  test('a question about another crop names that crop', () {
    expect(other('बाजरी लागवडी संदर्भात सांगा'), ['bajra']);
    expect(other('बाजरीची पेरणी'), ['bajra']);
    expect(other('कापूस लागवड'), ['cotton']);
    expect(other('कापसाची फवारणी'), ['cotton']);
    expect(other('कपाशीवरील बोंडअळी'), ['cotton']);
    expect(other('ज्वारी पेरणी'), ['jowar']);
    expect(other('उसाची लागवड'), ['sugarcane']);
    expect(other('हरभऱ्याची मर'), ['gram']);
    expect(other('pearl millet sowing'), ['bajra']);
    expect(other('kapsachi favarani'), ['cotton']);
    expect(other('गेहूं की बुवाई'), ['wheat']);
    expect(other('सोयाबीन आणि तूर आंतरपीक'), ['soybean', 'tur']);
  });

  test('santra / mosambi questions, and words that are no crop, pass', () {
    expect(other('संत्री बाजारात पॅकिंग'), isEmpty);
    expect(other('बाजारभाव'), isEmpty);
    expect(other('संत्र्याचा बाजारभाव'), isEmpty);
    expect(other('सायलाची लक्षणे काय?'), isEmpty);
    expect(other('मोसंबीवरील कोळी'), isEmpty);
    // Santra named too (an intercrop in the orchard): answered as before.
    expect(other('संत्र्याच्या बागेत हरभरा घ्यावा का'), isEmpty);
    expect(other('sweet lime fruit drop'), isEmpty);
    // Words that also mean something else.
    expect(other('फवारणी केला तरी सायला आहे'), isEmpty);
    expect(other('बोरचे पाणी खारट'), isEmpty);
    expect(other('10 gram per litre'), isEmpty);
    expect(other('lime sulphur spray'), isEmpty);
    expect(other('बोरॉन फवारणी'), isEmpty);
    expect(other('लिंबूवर्गीय झाडांत फळगळ'), isEmpty);
    expect(other('आंबिया बहार ताण'), isEmpty);
  });

  test('labels: the crop list for its crops, the config for the others', () {
    final cotton = crops.otherCropsIn('कापूस').single;
    expect(cotton.label('mr'), 'कापूस');
    final bajra = crops.otherCropsIn('bajra').single;
    expect(bajra.label('mr'), 'बाजरी');
    expect(bajra.label('hi'), 'बाजरा');
  });

  test('no stored question or paraphrase is taken for another crop', () {
    final json = jsonDecode(
      utf8.decode(
        gzip.decode(File('assets/config/qa_kb.json.gz').readAsBytesSync()),
      ),
    ) as Map<String, dynamic>;
    final caught = <String>[];
    for (final e in (json['entries'] as List).cast<Map<String, dynamic>>()) {
      for (final t in [
        ...(e['q'] as Map).values.cast<String>(),
        ...((e['p'] as List?) ?? const []).cast<String>(),
      ]) {
        final o = crops.otherCropsIn(t);
        if (o.isNotEmpty) caught.add('${e['id']}: $t -> ${o.first.slug}');
      }
    }
    expect(caught, isEmpty, reason: caught.join('\n'));
  });
}
