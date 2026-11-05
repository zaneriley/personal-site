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
  anchorLabel: string; // size label whose weights are set by eye
  regular: number; // regular wght at the anchor size
  bold: number; // bold wght at the anchor size
  // How the stroke-to-size ratio changes away from the anchor:
  // stem/size ∝ (size / anchorSize) ^ −k. 0 = every size keeps the anchor's
  // ratio; 1 = every size keeps the anchor's stroke in px. `display` applies
  // above the anchor, `text` below it. Small text needs more help than large
  // type needs taking away, so the two differ.
  opticalExponent: { display: number; text: number };
  labels: string[]; // size labels that get a weight rung (display → small)
  // Measured once from the font: [wght, stem width as a fraction of the em].
  // Ascending in both columns; weights are read back from it by interpolation.
  stems: [number, number][];
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
 * axis, so optical-size compensation rides the wght axis.
 *
 * Each size gets a target stroke-to-size ratio, then the weight that draws that
 * stroke is looked up in `stems`:
 *   target(size) = stem(anchor weight) · (size / anchor size) ^ −k
 * Large type gets a slightly lighter ratio (k = display) so it doesn't look
 * heavy, while its strokes still grow in px. Small type gets a clearly heavier
 * one (k = text): at 10–17px the strokes are only about a pixel wide and read
 * faint unless they are boosted more. Regular and bold follow the same rule
 * from their own anchor weights.
 *
 * 2026-11-04: one shared k = 0.2 made small text lighter than the old rule
 * (3xs 358 → 331), which read thin on a phone. The old rule's small end acted
 * like k ≈ 0.3; text = 0.45 is a step heavier than that.
 *
 * The previous rule subtracted 30 wght per step. Because the scale is
 * geometric and stroke width isn't linear in wght, that held the stroke at
 * ~2px from 2xl to 4xl, so 4xl was ~46% lighter relative to its size than md
 * (measured 2026-11-03) and 3xs-bold asked for 828, past the font's 800 max.
 *
 * `stems`: Chromium canvas, the served gt-flexa.woff2 at 100px, default width,
 * widest ink run through "l" 0.35em above the baseline (alpha-weighted).
 * Re-measure if the font file changes. The steep 700→800 end is the design.
 * Cardinal/Noto are static faces — no rungs.
 * This is the single source of truth; generate-type-tokens.ts emits the rungs. */
export const flexaWeightConfig: WeightConfig = {
  anchorLabel: "md",
  regular: 300,
  bold: 618,
  opticalExponent: { display: 0.2, text: 0.45 },
  labels: ["4xl", "3xl", "2xl", "1xl", "md", "1xs", "2xs", "3xs"],
  stems: [
    [100, 0.0306],
    [150, 0.0435],
    [200, 0.0568],
    [250, 0.0709],
    [300, 0.083],
    [350, 0.0911],
    [400, 0.0997],
    [450, 0.1115],
    [500, 0.1234],
    [550, 0.1326],
    [600, 0.1418],
    [650, 0.1527],
    [700, 0.1646],
    [750, 0.1935],
    [800, 0.2227],
  ],
};
