// The only place in the app where raw colour values may appear.
// See docs/design/DESIGN_SYSTEM.md. Enforced by test/architecture/no_inline_colors_test.dart.
import 'package:flutter/material.dart';

/// Raw brand palette, taken from docs/design/reference/home_mockup.html.
abstract final class BmPalette {
  static const leaf = Color(0xFF1F4D2B);
  static const leaf2 = Color(0xFF2E6B3C);
  static const leaf3 = Color(0xFF9BC79A);
  static const leafGlow = Color(0xFF3F8A4F);
  static const santra = Color(0xFFF28C28);
  static const santra2 = Color(0xFFFFB15C);

  /// Santra deepened until it reads as text on cream/white in sunlight (≥ 4.5:1).
  static const santraDeep = Color(0xFFA34A06);
  static const sun = Color(0xFFFFC857);
  static const soil = Color(0xFF6B4A2B);
  static const sky = Color(0xFFCFE8F3);
  static const cream = Color(0xFFF3F7EE);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B2A1E);
  static const ink2 = Color(0xFF4E6153);
  static const line = Color(0xFFE3EAD9);
  static const alert = Color(0xFFD64545);
  static const alertWarmBg1 = Color(0xFFFFF3E6);
  static const alertWarmBg2 = Color(0xFFFFE7CC);
  static const alertWarmBorder = Color(0xFFF7C98F);
  static const alertWarmTitle = Color(0xFF8A4B06);
  static const alertWarmBody = Color(0xFF5E4225);
  static const doneTint = Color(0xFFEEF6EC);

  /// Secondary-button fill: a leaf tint that still reads as green on cream and white.
  static const leafTint = Color(0xFFD4EBCF);

  /// Neutral notes and disclaimers: a calm slate-sky ink, never santra (orange = action).
  static const infoInk = Color(0xFF2C5A70);
  static const nowTint = Color(0xFFFFF1E2);

  // Dark mode: deep night-orchard greens; accents stay recognisably santra.
  static const night = Color(0xFF0F1A12);
  static const nightCard = Color(0xFF18271B);
  static const nightLine = Color(0xFF2A3D2E);
  static const nightInk = Color(0xFFE8F0E3);
  static const nightInk2 = Color(0xFFA9BCA9);
  static const nightAlertBg1 = Color(0xFF3A2610);
  static const nightAlertBg2 = Color(0xFF2E1E0D);
  static const nightAlertBorder = Color(0xFF7A4B16);
  static const nightAlertTitle = Color(0xFFFFC27A);
  static const nightAlertBody = Color(0xFFE9D3B8);
  static const nightDoneTint = Color(0xFF213826);
  static const nightInfoInk = Color(0xFFA9D2E4);
  static const nightNowTint = Color(0xFF3A2610);
  static const shadow = Color(0xFF1F4D2B);

  // Reading tones (article sections, highlights): an ink and a soft tint per meaning.
  static const leafReadTint = Color(0xFFE3F1DF);
  static const skyReadTint = Color(0xFFE1F0F7);
  static const tealInk = Color(0xFF0E5E5A);
  static const tealReadTint = Color(0xFFDDF2EF);
  static const violetInk = Color(0xFF5B4A8A);
  static const violetReadTint = Color(0xFFEEEAF7);
  static const greyReadTint = Color(0xFFEEF1EC);
  static const nightSkyTint = Color(0xFF1B3340);
  static const nightTealInk = Color(0xFF8FD8CF);
  static const nightTealTint = Color(0xFF163A36);
  static const nightVioletInk = Color(0xFFC9B8F0);
  static const nightVioletTint = Color(0xFF2E2745);
  static const nightGreyTint = Color(0xFF223026);
}

/// One reading tone: [ink] for an icon, a heading accent or a highlighted word, [tint] for
/// its chip, header strip or pill. [ink] is ≥ 4.5:1 on [tint] and on the card.
@immutable
class BmTone {
  const BmTone(this.ink, this.tint);

  final Color ink;
  final Color tint;
}

/// Semantic colours. Widgets use these, never [BmPalette] directly.
@immutable
class BmColors extends ThemeExtension<BmColors> {
  const BmColors({
    required this.background,
    required this.card,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
    required this.onAccent,
    required this.info,
    required this.caution,
    required this.sun,
    required this.soil,
    required this.sky,
    required this.danger,
    required this.onBrand,
    required this.headerGradient,
    required this.warnBg,
    required this.warnBorder,
    required this.warnTitle,
    required this.warnBody,
    required this.doneTint,
    required this.nowTint,
    required this.shadow,
    required this.accentEdge,
    required this.primaryFill,
    required this.onPrimaryFill,
    required this.secondaryFill,
    required this.secondaryBorder,
    required this.onSecondaryFill,
    required this.link,
    required this.toneGreen,
    required this.toneBlue,
    required this.toneTeal,
    required this.toneAmber,
    required this.toneViolet,
    required this.toneGrey,
  });

