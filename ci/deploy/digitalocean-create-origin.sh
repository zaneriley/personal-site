#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cloud_init_template="${script_dir}/digitalocean-origin-cloud-init.yml"
ssh_private_key_file=""
ssh_known_hosts_file=""
droplet_id=""
action_id=""
public_ipv4=""
public_ipv6=""
status="requested"
origin_ready="false"
created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

function cleanup_files {
    if [[ -n "${ssh_private_key_file}" ]]; then
        rm -f "${ssh_private_key_file}"
    fi

    if [[ -n "${ssh_known_hosts_file}" ]]; then
        rm -f "${ssh_known_hosts_file}"
    fi
}

function cleanup {
    local exit_status="$?"

    if [[ "${exit_status}" != "0" && -n "${droplet_id}" && "${origin_ready}" != "true" ]]; then
        set +e
        status="failed"
        write_receipt "failed"

        if [[ "${PRESERVE_FAILED_ORIGIN:-0}" == "1" ]]; then
            echo "failed origin preserved by PRESERVE_FAILED_ORIGIN=1" >&2
            echo "destroy=DROPLET_ID=${droplet_id} CONFIRM_DESTROY=1 ./run host:disposable:destroy" >&2
        else
            echo "create failed after Droplet allocation; destroying ${droplet_id}" >&2

            if delete_droplet; then
                status="destroyed_after_failure"
                write_receipt "destroyed_after_failure"
            else
                echo "fatal: failed to destroy failed Droplet ${droplet_id}; use receipt ${output}" >&2
            fi
        fi
    fi

    cleanup_files
    exit "${exit_status}"
}

trap cleanup EXIT

function require_env {
    local name

    name="${1}"

    if [[ -z "${!name:-}" ]]; then
        echo "fatal: ${name} is required" >&2
        return 1
    fi
}

function assert_allowed {
    local name
    local value
    local allowed_csv
    local allowed
    local allowed_value

    name="${1}"
    value="${2}"
    allowed_csv="${3}"

    IFS="," read -r -a allowed <<< "${allowed_csv}"

    for allowed_value in "${allowed[@]}"; do
        if [[ "${value}" == "${allowed_value}" ]]; then
            return 0
        fi
    done

    echo "fatal: ${name}=${value} is not allowed; allowed=${allowed_csv}" >&2
    return 1
}

function do_api {
    local method
    local path
    local data_arg
    local body_file
    local status_code

    method="${1}"
    path="${2}"
    data_arg="${3:-}"
    body_file="$(mktemp)"

    if [[ -n "${data_arg}" ]]; then
        status_code="$(curl -sS \
            -o "${body_file}" \
            -w "%{http_code}" \
            -X "${method}" \
            -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "${data_arg}" \
            "https://api.digitalocean.com/v2/${path}" || true)"
    else
        status_code="$(curl -sS \
            -o "${body_file}" \
            -w "%{http_code}" \
            -X "${method}" \
            -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
            "https://api.digitalocean.com/v2/${path}" || true)"
    fi

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

function droplet_public_ipv4 {
    jq -r '.droplet.networks.v4[]? | select(.type == "public") | .ip_address' | head -n 1
}

function droplet_public_ipv6 {
    jq -r '.droplet.networks.v6[]? | .ip_address' | head -n 1
}

function configure_ssh_private_key {
    ssh_private_key_file="$(mktemp)"
    ssh_known_hosts_file="$(mktemp)"
    chmod 600 "${ssh_private_key_file}"
    printf "%s\n" "${DEPLOY_SSH_PRIVATE_KEY}" > "${ssh_private_key_file}"
}

function render_cloud_init {
    local line

    while IFS= read -r line || [[ -n "${line}" ]]; do
        printf "%s\n" "${line/__DEPLOY_SSH_PUBLIC_KEY__/${DEPLOY_SSH_PUBLIC_KEY}}"
    done < "${cloud_init_template}"
}

function write_receipt {
    local lifecycle_status

    lifecycle_status="${1}"
    mkdir -p "$(dirname "${output}")"

    jq -n \
        --arg droplet_id "${droplet_id}" \
        --arg action_id "${action_id}" \
        --arg name "${droplet_name}" \
        --arg region "${region}" \
        --arg size "${size}" \
        --arg image "${image}" \
        --arg public_ipv4 "${public_ipv4}" \
        --arg public_ipv6 "${public_ipv6}" \
        --arg status "${status}" \
        --arg lifecycle_status "${lifecycle_status}" \
        --arg created_at "${created_at}" \
        --arg workflow_run_id "${GITHUB_RUN_ID:-}" \
        --arg workflow_sha "${GITHUB_SHA:-}" \
        --arg ssh_command "ssh deploy@${public_ipv4}" \
        --arg destroy_command "DROPLET_ID=${droplet_id} CONFIRM_DESTROY=1 ./run host:disposable:destroy" \
        --argjson tags "${tags_json}" \
        '{
            provider: "digitalocean",
            purpose: "personal-site disposable Docker host spike",
            droplet_id: $droplet_id,
            action_id: $action_id,
            name: $name,
            region: $region,
            size: $size,
            image: $image,
            public_ipv4: $public_ipv4,
            public_ipv6: $public_ipv6,
            status: $status,
            lifecycle_status: $lifecycle_status,
            tags: $tags,
            created_at: $created_at,
            workflow_run_id: $workflow_run_id,
            workflow_sha: $workflow_sha,
            ssh_command: $ssh_command,
            destroy_command: $destroy_command,
            notes: [
                "Use this host only for the disposable Docker-host spike.",
                "Destroy the droplet, do not power it off, when finished.",
                "Destroy must verify the expected disposable-origin tags before deleting."
            ]
        }' > "${output}"
}

