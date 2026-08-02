import type { LineHeightConfig } from "./configs/type-config";

const debugLog = (...args: unknown[]): void => {
  if (process.env.TYPE_SCALE_DEBUG === "1") {
    console.log(...args);
  }
};

/**
 * Calculates unitless line-height value aligned to the baseline grid.
 * @param config LineHeightConfig
 * @param fontSize number (in px units)
 * @returns lineHeight number
 * @throws {Error} If fontSize is negative or zero
 */
export const calculateLineHeight = (
  config: LineHeightConfig,
  fontSize: number,
): number => {
  debugLog("\nCalculating Line Height:");
  debugLog("Input Config:", {
    baseFontSize: config.baseFontSize,
    baseLineHeight: config.baseLineHeight,
    scalingFactor: config.scalingFactor,
    incrementStep: config.incrementStep,
  });
  debugLog("Input Font Size:", fontSize, "px");

  if (fontSize <= 0) {
    throw new Error("Font size must be positive.");
  }

  // Step 1: Calculate and round base line-height in pixels
  const baseLineHeightPxRaw = config.baseLineHeight * config.baseFontSize;
  debugLog("\nStep 1: Base Line Height Raw");
  debugLog(
    `baseLineHeightPxRaw = ${config.baseLineHeight} * ${config.baseFontSize} = ${baseLineHeightPxRaw}px`,
  );

  const baseLineHeightPx = Math.round(baseLineHeightPxRaw);
  debugLog("Step 1: Base Line Height Rounded");
  debugLog(
    `baseLineHeightPx = Math.round(${baseLineHeightPxRaw}) = ${baseLineHeightPx}px`,
  );

  // Step 2: Determine baseline unit with corrected rounding
  let baselineUnit: number;
  switch (config.incrementStep) {
    case "whole":
      baselineUnit = Math.round(baseLineHeightPx);
      debugLog("\nStep 2: Baseline Unit Calculation - Whole");
      debugLog(
        `baselineUnit (whole) = Math.round(${baseLineHeightPx}) = ${baselineUnit}px`,
      );
      break;
    case "half":
      baselineUnit = Math.round(baseLineHeightPx) / 2;
      debugLog("\nStep 2: Baseline Unit Calculation - Half");
      debugLog(
        `baselineUnit (half) = Math.round(${baseLineHeightPx} * 2) / 2 = ${baselineUnit}px`,
      );
      break;
    case "quarter":
      baselineUnit = Math.round(baseLineHeightPx) / 4;
      debugLog("\nStep 2: Baseline Unit Calculation - Quarter");
      debugLog(
        `baselineUnit (quarter) = Math.round(${baseLineHeightPx} * 4) / 4 = ${baselineUnit}px`,
      );
      break;
    default:
      baselineUnit = Math.round(baseLineHeightPx);
      debugLog("\nStep 2: Baseline Unit Calculation - Default");
      debugLog(
        `baselineUnit (default) = Math.round(${baseLineHeightPx}) = ${baselineUnit}px`,
      );
      break;
  }

  // Log the exact value of baselineUnit
  debugLog("Step 2: Baseline Unit Value");
  debugLog(`baselineUnit = ${baselineUnit}`);

  // Step 3: Calculate the desired line height before scaling
  let desiredLineHeightPx = fontSize * config.baseLineHeight;
  desiredLineHeightPx = Number.parseFloat(desiredLineHeightPx.toFixed(4));
  debugLog("\nStep 3: Initial Desired Line Height");
  debugLog(
    `desiredLineHeightPx = ${fontSize} * ${config.baseLineHeight} = ${desiredLineHeightPx}px`,
  );

  // Step 4: Adjust line height based on scaling factor
  if (config.scalingFactor) {
    const fontSizeDifference = fontSize - config.baseFontSize;
    const scalingCalculation =
      1 - config.scalingFactor * (fontSizeDifference / config.baseFontSize);
    const scalingAdjustment = Math.abs(
      Number.parseFloat(scalingCalculation.toFixed(10)),
    );

    debugLog("\nStep 4: Scaling Adjustment");
    debugLog(`Font size difference: ${fontSizeDifference} px`);
    debugLog(
      `Scaling calculation: 1 - ${config.scalingFactor} * ((${fontSize} - ${config.baseFontSize}) / ${config.baseFontSize})`,
    );
    debugLog(`Scaling adjustment: ${scalingAdjustment}`);

    const previousHeight = desiredLineHeightPx;
    desiredLineHeightPx = Number.parseFloat(
      (desiredLineHeightPx * scalingAdjustment).toFixed(4),
    );
    debugLog(
      `Adjusted line height: ${previousHeight}px → ${desiredLineHeightPx}px`,
    );
  }

  // Step 5: Calculate the number of baseline units
  const unitsRaw = desiredLineHeightPx / baselineUnit;
  debugLog("\nStep 5: Baseline Units Raw");
  debugLog(`unitsRaw = ${desiredLineHeightPx} / ${baselineUnit} = ${unitsRaw}`);

  // Step 6: Round units to the nearest increment
  const incrementMultipliers: Record<string, number> = {
    whole: 1,
    half: 2,
    quarter: 4,
    // Add more if needed
  };

  const multiplier = incrementMultipliers[config.incrementStep] || 2;

  if (!Object.hasOwn(incrementMultipliers, config.incrementStep)) {
    console.warn(
      `Invalid incrementStep: ${config.incrementStep}. Defaulting to 'half'.`,
    );
  }
  let roundedUnits = Math.round(unitsRaw * multiplier) / multiplier;
  roundedUnits = Number.parseFloat(roundedUnits.toFixed(4));
  debugLog(`roundedUnits (${config.incrementStep}) = ${roundedUnits}`);

  // Step 7: Calculate the aligned line height in pixels
  const alignedLineHeightPx = Number.parseFloat(
    (roundedUnits * baselineUnit).toFixed(4),
  );
  debugLog("\nStep 7: Aligned Line Height");
  debugLog(
    `alignedLineHeightPx = ${roundedUnits} * ${baselineUnit} = ${alignedLineHeightPx}px`,
  );

  // Step 8: Compute the unitless line height value
  const finalLineHeight = Number.parseFloat(
    (alignedLineHeightPx / fontSize).toFixed(10),
  );
  debugLog("\nStep 8: Final Line Height");
  debugLog(
    `finalLineHeight = ${alignedLineHeightPx} / ${fontSize} = ${finalLineHeight}`,
  );

  return finalLineHeight;
};
