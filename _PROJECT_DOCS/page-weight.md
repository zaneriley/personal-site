# Page weight: measurements, decisions, and how we prove nothing broke

This file owns one question: why the pages are heavier than the budgets allow,
and what we are doing about it. The work items live in `BACKLOG.md` under
**Page weight** and **Asset handling and regression checks**; this file holds
the numbers behind them, the reasoning that has already been settled, and the
checks that prove a weight change did not alter the design.

## Where the bytes are (home page, measured 2026-08-29)

The budgets live in `ci/contracts/routes.json` and are enforced by
`ci/gates/browser-performance.mjs`, which loads each page in a real browser on
a simulated mid-range phone and counts what came over the network.

| What | Measured | Budget | Note |
|---|---|---|---|
| Images | 577,161 | 150,000 | One draft photograph, 574,227 of it |
| Fonts | 372,100 | 100,000 | Five typefaces. Was 536,667 before the axis trim below |
| HTML | 52,658 | 30,000 | Sent uncompressed; would be ~12,000 compressed |
| Live-page connection | 33,404 | 20,000 | Not compressed either |
| JavaScript | 48,931 | 60,000 | Already passing; 92.5% is the framework |
| Requests | 11 | 6 | Five fonts plus the photograph |
| **Whole page** | **~1,219,051** | **88,000** | See the contract problem below |

**The contract cannot be satisfied as written.** The whole-page budget (88,000)
is smaller than the font budget alone (100,000), so no combination of passing
sub-budgets adds up to a passing page. That is a decision waiting to be made,
not a number to tune — see the BACKLOG item about deciding what the site is
willing to ship.

**What CI measures is not what visitors get.** The font files are deliberately
not committed to the repository, so a CI checkout has none of them and all five
requests fail with a 404. CI therefore reports zero font bytes and undercounts
the total page by 42–80% on every route. Only a local `./run ci:release` run
measures fonts honestly. This also means that when font delivery is fixed, the
font budget will begin being enforced for the first time and the gate will look
like it newly broke.

---

# Phase 1 (done): font axis trim

**Status:** planned. Executes deferred consequence #1 of ADR 0004 ("instance +
axis-trim the variable faces before launch"). This document is the measuring
stick for that slice: what we predict, what must not move, and how we'll know
the outcome. When the slice ships, record the actuals in the tables below and
append the commit hash to ADR 0004's status line; this file then stays as the
measurement record.

## What we found (2026-08-29 audit, three-agent pass)

The 343 KB of `gt-flexa.woff2` is **axes, not glyphs** — the Latin charset
subset already happened. The font carries three variation axes:

| Axis | Range | Default | Site usage |
|---|---|---|---|
| `wght` | 100–800 | 100 | 14 generated rungs spanning 148–758; calibration page exercises the full clamped 100–800 |
| `wdth` | 0–200 | 0 | **Never used.** No `font-stretch` or `font-variation-settings` anywhere; `app.css` explicitly bans variation-settings |
| `ital` | 0–100 | 0 | **Never used** |

`gt-flexa-mono.woff2` (60.6 KB) also carries a dead `ital` axis — and renders
at essentially one weight (268, inherited; the weight-class helper never
targets mono).

## The change (phase 1)

Pin the dead axes **at their defaults** in the `FACES` manifest of
`assets/fonts/generate-fonts.mjs`:

- GT Flexa: `variationAxes: { wdth: 0, ital: 0 }`
- GT Flexa Mono: `variationAxes: { ital: 0 }`

plus threading the option into the existing `subsetFont()` call. Pinning at
the default discards that axis's delta data without touching the default
instance's outlines, advance widths (`hmtx`), or vertical metrics
(`hhea`/`OS/2`) — which is exactly why it is the safe operation (see
Invariants 1–2).

**Explicit non-moves, and why:**

- **No `wght` range trim.** The axis default equals its minimum (100), so
  raising the min moves the default instance — the one operation that can
  silently invalidate the browser-measured fallback metrics. And because
  min = default, there is a single delta region; trimming the max saves
  almost nothing. Range restriction is also the youngest instancing code
  path in HarfBuzz (stable API only since 8.5.0). Bad risk, bad ROI.
- **No static instancing.** The weight system is continuous by design —
  14 rungs computed from 4 knobs, retuned by eye on `/weight-calibration`.
  Static cuts turn every knob tweak into a regenerate-and-rebucket pipeline
  event and kill intermediate weights.
- **No dev/prod font split.** Dual pipelines are forbidden by ADR 0004;
  parity is a feature — if a knob setting ever exceeds the served face, the
  calibration page shows the clamp immediately.
