# ADR 0001 — Production-build CI gates

**Status:** accepted 2026-05-07; implemented and promoted to required branch protection 2026-05-07.
**Supersedes:** none.
**Superseded by:** none.

Implementation-PR scope (workflow yaml + Phoenix readiness controller + entrypoint patch + `ci/` scripts) follows this ADR. Tactical PR-level notes live in `.tmp/`, not here.

## Context

The repo's vision (`AGENTS.md:38-42`) is a portfolio "visitors never see broken … with a deploy pipeline that doesn't require remembering anything six months later. CI catches LLM-authored mistakes before they merge." Today CI runs only `MIX_ENV=test` (`.github/workflows/ci.yml:20-46`). The class of mistakes that surfaces only in `MIX_ENV=prod` — `Mix.env()` called at runtime, missing `:applications` declarations, `runtime.exs` config gaps, `cache_static_manifest` failures, dev-only deps leaking — is invisible until first deploy attempt.

A prod-build CI gate produces *continuous* signal on every PR. It also subsumes one-shot resource-frugality measurement (sub-phase 3.3, tracker `:30`): latency baselines accumulate on the same ruler each commit.

## Deployability contract

For this repo, *deployable* means a specific app artifact and a specific content state can be promoted to an origin without fresh human reasoning. The artifact is not just "whatever is on `main`": it is the tuple of app image digest, app git SHA or release tag, content repo commit SHA, DB migration version, and runtime config generation.

There are four deployability levels:

- **PR deployable**: the proposed app code passes acceptance gates, builds a prod release, boots with image-baked content, serves canonical routes, and stays inside the CI-side speed floor or baseline-drift policy.
- **Release deployable**: the release tag creates an image that can be identified by tag, SHA, and digest; Release Please can merge only after the required gates pass.
- **Content deployable**: a content repo commit can be authenticated, deduped, synced, parsed, and either promoted or rejected without preventing the app from booting. The configured repo URL in `.env.example` currently points at `personal-site-content`; earlier planning notes may call this `personal-website-content`.
- **Origin deployable**: the selected origin can pull or receive the release artifact, run migrations, flip blue/green, pass live smoke, and roll back to the last known-good app/content pair.

This ADR implements the first level and prepares the second. Content and origin deployability remain follow-up work because they involve the webhook/sync path and the deploy substrate.

## Developer experience

The desired DX is "push, read the verdict, act only when the verdict is actionable."

For app-code work:

- A PR shows the existing acceptance gates plus a separate `prod-build` gate. The failing check name tells whether the problem is test code, static analysis, security, workflow shape, secret scan, or production deployability.
- When `prod-build` fails, the log points to the failed phase: prod deps, prod compile, assets, release assembly, migration round-trip, boot, readiness, route smoke, RPC introspection, or speed regression.
- The same gate can run locally as `./run ci:prod-build` once implemented. If a raw lower-level command is used while debugging, the final verdict still comes from the canonical `./run` task.
- A green PR means "safe to merge into the release automation," not "served to visitors." The deploy substrate and live-origin smoke are later gates.

For release work:

- Conventional commits feed Release Please.
- Release Please opens or updates the release PR.
- Auto-merge waits on the required gates, including `Prod build`.
- A merged release creates an image tagged by release and commit SHA. Future deploy tooling consumes that identity, not a floating local build.

For content work:

- Publishing a blog/content repo change should feel like a content deploy, not an SSH session.
- The content pipeline records the content commit SHA that the app accepted.
- If content sync fails, the site keeps serving the previous content state and reports the failed commit.
- If content is broken after promotion, rollback targets the previous app/content pair or the previous content commit alone.

For nightly work:

- Nightly reruns the prod-build gate against `main` and records speed data.
- Green nightly runs should be quiet.
- Red nightly runs should report the failing phase and the last good app/content identity. [Z to fill: notification destination]
- Nightly does not deploy by itself until origin deployability and rollback gates exist.

The operator experience this ADR rejects: reading raw Actions logs to infer whether a Phoenix release is safe, discovering prod-only failures on the origin, manually remembering which blog commit is live, or treating image `latest` as rollback identity.

