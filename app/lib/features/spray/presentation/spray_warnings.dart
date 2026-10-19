import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/spray_check.dart';

/// Crop label aliases and gazette crop groups for a plot's crop, from config.
CropRules cropRulesFor(WidgetRef ref, String? cropSlug) {
  final crop = ref
      .watch(cropsProvider)
      .value
      ?.where((c) => c.slug == cropSlug)
      .firstOrNull;
  return CropRules(
    labelAliases: {
      for (final a in crop?.labelAliases ?? const <String>[]) normaliseName(a),
    },
    groups: {...?crop?.groups},
  );
}

(String, String) warningText(AppLocalizations t, SprayWarning w, String lang) =>
    switch (w.kind) {
      SprayWarningKind.banned => (
        t.sprayWarnBannedTitle,
        t.sprayWarnBannedBody(w.detail ?? ''),
      ),
      SprayWarningKind.restrictedForCrop => (
        t.sprayWarnRestrictedTitle,
        t.sprayWarnRestrictedBody(w.detail ?? ''),
      ),
      SprayWarningKind.phiConflict => (
        t.sprayWarnPhiTitle,
        t.sprayWarnPhiBody(formatDate(w.safeFrom!, lang)),
      ),
    };
