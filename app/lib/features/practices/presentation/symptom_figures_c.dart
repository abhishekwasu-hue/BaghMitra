part of 'practice_figure_view.dart';

/// Symptom drawings, group C (batch 2). Each draws in the painter's 320 x 170 space
/// with the painter's helpers and writes its labels (in order) from [labels].
extension _SymptomFiguresC on _FigurePainter {
  // mites: Pale yellow along the veins, Fine webbing: dusty look, Rough rind (russeting)
  void _mitesLeaf() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
    _text(labels[2], 10, 90.0, maxWidth: 300);
  }

  // thrips: Ring-like scar round the stalk, Irregular patches on the rind
  void _thripsFruit() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
  }

  // heat_drop: Hot summer, Second wave of fruit drop
  void _heatDropTree() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
  }
}
