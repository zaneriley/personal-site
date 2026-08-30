# ADR 0004 — Self-hosted font subsetting and delivery pipeline

**Status:** accepted 2026-06-04; implemented in commits 5001ca5 (H1 metric-override fallbacks), 8a136e8 (self-host the real faces), 9984df6 (the generator), 23f1bb9 (critical-face preload). Deferred consequence #1 (axis trim) executed 2026-08-29 in 90d09b3 — italic axis pinned; the width axis measurably cannot be pinned safely (its CSS-requested value differs from its fvar default; evidence in `_PROJECT_DOCS/page-weight.md`).
**Supersedes:** none.
**Superseded by:** none.

This ADR records the shape of the self-hosted webfont pipeline — how licensed source faces become served woff2 + `@font-face` CSS, how the zero-CLS fallback faces are produced, and how the critical face is delivered. It was shaped by the 2026-06-04 font-loading literature pass and a four-lens peer review, and ratified through Z's in-session decisions.

## Context

The site sets Latin text in three licensed retail families (GT Flexa — a variable face used for body + a separate mono cut, Cardinal Fruit, and the Cheee display face) and will set Japanese in Noto. The performance floor is a cold first paint on mobile (~200 ms round-trip goal), which makes webfont weight, request count, and layout stability first-order concerns, not polish.

Before this work the faces were either not self-hosted or shipped as hand-maintained `@font-face` blocks, and the H1 zero-CLS metric-override fallbacks were hand-written into `assets/css/_fontface.css`. There was no repeatable way to re-subset a face, add a face, or keep the fallback metrics honest — every change was manual surgery on a committed CSS file.

Two findings constrained the design:

1. **The in-house metric extractor cannot be trusted for these faces.** `assets/tailwind/extract-font-metrics.ts` (fontkit) misreads variable and display fonts — it reported GT Flexa's average advance width as 0.21 against a browser-rendered 0.55, and Cardinal Fruit's cap-height as 0.37 against 0.75. `capsize` hit the same wall (0.127). Regenerating the override metrics from either tool would have **regressed** the already-correct, browser-measured values (Cardinal cap 0.75 → 0.37) and reintroduced the CLS the H1 work removed.
2. **A second, unrelated font pipeline already exists.** `assets/tailwind/extract-font-metrics.ts` + `generate-type-tokens.ts` derive the baseline/line-height *type tokens* in `_typography.css`. That pipeline is about vertical rhythm, not subsetting; the new pipeline must not collide or be confused with it.

The literature pass (`.tmp/2026-06-04-font-loading/literature/brief.md`) catalogued the techniques: H1 metric-override fallbacks, H2 preload + immutable cache, H3 CJK unicode-range slicing (e.g. `cn-font-split`), H4 content-aware static subsetting, H7 Incremental Font Transfer as the future. The peer review (`.tmp/2026-06-04-font-loading/peer-review/`) then pushed hard toward the least-additive shape.

## Decision

**One on-demand generator owns subsetting and `@font-face` emission.** `assets/fonts/generate-fonts.mjs`, run via `./run assets:fonts`. It is plain Node ESM — deliberately **not** ts-node (the ts-node type-token scripts are broken; a subsetting step must not depend on them). It reads the licensed sources in `assets/fonts/src/` (gitignored), subsets each with `subset-font` (harfbuzz `hb-subset`) to woff2 in `assets/static/fonts/`, and writes `assets/css/_fontface.generated.css` (committed, with a `DO-NOT-EDIT` header, the same way `_typography.css` is a committed generated file).

**The manifest is the inline `FACES` array in that script — not a separate config file.** One entry per output face: source path, output basename, family, weight, and an optional metric-override fallback. Co-locating the manifest with the loop that consumes it is the right size for ~5 faces.

**Metric-override fallback faces are browser-measured and hand-declared in the manifest, never extracted.** Each fallback entry carries `size-adjust` / `ascent-override` / `descent-override` / `line-gap-override` measured in the browser (a–z average advance + `fontBoundingBox ÷ em`). The generator emits these verbatim after the real faces. This is the load-bearing decision: the override values produced here are byte-identical to the previously committed `_fontface.css` and preserve zero CLS.

**Idempotency is by reproduction, not a lockfile.** Each run re-subsets every face (sub-second for this set) and the output is byte-stable, so re-running is effectively a no-op. There is no `.fonts.lock` and no skip-unchanged logic.

**Variable faces keep their full axes for now.** `gt-flexa.woff2` ships the whole `wght 100–900` range plus an unused `wdth` axis (~343 KB) because the design will use those axes later. Instancing/axis-trimming to shrink it is deferred (see Consequences).

