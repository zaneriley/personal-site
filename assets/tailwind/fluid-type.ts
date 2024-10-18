// This is a modified from Utopia.fyi
// In particular, there are changes to the logic.
// - text/spacing should only grow, not shrink, on larger devices.
//   This is because the minimum font size is usually bottlenecked by
//   the user's distance from screen. Larger scales work for sizing type up,
//   but not down from the base. The font size shrinks too much otherwise.

// Interfaces

interface ClampConfig {
  maxSize: number;
  minSize: number;
  minWidth: number;
  maxWidth: number;
  usePx?: boolean;
  relativeTo?: "viewport" | "viewport-width" | "container";
}

interface WCAGConfig {
  min: number;
  max: number;
  minWidth: number;
  maxWidth: number;
}

interface TypeConfig {
  minWidth: number;
  maxWidth: number;
  minTypeScale: number;
  maxTypeScale: number;
  minFontSize: number;
  maxFontSize: number;
  positiveSteps: number;
  negativeSteps: number;
  relativeTo: "viewport" | "viewport-width" | "container";
  typeLabels?: string[];
}

interface SpaceConfig {
  minWidth: number;
  maxWidth: number;
  minSpaceSize: number;
  maxSpaceSize: number;
  minSpaceScale: number;
  maxSpaceScale: number;
  positiveSteps: number;
  negativeSteps: number;
  relativeTo: "viewport" | "viewport-width" | "container";
  spaceLabels?: string[];
}

interface TypeSizeConfig {
  minWidth: number;
  maxWidth: number;
  minTypeScale: number;
  maxTypeScale: number;
  minFontSize: number;
  maxFontSize: number;
}

interface TypeStepConfig extends TypeSizeConfig {
  relativeTo: "viewport" | "viewport-width" | "container";
}

interface TypeStepResult {
  step: number;
  minFontSize: number;
  maxFontSize: number;
  wcagViolation: { from: number; to: number } | null;
  clamp: string;
  isFixed: boolean;
}

interface Size {
  step: number;
  [key: string]: number | string;
}

interface ClampResult {
  label: string;
  clamp: string;
  clampPx: string;
}

interface CalculateClampsConfig {
  minWidth: number;
  maxWidth: number;
  pairs: [number, number][];
  relativeTo: "viewport" | "viewport-width" | "container";
}

// Helpers
const lerp = (x: number, y: number, a: number): number => x * (1 - a) + y * a;
const clamp = (a: number, min = 0, max = 1): number =>
  Math.min(max, Math.max(min, a));
const invlerp = (x: number, y: number, a: number): number =>
  clamp((a - x) / (y - x));
const range = (
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  a: number,
): number => lerp(x2, y2, invlerp(x1, y1, a));
const roundValue = (n: number): number =>
  Math.round((n + Number.EPSILON) * 10000) / 10000;

const defaultTypeLabels = [
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
];
const defaultSpaceLabels = [
  "5xl",
  "4xl",
  "3xl",
  "2xl",
  "1xl",
  "md",
  "1xs",
  "2xs",
  "3xs",
];

const assignLabels = (
  sizes: Size[],
  labels: string[],
): (Size & { label: string })[] => {
  const mdIndex = labels.indexOf("md");
  if (mdIndex === -1) {
    throw new Error("The label array must include 'md' as the base size.");
  }

  const baseIndex = sizes.findIndex((s) => s.step === 0);

  return sizes
    .map((size, index) => {
      const offset = index - baseIndex;
      let label: string;

      if (offset === 0) {
        label = "md";
      } else if (offset > 0) {
        const xlIndex = mdIndex + offset;
        if (xlIndex < labels.length) {
          label = labels[xlIndex];
        } else {
          label = `${offset}xs`;
        }
      } else {
        const xsIndex = mdIndex + offset;
        if (xsIndex >= 0) {
          label = labels[xsIndex];
        } else {
          label = `${Math.abs(offset)}xl`;
        }
      }

      return { ...size, label };
    })
    .sort((a, b) => b.step - a.step); // Sort from largest to smallest
};

