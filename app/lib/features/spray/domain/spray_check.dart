/// Offline ban / PHI check for a spray record (spec M2). Mirrors the server's legal gate
/// for the facts a phone can know: gazette bans, crop restrictions and the pre-harvest
/// interval against the planned harvest date. It warns; it never blocks recording what
/// the grower actually did.
enum SprayWarningKind { banned, restrictedForCrop, phiConflict }

class SprayWarning {
  const SprayWarning(this.kind, {this.detail, this.safeFrom});
  final SprayWarningKind kind;

  /// The notification that bans / restricts the ingredient.
  final String? detail;

  /// For a PHI conflict: the first day harvest is safe.
  final DateTime? safeFrom;
}

/// How a crop appears on labels and in gazette crop groups (config, not code).
class CropRules {
  const CropRules({required this.labelAliases, required this.groups});
  final Set<String> labelAliases;
  final Set<String> groups;
}

class RestrictionRule {
  RestrictionRule({
    required String activeIngredient,
    required this.kind,
    required this.crops,
    required this.cropGroups,
    required this.notification,
    required this.effectiveFrom,
  }) : activeIngredient = normaliseName(activeIngredient);

  final String activeIngredient;

  /// banned | withdrawn | refused | restricted
  final String kind;
  final List<String> crops;
  final List<String> cropGroups;
  final String notification;
  final DateTime effectiveFrom;
}

String normaliseName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class RestrictionList {
  RestrictionList({required this.rules, this.synonyms = const {}})
    : _synonyms = {
        for (final e in synonyms.entries)
          normaliseName(e.key): normaliseName(e.value),
      };

  factory RestrictionList.empty() => RestrictionList(rules: const []);

  factory RestrictionList.fromJson(Map<String, Object?> json) =>
      RestrictionList(
        rules: [
          for (final r
              in ((json['restrictions'] as List<Object?>?) ?? const [])
                  .cast<Map<String, Object?>>())
            RestrictionRule(
              activeIngredient: r['active_ingredient']! as String,
              kind: r['kind']! as String,
              crops: ((r['crops'] as List<Object?>?) ?? const [])
                  .cast<String>(),
              cropGroups: ((r['crop_groups'] as List<Object?>?) ?? const [])
                  .cast<String>(),
              notification: r['notification']! as String,
              effectiveFrom: DateTime.parse(r['effective_from']! as String),
            ),
        ],
        synonyms: {
          for (final s
              in ((json['synonyms'] as List<Object?>?) ?? const [])
                  .cast<Map<String, Object?>>())
            s['name']! as String: s['active_ingredient']! as String,
        },
      );

  final List<RestrictionRule> rules;
  final Map<String, String> synonyms;
  final Map<String, String> _synonyms;

  String resolve(String name) {
    final n = normaliseName(name);
    return _synonyms[n] ?? n;
  }

  Map<String, Object?> toJson() => {
    'restrictions': [
      for (final r in rules)
        {
          'active_ingredient': r.activeIngredient,
          'kind': r.kind,
          'crops': r.crops,
          'crop_groups': r.cropGroups,
          'notification': r.notification,
          'effective_from': r.effectiveFrom.toUtc().toIso8601String(),
        },
    ],
    'synonyms': [
      for (final e in _synonyms.entries)
        {'name': e.key, 'active_ingredient': e.value},
    ],
  };
}

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

List<SprayWarning> checkSpray({
  required String? activeIngredient,
  required DateTime sprayedOn,
  required CropRules crop,
  required RestrictionList rules,
  int? phiDays,
  DateTime? plannedHarvest,
}) {
  final warnings = <SprayWarning>[];
  final on = _day(sprayedOn);
  final ai = (activeIngredient == null || activeIngredient.trim().isEmpty)
      ? null
      : rules.resolve(activeIngredient);
  if (ai != null) {
    for (final r in rules.rules.where((r) => r.activeIngredient == ai)) {
      if (_day(r.effectiveFrom).isAfter(on)) continue;
      if (r.kind != 'restricted') {
        warnings.add(
          SprayWarning(SprayWarningKind.banned, detail: r.notification),
        );
      } else if (r.crops.any(
            (c) => crop.labelAliases.contains(normaliseName(c)),
          ) ||
          r.cropGroups.any(crop.groups.contains)) {
        warnings.add(
          SprayWarning(
            SprayWarningKind.restrictedForCrop,
            detail: r.notification,
          ),
        );
      }
    }
  }
  if (phiDays != null && plannedHarvest != null) {
    final safeFrom = on.add(Duration(days: phiDays));
    if (safeFrom.isAfter(_day(plannedHarvest))) {
      warnings.add(
        SprayWarning(SprayWarningKind.phiConflict, safeFrom: safeFrom),
      );
    }
  }
  return warnings;
}
