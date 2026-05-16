# personal-site — repo contract

Repo-scoped rules and shipped intent. Global agent contract lives in `~/.agents/AGENTS.md`; this file is what's specific to this project.

This file was bootstrapped via `/grill-me` on 2026-05-06 against the deploy/ops scope. Other scopes (e.g. typography redesign) will extend it. Sections marked **partial** or **open** are explicit to-clarify items, not silent gaps.

---

## Acceptance gates (always-on)

A change is mergeable only if all of the following hold. These are inherited expectations — running them locally or in CI catches the kinds of mistakes the gates exist for.

The canonical command surface is `./run ci:*`. GitHub workflow YAML should call these canonical gate tasks, not raw `mix`, `npx`, `yarn`, or one-off shell versions of the same checks. If a gate changes, update `run` first, then call the `./run ci:*` task from CI.

GitHub CI must expose the real acceptance gates as legible top-level check jobs. Do not hide compile, lint, security, test, static analysis, workflow lint, or gate-integrity work as steps inside one generic `test` job. A PR reviewer should be able to identify the failing gate from the checks list without opening logs.

- `./run ci:compile` produces zero compile warnings.
- `./run ci:workflow-lint` is clean: actionlint accepts every GitHub workflow file.
- `./run ci:acceptance-gate-bypass-check` is clean, and `./run ci:acceptance-gate-bypass-check:test` passes its fixture matrix: canonical workflow/run samples pass, and known fake-green patterns are rejected.
- `./run ci:lint` is clean: ShellCheck, Hadolint, Credo, `mix format --check-formatted`, Biome check, and Stylelint check. The only allowed advisory is Biome `lint/complexity/noImportantStyles` for the intentional CJK line-height rule in `assets/css/app.css`; any other warning is red.
- `./run ci:security-check` is clean: Sobelow with project config and nonzero exit on findings.
- `./run ci:static-analysis` is clean: Dialyzer reports `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`.
- `./run ci:test` is clean: Elixir tests and JS tests have 0 failures.
- The secret-scan workflow runs `./run ci:secret-scan`; gitleaks current-tree scan has 0 findings.
- `./run ci:prod-build` is clean: prod image build, migration round-trip, release boot, `/readyz`, canonical route probes, release RPC introspection, and public page budget checks all pass. GitHub branch protection must require the top-level `Prod build` check.

Route smoke is part of the production-build gate, not a separate placeholder job. Do not add another route-smoke gate just to make CI look broader; widen `./run ci:prod-build` only when the app has a stronger readiness/content contract.

### CI / deploy IA guardrail

The CI/deploy/preview area was reset on 2026-05-16. New CI files must fit the map below instead of recreating a junk drawer.

Locked direction:

- Generated local evidence defaults to `.tmp/ci-artifacts/`, not `ci/`. CI can upload those paths as GitHub artifacts; durable repo inputs stay source-shaped.
- Prefer fewer files. Do not split tiny scripts/configs just to make a taxonomy look clean; split only when a folder/file owns a durable concept a future maintainer can name.
- `./run` remains the canonical command surface. The tree behind it must explain where contracts, gates, preview verification, provider glue, fixtures, and generated artifacts live.
- Reserve `preview` for a deployed private candidate lane or checks against that lane. Reserve `origin` for the future durable runtime environment. Use `candidate image`, `disposable host`, `runtime viability`, `route probe`, `preview page acceptance`, `public page budget`, `published fixture content`, and `receipt` for the current verification concepts.

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

The Elixir-side prescriptions (writing-controllers, writing-liveviews, writing-otp, etc.) live in the `elixir-phoenix-style` skill at `.agents/skills/elixir-phoenix-style/`. Load `SKILL.md` early in any Elixir-editing session.

---

## Decision records

- ADRs live in `_PROJECT_DOCS/adrs/`.
- `AGENTS.md` is for constant repo-level guidance, workflows, acceptance gates, and pointers to durable records. It may summarize or link to ADRs when the guidance must stay visible, but it is not the ADR body.
- Tactical day-to-day notes stay in conversation or `.tmp/` until promoted into either an ADR or an always-on repo rule.

## Commit and PR language

