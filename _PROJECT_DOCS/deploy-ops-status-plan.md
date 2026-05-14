# Deploy / ops status and plan

**Updated:** 2026-05-14.

This is the working plan for Phase 3 after the production-build gate landed. It is not an ADR: it records status, sequencing, and what "done" should feel like from Z's DX.

## Current status

- `main` is current; the exact release tag is tracked by `.release-please-manifest.json` and GitHub Releases, not duplicated here.
- Branch protection requires `Workflow lint`, `Gate integrity`, `Compile`, `Lint`, `Security check`, `Test`, `Static analysis`, `gitleaks`, and `Prod build`.
- `Prod build` runs on PRs, pushes to `main`, nightly schedule, and manual dispatch. It builds the prod image, runs migrations up/down/up, boots the release, waits for `/readyz`, probes canonical routes, runs release RPC introspection, compares perf data, and uploads measurements.
- Release Please is automated enough for this pre-1.0 portfolio: `feat`, `fix`, and `perf` commits open release PRs, auto-merge waits on required gates, and release creation builds/pushes tagged images. Docs, CI, and chores do not bump versions.
- Content deployability now has an app-side verdict path and a content-repo front door on the active branches. The webhook path validates the expected repo/ref/`after` SHA, syncs the local content clone to that exact commit, promotes changed Markdown transactionally, rejects bad content without moving the live generation, records accepted/rejected/ignored verdicts, and persists optional share-preview frontmatter.
- Content `main` is the intended publish boundary. Content-repo CI runs canonical wrapper commands: `./run ci:draft-safety /path/to/personal-site`, `./run ci:validate /path/to/personal-site`, and `./run ci:lint`. "Bad content" means content the app cannot parse, validate into the content schema, compile into its Markdown/component model, or render safely enough to promote.
- Content-repo CI is the authoring front door, not a standalone YAML exercise. It prints both the content commit and app validator commit, routes validation through the content repo's canonical `./run ci:validate /path/to/personal-site`, and fails with author-usable file/reason output before bad Markdown can reach production. Local hooks block unencrypted `is_draft: true` Markdown before push, but hooks are convenience guardrails; CI is the enforceable boundary that makes the content repo safe to make public without exposing drafts.
- Deleted and renamed Markdown now have separate policies. A deletion-only content change keeps the explicit hard-404 behavior. A mixed delete/add update must preserve each deleted live slug as either a canonical slug or an `aliases:` value in the new generation; otherwise the webhook rejects it with file/reason output. Valid aliases 301-redirect the old note/case-study slug to the canonical slug.
- Boot still pulls content via `Portfolio.Release.pull_repository/0`, but boot/startup now falls back to last-good content when a repository pull or embedded-content read fails and a live generation already exists.
- Content-only rollback now has a generation-aware operator command. `bin/content status` exposes live and last-good generation IDs; `bin/content rollback TARGET --reason REASON` records a rollback ledger event and flips the live generation without fetching Git or rolling back the app release. Ambiguous SHA targets fail with the matching generation IDs instead of guessing.
- Private content-repo auth is wired into clone/fetch through ephemeral Git command environment. HTTPS tokens use askpass, SSH can use `CONTENT_REPO_SSH_COMMAND`, tokenized `CONTENT_REPO_URL` values are rejected, and sync failures are redacted before they reach logs or ledger reasons.
- Origin deploy does not exist yet. There is a release image, but no selected origin, blue/green mechanism, live smoke, or rollback command.
- The first deploy-tooling literature pass is complete. Current planning bias is **GitHub Actions as deploy operator, Kamal as an ephemeral deploy-time adapter, and the origin as a Docker-only runtime**, but Kamal is not ratified. Literature artifacts: `.tmp/2026-05-11-deploy-preview-options/literature/` and `.tmp/2026-05-11-portfolio-deploy-tooling-deep-dive/literature/`.
- The disposable Docker-host spike has a manual GitHub Actions workflow and canonical `./run host:disposable:*` commands for DigitalOcean create/status/destroy. The GitHub `preview` environment exists and is limited to `main`; `DIGITALOCEAN_TOKEN`, `DEPLOY_SSH_PUBLIC_KEY`, and `DEPLOY_SSH_PRIVATE_KEY` are installed there. Local create/status/SSH/cloud-init/Docker/destroy proof passed on 2026-05-11 against a 1 GiB `sfo3` Droplet, then peer review found the first implementation was not lifecycle-safe enough. The scripts now write receipts as soon as a Droplet ID exists, destroy failed creates by default, require SSH/Docker/Compose readiness proof, bound the remote readiness wait, refuse arbitrary cost inputs, list disposable hosts by tag, and verify expected disposable tags/name before destroy. GitHub manual workflow proof is still blocked until the workflow file exists on the default branch, because GitHub does not expose new `workflow_dispatch` workflows from feature branches by filename.
- A simple preview deploy bug bash ran on 2026-05-12 and is recorded in `.tmp/2026-05-12-simple-preview-deploy-bugbash/report.md`. It proved the 1 GiB DO host is safe to create and destroy, but it also proved the host must be treated as a runtime, not a builder: an origin-side production image build OOM-killed BEAM while compiling `cowlib` after about 20 minutes. The next runtime spike must use a prebuilt image digest and measure app+Postgres runtime memory instead of rebuilding source on the origin.
- Observability exists only as CI/deployability evidence. Runtime metrics/logs/alerts and auto-cancel-on-spike are not designed yet.
- The configured content repo URL currently points at `personal-site-content`; earlier planning notes may call the separate content repo `personal-website-content`.

