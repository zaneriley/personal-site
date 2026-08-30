# Zane Riley's portfolio

The source for [zaneriley.com](https://zaneriley.com): a bilingual portfolio
built with Elixir, Phoenix LiveView, PostgreSQL, and a separate Markdown content
repository.

The application intentionally does more than a static portfolio. It exercises
content publication, last-good rollback, private preview deployment, feeds,
internationalization, and an optically aligned typography system while keeping
the public pages fast.

## Start here

Local tooling runs through Docker Compose. Do not install or run a host Elixir,
Node, or database toolchain for this repository.

```bash
./run help
./run dev:setup
./run dev:start
```

Then open [localhost:8000](http://localhost:8000). `dev:setup` creates `.env`
from `.env.example` when needed, builds the containers, starts PostgreSQL, and
waits for it to become ready, then initializes the database. Stop the stack
with:

```bash
./run dev:stop
```

Common development checks:

```bash
./run dev:format
./run dev:test
./run ci:lint
./run ci:test
./run ci:all
```

Run a focused Elixir test with:

```bash
./run dev:test:elixir test/portfolio_web/router_test.exs
```

Add `--verbose` to the focused Elixir command when application and Ecto SQL
debug logs are part of the investigation. Set `RUN_TIMING=1` for wrapper timing
or `RUN_VERBOSE=1` for wrapper/Mix invocation detail. Use
`TYPE_SCALE_DEBUG=1 ./run dev:test:js tests/tailwind/line-height.test.ts` for the
typography calculator trace.

## Project map

- `lib/portfolio/` — content, publication, persistence, and application logic.
- `lib/portfolio_web/` — Phoenix endpoint, routes, LiveViews, controllers, and
  components.
- `assets/` — JavaScript, CSS, typography generation, font tooling, and Vitest
  tests.
- `priv/repo/` — Ecto migrations and seed data.
- `test/` — ExUnit tests and shared test support.
- `config/` — environment-specific application configuration.
- `ci/` — checked-in contracts, fixtures, gates, preview implementation, and
  provider glue. Start with [ci/README.md](ci/README.md).
- `_PROJECT_DOCS/` — current work, durable contracts, and decision records.
  Start with
  [_PROJECT_DOCS/README.md](_PROJECT_DOCS/README.md).
- `.tmp/` — ignored measurements, research, and unfinished working evidence.

## Content and delivery

Authored Markdown lives in the separate `personal-site-content` repository.
This application validates and promotes content, records accepted/rejected/
ignored publication outcomes, preserves the last-good generation, and supports
content-only rollback. The author-facing contract is
[_PROJECT_DOCS/content-authoring-contract.md](_PROJECT_DOCS/content-authoring-contract.md).

The deploy and preview implementation is intentionally separated from the
content author workflow. Use `./run help` for the supported `deploy:*` commands
and [ci/README.md](ci/README.md) for their ownership and artifact paths. Some
preview/provider commands allocate paid infrastructure; do not run them as
ordinary local verification.

## Repository contracts

- [AGENTS.md](AGENTS.md) — concise repository map, command policy, and task
  routing for coding agents.
- [_PROJECT_DOCS/BACKLOG.md](_PROJECT_DOCS/BACKLOG.md) — canonical current work.
- [_PROJECT_DOCS/adrs/](_PROJECT_DOCS/adrs/) — accepted and proposed
  architectural decisions; each record's status is authoritative.
- [.github/workflows/ci.yml](.github/workflows/ci.yml) — top-level CI wiring;
  executable gate behavior remains in `./run`.

## License and history

The project is licensed under [AGPL-3.0](LICENSE).

Earlier portfolio versions used React/Next.js (2016–2024), vanilla JavaScript
(2014–2016), and Flash (2010). The Phoenix version began from Nick Janetakis's
Docker Phoenix example and has since grown its own content and deployment
architecture.
