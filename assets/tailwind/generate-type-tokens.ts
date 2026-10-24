import fs from "node:fs";
import path from "node:path";
import type { WeightConfig } from "./configs/type-config";
import {
  cjkTypeConfig,
  flexaWeightConfig,
  latinTypeConfig,
  spacingMultipliers,
} from "./configs/type-config";

import { generateTypeCSSVariables } from "./font-size";

const debugLog = (...args: unknown[]): void => {
  if (process.env.TYPE_SCALE_DEBUG === "1") {
    console.log(...args);
  }
};

// Constants
const DEFAULT_OUTPUT_PATH = path.resolve("css/_type-tokens.generated.css");
const SUPPORTED_SCRIPTS = ["latin", "cjk"] as const;
type ScriptType = (typeof SUPPORTED_SCRIPTS)[number];

interface ScriptConfig {
  type: typeof latinTypeConfig;
}

const scriptConfigs: Record<ScriptType, ScriptConfig> = {
  latin: { type: latinTypeConfig },
  cjk: { type: cjkTypeConfig },
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

  const base =
    script === "latin"
      ? config.type.lineHeightConfig.paragraphLeading
      : config.type.lineHeightConfig.paragraphSize;
  const spaceVars = Object.entries(spacingMultipliers)
    .map(
      ([label, multiplier]) =>
        `  --${script}-space-${label}: calc(${base / 16}rem * ${multiplier});`,
    )
    .join("\n");

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
  } = config;

  const typeVars = typeLabels
    .map((label) => `  --fs-${label}: var(--${script}-fs-${label});`)
    .join("\n");

  const spaceVars = Object.keys(spacingMultipliers)
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

      return `  --${font}-cap: ${metrics.capHeight};
  --${font}-trim-start: ${(metrics.capHeight + (Math.abs(metrics.descent) - metrics.ascent) / 2).toFixed(4)};
  --${font}-trim-end: ${((metrics.ascent - Math.abs(metrics.descent)) / 2).toFixed(4)};
  --${font}-distance-top: ${capAscentDiff};
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
  const config = latinTypeConfig.lineHeightConfig;
  return [
    `  --latin-interline-gap: ${((config.paragraphLeading - config.referenceCapHeight * config.paragraphSize) / 16).toFixed(4)}rem;`,
    `  --latin-leading-unit: ${config.paragraphLeading / config.subdivision / 16}rem;`,
    `  --cjk-interline-gap: ${cjkTypeConfig.lineHeightConfig.paragraphSize / 2 / 16}rem;`,
    ...latinTypeConfig.typeLabels.map(
      (label) =>
        `  --lh-en-${label}: round(nearest, calc(${config.referenceCapHeight} * var(--latin-fs-${label}) + var(--latin-interline-gap)), var(--latin-leading-unit));`,
    ),
  ].join("\n");
}

/**
 * Generates the GT Flexa optical weight rungs from the calibration knobs.
 * GT Flexa has no opsz axis, so weight is compensated per size step on the wght
 * axis: regular(step) = base − opszSlope·step, and bold lifts off its own
 * regular rung by (boldDelta − boldSlope·step). `step` is each label's distance
 * from the anchor. Emits literal `--fw-flexa-{size}[-bold]` values, same shape
 * as the size/line-height tokens — the relationship lives in the config + here.
 * @param config - The GT Flexa weight configuration
 * @returns Generated weight CSS variables
 */
export function generateFlexaWeightCSS(config: WeightConfig): string {
  const anchorIndex = config.labels.indexOf(config.anchorLabel);
  const step = (label: string) => anchorIndex - config.labels.indexOf(label);
  const regular = (label: string) =>
    config.base - config.opszSlope * step(label);
  const bold = (label: string) =>
    regular(label) + config.boldDelta - config.boldSlope * step(label);

  const regularVars = config.labels
    .map((label) => `  --fw-flexa-${label}: ${regular(label)};`)
    .join("\n");
  const boldVars = config.labels
    .map((label) => `  --fw-flexa-${label}-bold: ${bold(label)};`)
    .join("\n");

  return `${regularVars}\n${boldVars}`;
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
  // Calibrated browser metrics: GT Flexa A/D = .8/.2; Cardinal = 1/.318.
  // The fontkit extractor misreads these faces (ADR 0004). This input must not
  // be blindly replaced with source-table metrics or fallback-face descriptors.
  const actualFontMetrics = require("./font-metrics.json") as FontMetricsData;
  const fontMetricsVars = generateFontMetricsCSS(actualFontMetrics); // Pass loaded data
  const flexaWeightVars = generateFlexaWeightCSS(flexaWeightConfig);

  return `/*
* DO NOT EDIT THIS FILE DIRECTLY.
* Your changes will be overwritten. This file is auto-generated.
* Regenerate with: ./run yarn:generate:typography
*/
  
:root {
  /* Latin Typography Variables */
${latinVars.typeVars}

  /* Latin Spacing Variables */
${latinVars.spaceVars}

  /* CJK Typography Variables */
${cjkVars.typeVars}
  --cjk-lh: calc(1em + var(--cjk-interline-gap));

  /* CJK Spacing Variables */
${cjkVars.spaceVars}

  /* Latin Line Heights (Snapped) */
${latinLineHeightVars}

  /* Font Metrics */
  ${fontMetricsVars}

  /* GT Flexa Optical Weight (derived from flexaWeightConfig) */
${flexaWeightVars}

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
    debugLog(`CSS variables generated successfully at ${outputPath}`);
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
  // generateCSS handles loading metrics now
  const css = generateCSS();
  // Pass the generated CSS to writeCSS
  writeCSS(css, options.outputPath);
  debugLog("CSS generation complete.");
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
