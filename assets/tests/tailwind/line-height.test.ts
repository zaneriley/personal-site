import { describe, it, expect } from "vitest";
import { calculateLineHeight } from "../../tailwind/line-height";
import { LineHeightConfig } from "../../tailwind/configs/type-config";

// Define minimum line height thresholds per configuration
const minLineHeightThresholds: { [key: string]: number } = {
  latin: 1.0,
  cjk: 1.0, // Adjust as needed per script
};

const latinConfig: LineHeightConfig = {
  baseFontSize: 18,
  baseLineHeight: 1.555555556,
  scalingFactor: 0.5,
  incrementStep: "half", // Updated to match test description
};

const cjkConfig: LineHeightConfig = {
  baseFontSize: 18,
  baseLineHeight: 2,
  scalingFactor: 0.1,
  incrementStep: "whole",
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

  // it('should decrease line-height as fontSize increases', () => {
  //   const smallFontSize = 18; // Base font size
  //   const largeFontSize = 24; // Larger font size

  //   const smallLineHeight = calculateLineHeight(latinConfig, smallFontSize);
  //   const largeLineHeight = calculateLineHeight(latinConfig, largeFontSize);

  //   expect(largeLineHeight).toBeLessThan(smallLineHeight);
  // });

  //     it('should snap line-height to nearest half baselineUnit', () => {
  //       const fontSize = 22; // Arbitrary font size
  //       const lineHeight = calculateLineHeight(latinConfig, fontSize); // Unitless
  //       const baselineUnitPx = latinConfig.baseLineHeight * latinConfig.baseFontSize / 2; // 13.5px
  //       const desiredLineHeightPx = lineHeight * fontSize; // Convert unitless to px
  //       const snappedLineHeightPx = getSnappedLineHeightPx(desiredLineHeightPx, latinConfig.incrementStep, baselineUnitPx);
  //       const snappedLineHeight = snappedLineHeightPx / fontSize; // Convert back to unitless
  //       expect(lineHeight).toBeCloseTo(snappedLineHeight, 5);
  //     });

  //     it('should not fall below minimum line-height threshold', () => {
  //       const fontSize = 46; // Large font size
  //       const lineHeight = calculateLineHeight(latinConfig, fontSize);
  //       const minLineHeight = minLineHeightThresholds['latin'];

  //       expect(lineHeight).toBeGreaterThanOrEqual(minLineHeight);
  //     });
  //   });

  //   describe('CJK Script', () => {
  //     it('should calculate baselineUnit as characterSize', () => {
  //       const baselineUnitPx = cjkConfig.baseLineHeight; // For 'whole' increment
  //       expect(baselineUnitPx).toBe(2); // Adjusted to match configuration
  //     });

  //     it('should snap line-height to nearest whole baselineUnit', () => {
  //       const fontSize = 1.5;
  //       const lineHeight = calculateLineHeight(cjkConfig, fontSize); // Unitless
  //       const baselineUnitPx = cjkConfig.baseLineHeight * cjkConfig.baseFontSize / 1; // 2 * 18 / 1 = 36px
  //       const desiredLineHeightPx = lineHeight * fontSize; // Convert unitless to px
  //       const snappedLineHeightPx = getSnappedLineHeightPx(desiredLineHeightPx, cjkConfig.incrementStep, baselineUnitPx);
  //       const snappedLineHeight = snappedLineHeightPx / fontSize; // Convert back to unitless
  //       expect(lineHeight).toBeCloseTo(snappedLineHeight, 5);
  //     });

  //     it('should handle varying font sizes appropriately', () => {
  //       const fontSizes = [1, 1.5, 2, 2.5];
  //       fontSizes.forEach((fontSize) => {
  //         const lineHeight = calculateLineHeight(cjkConfig, fontSize);
  //         const minLineHeight = minLineHeightThresholds['cjk'];
  //         expect(lineHeight).toBeGreaterThanOrEqual(minLineHeight);
  //       });
  //     });
  //   });

  //   describe('General Cases', () => {
  //     it('should handle negative font sizes gracefully', () => {
  //       const fontSize = -1;
  //       expect(() => calculateLineHeight(latinConfig, fontSize)).toThrow('Font size must be positive.');
  //     });
});
