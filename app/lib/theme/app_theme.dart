import 'package:flutter/material.dart';

import 'tokens.dart';

export 'tokens.dart';

abstract final class BmTheme {
  static ThemeData light() => _build(BmColors.light, Brightness.light);
  static ThemeData dark() => _build(BmColors.dark, Brightness.dark);

  static ThemeData _build(BmColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.brand,
      brightness: brightness,
      primary: c.brand,
      secondary: c.accent,
      surface: c.card,
      error: c.danger,
    );
    final text = TextTheme(
      displayLarge: BmType.heroNumber,
      headlineMedium: BmType.title,
      titleLarge: BmType.cardTitle,
      titleMedium: BmType.section,
      bodyLarge: BmType.body,
      bodyMedium: BmType.body,
      labelLarge: BmType.bodyStrong,
      labelMedium: BmType.label,
      bodySmall: BmType.meta,
    ).apply(bodyColor: c.ink, displayColor: c.ink);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: BmFonts.body,
      textTheme: text,
      extensions: [c],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BmRadius.tile),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BmRadius.tile),
          borderSide: BorderSide(color: c.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BmRadius.tile),
          borderSide: BorderSide(color: c.brandStrong, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BmSpace.md,
          vertical: BmSpace.md,
        ),
      ),
      // One app bar for every screen: page-coloured, brand title, no tint when scrolled.
      // Screens set only the title and actions.
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: c.background,
        foregroundColor: c.brand,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: BmType.section.copyWith(color: c.brand),
        iconTheme: IconThemeData(color: c.brand),
        actionsIconTheme: IconThemeData(color: c.brand),
      ),
      // Choices look the same on every form: santra tint and border when picked.
      chipTheme: ChipThemeData(
        selectedColor: c.nowTint,
        checkmarkColor: c.ink,
        labelStyle: BmType.bodyStrong.copyWith(color: c.ink),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected) ? c.accent : c.line,
            width: 1.5,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BmRadius.chip),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          // Dark ink on santra: white on santra is 2.4:1 and washes out in sunlight.
          foregroundColor: c.onAccent,
          iconColor: c.onAccent,
          minimumSize: const Size.fromHeight(56),
          textStyle: BmType.alertTitle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BmRadius.tile),
          ),
        ),
      ),
      // Secondary actions: same shape and text as the main button, 48 dp tall at least.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.brand,
          minimumSize: const Size(BmSpace.tapTarget, BmSpace.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: BmSpace.md),
          textStyle: BmType.bodyStrong,
          side: BorderSide(color: c.brandStrong, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BmRadius.tile),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brandStrong,
          minimumSize: const Size(BmSpace.tapTarget, BmSpace.tapTarget),
          textStyle: BmType.bodyStrong,
        ),
      ),
    );
  }
}

extension BmThemeContext on BuildContext {
  BmColors get bm => Theme.of(this).extension<BmColors>()!;
}
