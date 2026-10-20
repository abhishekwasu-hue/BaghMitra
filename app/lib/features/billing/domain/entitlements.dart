/// What the signed snapshot from the server says this grower may use. The phone never decides
/// entitlements itself: it only reads the last snapshot and applies the offline grace margin.
class EntitlementRules {
  const EntitlementRules({required this.always, required this.graceHours});

  factory EntitlementRules.fromJson(Map<String, dynamic> json) =>
      EntitlementRules(
        always: {...(json['always'] as List<dynamic>).cast<String>()},
        graceHours: json['grace_hours'] as int,
      );

  final Set<String> always;
  final int graceHours;
}

class EntitlementSnapshot {
  const EntitlementSnapshot({
    required this.features,
    required this.plans,
    required this.computedAt,
    required this.validUntil,
  });

  factory EntitlementSnapshot.fromJson(Map<String, Object?> json) =>
      EntitlementSnapshot(
        features: {
          for (final e in (json['features']! as Map).entries)
            e.key as String: e.value as int?,
        },
        plans: [...(json['plans']! as List).cast<String>()],
        computedAt: DateTime.parse(json['computed_at']! as String),
        validUntil: DateTime.parse(json['valid_until']! as String),
      );

  /// Feature key -> limit; a null limit means unlimited.
  final Map<String, int?> features;
  final List<String> plans;
  final DateTime computedAt;
  final DateTime validUntil;

  Map<String, Object?> toJson() => {
    'features': features,
    'plans': plans,
    'computed_at': computedAt.toUtc().toIso8601String(),
    'valid_until': validUntil.toUtc().toIso8601String(),
  };

  /// Whether the snapshot may still be trusted at [now] (offline grace included).
  bool isFresh(DateTime now, EntitlementRules rules) =>
      now.isBefore(validUntil.add(Duration(hours: rules.graceHours)));
}

/// The answer the UI asks: may the grower use [feature], and up to how much?
class Entitlements {
  const Entitlements(this._snapshot, this._rules, this._now);

  final EntitlementSnapshot? _snapshot;
  final EntitlementRules _rules;
  final DateTime _now;

  bool get _usable => _snapshot != null && _snapshot.isFresh(_now, _rules);

  bool has(String feature) =>
      _rules.always.contains(feature) ||
      (_usable && _snapshot!.features.containsKey(feature));

  /// Null when unlimited, locked, or not limited at all; check [has] first.
  int? limitOf(String feature) => _usable ? _snapshot!.features[feature] : null;

  /// True when a cap exists and [used] has reached it.
  bool isAtLimit(String feature, int used) {
    final cap = limitOf(feature);
    return has(feature) && cap != null && used >= cap;
  }
}
