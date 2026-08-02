import { describe, expect, it, vi } from "vitest";
import type { LineHeightConfig } from "../../tailwind/configs/type-config";
import { calculateLineHeight } from "../../tailwind/line-height";

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

    it("should warn and default if incrementStep is invalid", () => {
      const consoleWarnSpy = vi
        .spyOn(console, "warn")
        .mockImplementation(() => {});

      // Define a looser type for the test setup
      type TestConfig = Omit<LineHeightConfig, "incrementStep"> & {
        incrementStep: string;
      };

      const invalidConfig: TestConfig = {
        ...latinConfig,
        incrementStep: "invalid_step", // Now valid for TestConfig
      };

      // Calculation should still proceed, likely defaulting to 'half'
      // Pass the TestConfig; calculateLineHeight should handle the string internally
      const lineHeight = calculateLineHeight(
        invalidConfig as LineHeightConfig,
        18,
      );
      expect(lineHeight).toBeGreaterThan(0); // Basic check that calculation didn't fail

      // Check that console.warn was called
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        expect.stringContaining("Invalid incrementStep: invalid_step"),
      );

      consoleWarnSpy.mockRestore(); // Clean up spy
    });
  });
  describe("CJK Script", () => {
    it("should calculate baselineUnit as characterSize", () => {
      const lineHeight = calculateLineHeight(cjkConfig, 42);
      expect(lineHeight).toBeCloseTo(0.8571428572, 3);
    });
  });
});
