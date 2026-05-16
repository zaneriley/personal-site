# Portfolio revival — running TODO

Started 2026-05-05 with the branch `frontend-infra` ("Backup from broken mac"). This doc tracks where we are in the bigger arc: get the repo working → clean it up → upgrade deps → merge to main → cold-start hardening → typography redesign.

**Updated:** 2026-05-13 (origin deploy is still in the disposable DigitalOcean host-spike stage, not app deployment. Real bug-bash evidence proved local Mac cross-arch Docker builds are not trustworthy without Buildx and the 1 GiB DO host cannot build the app without OOM. The next deploy slice must use a prebuilt image digest and measure the 1 GiB host as runtime-only).

---

## Big-picture phases

| Phase | Status | Notes |
|---|---|---|
| 0 — Local dev environment running | ✅ done | Docker/Colima socket reconciliation, postgres reset, css container fix |
| 1 — Cleanup compile warnings | ✅ done | 24 → 0 |
| 1.5 — Static-analysis cleanup (Credo/Sobelow/Dialyzer) | ✅ done | All green |
| 1.6 — Test failure triage | ✅ done | 5 → 4 failures (env fixes); 4 → 2 after Tier-1 (registry refactor) |
| Skill authoring | ✅ done | `elixir-phoenix-style` skill, 7 files, 1550 lines, 255-source literature run |
| Pre-merge merge to main | ✅ done | Done before deps upgrade per original plan |
| 2.0 — Tier-1 prep | ✅ done | Registry sync refactor, Routes → ~p, dns_cluster removed, prod debug-log purge |
| 2.1 — Group 1 (dev/test tooling) | ✅ done | credo, dialyxir, ex_doc, excoveralls, sobelow, mox, floki, jason |
| 2.2 — Group 2 (Ecto) | ✅ done | ecto_sql 3.11→3.13, postgrex 0.18→0.22 |
| 2.3 — Group 3 (other libs) | ✅ done | cachex 3→4, gettext 0.24→0.26, swoosh, finch, cowboy, etc. |
| 2.4 — Group 4 (Phoenix ecosystem) | ✅ done | phoenix 1.7→1.8, LV 0.20→1.1.30 |
| 2.5 — Group 5 (JS-only deps) | ✅ done | `9053f70` — vitest 2→4, biome 1→2, esbuild 0.23→0.28, jsdom 25→29 (forced Node 22.9→22.21 in Dockerfile), stylelint 16→17, vite added as vitest peer. |
| 2.6 — Push final to origin | ✅ done | All commits pushed; tag baseline `9053f70`. |
| 2.7 — Triage GitHub vulnerabilities | ✅ done | All 213 historical npm alerts auto-resolved by the Group 5 upgrade (timestamps line up exactly with the push). 0 open, 0 hex/elixir-side advisories. The 48-figure on push was a stale snapshot. |
| 3 — Deploy/ops scope | 🔄 **active** | `/grill-me` ran 2026-05-06. Vision + objectives + 6 strategies in `AGENTS.md`. Hard-constraints + taste-seeding cut short — re-run `/grill-me` next time. |
| 3.1 — Content deployability | 🔄 active | Feature branches now implement the authoring front door: content-repo CI runs draft safety, app validation, and shell lint through canonical `./run` commands; the app records accepted/rejected/ignored verdicts with content SHA and file/reason detail; bad pushes leave the previous live generation in place; deletion-only changes hard-404; mixed delete/add updates must preserve deleted live slugs through canonical URLs or `aliases:` with 301 redirects; content-only rollback is generation-aware; private repo auth is injected ephemerally into clone/fetch. Remaining: share-image generation/rendering/validation, deferred until the app/design work can make the OG image contract real. |
| 3.2 — CI gates | ✅ done | `Prod build` is required by branch protection. Gate covers release image build, migrations up/down/up, `/readyz`, route probes, release RPC introspection, public page budgets, and nightly schedule. |
| 3.3 — Resource-frugality of the app | ⏸ pending | Measure cold-start, p50, memory, cache-hit rate, and runtime footprint on the same ruler before choosing hardware. Cold-start audit at `.tmp/2026-05-05-upgrade-deep-dive/cold-start.md` queued. |
| 3.4 — Front-edge cache (CDN) | ⏸ pending | `/literature` required before tool selection. Needs app/cacheability measurements first. |
| 3.5 — Origin substrate + deploy pipeline | 🔄 active | Initial `/literature` complete, but Kamal is not ratified. Current path: GitHub Actions as deploy operator, Kamal as a possible ephemeral deploy-time adapter, and DigitalOcean Basic 1 GiB as the first disposable Docker-host spike. This is host bootstrap/runtime proof only: private preview, same-artifact promotion, live smoke, and app rollback do not exist yet. Manual DigitalOcean create/status/destroy workflow and scripts exist; local create/status/SSH/cloud-init/Docker/destroy passed against a real 1 GiB Droplet, then the Droplet was destroyed. Follow-up hardening added early receipts, failed-create cleanup, ownership-checked destroy, bounded readiness, tag-based listing, default-branch workflow checkout before secrets, and release-image publishing behind `Prod build`. The simple preview bug bash proved the 1 GiB host OOMs as a builder, so the next slice must deploy a prebuilt image digest and measure runtime memory/CPU/ready-route behavior. GitHub manual workflow proof waits until the workflow exists on the default branch. Static export is parked as a later performance/deploy simplification option, not the active path. |
| 3.6 — Observability + rollback loop | ⏸ planning-gated | `/literature` required before tool selection. Minimum signal set and rollback policy need planning; No Grafana (Z veto). |
| 3.7 — GitHub Actions Node 24 readiness | ✅ done | Workflows use Node 24 action majors for checkout, artifact upload, and Release Please; no temporary runtime override remains. |
| 4 — Tier-2/3 audit followups | ⏸ pending | ~24 inventoried, ranked. Pick what's load-bearing. |
| 5 — Typography redesign | ⏸ pending | Figma changes; JA/EN dynamic typography swap; optical alignment via `text-box-trim` (80% support) + existing fontkit polyfill. Touches `typography.ex`, `typography_helpers.ex`, the tailwind generator pipeline. |

