#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function usage {
    cat <<'USAGE'
Usage:
  DROPLET_ID=<id> CONFIRM_DESTROY=1 ./run deploy:origin:destroy
  CONFIRM_DESTROY=1 ./run deploy:origin:destroy ci/digitalocean-origin.json

Destroying a DigitalOcean Droplet is irreversible. This command requires
CONFIRM_DESTROY=1 and either DROPLET_ID or a JSON artifact with droplet_id.
USAGE
}

function require_env {
    local name

    name="${1}"

    if [[ -z "${!name:-}" ]]; then
        echo "fatal: ${name} is required" >&2
        return 1
    fi
}

function resolve_droplet_id {
    local source

    source="${1:-}"

    if [[ -n "${DROPLET_ID:-}" ]]; then
        printf "%s" "${DROPLET_ID}"
        return 0
    fi

    if [[ -n "${source}" && -f "${source}" ]]; then
        jq -r '.droplet_id // empty' "${source}"
        return 0
    fi
}

require_env DIGITALOCEAN_TOKEN

if [[ "${CONFIRM_DESTROY:-}" != "1" ]]; then
    usage >&2
    exit 1
fi

droplet_id="$(resolve_droplet_id "${1:-}")"

if [[ -z "${droplet_id}" ]]; then
    usage >&2
    exit 1
fi

status_code="$(
    curl -fsS \
        -o /tmp/personal-site-do-destroy-response.json \
        -w "%{http_code}" \
        -X DELETE \
        -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
        "https://api.digitalocean.com/v2/droplets/${droplet_id}" || true
)"

case "${status_code}" in
    204)
        echo "DigitalOcean droplet destroyed"
        echo "droplet_id=${droplet_id}"
        ;;
    404)
        echo "DigitalOcean droplet already absent"
        echo "droplet_id=${droplet_id}"
        ;;
    *)
        echo "fatal: DigitalOcean destroy failed with HTTP ${status_code}" >&2
        if [[ -s /tmp/personal-site-do-destroy-response.json ]]; then
            jq '.' /tmp/personal-site-do-destroy-response.json >&2 || cat /tmp/personal-site-do-destroy-response.json >&2
        fi
        exit 1
        ;;
esac
