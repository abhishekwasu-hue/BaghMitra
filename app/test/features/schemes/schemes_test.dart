import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:bagmitra/features/schemes/data/scheme_catalog.dart';
import 'package:bagmitra/features/schemes/data/scheme_ticks_store.dart';
import 'package:bagmitra/features/schemes/presentation/scheme_screens.dart';
import 'package:bagmitra/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../feed/feed_data_test.dart' show feedJson;
import '../feed/feed_screen_test.dart' show RecordingTextSharer;
import '../plots/plots_screen_test.dart' show settle;

FeedItem feedItem(String id, String title, {String? validTo}) =>
    FeedItem.fromJson({...feedJson(id, validTo: validTo), 'title': title});

/// A cached feed with one PM-Kisan notice, one expired and one unrelated.
CachedFeed schemeFeed() => CachedFeed(
  FeedPage(
    items: [
      feedItem('pk1', 'PM-Kisan: e-KYC camp in Nagpur'),
      feedItem('old', 'PM Kisan old camp', validTo: '2026-10-01'),
      feedItem('other', 'Mandi rates notice'),
    ],
  ),
  DateTime.utc(2026, 10, 12),
);

const schemeIds = [
  'agristack',
  'pm_kisan',
  'crop_insurance',
  'micro_irrigation',
  'falbag',
  'kcc',
];

