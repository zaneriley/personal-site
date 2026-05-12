#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function usage {
    cat <<'USAGE'
Usage:
  DROPLET_ID=<id> ./run host:disposable:status
  ./run host:disposable:status ci/digitalocean-host.json
  ./run host:disposable:status
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

function do_api {
    local path
    local body_file
    local status_code

    path="${1}"
    body_file="$(mktemp)"

    status_code="$(curl -sS \
        -o "${body_file}" \
        -w "%{http_code}" \
        -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
        "https://api.digitalocean.com/v2/${path}" || true)"

    if [[ ! "${status_code}" =~ ^2 ]]; then
        echo "fatal: DigitalOcean GET ${path} failed with HTTP ${status_code}" >&2

        if [[ -s "${body_file}" ]]; then
            jq '.' "${body_file}" >&2 || cat "${body_file}" >&2
        fi

        rm -f "${body_file}"
        return 1
    fi

    cat "${body_file}"
    rm -f "${body_file}"
}

function list_disposable_origins {
    local tag_name
    local response

    tag_name="${DO_LIST_TAG:-disposable-origin}"
    response="$(do_api "droplets?tag_name=${tag_name}")"

    printf "%s" "${response}" | jq --arg tag "${tag_name}" '{
        provider: "digitalocean",
        tag: $tag,
        count: (.droplets | length),
        droplets: [
            .droplets[] | {
                droplet_id: (.id | tostring),
                name,
                status,
                region: .region.slug,
                size: .size.slug,
                image: .image.slug,
                public_ipv4: ([.networks.v4[]? | select(.type == "public") | .ip_address] | first),
                public_ipv6: ([.networks.v6[]? | .ip_address] | first),
                tags,
                created_at
            }
        ]
    }'
}

require_env DIGITALOCEAN_TOKEN

droplet_id="$(resolve_droplet_id "${1:-}")"

if [[ -z "${droplet_id}" ]]; then
    list_disposable_origins
    exit 0
fi

response="$(do_api "droplets/${droplet_id}")"

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
