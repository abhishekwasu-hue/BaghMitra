import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/app_update_providers.dart';
import '../domain/app_update.dart';

/// Sits above the navigator (MaterialApp.builder), so it uses no Overlay-based widgets
/// (tooltips, text selection).
///
/// Wraps every screen: a blocking screen when this APK is below the minimum version, a small
/// closable notice on top when a newer one exists, otherwise just the app.
class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  /// Closed for this run of the app; it shows again on the next start.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appUpdateProvider).value ?? AppUpdateState.none;
    final release = state.release;
    if (release == null) return widget.child;
    switch (state.need) {
      case UpdateNeed.required:
        return UpdateRequiredScreen(downloadUrl: release.downloadUrl);
      case UpdateNeed.available when !_dismissed:
        return Column(
          children: [
            UpdateBanner(
              downloadUrl: release.downloadUrl,
              onDismiss: () => setState(() => _dismissed = true),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: widget.child,
              ),
            ),
          ],
        );
      case _:
        return widget.child;
    }
  }
}

/// Opens [url] in the browser; when that fails, copies it and says so. Returns the line to
/// show under the action (null when the browser opened).
Future<String?> _download(WidgetRef ref, AppLocalizations t, String url) async {
  final opened = await ref.read(urlOpenerProvider)(Uri.parse(url));
  if (opened) return null;
  await Clipboard.setData(ClipboardData(text: url));
  return t.updateLinkCopied(url);
}

class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({
    super.key,
    required this.downloadUrl,
    required this.onDismiss,
  });

  final String downloadUrl;
  final VoidCallback onDismiss;

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  String? _note;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Material(
      color: c.brand,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const Key('update-banner'),
                  onTap: () async {
                    final note = await _download(ref, t, widget.downloadUrl);
                    if (mounted) setState(() => _note = note);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: BmSpace.tapTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BmSpace.md,
                        vertical: BmSpace.xs,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.system_update_rounded,
                                size: 20,
                                color: c.onBrand,
                              ),
                              const SizedBox(width: BmSpace.xs),
                              Expanded(
                                child: Text(
                                  t.updateAvailable,
                                  style: BmType.label.copyWith(
                                    color: c.onBrand,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_note case final note?)
                            Padding(
                              padding: const EdgeInsets.only(top: BmSpace.xxs),
                              child: Text(
                                note,
                                key: const Key('update-link-note'),
                                style: BmType.meta.copyWith(color: c.onBrand),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // No tooltip: this sits above the navigator, outside any Overlay.
              Semantics(
                label: t.updateDismiss,
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  key: const Key('update-banner-close'),
                  icon: Icon(Icons.close_rounded, color: c.onBrand),
                  onPressed: widget.onDismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpdateRequiredScreen extends ConsumerStatefulWidget {
  const UpdateRequiredScreen({super.key, required this.downloadUrl});

  final String downloadUrl;

  @override
  ConsumerState<UpdateRequiredScreen> createState() =>
      _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends ConsumerState<UpdateRequiredScreen> {
  String? _note;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Scaffold(
      key: const Key('update-required'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BmSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.system_update_rounded, size: 64, color: c.brand),
                const SizedBox(height: BmSpace.lg),
                Text(
                  t.updateRequiredTitle,
                  style: BmType.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: BmSpace.sm),
                Text(
                  t.updateRequiredBody,
                  style: BmType.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: BmSpace.xl),
                FilledButton.icon(
                  key: const Key('update-download'),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(t.updateDownload),
                  onPressed: () async {
                    final note = await _download(ref, t, widget.downloadUrl);
                    if (mounted) setState(() => _note = note);
                  },
                ),
                if (_note case final note?) ...[
                  const SizedBox(height: BmSpace.md),
                  Text(
                    note,
                    key: const Key('update-link-note'),
                    style: BmType.meta,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
