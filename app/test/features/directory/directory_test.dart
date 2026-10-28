import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/directory/data/directory_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../feed/feed_screen_test.dart' show RecordingTextSharer;
import '../plots/plots_screen_test.dart' show settle;

class _OneAsset extends CachingAssetBundle {
  _OneAsset(this.json);

  final Map<String, Object?> json;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(jsonEncode(json)));
}

/// Captures what the app puts on the clipboard.
String? Function() mockClipboard(WidgetTester tester) {
  String? copied;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return () => copied;
}

void _expectSound(DirectoryData data, String what) {
  expect(data.entries, isNotEmpty, reason: what);
  expect(data.entries.map((e) => e.id).toSet(), hasLength(data.entries.length));
  for (final e in data.entries) {
    for (final lang in ['en', 'mr', 'hi']) {
      expect(e.name[lang]?.trim(), isNotEmpty, reason: '${e.id} name $lang');
      expect(e.offers[lang]?.trim(), isNotEmpty, reason: '${e.id} offers');
    }
    expect(data.districts.keys, contains(e.district), reason: e.id);
    expect(DirectoryEntry.kinds, contains(e.kind), reason: e.id);
    expect(e.url, startsWith('https://'), reason: e.id);
    // A phone or address is shown only with the official page it was read on.
    expect(e.source, startsWith('https://'), reason: e.id);
    expect(e.checked, isNotNull, reason: e.id);
    if (e.phone case final phone?) {
      expect(phone, matches(RegExp(r'^[0-9+][0-9 -]{6,}$')), reason: e.id);
    }
  }
  for (final labels in data.districts.values) {
    for (final lang in ['en', 'mr', 'hi']) {
      expect(labels[lang]?.trim(), isNotEmpty);
    }
  }
}

void main() {
  test(
    'lab directory: the asked-for institutions, each with a source',
    () async {
      final data = await DirectoryConfig(
        DirectoryConfig.labs,
        bundle: FileAssetBundle(),
      ).load();
      _expectSound(data, 'labs');
      final ids = data.entries.map((e) => e.id);
      for (final id in [
        'icar_ccri',
        'pdkv_akola',
        'kvk_nagpur',
        'kvk_ghatkhed',
        'kvk_selsura',
        'kvk_kharpudi',
      ]) {
        expect(ids, contains(id));
      }
      for (final d in ['nagpur', 'amravati', 'wardha', 'jalna']) {
        expect(
          data.entries.where((e) => e.district == d),
          isNotEmpty,
          reason: d,
        );
      }
    },
  );

  test(
    'market directory: short, official pages only, unverified marked',
    () async {
      final data = await DirectoryConfig(
        DirectoryConfig.markets,
        bundle: FileAssetBundle(),
      ).load();
      _expectSound(data, 'markets');
      for (final e in data.entries.where((e) => e.verified)) {
        final host = Uri.parse(e.source).host;
        expect(
          host.endsWith('.gov.in') || host == 'www.msamb.com',
          isTrue,
          reason: '${e.id}: $host is not an official page',
        );
      }
    },
  );

  test(
    'district filter keeps config order and only districts in use',
    () async {
      final data = await DirectoryConfig(
        'x',
        bundle: _OneAsset({
          'districts': {
            'nagpur': {'en': 'Nagpur', 'mr': 'नागपूर'},
            'wardha': {'en': 'Wardha'},
            'jalna': {'en': 'Jalna'},
          },
          'entries': [
            for (final (id, d) in [
              ('a', 'jalna'),
              ('b', 'nagpur'),
              ('c', 'jalna'),
            ])
              {
                'id': id,
                'kind': 'kvk',
                'district': d,
                'name': {'en': id},
                'offers': {'en': 'x'},
                'url': 'https://$id.example',
                'source': 'https://$id.example',
                'verified': id != 'c',
                'checked': '2026-10-28',
              },
          ],
        }),
      ).load();
      expect(data.districtsInUse, ['nagpur', 'jalna']);
      expect(data.inDistrict(null).map((e) => e.id), ['a', 'b', 'c']);
      expect(data.inDistrict('jalna').map((e) => e.id), ['a', 'c']);
      expect(data.districtLabel('nagpur', 'mr'), 'नागपूर');
      expect(data.districtLabel('wardha', 'mr'), 'Wardha');
      expect(data.districtLabel('pune', 'mr'), 'pune');
      expect(data.entries.last.verified, isFalse);
      expect(data.entries.first.nameIn('hi'), 'a');
      expect(data.entries.first.checked, DateTime(2026, 10, 28));
    },
  );

  testWidgets(
    'labs: filter by district, copy the number, copy the link, share',
    (tester) async {
      final sharer = RecordingTextSharer();
      final copied = mockClipboard(tester);
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/labs',
        overrides: [textSharerProvider.overrideWithValue(sharer)],
      );
      await settle(tester);
      expect(find.text('Labs and experts'), findsOneWidget);
      expect(
        find.text('ICAR-Central Citrus Research Institute (CCRI), Nagpur'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('labs-district-jalna')));
      await settle(tester);
      expect(
        find.text('ICAR-Central Citrus Research Institute (CCRI), Nagpur'),
        findsNothing,
      );
      expect(
        find.text('Krishi Vigyan Kendra (KVK), Kharpudi, Jalna'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('labs-district-nagpur')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('labs-copy-phone-kvk_nagpur')));
      await tester.pump();
      expect(copied(), '07103-275537');
      expect(find.text('Number copied'), findsOneWidget);

      await tester.tap(find.byKey(const Key('labs-link-kvk_nagpur')));
      await tester.pump();
      expect(copied(), 'https://www.kvknagpur.org.in/SoilTest.html');

      await tester.tap(find.byKey(const Key('labs-kvk_nagpur-share')));
      await tester.pump();
      expect(sharer.shared.single, contains('07103-275537'));
      expect(sharer.shared.single, contains('Nagpur'));
      expect(sharer.shared.single, contains('kvknagpur.org.in'));
      expect(sharer.shared.single, contains('BagMitra'));
      await unmountApp(tester);
    },
  );

  testWidgets(
    'market directory marks entries not checked on an official page',
    (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/market',
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('open-market-directory')));
      await settle(tester);
      expect(find.text('Markets and buyers'), findsOneWidget);
      expect(find.text('MSAMB: APMC arrivals and prices'), findsOneWidget);
      final kalamna = find.byKey(
        const Key('markets-entry-apmc_nagpur_kalamna'),
      );
      await tester.scrollUntilVisible(kalamna, 300);
      expect(
        find.descendant(
          of: kalamna,
          matching: find.text('Not yet checked on an official page'),
        ),
        findsOneWidget,
      );
      await unmountApp(tester);
    },
  );
}