## Hard constraints

Binding from `AGENTS.md:65-76` (and global `~/.agents/AGENTS.md` §3 anti-rationalization):

- No tool/stack prescription without `/literature` first. Citations to the run at `.tmp/2026-05-06-phoenix-prod-ci-gate/literature/brief.md` are the basis for every recommendation below; full URLs inlined in the **References** section so the ADR is self-contained when `.tmp/` ages out.
- Versioned + idempotent deploys.
- Speed wins ties.
- Compute-per-watt floor; never at user expense.
- Touch only what you're asked to touch; one commit, one concern.

Ratified by Z 2026-05-06: ADRs live in `_PROJECT_DOCS/adrs/` and are not embedded in `AGENTS.md`. AGENTS.md is for always-needed direction and workflows + lookup pointers.

## GitHub coupling — kept thin

Principle: the gate is a **shell pipeline that happens to run on GitHub Actions**, not a GitHub-native workflow. If CI migrates off GitHub, the *commands* port unchanged; only the wrapping yaml changes.

| GitHub-specific surface | Load-bearing for | Replaceable with |
|---|---|---|
| `actions/checkout@v4` | correctness + portable | `git clone` on any runner |
| `actions/cache@v4` | optimization-only + portable | local volume, S3, gitlab cache |
| `services: postgres:` | correctness + portable | `docker run postgres` on any runner |
| `${{ runner.os }}` interpolation in cache key | optimization-only + portable | hard-coded `linux-x64` outside GH |
| `${{ hashFiles(...) }}` in cache key | optimization-only + portable | `sha1sum` in shell |
| `if: failure()` / `if: always()` step-meta | step-meta only + tolerable GH-ism | per-runner equivalent or omit |

Explicitly avoided:

