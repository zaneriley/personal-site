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

// --- Updated Font Metrics Mock ---
// Mock the font metrics import based on the new strategy
vi.mock("../../tailwind/font-metrics.json", () => ({
  default: {
    // Use the structure and values from the user's example
    // NOTE: The actual implementation uses ascent/capHeight/descent directly,
    // so the values here should reflect that input format if generateCSS reads them.
    // The generateFontMetricsCSS function expects unitsPerEm, capHeight, ascent, descent.
    // Let's use the previous mock structure which aligns with the implementation's expected input.
    "test-font-a": {
      unitsPerEm: 1000,
      capHeight: 700,
      ascent: 1000,
      descent: -200,
      xHeight: 500,
    },
    "test-font-b": {
      unitsPerEm: 2048,
      capHeight: 1434,
      ascent: 2048,
      descent: -410,
      xHeight: 1024,
    },
  },
}));

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
      /--cardinal-fruit-web-medium-trial-distance-top:\s*0\.2700;/,
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
      /--cardinal-fruit-web-medium-trial-distance-bottom:\s*0\.3200;/,
    );
  });

  it("should contain --lh-en-{size} variables with valid positive numbers", () => {
    // Check a few examples based on default latinTypeConfig labels ('md', '4xl', '1xs' etc.)
    expect(generatedCSS).toMatch(/--lh-en-md:\s*\d+(\.\d+)?;/);
    expect(generatedCSS).toMatch(/--lh-en-4xl:\s*\d+(\.\d+)?;/);
    expect(generatedCSS).toMatch(/--lh-en-1xs:\s*\d+(\.\d+)?;/);

    // Extract and check if a value is positive (example for 'md')
    const matchMd = generatedCSS.match(/--lh-en-md:\s*(\d+(\.\d+)?);/);
    expect(matchMd).not.toBeNull();
    if (matchMd) {
      expect(Number.parseFloat(matchMd[1])).toBeGreaterThan(0);
    }

    // Extract and check another value ('1xs')
    const match1xs = generatedCSS.match(/--lh-en-1xs:\s*(\d+(\.\d+)?);/);
    expect(match1xs).not.toBeNull();
    if (match1xs) {
      expect(Number.parseFloat(match1xs[1])).toBeGreaterThan(0);
    }
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
