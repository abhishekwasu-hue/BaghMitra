part of 'practice_figure_view.dart';

/// Symptom drawings, group A (batch 2). Each draws in the painter's 320 x 170 space
/// with the painter's helpers and writes its labels (in order) from [labels].
extension _SymptomFiguresA on _FigurePainter {
  /// A citrus leaf from base (x0, y) to tip (x1, y): pointed tip, small winged
  /// petiole, midrib. Returns the blade path so callers can clip spots to it.
  Path _citrusLeaf(double x0, double x1, double y, double half, Color color) {
    final b = x0 + 12;
    final blade = Path()
      ..moveTo(b * _k, y * _k)
      ..cubicTo(
        (b + 20) * _k,
        (y - half * 1.3) * _k,
        (x1 - 50) * _k,
        (y - half * 1.1) * _k,
        x1 * _k,
        y * _k,
      )
      ..cubicTo(
        (x1 - 50) * _k,
        (y + half * 1.1) * _k,
        (b + 20) * _k,
        (y + half * 1.3) * _k,
        b * _k,
        y * _k,
      )
      ..close();
    final wing = Path()
      ..moveTo(x0 * _k, y * _k)
      ..quadraticBezierTo((x0 + 6) * _k, (y - 5) * _k, (b + 2) * _k, y * _k)
      ..quadraticBezierTo((x0 + 6) * _k, (y + 5) * _k, x0 * _k, y * _k)
      ..close();
    _c.drawLine(_o(x0 - 10, y + 2), _o(x0, y), _line(p.bark, 2.5));
    _c.drawPath(wing, _fill(color));
    _c.drawPath(blade, _fill(color));
    final vein = _line(p.ink.withValues(alpha: 0.25), 1.2);
    _c.drawLine(_o(b, y), _o(x1 - 4, y), vein);
    return blade;
  }

  // canker: Raised, rough, brown corky spots, Yellow halo, On fruit: spots stay in the rind
  void _cankerSpots() {
    final leaf = _citrusLeaf(26, 196, 96, 34, p.leaf);
    _c.save();
    _c.clipPath(leaf);
    for (final (x, y, r) in [
      (66.0, 84.0, 5.0),
      (92.0, 108.0, 4.0),
      (112.0, 80.0, 5.5),
      (138.0, 104.0, 4.5),
      (160.0, 88.0, 3.5),
      (80.0, 98.0, 3.0),
    ]) {
      _c.drawCircle(_o(x, y), (r + 3.5) * _k, _fill(p.leafSick));
      _cork(x, y, r);
    }
    _c.restore();
    // Fruit: spots without a halo.
    _c.drawLine(_o(262, 30), _o(266, 18), _line(p.bark, 2.5));
    _c.drawCircle(_o(262, 68), 38 * _k, _fill(p.gum));
    _c.drawCircle(_o(262, 32), 4 * _k, _fill(p.leaf));
    for (final (x, y, r) in [
      (246.0, 56.0, 4.0),
      (272.0, 50.0, 3.0),
      (284.0, 76.0, 4.5),
      (256.0, 88.0, 3.5),
      (236.0, 78.0, 3.0),
    ]) {
      _cork(x, y, r);
    }
    final ink = _line(p.ink, 1.2);
    _c.drawLine(_o(70, 40), _o(110, 76), ink);
    _text(labels[0], 6, 4, bold: true, maxWidth: 196);
    _c.drawLine(_o(140, 112), _o(150, 140), ink);
    _text(labels[1], 120, 142, maxWidth: 120);
    _c.drawLine(_o(262, 92), _o(262, 116), ink);
    _text(labels[2], 316, 118, align: TextAlign.right, maxWidth: 110);
  }

  /// A raised, rough, brown corky spot: a dark rim, brown body, rough flecks.
  void _cork(double x, double y, double r) {
    _c.drawCircle(_o(x, y), r * _k, _fill(p.bark));
    _c.drawCircle(_o(x, y), r * _k, _line(p.soilDark, 1));
    final fleck = _fill(p.soilDark);
    _c.drawCircle(_o(x - r * 0.35, y - r * 0.3), 0.8 * _k, fleck);
    _c.drawCircle(_o(x + r * 0.3, y + r * 0.2), 0.8 * _k, fleck);
    _c.drawCircle(
      _o(x - r * 0.3, y - r * 0.4),
      r * 0.35 * _k,
      _fill(_Palette.onSoil.withValues(alpha: 0.35)),
    );
  }

