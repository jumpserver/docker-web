#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. "${PROJECT_DIR}/client-version.txt"

: "${CLIENT_VERSION:?CLIENT_VERSION is required}"
: "${CLIENT_NAME:?CLIENT_NAME is required}"

RELEASE_URL=${CLIENT_RELEASE_URL:-https://github.com/jumpserver/luna/releases/download/v${CLIENT_VERSION}}
DOWNLOAD_DIR=${CLIENT_DOWNLOAD_DIR:-/opt/download/public}
WEBLITE_DOWNLOAD_DIR=${WEBLITE_DOWNLOAD_DIR:-/opt/download/applets}

mkdir -p "${DOWNLOAD_DIR}" "${WEBLITE_DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"

windows_file="${CLIENT_NAME}Client_${CLIENT_VERSION}_x64-setup.exe"
macos_arm64_file="${CLIENT_NAME}Client_${CLIENT_VERSION}_aarch64.dmg"
weblite_file="JumpServer-WebLite-${CLIENT_VERSION}-x64.msi"

wget --https-only \
    --output-document="${windows_file}" \
    "${RELEASE_URL}/${CLIENT_NAME}-${CLIENT_VERSION}.exe"
wget --https-only \
    --output-document="${macos_arm64_file}" \
    "${RELEASE_URL}/${CLIENT_NAME}-${CLIENT_VERSION}-arm64.dmg"
wget --https-only \
    --output-document="${WEBLITE_DOWNLOAD_DIR}/${weblite_file}" \
    "${RELEASE_URL}/${weblite_file}"

ln -s "${windows_file}" "Client_${CLIENT_VERSION}_x64-setup.exe"
ln -s "${macos_arm64_file}" "Client_${CLIENT_VERSION}_aarch64.dmg"
