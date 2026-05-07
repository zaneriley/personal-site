# Deploy / ops status and plan

**Updated:** 2026-05-07.

This is the working plan for Phase 3 after the production-build gate landed. It is not an ADR: it records status, sequencing, and what "done" should feel like from Z's DX.

## Current status

- `main` is current; the exact release tag is tracked by `.release-please-manifest.json` and GitHub Releases, not duplicated here.
- Branch protection requires `Workflow lint`, `Gate integrity`, `Compile`, `Lint`, `Security check`, `Test`, `Static analysis`, `gitleaks`, and `Prod build`.
- `Prod build` runs on PRs, pushes to `main`, nightly schedule, and manual dispatch. It builds the prod image, runs migrations up/down/up, boots the release, waits for `/readyz`, probes canonical routes, runs release RPC introspection, compares perf data, and uploads measurements.
- Release Please is automated enough for this pre-1.0 portfolio: conventional commits open release PRs, auto-merge waits on required gates, and release creation builds/pushes tagged images.
- The content pipeline is still partial. Boot pulls content via `Portfolio.Release.pull_repository/0`; the webhook path triggers a git sync through `RemoteUpdateTrigger`, but content promotion is not a deterministic "sync exact commit, parse, record verdict" flow yet.
- Origin deploy does not exist yet. There is a release image, but no selected origin, blue/green mechanism, live smoke, or rollback command.
- Observability exists only as CI/deployability evidence. Runtime metrics/logs/alerts and auto-cancel-on-spike are not designed yet.
- The configured content repo URL currently points at `personal-site-content`; earlier planning notes may call the separate content repo `personal-website-content`.

## Next slice: content-pipeline DX

Desired DX: edit content, run local content checks if useful, commit, push, then read a clear verdict: accepted and live, rejected with a parse/validation error, or ignored because no publishable content changed. No SSH, no container restart, no DB poking, no "did the watcher notice?" uncertainty.

Smallest implementation slice:

1. Validate signed GitHub push payloads against the expected repo, branch, and `after` SHA.
2. Dedupe deliveries by content commit SHA.
3. Acquire one content-sync lock so concurrent webhook deliveries cannot interleave.
4. Sync the local content clone to the exact accepted SHA, not just floating `origin/main`.
5. Parse and ingest the relevant markdown files through an explicit service path.
6. Record accepted/rejected content SHA and reason.
7. Keep serving the previous known-good content if sync or parsing fails.

Known risks to address in that slice:

- Webhook relevance ignores deleted markdown files.
- Webhook sync currently returns success after git sync; it does not explicitly promote content.
- Boot-time content pull can prevent the container from starting if GitHub or auth fails.
- Private repo auth is configured but not wired into the git clone/fetch path.
- Tests should use local fixture git repos rather than real network URLs.
- Production frontmatter parsing needs review before content promotion becomes authoritative.

## Origin deploy philosophy

Do not choose hardware or ingress first. The order is measurement-led:

1. Make content sync safe enough that origin restarts do not depend on upstream GitHub availability.
2. Measure the app using the same vocabulary as `Prod build`: time-to-ready, cold-first response, warm p50/p95, memory, CPU, and power where available.
3. Reduce app cost before buying or assigning hardware.
4. Lock origin invariants before stack choice: immutable app image/release plus content SHA, runtime secrets, blue/green, pre-flip and post-flip smoke, one-command rollback, and content-only rollback.
5. Run `/literature` for origin substrate only after measurements exist.

Free/FLOSS and self-hostable tools are preferred when viable. They do not beat visitor speed, rollback reliability, or the "future-Z can reproduce this in a year" rule. Cloudflare Tunnel, Tailscale/tailnet paths, reverse proxy ingress, owned NUC/Mac/NAS hardware, and Pi-class hardware are candidates, not decisions.

## Observability and rollback planning

Minimum useful signal set:

- Request health: status counts, 5xx rate, latency p50/p95/p99, route, method, request id.
- Release identity: app version, git SHA/tag, image digest, content SHA, DB migration version.
- Runtime health: boot, supervised child restarts, crash exits, memory, scheduler/CPU pressure, process count.
- DB boundary: query failures, migration result, pool pressure if available.
- Content pipeline: webhook accepted/rejected, HMAC failure, delivery dedupe, sync result, promoted content SHA, last-good content SHA.
- Edge/origin split after CDN selection: cache hit/miss, stale responses, origin fallthrough, origin unreachable events.

Rollback should act on deploy evidence:

- Deploy promotes an immutable app/content pair, never `latest` by memory.
- Blue/green smokes the inactive color before traffic flip and the active color after traffic flip.
- Every deploy exercises rollback mechanics, even when it does not keep the rollback active.
- Auto-cancel belongs to the rollout window or the next rollout. It must not weaken CI gates or hide failures.
- Rollback has two scopes: app+content pair rollback and content-only rollback.

Open planning questions:

- Telemetry-leaving-box policy.
- Notification destination for red nightly/deploy events.
- Budget ceiling.
- Network rule: tailnet-only admin? public tunnel? direct reverse proxy?
- Key-management policy beyond existing `op://` conventions.
- Why exactly Grafana is vetoed: UI, vendor, dashboard burden, Prometheus-style ops, or something else.

## Node 20 actions cleanup

GitHub warned that Node 20 JavaScript actions move to Node 24 defaults on 2026-06-02 and lose Node 20 runner support on 2026-09-16. The workflows now use Node 24 action majors for the affected actions (`actions/checkout@v6`, `actions/upload-artifact@v7`, `googleapis/release-please-action@v5`), so no temporary runtime override is needed.