// Clamp
export const calculateClamp = (config: ClampConfig): string => {
  const {
    maxSize,
    minSize,
    maxWidth,
    minWidth,
    usePx = false,
    relativeTo = "viewport",
  } = config;

  const isNegative = minSize > maxSize;
  const min = isNegative ? maxSize : minSize;
  const max = isNegative ? minSize : maxSize;

  const divider = usePx ? 1 : 16;
  const unit = usePx ? "px" : "rem";
  const relativeUnits: { [key: string]: string } = {
    viewport: "vi",
    "viewport-width": "vw",
    container: "cqi",
  };
  const relativeUnit = relativeUnits[relativeTo] || relativeUnits.viewport;

  const slope =
    (maxSize / divider - minSize / divider) /
    (maxWidth / divider - minWidth / divider);
  const intersection = -1 * (minWidth / divider) * slope + minSize / divider;

  return `clamp(${roundValue(min / divider)}${unit}, ${roundValue(
    intersection,
  )}${unit} + ${roundValue(slope * 100)}${relativeUnit}, ${roundValue(
    max / divider,
  )}${unit})`;
};

export function checkWCAG({
  min,
  max,
  minWidth,
  maxWidth,
}: WCAGConfig): number[] | null {
  if (minWidth > maxWidth) {
    // need to flip because our checks assume minWidth < maxWidth
    [minWidth, maxWidth] = [maxWidth, minWidth];
    [min, max] = [max, min];
  }

  const slope = (max - min) / (maxWidth - minWidth);
  const intercept = min - minWidth * slope;
  const lh = (5 * min - 2 * intercept) / (2 * slope);
  const rh = (5 * intercept - 2 * max) / (-1 * slope);
  const lh2 = (3 * intercept) / slope;

  let failRange: number[] = [];
  if (maxWidth < 5 * minWidth) {
    if (minWidth < lh && lh < maxWidth) {
      failRange.push(Math.max(lh, minWidth), maxWidth);
    }
    if (5 * min < 2 * max) {
      failRange.push(maxWidth, 5 * minWidth);
    }
    if (5 * minWidth < rh && rh < 5 * maxWidth) {
      failRange.push(5 * minWidth, Math.min(rh, 5 * maxWidth));
    }
  } else {
    if (minWidth < lh && lh < 5 * minWidth) {
      failRange.push(Math.max(lh, minWidth), 5 * minWidth);
    }
    if (5 * minWidth < lh2 && lh2 < maxWidth) {
      failRange.push(Math.max(lh2, 5 * minWidth), maxWidth);
    }
    if (maxWidth < rh && rh < 5 * maxWidth) {
      failRange.push(maxWidth, Math.min(rh, 5 * maxWidth));
    }
  }

  // Clean up range
  if (failRange.length) {
    failRange = [failRange[0], failRange[failRange.length - 1]];
    if (Math.abs(failRange[1] - failRange[0]) < 0.1) return null; // rounding errors, ignore
  }

  return failRange.length ? failRange : null;
}

export const calculateClamps = ({
  minWidth,
  maxWidth,
  pairs = [],
  relativeTo,
}: CalculateClampsConfig): ClampResult[] => {
  return pairs.map(([minSize, maxSize]) => {
    return {
      label: `${minSize}-${maxSize}`,
      clamp: calculateClamp({
        minSize,
        maxSize,
        minWidth,
        maxWidth,
        relativeTo,
      }),
      clampPx: calculateClamp({
        minSize,
        maxSize,
        minWidth,
        maxWidth,
        relativeTo,
        usePx: true,
      }),
    };
  });
};

// Type
const calculateTypeSize = (
  config: TypeSizeConfig,
  viewport: number,
  step: number,
): number => {
  const scale = range(
    config.minWidth,
    config.maxWidth,
    config.minTypeScale,
    config.maxTypeScale,
    viewport,
  );
  const fontSize = range(
    config.minWidth,
    config.maxWidth,
    config.minFontSize,
    config.maxFontSize,
    viewport,
  );
  return fontSize * scale ** step;
};

