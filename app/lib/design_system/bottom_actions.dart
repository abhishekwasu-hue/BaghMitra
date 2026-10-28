import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The pinned strip at the bottom of a screen that holds its main action (Save, Add …).
/// Every list and form puts its main button here, so it is always in the same place and
/// in reach of the thumb. Pass it as `Scaffold.bottomNavigationBar`.
///
/// One child fills the width; several sit side by side (or stacked with [stacked]).
class BottomActions extends StatelessWidget {
  const BottomActions({
    super.key,
    required this.children,
    this.stacked = false,
  });

  final List<Widget> children;
  final bool stacked;

  /// Side-by-side outlined and filled buttons get the same height as the main button.
  static const double actionHeight = 56;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        BmSpace.lg,
        BmSpace.xs,
        BmSpace.lg,
        BmSpace.md,
      ),
      child: stacked || children.length == 1
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const SizedBox(height: BmSpace.xs),
                  SizedBox(height: actionHeight, child: child),
                ],
              ],
            )
          : Row(
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const SizedBox(width: BmSpace.sm),
                  Expanded(
                    child: SizedBox(height: actionHeight, child: child),
                  ),
                ],
              ],
            ),
    ),
  );
}
