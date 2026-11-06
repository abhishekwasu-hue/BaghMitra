import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// An app bar title that never cuts a long name (a Marathi scheme or plot name, or a large
/// text size) to "…" after a few words. When it does not fit on one line it wraps to two
/// lines in a slightly smaller size, which still fits the standard bar height.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).appBarTheme.titleTextStyle ??
        DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final oneLine = TextPainter(
          text: TextSpan(text: text, style: base),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout(maxWidth: constraints.maxWidth);
        final fits = !oneLine.didExceedMaxLines;
        oneLine.dispose();
        return Text(
          text,
          maxLines: fits ? 1 : 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: fits
              ? base
              : base.copyWith(fontSize: BmType.alertTitle.fontSize),
        );
      },
    );
  }
}
