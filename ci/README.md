# CI Layout

This directory is organized by job, not provider.

- `contracts/` holds durable verification inputs shared by gates.
- `fixtures/` holds committed content used by CI.
- `gates/` holds merge-gate checks run by `./run ci:*`.
- `preview/` holds runtime viability and page acceptance checks for candidate previews.
- `providers/` holds provider-specific host lifecycle adapters such as DigitalOcean.

Generated evidence belongs under `.tmp/ci-artifacts/`, never beside the scripts.

Start from `./run` for commands. Current entrypoints:

- `./run ci:prod-build` runs the release-shaped production build gate.
- `./run ci:performance-browser` runs the public page budget check against a live local app.
- `./run ci:preview-page-acceptance:test` runs the browser assertion fixture suite.
- `./run ci:disposable-host-check` runs provider/runtime input tests without creating a cloud host.
- `./run host:disposable:*` creates, inspects, destroys, or checks a short-lived host.

Add new route, text, browser, or performance expectations to `contracts/routes.json` first. Add generated receipts, screenshots, or last-run JSON under `.tmp/ci-artifacts/`.
