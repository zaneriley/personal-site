import fs from "node:fs";
import path from "node:path";
import * as fontkit from "fontkit";
import type { Font, FontCollection } from "fontkit";

export interface FontMetrics {
  unitsPerEm: number;
  capHeight: number; // Normalized value (0 to 1)
  ascent: number; // Normalized value (0 to 1)
  descent: number; // Normalized value (-1 to 0)
  xHeight: number; // Normalized value (0 to 1)
}

export class CSSParsingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CSSParsingError";
  }
}

export function getFontPathsFromCSS(
  cssFilePath: string,
  webRoot?: string,
): string[] {
  console.log(`Processing CSS file: ${cssFilePath}`);
  let cssContent: string;
  const fontPaths: string[] = [];

  try {
    cssContent = fs.readFileSync(cssFilePath, "utf8");
  } catch (error) {
    if (error instanceof Error) {
      throw new CSSParsingError(`Error reading CSS file: ${error.message}`);
    }
    throw new CSSParsingError("Unknown error occurred while reading CSS file");
  }

  // Regular expression to match @font-face blocks
  const fontFaceRegex = /@font-face\s*{[^}]*}/g;
  const fontFaces = cssContent.match(fontFaceRegex);

  console.log(
    `Number of @font-face blocks found: ${fontFaces ? fontFaces.length : 0}`,
  );

  if (fontFaces) {
    fontFaces.forEach((fontFace, index) => {
      console.log(`Processing @font-face block ${index + 1}:`);
      console.log(fontFace);

      try {
        // Regular expression to match src: url(...) statements
        const srcRegex = /src:\s*([^;]+);/g;
        const srcMatches = srcRegex.exec(fontFace);

        if (srcMatches?.[1]) {
          const srcValue = srcMatches[1];
          console.log(`Found src value: ${srcValue}`);

          // Regular expression to extract URLs from src
          const urlRegex = /url\(['"]?([^'")]+)['"]?\)/g;
          let urlMatch = urlRegex.exec(srcValue);
          while (urlMatch !== null) {
            const fontPath = urlMatch[1];
            let absoluteFontPath = fontPath.startsWith("/")
              ? fontPath
              : path.join(path.dirname(cssFilePath), fontPath);

            // If webRoot is provided, transform web-relative paths to file system paths
            if (webRoot && fontPath.startsWith("/")) {
              absoluteFontPath = path.resolve(webRoot, `.${fontPath}`);
            }

            console.log(`Extracted font path: ${absoluteFontPath}`);
            fontPaths.push(absoluteFontPath);

            // Update urlMatch for the next iteration
            urlMatch = urlRegex.exec(srcValue);
          }
        } else {
          console.log("No src value found in this @font-face block");
        }
      } catch (error) {
        console.error(`Error processing @font-face block: ${error}`);
        // Continue to the next block
      }
    });
  } else {
    console.log("No @font-face blocks found in the CSS file");
  }

  console.log(`Total font paths extracted: ${fontPaths.length}`);
  console.log("Extracted font paths:", fontPaths);

  return fontPaths;
}

function isFontCollection(font: Font | FontCollection): font is FontCollection {
  return "fonts" in font;
}

export function extractFontMetrics(fontPath: string): FontMetrics {
  const absolutePath = path.resolve(fontPath);

  let fontResult: Font | FontCollection;
  try {
    fontResult = fontkit.openSync(absolutePath);
  } catch (error) {
    console.error(`Error opening font file: ${absolutePath}`, error);
    throw error; // Rethrow the original file system error
  }

  if (isFontCollection(fontResult)) {
    // Handle FontCollection
    throw new Error("FontCollections are not supported");
  }

  const font: Font = fontResult;

  const { unitsPerEm, capHeight, ascent, descent, xHeight } = font;

  // Log Raw Metrics
  console.log(`Raw Metrics for ${absolutePath}:`, {
    unitsPerEm,
    capHeight,
    ascent,
    descent,
    xHeight,
  });

  if (
    unitsPerEm === undefined ||
    unitsPerEm === 0 ||
    capHeight === undefined ||
    ascent === undefined ||
    descent === undefined ||
    xHeight === undefined
  ) {
    console.error(
      `One or more required font metrics are missing or invalid in: ${absolutePath}`,
    );
    throw new Error(`Invalid font metrics in: ${absolutePath}`);
  }

  // Normalize Metrics
  const normalizedCapHeight = capHeight / unitsPerEm;
  const normalizedAscent = ascent / unitsPerEm;
  const normalizedDescent = descent / unitsPerEm;
  const normalizedXHeight = xHeight / unitsPerEm;

  // **Log Normalized Metrics**
  console.log("Normalized Metrics:");
  console.log(`capHeight: ${normalizedCapHeight}`);
  console.log(`ascent: ${normalizedAscent}`);
  console.log(`descent: ${normalizedDescent}`);
  console.log(`xHeight: ${normalizedXHeight}`);

  // Check for NaN Values
  if (
    Number.isNaN(normalizedCapHeight) ||
    Number.isNaN(normalizedAscent) ||
    Number.isNaN(normalizedDescent) ||
    Number.isNaN(normalizedXHeight)
  ) {
    console.error(
      `Normalization resulted in NaN values for font: ${absolutePath}`,
    );
    throw new Error(`Invalid normalization for font: ${absolutePath}`);
  }

  return {
    unitsPerEm,
    capHeight: normalizedCapHeight,
    ascent: normalizedAscent,
    descent: normalizedDescent,
    xHeight: normalizedXHeight,
  };
}

export function generateFontMetricsJSON(
  cssFilePath: string,
  outputJsonPath: string,
  webRoot?: string,
) {
  try {
    const fontPaths = getFontPathsFromCSS(cssFilePath, webRoot);
    const fontMetrics: { [key: string]: FontMetrics } = {};

    for (const fontPath of fontPaths) {
      const fontName = path.basename(fontPath, path.extname(fontPath));
      try {
        const metrics = extractFontMetrics(fontPath);
        fontMetrics[fontName] = metrics;
      } catch (error) {
        console.error(`Failed to extract metrics for font: ${fontPath}`, error);
      }
    }

    fs.writeFileSync(
      outputJsonPath,
      JSON.stringify(fontMetrics, null, 2),
      "utf8",
    );
    console.log(`Successfully wrote font metrics to ${outputJsonPath}`);
  } catch (error) {
    console.error("Error generating font metrics JSON:", error);
    throw error;
  }
}

// **Execute the Script**
if (require.main === module) {
  const cssFilePath = path.join(__dirname, "../css/_fontface.css"); // Update with actual CSS path
  const outputJsonPath = path.join(__dirname, "font-metrics.json");
  const webRoot = path.join(__dirname, "../static"); // Updated based on your project structure

  generateFontMetricsJSON(cssFilePath, outputJsonPath, webRoot);
}
