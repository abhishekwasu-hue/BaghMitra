part of 'practice_figure_view.dart';

/// Symptom drawings, group B (batch 2). Each draws in the painter's 320 x 170 space
/// with the painter's helpers and writes its labels (in order) from [labels].
extension _SymptomFiguresB on _FigurePainter {
  // psylla: Yellow-orange nymphs on shoot tips, White waxy threads, New leaves curl
  void _psyllaShoot() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
    _text(labels[2], 10, 90.0, maxWidth: 300);
  }

  // aphids: Black or brown aphid colonies, Cup-shaped, crinkled leaves
  void _aphidShoot() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
  }

  // mealybug: White cottony clusters, Sooty mould
  void _mealybugTwig() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
  }

  // leaf_miner: Silvery zig-zag mines, Leaf curls and distorts
  void _leafMinerLeaf() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
  }
}