  final Color background;
  final Color card;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color brand;
  final Color brandStrong;
  final Color brandSoft;
  final Color accent;
  final Color accentSoft;

  /// Accent used as text on actions (the camera label) and the stage hero number:
  /// santra is too light for text on cream in sunlight, so light mode deepens it.
  /// Orange means action: notes use [info], deadlines and warnings use [caution].
  final Color accentInk;

  /// Text and icons on an [accent] fill (the main santra buttons). White on santra is
  /// only 2.4:1, so this is dark ink.
  final Color onAccent;

  /// Text and icon of a neutral note or disclaimer ("check this at the office").
  final Color info;

  /// Text and icon of a deadline, stale data or a warning line (amber, as the warning
  /// banner's title).
  final Color caution;
  final Color sun;
  final Color soil;
  final Color sky;
  final Color danger;
  final Color onBrand;
  final List<Color> headerGradient;
  final List<Color> warnBg;
  final Color warnBorder;
  final Color warnTitle;
  final Color warnBody;
  final Color doneTint;
  final Color nowTint;
  final Color shadow;

  /// Edge of a santra (main commit) button: santra alone is 2.3:1 on cream / white, the
  /// deepened edge keeps the button's shape ≥ 3:1 against the page.
  final Color accentEdge;

  /// Fill of a primary action inside a card or section (open the practices, try again):
  /// the brand green, so it stands out on the page and the card in both modes.
  /// The screen's main commit (Save, Add, Send) stays santra ([accent]).
  final Color primaryFill;

  /// Text and icon on [primaryFill] (≥ 4.5:1).
  final Color onPrimaryFill;

  /// Tonal fill and border of a secondary action: a green tint plus a visible border,
  /// never a hairline outline on the page colour.
  final Color secondaryFill;
  final Color secondaryBorder;

  /// Text and icon on [secondaryFill] (≥ 4.5:1).
  final Color onSecondaryFill;

  /// A link inside text (underlined); never a button.
  final Color link;

  /// Reading tones for article sections by meaning (docs/design/buttons-audit.md, article
  /// reading): do / green, when / blue, check / teal, see / amber, caution / violet (calm,
  /// never red), sources / grey.
  final BmTone toneGreen;
  final BmTone toneBlue;
  final BmTone toneTeal;
  final BmTone toneAmber;
  final BmTone toneViolet;
  final BmTone toneGrey;

  static const light = BmColors(
    background: BmPalette.cream,
    card: BmPalette.white,
    ink: BmPalette.ink,
    inkMuted: BmPalette.ink2,
    line: BmPalette.line,
    brand: BmPalette.leaf,
    brandStrong: BmPalette.leaf2,
    brandSoft: BmPalette.leaf3,
    accent: BmPalette.santra,
    accentSoft: BmPalette.santra2,
    accentInk: BmPalette.santraDeep,
    onAccent: BmPalette.ink,
    info: BmPalette.infoInk,
    caution: BmPalette.alertWarmTitle,
    sun: BmPalette.sun,
    soil: BmPalette.soil,
    sky: BmPalette.sky,
    danger: BmPalette.alert,
    onBrand: BmPalette.white,
    headerGradient: [BmPalette.leaf, BmPalette.leaf2, BmPalette.leafGlow],
    warnBg: [BmPalette.alertWarmBg1, BmPalette.alertWarmBg2],
    warnBorder: BmPalette.alertWarmBorder,
    warnTitle: BmPalette.alertWarmTitle,
    warnBody: BmPalette.alertWarmBody,
    doneTint: BmPalette.doneTint,
    nowTint: BmPalette.nowTint,
    shadow: BmPalette.shadow,
    accentEdge: BmPalette.santraDeep,
    primaryFill: BmPalette.leaf,
    onPrimaryFill: BmPalette.white,
    secondaryFill: BmPalette.leafTint,
    secondaryBorder: BmPalette.leaf2,
    onSecondaryFill: BmPalette.leaf,
    link: BmPalette.leaf2,
    toneGreen: BmTone(BmPalette.leaf, BmPalette.leafReadTint),
    toneBlue: BmTone(BmPalette.infoInk, BmPalette.skyReadTint),
    toneTeal: BmTone(BmPalette.tealInk, BmPalette.tealReadTint),
    toneAmber: BmTone(BmPalette.alertWarmTitle, BmPalette.alertWarmBg1),
    toneViolet: BmTone(BmPalette.violetInk, BmPalette.violetReadTint),
    toneGrey: BmTone(BmPalette.ink2, BmPalette.greyReadTint),
  );

