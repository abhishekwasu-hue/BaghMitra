import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/glyphs.dart';
import '../design_system/navigation.dart';
import '../features/home/presentation/home_screen.dart' show openForPlot;
import '../features/plots/domain/plot.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

/// The tab shell (audit M3): the bottom bar stays on the three top-level pages (home, the
/// blocks, the practices guide) and each keeps its own scroll and state. हिशोब is per
/// block, so it opens the accounts of the grower's block above the shell, as before.
/// Detail pages open above the shell, full screen, with a back arrow.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Bar position of each branch: home, बाग, (हिशोब is an action), विचारा.
  static const branchOfItem = [0, 1, null, 2];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final plots = ref.watch(plotsProvider).value ?? const <Plot>[];
    final selected = branchOfItem.indexOf(shell.currentIndex);
    return PopScope(
      // Back on another tab returns to home first; back on home leaves the app.
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: BmBottomBar(
          items: [
            BmNavItem(BmGlyph.home, t.navHome),
            BmNavItem(BmGlyph.orchard, t.navOrchard),
            BmNavItem(BmGlyph.ledger, t.navAccounts),
            BmNavItem(BmGlyph.mic, t.navAsk),
          ],
          selected: selected,
          onSelect: (i) {
            final branch = branchOfItem[i];
            if (branch == null) {
              openForPlot(context, plots, Routes.accounts);
              return;
            }
            // A second tap on the open tab brings it back to its first page.
            shell.goBranch(
              branch,
              initialLocation: branch == shell.currentIndex,
            );
          },
          cameraLabel: t.takePhoto,
          // A scouting record with a photo, for the grower's block.
          onCamera: () => openForPlot(context, plots, Routes.addScouting),
          onCameraLongPress: config.devGallery
              ? () => context.push(Routes.gallery)
              : null,
        ),
      ),
    );
  }
}
