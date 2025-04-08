import 'dart:math';
import 'package:roofgrid_uk/app/calculator/models/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/app/calculator/models/horizontal_calculation_result.dart';

/// Calculates the horizontal spacing for roof tiles based on input measurements
/// and tile specifications.
class HorizontalCalculationService {
  /// Performs the horizontal tile spacing calculation
  static HorizontalCalculationResult calculateHorizontal(HorizontalCalculationInput inputs) {
    // Validate inputs
    if (inputs.widths.isEmpty || inputs.widths.any((w) => w < 500)) {
      throw Exception('Width values must be at least 500mm to calculate a valid horizontal solution.');
    }

    // Step 1: Initialize
    var overhangLeft = inputs.useDryVerge == 'YES' ? 40 : 50;
    var overhangRight = inputs.useDryVerge == 'YES' ? 40 : 50;
    final minOverhang = inputs.useDryVerge == 'YES' ? 20 : 25;
    final maxOverhang = inputs.useDryVerge == 'YES' ? 40 : 75;
    
    var widthReduction = 0;
    var useDryVerge = inputs.useDryVerge;
    var useLHTile = inputs.useLHTile;
    
    if (inputs.abutmentSide == 'LEFT') {
      overhangLeft = 0;
      widthReduction = 5;
    } else if (inputs.abutmentSide == 'RIGHT') {
      overhangRight = 0;
      widthReduction = 5;
    } else if (inputs.abutmentSide == 'BOTH') {
      overhangLeft = 0;
      overhangRight = 0;
      widthReduction = 10;
    }
    
    if (inputs.abutmentSide != 'NONE') {
      useDryVerge = 'NO';
      useLHTile = 'NO';
    }
    
    final setSize = inputs.tileCoverWidth > 300 ? 2 : 3;

    // Step 2: Calculate desired total width
    final List<double> desiredTotalWidths = inputs.widths
        .map((width) => width + overhangLeft + overhangRight - widthReduction)
        .toList();
    final maxDesiredTotalWidth = desiredTotalWidths.reduce(max);

    // Step 3: Adjust for LH tile
    final double remainingWidth = useLHTile == 'YES'
        ? maxDesiredTotalWidth - inputs.lhTileWidth
        : maxDesiredTotalWidth;

    // Step 4: Find min and max tile counts
    final double maxCoverWidth = inputs.tileCoverWidth + inputs.maxSpacing;
    final double minCoverWidth = inputs.tileCoverWidth + inputs.minSpacing;
    
    int minTileCount = (remainingWidth / maxCoverWidth).floor();
    int maxTileCount = (remainingWidth / minCoverWidth).floor();
    
    if (useLHTile == 'YES') {
      minTileCount += 1;
      maxTileCount += 1;
    }

    // Step 5: Test each tile count for full tiles
    dynamic solution;
    var tilesWide = 0;
    
    for (int tileCount = minTileCount; tileCount <= maxTileCount; tileCount++) {
      tilesWide = tileCount;
      final regularTiles = tilesWide - (useLHTile == 'YES' ? 1 : 0);
      
      if (regularTiles <= 0) continue;
      
      final double actualCoverWidth = remainingWidth / regularTiles;
      final int roundedCoverWidth = actualCoverWidth.floor();
      final double actualSpacing = roundedCoverWidth - inputs.tileCoverWidth;
      
      if (actualSpacing < inputs.minSpacing || actualSpacing > inputs.maxSpacing) {
        continue;
      }
      
      final double tiledWidth = regularTiles * roundedCoverWidth + (useLHTile == 'YES' ? inputs.lhTileWidth : 0);
      
      final List<Map<String, dynamic>> widthResults = [];
      bool validResult = true;
      
      for (int index = 0; index < desiredTotalWidths.length; index++) {
        final double desiredTotalWidth = desiredTotalWidths[index];
        final double remainingWidth = desiredTotalWidth - tiledWidth;
        final double overhangAdjustment = remainingWidth / 2;
        
        var newOverhangLeft = overhangLeft - overhangAdjustment;
        var newOverhangRight = overhangRight - overhangAdjustment;
        
        newOverhangLeft = min(max(newOverhangLeft, minOverhang), maxOverhang).round().toDouble();
        newOverhangRight = min(max(newOverhangRight, minOverhang), maxOverhang).round().toDouble();
        
        // Respect abutment sides by enforcing 0 overhang
        if (inputs.abutmentSide == 'LEFT' || inputs.abutmentSide == 'BOTH') {
          newOverhangLeft = 0;
        }
        if (inputs.abutmentSide == 'RIGHT' || inputs.abutmentSide == 'BOTH') {
          newOverhangRight = 0;
        }
        
        if ((inputs.abutmentSide != 'LEFT' && inputs.abutmentSide != 'BOTH' && (newOverhangLeft < minOverhang || newOverhangLeft > maxOverhang)) ||
            (inputs.abutmentSide != 'RIGHT' && inputs.abutmentSide != 'BOTH' && (newOverhangRight < minOverhang || newOverhangRight > maxOverhang))) {
          validResult = false;
          break;
        }
        
        final double firstMark = inputs.lhTileWidth + (inputs.tileCoverWidth + actualSpacing) * (setSize - 1) - (overhangLeft - newOverhangLeft);
        final double? secondMark = inputs.crossBonded == 'YES' ? firstMark + ((inputs.tileCoverWidth + actualSpacing) / 2) : null;
        
        final int totalSets = tilesWide > 1 ? ((tilesWide - 1) / setSize).floor() : 0;
        final double baseIncrementMarks = setSize * (inputs.tileCoverWidth + actualSpacing);
        final double minMarks = setSize * (inputs.tileCoverWidth + inputs.minSpacing);
        final double maxMarks = setSize * (inputs.tileCoverWidth + inputs.maxSpacing);
        
        final int adjustedMarks = min(max(baseIncrementMarks, minMarks), maxMarks).round();
        
        widthResults.add({
          'totalWidth': desiredTotalWidth,
          'overhangLeft': newOverhangLeft,
          'overhangRight': newOverhangRight,
          'firstMark': firstMark.round(),
          'secondMark': secondMark?.round(),
          'totalSets': totalSets,
          'adjustedMarks': adjustedMarks,
          'actualSpacing': actualSpacing,
        });
      }
      
      if (!validResult) {
        continue;
      }
      
      solution = {'type': 'full', 'widthResults': widthResults};
      break;
    }

    // Step 6: Split Sets (if full tiles fail)
    if (solution == null) {
      for (int n1 = 1; n1 <= tilesWide - 2; n1++) {
        final int n2 = (tilesWide - 1) - n1;
        if (n2 <= 0) continue;
        
        final List<Map<String, dynamic>> widthResultsSplit = [];
        bool validResult = true;
        
        for (int index = 0; index < desiredTotalWidths.length; index++) {
          final double desiredTotalWidth = desiredTotalWidths[index];
          
          var spacing1 = inputs.maxSpacing;
          var spacing2 = (desiredTotalWidth - 
              ((tilesWide - (useLHTile == 'YES' ? 1 : 0)) * inputs.tileCoverWidth + 
              (useLHTile == 'YES' ? inputs.lhTileWidth : 0) + 
              n1 * spacing1)) / n2;
              
          spacing2 = min(max(spacing2, inputs.minSpacing), inputs.maxSpacing).round().toDouble();
          
          if (spacing2 < (inputs.minSpacing + inputs.maxSpacing) / 2) {
            final double totalSpacing = (desiredTotalWidth - 
                ((tilesWide - (useLHTile == 'YES' ? 1 : 0)) * inputs.tileCoverWidth + 
                (useLHTile == 'YES' ? inputs.lhTileWidth : 0))) / (tilesWide - 1);
                
            spacing1 = min(max(totalSpacing, inputs.minSpacing), inputs.maxSpacing).round().toDouble();
            spacing2 = spacing1;
          }
          
          final double tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) * inputs.tileCoverWidth + 
              (useLHTile == 'YES' ? inputs.lhTileWidth : 0) + 
              n1 * spacing1 + n2 * spacing2;
              
          var newOverhangLeft = overhangLeft;
          var newOverhangRight = overhangRight;
          
          final double remainingWidth = desiredTotalWidth - tiledWidth;
          final double overhangAdjustment = remainingWidth / 2;
          
          newOverhangLeft -= overhangAdjustment;
          newOverhangRight -= overhangAdjustment;
          
          newOverhangLeft = min(max(newOverhangLeft, minOverhang), maxOverhang).round().toDouble();
          newOverhangRight = min(max(newOverhangRight, minOverhang), maxOverhang).round().toDouble();
          
          // Respect abutment sides by enforcing 0 overhang
          if (inputs.abutmentSide == 'LEFT' || inputs.abutmentSide == 'BOTH') {
            newOverhangLeft = 0;
          }
          if (inputs.abutmentSide == 'RIGHT' || inputs.abutmentSide == 'BOTH') {
            newOverhangRight = 0;
          }
          
          if ((inputs.abutmentSide != 'LEFT' && inputs.abutmentSide != 'BOTH' && (newOverhangLeft < minOverhang || newOverhangLeft > maxOverhang)) ||
              (inputs.abutmentSide != 'RIGHT' && inputs.abutmentSide != 'BOTH' && (newOverhangRight < minOverhang || newOverhangRight > maxOverhang))) {
            validResult = false;
            break;
          }
          
          final double firstMark = inputs.lhTileWidth + (inputs.tileCoverWidth + spacing1) * (setSize - 1) - (overhangLeft - newOverhangLeft);
          final double? secondMark = inputs.crossBonded == 'YES' ? firstMark + ((inputs.tileCoverWidth + spacing1) / 2) : null;
          
          final int sets1 = (n1 / setSize).floor();
          final int sets2 = (n2 / setSize).floor();
          
          final double baseIncrementMarks1 = setSize * (inputs.tileCoverWidth + spacing1);
          final double baseIncrementMarks2 = setSize * (inputs.tileCoverWidth + spacing2);
          final double minMarks = setSize * (inputs.tileCoverWidth + inputs.minSpacing);
          final double maxMarks = setSize * (inputs.tileCoverWidth + inputs.maxSpacing);
          
          final int adjustedMarks1 = min(max(baseIncrementMarks1, minMarks), maxMarks).round();
          final int adjustedMarks2 = min(max(baseIncrementMarks2, minMarks), maxMarks).round();
          
          widthResultsSplit.add({
            'totalWidth': desiredTotalWidth,
            'overhangLeft': newOverhangLeft,
            'overhangRight': newOverhangRight,
            'firstMark': firstMark.round(),
            'secondMark': secondMark?.round(),
            'sets1': sets1,
            'sets2': sets2,
            'adjustedMarks1': adjustedMarks1,
            'adjustedMarks2': adjustedMarks2,
            'spacing1': spacing1,
            'spacing2': spacing2,
          });
        }
        
        if (!validResult) {
          continue;
        }
        
        solution = {'type': 'split', 'widthResults': widthResultsSplit};
        break;
      }
    }

