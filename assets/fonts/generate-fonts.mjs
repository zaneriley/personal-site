/**
 * Font pipeline — subsets the licensed source faces in ./src to web woff2 and
 * emits the @font-face CSS. Run on demand: `./run assets:fonts` (fonts change
 * rarely). Re-subsets every face each run — it's sub-second for a handful of
 * faces, so there's no lockfile to go stale; re-running is effectively a no-op.
 *
 * Plain Node ESM (NOT ts-node — the ts-node type-token scripts are broken).
 * Subsetter: subset-font = harfbuzz hb-subset, woff2 out.
 *
 * Variable faces keep their weight axis in full and pin the axes the site never
 * uses. See the axis policy above FACES, and _PROJECT_DOCS/font-trim-spec.md for
 * the measured outcome and the checks that prove nothing moved.
 *
 * The fallback faces below are METRIC-OVERRIDE fallbacks (zero-CLS + stable
 * ch-grid). Their numbers are BROWSER-MEASURED (a-z avg advance + fontBoundingBox
 * ÷ em), NOT extracted from the files: fontkit/capsize misread the variable
 * GT Flexa width (0.21 vs rendered 0.55) and Cardinal's cap-height (0.37 vs
 * 0.75). Re-measure in the browser if a face changes. size-adjust =
 * webfont.width / fallback.width; ascent/descent-override = metric / size-adjust.
 */
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import subsetFont from "subset-font";

const here = path.dirname(fileURLToPath(import.meta.url));
const SRC_DIR = here;
const OUT_DIR = path.join(here, "../static/fonts");
const CSS_OUT = path.join(here, "../css/_fontface.generated.css");

// The charset the site uses: basic latin, latin-1 supplement (© ° accents),
// latin extended-A, general punctuation (en/em dash, curly quotes, ellipsis),
// arrows (↑ for "go to top"), plus € ™ −.
const ranges = [
  [0x20, 0x7e],
  [0xa0, 0xff],
  [0x100, 0x17f],
  [0x2010, 0x2027],
  [0x2030, 0x205e],
  [0x2190, 0x2193],
];
let CHARSET = "€™−…";
for (const [a, b] of ranges) {
  for (let cp = a; cp <= b; cp++) CHARSET += String.fromCodePoint(cp);
}

// This array IS the manifest — co-located with the loop that reads it. A face:
// the source file in ./src, the output basename, the @font-face family/weight,
// and (optionally) a metric-override fallback face generated alongside it.
//
// Axis policy: only pin an axis whose CSS-requested value equals its fvar
// default. Then the pin drops delta data and moves no rendered pixel.
// ital qualifies (`font-style: normal` requests 0 = its default) — pinned.
// wdth does NOT: `font-stretch: normal` requests 100 but GT Flexa defaults to 0,
// so pinning at 0 condenses the site and pinning at 100 re-rounds deltas; both
// changed 28 of 32 surfaces. Left variable. wght stays whole — every
// --fw-flexa-* rung from tailwind/configs/type-config.ts must stay reachable,
// and its minimum IS its default (100), so raising it would move the default
// instance and void the browser-measured fallbacks below (ADR 0004).
// Re-verify any change here with the render-parity check in font-trim-spec.md.
const FACES = [
  {
    src: "src/gt-flexa-gx.ttf",
    out: "gt-flexa",
    family: "GT Flexa",
    weight: "100 900",
    variationAxes: { ital: 0 },
    fallback: {
      family: "GT Flexa Fallback",
      local: ["Arial", "Liberation Sans"],
      sizeAdjust: "112.52%",
      ascent: "71.1%",
      descent: "17.77%",
      lineGap: "0%",
    },
  },
  {
    src: "src/gt-flexa-mono-gx.ttf",
    out: "gt-flexa-mono",
    family: "GT Flexa Mono",
    weight: "100 900",
    variationAxes: { ital: 0 },
  },
  {
    src: "src/cardinal-fruit-regular.ttf",
    out: "cardinal-fruit-regular",
    family: "Cardinal Fruit",
    weight: "400",
    fallback: {
      family: "Cardinal Fruit Fallback",
      local: ["Times New Roman", "Liberation Serif"],
      sizeAdjust: "83.67%",
      ascent: "119.52%",
      descent: "38.01%",
      lineGap: "0%",
    },
  },
  {
    src: "src/cardinal-fruit-bold.ttf",
    out: "cardinal-fruit-bold",
    family: "Cardinal Fruit",
    weight: "700",
  },
  {
    src: "src/cheee-small.woff2",
    out: "cheee-small",
    family: "Cheee",
    weight: "400",
    fallback: {
      family: "Cheee Fallback",
      local: ["Arial", "Liberation Sans"],
      sizeAdjust: "157.96%",
      ascent: "73.69%",
      descent: "15.07%",
      lineGap: "0%",
    },
  },
];

// Quote font-family names only when they contain whitespace (stylelint's
// font-family-name-quotes wants single-word names bare).
const q = (name) => (/\s/.test(name) ? `"${name}"` : name);

const realFace = (f) =>
  `@font-face {\n  font-family: ${q(f.family)};\n  src: url("/fonts/${f.out}.woff2") format("woff2");\n  font-weight: ${f.weight};\n  font-style: normal;\n  font-display: swap;\n}\n`;

const fallbackFace = (fb) =>
  `@font-face {\n  font-family: ${q(fb.family)};\n  src: ${fb.local
    .map((l) => `local("${l}")`)
    .join(
      ", ",
    )};\n  size-adjust: ${fb.sizeAdjust};\n  ascent-override: ${fb.ascent};\n  descent-override: ${fb.descent};\n  line-gap-override: ${fb.lineGap};\n}\n`;

async function main() {
  await mkdir(OUT_DIR, { recursive: true });

  let css =
    "/* ============================================================================\n" +
    "   AUTO-GENERATED by assets/fonts/generate-fonts.mjs — DO NOT EDIT.\n" +
    "   Regenerate: ./run assets:fonts. Real faces + metric-override fallbacks.\n" +
    "============================================================================ */\n\n";

  for (const f of FACES) {
    const input = await readFile(path.join(SRC_DIR, f.src));
    const out = await subsetFont(input, CHARSET, {
      targetFormat: "woff2",
      ...(f.variationAxes && { variationAxes: f.variationAxes }),
    });
    await writeFile(path.join(OUT_DIR, `${f.out}.woff2`), out);
    console.log(
      `  ${f.out}.woff2  ${Math.round(out.length / 1024)}KB  (from ${Math.round(input.length / 1024)}KB)`,
    );
    css += realFace(f);
    css += "\n";
  }

  css +=
    "/* Metric-override fallbacks — browser-measured (fontkit misreads variable/\n" +
    "   display widths); see this script's header. Listed after the real face in\n" +
    "   each stack (body in app.css, .font-* in tailwind.config.ts). */\n\n";
  for (const f of FACES) {
    if (f.fallback) css += `${fallbackFace(f.fallback)}\n`;
  }

  await writeFile(CSS_OUT, `${css.trimEnd()}\n`);
  console.log(`wrote ${path.relative(path.join(here, ".."), CSS_OUT)}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
