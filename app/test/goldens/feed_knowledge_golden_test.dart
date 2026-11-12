// Knowledge articles, ज्ञान लेख (Q141), at phone width, Marathi, 1.3x text, light and dark: the
// feed list with the "ज्ञान" chip on, the article's top (badge, byline, sections) and its end
// (source link chips, the green "उपाय व माहिती पहा", the muted note). Served from the phone's cache (offline).
//   flutter test --update-goldens test/goldens/feed_knowledge_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/feed/feed_data_test.dart'
    show FakeFeedRepository, feedBody, feedJson;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

// Wording from the psylla practice card (practice_cards.json items 25-27, profile).
const _article = {
  'headline': 'सायला: नवतीवर बारकाईने लक्ष ठेवा',
  'standfirst': 'उबदार दिवस सायलाच्या वाढीस अनुकूल असतात; नवती तपासत राहा.',
  'key_points': <String>[],
  'sections': [
    {
      'heading': 'काय दिसते',
      'body':
          'चपटी पिवळी-नारिंगी पिल्ले शेंड्यांवर पांढऱ्या मेणचट धाग्यांसह गर्दी '
          'करतात; नवीन पाने वळतात, गुंडाळतात व गळतात.',
    },
    {
      'heading': 'बागेत काय तपासावे',
      'body': 'प्रत्येक नवती, मुख्यतः शेंडे व कोवळी पाने तपासा.',
    },
    {
      'heading': 'काय करावे',
      'body':
          'जूनच्या पहिल्या आठवड्यापासून जमिनीपासून सुमारे २ मीटर उंचीवर पिवळे '
          'चिकट सापळे लावा (स्रोतानुसार एकरी ३०) आणि दर महिन्याला बदला.',
    },
    {
      'heading': 'मित्रकीटकांचे जतन',
      'body': 'लेडीबर्ड (ढालकीडा) भुंगे सायलाची पिल्ले खातात; त्यांचे जतन करा.',
    },
    {
      'heading': 'KVK ला केव्हा विचारावे',
      'body': 'कीड पसरत असेल किंवा खात्री नसेल तर फोटो व माहिती KVK ला पाठवा.',
    },
  ],
  'facts': <Object>[],
  'charts': <Object>[],
  'key_dates': <Object>[],
  'sources': [
    {
      'title': 'NHB Citrus: Insect pests',
      'url': 'https://www.nhb.gov.in/pdf/fruits/citrus/cit008.pdf',
    },
    {
      'title': 'Dr. PDKV Research Recommendations 2025',
      'url': 'https://www.pdkv.ac.in/Circulars/Recom-2025English.pdf',
    },
  ],
  'card_section': 'psylla',
};

Map<String, Object?> _body() => feedBody([
  {
    ...feedJson(
      'k1',
      type: 'knowledge',
      grNumber: null,
      department: null,
      publishedAt: '2026-10-12T02:11:00Z',
    ),
    'title': _article['headline'],
    'summary': _article['standfirst'],
    'url': 'https://www.nhb.gov.in/pdf/fruits/citrus/cit008.pdf',
    'article': _article,
  },
  {
    ...feedJson(
      'k2',
      type: 'knowledge',
      grNumber: null,
      department: null,
      publishedAt: '2026-10-08T02:11:00Z',
    ),
    'title': 'आंबिया बहार: ताण सुरू करण्याची तयारी',
    'summary': 'बहार धरण्यासाठी पाण्याचा ताण कसा द्यावा.',
  },
  {
    ...feedJson('gr1', level: 'state', publishedAt: '2026-10-11T06:00:00Z'),
    'title': 'फळबाग योजना अर्ज',
  },
]);

Future<void> _seed(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('mr'),
  jsonEncode({
    'saved_at': DateTime(2026, 10, 12, 6).toUtc().toIso8601String(),
    'page': _body(),
  }),
);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (part, location) in [
      ('list', '/feed'),
      ('article', '/feed/k1'),
      ('sections', '/feed/k1'),
      ('end', '/feed/k1'),
    ]) {
      final name = 'feed_knowledge_${part}_mr_${mode.name}';
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: location,
          seed: _seed,
          size: _phone,
          overrides: [
            // Offline: everything shown comes from the cache.
            feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
          ],
        );
        await settle(tester);
        if (part == 'list') {
          await tester.tap(find.byKey(const Key('feed-filter-knowledge')));
          await settle(tester);
          await tester.pump(
            const Duration(seconds: 1),
          ); // the chip's check animation
        }
        if (part == 'sections') {
          // The section cards: "काय करावे" with its number pills and names.
          await tester.scrollUntilVisible(
            find.text('काय करावे'),
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text('काय करावे'));
          await tester.drag(find.byType(Scrollable).first, const Offset(0, 60));
          await settle(tester);
        }
        if (part == 'end') {
          await tester.scrollUntilVisible(
            find.byKey(const Key('feed-knowledge-note')),
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await settle(tester);
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$name.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
