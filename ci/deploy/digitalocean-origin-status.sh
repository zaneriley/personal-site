#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function usage {
    cat <<'USAGE'
Usage:
  DROPLET_ID=<id> ./run deploy:origin:status
  ./run deploy:origin:status ci/digitalocean-origin.json
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

droplet_id="$(resolve_droplet_id "${1:-}")"

if [[ -z "${droplet_id}" ]]; then
    usage >&2
    exit 1
fi

response="$(
    curl -fsS \
        -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
        "https://api.digitalocean.com/v2/droplets/${droplet_id}"
)"

printf "%s" "${response}" | jq '{
    provider: "digitalocean",
    droplet_id: (.droplet.id | tostring),
    name: .droplet.name,
    status: .droplet.status,
    region: .droplet.region.slug,
    size: .droplet.size.slug,
    image: .droplet.image.slug,
    public_ipv4: ([.droplet.networks.v4[]? | select(.type == "public") | .ip_address] | first),
    public_ipv6: ([.droplet.networks.v6[]? | .ip_address] | first),
    tags: .droplet.tags,
    created_at: .droplet.created_at
}'
