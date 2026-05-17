#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

preview_receipt="${1:-${PREVIEW_RECEIPT:-.tmp/ci-artifacts/preview/deploy-receipt.json}}"
output="${CONTENT_PUBLICATION_OUTPUT:-.tmp/ci-artifacts/content-publication/preview-rehearsal.json}"
remote_dir="${CONTENT_PUBLICATION_REMOTE_DIR:-/var/lib/personal-site/runtime-viability}"
project="${RUNTIME_VIABILITY_PROJECT:-personal-site-runtime-viability}"
ssh_private_key_file=""
ssh_known_hosts_file=""
remote_accepted_output=""
remote_rejected_output=""
delete_ssh_private_key_file="false"

function cleanup {
    if [[ "${delete_ssh_private_key_file}" == "true" && -n "${ssh_private_key_file}" ]]; then
        rm -f "${ssh_private_key_file}"
    fi

    if [[ -n "${ssh_known_hosts_file}" ]]; then
        rm -f "${ssh_known_hosts_file}"
    fi

    if [[ -n "${remote_accepted_output}" ]]; then
        rm -f "${remote_accepted_output}"
    fi

    if [[ -n "${remote_rejected_output}" ]]; then
        rm -f "${remote_rejected_output}"
    fi
}

trap cleanup EXIT

function usage {
    cat <<'USAGE'
Usage:
  ./run content:rehearse-preview .tmp/ci-artifacts/preview/deploy-receipt.json

Changes content on a running private preview, sends signed webhook deliveries,
and verifies that good content goes live while bad content leaves last-good live.
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
        usage >&2
        echo "fatal: preview receipt not found: ${path}" >&2
        exit 1
    fi
}

function read_receipt_value {
    local filter

    filter="${1}"
    jq -r "${filter} // empty" "${preview_receipt}"
}

