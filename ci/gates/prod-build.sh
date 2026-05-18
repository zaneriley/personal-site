#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PROJECT_NAME="${PROD_BUILD_COMPOSE_PROJECT:-personal-site-prod-build}"
HOST_PORT="${PROD_BUILD_HOST_PORT:-18080}"
APP_PORT="${PORT:-8000}"
OHA_VERSION="${OHA_VERSION:-1.4.7}"
COMPOSE_OVERRIDE_FILE=".tmp/prod-build/compose.override.yml"
PROD_BUILD_CONTENT_DIR="ci/fixtures/published-content"
OHA_DOCKER_IMAGE="${OHA_DOCKER_IMAGE:-debian:bookworm-slim}"
APP_SHA="$(git rev-parse HEAD)"
compose=(docker compose --project-name "${PROJECT_NAME}" -f docker-compose.yml -f "${COMPOSE_OVERRIDE_FILE}")

function now_ms {
    perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
}

function cleanup {
    local status=$?

    if [[ "${status}" -ne 0 ]]; then
        if ! "${compose[@]}" ps; then
            echo "warning: failed to inspect prod-build compose services" >&2
        fi

        if ! "${compose[@]}" logs --no-color --tail=200 web postgres; then
            echo "warning: failed to collect prod-build compose logs" >&2
        fi
    fi

    if ! "${compose[@]}" down --volumes --remove-orphans >/dev/null 2>&1; then
        echo "warning: failed to clean up prod-build compose project" >&2
    fi

    return "${status}"
}

function require_command {
    local command_name="$1"

    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "fatal: required command not found: ${command_name}" >&2
        exit 1
    fi
}

function oha_asset_name {
    local os="$1"
    local arch="$2"

    case "${os}-${arch}" in
        Linux-x86_64 | Linux-amd64)
            printf "oha-linux-amd64"
            ;;
        Linux-aarch64 | Linux-arm64)
            printf "oha-linux-arm64"
            ;;
        Darwin-arm64)
            printf "oha-macos-arm64"
            ;;
        Darwin-x86_64)
            printf "oha-macos-amd64"
            ;;
        *)
            echo "fatal: unsupported oha platform: ${os}-${arch}" >&2
            exit 1
            ;;
    esac
}

function download_oha_asset {
    local asset
    local target

    asset="$1"
    target="$2"

    if [[ -x "${target}" ]]; then
        return 0
    fi

    mkdir -p "$(dirname "${target}")"
    curl -fsSL "https://github.com/hatoo/oha/releases/download/v${OHA_VERSION}/${asset}" -o "${target}"
    chmod +x "${target}"
}

function ensure_native_oha {
    local asset
    local target

    if [[ -n "${OHA_BIN:-}" && -x "${OHA_BIN}" ]]; then
        export OHA_BIN
        return 0
    fi

    if command -v oha >/dev/null 2>&1; then
        OHA_BIN="$(command -v oha)"
        export OHA_BIN
        return 0
    fi

    asset="$(oha_asset_name "$(uname -s)" "$(uname -m)")"
    target=".tmp/tools/oha/v${OHA_VERSION}/oha"

    download_oha_asset "${asset}" "${target}"

    OHA_BIN="${target}"
    export OHA_BIN
}

function ensure_docker_oha {
    local asset
    local docker_arch
    local target
    local tool_dir
    local wrapper

    docker_arch="$(docker info --format '{{.Architecture}}')"
    asset="$(oha_asset_name "Linux" "${docker_arch}")"
    tool_dir="$(pwd -P)/.tmp/tools/oha/v${OHA_VERSION}"
    target="${tool_dir}/${asset}"
    wrapper="${tool_dir}/oha-docker"

    download_oha_asset "${asset}" "${target}"

    cat > "${wrapper}" <<BASH
#!/usr/bin/env bash
set -o errexit
exec docker run --rm --network "${PROJECT_NAME}_default" -v "${tool_dir}:/tools:ro" --entrypoint "/tools/${asset}" "${OHA_DOCKER_IMAGE}" "\$@"
BASH
    chmod +x "${wrapper}"

    OHA_BIN="${wrapper}"
    PROD_BUILD_BASE_URL="http://web:${APP_PORT}"
    export OHA_BIN
    export PROD_BUILD_BASE_URL
}

