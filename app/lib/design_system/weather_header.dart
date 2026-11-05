import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glyphs.dart';

/// Curved gradient header: greeting, avatar, and today's weather strip. The big temperature
/// and the soil pill share the first row; place, condition and max / min get their own
/// full-width line below, so they keep their text at large text sizes on narrow phones (H3).
class WeatherHeader extends StatelessWidget {
  const WeatherHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.initial,
    this.temperature,
    this.details = const [],
    this.soilPill,
    this.weatherNote,
    this.trailingAction,
    this.onAvatarTap,
    this.avatarLabel,
  });

  final String greeting;

  /// Empty when the grower gave no name: the greeting stands alone.
  final String name;

  /// Empty shows a person glyph.
  final String initial;

  /// Null when there is no weather; [weatherNote] then says how it comes.
  final String? temperature;

  /// Place, condition, max / min: joined with " · " on one full-width line.
  final List<String> details;
  final String? soilPill;
  final String? weatherNote;
  final Widget? trailingAction;

  /// Tapping the initial (e.g. to open the profile). Only a tap target: no visual change.
  final VoidCallback? onAvatarTap;
  final String? avatarLabel;

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
            if (temperature case final temp?) ...[
              Row(
                children: [
                  const GlyphIcon(BmGlyph.sunCloud, size: 52),
                  const SizedBox(width: BmSpace.sm),
                  Flexible(
                    child: Text(
                      temp,
                      style: BmType.heroNumber.copyWith(color: onBrand),
                      maxLines: 1,
                    ),
                  ),
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