  static const dark = BmColors(
    background: BmPalette.night,
    card: BmPalette.nightCard,
    ink: BmPalette.nightInk,
    inkMuted: BmPalette.nightInk2,
    line: BmPalette.nightLine,
    brand: BmPalette.leaf3,
    brandStrong: BmPalette.leaf3,
    brandSoft: BmPalette.leaf2,
    accent: BmPalette.santra,
    accentSoft: BmPalette.santra2,
    accentInk: BmPalette.santra,
    onAccent: BmPalette.ink,
    info: BmPalette.nightInfoInk,
    caution: BmPalette.nightAlertTitle,
    sun: BmPalette.sun,
    soil: BmPalette.soil,
    sky: BmPalette.sky,
    danger: BmPalette.alert,
    onBrand: BmPalette.white,
    headerGradient: [BmPalette.night, BmPalette.leaf, BmPalette.leaf2],
    warnBg: [BmPalette.nightAlertBg1, BmPalette.nightAlertBg2],
    warnBorder: BmPalette.nightAlertBorder,
    warnTitle: BmPalette.nightAlertTitle,
    warnBody: BmPalette.nightAlertBody,
    doneTint: BmPalette.nightDoneTint,
    nowTint: BmPalette.nightNowTint,
    shadow: BmPalette.night,
    accentEdge: BmPalette.santra,
    primaryFill: BmPalette.leaf3,
    onPrimaryFill: BmPalette.ink,
    secondaryFill: BmPalette.leaf2,
    secondaryBorder: BmPalette.leaf3,
    onSecondaryFill: BmPalette.nightInk,
    link: BmPalette.leaf3,
    toneGreen: BmTone(BmPalette.leaf3, BmPalette.nightDoneTint),
    toneBlue: BmTone(BmPalette.nightInfoInk, BmPalette.nightSkyTint),
    toneTeal: BmTone(BmPalette.nightTealInk, BmPalette.nightTealTint),
    toneAmber: BmTone(BmPalette.nightAlertTitle, BmPalette.nightAlertBg1),
    toneViolet: BmTone(BmPalette.nightVioletInk, BmPalette.nightVioletTint),
    toneGrey: BmTone(BmPalette.nightInk2, BmPalette.nightGreyTint),
  );

  /// Market hero card stays deep green in both modes (one hero colour per card).
  Color get heroCard => BmPalette.leaf;

  @override
  BmColors copyWith() => this;

  @override
  BmColors lerp(BmColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

abstract final class BmSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;

  /// Minimum tap target (spec §4A: 48 dp).
  static const double tapTarget = 48;
}

abstract final class BmRadius {
  static const double chip = 12;
  static const double tile = 18;
  static const double card = 22;
  static const double hero = 24;
  static const double header = 40;
  static const double pill = 999;
}

abstract final class BmFonts {
  static const display = 'Baloo2';
  static const body = 'Mukta';
}

/// Type scale. Body never goes below 16 sp (spec §4A); small labels are reserved for
/// secondary metadata and are never the only carrier of meaning.
abstract final class BmType {
  static const _display = TextStyle(fontFamily: BmFonts.display, height: 1.1);
  static const _body = TextStyle(fontFamily: BmFonts.body, height: 1.35);

  static final heroNumber = _display.copyWith(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1,
  );
  static final bigNumber = _display.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1,
  );
  static final money = _display.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1,
  );
  static final title = _display.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w800,
  );
  static final cardTitle = _display.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  static final section = _display.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static final alertTitle = _display.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  static final bodyStrong = _body.copyWith(
    fontSize: 16.5,
    fontWeight: FontWeight.w600,
  );
  static final body = _body.copyWith(fontSize: 16, fontWeight: FontWeight.w400);

  /// The question above a group of chips or fields ("Which crop?"). It carries meaning,
  /// so it keeps the 16 sp body minimum instead of the small [label] size.
  static final formLabel = _body.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Every button label: bold, so an action never reads as plain text.
  static final button = _body.copyWith(
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
  );
  static final meta = _body.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
  static final label = _body.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}

abstract final class BmElevation {
  static List<BoxShadow> card(BmColors c) => [
    BoxShadow(
      color: c.shadow.withValues(alpha: 0.10),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> tile(BmColors c) => [
    BoxShadow(
      color: c.shadow.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> fab(BmColors c) => [
    BoxShadow(
      color: c.accent.withValues(alpha: 0.45),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

abstract final class BmMotion {
  static const quick = Duration(milliseconds: 180);
  static const gentle = Duration(milliseconds: 320);
  static const pulse = Duration(milliseconds: 1400);
}
