# Backlog

This is the canonical index of known work in this repository. It records open
outcomes, not shipped-history narration. Verify implementation details against
current code and tests before starting a slice. Accepted architectural changes
belong in `adrs/`; tactical evidence belongs in `.tmp/`.

The private vault read-view and scratch area is
`~/repos/obsidian-notes/Backlog/side-projects/portfolio/`.

## Release and dependency blockers

- **Bring `./run ci:release` back inside its public-page budgets.** The
  2026-08-02 local release proof built the image, ran migrations, booted, and
  passed route probes, but failed the checked-in page budgets. Fonts shipped
  481,525 bytes against a 100,000-byte route budget. The same run also failed on
  a 574,227-byte hero photograph, uncompressed HTML, request count, and the
  live-page connection — originally summarised here as "related overruns," which
  hid the largest single item. See **Page weight** below for each one measured
  separately, and `page-weight.md` for the numbers. Fix delivery and weight; do
  not raise budgets to make the gate green.
- **Upgrade audited dependencies in a compatibility-focused slice.** The
  2026-08-02 audit found available Hex and JavaScript updates, advisories across
  the HTTP/Phoenix/PostgreSQL dependency surface, and retired `earmark` usage.
  Re-run `./run dev:deps:outdated` and the repository's audit commands before
  scoping; do not mix this migration into unrelated feature work.
- **Ship licensed production fonts through an explicit private mechanism.** The
  source faces and generated woff2 files are intentionally gitignored, so a
  clean checkout cannot assemble them. Choose an authenticated build-time fetch,
  private artifact, or other explicit delivery path before launch.

## Page weight

Measured 2026-08-29. Full numbers, method, and the checks that prove a change
did not alter the design are in `page-weight.md`. Work top to bottom: each item
below is ordered by bytes saved per unit of effort.

- **Turn on compression for pages the app renders.** The server sends every
  HTML page uncompressed. `Plug.Static` has `gzip: true`, but that setting only
  serves already-compressed copies of *static files* (CSS, JavaScript, fonts) —
  it does nothing for pages Phoenix renders on the fly. Cowboy, the web server,
  does not compress anything unless told to. Measured on `/en`: 70,225 bytes
  sent, 12,338 bytes if compressed — 82% smaller. This is the largest saving
  available on the site and it is a few lines of configuration. Turn it on,
  then re-measure; `html_bytes` should drop from 52,658 to roughly 12,000 and
  land under its 30,000 budget.
- **Turn on compression for the live-page connection too.** The `socket "/live"`
  declaration in `endpoint.ex` has no compression option, and the running page
  sends 33,404 bytes over that connection against a 20,000 budget. LiveView
  supports compressing this; it is one flag. Measure before and after — the
  saving is unverified.
- **Done 2026-08-29: re-encoded the draft hero photograph.** Was 574,227 bytes
  at 468×714 — 13.75 bits per pixel, where a normal web photograph is about 2.
  The dimensions were always right (468 pixels suits a 240-pixel slot on a
  high-resolution screen); it had simply been exported at near-maximum quality.
  Re-encoded at quality 82 with mozjpeg and progressive scan: **69,505 bytes,
  1.66 bits per pixel, an 88% reduction**, dimensions unchanged. `image_bytes`
  goes from 577,161 to about 73,000, under its 150,000 budget. The pristine
  574 KB original is recoverable from commit `16f3b25` if a different encoding
  is ever wanted; it was not kept in the working tree because this is a draft
  asset expected to be replaced, possibly by video.
- **Settled, do not re-investigate: SVGO has nothing left to give.** An earlier
  version of this entry claimed roughly 10,000 bytes were available by running
  SVGO over the signature wordmark. That was inferred from seeing decimal
  coordinates in the file and **it was wrong.** Measured 2026-08-29: the
  signature and all four logo files come back byte-identical, 0% saved. They are
  already at the configured precision. The signature is 13,771 bytes because the
  artwork contains that much path data, so reducing it means simplifying the
  drawing — a design decision, not an optimisation task.
- **Watch out: compression now hides the size of the markup.** The HTML document
  is 70,208 bytes, of which 26,850 is inline SVG and 42,681 is tags and class
  attributes wrapping only 12,334 bytes of visible text. None of that changed;
  it is simply compressed on the way out, so `html_bytes` reads 28,912 and
  passes its budget. Do not read a green `html_bytes` as "the markup is fine."
  If markup weight is worth attacking later, measure the uncompressed document,
  because the budget no longer will.
