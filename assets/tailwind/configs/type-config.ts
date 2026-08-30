export interface TypeConfig {
  minWidth: number;
  maxWidth: number;
  minTypeScale: number;
  maxTypeScale: number;
  minFontSize: number;
  maxFontSize: number;
  positiveSteps: number;
  negativeSteps: number;
  relativeTo: "viewport" | "viewport-width" | "container";
  typeLabels: string[];
  lineHeightConfig: LineHeightConfig;
}

export interface SpaceConfig {
  minWidth: number;
  maxWidth: number;
  minSpaceSize: number;
  maxSpaceSize: number;
  minSpaceScale: number;
  maxSpaceScale: number;
  positiveSteps: number;
  negativeSteps: number;
  relativeTo: "viewport" | "viewport-width" | "container";
  spaceLabels: string[];
}

export interface LineHeightConfig {
  baseFontSize: number; // Base font size in rem units
  baseLineHeight: number; // Base line-height in rem units
  scalingFactor: number; // Factor to adjust line-height
  incrementStep: "whole" | "half" | "quarter"; // Line-height snapping increment
  incrementMethod: "latin" | "cjk";
}

export interface WeightConfig {
  base: number; // regular weight at the anchor size (step 0)
  opszSlope: number; // regular weight gained per step toward smaller text
  boldDelta: number; // how much heavier bold is than regular, at the anchor
  boldSlope: number; // bold's extra lift shrinks by this per step toward display
  anchorLabel: string; // size label at step 0
  labels: string[]; // size labels that get a weight rung (display → small)
}

/* All the value are primarily derived from
 * the base font size and line-height. These values are used to calculate the
 * vertical rhythm, grid, spacing, etc.
 */
const baseFontSize = 22;

export const latinLineHeightConfig: LineHeightConfig = {
  baseFontSize: baseFontSize,
  // 28px base leading at the 22px reading size (28/22) — lands md leading on the
  // 7px baseline grid (quarter of 28). The snapping below keeps even line spacing
  // across the scale.
  baseLineHeight: 1.2727,
  scalingFactor: 0.5,
  incrementStep: "quarter",
  incrementMethod: "latin",
};

export const cjkLineHeightConfig: LineHeightConfig = {
  baseFontSize: baseFontSize,
  baseLineHeight: 2,
  scalingFactor: 0.1,
  incrementStep: "whole",
  incrementMethod: "cjk",
};

export const latinTypeConfig: TypeConfig = {
  minWidth: 320,
  maxWidth: 1914,
  minTypeScale: 1.2,
  maxTypeScale: 1.3,
  minFontSize: baseFontSize,
  maxFontSize: baseFontSize, // This is how large the base font will scale.
  positiveSteps: 7,
  negativeSteps: 2,
  relativeTo: "viewport",
  typeLabels: [
    "7xl",
    "6xl",
    "5xl",
    "4xl",
    "3xl",
    "2xl",
    "1xl",
    "md",
    "1xs",
    "2xs",
  ],
  lineHeightConfig: latinLineHeightConfig,
};

export const latinSpaceConfig: SpaceConfig = {
  minWidth: 320,
  maxWidth: 1440,
  minSpaceSize: 16,
  maxSpaceSize: 20,
  minSpaceScale: 1.5,
  maxSpaceScale: 2,
  positiveSteps: 5,
  negativeSteps: 3,
  relativeTo: "viewport",
  spaceLabels: ["5xl", "4xl", "3xl", "2xl", "1xl", "md", "1xs", "2xs", "3xs"],
};

export const cjkTypeConfig: TypeConfig = {
  minWidth: 320,
  maxWidth: 1914,
  minTypeScale: 1.2,
  maxTypeScale: 1.3,
  minFontSize: baseFontSize,
  maxFontSize: baseFontSize, // This is how large the base font will scale.
  positiveSteps: 7,
  negativeSteps: 2,
  relativeTo: "viewport",
  typeLabels: [
    "7xl",
    "6xl",
    "5xl",
    "4xl",
    "3xl",
    "2xl",
    "1xl",
    "md",
    "1xs",
    "2xs",
  ],
  lineHeightConfig: cjkLineHeightConfig,
};

export const cjkSpaceConfig: SpaceConfig = {
  minWidth: 320,
  maxWidth: 1440,
  minSpaceSize: 16,
  maxSpaceSize: 20,
  minSpaceScale: 1.5,
  maxSpaceScale: 2,
  positiveSteps: 5,
  negativeSteps: 3,
  relativeTo: "viewport",
  spaceLabels: ["5xl", "4xl", "3xl", "2xl", "1xl", "md", "1xs", "2xs", "3xs"],
};

/* GT Flexa optical weight. GT Flexa exposes wght 100–800 but has NO opsz/GRAD
 * axis, so optical-size weight compensation rides the wght axis, derived per
 * size step from these four knobs (calibrated by eye in /weight-calibration):
 *   regular(step) = base − opszSlope · step
 *   bold(step)    = regular(step) + boldDelta − boldSlope · step
 * `step` is each label's distance from the anchor (+ display, − small). The
 * label list stops at 4xl on the display end: 5xl/6xl/7xl regular weights would
 * fall under GT Flexa's 100 floor. Cardinal/Noto are static faces — no rungs.
 * This is the single source of truth; generate-type-tokens.ts emits the rungs. */
export const flexaWeightConfig: WeightConfig = {
  base: 268,
  opszSlope: 30,
  boldDelta: 350,
  boldSlope: 40,
  anchorLabel: "md",
  labels: ["4xl", "3xl", "2xl", "1xl", "md", "1xs", "2xs"],
};