- **No budget raise.** `ci/contracts/routes.json` `exceptions` stays `[]`.
  The gate exists to force this work (BACKLOG: "do not raise budgets to
  make the gate green").

## Expected outcomes (fill in actuals when the slice ships)

Research band: dropping one axis's variation data ≈ 20–35% of a variable
woff2; two dead axes compound. Predictions are deliberately written down
before running the generator.

| Measure | Before | Predicted after | **Actual (2026-08-29)** |
|---|---|---|---|
| `gt-flexa.woff2` | 343,436 B | 150,000–220,000 B | **203,420 B** (−40.8%) — in band |
| `gt-flexa-mono.woff2` | 60,608 B | 45,000–55,000 B (ital only — modest) | **37,148 B** (−38.7%) — beat band |
| `cardinal-fruit-*.woff2`, `cheee-small.woff2` | 53,024 / 54,924 / 23,584 B | **unchanged** | **unchanged** ✓ |
| `font_bytes` on `/` (browser perf gate, local `ci:release`) | 536,667 B | 350,000–430,000 B | **~372,100 B** (−30.7%) — in band |
| Diff size (see Invariant 6) | — | ≤ ~10 changed source lines, 0 new files, 0 new deps | **6 code + 14 comment lines**; 0 new files/deps/stages — see ledger below |

**Only `ital` was pinned. `wdth` was left variable** — see the correction
below; the original plan to pin both was wrong and the render-parity check
caught it.

### Correction: pinning at the fvar default is NOT always an identity operation

The plan (and all three research passes behind it) assumed "pin an unused
axis at its own default value ⇒ nothing rendered can move." That is false
whenever **CSS requests a value different from the font's default**:

- `font-stretch: normal` resolves to **wdth = 100** (CSS Fonts 4), but GT
  Flexa's `fvar` default for `wdth` is **0**. The browser was therefore
  never rendering the font's default width. Pinning at the fvar default (0)
  silently condensed the entire site: **28 of 32 surfaces changed**, whole
  pages reflowed (e.g. `color-tokens` desktop 1528 px → 1182 px tall).
- Pinning at the CSS-requested value (100) fixed the reflow but still failed
  parity: baking a non-default location re-rounds every delta to integer font
  units, drifting glyph positions. Still **28 of 32 surfaces**, max channel
  delta 203–251 — subtle, but measurable, and it also invalidates the
  "metric tables provably unchanged" argument that protects the fallbacks.
- `font-style: normal` resolves to **ital = 0**, which *does* equal its fvar
  default. Pinning it is a true identity operation: **32 of 32 surfaces
  byte-identical.**

**Rule going forward, encoded in the generator's axis policy comment:** only
pin an axis whose CSS-requested value equals its `fvar` default. Anything
else must clear the render-parity check before it ships. `wdth` remains a
live axis; reclaiming its ~143 KB is a separate decision needing its own
evidence (and would mean accepting sub-pixel glyph drift, or re-measuring
the fallback metrics).

**Honest expectation: phase 1 alone does not clear the 100,000 B per-route
font budget.** It removes the risk-free bytes and sets up the measured
decision for phase 2. The remaining gap adjudicates the next lever, in
order:

1. **Mono weight band** — full variable font shipped for one rendered
   weight; a narrow band or static cut lands ~25–35 KB. Can be aggressive:
   no calibration workflow exists on mono. (Only `bolder` resolution from a
   `<strong>` inside code/footer text can reach 400/700 — decide whether to
   keep or normalize that before cutting.)
2. **Charset pruning with evidence** — Latin Extended-A (128 glyphs, each
   carrying wght deltas) is subset in wholesale; run glyphhanger against
   actual content and prune what nothing uses.
3. **Per-route face discipline** — whether every route needs Cardinal ×2 +
   Cheee.

If all levers are exhausted and the gate still fails, that is ADR 0004's
recorded escalation (new ADR comparing Incremental Font Transfer — still
unshipped in browsers as of 2026-08) — not a budget raise.

## Backstop verification: what must not move

Each invariant has a mechanical check. "Looks the same" is not a check.

1. **Fallback metrics stay valid (zero CLS).** The browser-measured
   `size-adjust`/`ascent-override`/`descent-override` values in
   `_fontface.generated.css` were measured against the current file and are
   never regenerated (ADR 0004 hard rule). Proof they still hold: the metric
   tables of the trimmed font are **byte-identical** to the original.

   ```
   uvx --from fonttools ttx -q -t head -t hhea -t OS/2 -t hmtx -o before.ttx <original>
   uvx --from fonttools ttx -q -t head -t hhea -t OS/2 -t hmtx -o after.ttx  <trimmed>
   diff before.ttx after.ttx   # must be empty
   ```

   (One-time evidence recorded in `.tmp/`, not a permanent pipeline stage —
   the pin-at-default operation cannot change these tables by construction;
   the diff proves the implementation matches the theory.)

2. **`_fontface.generated.css` is byte-identical after regeneration.** Same
   families, weights, URLs, fallback blocks. This single check proves the
   preload/`url()` byte-match constraint and the `@font-face` surface are
   untouched. `git diff --stat` on the file must show nothing.

3. **Rendered text is unchanged at every served weight.** `hb-shape`
   advance-width diff at the 14 rungs (148…758) over a test string, before
   vs after — arrays must be equal. Belt-and-braces option: `diffenator3`
   (Google Fonts' regression tool). One-time evidence in `.tmp/`.

4. **The design-iteration surface keeps its full range.**
   `/weight-calibration` must still render the continuous 100–800 span with
   no visible clamping or fallback-font flashes. One-time browser
   confirmation — *confirm* the committed fallback numbers, never re-measure
   them into the repo.

5. **The existing gates are the permanent backstop — no new machinery.**
   `ci:test` (501 Elixir + 52 JS), the browser performance gate
   (`max_font_bytes` prices every face in `FACES` automatically, per route),
   and gate-integrity. No new CI steps, no font lockfile, no verification
   sidecar. Idempotency stays "rerun and reproduce."

6. **The diff itself stays small — additive code is a regression.** Budget
   for phase 1: **~10 changed source lines** (two manifest entries, option
   threading, header-comment update), zero new files (this doc excepted),
   zero new dependencies, zero new pipeline stages. If the implementation
   wants more than that, the implementation is wrong — stop and re-read
   this file. The axis policy lives as a comment in `FACES` deriving the
   answer from `type-config.ts` ("wght stays full: every `--fw-flexa-*`
   rung must remain inside; wght min may never rise above the default 100").

7. **The rendered design does not regress — pixel parity, not "looks
   right."** The design is unfinished, but it is *exactly reproducible*, and
   pin-at-default is an identity operation on everything the site renders —
   so unlike ordinary visual regression testing we can demand **zero
   differing pixels**, no fuzzy threshold.

   **Capture matrix:** the seven budget-gated public routes plus the design
   surfaces that exercise the fonts hardest — `/weight-calibration` (all 14
   rungs + bold rungs + the 100–800 continuum), `/code-block` (GT Flexa
   Mono), `/color-tokens` — at both contract viewports (1280×720 desktop,
   iPhone SE mobile) and both color schemes (the theme system is the point
   of this branch). Roughly 40 PNGs per capture set.

   **Determinism first — calibrate the meter before trusting it.** Capture
   the matrix twice at the *same commit* and diff. Any surface that differs
   against itself is not a valid witness: fix its nondeterminism or exclude
   it by name with the reason written here. Known handle: the animated
   cloud surface already renders a single static frame under
   `prefers-reduced-motion`, so captures emulate `reducedMotion: reduce`
   (and each LiveView page gets a settle wait after websocket connect).

   **Procedure:** baseline set from the pre-trim commit → trim → identical
   capture run → `magick compare -metric AE` per pair must report **0** for
   every included surface. Capture runs inside the existing browser image
   (chromium + playwright are already there); the capture driver is a small
   throwaway script in `.tmp/render-parity/` — **not committed** — reusing
   the screenshot pattern from `ci/preview/preview-page-acceptance.mjs`.
   Both capture sets and the diff log stay in `.tmp/render-parity/` as the
   slice's evidence; this file records the verdict. If phase 2 (charset
   pruning — where a pruned-but-used glyph is exactly the failure mode this
   catches) needs the harness again, rerun it from `.tmp/`; promote it to a
   committed tool only if it earns permanence, as its own decision.

## Submission gates (human review — the slice cannot land without these)

Automated invariants are necessary, not sufficient. Two things must be put
in front of Z, in the PR body, before the slice is submittable:

**Gate A — visible proof, or the ability to reproduce it.** Not a claim that
the diff was zero: the actual evidence. The PR must carry the
before/after/diff image triplet for at least `/` and `/weight-calibration`
at both color schemes, the full `magick compare -metric AE` table (every
captured surface, its pixel-difference count, and any excluded surface with
its reason), and the one-line command that re-runs the capture from
`.tmp/render-parity/` so the result can be reproduced rather than trusted.
A surface that cannot be captured deterministically is reported as such —
never silently dropped from the table.

**Gate B — the line-count ledger, over or under.** Report actual changed
source lines against the ~10-line budget from Invariant 6, stated as an
explicit over/under, split into:

- **source** (`generate-fonts.mjs`, any threading) — counted against budget
- **generated** (`_fontface.generated.css`) — must be 0 (Invariant 2)
- **docs** (this file, `BACKLOG.md`, ADR status line) — reported separately,
  not counted against the source budget
- **new files / new deps / new pipeline stages** — must be 0, and the
  throwaway capture script in `.tmp/` is uncommitted by construction

If the source count lands over budget, the ledger says so plainly and the
overage is justified in the PR or the change is reworked. "Slightly over
but it's fine" is not an outcome — the number is stated and adjudicated.

## Out of scope, noted during the audit (backlog, not this slice)

- Sketch/dev routes (`/weight-calibration`, `/color-sketch`, `/hdr-lab`, …)
  ship in production — no env guard in the router scope.
- `⧉` (code-block copy button) and `≺` `≻` (error pages) are outside the
  subset charset and silently render in system fonts today.
- Prod delivery of the gitignored licensed woff2 (ADR 0004 deferral #4) —
  CI builds currently ship **zero** webfonts, so CI's perf numbers
  undercount fonts; only local `ci:release` measures them truthfully.
