# personal-site — repo contract

Repo-scoped stable rules and pointers. The global agent contract lives in
`~/.agents/AGENTS.md`. Human orientation starts in `README.md`; durable project
documents start in `_PROJECT_DOCS/README.md`.

---

## Acceptance gates (always-on)

A change is mergeable only if all of the following hold. These are inherited expectations — running them locally or in CI catches the kinds of mistakes the gates exist for.

The human command surface is `./run help`, organized around `dev:*`, `ci:*`,
and `deploy:*`. `dev:*` stands the app up locally; `ci:*` proves repo state;
`deploy:*` handles private previews, publication rehearsals, content state, and
release-shaped deploy proof.

The supported acceptance-gate surface is `./run ci:*`: `ci:format`, `ci:lint`,
`ci:compile`, `ci:test`, `ci:types`, `ci:security`, `ci:secrets`, `ci:workflow`,
`ci:release`, and `ci:gate-integrity`. GitHub workflow YAML should call these
tasks, not raw `mix`, `npx`, `yarn`, or one-off shell versions of the same
checks. Existing workflows may still use compatibility aliases in `run`; those
aliases delegate to the same implementation and are migration debt, not a
second gate path. If a gate changes, update `run` first.

GitHub CI must expose the real acceptance gates as legible top-level check jobs. Do not hide compile, lint, security, test, static analysis, workflow lint, or gate-integrity work as steps inside one generic `test` job. A PR reviewer should be able to identify the failing gate from the checks list without opening logs.

- `./run ci:compile` produces zero compile warnings.
- `./run ci:workflow` is clean: actionlint accepts every GitHub workflow file.
- `./run ci:acceptance-gate-bypass-check` is clean, and `./run ci:acceptance-gate-bypass-check:test` passes its fixture matrix: canonical workflow/run samples pass, and known fake-green patterns are rejected.
- `./run ci:lint` is clean: ShellCheck, Hadolint, Credo, `mix format --check-formatted`, Biome check, and Stylelint check. The intentional CJK `!important` rule has a declaration-local Biome waiver in `assets/css/app.css`; any emitted warning is red.
- `./run ci:security` is clean: Sobelow with project config and nonzero exit on findings.
- `./run ci:types` is clean: Dialyzer reports `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`.
- `./run ci:test` is clean: Elixir tests and JS tests have 0 failures.
- `./run ci:secrets` is clean: gitleaks current-tree scan has 0 findings.
- `./run ci:release` is clean: prod image build, migration round-trip, release boot, `/readyz`, canonical route probes, release RPC introspection, and public page budget checks all pass. GitHub branch protection must require the top-level `Prod build` check.

Route smoke is part of the production-build gate, not a separate placeholder job. Do not add another route-smoke gate just to make CI look broader; widen `./run ci:prod-build` only when the app has a stronger readiness/content contract.

### CI / deploy IA guardrail

The CI/deploy/preview area was reset on 2026-05-16. New CI files must fit the map below instead of recreating a junk drawer.

Locked direction:

- Generated local evidence defaults to `.tmp/ci-artifacts/`, not `ci/`. CI can upload those paths as GitHub artifacts; durable repo inputs stay source-shaped.
- Prefer fewer files. Do not split tiny scripts/configs just to make a taxonomy look clean; split only when a folder/file owns a durable concept a future maintainer can name.
- `./run` remains the canonical command surface. The tree behind it must explain where contracts, gates, preview verification, provider glue, published sample content, content publication flow checks, and generated artifacts live.
- Reserve `preview` for a deployed private candidate lane or checks against that lane. Reserve `origin` for the future durable runtime environment. Use `candidate image`, `disposable host`, `runtime viability`, `route probe`, `preview page acceptance`, `public page budget`, `published sample content`, `content publication flow`, `publication verdict`, and `receipt` for the current verification concepts.
- Preserved private previews are leased, not permanent. Keep the default TTL low while preview cleanup is still maturing, record the expiry in the preview receipt, and rely on the destroy workflow or sweeper rather than leaving DigitalOcean droplets around by memory.
- Do not add a second "content preview" lane. Preview owns disposable deployed targets; content publication flow owns the author loop of content PR, merge to content `main`, delivery intake, accepted/rejected/ignored verdicts, and last-good preservation. Commands and scripts may rehearse this flow, but they are not the author DX.

### Gate integrity: no fake green

The canonical commands above are the gate contract. Use `./run <task>` unless debugging a command internals issue; if you use a raw underlying command, explain why and still re-run the canonical gate before calling it green. There is no `./psh` wrapper in this repo.

