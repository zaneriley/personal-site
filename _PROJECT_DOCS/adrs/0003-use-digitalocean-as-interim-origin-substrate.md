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
measurement. The next deploy work should promote the DigitalOcean path from
host/runtime proof toward a real preview lane and then an interim production
origin.

Self-hosting remains the likely long-term direction, but it is parked until the
application, content flow, deploy receipts, rollback, browser proof, and
operational loop are boring on DigitalOcean.

## Consequences

- Do not keep reopening provider choice while implementing the deploy loop.
- Do not add provider-neutral abstractions until DigitalOcean has enough real
  deploy surface to prove what abstraction is needed.
- Do add the DigitalOcean-specific hardening that now earns rent: deploy receipt,
  host janitor, key handling, firewall/IPv6 decision, rollback proof, and
  promotion flow.
- Continue treating AWS/S3/CloudFront as the live fallback until the DigitalOcean
  path has preview proof, rollback proof, and SEO-safe cutover work.
- Revisit owned hardware/self-hosting after the app is done enough that moving
  substrate is an optimization, not another source of uncertainty.