function delete_droplet {
    do_api DELETE "droplets/${droplet_id}" >/dev/null
}

function wait_for_action {
    local action_status
    local action_response

    if [[ -z "${action_id}" ]]; then
        echo "DigitalOcean did not return an action id; falling back to Droplet polling"
        return 0
    fi

    for _attempt in $(seq 1 120); do
        action_response="$(do_api GET "actions/${action_id}")"
        action_status="$(printf "%s" "${action_response}" | jq -r '.action.status')"

        case "${action_status}" in
            completed)
                return 0
                ;;
            errored)
                echo "fatal: DigitalOcean create action ${action_id} errored" >&2
                printf "%s\n" "${action_response}" | jq '.' >&2
                exit 1
                ;;
            in-progress)
                sleep 5
                ;;
            *)
                echo "fatal: unexpected DigitalOcean action status: ${action_status}" >&2
                printf "%s\n" "${action_response}" | jq '.' >&2
                exit 1
                ;;
        esac
    done

    echo "fatal: DigitalOcean create action ${action_id} did not complete" >&2
    exit 1
}

function wait_for_origin_ready {
    local public_ip
    local remote_command

    public_ip="${1}"
    remote_command="timeout ${SSH_READINESS_REMOTE_TIMEOUT_SECONDS:-300}s bash -lc 'cloud-init status --wait >/dev/null && command -v docker >/dev/null && docker --version >/dev/null && test -d /var/lib/personal-site'"

    echo "waiting for cloud-init and Docker readiness"

    for _attempt in $(seq 1 "${SSH_READINESS_ATTEMPTS:-60}"); do
        if ssh \
            -i "${ssh_private_key_file}" \
            -o BatchMode=yes \
            -o ConnectTimeout=10 \
            -o ServerAliveInterval=15 \
            -o ServerAliveCountMax=2 \
            -o StrictHostKeyChecking=accept-new \
            -o UserKnownHostsFile="${ssh_known_hosts_file}" \
            "deploy@${public_ip}" \
            "${remote_command}" >/dev/null 2>&1; then
            echo "origin Docker readiness verified"
            origin_ready="true"
            return 0
        fi

        sleep 5
    done

    echo "fatal: droplet ${droplet_id} did not finish cloud-init with Docker readiness" >&2
    exit 1
}

require_env DIGITALOCEAN_TOKEN
require_env DEPLOY_SSH_PUBLIC_KEY
require_env DEPLOY_SSH_PRIVATE_KEY
configure_ssh_private_key

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
output="${DO_HOST_OUTPUT:-${DO_ORIGIN_OUTPUT:-ci/digitalocean-host.json}}"
tags_csv="${DO_TAGS:-personal-site,disposable-origin,preview}"

assert_allowed DO_REGION "${region}" "${DO_ALLOWED_REGIONS:-sfo3}"
assert_allowed DO_SIZE "${size}" "${DO_ALLOWED_SIZES:-s-1vcpu-1gb}"
assert_allowed DO_IMAGE "${image}" "${DO_ALLOWED_IMAGES:-ubuntu-24-04-x64}"

cloud_init="$(render_cloud_init)"
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

echo "creating DigitalOcean disposable host"
echo "name=${droplet_name}"
echo "region=${region}"
echo "size=${size}"
echo "image=${image}"

create_response="$(do_api POST droplets "${payload}")"
droplet_id="$(printf "%s" "${create_response}" | jq -r '.droplet.id // empty')"
action_id="$(printf "%s" "${create_response}" | jq -r '.links.actions[0].id // empty')"

if [[ -z "${droplet_id}" ]]; then
    echo "fatal: DigitalOcean did not return a droplet id" >&2
    printf "%s\n" "${create_response}" | jq '.' >&2
    exit 1
fi

status="$(printf "%s" "${create_response}" | jq -r '.droplet.status // "new"')"
write_receipt "allocated"
wait_for_action

for _attempt in $(seq 1 120); do
    droplet_response="$(do_api GET "droplets/${droplet_id}")"
    status="$(printf "%s" "${droplet_response}" | jq -r '.droplet.status')"
    public_ipv4="$(printf "%s" "${droplet_response}" | droplet_public_ipv4)"
    public_ipv6="$(printf "%s" "${droplet_response}" | droplet_public_ipv6)"
    write_receipt "waiting_for_network"

    if [[ "${status}" == "active" && -n "${public_ipv4}" ]]; then
        break
    fi

    sleep 5
done

if [[ "${status}" != "active" || -z "${public_ipv4}" ]]; then
    echo "fatal: droplet ${droplet_id} did not become active with a public IPv4" >&2
    exit 1
fi

wait_for_origin_ready "${public_ipv4}"
write_receipt "ready"

echo "DigitalOcean disposable host created"
echo "droplet_id=${droplet_id}"
echo "public_ipv4=${public_ipv4}"
echo "public_ipv6=${public_ipv6}"
echo "artifact=${output}"
echo "ssh=ssh deploy@${public_ipv4}"
echo "destroy=DROPLET_ID=${droplet_id} CONFIRM_DESTROY=1 ./run host:disposable:destroy"
