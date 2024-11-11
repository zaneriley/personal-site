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

/* All the value are primarily derived from
 * the base font size and line-height. These values are used to calculate the
 * vertical rhythm, grid, spacing, etc.
 */
const baseFontSize = 18;

export const latinLineHeightConfig: LineHeightConfig = {
  baseFontSize: baseFontSize,
  baseLineHeight: 1.5555,
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
  maxTypeScale: 1.414,
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
  maxTypeScale: 1.414,
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