## Content Deployability DX

Adversarial check: #1 succeeds only if it makes content publishing trustworthy. Git sync is plumbing; it does not count by itself. The publish path must preserve last-good live content, name the currently served content commit, reject bad content with a useful reason, and support content-only rollback.

Desired DX: edit content, run local content checks if useful, commit, push, then read a clear verdict: accepted and live, rejected with a parse/validation error, or ignored because no publishable content changed. No SSH, no container restart, no DB poking, no "did the watcher notice?" uncertainty.

The complete authoring loop has two checks. Before merge, content-repo CI proves "this tree can publish" using the app's validator and blocks unencrypted drafts. After merge to content `main`, the production webhook proves "this commit did publish, was rejected, or was ignored" using the app's durable verdict path.

### Content Authoring Front-Door Done Criteria

This sub-phase is done when the authoring loop is trustworthy enough to use without babysitting it.

1. **Actionable, in-flow failure:** CI and webhook rejections must name the file path and specific field/reason, for example `notes/foo.md: missing title`. The output may use a stable error code or human-readable message, but it must include the path, the semantic reason, and the field name when field-specific. A generic parse error, 500, stacktrace, or "content validation failed" without a path/reason does not count.
2. **Draft safety guarantee:** A scripted adversarial test must prove that an unencrypted `is_draft: true` Markdown file is blocked by the local pre-push guardrail and by the content-repo CI gate. The helper command `./run check_unencrypted` proves the scanner; `lefthook run pre-push` proves hook wiring; content-repo CI must enforce the same rule through its canonical validation command.
3. **Atomic last-good resilience:** A bad content push must leave visitors on the previous known-good generation, record the bad content SHA as rejected in the persistent ledger, and never expose a partial generation. The normal proof should use author/operator surfaces such as `bin/content status`, the signed debug view, a secure diagnostic endpoint, structured deploy logs, and route probes; direct database queries are useful in automated tests but are not the DX path.
4. **Observability without SSH:** The current live content SHA, last known-good SHA, last rejected SHA, and last rejected reason must be visible through the author/operator surfaces: GitHub status/debug links, `bin/content status`, a secure diagnostic endpoint, or structured deployment logs. Reading server files or poking the database by hand is not an acceptable normal path.
5. **Local/CI parity:** The exact validation suite used by content-repo CI must be runnable locally through the content repo's `./run ci:validate /path/to/personal-site` command. The app-side equivalent is `./run ci:content-validate /path/to/personal-site-content`; these two command contracts must not be conflated.
6. **Signed debug access:** The private publication debug page must be reachable from the signed URL emitted in the GitHub status `target_url` and must render the path/reason for a rejected commit. Unsigned `/ops/content/publications/:id` requests must return 404.
7. **Webhook fixture parity:** Production-webhook acceptance tests must use a fixture or script that supplies the full GitHub webhook shape: `X-GitHub-Event`, `X-GitHub-Delivery`, JSON content type, expected repository/ref/after payload, and HMAC over the exact request body. Hand-written partial `curl` payloads are not enough to prove the contract.
8. **Deleted/renamed URL behavior:** Deleted and renamed Markdown need separate observable policies. A deletion-only content change is the explicit hard-404 policy. A mixed delete/add update must preserve deleted live URLs through the new generation's canonical `url` or `aliases:` frontmatter. Silent link breakage is not a fire-and-forget authoring loop.

Implemented app-side slice:

1. Validate signed GitHub push payloads against the expected repo, branch, and `after` SHA.
2. Sync the local content clone to the exact accepted SHA, not just floating `origin/main`.
3. Parse and ingest the relevant Markdown files through an explicit service path.
4. Keep failed remote generations diagnostically visible without moving the live pointer; local validator paths still roll back failed transactions so preflight leaves no DB residue.
5. Treat removed Markdown as unpublish instead of leaving stale live entries behind.
6. Persist optional share-preview frontmatter on notes and case studies. The current app stores explicit fields only; rendered metadata and share-image generation are still future work.
7. Roll content back by publication generation ID, or by content SHA only when that SHA maps to one rollback-capable generation.
8. Fetch private content repositories without embedding credentials in remotes, logs, ledger rows, or command arguments.

### Share Preview Authorship

Author in Obsidian against the `personal-site-content` repo. The content repo owns explicit fields. The portfolio app owns image templates, generation, routing, metadata rendering, and validation.

The field contract lives in `_PROJECT_DOCS/content-authoring-contract.md`. Use `share_*` fields in content frontmatter. Do not author Open Graph or Twitter protocol fields directly in Markdown.

Plain flow: write the Markdown in Obsidian, fill the share-preview fields only when the default title/introduction is not enough or when you want to leave editorial notes for a future share image, commit to the content repo, push, and let the content pipeline validate/promote the commit. The current app stores those fields; later slices add local preview, generated share-image output, rendered metadata tags, and production smoke checks for the same contract.

Completed in this authoring slice:

