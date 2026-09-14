import type { Config } from "tailwindcss";
import { latinLeadingCSS } from "./tailwind/line-height";

const config: Config = {
  content: [
    "/app/assets/js/**/*.js",
    "/app/assets/css/**/*.css",
    "!/app/assets/css/_type-tokens.generated.css", // Exclude the generated file
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
            "Cardinal Fruit Fallback",
            "Times New Roman",
            "Garamond",
            "Palatino",
            "system-ui",
            "serif",
          ].join(", "),
          "font-size-adjust": "ex-height from-font",
        },
        ".font-cheee": {
          "font-family": [
            "Cheee",
            "Cheee Fallback",
            "Arial",
            "sans-serif",
          ].join(", "),
          "font-size-adjust": "cap-height from-font",
        },
        ".font-gt-flexa": {
          // Family only. Weight is a separate axis — the document default (350)
          // lives on `body`, and overrides come from the fontWeight tokens
          // (font-body / font-display) so weight is set at the design-system
          // level, never bundled into the family utility.
          "font-family": [
            "GT Flexa",
            "GT Flexa Fallback",
            "Noto Sans JP",
            "Trebuchet MS",
            "Avenir",
            "Fira Sans",
            "-apple-system",
            "system-ui",
            "sans-serif",
          ].join(", "),
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
        ".font-gt-flexa-mono": {
          "font-family": [
            "GT Flexa Mono",
            "ui-monospace",
            "SF Mono",
            "Menlo",
            "monospace",
          ].join(", "),
        },
      };
      addUtilities(newUtilities, ["responsive"]);
    },
  ],
  theme: {
    // Snap once at the actual fluid size, using the selected face's cap metric.
    // Typography's trim consumes the resulting length through lh units.
    // CJK components instead add the fixed half-paragraph-body gap (app.css).
    fontSize: {
      "2xs": ["var(--fs-2xs)", { lineHeight: latinLeadingCSS }],
      "3xs": ["var(--fs-3xs)", { lineHeight: latinLeadingCSS }],
      "1xs": ["var(--fs-1xs)", { lineHeight: latinLeadingCSS }],
      md: ["var(--fs-md)", { lineHeight: latinLeadingCSS }],
      "1xl": ["var(--fs-1xl)", { lineHeight: latinLeadingCSS }],
      "2xl": ["var(--fs-2xl)", { lineHeight: latinLeadingCSS }],
      "3xl": ["var(--fs-3xl)", { lineHeight: latinLeadingCSS }],
      "4xl": ["var(--fs-4xl)", { lineHeight: latinLeadingCSS }],
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
