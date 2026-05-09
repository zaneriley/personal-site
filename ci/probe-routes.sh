#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

BASE_URL="${PROD_BUILD_BASE_URL:-http://127.0.0.1:18080}"
OUTPUT_FILE="${1:-ci/last-run.json}"
OHA_BIN="${OHA_BIN:-oha}"
OHA_REQUESTS="${OHA_REQUESTS:-30}"
OHA_CONNECTIONS="${OHA_CONNECTIONS:-1}"
OHA_TIMEOUT="${OHA_TIMEOUT:-10s}"
OHA_ATTEMPTS="${OHA_ATTEMPTS:-3}"
READY_MS="${PROD_BUILD_READY_MS:-null}"
APP_SHA="${PROD_BUILD_APP_SHA:-$(git rev-parse HEAD)}"
ROUTES_RAW="${PROD_BUILD_ROUTES:-/ /en /en/case-studies /en/notes /en/note/prod-build-smoke-note /en/self /ja}"
KNOWN_BROKEN_FILE="${KNOWN_BROKEN_FILE:-ci/routes-known-broken.txt}"
IFS=" " read -r -a ROUTES <<< "${ROUTES_RAW}"

function is_known_broken {
    local route="$1"
    local known_route

    [[ -f "${KNOWN_BROKEN_FILE}" ]] || return 1

    while IFS= read -r known_route || [[ -n "${known_route}" ]]; do
        known_route="${known_route%%#*}"
        known_route="${known_route//[[:space:]]/}"

        if [[ "${known_route}" == "${route}" ]]; then
            return 0
        fi
    done < "${KNOWN_BROKEN_FILE}"

    return 1
}

function oha_json {
    local attempts="${OHA_ATTEMPTS}"
    local attempt=1
    local output

    while (( attempt <= attempts )); do
        if output="$("${OHA_BIN}" "$@")"; then
            printf "%s" "${output}"
            return 0
        fi

        attempt=$((attempt + 1))
        sleep 1
    done

    return 1
}

function route_result {
    local route="$1"
    local url="${BASE_URL}${route}"
    local cold_json
    local warm_json
    local route_status="pass"

    if ! cold_json="$(oha_json -n 1 -c 1 --json --no-tui -t "${OHA_TIMEOUT}" "${url}")"; then
        route_status="fail"
        cold_json="{}"
    fi

    if ! warm_json="$(oha_json -n "${OHA_REQUESTS}" -c "${OHA_CONNECTIONS}" --json --no-tui -t "${OHA_TIMEOUT}" "${url}")"; then
        route_status="fail"
        warm_json="{}"
    fi

    if [[ "${route_status}" == "pass" ]]; then
        route_status="$(
            jq -r '
              def ok_status: test("^[23]");
              if ((.statusCodeDistribution // {}) | to_entries | map(select(.key | ok_status | not)) | length) == 0
                 and ((.summary.successRate // 0) == 1)
              then "pass"
              else "fail"
              end
            ' <<< "${warm_json}"
        )"
    fi

    if [[ "${route_status}" == "fail" ]] && is_known_broken "${route}"; then
        route_status="known_broken"
    fi

    jq -n \
        --arg route "${route}" \
        --arg url "${url}" \
        --arg status "${route_status}" \
        --argjson requests "${OHA_REQUESTS}" \
        --argjson cold "${cold_json}" \
        --argjson warm "${warm_json}" \
        '{
          route: $route,
          url: $url,
          status: $status,
          success_rate: (($warm.summary.successRate // 0) * 100),
          status_codes: ($warm.statusCodeDistribution // {}),
          cold_first_ms: (($cold.latencyPercentiles.p50 // 0) * 1000 | round),
          warm_p50_ms: (($warm.latencyPercentiles.p50 // 0) * 1000 | round),
          warm_p95_ms: (($warm.latencyPercentiles.p95 // 0) * 1000 | round),
          warm_p99_ms: (($warm.latencyPercentiles["p99"] // 0) * 1000 | round),
          requests: $requests
        }'
}

result="$(
    jq -n \
        --arg schema_version "1" \
        --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg app_sha "${APP_SHA}" \
        --arg base_url "${BASE_URL}" \
        --argjson ready_ms "${READY_MS}" \
        '{
          schema_version: ($schema_version | tonumber),
          generated_at: $generated_at,
          app_sha: $app_sha,
          base_url: $base_url,
          ready_ms: $ready_ms,
          routes: {}
        }'
)"

for route in "${ROUTES[@]}"; do
    route_json="$(route_result "${route}")"
    result="$(
        jq \
            --arg route "${route}" \
            --argjson route_json "${route_json}" \
            '.routes[$route] = $route_json' <<< "${result}"
    )"
done

mkdir -p "$(dirname "${OUTPUT_FILE}")"
printf "%s\n" "${result}" > "${OUTPUT_FILE}"
jq . "${OUTPUT_FILE}"
