import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import path from "node:path";

// Mock fs module BEFORE importing the module under test
vi.mock("node:fs", () => ({
  default: {
    writeFileSync: vi.fn(),
    readFileSync: vi.fn(),
  },
  writeFileSync: vi.fn(),
  readFileSync: vi.fn(),
}));

import fs from "node:fs";
import * as generateTypeTokensModule from "../../tailwind/generate-type-tokens";

const {
  generateCSS,
  generateAndWriteCSS,
  namespaceVariables,
  generateSemanticVariables,
  writeCSS,
  CSSGenerationError,
  CSSWriteError
} = generateTypeTokensModule;

describe("Critical Functional Tests - generateCSS", () => {
  it("should generate complete CSS structure with all sections", () => {
    const css = generateCSS();
    
    // Verify all required sections are present
    expect(css).toContain("/* Latin Typography Variables */");
    expect(css).toContain("/* Latin Spacing Variables */");
    expect(css).toContain("/* CJK Typography Variables */");
    expect(css).toContain("/* CJK Spacing Variables */");
    expect(css).toContain("/* Font Metrics */");
    expect(css).toContain("/* Semantic Variables (Default to Latin) */");
    
    // Verify root and CJK override blocks
    expect(css).toContain(":root {");
    expect(css).toContain("html[lang=\"ja\"] {");
  });

  it("should integrate font metrics correctly", () => {
    const css = generateCSS();
    
    // Check for font metric variables
    expect(css).toContain("--cheee-small-units-per-em:");
    expect(css).toContain("--noto-sans-jp-cap-height:");
    expect(css).toContain("--GT-Flexa-Trial-VF-ascent:");
  });

  it("should include semantic variable references", () => {
    const css = generateCSS();
    
    // Verify semantic variables reference namespaced variables
    expect(css).toContain("--fs-7xl: var(--latin-fs-7xl);");
    expect(css).toContain("--space-md: var(--latin-space-md);");
    
    // Verify CJK overrides
    expect(css).toContain("--fs-7xl: var(--cjk-fs-7xl);");
  });
});

describe("Critical Functional Tests - writeCSS", () => {
  const mockCSS = "/* Test CSS */";
  const expectedPath = path.resolve("css/_typography.css");
  
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should write CSS to the correct file", () => {
    generateAndWriteCSS();
    
    expect(fs.writeFileSync).toHaveBeenCalledWith(
      expectedPath,
      expect.any(String)
    );
  });

  it("should write the exact content provided", () => {
    generateAndWriteCSS();
    
    expect(fs.writeFileSync).toHaveBeenCalledWith(
      expectedPath,
      expect.stringContaining("/* Latin Typography Variables */")
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
    // Ensure NODE_ENV is set to 'test'
    process.env.NODE_ENV = 'test';
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("should generate and write CSS successfully", () => {
    const mockGenerateCSS = vi.spyOn(generateTypeTokensModule, 'generateCSS')
      .mockReturnValue("/* Mock CSS */");
    const mockWriteCSS = vi.spyOn(generateTypeTokensModule, 'writeCSS')
      .mockImplementation(() => {});
    const consoleLogSpy = vi.spyOn(console, "log")
      .mockImplementation(() => {});

    generateAndWriteCSS();

    expect(mockGenerateCSS).toHaveBeenCalled();
    expect(mockWriteCSS).toHaveBeenCalledWith("/* Mock CSS */");
    expect(consoleLogSpy).toHaveBeenCalledWith("CSS generation complete.");

    mockGenerateCSS.mockRestore();
    mockWriteCSS.mockRestore();
    consoleLogSpy.mockRestore();
  });

  it("should handle errors during CSS generation gracefully", () => {
    const error = new CSSGenerationError("Generation failed");
    vi.spyOn(generateTypeTokensModule, 'generateCSS').mockImplementation(() => {
      throw error;
    });
    const consoleErrorSpy = vi.spyOn(console, "error")
      .mockImplementation(() => {});

    expect(() => generateAndWriteCSS()).toThrow(CSSGenerationError);
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      "An error occurred during CSS generation:",
      error
    );
  });

  it("should handle errors during CSS writing gracefully", () => {
    const error = new CSSWriteError("Write failed");
    vi.spyOn(generateTypeTokensModule, 'generateCSS')
      .mockReturnValue("/* Mock CSS */");
    vi.spyOn(generateTypeTokensModule, 'writeCSS').mockImplementation(() => {
      throw error;
    });
    const consoleErrorSpy = vi.spyOn(console, "error")
      .mockImplementation(() => {});

    expect(() => generateAndWriteCSS()).toThrow(CSSWriteError);
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      "An error occurred while writing CSS:",
      error
    );
  });
});
