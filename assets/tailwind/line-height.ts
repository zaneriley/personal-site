import type { LineHeightConfig } from "./configs/type-config";

/** Baseline distance in px. CJK adds a fixed half-paragraph body; Latin snaps once. */
export function calculateLineHeight(
  config: LineHeightConfig,
  fontSize: number,
  capHeight = config.referenceCapHeight,
): number {
  if (!Number.isFinite(fontSize) || fontSize <= 0)
    throw new Error("Font size must be positive.");
  if (config.script === "cjk") return fontSize + config.paragraphSize / 2;
  const gap =
    config.paragraphLeading - config.referenceCapHeight * config.paragraphSize;
  const unit = config.paragraphLeading / config.subdivision;
  return Math.round((capHeight * fontSize + gap) / unit) * unit;
}

// Evaluate at the text element so em and its face metric follow the actual fluid size.
export const latinLeadingCSS =
  "round(nearest, calc(var(--type-cap, 0.7) * 1em + var(--latin-interline-gap)), var(--latin-leading-unit))";
export const cjkLeadingCSS = "calc(1em + var(--cjk-interline-gap))";
