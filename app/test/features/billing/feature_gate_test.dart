import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/billing/domain/entitlements.dart';
import 'package:bagmitra/features/billing/presentation/feature_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const rules = EntitlementRules(always: {'records'}, graceHours: 72);

Widget gate(String feature, Entitlements e) => ProviderScope(
  overrides: [entitlementsProvider.overrideWith((ref) async => e)],
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: FeatureGate(
      feature: feature,
      locked: const Text('locked'),
      child: const Text('open'),
    ),
  ),
);

void main() {
  final snap = EntitlementSnapshot(
    features: const {'calendar': null},
    plans: const ['grower_pro'],
    computedAt: DateTime.utc(2026, 11),
    validUntil: DateTime.utc(2026, 11, 2),
  );
  final now = DateTime.utc(2026, 11, 1, 12);

  testWidgets('shows the child when the plan includes the feature', (t) async {
    await t.pumpWidget(gate('calendar', Entitlements(snap, rules, now)));
    await t.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('shows the locked widget otherwise, and the child for always', (
    t,
  ) async {
    await t.pumpWidget(gate('roster', Entitlements(snap, rules, now)));
    await t.pumpAndSettle();
    expect(find.text('locked'), findsOneWidget);
    expect(find.text('open'), findsNothing);

    await t.pumpWidget(gate('records', Entitlements(null, rules, now)));
    await t.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
