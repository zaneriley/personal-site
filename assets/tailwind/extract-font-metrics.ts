import fs from 'fs';
import path from 'path';
import fontkit from 'fontkit';

// Define the FontMetrics interface
export interface FontMetrics {
  unitsPerEm: number;
  capHeight: number;    // Normalized value (0 to 1)
  ascender: number;     // Normalized value (0 to 1)
  descender: number;    // Normalized value (-1 to 0)
  xHeight: number;      // Normalized value (0 to 1)
}

// Export extractFontMetrics function
export function extractFontMetrics(fontPath: string): FontMetrics {
  const absolutePath = path.resolve(fontPath);
  
  if (!fs.existsSync(absolutePath)) {
    throw new Error(`Font file not found: ${absolutePath}`);
  }
  
  const fontBuffer = fs.readFileSync(absolutePath);
  const font = fontkit.create(fontBuffer);
  
  const { unitsPerEm, capHeight, ascender, descender, xHeight } = font;
  
  return {
    unitsPerEm,
    capHeight: capHeight / unitsPerEm,
    ascender: ascender / unitsPerEm,
    descender: descender / unitsPerEm,
    xHeight: xHeight / unitsPerEm,
  };
}

// Custom error class for CSS parsing errors
export class CSSParsingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CSSParsingError';
  }
}

// Export getFontPathsFromCSS function
export function getFontPathsFromCSS(cssFilePath: string, webRoot?: string): string[] {
  console.log(`Processing CSS file: ${cssFilePath}`);
  let cssContent: string;
  const fontPaths: string[] = [];

  try {
    cssContent = fs.readFileSync(cssFilePath, 'utf8');
  } catch (error) {
    if (error instanceof Error) {
      throw new CSSParsingError(`Error reading CSS file: ${error.message}`);
    } else {
      throw new CSSParsingError('Unknown error occurred while reading CSS file');
    }
  }

  // Regular expression to match @font-face blocks
  const fontFaceRegex = /@font-face\s*{[^}]*}/g;
  const fontFaces = cssContent.match(fontFaceRegex);

  console.log(`Number of @font-face blocks found: ${fontFaces ? fontFaces.length : 0}`);

  if (fontFaces) {
    fontFaces.forEach((fontFace, index) => {
      console.log(`Processing @font-face block ${index + 1}:`);
      console.log(fontFace);

      try {
        // Regular expression to match src: url(...) statements
        const srcRegex = /src:\s*([^;]+);/g;
        const srcMatches = srcRegex.exec(fontFace);

        if (srcMatches && srcMatches[1]) {
          const srcValue = srcMatches[1];
          console.log(`Found src value: ${srcValue}`);

          // Regular expression to extract URLs from src
          const urlRegex = /url\(['"]?([^'")]+)['"]?\)/g;
          let urlMatch;
          while ((urlMatch = urlRegex.exec(srcValue)) !== null) {
            const fontPath = urlMatch[1];
            let absoluteFontPath = fontPath.startsWith('/') ? fontPath : path.join(path.dirname(cssFilePath), fontPath);
            
            // If webRoot is provided, transform web-relative paths to file system paths
            if (webRoot && fontPath.startsWith('/')) {
              absoluteFontPath = path.join(webRoot, fontPath);
            }
            
            console.log(`Extracted font path: ${absoluteFontPath}`);
            fontPaths.push(absoluteFontPath);
          }
        } else {
          console.log('No src value found in this @font-face block');
        }
      } catch (error) {
        console.error(`Error processing @font-face block: ${error}`);
        // Continue to the next block
      }
    });
  } else {
    console.log('No @font-face blocks found in the CSS file');
  }

  console.log(`Total font paths extracted: ${fontPaths.length}`);
  console.log('Extracted font paths:', fontPaths);

  return fontPaths;
}

// Typography Calculations Module
function calculateFontSize(options: FontSizeOptions): FontSizeResult;
function calculateLineHeight(fontSize: number, fontMetrics: FontMetrics): number;
export function calculateOpticalCorrections(fontSizePx: number, fontMetrics: FontMetrics): OpticalCorrections {
    const capHeightPx = fontSizePx * fontMetrics.capHeight;
    const ascenderPx = fontSizePx * fontMetrics.ascender;
    const descenderPx = fontSizePx * fontMetrics.descender;
  
    const marginInlineStart = capHeightPx - ascenderPx;
    const marginInlineEnd = descenderPx;
  
    return {
      marginInlineStart,
      marginInlineEnd,
    };
  }
// CSS Generation Module
function generateTypographyStyles(options: TypographyStylesOptions): string;

// Utilities Module (Optional functions)
function convertPxToRem(pxValue: number, baseFontSize?: number): number;
function roundToPrecision(value: number, precision?: number): number;

// Interfaces
interface FontSizeOptions {
desiredCapHeightPx: number;
fontMetrics: FontMetrics;
}
interface FontSizeResult { /* as defined above */ }
interface OpticalCorrections { /* as defined above */ }
interface TypographyStylesOptions { /* as defined above */ }
