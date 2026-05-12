#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

host_receipt="${1:-${DO_HOST_RECEIPT:-ci/digitalocean-host.json}}"
app_image_ref="${APP_IMAGE_REF:-${APP_IMAGE:-}}"
output="${RUNTIME_PROOF_OUTPUT:-ci/disposable-runtime-proof.json}"
artifact_dir="${RUNTIME_PROOF_ARTIFACT_DIR:-ci/disposable-runtime-proof}"
remote_dir="${RUNTIME_PROOF_REMOTE_DIR:-/var/lib/personal-site/runtime-proof}"
project="${RUNTIME_PROOF_PROJECT:-personal-site-runtime-proof}"
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
  APP_IMAGE_REF=ghcr.io/owner/repo@sha256:<digest> ./run host:disposable:runtime-proof ci/digitalocean-host.json

Runs a digest-pinned application image on a ready disposable host, starts
Postgres beside it, checks /readyz and public routes, and records runtime
resource evidence.
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
    if [[ -z "${app_image_ref}" ]]; then
        usage >&2
        echo "fatal: APP_IMAGE_REF is required" >&2
        exit 1
    fi

    if [[ ! "${app_image_ref}" =~ @sha256:[0-9a-fA-F]{64}$ ]]; then
        echo "fatal: APP_IMAGE_REF must be digest-pinned with @sha256:<64 hex chars>" >&2
        exit 1
    fi
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
      URL_HOST: "${URL_HOST}"
      URL_PORT: "${URL_PORT}"
      URL_SCHEME: "${URL_SCHEME}"
    ports:
      - "127.0.0.1:${RUNTIME_PROOF_HOST_PORT}:${PORT}"
    volumes:
      - "./content:${CONTENT_BASE_PATH}:ro"

volumes:
  postgres: {}
YAML

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
SECRET_KEY_BASE=$(random_hex 64)
URL_HOST=${RUNTIME_PROOF_URL_HOST:-preview.local}
URL_PORT=${host_port}
URL_SCHEME=http
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
            base_url: ("http://127.0.0.1:" + $port),
            routes: $routes[0],
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

function probe_routes {
    local body_file
    local byte_count
    local failures
    local route
    local status_code
    local tmp_jsonl

    failures=0
    tmp_jsonl="${artifact_dir}/routes.jsonl"
    : > "${tmp_jsonl}"

    for route in / /en /en/case-studies /en/case-study/prod-build-smoke-case-study /en/notes /en/note/prod-build-smoke-note /ja; do
        body_file="$(mktemp)"
        status_code="$(curl -sS -o "${body_file}" -w "%{http_code}" "http://127.0.0.1:${RUNTIME_PROOF_HOST_PORT}${route}" || true)"
        byte_count="$(wc -c < "${body_file}" | tr -d ' ')"
        rm -f "${body_file}"

        case "${status_code}" in
            200 | 301 | 302 | 308)
                ;;
            *)
                failures=$((failures + 1))
                ;;
        esac

        jq -n \
            --arg route "${route}" \
            --arg status_code "${status_code}" \
            --arg byte_count "${byte_count}" \
            '{
                route: $route,
                status: ($status_code | tonumber?),
                bytes: ($byte_count | tonumber)
            }' >> "${tmp_jsonl}"
    done

    json_array_from_jsonl "${tmp_jsonl}" "${routes_json}"

    if [[ "${failures}" -gt 0 ]]; then
        return 1
    fi
}

mkdir -p "${artifact_dir}"
rm -f "${artifact_dir}"/*
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
require_digest_image
assert_safe_shell_value RUNTIME_PROOF_REMOTE_DIR "${remote_dir}"
assert_safe_shell_value RUNTIME_PROOF_PROJECT "${project}"

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
