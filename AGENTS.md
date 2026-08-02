# Personal Site

Personal Site is the Phoenix/LiveView application behind `zaneriley.com`.

## Project map

- `lib/portfolio/` — content, publication, persistence, and application logic.
- `lib/portfolio_web/` — routes, LiveViews, controllers, and components.
- `assets/` — JavaScript, CSS, typography generation, fonts, and Vitest tests.
- `test/` — ExUnit tests and shared test support.
- `ci/` — release, preview, publication, and acceptance-gate implementation.
  Read `ci/README.md` before changing this surface.
- `_PROJECT_DOCS/` — current work, contracts, and decision records. Start with
  `_PROJECT_DOCS/README.md`.
- `.agents/skills/` — task-specific workflows. Follow the matching skill instead
  of duplicating its instructions here.

## Work locally

```bash
./run help
./run dev:setup
./run dev:start
./run dev:format
./run dev:test
./run ci:all
```

Do not run host `mix`, `yarn`, `npx`, or database tools; use the corresponding
`./run` command. Some `deploy:*` commands allocate paid infrastructure. Run them
only when the task explicitly calls for a preview or deploy proof.

## Read only what the task needs

- Current work: `_PROJECT_DOCS/BACKLOG.md`
- Architecture decisions: `_PROJECT_DOCS/adrs/`
- Content authoring: `_PROJECT_DOCS/content-authoring-contract.md`
- Feed behavior: `_PROJECT_DOCS/feeds-spec.md`
- CI and deploy ownership: `ci/README.md`; executable behavior: `./run`
- Elixir/Phoenix edits: `.agents/skills/elixir-phoenix-style/SKILL.md`
- Infrastructure/tool selection: run a literature pass before choosing CDN,
  secrets, deploy substrate, or observability tooling. Grafana is out of scope.

Do not preload the documentation tree. Start with the nearest owner and follow
its links.

## Backlog

This repository follows the same split as Push Search: `AGENTS.md` is the
bootstrap spine, and `_PROJECT_DOCS/BACKLOG.md` is the canonical current-work
index. Load the backlog only when choosing or scoping current work.
