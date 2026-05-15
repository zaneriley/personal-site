#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

host_receipt="${1:-${DO_HOST_RECEIPT:-ci/digitalocean-host.json}}"
app_image_ref="${APP_IMAGE_REF:-${APP_IMAGE:-}}"
output="${RUNTIME_PROOF_OUTPUT:-ci/disposable-runtime-proof.json}"
artifact_dir="${RUNTIME_PROOF_ARTIFACT_DIR:-ci/disposable-runtime-proof}"
route_assertions_file="${PREVIEW_ROUTE_ASSERTIONS_FILE:-ci/deploy/preview-route-assertions.json}"
remote_dir="${RUNTIME_PROOF_REMOTE_DIR:-/var/lib/personal-site/runtime-proof}"
project="${RUNTIME_PROOF_PROJECT:-personal-site-runtime-proof}"
bind_host="${RUNTIME_PROOF_BIND_HOST:-0.0.0.0}"
host_port="${RUNTIME_PROOF_HOST_PORT:-18080}"
ssh_private_key_file=""
ssh_known_hosts_file=""
tmpdir=""
delete_ssh_private_key_file="false"

# shellcheck disable=SC2329
function cleanup {
    if [[ -n "${tmpdir}" ]]; then
        rm -rf "${tmpdir}"
    fi

    if [[ "${delete_ssh_private_key_file}" == "true" && -n "${ssh_private_key_file}" ]]; then
        rm -f "${ssh_private_key_file}"
    fi

    if [[ -n "${ssh_known_hosts_file}" ]]; then
        rm -f "${ssh_known_hosts_file}"
    fi
}

trap 'cleanup' EXIT

function usage {
    cat <<'USAGE'
Usage:
  APP_IMAGE_REF=ghcr.io/owner/repo@sha256:<app-digest> ./run host:disposable:runtime-proof ci/digitalocean-host.json

Runs a digest-pinned application image on a ready disposable host, starts
Postgres beside the app, checks /readyz, probes public routes, and records
runtime resource evidence. Run the browser-real preview check from an external
runner against the public_base_url emitted in the artifact.
USAGE
}

function require_command {
    local command_name

    command_name="${1}"

    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "fatal: required command not found: ${command_name}" >&2
        exit 1
    fi
}

function require_file {
    local path

    path="${1}"

    if [[ ! -f "${path}" ]]; then
        echo "fatal: file not found: ${path}" >&2
        exit 1
    fi
}

function require_digest_image {
    local name
    local value

    name="${1}"
    value="${2}"

    if [[ -z "${value}" ]]; then
        usage >&2
        echo "fatal: ${name} is required" >&2
        exit 1
    fi

    if [[ ! "${value}" =~ @sha256:[0-9a-fA-F]{64}$ ]]; then
        echo "fatal: ${name} must be digest-pinned with @sha256:<64 hex chars>" >&2
        exit 1
    fi
}

