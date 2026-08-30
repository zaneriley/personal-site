# ADR 0003 — Use DigitalOcean as the interim origin substrate

**Status:** accepted 2026-05-16.
**Supersedes:** none.
**Superseded by:** none.

## Context

The deploy work needs a real substrate before self-hosting is ready. The app is
still in active product and deploy-loop development, and the current priority is
to make deploys boring before moving the runtime onto owned hardware.

The throwaway VPS literature pass is complete, and the first DigitalOcean 1 GiB
runtime proof showed the app and Postgres can run on the smallest honest Droplet
shape. The same proof also showed the origin must consume prebuilt image digests;
building the app on the 1 GiB host is not viable.

## Decision

DigitalOcean is the interim origin/deploy substrate until the app and deploy loop
are done enough to revisit self-hosting deliberately.

This does not make every DigitalOcean Droplet a production origin. The current
`disposable host` commands still create short-lived hosts for proof and
measurement. The preview wrapper promotes that host/runtime proof into one
private-preview result: candidate app image digest, disposable host, runtime
viability, preview page acceptance, and preview deploy receipt. A manual GitHub
Actions workflow validates a PR SHA on the default branch, builds that candidate
image, and runs the preview path.

**Implementation update, 2026-05-18:** repeated real-PR/host preview proofs
passed, including content-publication rehearsal and default destroy. Current
work is promotion of the same proven digest/content shape to an interim origin,
with live smoke, receipts, and rollback. See `_PROJECT_DOCS/BACKLOG.md`.

Self-hosting remains the likely long-term direction, but it is parked until the
application, content flow, deploy receipts, rollback, browser proof, and
operational loop are boring on DigitalOcean.

## Consequences

- Do not keep reopening provider choice while implementing the deploy loop.
- Do not add provider-neutral abstractions until DigitalOcean has enough real
  deploy surface to prove what abstraction is needed.
- Preserve the proven GitHub Actions preview path while adding the
  DigitalOcean-specific hardening that now earns rent: host janitor, SSH login
  path, firewall/IPv6 decision, rollback proof, and promotion flow.
- Continue treating AWS/S3/CloudFront as the live fallback until the DigitalOcean
  path has preview proof, rollback proof, and SEO-safe cutover work.
- Revisit owned hardware/self-hosting after the app is done enough that moving
  substrate is an optimization, not another source of uncertainty.