    // Step 7: Cut Tile (if split sets fail)
    if (solution == null) {
      final double maxTotalWidth = desiredTotalWidths.reduce(max);
      var actualSpacing = inputs.maxSpacing;
      
      var tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) * inputs.tileCoverWidth + 
          (useLHTile == 'YES' ? inputs.lhTileWidth : 0) + 
          (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);
          
      if (tiledWidth > maxTotalWidth) {
        final double excessWidth = tiledWidth - maxTotalWidth;
        final double spacingReduction = excessWidth / (tilesWide > 1 ? tilesWide - 1 : 1);
        
        actualSpacing = inputs.maxSpacing - spacingReduction;
        actualSpacing = max(actualSpacing, inputs.minSpacing).round().toDouble();
        
        tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) * inputs.tileCoverWidth + 
            (useLHTile == 'YES' ? inputs.lhTileWidth : 0) + 
            (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);
      }
      
      var cutTileWidth = maxTotalWidth - 
          (tilesWide > 1 ? (tilesWide - 1) * (inputs.tileCoverWidth + actualSpacing) : 0) - 
          (useLHTile == 'YES' ? inputs.lhTileWidth : inputs.tileCoverWidth);
      
      if (cutTileWidth < inputs.tileCoverWidth / 2 && cutTileWidth < 100) {
        final double targetCutWidth = max(inputs.tileCoverWidth / 2, 100);
        final double targetTiledWidth = maxTotalWidth - targetCutWidth;
        
        final double totalSpacing = (targetTiledWidth - 
            ((tilesWide - (useLHTile == 'YES' ? 1 : 0)) * inputs.tileCoverWidth + 
            (useLHTile == 'YES' ? inputs.lhTileWidth : 0))) / 
            (tilesWide > 1 ? tilesWide - 1 : 1);
        
        actualSpacing = min(max(totalSpacing, inputs.minSpacing), inputs.maxSpacing).round().toDouble();
        
        tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) * inputs.tileCoverWidth + 
            (useLHTile == 'YES' ? inputs.lhTileWidth : 0) + 
            (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);
            
        cutTileWidth = maxTotalWidth - tiledWidth;
      }
      
      cutTileWidth = cutTileWidth.round();
      
      final List<Map<String, dynamic>> widthResultsCut = [];
      
      for (int index = 0; index < desiredTotalWidths.length; index++) {
        final double desiredTotalWidth = desiredTotalWidths[index];
        
        final double tiledWidth = (tilesWide > 1 ? (tilesWide - 1) * (inputs.tileCoverWidth + actualSpacing) : 0) + 
            (useLHTile == 'YES' ? inputs.lhTileWidth : inputs.tileCoverWidth) + cutTileWidth;
            
        final double remainingWidth = desiredTotalWidth - tiledWidth;
        
        var newOverhangLeft = overhangLeft;
        var newOverhangRight = overhangRight;
        
        final double overhangAdjustment = remainingWidth / 2;
        
        newOverhangLeft -= overhangAdjustment;
        newOverhangRight -= overhangAdjustment;
        
        newOverhangLeft = min(max(newOverhangLeft, minOverhang), maxOverhang).round().toDouble();
        newOverhangRight = min(max(newOverhangRight, minOverhang), maxOverhang).round().toDouble();
        
        // Respect abutment sides by enforcing 0 overhang
        if (inputs.abutmentSide == 'LEFT' || inputs.abutmentSide == 'BOTH') {
          newOverhangLeft = 0;
        }
        if (inputs.abutmentSide == 'RIGHT' || inputs.abutmentSide == 'BOTH') {
          newOverhangRight = 0;
        }
        
        final double firstMark = inputs.lhTileWidth + (inputs.tileCoverWidth + actualSpacing) * (setSize - 1) - (overhangLeft - newOverhangLeft);
        final double? secondMark = inputs.crossBonded == 'YES' ? firstMark + ((inputs.tileCoverWidth + actualSpacing) / 2) : null;
        
        final int totalSets = tilesWide > 1 ? ((tilesWide - 1) / setSize).floor() : 0;
        final double baseIncrementMarks = setSize * (inputs.tileCoverWidth + actualSpacing);
        final double minMarks = setSize * (inputs.tileCoverWidth + inputs.minSpacing);
        final double maxMarks = setSize * (inputs.tileCoverWidth + inputs.maxSpacing);
        
        final int adjustedMarks = min(max(baseIncrementMarks, minMarks), maxMarks).round();
        
        widthResultsCut.add({
          'totalWidth': desiredTotalWidth,
          'overhangLeft': newOverhangLeft,
          'overhangRight': newOverhangRight,
          'firstMark': firstMark.round(),
          'secondMark': secondMark?.round(),
          'totalSets': totalSets,
          'adjustedMarks': adjustedMarks,
          'actualSpacing': actualSpacing,
          'cutTileWidth': cutTileWidth,
        });
      }
      
      solution = {'type': 'cut', 'widthResults': widthResultsCut};
    }

    // Step 8: Verify solution exists
    if (solution == null) {
      throw Exception('Unable to compute a horizontal solution. Please check your inputs: ensure widths are valid and tile specifications (tile cover width, min/max spacing) are appropriate.');
    }

    // Create result object
    final result = solution['widthResults'][0];
    final solutionType = solution['type'];
    
    return HorizontalCalculationResult(
      width: inputs.widths[0].round(),
      solution: solutionType == 'full'
          ? 'Even Sets'
          : solutionType == 'split'
              ? 'Split Sets'
              : 'Cut Course',
      newWidth: result['totalWidth'].round(),
      lhOverhang: inputs.useDryVerge == 'NO' && inputs.abutmentSide == 'NONE' ? result['overhangLeft'].round() : null,
      rhOverhang: inputs.useDryVerge == 'NO' && inputs.abutmentSide == 'NONE' ? result['overhangRight'].round() : null,
      cutTile: solutionType == 'cut' ? result['cutTileWidth'].round() : null,
      firstMark: result['firstMark'].round(),
      secondMark: inputs.crossBonded == 'YES' ? result['secondMark'].round() : null,
      marks: solutionType == 'split'
          ? '${result['sets2']} sets of $setSize @ ${result['adjustedMarks2']}'
          : '${result['totalSets']} sets of $setSize @ ${result['adjustedMarks']}',
      splitMarks: solutionType == 'split'
          ? '${result['sets1']} sets of $setSize @ ${result['adjustedMarks1']}'
          : null,
    );
  }
}
