part of 'practice_figure_view.dart';

/// Symptom drawings, group A (batch 2). Each draws in the painter's 320 x 170 space
/// with the painter's helpers and writes its labels (in order) from [labels].
extension _SymptomFiguresA on _FigurePainter {
  // canker: Raised, rough, brown corky spots, Yellow halo, On fruit: spots stay in the rind
  void _cankerSpots() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
    _text(labels[2], 10, 90.0, maxWidth: 300);
  }

  // powdery_mildew: White powder, Leaves twist and curl
  void _mildewLeaf() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
  }

  // anthracnose: Light-tan patch, purple edge, Tiny black dots, Dead twig: silvery grey
  void _anthracnoseLeaf() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
    _text(labels[2], 10, 90.0, maxWidth: 300);
  }

  // greening: Yellow leaf with green islands, Fruit small, lopsided, green
  void _greeningLeaf() {
    _text(labels[0], 10, 10.0, maxWidth: 300);
    _text(labels[1], 10, 50.0, maxWidth: 300);
  }
}
