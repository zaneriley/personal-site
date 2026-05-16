# CI

This folder holds the checks that keep a broken branch from reaching visitors.
Start with `./run`; it is the command surface. Files under `ci/` are either
checked-in inputs or scripts that run those inputs. Generated proof belongs in
`.tmp/ci-artifacts/`.

## Where Things Go

- `contracts/` says what the site must prove: routes, page text, browser checks, and performance budgets.
- `fixtures/` holds small posts and case studies used to prove real detail pages render.
- `gates/` holds checks that can block a merge.
- `preview/` deploys a candidate image to a disposable host and checks whether its pages look real in a browser.
- `providers/` holds paid host plumbing. DigitalOcean lives there because it is one provider, not the deploy model.

## Commands

- `./run ci:prod-build` asks, "would this release boot and serve the pages visitors need?"
- `./run ci:performance-browser` asks, "are public pages still small and quick in a real browser?"
- `./run ci:preview-page-acceptance:test` checks the browser assertions without deploying anything.
- `./run ci:disposable-host-check` checks host scripts and runtime inputs without creating a cloud server.
- `./run host:disposable:*` creates, inspects, destroys, or tests a short-lived host.
- `./run preview:deploy --app-image-ref <digest-ref> --app-sha <sha> --preview-page-acceptance-image <trusted-image>` writes one private preview receipt.
- `./run preview:destroy <deploy-receipt.json>` destroys the disposable host recorded by a preview deploy.

## Adding Work

Add new route, text, browser, or performance expectations to
`contracts/routes.json` first. Do not make a second route list in a script.

Add receipts, screenshots, and last-run JSON under `.tmp/ci-artifacts/`. Do not
put generated files beside the scripts that produced them.

For preview deploys, start with `.tmp/ci-artifacts/preview/deploy-receipt.json`.
Terminal output, GitHub summaries, and failure markdown are rendered views of
that receipt; stage logs and screenshots are supporting evidence linked from it.
