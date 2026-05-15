#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

LAST_RUN_FILE="${1:-.tmp/ci-artifacts/prod-build/route-latency-last-run.json}"
BASELINE_FILE="${2:-ci/contracts/prod-build-baseline.json}"
branch=""

if branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"; then
    :
fi

if [[ "${branch}" != "main" ]]; then
    echo "baseline update skipped: current branch is '${branch:-detached}', not main"
    exit 0
fi

if [[ ! -f "${LAST_RUN_FILE}" ]]; then
    echo "fatal: last-run file not found: ${LAST_RUN_FILE}" >&2
    exit 1
fi

if [[ ! -f "${BASELINE_FILE}" ]]; then
    echo "fatal: baseline file not found: ${BASELINE_FILE}" >&2
    exit 1
fi

sha="$(git rev-parse HEAD)"
tmp_file="$(mktemp)"

jq \
    --arg sha "${sha}" \
    --slurpfile last "${LAST_RUN_FILE}" \
    '
    def median_array:
      sort | if length == 0 then null else .[(length / 2 | floor)] end;

    .schema_version = 1
    | .runs_count = ((.runs_count // 0) + 1)
    | .last_updated_main_sha = $sha
    | .ready_ms_samples = (((.ready_ms_samples // []) + [{sha: $sha, value: $last[0].ready_ms}]) | .[-30:])
    | .ready_ms_median = ([.ready_ms_samples[].value] | median_array)
    | reduce ($last[0].routes | to_entries[]) as $route (.;
        .routes[$route.key].samples = (
          ((.routes[$route.key].samples // []) + [{
            sha: $sha,
            warm_p50_ms: $route.value.warm_p50_ms,
            warm_p95_ms: $route.value.warm_p95_ms,
            warm_p99_ms: $route.value.warm_p99_ms,
            cold_first_ms: $route.value.cold_first_ms
          }]) | .[-30:]
        )
        | .routes[$route.key].warm_p50_ms = ([.routes[$route.key].samples[].warm_p50_ms] | median_array)
        | .routes[$route.key].warm_p95_ms = ([.routes[$route.key].samples[].warm_p95_ms] | median_array)
        | .routes[$route.key].warm_p99_ms = ([.routes[$route.key].samples[].warm_p99_ms] | median_array)
        | .routes[$route.key].cold_first_ms = ([.routes[$route.key].samples[].cold_first_ms] | median_array)
      )
    ' "${BASELINE_FILE}" > "${tmp_file}"

mv "${tmp_file}" "${BASELINE_FILE}"
jq . "${BASELINE_FILE}"
