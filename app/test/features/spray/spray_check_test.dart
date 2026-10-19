import 'package:bagmitra/features/spray/domain/spray_check.dart';
import 'package:flutter_test/flutter_test.dart';

RestrictionList list() => RestrictionList(
  rules: [
    RestrictionRule(
      activeIngredient: 'dicofol',
      kind: 'banned',
      crops: const [],
      cropGroups: const [],
      notification: 'S.O. 4294(E)',
      effectiveFrom: DateTime.utc(2023, 10, 3),
    ),
    RestrictionRule(
      activeIngredient: 'chlorpyrifos',
      kind: 'restricted',
      crops: const ['citrus', 'ber'],
      cropGroups: const [],
      notification: 'CIB&RC 2020',
      effectiveFrom: DateTime.utc(2020),
    ),
    RestrictionRule(
      activeIngredient: 'dimethoate',
      kind: 'restricted',
      crops: const [],
      cropGroups: const ['fruit_eaten_raw'],
      notification: 'CIB&RC',
      effectiveFrom: DateTime.utc(2020),
    ),
  ],
  synonyms: const {'Kelthane': 'dicofol'},
);

const santra = CropRules(
  labelAliases: {'citrus', 'mandarin', 'orange'},
  groups: {'fruit_eaten_raw'},
);

List<SprayWarning> check({
  String? ai,
  DateTime? on,
  int? phi,
  DateTime? harvest,
  RestrictionList? rules,
}) => checkSpray(
  activeIngredient: ai,
  sprayedOn: on ?? DateTime.utc(2026, 11, 2),
  phiDays: phi,
  plannedHarvest: harvest,
  crop: santra,
  rules: rules ?? list(),
);

void main() {
  test('a banned ingredient is flagged, by name or trade name, any case', () {
    for (final name in ['dicofol', 'Dicofol ', 'KELTHANE']) {
      final w = check(ai: name);
      expect(w.map((e) => e.kind), [SprayWarningKind.banned], reason: name);
      expect(w.single.detail, 'S.O. 4294(E)');
    }
  });

  test('a ban is not flagged for a spray before it took effect', () {
    expect(check(ai: 'dicofol', on: DateTime.utc(2023)), isEmpty);
  });

  test('restricted applies only to the listed crops or crop groups', () {
    expect(
      check(ai: 'chlorpyrifos').single.kind,
      SprayWarningKind.restrictedForCrop,
    );
    expect(
      check(ai: 'dimethoate').single.kind,
      SprayWarningKind.restrictedForCrop,
    );
    const other = CropRules(labelAliases: {'grape'}, groups: {});
    expect(
      checkSpray(
        activeIngredient: 'chlorpyrifos',
        sprayedOn: DateTime.utc(2026, 11, 2),
        crop: other,
        rules: list(),
      ),
      isEmpty,
    );
  });

  test('PHI conflict: spray date + PHI days after the planned harvest', () {
    final harvest = DateTime.utc(2026, 11, 10);
    final w = check(ai: 'imidacloprid', phi: 15, harvest: harvest);
    expect(w.single.kind, SprayWarningKind.phiConflict);
    expect(w.single.safeFrom, DateTime.utc(2026, 11, 17));
    expect(check(ai: 'imidacloprid', phi: 8, harvest: harvest), isEmpty);
    expect(check(ai: 'imidacloprid', phi: 7, harvest: harvest), isEmpty);
    expect(check(ai: 'imidacloprid', phi: 15), isEmpty); // no harvest date
    expect(check(ai: 'imidacloprid', harvest: harvest), isEmpty); // no PHI
  });

  test('unknown or missing ingredient with no rules gives no warning', () {
    expect(check(), isEmpty);
    expect(check(ai: 'neem oil'), isEmpty);
  });

  test('the list parses from the API payload and round-trips as JSON', () {
    final parsed = RestrictionList.fromJson({
      'restrictions': [
        {
          'active_ingredient': 'Dicofol',
          'kind': 'banned',
          'crops': <String>[],
          'crop_groups': <String>[],
          'notification': 'S.O. 4294(E)',
          'effective_from': '2023-10-03T00:00:00Z',
        },
      ],
      'synonyms': [
        {'name': 'Kelthane', 'active_ingredient': 'dicofol'},
      ],
    });
    expect(parsed.rules.single.activeIngredient, 'dicofol');
    expect(RestrictionList.fromJson(parsed.toJson()).rules, hasLength(1));
    expect(
      check(ai: 'kelthane', rules: parsed).single.kind,
      SprayWarningKind.banned,
    );
  });
}