  // powdery_mildew: White powder, Leaves twist and curl
  void _mildewLeaf() {
    final pale = Color.lerp(
      Color.lerp(p.leaf, _Palette.onWater, 0.2)!,
      _Palette.onSoil,
      0.25,
    )!;
    // A young shoot carrying both leaves.
    _c.drawLine(_o(20, 150), _o(300, 150), _line(p.bark, 3));
    _c.drawLine(_o(96, 150), _o(94.3, 136), _line(p.bark, 2));
    _c.save();
    _c.translate(96 * _k, 126 * _k);
    _c.rotate(-math.pi / 2.6);
    _c.translate(-96 * _k, -126 * _k);
    final leaf = _citrusLeaf(96, 196, 126, 22, pale);
    _c.clipPath(leaf);
    final powder = _fill(_Palette.onSoil.withValues(alpha: 0.9));
    final rim = _line(_Palette.onWater.withValues(alpha: 0.3), 0.8);
    for (final (x, y, r) in [
      (126.0, 120.0, 8.0),
      (134.0, 130.0, 6.0),
      (150.0, 122.0, 7.0),
      (166.0, 128.0, 6.0),
      (176.0, 122.0, 4.5),
      (118.0, 131.0, 4.0),
    ]) {
      _c.drawCircle(_o(x, y), r * _k, powder);
      _c.drawCircle(_o(x, y), r * _k, rim);
    }
    _c.restore();
    _twistedLeaf(pale);
    final ink = _line(p.ink, 1.2);
    _c.drawLine(_o(118, 72), _o(74, 50), ink);
    _text(labels[0], 6, 22, bold: true, maxWidth: 110);
    _c.drawLine(_o(232, 79), _o(256, 50), ink);
    _text(labels[1], 316, 4, bold: true, align: TextAlign.right, maxWidth: 140);
  }

  /// A leaf that twists along an S-shaped midrib, its pale underside showing,
  /// and curls over at the tip.
  void _twistedLeaf(Color pale) {
    _c.drawLine(_o(214, 150), _o(214, 132), _line(p.bark, 2));
    final upper = Path()
      ..moveTo(214 * _k, 132 * _k)
      ..cubicTo(190 * _k, 112 * _k, 196 * _k, 82 * _k, 222 * _k, 78 * _k)
      ..cubicTo(244 * _k, 74 * _k, 262 * _k, 90 * _k, 258 * _k, 106 * _k)
      ..cubicTo(250 * _k, 96 * _k, 236 * _k, 92 * _k, 226 * _k, 98 * _k)
      ..cubicTo(216 * _k, 106 * _k, 222 * _k, 122 * _k, 214 * _k, 132 * _k)
      ..close();
    _c.drawPath(upper, _fill(pale));
    final under = Path()
      ..moveTo(258 * _k, 106 * _k)
      ..cubicTo(250 * _k, 96 * _k, 236 * _k, 92 * _k, 226 * _k, 98 * _k)
      ..cubicTo(236 * _k, 104 * _k, 248 * _k, 112 * _k, 254 * _k, 124 * _k)
      ..cubicTo(262 * _k, 124 * _k, 264 * _k, 114 * _k, 258 * _k, 106 * _k)
      ..close();
    _c.drawPath(under, _fill(Color.lerp(pale, _Palette.onSoil, 0.35)!));
    _c.drawPath(under, _line(p.ink.withValues(alpha: 0.3), 1));
    final rib = Path()
      ..moveTo(214 * _k, 132 * _k)
      ..cubicTo(204 * _k, 108 * _k, 214 * _k, 88 * _k, 240 * _k, 88 * _k);
    _c.drawPath(rib, _line(p.ink.withValues(alpha: 0.25), 1.2));
    final powder = _fill(_Palette.onSoil.withValues(alpha: 0.9));
    final rim = _line(_Palette.onWater.withValues(alpha: 0.3), 0.8);
    for (final (x, y, r) in [
      (212.0, 104.0, 5.0),
      (230.0, 84.0, 4.0),
      (222.0, 92.0, 3.0),
    ]) {
      _c.drawCircle(_o(x, y), r * _k, powder);
      _c.drawCircle(_o(x, y), r * _k, rim);
    }
  }

