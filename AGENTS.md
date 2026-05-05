# personal-site — repo contract

Repo-scoped rules and shipped intent. Global agent contract lives in `~/.agents/AGENTS.md`; this file is what's specific to this project.

This file was bootstrapped via `/grill-me` on 2026-05-06 against the deploy/ops scope. Other scopes (e.g. typography redesign) will extend it. Sections marked **partial** or **open** are explicit to-clarify items, not silent gaps.

---

## Acceptance gates (always-on)

A change is mergeable only if all of the following hold. These are inherited expectations — running them locally or in CI catches the kinds of mistakes the gates exist for.

- `mix compile --force` produces zero warnings.
- `mix format --check-formatted` clean.
- `mix credo` (project config) clean.
- `mix sobelow --config --exit` clean.
- `mix dialyzer` 0 errors.
- `mix test` failure count ≤ baseline (currently 2: typography-slot tests, deferred per the typography rewrite plan).
- `npx biome check .` clean (advisory warnings on intentional `!important` are OK).
- `yarn stylelint 'css/**/*.css'` clean.
- `npx vitest run` 0 failures.
- The 6 canonical routes return 200: `/en`, `/ja`, `/en/notes`, `/en/case-studies`, `/en/case-study/case-study-1`, `/en/self`.

The Elixir-side prescriptions (writing-controllers, writing-liveviews, writing-otp, etc.) live in the `elixir-phoenix-style` skill at `.agents/skills/elixir-phoenix-style/`. Load `SKILL.md` early in any Elixir-editing session.

---

## Deploy / ops scope

### Objectives

- **Purpose:** Never ship errors to visitors at zaneriley.com; site always reachable. Iteration confidence via CI gates that catch LLM-authored mistakes before merge. Self-host on the smallest hardware that doesn't compromise users.
- **Why now:** The repo just emerged from a multi-year "Backup from broken mac" state. Deps current, code clean, deps cleared GitHub vulnerabilities, branch merged. The infra layer is the next thing needed before design / typography rewrite work.
- **Done looks like:** A push to main triggers CI gates; if green, an image is built and deployed via blue/green at the origin; smoke test runs; rollback is one command and tested. Visitors never see broken (CDN-cached front absorbs origin restarts and outages). Origin runs on the smallest hardware that meets the app's measured needs. Content-repo updates flow through the same loop. Observability emits metrics/logs Z can see; the next deploy reacts (auto-cancel rollout if error rate spikes).
- **Out of scope:** No Grafana. No tool/stack prescription without `/literature` first (CDN, secrets, deploy substrate, observability all queued).
- **Who else:** visitors (uptime + speed); future-Z (returning months later, expects deploy = forget nothing); LLMs working in this repo (CI is their guardrail); content-repo automation (`personal-website-content` webhook is a deploy "user").

### Vision

A portfolio visitors never see broken, served from cached edges so the origin can be tiny, hosted on hardware that fits in a drawer or in a breadboard frame, with a deploy pipeline that doesn't require remembering anything six months later. CI catches LLM-authored mistakes before they merge; rollback is one command and tested. Speed wins ties. Compute-per-watt and compute-per-cost are optimized, never at user expense.

The breadboard-frame-as-painting is an aspiration, not a romantic floor. Owned hardware (Mac Studio, NUCs, the new NAS) is the honest fallback if breadboard-class can't meet measured app needs after resource-frugality work lands.

### Architectural framing

**CDN-fronted, tiny dynamic origin.** A highly-cached static front absorbs availability gaps so the origin can be Pi-class. The HA story is the cache layer, not origin redundancy. The origin can be slow and small; users don't see it directly. This is the framing that makes "five-nines" plausible alongside "single tiny server."

### Strategies

In approximate PM rank order. #1 anchors first — site is meaningless without content flowing through.

1. **Content-pipeline sync.** Finish the `personal-website-content` webhook story. Currently partially wired (`Portfolio.Release.pull_repository`, `GitHubWebhook` plug). Site is meaningless without content flowing through.
2. **CI gates.** LLM-mistake catcher. Largely orthogonal to where prod runs; can ship while #1 is in flight. Includes hardening lint/test/dialyzer gates already passing locally; build-and-cache the prod image; run smoke tests against it; perf budget if/when measured baseline exists.
3. **Resource-frugality of the app itself.** Measure cold-start, p50 request latency, memory footprint, cache-hit rate. Reduce until "small enough." Cold-start audit at `.tmp/2026-05-05-upgrade-deep-dive/cold-start.md` is queued input. Hardware decision falls out of this measurement, not before.
4. **Front-edge cache substrate.** CDN choice. Depends on #3 to know what's safely cacheable and TTL bounds. **Requires `/literature` before tool selection.**
5. **Origin substrate + deploy pipeline.** Hardware + release format + blue/green at origin + deploy mechanics. Hardware falls out of #3. **Requires `/literature` before tool selection.**
6. **Observability + rollback loop.** Metrics, logs, the auto-cancel-on-spike loop. **Requires `/literature` before tool selection.** No Grafana.

The order is not fully ratified beyond #1; #2 explicitly parallelizes with #1; #3 is prerequisite to #4–#5.

### Round-trip deploy definition

The "round-trip" is the full loop: **push → CI gates → image build → blue/green deploy → smoke test → notify → tested rollback path exercised on every deploy → content-repo updates flowing through the same loop → observability emits metrics/logs the next deploy reacts to (auto-cancel on error-rate spike).** All four pieces (the basic loop, rollback, content sync, observability feedback) are in scope; this is what success looks like.

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
- ADR-grade decisions land here; tactical day-to-day stays in conversation or `.tmp/`.
- This file is git-tracked and public-shaped per `~/.agents/AGENTS.md` §10. PII goes to the vault, not here.
