# Content Publication Flow

Status: local rehearsal implemented; preview rehearsal has passed repeatedly in
the real `Private preview deploy` workflow, including final pushed-head proof
`26025380183`.

This folder owns checks for the content authoring flow:

```text
write Markdown -> open PR in personal-site-content -> merge to main -> webhook delivery -> publication verdict
```

The human DX is the content repo workflow. Z should write Markdown, commit,
open a PR, and merge it into content `main`. That merge is the publish action.

Any scripts in this folder are rehearsal machinery for CI or private-preview
validation. They are not commands the author should need to remember.

## Fast Rehearsal

Use this while building the tracer:

```text
./run content:rehearse
```

That command creates a temporary content Git repo, commits a note, sends a
signed GitHub-shaped webhook delivery through the app endpoint, verifies the note
route renders, commits an invalid update, verifies the rejection verdict, and
checks that the previous known-good note stays live.

This command is not the author workflow. It is the fast app-repo rehearsal for
the same checks the real content PR/merge flow must satisfy.

The private preview runtime starts with published sample content, exposes a
local content Git repository, and mounts a writable checkout path for the app.
That lets preview rehearsal send a content delivery to a running preview instead
of only using the in-process test harness.

Use this after `./run preview:deploy` creates a reviewable private preview:

```text
./run content:rehearse-preview .tmp/ci-artifacts/preview/deploy-receipt.json
```

That command SSHes to the preview host, commits a note into the preview content
source repo, sends a signed webhook to the running app, verifies the note route
renders, commits an invalid update, verifies the rejection verdict, and checks
that last-good content stays live. It writes
`.tmp/ci-artifacts/content-publication/preview-rehearsal.json`.

This is still rehearsal machinery. The author workflow remains content PR,
merge to main, and read the verdict.

Current next step: wire the same behavior to the real content repo PR/merge
flow.

Operator view:

```text
Lane: Private preview deploy
Input: app PR number + expected head SHA
Success: preview deploy receipt is reviewable, content rehearsal receipt passes,
and the disposable host is destroyed unless preserve_preview=true
Failure: inspect preview-deploy-artifacts, then use the receipt's destroy command
if preserve_preview=true or cleanup failed
```

## Acceptance Criteria

The next step is complete only when all of this is true:

- A real private preview was created from the candidate app image.
- The workflow wrote
  `.tmp/ci-artifacts/candidate-image/candidate-image.json`.
- The candidate image receipt names a digest-pinned `image_ref`, and that same
  image ref appears in the preview deploy receipt.
- The preview receipt says `outcome: "reviewable"`.
- `./run content:rehearse-preview .tmp/ci-artifacts/preview/deploy-receipt.json`
  ran against that preview receipt and exited 0.
- The generated receipt exists at
  `.tmp/ci-artifacts/content-publication/preview-rehearsal.json`.
- The generated receipt says `status: "pass"`.
- The rehearsal changed content in the preview content source repo after the app
  was already running.
- A wrong-signed webhook delivery was rejected before any rehearsal content
  changed, and publication state did not move.
- A signed webhook delivery reached the running preview app for the good content
  change.
- `bin/content status --json` on the preview reported the good content SHA as
  live.
- The public preview route rendered the new good content body.
- A signed webhook delivery reached the running preview app for the bad content
  change.
- `bin/content status --json` on the preview reported the bad content SHA as the
  last rejected SHA.
- The rejection reason named the bad content path and a useful reason.
- The same public preview route still rendered the previous good content body
  after the bad delivery.
- The private preview host was destroyed after the check, unless
  `preserve_preview=true` was set for human review or debugging.

## Ways To Cheat

Do not call the next step done if any of these are true:

- Only `./run content:rehearse` passed. That is the local check, not the preview
  check.
- The preview was never created, or the receipt is missing/stale.
- The command ran against a local test server instead of the private preview
  URL/host.
- The content was present before the app started. The rehearsal must change
  content after the app is already running.
- The check only inspected a database row and did not verify the public route.
- The check only verified the public route and did not verify the publication
  status.
- The check only tested the good path and skipped the bad content rejection.
- The bad content was rejected, but the previous good content was not proven
  still visible.
- The rehearsal only sent correctly signed webhooks and never proved that
  invalid signatures are rejected.
- The webhook was bypassed by calling internal Elixir functions directly.
- The webhook was unsigned or missing the GitHub-shaped headers/payload.
- A failed command was treated as advisory.
- The preview host was left running without `preserve_preview=true` and a clear
  review or debugging reason.

## Reader Goal

Use this folder when the question is:

```text
If a content PR merges to main, will the app accept, reject, or ignore the
delivery clearly, and will bad content leave the previous known-good content
live?
```

## Vocabulary

- `published sample content`: checked-in content used by runtime and route checks
  to prove real detail pages render.
- `content publication flow`: the author workflow from Markdown change through
  PR merge, webhook delivery, app publication, and visible verdict.
- `content delivery intake`: the GitHub-shaped webhook edge: HMAC, event,
  delivery ID, repository, ref, and target SHA validation.
- `publication verdict`: the author/operator-visible result: accepted, rejected,
  or ignored.
- `publication rehearsal`: a CI/private-preview check that exercises the content
  publication flow without relying on a human to remember harness commands.

Avoid `fixture mode`, `repo mode`, `content preview`, and `content publish
tracer` in durable code. Those names describe implementation details or planning
technique instead of the author-facing promise.

## Actual Author DX

The desired workflow is:

```text
cd personal-site-content
edit Markdown
git commit
open PR
merge PR to main
read the publication verdict
```

The verdict should say one of:

- accepted and live
- rejected with file/path/reason while last-good stays live
- ignored because no publishable content changed

The author should not need to SSH to the host, restart containers, inspect the
database, find a preview receipt, or run an app-repo rehearsal command.

## Rehearsal Shape

Publication rehearsal scenarios should live here:

```text
ci/content-publication/
  scenarios/
    accepted-note/
      scenario.json
      content/
    rejected-invalid-note/
      scenario.json
      content/
    ignored-no-publishable-change/
      scenario.json
      content/
```

Do not put publication scenarios in `ci/contracts/routes.json`. That file owns
route, browser, and performance expectations. Publication scenarios own content
delivery inputs and expected verdicts.

## Evidence Surfaces

The normal evidence should use author/operator surfaces:

- content-repo PR/merge status
- webhook response
- `bin/content status --json`
- signed publication debug page
- public route probe for the changed content
- generated receipt and summary under `.tmp/ci-artifacts/content-publication/`

Direct database queries are acceptable in lower-level tests, but they are not the
author workflow.
