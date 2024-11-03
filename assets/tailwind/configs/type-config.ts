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

export const latinTypeConfig: TypeConfig = {
  minWidth: 320,
  maxWidth: 1914,
  minTypeScale: 1.2,
  maxTypeScale: 1.414,
  minFontSize: 18,
  maxFontSize: 18,
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
  minFontSize: 18,
  maxFontSize: 18,
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
