import type { Config } from "tailwindcss";
import { generateAndWriteCSS } from "./tailwind/generate-type-tokens.ts";

generateAndWriteCSS();

const config: Config = {
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
    ({ addUtilities }) => {
      const newUtilities = {
        ".font-cardinal-fruit": {
          "font-family": [
            "Cardinal Fruit",
            "Times New Roman",
            "Garamond",
            "Palatino",
            "system-ui",
            "serif",
          ].join(", "),
          "font-size-adjust": "ex-height from-font",
        },
        ".font-cheee": {
          "font-family": ["Cheee", "Arial", "sans-serif"].join(", "),
          "font-size-adjust": "cap-height from-font",
        },
        ".font-gt-flexa": {
          "font-family": [
            "GT Flexa",
            "Noto Sans JP",
            "Trebuchet MS",
            "Avenir",
            "Fira Sans",
            "-apple-system",
            "system-ui",
            "sans-serif",
          ].join(", "),
          "font-weight": "350",
        },
        ".font-noto-serif-jp": {
          "font-family": [
            "Noto Serif JP",
            "Source Han Serif",
            "MS Mincho",
            "Hina Mincho",
            "serif",
          ].join(", "),
          transform: "scaleX(0.7)",
          "transform-origin": "left",
          "font-size-adjust": "ic-height from-font",
          "font-weight": "480",
        },
        ".font-noto-sans-jp": {
          "font-family": [
            "Noto Sans JP",
            "Hiragino Kaku Gothic ProN",
            "Meiryo",
            "sans-serif",
          ].join(", "),
          "font-size-adjust": "ic-height from-font",
          "font-weight": "480",
        },
      };
      addUtilities(newUtilities, ["responsive"]);
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

export default config;