function ensure_oha {
    ensure_native_oha
}

function write_compose_override {
    mkdir -p "$(dirname "${COMPOSE_OVERRIDE_FILE}")"

    cat > "${COMPOSE_OVERRIDE_FILE}" <<'YAML'
services:
  web:
    environment:
      CI_SKIP_CONTENT_PULL: "${CI_SKIP_CONTENT_PULL}"
      CONTENT_BASE_PATH: "${CONTENT_BASE_PATH}"
      CONTENT_REPO_URL: "${CONTENT_REPO_URL}"
      DATABASE_URL: "${DATABASE_URL:-}"
      GITHUB_TOKEN: "${GITHUB_TOKEN:-}"
      GITHUB_WEBHOOK_SECRET: "${GITHUB_WEBHOOK_SECRET}"
      MIX_ENV: "${MIX_ENV}"
      NODE_ENV: "${NODE_ENV}"
      PORT: "${PORT}"
      POSTGRES_DB: "${POSTGRES_DB}"
      POSTGRES_HOST: "${POSTGRES_HOST}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_POOL: "${POSTGRES_POOL:-15}"
      POSTGRES_PORT: "${POSTGRES_PORT}"
      POSTGRES_USER: "${POSTGRES_USER}"
      SECRET_KEY_BASE: "${SECRET_KEY_BASE}"
      PHX_FORCE_SSL: "${PHX_FORCE_SSL}"
      PHX_HOST: "${PHX_HOST}"
      PHX_NOINDEX: "${PHX_NOINDEX}"
      PHX_URL_PORT: "${PHX_URL_PORT}"
      PHX_URL_SCHEME: "${PHX_URL_SCHEME}"
    volumes:
      - "${PROD_BUILD_CONTENT_VOLUME}"
YAML
}

function wait_for_postgres {
    local attempts=60

    until "${compose[@]}" exec -T postgres pg_isready -U "${POSTGRES_USER}" >/dev/null 2>&1; do
        attempts=$((attempts - 1))

        if [[ "${attempts}" -le 0 ]]; then
            echo "fatal: postgres did not become ready" >&2
            exit 1
        fi

        sleep 1
    done
}

function wait_for_ready {
    local start_ms="$1"
    local attempts=60
    local ready_url="http://127.0.0.1:${HOST_PORT}/readyz"
    local end_ms

    until curl -fsS "${ready_url}" >/dev/null; do
        attempts=$((attempts - 1))

        if [[ "${attempts}" -le 0 ]]; then
            echo "fatal: release did not become ready at ${ready_url}" >&2
            exit 1
        fi

        sleep 1
    done

    end_ms="$(now_ms)"
    PROD_BUILD_READY_MS="$((end_ms - start_ms))"
    export PROD_BUILD_READY_MS

    echo "release ready in ${PROD_BUILD_READY_MS}ms"
}

function content_fixture_sha256 {
    (
        cd "${PROD_BUILD_CONTENT_DIR}"
        find . -type f -print | LC_ALL=C sort | while IFS= read -r file_path; do
            shasum -a 256 "${file_path}"
        done
    ) | shasum -a 256 | awk '{print $1}'
}