function validate_route_assertions {
    jq -e '
        .schema_version == 1
        and (.text_policy.forbidden_visible_text | type == "array")
        and (.text_policy.forbidden_html_text | type == "array")
        and (.routes | type == "array" and length > 0)
        and ([.routes[] | select((.browser.enabled // true) != false)] | length > 0)
        and all(.routes[];
            (.label | type == "string" and length > 0)
            and (.path | type == "string" and startswith("/"))
            and (.allowed_statuses | type == "array" and length > 0)
            and (.required_body_text | type == "array" and length > 0)
        )
    ' "${route_assertions_file}" >/dev/null
}

function assert_safe_shell_value {
    local name
    local value

    name="${1}"
    value="${2}"

    if [[ ! "${value}" =~ ^[A-Za-z0-9._/@:-]+$ ]]; then
        echo "fatal: ${name} contains unsupported characters: ${value}" >&2
        exit 1
    fi
}

function read_receipt_value {
    local filter

    filter="${1}"
    jq -r "${filter} // empty" "${host_receipt}"
}

function configure_ssh_private_key {
    ssh_known_hosts_file="$(mktemp)"

    if [[ -n "${DEPLOY_SSH_PRIVATE_KEY_FILE:-}" ]]; then
        ssh_private_key_file="${DEPLOY_SSH_PRIVATE_KEY_FILE}"
        return 0
    fi

    if [[ -z "${DEPLOY_SSH_PRIVATE_KEY:-}" ]]; then
        echo "fatal: DEPLOY_SSH_PRIVATE_KEY or DEPLOY_SSH_PRIVATE_KEY_FILE is required" >&2
        exit 1
    fi

    ssh_private_key_file="$(mktemp)"
    delete_ssh_private_key_file="true"
    chmod 600 "${ssh_private_key_file}"
    printf "%s\n" "${DEPLOY_SSH_PRIVATE_KEY}" > "${ssh_private_key_file}"
}

function random_hex {
    local bytes

    bytes="${1}"
    openssl rand -hex "${bytes}"
}

function write_payload {
    local payload_dir

    payload_dir="${tmpdir}/payload"
    mkdir -p "${payload_dir}/content/notes/prod-build"
    mkdir -p "${payload_dir}/content/case-studies/prod-build"

    cat > "${payload_dir}/content/notes/prod-build/en.md" <<'MARKDOWN'
---
title: "Prod Build Smoke Note"
url: "prod-build-smoke-note"
introduction: "Prod build smoke content."
published_at: "2026-05-09T00:00:00Z"
is_draft: false
---

# Prod Build Smoke Note

This note exists so the production build gate exercises accepted live content.
MARKDOWN

    cat > "${payload_dir}/content/case-studies/prod-build/en.md" <<'MARKDOWN'
---
title: "Prod Build Smoke Case Study"
url: "prod-build-smoke-case-study"
company: "Portfolio CI"
role: "Performance fixture"
timeline: "2026"
platforms: ["Web"]
sort_order: 999
introduction: "Fixture content for production browser performance checks."
published_at: "2026-05-09T00:00:00Z"
is_draft: false
---

# Prod Build Smoke Case Study

This case study exists so the production build gate exercises a stable detail page.
MARKDOWN

    cat > "${payload_dir}/compose.yml" <<'YAML'
services:
  postgres:
    image: "postgres:16.0-bookworm"
    environment:
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: "${POSTGRES_DB}"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \"$${POSTGRES_USER}\" -d \"$${POSTGRES_DB}\""]
      interval: "2s"
      timeout: "3s"
      retries: 30
    volumes:
      - "postgres:/var/lib/postgresql/data"

  web:
    image: "${APP_IMAGE_REF}"
    depends_on:
      postgres:
        condition: "service_healthy"
    environment:
      CI_SKIP_CONTENT_PULL: "1"
      CONTENT_BASE_PATH: "${CONTENT_BASE_PATH}"
      CONTENT_REPO_URL: "${CONTENT_REPO_URL}"
      GITHUB_WEBHOOK_SECRET: "${GITHUB_WEBHOOK_SECRET}"
      MIX_ENV: "prod"
      NODE_ENV: "production"
      PORT: "${PORT}"
      POSTGRES_DB: "${POSTGRES_DB}"
      POSTGRES_HOST: "postgres"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_PORT: "5432"
      POSTGRES_USER: "${POSTGRES_USER}"
      SECRET_KEY_BASE: "${SECRET_KEY_BASE}"
      PHX_FORCE_SSL: "${PHX_FORCE_SSL}"
      PHX_HOST: "${PHX_HOST}"
      PHX_NOINDEX: "${PHX_NOINDEX}"
      PHX_URL_PORT: "${PHX_URL_PORT}"
      PHX_URL_SCHEME: "${PHX_URL_SCHEME}"
    ports:
      - "${RUNTIME_PROOF_BIND_HOST}:${RUNTIME_PROOF_HOST_PORT}:${PORT}"
    volumes:
      - "./content:${CONTENT_BASE_PATH}:ro"

volumes:
  postgres: {}
YAML

    cp "${route_assertions_file}" "${payload_dir}/preview-route-assertions.json"

    cat > "${payload_dir}/.env" <<ENV
APP_IMAGE_REF=${app_image_ref}
CONTENT_BASE_PATH=/app/prod-build-content
CONTENT_REPO_URL=https://example.invalid/personal-site-content.git
GITHUB_WEBHOOK_SECRET=$(random_hex 32)
PORT=8000
POSTGRES_DB=portfolio
POSTGRES_PASSWORD=$(random_hex 32)
POSTGRES_USER=portfolio
RUNTIME_PROOF_HOST_PORT=${host_port}
RUNTIME_PROOF_BIND_HOST=${bind_host}
SECRET_KEY_BASE=$(random_hex 64)
PHX_FORCE_SSL=false
PHX_HOST=${RUNTIME_PROOF_PHX_HOST:-${public_ipv4}}
PHX_NOINDEX=true
PHX_URL_PORT=${host_port}
PHX_URL_SCHEME=http
ENV

    cat > "${payload_dir}/run-runtime-proof.sh" <<'REMOTE_SCRIPT'
#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

artifact_dir="artifacts"
status="fail"
failure_reason="not_started"
ready_ms=""
routes_json="${artifact_dir}/routes.json"
route_assertions_file="preview-route-assertions.json"
memory_peaks_json="${artifact_dir}/memory-peaks.json"
docker_stats_json="${artifact_dir}/docker-stats.json"
compose_ps_json="${artifact_dir}/compose-ps.json"
summary_json="${artifact_dir}/summary.json"

function now_ms {
    date +%s%3N
}

function compose {
    docker compose --project-name "${RUNTIME_PROOF_PROJECT}" --env-file .env -f compose.yml "$@"
}

function json_array_from_jsonl {
    local input_file
    local output_file

    input_file="${1}"
    output_file="${2}"

    if [[ -s "${input_file}" ]]; then
        jq -s '.' "${input_file}" > "${output_file}"
    else
        printf "[]\n" > "${output_file}"
    fi
}

function collect_memory_peaks {
    local cid
    local container_name
    local memory_peak
    local peak_path
    local peak_paths
    local tmp_jsonl

    tmp_jsonl="${artifact_dir}/memory-peaks.jsonl"
    : > "${tmp_jsonl}"

    while IFS= read -r cid; do
        if [[ -z "${cid}" ]]; then
            continue
        fi

        container_name="$(docker inspect --format '{{.Name}}' "${cid}" | sed 's#^/##')"
        memory_peak=""
        peak_paths=(
            "/sys/fs/cgroup/system.slice/docker-${cid}.scope/memory.peak"
            "/sys/fs/cgroup/docker/${cid}/memory.peak"
        )

        for peak_path in "${peak_paths[@]}"; do
            if [[ -r "${peak_path}" ]]; then
                memory_peak="$(< "${peak_path}")"
                break
            fi
        done

        jq -n \
            --arg container "${container_name}" \
            --arg id "${cid}" \
            --arg peak_bytes "${memory_peak}" \
            '{
                container: $container,
                id: $id,
                peak_bytes: (if $peak_bytes == "" then null else ($peak_bytes | tonumber) end)
            }' >> "${tmp_jsonl}"
    done < <(compose ps -q || true)

    json_array_from_jsonl "${tmp_jsonl}" "${memory_peaks_json}"
}

function collect_artifacts {
    local ready_ms_json

    mkdir -p "${artifact_dir}"

    compose ps --format json > "${artifact_dir}/compose-ps.jsonl" 2>/dev/null || true
    docker stats --no-stream --format '{{json .}}' > "${artifact_dir}/docker-stats.jsonl" 2>/dev/null || true
    free -m > "${artifact_dir}/free-m.txt" 2>/dev/null || true
    compose logs --no-color --tail=300 web postgres > "${artifact_dir}/compose-logs.txt" 2>&1 || true
    compose exec -T web /app/bin/content status --json > "${artifact_dir}/content-status.json" 2>/dev/null || true

    json_array_from_jsonl "${artifact_dir}/compose-ps.jsonl" "${compose_ps_json}"
    json_array_from_jsonl "${artifact_dir}/docker-stats.jsonl" "${docker_stats_json}"
    collect_memory_peaks

    if [[ ! -f "${routes_json}" ]]; then
        printf "[]\n" > "${routes_json}"
    fi

    if [[ -z "${ready_ms}" ]]; then
        ready_ms_json="null"
    else
        ready_ms_json="${ready_ms}"
    fi

    jq -n \
        --arg status "${status}" \
        --arg failure_reason "${failure_reason}" \
        --arg app_image_ref "${APP_IMAGE_REF}" \
        --arg project "${RUNTIME_PROOF_PROJECT}" \
        --arg port "${RUNTIME_PROOF_HOST_PORT}" \
        --arg public_base_url "$(expected_site_origin)" \
        --argjson ready_ms "${ready_ms_json}" \
        --slurpfile routes "${routes_json}" \
        --slurpfile memory_peaks "${memory_peaks_json}" \
        --slurpfile docker_stats "${docker_stats_json}" \
        --slurpfile compose_ps "${compose_ps_json}" \
        '{
            status: $status,
            failure_reason: (if $failure_reason == "" then null else $failure_reason end),
            app_image_ref: $app_image_ref,
            project: $project,
            ready_ms: $ready_ms,
            loopback_base_url: ("http://127.0.0.1:" + $port),
            public_base_url: $public_base_url,
            routes: $routes[0],
            preview_browser_check: {
                status: "external_required",
                browser_connect_url: $public_base_url,
                expected_site_origin: $public_base_url,
                route_assertions_file: "ci/deploy/preview-route-assertions.json"
            },
            memory_peaks: $memory_peaks[0],
            docker_stats: $docker_stats[0],
            compose_ps: $compose_ps[0]
        }' > "${summary_json}"
}

function finish {
    local exit_status

    exit_status="$?"
    collect_artifacts
    exit "${exit_status}"
}

trap finish EXIT

function wait_for_ready {
    local attempts
    local start_ms
    local end_ms
    local ready_url

    attempts=90
    start_ms="$(now_ms)"
    ready_url="http://127.0.0.1:${RUNTIME_PROOF_HOST_PORT}/readyz"

    for attempt in $(seq 1 "${attempts}"); do
        if curl -fsS "${ready_url}" >/dev/null 2>&1; then
            end_ms="$(now_ms)"
            ready_ms="$((end_ms - start_ms))"
            echo "runtime ready in ${ready_ms}ms"
            return 0
        fi

        if (( attempt == 1 || attempt % 10 == 0 )); then
            echo "still waiting for runtime readiness (attempt ${attempt}/${attempts})"
        fi

        sleep 2
    done

    return 1
}

function expected_site_origin_uses_loopback {
    case "${PHX_HOST}" in
        "localhost" | "0.0.0.0" | "web" | "web:8000" | 127.*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
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

function status_allowed {
    local allowed_statuses_json
    local status_code

    allowed_statuses_json="${1}"
    status_code="${2}"

    jq -e --argjson status_code "${status_code}" 'index($status_code) != null' <<< "${allowed_statuses_json}" >/dev/null
}

function probe_routes {
    local allowed_statuses_json
    local body_file
    local byte_count
    local forbidden_html_hits_json
    local forbidden_html_text_json
    local forbidden_visible_hits_json
    local forbidden_visible_text_json
    local failures
    local label
    local route
    local required_body_text_json
    local required_body_text_missing_json
    local required_body_text_present_json
    local status_code
    local status_number
    local status_ok
    local tmp_jsonl

    failures=0
    tmp_jsonl="${artifact_dir}/routes.jsonl"
    : > "${tmp_jsonl}"
    forbidden_visible_text_json="$(jq -c '.text_policy.forbidden_visible_text // []' "${route_assertions_file}")"
    forbidden_html_text_json="$(jq -c '.text_policy.forbidden_html_text // []' "${route_assertions_file}")"

    while IFS= read -r route_json; do
        label="$(jq -r '.label' <<< "${route_json}")"
        route="$(jq -r '.path' <<< "${route_json}")"
        allowed_statuses_json="$(jq -c '.allowed_statuses' <<< "${route_json}")"
        required_body_text_json="$(jq -c '.required_body_text // []' <<< "${route_json}")"
        body_file="$(mktemp)"
        status_code="$(curl -sS -o "${body_file}" -w "%{http_code}" "http://127.0.0.1:${RUNTIME_PROOF_HOST_PORT}${route}" || true)"
        status_number="null"
        byte_count="$(wc -c < "${body_file}" | tr -d ' ')"
        required_body_text_present_json="$(literal_hits "${body_file}" "${required_body_text_json}")"
        required_body_text_missing_json="$(literal_misses "${body_file}" "${required_body_text_json}")"
        forbidden_visible_hits_json="$(literal_hits "${body_file}" "${forbidden_visible_text_json}")"

        if expected_site_origin_uses_loopback; then
            forbidden_html_hits_json="[]"
        else
            forbidden_html_hits_json="$(literal_hits "${body_file}" "${forbidden_html_text_json}")"
        fi

        status_ok="false"

        if [[ "${status_code}" =~ ^[0-9]+$ ]]; then
            status_number="$((10#${status_code}))"
        fi

        if [[ "${status_number}" != "null" ]] && status_allowed "${allowed_statuses_json}" "${status_number}"; then
            status_ok="true"
        fi

        if [[ "${status_ok}" != "true" ]] ||
            [[ "$(jq 'length' <<< "${required_body_text_missing_json}")" -gt 0 ]] ||
            [[ "$(jq 'length' <<< "${forbidden_visible_hits_json}")" -gt 0 ]] ||
            [[ "$(jq 'length' <<< "${forbidden_html_hits_json}")" -gt 0 ]]; then
            failures=$((failures + 1))
        fi

        jq -n \
            --arg label "${label}" \
            --arg route "${route}" \
            --arg byte_count "${byte_count}" \
            --argjson status_code "${status_number}" \
            --argjson allowed_statuses "${allowed_statuses_json}" \
            --argjson required_body_text_present "${required_body_text_present_json}" \
            --argjson required_body_text_missing "${required_body_text_missing_json}" \
            --argjson forbidden_visible_hits "${forbidden_visible_hits_json}" \
            --argjson forbidden_html_hits "${forbidden_html_hits_json}" \
            --argjson status_ok "${status_ok}" \
            '{
                label: $label,
                route: $route,
                status: $status_code,
                allowed_statuses: $allowed_statuses,
                status_ok: $status_ok,
                bytes: ($byte_count | tonumber),
                required_body_text_present: $required_body_text_present,
                required_body_text_missing: $required_body_text_missing,
                forbidden_visible_hits: $forbidden_visible_hits,
                forbidden_html_hits: $forbidden_html_hits,
                result: (
                    if $status_ok
                        and ($required_body_text_missing | length) == 0
                        and ($forbidden_visible_hits | length) == 0
                        and ($forbidden_html_hits | length) == 0
                    then "pass"
                    else "fail"
                    end
                )
            }' >> "${tmp_jsonl}"

        rm -f "${body_file}"
    done < <(jq -c '.routes[]' "${route_assertions_file}")

    json_array_from_jsonl "${tmp_jsonl}" "${routes_json}"

    if [[ "${failures}" -gt 0 ]]; then
        return 1
    fi
}

function expected_site_origin {
    local origin

    origin="${PHX_URL_SCHEME}://${PHX_HOST}"

    if [[ "${PHX_URL_PORT}" != "80" && "${PHX_URL_PORT}" != "443" ]]; then
        origin="${origin}:${PHX_URL_PORT}"
    fi

    printf "%s\n" "${origin}"
}

mkdir -p "${artifact_dir}"
rm -rf "${artifact_dir:?}"/*
set -o allexport
# shellcheck disable=SC1091
. ./.env
set +o allexport

RUNTIME_PROOF_PROJECT="${RUNTIME_PROOF_PROJECT:-personal-site-runtime-proof}"
export RUNTIME_PROOF_PROJECT

failure_reason="pull_failed"
compose down --volumes --remove-orphans >/dev/null 2>&1 || true
compose pull

failure_reason="start_failed"
compose up -d

failure_reason="not_ready"
wait_for_ready

failure_reason="route_probe_failed"
probe_routes

status="pass"
failure_reason=""
echo "runtime proof passed"
REMOTE_SCRIPT

    chmod +x "${payload_dir}/run-runtime-proof.sh"
}

function copy_payload {
    local payload_dir

    payload_dir="${tmpdir}/payload"

    tar -C "${payload_dir}" -czf - . |
        "${ssh_base[@]}" "mkdir -p '${remote_dir}' && tar -xzf - -C '${remote_dir}'"
}

function fetch_artifacts {
    rm -rf "${artifact_dir}"
    mkdir -p "${artifact_dir}"

    "${ssh_base[@]}" "tar -C '${remote_dir}/artifacts' -czf - ." |
        tar -C "${artifact_dir}" -xzf -

    jq --slurpfile host "${host_receipt}" \
        '. + {host: $host[0]}' \
        "${artifact_dir}/summary.json" > "${output}"
}

require_command jq
require_command openssl
require_command ssh
require_command tar
require_file "${host_receipt}"
require_file "${route_assertions_file}"
require_digest_image APP_IMAGE_REF "${app_image_ref}"

validate_route_assertions
assert_safe_shell_value RUNTIME_PROOF_REMOTE_DIR "${remote_dir}"
assert_safe_shell_value RUNTIME_PROOF_PROJECT "${project}"
assert_safe_shell_value RUNTIME_PROOF_BIND_HOST "${bind_host}"

droplet_id="$(read_receipt_value '.droplet_id')"
public_ipv4="$(read_receipt_value '.public_ipv4')"
lifecycle_status="$(read_receipt_value '.lifecycle_status')"

if [[ -z "${droplet_id}" || -z "${public_ipv4}" ]]; then
    echo "fatal: host receipt must contain droplet_id and public_ipv4" >&2
    exit 1
fi

if [[ "${lifecycle_status}" != "ready" ]]; then
    echo "fatal: host receipt lifecycle_status must be ready; got ${lifecycle_status:-empty}" >&2
    exit 1
fi

if [[ "${RUNTIME_PROOF_VALIDATE_ONLY:-0}" == "1" ]]; then
    echo "runtime proof inputs valid"
    exit 0
fi

configure_ssh_private_key
tmpdir="$(mktemp -d)"

ssh_base=(
    ssh
    -i "${ssh_private_key_file}"
    -o BatchMode=yes
    -o ConnectTimeout=10
    -o ServerAliveInterval=15
    -o ServerAliveCountMax=2
    -o StrictHostKeyChecking=accept-new
    -o UserKnownHostsFile="${ssh_known_hosts_file}"
    "deploy@${public_ipv4}"
)

write_payload
copy_payload

echo "running disposable-host runtime proof"
echo "droplet_id=${droplet_id}"
echo "app_image_ref=${app_image_ref}"

remote_status=0
"${ssh_base[@]}" "cd '${remote_dir}' && RUNTIME_PROOF_PROJECT='${project}' bash ./run-runtime-proof.sh" ||
    remote_status="$?"

fetch_artifacts

echo "runtime proof artifact written: ${output}"
jq -r '"status=\(.status)\nready_ms=\(.ready_ms)\nroutes=\(.routes | length)\ncontainers=\(.docker_stats | length)"' "${output}"

exit "${remote_status}"
