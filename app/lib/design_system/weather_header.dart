import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glyphs.dart';

/// The sky the header icon draws (with day or night for the current reading, Q140).
enum WeatherSky { clear, cloudy, rain, storm }

/// Curved gradient header: greeting, avatar, and today's weather strip. The big temperature
/// and the soil pill share the first row; place, condition and max / min get their own
/// full-width line below, so they keep their text at large text sizes on narrow phones (H3).
/// The big number says what it is in [temperatureLabel] ("आत्ता" with its reading time, or
/// "आज कमाल"), so a day's max is never read as the temperature now (owner Q140).
class WeatherHeader extends StatelessWidget {
  const WeatherHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.initial,
    this.temperature,
    this.temperatureLabel,
    this.temperatureTime,
    this.sky,
    this.night = false,
    this.skyLabel,
    this.details = const [],
    this.soilPill,
    this.weatherNote,
    this.trailingAction,
    this.onAvatarTap,
    this.avatarLabel,
    this.onWeatherTap,
    this.weatherTapLabel,
  });

  final String greeting;

  /// Empty when the grower gave no name: the greeting stands alone.
  final String name;

  /// Empty shows a person glyph.
  final String initial;

  /// Null when there is no weather; [weatherNote] then says how it comes.
  final String? temperature;

  /// What the big number is: "आत्ता" (now) or "आज कमाल" (today's max).
  final String? temperatureLabel;

  /// When the current reading was taken ("१८:१५ ला"); null for the max.
  final String? temperatureTime;

  /// The icon beside the number; null draws a thermometer (no sky is claimed).
  final WeatherSky? sky;

  /// After sunset: a clear sky is a moon, a cloudy one a moon behind cloud.
  final bool night;
  final String? skyLabel;

  /// Place, condition, max / min: joined with " · " on one full-width line.
  final List<String> details;
  final String? soilPill;
  final String? weatherNote;
  final Widget? trailingAction;

  /// Tapping the initial (e.g. to open the profile). Only a tap target: no visual change.
  final VoidCallback? onAvatarTap;
  final String? avatarLabel;

  /// Tapping the weather strip (e.g. to open the forecast). Only a tap target.
  final VoidCallback? onWeatherTap;
  final String? weatherTapLabel;

  Widget _weatherTappable(Widget strip) => onWeatherTap == null
      ? strip
      : Semantics(
          button: true,
          label: weatherTapLabel,
          child: GestureDetector(
            key: const Key('open-forecast'),
            behavior: HitTestBehavior.opaque,
            onTap: onWeatherTap,
            child: strip,
          ),
        );

  Widget _tappable(Widget avatar) => onAvatarTap == null
      ? avatar
      : Semantics(
          button: true,
          label: avatarLabel,
          child: GestureDetector(
            key: const Key('open-profile'),
            behavior: HitTestBehavior.opaque,
            onTap: onAvatarTap,
            child: avatar,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final onBrand = c.onBrand;
    final topInset = MediaQuery.paddingOf(context).top;
    final meta = BmType.meta.copyWith(
      color: onBrand.withValues(alpha: 0.92),
      height: 1.25,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.headerGradient,
          stops: const [0, 0.7, 1],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(BmRadius.header),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, topInset + 20, 22, 78),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: BmType.body.copyWith(
                          color: onBrand.withValues(alpha: 0.85),
                        ),
                      ),
                      if (name.isNotEmpty)
                        Text(
                          name,
                          style: BmType.title.copyWith(color: onBrand),
                        ),
                    ],
                  ),
                ),
                ?trailingAction,
                const SizedBox(width: BmSpace.xs),
                _tappable(
                  Container(
                    width: BmSpace.tapTarget,
                    height: BmSpace.tapTarget,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.sun,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: onBrand.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: initial.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            color: BmColors.light.brand,
                          )
                        : Text(
                            initial,
                            style: BmType.alertTitle.copyWith(
                              fontSize: 19,
                              color: BmColors.light.brand,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BmSpace.lg),
            _weatherTappable(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (temperature case final temp?) ...[
                    Row(
                      children: [
                        _skyIcon(c),
                        const SizedBox(width: BmSpace.sm),
                        Text(
                          temp,
                          key: const Key('weather-temperature'),
                          style: BmType.heroNumber.copyWith(color: onBrand),
                          maxLines: 1,
                        ),
                        if (temperatureLabel case final label?) ...[
                          const SizedBox(width: BmSpace.xs),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  key: const Key('weather-temperature-label'),
                                  style: BmType.label.copyWith(color: onBrand),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (temperatureTime case final time?)
                                  Text(
                                    time,
                                    key: const Key('weather-temperature-time'),
                                    style: meta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (soilPill case final pill?) _pill(c, pill),
                      ],
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details.join(' · '),
                        key: const Key('weather-details'),
                        style: meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ] else if (weatherNote case final note?)
                    Row(
                      children: [
                        const GlyphIcon(BmGlyph.sunCloud, size: 36),
                        const SizedBox(width: BmSpace.sm),
                        Expanded(child: Text(note, style: meta, maxLines: 3)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skyIcon(BmColors c) {
    const size = 52.0;
    final onBrand = c.onBrand;
    final (IconData? icon, Color colour) = switch ((sky, night)) {
      (null, _) => (Icons.thermostat_rounded, onBrand),
      (WeatherSky.clear, false) => (Icons.wb_sunny_rounded, c.sun),
      (WeatherSky.clear, true) => (Icons.nightlight_round, c.sun),
      (WeatherSky.cloudy, false) => (null, onBrand),
      (WeatherSky.cloudy, true) => (Icons.nights_stay_rounded, onBrand),
      (WeatherSky.rain, _) => (Icons.water_drop_rounded, onBrand),
      (WeatherSky.storm, _) => (Icons.thunderstorm_rounded, onBrand),
    };
    final key = Key(
      'weather-sky-${sky?.name ?? 'none'}${night ? '-night' : ''}',
    );
    return icon == null
        ? GlyphIcon(
            BmGlyph.sunCloud,
            key: key,
            size: size,
            semanticLabel: skyLabel,
          )
        : Icon(
            icon,
            key: key,
            size: size,
            color: colour,
            semanticLabel: skyLabel,
          );
  }

  Widget _pill(BmColors c, String text) {
    final onBrand = c.onBrand;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BmSpace.sm,
        vertical: BmSpace.xs,
      ),
      decoration: BoxDecoration(
        // A darkened (not lightened) pill keeps white text readable on the
        // lightest end of the header gradient.
        color: c.shadow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(BmRadius.pill),
        border: Border.all(color: onBrand.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlyphIcon(BmGlyph.drop, size: 16, color: onBrand),
          const SizedBox(width: BmSpace.xxs),
          Text(text, style: BmType.label.copyWith(color: onBrand)),
        ],
      ),
    );
  }
}