function assert_http_origin {
    local name
    local value

    name="${1}"
    value="${2}"

    if [[ ! "${value}" =~ ^https?://[A-Za-z0-9._:-]+$ ]]; then
        echo "fatal: ${name} must be an http(s) origin; got ${value:-empty}" >&2
        exit 1
    fi
}

function origin_host {
    local origin
    local without_scheme

    origin="${1}"
    without_scheme="${origin#http://}"
    without_scheme="${without_scheme#https://}"
    printf "%s\n" "${without_scheme%%:*}"
}

function assert_preview_url_matches_host {
    local url_host

    url_host="$(origin_host "${public_base_url}")"

    if [[ "${url_host}" != "${public_ipv4}" ]]; then
        echo "fatal: preview.url host must match host.public_ipv4" >&2
        echo "fatal: preview.url=${public_base_url}, host.public_ipv4=${public_ipv4}" >&2
        exit 1
    fi
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

function assert_private_preview_receipt {
    local receipt_type
    local lifecycle
    local outcome

    receipt_type="$(read_receipt_value '.receipt_type')"
    lifecycle="$(read_receipt_value '.host.lifecycle')"
    outcome="$(read_receipt_value '.outcome')"

    if [[ "${receipt_type}" != "private_preview" ]]; then
        echo "fatal: receipt_type must be private_preview" >&2
        exit 1
    fi

    if [[ "${lifecycle}" != "disposable" ]]; then
        echo "fatal: preview host lifecycle must be disposable" >&2
        exit 1
    fi

    if [[ "${outcome}" != "reviewable" ]]; then
        echo "fatal: preview must be reviewable before content rehearsal" >&2
        exit 1
    fi
}

function run_remote_rehearsal {
    local phase
    local accepted_sha

    phase="${1}"
    accepted_sha="${2:-}"

    "${ssh_base[@]}" "cd '${remote_dir}' && RUNTIME_VIABILITY_PROJECT='${project}' CONTENT_PUBLICATION_PHASE='${phase}' CONTENT_PUBLICATION_ACCEPTED_SHA='${accepted_sha}' bash -s" <<'REMOTE_SCRIPT'
set -o errexit
set -o nounset
set -o pipefail

artifact_dir="artifacts/content-publication"
worktree="publication/rehearsal-worktree"
content_path="notes/publication-flow-preview/en.md"
note_url="publication-flow-preview"
route="/en/note/${note_url}"
rehearsal_id="content-publication-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}"
valid_body="Body published through private preview rehearsal ${rehearsal_id}."

function compose {
    docker compose --project-name "${RUNTIME_VIABILITY_PROJECT}" --env-file .env -f compose.yml "$@"
}

function load_env {
    set -o allexport
    # shellcheck disable=SC1091
    . ./.env
    set +o allexport
}

function write_valid_note {
    mkdir -p "$(dirname "${worktree}/${content_path}")"

    cat > "${worktree}/${content_path}" <<MARKDOWN
---
title: "Publication Flow Preview"
url: "${note_url}"
introduction: "Preview publication rehearsal"
published_at: "2024-07-27T14:30:00Z"
is_draft: false
---

${valid_body}
MARKDOWN
}

function write_invalid_note {
    cat > "${worktree}/${content_path}" <<'MARKDOWN'
---
title: "Broken Publication Flow Preview"
url: "publication-flow-preview"
is_draft: false
--

# Broken frontmatter
MARKDOWN
}

function commit_content {
    local message

    message="${1}"

    git -C "${worktree}" add .
    git -C "${worktree}" commit -m "${message}" >/dev/null
    git -C "${worktree}" rev-parse HEAD
}

function push_content {
    git -C "${worktree}" push origin main >/dev/null
}

function webhook_payload {
    local sha
    local delivery_id
    local change_key

    sha="${1}"
    delivery_id="${2}"
    change_key="${3}"

    jq -n \
        --arg sha "${sha}" \
        --arg delivery_id "${delivery_id}" \
        --arg repository_url "${CONTENT_REPO_URL}" \
        --arg path "${content_path}" \
        --arg change_key "${change_key}" \
        '{
            ref: "refs/heads/main",
            after: $sha,
            delivery_id: $delivery_id,
            repository: {
                clone_url: $repository_url,
                ssh_url: $repository_url,
                full_name: "zaneriley/personal-site-content",
                name: "personal-site-content",
                owner: {id: 1, login: "zaneriley", name: "zaneriley"}
            },
            commits: [
                {
                    id: $sha,
                    added: (if $change_key == "added" then [$path] else [] end),
                    modified: (if $change_key == "modified" then [$path] else [] end),
                    removed: []
                }
            ],
            sender: {id: 1, login: "publication-rehearsal"}
        }'
}

function webhook_signature {
    local payload

    payload="${1}"

    printf "%s" "${payload}" |
        compose exec -T web /app/bin/portfolio eval '
payload = IO.read(:stdio, :all)
secret = System.fetch_env!("GITHUB_WEBHOOK_SECRET")
signature = :crypto.mac(:hmac, :sha256, secret, payload) |> Base.encode16(case: :lower)
IO.write("sha256=#{signature}")
'
}

function send_webhook {
    local payload
    local delivery_id
    local body_file
    local headers_file
    local signature
    local status

    payload="${1}"
    delivery_id="${2}"
    signature="${3:-}"
    body_file="${artifact_dir}/${delivery_id}-body.txt"
    headers_file="${artifact_dir}/${delivery_id}-headers.txt"

    if [[ -z "${signature}" ]]; then
        signature="$(webhook_signature "${payload}")"
    fi

    status="$(
        curl -sS \
            -D "${headers_file}" \
            -o "${body_file}" \
            -w "%{http_code}" \
            -X POST \
            -H "content-type: application/json" \
            -H "x-github-event: push" \
            -H "x-github-delivery: ${delivery_id}" \
            -H "x-hub-signature-256: ${signature}" \
            --data-binary "${payload}" \
            "http://127.0.0.1:${RUNTIME_VIABILITY_HOST_PORT}/api/v1/content/push"
    )"

    printf "%s\n" "${status}"
}

function wrong_signature_payload {
    local sha
    local delivery_id

    sha="${1}"
    delivery_id="${2}"

    jq -n \
        --arg sha "${sha}" \
        --arg delivery_id "${delivery_id}" \
        --arg repository_url "${CONTENT_REPO_URL}" \
        '{
            ref: "refs/heads/main",
            after: $sha,
            delivery_id: $delivery_id,
            repository: {
                clone_url: $repository_url,
                ssh_url: $repository_url,
                full_name: "zaneriley/personal-site-content",
                name: "personal-site-content",
                owner: {id: 1, login: "zaneriley", name: "zaneriley"}
            },
            commits: [
                {
                    id: $sha,
                    added: ["README.md"],
                    modified: [],
                    removed: []
                }
            ],
            sender: {id: 1, login: "publication-rehearsal"}
        }'
}

function content_status {
    compose exec -T web /app/bin/content status --json
}

load_env
mkdir -p "${artifact_dir}"
rm -rf "${worktree}"

if [[ ! -d "publication/content-source.git" ]]; then
    echo "fatal: publication/content-source.git is missing; rerun private preview with current runtime viability" >&2
    exit 1
fi

git clone publication/content-source.git "${worktree}" >/dev/null 2>&1
git -C "${worktree}" config user.email "preview@example.test"
git -C "${worktree}" config user.name "Preview Content"

initial_status="$(content_status)"

status="pass"
failure_reason=""

case "${CONTENT_PUBLICATION_PHASE}" in
    accepted)
        wrong_signature_delivery_id="content-publication-rehearsal-wrong-signature-${rehearsal_id}"
        wrong_signature_payload="$(
            wrong_signature_payload \
                "$(jq -r '.live' <<< "${initial_status}")" \
                "${wrong_signature_delivery_id}"
        )"
        wrong_signature_http_status="$(
            send_webhook \
                "${wrong_signature_payload}" \
                "${wrong_signature_delivery_id}" \
                "sha256=$(printf '0%.0s' {1..64})"
        )"
        after_wrong_signature_status="$(content_status)"

        write_valid_note
        accepted_sha="$(commit_content "Publish preview rehearsal note")"
        push_content
        accepted_delivery_id="content-publication-rehearsal-accepted-${rehearsal_id}"
        accepted_payload="$(webhook_payload "${accepted_sha}" "${accepted_delivery_id}" "added")"
        accepted_http_status="$(send_webhook "${accepted_payload}" "${accepted_delivery_id}")"
        accepted_status="$(content_status)"

        if [[ "$(jq -r '.live // empty' <<< "${initial_status}")" == "" ]]; then
            status="fail"
            failure_reason="app_not_running_before_content_change"
        elif [[ "${wrong_signature_http_status}" == "200" ]]; then
            status="fail"
            failure_reason="wrong_signature_delivery_accepted"
        elif [[ "$(jq -S . <<< "${after_wrong_signature_status}")" != "$(jq -S . <<< "${initial_status}")" ]]; then
            status="fail"
            failure_reason="wrong_signature_changed_publication_state"
        elif [[ "${accepted_http_status}" != "200" ]]; then
            status="fail"
            failure_reason="accepted_delivery_http_${accepted_http_status}"
        elif [[ "$(jq -r '.live' <<< "${accepted_status}")" != "${accepted_sha}" ]]; then
            status="fail"
            failure_reason="accepted_sha_not_live"
        fi

        jq -n \
            --arg status "${status}" \
            --arg failure_reason "${failure_reason}" \
            --arg route "${route}" \
            --arg valid_body "${valid_body}" \
            --arg wrong_signature_http_status "${wrong_signature_http_status}" \
            --arg accepted_sha "${accepted_sha}" \
            --arg accepted_http_status "${accepted_http_status}" \
            --argjson initial_status "${initial_status}" \
            --argjson after_wrong_signature_status "${after_wrong_signature_status}" \
            --argjson accepted_status "${accepted_status}" \
            '{
                status: $status,
                failure_reason: (if $failure_reason == "" then null else $failure_reason end),
                route: $route,
                expected_body: $valid_body,
                initial: {
                    live_content_sha: $initial_status.live,
                    last_delivery_id: $initial_status.last_delivery_id
                },
                wrong_signature: {
                    http_status: ($wrong_signature_http_status | tonumber),
                    live_content_sha_after_probe: $after_wrong_signature_status.live,
                    last_delivery_id_after_probe: $after_wrong_signature_status.last_delivery_id
                },
                accepted: {
                    content_sha: $accepted_sha,
                    http_status: ($accepted_http_status | tonumber),
                    live_content_sha: $accepted_status.live
                }
            }'
        ;;
    rejected)
        write_invalid_note
        rejected_sha="$(commit_content "Reject preview rehearsal note")"
        push_content
        rejected_delivery_id="content-publication-rehearsal-rejected-${rehearsal_id}"
        rejected_payload="$(webhook_payload "${rejected_sha}" "${rejected_delivery_id}" "modified")"
        rejected_http_status="$(send_webhook "${rejected_payload}" "${rejected_delivery_id}")"
        rejected_status="$(content_status)"

        if [[ "${rejected_http_status}" != "200" ]]; then
            status="fail"
            failure_reason="rejected_delivery_http_${rejected_http_status}"
        elif [[ "$(jq -r '.live' <<< "${rejected_status}")" != "${CONTENT_PUBLICATION_ACCEPTED_SHA}" ]]; then
            status="fail"
            failure_reason="last_good_not_preserved"
        elif [[ "$(jq -r '.last_rejected_sha' <<< "${rejected_status}")" != "${rejected_sha}" ]]; then
            status="fail"
            failure_reason="rejected_sha_not_recorded"
        elif ! jq -e --arg path "${content_path}" '.last_rejected_reason | contains($path)' <<< "${rejected_status}" >/dev/null; then
            status="fail"
            failure_reason="rejected_reason_missing_path"
        elif ! jq -e '.last_rejected_reason | contains("invalid markdown format")' <<< "${rejected_status}" >/dev/null; then
            status="fail"
            failure_reason="rejected_reason_missing"
        fi

        jq -n \
            --arg status "${status}" \
            --arg failure_reason "${failure_reason}" \
            --arg rejected_sha "${rejected_sha}" \
            --arg rejected_http_status "${rejected_http_status}" \
            --argjson rejected_status "${rejected_status}" \
            '{
                status: $status,
                failure_reason: (if $failure_reason == "" then null else $failure_reason end),
                rejected: {
                    content_sha: $rejected_sha,
                    http_status: ($rejected_http_status | tonumber),
                    live_content_sha_after_rejection: $rejected_status.live,
                    last_rejected_sha: $rejected_status.last_rejected_sha,
                    last_rejected_reason: $rejected_status.last_rejected_reason
                }
            }'
        ;;
    *)
        echo "fatal: unknown content publication phase: ${CONTENT_PUBLICATION_PHASE}" >&2
        exit 64
        ;;
