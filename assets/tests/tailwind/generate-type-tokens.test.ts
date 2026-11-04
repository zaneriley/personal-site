import path from "node:path";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

// Corrected fs mock for both sync and async usage in tests
vi.mock("node:fs", async (importOriginal) => {
  const originalFs = await importOriginal<typeof import("node:fs")>();
  const mkdirPromiseMock = vi.fn().mockResolvedValue(undefined);
  const writeFilePromiseMock = vi.fn().mockResolvedValue(undefined);
  return {
    ...originalFs,
    mkdirSync: vi.fn(),
    writeFileSync: vi.fn(),
    promises: {
      mkdir: mkdirPromiseMock,
      writeFile: writeFilePromiseMock,
    },
    default: {
      mkdirSync: vi.fn(),
      writeFileSync: vi.fn(),
      promises: {
        mkdir: mkdirPromiseMock,
        writeFile: writeFilePromiseMock,
      },
    },
  };
});

// --- Test Subject ---
import fs from "node:fs";
import { flexaWeightConfig } from "../../tailwind/configs/type-config";
import * as generateTypeTokensModule from "../../tailwind/generate-type-tokens";

// Import latinTypeConfig if needed for labels, although the test doesn't directly use it now
// import { latinTypeConfig } from "../../tailwind/configs/type-config";

// Define DEFAULT_OUTPUT_PATH locally for test verification
const DEFAULT_OUTPUT_PATH = path.resolve("css/_type-tokens.generated.css");

const {
  flexaWeightRungs,
  generateCSS, // This is the function we want to test directly now
  generateAndWriteCSS,
  writeCSS,
  // ... other functions ...
} = generateTypeTokensModule;

// --- Updated Tests for generateCSS Output Contract ---

describe("generateCSS Output Contract", () => {
  let generatedCSS: string;

  beforeAll(() => {
    // generateCSS will now use the path-mocked font metrics
    // It relies on require internally, which should work fine in Vitest/Node
    generatedCSS = generateCSS();
  });

  it("should contain the :root selector with variables", () => {
    expect(generatedCSS).toContain(":root {");
    // Check a sample variable expected from generateScriptVariables("latin")
    expect(generatedCSS).toMatch(/--latin-fs-\w+:/);
    expect(generatedCSS).toContain("}");
  });

  it('should contain the html[lang="ja"] selector with overrides', () => {
    expect(generatedCSS).toContain('html[lang="ja"] {');
    // Check a sample override expected from generateSemanticVariables("cjk")
    expect(generatedCSS).toMatch(/--fs-\w+:\s*var\(--cjk-fs-\w+\);/);
    expect(generatedCSS).toContain("}");
  });

  it("should contain correctly formatted --distance-top variables based on REAL metrics", () => {
    // Updated expectations based on actual font-metrics.json and generateFontMetricsCSS logic
    expect(generatedCSS).toMatch(/--cheee-small-distance-top:\s*0\.5240;/);
    expect(generatedCSS).toMatch(/--noto-sans-jp-distance-top:\s*0\.4270;/);
    expect(generatedCSS).toMatch(
      /--cardinal-fruit-web-medium-trial-distance-top:\s*0\.2500;/,
    );
    // Check against duplication (simple count check for one key)
    const topMatches = generatedCSS.match(/--cheee-small-distance-top:/g);
    expect(topMatches ? topMatches.length : 0).toBe(1);
  });

  it("should contain correctly formatted --distance-bottom variables based on REAL metrics", () => {
    // Updated expectations based on actual font-metrics.json and generateFontMetricsCSS logic
    expect(generatedCSS).toMatch(/--cheee-small-distance-bottom:\s*0\.2380;/);
    expect(generatedCSS).toMatch(/--noto-sans-jp-distance-bottom:\s*0\.2880;/);
    expect(generatedCSS).toMatch(
      /--cardinal-fruit-web-medium-trial-distance-bottom:\s*0\.3180;/,
    );
  });

  it("keeps leading live at every generated size, including 6xl", () => {
    for (const size of ["3xs", "md", "4xl", "6xl", "7xl"]) {
      expect(generatedCSS).toContain(
        `--lh-en-${size}: round(nearest, calc(0.7 * var(--latin-fs-${size}) + var(--latin-interline-gap)), var(--latin-leading-unit));`,
      );
    }
    expect(generatedCSS).toContain(
      "--cjk-lh: calc(1em + var(--cjk-interline-gap));",
    );
    expect(generatedCSS).toContain("--cjk-interline-gap: 0.6875rem;");
  });

  it("anchors layout spacing to the paragraph separately for each script", () => {
    expect(generatedCSS).toContain("--latin-space-md: calc(1.75rem * 1);");
    expect(generatedCSS).toContain("--cjk-space-md: calc(1.375rem * 1);");
    expect(generatedCSS).toContain("--latin-space-3xs: calc(1.75rem * 0.125);");
  });

  it("should derive the GT Flexa optical weight rungs from the knobs", () => {
    // The anchor (md) keeps the weights set by eye; other sizes get the weight
    // whose measured stem gives stem(md) · (size/md)^−k (display k above md, text k below).
    expect(generatedCSS).toContain("--fw-flexa-md: 268;");
    expect(generatedCSS).toContain("--fw-flexa-md-bold: 618;");
    expect(generatedCSS).toContain("--fw-flexa-4xl: 222;");
    expect(generatedCSS).toContain("--fw-flexa-3xs: 432;");
    expect(generatedCSS).toContain("--fw-flexa-3xs-bold: 774;");
  });

  it("keeps stroke width growing with size while its share of the size shrinks", () => {
    // The bug this guards: −30 wght/step held the stroke at ~2px from 2xl to
    // 4xl, so large type read 46% lighter relative to its size than md.
    const stem = (w: number) => {
      const t = flexaWeightConfig.stems;
      for (let i = 1; i < t.length; i++)
        if (w <= t[i][0])
          return (
            t[i - 1][1] +
            ((t[i][1] - t[i - 1][1]) * (w - t[i - 1][0])) /
              (t[i][0] - t[i - 1][0])
          );
      return t[t.length - 1][1];
    };
    for (const weight of ["regular", "bold"] as const) {
      const rungs = flexaWeightRungs(flexaWeightConfig);
      for (let i = 1; i < rungs.length; i++) {
        const larger = rungs[i - 1];
        const smaller = rungs[i];
        const largerStemPx = stem(larger[weight]) * larger.size;
        const smallerStemPx = stem(smaller[weight]) * smaller.size;
        expect(largerStemPx).toBeGreaterThan(smallerStemPx);
        expect(stem(larger[weight])).toBeLessThanOrEqual(stem(smaller[weight]));
      }
    }
  });

  it("makes small text heavier than the old linear rule did", () => {
    // 2026-11-04 regression: a shared k = 0.2 dropped 3xs from 358 to 331.
    const old: Record<string, number> = { "1xs": 298, "2xs": 328, "3xs": 358 };
    for (const r of flexaWeightRungs(flexaWeightConfig)) {
      if (r.label in old) expect(r.regular).toBeGreaterThan(old[r.label]);
    }
  });

  it("stays inside the font's weight range at every rung", () => {
    for (const r of flexaWeightRungs(flexaWeightConfig)) {
      expect(r.regular).toBeGreaterThanOrEqual(100);
      expect(r.bold).toBeLessThanOrEqual(800);
    }
  });

  it("holds every size at the anchor's ratio when the exponent is 0", () => {
    const rungs = flexaWeightRungs({
      ...flexaWeightConfig,
      opticalExponent: { display: 0, text: 0 },
    });
    for (const r of rungs) {
      expect(r.regular).toBe(flexaWeightConfig.regular);
      expect(r.bold).toBe(flexaWeightConfig.bold);
    }
  });
});

