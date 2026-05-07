import fs from "node:fs";
import path from "node:path";
import {
  cjkSpaceConfig,
  cjkTypeConfig,
  latinSpaceConfig,
  latinTypeConfig,
} from "./configs/type-config";

import {
  assignLabels,
  calculateTypeScale,
  generateSpaceCSSVariables,
  generateTypeCSSVariables,
} from "./font-size";
import { calculateLineHeight } from "./line-height";

// Constants
const DEFAULT_OUTPUT_PATH = path.resolve("css/_typography.css");
const SUPPORTED_SCRIPTS = ["latin", "cjk"] as const;
type ScriptType = (typeof SUPPORTED_SCRIPTS)[number];

interface ScriptConfig {
  type: typeof latinTypeConfig;
  space: typeof latinSpaceConfig;
}

const scriptConfigs: Record<ScriptType, ScriptConfig> = {
  latin: { type: latinTypeConfig, space: latinSpaceConfig },
  cjk: { type: cjkTypeConfig, space: cjkSpaceConfig },
};

// Define FontMetrics type based on font-metrics.json structure
interface FontMetricsData {
  [fontName: string]: {
    unitsPerEm: number;
    capHeight: number;
    ascent: number;
    descent: number;
    xHeight: number;
  };
}

interface GenerateOptions {
  outputPath?: string;
}

/**
 * Namespaces CSS variables with a given prefix
 * @param variables - CSS variable definitions
 * @param namespace - Namespace prefix to add
 * @returns Namespaced CSS variables
 * @throws {Error} If variables or namespace are invalid
 */
export function namespaceVariables(
  variables: string,
  namespace: string,
): string {
  if (!variables?.trim() || !namespace?.trim()) {
    throw new Error("Variables and namespace must be non-empty strings");
  }

  return variables
    .split("\n")
    .map((line) => {
      const trimmedLine = line.trim();
      if (trimmedLine.startsWith("/*") || trimmedLine === "") return line;
      return line.replace(/--(fs|space)-/g, `--${namespace}-$1-`);
    })
    .join("\n");
}

/**
 * Generates CSS variables for a specific script configuration
 * @param script - Script type ('latin' or 'cjk')
 * @returns Generated CSS variables
 */
function generateScriptVariables(script: ScriptType) {
  const config = scriptConfigs[script];

  const typeVars = namespaceVariables(
    generateTypeCSSVariables(config.type),
    script,
  );

  const spaceVars = namespaceVariables(
    generateSpaceCSSVariables(config.space),
    script,
  );

  return { typeVars, spaceVars };
}

/**
 * Generates semantic variable mappings for a script
 * @param script - Script type to generate variables for
 * @returns Generated semantic variables
 */
export function generateSemanticVariables(
  script: ScriptType = "latin",
): string {
  const config = scriptConfigs[script];
  const {
    type: { typeLabels },
    space: { spaceLabels },
  } = config;

  const typeVars = typeLabels
    .map((label) => `  --fs-${label}: var(--${script}-fs-${label});`)
    .join("\n");

  const spaceVars = spaceLabels
    .map((label) => `  --space-${label}: var(--${script}-space-${label});`)
    .join("\n");

  return `${typeVars}\n\n${spaceVars}`;
}

/**
 * Generates CSS for font metrics
 * @param metricsData - The font metrics data object
 * @returns Generated font metrics CSS
 */
function generateFontMetricsCSS(metricsData: FontMetricsData): string {
  // Type assertion needed with require()
  // const metricsData = fontMetrics as FontMetricsData;

  const metrics = Object.entries(metricsData) // Use provided metricsData
    .map(([font, metrics]) => {
      // metrics implicitly has type from FontMetricsData here
      // Round values to 4 decimal places to meet linter requirements
      const capAscentDiff = (metrics.ascent - metrics.capHeight).toFixed(4);
      const descentAbs = Math.abs(metrics.descent).toFixed(4);

      return `  --${font}-distance-top: ${capAscentDiff};
  --${font}-distance-bottom: ${descentAbs};`; // Fix: Use distance-bottom
    })
    .join("\n");

  return metrics.trim();
}

/**
 * Generates CSS variables for snapped Latin line heights
 * @returns Generated line height CSS variables
 */
