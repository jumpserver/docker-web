FROM nginx:1.22

ARG TARGETARCH
ARG APT_MIRROR=http://mirrors.ustc.edu.cn

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web \
    sed -i "s@http://.*.debian.org@${APT_MIRROR}@g" /etc/apt/sources.list \
    && rm -f /etc/cron.daily/apt-compat \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get install -y --no-install-recommends wget vim logrotate locales \
    && echo "no" | dpkg-reconfigure dash \
    && echo "zh_CN.UTF-8" | dpkg-reconfigure locales \
    && rm -f /var/log/nginx/*.log \
    && rm -rf /var/lib/apt/lists/*

ARG Jmservisor_VERSION=v1.2.5
ARG Client_VERSION=v1.1.7
ARG MRD_VERSION=10.6.7
ARG VIDEO_PLAYER_VERSION=0.1.5
ARG PLAY_VERSION=1.1.0-1
ARG DOWNLOAD_URL=https://download.jumpserver.org

RUN set -ex \
    && mkdir -p /opt/download /opt/player /etc/nginx/sites-enabled \
    && cd /opt/download \
    && wget -qO /opt/download/Jmservisor.msi ${DOWNLOAD_URL}/public/Jmservisor-${Jmservisor_VERSION}.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer-x86_64.msi ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-x86_64.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer.dmg ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}.dmg \
    && wget -qO /opt/download/JumpServer-Client-Installer-amd64.run ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-amd64.run \
    && wget -qO /opt/download/JumpServer-Client-Installer-arm64.run ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-arm64.run \
    && wget -qO /opt/download/JumpServer-Video-Player.dmg ${DOWNLOAD_URL}/public/JumpServer.Video.Player-${VIDEO_PLAYER_VERSION}.dmg \
    && wget -qO /opt/download/JumpServer-Video-Player.exe ${DOWNLOAD_URL}/public/JumpServer.Video.Player.Setup.${VIDEO_PLAYER_VERSION}.exe \
    && wget -qO /opt/download/OpenSSH-Win64.msi ${DOWNLOAD_URL}/public/OpenSSH-Win64.msi \
    && wget -q ${DOWNLOAD_URL}/public/Microsoft_Remote_Desktop_${MRD_VERSION}_installer.pkg \
    && wget -q ${DOWNLOAD_URL}/public/glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz \
    && tar -xf glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz -C /opt/player --strip-components 1 \
    && rm -f glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz

COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