Keep Conventional Commits for tooling, but make the subject after the prefix readable to someone who has not read this repo's planning docs. Use `feat:` only when the world changes in a user-observable way; plumbing, renames, and guardrail tightening are usually `chore:`, `build:`, or `ci:`. Avoid internal nouns in subjects such as verdicts, generations, ledgers, spikes, acceptance surfaces, or publishability; put mechanism in the body.

---

## Deploy / ops scope

### Objectives

- **Purpose:** Never ship errors to visitors at zaneriley.com; site always reachable. Iteration confidence via CI gates that catch LLM-authored mistakes before merge. Self-host on the smallest hardware that doesn't compromise users.
- **Why now:** The repo just emerged from a multi-year "Backup from broken mac" state. Deps current, code clean, deps cleared GitHub vulnerabilities, branch merged. The infra layer is the next thing needed before design / typography rewrite work.
- **Done looks like:** A push to main triggers CI gates; if green, an image is built and deployed via blue/green at the origin; smoke test runs; rollback is one command and tested. Visitors never see broken (CDN-cached front absorbs origin restarts and outages). Origin runs on the smallest hardware that meets the app's measured needs. Content-repo updates flow through the same loop. Observability emits metrics/logs Z can see; the next deploy reacts (auto-cancel rollout if error rate spikes).
- **Out of scope:** No Grafana. No tool/stack prescription without `/literature` first (CDN, secrets, deploy substrate, observability all queued).
- **Who else:** visitors (uptime + speed); future-Z (returning months later, expects deploy = forget nothing); LLMs working in this repo (CI is their guardrail); content-repo automation (`personal-site-content` webhook is a deploy "user"; earlier notes may call this `personal-website-content`).

### Vision

A portfolio visitors never see broken, served from cached edges so the origin can be tiny, hosted on hardware that fits in a drawer or in a breadboard frame, with a deploy pipeline that doesn't require remembering anything six months later. CI catches LLM-authored mistakes before they merge; rollback is one command and tested. Speed wins ties. Compute-per-watt and compute-per-cost are optimized, never at user expense.

The breadboard-frame-as-painting is an aspiration, not a romantic floor. Owned hardware (Mac Studio, NUCs, the new NAS) is the honest fallback if breadboard-class can't meet measured app needs after resource-frugality work lands.

### Architectural framing

**CDN-fronted, tiny dynamic origin.** A highly-cached static front absorbs availability gaps so the origin can be Pi-class. The HA story is the cache layer, not origin redundancy. The origin can be slow and small; users don't see it directly. This is the framing that makes "five-nines" plausible alongside "single tiny server."

### Strategies

In approximate PM rank order. #1 anchors first because the site is meaningless without content flowing through. The adversarial check for #1 is **content deployability**, not mere repo sync: a fresher checkout does not count unless the site can keep serving last-good content, name the live content commit, reject bad content with a clear reason, and roll content back without guessing.

1. **Content deployability.** Finish the content-repo publish path. The configured repo is `personal-site-content` in `.env.example`; earlier notes may call it `personal-website-content`. As of 2026-05-11, the app-side webhook path validates repo/ref/`after` SHA, syncs the local content clone to the exact commit, promotes changed Markdown transactionally, rejects bad content without moving the live generation, records accepted/rejected/ignored verdicts, falls back to last-good content on boot failures, supports generation-aware content-only rollback, and injects private content-repo auth without persisting credentials into Git remotes. The content-repo front door runs canonical CI commands for draft safety, app validation, and shell lint. Renames use explicit `aliases:` frontmatter with 301 redirects; deletion-only changes keep hard-404 behavior. Mixed delete/add updates must preserve deleted live slugs through canonical URLs or aliases. The authoring contract lives in `_PROJECT_DOCS/content-authoring-contract.md`. Remaining work: share-image generation/rendering/validation. The DX target is Obsidian -> commit -> push -> accepted/rejected/ignored verdict, with no SSH, restart, DB poking, or "did the watcher notice?" uncertainty.
2. **CI gates.** LLM-mistake catcher. Shipped 2026-05-07: existing compile/lint/security/test/static-analysis/workflow/secret gates are required, and `Prod build` is now a required branch-protection check. The gate builds the release image, runs migrations up/down/up, boots the release, checks `/readyz`, probes canonical routes, runs release RPC introspection, and records perf data.
3. **Resource-frugality of the app itself.** Measure cold-start, p50 request latency, memory footprint, cache-hit rate. Reduce until "small enough." Cold-start audit at `.tmp/2026-05-05-upgrade-deep-dive/cold-start.md` is queued input. Hardware decision falls out of this measurement, not before.
4. **Front-edge cache substrate.** CDN choice. Depends on #3 to know what's safely cacheable and TTL bounds. **Requires `/literature` before tool selection.**
5. **Origin substrate + deploy pipeline.** Hardware + release format + blue/green at origin + deploy mechanics. Hardware falls out of #3. **Requires `/literature` before tool selection.**
6. **Observability + rollback loop.** Metrics, logs, the auto-cancel-on-spike loop. **Requires `/literature` before tool selection.** No Grafana.

