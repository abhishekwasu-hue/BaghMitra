import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../app/refresh.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/refresh_note.dart';
import '../../../theme/app_theme.dart';
import '../../voice/presentation/share_speak_buttons.dart';
import '../data/plot_weather_cache.dart';
import 'alert_switch.dart';
import 'weather_forecast_screen.dart' show forecastDays;

/// The next days for a plot and the rule-based risk alerts, each with its source. Shows the
/// last saved answer offline; alerts never carry chemical advice (they come from the API).
/// A storm / hail / heavy-rain alert links to the claim kit ("take loss photos now").
class PlotWeatherCard extends ConsumerWidget {
  const PlotWeatherCard({required this.plotId, super.key});

  final String plotId;

  static const _daysShown = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.watch(clockProvider)();
    final cached = ref.watch(plotWeatherProvider((plotId, lang))).value;
    String deg(double? v) => v == null ? '–' : '${formatInt(v.round(), lang)}°';

    final days = [
      for (final d in cached?.weather.days ?? const <WeatherDay>[])
        if (!d.day.isBefore(DateTime(today.year, today.month, today.day))) d,
    ].take(_daysShown);
    final alerts = cached?.weather.alerts ?? const <WeatherAlert>[];
    // Alert types switched off on this phone: one muted line each (Q133).
    final off = ref.watch(alertsOffProvider).value ?? const <String>{};
    final shown = [
      for (final a in alerts)
        if (!off.contains(a.ruleKey)) a,
    ];

    return Card(
      key: const Key('plot-weather'),
      child: Padding(
        padding: const EdgeInsets.all(BmSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.weatherTitle,
              style: BmType.section.copyWith(color: c.brand),
            ),
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
            if (cached != null) ...[
              if (cached.weather.stale)
                Text(
                  t.weatherStale,
                  style: BmType.meta.copyWith(color: c.caution),
                ),
              for (final d in days)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(formatDate(d.day, lang), style: BmType.body),
                  subtitle: (d.precipMm ?? 0) > 0
                      ? Text(
                          t.weatherRain(formatDecimal(d.precipMm!, lang)),
                          style: BmType.meta,
                        )
                      : null,
                  trailing: Text(
                    '${deg(d.tMaxC)} / ${deg(d.tMinC)}',
                    style: BmType.bodyStrong,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('weather-forecast-link'),
                  onPressed: () => context.push(Routes.weatherForecast(plotId)),
                  icon: const Icon(Icons.calendar_view_week_rounded),
                  label: Text(
                    t.weatherForecastNext(formatInt(forecastDays, lang)),
                  ),
                ),
              ),
              for (final ruleKey in {
                for (final a in alerts)
                  if (off.contains(a.ruleKey)) a.ruleKey,
              })
                SwitchedOffAlert(ruleKey: ruleKey, keyPrefix: 'weather-alert'),
              for (final a in shown)
                ListTile(
                  key: Key('weather-alert-${a.ruleKey}'),
                  contentPadding: EdgeInsets.zero,
                  // The ⚠ is the on / off button for this alert type (Q133).
                  leading: IconButton(
                    key: Key('weather-alert-toggle-${a.ruleKey}'),
                    tooltip: t.alertSwitchOff,
                    onPressed: () => switchAlert(ref, a.ruleKey, on: false),
                    icon: Icon(Icons.warning_amber_rounded, color: c.caution),
                  ),
                  title: Text(a.text, style: BmType.body),
                  subtitle: Text(t.weatherSource(a.source), style: BmType.meta),
                  trailing: ShareSpeakButtons(
                    keyPrefix: 'weather-alert-${a.ruleKey}',
                    shareText: weatherAlertShareText(
                      t,
                      a,
                      lang,
                      ref.watch(appConfigProvider).productName,
                    ),
                    speakText: weatherAlertShareText(t, a, lang, null),
                  ),
                ),
              for (final a in shown)
                if (a.action == 'claim_kit')
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: Key('alert-claim-kit-${a.ruleKey}'),
                      onPressed: () => context.push(Routes.newClaimKit(plotId)),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(t.claimKitFromAlert),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What sharing a risk alert hands on: the day it starts, the alert as the API wrote it
/// (never chemical advice), its source and, unless [productName] is null (read aloud), where
/// it came from.
String weatherAlertShareText(
  AppLocalizations t,
  WeatherAlert alert,
  String lang,
  String? productName,
) => [
  '${formatDate(alert.firstDay, lang)}: ${alert.text}',
  t.shareSource(alert.source),
  if (productName != null) shareFooter(t, productName),
].join('\n');
