# Project documents

Use this directory for durable product and architecture knowledge. Start from
the lifecycle group that matches the question; do not treat every plausible
Markdown file as current implementation truth.

## Current contracts

- [content-authoring-contract.md](content-authoring-contract.md) — fields and
  syntax the separate content repository may publish.
- [feeds-spec.md](feeds-spec.md) — feed taxonomy, URLs, entry mapping, and
  acceptance criteria.
- [../ci/README.md](../ci/README.md) — CI/deploy code ownership, public command
  surface, and generated artifact paths.

## Accepted decisions

Accepted ADRs live in [adrs/](adrs/). Their status headers are authoritative;
change an accepted direction through a successor ADR rather than silently
rewriting history.

- [0001-prod-build-ci-gate.md](adrs/0001-prod-build-ci-gate.md)
- [0002-keep-liveview-for-app-like-page-transitions.md](adrs/0002-keep-liveview-for-app-like-page-transitions.md)
- [0003-use-digitalocean-as-interim-origin-substrate.md](adrs/0003-use-digitalocean-as-interim-origin-substrate.md)
- [0004-font-subsetting-and-delivery-pipeline.md](adrs/0004-font-subsetting-and-delivery-pipeline.md)
- [0005-publish-time-syntax-highlighting.md](adrs/0005-publish-time-syntax-highlighting.md)

## Working status

- [deploy-ops-status-plan.md](deploy-ops-status-plan.md) — dated deploy/content/
  origin working record. Verify its claims against current code and Git history
  before using them as present state.

Working status is not an architectural decision and should not be copied into
`AGENTS.md`. Tactical evidence remains under `.tmp/` until it becomes a durable
contract or accepted decision.

## Historical design sketches

These files explain how the current Markdown system evolved. They are not the
current source of truth and their unchecked TODOs are not the canonical backlog.

- [ast_plan.md](ast_plan.md) — superseded runtime AST-to-HEEx proposal.
- [ex_doc_markdown.md](ex_doc_markdown.md) — partially stale Markdown pipeline
  orientation.
- [todo1.md](todo1.md) — old two-phase rendering implementation plan.
- [2026-revival-todo.md](2026-revival-todo.md) — archived 2026 revival ledger;
  no longer the source of current status or backlog.

For shipped Markdown behavior, start with
`lib/portfolio/content/entry/compiler.ex`,
`lib/portfolio/content/markdown/renderer.ex`, their tests, and ADR 0005.
