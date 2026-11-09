import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../app/refresh.dart';
import '../../../core/formatting.dart';
import '../../../design_system/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/refresh_note.dart';
import '../../../theme/app_theme.dart';
import '../data/price_history_cache.dart';
import '../domain/market_labels.dart';
import '../domain/price_trend.dart';

/// Opens the price trend of one mandi (owner 2026-11-09, Q130) from the prices list.
Future<void> showPriceTrend(BuildContext context, PriceSeriesKey key) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PriceTrendSheet(seriesKey: key),
    );

/// Modal price per day as a line with a faint min–max band; sliding a finger over the chart
/// shows that day's prices. High, low and the change against 15 days and a month earlier sit
/// on top. Days without a published price stay empty: nothing is filled in.
class PriceTrendSheet extends ConsumerStatefulWidget {
  const PriceTrendSheet({required this.seriesKey, super.key});

  final PriceSeriesKey seriesKey;

  @override
  ConsumerState<PriceTrendSheet> createState() => _PriceTrendSheetState();
}

class _PriceTrendSheetState extends ConsumerState<PriceTrendSheet> {
  var _range = TrendRange.months3;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final k = widget.seriesKey;
    final loaded = ref.watch(priceHistoryProvider(k));
    final cached = loaded.value;
    final today = ref.watch(clockProvider)();
    final points = pointsIn(
      cached?.history.days ?? const <PriceDay>[],
      _range,
      today,
    );
    final stats = TrendStats.of(points);
    final selected = points.isEmpty
        ? null
        : points[(_selected ?? points.length - 1).clamp(0, points.length - 1)];
    String rs(int? v) => v == null ? '–' : formatRupees(v, lang);
    final ranges = {
      TrendRange.days15: t.marketTrendRange15,
      TrendRange.month1: t.marketTrendRange30,
      TrendRange.months3: t.marketTrendRange90,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          0,
          BmSpace.lg,
          BmSpace.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.marketTrendTitle(marketLabel(k.market, lang)),
              style: BmType.cardTitle,
            ),
            if (k.variety.isNotEmpty)
              Text(
                t.marketVariety(marketVarietyLabel(k.variety, lang)),
                style: BmType.meta,
              ),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              children: [
                for (final MapEntry(key: range, value: label) in ranges.entries)
                  ChoiceChip(
                    key: Key('trend-range-${range.days}'),
                    label: Text(label),
                    selected: _range == range,
                    onSelected: (_) => setState(() {
                      _range = range;
                      _selected = null;
                    }),
                  ),
              ],
            ),
            RefreshNote(
              cacheKey: PriceHistoryCache.keyFor(k),
              updated: cached == null
                  ? null
                  : t.marketUpdated(
                      formatDateTime(cached.savedAt.toLocal(), lang),
                    ),
              onRetry: () => ref.read(refresherProvider).priceHistory(k),
            ),
            if (stats == null)
              loaded.isLoading && !loaded.hasValue
                  ? LoadingState(label: t.loadingLabel)
                  : EmptyNote(
                      t.marketTrendCollecting,
                      key: const Key('trend-empty'),
                    )
            else ...[
              _StatsRow(stats: stats, rs: rs, lang: lang),
              const SizedBox(height: BmSpace.sm),
              if (selected != null)
                _SelectedDay(day: selected, rs: rs, lang: lang),
              const SizedBox(height: BmSpace.xs),
              Semantics(
                label: t.marketTrendSemantics(
                  ranges[_range]!,
                  rs(stats.high.modalRsPerQuintal),
                  rs(stats.low.modalRsPerQuintal),
                  rs(stats.latest.modalRsPerQuintal),
                ),
                child: _TrendChart(
                  points: points,
                  range: _range,
                  today: today,
                  selected: selected,
                  onSelect: (i) => setState(() => _selected = i),
                ),
              ),
              Row(
                children: [
                  Text(formatDate(points.first.day, lang), style: BmType.meta),
                  const Spacer(),
                  Text(formatDate(points.last.day, lang), style: BmType.meta),
                ],
              ),
              const SizedBox(height: BmSpace.xs),
              Text(
                points.length < 2 ? t.marketTrendCollecting : t.marketTrendHint,
                style: BmType.meta.copyWith(color: c.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.rs, required this.lang});

  final TrendStats stats;
  final String Function(int?) rs;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: BmSpace.sm,
      runSpacing: BmSpace.xs,
      children: [
        _Stat(t.marketTrendHigh, rs(stats.high.modalRsPerQuintal)),
        _Stat(t.marketTrendLow, rs(stats.low.modalRsPerQuintal)),
        if (stats.change15 case final change?)
          _Change(t.marketTrendChange15, change, lang),
        if (stats.change30 case final change?)
          _Change(t.marketTrendChange30, change, lang),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: BmType.meta),
      Text(value, style: BmType.bodyStrong),
    ],
  );
}

/// A change in percent: green and an up arrow for a rise, red and a down arrow for a fall.
class _Change extends StatelessWidget {
  const _Change(this.label, this.percent, this.lang);

