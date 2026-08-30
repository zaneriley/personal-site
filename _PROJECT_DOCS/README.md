# Project documents

Use this directory for current work, durable product contracts, and architecture
decision records. Code and tests own shipped implementation truth; Git
history owns deleted plans and completion ledgers.

## Current work

- [BACKLOG.md](BACKLOG.md) — canonical index of known work. Verify each item
  against current code and tests before starting it.
- [page-weight.md](page-weight.md) — page-weight measurements, settled
  reasoning, and the verification methods that prove a weight change did not
  alter the design. Companion to ADR 0006.
- [font-delivery-spec.md](font-delivery-spec.md) — plan and verification
  contract for delivering the licensed fonts to CI through a private
  repository; closes the CI-measures-fiction gap.

## Current contracts

- [content-authoring-contract.md](content-authoring-contract.md) — fields and
  syntax the separate content repository may publish.
- [feeds-spec.md](feeds-spec.md) — feed taxonomy, URLs, entry mapping, and
  acceptance criteria.
- [../ci/README.md](../ci/README.md) — CI/deploy code ownership, public command
  surface, and generated artifact paths.

## Decision records

ADRs live in [adrs/](adrs/). Their status headers are authoritative; proposed
records do not authorize implementation. Change an accepted direction through a
successor ADR rather than silently rewriting history.

- [0001-prod-build-ci-gate.md](adrs/0001-prod-build-ci-gate.md)
- [0003-use-digitalocean-as-interim-origin-substrate.md](adrs/0003-use-digitalocean-as-interim-origin-substrate.md)
- [0004-font-subsetting-and-delivery-pipeline.md](adrs/0004-font-subsetting-and-delivery-pipeline.md)
- [0005-publish-time-syntax-highlighting.md](adrs/0005-publish-time-syntax-highlighting.md)
- [0006-time-first-performance-contract.md](adrs/0006-time-first-performance-contract.md)
- [0002-keep-liveview-for-app-like-page-transitions.md](adrs/0002-keep-liveview-for-app-like-page-transitions.md)
  — proposed; awaiting ratification.

Tactical evidence and working plans remain under `.tmp/` until an outcome earns
a durable home here. For shipped Markdown behavior, start with
`lib/portfolio/content/entry/compiler.ex`,
`lib/portfolio/content/markdown/renderer.ex`, their tests, and ADR 0005.
