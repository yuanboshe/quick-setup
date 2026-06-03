#!/bin/bash

set -e

VERSION="v0.3.0"
BASE_URL="https://github.com/yuanboshe/quick-setup/releases/download/${VERSION}/"
PROXY="${1:-${QS_DOWNLOAD_PREFIX:-}}"
INSTALL_DIR="${QS_INSTALL_DIR:-/usr/local/bin}"
CURL_CONNECT_TIMEOUT="${QS_CURL_CONNECT_TIMEOUT:-8}"
CURL_MAX_TIME="${QS_CURL_MAX_TIME:-120}"
CURL_RETRY="${QS_CURL_RETRY:-2}"
# 发布方可以在这里填入默认镜像或 GHX 转发入口，多个值用空格或逗号分隔。
DEFAULT_RELEASE_BASE_URLS=""
DEFAULT_GHX_BASE_URLS="https://ghx-cache.pz1.top https://ghx.pz1.top"

urlencode() {
    local raw="$1"
    local encoded=""
    local i char hex
    for ((i = 0; i < ${#raw}; i++)); do
        char="${raw:i:1}"
        case "${char}" in
            [a-zA-Z0-9.~_-])
                encoded+="${char}"
                ;;
            *)
                printf -v hex '%%%02X' "'${char}"
                encoded+="${hex}"
                ;;
        esac
    done
    printf '%s' "${encoded}"
}

ghx_proxy_url() {
    local base="${1%/}"
    local target="$2"
    local sep="?"
    if [[ "${base}" == *"?"* ]]; then
        sep="&"
    fi
    printf '%s%surl=%s' "${base}" "${sep}" "$(urlencode "${target}")"
}

download_one() {
    local url="$1"
    local output="$2"
    local mode="${3:-direct}"
    local extra_args=()
    if [ "${mode}" = "ghx" ] && [ -n "${QS_GHX_TOKEN:-}" ]; then
        extra_args=(-H "X-GHX-Token: ${QS_GHX_TOKEN}")
    fi
    curl -fsSL \
        --connect-timeout "${CURL_CONNECT_TIMEOUT}" \
        --max-time "${CURL_MAX_TIME}" \
        --retry "${CURL_RETRY}" \
        --retry-delay 1 \
        "${extra_args[@]}" \
        -o "${output}" \
        "${url}"
}

append_url_list() {
    local list="$1"
    local -n output_ref="$2"
    local item
    list="${list//,/ }"
    for item in ${list}; do
        if [ -n "${item}" ]; then
            output_ref+=("${item}")
        fi
    done
}

download_asset() {
    local asset="$1"
    local output="$2"
    local upstream="${BASE_URL}${asset}"
    local url
    local base
    local release_base_urls=()
    local ghx_base_urls=()

    if [ -n "${QS_RELEASE_BASE_URL:-}" ]; then
        release_base_urls+=("${QS_RELEASE_BASE_URL}")
    fi
    append_url_list "${QS_RELEASE_BASE_URLS:-}" release_base_urls
    append_url_list "${DEFAULT_RELEASE_BASE_URLS}" release_base_urls

    if [ -n "${QS_GHX_BASE_URL:-}" ]; then
        ghx_base_urls+=("${QS_GHX_BASE_URL}")
    fi
    append_url_list "${QS_GHX_BASE_URLS:-}" ghx_base_urls
    append_url_list "${DEFAULT_GHX_BASE_URLS}" ghx_base_urls

    for base in "${release_base_urls[@]}"; do
        url="${base%/}/${asset}"
        echo "Download ${asset} from ${url} ..."
        if download_one "${url}" "${output}"; then
            return 0
        fi
        echo "Download failed: ${url}" >&2
    done

    for base in "${ghx_base_urls[@]}"; do
        url="$(ghx_proxy_url "${base}" "${upstream}")"
        echo "Download ${asset} through GHX proxy ${base} ..."
        if download_one "${url}" "${output}" "ghx"; then
            return 0
        fi
        echo "Download failed through GHX proxy: ${base}" >&2
    done

    if [ -n "${PROXY}" ]; then
        url="${PROXY}${upstream}"
        echo "Download ${asset} from ${url} ..."
        if download_one "${url}" "${output}"; then
            return 0
        fi
        echo "Download failed: ${url}" >&2
    fi

    echo "Download ${asset} from ${upstream} ..."
    if download_one "${upstream}" "${output}"; then
        return 0
    fi

    echo "Failed to download ${asset}." >&2
    echo "If GitHub is unreachable, set QS_GHX_BASE_URL, QS_GHX_BASE_URLS, QS_RELEASE_BASE_URL or QS_RELEASE_BASE_URLS and retry." >&2
    return 1
}

ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64|amd64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

OS="$(uname -s)"
case "${OS}" in
    Linux)
        OS="linux"
        ;;
    *)
        echo "This install script currently supports Linux only: ${OS}"
        exit 1
        ;;
esac

FILE="qs-${OS}-${ARCH}"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

download_asset "${FILE}" "${TMP_DIR}/${FILE}"

if command -v sha256sum >/dev/null 2>&1; then
    download_asset "SHA256SUMS" "${TMP_DIR}/SHA256SUMS"
    (cd "${TMP_DIR}" && grep "  ${FILE}$" SHA256SUMS | sha256sum -c -)
else
    echo "sha256sum not found, skip checksum verification"
fi

chmod +x "${TMP_DIR}/${FILE}"

if [ -w "${INSTALL_DIR}" ]; then
    mv "${TMP_DIR}/${FILE}" "${INSTALL_DIR}/qs"
elif command -v sudo >/dev/null 2>&1; then
    sudo mv "${TMP_DIR}/${FILE}" "${INSTALL_DIR}/qs"
else
    echo "No write permission for ${INSTALL_DIR} and sudo is not available"
    exit 1
fi

echo "qs has been installed to ${INSTALL_DIR}/qs"