  final String label;
  final int percent;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final color = percent > 0
        ? c.brand
        : percent < 0
        ? c.danger
        : c.inkMuted;
    final icon = percent > 0
        ? Icons.arrow_upward_rounded
        : percent < 0
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;
    final sign = percent > 0 ? '+' : (percent < 0 ? '−' : '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BmType.meta),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            Text(
              '$sign${formatPercent(percent.abs(), lang)}',
              style: BmType.bodyStrong.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}

/// The day under the finger (the latest day until the grower touches the chart).
class _SelectedDay extends StatelessWidget {
  const _SelectedDay({required this.day, required this.rs, required this.lang});

  final PriceDay day;
  final String Function(int?) rs;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return DecoratedBox(
      key: const Key('trend-selected'),
      decoration: BoxDecoration(
        color: c.brandSoft.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BmSpace.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatDate(day.day, lang), style: BmType.meta),
                  if (day.minRsPerQuintal != null ||
                      day.maxRsPerQuintal != null)
                    Text(
                      t.marketRange(
                        rs(day.minRsPerQuintal),
                        rs(day.maxRsPerQuintal),
                      ),
                      style: BmType.meta,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rs(day.modalRsPerQuintal),
                  style: BmType.cardTitle.copyWith(color: c.brand),
                ),
                Text(t.marketPerQuintal, style: BmType.meta),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.points,
    required this.range,
    required this.today,
    required this.selected,
    required this.onSelect,
  });

  final List<PriceDay> points;
  final TrendRange range;
  final DateTime today;
  final PriceDay? selected;
  final ValueChanged<int> onSelect;

  DateTime get _start => DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: range.days));

  double _x(PriceDay p, double width) =>
      p.day.difference(_start).inHours / (range.days * 24) * width;

  void _pick(double dx, double width) {
    var best = 0;
    for (final (i, p) in points.indexed) {
      if ((_x(p, width) - dx).abs() < (_x(points[best], width) - dx).abs()) {
        best = i;
      }
    }
    onSelect(best);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        return GestureDetector(
          key: const Key('trend-chart'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _pick(d.localPosition.dx, width),
          onHorizontalDragStart: (d) => _pick(d.localPosition.dx, width),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, width),
          child: SizedBox(
            height: 180,
            width: width,
            child: CustomPaint(
              painter: _TrendPainter(
                points: points,
                xOf: (p) => _x(p, width),
                selected: selected,
                line: c.brand,
                band: c.brandSoft.withValues(alpha: 0.45),
                grid: c.line,
                cursor: c.accent,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.xOf,
    required this.selected,
    required this.line,
    required this.band,
    required this.grid,
    required this.cursor,
  });

  final List<PriceDay> points;
  final double Function(PriceDay) xOf;
  final PriceDay? selected;
  final Color line;
  final Color band;
  final Color grid;
  final Color cursor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    int low(PriceDay p) => p.minRsPerQuintal ?? p.modalRsPerQuintal;
    int high(PriceDay p) => p.maxRsPerQuintal ?? p.modalRsPerQuintal;
    var lo = points.map(low).reduce((a, b) => a < b ? a : b);
    var hi = points.map(high).reduce((a, b) => a > b ? a : b);
    if (hi == lo) {
      hi += 100;
      lo = (lo - 100).clamp(0, lo);
    }
    const pad = 8.0;
    double y(int v) =>
        size.height - pad - (v - lo) / (hi - lo) * (size.height - 2 * pad);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final gy = pad + i * (size.height - 2 * pad) / 3;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    // Min–max band and the modal line, each broken where no price was published.
    final bandPaint = Paint()..color = band;
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    var run = <PriceDay>[points.first];
    void flush() {
      if (run.length > 1) {
        final area = Path()..moveTo(xOf(run.first), y(high(run.first)));
        for (final p in run.skip(1)) {
          area.lineTo(xOf(p), y(high(p)));
        }
        for (final p in run.reversed) {
          area.lineTo(xOf(p), y(low(p)));
        }
        canvas.drawPath(area..close(), bandPaint);
        final path = Path()
          ..moveTo(xOf(run.first), y(run.first.modalRsPerQuintal));
        for (final p in run.skip(1)) {
          path.lineTo(xOf(p), y(p.modalRsPerQuintal));
        }
        canvas.drawPath(path, linePaint);
      }
    }

    for (final (i, p) in points.indexed.skip(1)) {
      if (joined(points[i - 1], p)) {
        run.add(p);
      } else {
        flush();
        run = [p];
      }
    }
    flush();
    final dot = Paint()..color = line;
    for (final p in points) {
      canvas.drawCircle(Offset(xOf(p), y(p.modalRsPerQuintal)), 2.5, dot);
    }

    if (selected case final s?) {
      final sx = xOf(s);
      canvas.drawLine(
        Offset(sx, 0),
        Offset(sx, size.height),
        Paint()
          ..color = cursor
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(sx, y(s.modalRsPerQuintal)),
        6,
        Paint()..color = cursor,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.line != line ||
      old.band != band;
}
