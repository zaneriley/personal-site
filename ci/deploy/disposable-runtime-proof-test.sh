#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmpdir="$(mktemp -d)"

function cleanup {
    rm -rf "${tmpdir}"
}

trap cleanup EXIT

function write_receipt {
    local lifecycle_status
    local path

    lifecycle_status="${1}"
    path="${2}"

    jq -n \
        --arg lifecycle_status "${lifecycle_status}" \
        '{
            droplet_id: "123",
            public_ipv4: "203.0.113.10",
            lifecycle_status: $lifecycle_status
        }' > "${path}"
}

function assert_contains {
    local file
    local expected

    file="${1}"
    expected="${2}"

    if ! grep -F "${expected}" "${file}" >/dev/null; then
        echo "expected ${file} to contain: ${expected}" >&2
        cat "${file}" >&2
        exit 1
    fi
}

function assert_json {
    local file
    local filter

    file="${1}"
    filter="${2}"

    if ! jq -e "${filter}" "${file}" >/dev/null; then
        echo "expected ${file} to satisfy jq filter: ${filter}" >&2
        cat "${file}" >&2
        exit 1
    fi
}

ready_receipt="${tmpdir}/ready.json"
waiting_receipt="${tmpdir}/waiting.json"
write_receipt "ready" "${ready_receipt}"
write_receipt "waiting_for_network" "${waiting_receipt}"

if RUNTIME_PROOF_VALIDATE_ONLY=1 \
    APP_IMAGE_REF="ghcr.io/zaneriley/personal-site:latest" \
    "${script_dir}/disposable-runtime-proof.sh" "${ready_receipt}" > "${tmpdir}/floating.out" 2>&1; then
    echo "expected floating image ref to fail" >&2
    exit 1
fi

assert_contains "${tmpdir}/floating.out" "APP_IMAGE_REF must be digest-pinned"

if RUNTIME_PROOF_VALIDATE_ONLY=1 \
    APP_IMAGE_REF="ghcr.io/zaneriley/personal-site@sha256:2da620d6fe3a64aef7d23927835722be08d56c6449f3c557f14c6993b59ee467" \
    "${script_dir}/disposable-runtime-proof.sh" "${waiting_receipt}" > "${tmpdir}/waiting.out" 2>&1; then
    echo "expected non-ready receipt to fail" >&2
    exit 1
fi

assert_contains "${tmpdir}/waiting.out" "lifecycle_status must be ready"

RUNTIME_PROOF_VALIDATE_ONLY=1 \
    APP_IMAGE_REF="ghcr.io/zaneriley/personal-site@sha256:2da620d6fe3a64aef7d23927835722be08d56c6449f3c557f14c6993b59ee467" \
    "${script_dir}/disposable-runtime-proof.sh" "${ready_receipt}" > "${tmpdir}/ready.out" 2>&1

assert_contains "${tmpdir}/ready.out" "runtime proof inputs valid"

routes_file="${script_dir}/preview-browser-routes.json"
assert_json "${routes_file}" '.schema_version == 1'
assert_json "${routes_file}" '.routes | any(.path == "/en/note/prod-build-smoke-note" and (.required_text | index("Prod Build Smoke Note")))'
assert_json "${routes_file}" '.routes | any(.path == "/en/case-study/prod-build-smoke-case-study" and (.required_text | index("Prod Build Smoke Case Study")))'
assert_json "${routes_file}" '.routes | any(.path == "/en/note/this-route-cannot-exist-xyzzy" and (.allowed_statuses | index(404)))'
assert_json "${routes_file}" '.forbidden_text | index("We ran into an issue loading this note")'
assert_json "${routes_file}" '.wrong_host_text | index("web:8000")'

echo "disposable runtime proof input test passed"
