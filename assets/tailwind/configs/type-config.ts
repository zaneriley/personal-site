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

export interface LineHeightConfig {
  script: "latin" | "cjk";
  paragraphSize: number; // px at the default root size
  paragraphLeading: number; // px; Latin spacing anchor
  referenceCapHeight: number; // normalized em metric of paragraph face
  subdivision: number; // divide the Latin paragraph leading once
}

export const spacingMultipliers = {
  "3xs": 1 / 8,
  "2xs": 1 / 4,
  "1xs": 1 / 2,
  md: 1,
  "1xl": 1.5,
  "2xl": 2,
  "3xl": 3,
  "4xl": 4,
  "5xl": 6,
};

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
  script: "latin",
  paragraphSize: baseFontSize,
  paragraphLeading: 28,
  referenceCapHeight: 0.7,
  subdivision: 4,
};

export const cjkLineHeightConfig: LineHeightConfig = {
  script: "cjk",
  paragraphSize: baseFontSize,
  paragraphLeading: baseFontSize * 1.5,
  referenceCapHeight: 1,
  subdivision: 1,
};

export const latinTypeConfig: TypeConfig = {
  minWidth: 320,
  maxWidth: 1914,
  minTypeScale: 1.2,
  maxTypeScale: 1.3,
  minFontSize: baseFontSize,
  maxFontSize: baseFontSize, // This is how large the base font will scale.
  positiveSteps: 7,
  negativeSteps: 3,
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
    "3xs",
  ],
  lineHeightConfig: latinLineHeightConfig,
};

export const cjkTypeConfig: TypeConfig = {
  minWidth: 320,
  maxWidth: 1914,
  minTypeScale: 1.2,
  maxTypeScale: 1.3,
  minFontSize: baseFontSize,
  maxFontSize: baseFontSize, // This is how large the base font will scale.
  positiveSteps: 7,
  negativeSteps: 3,
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
    "3xs",
  ],
  lineHeightConfig: cjkLineHeightConfig,
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
  labels: ["4xl", "3xl", "2xl", "1xl", "md", "1xs", "2xs", "3xs"],
};
