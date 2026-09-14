// SVG optimization config. Tuned to be safe for BOTH static favicons and SVGs
// destined to be inlined as Phoenix components:
//   - keep viewBox            (sizing depends on it)
//   - keep <style> as-is      (favicon's prefers-color-scheme media query)
//   - keep ids                (clipPath/gradient refs and animation targets;
//                              inline assets must namespace their own ids)
//   - keep comments           (hand-maintained sources stay documented)
//   - floatPrecision 2        (visually identical, big shrink on Figma exports)
module.exports = {
  multipass: true,
  plugins: [
    {
      name: "preset-default",
      params: {
        overrides: {
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