- **Decide what the site is willing to ship, then set the budgets to match.**
  After the items above, fonts are the only measurement still over budget:
  roughly 372,100 bytes against 100,000. Two facts make this a decision rather
  than a task. First, five custom typefaces cannot fit a 100,000-byte font
  budget without either dropping a typeface from the home page or cutting the
  display faces down to only the characters they actually use. Second, the
  contract in `ci/contracts/routes.json` cannot be satisfied as written — the
  whole-page budget (88,000 bytes) is smaller than the font budget alone
  (100,000). Pick the design you want, then write budgets that describe it.
  This is ADR-shaped work; do not quietly raise a number to get a green run.
- **Settled, do not re-investigate: the JavaScript is not a problem.** The
  built file is 345,021 bytes during development, but that version is
  unminified and carries a source map. What ships is 156,669 bytes minified and
  **48,931 bytes compressed**, against a 60,000 budget — already passing, which
  is why `js_bytes` has never appeared in a failure list. Of the minified code,
  92.5% is the Phoenix and LiveView framework itself (LiveView alone is 78%);
  code written for this site totals about 7.5 KB. There is no meaningful saving
  here that does not mean abandoning LiveView, which is ADR 0002's separate and
  unratified question.

## Asset handling and regression checks

- **Give images the same treatment fonts already have.** Fonts have a generator
  (`assets/fonts/generate-fonts.mjs`), a command (`./run assets:fonts`), and a
  place for original files (`assets/fonts/src/`). Images have none of these —
  `assets/static/images/` is a folder that files get dropped into, which is why
  an unoptimized draft shipped. Add `./run assets:images` following the same
  shape: original files in `assets/images/src/`, never modified; generated files
  written to `assets/static/images/`. Use `sharp`. Research conclusions, so this
  does not need re-deciding: produce AVIF with a JPEG fallback and skip WebP
  entirely (WebP now serves about 1.5% of visitors that AVIF does not); put a
  hash of the original file plus the encoding settings into the output filename
  so "does this file already exist" is the entire staleness check, with no
  separate record to keep in sync; do not generate a ladder of widths yet — one
  double-resolution copy per image, and three only for the single largest image
  on a page. Never re-compress an image in place: compressing an
  already-compressed photograph degrades it a little more each time, which is
  also why automatic image-compressing bots were rejected.
- **Expose the SVG optimizer as a command.** `assets/svgo.config.js` and the
  `svg:optimize` script already exist but are only reachable through yarn, so
  they are not in `./run`'s list and effectively invisible. Add
  `./run assets:svg` alongside `assets:fonts`.
- **Add a size check that runs before a commit is made.** Nothing in this
  repository measures asset weight until a push triggers a four-minute build in
  CI, so an oversized file can sit on a local branch indefinitely — which is
  exactly what happened: the photograph was committed 2026-06-05 and first
  measured 2026-08-29. Add a check on files being committed that computes bits
  per pixel (file size divided by pixel count) and fails above roughly 4, plus a
  plain size ceiling. The photograph is 13.75; every other image in the
  repository is under 0.18, so a single threshold catches it and nothing else.
  It must run in well under a second and must not need Docker, or it will be
  bypassed. **The message must contain the fix, not just the complaint.** In a
  1,470-developer study, people preferred a worse-written error message that
  told them how to fix the problem over a better-written one that did not, and
  the effect was statistically significant. So: name the file, give the numbers,
  and print the exact command to run.
- **Rejected, do not re-propose: writing measured page weights into a committed
  file.** The idea is that a weight change would then show up as a line in the
  diff you are already reading. It is appealing and it does not last. React
  adopted exactly this in 2017 and deleted it in 2019; MUI adopted it in 2018
  and deleted it in 2019. Both hit the same two problems: the file causes merge
  conflicts, and nothing forces it to be updated, so it goes stale and CI ends
  up comparing against a number a human typed. The pattern that *does* survive
  in the wild — API signature files, lock files — works because it records a
  contract that only changes when the contract changes. Page weight is a
  continuous measurement that legitimately changes on almost every commit, which
  is the case that gets abandoned. The check-before-commit item above solves the
  same problem without a file to maintain.