1. Dedupe deliveries by GitHub delivery ID while recording the content commit SHA.
2. Acquire one content-sync lock so concurrent webhook deliveries cannot interleave.
3. Record accepted/rejected content SHA and reason.
4. Keep serving the previous known-good content if boot-time sync or parsing fails.
5. Add content-repo CI so a merge to content `main` validates draft safety, schema, compilation, and renderability before the production webhook ever sees it.
6. Define deleted/renamed URL behavior: deletion-only changes hard-404; mixed delete/add updates must preserve deleted live URLs through canonical slugs or explicit `aliases:`, and aliases redirect renamed URLs with 301.

Remaining implementation slice:

1. Add share-image generation, local preview, rendered Open Graph/Twitter metadata, and production validation for generated image URLs/dimensions.

Done for this sub-phase means the app can answer four questions without fresh human reasoning: what content commit is live, what content commit was last rejected and why, what commit was last known-good, and how to return to it.

### Content Rollback and Private Auth Acceptance Matrix

This matrix applies to the #1 deployability tail only: content-only rollback and private content-repo auth. It is intentionally empirical. Passing it means the operator surfaces and durable state prove the behavior; it does not prescribe the internal implementation.

Rollback must be generation-aware. A content SHA is an author-friendly hint, not always a unique rollback identity.

1. **Ambiguous SHA trap:** If one content SHA maps to multiple accepted or rollback-capable publication generations, `bin/content rollback <sha> --reason "bad publish"` must exit nonzero, leave `PublicationState.live_content_sha` unchanged, create no rollback ledger row, and print enough information for the operator to choose a specific generation. The JSON form must expose a stable `ambiguous_content_sha` reason and the matching generation IDs.
2. **Durable rollback:** If Generation B is live and Generation A is an older known-good generation, `bin/content rollback <generation-a-id> --reason "recovery"` must exit zero, append a `PublicationLedgerEntry` with `status: "rollback"`, keep `last_accepted_content_sha` pointing at Generation B's accepted SHA, and point `live_content_publication_generation_id` at Generation A. After an app restart, `/readyz` must pass and a route whose content differs between A and B must serve Generation A's content. Rollback must still work when Git credentials or network access are unavailable, proving it does not secretly fetch or checkout content.
3. **Zero token leakage:** With `CONTENT_REPO_URL` set to a clean HTTPS or SSH URL and content-repo credentials supplied through the configured secret mechanism, failed sync logs, command output, ledger `repository` values, and failure `reason` values must not contain the raw token. A deliberately invalid token such as `BOGUS_TOKEN_123` must be absent from all captured app logs and database-backed diagnostic fields.
4. **Clean Git state:** After a successful private-repo sync, the local clone's `.git/config` must keep the remote URL clean. The configured token must not appear in the `remote.origin.url`, any persisted Git config value, or any app-owned status output. Auth must be ephemeral at clone/fetch time.

Known risks to address in that slice:

- Share-preview frontmatter is persisted, but share-image generation, preview UI, rendered metadata, and production smoke assertions do not exist yet.

## Origin deploy philosophy

Do not choose hardware or ingress first. The order is measurement-led:

1. Make content sync safe enough that origin restarts do not depend on upstream GitHub availability.
2. Measure the app using the same vocabulary as `Prod build`: time-to-ready, cold-first response, warm p50/p95, memory, CPU, and power where available.
3. Reduce app cost before buying or assigning hardware.
4. Lock origin invariants before stack choice: immutable app image/release plus content SHA, runtime secrets, blue/green, pre-flip and post-flip smoke, one-command rollback, and content-only rollback.
5. Run `/literature` for origin substrate only after measurements exist.

Free/FLOSS and self-hostable tools are preferred when viable. They do not beat visitor speed, rollback reliability, or the "future-Z can reproduce this in a year" rule. Cloudflare Tunnel, Tailscale/tailnet paths, reverse proxy ingress, owned NUC/Mac/NAS hardware, and Pi-class hardware are candidates, not decisions.

### Origin Deploy Service Design

This section is planning alignment, not a ratified tool choice.

The deploy target is a **portfolio origin**, not Kamal, GitHub, or a dashboard. The origin is the host/environment that runs the Phoenix release container behind the eventual edge/cache/access layer. Final hardware is still measurement-led: Pi-class hardware, a NUC, the Mac Studio, a small VPS, or another owned host remain candidates until resource-frugality data says what is honest.

Service boundary:

1. **GitHub Actions is the deploy operator.** It runs the deploy workflow in an ephemeral runner, installs or runs Kamal only for that job, builds or selects the release image, pushes/pulls registry artifacts, and emits deploy receipts.
2. **Kamal is a deploy-time adapter, not a domain.** It may SSH to the origin, start the candidate container, wait for health, switch `kamal-proxy`, retain old versions, and invoke rollback. It is not installed on Z's local machines and is not a Phoenix runtime dependency.
3. **The origin is a Docker runtime.** It needs SSH, Docker, a constrained deploy user, registry access, `kamal-proxy`, app containers, and the chosen tunnel/edge prerequisites. It should not need the Kamal CLI as its normal interface.
4. **The app repo owns the app deploy contract.** `personal-site` owns release-image creation, `/readyz` semantics, migrations, route smoke, browser/perf checks, content status, and the wrapper commands that make deploy behavior legible.
5. **The homelab substrate owns host readiness.** `automated-homelab-deployment` owns OS packages, Docker host setup, deploy users, SSH/firewall posture, tunnel daemon prerequisites, and secret plumbing for real machines.
6. **The content repo remains content input.** `personal-site-content` feeds content publication; it is not deploy infrastructure.