**Delivery: woff2-only, preload the one critical face, cache via the static manifest.** `root.html.heex` preloads GT Flexa (the body type) with `crossorigin`, at the **literal non-digested** path `/fonts/gt-flexa.woff2`, so the preload byte-matches the `@font-face` the (non-digested) `app.css` requests. Caching rides on the existing `cache_static_manifest`; no custom cache plug is added.

**The two font pipelines coexist deliberately and are named to stay distinct.** New: `assets/fonts/generate-fonts.mjs` → subsetting + `@font-face`. Existing: `assets/tailwind/extract-font-metrics.ts` + `generate-type-tokens.ts` → baseline/line-height type tokens in `_typography.css`. Consolidation is deferred, not done here.

**CJK/Japanese is deferred; Latin ships first.** The planned Noto recipe (content-aware static subset, `font-display: optional`, system fallback, no descriptor overrides, `:lang(ja)` line-height) is recorded but not built.

## Why This Direction

The peer review revised an earlier, heavier proposal down to the shape above:

- **Dropped `cn-font-split` / runtime unicode-range slicing.** For a site whose content is mostly known at build time, content-aware static subsetting (H4) delivers the bytes without a runtime slicing dependency and its CSS-generation surface. CJK can adopt static subsetting too when it lands.
- **Dropped the standalone manifest file and the lockfile.** Both are over-engineering for ~5 faces. The inline array keeps the manifest one scroll from the code that reads it; reproduction is a simpler idempotency contract than a content-hash lock that can go stale.
- **Emit `_fontface.generated.css` instead of clobbering a hand-written file.** A generated artifact must be unmistakably generated. Overwriting a hand-edited `_fontface.css` invited "two sources of truth" confusion; a `DO-NOT-EDIT` generated file does not.
- **"generate", not "build".** "build" was already the esbuild/Tailwind asset build; the font step *generates* derived artifacts. Naming it `generate-fonts` keeps the verb honest.
- **Browser-measured metrics are non-negotiable.** The entire value of a metric-override fallback is zero CLS; a wrong width defeats the purpose. The browser is ground truth for variable/display faces where fontkit and capsize are not.

For the preload specifically: `mix phx.digest` was verified to **not** rewrite the original `app.css`'s `url()` (only the digested copy carries the digested font path), and the layout loads CSS via a literal non-digested `href`. So the browser requests the non-digested font, and the preload must match it. A `~p` preload would resolve to the digested path in production and download the font twice.

## Consequences

Adding or changing a face is now: edit the `FACES` array → `./run assets:fonts` → commit the regenerated `_fontface.generated.css` → ship the woff2. No manual `@font-face` editing.

Hard "do nots" for future maintainers:

- **Do not regenerate the fallback metrics from fontkit/capsize.** They will regress (see Context). Re-measure in the browser if a face changes.
- **Do not add a lockfile or skip-unchanged logic.** Re-running and reproducing is the idempotency contract.
- **Do not move the preload to `~p` while the CSS link is literal/non-digested** — it would double-download in production. Move both together (see backlog).

Deferred to **`_PROJECT_DOCS/BACKLOG.md` → Typography, color, and font pipeline**
(each its own commit):

1. Instance + axis-trim the variable faces before launch (the single biggest byte win on the heaviest, highest-priority asset).
2. Consolidate the two font pipelines into one `assets/fonts/` home.
3. Fix the broken type-token npm scripts (`assets:font-metrics` / `generate:typography`).
4. Define prod delivery of the gitignored, licensed woff2 (deploy ships `priv/static/fonts/` out-of-band).
5. Digest the layout's CSS link (`~p"/css/app.css"`) to immutable-cache the CSS *and* the font, then move the preload to `~p` in lockstep — the remaining H2 caching win.
6. The CJK/JP (Noto) subset + delivery recipe.

If the measured cold-load result still misses the goal after axis-trimming and immutable caching, open a new ADR comparing Incremental Font Transfer (H7) rather than reaching for it by opportunistic change.

## References

- Pipeline (durable source of truth): `assets/fonts/generate-fonts.mjs`; generated output `assets/css/_fontface.generated.css`; run target `./run assets:fonts`; preload in `lib/portfolio_web/components/layouts/root.html.heex`.
- Deferred work: `_PROJECT_DOCS/BACKLOG.md` → Typography, color, and font
  pipeline.
- Audit trail (in `.tmp/`, may age out): font-loading literature brief `.tmp/2026-06-04-font-loading/literature/brief.md`; H1 gap analysis `.tmp/2026-06-04-font-loading/h1-gap-analysis.md`; peer review `.tmp/2026-06-04-font-loading/peer-review/{ia,ddd,subtractive,performance}.md`.
- `subset-font` (harfbuzz `hb-subset`): `https://github.com/papandreou/subset-font`
- web.dev font best practices (preload, `font-display`, metric overrides): `https://web.dev/articles/font-best-practices`
- W3C Incremental Font Transfer (future, H7): `https://www.w3.org/TR/IFT/`