- **Fix or delete the pre-push hook.** `.lefthook.yml` ends its push checks with
  `|| echo "Checks failed, but push will proceed."`, so the hook cannot fail no
  matter what it finds. Separately, `.git/hooks/` is empty — lefthook was never
  installed on this machine, so none of it runs at all. A check that always
  passes is worse than no check, because it occupies the place where a real one
  would go.
- **Record accepted budget failures with an expiry date.** `routes.json` has an
  `exceptions` list that has never been used. While fonts are knowingly over
  budget, the gate fails on every single run, which trains you to ignore it —
  that is how the photograph's failure got summarised away as "related
  overruns" in this file's own release-blocker entry. Put the font overrun in
  `exceptions` with the observed number, the reason, and a date. Make the gate
  pass on a recorded exception, but fail if the number grows or the date passes.
  Then a red run means something new is wrong.
- **Fix what CI measures before trusting it.** Font files are deliberately not
  committed, so a CI checkout has none and all five requests return 404. CI
  therefore reports `font_bytes: 0` and undercounts total page weight by 42–80%
  on every route. It happens to fail today only because those 404s trip
  unrelated checks. When the font delivery item above is finished, those
  failures disappear and the font budget will start being enforced for the
  first time — expect the gate to appear to "newly break" on something that was
  always true.
- **Protect the performance gate from being quietly weakened.**
  `bin/ci/acceptance-gate-bypass-check` keeps a list of gates that cannot be
  narrowed or removed without failing. `ci:prod-build` and
  `ci:performance-browser` are not in it. One-line addition; the test fixtures
  already exist.
- **List the `assets:` commands in `./run help`.** `assets:fonts` and
  `assets:font-metrics` exist but appear in no section of the help menu, so
  neither is discoverable without reading the script.

## Deploy, origin, and operations

- **Promote the proven private-preview path into an interim DigitalOcean
  origin.** ADR 0003 locks the provider direction. Promotion must consume the
  same digest proven in preview, record an app/content receipt, perform live
  smoke, and support rollback; do not reopen provider choice or add a
  provider-neutral abstraction.
- **Finish preview/origin safety proof.** Observe manual destroy for one
  intentionally preserved preview; measure repeated-request runtime load on the
  1 GiB app-plus-Postgres host; abort wrong-origin network requests before they
  leave browser verification; prevent raw runtime logs from exposing generated
  secret names or values; replace or rotate the long-lived preview SSH key; and
  make the IPv6 firewall decision explicit.
- **Design observability and rollback from deploy evidence.** Required signals
  include request health, release identity, content SHA/generation, BEAM/runtime
  health, the database boundary, publication outcomes, and the edge/origin split.
  Decide telemetry egress, notifications, budget, network access, and key
  management before choosing tooling. The repository-wide literature-first and
  no-Grafana constraints remain in `AGENTS.md`.
- **Measure before revisiting self-hosting or a CDN.** Capture time-to-ready,
  cold-first response, warm p50/p95, memory, CPU, cacheability, and power where
  available. Visitor speed and rollback reliability are the floor; compute per
  watt breaks ties only after the user experience is sound.

## Content publication

- **Complete the production content-main loop.** The app and content-repository
  preflight paths can produce accepted/rejected/ignored verdicts; the real
  content `main` webhook still needs a durable origin to prove which commit went
  live while preserving last-good content.
- **Generate and validate share images.** The authoring contract and explicit
  frontmatter fields exist; template generation, rendering, metadata wiring,
  and publish-time validation remain.
- **Make `figure.ex` work through the stored Markdown pipeline.** The component
  is registered but accepts only HEEx-shaped assigns, while the renderer invokes
  registered components with string-keyed `attrs`. Add the pipeline-shaped
  clause and pin it with a compile → serialize → render test like the code-block
  coverage.
- **Finish the code-block presentation slice.** Add the LiveView-safe copy and
  scrim/expand hook, add the Typography mono variant backed by `--font-mono`,
  and tune category-to-color mappings in situ without moving tokenization onto
  the request path or into the browser.
- Feed-specific follow-ups remain in `feeds-spec.md` under **Open items**.

## Design and interaction passes

- **Repair the grid mobile-first across the site.** Base placement is missing
  on several 12-column layouts, and nav/main/footer do not share one constrained
  container. Define base stacking and align all three surfaces through the
  existing grid tokens.
