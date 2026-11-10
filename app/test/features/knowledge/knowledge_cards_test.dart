import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/knowledge/data/knowledge_cards_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sources.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

/// One cached API answer, as `GET /v1/knowledge/cards` gives it.
Future<void> seedKnowledge(AppDatabase db) async {
  await seedPlot(db);
  await db.writeMeta(
    KnowledgeCardsCache.key,
    jsonEncode({
      'saved_at': '2026-11-06T06:00:00Z',
      'response': {
        'kind': 'general_information',
        'cards': [
          {
            'topic': 'mites',
            'topic_kind': 'pest',
            'topic_labels': {'en': 'Mites', 'mr': 'कोळी', 'hi': 'माइट'},
            'crop': 'santra',
            'reviewed': false,
            'text': {
              'en': {
                'title': 'Mites (lalya)',
                'summary': 'Tiny mites bronze leaves in hot, dry weather.',
                'cultural': 'Keep moisture even.',
                'when_to_call_expert': 'Send photos to your KVK.',
              },
              'mr': {
                'title': 'कोळी (लाल्या)',
                'summary':
                    'उष्ण, कोरड्या हवामानात सूक्ष्म कोळी पाने तांबूस करतात.',
                'cultural': 'ओलावा सारखा ठेवा.',
              },
            },
            'sources': [
              {
                'title': 'NIPHM IPM package for citrus',
                'publisher': 'NIPHM',
                'url': 'https://example.org/niphm',
                'checked': '2026-11-06',
              },
            ],
          },
          {
            'topic': 'psylla',
            'topic_kind': 'pest',
            'topic_labels': {'en': 'Psylla', 'mr': 'सायला', 'hi': 'सिल्ला'},
            'crop': 'santra',
            'reviewed': true,
            'text': {
              'en': {'summary': 'Watch every new flush.'},
            },
            'sources': <Object>[],
          },
        ],
      },
    }),
  );
}

void main() {
  testWidgets('cards show their general part, marked, with sources', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/knowledge', seed: seedKnowledge);
    await settle(tester);
    expect(find.text('ज्ञान कार्ड'), findsWidgets);
    expect(find.text('कोळी (लाल्या)'), findsOneWidget);
    expect(find.text('ओलावा सारखा ठेवा.'), findsOneWidget);
    // A field with no Marathi falls back to English.
    expect(find.text('Send photos to your KVK.'), findsOneWidget);
    // Owner 2026-11-10: no "general information · confirm with your KVK" mark.
    expect(find.textContaining('सर्वसाधारण माहिती'), findsNothing);
    // The sources fold behind one "See sources" line per card (owner request).
    expect(find.textContaining('NIPHM'), findsNothing);
    await openAllSources(tester);
    expect(find.textContaining('NIPHM'), findsWidgets);
    // No title in the answer: the topic label is the title.
    expect(find.text('सायला'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a practice section opens its own knowledge card', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/practices',
      seed: seedKnowledge,
    );
    await settle(tester);
    final mites = find.byKey(const Key('practices-mites'));
    await tester.scrollUntilVisible(mites, 300);
    await tester.tap(mites);
    await settle(tester);
    final kb = find.byKey(const Key('practices-kb-mites'));
    await tester.scrollUntilVisible(kb, 200);
    await tester.ensureVisible(kb);
    await tester.pumpAndSettle();
    await tester.tap(kb);
    await settle(tester);
    expect(find.text('Mites (lalya)'), findsOneWidget);
    expect(find.text('Psylla'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('with nothing cached and no server the screen says so', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/knowledge',
    );
    await settle(tester);
    expect(
      find.text('Knowledge cards appear here once the phone has been online.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
