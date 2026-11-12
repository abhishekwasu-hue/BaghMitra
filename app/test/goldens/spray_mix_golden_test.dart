// Tank mix on the spray record (OPEN_QUESTIONS Q142) and spraying labour (Q143), Marathi,
// 360 dp phone, text at 1.3x, light and dark: the form with three products filled from a
// bill (one with a ban note on it) and labour, the spray log with a mix, and its detail. Regenerate with:
//   flutter test --update-goldens test/goldens/spray_mix_golden_test.dart
@Tags(['golden'])
library;

import 'dart:io';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../features/bills/bill_forms_test.dart' show billOverrides;
import '../features/bills/bill_read_test.dart';
import '../features/photo_analysis/photo_analysis_test.dart' show json;
import '../features/plots/plots_screen_test.dart' show settle;
import '../features/scouting/scouting_test.dart' show FakePhotos;
import '../features/spray/spray_mix_test.dart' show captan, imida, kelthane;
import '../features/spray/spray_screen_test.dart' show seedPlotAndBanList;
import '../helpers/pump_app.dart';

String _billFile() {
  final image = img.Image(width: 300, height: 400)
    ..clear(img.ColorRgb8(250, 248, 240));
  for (var y = 40; y < 380; y += 28) {
    img.drawLine(
      image,
      x1: 24,
      y1: y,
      x2: y % 56 == 0 ? 200 : 276,
      y2: y,
      color: img.ColorRgb8(120, 120, 120),
      thickness: 3,
    );
  }
  final dir = Directory.systemTemp.createTempSync('mix_bill_golden');
  final file = File('${dir.path}/bill.jpg')
    ..writeAsBytesSync(img.encodeJpg(image));
  return file.path;
}

String _bill() => billJson(
  shop: 'श्री कृषी सेवा केंद्र',
  items: [
    {
      'name': 'Captan 50 WP',
      'active_ingredient': 'captan',
      'quantity': 500,
      'unit': 'g',
      'amount_rs': 450,
    },
    {
      'name': 'Imida 17.8 SL',
      'active_ingredient': 'imidacloprid',
      'quantity': 250,
      'unit': 'ml',
      'amount_rs': 650,
    },
    {
      'name': 'Kelthane',
      'active_ingredient': 'Kelthane',
      'quantity': 1,
      'unit': 'l',
      'amount_rs': 200,
    },
  ],
);

Future<void> _seedMix(AppDatabase db) async {
  await seedPlotAndBanList(db);
  final repo = SprayRepository(db);
  await repo.save(
    SprayRecord.ofProducts(
      id: 'm1',
      plotId: 'p1',
      baharCycleId: 'b1',
      sprayedOn: DateTime(2026, 11, 2),
      products: const [captan, imida, kelthane],
      waterLitres: 600,
      areaAcres: 4,
      operator: 'Ramesh',
      target: 'psylla, canker',
      // Spraying labour (Q143).
      labourPaise: 50000,
    ),
  );
  await repo.save(
    SprayRecord(
      id: 's1',
      plotId: 'p1',
      sprayedOn: DateTime(2026, 9, 20),
      productName: 'Neem oil',
      costPaise: 30000,
      target: 'मावा',
    ),
  );
}

void main() {
  late String path;
  setUpAll(() => path = _billFile());

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final form = 'spray_mix_form_mr_${mode.name}_x13';
    testWidgets(form, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/plots/p1/sprays/new',
        seed: seedPlotAndBanList,
        size: const Size(360, 3200),
        overrides: billOverrides(
          FakeBillServer((_) async => json(_bill(), 200)),
          FakePhotos(picked: path),
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('bill-photo-camera')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('bill-fill')));
      await settle(tester);
      for (final i in [0, 1, 2]) {
        await tester.tap(find.byKey(Key('bill-pick-$i')));
        await settle(tester);
      }
      await tester.tap(find.byKey(const Key('bill-pick-fill')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('spray-phi')), '7');
      await tester.enterText(find.byKey(const Key('spray-phi-1')), '15');
      await tester.enterText(find.byKey(const Key('spray-water')), '600');
      await tester.enterText(find.byKey(const Key('spray-area')), '4');
      await tester.enterText(find.byKey(const Key('spray-labour')), '500');
      await tester.enterText(
        find.byKey(const Key('spray-target')),
        'सिट्रस सायला, कॅन्कर',
      );
      await settle(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$form.png'),
      );
      await unmountApp(tester);
    });

    for (final (name, location, height) in [
      ('spray_mix_log', '/plots/p1/sprays', 900.0),
      ('spray_mix_detail', '/plots/p1/sprays/view/m1', 1300.0),
    ]) {
      final file = '${name}_mr_${mode.name}_x13';
      testWidgets(file, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: location,
          seed: _seedMix,
          size: Size(360, height),
        );
        await settle(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$file.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
