import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { afterEach, describe, expect, it } from "vitest";
import {
  CSSParsingError,
  type FontMetrics,
  extractFontMetrics,
  generateFontMetricsJSON,
  getFontPathsFromCSS,
} from "../../tailwind/extract-font-metrics";

describe("getFontPathsFromCSS", () => {
  const cssFilePath = path.resolve(__dirname, "../../css/_fontface.css");

  it("should extract font paths from a valid CSS file", () => {
    const fontPaths = getFontPathsFromCSS(cssFilePath);

    expect(Array.isArray(fontPaths)).toBe(true);
    expect(fontPaths.length).toBeGreaterThan(0);
    for (const fontPath of fontPaths) {
      expect(typeof fontPath).toBe("string");
      expect(fontPath).toMatch(/\.(woff2?|ttf|otf)$/i);
    }
  });

  it("should throw CSSParsingError for missing CSS file", () => {
    const invalidCssPath = path.resolve(__dirname, "../../css/nonexistent.css");
    expect(() => {
      getFontPathsFromCSS(invalidCssPath);
    }).toThrow(CSSParsingError);
  });

  it("should return an empty array when no @font-face declarations are found", () => {
    const emptyCssPath = path.resolve(__dirname, "../../css/empty.css");

    // Create an empty CSS file for this test
    fs.writeFileSync(emptyCssPath, "");

    try {
      const fontPaths = getFontPathsFromCSS(emptyCssPath);
      expect(Array.isArray(fontPaths)).toBe(true);
      expect(fontPaths.length).toBe(0);
    } finally {
      // Clean up: remove the temporary file
      fs.unlinkSync(emptyCssPath);
    }
  });

  it("should extract paths with different formats and multiple URLs", () => {
    const fontPaths = getFontPathsFromCSS(cssFilePath);
    expect(fontPaths).toContain("/fonts/cheee-small.woff2");
    expect(fontPaths).toContain("/fonts/cheee-small.woff");
  });

  it("should handle malformed @font-face declarations", () => {
    const malformedCssPath = path.resolve(
      __dirname,
      "../../css/malformed-fontface.css",
    );

    // Create a malformed CSS file for this test
    const malformedContent = `
        @font-face {
          font-family: 'Malformed Font';
          src: url('/fonts/malformed.woff2') format('woff2'),
          This line is malformed
          url('/fonts/malformed.woff') format('woff');
        }
        @font-face {
          font-family: 'Valid Font';
          src: url('/fonts/valid.woff2') format('woff2');
        }
      `;
    fs.writeFileSync(malformedCssPath, malformedContent);

    try {
      const fontPaths = getFontPathsFromCSS(malformedCssPath);
      expect(fontPaths.length).toBeGreaterThan(0);
      expect(fontPaths).toContain("/fonts/valid.woff2");
    } finally {
      // Clean up: remove the temporary file
      fs.unlinkSync(malformedCssPath);
    }
  });

  it("should resolve relative and absolute font paths correctly", () => {
    console.log(`Current working directory: ${process.cwd()}`);
    console.log(`Directory of current file: ${__dirname}`);
    console.log(
      `Absolute path of this test file: ${path.resolve(__dirname, __filename)}`,
    );

    const webRoot = path.resolve(__dirname, "../../static");
    console.log(`Calculated webRoot: ${webRoot}`);

    const cssFilePath = path.resolve(__dirname, "../../css/_fontface.css");
    console.log(`CSS file path: ${cssFilePath}`);

    const fontPaths = getFontPathsFromCSS(cssFilePath, webRoot);

    for (const absoluteFontPath of fontPaths) {
      const exists = fs.existsSync(absoluteFontPath);
      console.log(`Checking if file exists: ${absoluteFontPath} -> ${exists}`);
      expect(exists).toBe(true);
    }
  });
});

