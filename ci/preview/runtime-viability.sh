#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

host_receipt="${1:-${DO_HOST_RECEIPT:-.tmp/ci-artifacts/disposable-host/digitalocean-host.json}}"
app_image_ref="${APP_IMAGE_REF:-${APP_IMAGE:-}}"
output="${RUNTIME_VIABILITY_OUTPUT:-.tmp/ci-artifacts/runtime-viability/runtime-viability.json}"
artifact_dir="${RUNTIME_VIABILITY_ARTIFACT_DIR:-.tmp/ci-artifacts/runtime-viability}"
route_contract_file="${ROUTE_CONTRACT_FILE:-ci/contracts/routes.json}"
remote_dir="${RUNTIME_VIABILITY_REMOTE_DIR:-/var/lib/personal-site/runtime-viability}"
project="${RUNTIME_VIABILITY_PROJECT:-personal-site-runtime-viability}"
bind_host="${RUNTIME_VIABILITY_BIND_HOST:-0.0.0.0}"
host_port="${RUNTIME_VIABILITY_HOST_PORT:-18080}"
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
  APP_IMAGE_REF=ghcr.io/owner/repo@sha256:<app-digest> ./run host:disposable:runtime-viability .tmp/ci-artifacts/disposable-host/digitalocean-host.json

Runs a digest-pinned application image on a ready disposable host, starts
Postgres beside the app, checks /readyz, probes public routes, and records
runtime resource evidence. Run preview page acceptance from an external
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

