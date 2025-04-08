import 'dart:math';
import 'package:roofgrid_uk/app/calculator/models/vertical_calculation_input.dart';
import 'package:roofgrid_uk/app/calculator/models/vertical_calculation_result.dart';

/// Calculates the vertical gauge for roof battens based on input measurements
/// and material specifications.
class VerticalCalculationService {
  /// Performs the vertical batten calculation
  static VerticalCalculationResult calculateVertical(
      VerticalCalculationInput inputs) {
    // Validate inputs
    if (inputs.rafterHeights.isEmpty ||
        inputs.rafterHeights.any((h) => h < 500)) {
      throw Exception(
          'Rafter height values must be at least 500mm to calculate a valid vertical gauge solution.');
    }

    // Step 1: Initialize
    final underEaveBatten =
        inputs.materialType == 'Fibre Cement Slate' ? 120 : 0;
    final eaveBattenAdjustment = inputs.materialType == 'Plain Tile' ? 65 : 0;

    late int firstBatten;
    if (inputs.materialType == 'Slate' ||
        inputs.materialType == 'Fibre Cement Slate') {
      firstBatten =
          (inputs.slateTileHeight - inputs.gutterOverhang + 25).round();
    } else if (inputs.materialType == 'Plain Tile') {
      firstBatten =
          (inputs.slateTileHeight - inputs.gutterOverhang - 15).round();
    } else {
      firstBatten =
          (inputs.slateTileHeight - inputs.gutterOverhang - 25).round();
    }

    final eaveBatten = inputs.materialType == 'Plain Tile'
        ? firstBatten - eaveBattenAdjustment
        : firstBatten - inputs.maxGauge;

    final underEaveBattenValue = inputs.materialType == 'Fibre Cement Slate'
        ? (eaveBatten - 120).round()
        : 0;

    final ridgeOffsetMin = inputs.useDryRidge == 'YES' ? 40 : 25;
    const ridgeOffsetMax = 65;

    // Step 2: Calculate remaining length after first batten
    final List<double> remainingLengths = inputs.rafterHeights
        .map((rafterHeight) => rafterHeight - firstBatten - ridgeOffsetMin)
        .toList();

    // Step 3: Min/Max Courses
    final maxRafterHeight = inputs.rafterHeights.reduce(max);
    final minCourses =
        ((maxRafterHeight - firstBatten - ridgeOffsetMax) / inputs.maxGauge)
                .ceil() +
            1;
    final maxCourses =
        ((maxRafterHeight - firstBatten - ridgeOffsetMin) / inputs.minGauge)
                .floor() +
            1;

    // Step 4: Full tiles with single gauge
    dynamic solution;
    String? warning;

    for (int n = minCourses; n <= maxCourses; n++) {
      final List<Map<String, dynamic>> rafterResults = [];

      for (final rafterHeight in inputs.rafterHeights) {
        final battenGauge =
            (rafterHeight - firstBatten - ridgeOffsetMin) / (n - 1);
        final roundedBattenGauge =
            min(max(battenGauge, inputs.minGauge), inputs.maxGauge).round();
        final effectiveRidgeOffset =
            rafterHeight - (firstBatten + (n - 1) * roundedBattenGauge);

        rafterResults.add({
          'battenGauge': roundedBattenGauge,
          'effectiveRidgeOffset': effectiveRidgeOffset,
        });
      }

      bool isWithinRidgeOffset = rafterResults.every((r) =>
          r['effectiveRidgeOffset'] >= ridgeOffsetMin &&
          r['effectiveRidgeOffset'] <= ridgeOffsetMax);

      if (isWithinRidgeOffset) {
        solution = {
          'type': 'full',
          'n_spaces': n,
          'rafterResults': rafterResults
        };
        break;
      }

      // Try with max ridge offset
      final List<Map<String, dynamic>> rafterResultsMax = [];

      for (int i = 0; i < inputs.rafterHeights.length; i++) {
        final battenGauge =
            (inputs.rafterHeights[i] - firstBatten - ridgeOffsetMax) / (n - 1);
        final roundedBattenGauge =
            min(max(battenGauge, inputs.minGauge), inputs.maxGauge).round();
        final effectiveRidgeOffset = inputs.rafterHeights[i] -
            (firstBatten + (n - 1) * roundedBattenGauge);

        rafterResultsMax.add({
          'battenGauge': roundedBattenGauge,
          'effectiveRidgeOffset': effectiveRidgeOffset,
        });
      }

      isWithinRidgeOffset = rafterResultsMax.every((r) =>
          r['effectiveRidgeOffset'] >= ridgeOffsetMin &&
          r['effectiveRidgeOffset'] <= ridgeOffsetMax);

      if (isWithinRidgeOffset) {
        solution = {
          'type': 'full',
          'n_spaces': n,
          'rafterResults': rafterResultsMax
        };
        break;
      }
    }

    // Step 5: Split gauges
    if (solution == null) {
      for (int n = minCourses; n <= maxCourses; n++) {
        for (int n1 = 1; n1 <= n - 2; n1++) {
          final n2 = (n - 2) - n1;
          if (n2 <= 0) continue; // Ensure n2 is positive

          final double maxGauge1 = (maxRafterHeight -
                  firstBatten -
                  ridgeOffsetMin -
                  inputs.maxGauge) /
              n1;
          final double maxGauge2 = (maxRafterHeight -
                  firstBatten -
                  ridgeOffsetMin -
                  n1 * maxGauge1) /
              n2;

          final int roundedMaxGauge1 =
              min(max(maxGauge1, inputs.minGauge), inputs.maxGauge).round();
          final int roundedMaxGauge2 =
              min(max(maxGauge2, inputs.minGauge), inputs.maxGauge).round();

          final List<Map<String, dynamic>> rafterResults = [];

          for (final rafterHeight in inputs.rafterHeights) {
            final double gauge1 = (rafterHeight -
                    firstBatten -
                    ridgeOffsetMin -
                    inputs.maxGauge) /
                n1;
            final double gauge2 =
                (rafterHeight - firstBatten - ridgeOffsetMin - n1 * gauge1) /
                    n2;

            final int roundedGauge1 =
                min(max(gauge1, inputs.minGauge), inputs.maxGauge).round();
            final int roundedGauge2 =
                min(max(gauge2, inputs.minGauge), inputs.maxGauge).round();

            final double remainder = rafterHeight -
                firstBatten -
                ridgeOffsetMin -
                (n1 * roundedGauge1 + n2 * roundedGauge2);
            final double effectiveRidgeOffset = ridgeOffsetMin + remainder;

            rafterResults.add({
              'gauge1': roundedGauge1,
              'gauge2': roundedGauge2,
              'effectiveRidgeOffset': effectiveRidgeOffset,
            });
          }

          bool isWithinRidgeOffset = rafterResults.every((r) =>
              r['effectiveRidgeOffset'] >= ridgeOffsetMin &&
              r['effectiveRidgeOffset'] <= ridgeOffsetMax);

          if (isWithinRidgeOffset) {
            solution = {
              'type': 'split',
              'n_spaces': n,
              'n1': n1,
              'n2': n2,
              'rafterResults': rafterResults
            };
            break;
          }
        }
        if (solution != null) break;
      }
    }

    // Step 6: Cut course
    if (solution == null) {
      final int fullCourses =
          ((maxRafterHeight - firstBatten - ridgeOffsetMin) / inputs.maxGauge)
              .floor();
      final int nSpaces = fullCourses + 1;

      final List<Map<String, dynamic>> rafterResults = [];

      for (final rafterHeight in inputs.rafterHeights) {
        final double cutCourseGauge = rafterHeight -
            firstBatten -
            ridgeOffsetMin -
            fullCourses * inputs.maxGauge;
        final int roundedCutCourseGauge = cutCourseGauge.round();
        final double effectiveRidgeOffset = rafterHeight -
            (firstBatten +
                roundedCutCourseGauge +
                fullCourses * inputs.maxGauge);

        rafterResults.add({
          'cutCourseGauge': roundedCutCourseGauge,
          'fullCourses': fullCourses,
          'effectiveRidgeOffset': effectiveRidgeOffset,
        });
      }

      solution = {
        'type': 'cut',
        'n_spaces': nSpaces,
        'rafterResults': rafterResults
      };
    }

    // Step 7: Add warning for gauge constraints
    if (solution == null) {
      throw Exception(
          'Unable to compute a vertical solution. Please check your inputs: ensure rafter heights are valid and tile specifications (min/max gauge, slate height) are appropriate.');
    }

    bool hasInvalidGauge = false;

    for (final r in solution['rafterResults']) {
      if (solution['type'] == 'full' && r['battenGauge'] < inputs.minGauge) {
        hasInvalidGauge = true;
      } else if (solution['type'] == 'split' &&
          (r['gauge1'] < inputs.minGauge || r['gauge2'] < inputs.minGauge)) {
        hasInvalidGauge = true;
      } else if (solution['type'] == 'cut' && r['cutCourseGauge'] < 75) {
        hasInvalidGauge = true;
      }
    }

    if (hasInvalidGauge) {
      warning =
          'Batten gauge or cut course is below the minimum threshold (75mm) on one or more rafters. Consider adjusting rafter length or tile specifications.';
    }

    // Step 8: Verify totals
    const tolerance = 3;
    List<String> totalWarnings = [];

    for (int index = 0; index < inputs.rafterHeights.length; index++) {
      final rafterHeight = inputs.rafterHeights[index];
      final result = solution['rafterResults'][index];

      double computedTotal;

      if (solution['type'] == 'full') {
        computedTotal = firstBatten +
            (solution['n_spaces'] - 1) * result['battenGauge'] +
            result['effectiveRidgeOffset'];
      } else if (solution['type'] == 'split') {
        computedTotal = firstBatten +
            (solution['n1'] * result['gauge1'] +
                solution['n2'] * result['gauge2'] +
                result['effectiveRidgeOffset']);
      } else {
        computedTotal = firstBatten +
            result['cutCourseGauge'] +
            result['fullCourses'] * inputs.maxGauge +
            result['effectiveRidgeOffset'];
      }

      final difference = (rafterHeight - computedTotal).abs();

      if (difference > tolerance) {
        totalWarnings.add(
            'Computed total (${computedTotal.round()}mm) for rafter ${index + 1} differs from rafter height (${rafterHeight.round()}mm) by ${difference.round()}mm, exceeding tolerance of ${tolerance}mm.');
      }
    }

    if (totalWarnings.isNotEmpty) {
      warning = warning != null
          ? '$warning ${totalWarnings.join(' ')}'
          : totalWarnings.join(' ');
    }

    // Create result object
    final result = solution['rafterResults'][0];

    String gauge;
    if (solution['type'] == 'cut') {
      gauge = '${result['fullCourses']} @ ${inputs.maxGauge.round()}';
    } else if (solution['type'] == 'full') {
      gauge = '${solution['n_spaces'] - 1} @ ${result['battenGauge']}';
    } else {
      gauge = '${solution['n1']} @ ${result['gauge1']}';
    }

    final String? splitGauge = solution['type'] == 'split'
        ? '${solution['n2']} @ ${result['gauge2']}'
        : null;

    return VerticalCalculationResult(
      inputRafter: inputs.rafterHeights[0].round(),
      totalCourses: solution['n_spaces'],
      solution: solution['type'] == 'full'
          ? 'Full Courses'
          : solution['type'] == 'split'
              ? 'Split Gauge'
              : 'Cut Course',
      ridgeOffset: result['effectiveRidgeOffset'].round(),
      underEaveBatten: inputs.materialType == 'Fibre Cement Slate'
          ? underEaveBattenValue
          : null,
      eaveBatten: ['Slate', 'Fibre Cement Slate', 'Plain Tile']
              .contains(inputs.materialType)
          ? eaveBatten.round()
          : null,
      firstBatten: firstBatten,
      cutCourse:
          solution['type'] == 'cut' ? result['cutCourseGauge'].round() : null,
      gauge: gauge,
      splitGauge: splitGauge,
      warning: warning,
    );
  }
}
