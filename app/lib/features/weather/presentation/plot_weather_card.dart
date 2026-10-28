import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

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
            if (cached == null)
              Text(t.weatherNone, style: BmType.meta)
            else ...[
              Text(
                t.weatherAsOf(formatDate(cached.savedAt.toLocal(), lang)),
                style: BmType.meta,
              ),
              if (cached.weather.stale)
                Text(
                  t.weatherStale,
                  style: BmType.meta.copyWith(color: c.accentInk),
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
              for (final a in alerts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.warning_amber_rounded, color: c.accent),
                  title: Text(a.text, style: BmType.body),
                  subtitle: Text(t.weatherSource(a.source), style: BmType.meta),
                ),
              for (final a in alerts)
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