A gate is green only when the real command runs, returns its real exit code, and its output satisfies the rule above. Agents must not make a gate pass by weakening the gate.

Forbidden for acceptance gates:

- No `|| true`, `--ignore-exit-status`, `continue-on-error`, `allow_failure`, unnamed warning baselines, broad ignore files, or tool-specific suppressions.
- No deleting, narrowing, renaming, or skipping tests to reduce failures.
- No changing CI from "fail on problem" to "report problem but pass."
- No replacing a required gate with a cheaper proxy. Lint, compile, Dialyzer, unit tests, and secret scan are separate gates.
- No claiming "green" from a command that exited nonzero, timed out, failed to start, or was not run.
- No count-only baseline games. A baseline exception must name the exact failing tests or warning IDs; different failures are new failures. Prefer deleting the exception by fixing the underlying behavior.

When a gate fails, do this instead:

1. Keep the gate strict.
2. Identify the root cause from the command output.
3. Fix the code, test, config, or type contract causing the failure.
4. Re-run the same canonical gate without suppressions.
5. Report the exact command, exit status, and remaining failures or warnings.

If a gate cannot be fixed in the current slice, stop and report it as red. Do not downgrade it to advisory. Do not hide it behind a baseline. Do not merge it into an unrelated change.

The Elixir-side prescriptions (writing-controllers, writing-liveviews,
writing-otp, etc.) live in the global `~/.agents/skills/elixir-phoenix-style/`
skill. Load `SKILL.md` early in any Elixir-editing session.

---

## Decision records

- ADRs live in `_PROJECT_DOCS/adrs/`.
- `AGENTS.md` is for constant repo-level guidance, workflows, acceptance gates, and pointers to durable records. It may summarize or link to ADRs when the guidance must stay visible, but it is not the ADR body.
- Tactical day-to-day notes stay in conversation or `.tmp/` until promoted into either an ADR or an always-on repo rule.

## Commit and PR language

Keep Conventional Commits for tooling, but make the subject after the prefix readable to someone who has not read this repo's planning docs. Use `feat:` only when the world changes in a user-observable way; plumbing, renames, and guardrail tightening are usually `chore:`, `build:`, or `ci:`. Avoid internal nouns in subjects such as verdicts, generations, ledgers, spikes, acceptance surfaces, or publishability; put mechanism in the body.

---

## Deploy / ops constraints

The durable objective is a site visitors do not see broken: strict CI before
promotion, last-good content, explicit rollback, and the smallest origin that
meets measured user-facing performance. DigitalOcean is the accepted interim
substrate; see `_PROJECT_DOCS/adrs/0003-use-digitalocean-as-interim-origin-substrate.md`.

Current implementation status and unfinished planning live in
`_PROJECT_DOCS/deploy-ops-status-plan.md`. Treat its dates and run evidence as a
working record, not as always-current repository truth. The content authoring
contract lives in `_PROJECT_DOCS/content-authoring-contract.md`; CI/deploy file
ownership lives in `ci/README.md`.

Locked constraints:

- **No Co-Authored-By; no Claude/Anthropic mentions in commit messages.** Hook-enforced via `~/.agents/claude-code/hooks/block-co-author.sh`. Why: tool-attribution leaks tooling choice into history; commits are by Z regardless of who drafted the prose.
- **No tool/stack prescription without `/literature` first.** Why: prevents unsourced lock-in. Z explicitly ratified this 2026-05-06 for CDN, secrets management, deploy substrate, and observability. Default to literature-first; "I think we should use X" is a yellow flag without a brief.
- **No Grafana.** Explicit veto 2026-05-06.
- **Versioned + idempotent deploys.** Why: blast-radius-bounded, repeatable, recoverable.
- **Speed wins ties.** Decision criterion *and* operational constraint: any tool that slows the user-visible path loses, full stop.
- **Compute-per-watt floor; never at user expense.** Resource minimization is the goal until it costs visitors. User experience is the hard floor.

---

## Backlog

Canonical backlog for this repo (per `~/.agents/AGENTS.md` §10). Vault read-view/scratch lives at `~/repos/obsidian-notes/Backlog/side-projects/portfolio/`. Items here are scoped enough to start cold; ADR-grade decisions still land in `_PROJECT_DOCS/adrs/`.

### Design passes (logged 2026-06-03)

These three surfaced during the light/dark theme + identity work and are explicitly **design passes**, not quick fixes.

