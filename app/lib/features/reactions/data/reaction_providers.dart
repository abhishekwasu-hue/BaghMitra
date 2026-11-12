import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/reaction.dart';
import 'reaction_server.dart';
import 'reaction_store.dart';

/// The demo build has no backend: reactions stay in memory there. Tests override this.
final reactionServerProvider = Provider<ReactionServer>(
  (ref) => ref.watch(appConfigProvider).demoMode
      ? DemoReactionServer()
      : ApiReactionServer(ref.watch(apiProvider)),
);

final reactionStoreProvider = Provider<ReactionStore>(
  (ref) => ReactionStore(
    ref.watch(databaseProvider),
    ref.watch(reactionServerProvider),
  ),
);

/// What the bar shows for one target, from the phone's copy. Invalidate after a tap or a
/// refresh.
final reactionViewProvider = FutureProvider.family<ReactionView, String>(
  (ref, target) async =>
      (await ref.watch(reactionStoreProvider).load()).view(target),
);

/// Reactions tapped offline go once the app starts online (never in demo mode).
final reactionStartupProvider = FutureProvider<void>((ref) async {
  if (ref.watch(appConfigProvider).demoMode) return;
  await ref.read(reactionStoreProvider).flush();
});
