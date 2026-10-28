import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glyphs.dart';

/// What a list screen shows before its first record: a painted glyph in a soft circle,
/// an optional title, a short line saying what to do, and an optional action. Every
/// empty screen uses this so a blank page always looks and reads the same way.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.glyph,
    required this.message,
    this.title,
    this.action,
  });

  final BmGlyph glyph;
  final String? title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BmSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(BmSpace.xl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [c.nowTint, c.doneTint]),
                ),
                child: GlyphIcon(glyph),
              ),
            ),
            const SizedBox(height: BmSpace.xl),
            if (title case final title?) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: BmType.cardTitle.copyWith(color: c.brand),
              ),
              const SizedBox(height: BmSpace.xs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: BmType.body.copyWith(color: c.inkMuted),
            ),
            if (action case final action?) ...[
              const SizedBox(height: BmSpace.xl),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

/// A short "nothing here yet" line inside a page that has other content above it
/// (filters, totals). Same text style as [EmptyState]'s message.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: BmSpace.lg),
    child: Text(
      message,
      style: BmType.body.copyWith(color: context.bm.inkMuted),
    ),
  );
}