- **Bring the footer spec sheets back to the mock.** Revisit padding,
  proportions, border/inset treatment, status-dot placement, narrow wrapping,
  and label-column width. Load GT Flexa Mono or choose a deliberate substitute.
  Archive the transient `~/Downloads/Footer.{png,svg}` reference before using it
  as acceptance evidence.
- **Define interactive-state tokens.** Links, buttons, tap targets, and
  hover/active/focus-visible/visited states need a consistent contract that
  works across both OKLCH theme ramps. Preserve a 44px minimum target and a
  visible focus ring.
- **Adjudicate the proposed app-like motion direction.** ADR 0002 is not
  ratified. Before implementation, finish nonessential-JS attribution and
  compression work; then decide whether a measured one-route-pair
  `onDocumentPatch` View Transition spike should proceed.
- **Replace display-only footer status with owned live data.** Give temperature,
  deploy identity/status, node health, operating cost, and Tokyo weather bounded
  cached owners while retaining explicit assigns for deterministic tests and
  degraded operation.
- **Decide navigation taxonomy before launch.** `Case Studies`/`Self` versus
  `Work`/`About` affects labels, routes, SEO redirects, locale slugs, modules,
  and content types. Because robots currently disallow indexing, a route change
  is cheapest before launch; do not make a label-only partial rename.
- **Stop shipping the design sketch pages to visitors.** The router scope
  holding `/weight-calibration`, `/color-tokens`, `/code-block`, `/hdr-lab`,
  `/color-sketch`, `/shader-scale-sketch`, `/palette-comparison`, and
  `/dark-background-sketch` has no development-only guard, so all of them are
  reachable in production. Decide whether to guard them by environment or keep
  them deliberately public; do not leave it accidental.
- **Route the hero image through a component instead of a bare tag.** The
  portrait in `home_live.ex` is a hand-written `<img>` with a TODO on it, so it
  gets none of the shared handling. Note that `image.ex` is currently two things
  at once: it describes itself as a general-purpose image primitive, and it is
  also registered as a Markdown component for images inside written content.
  Page furniture and article images are different callers; decide whether they
  should share one component before wiring the hero into it.
- **Add the two characters that currently fall back to a system font.** The
  subset built into the web fonts covers Latin plus common punctuation and
  arrows, but misses `⧉` (the copy button on code blocks,
  `lib/portfolio_web/components/code_block.ex`) and `≺` `≻` (the error pages).
  Both render today in whatever font the visitor's device supplies. Either add
  them to the character set in `assets/fonts/generate-fonts.mjs` or replace them
  with characters already covered.

## Typography, color, and font pipeline

- **Fix dark-footer `--neutral-25` contrast and adjudicate the light edge.** The
  dark footer remains 2.84:1 at small text. Commit `57c86fd` moved light from
  3.53:1 to the measured mock value, 4.49:1—effectively on, but fractionally
  below, the 4.5:1 AA threshold. Preserve a visible quiet tier below
  `--neutral-50`; do not flatten both roles by aliasing them.
- **Complete the mock-fidelity type/color pass.** Recheck the dark-surface
  chroma, the hero's semantic text ladder, optical weight mapping, connective
  text sizes, city letter spacing and real 700 face, and footer muted/emphasis
  relationship against archived mocks.
- **Instance and axis-trim variable faces before launch.** GT Flexa currently
  ships the full weight range plus unused width and italic axes. Predictions,
  phased levers, and the must-not-move verification contract are ratified in
  `page-weight.md`; preserve the browser-measured fallback metrics from
  ADR 0004.
- **Consolidate font generation under `assets/fonts/`.** The subsetting/
  `@font-face` generator and typography-metric pipeline share source faces but
  live in separate homes. Move toward one source-oriented pipeline without
  regenerating known-bad fontkit measurements for display/variable faces.
- **Emit font preload data from the font pipeline.** The layout and generated
  `@font-face` output currently duplicate the critical face path. Move both the
  CSS link and preload to digested paths together so production cannot
  double-fetch.
- **Repair the remaining font-metrics command.** `assets:font-metrics` still
  relies on `ts-node` without its TypeScript peer. Use the already-available
  bundled execution shape when consolidating the pipeline.