function capture_runtime_snapshot {
    local container_id
    local container_inspect_file
    local image_id
    local image_inspect_file
    local stage="$1"
    local stats_file

    container_id="$("${compose[@]}" ps -q web)"
    image_id="$("${compose[@]}" images -q web | head -n 1)"

    if [[ -z "${container_id}" || -z "${image_id}" ]]; then
        echo "fatal: prod-build web container/image was not available for runtime measurement" >&2
        exit 1
    fi

    stats_file="$(mktemp)"
    container_inspect_file="$(mktemp)"
    image_inspect_file="$(mktemp)"

    docker stats --no-stream --format '{{json .}}' "${container_id}" > "${stats_file}"
    docker inspect "${container_id}" > "${container_inspect_file}"
    docker image inspect "${image_id}" > "${image_inspect_file}"

    jq -n \
        --arg captured_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --arg stage "${stage}" \
        --slurpfile stats "${stats_file}" \
        --slurpfile container "${container_inspect_file}" \
        --slurpfile image "${image_inspect_file}" \
        '{
            captured_at: $captured_at,
            stage: $stage,
            container: {
                id: $container[0][0].Id,
                name: $container[0][0].Name,
                image_id: $container[0][0].Image,
                state: $container[0][0].State.Status
            },
            image: {
                id: $image[0][0].Id,
                repo_tags: ($image[0][0].RepoTags // []),
                repo_digests: ($image[0][0].RepoDigests // []),
                local_image_disk_size_bytes: $image[0][0].Size
            },
            docker_stats: $stats[0]
        }'

    rm -f "${stats_file}" "${container_inspect_file}" "${image_inspect_file}"
}

function write_runtime_artifact {
    local after_browser_snapshot="$1"
    local output=".tmp/ci-artifacts/prod-build/runtime-last-run.json"
    local ready_snapshot="$2"

    mkdir -p "$(dirname "${output}")"

    jq -n \
        --arg app_sha "${APP_SHA}" \
        --arg content_fixture_path "${PROD_BUILD_CONTENT_DIR}" \
        --arg content_fixture_sha256 "$(content_fixture_sha256)" \
        --arg generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --slurpfile ready "${ready_snapshot}" \
        --slurpfile after_browser "${after_browser_snapshot}" \
        '{
            schema_version: 1,
            command: "ci:prod-build",
            generated_at: $generated_at,
            app_sha: $app_sha,
            content: {
                fixture_path: $content_fixture_path,
                fixture_sha256: $content_fixture_sha256
            },
            image: $after_browser[0].image,
            snapshots: {
                ready: $ready[0],
                after_browser_performance: $after_browser[0]
            }
        }' > "${output}"

    echo "runtime artifact written: ${output}"
}

function run_browser_performance {
    local output=".tmp/ci-artifacts/prod-build/browser-performance-last-run.json"
    local tmp_output
    local status

    tmp_output="$(mktemp)"

    "${compose[@]}" build js >/dev/null

    if "${compose[@]}" run --rm --no-deps \
        -e "PERF_BROWSER_BASE_URL=http://web:${APP_PORT}" \
        -e "PROD_BUILD_APP_SHA=${APP_SHA}" \
        js node ../ci/gates/browser-performance.mjs --output - > "${tmp_output}" &&
        jq -e '.status == "pass"' "${tmp_output}" >/dev/null; then
        mkdir -p "$(dirname "${output}")"
        mv "${tmp_output}" "${output}"
        echo "performance browser artifact written: ${output}"
        return 0
    else
        status=$?
    fi

    if [[ -s "${tmp_output}" ]]; then
        mkdir -p "$(dirname "${output}")"
        cp "${tmp_output}" "${output}"
        echo "performance browser artifact written: ${output}"
    fi

    rm -f "${tmp_output}"
    return "${status}"
}

function run_perf_audit {
    "${compose[@]}" run --rm --no-deps \
        js node ../ci/gates/perf-audit.mjs
}

trap cleanup EXIT

require_command curl
require_command docker
require_command jq
require_command openssl
require_command perl

if [[ ! -e .env ]]; then
    cp .env.example .env
fi

