import { describe, expect, it } from "vitest";
import {
  calculateClamp,
  calculateTypeScale,
  generateTypeCSSVariables,
} from "../../tailwind/fluid-type.ts";

describe("calculateClamp", () => {
  it("should return a valid clamp value with default parameters", () => {
    const result = calculateClamp({
      minSize: 16,
      maxSize: 24,
      minWidth: 320,
      maxWidth: 1200,
    });

    expect(result).toBe("clamp(1rem, 0.8182rem + 0.9091vi, 1.5rem)");
  });

  it("should return a valid clamp value with usePx set to true", () => {
    const result = calculateClamp({
      minSize: 16,
      maxSize: 24,
      minWidth: 320,
      maxWidth: 1200,
      usePx: true,
    });

    expect(result).toBe("clamp(16px, 13.0909px + 0.9091vi, 24px)");
  });

  it("should handle negative values (minSize > maxSize)", () => {
    const result = calculateClamp({
      minSize: 24,
      maxSize: 16,
      minWidth: 320,
      maxWidth: 1200,
    });

    expect(result).toBe("clamp(1rem, 1.6818rem + -0.9091vi, 1.5rem)");
  });

  it("should use different relative units based on relativeTo parameter", () => {
    const result = calculateClamp({
      minSize: 16,
      maxSize: 24,
      minWidth: 320,
      maxWidth: 1200,
      relativeTo: "viewport-width",
    });

    expect(result).toBe("clamp(1rem, 0.8182rem + 0.9091vw, 1.5rem)");
  });
});

describe("calculateTypeScale", () => {
  it("should generate correct number of steps", () => {
    const config = {
      positiveSteps: 2,
      negativeSteps: 1,
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      relativeTo: "viewport",
    };

    const result = calculateTypeScale(config);

    expect(result).toHaveLength(4); // 2 positive + 1 zero + 1 negative
    expect(result[0].step).toBe(2);
    expect(result[1].step).toBe(1);
    expect(result[2].step).toBe(0);
    expect(result[3].step).toBe(-1);
  });

  it("should handle configuration with only positive steps", () => {
    const config = {
      positiveSteps: 3,
      negativeSteps: 0,
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      relativeTo: "viewport",
    };

    const result = calculateTypeScale(config);

    expect(result).toHaveLength(4); // 3 positive + 1 zero
    expect(result[0].step).toBe(3);
    expect(result[1].step).toBe(2);
    expect(result[2].step).toBe(1);
    expect(result[3].step).toBe(0);
  });

  it("should handle configuration with only negative steps", () => {
    const config = {
      positiveSteps: 0,
      negativeSteps: 2,
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      relativeTo: "viewport",
    };

    const result = calculateTypeScale(config);

    expect(result).toHaveLength(3); // 1 zero + 2 negative
    expect(result[0].step).toBe(0);
    expect(result[1].step).toBe(-1);
    expect(result[2].step).toBe(-2);
  });

  it("should calculate correct min and max font sizes for each step", () => {
    const config = {
      positiveSteps: 1,
      negativeSteps: 1,
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      relativeTo: "viewport",
    };

    const result = calculateTypeScale(config);

    expect(result).toHaveLength(3);

    // Check positive step
    expect(result[0].minFontSize).toBeCloseTo(19.2, 1); // 16 * 1.2
    expect(result[0].maxFontSize).toBeCloseTo(25, 1); // 20 * 1.25

    // Check zero step
    expect(result[1].minFontSize).toBeCloseTo(16, 1);
    expect(result[1].maxFontSize).toBeCloseTo(20, 1);

    // Check negative step
    expect(result[2].minFontSize).toBeCloseTo(13.33, 1); // 16 / 1.2
    expect(result[2].maxFontSize).toBeCloseTo(16, 1); // 20 / 1.25
  });

  it("should not clamp font sizes smaller than md", () => {
    const config = {
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      positiveSteps: 2,
      negativeSteps: 2,
      relativeTo: "viewport",
    };

    const result = calculateTypeScale(config);

    // Check md size
    expect(result.find((r) => r.step === 0).clamp).toContain("clamp(");

    // Check sizes smaller than md
    for (const size of result) {
      if (size.step < 0) {
        expect(size.clamp).not.toContain("clamp(");
        expect(size.clamp).toMatch(/^\d+(\.\d+)?rem$/);
      }
    }
  });

  it("should use the smaller scale for sizes below md", () => {
    const config = {
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      positiveSteps: 2,
      negativeSteps: 2,
      relativeTo: "viewport",
    };

    const result = calculateTypeScale(config);

    const mdSize = result.find((r) => r.step === 0);
    const smallerSizes = result.filter((r) => r.step < 0);

    smallerSizes.forEach((size, index) => {
      const expectedSize =
        config.minFontSize / config.minTypeScale ** (index + 1);
      expect(Number.parseFloat(size.clamp)).toBeCloseTo(expectedSize / 16, 2); // Convert to rem
    });
  });
});

