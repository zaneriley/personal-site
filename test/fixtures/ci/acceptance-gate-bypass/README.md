# Acceptance-Gate Bypass Fixtures

`pass/` contains workflows that must pass the checker. `fail/` contains one
known-bad bypass per directory. Fixture verification uses
`fixture-run-stubs/run` unless a case provides its own `run` file. Those stub
gate bodies are deliberate no-ops; the fixtures test gate wiring, not tool
behavior.
