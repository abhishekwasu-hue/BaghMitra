import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/core/formatting.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/feed/domain/feed_article.dart';
import 'package:bagmitra/features/feed/domain/feed_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'feed_data_test.dart' show FakeFeedRepository, feedBody, feedJson;

/// An AI article in the `/v1/feed` contract shape (spec v1.6).
Map<String, Object?> articleJson({bool charts = true}) => {
  'headline': 'Orange growers: subsidy ₹6,000 per hectare',
  'standfirst': 'The state announced help for orange growers.',
  'key_points': [
    'Subsidy ₹6,000 per hectare',
    'Last date 30 November 2026',
    '1,200 farmers eligible',
  ],
  'sections': [
    {'heading': 'What was decided', 'body': 'The state announced a subsidy.'},
    {'heading': 'Who benefits', 'body': 'Orange growers in two divisions.'},
    {'heading': 'What farmers can do next', 'body': 'Apply on MahaDBT.'},
  ],
  'facts': [
    {'label': 'Amount', 'value': '₹6,000 per hectare'},
    {'label': 'Last date', 'value': '30 November 2026'},
    {'label': 'Eligible farmers', 'value': '1,200'},
  ],
  'charts': [
    if (charts) ...[
      {
        'type': 'pie',
        'title': 'Beneficiaries by division',
        'unit': '%',
        'data': [
          {'label': 'Nagpur', 'value': 60.0},
          {'label': 'Amravati', 'value': 40.0},
        ],
      },
      {
        'type': 'bar',
        'title': 'Applications by district',
        'unit': 'farmers',
        'data': [
          {'label': 'Nagpur', 'value': 700.0},
          {'label': 'Amravati', 'value': 500.0},
        ],
      },
    ],
  ],
  'key_dates': [
    {'date': '2026-11-30', 'label': 'Last date to apply'},
  ],
  'sources': [
    {'title': 'Mahasamvad', 'url': 'https://mahasamvad.in/12345/'},
  ],
};

void main() {
  test('an item keeps its article through the phone cache', () {
    final item = FeedItem.fromJson({
      ...feedJson('a1', trust: 'news'),
      'article': articleJson(),
    });
    final article = item.article!;
    expect(article.keyPoints, hasLength(3));
    expect(article.sections.first.heading, 'What was decided');
    expect(article.facts.last.value, '1,200');
    expect(article.charts.first.type, FeedChartType.pie);
    expect(article.charts.first.points.first.value, 60);
    expect(article.keyDates.single.date, DateTime(2026, 11, 30));
    expect(article.sources.single.url, 'https://mahasamvad.in/12345/');
    final again = FeedItem.fromJson(item.toJson());
    expect(again.article!.toJson(), article.toJson());
  });

  test('an item without an article, or with a broken one, has none', () {
    expect(FeedItem.fromJson(feedJson('a1')).article, isNull);
    final broken = FeedItem.fromJson({
      ...feedJson('a2'),
      'article': {'headline': 1},
    });
    expect(broken.article, isNull);
  });

  test('an unknown chart type is left out', () {
    final json = articleJson();
    (json['charts']! as List).add({
      'type': 'line',
      'title': 'x',
      'unit': '',
      'data': [
        {'label': 'a', 'value': 1.0},
        {'label': 'b', 'value': 2.0},
      ],
    });
    expect(FeedArticle.tryParse(json)!.charts, hasLength(2));
  });

  articleWidgetTests();
}

/// The feed cache with one article item, as the phone stores it.
Future<void> seedArticleFeed(AppDatabase db, {String lang = 'en'}) =>
    db.writeMeta(
      FeedCache.keyFor(lang),
      jsonEncode({
        'saved_at': '2026-10-12T06:00:00.000Z',
        'page': feedBody([
          {
            ...feedJson(
              'art1',
              trust: 'news',
              level: 'state',
              grNumber: null,
              department: null,
              publishedAt: '2026-10-12T05:00:00Z',
            ),
            'title': 'Orange growers: subsidy ₹6,000 per hectare',
            'summary': 'The state announced help for orange growers.',
            'article': articleJson(),
          },
        ]),
      }),
    );

final _list = find.byType(Scrollable).first;

void articleWidgetTests() {
  testWidgets(
    'the article screen: byline, key points, sections, facts, charts, '
    'dates, sources',
    (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/feed/art1',
        seed: seedArticleFeed,
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
        ],
      );
      await settle(tester);
      expect(find.byKey(const Key('feed-article')), findsOneWidget);
      expect(find.textContaining('written by AI'), findsOneWidget);
      expect(find.text('1,200 farmers eligible'), findsOneWidget);
      for (final heading in ['What was decided', 'What farmers can do next']) {
        await tester.scrollUntilVisible(
          find.text(heading),
          300,
          scrollable: _list,
        );
        expect(find.text(heading), findsOneWidget);
      }
      await tester.scrollUntilVisible(
        find.text('Eligible farmers'),
        300,
        scrollable: _list,
      );
      expect(find.text('₹6,000 per hectare'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('feed-chart-0')),
        300,
        scrollable: _list,
      );
      expect(find.text('Beneficiaries by division'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Nagpur 60 %')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('feed-chart-1')),
        300,
        scrollable: _list,
      );
      expect(find.text('700 farmers'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Last date to apply'),
        300,
        scrollable: _list,
      );
      expect(
        find.text(formatDate(DateTime(2026, 11, 30), 'en')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining('mahasamvad.in'),
        300,
        scrollable: _list,
      );
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    },
  );
}
