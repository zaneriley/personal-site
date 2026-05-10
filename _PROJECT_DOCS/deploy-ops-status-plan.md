# Deploy / ops status and plan

**Updated:** 2026-05-08.

This is the working plan for Phase 3 after the production-build gate landed. It is not an ADR: it records status, sequencing, and what "done" should feel like from Z's DX.

## Current status

- `main` is current; the exact release tag is tracked by `.release-please-manifest.json` and GitHub Releases, not duplicated here.
- Branch protection requires `Workflow lint`, `Gate integrity`, `Compile`, `Lint`, `Security check`, `Test`, `Static analysis`, `gitleaks`, and `Prod build`.
- `Prod build` runs on PRs, pushes to `main`, nightly schedule, and manual dispatch. It builds the prod image, runs migrations up/down/up, boots the release, waits for `/readyz`, probes canonical routes, runs release RPC introspection, compares perf data, and uploads measurements.
- Release Please is automated enough for this pre-1.0 portfolio: `feat`, `fix`, and `perf` commits open release PRs, auto-merge waits on required gates, and release creation builds/pushes tagged images. Docs, CI, and chores do not bump versions.
- Content deployability is still partial, but app-side webhook promotion now exists. The webhook path validates the expected repo/ref/`after` SHA, syncs the local content clone to that exact commit, promotes changed Markdown transactionally, rejects bad content without mutating live DB state, treats deleted Markdown as unpublish, and persists optional share-preview frontmatter.
- Content `main` is the intended publish boundary, once content-repo CI validates the same schema/renderability rules before merge. "Bad content" means content the app cannot parse, validate into the content schema, compile into its Markdown/component model, or render safely enough to promote.
- Content-repo CI is the authoring front door, not a standalone YAML exercise. A content PR should check out the portfolio app at a known validator ref, print both the content commit and app validator commit, run the content repo's canonical `./run ci:validate /path/to/personal-site`, and fail with author-usable file/reason output before bad Markdown can reach production. Local hooks should block or warn on unencrypted `is_draft: true` Markdown before push, but hooks are convenience guardrails; CI is the enforceable boundary that makes the content repo safe to make public without exposing drafts.
- Deleted Markdown should unpublish content. The SEO/user-facing behavior for previously indexed URLs is still open: the code now removes DB entries; a tombstone/redirect/410 policy still needs design.
- Boot still pulls content via `Portfolio.Release.pull_repository/0`, but boot/startup does not yet have explicit last-good content behavior or a content-SHA ledger.
- Origin deploy does not exist yet. There is a release image, but no selected origin, blue/green mechanism, live smoke, or rollback command.
- Observability exists only as CI/deployability evidence. Runtime metrics/logs/alerts and auto-cancel-on-spike are not designed yet.
- The configured content repo URL currently points at `personal-site-content`; earlier planning notes may call the separate content repo `personal-website-content`.

## Content Deployability DX

Adversarial check: #1 succeeds only if it makes content publishing trustworthy. Git sync is plumbing; it does not count by itself. The publish path must preserve last-good live content, name the currently served content commit, reject bad content with a useful reason, and support content-only rollback.

Desired DX: edit content, run local content checks if useful, commit, push, then read a clear verdict: accepted and live, rejected with a parse/validation error, or ignored because no publishable content changed. No SSH, no container restart, no DB poking, no "did the watcher notice?" uncertainty.

The complete authoring loop has two checks. Before merge, content-repo CI proves "this tree can publish" using the app's validator and blocks unencrypted drafts. After merge to content `main`, the production webhook proves "this commit did publish, was rejected, or was ignored" using the app's durable verdict path.

Implemented app-side slice:

1. Validate signed GitHub push payloads against the expected repo, branch, and `after` SHA.
2. Sync the local content clone to the exact accepted SHA, not just floating `origin/main`.
3. Parse and ingest the relevant Markdown files through an explicit service path.
4. Roll back the DB transaction when parsing, schema validation, Markdown compilation, or promotion fails.
5. Treat removed Markdown as unpublish instead of leaving stale live entries behind.
6. Persist optional share-preview frontmatter on notes and case studies. The current app stores explicit fields only; rendered metadata and share-image generation are still future work.

### Share Preview Authorship

Author in Obsidian against the `personal-site-content` repo. The content repo owns explicit fields. The portfolio app owns image templates, generation, routing, metadata rendering, and validation.

The field contract lives in `_PROJECT_DOCS/content-authoring-contract.md`. Use `share_*` fields in content frontmatter. Do not author Open Graph or Twitter protocol fields directly in Markdown.

Plain flow: write the Markdown in Obsidian, fill the share-preview fields only when the default title/introduction is not enough or when you want to leave editorial notes for a future share image, commit to the content repo, push, and let the content pipeline validate/promote the commit. The current app stores those fields; later slices add local preview, generated share-image output, rendered metadata tags, and content-repo CI for the same contract.

Remaining implementation slice:

1. Dedupe deliveries by content commit SHA.
2. Acquire one content-sync lock so concurrent webhook deliveries cannot interleave.
3. Record accepted/rejected content SHA and reason.
4. Keep serving the previous known-good content if boot-time sync or parsing fails.
5. Add content-repo CI so a merge to content `main` validates draft safety, schema, compilation, and renderability before the production webhook ever sees it.
6. Add share-image generation, local preview, rendered Open Graph/Twitter metadata, and production validation for generated image URLs/dimensions.
7. Decide the deleted-URL SEO behavior: hard 404, 410, redirect, or tombstone page.

Done for this sub-phase means the app can answer four questions without fresh human reasoning: what content commit is live, what content commit was last rejected and why, what commit was last known-good, and how to return to it.

Known risks to address in that slice:

- Boot-time content pull can prevent the container from starting if GitHub or auth fails.
- Private repo auth is configured but not wired into the git clone/fetch path.
- Delivery dedupe and sync locking do not exist yet.
- Accepted/rejected content SHA is not persisted yet.
- Content-repo CI does not exist yet.
- Share-preview frontmatter is persisted, but share-image generation, preview UI, rendered metadata, and production smoke assertions do not exist yet.

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