esac

if [[ "${status}" != "pass" ]]; then
    exit 1
fi
REMOTE_SCRIPT
}

function write_failure_receipt {
    local reason

    reason="${1}"

    jq -n \
        --arg reason "${reason}" \
        '{
            schema_version: 1,
            receipt_type: "content_publication_rehearsal",
            status: "fail",
            failure_reason: $reason
        }' > "${output}"
}

function assert_public_route_contains {
    local label
    local route
    local expected_body
    local body_file
    local body

    label="${1}"
    route="${2}"
    expected_body="${3}"
    body_file="$(mktemp)"

    if ! curl -fsS -o "${body_file}" "${public_base_url}${route}"; then
        rm -f "${body_file}"
        write_failure_receipt "${label}_route_fetch_failed"
        echo "content publication rehearsal failed" >&2
        echo "failure_reason=${label}_route_fetch_failed" >&2
        exit 1
    fi

    body="$(cat "${body_file}")"
    rm -f "${body_file}"

    if ! grep -F "${expected_body}" <<< "${body}" >/dev/null; then
        write_failure_receipt "${label}_route_missing_body"
        echo "content publication rehearsal failed" >&2
        echo "failure_reason=${label}_route_missing_body" >&2
        exit 1
    fi
}

require_command jq
require_command ssh
require_command curl
require_file "${preview_receipt}"
assert_private_preview_receipt
configure_ssh_private_key

