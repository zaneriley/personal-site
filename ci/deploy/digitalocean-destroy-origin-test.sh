#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
tmpdir="$(mktemp -d)"

function cleanup {
    rm -rf "${tmpdir}"
}

trap cleanup EXIT

function write_mock_curl {
    local mock_curl

    mock_curl="${tmpdir}/bin/curl"
    mkdir -p "$(dirname "${mock_curl}")"

    cat > "${mock_curl}" <<'MOCK_CURL'
#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

method="GET"
output_file=""
url=""

while [[ "$#" -gt 0 ]]; do
    case "${1}" in
        -o)
            output_file="${2}"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        -X)
            method="${2}"
            shift 2
            ;;
        -H)
            shift 2
            ;;
        -sS | -s | -S)
            shift
            ;;
        *)
            if [[ "${1}" == https://* ]]; then
                url="${1}"
            fi
            shift
            ;;
    esac
done

if [[ -z "${output_file}" || -z "${url}" ]]; then
    echo "mock curl received incomplete arguments" >&2
    exit 2
fi

path="${url#https://api.digitalocean.com/v2/}"

case "${method}:${path}" in
    GET:droplets/123)
        case "${MOCK_DO_CASE:-ok}" in
            ok)
                jq -n '{
                    droplet: {
                        id: 123,
                        name: "personal-site-preview-test",
                        tags: ["personal-site", "disposable-origin", "preview"],
                        status: "active"
                    }
                }' > "${output_file}"
                ;;
            missing_tags)
                jq -n '{
                    droplet: {
                        id: 123,
                        name: "personal-site-preview-test",
                        tags: ["personal-site"],
                        status: "active"
                    }
                }' > "${output_file}"
                ;;
            bad_name)
                jq -n '{
                    droplet: {
                        id: 123,
                        name: "production-do-not-delete",
                        tags: ["personal-site", "disposable-origin", "preview"],
                        status: "active"
                    }
                }' > "${output_file}"
                ;;
        esac
        printf "200"
        ;;
    DELETE:droplets/123)
        printf "DELETE droplets/123\n" >> "${MOCK_DO_DELETE_LOG}"
        : > "${output_file}"
        printf "204"
        ;;
    GET:droplets/404)
        : > "${output_file}"
        printf "404"
        ;;
    *)
        jq -n --arg method "${method}" --arg path "${path}" '{
            message: "unexpected mock request",
            method: $method,
            path: $path
        }' > "${output_file}"
        printf "500"
        ;;
esac
MOCK_CURL

    chmod +x "${mock_curl}"
}

function write_receipt {
    local droplet_id
    local path

    droplet_id="${1}"
    path="${2}"

    jq -n --arg droplet_id "${droplet_id}" '{droplet_id: $droplet_id}' > "${path}"
}

function run_destroy {
    local mock_case
    local receipt
    local output

    mock_case="${1}"
    receipt="${2}"
    output="${3}"

    PATH="${tmpdir}/bin:${PATH}" \
        MOCK_DO_CASE="${mock_case}" \
        MOCK_DO_DELETE_LOG="${tmpdir}/delete.log" \
        DIGITALOCEAN_TOKEN_STDIN=1 \
        CONFIRM_DESTROY=1 \
        "${repo_root}/ci/deploy/digitalocean-destroy-origin.sh" "${receipt}" \
        <<< "mock-token" > "${output}" 2>&1
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

function assert_no_delete {
    if [[ -s "${tmpdir}/delete.log" ]]; then
        echo "expected no delete request" >&2
        cat "${tmpdir}/delete.log" >&2
        exit 1
    fi
}

write_mock_curl

ok_receipt="${tmpdir}/receipt-ok.json"
missing_tags_receipt="${tmpdir}/receipt-missing-tags.json"
bad_name_receipt="${tmpdir}/receipt-bad-name.json"
absent_receipt="${tmpdir}/receipt-absent.json"

write_receipt "123" "${ok_receipt}"
write_receipt "123" "${missing_tags_receipt}"
write_receipt "123" "${bad_name_receipt}"
write_receipt "404" "${absent_receipt}"

run_destroy ok "${ok_receipt}" "${tmpdir}/ok.out"
assert_contains "${tmpdir}/ok.out" "DigitalOcean droplet destroyed"
assert_contains "${tmpdir}/ok.out" "droplet_id=123"
assert_contains "${tmpdir}/delete.log" "DELETE droplets/123"

: > "${tmpdir}/delete.log"

if run_destroy missing_tags "${missing_tags_receipt}" "${tmpdir}/missing-tags.out"; then
    echo "expected missing-tags destroy to fail" >&2
    cat "${tmpdir}/missing-tags.out" >&2
    exit 1
fi

assert_contains "${tmpdir}/missing-tags.out" "missing expected tags"
assert_no_delete

if run_destroy bad_name "${bad_name_receipt}" "${tmpdir}/bad-name.out"; then
    echo "expected bad-name destroy to fail" >&2
    cat "${tmpdir}/bad-name.out" >&2
    exit 1
fi

assert_contains "${tmpdir}/bad-name.out" "unexpected name"
assert_no_delete

run_destroy ok "${absent_receipt}" "${tmpdir}/absent.out"
assert_contains "${tmpdir}/absent.out" "DigitalOcean droplet already absent"
assert_no_delete

echo "digitalocean destroy receipt test passed"