The order is not fully ratified beyond #1; #2 explicitly parallelizes with #1; #3 is prerequisite to #4–#5.

### Round-trip deploy definition

The "round-trip" is the full loop: **push → CI gates → image build → blue/green deploy → smoke test → notify → tested rollback path exercised on every deploy → content-repo updates flowing through the same loop → observability emits metrics/logs the next deploy reacts to (auto-cancel on error-rate spike).** All four pieces (the basic loop, rollback, content sync, observability feedback) are in scope; this is what success looks like.

Current Phase 3 status and sequencing live in `_PROJECT_DOCS/deploy-ops-status-plan.md`. Keep that plan synchronized with `_PROJECT_DOCS/2026-revival-todo.md` when the active workstream changes.

### Hard constraints (partial — Step 4 of `/grill-me` was cut short)

Captured so far. Re-run `/grill-me --step 4` (constraints) when picking this up to fill in the rest.

- **No Co-Authored-By; no Claude/Anthropic mentions in commit messages.** Hook-enforced via `~/.agents/claude-code/hooks/block-co-author.sh`. Why: tool-attribution leaks tooling choice into history; commits are by Z regardless of who drafted the prose.
- **No tool/stack prescription without `/literature` first.** Why: prevents unsourced lock-in. Z explicitly ratified this 2026-05-06 for CDN, secrets management, deploy substrate, and observability. Default to literature-first; "I think we should use X" is a yellow flag without a brief.
- **No Grafana.** Explicit veto 2026-05-06. (Why not yet recorded; surface in next grill.)
- **Versioned + idempotent deploys.** Why: blast-radius-bounded, repeatable, recoverable.
- **Speed wins ties.** Decision criterion *and* operational constraint: any tool that slows the user-visible path loses, full stop.
- **Compute-per-watt floor; never at user expense.** Resource minimization is the goal until it costs visitors. User experience is the hard floor.

Not yet captured: budget ceilings, telemetry-leaving-box policy, network rules (Tailscale?), key-management policy beyond `op://`, "reproducible solo in a year" rule, refusals on specific orgs.

### Open / unfinished items from the grill

- **Hard constraints** — only ~6 captured of probably 10–12. Re-run constraint elicitation.
- **Taste seeding (Step 5 of `/grill-me`)** — not started. 3–5 representative past decisions in this scope with the why behind each.
- **Strategy ordering** — beyond #1 anchored first, the rest is "approximately the order I sketched." Pin down before kicking off scope-by-scope work.
- **Performance targets** — Z mentioned 200ms round-trip and 400ms cold-start in the same conversation. Confirm both are targets (boot ≤ 400ms; response p50 ≤ 200ms) and what "remote" means for the cold-start measurement.
- **Why-no-Grafana.** Pure preference, past pain, ideological? Affects what an acceptable observability stack looks like.

---

## How this file gets updated

- After the next `/grill-me` pass: append to or replace the partial sections above.
- New scopes (typography redesign, etc.) get their own top-level sections following the same shape.
- ADR-grade decisions land in `_PROJECT_DOCS/adrs/`; this file keeps only stable guidance, workflows, acceptance gates, and pointers.
- This file is git-tracked and public-shaped per `~/.agents/AGENTS.md` §10. PII goes to the vault, not here.