public_ipv4="$(read_receipt_value '.host.public_ipv4')"
public_base_url="$(read_receipt_value '.preview.url')"

if [[ -z "${public_ipv4}" ]]; then
    echo "fatal: preview receipt must include host.public_ipv4" >&2
    exit 1
fi

assert_http_origin "preview.url" "${public_base_url}"
assert_preview_url_matches_host

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

mkdir -p "$(dirname "${output}")"
remote_accepted_output="$(mktemp)"
remote_rejected_output="$(mktemp)"

if run_remote_rehearsal accepted > "${remote_accepted_output}"; then
    :
else
    accepted_status="$?"
    cp "${remote_accepted_output}" "${output}"
    if [[ ! -s "${output}" ]]; then
        write_failure_receipt "accepted_phase_failed"
    fi
    echo "content publication rehearsal failed" >&2
    jq -r '"failure_reason=\(.failure_reason // "unknown")"' "${output}" >&2 || true
    exit "${accepted_status}"
fi

accepted_sha="$(jq -r '.accepted.content_sha' "${remote_accepted_output}")"
route="$(jq -r '.route' "${remote_accepted_output}")"
expected_body="$(jq -r '.expected_body' "${remote_accepted_output}")"
assert_public_route_contains "accepted" "${route}" "${expected_body}"

if run_remote_rehearsal rejected "${accepted_sha}" > "${remote_rejected_output}"; then
    :
else
    rejected_status="$?"
    cp "${remote_rejected_output}" "${output}"
    if [[ ! -s "${output}" ]]; then
        write_failure_receipt "rejected_phase_failed"
    fi
    echo "content publication rehearsal failed" >&2
    jq -r '"failure_reason=\(.failure_reason // "unknown")"' "${output}" >&2 || true
    exit "${rejected_status}"
fi

assert_public_route_contains "last_good" "${route}" "${expected_body}"

jq -s \
    '.[0] * .[1] | .schema_version = 1 | .receipt_type = "content_publication_rehearsal" | .status = "pass" | .failure_reason = null' \
    "${remote_accepted_output}" \
    "${remote_rejected_output}" > "${output}"

echo "content publication rehearsal passed"
echo "artifact written: ${output}"