- **Grid system is broken site-wide — needs a holistic pass.** The 12-col grid is applied inconsistently and breaks at mobile. Evidence: `main` (home/about) uses `sm:col-start-3 sm:col-end-11` with **no base placement**, so below the `sm` breakpoint it falls to `grid-column: auto` = 1 of 12 tracks (~27px at a 342px viewport) and squishes all content; the footer is full-bleed `grid grid-cols-12` not constrained to `--grid-max-width` nor aligned to the content inset. `.u-container` / `.u-grid` + the `--grid-*` tokens exist but aren't consistently used. **Pass should:** go mobile-first (define base stacking, not `sm:`-only placement), pick one container (max-width + gutters via `--grid-*`), and align nav / main / footer to the same grid. Affects most templates + `assets/css/app.css`.

- **`spec_sheet` primitive is close but off-mock — second pass.** The footer's Typefaces + Server cards (`PortfolioWeb.Components.Footer.spec_sheet/1`, styles in `assets/css/_footer.css`) are structurally right but don't match the Figma mock. Gaps: padding/proportions, border + inset treatment, header tag + status-dot placement (dot floats to the right edge / header wraps at narrow widths), and row label-column width (values wrap awkwardly). (The green "PASSING"/dot and metric colors now have real tokens — `--footer-ok`/`--footer-datum`, aliased to the code palette so they track theme.) **Also:** GT Flexa Mono isn't loaded — labels/values fall back to the system monospace stack (footer uses `--font-mono` directly); load the face or pick a deliberate substitute. Mock: `~/Downloads/Footer.{png,svg}` (TRANSIENT — archive into the repo/vault before it's lost; the `.svg` is a flat outlined export, a visual spec only). **Lint policy decision — RESOLVED (`bededc5`):** the spec_sheet's BEM `.spec-sheet__el` / `--mod` selectors were renamed to kebab (`.spec-sheet-el`), clearing the 14 `selector-class-pattern` errors and keeping the CSS single-convention (kebab throughout). No BEM-sanctioning `.stylelintrc.json` change was made.

- **No design-system solution for click/tap affordances.** There's no consistent treatment for interactive elements (links, buttons, tap targets, and hover / active / focus-visible / visited states). Hard because the dusk/neutral palette **shifts both hue and chroma across the OKLCH lightness ramp**, so naive "darken on hover" or a single fixed accent doesn't read consistently — affordances must hold across the moving neutral ramp **and** both themes, on a textured surface. **Pass should:** define interactive-state tokens (hover/active/focus-visible/visited), a minimum tap-target size (44px), a focus-visible ring legible over the surface texture, and link underline/affordance conventions — wired into the existing `--text-color-*` / `--accent` token system, not ad-hoc per component.

- **Replace the footer's display-only status with owned live data.** `PortfolioWeb.Components.Footer` currently defaults the server temperature, deploy SHA/status, node health, operating cost, and Tokyo temperature. Wire each value to a bounded, cached source (thermal zone, release stamp, health state, and weather provider) without moving data access into HEEx; preserve explicit assigns so tests and degraded operation stay deterministic.

- **Revisit nav label/route naming (Case Studies, Self) — punted 2026-06-05.** Shortening the nav labels ("Case Studies"→"Work", "Self"→"About") would gain header width, but the quick win is outweighed by what it opens: (1) **taxonomy** — a single *case study* is a deliberately distinct content type from a *note*; "Work" blurs that distinction. (2) It's **unclear "Work" reads better** than "Case Studies" at all. (3) **Routes** — changing `/case-studies`, `/self` is an SEO call: it needs 301s once the site is indexed, but the site is currently `robots.txt: Disallow: /` (default Phoenix, pre-launch), so a route change would be **free right now** — argues for deciding *before* launch if ever. (4) **i18n** — slugs are currently English under a locale prefix (`/ja/case-studies`); a rename forces the choice to keep English slugs everywhere vs. localize per locale. (5) **Depth** — label-only vs. +route vs. +concept rename (`CaseStudyLive`/`:case_studies`/content-type). Decide the taxonomy and depth first when revisiting; don't do a partial swap.

### Fonts / performance (logged 2026-06-04, from the font-loading peer review)

The pipeline these items defer from is ratified in `_PROJECT_DOCS/adrs/0004-font-subsetting-and-delivery-pipeline.md` (the "why", and the hard "do nots"); the items below are its deferred consequences.

