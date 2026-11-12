import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/location_service.dart';
import '../data/place_geocoder.dart';
import '../domain/geo.dart';

/// A block's location as the grower reads it, in locale digits: "21.23050, 77.75060" in
/// English, "२१.२३०५०, ७७.७५०६०" in Marathi.
String formatLatLon(LatLon p, String languageCode) =>
    '${formatCoordinate(p.lat, languageCode)}, '
    '${formatCoordinate(p.lon, languageCode)}';

/// The nearby place as one line: "पेठ, काटोल, जि. नागपूर, महाराष्ट्र ४४१३०२" (blank parts
/// dropped, the PIN in locale digits).
String formatPlaceAddress(
  PlaceAddress a,
  AppLocalizations t,
  String languageCode,
) {
  final parts = [
    ?a.area,
    ?a.place,
    if (a.district case final d?) t.plotAddressDistrict(d),
    ?a.state,
  ];
  final pin = a.postalCode == null
      ? null
      : localDigits(a.postalCode!, languageCode);
  if (pin == null) return parts.join(', ');
  return parts.isEmpty ? pin : '${parts.join(', ')} $pin';
}

/// What the add-block form knows of the place at its point: still asking, a name, or none.
sealed class PlaceLine {
  const PlaceLine();
}

class PlaceLooking extends PlaceLine {
  const PlaceLooking();
}

class PlaceFound extends PlaceLine {
  const PlaceFound(this.address);
  final PlaceAddress address;
}

class PlaceMissing extends PlaceLine {
  const PlaceMissing();
}

/// The line under the block's point: "जवळचे ठिकाण: …", or a short note that no name was
/// found (the location is saved all the same).
class _PlaceLineText extends StatelessWidget {
  const _PlaceLineText(this.line);

  final PlaceLine line;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    return switch (line) {
      PlaceLooking() => Text(
        t.plotAddressLooking,
        key: const Key('point-address-looking'),
        style: BmType.meta.copyWith(color: c.inkMuted),
      ),
      PlaceFound(:final address) => Text(
        t.plotAddressNear(formatPlaceAddress(address, t, lang)),
        key: const Key('point-address'),
        style: BmType.body.copyWith(color: c.ink),
      ),
      PlaceMissing() => Text(
        t.plotAddressMissing,
        key: const Key('point-address-missing'),
        style: BmType.meta.copyWith(color: c.caution),
      ),
    };
  }
}

/// Taking the phone's position for a block: one settled fix, or why there is none.
mixin _PointCapture<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  var reading = false;
  LocationProblem? problem;
  LocationReading? fix;

  /// Called with each new fix.
  Future<void> onFix(LocationReading fix);

  Future<void> capture() async {
    if (reading) return;
    setState(() {
      reading = true;
      problem = null;
    });
    final r = await ref.read(locationServiceProvider).settled();
    if (!mounted) return;
    setState(() {
      reading = false;
      problem = r.problem;
      if (r.position != null) fix = r;
    });
    if (r.position != null) await onFix(r);
  }

  Future<void> openSettings() =>
      ref.read(locationServiceProvider).openSettings(problem!);

  /// The accuracy of the last fix, when [shown] is still that fix.
  double? accuracyOf(LatLon? shown) =>
      shown != null && fix?.position == shown ? fix!.accuracyM : null;
}

/// "±6 m", in the brand colour when within [PointFix.goodEnoughM], otherwise in the warm ink
/// (the grower may take it again in a more open spot).
class _Accuracy extends StatelessWidget {
  const _Accuracy(this.metres);

  final double metres;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    return Text(
      t.boundaryAccuracy(formatDecimal(metres.roundToDouble(), lang)),
      key: const Key('point-accuracy'),
      style: BmType.label.copyWith(
        color: metres <= PointFix.goodEnoughM ? c.brand : c.caution,
      ),
    );
  }
}

/// What went wrong, with the action that fixes it.
class _Problem extends StatelessWidget {
  const _Problem({
    required this.problem,
    required this.onRetry,
    required this.onSettings,
  });

