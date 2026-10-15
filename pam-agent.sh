#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${PROJECT_DIR}/pam-agent-version.txt"

: "${PAM_AGENT_VERSION:?PAM_AGENT_VERSION must name a published JumpServer release}"
RELEASE_TAG="v${PAM_AGENT_VERSION#v}"
RELEASE_URL=${PAM_AGENT_RELEASE_URL:-https://github.com/jumpserver/pam-clients/releases/download/${RELEASE_TAG}}
DOWNLOAD_DIR=${PAM_AGENT_DOWNLOAD_DIR:-/opt/download/pam}

mkdir -p "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"
for filename in jms-pam-agent-linux-amd64 jms-pam-agent-linux-arm64 SHA256SUMS; do
    wget --https-only --output-document="${filename}" "${RELEASE_URL}/${filename}"
done
sha256sum --check SHA256SUMS
chmod 0755 jms-pam-agent-linux-amd64 jms-pam-agent-linux-arm64
