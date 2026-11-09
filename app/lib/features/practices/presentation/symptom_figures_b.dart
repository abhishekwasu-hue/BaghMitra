part of 'practice_figure_view.dart';

/// Symptom drawings, group B (batch 2). Each draws in the painter's 320 x 170 space
/// with the painter's helpers and writes its labels (in order) from [labels].
extension _SymptomFiguresB on _FigurePainter {
  /// Tender new growth: a lighter, yellower green than mature leaves.
  Color get _tender => Color.lerp(p.leaf, p.leafSick, 0.35)!;

  /// Thin dark outline that reads on the light sky and on leaves in both themes.
  Paint _edge(double w, [double a = 0.45]) =>
      _line(p.soilDark.withValues(alpha: a), w);

  /// A leaf whose base is at [x],[y], pointing along [angle] (radians), [len] long and
  /// [w] wide. [bend] curves the tip sideways; [roll] rolls the tip over (a curled leaf).
  void _leafB(
    double x,
    double y,
    double angle,
    double len,
    double w,
    Color color, {
    double bend = 0,
    bool roll = false,
  }) {
    _c.save();
    _c.translate(x * _k, y * _k);
    _c.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.5 * _k, -w * 1.4 * _k, len * _k, bend * _k)
      ..quadraticBezierTo(len * 0.5 * _k, w * 1.4 * _k, 0, 0)
      ..close();
    _c.drawPath(leaf, _fill(color));
    final mid = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.55 * _k, 0, len * 0.92 * _k, bend * _k);
    _c.drawPath(mid, _edge(0.8, 0.35));
    if (roll) {
      final r = w * 0.62;
      final tip = _o(len - r * 0.4, bend);
      _c.drawCircle(tip, r * _k, _fill(Color.lerp(color, p.soilDark, 0.25)!));
      final spiral = Path()
        ..addArc(
          Rect.fromCircle(center: tip, radius: r * 0.55 * _k),
          0,
          math.pi * 1.5,
        );
      _c.drawPath(spiral, _edge(1, 0.6));
    }
    _c.restore();
  }

  /// A wavy thread from [a] to [b] (white wax, outlined so it shows on light sky).
  void _thread(Offset a, Offset b, {double waves = 3, double amp = 3}) {
    final path = Path()..moveTo(a.dx * _k, a.dy * _k);
    final d = b - a;
    final n = Offset(-d.dy, d.dx) / d.distance;
    for (var i = 1; i <= 24; i++) {
      final t = i / 24;
      final q = a + d * t + n * (amp * math.sin(t * waves * 2 * math.pi));
      path.lineTo(q.dx * _k, q.dy * _k);
    }
    _c.drawPath(path, _edge(2.6, 0.5));
    _c.drawPath(path, _line(_Palette.onSoil, 1.3));
  }

  /// A small rotated oval (an insect body) at [x],[y], with an optional outline.
  void _bug(
    double x,
    double y,
    double w,
    double h,
    double angle,
    Color color, {
    bool outline = false,
  }) {
    _c.save();
    _c.translate(x * _k, y * _k);
    _c.rotate(angle);
    _c.drawOval(_r(-w / 2, -h / 2, w, h), _fill(color));
    if (outline) _c.drawOval(_r(-w / 2, -h / 2, w, h), _edge(0.8, 0.6));
    _c.restore();
  }

  /// A soft white cotton-like blob of a few circles, outlined for light backgrounds.
  void _cotton(double x, double y, double s) {
    const parts = [
      (0.0, 0.0, 1.0),
      (-0.8, 0.3, 0.7),
      (0.8, 0.2, 0.75),
      (0.1, -0.7, 0.65),
    ];
    for (final (dx, dy, r) in parts) {
      _c.drawCircle(_o(x + dx * s, y + dy * s), r * s * _k, _edge(1.4, 0.55));
    }
    for (final (dx, dy, r) in parts) {
      _c.drawCircle(
        _o(x + dx * s, y + dy * s),
        r * s * _k,
        _fill(_Palette.onSoil),
      );
    }
  }

  // psylla: Yellow-orange nymphs on shoot tips, White waxy threads, New leaves curl
  void _psyllaShoot() {
    // Woody stem below, tender green shoot above.
    _c.drawLine(_o(150, 170), _o(149, 136), _line(p.bark, 6));
    final shoot = Path()
      ..moveTo(149 * _k, 138 * _k)
      ..quadraticBezierTo(144 * _k, 80 * _k, 168 * _k, 26 * _k);
    _c.drawPath(shoot, _line(p.leaf, 4.5));
    // Mature leaves.
    _leafB(148, 152, math.pi + 0.15, 52, 12, p.leaf);
    _leafB(150, 142, -0.15, 52, 12, p.leaf);
    // New leaves: twisted and curled.
    _leafB(148, 110, -2.55, 42, 11, _tender, bend: 14, roll: true);
    _leafB(152, 96, -0.4, 42, 11, _tender, bend: -14, roll: true);
    _leafB(166, 32, -2.2, 24, 7, _tender, bend: 8, roll: true);
    _leafB(167, 30, -0.8, 22, 7, _tender, bend: -8, roll: true);
    // Flat yellow-orange nymphs crowding the tip.
    const nymphs = [
      (158.0, 44.0),
      (169.0, 42.0),
      (152.0, 56.0),
      (163.0, 54.0),
      (174.0, 52.0),
      (149.0, 68.0),
      (160.0, 66.0),
      (171.0, 64.0),
      (156.0, 78.0),
      (166.0, 76.0),
    ];
    for (var i = 0; i < nymphs.length; i++) {
      final (x, y) = nymphs[i];
      _bug(
        x,
        y,
        10,
        6.5,
        -1.1 + (i % 3) * 0.35,
        i.isEven ? p.gum : p.leafSick,
        outline: true,
      );
    }
    // White waxy threads.
    _thread(const Offset(150, 50), const Offset(118, 36));
    _thread(const Offset(146, 64), const Offset(114, 56), waves: 2.5);
    _thread(const Offset(156, 40), const Offset(138, 14), waves: 2);
    // Labels: nymphs (right), threads (left), curling leaves (right, lower).
    final lead = _line(p.ink, 1.2);
    _c.drawLine(_o(180, 50), _o(208, 30), lead);
    _text(labels[0], 212, 8, bold: true, maxWidth: 104);
    _c.drawLine(_o(114, 40), _o(100, 36), lead);
    _text(labels[1], 6, 26, maxWidth: 92);
    _c.drawLine(_o(189, 74), _o(210, 102), lead);
    _text(labels[2], 212, 98, maxWidth: 104);
  }

  /// A leaf seen side-on with its edges turned up like a cup, its surface crinkled.
  void _cupLeaf(double cx, double cy, double l, double h) {
    final cup = Path()
      ..moveTo((cx - l) * _k, (cy - h) * _k)
      ..quadraticBezierTo(
        cx * _k,
        (cy + h * 1.8) * _k,
        (cx + l) * _k,
        (cy - h) * _k,
      )
      ..quadraticBezierTo(
        cx * _k,
        (cy + h * 0.1) * _k,
        (cx - l) * _k,
        (cy - h) * _k,
      )
      ..close();
    _c.drawPath(cup, _fill(_tender));
    // Inner (upper) surface, darker, so the hollow reads.
    final inner = Path()
      ..moveTo((cx - l) * _k, (cy - h) * _k)
      ..quadraticBezierTo(
        cx * _k,
        (cy + h * 0.1) * _k,
        (cx + l) * _k,
        (cy - h) * _k,
      )
      ..quadraticBezierTo(
        cx * _k,
        (cy - h * 1.2) * _k,
        (cx - l) * _k,
        (cy - h) * _k,
      )
      ..close();
    _c.drawPath(inner, _fill(p.leaf));
    // Crinkles: a wavy line along the middle of the cup's outer face.
    final crinkle = Path();
    for (var i = 0; i <= 24; i++) {
      final s = 0.12 + 0.76 * i / 24;
      final x = cx - l + 2 * l * s;
      final wave = 1.3 * math.sin(i / 24 * 7 * 2 * math.pi);
      final y = cy - h + 2 * s * (1 - s) * 1.95 * h + wave;
      i == 0 ? crinkle.moveTo(x * _k, y * _k) : crinkle.lineTo(x * _k, y * _k);
    }
    _c.drawPath(crinkle, _edge(1, 0.5));
    _c.drawPath(cup, _edge(1, 0.5));
  }

  /// A point on the aphid shoot curve, [t] from 0 (base) to 1 (tip).
  Offset _aphidStem(double t) {
    final u = 1 - t;
    return Offset(
      u * u * 160 + 2 * u * t * 156 + t * t * 176,
      u * u * 130 + 2 * u * t * 70 + t * t * 28,
    );
  }

  // aphids: Black or brown aphid colonies, Cup-shaped, crinkled leaves
  void _aphidShoot() {
    _c.drawLine(_o(160, 170), _o(160, 128), _line(p.bark, 6));
    final shoot = Path()
      ..moveTo(160 * _k, 130 * _k)
      ..quadraticBezierTo(156 * _k, 70 * _k, 176 * _k, 28 * _k);
    _c.drawPath(shoot, _line(p.leaf, 4.5));
    // Petioles and cup-shaped leaves.
    final petiole = _line(p.leaf, 2);
    _c.drawLine(_o(159, 120), _o(136, 112), petiole);
    _cupLeaf(112, 112, 34, 11);
    _c.drawLine(_o(160, 96), _o(184, 86), petiole);
    _cupLeaf(212, 86, 32, 10);
    _c.drawLine(_o(163, 64), _o(146, 56), petiole);
    _cupLeaf(126, 54, 24, 8);
    // A dense colony of small black and brown aphids on the tender shoot.
    var i = 0;
    for (var t = 0.30; t <= 0.98; t += 0.034) {
      final q = _aphidStem(t);
      for (final side in [-3.4, 3.4]) {
        _bug(
          q.dx + side,
          q.dy + (side > 0 ? 1.5 : 0),
          4.6,
          3,
          -1.4 + (i % 3) * 0.3,
          i % 3 == 0 ? p.bark : p.soilDark,
        );
        i++;
      }
    }
    // Labels: colony (right, top), cup-shaped leaves (left).
    final lead = _line(p.ink, 1.2);
    _c.drawLine(_o(176, 44), _o(210, 24), lead);
    _text(labels[0], 212, 6, bold: true, maxWidth: 104);
    _c.drawLine(_o(84, 112), _o(72, 126), lead);
    _text(labels[1], 6, 128, maxWidth: 140);
  }

  // mealybug: White cottony clusters, Sooty mould
  void _mealybugTwig() {
    final twig = Path()
      ..moveTo(40 * _k, 64 * _k)
      ..quadraticBezierTo(150 * _k, 44 * _k, 262 * _k, 54 * _k);
    _c.drawPath(twig, _line(p.bark, 6));
    // Leaf darkened by sooty mould (patches clipped to the leaf).
    const len = 66.0, w = 17.0;
    _leafB(96, 56, 2.35, len, w, _tender);
    _c.save();
    _c.translate(96 * _k, 56 * _k);
    _c.rotate(2.35);
    _c.clipPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5 * _k, -w * 1.4 * _k, len * _k, 0)
        ..quadraticBezierTo(len * 0.5 * _k, w * 1.4 * _k, 0, 0)
        ..close(),
    );
    final mould = _fill(p.soilDark.withValues(alpha: 0.85));
    for (final (x, y, r) in [
      (14.0, -4.0, 7.0),
      (28.0, 5.0, 8.5),
      (40.0, -6.0, 7.0),
      (52.0, 3.0, 5.5),
      (20.0, 8.0, 4.5),
    ]) {
      _c.drawCircle(_o(x, y), r * _k, mould);
    }
    _c.restore();
    // A clean leaf on the other side.
    _leafB(150, 52, -0.7, 44, 11, p.leaf);
    // Fruit hanging from the twig.
    _c.drawLine(_o(200, 52), _o(200, 82), _line(p.bark, 2.5));
    _c.drawCircle(_o(200, 108), 27 * _k, _fill(p.gum));
    // White cottony clusters on the twig and the fruit.
    _cotton(176, 52, 5);
    _cotton(236, 53, 5.5);
    _cotton(120, 55, 4.5);
    _cotton(190, 96, 6);
    _cotton(212, 118, 5.5);
    _cotton(194, 124, 4);
    // Labels: clusters (right), sooty mould (left, below the leaf).
    final lead = _line(p.ink, 1.2);
    _c.drawLine(_o(219, 118), _o(240, 112), lead);
    _c.drawLine(_o(240, 60), _o(250, 98), lead);
    _text(labels[0], 244, 100, bold: true, maxWidth: 74);
    _c.drawLine(_o(62, 96), _o(46, 120), lead);
    _text(labels[1], 6, 124, bold: true, maxWidth: 130);
  }

  // leaf_miner: Silvery zig-zag mines, Leaf curls and distorts
  void _leafMinerLeaf() {
    final pale = Color.lerp(p.leaf, p.leafSick, 0.45)!;
    final silver = _line(_Palette.onSoil.withValues(alpha: 0.92), 1);
    // Large pale leaf on its stalk.
    _c.drawLine(_o(14, 116), _o(34, 104), _line(p.bark, 3));
    _leafB(34, 104, -0.12, 186, 44, pale);
    // Silvery serpentine mine, widening as it goes.
    _c.save();
    _c.translate(34 * _k, 104 * _k);
    _c.rotate(-0.12);
    const pts = [
      Offset(28, 4),
      Offset(40, -14),
      Offset(54, 10),
      Offset(68, -20),
      Offset(84, 14),
      Offset(100, -24),
      Offset(118, 18),
      Offset(136, -18),
      Offset(150, 8),
    ];
    for (var i = 0; i + 1 < pts.length; i++) {
      final a = pts[i], b = pts[i + 1];
      final w = 1.6 + i * 0.4;
      final seg = Path()
        ..moveTo(a.dx * _k, a.dy * _k)
        ..quadraticBezierTo(
          (a.dx + b.dx) / 2 * _k,
          (b.dy + (b.dy - a.dy) * 0.15) * _k,
          b.dx * _k,
          b.dy * _k,
        );
      _c.drawPath(seg, _edge(w + 1.4, 0.3));
      _c.drawPath(seg, silver..strokeWidth = w * _k);
    }
    _c.restore();
    // Second leaf: curled and distorted, with a short mine.
    _c.drawLine(_o(250, 166), _o(246, 146), _line(p.bark, 3));
    _leafB(246, 146, -1.3, 84, 20, pale, bend: 24, roll: true);
    _c.save();
    _c.translate(246 * _k, 146 * _k);
    _c.rotate(-1.3);
    final mine = Path()
      ..moveTo(12 * _k, 2 * _k)
      ..quadraticBezierTo(20 * _k, -12 * _k, 28 * _k, 2 * _k)
      ..quadraticBezierTo(36 * _k, 14 * _k, 46 * _k, 4 * _k);
    _c.drawPath(mine, _edge(3, 0.3));
    _c.drawPath(mine, silver..strokeWidth = 1.8 * _k);
    _c.restore();
    // Labels: mines (top), curled leaf (top right).
    final lead = _line(p.ink, 1.2);
    _c.drawLine(_o(118, 30), _o(134, 64), lead);
    _text(labels[0], 30, 6, bold: true, maxWidth: 176);
    _c.drawLine(_o(290, 62), _o(290, 42), lead);
    _text(labels[1], 222, 6, maxWidth: 96);
  }
}
