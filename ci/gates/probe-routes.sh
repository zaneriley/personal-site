#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

BASE_URL="${PROD_BUILD_BASE_URL:-http://127.0.0.1:18080}"
OUTPUT_FILE="${1:-.tmp/ci-artifacts/prod-build/route-latency-last-run.json}"
ROUTE_CONTRACT_FILE="${ROUTE_CONTRACT_FILE:-ci/contracts/routes.json}"
OHA_BIN="${OHA_BIN:-oha}"
OHA_REQUESTS="${OHA_REQUESTS:-30}"
OHA_CONNECTIONS="${OHA_CONNECTIONS:-1}"
OHA_TIMEOUT="${OHA_TIMEOUT:-10s}"
OHA_ATTEMPTS="${OHA_ATTEMPTS:-3}"
OHA_PROCESS_TIMEOUT_SECONDS="${OHA_PROCESS_TIMEOUT_SECONDS:-30}"
READY_MS="${PROD_BUILD_READY_MS:-null}"
APP_SHA="${PROD_BUILD_APP_SHA:-$(git rev-parse HEAD)}"

function contract_routes {
    if [[ -n "${PROD_BUILD_ROUTES:-}" ]]; then
        printf "%s\n" "${PROD_BUILD_ROUTES}" |
            tr ' ' '\n' |
            jq -c -R 'select(length > 0) | {
                label: .,
                path: .,
                allowed_statuses: [200],
                required_body_text: []
            }'
        return 0
    fi

    jq -c '
        .routes[]
        | select(.load_probe.enabled != false)
    ' "${ROUTE_CONTRACT_FILE}"
}

function literal_hits {
    local body_file
    local strings_json

    body_file="${1}"
    strings_json="${2}"

    jq -r '.[]' <<< "${strings_json}" |
        while IFS= read -r needle; do
            if [[ -n "${needle}" ]] && grep -F -- "${needle}" "${body_file}" >/dev/null; then
                printf "%s\n" "${needle}"
            fi
        done |
        jq -R -s 'split("\n") | map(select(length > 0))'
}

function literal_misses {
    local body_file
    local strings_json

    body_file="${1}"
    strings_json="${2}"

    jq -r '.[]' <<< "${strings_json}" |
        while IFS= read -r needle; do
            if [[ -n "${needle}" ]] && ! grep -F -- "${needle}" "${body_file}" >/dev/null; then
                printf "%s\n" "${needle}"
            fi
        done |
        jq -R -s 'split("\n") | map(select(length > 0))'
}

function expected_site_origin_uses_loopback {
    case "${PHX_HOST:-}" in
        "localhost" | "0.0.0.0" | "web" | "web:8000" | 127.*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function route_body_assertions {
    local allowed_statuses_json
    local body_file
    local forbidden_html_hits_json
    local forbidden_html_text_json
    local forbidden_visible_hits_json
    local forbidden_visible_text_json
    local required_body_text_json
    local required_body_text_missing_json
    local required_body_text_present_json
    local route_json
    local status_code
    local status_number
    local url

    route_json="${1}"
    url="${2}"
    body_file="$(mktemp)"
    status_code="$(curl -L -sS -o "${body_file}" -w "%{http_code}" "${url}" || true)"
    status_number="null"

    if [[ "${status_code}" =~ ^[0-9]+$ ]]; then
        status_number="$((10#${status_code}))"
    fi

    allowed_statuses_json="$(jq -c '.allowed_statuses // [200]' <<< "${route_json}")"
    required_body_text_json="$(jq -c '.required_body_text // []' <<< "${route_json}")"
    forbidden_visible_text_json="$(jq -c '.text_policy.forbidden_visible_text // []' "${ROUTE_CONTRACT_FILE}")"
    forbidden_html_text_json="$(jq -c '.text_policy.forbidden_html_text // []' "${ROUTE_CONTRACT_FILE}")"
    required_body_text_present_json="$(literal_hits "${body_file}" "${required_body_text_json}")"
    required_body_text_missing_json="$(literal_misses "${body_file}" "${required_body_text_json}")"
    forbidden_visible_hits_json="$(literal_hits "${body_file}" "${forbidden_visible_text_json}")"
    if expected_site_origin_uses_loopback; then
        forbidden_html_hits_json="[]"
    else
        forbidden_html_hits_json="$(literal_hits "${body_file}" "${forbidden_html_text_json}")"
    fi

    jq -n \
        --argjson status_code "${status_number}" \
        --argjson allowed_statuses "${allowed_statuses_json}" \
        --argjson required_body_text_present "${required_body_text_present_json}" \
        --argjson required_body_text_missing "${required_body_text_missing_json}" \
        --argjson forbidden_visible_hits "${forbidden_visible_hits_json}" \
        --argjson forbidden_html_hits "${forbidden_html_hits_json}" \
        --argjson bytes "$(wc -c < "${body_file}" | tr -d ' ')" \
        '{
            http_status: $status_code,
            allowed_statuses: $allowed_statuses,
            status_ok: (
                if $status_code == null then false
                else ($allowed_statuses | index($status_code)) != null
                end
            ),
            bytes: $bytes,
            required_body_text_present: $required_body_text_present,
            required_body_text_missing: $required_body_text_missing,
            forbidden_visible_hits: $forbidden_visible_hits,
            forbidden_html_hits: $forbidden_html_hits,
            body_ok: (
                ($required_body_text_missing | length) == 0
                and ($forbidden_visible_hits | length) == 0
                and ($forbidden_html_hits | length) == 0
            )
        }'

    rm -f "${body_file}"
}

