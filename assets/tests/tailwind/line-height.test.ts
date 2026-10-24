import { describe, expect, it } from "vitest";
import {
  cjkLineHeightConfig as cjk,
  latinLineHeightConfig as latin,
} from "../../tailwind/configs/type-config";
import { calculateLineHeight } from "../../tailwind/line-height";

describe("paragraph-derived rhythm", () => {
  it("preserves the Latin paragraph anchor and never folds at large sizes", () => {
    expect(calculateLineHeight(latin, 22)).toBe(28);
    expect(calculateLineHeight(latin, 66)).toBe(56);
    expect(calculateLineHeight(latin, 100)).toBe(84);
    let previous = 0;
    for (let size = 8; size <= 140; size += 0.25) {
      const leading = calculateLineHeight(latin, size);
      expect(leading).toBeGreaterThanOrEqual(previous);
      expect(leading % 7).toBe(0);
      expect(Math.abs(leading - (0.7 * size + 12.6))).toBeLessThanOrEqual(
        3.5 + 1e-10,
      );
      previous = leading;
    }
  });
  it("uses the selected face's cap height at the rendered size", () => {
    expect(calculateLineHeight(latin, 46.03, 0.75)).toBe(49);
    expect(calculateLineHeight(latin, 46.03, 0.64)).toBe(42);
  });
  it("keeps an 11px CJK interline gap across sizes instead of snapping total leading", () => {
    for (const size of [10, 12.73, 22, 31.68, 46.03, 66, 100]) {
      expect(calculateLineHeight(cjk, size) - size).toBeCloseTo(11);
    }
    expect(calculateLineHeight(cjk, 22)).toBe(33);
  });
  it("derives the CJK gap from the configured paragraph body", () => {
    expect(calculateLineHeight({ ...cjk, paragraphSize: 24 }, 40)).toBe(52);
  });
  it.each([0, -1, NaN, Infinity])("rejects invalid font size %s", (size) => {
    expect(() => calculateLineHeight(latin, size)).toThrow(
      "Font size must be positive.",
    );
  });
});
