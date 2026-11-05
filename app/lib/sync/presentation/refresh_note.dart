import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/refresh.dart';
import '../../core/net_failure.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// The small "updated <time>" line under a cache-first list, and, when the last fetch of
/// [cacheKey] failed, what to do next with one action: try again (offline / server busy) or
/// sign in again (session ended). The saved copy stays on screen either way.
class RefreshNote extends ConsumerWidget {
  const RefreshNote({
    super.key,
    required this.cacheKey,
    required this.updated,
    required this.onRetry,
  });

  final String cacheKey;

  /// The localized "updated …" line, or null when nothing is saved yet.
  final String? updated;
  final Future<void> Function() onRetry;

  static String failureText(AppLocalizations t, NetFailure f) => switch (f) {
    NetFailure.offline => t.refreshOffline,
    NetFailure.server => t.refreshServer,
    NetFailure.signedOut => t.netSignedOut,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final state = ref.watch(refreshStateProvider(cacheKey));
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (updated case final line?)
          Text(line, key: const Key('refresh-updated'), style: BmType.meta),
        if (failure != null)
          Row(
            key: const Key('refresh-failure'),
            children: [
              Expanded(
                child: Text(
                  failureText(t, failure),
                  style: BmType.meta.copyWith(color: c.caution),
                ),
              ),
              if (failure == NetFailure.signedOut)
                TextButton(
                  key: const Key('refresh-sign-in'),
                  onPressed: () =>
                      unawaited(ref.read(authRepositoryProvider).signOut()),
                  child: Text(t.signInAgain),
                )
              else
                TextButton(
                  key: const Key('refresh-retry'),
                  onPressed: state.busy ? null : () => unawaited(onRetry()),
                  child: Text(t.netRetry),
                ),
            ],
          ),
      ],
    );
  }
}