export MIX_ENV=prod
export NODE_ENV=production
export POSTGRES_USER="${POSTGRES_USER:-portfolio}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
export POSTGRES_DB="${POSTGRES_DB:-${POSTGRES_USER}}"
export POSTGRES_HOST=postgres
export POSTGRES_PORT=5432
export POSTGRES_POOL="${POSTGRES_POOL:-15}"
export PORT="${APP_PORT}"
export PHX_FORCE_SSL="${PHX_FORCE_SSL:-false}"
export PHX_HOST="${PHX_HOST:-web}"
export PHX_NOINDEX="${PHX_NOINDEX:-true}"
export PHX_URL_SCHEME="${PHX_URL_SCHEME:-http}"
export PHX_URL_PORT="${PHX_URL_PORT:-${APP_PORT}}"
export SECRET_KEY_BASE="${SECRET_KEY_BASE:-$(openssl rand -hex 64)}"
export GITHUB_WEBHOOK_SECRET="${GITHUB_WEBHOOK_SECRET:-ci-github-webhook-secret}"
export CONTENT_REPO_URL="${CONTENT_REPO_URL:-https://example.invalid/personal-website-content.git}"
export CONTENT_BASE_PATH="${CONTENT_BASE_PATH:-/app/prod-build-content}"
export CI_SKIP_CONTENT_PULL=1
export DOCKER_WEB_VOLUME="${DOCKER_WEB_VOLUME:-/tmp:/tmp}"
export DOCKER_WEB_PORT_FORWARD="${DOCKER_WEB_PORT_FORWARD:-127.0.0.1:${HOST_PORT}}"
export DOCKER_RESTART_POLICY=no
export PROD_BUILD_APP_SHA="${APP_SHA}"
export PROD_BUILD_BASE_URL="${PROD_BUILD_BASE_URL:-http://127.0.0.1:${HOST_PORT}}"

prod_build_content_host_path="$(pwd -P)/${PROD_BUILD_CONTENT_DIR}"
export PROD_BUILD_CONTENT_VOLUME="${prod_build_content_host_path}:${CONTENT_BASE_PATH}:ro"

ensure_oha
write_compose_override

"${compose[@]}" build web
"${compose[@]}" up -d postgres
wait_for_postgres

"${compose[@]}" run --rm --no-deps --entrypoint /app/bin/portfolio web eval "Portfolio.Release.migrate()"
"${compose[@]}" run --rm --no-deps --entrypoint /app/bin/portfolio web eval "Portfolio.Release.rollback(Portfolio.Repo, 1)"
"${compose[@]}" run --rm --no-deps --entrypoint /app/bin/portfolio web eval "Portfolio.Release.migrate()"

start_ms="$(now_ms)"
"${compose[@]}" up -d web
wait_for_ready "${start_ms}"

ready_runtime_snapshot="$(mktemp)"
after_browser_runtime_snapshot="$(mktemp)"
capture_runtime_snapshot "ready" > "${ready_runtime_snapshot}"

ci/gates/probe-routes.sh .tmp/ci-artifacts/prod-build/route-latency-last-run.json

if ! curl -fsS "http://127.0.0.1:${HOST_PORT}/en/note/prod-build-smoke-note" |
    grep -F "Prod Build Smoke Note" >/dev/null; then
    echo "fatal: prod-build smoke note did not render accepted live content" >&2
    exit 1
fi

if ! curl -fsS "http://127.0.0.1:${HOST_PORT}/en/case-study/prod-build-smoke-case-study" |
    grep -F "Prod Build Smoke Case Study" >/dev/null; then
    echo "fatal: prod-build smoke case study did not render accepted live content" >&2
    exit 1
fi

content_status_json="$("${compose[@]}" exec -T web bin/content status --json)"
printf "%s\n" "${content_status_json}"
jq -e '.live != null and .last_good == .live and .sync_state == "idle" and .last_delivery_id == ("embedded:" + .live)' <<< "${content_status_json}"

"${compose[@]}" exec -T web \
    bin/portfolio rpc "IO.inspect({Application.spec(:portfolio, :vsn), length(Supervisor.which_children(Portfolio.Supervisor)), Ecto.Adapters.SQL.query!(Portfolio.Repo, \"SELECT 1\").num_rows})"

run_browser_performance
capture_runtime_snapshot "after_browser_performance" > "${after_browser_runtime_snapshot}"
write_runtime_artifact "${after_browser_runtime_snapshot}" "${ready_runtime_snapshot}"
rm -f "${ready_runtime_snapshot}" "${after_browser_runtime_snapshot}"
run_perf_audit
