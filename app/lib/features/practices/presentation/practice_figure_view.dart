import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/practice_cards.dart';

part 'symptom_figures_a.dart';
part 'symptom_figures_b.dart';
part 'symptom_figures_c.dart';

/// A drawing of how a practice is done, or of what a disease looks like (owner 2026-11-09):
/// simple shapes painted in the theme's colours, labelled in the app language with locale
/// digits, and read out as one sentence for TalkBack. Works offline (nothing to download).
class PracticeFigureView extends StatelessWidget {
  const PracticeFigureView({
    super.key,
    required this.figure,
    required this.lang,
  });

  final PracticeFigure figure;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final n = [for (final v in figure.values) formatInt(v, lang)];
    final labels = _labels(t, n);
    final tall = figure.kind == PracticeFigureKind.gummosisTrunk;
    return Semantics(
      label: labels.join(', '),
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BmRadius.tile),
        child: AspectRatio(
          aspectRatio: tall ? 320 / 250 : 320 / 170,
          child: CustomPaint(
            painter: _FigurePainter(
              figure.kind,
              labels,
              [formatInt(1, lang), formatInt(2, lang)],
              _Palette(
                sky: c.sky.withValues(alpha: 0.35),
                soil: c.soil,
                soilDark: Color.lerp(c.soil, BmPalette.ink, 0.45)!,
                bark: Color.lerp(c.soil, c.ink, 0.25)!,
                leaf: c.brand,
                leafSick: c.sun,
                water: BmPalette.sky,
                gum: c.accent,
                danger: c.danger,
                ink: c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The words drawn on the figure, in the order the painter uses them.
  List<String> _labels(
    AppLocalizations t,
    List<String> n,
  ) => switch (figure.kind) {
    PracticeFigureKind.gummosisTrunk => [
      t.figureGum,
      t.figureWetPatches,
      t.figureBarkPeels,
      t.figureYellowLeaves,
    ],
    PracticeFigureKind.drainageTrench => [
      t.figureWidthCm(n[0]),
      t.figureDepthCm(n[1]),
      t.figureDrainsAway,
    ],
    PracticeFigureKind.doubleRing => [
      t.figureDry,
      t.figureWaterHere,
      t.figureTopView,
      if (n.isNotEmpty) t.figureInnerRingCm(n[0]),
    ],
    PracticeFigureKind.pruneCut => [
      t.figureDeadPart,
      t.figureCutHere,
      t.figureHealthyCm(n[0]),
    ],
    PracticeFigureKind.rootSun => [
      t.figureSunDays(n[0], n[1]),
      t.figureCutRotten,
    ],
    PracticeFigureKind.barkStrip => [t.figureWithBand, t.figureDiseasedBark],
    PracticeFigureKind.twiceYearly => [
      t.figureRains,
      t.figureBeforeRains,
      t.figureAfterRains,
    ],
    PracticeFigureKind.stickyTrap => [
      t.figureYellowTrap,
      t.figureHeightM(n[0]),
    ],
    PracticeFigureKind.budHeight => [
      t.figureBudUnion,
      t.figureHeightRangeCm(n[0], n[1]),
    ],
    PracticeFigureKind.trunkBand => [t.figureStickyBand(n[0]), t.figureAnts],
    PracticeFigureKind.lureTrap => [
      t.figureLureTrap,
      t.figureRenewDays(n[0], n[1]),
    ],
    PracticeFigureKind.shadySide => [t.figureShadyFirst, t.figureSunnySide],
    PracticeFigureKind.openCanopy => [t.figureOpenCentre, t.figureCutCrowded],
    PracticeFigureKind.manureRing => [t.figureRootZone, t.figureManureHere],
    PracticeFigureKind.cankerSpots => [
      t.figCankerSpots,
      t.figCankerHalo,
      t.figCankerFruit,
    ],
    PracticeFigureKind.mildewLeaf => [t.figMildewPowder, t.figMildewCurl],
    PracticeFigureKind.anthracnoseLeaf => [
      t.figAnthPatch,
      t.figAnthDots,
      t.figAnthTwig,
    ],
    PracticeFigureKind.greeningLeaf => [t.figGreeningLeaf, t.figGreeningFruit],
    PracticeFigureKind.psyllaShoot => [
      t.figPsyllaNymphs,
      t.figPsyllaThreads,
      t.figPsyllaCurl,
    ],
    PracticeFigureKind.aphidShoot => [t.figAphidColony, t.figAphidCup],
    PracticeFigureKind.mealybugTwig => [t.figMealyClusters, t.figSootyMould],
    PracticeFigureKind.leafMinerLeaf => [t.figMinerMines, t.figMinerDistort],
    PracticeFigureKind.mitesLeaf => [
      t.figMitesVeins,
      t.figMitesWeb,
      t.figMitesRind,
    ],
    PracticeFigureKind.thripsFruit => [t.figThripsRing, t.figThripsPatches],
    PracticeFigureKind.heatDropTree => [t.figHeatSummer, t.figHeatDrop],
  };
}

class _Palette {
  const _Palette({
    required this.sky,
    required this.soil,
    required this.soilDark,
    required this.bark,
    required this.leaf,
    required this.leafSick,
    required this.water,
    required this.gum,
    required this.danger,
    required this.ink,
  });

  final Color sky,
      soil,
      soilDark,
      bark,
      leaf,
      leafSick,
      water,
      gum,
      danger,
      ink;
  static const onSoil = BmPalette.white;

  /// Dark text on the light water colour, in both themes.
  static const onWater = BmPalette.ink;
}

/// Paints in a 320-wide coordinate space scaled to the widget, like the design sample.
class _FigurePainter extends CustomPainter {
  _FigurePainter(this.kind, this.labels, this.marks, this.p);

  final PracticeFigureKind kind;
  final List<String> labels;

  /// Step numbers in locale digits.
  final List<String> marks;
  final _Palette p;

  late Canvas _c;
  late double _k;

  Paint _fill(Color color) => Paint()..color = color;

  Paint _line(Color color, double w) => Paint()
    ..color = color
    ..strokeWidth = w * _k
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  Offset _o(double x, double y) => Offset(x * _k, y * _k);

  Rect _r(double x, double y, double w, double h) =>
      Rect.fromLTWH(x * _k, y * _k, w * _k, h * _k);

  void _text(
    String s,
    double x,
    double y, {
    Color? color,
    bool bold = false,
    TextAlign align = TextAlign.left,
    double maxWidth = 150,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: BmType.body.fontFamily,
          fontSize: 12.5 * _k,
          height: 1.15,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? p.ink,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth * _k);
    final dx = switch (align) {
      TextAlign.center => tp.width / 2,
      TextAlign.right => tp.width,
      _ => 0.0,
    };
    tp.paint(_c, Offset(x * _k - dx, y * _k));
  }

  void _tree(double x, double top, double ground, {double r = 38}) {
    _c.drawRect(_r(x - 6, top + 10, 12, ground - top - 10), _fill(p.bark));
    _c.drawOval(_r(x - r, top - r * 0.75, r * 2, r * 1.5), _fill(p.leaf));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    _k = size.width / 320;
    canvas.drawRect(Offset.zero & size, _fill(p.sky));
    switch (kind) {
      case PracticeFigureKind.gummosisTrunk:
        _trunk();
      case PracticeFigureKind.drainageTrench:
        _trench();
      case PracticeFigureKind.doubleRing:
        _ring();
      case PracticeFigureKind.pruneCut:
        _prune();
      case PracticeFigureKind.rootSun:
        _roots();
      case PracticeFigureKind.barkStrip:
        _bark();
      case PracticeFigureKind.twiceYearly:
        _twice();
      case PracticeFigureKind.stickyTrap:
        _stickyTrap();
      case PracticeFigureKind.budHeight:
        _budHeight();
      case PracticeFigureKind.trunkBand:
        _trunkBand();
      case PracticeFigureKind.lureTrap:
        _lureTrap();
      case PracticeFigureKind.shadySide:
        _shadySide();
      case PracticeFigureKind.openCanopy:
        _openCanopy();
      case PracticeFigureKind.manureRing:
        _manureRing();
      case PracticeFigureKind.cankerSpots:
        _cankerSpots();
      case PracticeFigureKind.mildewLeaf:
        _mildewLeaf();
      case PracticeFigureKind.anthracnoseLeaf:
        _anthracnoseLeaf();
      case PracticeFigureKind.greeningLeaf:
        _greeningLeaf();
      case PracticeFigureKind.psyllaShoot:
        _psyllaShoot();
      case PracticeFigureKind.aphidShoot:
        _aphidShoot();
      case PracticeFigureKind.mealybugTwig:
        _mealybugTwig();
      case PracticeFigureKind.leafMinerLeaf:
        _leafMinerLeaf();
      case PracticeFigureKind.mitesLeaf:
        _mitesLeaf();
      case PracticeFigureKind.thripsFruit:
        _thripsFruit();
      case PracticeFigureKind.heatDropTree:
        _heatDropTree();
    }
  }

  void _trunk() {
    _c.drawRect(_r(0, 195, 320, 55), _fill(p.soil));
    _c.drawOval(_r(65, 12, 190, 116), _fill(p.leaf));
    _c.drawOval(_r(71, 36, 68, 48), _fill(p.leafSick));
    _c.drawOval(_r(185, 58, 60, 40), _fill(p.leafSick));
    final trunk = Path()
      ..moveTo(146 * _k, 112 * _k)
      ..lineTo(174 * _k, 112 * _k)
      ..lineTo(180 * _k, 197 * _k)
      ..lineTo(140 * _k, 197 * _k)
      ..close();
    _c.drawPath(trunk, _fill(p.bark));
    _c.drawRect(_r(142, 158, 37, 39), _fill(p.soilDark));
    for (final x in [150.0, 158.0, 167.0]) {
      _c.drawLine(_o(x, 164), _o(x, 194), _line(_Palette.onSoil, 2));
    }
    _c.drawCircle(_o(172, 174), 5 * _k, _fill(p.gum));
    _c.drawCircle(_o(148, 184), 4 * _k, _fill(p.gum));
    _c.drawLine(_o(181, 176), _o(232, 166), _line(p.ink, 1.2));
    _text(labels[0], 236, 156, bold: true, maxWidth: 80);
    _c.drawLine(_o(140, 180), _o(78, 176), _line(p.ink, 1.2));
    _text(labels[1], 6, 160, maxWidth: 70);
    _c.drawLine(_o(158, 194), _o(118, 222), _line(_Palette.onSoil, 1.2));
    _text(labels[2], 10, 222, color: _Palette.onSoil, maxWidth: 260);
    _c.drawLine(_o(215, 78), _o(258, 40), _line(p.ink, 1.2));
    _text(labels[3], 236, 18, maxWidth: 82);
  }

  void _trench() {
    _c.drawRect(_r(0, 110, 320, 60), _fill(p.soil));
    final cut = Path()
      ..moveTo(130 * _k, 110 * _k)
      ..lineTo(190 * _k, 110 * _k)
      ..lineTo(184 * _k, 140 * _k)
      ..lineTo(136 * _k, 140 * _k)
      ..close();
    _c.drawPath(cut, _fill(p.soilDark));
    _c.drawRect(_r(137, 131, 46, 9), _fill(p.water));
    _tree(58, 62, 110);
    _tree(262, 62, 110);
    final dim = _line(p.ink, 1.5);
    _c.drawLine(_o(130, 100), _o(190, 100), dim);
    _c.drawLine(_o(130, 95), _o(130, 105), dim);
    _c.drawLine(_o(190, 95), _o(190, 105), dim);
    _text(labels[0], 160, 80, bold: true, align: TextAlign.center);
    _c.drawLine(_o(198, 110), _o(198, 140), _line(_Palette.onSoil, 1.5));
    _text(
      labels[1],
      204,
      117,
      color: _Palette.onSoil,
      bold: true,
      maxWidth: 110,
    );
    _text(
      labels[2],
      160,
      148,
      color: _Palette.onSoil,
      align: TextAlign.center,
      maxWidth: 300,
    );
  }

  void _ring() {
    _c.drawRect(_r(0, 0, 320, 170), _fill(p.soil));
    final centre = _o(160, 85);
    _c.drawCircle(centre, 70 * _k, _fill(p.water));
    _c.drawCircle(centre, 38 * _k, _fill(p.soil));
    _c.drawCircle(centre, 38 * _k, _line(p.soilDark, 5));
    _c.drawCircle(centre, 70 * _k, _line(p.soilDark, 5));
    _c.drawCircle(centre, 11 * _k, _fill(p.bark));
    _text(
      labels[0],
      160,
      56,
      color: _Palette.onSoil,
      bold: true,
      align: TextAlign.center,
      maxWidth: 70,
    );
    _text(
      labels[1],
      160,
      132,
      color: _Palette.onWater,
      bold: true,
      align: TextAlign.center,
      maxWidth: 90,
    );
    _text(
      labels[2],
      314,
      8,
      color: _Palette.onSoil,
      align: TextAlign.right,
      maxWidth: 80,
    );
    if (labels.length > 3) {
      _c.drawLine(_o(192, 92), _o(250, 128), _line(_Palette.onSoil, 1.2));
      _text(
        labels[3],
        236,
        130,
        color: _Palette.onSoil,
        bold: true,
        maxWidth: 82,
      );
    }
  }

  void _prune() {
    _c.drawLine(_o(20, 140), _o(200, 88), _line(p.bark, 14));
    _c.drawLine(_o(200, 88), _o(300, 60), _line(p.soilDark, 14));
    final cut = _line(p.danger, 3);
    for (var y = 70.0; y < 110; y += 10) {
      _c.drawLine(
        _o(178 + (y - 70) / 4, y),
        _o(180.5 + (y - 66) / 4, y + 6),
        cut,
      );
    }
    _text(labels[0], 230, 34, maxWidth: 90);
    _text(labels[1], 116, 48, color: p.danger, bold: true, maxWidth: 70);
    _c.drawLine(_o(183, 122), _o(203, 116), _line(p.ink, 1.5));
    _text(labels[2], 150, 128, maxWidth: 170);
    for (final (x, y) in [(60.0, 118.0), (100.0, 104.0)]) {
      _c.save();
      _c.translate(x * _k, y * _k);
      _c.rotate(-math.pi / 6);
      _c.drawOval(_r(-16, -9, 32, 18), _fill(p.leaf));
      _c.restore();
    }
  }

  void _roots() {
    _c.drawCircle(_o(282, 30), 16 * _k, _fill(p.leafSick));
    _c.drawRect(_r(0, 100, 320, 70), _fill(p.soil));
    final pit = Path()
      ..moveTo(90 * _k, 100 * _k)
      ..quadraticBezierTo(160 * _k, 150 * _k, 230 * _k, 100 * _k)
      ..close();
    _c.drawPath(pit, _fill(p.soilDark));
    _c.drawRect(_r(154, 30, 12, 80), _fill(p.bark));
    final root = _line(p.bark, 4);
    _c.drawLine(_o(160, 108), _o(116, 124), root);
    _c.drawLine(_o(160, 108), _o(206, 122), root);
    _c.drawLine(_o(206, 122), _o(216, 126), _line(p.danger, 5));
    _text(
      labels[0],
      250,
      52,
      bold: true,
      align: TextAlign.center,
      maxWidth: 130,
    );
    _text(labels[1], 196, 134, color: _Palette.onSoil, maxWidth: 120);
  }

  void _bark() {
    _c.drawRect(_r(120, 0, 80, 170), _fill(p.bark));
    _c.drawOval(_r(128, 45, 64, 100), _fill(p.leaf.withValues(alpha: 0.6)));
    _c.drawOval(_r(138, 57, 44, 76), _fill(p.soilDark));
    _c.drawOval(_r(128, 45, 64, 100), _line(p.danger, 2.5));
    _c.drawLine(_o(192, 80), _o(232, 62), _line(p.ink, 1.2));
    _text(labels[0], 214, 30, maxWidth: 104);
    _c.drawLine(_o(140, 100), _o(84, 118), _line(p.ink, 1.2));
    _text(labels[1], 6, 118, maxWidth: 80);
  }

  void _twice() {
    _c.drawRRect(
      RRect.fromRectAndRadius(_r(30, 78, 260, 14), Radius.circular(7 * _k)),
      _fill(p.ink.withValues(alpha: 0.15)),
    );
    _c.drawRect(_r(110, 78, 100, 14), _fill(p.water));
    _text(
      labels[0],
      160,
      54,
      bold: true,
      align: TextAlign.center,
      maxWidth: 120,
    );
    for (final (x, n, label) in [
      (90.0, marks[0], labels[1]),
      (230.0, marks[1], labels[2]),
    ]) {
      _c.drawCircle(_o(x, 85), 14 * _k, _fill(p.gum));
      _text(
        n,
        x,
        76,
        color: _Palette.onSoil,
        bold: true,
        align: TextAlign.center,
        maxWidth: 20,
      );
      _text(label, x, 108, align: TextAlign.center, maxWidth: 120);
    }
  }

  void _ground([double y = 140]) =>
      _c.drawRect(_r(0, y, 320, 170 - y), _fill(p.soil));

  void _dim(double x, double y1, double y2, Color color) {
    final l = _line(color, 1.5);
    _c.drawLine(_o(x, y1), _o(x, y2), l);
    _c.drawLine(_o(x - 5, y1), _o(x + 5, y1), l);
    _c.drawLine(_o(x - 5, y2), _o(x + 5, y2), l);
  }

  void _stickyTrap() {
    _ground();
    _tree(70, 50, 140, r: 44);
    _c.drawLine(_o(200, 140), _o(200, 40), _line(p.bark, 4));
    _c.drawRect(_r(186, 34, 28, 36), _fill(p.leafSick));
    _c.drawRect(_r(186, 34, 28, 36), _line(p.ink, 1));
    _dim(236, 52, 140, p.ink);
    _text(labels[0], 150, 6, bold: true, maxWidth: 160);
    _text(labels[1], 244, 86, bold: true, maxWidth: 76);
  }

  void _budHeight() {
    _ground(150);
    _c.drawRect(_r(150, 30, 20, 120), _fill(p.bark));
    _c.drawOval(_r(108, 0, 104, 48), _fill(p.leaf));
    _c.drawRect(_r(146, 92, 28, 8), _fill(p.gum));
    _c.drawLine(_o(176, 96), _o(214, 86), _line(p.ink, 1.2));
    _text(labels[0], 218, 76, bold: true, maxWidth: 100);
    _dim(120, 96, 150, p.ink);
    _text(labels[1], 6, 110, bold: true, maxWidth: 108);
  }

  void _trunkBand() {
    _ground(150);
    _c.drawRect(_r(144, 0, 32, 150), _fill(p.bark));
    _c.drawRect(_r(140, 70, 40, 16), _fill(p.leafSick));
    _dim(196, 70, 86, p.ink);
    _text(labels[0], 204, 66, bold: true, maxWidth: 110);
    for (final x in [152.0, 162.0, 170.0]) {
      _c.drawCircle(_o(x, 118 + (x - 152) / 2), 3 * _k, _fill(p.ink));
    }
    _c.drawLine(_o(140, 110), _o(96, 120), _line(p.ink, 1.2));
    _text(labels[1], 6, 112, maxWidth: 92);
  }

  void _lureTrap() {
    _ground();
    _tree(80, 44, 140, r: 46);
    _c.drawLine(_o(80, 60), _o(80, 84), _line(p.ink, 1.5));
    _c.drawRRect(
      RRect.fromRectAndRadius(_r(66, 84, 28, 34), Radius.circular(6 * _k)),
      _fill(p.water),
    );
    _c.drawCircle(_o(80, 101), 5 * _k, _fill(p.gum));
    _c.drawLine(_o(96, 100), _o(150, 92), _line(p.ink, 1.2));
    _text(labels[0], 154, 82, bold: true, maxWidth: 160);
    _text(labels[1], 154, 112, maxWidth: 160);
  }

  void _shadySide() {
    _ground();
    _c.drawCircle(_o(290, 26), 16 * _k, _fill(p.leafSick));
    _c.drawRect(_r(174, 80, 12, 60), _fill(p.bark));
    _c.drawOval(_r(120, 20, 120, 80), _fill(p.leaf));
    final shade = Path()
      ..moveTo(180 * _k, 20 * _k)
      ..arcTo(_r(120, 20, 120, 80), -math.pi / 2, -math.pi, false)
      ..close();
    _c.drawPath(shade, _fill(p.ink.withValues(alpha: 0.35)));
    _c.drawOval(_r(60, 132, 110, 14), _fill(p.ink.withValues(alpha: 0.2)));
    _text(labels[0], 6, 40, bold: true, maxWidth: 108);
    _text(labels[1], 246, 64, maxWidth: 72);
  }

  void _openCanopy() {
    _ground();
    _c.drawRect(_r(154, 92, 12, 48), _fill(p.bark));
    final branch = _line(p.bark, 6);
    _c.drawLine(_o(160, 96), _o(108, 52), branch);
    _c.drawLine(_o(160, 96), _o(212, 52), branch);
    _c.drawOval(_r(70, 20, 70, 50), _fill(p.leaf));
    _c.drawOval(_r(180, 20, 70, 50), _fill(p.leaf));
    _c.drawLine(_o(160, 96), _o(160, 46), _line(p.danger, 3));
    _text(
      labels[0],
      160,
      2,
      bold: true,
      align: TextAlign.center,
      maxWidth: 200,
    );
    _c.drawLine(_o(162, 70), _o(232, 100), _line(p.danger, 1.2));
    _text(labels[1], 236, 94, color: p.danger, bold: true, maxWidth: 82);
  }

  void _manureRing() {
    _c.drawRect(_r(0, 0, 320, 170), _fill(p.soil));
    final centre = _o(160, 85);
    _c.drawCircle(centre, 70 * _k, _line(p.gum, 14));
    _c.drawCircle(centre, 12 * _k, _fill(p.bark));
    _c.drawCircle(centre, 46 * _k, _line(p.soilDark, 2));
    _text(
      labels[0],
      160,
      102,
      color: _Palette.onSoil,
      bold: true,
      align: TextAlign.center,
      maxWidth: 80,
    );
    _c.drawLine(_o(224, 60), _o(262, 34), _line(_Palette.onSoil, 1.2));
    _text(labels[1], 236, 4, color: _Palette.onSoil, bold: true, maxWidth: 84);
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.kind != kind || old.labels.join() != labels.join() || old.p != p;
}