- **Instance + axis-trim the variable faces before launch.** `gt-flexa.woff2` ships the full `wght 100–900` **and an unused `wdth` axis** (~343 KB) but the design currently uses 350/700 at one width. Trimming → ~150–190 KB on the heaviest, highest-priority asset, no design loss. **Deferred** because we expect to use width/weight axes on the variable typefaces later — **revisit before site launch** (instance to the axes actually used, per the `generate-fonts.mjs` pipeline). Peer-review verdict: this is the single biggest font perf win.
- **Consolidate the two font pipelines into one.** `assets/tailwind/extract-font-metrics.ts` + `generate-type-tokens.ts` → `_type-tokens.generated.css` (sizes, line-heights, baseline/line-height *metrics*, optical weight) and the new `assets/fonts/generate-fonts.mjs` (subsetting + `@font-face`) both read the source fonts. `assets/tailwind/` is mislabeled (font-metrics work, not Tailwind). Collapse into one `assets/fonts/` home; `generate-type-tokens` stays a downstream consumer. Own commit. Note: `extract-font-metrics.ts` (fontkit) is **unreliable** for variable + display faces (misreads GT Flexa width 0.21 vs 0.55, Cardinal cap 0.37 vs 0.75) — H1 override values must stay browser-measured, never fontkit-regenerated.
- **Emit the font-preload list from the pipeline so it can't drift from `@font-face`.** The critical-font `<link rel=preload>` in `root.html.heex` hardcodes `/fonts/gt-flexa.woff2` — a duplicate of the body `@font-face` the pipeline writes into `_fontface.generated.css`. Have `generate-fonts.mjs` emit the "preload these" list (or a single body-face token the layout reads) so preload and `@font-face` derive from one source; that removes the double-fetch hazard structurally (no sync test needed). Natural to fold into the pipeline consolidation above.
- **`assets:font-metrics` npm script is still broken.** It runs via `ts-node`, which fails on a missing `typescript` peer dep. (`generate:typography` was switched to an `esbuild` bundle+run and now works — esbuild is already a dependency and needs no `typescript`; do the same for `assets:font-metrics` when consolidating.) `extract-font-metrics` is also the *unreliable* one (fontkit misreads display/variable faces — see above), so leave it until the pipeline consolidation.
- **Prod delivery of the (gitignored, licensed) woff2.** Font binaries can't be committed (public repo) — the deploy must ship `priv/static/fonts/` out-of-band. Define the mechanism before launch. **Note:** the asset build (`yarn:build:js`/`build:css`) does *not* run `generate-fonts.mjs`, and both the source faces (`assets/fonts/src/`) and the built woff2 are gitignored — so a clean CI checkout builds an image with **no fonts at all**. This is the load-bearing gap; pick a mechanism (private artifact store, authed build-time fetch, git-lfs on a private mirror, or an out-of-band copy in the deploy step).

### Content pipeline (logged 2026-06-10)

