import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [offline]: no network; [server]: the server is unavailable; [signedOut]: sign in again;
/// [failed]: entries the server turned down wait for the grower's choice.
enum SyncBannerKind { offline, server, signedOut, pending, failed }

/// Compact status strip shown only when something is not synced, with an optional action
/// (sign in again, review the turned-down entries).
class SyncBanner extends StatelessWidget {
  const SyncBanner({
    super.key,
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final SyncBannerKind kind;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final (bg, fg, icon) = switch (kind) {
      SyncBannerKind.offline => (c.ink, c.background, Icons.cloud_off_rounded),
      SyncBannerKind.server => (c.ink, c.background, Icons.cloud_sync_rounded),
      SyncBannerKind.signedOut => (c.nowTint, c.warnTitle, Icons.login_rounded),
      SyncBannerKind.pending => (
        c.nowTint,
        c.warnTitle,
        Icons.cloud_upload_rounded,
      ),
      SyncBannerKind.failed => (
        c.danger,
        c.onBrand,
        Icons.sync_problem_rounded,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: BmSpace.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BmRadius.chip),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: BmSpace.xs),
            Expanded(
              child: Text(
                message,
                style: BmType.label.copyWith(color: fg, fontSize: 14),
              ),
            ),
            if (actionLabel case final label? when onAction != null)
              TextButton(
                key: const Key('sync-banner-action'),
                style: TextButton.styleFrom(foregroundColor: fg),
                onPressed: onAction,
                child: Text(
                  label,
                  style: BmType.bodyStrong.copyWith(color: fg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
