#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

LAST_RUN_FILE="${1:-.tmp/ci-artifacts/prod-build/route-latency-last-run.json}"
BASELINE_FILE="${2:-ci/contracts/prod-build-baseline.json}"
ABSOLUTE_P50_FLOOR_MS="${ABSOLUTE_P50_FLOOR_MS:-1000}"
DRIFT_PERCENT="${DRIFT_PERCENT:-20}"
MIN_BASELINE_RUNS="${MIN_BASELINE_RUNS:-30}"
failures=0

if [[ ! -f "${LAST_RUN_FILE}" ]]; then
    echo "fatal: last-run file not found: ${LAST_RUN_FILE}" >&2
    exit 1
fi

if [[ ! -f "${BASELINE_FILE}" ]]; then
    echo "fatal: baseline file not found: ${BASELINE_FILE}" >&2
    exit 1
fi

baseline_runs="$(jq -r '.runs_count // 0' "${BASELINE_FILE}")"

while IFS= read -r route; do
    status="$(jq -r --arg route "${route}" '.routes[$route].status' "${LAST_RUN_FILE}")"
    p50="$(jq -r --arg route "${route}" '.routes[$route].warm_p50_ms // 0' "${LAST_RUN_FILE}")"

    case "${status}" in
        pass)
            ;;
        fail)
            echo "prod-build route failed: ${route}" >&2
            failures=$((failures + 1))
            continue
            ;;
        known_broken)
            echo "prod-build route known-broken exemption used: ${route}" >&2
            continue
            ;;
        *)
            echo "prod-build route has unexpected status: ${route} status=${status}" >&2
            failures=$((failures + 1))
            continue
            ;;
    esac

    if (( p50 > ABSOLUTE_P50_FLOOR_MS )); then
        echo "prod-build route exceeded absolute p50 floor: ${route} p50=${p50}ms floor=${ABSOLUTE_P50_FLOOR_MS}ms" >&2
        failures=$((failures + 1))
    fi

    if (( baseline_runs >= MIN_BASELINE_RUNS )); then
        baseline_p50="$(jq -r --arg route "${route}" '.routes[$route].warm_p50_ms // empty' "${BASELINE_FILE}")"

        if [[ -n "${baseline_p50}" && "${baseline_p50}" != "null" ]]; then
            drift_limit="$(
                awk -v base="${baseline_p50}" -v drift="${DRIFT_PERCENT}" 'BEGIN { printf "%.0f", base * (1 + drift / 100) }'
            )"

            if (( p50 > drift_limit )); then
                echo "prod-build route exceeded rolling baseline drift: ${route} p50=${p50}ms limit=${drift_limit}ms baseline=${baseline_p50}ms" >&2
                failures=$((failures + 1))
            fi
        fi
    fi
done < <(jq -r '.routes | keys[]' "${LAST_RUN_FILE}")

if (( baseline_runs < MIN_BASELINE_RUNS )); then
    echo "prod-build drift gate logging-only: baseline runs ${baseline_runs}/${MIN_BASELINE_RUNS}"
fi

if (( failures > 0 )); then
    exit 1
fi

echo "prod-build comparison passed"
