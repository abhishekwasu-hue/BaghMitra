import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/market_link.dart';
import 'market_link_store.dart';

final marketLinkStoreProvider = Provider<MarketLinkStore>(
  (ref) => MarketLinkStore(ref.watch(databaseProvider), ref.watch(apiProvider)),
);

/// The current terms: the phone's copy answers first (works offline); once per app run,
/// online and signed in, the server is asked and this is read again when anything changed.
final marketTermsProvider = FutureProvider<MarketTerms>((ref) async {
  final store = ref.watch(marketLinkStoreProvider);
  final user = ref.watch(sessionProvider).value?.userId;
  if (user != null && !store.synced && !ref.watch(appConfigProvider).demoMode) {
    unawaited(
      store.sync(user).then((changed) {
        if (changed) ref.invalidateSelf();
      }),
    );
  }
  return store.terms();
});

/// Whether the signed-in user accepted the current terms for [role] (spec v1.5 §4C).
final marketRoleAcceptedProvider = FutureProvider.family<bool, MarketRole>((
  ref,
  role,
) async {
  final user = ref.watch(sessionProvider).value?.userId;
  if (user == null) return false;
  await ref.watch(marketTermsProvider.future);
  return ref.watch(marketLinkStoreProvider).isAccepted(user, role);
});

/// The role whose home `/` opens; null until a role card was picked on this phone.
final activeMarketRoleProvider =
    AsyncNotifierProvider<ActiveMarketRole, MarketRole?>(ActiveMarketRole.new);

class ActiveMarketRole extends AsyncNotifier<MarketRole?> {
  @override
  Future<MarketRole?> build() =>
      ref.watch(marketLinkStoreProvider).activeRole();

  Future<void> choose(MarketRole role) async {
    await ref.read(marketLinkStoreProvider).setActiveRole(role);
    state = AsyncData(role);
  }
}
