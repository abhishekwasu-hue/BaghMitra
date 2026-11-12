import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../design_system/sync_banner.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../sync_engine.dart';

/// The writes the server turned down, oldest first (see [SyncEngine.watchRejected]).
final rejectedWritesProvider = StreamProvider<List<OutboxEntry>>(
  (ref) => ref.watch(syncEngineProvider).watchRejected(),
);

/// The sync strip for a screen, or null when everything is sent. Signed out comes first
/// (nothing syncs until then), then offline, server unavailable, entries to check and
/// entries still waiting. A test build with no backend says where the data lives instead.
Widget? buildSyncStatusBanner(BuildContext context, WidgetRef ref) {
  final t = AppLocalizations.of(context);
  final config = ref.watch(appConfigProvider);
  if (config.demoMode && config.isTestBuild) {
    return SyncBanner(kind: SyncBannerKind.offline, message: t.localModeBanner);
  }
  final s = ref.watch(syncStatusProvider).value;
  if (s == null) return null;
  switch (s.connectivity) {
    case Connectivity.signedOut:
      return SyncBanner(
        key: const Key('sync-banner-signed-out'),
        kind: SyncBannerKind.signedOut,
        message: t.syncSignedOutBanner,
        actionLabel: t.signInAgain,
        onAction: () => unawaited(ref.read(authRepositoryProvider).signOut()),
      );
    case Connectivity.offline:
      return SyncBanner(
        key: const Key('sync-banner-offline'),
        kind: SyncBannerKind.offline,
        message: t.offlineBanner,
      );
    case Connectivity.serverError:
      return SyncBanner(
        key: const Key('sync-banner-server'),
        kind: SyncBannerKind.server,
        message: t.syncServerBanner,
      );
    case Connectivity.unknown || Connectivity.online:
      break;
  }
  if (s.rejected > 0) {
    return SyncBanner(
      key: const Key('sync-banner-rejected'),
      kind: SyncBannerKind.failed,
      message: t.syncRejectedBanner(s.rejected),
      actionLabel: t.syncReview,
      onAction: () => unawaited(showRejectedWritesSheet(context)),
    );
  }
  if (s.pending > 0) {
    return SyncBanner(
      key: const Key('sync-banner-pending'),
      kind: SyncBannerKind.pending,
      message: t.pendingSync(s.pending),
    );
  }
  return null;
}

/// [buildSyncStatusBanner] as a widget (nothing when everything is sent).
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      buildSyncStatusBanner(context, ref) ?? const SizedBox.shrink();
}

/// Lists the turned-down entries in plain words, each with "send again" and "delete".
Future<void> showRejectedWritesSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const RejectedWritesSheet(),
    );

class RejectedWritesSheet extends ConsumerWidget {
  const RejectedWritesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final entries = ref.watch(rejectedWritesProvider).value ?? const [];
    final engine = ref.watch(syncEngineProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          0,
          BmSpace.lg,
          BmSpace.lg,
        ),
        child: Column(
          key: const Key('rejected-writes-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.syncRejectedTitle,
              style: BmType.section.copyWith(color: c.brand),
            ),
            const SizedBox(height: BmSpace.xs),
            if (entries.isEmpty)
              Text(t.syncRejectedDone, style: BmType.body)
            else ...[
              Text(t.syncRejectedHelp, style: BmType.meta),
              const SizedBox(height: BmSpace.sm),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in entries)
                      _RejectedRow(
                        key: Key('rejected-${e.id}'),
                        title: t.syncEntryName(e.entity),
                        when: formatDateTime(e.clientUpdatedAt.toLocal(), lang),
                        onResend: () => unawaited(engine.resendRejected(e.id)),
                        onDelete: () => unawaited(engine.deleteRejected(e.id)),
                        resendLabel: t.syncResend,
                        deleteLabel: t.syncDelete,
                        entryId: e.id,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RejectedRow extends StatelessWidget {
  const _RejectedRow({
    super.key,
    required this.title,
    required this.when,
    required this.onResend,
    required this.onDelete,
    required this.resendLabel,
    required this.deleteLabel,
    required this.entryId,
  });

  final String title;
  final String when;
  final VoidCallback onResend;
  final VoidCallback onDelete;
  final String resendLabel;
  final String deleteLabel;
  final String entryId;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: BmType.bodyStrong),
          Text(when, style: BmType.meta),
          Wrap(
            spacing: BmSpace.xs,
            children: [
              FilledButton.tonal(
                key: Key('rejected-resend-$entryId'),
                onPressed: onResend,
                child: Text(resendLabel),
              ),
              TextButton(
                key: Key('rejected-delete-$entryId'),
                style: BmButtonStyle.destructive(c),
                onPressed: onDelete,
                child: Text(deleteLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
