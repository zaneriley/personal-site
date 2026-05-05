# Portfolio revival — running TODO

Started 2026-05-05 with the branch `frontend-infra` ("Backup from broken mac"). This doc tracks where we are in the bigger arc: get the repo working → clean it up → upgrade deps → merge to main → cold-start hardening → typography redesign.

**Updated:** 2026-05-06 (deps + dependabot done; deploy/ops scope grilled into `AGENTS.md`).

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
| 3.1 — Content-pipeline sync | ⏸ next | `personal-website-content` webhook hardening. PM rank #1 — site is meaningless without content. |
| 3.2 — CI gates | ⏸ pending | LLM-mistake catcher. Parallelizable with 3.1. |
| 3.3 — Resource-frugality of the app | ⏸ pending | Measure cold-start, p50, memory, cache-hit rate. Cold-start audit at `.tmp/2026-05-05-upgrade-deep-dive/cold-start.md` queued. **Hardware decision falls out of this, not before.** |
| 3.4 — Front-edge cache (CDN) | ⏸ pending | `/literature` required before tool selection. |
| 3.5 — Origin substrate + deploy pipeline | ⏸ pending | `/literature` required. Hardware + blue/green + deploy mechanics. |
| 3.6 — Observability + rollback loop | ⏸ pending | `/literature` required. No Grafana (Z veto). |
| 4 — Tier-2/3 audit followups | ⏸ pending | ~24 inventoried, ranked. Pick what's load-bearing. |
| 5 — Typography redesign | ⏸ pending | Figma changes; JA/EN dynamic typography swap; optical alignment via `text-box-trim` (80% support) + existing fontkit polyfill. Touches `typography.ex`, `typography_helpers.ex`, the tailwind generator pipeline. |

---

## Active workstream — Group 5 (JS-only deps)

In-flight as of this writing. Constraints:
- Tailwind v3 stays (Z's ratification 2026-05-05 — cross-arch Docker bug + no daisyUI need + portfolio scale).
- Skip new tooling; bump existing only.
- Each version bump verified by `mix compile clean` + `vitest run` + route smoke + `mix test --seed 0`.

Bumping (per `assets/package.json`):
- `@biomejs/biome` 1.9 → 2.4 (major)
- `@vitest/*` + `vitest` 2.1 → 4.1 (two majors)
- `esbuild` 0.23 → 0.28
- `jsdom` 25 → 29 (forces Node base image bump from 22.9 to 22.21 in Dockerfile)
- `playwright` 1.48 → 1.59
- `postcss` 8.4 → 8.5; `postcss-import` 16.1.0 → 16.1.1
- `prettier` 3.3 → 3.8
- `stylelint` 16 → 17 (major); `stylelint-config-standard` 36 → 40 (major); `stylelint-config-tailwindcss` 0.0.7 → 1.0 (major)
- `@types/fontkit` 2.0.7 → 2.0.9
- `autoprefixer` 10.4 → 10.5
- `topbar` 3.0.0 → 3.0.1

Already done:
- Node base image bumped 22.9 → 22.21 in Dockerfile (jsdom 29 needed it).

Not yet done:
- yarn install resolution + verify build works
- vitest config compatibility with v4
- biome config compatibility with v2
- stylelint config compatibility with v17

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
