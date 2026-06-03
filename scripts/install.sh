#!/bin/bash

set -e

VERSION="v0.3.0"
BASE_URL="https://github.com/yuanboshe/quick-setup/releases/download/${VERSION}/"
PROXY="${1:-}"
INSTALL_DIR="${QS_INSTALL_DIR:-/usr/local/bin}"

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
DOWNLOAD_URL="${BASE_URL}${FILE}"
SUMS_URL="${BASE_URL}SHA256SUMS"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "Download qs ${VERSION} from ${PROXY}${DOWNLOAD_URL} ..."
curl -fsSL -o "${TMP_DIR}/${FILE}" "${PROXY}${DOWNLOAD_URL}"

if command -v sha256sum >/dev/null 2>&1; then
    curl -fsSL -o "${TMP_DIR}/SHA256SUMS" "${PROXY}${SUMS_URL}"
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