Domain language should stay tool-neutral: artifact, digest, preview, promote, live, previous, rollback, receipt, health gate, deploy lock. Kamal vocabulary belongs behind adapter/wrapper commands.

Ideal service flow:

1. A protected branch or manual dispatch asks for a candidate deploy.
2. GitHub Actions runs the canonical gates and builds or selects one immutable image digest.
3. GitHub Actions deploys that exact digest to a private preview lane.
4. Preview checks run against the private URL: `/readyz`, canonical routes, content status, browser/performance checks, and any release RPC assertions.
5. Z or a protected environment approval promotes that exact digest to production.
6. The deploy adapter starts the candidate container on the origin, waits for truthful health, flips traffic, and post-smokes the live URL.
7. The workflow emits a receipt: live digest, previous digest, app SHA/tag, content SHA/generation, DB migration version, route/perf verdict, and exact rollback command.
8. Failures leave the old production version live and explain the blocking reason without SSH, DB poking, or reading raw server files.

### Origin Deploy Ideal UX Criteria

Origin deploy is not done until these are true from Z's and an LLM agent's perspective:

1. **No local Kamal install required:** Z can deploy from GitHub Actions alone. Local machines may use `gh` to trigger or inspect workflows, but Kamal itself runs ephemerally in CI or an explicit deploy runner.
2. **Private preview before production:** Every production candidate has a private, prod-like preview URL that can be tested from another machine without exposing unfinished design publicly.
3. **Same-artifact promotion:** The previewed image digest is exactly the digest promoted to production. Branch names, floating tags, or rebuilds that merely recreate a similar image do not count.
4. **Manual production approval until proven safe:** Automatic work can build and update preview. Production promotion should require a protected environment/manual action until rollback, smoke, and observability are boring.
5. **Truthful health gates:** The inactive candidate must pass readiness before traffic flips, and the active production URL must pass live smoke after traffic flips. Generic container-running status is not enough.
6. **Old version stays live on failure:** If build, migration, readiness, route smoke, browser smoke, or promotion fails, visitors stay on the previously live app/content pair.
7. **One-command rollback:** A receipt names the previous version and an executable rollback command. Rollback targets an app image digest/content generation pair, not `latest` or "whatever was before" by memory.
8. **Deploy receipts over dashboards:** The primary surface is GitHub checks/log summaries plus `bin/deploy status`-style output. A UI is optional and only useful if it reduces uncertainty.
9. **No secret leakage:** Deploy credentials and app secrets must not appear in image metadata, Git remotes, command lines, logs, deploy receipts, or app diagnostic output. Preview and production secrets are scoped separately.
10. **Deploy serialization is explicit:** Concurrent deploy attempts must be queued, rejected, or visibly blocked by a deploy lock. Silent races are a failure.
11. **Edge/cache behavior is named:** When an edge layer exists, deploy smoke must say whether it tested preview, origin, cached production, stale cache, or first-fill origin behavior.
12. **LLM-friendly failure output:** Failures must name the stage, artifact, route/check, observed value, expected value, artifact path, and likely next action. "Kamal failed" or "deploy failed" is too vague.

### Kamal-Specific Questions Before Ratification

The next implementation/design spike should answer these empirically:

1. Can GitHub Actions run Kamal without requiring Kamal on Z's machines?
2. Can preview and production destinations use the same image digest while keeping separate runtime config and access policy?
3. What exact files can be public in `personal-site`, and what host/secret/topology values must live in private homelab/vault configuration?
4. How does rollback behave after image/container pruning, an origin restart, and a registry outage?
5. How clear is the failure output when `/readyz` fails, SSH fails, registry auth fails, a deploy lock is held, or `kamal-proxy` cannot bind ports?
6. How do migrations interact with app rollback for this Phoenix app?
7. Does Kamal still fit after the first disposable-host spike, or does the evidence justify revisiting Dokku, Coolify, Dokploy, Fly, Render, or a simpler Docker Compose rollout path?

### Origin Migration Strategy

The current AWS/S3/CloudFront site is messy, but it is also the live incumbent for `zaneriley.com`. Treat it as a protective fallback until the replacement origin is boring.

Migration sequence:

1. **Do not disturb `zaneriley.com` first.** Keep the AWS static site serving public traffic while the new deploy loop is designed and proven.
2. **Stand up a private, non-AWS preview origin in parallel.** The first target may be a throwaway VPS or later a home host, but it must be reachable from GitHub Actions and from Z's real devices for preview.
3. **Prove the deploy loop off-domain.** The replacement must support private preview, same-digest promotion, truthful health gates, live smoke, rollback receipts, and no-secret-leak behavior before public cutover.
4. **Run repeated deploys until boring.** One green deploy is not enough. The loop should survive failed readiness, rollback, restart, registry/auth failure, and content publication cases without risking the live site.
5. **Prepare SEO-safe cutover before DNS changes.** Lower TTLs, crawl the current site, preserve URLs/redirects, define cache behavior, and write the rollback path before touching production records.
6. **Move public traffic only after rollback is ready.** The first public cutover should leave AWS available as a rollback/fallback path until the new origin has proven stable.
7. **Retire AWS last.** Getting off AWS is the desired end state, not the first irreversible step.

