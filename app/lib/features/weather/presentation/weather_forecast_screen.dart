import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../app/refresh.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/refresh_note.dart';
import '../../../theme/app_theme.dart';
import '../data/plot_weather_cache.dart';

/// Days the forecast covers (owner, Q134); the API pulls this many forecast days.
const forecastDays = 15;

/// Max temperature shown in the caution ink: the threshold of the API's heat rule
/// (`heat_fruit_drop` in api/.../risk/rules.json).
const forecastHeatC = 35.0;

/// A chance of rain from this many per cent (or any rain amount) shows in the info ink.
const forecastRainLikelyPct = 50.0;

/// "Weather forecast" for one block (Q134): the next [forecastDays] days of the cached plot
/// weather as a table, one row per day. Numbers only, no advice; rain expected and strong
/// heat are coloured by meaning. Offline it shows the saved days and when they were saved.
class WeatherForecastScreen extends ConsumerWidget {
  const WeatherForecastScreen({required this.plotId, super.key});

  final String plotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final plot = ref
        .watch(plotsProvider)
        .value
        ?.where((p) => p.id == plotId)
        .firstOrNull;
    final appBar = AppBar(title: AppBarTitle(t.weatherForecastTitle));
    if (plot == null) return Scaffold(appBar: appBar);
    final located = plot.centroidLat != null && plot.centroidLon != null;
    final cached = located
        ? ref.watch(plotWeatherProvider((plotId, lang))).value
        : null;
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (final d in cached?.weather.days ?? const <WeatherDay>[])
        if (!d.day.isBefore(today)) d,
    ].take(forecastDays).toList();

    return Scaffold(
      appBar: appBar,
      body: RefreshIndicator(
        onRefresh: () => ref.read(refresherProvider).plotWeather(plotId, lang),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            BmSpace.sm,
            BmSpace.md,
            BmSpace.sm,
            BmSpace.xl,
          ),
          children: [
            Text(
              '${plot.name} · '
              '${t.weatherForecastNext(formatInt(forecastDays, lang))}',
              style: BmType.bodyStrong.copyWith(color: c.brand),
            ),
            if (!located)
              Text(t.homeWeatherNeedsLocation, style: BmType.meta)
            else ...[
              if (cached == null) Text(t.weatherNone, style: BmType.meta),
              RefreshNote(
                cacheKey: PlotWeatherCache.keyFor(plotId, lang),
                updated: cached == null
                    ? null
                    : t.weatherAsOf(
                        formatDateTime(cached.savedAt.toLocal(), lang),
                      ),
                onRetry: () =>
                    ref.read(refresherProvider).plotWeather(plotId, lang),
              ),
              if (cached?.weather.stale ?? false)
                Text(
                  t.weatherStale,
                  style: BmType.meta.copyWith(color: c.caution),
                ),
              if (days.isNotEmpty) ...[
                const SizedBox(height: BmSpace.xs),
                _Legend(days: days, lang: lang),
                const SizedBox(height: BmSpace.xs),
                BmCard(
                  padding: const EdgeInsets.all(BmSpace.xs),
                  radius: BmRadius.tile,
                  elevated: false,
                  child: _ForecastTable(days: days, lang: lang),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

bool _rainLikely(WeatherDay d) =>
    (d.precipMm ?? 0) > 0 || (d.rainProbPct ?? 0) >= forecastRainLikelyPct;

bool _hot(WeatherDay d) =>
    (d.tMaxC ?? double.negativeInfinity) >= forecastHeatC;

String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

class _ForecastTable extends StatelessWidget {
  const _ForecastTable({required this.days, required this.lang});

  final List<WeatherDay> days;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final head = BmType.label.copyWith(color: c.inkMuted);
    final muted = BmType.meta.copyWith(color: c.inkMuted);
    String num(double? v, String Function(int) f) =>
        v == null ? '–' : f(v.round());
    String deg(double? v) => num(v, (n) => '${formatInt(n, lang)}°');
    String pct(double? v) => num(v, (n) => formatPercent(n, lang));

    Widget cell(Widget child, {bool end = true}) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BmSpace.xxs,
        vertical: BmSpace.xs,
      ),
      child: Align(
        alignment: end ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
    Widget header(String title, String unit) =>
        cell(Text('$title\n$unit', style: head, textAlign: TextAlign.end));
    Widget pair(Text top, Text bottom) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [top, bottom],
    );

    TableRow row(WeatherDay d) {
      final id = _iso(d.day);
      final rain = _rainLikely(d);
      final rainInk = rain ? c.info : null;
      return TableRow(
        key: ValueKey('forecast-tr-$id'),
        children: [
          cell(
            KeyedSubtree(
              key: ValueKey('forecast-row-$id'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatWeekday(d.day, lang),
                    key: Key('forecast-day-$id'),
                    style: BmType.bodyStrong,
                  ),
                  Text(
                    formatDayMonth(d.day, lang),
                    key: Key('forecast-date-$id'),
                    style: muted,
                  ),
                ],
              ),
            ),
            end: false,
          ),
          cell(_SkyIcon(code: d.weatherCode), end: false),
          cell(
            pair(
              Text(
                deg(d.tMaxC),
                key: Key('forecast-max-$id'),
                style: BmType.bodyStrong.copyWith(
                  color: _hot(d) ? c.caution : c.ink,
                ),
              ),
              Text(deg(d.tMinC), key: Key('forecast-min-$id'), style: muted),
            ),
          ),
          cell(
            pair(
              Text(
                d.precipMm == null ? '–' : formatDecimal(d.precipMm!, lang),
                key: Key('forecast-rain-mm-$id'),
                style: BmType.bodyStrong.copyWith(color: rainInk ?? c.ink),
              ),
              Text(
                pct(d.rainProbPct),
                key: Key('forecast-rain-prob-$id'),
                style: rain
                    ? muted.copyWith(color: c.info, fontWeight: FontWeight.w700)
                    : muted,
              ),
            ),
          ),
          cell(
            Text(
              num(d.windGustKmh, (n) => formatInt(n, lang)),
              key: Key('forecast-wind-$id'),
              style: BmType.bodyStrong,
            ),
          ),
          cell(
            Text(
              pct(d.rhMeanPct),
              key: Key('forecast-rh-$id'),
              style: BmType.bodyStrong,
            ),
          ),
        ],
      );
    }

    return Table(
      key: const Key('forecast-table'),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      // Day and sky keep their content width; the four number columns (flex, the
      // default) share the rest
      // equally, and their header words wrap first, so the table never runs off the screen.
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
      },
      border: TableBorder(horizontalInside: BorderSide(color: c.line)),
      children: [
        TableRow(
          children: [
            cell(Text(t.weatherColDay, style: head), end: false),
            const SizedBox.shrink(),
            header(t.weatherColTemp, t.weatherUnitTemp),
            header(t.weatherColRain, t.weatherUnitRain),
            header(t.weatherColWind, t.weatherUnitWind),
            header(t.weatherColHumidity, '%'),
          ],
        ),
        for (final d in days) row(d),
      ],
    );
  }
}

