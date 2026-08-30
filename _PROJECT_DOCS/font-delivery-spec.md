# Font delivery: private sources, honest CI

**Status:** direction ratified 2026-08-30 (private repository + build-time
generation); not yet implemented. This file is the plan, the impact-site
inventory, and the verification contract. Record actuals here when the slice
ships.

## Decisions already made — do not reopen

- **Subsetting stays.** Ratified 2026-08-30; the speed win is the point. No
  further license archaeology; purchase receipts live beside the fonts (below).
- **Licensed bytes never enter the public repository, even encrypted** —
  encrypted redistribution is still redistribution.
- **The channel is a private GitHub repository plus a read-only deploy key.**
  Rejected: encrypted blob in this repo (legal), object storage (external
  service + credential rotation for five files that change roughly never),
  self-hosted runner (arbitrary code from fork PRs runs on the machine —
  never for a public repo), CI caches (not canonical storage).

## The design

**1. The private repository** (e.g. `personal-site-fonts`) is the canonical
home of the pristine source faces — the files now living untracked in
`assets/fonts/src/`. Sources only, never generated woff2 (reproduction is the
idempotency contract, ADR 0004). Purchase receipts and license PDFs live in
the same repo, beside the faces they cover.

**2. Local setup:** clone the private repo directly at `assets/fonts/src/`.
The path is gitignored, so a nested repository there is invisible to this
repo. Everything local behaves exactly as today.

**3. CI fetch:** one step in each workflow that builds the app image —
`actions/checkout` of the private repo into `assets/fonts/src/`, authenticated
with a read-only deploy key scoped to that single repository, stored as an
Actions secret. **Mirror the secret into the Dependabot secrets store** —
Dependabot PRs use a separate secrets context, and forgetting this recreates
"red for the wrong reason" on every dependency PR.

**4. Generation moves into the image build.** The Dockerfile assets stage runs
`node fonts/generate-fonts.mjs` after `yarn install`. This gives one canonical
path for every environment: any build, anywhere, regenerates the woff2 from
sources — no reliance on whatever happened to be sitting in a working tree
(which is exactly the accident that made local images honest and CI images
fictional without anyone deciding that).

**5. Fail loudly, and assert drift.** Two properties, both deliberate:
- A build **without** sources must fail the build — the generator erroring on
  a missing directory is the desired behavior, not a case to handle. No
  fallback, no fontless "success."
- The generator writes `_fontface.generated.css`; the committed copy is
  canonical. The build compares its freshly generated CSS against the
  committed file (`cmp`) and fails on any difference — catching generator or
  manifest drift at build time instead of at review time.

## Impact-site inventory (enumerated 2026-08-30, verify each during the slice)

| Site | What changes / what to check |
|---|---|
| `.github/workflows/prod-build.yml` | Add the checkout step (runs on every PR — the main payoff site) |
| `.github/workflows/release-please.yml` | Same step in the `prod-build-gate` job |
| `.github/workflows/private-preview-deploy.yml` | Same step; previews currently ship fontless too |
| `.github/workflows/ci.yml` | **No change** — test/lint jobs don't serve fonts; confirm nothing in them touches `priv/static/fonts` |
| `Dockerfile` assets stage | Generator invocation + the `cmp` drift assertion |
| `.gitignore:14-15` | `*.woff` / `*.woff2` are ignored **globally**, not per-directory — leave for now, but know that any future legitimately-committable font file will silently vanish; scope to the two font directories if that ever bites |
| `.dockerignore` | Confirmed: does not exclude fonts — sources checked out pre-build reach the build context |
| Build-flow trace | assets stage → `priv/static/fonts/` (via the esbuild static copy) → `mix phx.digest` → prod stage `COPY --from=dev /public`. Confirm fonts appear in `cache_manifest.json` in a CI-built image |
| `root.html.heex:142` preload | Literal non-digested `/fonts/gt-flexa.woff2` — byte-matched to the CSS `url()` per ADR 0004; no change, but any digested-paths work (the edge-caching prerequisite) must move both together |
| `ci/gates/browser-performance.mjs` | No change — but its three 404-driven failure classes are the *verification signal* (below) |
| `ci/contracts/routes.json` | No change — the 380,000 font ratchet was set from honest local numbers and should hold as-is in CI |
| Docs | `BACKLOG.md` release-blocker entry; `page-weight.md` "What CI measures is not what visitors get" section becomes historical; ADR 0004 deferral #4 gets the commit hash |
| Deploy/preview receipts | Preview acceptance runs against built images; first preview after this ships fonts for the first time — expect its page-weight observations to jump accordingly |

Search commands used to build this inventory (rerun during implementation to
catch drift): `grep -rn "fonts/"` over `lib/ assets/ Dockerfile`, `grep -l
docker .github/workflows/*.yml`, `grep -n woff .gitignore .dockerignore`.

## Verification: how we know it worked

Run after the slice, in order. Expected values are from the 2026-08-30
measured baseline.

1. **The build fails without fonts (negative test, run first).** On a scratch
   branch with the checkout step deleted, the workflow must go red at the
   generator, not green-and-fontless. This proves fail-loudly before proving
   success.
2. **CI stops lying.** On a real PR: `font_bytes` ≈ 373,191 (was 0), zero
   font 404s, and the three 404-driven failure classes (`console_errors`,
   `request_failures`, `failed_resource_status`) gone from the artifact.
3. **Reproduction holds across machines.** sha256 of each CI-generated woff2
   printed in the build log matches a local `./run assets:fonts` run —
   same sources + pinned deps ⇒ identical bytes. Any mismatch is a real
   finding (environment-dependent generation), not noise to tolerate.
4. **The digest manifest carries the fonts.** `cache_manifest.json` inside
   the CI-built image lists all five faces.
5. **Dependabot proof.** Rebase one Dependabot PR after mirroring the secret;
   its Prod build must pass. Skipping this check is how the secrets-context
   trap ships.
6. **The payoff assertion: PR #-next merges without the admin bypass.** Every
   required check green in CI, branch protection satisfied normally. This is
   the observable end state that defines "works as intended."

## Line budget, declared before building

| Piece | Budget |
|---|---|
| Workflow checkout step × 3 | ≤ 18 (≈6 each; duplicated deliberately — a shared action for three identical stanzas is ceremony) |
| Dockerfile: generation + drift assertion | ≤ 6 |
| **Total** | **≤ 24 code lines, 0 new dependencies, 1 secret (+ its Dependabot mirror), 1 private repo** |

Tripwire: if this wants a new script, a fallback path, or a "skip fonts"
flag anywhere, stop — the design's whole value is that fontless builds are
impossible, not optional.

## Out of scope

- Digested font/CSS paths (separate item; prerequisite for edge caching).
- Latin Extended-A removal and display-face subsetting (ratchet tighteners,
  listed under the ADR 0006 entry in `BACKLOG.md`).
- Any change to which faces ship. This slice moves bytes' *provenance*, not
  the bytes.
