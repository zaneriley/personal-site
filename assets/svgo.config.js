// SVG optimization config. Tuned to be safe for BOTH static favicons and SVGs
// destined to be inlined as Phoenix components:
//   - keep viewBox            (sizing depends on it)
//   - keep <style> as-is      (favicon's prefers-color-scheme media query)
//   - keep ids                (clipPath/gradient refs; avoids id collisions
//                              when several inline SVGs share one page)
//   - keep comments           (hand-maintained sources stay documented)
//   - floatPrecision 2        (visually identical, big shrink on Figma exports)
module.exports = {
  multipass: true,
  plugins: [
    {
      name: "preset-default",
      params: {
        overrides: {
          removeViewBox: false,
          cleanupIds: false,
          inlineStyles: false,
          removeComments: false,
          convertPathData: { floatPrecision: 2 },
          cleanupNumericValues: { floatPrecision: 2 },
        },
      },
    },
  ],
};