/// The sky of the day from its WMO code: sun, cloud, rain or thunderstorm.
class _SkyIcon extends StatelessWidget {
  const _SkyIcon({required this.code});

  final double? code;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final code = this.code;
    if (code == null) return Text('–', style: BmType.body);
    final (icon, colour, label) = switch (code) {
      >= 95 => (Icons.thunderstorm_rounded, c.danger, t.weatherSkyStorm),
      >= 51 => (Icons.water_drop_rounded, c.info, t.weatherSkyRain),
      >= 2 => (Icons.cloud_rounded, c.inkMuted, t.weatherSkyCloudy),
      _ => (Icons.wb_sunny_rounded, c.caution, t.weatherSkyClear),
    };
    return Icon(icon, size: 24, color: colour, semanticLabel: label);
  }
}

/// What the two colours mean, each shown only when a day in the table has it.
class _Legend extends StatelessWidget {
  const _Legend({required this.days, required this.lang});

  final List<WeatherDay> days;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    Widget item(Color colour, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: BmSpace.xxs),
        Flexible(
          child: Text(text, style: BmType.meta.copyWith(color: colour)),
        ),
      ],
    );
    return Wrap(
      spacing: BmSpace.md,
      runSpacing: BmSpace.xxs,
      children: [
        if (days.any(_rainLikely)) item(c.info, t.weatherLegendRain),
        if (days.any(_hot))
          item(
            c.caution,
            t.weatherLegendHeat(formatInt(forecastHeatC.round(), lang)),
          ),
      ],
    );
  }
}