describe("generateTypeCSSVariables", () => {
  it("should generate correct CSS variables for a valid configuration", () => {
    const config = {
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      positiveSteps: 2,
      negativeSteps: 1,
      relativeTo: "viewport",
      typeLabels: ["2xl", "1xl", "md", "1xs", "2xs"], // Ensure "md" is in the middle
    };

    const result = generateTypeCSSVariables(config);

    expect(result).toContain("--fs-2xl:");
    expect(result).toContain("--fs-1xl:");
    expect(result).toContain("--fs-md:");
    expect(result).toContain("--fs-1xs:");
    expect(result).toContain("clamp(");
    expect(result).toContain("vi");
    expect(result).toContain("/* min:");
    expect(result).toContain("max:");
  });

  it('should throw an error when "md" is not in the label array', () => {
    const config = {
      // ... other config options ...
      typeLabels: ["xl", "lg", "sm", "xs"], // No "md"
    };

    expect(() => generateTypeCSSVariables(config)).toThrow(
      "The label array must include 'md' as the base size.",
    );
  });

  it("should handle configuration with only positive steps", () => {
    const config = {
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      positiveSteps: 3,
      negativeSteps: 0,
      relativeTo: "viewport",
    };

    const result = generateTypeCSSVariables(config);

    expect(result).toContain("--fs-3xl:");
    expect(result).toContain("--fs-2xl:");
    expect(result).toContain("--fs-1xl:");
    expect(result).toContain("--fs-md:");
    expect(result).not.toContain("--fs-1xs:");
  });

  it("should handle configuration with only negative steps", () => {
    const config = {
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      positiveSteps: 0,
      negativeSteps: 2,
      relativeTo: "viewport",
    };

    const result = generateTypeCSSVariables(config);

    expect(result).toContain("--fs-md:");
    expect(result).toContain("--fs-1xs:");
    expect(result).toContain("--fs-2xs:");
    expect(result).not.toContain("--fs-1xl:");
  });

  it("should generate fixed values for sizes smaller than md", () => {
    const config = {
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      positiveSteps: 2,
      negativeSteps: 2,
      relativeTo: "viewport",
    };

    const result = generateTypeCSSVariables(config);

    expect(result).toContain("--fs-md: clamp(");
    expect(result).toContain("--fs-1xs: 0.8333rem;");
    expect(result).toContain("--fs-2xs: 0.6944rem;");
  });
  it("should handle more sizes than available labels by extending the default labeling system", () => {
    const config = {
      minWidth: 320,
      maxWidth: 1200,
      minFontSize: 16,
      maxFontSize: 20,
      minTypeScale: 1.2,
      maxTypeScale: 1.25,
      positiveSteps: 10, // This will generate more sizes than available labels
      negativeSteps: 0,
      relativeTo: "viewport",
    };

    const result = generateTypeCSSVariables(config);

    // Check for extended labels
    expect(result).toContain("--fs-10xl:");
    expect(result).toContain("--fs-9xl:");
    expect(result).toContain("--fs-8xl:");

    // Check for standard labels
    expect(result).toContain("--fs-7xl:");
    expect(result).toContain("--fs-md:");

    // Verify correct ordering (largest to smallest)
    const lines = result.split("\n");
    expect(lines[0]).toContain("--fs-10xl:");
    expect(lines[lines.length - 1]).toContain("--fs-md:");

    // Check format of each line
    for (const line of lines) {
      expect(line).toMatch(
        /^\s+--fs-\w+: clamp\(.+\); \/\* min: .+ max: .+ \*\/$/,
      );
    }
  });
});
