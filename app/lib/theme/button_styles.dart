import 'package:flutter/material.dart';

import 'tokens.dart';

/// The button roles (docs/design/buttons-audit.md). The theme gives every button its
/// look, so screens only pick a widget:
///
/// | Role | Widget | Look |
/// |---|---|---|
/// | Main commit of a screen (Save, Add, Send; dialog confirm) | `FilledButton` | santra fill, dark ink, bold, 56 dp |
/// | Primary action inside a card or section (see the practices, try again) | `FilledButton` + [BmButtonStyle.primary] | brand-green fill, bold, 48 dp |
/// | Secondary action | `OutlinedButton`, `TextButton` | green tint fill, visible green border, bold |
/// | Destructive (delete, hide) | any button + [BmButtonStyle.destructive] | calm amber tint, caution ink |
/// | Icon-only (speak, share, copy) | `IconButton` + [BmButtonStyle.icon] | tonal circle, tooltip, 48 dp |
/// | Link that opens a page | `TextButton` + [BmButtonStyle.link] | link colour, underlined |
abstract final class BmButtonStyle {
  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(BmRadius.tile),
  );

  static const _minimum = Size(BmSpace.tapTarget, BmSpace.tapTarget);
  static const _padding = EdgeInsets.symmetric(horizontal: BmSpace.md);

  /// Green filled: the one main action of a card or section.
  static ButtonStyle primary(BmColors c) => FilledButton.styleFrom(
    backgroundColor: c.primaryFill,
    foregroundColor: c.onPrimaryFill,
    iconColor: c.onPrimaryFill,
    side: BorderSide(color: c.primaryFill, width: 1.5),
    minimumSize: _minimum,
    padding: _padding,
    textStyle: BmType.button,
    shape: _shape,
  );

  /// Tonal: a green tint with a visible border. The theme of `OutlinedButton` and
  /// `TextButton`.
  static ButtonStyle secondary(BmColors c) {
    bool off(Set<WidgetState> states) => states.contains(WidgetState.disabled);
    final fg = WidgetStateProperty.resolveWith(
      (states) => off(states) ? c.inkMuted : c.onSecondaryFill,
    );
    return ButtonStyle(
      foregroundColor: fg,
      iconColor: fg,
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => off(states) ? c.line : c.secondaryFill,
      ),
      overlayColor: WidgetStatePropertyAll(
        c.onSecondaryFill.withValues(alpha: 0.12),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: off(states) ? c.line : c.secondaryBorder,
          width: 1.5,
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(_minimum),
      padding: const WidgetStatePropertyAll(_padding),
      textStyle: WidgetStatePropertyAll(BmType.button),
      shape: WidgetStatePropertyAll(_shape),
    );
  }

  /// Calm destructive: a soft amber tint and caution ink, never an alarming red fill.
  static ButtonStyle destructive(BmColors c) {
    bool off(Set<WidgetState> states) => states.contains(WidgetState.disabled);
    final fg = WidgetStateProperty.resolveWith(
      (states) => off(states) ? c.inkMuted : c.caution,
    );
    return ButtonStyle(
      foregroundColor: fg,
      iconColor: fg,
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => off(states) ? c.line : c.warnBg.first,
      ),
      overlayColor: WidgetStatePropertyAll(c.caution.withValues(alpha: 0.12)),
      side: WidgetStateProperty.resolveWith(
        (states) =>
            BorderSide(color: off(states) ? c.line : c.warnBorder, width: 1.5),
      ),
      minimumSize: const WidgetStatePropertyAll(_minimum),
      padding: const WidgetStatePropertyAll(_padding),
      textStyle: WidgetStatePropertyAll(BmType.button),
      shape: WidgetStatePropertyAll(_shape),
    );
  }

  /// Icon-only action: a filled tonal circle, 48 dp. Pair it with a tooltip.
  static ButtonStyle icon(BmColors c) => IconButton.styleFrom(
    backgroundColor: c.secondaryFill,
    foregroundColor: c.onSecondaryFill,
    side: BorderSide(color: c.secondaryBorder, width: 1.5),
    minimumSize: _minimum,
    shape: const CircleBorder(),
  );

  /// Icon-only main action (call): a green filled circle, 48 dp.
  static ButtonStyle iconPrimary(BmColors c) => IconButton.styleFrom(
    backgroundColor: c.primaryFill,
    foregroundColor: c.onPrimaryFill,
    minimumSize: _minimum,
    shape: const CircleBorder(),
  );

  /// A link that opens a page or copies its address: link colour, underlined, no fill.
  static ButtonStyle link(BmColors c) => TextButton.styleFrom(
    foregroundColor: c.link,
    iconColor: c.link,
    backgroundColor: Colors.transparent,
    side: BorderSide.none,
    minimumSize: _minimum,
    padding: const EdgeInsets.symmetric(horizontal: BmSpace.xs),
    textStyle: BmType.bodyStrong.copyWith(decoration: TextDecoration.underline),
  );
}
