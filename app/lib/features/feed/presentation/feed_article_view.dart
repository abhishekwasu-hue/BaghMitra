import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/article_reading.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/feed_article.dart';

/// The AI article of a feed item (spec v1.6): a byline saying it was written by AI from
/// official sources, key points, sections, a facts table, bar / pie charts drawn here (no
/// chart package), key dates and the sources. Every chart is also read out as text.
/// A knowledge article (ज्ञान लेख, Q141, [knowledge]) has its own byline, its sections and
/// sources (a tap copies the link), and "उपाय व माहिती पहा" to the practices it came from.
///
/// Reading (owner 2026-11-12): every part is a card with a coloured header and icon chosen
/// by meaning, numbers and KB names are marked, long paragraphs become bullets
/// (design_system/article_reading.dart). The server text is drawn as written.
class FeedArticleView extends StatelessWidget {
  const FeedArticleView({
    super.key,
    required this.article,
    required this.lang,
    this.knowledge = false,
  });

  final FeedArticle article;
  final String lang;
  final bool knowledge;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    var others = 0;
    return Column(
      key: const Key('feed-article'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadingBadge(
          icon: knowledge ? Icons.verified_rounded : Icons.newspaper_rounded,
          text: knowledge ? t.feedKnowledgeByline : t.feedArticleByline,
          tone: knowledge ? c.toneGreen : c.toneBlue,
        ),
        if (article.keyPoints.isNotEmpty) ...[
          const SizedBox(height: BmSpace.md),
          ReadingCard(
            heading: t.feedArticleKeyPoints,
            icon: Icons.star_rounded,
            tone: c.toneGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final point in article.keyPoints)
                  ReadingBullet(text: point, tone: c.toneGreen),
              ],
            ),
          ),
        ],
        for (final s in article.sections) ...[
          const SizedBox(height: BmSpace.md),
          ArticleSectionCard(
            heading: s.heading,
            body: s.body,
            otherIndex: sectionKindFor(s.heading) == ArticleSectionKind.other
                ? others++
                : 0,
          ),
        ],
        if (article.facts.isNotEmpty) ...[
          const SizedBox(height: BmSpace.md),
          ReadingCard(
            key: const Key('feed-facts'),
            heading: t.feedArticleFacts,
            icon: Icons.table_chart_rounded,
            tone: c.toneBlue,
            child: _FactsTable(article.facts),
          ),
        ],
        for (final (i, chart) in article.charts.indexed) ...[
          const SizedBox(height: BmSpace.md),
          ReadingCard(
            key: Key('feed-chart-$i'),
            heading: chart.title,
            icon: chart.type == FeedChartType.pie
                ? Icons.pie_chart_rounded
                : Icons.bar_chart_rounded,
            tone: c.toneTeal,
            child: chart.type == FeedChartType.pie
                ? _PieChart(chart: chart, lang: lang)
                : _BarChart(chart: chart, lang: lang),
          ),
        ],
        if (article.keyDates.isNotEmpty) ...[
          const SizedBox(height: BmSpace.md),
          ReadingCard(
            heading: t.feedArticleKeyDates,
            icon: Icons.event_rounded,
            tone: c.toneAmber,
            child: Column(
              children: [
                for (final d in article.keyDates)
                  Padding(
                    padding: const EdgeInsets.only(top: BmSpace.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.event_rounded, size: 20, color: c.caution),
                        const SizedBox(width: BmSpace.xs),
                        Text(
                          formatDate(d.date, lang),
                          style: BmType.bodyStrong.copyWith(color: c.caution),
                        ),
                        const SizedBox(width: BmSpace.sm),
                        Expanded(child: Text(d.label, style: BmType.body)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (article.sources.isNotEmpty) ...[
          const SizedBox(height: BmSpace.md),
          Row(
            children: [
              ToneIconChip(
                icon: sectionIcon(ArticleSectionKind.sources),
                tone: c.toneGrey,
                size: 28,
              ),
              const SizedBox(width: BmSpace.xs),
              Text(t.feedArticleSources, style: BmType.bodyStrong),
            ],
          ),
          const SizedBox(height: BmSpace.xs),
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              for (final (i, s) in article.sources.indexed)
                if (knowledge)
                  _SourceRow(key: Key('feed-knowledge-source-$i'), source: s)
                else
                  SourceChip(title: s.title, url: s.url),
            ],
          ),
        ],
        if (knowledge && article.cardSection != null) ...[
          const SizedBox(height: BmSpace.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('feed-knowledge-card'),
              style: BmButtonStyle.primary(c),
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(t.feedKnowledgeOpenCard),
              onPressed: () =>
                  context.push(Routes.practicesSection(article.cardSection!)),
            ),
          ),
        ],
      ],
    );
  }
}

