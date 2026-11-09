part of 'practice_figure_view.dart';

/// Symptom drawings, group C (batch 2). Each draws in the painter's 320 x 170 space
/// with the painter's helpers and writes its labels (in order) from [labels].
extension _SymptomFiguresC on _FigurePainter {
  // mites: Pale yellow along the veins, Fine webbing: dusty look, Rough rind (russeting)
  void _mitesLeaf() {
    // Leaf: stalk at the left, tip at the right.
    final leaf = Path()
      ..moveTo(26 * _k, 94 * _k)
      ..quadraticBezierTo(108 * _k, 26 * _k, 206 * _k, 80 * _k)
      ..quadraticBezierTo(118 * _k, 142 * _k, 26 * _k, 94 * _k)
      ..close();
    _c.drawLine(_o(10, 98), _o(28, 94), _line(p.bark, 3));
    _c.drawPath(leaf, _fill(p.leaf));
    double midY(double x) => 94 - (x - 26) / 180 * 14;
    _c.save();
    _c.clipPath(leaf);
    // Pale-yellow bands along the midrib and the veins.
    final band = p.leafSick.withValues(alpha: 0.75);
    _c.drawLine(_o(26, 94), _o(206, 80), _line(band, 10));
    final veins = [for (var x = 50.0; x <= 170; x += 30) x];
    for (final x in veins) {
      final y = midY(x);
      _c.drawLine(_o(x, y), _o(x + 26, y - 30), _line(band, 6));
      _c.drawLine(_o(x, y), _o(x + 26, y + 30), _line(band, 6));
    }
    final vein = _line(p.ink.withValues(alpha: 0.35), 1);
    _c.drawLine(
      _o(26, 94),
      _o(206, 80),
      _line(p.ink.withValues(alpha: 0.4), 1.5),
    );
    for (final x in veins) {
      final y = midY(x);
      _c.drawLine(_o(x, y), _o(x + 26, y - 30), vein);
      _c.drawLine(_o(x, y), _o(x + 26, y + 30), vein);
    }
    // Dusty look where the webbing is.
    _c.drawOval(
      _r(146, 56, 64, 48),
      _fill(_Palette.onSoil.withValues(alpha: 0.3)),
    );
    _c.restore();
    _c.drawPath(leaf, _line(p.ink.withValues(alpha: 0.3), 1));
    // Fine web strands across the leaf tip.
    final web = _line(_Palette.onSoil.withValues(alpha: 0.95), 0.9);
    for (final (x1, y1, x2, y2) in [
      (150.0, 62.0, 204.0, 92.0),
      (156.0, 98.0, 200.0, 64.0),
      (160.0, 56.0, 176.0, 104.0),
      (178.0, 58.0, 190.0, 100.0),
      (148.0, 80.0, 212.0, 78.0),
      (164.0, 60.0, 212.0, 70.0),
    ]) {
      _c.drawLine(_o(x1, y1), _o(x2, y2), web);
    }
    // Fruit with a rough, russeted patch.
    final fruit = _o(268, 116);
    _c.drawLine(_o(268, 84), _o(270, 74), _line(p.bark, 2.5));
    _c.drawCircle(fruit, 32 * _k, _fill(p.gum));
    _c.save();
    _c.clipPath(
      Path()..addOval(Rect.fromCircle(center: fruit, radius: 32 * _k)),
    );
    final rust = Path()
      ..addOval(_r(236, 108, 34, 30))
      ..addOval(_r(254, 122, 26, 24));
    _c.drawPath(rust, _fill(p.soil.withValues(alpha: 0.55)));
    final dot = _fill(p.soilDark);
    final rnd = math.Random(7);
    for (var i = 0; i < 46; i++) {
      final x = 238 + rnd.nextDouble() * 40;
      final y = 110 + rnd.nextDouble() * 34;
      if (rust.contains(_o(x, y))) _c.drawCircle(_o(x, y), 0.9 * _k, dot);
    }
    _c.restore();
    // Labels in the margins.
    final lead = _line(p.ink, 1.2);
    _c.drawLine(_o(70, 38), _o(80, 66), lead);
    _text(labels[0], 6, 4, bold: true);
    _c.drawLine(_o(200, 36), _o(186, 64), lead);
    _text(labels[1], 176, 4, bold: true, maxWidth: 140);
    _c.drawLine(_o(150, 150), _o(244, 126), lead);
    _text(labels[2], 6, 142, bold: true, maxWidth: 142);
  }