// --- Keep existing tests for writeCSS and generateAndWriteCSS ---

describe("Critical Functional Tests - writeCSS", () => {
  const mockCSS = "/* Test CSS */"; // Specific CSS content for this test
  const expectedPath = path.resolve("css/_type-tokens.generated.css");

  beforeEach(() => {
    // Clear mocks for fs sync methods used by writeCSS
    vi.mocked(fs.mkdirSync).mockClear();
    vi.mocked(fs.writeFileSync).mockClear();
  });

  it("should attempt to write the provided CSS to the correct file using sync methods", () => {
    writeCSS(mockCSS);
    expect(fs.mkdirSync).toHaveBeenCalledWith(path.dirname(expectedPath), {
      recursive: true,
    });
    expect(fs.writeFileSync).toHaveBeenCalledWith(expectedPath, mockCSS);
  });

  it("should handle sync write errors gracefully", () => {
    const error = new Error("Sync Write failed");
    vi.mocked(fs.writeFileSync).mockImplementationOnce(() => {
      throw error;
    });
    // Since writeCSS calls generateCSS, then fs.writeFileSync, the error thrown
    // should originate from the fs call.
    // Corrected assertion to check the error message
    expect(() => writeCSS(mockCSS)).toThrowError(
      `Failed to write CSS file to ${expectedPath}: Sync Write failed`,
    );
  });
});

describe("Integration Tests - generateAndWriteCSS", () => {
  beforeEach(() => {
    vi.mocked(fs.mkdirSync).mockClear();
    vi.mocked(fs.writeFileSync).mockClear();
  });

  it("should generate and write CSS successfully using sync methods", () => {
    generateAndWriteCSS(); // Calls generateCSS -> writeCSS (using mocked fs)
    // Verify writeFileSync was called with the default path and the generated CSS string
    expect(fs.writeFileSync).toHaveBeenCalledWith(
      DEFAULT_OUTPUT_PATH,
      expect.any(String),
    );
  });

  it("should handle sync file system errors gracefully during write", () => {
    const error = new Error("Sync File system error during write");
    // Mock writeFileSync to throw, simulating an error during the write phase inside writeCSS
    vi.mocked(fs.writeFileSync).mockImplementationOnce(() => {
      throw error;
    });
    // generateAndWriteCSS lets writeCSS's actionable error propagate.
    expect(() => generateAndWriteCSS()).toThrowError(
      `Failed to write CSS file to ${DEFAULT_OUTPUT_PATH}: Sync File system error during write`,
    );
  });

  it("should use custom output path when provided (sync)", () => {
    const customPath = "custom/path/styles.css";
    generateAndWriteCSS({ outputPath: customPath });
    expect(fs.mkdirSync).toHaveBeenCalledWith(path.dirname(customPath), {
      recursive: true,
    });
    expect(fs.writeFileSync).toHaveBeenCalledWith(
      customPath,
      expect.any(String),
    );
  });
});
