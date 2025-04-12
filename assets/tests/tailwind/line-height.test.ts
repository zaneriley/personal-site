import { describe, expect, it } from "vitest";
import type { LineHeightConfig } from "../../tailwind/configs/type-config";
import { calculateLineHeight } from "../../tailwind/line-height";

// Define minimum line height thresholds per configuration
const minLineHeightThresholds: { [key: string]: number } = {
  latin: 1.0,
  cjk: 1.0, // Adjust as needed per script
};

const latinConfig: LineHeightConfig = {
  baseFontSize: 18,
  baseLineHeight: 1.555555556,
  scalingFactor: 0.5,
  incrementStep: "half",
  incrementMethod: "latin",
};

const cjkConfig: LineHeightConfig = {
  baseFontSize: 18,
  baseLineHeight: 2,
  scalingFactor: 0.5,
  incrementStep: "whole",
  incrementMethod: "cjk",
};

describe("calculateLineHeight", () => {
  describe("Latin Script", () => {
    it("should return the correct line-height for base font size", () => {
      const lineHeight = calculateLineHeight(latinConfig, 18);
      expect(lineHeight).toBeCloseTo(1.5556, 3);
    });

    it("should calculate correct line-height for larger font size", () => {
      const lineHeight = calculateLineHeight(latinConfig, 24);
      expect(lineHeight).toBeCloseTo(1.1666, 3);
    });

    it("should calculate correct line-height for smaller font size", () => {
      const lineHeight = calculateLineHeight(latinConfig, 12);
      expect(lineHeight).toBeCloseTo(1.75, 3);
    });

    it("should calculate correct line-height for line-heights under 1", () => {
      const lineHeight = calculateLineHeight(latinConfig, 72);
      expect(lineHeight).toBeCloseTo(0.7778, 3);
    });

    it("should throw an error for zero font size", () => {
      expect(() => calculateLineHeight(latinConfig, 0)).toThrow(
        "Font size must be positive.",
      );
    });
  });
  describe("CJK Script", () => {
    it("should calculate baselineUnit as characterSize", () => {
      const lineHeight = calculateLineHeight(cjkConfig, 42);
      expect(lineHeight).toBeCloseTo(0.8571428572, 3);
    });
  });
});