  final LocationProblem problem;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final text = switch (problem) {
      LocationProblem.serviceOff => t.boundaryServiceOff,
      LocationProblem.denied => t.plotPointDenied,
      LocationProblem.deniedForever => t.boundaryDeniedForever,
      LocationProblem.failed => t.boundaryFailed,
    };
    final needsSettings =
        problem == LocationProblem.serviceOff ||
        problem == LocationProblem.deniedForever;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: BmType.body.copyWith(color: c.danger)),
        const SizedBox(height: BmSpace.xs),
        Wrap(
          spacing: BmSpace.xs,
          runSpacing: BmSpace.xs,
          children: [
            // The fix that helps is the green primary: settings when location is off.
            if (needsSettings)
              FilledButton.icon(
                key: const Key('point-settings'),
                style: BmButtonStyle.primary(c),
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
                label: Text(t.plotPointOpenSettings),
              ),
            OutlinedButton.icon(
              key: const Key('point-retry'),
              style: needsSettings ? null : BmButtonStyle.primary(c),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.plotPointTryAgain),
            ),
          ],
        ),
      ],
    );
  }
}

/// The first thing on the add-block form: the grower stands in the block and taps once. The
/// fix becomes the block's location (weather and alerts); the form is filled after.
class PointCaptureCard extends ConsumerStatefulWidget {
  const PointCaptureCard({
    required this.point,
    required this.onCaptured,
    this.place,
    super.key,
  });

  /// The block's location as the form holds it (a fix, a walked centre, or the saved one).
  final LatLon? point;
  final ValueChanged<LocationReading> onCaptured;

  /// The nearby place of [point], when the form looked it up (display only, never saved).
  final PlaceLine? place;

  @override
  ConsumerState<PointCaptureCard> createState() => _PointCaptureCardState();
}

class _PointCaptureCardState extends ConsumerState<PointCaptureCard>
    with _PointCapture {
  @override
  Future<void> onFix(LocationReading fix) async => widget.onCaptured(fix);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final point = widget.point;
    final accuracy = accuracyOf(point);
    return BmCard(
      key: const Key('point-card'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (point != null && !reading) ...[
            Row(
              children: [
                Icon(Icons.place_rounded, color: c.brand),
                const SizedBox(width: BmSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatLatLon(
                          point,
                          Localizations.localeOf(context).languageCode,
                        ),
                        key: const Key('point-value'),
                        style: BmType.bodyStrong.copyWith(color: c.ink),
                      ),
                      if (accuracy != null) _Accuracy(accuracy),
                      if (widget.place case final place?) ...[
                        const SizedBox(height: BmSpace.xxs),
                        _PlaceLineText(place),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BmSpace.xs),
            OutlinedButton.icon(
              key: const Key('point-retake'),
              onPressed: capture,
              icon: const Icon(Icons.my_location),
              label: Text(t.plotPointRetake),
            ),
          ] else
            FilledButton.icon(
              key: const Key('point-take'),
              onPressed: reading ? null : capture,
              icon: reading
                  ? const SizedBox.square(
                      dimension: BmSpace.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(reading ? t.plotPointReading : t.plotPointCapture),
            ),
          if (point == null && problem == null) ...[
            const SizedBox(height: BmSpace.xs),
            Text(
              t.plotPointWhy,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
          ],
          if (problem != null && !reading) ...[
            const SizedBox(height: BmSpace.sm),
            _Problem(
              problem: problem!,
              onRetry: capture,
              onSettings: openSettings,
            ),
            const SizedBox(height: BmSpace.xs),
            Text(
              t.plotPointLater,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The location row of a block's detail screen: the saved point and one action to take it
/// again from where the grower stands. [onCaptured] saves the new point.
class PlotLocationRow extends ConsumerStatefulWidget {
  const PlotLocationRow({
    required this.point,
    required this.onCaptured,
    super.key,
  });

  final LatLon? point;
  final Future<void> Function(LatLon point) onCaptured;

  @override
  ConsumerState<PlotLocationRow> createState() => _PlotLocationRowState();
}

class _PlotLocationRowState extends ConsumerState<PlotLocationRow>
    with _PointCapture {
  @override
  Future<void> onFix(LocationReading fix) => widget.onCaptured(fix.position!);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final point = widget.point;
    final accuracy = accuracyOf(point);
    return Padding(
      key: const Key('plot-location'),
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              t.plotLocation,
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (point != null)
                  Text(
                    formatLatLon(
                      point,
                      Localizations.localeOf(context).languageCode,
                    ),
                    key: const Key('point-value'),
                    style: BmType.bodyStrong,
                  ),
                if (accuracy != null) _Accuracy(accuracy),
                TextButton.icon(
                  key: const Key('point-retake'),
                  onPressed: reading ? null : capture,
                  icon: reading
                      ? const SizedBox.square(
                          dimension: BmSpace.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    reading
                        ? t.plotPointReading
                        : point == null
                        ? t.plotPointTake
                        : t.plotPointRetake,
                  ),
                ),
                if (problem != null && !reading)
                  _Problem(
                    problem: problem!,
                    onRetry: capture,
                    onSettings: openSettings,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
