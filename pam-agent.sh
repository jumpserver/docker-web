#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${PROJECT_DIR}/pam-agent-version.txt"

: "${PAM_AGENT_VERSION:?PAM_AGENT_VERSION must name a published JumpServer release}"
RELEASE_TAG="v${PAM_AGENT_VERSION#v}"
OFFICIAL_RELEASE_URL=https://github.com/jumpserver/pam-clients/releases/download/${RELEASE_TAG}
RELEASE_URL=${PAM_AGENT_RELEASE_URL:-${OFFICIAL_RELEASE_URL}}
DOWNLOAD_DIR=${PAM_AGENT_DOWNLOAD_DIR:-/opt/download/pam}

mkdir -p "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"
for filename in jms-pam-agent-linux-amd64 jms-pam-agent-linux-arm64 SHA256SUMS; do
    if wget --https-only --timeout=30 --tries=1 --output-document="${filename}" "${RELEASE_URL}/${filename}"; then
        continue
    else
        status=$?
    fi
    # Some GnuTLS/proxy combinations fail with automatic TLS negotiation. Retry
    # network errors once with TLS 1.2, only for the same official release URL.
    # Certificate, authentication, HTTP and checksum errors must still fail.
    if [ "${status}" -ne 4 ] || [ "${RELEASE_URL}" != "${OFFICIAL_RELEASE_URL}" ]; then
        exit "${status}"
    fi
    printf '%s\n' "PAM download network failure; retrying ${filename} once with TLS 1.2" >&2
    wget --https-only --timeout=30 --tries=1 --secure-protocol=TLSv1_2 \
        --output-document="${filename}" "${RELEASE_URL}/${filename}"
done
sha256sum --check SHA256SUMS
chmod 0755 jms-pam-agent-linux-amd64 jms-pam-agent-linux-arm64
