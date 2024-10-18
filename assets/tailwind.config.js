import { generateScales } from "./tailwind/generate-type-tokens.js";

const { typeSizes } = generateScales();

module.exports = {
  content: [
    "/app/assets/js/**/*.js",
    "/app/assets/css/**/*.css",
    "!/app/assets/css/_typography.css", // Exclude the generated file
    "/app/lib/portfolio_web/**/*.*ex",
  ],
  corePlugins: {},
  plugins: [
    ({ addVariant }) => {
      addVariant("phx-page-loading", [
        ".phx-page-loading&",
        ".phx-page-loading &",
      ]);
    },
  ],
  theme: {
    fontSize: {
      "2xs": ["var(--fs-2xs)", { lineHeight: "1.2" }],
      "1xs": ["var(--fs-1xs)", { lineHeight: "1.2" }],
      md: ["var(--fs-md)", { lineHeight: "1.5" }],
      "1xl": ["var(--fs-1xl)", { lineHeight: "1.3" }],
      "2xl": ["var(--fs-2xl)", { lineHeight: "1" }],
      "3xl": ["var(--fs-3xl)", { lineHeight: "1" }],
      "4xl": ["var(--fs-4xl)", { lineHeight: "1" }],
    },
    spacing: {
      "3xs": "var(--space-3xs)",
      "2xs": "var(--space-2xs)",
      "1xs": "var(--space-1xs)",
      md: "var(--space-md)",
      "1xl": "var(--space-1xl)",
      "2xl": "var(--space-2xl)",
      "3xl": "var(--space-3xl)",
      "4xl": "var(--space-4xl)",
    },
    textColor: {
      main: "var(--text-color-main)",
      callout: "var(--text-color-callout)",
      deemphasized: "var(--text-color-deemphasized)",
      suppressed: "var(--text-color-suppressed)",
      accent: "var(--text-color-accent)",
    },
    extend: {
      fontFamily: {
        "cardinal-fruit": [
          "Cardinal Fruit",
          "Times New Roman",
          "Garamond",
          "Palatino",
          "serif",
        ],
        cheee: ["Cheee", "Arial", "sans-serif"],
        "gt-flexa": [
          "GT Flexa",
          "Trebuchet MS",
          "Avenir",
          "Fira Sans",
          "-apple-system",
          "system-ui",
          "sans-serif",
        ],
        "noto-sans-jp": [
          "Noto Sans JP",
          "Hiragino Kaku Gothic ProN",
          "Meiryo",
          "sans-serif",
        ],
      },
      // Add transition properties for the page fade effect
      transitionProperty: {
        opacity: "opacity",
      },
      transitionDuration: {
        500: "500ms",
      },
      transitionTimingFunction: {
        ease: "ease",
      },
      opacity: {
        0: "0",
      },
    },
  },
};
