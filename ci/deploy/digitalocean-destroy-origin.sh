#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

response_file=""

function cleanup {
    if [[ -n "${response_file}" ]]; then
        rm -f "${response_file}"
    fi
}

trap cleanup EXIT

function usage {
    cat <<'USAGE'
Usage:
  DROPLET_ID=<id> CONFIRM_DESTROY=1 ./run host:disposable:destroy
  CONFIRM_DESTROY=1 ./run host:disposable:destroy ci/digitalocean-host.json

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

function do_api_to_file {
    local method
    local path
    local status_code

    method="${1}"
    path="${2}"
    response_file="$(mktemp)"

    status_code="$(curl -sS \
        -o "${response_file}" \
        -w "%{http_code}" \
        -X "${method}" \
        -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
        "https://api.digitalocean.com/v2/${path}" || true)"

    printf "%s" "${status_code}"
}

function print_api_error {
    local message

    message="${1}"
    echo "${message}" >&2

    if [[ -s "${response_file}" ]]; then
        jq '.' "${response_file}" >&2 || cat "${response_file}" >&2
    fi
}

function verify_disposable_origin {
    local expected_tags_json
    local missing_tags
    local name

    expected_tags_json="$(
        printf "%s" "${DO_EXPECTED_TAGS:-personal-site,disposable-origin,preview}" |
            jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))'
    )"

    missing_tags="$(
        jq -r --argjson expected "${expected_tags_json}" '
            [ $expected[] as $tag | select((.droplet.tags // []) | index($tag) | not) ] | join(",")
        ' "${response_file}"
    )"

    if [[ -n "${missing_tags}" ]]; then
        echo "fatal: refusing to destroy Droplet ${droplet_id}; missing expected tags: ${missing_tags}" >&2
        jq '{id: .droplet.id, name: .droplet.name, tags: .droplet.tags}' "${response_file}" >&2
        exit 1
    fi

    name="$(jq -r '.droplet.name' "${response_file}")"

    if [[ ! "${name}" =~ ^personal-site-preview- ]]; then
        echo "fatal: refusing to destroy Droplet ${droplet_id}; unexpected name: ${name}" >&2
        jq '{id: .droplet.id, name: .droplet.name, tags: .droplet.tags}' "${response_file}" >&2
        exit 1
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

status_code="$(do_api_to_file GET "droplets/${droplet_id}")"

case "${status_code}" in
    200)
        verify_disposable_origin
        ;;
    404)
        echo "DigitalOcean droplet already absent"
        echo "droplet_id=${droplet_id}"
        exit 0
        ;;
    *)
        print_api_error "fatal: DigitalOcean lookup failed with HTTP ${status_code}"
        exit 1
        ;;
esac

status_code="$(do_api_to_file DELETE "droplets/${droplet_id}")"

case "${status_code}" in
    204)
        echo "DigitalOcean droplet destroyed"
        echo "droplet_id=${droplet_id}"
        ;;
    404)
        echo "DigitalOcean droplet already absent after ownership check"
        echo "droplet_id=${droplet_id}"
        ;;
    *)
        print_api_error "fatal: DigitalOcean destroy failed with HTTP ${status_code}"
        exit 1
        ;;
esac
