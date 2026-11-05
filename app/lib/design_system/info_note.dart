import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A neutral note or disclaimer ("check this at the office", "not verified yet"): an (i)
/// icon and text in the [BmColors.info] ink. Orange stays for actions only (audit M5).
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.style});

  final String text;

  /// The text style before the info colour is applied; [BmType.meta] when not given.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    final base = style ?? BmType.meta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ExcludeSemantics(
            child: Icon(
              Icons.info_outline_rounded,
              size: (base.fontSize ?? 14) + 4,
              color: c.info,
            ),
          ),
        ),
        const SizedBox(width: BmSpace.xs),
        Expanded(
          child: Text(text, style: base.copyWith(color: c.info)),
        ),
      ],
    );
  }
}
