# CI Layout

This directory is organized by job, not provider.

- `contracts/` holds the durable inputs shared by gates.
- `fixtures/` holds committed content used by CI.
- `gates/` holds merge-gate checks run by `./run ci:*`.
- `preview/` holds disposable preview validation.
- `providers/` holds provider adapters such as DigitalOcean.

Generated evidence belongs under `.tmp/ci-artifacts/`, never beside the scripts.
