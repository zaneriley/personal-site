#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

deploy_receipt="${1:-}"
tmpdir=""

function cleanup {
    if [[ -n "${tmpdir}" ]]; then
        rm -rf "${tmpdir}"
    fi
}

trap cleanup EXIT

function usage {
    cat <<'USAGE'
Usage:
  ./run preview:destroy .tmp/ci-artifacts/preview/deploy-receipt.json

Destroys the disposable DigitalOcean host recorded in a preview deploy receipt.
The provider destroy path still verifies ownership by remote tags and name.
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

if [[ -z "${deploy_receipt}" || ! -f "${deploy_receipt}" ]]; then
    usage >&2
    exit 1
fi

require_command jq

droplet_id="$(jq -r '.host.droplet_id // empty' "${deploy_receipt}")"
host_kind="$(jq -r '.host.kind // empty' "${deploy_receipt}")"
host_lifecycle="$(jq -r '.host.lifecycle // empty' "${deploy_receipt}")"

if [[ -z "${droplet_id}" ]]; then
    echo "fatal: preview deploy receipt does not contain host.droplet_id" >&2
    exit 1
fi

if [[ "${host_kind}" != "disposable_host" || "${host_lifecycle}" != "disposable" ]]; then
    echo "fatal: refusing to destroy non-disposable preview host" >&2
    jq '{host}' "${deploy_receipt}" >&2
    exit 1
fi

tmpdir="$(mktemp -d)"
host_receipt="${tmpdir}/host.json"
jq '{droplet_id: .host.droplet_id}' "${deploy_receipt}" > "${host_receipt}"

CONFIRM_DESTROY=1 ./run host:disposable:destroy "${host_receipt}"
