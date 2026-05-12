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

echo "disposable runtime proof input test passed"