This framing keeps the values in order: visitor experience and SEO safety first, then deploy confidence, then AWS removal and cost/compute optimization.

The throwaway VPS literature pass is complete at `.tmp/2026-05-11-throwaway-vps-origin/literature/`. Hetzner Cloud CX23 x86 is the lowest-cost clean candidate on paper, but DigitalOcean is the chosen first spike target because Z already has an account and the goal is to reduce setup friction. Use the smallest honest DigitalOcean Droplet first: Basic 1 GiB / 1 vCPU, no backups, no snapshots unless explicitly needed, no managed database, no load balancer, no extra volumes, and destroy rather than power off when done. The 512 MiB Droplet is a later squeeze target only if the 1 GiB path works and resource measurements say it is worth testing.

Static public-site export remains a **performance/deploy simplification option**, not the active path. Phoenix may be able to render the visitor-facing portfolio to static HTML someday, but do not pivot there now. Keep the current dynamic Phoenix/Docker origin path until DigitalOcean/Kamal/private-preview evidence says it fails or performance/cost data makes static export the right optimization.

### Known Origin / Build Gotchas

These are durable findings from the 2026-05-12 simple preview bug bash, not scratch speculation:

1. **Do not build the deploy artifact locally on the Mac Studio with plain `docker build --platform linux/amd64`.** The local Docker CLI lacks Buildx, falls back to the legacy builder, and proceeded down an ARM64 build path while accepting the `linux/amd64` flag. Final deploy tooling must consume a CI-built image digest or use an explicitly provisioned multi-arch builder.
2. **Do not build the app on the 1 GiB origin.** A real 1 GiB `sfo3` Droplet reached Docker readiness, accepted the source tree, and then OOM-killed BEAM during `mix deps.compile` after about 20 minutes. This only rules out origin-side builds; it does not rule out the 1 GiB shape as a runtime host.
3. **The smallest DO host passed the first runtime-only proof.** On 2026-05-13, a Basic 1 GiB / 1 vCPU `sfo3` Droplet ran Postgres plus the current PR preview image, hit `/readyz`, served all seven public smoke routes, and reported content status without OOM. Snapshot: web `191.8MiB`, Postgres `97.14MiB`, `337MiB` available; cgroup peaks were web `256.6MiB`, Postgres `148.4MiB`; `/readyz` passed in `12662ms` after `docker compose up -d`. Evidence lives at `.tmp/2026-05-13-current-preview-runtime-proof/`. This keeps 1 GiB viable for preview-origin work, but production safety still needs repeated-request and deploy/rollback measurement. The route-smoke portion of this proof was status/bytes-only; treat it as weak historical evidence until content-level browser assertions exist.
4. **HTTP route smoke can be green while browser preview is visibly broken.** A follow-up visual proof on 2026-05-13 used an SSH tunnel to the 1 GiB host plus Playwright/Chromium screenshots. It proved `/css/app.css` loaded, but also found that JS and favicon URLs were emitted as `preview.local:8000` and blocked by CSP/DNS, the mobile homepage layout collided badly, and the note detail route returned HTTP 200 while rendering the visible error state `We ran into an issue loading this note!`. Evidence lives at `.tmp/2026-05-13-current-preview-visual-proof/`. Deploy readiness needs at least one browser-level preview check; curl status/bytes are not enough. Prior "route probes passed" notes in bug-bash artifacts are now retroactively weaker than written because a Phoenix route can return `200` while rendering a page-level error state.
5. **The broken preview is probably app runtime config first, deploy machinery second.** The `preview.local:8000` asset URLs point toward Phoenix endpoint/static URL configuration under the preview origin shape. Audit runtime config before refactoring deploy scripts: `PHX_HOST`, endpoint `url:`, scheme/port handling, static URL prefix, CSP hosts, and any absolute URL generation around `url(~p"...")` or static asset helpers.
6. **The disposable host needs Docker Compose before runtime spikes.** Ubuntu's `docker.io` package did not provide `docker compose`; cloud-init now installs `docker-compose-v2` and readiness must prove `docker compose version`.
7. **Browser-test payloads now need to earn rent.** Playwright in the image was previously flagged as production-image bloat. Since the next deploy gate needs browser-real proof, keep the browser tooling question open until the gate is shaped: use it for preview smoke if it is already present, then decide whether both root and node installs are necessary or whether browser tooling belongs in a separate test image target.
8. **1Password CLI authorization remains an operator nuisance.** `op read ... | DIGITALOCEAN_TOKEN_STDIN=1` avoids clipboard leakage, but local runs still surface GUI authorization prompts. Treat this as an operator-flow decision, not a new discovery, if it appears in future observation packets.

### DigitalOcean Disposable Origin Requirements

First implementation slice: create, inspect, and destroy a disposable DigitalOcean Docker host without touching `zaneriley.com`, AWS, release automation, or production DNS.

GitHub environment: `preview`.

Required secrets:

1. `DIGITALOCEAN_TOKEN`: DigitalOcean API token with enough scope to create, inspect, and destroy Droplets, read images/actions, and create/use tags. Installed in the GitHub `preview` environment on 2026-05-11 and saved in 1Password as "DigitalOcean Personal Access Token". The exact DO token UI evolves; least-privilege intent is create/read/delete only for spike resources plus read-only metadata needed by the create action.
2. `DEPLOY_SSH_PUBLIC_KEY`: public SSH key installed into the Droplet's `deploy` user by cloud-init.

3. `DEPLOY_SSH_PRIVATE_KEY`: private SSH key used by the create workflow to prove cloud-init completed, Docker is installed, and `/var/lib/personal-site` exists before it emits the receipt.

Current command surface:

1. `./run host:disposable:create`
   - Creates a Basic 1 GiB / 1 vCPU Droplet by default.
   - Defaults and allowlist: `DO_REGION=sfo3`, `DO_SIZE=s-1vcpu-1gb`, `DO_IMAGE=ubuntu-24-04-x64`.
   - Installs Docker and Docker Compose v2 through cloud-init and creates a `deploy` user in the `docker` group.
   - Requires `DEPLOY_SSH_PRIVATE_KEY`; missing SSH readiness proof is a failure, not a skipped check.
   - Waits for SSH, cloud-init, Docker readiness, Docker Compose readiness, and `/var/lib/personal-site` with a bounded remote timeout.
   - Writes `ci/digitalocean-host.json` immediately after Droplet allocation and updates it through `allocated`, `waiting_for_network`, `ready`, `failed`, or `destroyed_after_failure`.
   - Destroys failed creates by default. Set `PRESERVE_FAILED_ORIGIN=1` only when intentionally debugging the host.
2. `./run host:disposable:status`
   - With no `DROPLET_ID` or receipt, lists Droplets tagged `disposable-origin`.
   - With `DROPLET_ID` or a receipt file path, prints one Droplet's status.
   - Prints Droplet status, region, size, image, public IPv4/IPv6, and tags.
3. `CONFIRM_DESTROY=1 ./run host:disposable:destroy`
   - Requires `DROPLET_ID` or a receipt file path.
   - Fetches the Droplet first and refuses to delete unless it has the expected `personal-site`, `disposable-origin`, and `preview` tags plus the expected preview name prefix.
   - Destroys the Droplet only after ownership verification. Powering off is not the disposal path because powered-off Droplets still bill.
4. `APP_IMAGE_REF=ghcr.io/owner/repo@sha256:<digest> ./run host:disposable:runtime-proof ci/digitalocean-host.json`
   - Runs only against a ready disposable-host receipt; it refuses non-ready receipts and floating image tags.
   - Copies a small runtime payload to `/var/lib/personal-site/runtime-proof`, starts Postgres plus the digest-pinned app image with fixture content, waits for `/readyz`, and probes the public route set.
   - Writes `ci/disposable-runtime-proof.json` and `ci/disposable-runtime-proof/` artifacts with ready time, route statuses, `docker stats`, `free -m`, cgroup memory peaks when available, app logs, compose status, and `bin/content status --json`.
   - This is a runtime viability proof, not a production deploy. It does not touch DNS, `zaneriley.com`, AWS, CDN config, release automation, or blue/green promotion.

Preview image workflow:

- `Preview image` builds a non-release `linux/amd64` production image in GitHub Actions and pushes only a SHA-scoped tag: `ghcr.io/zaneriley/personal-site:preview-sha-<sha>`.
- It writes `ci/preview-image.json` as the `preview-image` artifact. The runtime-proof command should consume `.image_ref`, which is digest-pinned as `ghcr.io/zaneriley/personal-site@sha256:<digest>`.
- This workflow is deliberately separate from Release Please. It must not create GitHub Releases, version tags, `latest`, or semver tags.
- Local handoff after a successful workflow run:

  ```bash
  gh run download <run-id> -n preview-image -D .tmp/preview-image
  APP_IMAGE_REF="$(jq -r .image_ref .tmp/preview-image/preview-image.json)" \
    ./run host:disposable:runtime-proof ci/digitalocean-host.json
  ```

GitHub workflow:

- `Disposable host spike` is manual-only (`workflow_dispatch`).
- Actions: `create`, `status`, `destroy`.
- The default action is `status`, not `create`, so the easiest click path does not allocate money.
- The workflow checks out the default branch before loading DO/SSH secrets; feature-branch workflow code should not receive deploy credentials.
- The workflow uploads `ci/digitalocean-host.json` as the create receipt with 2-day retention and treats a missing receipt as an error.
- The workflow is deliberately not wired to PRs, `main`, Release Please, production deployment, or domain cutover.
- GitHub will not run this new manual workflow from a feature branch until the workflow definition is present on the default branch. Before merge, use the same canonical `./run host:disposable:*` commands locally for proof; after merge, rerun the create/status/destroy proof through GitHub Actions.

Remaining hardening before this graduates from host spike to deploy substrate:

- Add a deploy receipt that records host id, image digest, content SHA/generation, smoke result, and rollback/destroy commands.
- Add a browser-level preview proof that fails on missing CSS/JS/icon assets, requests to the wrong origin such as `preview.local`, visible app error states on required routes, and obvious viewport breakage before treating a preview as user-credible. First fix and assert the asset-origin problem; then re-check mobile layout so asset/config failure and true responsive bugs do not get mixed together.
- Add repeated-request/runtime-load observation before treating 1 GiB as production-safe.
- Add a scheduled or manual age-based janitor for tagged disposable hosts.
- Replace the long-lived preview SSH keypair with per-run keys, or rotate the current spike key before any persistent origin exists.
- Decide whether IPv6 should stay enabled for the spike; if yes, firewall and smoke must treat it as first-class.
- Keep the command taxonomy honest: this is Docker-host bootstrap. "Deploy" still means app image digest plus content SHA/generation, preview checks, promotion, and rollback.