- **`figure.ex` can't render through the markdown pipeline (latent).** It's registered with the Component.Registry, but its `figure/1` only accepts HEEx-shaped assigns (`@src`, `@alt`) — the pipeline applies registered components with `%{component:, attrs: string-keyed-map, content:}` (see `Component.Definition`'s moduledoc), which would crash it. Unexercised today because no stored content emits a `:figure` node. Fix = add a pipeline-shape clause like `CodeBlock.code_block/1`'s, plus an end-to-end test through serialize→render (the code-block e2e in `compiler_test.exs` is the template — it caught the string-vs-atom type bug the same way).

### Mock fidelity bugs (logged 2026-06-06)

Manual visual-diff findings vs the Figma mocks, caught while reworking type weight + the color tokens. **Several are entangled with the in-progress color-system rework** (the `/color-tokens` dev experiment, the `--dusk-000` = white-point body decision, and the text-ladder re-seat) — settle those tokens first where noted. Hero markup: `lib/portfolio_web/live/home_live.ex`. **Before working these, archive the relevant Figma frames into the repo/vault** so they stay checkable (prior mocks went transient in `~/Downloads`).

- **Dark surface background is too dull (under-saturated) vs the mocks.** `--surface-grad-dark` (`assets/css/_color.css`) stops are very low chroma — `oklch(25.7% 0.006 286)` → `oklch(27.5% 0.009 286)` → `oklch(33.1% 0.022 259)`. The Figma dark bg reads more saturated. (Needs comparison against the mock's actual background values — fix TBD.)

- **"Product designer" weight exposes that the optical weight *system* is off.** The mock sets it at **wght 427**, which our optical curve produces at *neither* 2xl rung: 2xl **regular = 208**, 2xl **bold = 478** (derived from `flexaWeightConfig` in `assets/tailwind/configs/type-config.ts`, emitted to `assets/css/_type-tokens.generated.css`). So 427 falls *between* our regular and bold — confirmed not "bold" in our sense, and not our regular. The bold delta / the per-size weight mapping doesn't match the mock. **Needs a pass on the weight system** (the purpose of the size→weight mapping + the bold delta) using the `/weight-calibration` experiment page — fix TBD. The hero currently leaves "Product designer" at 2xl regular (208) as a placeholder.

- **Hero text-color tiers applied via an INTERIM raw `dusk-100` token — needs semantic naming + ladder re-seat.** Hero colors now: "Product designer" = **absolute white** (`text-callout`); TOKYO / SAN FRANCISCO = **dusk-000** (`text-main`); everything else (at / "Based in" / "& previously" / +15 body) = **dusk-100** (one rung down). To do the last tier at the system level (not inline) a raw `dusk-100` text color was added — `tailwind.config.ts` `textColor` + the typography `color="dusk-100"` (`typography_helpers.ex`). **Two follow-ups:** (1) `dusk-100` is a raw-ramp name in a semantic list — rename when the ladder is settled; (2) the text ladder still wants re-seating onto consecutive dusk rungs (`main`=dusk-000, `deemphasized`=dusk-400 skips dusk-100/200/300). Note the multi-context tension — *article* body wants dusk-000 (`main`), the *hero* supporting text wants dusk-100; the ladder must serve both.

- **"at" in "Product designer at [G]" is too big.** The tagline is `size="2xl"`, so "at" inherits 2xl. It should be **md** (matching "+15 years experience…"). **Do:** size the "at" run at md — mind the per-size optical weight (use the md weight token, not 2xl).

- **"Based in" and "& previously" should be md, not 1xl.** The cities line is `size="1xl"`, so the connective text renders at 1xl. Per the mock it should be **md** (same as "+15 years…"); only TOKYO / SAN FRANCISCO carry the larger/emphasis size. **Do:** set the connective to md, keep the city spans at their intended size.

- **TOKYO / SAN FRANCISCO — verify letter-spacing and true-vs-faux bold.** Cities use `font-cardinal-fruit uppercase font-bold tracking-[0.02em]`. **Check:** (a) is `tracking-[0.02em]` the mock's letter-spacing? (b) Is `font-bold` rendering the **true** Cardinal Fruit 700 face (`cardinal-fruit-bold.woff2`, `assets/css/_fontface.generated.css`) or a **faux/synthetic** bold / no bold? `font-synthesis: none` is global (`assets/css/app.css`) so synthesis should be off — confirm the 700 face is actually loaded and applied, not silently falling back to the 400 face. Inspect computed `font-weight` + the resolved face.

- **Footer "(PDF)" vs "Resume" color — re-verify against the mock.** The "(PDF)" suffix now uses `.footer-muted` = `--neutral-25` (`bededc5` repointed it off `--text-color-suppressed`, resolving the token-model dependency this item was waiting on). Confirm the de-emphasis now reads right visually: "(PDF)" should recede from the "Resume" link (`.footer-eyebrow` = `--neutral-50`) — i.e. `--neutral-25` sits one quiet rung below `--neutral-50`, which is the intended relationship. Close this item once checked against the mock.

- **`--neutral-25` footer text fails WCAG AA in BOTH themes — measured.** (Codex flag + RCA, 2026-07-01.) `--neutral-25` backs the footer's quiet text roles — the spec-sheet label rail (`.spec-sheet-row dt`), the copyright (`.footer-copyright`), and the "(PDF)"/"Now in Tokyo" muted text (`.footer-muted`) — at ~13-15px, which needs **≥4.5:1**. Measured against each footer surface: **dark = 2.84:1 (worst)**, **light = 3.53:1** (AA-large only). For reference `--neutral-50` on light is 6.82:1. Note this is a *palette-value* bug, not a theming bug — both themes re-seat correctly, the values themselves are just too quiet. **Do not** reflexively repoint these roles at `--neutral-50` (that flattens the deliberate quiet-vs-emphasis hierarchy the mock wants); instead darken/lighten `--neutral-25` per theme until it clears 4.5:1 while staying visibly below `--neutral-50`. Check the mock's intended contrast first — if the mock itself is sub-AA, that's a design decision to raise, not silently "fix".

---

## How this file gets updated

- Keep only stable repository rules, acceptance gates, durable pointers, and
  the canonical backlog here.
- Put accepted architectural decisions in `_PROJECT_DOCS/adrs/`, dated status
  in the appropriate `_PROJECT_DOCS/` working record, and tactical evidence in
  `.tmp/` until it earns a durable home.
- Keep this public-shaped per `~/.agents/AGENTS.md` §10. PII goes to the vault,
  not here.