  // thrips: Ring-like scar round the stalk, Irregular patches on the rind
  void _thripsFruit() {
    final centre = _o(152, 98);
    const r = 60.0;
    // Stalk and leaf at the top.
    _c.drawLine(_o(152, 40), _o(150, 14), _line(p.bark, 3));
    _c.save();
    _c.translate(170 * _k, 18 * _k);
    _c.rotate(-math.pi / 9);
    _c.drawOval(_r(-20, -8, 40, 16), _fill(p.leaf));
    _c.restore();
    _c.drawCircle(centre, r * _k, _fill(p.gum));
    _c.save();
    _c.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: r * _k)),
    );
    // Irregular mottled pale patches on the skin.
    final pale = _fill(_Palette.onSoil.withValues(alpha: 0.38));
    for (final blob in [
      [(112.0, 92.0, 9.0), (121.0, 98.0, 8.0), (116.0, 106.0, 6.0)],
      [(178.0, 108.0, 10.0), (187.0, 116.0, 7.0), (171.0, 118.0, 6.0)],
      [(140.0, 132.0, 8.0), (151.0, 136.0, 6.0), (133.0, 140.0, 5.0)],
      [(182.0, 76.0, 6.0), (189.0, 82.0, 5.0)],
      [(126.0, 66.0, 5.0), (120.0, 72.0, 4.0)],
    ]) {
      final path = Path();
      for (final (x, y, br) in blob) {
        path.addOval(Rect.fromCircle(center: _o(x, y), radius: br * _k));
      }
      _c.drawPath(path, pale);
    }
    // Grey-brown ring-shaped scar round the stalk end.
    _c.drawOval(_r(128, 36, 48, 22), _line(p.soil.withValues(alpha: 0.85), 7));
    _c.drawOval(_r(128, 36, 48, 22), _line(p.ink.withValues(alpha: 0.25), 1.5));
    _c.restore();
    _c.drawCircle(_o(152, 41), 4 * _k, _fill(p.leaf));
    // Labels in the margins.
    final lead = _line(p.ink, 1.2);
    _c.drawLine(_o(86, 40), _o(128, 46), lead);
    _text(labels[0], 6, 22, bold: true, maxWidth: 80);
    _c.drawLine(_o(236, 112), _o(190, 112), lead);
    _text(labels[1], 238, 100, bold: true, maxWidth: 80);
  }

  // heat_drop: Hot summer, Second wave of fruit drop
  void _heatDropTree() {
    _ground(132);
    // Hot sun with rays in the top corner.
    final sun = _o(290, 26);
    final ray = _line(p.leafSick, 2.5);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      _c.drawLine(
        _o(290 + 18 * math.cos(a), 26 + 18 * math.sin(a)),
        _o(290 + 25 * math.cos(a), 26 + 25 * math.sin(a)),
        ray,
      );
    }
    _c.drawCircle(sun, 13 * _k, _fill(p.leafSick));
    // Tree with a few fruits still on it.
    _tree(110, 52, 132, r: 46);
    for (final (x, y) in [(86.0, 58.0), (128.0, 42.0), (142.0, 70.0)]) {
      _c.drawCircle(_o(x, y), 4.5 * _k, _fill(p.gum));
    }
    // Many fallen fruits on the ground under it.
    for (final (x, y) in [
      (54.0, 140.0),
      (66.0, 147.0),
      (78.0, 138.0),
      (88.0, 152.0),
      (96.0, 142.0),
      (130.0, 141.0),
      (138.0, 152.0),
      (148.0, 139.0),
      (158.0, 148.0),
      (170.0, 140.0),
      (74.0, 158.0),
      (122.0, 158.0),
      (176.0, 155.0),
      (44.0, 152.0),
    ]) {
      _c.drawCircle(_o(x, y), 4.5 * _k, _fill(p.gum));
    }
    // Labels.
    _c.drawLine(_o(260, 40), _o(248, 52), _line(p.ink, 1.2));
    _text(
      labels[0],
      300,
      54,
      bold: true,
      align: TextAlign.right,
      maxWidth: 110,
    );
    _c.drawLine(_o(196, 148), _o(178, 150), _line(_Palette.onSoil, 1.2));
    _text(
      labels[1],
      200,
      138,
      color: _Palette.onSoil,
      bold: true,
      maxWidth: 116,
    );
  }
}