  // anthracnose: Light-tan patch, purple edge, Tiny black dots, Dead twig: silvery grey
  void _anthracnoseLeaf() {
    final tan = Color.lerp(
      Color.lerp(p.leafSick, p.soil, 0.3)!,
      _Palette.onSoil,
      0.35,
    )!;
    // Purple from the theme's red, hue-turned (red and blue do not mix to purple
    // in this palette's light sky blue).
    final purple = HSLColor.fromColor(p.danger).withHue(290).toColor();
    final leaf = _citrusLeaf(20, 186, 98, 34, p.leaf);
    _c.save();
    _c.clipPath(leaf);
    for (final (x, y, r) in [
      (76.0, 86.0, 12.0),
      (128.0, 108.0, 13.0),
      (154.0, 84.0, 7.0),
    ]) {
      _c.drawCircle(_o(x, y), r * _k, _fill(tan));
      _c.drawCircle(_o(x, y), r * _k, _line(purple, 3));
      for (var i = 0; i < 7; i++) {
        final a = i * 2.4;
        final d = r * (0.25 + 0.08 * i);
        _c.drawCircle(
          _o(x + d * math.cos(a), y + d * math.sin(a)),
          0.9 * _k,
          _fill(_Palette.onWater),
        );
      }
    }
    _c.restore();
    // Twig: green-brown living part, silvery grey dead tip.
    final grey = Color.lerp(_Palette.onSoil, _Palette.onWater, 0.42)!;
    _c.drawLine(_o(212, 160), _o(256, 110), _line(p.bark, 6));
    _c.drawLine(_o(256, 110), _o(298, 62), _line(grey, 5));
    _c.drawLine(_o(232, 138), _o(214, 118), _line(p.bark, 2));
    _c.save();
    _c.translate(214 * _k, 118 * _k);
    _c.rotate(-2.3);
    _c.drawOval(_r(-20, -7, 22, 14), _fill(p.leaf));
    _c.restore();
    final ink = _line(p.ink, 1.2);
    _c.drawLine(_o(70, 40), _o(70, 74), ink);
    _text(labels[0], 6, 4, bold: true, maxWidth: 190);
    _c.drawLine(_o(130, 112), _o(118, 140), ink);
    _text(labels[1], 60, 142, bold: true, maxWidth: 130);
    _c.drawLine(_o(290, 40), _o(283, 77), ink);
    _text(labels[2], 316, 4, bold: true, align: TextAlign.right, maxWidth: 110);
  }

  // greening: Yellow leaf with green islands, Fruit small, lopsided, green
  void _greeningLeaf() {
    final leaf = _citrusLeaf(20, 180, 104, 34, p.leafSick);
    _c.save();
    _c.clipPath(leaf);
    final green = _fill(p.leaf);
    for (final (x, y, w, h, a) in [
      (62.0, 92.0, 14.0, 8.0, 0.4),
      (84.0, 112.0, 12.0, 7.0, -0.3),
      (104.0, 94.0, 9.0, 12.0, 0.2),
      (122.0, 116.0, 15.0, 7.0, 0.6),
      (138.0, 96.0, 10.0, 7.0, -0.5),
      (156.0, 108.0, 8.0, 5.0, 0.1),
      (72.0, 104.0, 6.0, 5.0, 0.0),
    ]) {
      _c.save();
      _c.translate(x * _k, y * _k);
      _c.rotate(a);
      _c.drawOval(_r(-w / 2, -h / 2, w, h), green);
      _c.drawOval(_r(w / 6, -h / 2 - 2, w / 2, h / 2 + 1), green);
      _c.restore();
    }
    _c.restore();
    // Healthy fruit for comparison (unlabelled), then the small lopsided green one.
    _c.drawLine(_o(226, 30), _o(228, 18), _line(p.bark, 2.5));
    _c.drawCircle(_o(226, 66), 34 * _k, _fill(p.gum));
    _c.drawCircle(_o(226, 33), 3.5 * _k, _fill(p.leaf));
    final small = Path()
      ..moveTo(286 * _k, 76 * _k)
      ..cubicTo(304 * _k, 70 * _k, 318 * _k, 96 * _k, 306 * _k, 108 * _k)
      ..cubicTo(298 * _k, 116 * _k, 282 * _k, 114 * _k, 278 * _k, 104 * _k)
      ..cubicTo(274 * _k, 94 * _k, 276 * _k, 82 * _k, 286 * _k, 76 * _k)
      ..close();
    _c.drawLine(_o(287, 77), _o(285, 66), _line(p.bark, 2));
    _c.drawPath(small, _fill(Color.lerp(p.leaf, p.leafSick, 0.2)!));
    _c.drawPath(small, _line(p.ink.withValues(alpha: 0.3), 1));
    final ink = _line(p.ink, 1.2);
    _c.drawLine(_o(90, 48), _o(104, 90), ink);
    _text(labels[0], 6, 4, bold: true, maxWidth: 170);
    _c.drawLine(_o(288, 114), _o(288, 126), ink);
    _text(
      labels[1],
      316,
      128,
      bold: true,
      align: TextAlign.right,
      maxWidth: 130,
    );
  }
}
