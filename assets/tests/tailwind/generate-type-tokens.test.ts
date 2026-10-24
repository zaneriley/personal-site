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
import * as generateTypeTokensModule from "../../tailwind/generate-type-tokens";

// Import latinTypeConfig if needed for labels, although the test doesn't directly use it now
// import { latinTypeConfig } from "../../tailwind/configs/type-config";

// Define DEFAULT_OUTPUT_PATH locally for test verification
const DEFAULT_OUTPUT_PATH = path.resolve("css/_type-tokens.generated.css");

const {
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
    // The curve is derived: regular(step) = base − opszSlope·step;
    // bold(step) = regular + boldDelta − boldSlope·step. md is the anchor (step 0).
    // These exact values are the contract — a mismatch means the relationship,
    // not a literal, changed (knobs: base 268, opsz 30, boldDelta 350, boldSlope 40).
    expect(generatedCSS).toContain("--fw-flexa-md: 268;"); // anchor regular
    expect(generatedCSS).toContain("--fw-flexa-md-bold: 618;"); // anchor + delta
    expect(generatedCSS).toContain("--fw-flexa-4xl: 148;"); // +4 steps lighter
    expect(generatedCSS).toContain("--fw-flexa-2xs-bold: 758;"); // −2 steps, near 800 ceiling
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
