import 'package:flutter/widgets.dart';

import '../domain/market_link_role.dart';

/// Wraps every market-link screen for [role].
///
/// L1 HOOK (spec v1.5 §4C, milestone L1): the terms / privacy / 18+ / disclaimer acceptance
/// screen plugs in here, so no market-link screen opens before the user has accepted it.
/// Until L1 lands this shows the screen as it is.
class MarketLinkEntry extends StatelessWidget {
  const MarketLinkEntry({required this.role, required this.child, super.key});

  final MarketLinkRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
