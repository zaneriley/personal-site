import path from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// Mock fs module BEFORE importing the module under test
vi.mock("node:fs", () => ({
  default: {
    promises: {
      mkdir: vi.fn(),
      writeFile: vi.fn(),
    },
  },
  promises: {
    mkdir: vi.fn(),
    writeFile: vi.fn(),
  },
}));

import fs from "node:fs";
import * as generateTypeTokensModule from "../../tailwind/generate-type-tokens";

const {
  generateCSS,
  generateAndWriteCSS,
  namespaceVariables,
  generateSemanticVariables,
  writeCSS,
} = generateTypeTokensModule;

describe("Critical Functional Tests - generateCSS", () => {
  it("should generate complete CSS structure with all sections", () => {
    const css = generateCSS();

    expect(css).toContain("/* Latin Typography Variables */");
    expect(css).toContain("/* Latin Spacing Variables */");
    expect(css).toContain("/* CJK Typography Variables */");
    expect(css).toContain("/* CJK Spacing Variables */");
    expect(css).toContain("/* Font Metrics */");
    expect(css).toContain("/* Semantic Variables (Default to Latin) */");
    expect(css).toContain(":root {");
    expect(css).toContain('html[lang="ja"] {');
  });

  it("should integrate font metrics correctly", () => {
    const css = generateCSS();

    expect(css).toContain("--cheee-small-units-per-em:");
    expect(css).toContain("--noto-sans-jp-cap-height:");
    expect(css).toContain("--GT-Flexa-Trial-VF-ascent:");
  });

  it("should include semantic variable references", () => {
    const css = generateCSS();

    expect(css).toContain("--fs-7xl: var(--latin-fs-7xl);");
    expect(css).toContain("--space-md: var(--latin-space-md);");
    expect(css).toContain("--fs-7xl: var(--cjk-fs-7xl);");
  });
});

describe("Critical Functional Tests - writeCSS", () => {
  const mockCSS = "/* Test CSS */";
  const expectedPath = path.resolve("css/_typography.css");

  beforeEach(() => {
    vi.clearAllMocks();
    fs.promises.mkdir.mockResolvedValue(undefined);
    fs.promises.writeFile.mockResolvedValue(undefined);
  });

  it("should write CSS to the correct file", async () => {
    await writeCSS(mockCSS);

    expect(fs.promises.mkdir).toHaveBeenCalledWith(path.dirname(expectedPath), {
      recursive: true,
    });
    expect(fs.promises.writeFile).toHaveBeenCalledWith(expectedPath, mockCSS);
  });

  it("should handle write errors gracefully", async () => {
    const error = new Error("Write failed");
    fs.promises.writeFile.mockRejectedValue(error);

    await expect(writeCSS(mockCSS)).rejects.toThrow(
      `Failed to write CSS file to ${expectedPath}: Write failed`,
    );
  });
});

describe("Core Utility Tests - namespaceVariables", () => {
  it("should correctly namespace fs and space variables", () => {
    const input = `
      --fs-md: 1rem;
      --space-lg: 2rem;
      --other-var: 3rem;
    `;

    const result = namespaceVariables(input, "latin");

    expect(result).toContain("--latin-fs-md:");
    expect(result).toContain("--latin-space-lg:");
    expect(result).toContain("--other-var: 3rem;");
  });

  it("should throw error for invalid inputs", () => {
    expect(() => namespaceVariables("", "latin")).toThrow();
    expect(() => namespaceVariables("  ", "latin")).toThrow();
    expect(() => namespaceVariables("--fs-md: 1rem", "")).toThrow();
    expect(() => namespaceVariables("--fs-md: 1rem", "  ")).toThrow();
  });

  it("should preserve comments and empty lines", () => {
    const input = `
      /* Comment */
      
      --fs-md: 1rem;
      /* Another comment */
      --space-lg: 2rem;
    `;

    const result = namespaceVariables(input, "latin");

    expect(result).toContain("/* Comment */");
    expect(result).toContain("/* Another comment */");
    expect(result.split("\n").length).toBe(input.split("\n").length);
  });
});

describe("Core Utility Tests - generateSemanticVariables", () => {
  it("should generate semantic variables with default latin script", () => {
    const result = generateSemanticVariables();

    expect(result).toContain("--fs-7xl: var(--latin-fs-7xl);");
    expect(result).toContain("--space-md: var(--latin-space-md);");
  });

  it("should generate semantic variables with specified script", () => {
    const result = generateSemanticVariables("cjk");

    expect(result).toContain("--fs-7xl: var(--cjk-fs-7xl);");
    expect(result).toContain("--space-md: var(--cjk-space-md);");
  });
});

describe("Integration Tests - generateAndWriteCSS", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    fs.promises.mkdir.mockResolvedValue(undefined);
    fs.promises.writeFile.mockResolvedValue(undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("should generate and write CSS successfully", async () => {
    const consoleLogSpy = vi.spyOn(console, "log").mockImplementation(() => {});

    await generateAndWriteCSS();

    expect(fs.promises.writeFile).toHaveBeenCalled();
    expect(consoleLogSpy).toHaveBeenCalledWith("CSS generation complete.");
  });

  it("should handle file system errors gracefully", async () => {
    const error = new Error("File system error");
    fs.promises.mkdir.mockRejectedValue(error);

    const consoleErrorSpy = vi
      .spyOn(console, "error")
      .mockImplementation(() => {});

    await expect(generateAndWriteCSS()).rejects.toThrow(
      "Failed to write CSS file to /app/assets/css/_typography.css: File system error",
    );
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      "Failed to generate or write CSS:",
      "Failed to write CSS file to /app/assets/css/_typography.css: File system error",
    );
  });

  it("should use custom output path when provided", async () => {
    const customPath = "custom/path/styles.css";

    await generateAndWriteCSS({ outputPath: customPath });

    expect(fs.promises.mkdir).toHaveBeenCalledWith(path.dirname(customPath), {
      recursive: true,
    });
    expect(fs.promises.writeFile).toHaveBeenCalledWith(
      customPath,
      expect.any(String),
    );
  });
});