- **No third-party Actions** for gate logic. `oha`, `gitleaks`, future scanners install via direct `curl + tar` of release tarballs (precedent: `.github/workflows/secret-scan.yml`).
- **No `gh-pages` for baseline storage.** Baseline lives in `ci/baseline.json` checked into the repo (precedent: `.gitleaks.baseline.json` in PR #51).
- **No GH Check API** beyond standard exit codes.
- **No GitHub Secret Scanning or Dependabot** dependency.
- **No load-bearing GH-only artifact storage.** `actions/upload-artifact@v4` uploads exist for human inspection only; the gate's verdict logic never reads them back.
- **No `${{ github.ref }}` branch conditionals in yaml.** Branch logic lives in `ci/update-baseline.sh`.

**Invariant:** `ci/*.sh` may set the app's existing runtime variables whose names start with `GITHUB_`, such as `GITHUB_WEBHOOK_SECRET`, but it must not consume GitHub Actions-provided `$GITHUB_*` metadata or call the `gh` CLI. That keeps the gate portable without renaming application configuration in this slice.

## Decisions

Each decision is `recommendation from /literature → adoption verdict → citation`. Citations resolve in **References** below.

### Group A — Build pipeline (`MIX_ENV=prod`)

#### deps-prod-only

`MIX_ENV=prod mix deps.get --only prod`. Excludes dev-only deps from the resolved tree; forces dev-only-dep leakage to surface in CI rather than at deploy. Cite `[p101] [p103] [p117]`.

#### compile-warnings-as-errors

`MIX_ENV=prod mix compile --warnings-as-errors`. Catches: `LiveDashboard` referenced from a shared template (`[p115]`), `Mix.env()` at runtime (`[p119]`), compile-time module-attribute bake-in (`[p120]`). Authoritative endorsement: Dashbit `[p118]`. Set `CI: false` for the next step (`[p127]` — JS toolchain treats `CI=true` as warnings-as-errors).

#### assets-deploy

`MIX_ENV=prod mix assets.deploy`. Canonical Phoenix 1.7+ task: bundles esbuild + tailwind with `--minify`, runs `mix phx.digest`, generates `priv/static/cache_manifest.json`. Without this, boot crashes on `cache_manifest.json not found` (`[p121]`).

#### mix-release

`MIX_ENV=prod mix release`. Catches strictly more than compile-only: missing `:applications` (`[p116]`), `runtime.exs`-only failures including `server: true` (`[p114]`), assembly-time path / permission issues. Cite `[p101] [p114] [p116] [p117] [p119]`.

### Group B — Boot harness

#### bypass-content-pull

The release boot script (`bin/docker-entrypoint-web`) currently runs `Portfolio.Release.pull_repository/0` against GitHub. CI must not depend on GitHub.com reachability. Honor `CI_SKIP_CONTENT_PULL=1` in the entrypoint; CI sets it and serves the image-baked `priv/content` snapshot at `/app/priv/content`. Pattern matches `[p102] [p126]`. Localized to the entrypoint script — `CI_SKIP_CONTENT_PULL` MUST NOT leak into application code (avoids dev/prod drift, `[p120]`).

#### runtime-config-discipline

`runtime.exs` MUST use `config_env() == :prod`, never `Mix.env()` (`[p119] [p110]`). Enforced by review until a Credo rule lands (out of scope for this ADR).

#### readiness-endpoint

`GET /readyz` returns 200 OK after `Repo` and `Endpoint` are up. Pattern: `[p102] [p113]`. The 30s retry loop interposed before the smoke and latency-probe steps is a *readiness* check, not a *liveness* check — name is `/readyz` (not `/healthz`) per S5 of the IA/DDD peer-review. `lib/portfolio_web/controllers/readiness_controller.ex` + a route in `router.ex`.

```bash
for _i in $(seq 1 30); do
  curl -sf "http://localhost:${APP_PORT:-4000}/readyz" && break || sleep 1
done
```

#### migrations-roundtrip

Locked rule per `~/.agents/skills/elixir-phoenix-style/`: migration round-trip in CI on a fresh DB.

```yaml
- name: Migrations round-trip
  run: |
    bin/portfolio eval "Portfolio.Release.migrate()"
    bin/portfolio eval "Portfolio.Release.rollback(Portfolio.Repo, 1)"
    bin/portfolio eval "Portfolio.Release.migrate()"
```

`Portfolio.Release.rollback/2` already exists at `lib/portfolio/release.ex:123` with arity `(repo, version)`. No new code needed for this decision.

### Group C — Measurement

#### latency-probe-tool

`oha` (Rust binary, single static install via release tarball). `oha <url> -n 30 --json --no-tui` outputs p50/p95/p99/min/max/stddev/req-per-second per route. Boring, obvious fit (`[p111]`). Reject `curl` bash loop (fragile parsing), reject `k6`/`playwright` (overkill), `wrk`/`hey` are inferior to `oha`. **N=30 per route**, not N=10 — the academic floor for stable p50 estimates on noisy infrastructure (`[p108]`).

#### perf-budget-policy

The 200ms p50 figure (`AGENTS.md:53`, sub-phase 3.3 frugality target) stays valid as the *production* target. Enforced as an absolute gate on `ubuntu-latest` it is structurally fragile: 2.66% CV (`[p105]`), CPU-SKU rotation 5–10% across runs (`[p106]`).

Adopted CI-side policy:

- **Absolute floor: 1000ms p50** (5× the production target; catches catastrophic regressions only).
- **Rolling-30-main-branch median + 20% drift** (catches creeping regressions).
- **Disabled until 30 main-branch runs accumulate.**

Cite `[p108] [p122] [p123] [p124]`.

#### cold-start-measurement

Captured separately from warm p50:

- **Time to ready** — from `bin/portfolio start` to first 200 on `/readyz`.
- **Cold response** — `oha -n 1 -c 1` on the first request.

Both written to `ci/baseline.json` for trend tracking. Ties to the 400ms cold-start target in the queued cold-start audit (`.tmp/2026-05-05-upgrade-deep-dive/cold-start.md`). Not gated initially.

#### release-rpc-introspection

After the latency probe is green, run `bin/portfolio rpc` against the booted release to confirm:

- `Application.spec(:portfolio, :vsn)` is readable and logged next to the app SHA.
- Supervision tree intact.
- `Portfolio.Repo` serves a query.

Adds ~3 seconds; catches "boot ran but app silently degraded" — a class HTTP probes alone don't cover (`[p112] [p125]`).

### Group D — Persistence

#### latency-baseline-file

`ci/baseline.json` (durable, repo-checked, updated on main only). Schema in repo's vocabulary, **not** `oha`'s output shape (avoids conformist anti-pattern):

```json
{
  "runs_count": <int>,
  "routes": {
    "/en": {"warm_p50_ms": <int>, "warm_p95_ms": <int>, "cold_first_ms": <int>, ...},
    ...
  },
  "ready_ms_median": <int>,
  "last_updated_main_sha": "<sha>"
}
```

The `ci/update-baseline.sh` script translates `oha`'s output into this schema; if `oha` ships v2 with renamed fields, the translation step changes, not the baseline file format.

When `runs_count >= 30`, the perf-budget gate transitions from disabled (logging-only) to enforcing.

#### routes-known-broken

`ci/routes-known-broken.txt`, one route per line, with a `# why:` comment per entry. Initial state: empty. New failures fix-or-revert; deferring requires explicit edit + justification commit. *Not* a ratchet — additions are allowed but require ceremony; the file is an exemption list, not a monotone-shrinking pile.

## Workflow shape (concrete)

> Current-path note, 2026-05-16: the accepted gate contract below is still
> current, but the file paths were reorganized by the CI IA reset. Current live
> inputs are under `ci/contracts/`, gate scripts under `ci/gates/`, and generated
> evidence under `.tmp/ci-artifacts/`.

```yaml
name: "Prod build"

on:
  pull_request:
  push:
    branches: ["main"]
  schedule:
    - cron: "17 9 * * *"
  workflow_dispatch:

jobs:
  prod-build:
    name: "Prod build"
    runs-on: "ubuntu-22.04"

    steps:
      - uses: "actions/checkout@v4"
      - name: "Install CI dependencies"
        run: ./run ci:install-deps
      - name: "Prod build"
        run: ./run ci:prod-build
      - name: "Upload prod-build measurements"
        if: always()
        uses: "actions/upload-artifact@v4"
        with:
          name: "prod-build-measurements"
          path: |
            ci/last-run.json
            ci/baseline.json
```

`ci/prod-build.sh` owns the release build, migration round-trip, boot, readiness wait, route probe, RPC introspection, comparison, and baseline update. `ci/probe-routes.sh`, `ci/compare.sh`, and `ci/update-baseline.sh` are thin shell wrappers around `oha` and `jq`. They contain all branch conditionals (`update-baseline.sh` exits 0 unless on `main`) and translate `oha`-shaped JSON into the repo-native baseline schema.

## Mistake classes caught

| Mistake class | Caught by |
|---|---|
| Dev-only dep referenced in shared template | compile-warnings-as-errors (`[p115]`) |
| `Mix.env()` called at runtime in a release | mix-release boot — crashes on first call (`[p119]`) |
| `server: true` missing from `runtime.exs` | readiness-endpoint wait — port doesn't bind (`[p114]`) |
| Compile-time module-attribute bakes wrong value | latency-probe-tool — wrong response (`[p120]`) |
| `:applications` vs `:extra_applications` mistake | mix-release — load failure (`[p116]`) |
| `cache_static_manifest` missing | prevented by assets-deploy (`[p121]`) |
| Migration ran but cannot roll back | migrations-roundtrip |
| Boot succeeded but supervision tree silently degraded | release-rpc-introspection |
| Deps resolution leaks dev-only deps to prod tree | deps-prod-only |
| Slow regression below catastrophic floor (1000ms+) | perf-budget-policy floor |
| Creeping regression (>20% drift over rolling-30 main median) | perf-budget-policy drift gate |
| Newly-broken canonical route on a PR | latency-probe-tool + routes-known-broken (no entry → fail) |

## What this gate doesn't catch

- Multi-arch image differences (sub-phase 3.5 — deploy substrate).
- Deploy-time concerns: blue/green flip, post-deploy smoke against live origin, traffic-served verification.
- Observability concerns (sub-phase 3.6).
- Real GitHub-webhook integration (sub-phase 3.1).

## Open questions / future work

- **Compile-time-only-value lint** — Credo rule for `Application.compile_env/3` misuse (`[p110] [p120]`). Out of scope for this ADR.
- **Cache reset on retry hygiene** (`[p104]`). Over-engineered for personal-site scale; revisit if flakes appear.
- **Multi-arch latency probe** — when sub-phase 3.5 lands, decide between QEMU-on-ARM (slow, exact) and trust-multi-arch-image-equivalence (fast, cogini-style `[p102]`).
- **`bench/` for actual `mix bench` benchmarks** — directory deliberately reserved by this ADR's choice of `ci/`.

## Caveats

The literature peer-review run at `.tmp/2026-05-06-phoenix-prod-ci-gate/literature/brief.md` has no published `ubuntu-latest` Phoenix HTTP-loop CV/latency benchmark. The first 30 main-branch runs *populate* the rolling baseline; the 1000ms floor and 20% drift threshold are derived defaults — **revisit when `ci/baseline.json` `runs_count >= 30`**, tracked as a self-trigger inside the baseline file.

## References

Each `[pNNN]` resolves to a primary source. Inlined here so the ADR is self-contained when `.tmp/` ages out.

| ID | Source | URL | One-line claim used |
|----|--------|-----|---------------------|
| `[p101]` | Phoenix Releases hexdocs | https://hexdocs.pm/phoenix/releases.html | Canonical Phoenix release-task contract; `mix release` + `assets.deploy` shape |
| `[p102]` | cogini/phoenix_container_example | https://github.com/cogini/phoenix_container_example | Reference prod-build CI pattern; readiness probe loop; CI-only entrypoint guards |
| `[p103]` | Richard Taylor — Elixir/Phoenix release workflow | https://richard.dev/articles/elixir-phoenix-release-workflow | `--only prod` discipline; release-vs-test pipeline split |
| `[p104]` | Felt — Hashrocket Ultimate Elixir CI | https://feltdev.com/blog/ultimate-elixir-ci | Cache-reset-on-retry as flake hygiene |
| `[p105]` | CodSpeed — runner noise study | https://codspeed.io/articles/runner-noise | 2.66% CV measured on `ubuntu-latest` |
| `[p106]` | CodSpeed — GLIBC variance | https://codspeed.io/articles/glibc-variance | CPU-SKU rotation effect on ubuntu-latest baseline |
| `[p108]` | arxiv 2408.08148 — early perf regression detection | https://arxiv.org/abs/2408.08148 | N=30 per measurement at component level for stable p50 |
| `[p110]` | ElixirForum — runtime.exs gotchas | https://elixirforum.com/t/runtime-exs-config-gotchas | `config_env()` not `Mix.env()` discipline |
| `[p111]` | oha vs hey vs wrk vs k6 vs bombardier | https://github.com/hatoo/oha#comparison | `oha` JSON output shape; single static binary |
| `[p112]` | cogini — K8s health checks for Elixir | https://github.com/cogini/elixir-health-checks | Readiness vs liveness probe split |
| `[p113]` | jola — Plug+Phoenix health checks | https://hexdocs.pm/jola/readme.html | `/readyz` retry loop pattern |
| `[p114]` | Phoenix issue #4695 — `server: true` in runtime.exs | https://github.com/phoenixframework/phoenix/issues/4695 | release "starts" but doesn't bind port if `server: true` missing |
| `[p115]` | Phoenix issue #4080 — LiveDashboard prod warning | https://github.com/phoenixframework/phoenix/issues/4080 | Dev-only dep referenced from shared template fires only in `MIX_ENV=prod` |
| `[p116]` | AmberBit — mix release missing deps | https://amberbit.com/blog/mix-release-missing-deps | `:applications` vs `:extra_applications` mistakes; release-assembly catch |
| `[p117]` | Codemancers — Phoenix release nuances | https://codemancers.com/blog/phoenix-release-nuances | runtime.exs evaluated only at release boot |
| `[p118]` | Dashbit — warnings as errors | https://dashbit.co/blog/warnings-as-errors | Authoritative `--warnings-as-errors` endorsement |
| `[p119]` | ElixirForum — Mix.env runtime crash | https://elixirforum.com/t/mix-env-runtime-crash | `Mix.env()` masked in `MIX_ENV=test`, crashes in release |
| `[p120]` | Felt — Elixir configuration tips | https://feltdev.com/blog/elixir-configuration-tips | `Application.compile_env/3` discipline |
| `[p121]` | Phoenix asset pipeline + cache_static_manifest | https://hexdocs.pm/phoenix/asset_management.html | `cache_manifest.json not found` boot crash if `assets.deploy` skipped |
| `[p122]` | Bencher.dev — continuous benchmarking | https://bencher.dev/docs/explanation/thresholds/ | Rolling baseline + drift threshold pattern |
| `[p123]` | github-action-benchmark | https://github.com/benchmark-action/github-action-benchmark | Default 200% drift gate; `gh-pages` vs in-repo baseline |
| `[p124]` | OneUptime — perf testing in GitHub Actions | https://oneuptime.com/blog/perf-testing-github-actions | N=100 with hyperfine; warm-up phase rule |
| `[p125]` | ElixirForum — `start_iex` / `rpc` | https://elixirforum.com/t/release-rpc-introspection | `bin/<app> rpc` introspection pattern |
| `[p126]` | Phoenix Railway nixpacks skip-migrate | https://railway.app/docs/phoenix-nixpacks | "skip migrate during build" idiom |
| `[p127]` | GitHub #25228 — `CI=true` warnings as errors | https://github.com/actions/runner/issues/25228 | JS toolchain treats `CI=true` as warnings-as-errors |
| `[p128]` | cogini — best practices deploying Elixir | https://www.cogini.com/blog/best-practices-deploying-elixir-apps | Ubuntu/Debian over Alpine for Elixir release |

(Manifest of all 30 sources, including those not cited here, is at `.tmp/2026-05-06-phoenix-prod-ci-gate/literature/manifest.md`. Manifest will be cleaned up when `.tmp/` ages out; the URLs above are the durable record.)

## Pointers

- `AGENTS.md:9-23` — acceptance gates (this ADR's gates extend the family).
- `AGENTS.md:38-42` — vision.
- `AGENTS.md:53` — strategy #2 (CI gates).
- `AGENTS.md:92` — ADR routing rule (amended same commit).
- `_PROJECT_DOCS/2026-revival-todo.md:29` — sub-phase 3.2 row (links to this ADR).
- `.github/workflows/ci.yml` — existing `MIX_ENV=test` pipeline.
- `.github/workflows/secret-scan.yml` (PR #51) — gitleaks gate; baseline-file pattern precedent.
- `.gitleaks.baseline.json` — durable-baseline-file shape this ADR borrows.
- `bin/docker-entrypoint-web:43-52` — current boot sequence (will honor `CI_SKIP_CONTENT_PULL`).
- `lib/portfolio/release.ex:123` — `rollback/2` (already exists; no new code).
- `lib/portfolio_web/endpoint.ex:18` — exposed HMAC literal (Task #4 op-side; rotation independent of this ADR).

## Implementation PR (follows ratification)

- `.github/workflows/prod-build.yml` (new — workflow above)
- `lib/portfolio_web/controllers/readiness_controller.ex` + route entry in `router.ex`
- `bin/docker-entrypoint-web` patch (honor `CI_SKIP_CONTENT_PULL=1`)
- `ci/probe-routes.sh`, `ci/compare.sh`, `ci/update-baseline.sh`
- `ci/routes-known-broken.txt` (initial empty)
- `ci/baseline.json` (initial `{"runs_count": 0, "routes": {}}`)

No application-code changes outside `lib/portfolio_web/controllers/readiness_controller.ex` and the `router.ex` route.
