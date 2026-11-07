import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';

/// The grower's own season sale package status (spec v1.5 §4E): only whether the package
/// switch is ON and the end date of each active package. Consumption-only: the app never
/// gets or shows an amount, price, UPI ID, QR, link or payment instruction.
class PackageStatus {
  const PackageStatus({required this.switchOn, this.covers = const {}});

  /// Unknown (offline, or the server said no): no chip is shown.
  static const unknown = PackageStatus(switchOn: false);

  final bool switchOn;

  /// Lot id (or null for "every lot") -> the latest end date.
  final Map<String?, DateTime> covers;

  /// When the package covering [lotId] ends; null when no package covers it.
  DateTime? untilFor(String lotId) {
    final dates = [?covers[lotId], ?covers[null]];
    if (dates.isEmpty) return null;
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

abstract interface class PackageStatusSource {
  Future<PackageStatus> load();
}

class HttpPackageStatusSource implements PackageStatusSource {
  const HttpPackageStatusSource(this._api);
  final Bagmitra _api;

  @override
  Future<PackageStatus> load() async {
    final res = await _api.v1MarketLinkPackageGet();
    final body = res.body;
    if (!res.isSuccessful || body == null) return PackageStatus.unknown;
    final covers = <String?, DateTime>{};
    for (final c in body.active) {
      final old = covers[c.lotId];
      if (old == null || c.validUntil.isAfter(old)) {
        covers[c.lotId] = c.validUntil;
      }
    }
    return PackageStatus(switchOn: body.switchOn, covers: covers);
  }
}

final packageStatusSourceProvider = Provider<PackageStatusSource>(
  (ref) => HttpPackageStatusSource(ref.watch(apiProvider)),
);

/// Loaded when "My lots" opens; any failure means "unknown" (no chip, nothing breaks).
final packageStatusProvider = FutureProvider<PackageStatus>((ref) async {
  try {
    return await ref.watch(packageStatusSourceProvider).load();
  } on Object {
    return PackageStatus.unknown;
  }
});