function validate_route_contract {
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
    ' "${route_contract_file}" >/dev/null
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

function assert_single_line_value {
    local name
    local value

    name="${1}"
    value="${2}"

    if [[ "${value}" == *$'\n'* || "${value}" == *$'\r'* ]]; then
        echo "fatal: ${name} must be a single-line value" >&2
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
    mkdir -p "${payload_dir}"
    mkdir -p "${payload_dir}/publication"
    cp -R ci/fixtures/published-content "${payload_dir}/publication/content"

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
      - "${RUNTIME_VIABILITY_BIND_HOST}:${RUNTIME_VIABILITY_HOST_PORT}:${PORT}"
    volumes:
      - "./publication:/app/content-publication"

volumes:
  postgres: {}
YAML

    cp "${route_contract_file}" "${payload_dir}/routes.json"

    cat > "${payload_dir}/.env" <<ENV
APP_IMAGE_REF=${app_image_ref}
CONTENT_BASE_PATH=/app/content-publication/content
CONTENT_REPO_URL=file:///app/content-publication/content-source.git
GITHUB_WEBHOOK_SECRET=$(random_hex 32)
PORT=8000
POSTGRES_DB=portfolio
POSTGRES_PASSWORD=$(random_hex 32)
POSTGRES_USER=portfolio
RUNTIME_VIABILITY_HOST_PORT=${host_port}
RUNTIME_VIABILITY_BIND_HOST=${bind_host}
SECRET_KEY_BASE=$(random_hex 64)
PHX_FORCE_SSL=false
PHX_HOST=${RUNTIME_VIABILITY_PHX_HOST:-${public_ipv4}}
PHX_NOINDEX=true
PHX_URL_PORT=${host_port}
PHX_URL_SCHEME=http
ENV

    cat > "${payload_dir}/run-runtime-viability.sh" <<'REMOTE_SCRIPT'
#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

artifact_dir="artifacts"
registry_docker_config=".docker-auth"
registry_token_file=".registry-token"
status="fail"
failure_reason="not_started"
ready_ms=""
routes_json="${artifact_dir}/routes.json"
route_contract_file="routes.json"
memory_peaks_json="${artifact_dir}/memory-peaks.json"
docker_stats_json="${artifact_dir}/docker-stats.json"
compose_ps_json="${artifact_dir}/compose-ps.json"
summary_json="${artifact_dir}/summary.json"

function now_ms {
    date +%s%3N
}

function compose {
    docker compose --project-name "${RUNTIME_VIABILITY_PROJECT}" --env-file .env -f compose.yml "$@"
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
        --arg attempt_id "${PREVIEW_DEPLOY_ATTEMPT_ID:-}" \
        --arg route_contract_sha256 "$(sha256sum "${route_contract_file}" | awk '{print $1}')" \
        --arg content_base_path "${CONTENT_BASE_PATH}" \
        --arg content_repo_url "${CONTENT_REPO_URL}" \
        --arg project "${RUNTIME_VIABILITY_PROJECT}" \
        --arg port "${RUNTIME_VIABILITY_HOST_PORT}" \
        --arg public_base_url "$(expected_site_origin)" \
        --argjson ready_ms "${ready_ms_json}" \
        --slurpfile routes "${routes_json}" \
        --slurpfile memory_peaks "${memory_peaks_json}" \
        --slurpfile docker_stats "${docker_stats_json}" \
        --slurpfile compose_ps "${compose_ps_json}" \
        '{
            status: $status,
            failure_reason: (if $failure_reason == "" then null else $failure_reason end),
            preview_deploy_attempt_id: (if $attempt_id == "" then null else $attempt_id end),
            route_contract_sha256: $route_contract_sha256,
            app_image_ref: $app_image_ref,
            project: $project,
            ready_ms: $ready_ms,
            loopback_base_url: ("http://127.0.0.1:" + $port),
            public_base_url: $public_base_url,
            routes: $routes[0],
            preview_page_acceptance: {
                status: "external_required",
                browser_connect_url: $public_base_url,
                expected_site_origin: $public_base_url,
                route_contract_file: "ci/contracts/routes.json"
            },
            content_publication_flow: {
                status: "ready_for_rehearsal",
                content_base_path: $content_base_path,
                content_repo_url: $content_repo_url
            },
            memory_peaks: $memory_peaks[0],
            docker_stats: $docker_stats[0],
            compose_ps: $compose_ps[0]
        }' > "${summary_json}"
}

function finish {
    local exit_status

    exit_status="$?"
    cleanup_registry_auth
    collect_artifacts
    exit "${exit_status}"
}

trap finish EXIT

function cleanup_registry_auth {
    if [[ -d "${registry_docker_config}" ]]; then
        DOCKER_CONFIG="${PWD}/${registry_docker_config}" \
            docker logout "${RUNTIME_VIABILITY_REGISTRY:-ghcr.io}" >/dev/null 2>&1 || true
        rm -rf "${registry_docker_config}"
    fi

    rm -f "${registry_token_file}"
    unset RUNTIME_VIABILITY_REGISTRY_TOKEN
}

function registry_login {
    if [[ "${RUNTIME_VIABILITY_REGISTRY_AUTH_REQUIRED:-0}" != "1" ]]; then
        return 0
    fi

    IFS= read -r RUNTIME_VIABILITY_REGISTRY_TOKEN
    printf "%s" "${RUNTIME_VIABILITY_REGISTRY_TOKEN}" > "${registry_token_file}"
    chmod 600 "${registry_token_file}"

    mkdir -p "${registry_docker_config}"
    export DOCKER_CONFIG="${PWD}/${registry_docker_config}"

    docker login "${RUNTIME_VIABILITY_REGISTRY:-ghcr.io}" \
        --username "${RUNTIME_VIABILITY_REGISTRY_USERNAME}" \
        --password-stdin < "${registry_token_file}" >/dev/null

    unset RUNTIME_VIABILITY_REGISTRY_TOKEN
    rm -f "${registry_token_file}"
}

function wait_for_ready {
    local attempts
    local start_ms
    local end_ms
    local ready_url

    attempts=90
    start_ms="$(now_ms)"
    ready_url="http://127.0.0.1:${RUNTIME_VIABILITY_HOST_PORT}/readyz"

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
    forbidden_visible_text_json="$(jq -c '.text_policy.forbidden_visible_text // []' "${route_contract_file}")"
    forbidden_html_text_json="$(jq -c '.text_policy.forbidden_html_text // []' "${route_contract_file}")"

    while IFS= read -r route_json; do
        label="$(jq -r '.label' <<< "${route_json}")"
        route="$(jq -r '.path' <<< "${route_json}")"
        allowed_statuses_json="$(jq -c '.allowed_statuses' <<< "${route_json}")"
        required_body_text_json="$(jq -c '.required_body_text // []' <<< "${route_json}")"
        body_file="$(mktemp)"
        status_code="$(curl -sS -o "${body_file}" -w "%{http_code}" "http://127.0.0.1:${RUNTIME_VIABILITY_HOST_PORT}${route}" || true)"
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
            --arg route_label "${label}" \
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
                "label": $route_label,
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
    done < <(jq -c '.routes[]' "${route_contract_file}")

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

function prepare_content_source_repo {
    rm -rf publication/content-source-worktree publication/content-source.git

    cp -R publication/content publication/content-source-worktree
    git -C publication/content-source-worktree init --initial-branch=main >/dev/null
    git -C publication/content-source-worktree config user.email "preview@example.test"
    git -C publication/content-source-worktree config user.name "Preview Content"
    git -C publication/content-source-worktree add .
    git -C publication/content-source-worktree commit -m "Seed published sample content" >/dev/null
    git clone --bare publication/content-source-worktree publication/content-source.git >/dev/null 2>&1
    rm -rf publication/content-source-worktree
}

mkdir -p "${artifact_dir}"
rm -rf "${artifact_dir:?}"/*
set -o allexport
# shellcheck disable=SC1091
. ./.env
set +o allexport

RUNTIME_VIABILITY_PROJECT="${RUNTIME_VIABILITY_PROJECT:-personal-site-runtime-viability}"
export RUNTIME_VIABILITY_PROJECT

prepare_content_source_repo

failure_reason="pull_failed"
compose down --volumes --remove-orphans >/dev/null 2>&1 || true
registry_login
compose pull
cleanup_registry_auth

failure_reason="start_failed"
compose up -d

failure_reason="not_ready"
wait_for_ready

failure_reason="route_probe_failed"
probe_routes

status="pass"
failure_reason=""
echo "runtime viability passed"
REMOTE_SCRIPT

    chmod +x "${payload_dir}/run-runtime-viability.sh"
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
require_file "${route_contract_file}"
require_digest_image APP_IMAGE_REF "${app_image_ref}"

validate_route_contract
assert_safe_shell_value RUNTIME_VIABILITY_REMOTE_DIR "${remote_dir}"
assert_safe_shell_value RUNTIME_VIABILITY_PROJECT "${project}"
assert_safe_shell_value RUNTIME_VIABILITY_BIND_HOST "${bind_host}"

if [[ -n "${RUNTIME_VIABILITY_REGISTRY_TOKEN:-}" && -z "${RUNTIME_VIABILITY_REGISTRY_USERNAME:-}" ]]; then
    echo "fatal: RUNTIME_VIABILITY_REGISTRY_USERNAME is required when RUNTIME_VIABILITY_REGISTRY_TOKEN is set" >&2
    exit 1
fi

if [[ -n "${RUNTIME_VIABILITY_REGISTRY_TOKEN:-}" ]]; then
    assert_single_line_value RUNTIME_VIABILITY_REGISTRY "${RUNTIME_VIABILITY_REGISTRY:-ghcr.io}"
    assert_single_line_value RUNTIME_VIABILITY_REGISTRY_USERNAME "${RUNTIME_VIABILITY_REGISTRY_USERNAME}"
    assert_single_line_value RUNTIME_VIABILITY_REGISTRY_TOKEN "${RUNTIME_VIABILITY_REGISTRY_TOKEN}"
fi

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

if [[ "${RUNTIME_VIABILITY_VALIDATE_ONLY:-0}" == "1" ]]; then
    echo "runtime viability inputs valid"
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

echo "running disposable-host runtime viability"
echo "droplet_id=${droplet_id}"
echo "app_image_ref=${app_image_ref}"

remote_status=0
if [[ -n "${RUNTIME_VIABILITY_REGISTRY_TOKEN:-}" ]]; then
    printf "%s\n" "${RUNTIME_VIABILITY_REGISTRY_TOKEN}" |
        "${ssh_base[@]}" \
            "cd '${remote_dir}' && RUNTIME_VIABILITY_PROJECT='${project}' RUNTIME_VIABILITY_REGISTRY_AUTH_REQUIRED=1 RUNTIME_VIABILITY_REGISTRY='${RUNTIME_VIABILITY_REGISTRY:-ghcr.io}' RUNTIME_VIABILITY_REGISTRY_USERNAME='${RUNTIME_VIABILITY_REGISTRY_USERNAME}' bash ./run-runtime-viability.sh" ||
        remote_status="$?"
else
    "${ssh_base[@]}" "cd '${remote_dir}' && RUNTIME_VIABILITY_PROJECT='${project}' bash ./run-runtime-viability.sh" ||
        remote_status="$?"
fi

fetch_artifacts

echo "runtime viability artifact written: ${output}"
jq -r '"status=\(.status)\nready_ms=\(.ready_ms)\nroutes=\(.routes | length)\ncontainers=\(.docker_stats | length)"' "${output}"

exit "${remote_status}"
