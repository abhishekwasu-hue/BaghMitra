import '../../../api/generated/bagmitra.swagger.dart' show MarketPriceOut;
import '../../bahar/data/bahar_catalog.dart';
import '../../bahar/domain/bahar_cycle.dart';
import '../../market/data/market_prices_cache.dart';
import '../../plots/domain/plot.dart';
import '../../profile/domain/farmer_profile.dart';
import '../../weather/data/plot_weather_cache.dart';
import '../domain/home_snapshot.dart';

/// Builds "today's orchard" only from what the grower has on this phone: the profile name,
/// the first plot (by name, as the plots list and the market screen order them), its
/// planned / active bahar with the grower's own stage dates, the saved weather and alerts
/// for that plot, and the saved mandi prices for its crop. Nothing is estimated: a block
/// with no data is left null and the screen shows its empty state instead.
HomeSnapshot buildLocalHomeSnapshot({
  required FarmerProfile? profile,
  required List<Plot> plots,
  required List<BaharCycle> cycles,
  required BaharCatalogData? catalog,
  required CachedWeather? weather,
  required bool weatherLoading,
  required CachedMarketPrices? prices,
  required DateTime today,
  required String lang,
  required String Function(double acres) acresLabel,
}) {
  final plot = plots.firstOrNull;
  final located = plot?.centroidLat != null && plot?.centroidLon != null;
  final day = _dateOnly(today);
  final forecast = weather?.weather.days
      .where((d) => !_dateOnly(d.day).isBefore(day) && d.tMaxC != null)
      .firstOrNull;
  final alert = weather?.weather.alerts.firstOrNull;
  return HomeSnapshot(
    farmerName: profile?.displayName?.trim() ?? '',
    plotId: plot?.id,
    weather: plot == null || forecast == null
        ? null
        : WeatherNow(
            place: plot.name,
            tempC: forecast.tMaxC!.round(),
            minC: forecast.tMinC?.round(),
          ),
    weatherNote: plot == null || forecast != null || weatherLoading
        ? null
        : located
        ? WeatherNote.notYetLoaded
        : WeatherNote.needsLocation,
    alert: alert == null
        ? null
        : RiskAlert(
            title: alert.text,
            source: alert.source,
            firstDay: alert.firstDay,
          ),
    stage: plot == null || catalog == null
        ? null
        : _stage(plot, cycles, catalog, day, lang, acresLabel),
    market: plot == null ? null : _quote(prices?.prices.prices),
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

StageKind _kindOf(String key) => switch (key) {
  'stress_start' => StageKind.stress,
  'flowering' => StageKind.flowering,
  'fruit_set' => StageKind.fruitSet,
  'harvest' => StageKind.harvest,
  _ => StageKind.fruitGrowth,
};

/// The bahar in progress (else the planned one) of [plot], newest season first.
BaharCycle? currentCycle(Plot plot, List<BaharCycle> cycles) {
  final open = [
    for (final c in cycles)
      if (c.plotId == plot.id &&
          (c.status == 'active' || c.status == 'planned'))
        c,
  ];
  open.sort((a, b) {
    final byStatus = (a.status == 'active' ? 0 : 1).compareTo(
      b.status == 'active' ? 0 : 1,
    );
    return byStatus != 0 ? byStatus : b.seasonYear.compareTo(a.seasonYear);
  });
  return open.firstOrNull;
}

StageSummary? _stage(
  Plot plot,
  List<BaharCycle> cycles,
  BaharCatalogData catalog,
  DateTime today,
  String lang,
  String Function(double acres) acresLabel,
) {
  final cycle = currentCycle(plot, cycles);
  if (cycle == null) return null;
  final stages = catalog.stages;
  // The grower's own dates: what happened, else what they planned.
  final dates = [
    for (final s in stages)
      switch (cycle.actual[s.key] ?? cycle.planned[s.key]) {
        final DateTime d => _dateOnly(d),
        null => null,
      },
  ];
  final start = (dates.nonNulls.toList()..sort()).firstOrNull;
  final n = stages.length;
  // Nodes are spaced evenly so their labels stay readable on a narrow phone; the bar
  // moves between two nodes in step with the grower's dates.
  double position(int i) => n < 2 ? 0 : i / (n - 1);
  var current = -1;
  for (var i = 0; i < n; i++) {
    if (dates[i] case final d? when !d.isAfter(today)) current = i;
  }
  int? next;
  for (var i = 0; i < n; i++) {
    if (dates[i] case final d? when d.isAfter(today)) {
      if (next == null || d.isBefore(dates[next]!)) next = i;
    }
  }
  final harvestIndex = stages.indexWhere((s) => s.key == 'harvest');
  final reached = start != null && !start.isAfter(today);
  return StageSummary(
    tag: [
      catalog.baharLabel(cycle.bahar, lang),
      plot.name,
      acresLabel(plot.areaAcres),
    ].join(' · '),
    currentName: current >= 0
        ? stages[current].label(lang)
        : catalog.baharLabel(cycle.bahar, lang),
    day: reached ? _daysBetween(start, today) : null,
    milestones: [
      for (final (i, s) in stages.indexed)
        StageMilestone(
          kind: _kindOf(s.key),
          label: s.label(lang),
          position: position(i),
        ),
    ],
    currentIndex: current,
    progress: _progress(current, dates, today, position),
    nextName: next == null ? null : stages[next].label(lang),
    nextInDays: next == null ? null : _daysBetween(today, dates[next]!),
    // When harvest is itself the next stage, its day count already says it.
    harvestMonth: harvestIndex < 0 || next == harvestIndex
        ? null
        : dates[harvestIndex],
  );
}

/// How far along the bar is: at the node reached last, plus the share of the days to the
/// following node when that one has a date.
double _progress(
  int current,
  List<DateTime?> dates,
  DateTime today,
  double Function(int) position,
) {
  if (current < 0) return 0;
  final here = position(current);
  if (current + 1 >= dates.length) return here;
  final from = dates[current]!;
  final to = dates[current + 1];
  if (to == null || !to.isAfter(today)) return here;
  final share = _daysBetween(from, today) / _daysBetween(from, to);
  return here + (position(current + 1) - here) * share.clamp(0.0, 1.0);
}

/// The newest saved price, from a local market when one is listed.
MarketQuote? _quote(List<MarketPriceOut>? prices) {
  if (prices == null || prices.isEmpty) return null;
  final local = prices.where((p) => p.isLocal).toList();
  final pool = local.isNotEmpty ? local : prices;
  final newest = pool.reduce((a, b) => b.day.isAfter(a.day) ? b : a);
  return MarketQuote(
    market: newest.market,
    pricePerQuintal: newest.modalRsPerQuintal,
    grade: newest.grade ?? newest.variety,
    day: newest.day,
  );
}
