#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. "${PROJECT_DIR}/client-version.txt"

: "${CLIENT_VERSION:?CLIENT_VERSION is required}"
: "${CLIENT_NAME:?CLIENT_NAME is required}"
: "${WEBLITE_VERSION:?WEBLITE_VERSION is required}"

OFFICIAL_RELEASE_URL=https://github.com/jumpserver/luna/releases/download/client-v${CLIENT_VERSION}
RELEASE_URL=${CLIENT_RELEASE_URL:-${OFFICIAL_RELEASE_URL}}
OFFICIAL_WEBLITE_RELEASE_URL=https://github.com/jumpserver/luna/releases/download/weblite-v${WEBLITE_VERSION}
WEBLITE_RELEASE_URL=${WEBLITE_RELEASE_URL:-${OFFICIAL_WEBLITE_RELEASE_URL}}
DOWNLOAD_DIR=${CLIENT_DOWNLOAD_DIR:-/opt/download/public}
WEBLITE_DOWNLOAD_DIR=${WEBLITE_DOWNLOAD_DIR:-/opt/download/applets}

mkdir -p "${DOWNLOAD_DIR}" "${WEBLITE_DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"

windows_file="${CLIENT_NAME}Client_${CLIENT_VERSION}_x64-setup.exe"
macos_arm64_file="${CLIENT_NAME}Client_${CLIENT_VERSION}_aarch64.dmg"
weblite_file="JumpServer-WebLite-${WEBLITE_VERSION}-x64.msi"

download_release() {
    file=$1 url=$2 official_url=$3
    if wget --https-only --timeout=30 --tries=1 --output-document="${file}" "${url}"; then
        return 0
    else
        status=$?
    fi
    # Match PAM downloads: retry only a network failure against the same official
    # URL. Certificate, authentication and HTTP failures retain their error status.
    if [ "${status}" -ne 4 ] || [ "${url}" != "${official_url}" ]; then
        return "${status}"
    fi
    printf '%s\n' "Client download network failure; retrying once with TLS 1.2" >&2
    wget --https-only --timeout=30 --tries=1 --secure-protocol=TLSv1_2 \
        --output-document="${file}" "${url}"
}

download_release "${windows_file}" \
    "${RELEASE_URL}/${CLIENT_NAME}-${CLIENT_VERSION}-Setup.exe" \
    "${OFFICIAL_RELEASE_URL}/${CLIENT_NAME}-${CLIENT_VERSION}-Setup.exe"
download_release "${macos_arm64_file}" \
    "${RELEASE_URL}/${CLIENT_NAME}-${CLIENT_VERSION}-arm64.dmg" \
    "${OFFICIAL_RELEASE_URL}/${CLIENT_NAME}-${CLIENT_VERSION}-arm64.dmg"
download_release "${WEBLITE_DOWNLOAD_DIR}/${weblite_file}" \
    "${WEBLITE_RELEASE_URL}/${weblite_file}" \
    "${OFFICIAL_WEBLITE_RELEASE_URL}/${weblite_file}"

ln -s "${windows_file}" "Client_${CLIENT_VERSION}_x64-setup.exe"
ln -s "${macos_arm64_file}" "Client_${CLIENT_VERSION}_aarch64.dmg"
