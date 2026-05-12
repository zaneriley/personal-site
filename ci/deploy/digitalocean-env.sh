#!/usr/bin/env bash

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
