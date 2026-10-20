import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Shows [child] when the grower's plan includes [feature], otherwise [locked]
/// (nothing by default). While the entitlements load nothing is shown, never the child.
class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    required this.feature,
    required this.child,
    this.locked = const SizedBox.shrink(),
    super.key,
  });

  final String feature;
  final Widget child;
  final Widget locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider).value;
    if (entitlements == null) return const SizedBox.shrink();
    return entitlements.has(feature) ? child : locked;
  }
}
