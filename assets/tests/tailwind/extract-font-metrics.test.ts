import { describe, it, expect } from 'vitest';
import path from 'path';
import process from 'process';
import fs from 'fs';
import { extractFontMetrics, getFontPathsFromCSS, CSSParsingError } from '../../tailwind/extract-font-metrics';

describe('getFontPathsFromCSS', () => {
    const cssFilePath = path.resolve(__dirname, '../../css/_fontface.css');
    
  
    it('should extract font paths from a valid CSS file', () => {
      const fontPaths = getFontPathsFromCSS(cssFilePath);
  
      expect(Array.isArray(fontPaths)).toBe(true);
      expect(fontPaths.length).toBeGreaterThan(0);
      fontPaths.forEach((fontPath) => {
        expect(typeof fontPath).toBe('string');
        expect(fontPath).toMatch(/\.(woff2?|ttf|otf)$/i);
      });
    });
  
    it('should throw CSSParsingError for missing CSS file', () => {
      const invalidCssPath = path.resolve(__dirname, '../../css/nonexistent.css');
      expect(() => {
        getFontPathsFromCSS(invalidCssPath);
      }).toThrow(CSSParsingError);
    });
  
    it('should return an empty array when no @font-face declarations are found', () => {
      const emptyCssPath = path.resolve(__dirname, '../../css/empty.css');
      
      // Create an empty CSS file for this test
      fs.writeFileSync(emptyCssPath, '');

      try {
        const fontPaths = getFontPathsFromCSS(emptyCssPath);
        expect(Array.isArray(fontPaths)).toBe(true);
        expect(fontPaths.length).toBe(0);
      } finally {
        // Clean up: remove the temporary file
        fs.unlinkSync(emptyCssPath);
      }
    });
  
    it('should extract paths with different formats and multiple URLs', () => {
      const fontPaths = getFontPathsFromCSS(cssFilePath);
      expect(fontPaths).toContain('/fonts/cheee-small.woff2');
      expect(fontPaths).toContain('/fonts/cheee-small.woff');
    });
  
    it('should handle malformed @font-face declarations', () => {
      const malformedCssPath = path.resolve(__dirname, '../../css/malformed-fontface.css');
      
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
        expect(fontPaths).toContain('/fonts/valid.woff2');
      } finally {
        // Clean up: remove the temporary file
        fs.unlinkSync(malformedCssPath);
      }
    });
  
    it('should resolve relative and absolute font paths correctly', () => {
      console.log(`Current working directory: ${process.cwd()}`);
      console.log(`Directory of current file: ${__dirname}`);
      console.log(`Absolute path of this test file: ${path.resolve(__dirname, __filename)}`);
      
      const webRoot = path.resolve(__dirname, '../../static');
      console.log(`Calculated webRoot: ${webRoot}`);
      
      const cssFilePath = path.resolve(__dirname, '../../css/_fontface.css');
      console.log(`CSS file path: ${cssFilePath}`);
  
      const fontPaths = getFontPathsFromCSS(cssFilePath, webRoot);
  
      fontPaths.forEach((absoluteFontPath) => {
        const exists = fs.existsSync(absoluteFontPath);
        console.log(`Checking if file exists: ${absoluteFontPath} -> ${exists}`);
        expect(exists).toBe(true);
      });
    });
  });
  
describe('extractFontMetrics', () => {
  const fontsDirectory = path.resolve(__dirname, '../../fonts');

  it('should successfully extract metrics from a valid font file', () => {
    const fontPath = path.join(fontsDirectory, 'CardinalFruit.ttf'); // Use an actual font file for testing
    const metrics: FontMetrics = extractFontMetrics(fontPath);

    expect(metrics).toHaveProperty('capitalHeight');
    expect(metrics).toHaveProperty('ascender');
    expect(metrics).toHaveProperty('descender');
    expect(metrics).toHaveProperty('xHeight');

    expect(typeof metrics.capitalHeight).toBe('number');
    expect(typeof metrics.ascender).toBe('number');
    expect(typeof metrics.descender).toBe('number');
    expect(typeof metrics.xHeight).toBe('number');

    // Ensure values are within expected ranges (0 to 1)
    expect(metrics.capitalHeight).toBeGreaterThan(0);
    expect(metrics.capitalHeight).toBeLessThanOrEqual(1);
    expect(metrics.ascender).toBeGreaterThan(0);
    expect(metrics.ascender).toBeLessThanOrEqual(1);
    expect(metrics.descender).toBeLessThanOrEqual(0); // Descender usually negative
    expect(metrics.descender).toBeGreaterThanOrEqual(-1);
  });

  it('should handle missing font file gracefully', () => {
    const fontPath = path.join(fontsDirectory, 'NonExistentFont.ttf');

    expect(() => {
      extractFontMetrics(fontPath);
    }).toThrowError(/ENOENT|no such file or directory/i);
  });

  it('should handle unsupported font formats', () => {
    const fontPath = path.join(fontsDirectory, 'invalid.txt'); // A non-font file

    expect(() => {
      extractFontMetrics(fontPath);
    }).toThrowError(/invalid font format/i);
  });

  it('should correctly extract metrics from different font formats', () => {
    const fontFormats = ['.ttf', '.otf', '.woff', '.woff2'];
    fontFormats.forEach((ext) => {
      const fontFileName = `TestFont${ext}`;
      const fontPath = path.join(fontsDirectory, fontFileName);

      // Assuming we have test fonts for each format
      const metrics: FontMetrics = extractFontMetrics(fontPath);

      expect(metrics).toBeDefined();
      expect(metrics.capitalHeight).toBeGreaterThan(0);
      expect(metrics.capitalHeight).toBeLessThanOrEqual(1);
    });
  });

  it('should accurately calculate metrics relative to unitsPerEm', () => {
    const fontPath = path.join(fontsDirectory, 'KnownUnitsPerEm.ttf');
    const metrics: FontMetrics = extractFontMetrics(fontPath);
    // Assuming we know the unitsPerEm and raw capHeight
    const knownUnitsPerEm = 1000;
    const knownCapHeight = 700;
    const expectedCapitalHeight = knownCapHeight / knownUnitsPerEm;

    expect(metrics.capitalHeight).toBeCloseTo(expectedCapitalHeight, 5);
  });

  it('should produce consistent results across multiple runs', () => {
    const fontPath = path.join(fontsDirectory, 'CardinalFruit.ttf');
    const metrics1: FontMetrics = extractFontMetrics(fontPath);
    const metrics2: FontMetrics = extractFontMetrics(fontPath);

    expect(metrics1).toEqual(metrics2);
  });

  it('should handle fonts with unusual metrics', () => {
    const fontPath = path.join(fontsDirectory, 'UnusualMetricsFont.ttf');
    const metrics: FontMetrics = extractFontMetrics(fontPath);

    expect(metrics.capitalHeight).toBeGreaterThanOrEqual(0);
    expect(metrics.capitalHeight).toBeLessThanOrEqual(1);
    expect(metrics.ascender).toBeGreaterThanOrEqual(0);
    expect(metrics.ascender).toBeLessThanOrEqual(1);
    expect(metrics.descender).toBeLessThanOrEqual(0);
    expect(metrics.descender).toBeGreaterThanOrEqual(-1);
  });
});
