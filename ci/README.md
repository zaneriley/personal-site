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

- `./run ci:prod-build` asks, "would this release boot and serve the pages visitors need?"
- `./run ci:performance-browser` asks, "are public pages still small and quick in a real browser?"
- `./run ci:preview-page-acceptance:test` checks the browser assertions without deploying anything.
- `./run ci:disposable-host-check` checks host scripts and runtime inputs without creating a cloud server.
- `./run host:disposable:*` creates, inspects, destroys, or tests a short-lived host.
- `./run preview:deploy --app-image-ref <digest-ref> --app-sha <sha> --preview-page-acceptance-image <trusted-image> --preview-lease-minutes 15` writes one private preview receipt.
- `./run preview:destroy <deploy-receipt.json>` destroys the disposable host recorded by a preview deploy.
- `./run preview:sweep-expired` destroys leased preview droplets whose TTL has expired.
- The `Private preview destroy` workflow is the GitHub UI path for destroying a preserved preview by Droplet ID.
- `./run content:rehearse` runs the fast app-repo rehearsal for content publication flow. It is a developer check, not the author workflow.
- `./run content:rehearse-preview <deploy-receipt.json>` changes content on a running private preview and sends signed webhook deliveries. It is a preview check, not the author workflow.

The first content publication flow check is local and fast: it creates a content
Git commit, sends a signed GitHub-shaped delivery, verifies the publication
verdict, and proves a bad delivery leaves last-good content live. The preview
rehearsal command applies the same check to a running private preview. Neither
command is the author DX.

Private preview runtime now starts with published sample content plus a writable
content checkout backed by a local Git source repo. That keeps normal preview
checks stable while allowing the next publication rehearsal to change content and
send a real webhook to the running preview.

Current status: `content:rehearse-preview` passed in the real `Private preview
deploy` workflow on run `25985240113`. Next, promote the same behavior to the
real content repo PR/merge trigger.

## Adding Work

Add new route, text, browser, or performance expectations to
`contracts/routes.json` first. Do not make a second route list in a script.

Add receipts, screenshots, and last-run JSON under `.tmp/ci-artifacts/`. Do not
put generated files beside the scripts that produced them.

For preview deploys, start with `.tmp/ci-artifacts/preview/deploy-receipt.json`.
Terminal output, GitHub summaries, and failure markdown are rendered views of
that receipt; stage logs and screenshots are supporting evidence linked from it.
Preserved private previews are leased, not parked indefinitely. The dispatch
default is 15 minutes while this lane is still being proven, with a 5-to-60
minute allowed range. The `Private preview destroy` workflow uses the Droplet ID
from the receipt when you are done early; the `Private preview sweeper` workflow
also runs every 15 minutes and deletes expired leased previews. Both paths keep
the provider safety checks: the DigitalOcean name prefix and disposable-host
tags must match before deletion.

For content publication flow work, start with `content-publication/README.md`.
Publication scenarios belong under `content-publication/scenarios/`, not in the
route contract or the stable render samples.
