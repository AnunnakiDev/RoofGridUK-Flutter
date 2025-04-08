Horizontal Calculation Logic

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateHorizontal = calculateHorizontal;
/**
 * Calculates the horizontal spacing for roof tiles based on input measurements
 * and tile specifications.
 *
 * @param inputs The inputs required for horizontal tile spacing calculation
 * @returns The horizontal calculation results
 */
function calculateHorizontal(inputs) {
    let { widths, tileCoverWidth, minSpacing, maxSpacing, useDryVerge, abutmentSide, useLHTile, lhTileWidth, crossBonded } = inputs;
    // Validate inputs
    if (!widths.length || widths.some(w => w < 500)) {
        throw new Error('Width values must be at least 500mm to calculate a valid horizontal solution.');
    }
    // Step 1: Initialize
    let overhangLeft = useDryVerge === 'YES' ? 40 : 50;
    let overhangRight = useDryVerge === 'YES' ? 40 : 50;
    const minOverhang = useDryVerge === 'YES' ? 20 : 25;
    const maxOverhang = useDryVerge === 'YES' ? 40 : 75;
    let widthReduction = 0;
    if (abutmentSide === 'LEFT') {
        overhangLeft = 0;
        widthReduction = 5;
    }
    else if (abutmentSide === 'RIGHT') {
        overhangRight = 0;
        widthReduction = 5;
    }
    else if (abutmentSide === 'BOTH') {
        overhangLeft = 0;
        overhangRight = 0;
        widthReduction = 10;
    }
    if (abutmentSide !== 'NONE') {
        useDryVerge = 'NO';
        useLHTile = 'NO';
    }
    const setSize = tileCoverWidth > 300 ? 2 : 3;
    // Step 2: Calculate desired total width
    const desiredTotalWidths = widths.map(width => width + overhangLeft + overhangRight - widthReduction);
    const maxDesiredTotalWidth = Math.max(...desiredTotalWidths);
    // Step 3: Adjust for LH tile
    const remainingWidth = useLHTile === 'YES' ? maxDesiredTotalWidth - lhTileWidth : maxDesiredTotalWidth;
    // Step 4: Find min and max tile counts
    const maxCoverWidth = tileCoverWidth + maxSpacing;
    const minCoverWidth = tileCoverWidth + minSpacing;
    let minTileCount = Math.floor(remainingWidth / maxCoverWidth);
    let maxTileCount = Math.floor(remainingWidth / minCoverWidth);
    if (useLHTile === 'YES') {
        minTileCount += 1;
        maxTileCount += 1;
    }
    // Step 5: Test each tile count for full tiles
    let solution = null;
    let tilesWide = 0;
    for (let tileCount = minTileCount; tileCount <= maxTileCount; tileCount++) {
        tilesWide = tileCount;
        const regularTiles = tilesWide - (useLHTile === 'YES' ? 1 : 0);
        if (regularTiles <= 0)
            continue;
        const actualCoverWidth = remainingWidth / regularTiles;
        const roundedCoverWidth = Math.floor(actualCoverWidth);
        const actualSpacing = roundedCoverWidth - tileCoverWidth;
        if (actualSpacing < minSpacing || actualSpacing > maxSpacing) {
            continue;
        }
        const tiledWidth = regularTiles * roundedCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0);
        const widthResults = desiredTotalWidths.map((desiredTotalWidth, index) => {
            const remainingWidth = desiredTotalWidth - tiledWidth;
            const overhangAdjustment = remainingWidth / 2;
            let newOverhangLeft = overhangLeft - overhangAdjustment;
            let newOverhangRight = overhangRight - overhangAdjustment;
            newOverhangLeft = Math.round(Math.min(Math.max(newOverhangLeft, minOverhang), maxOverhang));
            newOverhangRight = Math.round(Math.min(Math.max(newOverhangRight, minOverhang), maxOverhang));
            // Respect abutment sides by enforcing 0 overhang
            if (abutmentSide === 'LEFT' || abutmentSide === 'BOTH') {
                newOverhangLeft = 0;
            }
            if (abutmentSide === 'RIGHT' || abutmentSide === 'BOTH') {
                newOverhangRight = 0;
            }
            if ((abutmentSide !== 'LEFT' && abutmentSide !== 'BOTH' && (newOverhangLeft < minOverhang || newOverhangLeft > maxOverhang)) ||
                (abutmentSide !== 'RIGHT' && abutmentSide !== 'BOTH' && (newOverhangRight < minOverhang || newOverhangRight > maxOverhang))) {
                return null;
            }
            const firstMark = lhTileWidth + (tileCoverWidth + actualSpacing) * (setSize - 1) - (overhangLeft - newOverhangLeft);
            const secondMark = crossBonded === 'YES' ? firstMark + ((tileCoverWidth + actualSpacing) / 2) : undefined;
            const totalSets = tilesWide > 1 ? Math.floor((tilesWide - 1) / setSize) : 0;
            const baseIncrementMarks = setSize * (tileCoverWidth + actualSpacing);
            const minMarks = setSize * (tileCoverWidth + minSpacing);
            const maxMarks = setSize * (tileCoverWidth + maxSpacing);
            const adjustedMarks = Math.round(Math.min(Math.max(baseIncrementMarks, minMarks), maxMarks));
            return {
                totalWidth: desiredTotalWidth,
                overhangLeft: newOverhangLeft,
                overhangRight: newOverhangRight,
                firstMark: Math.round(firstMark),
                secondMark: secondMark ? Math.round(secondMark) : undefined,
                totalSets,
                adjustedMarks,
                actualSpacing,
            };
        });
        if (widthResults.some(result => result === null)) {
            continue;
        }
        solution = { type: 'full', widthResults: widthResults };
        break;
    }
    // Step 6: Split Sets (if full tiles fail)
    if (!solution) {
        for (let n1 = 1; n1 <= tilesWide - 2; n1++) {
            const n2 = (tilesWide - 1) - n1;
            if (n2 <= 0)
                continue;
            const widthResultsSplit = desiredTotalWidths.map((desiredTotalWidth, index) => {
                let spacing1 = maxSpacing;
                let spacing2 = (desiredTotalWidth - ((tilesWide - (useLHTile === 'YES' ? 1 : 0)) * tileCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0) + n1 * spacing1)) / n2;
                spacing2 = Math.round(Math.min(Math.max(spacing2, minSpacing), maxSpacing));
                if (spacing2 < (minSpacing + maxSpacing) / 2) {
                    const totalSpacing = (desiredTotalWidth - ((tilesWide - (useLHTile === 'YES' ? 1 : 0)) * tileCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0))) / (tilesWide - 1);
                    spacing1 = Math.round(Math.min(Math.max(totalSpacing, minSpacing), maxSpacing));
                    spacing2 = spacing1;
                }
                const tiledWidth = (tilesWide - (useLHTile === 'YES' ? 1 : 0)) * tileCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0) + n1 * spacing1 + n2 * spacing2;
                let newOverhangLeft = overhangLeft;
                let newOverhangRight = overhangRight;
                const remainingWidth = desiredTotalWidth - tiledWidth;
                const overhangAdjustment = remainingWidth / 2;
                newOverhangLeft -= overhangAdjustment;
                newOverhangRight -= overhangAdjustment;
                newOverhangLeft = Math.round(Math.min(Math.max(newOverhangLeft, minOverhang), maxOverhang));
                newOverhangRight = Math.round(Math.min(Math.max(newOverhangRight, minOverhang), maxOverhang));
                // Respect abutment sides by enforcing 0 overhang
                if (abutmentSide === 'LEFT' || abutmentSide === 'BOTH') {
                    newOverhangLeft = 0;
                }
                if (abutmentSide === 'RIGHT' || abutmentSide === 'BOTH') {
                    newOverhangRight = 0;
                }
                if ((abutmentSide !== 'LEFT' && abutmentSide !== 'BOTH' && (newOverhangLeft < minOverhang || newOverhangLeft > maxOverhang)) ||
                    (abutmentSide !== 'RIGHT' && abutmentSide !== 'BOTH' && (newOverhangRight < minOverhang || newOverhangRight > maxOverhang))) {
                    return null;
                }
                const firstMark = lhTileWidth + (tileCoverWidth + spacing1) * (setSize - 1) - (overhangLeft - newOverhangLeft);
                const secondMark = crossBonded === 'YES' ? firstMark + ((tileCoverWidth + spacing1) / 2) : undefined;
                const sets1 = Math.floor(n1 / setSize);
                const sets2 = Math.floor(n2 / setSize);
                const baseIncrementMarks1 = setSize * (tileCoverWidth + spacing1);
                const baseIncrementMarks2 = setSize * (tileCoverWidth + spacing2);
                const minMarks = setSize * (tileCoverWidth + minSpacing);
                const maxMarks = setSize * (tileCoverWidth + maxSpacing);
                const adjustedMarks1 = Math.round(Math.min(Math.max(baseIncrementMarks1, minMarks), maxMarks));
                const adjustedMarks2 = Math.round(Math.min(Math.max(baseIncrementMarks2, minMarks), maxMarks));
                return {
                    totalWidth: desiredTotalWidth,
                    overhangLeft: newOverhangLeft,
                    overhangRight: newOverhangRight,
                    firstMark: Math.round(firstMark),
                    secondMark: secondMark ? Math.round(secondMark) : undefined,
                    sets1,
                    sets2,
                    adjustedMarks1,
                    adjustedMarks2,
                    spacing1,
                    spacing2,
                };
            });
            if (widthResultsSplit.some(result => result === null)) {
                continue;
            }
            solution = { type: 'split', widthResults: widthResultsSplit };
            break;
        }
    }
    // Step 7: Cut Tile (if split sets fail)
    if (!solution) {
        const maxTotalWidth = Math.max(...desiredTotalWidths);
        let actualSpacing = maxSpacing;
        let tiledWidth = (tilesWide - (useLHTile === 'YES' ? 1 : 0)) * tileCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0) + (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);
        if (tiledWidth > maxTotalWidth) {
            const excessWidth = tiledWidth - maxTotalWidth;
            const spacingReduction = excessWidth / (tilesWide > 1 ? tilesWide - 1 : 1);
            actualSpacing = maxSpacing - spacingReduction;
            actualSpacing = Math.round(Math.max(actualSpacing, minSpacing));
            tiledWidth = (tilesWide - (useLHTile === 'YES' ? 1 : 0)) * tileCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0) + (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);
        }
        let cutTileWidth = maxTotalWidth - (tilesWide > 1 ? (tilesWide - 1) * (tileCoverWidth + actualSpacing) : 0) - (useLHTile === 'YES' ? lhTileWidth : tileCoverWidth);
        if (cutTileWidth < tileCoverWidth / 2 && cutTileWidth < 100) {
            const targetCutWidth = Math.max(tileCoverWidth / 2, 100);
            const targetTiledWidth = maxTotalWidth - targetCutWidth;
            const totalSpacing = (targetTiledWidth - ((tilesWide - (useLHTile === 'YES' ? 1 : 0)) * tileCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0))) / (tilesWide > 1 ? tilesWide - 1 : 1);
            actualSpacing = Math.round(Math.min(Math.max(totalSpacing, minSpacing), maxSpacing));
            tiledWidth = (tilesWide - (useLHTile === 'YES' ? 1 : 0)) * tileCoverWidth + (useLHTile === 'YES' ? lhTileWidth : 0) + (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);
            cutTileWidth = maxTotalWidth - tiledWidth;
        }
        cutTileWidth = Math.round(cutTileWidth);
        const widthResultsCut = desiredTotalWidths.map((desiredTotalWidth, index) => {
            const tiledWidth = (tilesWide > 1 ? (tilesWide - 1) * (tileCoverWidth + actualSpacing) : 0) + (useLHTile === 'YES' ? lhTileWidth : tileCoverWidth) + cutTileWidth;
            const remainingWidth = desiredTotalWidth - tiledWidth;
            let newOverhangLeft = overhangLeft;
            let newOverhangRight = overhangRight;
            const overhangAdjustment = remainingWidth / 2;
            newOverhangLeft -= overhangAdjustment;
            newOverhangRight -= overhangAdjustment;
            newOverhangLeft = Math.round(Math.min(Math.max(newOverhangLeft, minOverhang), maxOverhang));
            newOverhangRight = Math.round(Math.min(Math.max(newOverhangRight, minOverhang), maxOverhang));
            // Respect abutment sides by enforcing 0 overhang
            if (abutmentSide === 'LEFT' || abutmentSide === 'BOTH') {
                newOverhangLeft = 0;
            }
            if (abutmentSide === 'RIGHT' || abutmentSide === 'BOTH') {
                newOverhangRight = 0;
            }
            const firstMark = lhTileWidth + (tileCoverWidth + actualSpacing) * (setSize - 1) - (overhangLeft - newOverhangLeft);
            const secondMark = crossBonded === 'YES' ? firstMark + ((tileCoverWidth + actualSpacing) / 2) : undefined;
            const totalSets = tilesWide > 1 ? Math.floor((tilesWide - 1) / setSize) : 0;
            const baseIncrementMarks = setSize * (tileCoverWidth + actualSpacing);
            const minMarks = setSize * (tileCoverWidth + minSpacing);
            const maxMarks = setSize * (tileCoverWidth + maxSpacing);
            const adjustedMarks = Math.round(Math.min(Math.max(baseIncrementMarks, minMarks), maxMarks));
            return {
                totalWidth: desiredTotalWidth,
                overhangLeft: newOverhangLeft,
                overhangRight: newOverhangRight,
                firstMark: Math.round(firstMark),
                secondMark: secondMark ? Math.round(secondMark) : undefined,
                totalSets,
                adjustedMarks,
                actualSpacing,
                cutTileWidth,
            };
        });
        solution = { type: 'cut', widthResults: widthResultsCut };
    }
    // Step 8: Verify solution exists
    if (!solution) {
        throw new Error('Unable to compute a horizontal solution. Please check your inputs: ensure widths are valid and tile specifications (tile cover width, min/max spacing) are appropriate.');
    }
    // Updated Return Statement
    return {
        "Width": widths[0], // Assuming single width for simplicity
        "Solution": solution.type === 'full' ? "Even Sets" : solution.type === 'split' ? "Split Sets" : "Cut Course",
        "New Width": solution.widthResults[0].totalWidth,
        ...(useDryVerge === 'NO' && abutmentSide === 'NONE' && { "LH Overhang": solution.widthResults[0].overhangLeft }),
        ...(useDryVerge === 'NO' && abutmentSide === 'NONE' && { "RH Overhang": solution.widthResults[0].overhangRight }),
        ...(solution.type === 'cut' && { "Cut Tile": solution.widthResults[0].cutTileWidth }),
        "1st Mark": solution.widthResults[0].firstMark,
        ...(crossBonded === 'YES' && { "2nd Mark": solution.widthResults[0].secondMark }),
        "Marks": `${solution.type === 'split' ? solution.widthResults[0].sets2 : solution.widthResults[0].totalSets} sets of ${setSize} @ ${solution.type === 'split' ? solution.widthResults[0].adjustedMarks2 : solution.widthResults[0].adjustedMarks}`,
        ...(solution.type === 'split' && { "Split Marks": `${solution.widthResults[0].sets1} sets of ${setSize} @ ${solution.widthResults[0].adjustedMarks1}` })
    };
}