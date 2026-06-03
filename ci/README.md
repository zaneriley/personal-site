# CI

This folder holds the checks that keep a broken branch from reaching visitors.
Start with `./run`; it is the command surface. Files under `ci/` are either
checked-in inputs or scripts that run those inputs. Generated proof belongs in
`.tmp/ci-artifacts/`.

## Where Things Go

- `contracts/` says what the site must prove: routes, page text, browser checks, and performance budgets.
- `fixtures/` holds published sample content used to prove real detail pages render. It is stable render input, not the author publication workflow.
- `content-publication/` explains the content authoring flow: content PR, merge to content `main`, delivery intake, accepted/rejected/ignored verdicts, and last-good preservation.
- `gates/` holds checks that can block a merge.
- `preview/` deploys a candidate image to a disposable host and checks whether its pages look real in a browser.
- `providers/` holds paid host plumbing. DigitalOcean lives there because it is one provider, not the deploy model.

## Commands

`./run help` is the human command map. It shows three public namespaces:

- `dev:*` stands the app up locally or opens local development tools.
- `ci:*` proves repo state.
- `deploy:*` previews, rehearses publication, inspects content state, and proves release-shaped deployment gates.

Use these public commands in docs and workflows when they fit. Older command names
remain callable as compatibility aliases or implementation helpers, but they are
not the preferred DX.

### CI

- `./run ci:format` asks, "is formatting/style shape acceptable?"
- `./run ci:lint` asks, "do static lint gates pass?"
- `./run ci:test` asks, "do Elixir and JS tests pass?"
- `./run ci:types` asks, "does static type analysis pass?"
- `./run ci:security` asks, "does the security scan pass?"
- `./run ci:secrets` asks, "does secret scanning pass?"
- `./run ci:workflow` asks, "are GitHub workflow files valid?"
- `./run ci:performance` asks, "are public pages still within budget?"
- `./run ci:content` asks, "can app-side content validation pass?"
- `./run ci:release` asks, "would this release-shaped artifact boot and serve the pages visitors need?"
- `./run ci:gate-integrity` asks, "have acceptance gates been bypassed?"
- `./run ci:all` runs the local CI aggregate.

### Deploy

- `./run deploy:preview --app-image-ref <digest-ref> --app-sha <sha> --preview-page-acceptance-image <trusted-image> --preview-lease-minutes 15` creates one private preview receipt.
- `./run deploy:preview:destroy <deploy-receipt.json>` destroys the disposable host recorded by a preview receipt.
- `./run deploy:preview:cleanup` destroys leased preview hosts whose TTL has expired.
- `./run deploy:publication` runs the fast app-repo rehearsal for content publication flow. It is a developer/deploy check, not the author workflow.
- `./run deploy:publication:preview <deploy-receipt.json>` changes content on a running private preview and sends signed webhook deliveries. It is a preview check, not the author workflow.
- `./run deploy:content:status` prints the app-owned content publication status.
- `./run deploy:content:rollback` rolls live content back to a known-good publication generation.
- `./run deploy:release` runs the release-shaped production-build gate. It does not promote the future origin.

The `Private preview destroy` workflow is the GitHub UI path for destroying a
preserved preview by Droplet ID. The content author DX remains content PR ->
merge -> publication verdict; authors should not need to run app-repo rehearsal
commands.

### Debug Internals

The following commands are for debugging preview/provider internals, not normal
operator flow:

- `./run debug:preview-host:create`
- `./run debug:preview-host:status`
- `./run debug:preview-host:destroy`
- `./run debug:preview-runtime`
- `./run debug:preview-artifacts`

Use `./run help:all` to list compatibility aliases and lower-level tool wrappers.

## Adding Work

Add new route, text, browser, or performance expectations to
`contracts/routes.json` first. Do not make a second route list in a script.

Add receipts, screenshots, and last-run JSON under `.tmp/ci-artifacts/`. Do not
put generated files beside the scripts that produced them.

For preview deploys, start with `.tmp/ci-artifacts/preview/deploy-receipt.json`.
Terminal output, GitHub summaries, and failure markdown are rendered views of
that receipt; stage logs and screenshots are supporting evidence linked from it.
Preserved private previews are leased, not parked indefinitely. Keep the
dispatch default low while the cleanup path is still maturing; the allowed range
is 5 to 60 minutes. The `Private preview destroy` workflow uses the Droplet ID
from the receipt when you are done early; the `Private preview sweeper` workflow
also runs every 15 minutes and deletes expired leased previews. Both paths keep
the provider safety checks: the DigitalOcean name prefix and disposable-host
tags must match before deletion.

For content publication flow work, start with `content-publication/README.md`.
Publication scenarios belong under `content-publication/scenarios/`, not in the
route contract or the stable render samples.