---

## Active workstream — Phase 3 deploy/ops

Current order of operations:

1. **Lock the shipped CI guardrail.** Done: `Prod build` is required in branch protection and release automation has exercised the image build/publish path.
2. **Make content deployment deterministic.** Active feature branches now cover delivery dedupe, sync locking, accepted/rejected/ignored SHA recording, last-good boot fallback, content-repo CI, draft safety, rename aliases, content-only rollback, and private content-repo auth. The acceptance test is content deployability, not git freshness: the app must name the live content SHA, the last rejected SHA and reason, the last known-good SHA, and the rollback path. Next: keep share-image generation/preview/rendering with the later design/app-finish work rather than treating it as a standalone plumbing task.
3. **Measure before choosing origin hardware.** Use the prod-build vocabulary for live/local runs: time-to-ready, cold-first response, warm p50/p95, memory, CPU, and power where available. The next origin measurement must run a prebuilt image plus Postgres on the 1 GiB DO host and capture runtime memory, not build memory.
4. **Plan origin and edge only after measurements.** The philosophical constraint is smallest honest origin, free/FLOSS where viable, but visitor speed and rollback reliability are the floor.
5. **Plan observability around deploy evidence.** Minimum useful signals: request health, release identity, content SHA, BEAM/runtime health, DB boundary, and cache/origin split after an edge substrate exists.

---

## Parked / known issues (not blocking)

| Item | Status |
|---|---|
| 2 typography-slot test failures | Deferred per typography rewrite plan |
| Tailwind v3 → v4 | Explicitly rejected this round |
| Heroicons replacement | Decided to keep `:heroicons` Hex dep |
| Multi refactor in `content.ex` | Has semantic risk; agent flagged for separate handling |
| Logger debug strip vs. compile_time_purge | Compile-time purge in prod is in place; per-call lift to info if needed |
| Tier-2/3 audit recommendations | ~24 inventoried, none load-bearing for the upgrade |

## Cross-references

- Skill: `~/.agents/skills/elixir-phoenix-style/` (symlinked at `.agents/skills/elixir-phoenix-style/`)
- Literature: `.tmp/2026-05-05-elixir-phoenix-style/literature/` (255 sources)
- Audits: `.tmp/2026-05-05-upgrade-deep-dive/{web-layer,domain-layer,cold-start}.md`
- Ash decision: `.tmp/2026-05-05-ash-framework/literature/brief.md` — verdict don't adopt
- Tier-1 plan: `.tmp/2026-05-05-repo-cleanup/PLAN.md`

## How this doc gets updated

- After each completed sub-phase: mark ✅ in the table, note the commit hash if useful.
- New parked items go in the parked table, not buried in narrative.
- When the typography redesign starts, this doc gets archived and a fresh one starts for that phase.
