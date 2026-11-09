// Symptom drawings, group A (batch 2), Marathi, phone width, light and dark.
//   flutter test --update-goldens test/goldens/symptom_figures_a_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/features/practices/data/practice_cards.dart';
import 'package:flutter_test/flutter_test.dart';

import 'practice_figures_golden_test.dart' show figureGallery;

void main() => figureGallery('symptom_figures_a', const [
  PracticeFigure(PracticeFigureKind.cankerSpots),
  PracticeFigure(PracticeFigureKind.mildewLeaf),
  PracticeFigure(PracticeFigureKind.anthracnoseLeaf),
  PracticeFigure(PracticeFigureKind.greeningLeaf),
]);
