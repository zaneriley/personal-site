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
  passed route probes, but failed the checked-in page budgets. Locally available
  production fonts alone shipped 481,525 bytes against a 100,000-byte route
  budget, with related HTML and request-count overruns. Fix delivery/weight; do
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
  `font-trim-spec.md`; preserve the browser-measured fallback metrics from
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