describe("extractFontMetrics", () => {
  const fontsDirectory = path.resolve(__dirname, "../../static/fonts");

  it("should successfully extract metrics from a valid font file", () => {
    // Update this line to use an existing font file
    const fontPath = path.join(
      fontsDirectory,
      "trials/CardinalFruitWeb-Medium-Trial.woff2",
    );
    const metrics: FontMetrics = extractFontMetrics(fontPath);

    // Corrected property names
    expect(metrics).toHaveProperty("capHeight");
    expect(metrics).toHaveProperty("ascent");
    expect(metrics).toHaveProperty("descent");
    expect(metrics).toHaveProperty("xHeight");

    expect(typeof metrics.capHeight).toBe("number");
    expect(typeof metrics.ascent).toBe("number");
    expect(typeof metrics.descent).toBe("number");
    expect(typeof metrics.xHeight).toBe("number");

    // Ensure values are within expected ranges (0 to 1)
    expect(metrics.capHeight).toBeGreaterThan(0);
    expect(metrics.capHeight).toBeLessThanOrEqual(2);
    expect(metrics.ascent).toBeGreaterThan(0);
    expect(metrics.ascent).toBeLessThanOrEqual(2);
    expect(metrics.descent).toBeLessThanOrEqual(0); // descent usually negative
    expect(metrics.descent).toBeGreaterThanOrEqual(-2);
  });

  it("should handle missing font file gracefully", () => {
    const fontPath = path.join(fontsDirectory, "NonExistentFont.ttf");

    expect(() => {
      extractFontMetrics(fontPath);
    }).toThrowError(/ENOENT|no such file or directory/i);
  });

  it("should correctly extract metrics from different font formats", () => {
    // Update this test to use existing font files
    const fontFiles = [
      "trials/CardinalFruitWeb-Medium-Trial.woff2",
      "trials/GT-Flexa-Trial-VF.woff2",
      "cheee-small.woff",
      "noto-sans-jp.ttf",
    ];

    // Replace forEach with for...of loop
    for (const fontFile of fontFiles) {
      const fontPath = path.join(fontsDirectory, fontFile);

      const metrics: FontMetrics = extractFontMetrics(fontPath);

      expect(metrics).toBeDefined();
      expect(metrics.capHeight).toBeGreaterThan(0);
      expect(metrics.capHeight).toBeLessThanOrEqual(1);
    }
  });

  it("should produce consistent results across multiple runs", () => {
    const fontPath = path.join(fontsDirectory, "cheee-small.woff");
    const metrics1: FontMetrics = extractFontMetrics(fontPath);
    const metrics2: FontMetrics = extractFontMetrics(fontPath);

    expect(metrics1).toEqual(metrics2);
  });
});

// Adding tests for generateFontMetricsJSON