## Resource-frugality feedback harness proposal

Status: first CI slice implemented. Literature artifacts live at `.tmp/2026-05-11-cold-performance-ratchet/literature/`.

The goal is not a one-time benchmark. The goal is a feedback ladder that gives LLMs and humans faster, earlier, harder-to-ignore performance signal while preserving `./run ci:prod-build` as the final release-shaped gate. Performance is a process constraint from the beginning of app/design work, not a cleanup phase after the portfolio is finished.

Primary user model: mostly first-time visitors. Optimize and measure cold public-page experience first. Warm page-to-page navigation matters after first load. Admin routes are out of scope.

Target philosophy:

- 200ms wall-to-wall remains the ambition, but the repo should ratchet toward it rather than pretend one noisy CI run proves reality.
- User-perceived mobile performance comes before compute-per-watt. Compute/watt only matters after the visitor experience is good.
- A complete mediocre portfolio is better than an unfinished excellent one, but performance feedback must stay visible while the app is being finished so expensive choices do not become baked in.
- Runtime/framework rewrites are low-ROI unless route/browser profiling proves Phoenix is the bottleneck.

### Public Navigation and App-Like Motion

The app-like navigation decision is parked, not forgotten. ADR 0002 proposes keeping LiveView as the public navigation substrate and later proving same-document View Transitions through LiveView 1.1.18+'s `onDocumentPatch` hook. Do not turn the current JS-byte concern into a framework rewrite while the active slice is still preview correctness, gzip/compression verification, budget calibration, and nonessential-JS cleanup.

The near-term performance question is: what bytes ship to a cold first-time mobile visitor, are they compressed, and which payloads can be removed or lazy-loaded without changing the product? Easter egg/debug JavaScript should be split out of the first-load path before LiveView itself is judged. A later motion slice can then measure LiveView's actual tradeoff: first-load JS/WebSocket cost versus warm page-to-page continuity.

Proposed feedback ladder:

1. **Fast local smoke:** `./run performance:smoke`
   - Fastest loop for small route/template/CSS/content-rendering changes.
   - Probes canonical public routes, status/redirect shape, rough transferred bytes, HTML size, and obvious asset explosions.
   - Target runtime: under 30 seconds.
   - Intended use: LLMs run habitually after user-visible edits.
2. **Representative local browser check:** `./run performance:browser` or `./run performance:ratchet`
   - Playwright-based mobile browser run against the public route set.
   - Cold browser context for first-load checks; separate warm navigation flow for page-to-page behavior.
   - Captures status, request count, transferred bytes, FCP/LCP or readable-content timing, CLS, JS/CSS/font/image bytes, console errors, and artifacts.
   - Target runtime: 1-3 minutes for the normal route set.
3. **CI browser preview:** `./run ci:performance-browser`
   - First implementation: called from `./run ci:prod-build` after the release is ready and route smoke has passed.
   - Later, after enough trusted samples prove low false-positive risk, split into a top-level PR check named `Performance browser`.
   - Uploads `ci/browser-last-run.json` and failure artifacts.
   - Hard-fails on broken pages, missing metrics, console/page errors, catastrophic page-weight blowups, and trusted budget violations.
4. **Final PR authority:** `./run ci:prod-build`
   - Keep as the final release-shaped gate: prod image build, migration round-trip, release boot, `/readyz`, canonical route probes, content status, release RPC introspection, and current `oha` route-latency comparison.
   - Fold only stable, low-noise performance assertions into this gate.
5. **Nightly calibration:** future `./run ci:performance-calibration`
   - Heavier browser measurements, repeated samples, traces/screenshots/HAR, and baseline learning.
   - Used to understand variance and decide which browser budgets are ready to move from observation to hard failure.
6. **Live/deploy smoke:** future origin/deploy gate
   - After origin deployability exists, measure the live URL through the real edge/origin path.
   - Must report cache state explicitly: hit, stale hit, revalidation, miss, and first-fill.

First implementation slice:

1. Add `ci/browser-performance.mjs` and `ci/browser-budget.json`. Done.
2. Add canonical command `./run ci:performance-browser`. Done.
3. Use Playwright first because it is already in `assets/package.json`, avoids Lighthouse score theater, and can emit explicit route/page metrics.
4. Keep `oha` for origin route latency; it already feeds `ci/last-run.json`.
5. Write browser results to `ci/browser-last-run.json`. Done; generated artifact is gitignored and uploaded by CI.
6. Call the browser check from `ci/prod-build.sh` after the release is ready and route smoke has passed. Done; this is the embed-first phase, not the final desired check topology.
7. Upload `ci/browser-last-run.json` beside `ci/last-run.json` and `ci/baseline.json`. Done.
8. After the command has accumulated enough trusted runs and false-positive behavior is understood, consider splitting it out of `Prod build` into its own top-level `Performance browser` workflow check.

Hardening added after peer review:

- Browser byte metrics use Playwright network-size data consistently instead of mixing `content-length` and decompressed body lengths.
- Resource byte totals count transferred response body plus response headers, which makes the metric closer to what the browser actually downloads.
- The browser artifact records WebSocket frames and bytes so future LiveView traffic cannot hide outside the page-weight budget.
- `ci/prod-build.sh` derives its route-smoke list from `ci/browser-budget.json`, plus the legacy `/en/self` smoke route, so browser and HTTP route coverage do not drift apart.
- Initial hard ceilings are intentionally close to current reality: `max_total_bytes=120000`, `max_css_bytes=50000`, `max_js_bytes=120000`, `max_request_count=12`, `max_fcp_ms=1800`, and `max_cls=0.1`.

Do not add Lighthouse CI, sitespeed.io, Server-Timing, or `hyperfine` in the first slice unless implementation evidence changes the tradeoff. Lighthouse CI is useful later but easier to turn into score theater. Server-Timing should wait until `oha` plus browser timing cannot explain a server-side ambiguity. `hyperfine` should wait until release boot timing needs repeated command-level measurement outside the current Docker orchestration.

Initial public route/page set:

- `/`
- `/en`
- `/en/case-studies`
- one representative case-study detail route backed by prod-build fixture content
- `/en/notes`
- one representative note detail route backed by prod-build fixture content
- `/ja`

The route set must be explicit and versioned. Removing a route from the performance matrix is a budget/integrity change, not a casual script edit. Representative detail routes must not depend on mutable `personal-site-content` state. The prod-build fixture should provide stable note and case-study content for browser performance checks, just as it already provides stable smoke content.

Output contract:

- Human output must name the user-visible problem, the route/page, observed value, allowed value, artifact path, and likely class of fix.
- Machine artifacts must include at least: command, generated timestamp, app SHA, content SHA/generation when available, base URL, route/page metrics, thresholds, status, failures, warnings, and exemptions used.
- Browser artifacts must include consistent transferred-byte measurements and WebSocket frame/byte counts.
- Missing metrics fail. Missing FCP/LCP/readable-content timing must not be coerced to `0`.
- A clean run should end with a stable verdict line such as `performance browser passed`.

Example failure shape:

```text
performance browser failed

Route/page: /en/notes
Problem: CSS shipped to first-time visitors grew too much
Observed: total=184KB css=73KB requests=12
Allowed: total<=130KB or <=20% drift
Artifact: ci/browser-last-run.json
Next: reduce shipped CSS, split noncritical CSS, or submit an explicit budget-change proposal
```

Budget and anti-cheat rules:

- Warnings are failures unless allowlisted with exact source, reason, and expiry.
- Budgets live in a versioned file, initially `ci/browser-budget.json`.
- Budgets cannot be silently weakened. Increasing thresholds, removing metrics, removing routes, lowering sample counts, disabling mobile emulation, or broadening exemptions requires an explicit budget-change proposal.
- Baselines update only from trusted `main`/nightly paths, not arbitrary PR branches.
- Missing measured values from the current run fail. Missing historical baselines do not automatically fail for newly introduced routes or metrics.
- New routes and new metrics enter an onboarding state: they must satisfy coarse absolute ceilings immediately, emit artifacts immediately, and graduate to drift enforcement only after enough trusted `main`/nightly samples exist.
- Performance claims must cite user-facing metric deltas: route p50/p95, ready time, cold first response, FCP, LCP/readable-content timing, CLS, transferred bytes, request count, JS bytes, CSS bytes, image bytes, font bytes, or main-thread work.
- WebSocket bytes count as first-load/page-interaction cost once LiveView traffic exists. A page with low HTTP bytes but hidden LiveView frame weight is not frugal.
- Lighthouse aggregate score alone never counts as progress.
- Microbenchmarks only count when tied to a failing/protected product metric and a route/browser artifact moves in the same direction.
- The integrity gate should eventually reject fake-green patterns for performance commands: `|| true`, `continue-on-error`, warning filtering, score-only reports, route removal, sample-count reduction, budget weakening, PR baseline updates, and artifact upload without threshold checks.

Budget-change UX:

- Legitimate budget increases should be possible without teaching agents to weaken gates by stealth.
- Use an explicit versioned exception/change record, initially in `ci/browser-budget.json` unless it grows enough to split into `ci/browser-budget-exceptions.json`.
- Each exception must name: route/page, metric, old value, new value, reason, expiry or follow-up, and whether it is a temporary exception or a deliberate new budget.
- Expired exceptions fail.
- Tightening budgets requires no exception record, but should still print a ratchet summary so the improvement is visible.
- A failure caused by a legitimate heavier design choice should point to the exception mechanism rather than trapping the agent in endless optimization.

Artifact naming:

- Keep the current `ci/last-run.json` during the first slice to avoid a noisy rename.
- If the browser artifact lands cleanly, consider a later compatibility-preserving rename or alias from `ci/last-run.json` to `ci/latency-last-run.json` so it sits symmetrically beside `ci/browser-last-run.json`.

Cleanup completed during implementation:

- Removed the production FCP console observer and `REMOVE FOR PRODUCTION` comment from `assets/js/app.js`.
- Removed `@font-face` declarations for font files that the repo does not actually ship, because they caused real first-load 404s and hid page-weight truth.

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