const calculateTypeStep = (
  config: TypeStepConfig,
  step: number,
): TypeStepResult => {
  const minFontSize = calculateTypeSize(config, config.minWidth, step);
  const maxFontSize = calculateTypeSize(config, config.maxWidth, step);
  const wcag = checkWCAG({
    min: minFontSize,
    max: maxFontSize,
    minWidth: config.minWidth,
    maxWidth: config.maxWidth,
  });

  const isFixed = step < 0;
  const fixedSize = config.minFontSize / config.minTypeScale ** Math.abs(step);

  return {
    step,
    minFontSize: roundValue(minFontSize),
    maxFontSize: roundValue(maxFontSize),
    wcagViolation: wcag?.length
      ? {
          from: Math.round(wcag[0]),
          to: Math.round(wcag[1]),
        }
      : null,
    clamp: isFixed
      ? `${roundValue(fixedSize / 16)}rem`
      : calculateClamp({
          minSize: minFontSize,
          maxSize: maxFontSize,
          minWidth: config.minWidth,
          maxWidth: config.maxWidth,
          relativeTo: config.relativeTo,
        }),
    isFixed,
  };
};

export const calculateTypeScale = (config: TypeConfig): TypeStepResult[] => {
  const positiveSteps = Array.from({ length: config.positiveSteps })
    .map((_, i) => calculateTypeStep(config, i + 1))
    .reverse();

  const negativeSteps = Array.from({
    length: config.negativeSteps,
  }).map((_, i) => calculateTypeStep(config, -1 * (i + 1)));

  return [...positiveSteps, calculateTypeStep(config, 0), ...negativeSteps];
};

// Space

const calculateSpaceSize = (config: SpaceConfig, step: number) => {
  const minSize = config.minSpaceSize * config.minSpaceScale ** step;
  const maxSize = config.maxSpaceSize * config.maxSpaceScale ** step;

  return {
    step,
    minSize: roundValue(minSize),
    maxSize: roundValue(maxSize),
    clamp: calculateClamp({
      minSize,
      maxSize,
      minWidth: config.minWidth,
      maxWidth: config.maxWidth,
      relativeTo: config.relativeTo,
    }),
  };
};

export const calculateSpaceScale = (config: SpaceConfig) => {
  const positiveSteps = Array.from({ length: config.positiveSteps })
    .map((_, i) => calculateSpaceSize(config, i + 1))
    .reverse();

  const negativeSteps = Array.from({
    length: config.negativeSteps,
  }).map((_, i) => calculateSpaceSize(config, -1 * (i + 1)));

  return [...positiveSteps, calculateSpaceSize(config, 0), ...negativeSteps];
};

export const generateTypeCSSVariables = (config: TypeConfig): string => {
  const typeScale = calculateTypeScale(config);
  const labels = config.typeLabels || defaultTypeLabels;

  if (!labels.includes("md")) {
    throw new Error("The label array must include 'md' as the base size.");
  }

  const labeledSizes = assignLabels(typeScale, labels);

  return labeledSizes
    .map((size) => {
      if (size.isFixed) {
        const pixelValue = Number.parseFloat(size.clamp) * 16; // Convert rem to px
        return `  --fs-${size.label}: ${size.clamp}; /* ${roundValue(pixelValue)}px */`;
      }
      return `  --fs-${size.label}: ${size.clamp}; /* min: ${size.minFontSize}px, max: ${size.maxFontSize}px */`;
    })
    .join("\n");
};

export const generateSpaceCSSVariables = (config: SpaceConfig): string => {
  try {
    const spaceScale = calculateSpaceScale(config);
    const labels = config.spaceLabels || defaultSpaceLabels;
    const labeledSizes = assignLabels(spaceScale, labels);

    return labeledSizes
      .map(
        (size) =>
          `  --space-${size.label}: ${size.clamp}; /* min: ${size.minSize}px, max: ${size.maxSize}px */`,
      )
      .join("\n");
  } catch (error) {
    console.error("Error generating spacing variables:", error);
    return `/* Error generating spacing variables: ${(error as Error).message} */`;
  }
};