function run_with_timeout {
    local timeout_seconds="$1"
    local stdout_file
    local stderr_file
    local command_pid
    local timer_pid
    local status

    shift
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    "$@" > "${stdout_file}" 2> "${stderr_file}" &
    command_pid="$!"

    (
        sleep "${timeout_seconds}"

        if kill -0 "${command_pid}" 2>/dev/null; then
            kill "${command_pid}" 2>/dev/null || true
            sleep 1
            kill -9 "${command_pid}" 2>/dev/null || true
        fi
    ) >/dev/null 2>&1 &
    timer_pid="$!"

    if wait "${command_pid}"; then
        status=0
    else
        status="$?"
    fi

    kill "${timer_pid}" 2>/dev/null || true
    wait "${timer_pid}" 2>/dev/null || true

    cat "${stdout_file}"
    cat "${stderr_file}" >&2
    rm -f "${stdout_file}" "${stderr_file}"

    return "${status}"
}

function oha_json {
    local attempts="${OHA_ATTEMPTS}"
    local attempt=1
    local output

    while (( attempt <= attempts )); do
        if output="$(run_with_timeout "${OHA_PROCESS_TIMEOUT_SECONDS}" "${OHA_BIN}" "$@")"; then
            printf "%s" "${output}"
            return 0
        fi

        attempt=$((attempt + 1))
        sleep 1
    done

    return 1
}

function route_result {
    local assertions_json
    local cold_json
    local label
    local path
    local route_json
    local route_status
    local url
    local warm_json

    route_json="${1}"
    label="$(jq -r '.label' <<< "${route_json}")"
    path="$(jq -r '.path' <<< "${route_json}")"
    url="${BASE_URL}${path}"
    route_status="pass"

    assertions_json="$(route_body_assertions "${route_json}" "${url}")"

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
            jq -n -r --argjson cold "${cold_json}" --argjson warm "${warm_json}" --argjson assertions "${assertions_json}" '
              def ok_status: test("^[23]");
              def successful($run):
                (($run.statusCodeDistribution // {}) | to_entries | map(select(.key | ok_status | not)) | length) == 0
                and (($run.summary.successRate // 0) == 1);

              if successful($cold) and successful($warm) and $assertions.status_ok and $assertions.body_ok
              then "pass"
              else "fail"
              end
            '
        )"
    fi

    jq -n \
        --arg label "${label}" \
        --arg route "${path}" \
        --arg url "${url}" \
        --arg status "${route_status}" \
        --argjson requests "${OHA_REQUESTS}" \
        --argjson assertions "${assertions_json}" \
        --argjson cold "${cold_json}" \
        --argjson warm "${warm_json}" \
        '{
          "label": $label,
          route: $route,
          url: $url,
          status: $status,
          http_status: $assertions.http_status,
          allowed_statuses: $assertions.allowed_statuses,
          required_body_text_present: $assertions.required_body_text_present,
          required_body_text_missing: $assertions.required_body_text_missing,
          forbidden_visible_hits: $assertions.forbidden_visible_hits,
          forbidden_html_hits: $assertions.forbidden_html_hits,
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

while IFS= read -r route_json; do
    route_path="$(jq -r '.path' <<< "${route_json}")"
    route_result_json="$(route_result "${route_json}")"
    result="$(
        jq \
            --arg route "${route_path}" \
            --argjson route_json "${route_result_json}" \
            '.routes[$route] = $route_json' <<< "${result}"
    )"
done < <(contract_routes)

mkdir -p "$(dirname "${OUTPUT_FILE}")"
printf "%s\n" "${result}" > "${OUTPUT_FILE}"
jq . "${OUTPUT_FILE}"

if jq -e '[.routes[] | select(.status != "pass")] | length == 0' "${OUTPUT_FILE}" >/dev/null; then
    exit 0
fi

jq -r '
    .routes
    | to_entries[]
    | select(.value.status != "pass")
    | "route probe failed: \(.key)"
' "${OUTPUT_FILE}" >&2
exit 1
