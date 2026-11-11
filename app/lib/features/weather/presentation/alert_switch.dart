import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/alert_banner.dart';
import '../../../l10n/app_localizations.dart';

/// The short name of a risk rule (`api/src/bagmitra_api/risk/rules.json`), for the line
/// that stays when its alerts are switched off; null for a rule the app does not know yet.
String? alertShortName(AppLocalizations t, String ruleKey) => switch (ruleKey) {
  'heat_fruit_drop' => t.alertNameHeat,
  'psylla_degree_days' => t.alertNamePsylla,
  'hail_thunderstorm' => t.alertNameHail,
  'high_wind_gust' => t.alertNameWind,
  'heavy_rain' => t.alertNameHeavyRain,
  'unseasonal_rain' => t.alertNameUnseasonalRain,
  'cold_wave' => t.alertNameColdWave,
  'high_humidity' => t.alertNameHumidity,
  _ => null,
};

/// "सायला अलर्ट बंद", or "हा अलर्ट बंद" for a rule with no short name.
String alertOffLabel(AppLocalizations t, String ruleKey) =>
    switch (alertShortName(t, ruleKey)) {
      final name? => t.alertTypeOff(name),
      null => t.alertThisOff,
    };

/// Switches every alert of [ruleKey] on or off on this phone (home and plot card).
Future<void> switchAlert(WidgetRef ref, String ruleKey, {required bool on}) =>
    ref.read(alertSwitchesProvider).setOn(ruleKey, on: on);

/// The muted line of a switched-off alert type, with its "switch on" button. Keys:
/// `<keyPrefix>-off-<rule>` (the line) and `<keyPrefix>-on-<rule>` (the button).
class SwitchedOffAlert extends ConsumerWidget {
  const SwitchedOffAlert({
    required this.ruleKey,
    required this.keyPrefix,
    super.key,
  });

  final String ruleKey;
  final String keyPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return AlertOffLine(
      key: Key('$keyPrefix-off-$ruleKey'),
      toggleKey: Key('$keyPrefix-on-$ruleKey'),
      label: alertOffLabel(t, ruleKey),
      toggleLabel: t.alertSwitchOn,
      onToggle: () => switchAlert(ref, ruleKey, on: true),
    );
  }
}
