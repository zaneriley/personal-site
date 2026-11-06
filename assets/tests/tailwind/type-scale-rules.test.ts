import { beforeAll, describe, expect, it } from "vitest";
import { generateCSS } from "../../tailwind/generate-type-tokens";

// The design rules of the type scale, checked against the CSS the generator
// emits, evaluated at every width. See the type scale design doc.
const widths = Array.from({ length: 1914 - 320 + 1 }, (_, i) => 320 + i);
const headings = ["1xl", "2xl", "3xl", "4xl", "5xl", "6xl", "7xl"];
const small = { "1xs": 16.9232, "2xs": 13.0176, "3xs": 10.0144 };
const everySize = [...headings, "md", ...Object.keys(small)];
const CAP = 0.7;
const GAP = 12.6;

let css: string;

const token = (name: string): string => {
  const match = css.match(new RegExp(`--${name}:\\s*([^;]+);`));
  if (!match) throw new Error(`No token --${name}`);
  return match[1].replace(/\s+/g, " ").trim();
};

// Evaluates clamp()/min()/max() of `<n>rem [+ <n>vi]` at one viewport width.
const evaluate = (expression: string, width: number): number => {
  const fn = expression.match(/^(clamp|min|max)\((.*)\)$/);
  if (fn) {
    const parts: string[] = [];
    let depth = 0;
    let current = "";
    for (const char of fn[2]) {
      if (char === "(") depth++;
      if (char === ")") depth--;
      if (char === "," && depth === 0) {
        parts.push(current);
        current = "";
      } else current += char;
    }
    parts.push(current);
    const values = parts.map((part) => evaluate(part.trim(), width));
    if (fn[1] === "min") return Math.min(...values);
    if (fn[1] === "max") return Math.max(...values);
    return Math.min(values[2], Math.max(values[0], values[1]));
  }
  return expression.split(" + ").reduce((total, term) => {
    const value = Number.parseFloat(term);
    if (term.endsWith("rem")) return total + value * 16;
    if (term.endsWith("vi")) return total + (value * width) / 100;
    throw new Error(`Unexpected term ${term}`);
  }, 0);
};

const sizeAt = (label: string, width: number, script = "latin"): number =>
  evaluate(token(`${script}-fs-${label}`), width);

const lineHeight = (size: number) => Math.round(CAP * size + GAP);

describe("type scale rules", () => {
  beforeAll(() => {
    css = generateCSS();
  });

  it("holds the body flat on phones and at full size from 1024", () => {
    for (const width of widths) {
      const body = sizeAt("md", width);
      if (width <= 570) expect(body).toBeCloseTo(22 / 1.2, 1);
      if (width >= 1024) expect(body).toBeCloseTo(22, 1);
    }
  });

  it("gives phones one value per size", () => {
    for (const label of everySize) {
      for (const width of widths.filter((w) => w <= 570)) {
        expect(sizeAt(label, width)).toBeCloseTo(sizeAt(label, 320), 2);
      }
    }
  });

  it("keeps every step above the body at 1.2 or more", () => {
    const ladder = ["md", ...headings];
    for (const width of widths) {
      for (let i = 1; i < ladder.length; i++) {
        const step = sizeAt(ladder[i], width) / sizeAt(ladder[i - 1], width);
        expect(step).toBeGreaterThanOrEqual(1.199);
      }
    }
  });

  it("never renders a size below 10px", () => {
    for (const width of widths) {
      for (const label of everySize) {
        expect(sizeAt(label, width)).toBeGreaterThanOrEqual(10);
      }
    }
  });

  it("keeps line gaps within 1px of each other at every width", () => {
    for (const width of widths) {
      const gaps = everySize.map((label) => {
        const size = sizeAt(label, width);
        return lineHeight(size) - CAP * size;
      });
      expect(Math.max(...gaps) - Math.min(...gaps)).toBeLessThanOrEqual(1);
    }
  });

  it("keeps the small sizes and their weights unchanged", () => {
    for (const [label, px] of Object.entries(small)) {
      for (const width of [320, 570, 1024, 1914]) {
        expect(sizeAt(label, width)).toBeCloseTo(px, 1);
      }
    }
    for (const [name, weight] of Object.entries({
      "1xs": 363,
      "2xs": 423,
      "3xs": 478,
      "1xs-bold": 697,
      "2xs-bold": 734,
      "3xs-bold": 774,
    })) {
      expect(token(`fw-flexa-${name}`)).toBe(String(weight));
    }
  });

  it("uses the same font sizes in Japanese", () => {
    for (const label of everySize) {
      expect(token(`cjk-fs-${label}`)).toBe(token(`latin-fs-${label}`));
    }
  });
});
