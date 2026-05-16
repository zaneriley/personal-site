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
delete_ssh_private_key_file="false"

function cleanup {
    if [[ "${delete_ssh_private_key_file}" == "true" && -n "${ssh_private_key_file}" ]]; then
        rm -f "${ssh_private_key_file}"
    fi

    if [[ -n "${ssh_known_hosts_file}" ]]; then
        rm -f "${ssh_known_hosts_file}"
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
    "${ssh_base[@]}" "cd '${remote_dir}' && RUNTIME_VIABILITY_PROJECT='${project}' bash -s" <<'REMOTE_SCRIPT'
set -o errexit
set -o nounset
set -o pipefail

artifact_dir="artifacts/content-publication"
worktree="publication/rehearsal-worktree"
content_path="notes/publication-flow-preview/en.md"
note_url="publication-flow-preview"
route="/en/note/${note_url}"
valid_body="Body published through private preview rehearsal."

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
        openssl dgst -sha256 -hmac "${GITHUB_WEBHOOK_SECRET}" -hex |
        awk '{ print "sha256=" $2 }'
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
    body_file="${artifact_dir}/${delivery_id}-body.txt"
    headers_file="${artifact_dir}/${delivery_id}-headers.txt"
    signature="$(webhook_signature "${payload}")"

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

function content_status {
    compose exec -T web /app/bin/content status --json
}

function route_body {
    curl -fsS "http://127.0.0.1:${RUNTIME_VIABILITY_HOST_PORT}${route}"
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

write_valid_note
accepted_sha="$(commit_content "Publish preview rehearsal note")"
push_content
accepted_delivery_id="content-publication-rehearsal-accepted"
accepted_payload="$(webhook_payload "${accepted_sha}" "${accepted_delivery_id}" "added")"
accepted_http_status="$(send_webhook "${accepted_payload}" "${accepted_delivery_id}")"
accepted_status="$(content_status)"
accepted_route_body="$(route_body)"

write_invalid_note
rejected_sha="$(commit_content "Reject preview rehearsal note")"
push_content
rejected_delivery_id="content-publication-rehearsal-rejected"
rejected_payload="$(webhook_payload "${rejected_sha}" "${rejected_delivery_id}" "modified")"
rejected_http_status="$(send_webhook "${rejected_payload}" "${rejected_delivery_id}")"
rejected_status="$(content_status)"
rejected_route_body="$(route_body)"

status="pass"
failure_reason=""

if [[ "${accepted_http_status}" != "200" ]]; then
    status="fail"
    failure_reason="accepted_delivery_http_${accepted_http_status}"
elif [[ "$(jq -r '.live' <<< "${accepted_status}")" != "${accepted_sha}" ]]; then
    status="fail"
    failure_reason="accepted_sha_not_live"
elif ! grep -F "${valid_body}" <<< "${accepted_route_body}" >/dev/null; then
    status="fail"
    failure_reason="accepted_route_missing_body"
elif [[ "${rejected_http_status}" != "200" ]]; then
    status="fail"
    failure_reason="rejected_delivery_http_${rejected_http_status}"
elif [[ "$(jq -r '.live' <<< "${rejected_status}")" != "${accepted_sha}" ]]; then
    status="fail"
    failure_reason="last_good_not_preserved"
elif [[ "$(jq -r '.last_rejected_sha' <<< "${rejected_status}")" != "${rejected_sha}" ]]; then
    status="fail"
    failure_reason="rejected_sha_not_recorded"
elif ! jq -e '.last_rejected_reason | contains("invalid markdown format")' <<< "${rejected_status}" >/dev/null; then
    status="fail"
    failure_reason="rejected_reason_missing"
elif ! grep -F "${valid_body}" <<< "${rejected_route_body}" >/dev/null; then
    status="fail"
    failure_reason="last_good_route_missing_body"
fi

jq -n \
    --arg status "${status}" \
    --arg failure_reason "${failure_reason}" \
    --arg route "${route}" \
    --arg accepted_sha "${accepted_sha}" \
    --arg rejected_sha "${rejected_sha}" \
    --arg accepted_http_status "${accepted_http_status}" \
    --arg rejected_http_status "${rejected_http_status}" \
    --argjson accepted_status "${accepted_status}" \
    --argjson rejected_status "${rejected_status}" \
    '{
        schema_version: 1,
        receipt_type: "content_publication_rehearsal",
        status: $status,
        failure_reason: (if $failure_reason == "" then null else $failure_reason end),
        route: $route,
        accepted: {
            content_sha: $accepted_sha,
            http_status: ($accepted_http_status | tonumber),
            live_content_sha: $accepted_status.live
        },
        rejected: {
            content_sha: $rejected_sha,
            http_status: ($rejected_http_status | tonumber),
            live_content_sha_after_rejection: $rejected_status.live,
            last_rejected_sha: $rejected_status.last_rejected_sha,
            last_rejected_reason: $rejected_status.last_rejected_reason
        }
    }'

if [[ "${status}" != "pass" ]]; then
    exit 1
fi
REMOTE_SCRIPT
}

require_command jq
require_command ssh
require_file "${preview_receipt}"
assert_private_preview_receipt
configure_ssh_private_key

public_ipv4="$(read_receipt_value '.host.public_ipv4')"

if [[ -z "${public_ipv4}" ]]; then
    echo "fatal: preview receipt must include host.public_ipv4" >&2
    exit 1
fi

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

if run_remote_rehearsal > "${output}"; then
    echo "content publication rehearsal passed"
    echo "artifact written: ${output}"
else
    status="$?"
    echo "content publication rehearsal failed" >&2
    if [[ -s "${output}" ]]; then
        jq -r '"failure_reason=\(.failure_reason // "unknown")"' "${output}" >&2 || true
    fi
    exit "${status}"
fi
