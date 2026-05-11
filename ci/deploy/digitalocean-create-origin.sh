#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cloud_init_template="${script_dir}/digitalocean-origin-cloud-init.yml"

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
    local data_arg

    method="${1}"
    path="${2}"
    data_arg="${3:-}"

    if [[ -n "${data_arg}" ]]; then
        curl -fsS \
            -X "${method}" \
            -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "${data_arg}" \
            "https://api.digitalocean.com/v2/${path}"
    else
        curl -fsS \
            -X "${method}" \
            -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
            "https://api.digitalocean.com/v2/${path}"
    fi
}

function droplet_public_ipv4 {
    jq -r '.droplet.networks.v4[]? | select(.type == "public") | .ip_address' | head -n 1
}

require_env DIGITALOCEAN_TOKEN
require_env DEPLOY_SSH_PUBLIC_KEY

if [[ ! -f "${cloud_init_template}" ]]; then
    echo "fatal: cloud-init template missing: ${cloud_init_template}" >&2
    exit 1
fi

timestamp="$(date -u +%Y%m%d%H%M%S)"
default_name="personal-site-preview-${GITHUB_RUN_ID:-${timestamp}}"

droplet_name="${DO_DROPLET_NAME:-${default_name}}"
region="${DO_REGION:-sfo3}"
size="${DO_SIZE:-s-1vcpu-1gb}"
image="${DO_IMAGE:-ubuntu-24-04-x64}"
output="${DO_ORIGIN_OUTPUT:-ci/digitalocean-origin.json}"
tags_csv="${DO_TAGS:-personal-site,disposable-origin,preview}"

cloud_init="$(awk -v key="${DEPLOY_SSH_PUBLIC_KEY}" '{gsub(/__DEPLOY_SSH_PUBLIC_KEY__/, key); print}' "${cloud_init_template}")"
tags_json="$(printf "%s" "${tags_csv}" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))')"

payload="$(
    jq -n \
        --arg name "${droplet_name}" \
        --arg region "${region}" \
        --arg size "${size}" \
        --arg image "${image}" \
        --arg user_data "${cloud_init}" \
        --argjson tags "${tags_json}" \
        '{
            name: $name,
            region: $region,
            size: $size,
            image: $image,
            backups: false,
            ipv6: true,
            monitoring: true,
            user_data: $user_data,
            tags: $tags
        }'
)"

echo "creating DigitalOcean disposable origin"
echo "name=${droplet_name}"
echo "region=${region}"
echo "size=${size}"
echo "image=${image}"

create_response="$(do_api POST droplets "${payload}")"
droplet_id="$(printf "%s" "${create_response}" | jq -r '.droplet.id // empty')"

if [[ -z "${droplet_id}" ]]; then
    echo "fatal: DigitalOcean did not return a droplet id" >&2
    printf "%s\n" "${create_response}" | jq '.' >&2
    exit 1
fi

public_ipv4=""
status=""

for _attempt in $(seq 1 120); do
    droplet_response="$(do_api GET "droplets/${droplet_id}")"
    status="$(printf "%s" "${droplet_response}" | jq -r '.droplet.status')"
    public_ipv4="$(printf "%s" "${droplet_response}" | droplet_public_ipv4)"

    if [[ "${status}" == "active" && -n "${public_ipv4}" ]]; then
        break
    fi

    sleep 5
done

if [[ "${status}" != "active" || -z "${public_ipv4}" ]]; then
    echo "fatal: droplet ${droplet_id} did not become active with a public IPv4" >&2
    exit 1
fi

mkdir -p "$(dirname "${output}")"

jq -n \
    --arg droplet_id "${droplet_id}" \
    --arg name "${droplet_name}" \
    --arg region "${region}" \
    --arg size "${size}" \
    --arg image "${image}" \
    --arg public_ipv4 "${public_ipv4}" \
    --arg status "${status}" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg ssh_command "ssh deploy@${public_ipv4}" \
    --arg destroy_command "DROPLET_ID=${droplet_id} CONFIRM_DESTROY=1 ./run deploy:origin:destroy" \
    --argjson tags "${tags_json}" \
    '{
        provider: "digitalocean",
        droplet_id: $droplet_id,
        name: $name,
        region: $region,
        size: $size,
        image: $image,
        public_ipv4: $public_ipv4,
        status: $status,
        tags: $tags,
        created_at: $created_at,
        ssh_command: $ssh_command,
        destroy_command: $destroy_command,
        notes: [
            "Use this host only for the disposable deploy-origin spike.",
            "Destroy the droplet, do not power it off, when finished."
        ]
    }' > "${output}"

echo "DigitalOcean disposable origin created"
echo "droplet_id=${droplet_id}"
echo "public_ipv4=${public_ipv4}"
echo "artifact=${output}"
echo "ssh=ssh deploy@${public_ipv4}"
echo "destroy=DROPLET_ID=${droplet_id} CONFIRM_DESTROY=1 ./run deploy:origin:destroy"