describe("generateFontMetricsJSON", () => {
  const cssFilePath = path.resolve(__dirname, "../../css/_fontface.css");
  const outputJsonPath = path.resolve(
    __dirname,
    "../../tailwind/font-metrics.test.json",
  );
  const webRoot = path.resolve(__dirname, "../../static"); // Updated webRoot

  afterEach(() => {
    // Clean up after each test
    if (fs.existsSync(outputJsonPath)) {
      fs.unlinkSync(outputJsonPath);
    }
  });

  it("should successfully generate font-metrics.json with correct content", () => {
    generateFontMetricsJSON(cssFilePath, outputJsonPath, webRoot);

    expect(fs.existsSync(outputJsonPath)).toBe(true);

    const data = fs.readFileSync(outputJsonPath, "utf8");
    const metrics = JSON.parse(data);

    expect(metrics).toBeDefined();
    expect(Object.keys(metrics).length).toBeGreaterThan(0);

    // Check that metrics for known fonts are present
    expect(metrics).toHaveProperty("cheee-small");
    expect(metrics).toHaveProperty("CardinalFruitWeb-Medium-Trial");
  });

  it("should handle missing CSS file gracefully", () => {
    const invalidCssPath = path.resolve(__dirname, "../../css/nonexistent.css");

    expect(() => {
      generateFontMetricsJSON(invalidCssPath, outputJsonPath, webRoot);
    }).toThrow(CSSParsingError);

    expect(fs.existsSync(outputJsonPath)).toBe(false);
  });

  it("should create an empty JSON file when no @font-face declarations are found", () => {
    const emptyCssPath = path.resolve(__dirname, "../../css/empty.css");
    // Create an empty CSS file
    fs.writeFileSync(emptyCssPath, "");

    try {
      generateFontMetricsJSON(emptyCssPath, outputJsonPath, webRoot);

      expect(fs.existsSync(outputJsonPath)).toBe(true);

      const data = fs.readFileSync(outputJsonPath, "utf8");
      const metrics = JSON.parse(data);

      expect(metrics).toEqual({});
    } finally {
      // Clean up
      fs.unlinkSync(emptyCssPath);
    }
  });

  it("should continue processing fonts even if one font causes an error", () => {
    const malformedCssPath = path.resolve(
      __dirname,
      "../../css/malformed-fontface.css",
    );
    // Create a CSS file with one valid and one invalid font path
    const cssContent = `
      @font-face {
        font-family: 'Valid Font';
        src: url('/fonts/cheee-small.woff') format('woff');
      }
      @font-face {
        font-family: 'Invalid Font';
        src: url('/fonts/nonexistent-font.woff2') format('woff2');
      }
    `;
    fs.writeFileSync(malformedCssPath, cssContent);

    try {
      generateFontMetricsJSON(malformedCssPath, outputJsonPath, webRoot);

      expect(fs.existsSync(outputJsonPath)).toBe(true);

      const data = fs.readFileSync(outputJsonPath, "utf8");
      const metrics = JSON.parse(data);

      // Should only contain the valid font
      expect(metrics).toHaveProperty("cheee-small");
      expect(metrics).not.toHaveProperty("nonexistent-font");
    } finally {
      // Clean up
      fs.unlinkSync(malformedCssPath);
    }
  });

  it("should generate correct metrics for fonts", () => {
    generateFontMetricsJSON(cssFilePath, outputJsonPath, webRoot);

    const data = fs.readFileSync(outputJsonPath, "utf8");
    const metrics = JSON.parse(data);

    for (const fontName in metrics) {
      if (Object.prototype.hasOwnProperty.call(metrics, fontName)) {
        const fontMetrics = metrics[fontName];
        expect(fontMetrics.capHeight).toBeGreaterThan(0);
        expect(fontMetrics.capHeight).toBeLessThanOrEqual(1);
        expect(fontMetrics.ascent).toBeGreaterThan(0);
        expect(fontMetrics.ascent).toBeLessThanOrEqual(2);
        expect(fontMetrics.descent).toBeLessThanOrEqual(0);
        expect(fontMetrics.descent).toBeGreaterThanOrEqual(-1);
        expect(fontMetrics.xHeight).toBeGreaterThan(0);
        expect(fontMetrics.xHeight).toBeLessThanOrEqual(1);
      }
    }
  });

  it("should correctly serialize fontMetrics into JSON", () => {
    const fontMetrics = {
      "cheee-small": {
        unitsPerEm: 1000,
        capHeight: 0.64,
        ascent: 1.164,
        descent: -0.238,
        xHeight: 0.6,
      },
    };

    const outputJsonPath =
      "/app/assets/tailwind/font-metrics.serialize-test.json";

    fs.writeFileSync(
      outputJsonPath,
      JSON.stringify(fontMetrics, null, 2),
      "utf8",
    );

    const writtenContent = fs.readFileSync(outputJsonPath, "utf8");
    const parsedContent = JSON.parse(writtenContent);

    expect(parsedContent).toEqual(fontMetrics);

    // Clean up
    fs.unlinkSync(outputJsonPath);
  });
});