void main() {
  late SchemesData data;

  setUpAll(() async {
    data = await SchemeCatalog(bundle: FileAssetBundle()).load();
  });

  test('the catalog has the six schemes in three languages', () {
    expect([for (final s in data.schemes) s.id], schemeIds);
    expect(data.checkedOn, DateTime(2026, 10, 28));
    for (final s in data.schemes) {
      for (final labels in [s.names, s.summaries, s.who]) {
        expect(labels.keys.toSet(), {'en', 'mr', 'hi'}, reason: s.id);
      }
      expect(s.documents, isNotEmpty, reason: s.id);
      expect(s.apply.where((a) => a.url != null), isNotEmpty, reason: s.id);
      expect(s.sources.every((x) => x.official), isTrue, reason: s.id);
      expect(s.feedKeywords, isNotEmpty);
      for (final d in s.documents) {
        expect(data.documentLabels[d.key]!.keys.toSet(), {'en', 'mr', 'hi'});
      }
      for (final a in s.apply) {
        if (a.url case final url?) {
          expect(Uri.parse(url).host, endsWith('.gov.in'), reason: url);
        }
      }
    }
    final pmKisan = data.byId('pm_kisan')!;
    expect([
      for (final d in pmKisan.documents) d.key,
    ], containsAll(['aadhaar', 'satbara', 'bank_passbook', 'farmer_id']));
    expect(data.byId('nope'), isNull);
    expect(data.documentLabel('satbara', 'mr'), '७/१२ उतारा (सातबारा)');
    expect(data.documentLabel('unknown', 'mr'), 'unknown');
  });

  test('no amounts, rates or advice in the scheme content', () {
    final raw = File(SchemeCatalog.asset).readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final shown = jsonEncode({
      'documents': json['documents'],
      'schemes': [
        for (final s in (json['schemes'] as List).cast<Map<String, dynamic>>())
          {'names': s['names'], 'summary': s['summary'], 'who': s['who']},
      ],
    });
    for (final word in ['₹', 'Rs', 'रु', 'lakh', 'लाख', '%', 'हेक्टर']) {
      expect(shown, isNot(contains(word)), reason: word);
    }
    expect(json['status'], 'draft');
  });

  test('feed items match a scheme by its words, live items only', () {
    final pmKisan = data.byId('pm_kisan')!;
    final now = DateTime(2026, 10, 13);
    expect(
      [
        for (final i in pmKisan.matchingFeedItems(schemeFeed().page.items, now))
          i.id,
      ],
      ['pk1'],
    );
    expect(
      data.byId('falbag')!.matchingFeedItems([
        feedItem('f1', 'भाऊसाहेब फुंडकर योजना'),
      ], now),
      hasLength(1),
    );
  });

  test('ticked documents stay on the phone per scheme', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final store = SchemeTicksStore(db);
    expect(await store.load('kcc'), isEmpty);
    await store.set('kcc', 'satbara', has: true);
    await store.set('kcc', 'crop_details', has: true);
    await store.set('kcc', 'satbara', has: false);
    expect(await store.load('kcc'), {'crop_details'});
    expect(await store.load('pm_kisan'), isEmpty);
    expect(await store.watch('kcc').first, {'crop_details'});
    expect(await db.select(db.outboxEntries).get(), isEmpty);
  });

  testWidgets('the share text lists what is ready and what to get', (
    tester,
  ) async {
    await pumpApp(tester, locale: const Locale('en'), initialLocation: '/');
    final t = AppLocalizationsEn();
    final text = schemeShareText(
      t,
      data,
      data.byId('kcc')!,
      {'satbara'},
      'en',
      'BagMitra',
    );
    expect(text, contains('✔ 7/12 extract (Satbara) (have)'));
    expect(text, contains('☐ Details of the crops you grow (to get)'));
    expect(
      text,
      contains('KCC form on the PM-Kisan portal: https://pmkisan.gov.in/'),
    );
    expect(text, contains(t.schemeWhoCheck));
    expect(text, contains(t.schemeVisitSetu));
    await unmountApp(tester);
  });

  testWidgets('home opens the scheme list; a scheme shows its checklist', (
    tester,
  ) async {
    final sharer = RecordingTextSharer();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/',
      overrides: [
        textSharerProvider.overrideWithValue(sharer),
        feedProvider.overrideWith((ref, lang) async => schemeFeed()),
      ],
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-schemes')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('open-schemes')));
    await settle(tester);
    expect(find.textContaining('Always check the official page'), findsOne);
    expect(find.byKey(const Key('setu-note')), findsOne);
    expect(find.byKey(const Key('scheme-agristack')), findsOne);
    await tester.tap(find.byKey(const Key('scheme-pm_kisan')));
    await settle(tester);

    expect(find.text('PM-Kisan Samman Nidhi'), findsOne);
    expect(find.text('In general terms. Check the official page.'), findsOne);
    expect(find.text('0 of 5 ready'), findsOne);
    expect(find.textContaining('Visit your nearest Setu Kendra'), findsOne);
    await tester.tap(find.byKey(const Key('scheme-doc-aadhaar')));
    await settle(tester);
    expect(find.text('1 of 5 ready'), findsOne);
    expect(await tester.runAsync(() => SchemeTicksStore(db).load('pm_kisan')), {
      'aadhaar',
    });

    await tester.tap(find.byKey(const Key('scheme-share')));
    await settle(tester);
    expect(sharer.shared.single, contains('✔ Aadhaar card (have)'));

    await tester.scrollUntilVisible(
      find.byKey(const Key('scheme-feed-pk1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('scheme-feed-old')), findsNothing);
    expect(find.byKey(const Key('scheme-feed-other')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('scheme-source-0')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sources (checked on 28 Oct 2026)'), findsOne);
    await tester.tap(find.byKey(const Key('scheme-source-0')));
    await settle(tester);
    expect(find.text('Link copied. Open it in your browser.'), findsOne);
    await unmountApp(tester);
  });

  testWidgets('unconfirmed documents say so', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/schemes/falbag',
      overrides: [feedProvider.overrideWith((ref, lang) async => null)],
    );
    await settle(tester);
    expect(
      find.text('Not yet confirmed on an official page'),
      findsAtLeastNWidgets(1),
    );
    expect(find.byKey(const Key('scheme-feed-pk1')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('an unknown scheme shows the empty state', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/schemes/nope',
    );
    await settle(tester);
    expect(find.textContaining('Always check the official page'), findsOne);
    await unmountApp(tester);
  });
}
