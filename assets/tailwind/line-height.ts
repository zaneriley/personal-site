import type { LineHeightConfig } from "./configs/type-config.ts";

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
  console.log("\nCalculating Line Height:");
  console.log("Input Config:", {
    baseFontSize: config.baseFontSize,
    baseLineHeight: config.baseLineHeight,
    scalingFactor: config.scalingFactor,
    incrementStep: config.incrementStep,
  });
  console.log("Input Font Size:", fontSize, "px");

  if (fontSize <= 0) {
    throw new Error("Font size must be positive.");
  }

  // Step 1: Calculate and round base line-height in pixels
  const baseLineHeightPxRaw = config.baseLineHeight * config.baseFontSize;
  console.log("\nStep 1: Base Line Height Raw");
  console.log(
    `baseLineHeightPxRaw = ${config.baseLineHeight} * ${config.baseFontSize} = ${baseLineHeightPxRaw}px`,
  );

  const baseLineHeightPx = Math.round(baseLineHeightPxRaw);
  console.log("Step 1: Base Line Height Rounded");
  console.log(
    `baseLineHeightPx = Math.round(${baseLineHeightPxRaw}) = ${baseLineHeightPx}px`,
  );

  // Step 2: Determine baseline unit with corrected rounding
  let baselineUnit: number;
  switch (config.incrementStep) {
    case "whole":
      baselineUnit = Math.round(baseLineHeightPx);
      console.log("\nStep 2: Baseline Unit Calculation - Whole");
      console.log(
        `baselineUnit (whole) = Math.round(${baseLineHeightPx}) = ${baselineUnit}px`,
      );
      break;
    case "half":
      baselineUnit = Math.round(baseLineHeightPx) / 2;
      console.log("\nStep 2: Baseline Unit Calculation - Half");
      console.log(
        `baselineUnit (half) = Math.round(${baseLineHeightPx} * 2) / 2 = ${baselineUnit}px`,
      );
      break;
    case "quarter":
      baselineUnit = Math.round(baseLineHeightPx) / 4;
      console.log("\nStep 2: Baseline Unit Calculation - Quarter");
      console.log(
        `baselineUnit (quarter) = Math.round(${baseLineHeightPx} * 4) / 4 = ${baselineUnit}px`,
      );
      break;
    default:
      baselineUnit = Math.round(baseLineHeightPx);
      console.log("\nStep 2: Baseline Unit Calculation - Default");
      console.log(
        `baselineUnit (default) = Math.round(${baseLineHeightPx}) = ${baselineUnit}px`,
      );
      break;
  }

  // Log the exact value of baselineUnit
  console.log("Step 2: Baseline Unit Value");
  console.log(`baselineUnit = ${baselineUnit}`);

  // Step 3: Calculate the desired line height before scaling
  let desiredLineHeightPx = fontSize * config.baseLineHeight;
  desiredLineHeightPx = Number.parseFloat(desiredLineHeightPx.toFixed(4));
  console.log("\nStep 3: Initial Desired Line Height");
  console.log(
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

    console.log("\nStep 4: Scaling Adjustment");
    console.log(`Font size difference: ${fontSizeDifference} px`);
    console.log(
      `Scaling calculation: 1 - ${config.scalingFactor} * ((${fontSize} - ${config.baseFontSize}) / ${config.baseFontSize})`,
    );
    console.log(`Scaling adjustment: ${scalingAdjustment}`);

    const previousHeight = desiredLineHeightPx;
    desiredLineHeightPx = Number.parseFloat(
      (desiredLineHeightPx * scalingAdjustment).toFixed(4),
    );
    console.log(
      `Adjusted line height: ${previousHeight}px → ${desiredLineHeightPx}px`,
    );
  }

  // Step 5: Calculate the number of baseline units
  const unitsRaw = desiredLineHeightPx / baselineUnit;
  console.log("\nStep 5: Baseline Units Raw");
  console.log(
    `unitsRaw = ${desiredLineHeightPx} / ${baselineUnit} = ${unitsRaw}`,
  );

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
  console.log(`roundedUnits (${config.incrementStep}) = ${roundedUnits}`);

  // Step 7: Calculate the aligned line height in pixels
  const alignedLineHeightPx = Number.parseFloat(
    (roundedUnits * baselineUnit).toFixed(4),
  );
  console.log("\nStep 7: Aligned Line Height");
  console.log(
    `alignedLineHeightPx = ${roundedUnits} * ${baselineUnit} = ${alignedLineHeightPx}px`,
  );

  // Step 8: Compute the unitless line height value
  const finalLineHeight = Number.parseFloat(
    (alignedLineHeightPx / fontSize).toFixed(10),
  );
  console.log("\nStep 8: Final Line Height");
  console.log(
    `finalLineHeight = ${alignedLineHeightPx} / ${fontSize} = ${finalLineHeight}`,
  );

  return finalLineHeight;
};
