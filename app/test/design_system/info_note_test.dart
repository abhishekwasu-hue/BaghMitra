import 'package:bagmitra/design_system/info_note.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Owner 2026-11-10: every note that stays is in the small style and the muted ink, with no
  // icon, box or border that makes it stand out.
  for (final (name, theme, colors) in [
    ('light', BmTheme.light(), BmColors.light),
    ('dark', BmTheme.dark(), BmColors.dark),
  ]) {
    testWidgets('InfoNote is small, muted and plain ($name)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: InfoNote('A short note.')),
        ),
      );
      final text = tester.widget<Text>(find.text('A short note.'));
      expect(text.style!.fontSize, lessThanOrEqualTo(BmType.meta.fontSize!));
      expect(text.style!.color, colors.inkMuted);
      for (final type in [Icon, DecoratedBox, Container, Card]) {
        expect(
          find.descendant(
            of: find.byType(InfoNote),
            matching: find.byType(type),
          ),
          findsNothing,
          reason: '$type',
        );
      }
    });
  }
}
