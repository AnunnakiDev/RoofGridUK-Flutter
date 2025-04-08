Vertical Calculator Logic

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateVertical = calculateVertical;
/**
 * Calculates the vertical gauge for roof battens based on input measurements
 * and material specifications.
 *
 * @param inputs The inputs required for vertical batten calculation
 * @returns The vertical calculation results
 */
function calculateVertical(inputs) {
    const { rafterHeights, gutterOverhang, materialType, slateTileHeight, maxGauge, minGauge, useDryRidge } = inputs;
    // Validate inputs
    if (!rafterHeights.length || rafterHeights.some(h => h < 500)) {
        throw new Error('Rafter height values must be at least 500mm to calculate a valid vertical gauge solution.');
    }
    // Step 1: Initialize
    const underEaveBatten = materialType === 'Fibre Cement Slate' ? 120 : 0;
    const eaveBattenAdjustment = materialType === 'Plain Tile' ? 65 : 0;
    let firstBatten;
    if (materialType === 'Slate' || materialType === 'Fibre Cement Slate') {
        firstBatten = slateTileHeight - gutterOverhang + 25;
    }
    else if (materialType === 'Plain Tile') {
        firstBatten = slateTileHeight - gutterOverhang - 15;
    }
    else {
        firstBatten = slateTileHeight - gutterOverhang - 25;
    }
    const eaveBatten = materialType === 'Plain Tile' ? firstBatten - eaveBattenAdjustment : firstBatten - maxGauge;
    const underEaveBattenValue = materialType === 'Fibre Cement Slate' ? eaveBatten - 120 : 0;
    const ridgeOffsetMin = useDryRidge === 'YES' ? 40 : 25;
    const ridgeOffsetMax = 65;
    // Step 2: Calculate remaining length after first batten
    const remainingLengths = rafterHeights.map(rafterHeight => rafterHeight - firstBatten - ridgeOffsetMin);
    // Step 3: Min/Max Courses
    const maxRafterHeight = Math.max(...rafterHeights);
    const minCourses = Math.ceil((maxRafterHeight - firstBatten - ridgeOffsetMax) / maxGauge) + 1;
    const maxCourses = Math.floor((maxRafterHeight - firstBatten - ridgeOffsetMin) / minGauge) + 1;
    // Step 4: Full tiles with single gauge
    let solution = null;
    let warning;
    for (let n = minCourses; n <= maxCourses; n++) {
        const rafterResults = rafterHeights.map((rafterHeight) => {
            const battenGauge = (rafterHeight - firstBatten - ridgeOffsetMin) / (n - 1);
            const roundedBattenGauge = Math.round(Math.min(Math.max(battenGauge, minGauge), maxGauge));
            const effectiveRidgeOffset = rafterHeight - (firstBatten + (n - 1) * roundedBattenGauge);
            return { battenGauge: roundedBattenGauge, effectiveRidgeOffset };
        });
        const isWithinRidgeOffset = rafterResults.every(r => r.effectiveRidgeOffset >= ridgeOffsetMin && r.effectiveRidgeOffset <= ridgeOffsetMax);
        if (isWithinRidgeOffset) {
            solution = { type: 'full', n_spaces: n, rafterResults };
            break;
        }
        const rafterResultsMax = rafterHeights.map((r, i) => {
            const battenGauge = (rafterHeights[i] - firstBatten - ridgeOffsetMax) / (n - 1);
            const roundedBattenGauge = Math.round(Math.min(Math.max(battenGauge, minGauge), maxGauge));
            const effectiveRidgeOffset = rafterHeights[i] - (firstBatten + (n - 1) * roundedBattenGauge);
            return { battenGauge: roundedBattenGauge, effectiveRidgeOffset };
        });
        const isWithinRidgeOffsetMax = rafterResultsMax.every(r => r.effectiveRidgeOffset >= ridgeOffsetMin && r.effectiveRidgeOffset <= ridgeOffsetMax);
        if (isWithinRidgeOffsetMax) {
            solution = { type: 'full', n_spaces: n, rafterResults: rafterResultsMax };
            break;
        }
    }
    // Step 5: Split gauges
    if (!solution) {
        for (let n = minCourses; n <= maxCourses; n++) {
            for (let n1 = 1; n1 <= n - 2; n1++) {
                const n2 = (n - 2) - n1;
                if (n2 <= 0)
                    continue; // Ensure n2 is positive
                const maxGauge1 = (maxRafterHeight - firstBatten - ridgeOffsetMin - maxGauge) / n1;
                const maxGauge2 = (maxRafterHeight - firstBatten - ridgeOffsetMin - n1 * maxGauge1) / n2;
                const roundedMaxGauge1 = Math.round(Math.min(Math.max(maxGauge1, minGauge), maxGauge));
                const roundedMaxGauge2 = Math.round(Math.min(Math.max(maxGauge2, minGauge), maxGauge));
                const rafterResults = rafterHeights.map((rafterHeight) => {
                    const gauge1 = (rafterHeight - firstBatten - ridgeOffsetMin - maxGauge) / n1;
                    const gauge2 = (rafterHeight - firstBatten - ridgeOffsetMin - n1 * gauge1) / n2;
                    const roundedGauge1 = Math.round(Math.min(Math.max(gauge1, minGauge), maxGauge));
                    const roundedGauge2 = Math.round(Math.min(Math.max(gauge2, minGauge), maxGauge));
                    const remainder = rafterHeight - firstBatten - ridgeOffsetMin - (n1 * roundedGauge1 + n2 * roundedGauge2);
                    const effectiveRidgeOffset = ridgeOffsetMin + remainder;
                    return { gauge1: roundedGauge1, gauge2: roundedGauge2, effectiveRidgeOffset };
                });
                const isWithinRidgeOffset = rafterResults.every(r => r.effectiveRidgeOffset >= ridgeOffsetMin && r.effectiveRidgeOffset <= ridgeOffsetMax);
                if (isWithinRidgeOffset) {
                    solution = { type: 'split', n_spaces: n, n1, n2, rafterResults };
                    break;
                }
            }
            if (solution)
                break;
        }
    }
    // Step 6: Cut course
    if (!solution) {
        const fullCourses = Math.floor((maxRafterHeight - firstBatten - ridgeOffsetMin) / maxGauge);
        const n_spaces = fullCourses + 1;
        const rafterResults = rafterHeights.map((rafterHeight) => {
            const cutCourseGauge = rafterHeight - firstBatten - ridgeOffsetMin - fullCourses * maxGauge;
            const roundedCutCourseGauge = Math.round(cutCourseGauge);
            const effectiveRidgeOffset = rafterHeight - (firstBatten + roundedCutCourseGauge + fullCourses * maxGauge);
            return { cutCourseGauge: roundedCutCourseGauge, fullCourses, effectiveRidgeOffset };
        });
        solution = { type: 'cut', n_spaces, rafterResults };
    }
    // Step 7: Add warning for gauge constraints
    if (!solution) {
        throw new Error('Unable to compute a vertical solution. Please check your inputs: ensure rafter heights are valid and tile specifications (min/max gauge, slate height) are appropriate.');
    }
    if (!warning) {
        const hasInvalidGauge = solution.rafterResults.some(r => {
            if (solution.type === 'full') return r.battenGauge < minGauge;
            if (solution.type === 'split') return r.gauge1 < minGauge || r.gauge2 < minGauge;
            if (solution.type === 'cut') return r.cutCourseGauge < 75;
            return false;
        });
        if (hasInvalidGauge) {
            warning = 'Batten gauge or cut course is below the minimum threshold (75mm) on one or more rafters. Consider adjusting rafter length or tile specifications.';
        }
    }
    // Step 8: Verify totals
    const tolerance = 3;
    const totalWarnings = rafterHeights.map((rafterHeight, index) => {
        var _a, _b, _c;
        const result = solution.rafterResults[index];
        const computedTotal = solution.type === 'full'
            ? firstBatten + (solution.n_spaces - 1) * ((_a = result.battenGauge) !== null && _a !== void 0 ? _a : 0) + result.effectiveRidgeOffset
            : solution.type === 'split'
                ? firstBatten + (solution.n1 * result.gauge1 + solution.n2 * result.gauge2 + result.effectiveRidgeOffset)
                : firstBatten + ((_b = result.cutCourseGauge) !== null && _b !== void 0 ? _b : 0) + ((_c = result.fullCourses) !== null && _c !== void 0 ? _c : 0) * maxGauge + result.effectiveRidgeOffset;
        const difference = Math.abs(rafterHeight - computedTotal);
        if (difference > tolerance) {
            return `Computed total (${computedTotal}mm) for rafter ${index + 1} differs from rafter height (${rafterHeight}mm) by ${difference}mm, exceeding tolerance of ${tolerance}mm.`;
        }
        return null;
    }).filter(w => w !== null);
    if (totalWarnings.length > 0) {
        warning = warning ? `${warning} ${totalWarnings.join(' ')}` : totalWarnings.join(' ');
    }
    // Updated Return Statement
    return {
        "Input Rafter": rafterHeights[0], // Assuming single rafter for simplicity
        "Total Courses": solution.n_spaces,
        "Solution": solution.type === 'full' ? "Full Courses" : solution.type === 'split' ? "Split Gauge" : "Cut Course",
        "Ridge Offset": solution.rafterResults[0].effectiveRidgeOffset,
        ...(materialType === 'Fibre Cement Slate' && { "Under Eave Batten": underEaveBattenValue }),
        ...(['Slate', 'Fibre Cement Slate', 'Plain Tile'].includes(materialType) && { "Eave Batten": eaveBatten }),
        "1st Batten": firstBatten,
        ...(solution.type === 'cut' && { "Cut Course": solution.rafterResults[0].cutCourseGauge }),
        "Gauge": `${solution.type === 'cut' ? solution.rafterResults[0].fullCourses : solution.n_spaces - 1} @ ${solution.type === 'full' ? solution.rafterResults[0].battenGauge : solution.type === 'cut' ? maxGauge : solution.rafterResults[0].gauge1}`,
        ...(solution.type === 'split' && { "Split Gauge": `${solution.n2} @ ${solution.rafterResults[0].gauge2}` }),
        ...(warning && { "Warning": warning })
    };
}