import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A neutral note or disclaimer ("see the official page", "a source is still to be
/// checked"). Owner 2026-11-10: notes that stay are small and light, so they never alarm the
/// grower: [BmType.meta] in the muted ink, with no icon, box or border.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: BmType.meta.copyWith(color: context.bm.inkMuted));
}