function generateLatinLineHeightCSS(): string {
  const typeScale = calculateTypeScale(latinTypeConfig);
  const labeledSizes = assignLabels(
    typeScale.map((tsResult) => ({
      step: tsResult.step,
      minFontSize: tsResult.minFontSize, // Keep minFontSize for calculation
      label: "", // Placeholder label, will be assigned by assignLabels
    })),
    latinTypeConfig.typeLabels,
  );

  const lineHeightVars = labeledSizes
    .map((size) => {
      // Find the original TypeStepResult to get minFontSize accurately
      const originalStep = typeScale.find((s) => s.step === size.step);
      if (!originalStep) return ""; // Should not happen

      const snappedLineHeight = calculateLineHeight(
        latinTypeConfig.lineHeightConfig,
        originalStep.minFontSize, // Use minFontSize (pixels)
      );
      // Use the label assigned by assignLabels
      return `  --lh-en-${size.label}: ${snappedLineHeight.toFixed(10)};`;
    })
    .filter(Boolean) // Remove empty strings if any step wasn't found
    .join("\n");

  return lineHeightVars;
}

/**
 * Generates the complete CSS content
 * @returns Generated CSS content
 */
export function generateCSS(): string {
  const latinVars = generateScriptVariables("latin");
  const cjkVars = generateScriptVariables("cjk");
  const latinLineHeightVars = generateLatinLineHeightCSS();

  const semanticVars = generateSemanticVariables("latin");
  const semanticCJKVars = generateSemanticVariables("cjk");
  // Load metrics here and pass to the function
  const actualFontMetrics = require("./font-metrics.json") as FontMetricsData;
  const fontMetricsVars = generateFontMetricsCSS(actualFontMetrics); // Pass loaded data

  return `/* 
* DO NOT EDIT THIS FILE DIRECTLY. 
* Your changes will be overwritten. This file is auto-generated. 
* Generated on: ${new Date().toISOString()}
*/
  
:root {
  /* Latin Typography Variables */
${latinVars.typeVars}

  /* Latin Spacing Variables */
${latinVars.spaceVars}

  /* CJK Typography Variables */
${cjkVars.typeVars}
  --cjk-lh: calc(1em + 1rem);

  /* CJK Spacing Variables */
${cjkVars.spaceVars}

  /* Latin Line Heights (Snapped) */
${latinLineHeightVars}

  /* Font Metrics */
  ${fontMetricsVars}

  /* Semantic Variables (Default to Latin) */
${semanticVars}
}

/* CJK Overrides */
html[lang="ja"] {
  /* Semantic Variables (CJK) */
${semanticCJKVars}
}

`.trim();
}

/**
 * Writes CSS content to a file
 * @param css - CSS content to write
 * @param outputPath - Path to write the CSS file
 */
export function writeCSS(
  css: string,
  outputPath: string = DEFAULT_OUTPUT_PATH,
): void {
  try {
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, css);
    console.log(`CSS variables generated successfully at ${outputPath}`);
  } catch (error) {
    throw new Error(
      `Failed to write CSS file to ${outputPath}: ${error instanceof Error ? error.message : "Unknown error"}`,
    );
  }
}

/**
 * Generates and writes CSS content to a file
 * @param options - Generation options
 */
export function generateAndWriteCSS(options: GenerateOptions = {}): void {
  try {
    // generateCSS handles loading metrics now
    const css = generateCSS();
    // Pass the generated CSS to writeCSS
    writeCSS(css, options.outputPath);
    console.log("CSS generation complete.");
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    console.error("Failed to generate or write CSS:", message);
    throw error;
  }
}

// Main execution
if (require.main === module) {
  try {
    generateAndWriteCSS();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

// Add the generateScales function
export function generateScales() {
  const latinTypeVars = generateTypeCSSVariables(latinTypeConfig);
  const latinSpaceVars = generateSpaceCSSVariables(latinSpaceConfig);
  const cjkTypeVars = generateTypeCSSVariables(cjkTypeConfig);
  const cjkSpaceVars = generateSpaceCSSVariables(cjkSpaceConfig);

  // Combine the strings instead of spreading
  return {
    typeSizes: `${latinTypeVars}\n${cjkTypeVars}`,
    spaceSizes: `${latinSpaceVars}\n${cjkSpaceVars}`,
  };
}
