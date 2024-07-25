#!/bin/bash
set -ex

echo "check_certificate = off
      no_clobber = on" > /tmp/.wgetrc
export WGETRC=/tmp/.wgetrc

PROJECT_DIR=$(cd `dirname $0`; pwd)

. "${PROJECT_DIR}"/versions.txt

DOWNLOAD_URL=https://download.jumpserver.org

mkdir -p /opt/player
cd /opt/player || exit 1
wget ${DOWNLOAD_URL}/public/glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz
tar -xf glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz -C /opt/player --strip-components 1
rm -f glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz

DOWNLOAD_DIR=/opt/download
mkdir -p ${DOWNLOAD_DIR}/applets
cd ${DOWNLOAD_DIR}/applets || exit 1
wget -O chromedriver-${CHROME_DRIVER_VERSION}-win64.zip https://github.com/jumpserver-dev/Chrome-Portable-Win64/releases/download/${CHROME_DRIVER_VERSION}/chromedriver-win64.zip
wget -O chrome-${CHROME_VERSION}-win.zip https://github.com/jumpserver-dev/Chrome-Portable-Win64/releases/download/${CHROME_VERSION}/chrome-win.zip
wget https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-amd64.exe
wget ${DOWNLOAD_URL}/public/dbeaver-ce-${DBEAVER_VERSION}-x86_64-setup.exe
wget ${DOWNLOAD_URL}/public/dbeaver-patch-${DBEAVER_VERSION}-x86_64-setup.msi
wget ${DOWNLOAD_URL}/public/Tinker_Installer_${TINKER_VERSION}.exe

mkdir -p ${DOWNLOAD_DIR}/public
cd ${DOWNLOAD_DIR}/public || exit 1
wget ${DOWNLOAD_URL}/public/Microsoft_Remote_Desktop_${MRD_VERSION}_installer.pkg
wget https://github.com/jumpserver/VideoPlayer/releases/download/v${VIDEO_PLAYER_VERSION}/JumpServer.Video.Player-${VIDEO_PLAYER_VERSION}.dmg
wget https://github.com/jumpserver/VideoPlayer/releases/download/v${VIDEO_PLAYER_VERSION}/JumpServer.Video.Player.Setup.${VIDEO_PLAYER_VERSION}.exe

wget https://github.com/PowerShell/Win32-OpenSSH/releases/download/${OPENSSH_VERSION}p1-Beta/OpenSSH-Win64-${OPENSSH_VERSION}.msi

clients=("win-${CLIENT_VERSION}-x64.exe" "mac-${CLIENT_VERSION}-x64.dmg" "mac-${CLIENT_VERSION}-arm64.dmg"
         "linux-${CLIENT_VERSION}-amd64.deb" "linux-${CLIENT_VERSION}-arm64.deb")
for client in "${clients[@]}"; do
    wget "https://github.com/jumpserver/clients/releases/download/${CLIENT_VERSION}/JumpServer-Client-Installer-${client}"
done

for arch in x64 arm64; do
    wget https://downloads.mongodb.com/compass/mongosh-${MONGOSH_VERSION}-linux-${arch}.tgz
done

cp "${PROJECT_DIR}"/versions.txt ${DOWNLOAD_DIR}
