import type { Config } from "tailwindcss";

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
          "font-family": ["Cheee", "Cheee Fallback", "Arial", "sans-serif"].join(
            ", ",
          ),
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
      };
      addUtilities(newUtilities, ["responsive"]);
    },
  ],
  theme: {
    // Line-height comes from the generated baseline-grid values (--lh-en-*, see
    // generate-type-tokens.ts / line-height.ts) — one leading relationship, snapped
    // to the 7px grid — NOT flat per-size ratios. The optical-adjustment margins
    // read the same --lh-en-*, so rendered leading and the trim math agree.
    // CJK overrides line-height via html[lang="ja"] * (app.css).
    fontSize: {
      "2xs": ["var(--fs-2xs)", { lineHeight: "var(--lh-en-2xs)" }],
      "1xs": ["var(--fs-1xs)", { lineHeight: "var(--lh-en-1xs)" }],
      md: ["var(--fs-md)", { lineHeight: "var(--lh-en-md)" }],
      "1xl": ["var(--fs-1xl)", { lineHeight: "var(--lh-en-1xl)" }],
      "2xl": ["var(--fs-2xl)", { lineHeight: "var(--lh-en-2xl)" }],
      "3xl": ["var(--fs-3xl)", { lineHeight: "var(--lh-en-3xl)" }],
      "4xl": ["var(--fs-4xl)", { lineHeight: "var(--lh-en-4xl)" }],
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
      // The hero's "one rung down from main" tier. Per-theme (see _color.css),
      // replacing the raw --dusk-100 rung that was :root-only and so stayed a
      // pale pink in light mode.
      soft: "var(--text-color-soft)",
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