/// One source of a knowledge article as a link chip: its title and site; a tap copies the
/// full link (the app opens no browser), at least 48 dp tall.
class _SourceRow extends StatelessWidget {
  const _SourceRow({super.key, required this.source});

  final ({String title, String url}) source;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SourceChip(
      title: source.title,
      url: source.url,
      hint: t.feedCopyLink,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: source.url));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t.feedLinkCopied)));
        }
      },
    );
  }
}

class _FactsTable extends StatelessWidget {
  const _FactsTable(this.facts);

  final List<({String label, String value})> facts;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final (i, f) in facts.indexed)
          TableRow(
            decoration: BoxDecoration(color: i.isEven ? c.toneBlue.tint : null),
            children: [
              Padding(
                padding: const EdgeInsets.all(BmSpace.xs),
                child: Text(f.label, style: BmType.meta),
              ),
              Padding(
                padding: const EdgeInsets.all(BmSpace.xs),
                child: Text(f.value, style: BmType.bodyStrong),
              ),
            ],
          ),
      ],
    );
  }
}

/// Category colours by meaning-free order, readable in light and dark themes.
List<Color> _palette(BmColors c) => [
  c.brand,
  c.accent,
  c.sky,
  c.sun,
  c.soil,
  c.caution,
  c.info,
  c.danger,
];

String _value(double v, String unit, String lang) {
  final number = formatDecimal(v, lang);
  if (unit.isEmpty) return number;
  return unit == '%' ? '$number %' : '$number $unit';
}

String _spoken(FeedChart chart, String lang) => [
  chart.title,
  for (final p in chart.points)
    '${p.label} ${_value(p.value, chart.unit, lang)}',
].join(', ');

class _BarChart extends StatelessWidget {
  const _BarChart({required this.chart, required this.lang});

  final FeedChart chart;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final colors = _palette(c);
    final top = chart.points.map((p) => p.value).fold(0.0, math.max);
    return Semantics(
      label: _spoken(chart, lang),
      excludeSemantics: true,
      child: Column(
        children: [
          for (final (i, p) in chart.points.indexed)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(p.label, style: BmType.meta)),
                      Text(
                        _value(p.value, chart.unit, lang),
                        style: BmType.bodyStrong,
                      ),
                    ],
                  ),
                  const SizedBox(height: BmSpace.xxs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(BmRadius.chip),
                    child: LinearProgressIndicator(
                      value: top == 0 ? 0 : p.value / top,
                      minHeight: 14,
                      color: colors[i % colors.length],
                      backgroundColor: c.line,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.chart, required this.lang});

  final FeedChart chart;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final colors = _palette(c);
    return Semantics(
      label: _spoken(chart, lang),
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 160,
            child: CustomPaint(
              painter: _PiePainter(
                [for (final p in chart.points) p.value],
                colors,
                c.card,
              ),
            ),
          ),
          const SizedBox(height: BmSpace.sm),
          for (final (i, p) in chart.points.indexed)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xxs),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: BmSpace.xs),
                  Expanded(child: Text(p.label, style: BmType.meta)),
                  Text(
                    _value(p.value, chart.unit, lang),
                    style: BmType.bodyStrong,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.values, this.colors, this.gap);

  final List<double> values;
  final List<Color> colors;
  final Color gap;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    for (final (i, v) in values.indexed) {
      final sweep = v / total * 2 * math.pi;
      canvas.drawArc(
        rect.deflate(2),
        start,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      start += sweep;
    }
    // A hole in the middle (donut) reads better at phone size.
    canvas.drawCircle(
      rect.center,
      size.shortestSide * 0.28,
      Paint()..color = gap,
    );
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.values != values || old.colors != colors || old.gap != gap;
}
