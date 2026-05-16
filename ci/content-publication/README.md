# Content Publication Flow

Status: local rehearsal implemented; preview rehearsal command implemented but
not yet proven against a real private preview host.

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

The private preview runtime is prepared for the next step: it starts with
published sample content, exposes a local content Git repository, and mounts a
writable checkout path for the app. That lets the next rehearsal send a content
delivery to a running preview instead of only using the in-process test harness.

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

Current next step: create a real private preview, then run
`./run content:rehearse-preview .tmp/ci-artifacts/preview/deploy-receipt.json`.
If it passes, wire the same behavior to the real content repo PR/merge flow.

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
