#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    GET:droplets\?tag_name=preview-lease\&per_page=200\&page=1)
        jq -n '{
            droplets: [
                {
                    id: 101,
                    name: "personal-site-disposable-expired",
                    tags: ["personal-site", "disposable-host", "preview-lease", "preview-expires-1000"]
                },
                {
                    id: 102,
                    name: "personal-site-disposable-future",
                    tags: ["personal-site", "disposable-host", "preview-lease", "preview-expires-999999"]
                },
                {
                    id: 103,
                    name: "personal-site-disposable-missing-expiry",
                    tags: ["personal-site", "disposable-host", "preview-lease"]
                },
                {
                    id: 104,
                    name: "production-do-not-delete",
                    tags: ["personal-site", "disposable-host", "preview-lease", "preview-expires-1000"]
                }
            ]
        }' > "${output_file}"
        printf "200"
        ;;
    GET:droplets/101)
        jq -n '{
            droplet: {
                id: 101,
                name: "personal-site-disposable-expired",
                tags: ["personal-site", "disposable-host", "preview-lease", "preview-expires-1000"],
                status: "active"
            }
        }' > "${output_file}"
        printf "200"
        ;;
    DELETE:droplets/101)
        printf "DELETE droplets/101\n" >> "${MOCK_DO_DELETE_LOG}"
        : > "${output_file}"
        printf "204"
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

write_mock_curl

PATH="${tmpdir}/bin:${PATH}" \
    MOCK_DO_DELETE_LOG="${tmpdir}/delete.log" \
    DIGITALOCEAN_TOKEN_STDIN=1 \
    SWEEP_NOW_EPOCH=2000 \
    "${script_dir}/sweep-expired-disposable-hosts.sh" \
    <<< "mock-token" > "${tmpdir}/sweep.out" 2>&1

assert_contains "${tmpdir}/sweep.out" "DigitalOcean droplet destroyed"
assert_contains "${tmpdir}/sweep.out" "keep droplet 102"
assert_contains "${tmpdir}/sweep.out" "skip droplet 103"
assert_contains "${tmpdir}/sweep.out" "skip droplet 104"
assert_contains "${tmpdir}/sweep.out" "expired_count=1"
assert_contains "${tmpdir}/sweep.out" "destroyed_count=1"
assert_contains "${tmpdir}/sweep.out" "skipped_count=2"
assert_contains "${tmpdir}/delete.log" "DELETE droplets/101"

echo "digitalocean expired preview sweep test passed"
