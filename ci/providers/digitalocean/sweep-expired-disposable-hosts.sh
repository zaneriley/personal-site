#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tag_name="${DO_SWEEP_TAG_NAME:-preview-lease}"
now_epoch="${SWEEP_NOW_EPOCH:-$(date -u +%s)}"
dry_run="${SWEEP_DRY_RUN:-0}"
page=1
destroyed_count=0
expired_count=0
skipped_count=0

function load_digitalocean_token {
    if [[ -n "${DIGITALOCEAN_TOKEN:-}" ]]; then
        return 0
    fi

    if [[ -n "${DIGITALOCEAN_TOKEN_FILE:-}" ]]; then
        DIGITALOCEAN_TOKEN="$(< "${DIGITALOCEAN_TOKEN_FILE}")"
        export DIGITALOCEAN_TOKEN
        return 0
    fi

    if [[ "${DIGITALOCEAN_TOKEN_STDIN:-0}" == "1" ]]; then
        IFS= read -r DIGITALOCEAN_TOKEN
        export DIGITALOCEAN_TOKEN
        return 0
    fi
}

function require_env {
    local name

    name="${1}"
    if [[ -z "${!name:-}" ]]; then
        echo "fatal: ${name} is required" >&2
        return 1
    fi
}

function do_api {
    local method
    local path
    local body_file
    local status_code

    method="${1}"
    path="${2}"
    body_file="$(mktemp)"

    status_code="$(curl -sS \
        -o "${body_file}" \
        -w "%{http_code}" \
        -X "${method}" \
        -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
        "https://api.digitalocean.com/v2/${path}" || true)"

    if [[ ! "${status_code}" =~ ^2 ]]; then
        echo "fatal: DigitalOcean ${method} ${path} failed with HTTP ${status_code}" >&2

        if [[ -s "${body_file}" ]]; then
            jq '.' "${body_file}" >&2 || cat "${body_file}" >&2
        fi

        rm -f "${body_file}"
        return 1
    fi

    cat "${body_file}"
    rm -f "${body_file}"
}

function tag_value {
    local prefix
    local tag

    prefix="${1}"
    shift

    for tag in "$@"; do
        if [[ "${tag}" == "${prefix}"* ]]; then
            printf "%s\n" "${tag#"${prefix}"}"
            return 0
        fi
    done

    return 1
}

function has_tag {
    local expected
    local tag

    expected="${1}"
    shift

    for tag in "$@"; do
        if [[ "${tag}" == "${expected}" ]]; then
            return 0
        fi
    done

    return 1
}

function inspect_droplet {
    local droplet_json
    local droplet_id
    local droplet_name
    local expires_epoch
    local -a tags

    droplet_json="${1}"
    droplet_id="$(jq -r '.id' <<< "${droplet_json}")"
    droplet_name="$(jq -r '.name' <<< "${droplet_json}")"
    tags=()
    while IFS= read -r tag; do
        tags+=("${tag}")
    done < <(jq -r '.tags[]?' <<< "${droplet_json}")

    if [[ ! "${droplet_name}" =~ ^personal-site-disposable- ]]; then
        echo "skip droplet ${droplet_id}: unexpected name ${droplet_name}" >&2
        skipped_count=$((skipped_count + 1))
        return 0
    fi

    if ! has_tag "personal-site" "${tags[@]}" || ! has_tag "disposable-host" "${tags[@]}"; then
        echo "skip droplet ${droplet_id}: missing expected disposable-host tags" >&2
        skipped_count=$((skipped_count + 1))
        return 0
    fi

    if ! expires_epoch="$(tag_value "preview-expires-" "${tags[@]}")"; then
        echo "skip droplet ${droplet_id}: missing preview-expires tag" >&2
        skipped_count=$((skipped_count + 1))
        return 0
    fi

    if [[ ! "${expires_epoch}" =~ ^[0-9]+$ ]]; then
        echo "skip droplet ${droplet_id}: invalid preview-expires tag" >&2
        skipped_count=$((skipped_count + 1))
        return 0
    fi

    if (( expires_epoch > now_epoch )); then
        echo "keep droplet ${droplet_id}: lease expires at ${expires_epoch}"
        return 0
    fi

    expired_count=$((expired_count + 1))

    if [[ "${dry_run}" == "1" ]]; then
        echo "would destroy expired droplet ${droplet_id}"
        return 0
    fi

    CONFIRM_DESTROY=1 \
        DROPLET_ID="${droplet_id}" \
        "${script_dir}/destroy-disposable-host.sh"
    destroyed_count=$((destroyed_count + 1))
}

load_digitalocean_token
require_env DIGITALOCEAN_TOKEN

while :; do
    response="$(do_api GET "droplets?tag_name=${tag_name}&per_page=200&page=${page}")"
    count="$(jq '.droplets | length' <<< "${response}")"

    if [[ "${count}" == "0" ]]; then
        break
    fi

    while IFS= read -r droplet_json; do
        inspect_droplet "${droplet_json}"
    done < <(jq -c '.droplets[]' <<< "${response}")

    if (( count < 200 )); then
        break
    fi

    page=$((page + 1))
done

echo "expired_count=${expired_count}"
echo "destroyed_count=${destroyed_count}"
echo "skipped_count=${skipped_count}"
