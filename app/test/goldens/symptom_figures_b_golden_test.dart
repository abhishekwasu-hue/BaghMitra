// Symptom drawings, group B (batch 2), Marathi, phone width, light and dark.
//   flutter test --update-goldens test/goldens/symptom_figures_b_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/features/practices/data/practice_cards.dart';
import 'package:flutter_test/flutter_test.dart';

import 'practice_figures_golden_test.dart' show figureGallery;

void main() => figureGallery('symptom_figures_b', const [
  PracticeFigure(PracticeFigureKind.psyllaShoot),
  PracticeFigure(PracticeFigureKind.aphidShoot),
  PracticeFigure(PracticeFigureKind.mealybugTwig),
  PracticeFigure(PracticeFigureKind.leafMinerLeaf),
]);
