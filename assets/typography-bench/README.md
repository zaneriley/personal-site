# Typography bench

Open `/typography-bench` on the development server. These routes are compiled
only when `:portfolio, :typography_bench` is enabled (dev/test configuration).
The shell's CSS never enters the specimen iframe. Specimens render the actual
Phoenix Typography component or weather component; they do not duplicate it.

The default view is a mobile kitchen sink: sticky face/weight/language/theme
controls update the selected composition and all supported sizes immediately.
Size, sample, viewport and deliberate faults live in a disclosure beside the
selected composition. Matrix execution uses a separate hidden iframe, so a
run cannot replace the specimen being inspected. Request IDs discard stale
responses during rapid changes. Orange outlines identify components; blue
guides identify each baseline or ideographic body bottom. Neither traces glyph ink.

The manifest joins the component's supported roles/sizes with generated size
tokens, stored metrics, font-face CSS, and file hashes. The matrix covers all
font roles × selected sizes × regular/bold roles × locales × sample strings at
one chosen width/theme/browser. Unsupported component sizes and unverified
fonts remain findings. Continuous sizes, all font pairs, all browsers, and
all strings are not claimed covered.

`?view=stress` pairs seven identical specimens under Latin and CJK rhythm,
including mixed scripts, forced line breaks, accents, punctuation and wrapping.
`?view=article` shows a mixed-size reading composition with translated EN/JA
sample copy and shared spacing tokens. Neither view uses publication drafts.
Font-role selection follows the production locale mapping; the CSS family and
fallback warnings remain visible. Export includes all stress specimens.

## Run

```sh
./run _dc js node typography-bench/audit-fonts.mjs
./run dev:test:elixir test/portfolio_web/controllers/typography_bench_controller_test.exs
docker run --rm --network portfolio_default -v "$PWD:/work" \
  personal-site-prod-build-browser node /work/ci/gates/typography-bench.mjs
```

The browser image is the existing release-test image. `BENCH_URL` defaults to
`http://web:8000`; `BENCH_OUTPUT` defaults to `/work/.tmp/typography-bench`.
Set `BENCH_SCOPE=all` to include every generated size. The browser runner
verifies deliberate margin/wrong-font faults, outline invariance, and isolated
frame parity, and writes JSON evidence plus a screenshot. It also inspects the
actual font used by a control run through Chromium's font-inspection API.
It tests rapid face/language changes, 320/390px mobile layout, and automatic
size/text repainting. `raster.json` records screenshot-derived ink insets for
English capitals at the three smallest sizes across five roles (Chromium,
DPR 1, regular, 390px). A 24-channel-value threshold separates ink from the
solid background; these are sample-specific measurements, not optical targets.

`audit-fonts.mjs` only reads licensed source/generated binaries. It records
default-instance metadata, coverage probes, and hashes under `.tmp/`; it does
not regenerate fonts. Rerun after changing fonts and compare current manifest
hashes with audit hashes before using an older audit. File extraction is not
treated as ground truth for variable-font/browser behavior.

## Interpretation

DOM rectangles, content range rectangles, and canvas single-run ink estimates
are separately labeled. Canvas does not model DOM wrapping, nested optical
wrappers, CSS size adjustment, or transformed numerals. A settled FontFaceSet
does not prove actual per-glyph face selection. The interactive report keeps
that identity unverified even when a declared face loaded successfully.

There is no automatic optical pass or baseline approval. The current bench
does not yet perform source-versus-output raster parity, general DOM raster ink
segmentation for arbitrary compositions, pairwise font composition generation,
or cross-browser sweeps. Resolved leading and reference-box height are checked;
a mismatch is flagged rather than automatically corrected.
These are explicit coverage gaps, not passing checks.
